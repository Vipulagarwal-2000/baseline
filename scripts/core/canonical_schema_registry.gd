class_name CanonicalSchemaRegistry
extends RefCounted


const SCHEMA_PATH := "res://data/canonical_schemas.json"

const REQUIRED_SCHEMA_FIELDS: Array = [
	"schema_status",
	"canonical_domain",
	"identity_field",
	"shape",
	"required_fields",
	"fields",
	"source_kind",
	"source_paths",
	"notes"
]

const ALLOWED_SCHEMA_STATUS: Array = [
	"defined",
	"runtime_contract",
	"reference_contract",
	"reserved_identity_contract"
]

const ALLOWED_SHAPES: Array = [
	"object",
	"object_collection",
	"definition_map",
	"runtime_object",
	"variant_union",
	"reference_scalar"
]


var version: int = 0
var schema_registry_id: String = ""
var policy: Dictionary = {}
var domains: Dictionary = {}
var load_error: String = ""


func _init() -> void:
	_load()


func is_loaded() -> bool:
	return load_error.is_empty() and not domains.is_empty()


func get_load_error() -> String:
	return load_error


func get_version() -> int:
	return version


func get_schema_registry_id() -> String:
	return schema_registry_id


func get_policy() -> Dictionary:
	return policy.duplicate(true)


func get_domain_ids() -> Array:
	var result: Array = domains.keys()
	result.sort()
	return result


func has_domain(domain_id: String) -> bool:
	return domains.has(domain_id)


func get_domain_schema(domain_id: String) -> Dictionary:
	if not domains.has(domain_id):
		return {}

	return domains[domain_id].duplicate(true)


func get_invalid_schema_entries() -> Array:
	var invalid: Array = []

	for domain_id in domains.keys():
		var schema = domains[domain_id]

		if typeof(schema) != TYPE_DICTIONARY:
			invalid.append(
				str(domain_id) + " is not a dictionary"
			)
			continue

		for field_name in REQUIRED_SCHEMA_FIELDS:
			if not schema.has(field_name):
				invalid.append(
					str(domain_id) + " missing " + field_name
				)
				continue

		if str(
			schema.get("canonical_domain", "")
		) != str(domain_id):
			invalid.append(
				str(domain_id) + " canonical_domain mismatch"
			)

		var status := str(
			schema.get(
				"schema_status",
				""
			)
		)

		if not ALLOWED_SCHEMA_STATUS.has(status):
			invalid.append(
				str(domain_id)
				+ " invalid schema_status: "
				+ status
			)

		var shape := str(
			schema.get(
				"shape",
				""
			)
		)

		if not ALLOWED_SHAPES.has(shape):
			invalid.append(
				str(domain_id)
				+ " invalid shape: "
				+ shape
			)

		var identity_field := str(
			schema.get(
				"identity_field",
				""
			)
		)

		if status != "reserved_identity_contract":
			if identity_field.is_empty():
				invalid.append(
					str(domain_id)
					+ " requires an identity_field"
				)

		var required_fields = schema.get(
			"required_fields",
			[]
		)

		if typeof(required_fields) != TYPE_ARRAY:
			invalid.append(
				str(domain_id)
				+ " required_fields must be an array"
			)

		var field_definitions = schema.get(
			"fields",
			{}
		)

		if typeof(field_definitions) != TYPE_DICTIONARY:
			invalid.append(
				str(domain_id)
				+ " fields must be a dictionary"
			)

		var source_paths = schema.get(
			"source_paths",
			[]
		)

		if typeof(source_paths) != TYPE_ARRAY:
			invalid.append(
				str(domain_id)
				+ " source_paths must be an array"
			)

	invalid.sort()
	return invalid


func get_invalid_field_definitions() -> Array:
	var invalid: Array = []

	for domain_id in domains.keys():
		var schema = domains[domain_id]

		if typeof(schema) != TYPE_DICTIONARY:
			continue

		var field_definitions = schema.get(
			"fields",
			{}
		)

		if typeof(field_definitions) != TYPE_DICTIONARY:
			continue

		var required_fields = schema.get(
			"required_fields",
			[]
		)

		if typeof(required_fields) != TYPE_ARRAY:
			continue

		for required_field in required_fields:
			var field_name := str(required_field)

			if not field_definitions.has(field_name):
				invalid.append(
					str(domain_id)
					+ " required field has no definition: "
					+ field_name
				)

		for field_name in field_definitions.keys():
			var definition = field_definitions[field_name]

			if typeof(definition) != TYPE_DICTIONARY:
				invalid.append(
					str(domain_id)
					+ " field is not a dictionary: "
					+ str(field_name)
				)
				continue

			if str(
				definition.get(
					"type",
					""
				)
			).is_empty():
				invalid.append(
					str(domain_id)
					+ " field missing type: "
					+ str(field_name)
				)

			if str(
				definition.get(
					"semantic_type",
					""
				)
			).is_empty():
				invalid.append(
					str(domain_id)
					+ " field missing semantic_type: "
					+ str(field_name)
				)

			if not definition.has("required"):
				invalid.append(
					str(domain_id)
					+ " field missing required flag: "
					+ str(field_name)
				)

	invalid.sort()
	return invalid


func get_missing_domains(
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


func get_source_paths() -> Array:
	var result: Array = []

	for domain_id in domains.keys():
		var schema = domains[domain_id]
		var paths = schema.get(
			"source_paths",
			[]
		)

		if typeof(paths) != TYPE_ARRAY:
			continue

		for raw_path in paths:
			var path := str(raw_path)

			if path.is_empty():
				continue

			result.append({
				"domain": str(domain_id),
				"path": path
			})

	return result


func get_missing_source_paths() -> Array:
	var missing: Array = []

	for item in get_source_paths():
		var domain_id := str(item.get("domain", ""))
		var path := str(item.get("path", ""))

		if path.is_empty():
			continue

		if path.begins_with("res://"):
			if (
				not FileAccess.file_exists(path)
				and not DirAccess.dir_exists_absolute(
					ProjectSettings.globalize_path(path)
				)
			):
				missing.append(
					domain_id
					+ " -> "
					+ path
				)

	missing.sort()
	return missing


func _load() -> void:
	version = 0
	schema_registry_id = ""
	policy = {}
	domains = {}
	load_error = ""

	if not FileAccess.file_exists(SCHEMA_PATH):
		load_error = (
			"CanonicalSchemaRegistry: file not found: "
			+ SCHEMA_PATH
		)
		return

	var file := FileAccess.open(
		SCHEMA_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"CanonicalSchemaRegistry: could not open file."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"CanonicalSchemaRegistry: root must be a dictionary."
		)
		return

	version = int(
		parsed.get(
			"version",
			0
		)
	)

	schema_registry_id = str(
		parsed.get(
			"schema_registry_id",
			""
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
			"CanonicalSchemaRegistry: 'domains' must be a dictionary."
		)
		return

	domains = parsed_domains.duplicate(true)
