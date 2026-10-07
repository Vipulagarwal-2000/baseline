class_name ReferentialIntegrityAuditor
extends RefCounted


var canonical_ids: Dictionary = {}
var rules_registry: ReferentialIntegrityRulesRegistry
var errors: Array = []
var checked_references: int = 0


func _init() -> void:
	rules_registry = ReferentialIntegrityRulesRegistry.new()
	_load_canonical_ids()


func is_ready() -> bool:
	return not canonical_ids.is_empty() and rules_registry.is_loaded()


func get_errors() -> Array:
	return errors.duplicate(true)


func get_checked_reference_count() -> int:
	return checked_references


func run() -> bool:
	errors = []
	checked_references = 0

	if not rules_registry.is_loaded():
		errors.append(
			"Rules registry unavailable: "
			+ rules_registry.get_load_error()
		)
		return false

	if canonical_ids.is_empty():
		errors.append(
			"Canonical ID registry unavailable."
		)
		return false

	for rule in rules_registry.get_rules():
		_apply_rule(rule)

	return errors.is_empty()


func _apply_rule(rule: Dictionary) -> void:
	var rule_id := str(
		rule.get(
			"rule_id",
			""
		)
	)

	var target_domain := str(
		rule.get(
			"target_domain",
			""
		)
	)

	if not _canonical_domain_exists(target_domain):
		errors.append(
			rule_id
			+ ": target canonical domain does not exist: "
			+ target_domain
		)
		return

	var mode := str(
		rule.get(
			"mode",
			""
		)
	)

	var selector := str(
		rule.get(
			"selector",
			""
		)
	)

	var source_paths = rule.get(
		"source_paths",
		[]
	)

	if typeof(source_paths) != TYPE_ARRAY:
		errors.append(
			rule_id + ": source_paths is not an array"
		)
		return

	for raw_source_path in source_paths:
		var source_path := str(raw_source_path)
		var data = _load_json(source_path)

		if data == null:
			errors.append(
				rule_id
				+ ": source data could not be loaded: "
				+ source_path
			)
			continue

		var references := _extract_references(
			data,
			selector,
			mode
		)

		for reference in references:
			checked_references += 1

			var reference_id := str(reference).strip_edges()

			if reference_id.is_empty():
				errors.append(
					rule_id
					+ ": empty canonical reference in "
					+ source_path
				)
				continue

			if not _canonical_id_exists(
				target_domain,
				reference_id
			):
				errors.append(
					rule_id
					+ ": unknown "
					+ target_domain
					+ " reference '"
					+ reference_id
					+ "' in "
					+ source_path
				)


func _extract_references(
	data,
	selector: String,
	mode: String
) -> Array:

	match mode:
		"value":
			return _extract_value(data, selector)

		"map_keys":
			return _extract_map_keys(data, selector)

		"root_map_keys":
			if typeof(data) != TYPE_DICTIONARY:
				return []
			return _stringify_array(data.keys())

		"array_item_field":
			return _extract_array_item_field(
				data,
				selector
			)

		"array_map_keys":
			return _extract_array_map_keys(
				data,
				selector
			)

		"nested_root_map_keys":
			return _extract_nested_root_map_keys(
				data,
				selector
			)

		"array_item_field_nested":
			return _extract_array_item_field_nested(
				data,
				selector
			)

	return []


func _extract_value(
	data,
	path: String
) -> Array:

	var value = _get_path(
		data,
		path
	)

	if value == null:
		return []

	return [str(value)]


func _extract_map_keys(
	data,
	path: String
) -> Array:

	var value = _get_path(
		data,
		path
	)

	if typeof(value) != TYPE_DICTIONARY:
		return []

	return _stringify_array(
		value.keys()
	)


func _extract_array_item_field(
	data,
	path: String
) -> Array:

	var parts := path.split(
		".",
		false
	)

	if parts.size() < 2:
		return []

	var field_name := parts[-1]
	var array_parts: Array = parts.slice(
		0,
		parts.size() - 1
	)

	var array_path_parts: Array = []

	for raw_part in array_parts:
		var part := str(raw_part)

		if part.ends_with("[]"):
			part = part.left(
				part.length() - 2
			)

		array_path_parts.append(part)

	var array = _get_path(
		data,
		".".join(array_path_parts)
	)

	if typeof(array) != TYPE_ARRAY:
		return []

	var references: Array = []

	for item in array:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		if item.has(field_name):
			references.append(
				str(item[field_name])
			)

	return references


func _extract_array_map_keys(
	data,
	path: String
) -> Array:

	var parts := path.split(
		".",
		false
	)

	var wildcard_index := -1

	for i in range(parts.size()):
		if parts[i] == "[]":
			wildcard_index = i
			break

	if wildcard_index < 0:
		return []

	var array_path := ".".join(
		parts.slice(
			0,
			wildcard_index
		)
	)

	var nested_path := ".".join(
		parts.slice(
			wildcard_index + 1
		)
	)

	var array = _get_path(
		data,
		array_path
	)

	if typeof(array) != TYPE_ARRAY:
		return []

	var references: Array = []

	for item in array:
		var nested = _get_path(
			item,
			nested_path
		)

		if typeof(nested) != TYPE_DICTIONARY:
			continue

		for key in nested.keys():
			references.append(
				str(key)
			)

	return references


func _extract_nested_root_map_keys(
	data,
	path: String
) -> Array:

	# Selector pattern: *.<field>
	var parts := path.split(
		".",
		false
	)

	if parts.size() != 2 or parts[0] != "*":
		return []

	if typeof(data) != TYPE_DICTIONARY:
		return []

	var field_name := parts[1]
	var references: Array = []

	for process_id in data.keys():
		var definition = data[process_id]

		if typeof(definition) != TYPE_DICTIONARY:
			continue

		var nested = definition.get(
			field_name,
			{}
		)

		if typeof(nested) != TYPE_DICTIONARY:
			continue

		for key in nested.keys():
			references.append(
				str(key)
			)

	return references


func _extract_array_item_field_nested(
	data,
	path: String
) -> Array:

	# Selector pattern: regions[].provinces, returning the id from
	# every dictionary in each nested collection.
	var parts := path.split(
		".",
		false
	)

	if parts.size() != 2:
		return []

	if parts[1] == "provinces" and parts[0] == "regions[]":
		var regions = data.get(
			"regions",
			[]
		)

		if typeof(regions) != TYPE_ARRAY:
			return []

		var references: Array = []

		for region in regions:
			if typeof(region) != TYPE_DICTIONARY:
				continue

			var provinces = region.get(
				"provinces",
				[]
			)

			if typeof(provinces) != TYPE_ARRAY:
				continue

			for province in provinces:
				if typeof(province) != TYPE_DICTIONARY:
					continue

				if province.has("id"):
					references.append(
						str(province["id"])
					)

		return references

	return []


func _get_path(
	data,
	path: String
):

	if path.is_empty():
		return data

	var current = data

	for segment in path.split(
		".",
		false
	):
		if typeof(current) != TYPE_DICTIONARY:
			return null

		if not current.has(segment):
			return null

		current = current[segment]

	return current


func _canonical_domain_exists(
	domain_id: String
) -> bool:

	return (
		canonical_ids.has(domain_id)
		and typeof(canonical_ids[domain_id]) == TYPE_DICTIONARY
	)


func _canonical_id_exists(
	domain_id: String,
	id: String
) -> bool:

	if not _canonical_domain_exists(domain_id):
		return false

	var entries = canonical_ids[domain_id].get(
		"entries",
		{}
	)

	if typeof(entries) != TYPE_DICTIONARY:
		return false

	return entries.has(id)


func _stringify_array(
	values: Array
) -> Array:

	var result: Array = []

	for value in values:
		result.append(str(value))

	return result


func _load_canonical_ids() -> void:
	canonical_ids = {}

	const path := "res://data/canonical_ids.json"

	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var domains = parsed.get(
		"domains",
		{}
	)

	if typeof(domains) == TYPE_DICTIONARY:
		canonical_ids = domains.duplicate(true)


func _load_json(path: String):
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return null

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()
	return parsed
