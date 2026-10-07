class_name CatalogLoaderOwnershipRegistry
extends RefCounted


const REGISTRY_PATH := "res://data/catalog_loader_ownership.json"
const CANONICAL_IDS_PATH := "res://data/canonical_ids.json"
const DOMAIN_OWNERSHIP_PATH := "res://data/domain_ownership.json"
const CANONICAL_SCHEMAS_PATH := "res://data/canonical_schemas.json"

const REQUIRED_RECORD_FIELDS: Array = [
	"domain",
	"schema_status",
	"ownership_status",
	"ownership_mode",
	"definition_authority",
	"loader_contract",
	"loader_mode",
	"loader_path",
	"source_paths",
	"runtime_authority",
	"notes"
]

const ALLOWED_OWNERSHIP_MODES: Array = [
	"catalog",
	"runtime_definition",
	"reference",
	"reserved_identity_only"
]

const ALLOWED_LOADER_MODES: Array = [
	"explicit_existing_loader",
	"explicit_runtime_definition",
	"catalog_owned_reference_resolution",
	"contract_named_not_dedicated_file",
	"reserved_identity_only"
]

const ALLOWED_AUTHORITY_STATUSES: Array = [
	"active",
	"partial",
	"reserved_unmodeled"
]

var version: int = 0
var registry_id: String = ""
var policy: Dictionary = {}
var records: Array = []
var load_error: String = ""


func _init() -> void:
	_load()


func is_loaded() -> bool:
	return load_error.is_empty() and not records.is_empty()


func get_load_error() -> String:
	return load_error


func get_version() -> int:
	return version


func get_registry_id() -> String:
	return registry_id


func get_policy() -> Dictionary:
	return policy.duplicate(true)


func get_records() -> Array:
	return records.duplicate(true)


func get_record_count() -> int:
	return records.size()


func get_record(domain: String) -> Dictionary:
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		if str(record.get("domain", "")) == domain:
			return record.duplicate(true)
	return {}


func has_record(domain: String) -> bool:
	return not get_record(domain).is_empty()


func get_invalid_records() -> Array:
	var invalid: Array = []
	var seen_domains: Dictionary = {}

	for index in range(records.size()):
		var record = records[index]
		if typeof(record) != TYPE_DICTIONARY:
			invalid.append("record[" + str(index) + "] is not a dictionary")
			continue

		for field_name in REQUIRED_RECORD_FIELDS:
			if not record.has(field_name):
				invalid.append("record[" + str(index) + "] missing " + field_name)

		var domain := str(record.get("domain", ""))
		if domain.is_empty():
			invalid.append("record[" + str(index) + "] empty domain")
		elif seen_domains.has(domain):
			invalid.append("duplicate ownership domain: " + domain)
		else:
			seen_domains[domain] = true

		var schema_status := str(record.get("schema_status", ""))
		if schema_status.is_empty():
			invalid.append(domain + " empty schema_status")

		var ownership_status := str(record.get("ownership_status", ""))
		if not ALLOWED_AUTHORITY_STATUSES.has(ownership_status):
			invalid.append(domain + " invalid ownership_status: " + ownership_status)

		var ownership_mode := str(record.get("ownership_mode", ""))
		if not ALLOWED_OWNERSHIP_MODES.has(ownership_mode):
			invalid.append(domain + " invalid ownership_mode: " + ownership_mode)

		var loader_mode := str(record.get("loader_mode", ""))
		if not ALLOWED_LOADER_MODES.has(loader_mode):
			invalid.append(domain + " invalid loader_mode: " + loader_mode)

		var loader_contract := str(record.get("loader_contract", "")).strip_edges()
		if loader_contract.is_empty():
			invalid.append(domain + " empty loader_contract")
		if loader_contract.to_lower().contains("datamanager"):
			invalid.append(domain + " generic DataManager ownership is forbidden")

		var definition_authority := str(record.get("definition_authority", "")).strip_edges()
		if definition_authority.is_empty():
			invalid.append(domain + " empty definition_authority")

		var runtime_authority := str(record.get("runtime_authority", "")).strip_edges()
		if runtime_authority.is_empty():
			invalid.append(domain + " empty runtime_authority")

		var notes := str(record.get("notes", "")).strip_edges()
		if notes.is_empty():
			invalid.append(domain + " empty notes")

		var source_paths = record.get("source_paths", [])
		if typeof(source_paths) != TYPE_ARRAY:
			invalid.append(domain + " source_paths must be an array")
		else:
			for raw_path in source_paths:
				var path := str(raw_path).strip_edges()
				if path.is_empty():
					invalid.append(domain + " contains empty source path")
				elif not path.begins_with("res://"):
					invalid.append(domain + " source path outside res://: " + path)

		var loader_path := str(record.get("loader_path", "")).strip_edges()
		if not loader_path.is_empty() and not loader_path.begins_with("res://"):
			invalid.append(domain + " loader_path outside res://: " + loader_path)

		if ownership_status == "reserved_unmodeled":
			if ownership_mode != "reserved_identity_only":
				invalid.append(domain + " reserved domain must use reserved_identity_only ownership")
			if loader_mode != "reserved_identity_only":
				invalid.append(domain + " reserved domain must use reserved_identity_only loader mode")
			if not source_paths.is_empty():
				invalid.append(domain + " reserved domain cannot declare source paths")
			if not loader_path.is_empty():
				invalid.append(domain + " reserved domain cannot declare loader_path")

		if ownership_mode == "reference" and loader_mode != "catalog_owned_reference_resolution":
			invalid.append(domain + " reference ownership requires catalog_owned_reference_resolution")

		if loader_mode == "explicit_existing_loader" and loader_path.is_empty():
			invalid.append(domain + " explicit_existing_loader requires loader_path")

		if loader_mode == "explicit_runtime_definition" and loader_path.is_empty():
			invalid.append(domain + " explicit_runtime_definition requires loader_path")

	invalid.sort()
	return invalid


func get_missing_source_paths() -> Array:
	var missing: Array = []

	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		for raw_path in record.get("source_paths", []):
			var path := str(raw_path)
			if path.is_empty():
				continue
			if not FileAccess.file_exists(path):
				missing.append(path)

	var loader_paths_seen: Dictionary = {}
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var loader_path := str(record.get("loader_path", ""))
		if loader_path.is_empty() or loader_paths_seen.has(loader_path):
			continue
		loader_paths_seen[loader_path] = true
		if not FileAccess.file_exists(loader_path):
			missing.append(loader_path)

	missing = _unique_sorted(missing)
	return missing


func get_canonical_domain_mismatches() -> Array:
	var mismatches: Array = []
	var canonical := _load_json_dictionary(CANONICAL_IDS_PATH)
	var domains = canonical.get("domains", {})
	if typeof(domains) != TYPE_DICTIONARY:
		mismatches.append("canonical IDs domains unavailable")
		return mismatches

	var registry_domains: Dictionary = {}
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		registry_domains[str(record.get("domain", ""))] = true

	for domain in domains.keys():
		if not registry_domains.has(str(domain)):
			mismatches.append("missing domain: " + str(domain))

	for domain in registry_domains.keys():
		if not domains.has(domain):
			mismatches.append("extra domain: " + str(domain))

	mismatches.sort()
	return mismatches


func get_schema_mismatches() -> Array:
	var mismatches: Array = []
	var schemas := _load_json_dictionary(CANONICAL_SCHEMAS_PATH)
	var schema_domains = schemas.get("domains", {})
	if typeof(schema_domains) != TYPE_DICTIONARY:
		mismatches.append("canonical schema domains unavailable")
		return mismatches

	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var domain := str(record.get("domain", ""))
		if not schema_domains.has(domain):
			mismatches.append(domain + " missing from canonical schemas")
			continue

		var expected = schema_domains[domain]
		if typeof(expected) != TYPE_DICTIONARY:
			mismatches.append(domain + " canonical schema definition invalid")
			continue

		if str(record.get("schema_status", "")) != str(expected.get("schema_status", "")):
			mismatches.append(domain + " schema_status mismatch")

		var expected_paths: Array = []
		for raw_path in expected.get("source_paths", []):
			expected_paths.append(str(raw_path))
		expected_paths.sort()

		var actual_paths: Array = []
		for raw_path in record.get("source_paths", []):
			actual_paths.append(str(raw_path))
		actual_paths.sort()

		if expected_paths != actual_paths:
			mismatches.append(domain + " source_paths disagree with canonical schema")

	mismatches.sort()
	return mismatches


func get_ownership_status_mismatches() -> Array:
	var mismatches: Array = []
	var ownership := _load_json_dictionary(DOMAIN_OWNERSHIP_PATH)
	var ownership_domains = ownership.get("domains", {})
	if typeof(ownership_domains) != TYPE_DICTIONARY:
		mismatches.append("domain ownership definitions unavailable")
		return mismatches

	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var domain := str(record.get("domain", ""))
		if not ownership_domains.has(domain):
			mismatches.append(domain + " missing from domain ownership registry")
			continue

		var expected = ownership_domains[domain]
		if typeof(expected) != TYPE_DICTIONARY:
			mismatches.append(domain + " domain ownership definition invalid")
			continue

		if str(record.get("ownership_status", "")) != str(expected.get("status", "")):
			mismatches.append(domain + " ownership_status mismatch")

	mismatches.sort()
	return mismatches


func _load() -> void:
	version = 0
	registry_id = ""
	policy = {}
	records = []
	load_error = ""

	var parsed := _load_json_dictionary(REGISTRY_PATH)
	if parsed.is_empty():
		load_error = "Catalog/loader ownership registry could not be loaded."
		return

	version = int(parsed.get("version", 0))
	registry_id = str(parsed.get("registry_id", ""))
	policy = parsed.get("policy", {})
	records = parsed.get("records", [])

	if typeof(policy) != TYPE_DICTIONARY:
		load_error = "Catalog/loader ownership policy must be a dictionary."
		return
	if typeof(records) != TYPE_ARRAY:
		load_error = "Catalog/loader ownership records must be an array."
		records = []


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _unique_sorted(values: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for value in values:
		var text := str(value)
		if text.is_empty() or seen.has(text):
			continue
		seen[text] = true
		result.append(text)
	result.sort()
	return result
