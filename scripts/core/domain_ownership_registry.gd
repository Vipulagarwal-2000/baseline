class_name DomainOwnershipRegistry
extends RefCounted


const OWNERSHIP_PATH := "res://data/domain_ownership.json"

const REQUIRED_FIELDS: Array = [
	"status",
	"definition_authority",
	"definition_paths",
	"runtime_authority",
	"loader_authority",
	"runtime_systems",
	"canonical_domain",
	"provenance_class",
	"notes"
]

const ALLOWED_STATUS_VALUES: Array = [
	"active",
	"partial",
	"reserved_unmodeled"
]

var ownership_id: String = ""
var version: int = 0
var policy: Dictionary = {}
var domains: Dictionary = {}
var load_error: String = ""


func _init() -> void:
	_load()


func is_loaded() -> bool:
	return load_error.is_empty() and not domains.is_empty()


func get_load_error() -> String:
	return load_error


func get_ownership_id() -> String:
	return ownership_id


func get_version() -> int:
	return version


func get_policy() -> Dictionary:
	return policy.duplicate(true)


func get_domain_ids() -> Array:
	var ids: Array = domains.keys()
	ids.sort()
	return ids


func has_domain(domain_id: String) -> bool:
	return domains.has(domain_id)


func get_domain(domain_id: String) -> Dictionary:
	if not domains.has(domain_id):
		return {}
	return domains[domain_id].duplicate(true)


func get_active_domain_ids() -> Array:
	return _get_domains_by_status(["active", "partial"])


func get_reserved_domain_ids() -> Array:
	return _get_domains_by_status(["reserved_unmodeled"])


func get_invalid_entries() -> Array:
	var invalid: Array = []

	for domain_id in domains.keys():
		var definition = domains[domain_id]

		if typeof(definition) != TYPE_DICTIONARY:
			invalid.append(
				str(domain_id) + " is not a dictionary"
			)
			continue

		for field_name in REQUIRED_FIELDS:
			if not definition.has(field_name):
				invalid.append(
					str(domain_id) + " missing " + field_name
				)
				continue

			var value = definition[field_name]

			if typeof(value) == TYPE_STRING:
				if value.strip_edges().is_empty():
					invalid.append(
						str(domain_id) + " empty " + field_name
					)

		var status := str(definition.get("status", ""))
		if not ALLOWED_STATUS_VALUES.has(status):
			invalid.append(
				str(domain_id) + " invalid status: " + status
			)

		if str(definition.get("canonical_domain", "")) != str(domain_id):
			invalid.append(
				str(domain_id) + " canonical_domain mismatch"
			)

		var definition_paths = definition.get(
			"definition_paths",
			[]
		)

		if typeof(definition_paths) != TYPE_ARRAY:
			invalid.append(
				str(domain_id) + " definition_paths must be an array"
			)

		var runtime_systems = definition.get(
			"runtime_systems",
			[]
		)

		if typeof(runtime_systems) != TYPE_ARRAY:
			invalid.append(
				str(domain_id) + " runtime_systems must be an array"
			)

	invalid.sort()
	return invalid


func get_domains_missing_from(
	expected_domain_ids: Array
) -> Array:

	var missing: Array = []

	for raw_domain_id in expected_domain_ids:
		var domain_id := str(raw_domain_id)

		if domain_id.is_empty():
			continue

		if not has_domain(domain_id):
			missing.append(domain_id)

	missing.sort()
	return missing


func get_duplicate_canonical_domains() -> Array:
	var seen: Dictionary = {}
	var duplicates: Array = []

	for domain_id in domains.keys():
		var canonical_domain := str(
			domains[domain_id].get(
				"canonical_domain",
				""
			)
		)

		if canonical_domain.is_empty():
			continue

		if seen.has(canonical_domain):
			duplicates.append(canonical_domain)
		else:
			seen[canonical_domain] = true

	duplicates.sort()
	return duplicates


func get_invalid_definition_paths() -> Array:
	var invalid: Array = []

	for domain_id in domains.keys():
		var definition = domains[domain_id]
		var paths = definition.get("definition_paths", [])

		if typeof(paths) != TYPE_ARRAY:
			continue

		for raw_path in paths:
			var path := str(raw_path)

			if path.is_empty():
				continue

			if not path.begins_with("res://"):
				invalid.append(
					str(domain_id)
					+ " -> "
					+ path
					+ " is not a res:// path"
				)

	invalid.sort()
	return invalid


func _load() -> void:
	ownership_id = ""
	version = 0
	policy = {}
	domains = {}
	load_error = ""

	if not FileAccess.file_exists(OWNERSHIP_PATH):
		load_error = (
			"DomainOwnershipRegistry: file not found: "
			+ OWNERSHIP_PATH
		)
		return

	var file := FileAccess.open(
		OWNERSHIP_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"DomainOwnershipRegistry: could not open file."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"DomainOwnershipRegistry: root must be a dictionary."
		)
		return

	ownership_id = str(
		parsed.get(
			"ownership_id",
			""
		)
	)

	version = int(
		parsed.get(
			"version",
			0
		)
	)

	var parsed_policy = parsed.get(
		"policy",
		{}
	)

	if typeof(parsed_policy) == TYPE_DICTIONARY:
		policy = parsed_policy.duplicate(true)

	var parsed_domains = parsed.get(
		"domains",
		{}
	)

	if typeof(parsed_domains) != TYPE_DICTIONARY:
		load_error = (
			"DomainOwnershipRegistry: 'domains' must be a dictionary."
		)
		return

	domains = parsed_domains.duplicate(true)


func _get_domains_by_status(
	statuses: Array
) -> Array:

	var result: Array = []

	for domain_id in domains.keys():
		var status := str(
			domains[domain_id].get(
				"status",
				""
			)
		)

		if statuses.has(status):
			result.append(str(domain_id))

	result.sort()
	return result
