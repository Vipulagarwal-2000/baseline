class_name VersioningRegistry
extends RefCounted


const VERSIONING_PATH := "res://data/versioning_registry.json"
const INVENTORY_PATH := "res://data/data_inventory.json"
const PROVENANCE_PATH := "res://data/provenance_registry.json"

const REQUIRED_RECORD_FIELDS: Array = [
	"path",
	"domain",
	"asset_type",
	"version_status",
	"version_label",
	"revision_state",
	"schema_version",
	"introduced_reference",
	"baseline_reference",
	"previous_version",
	"effective_date",
	"lifecycle_status",
	"change_authority",
	"compatibility",
	"notes"
]

const ALLOWED_VERSION_STATUSES: Array = [
	"controlled",
	"baseline_unversioned"
]

const ALLOWED_REVISION_STATES: Array = [
	"controlled",
	"explicit_baseline"
]

const ALLOWED_LIFECYCLE_STATUSES: Array = [
	"active",
	"deprecated",
	"retired"
]

const ALLOWED_COMPATIBILITY_POLICIES: Array = [
	"same_schema_or_explicit_migration_required",
	"breaking_change_requires_migration",
	"metadata_only_change"
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


func get_record(path: String) -> Dictionary:
	var normalized_path := _normalize_path(path)

	for record in records:
		if _normalize_path(str(record.get("path", ""))) == normalized_path:
			return record.duplicate(true)

	return {}


func has_record(path: String) -> bool:
	return not get_record(path).is_empty()


func get_invalid_records() -> Array:
	var invalid: Array = []
	var seen_paths: Dictionary = {}

	for index in range(records.size()):
		var record = records[index]

		if typeof(record) != TYPE_DICTIONARY:
			invalid.append("record[" + str(index) + "] is not a dictionary")
			continue

		for field_name in REQUIRED_RECORD_FIELDS:
			if not record.has(field_name):
				invalid.append(
					"record[" + str(index) + "] missing " + field_name
				)

		var path := _normalize_path(str(record.get("path", "")))

		if path.is_empty():
			invalid.append("record[" + str(index) + "] empty path")
		elif seen_paths.has(path):
			invalid.append("duplicate versioning path: " + path)
		else:
			seen_paths[path] = true

		if not path.begins_with("res://data/"):
			invalid.append(path + " outside data root")

		var status := str(record.get("version_status", ""))
		if not ALLOWED_VERSION_STATUSES.has(status):
			invalid.append(path + " invalid version_status: " + status)

		var revision_state := str(record.get("revision_state", ""))
		if not ALLOWED_REVISION_STATES.has(revision_state):
			invalid.append(path + " invalid revision_state: " + revision_state)

		var schema_version = record.get("schema_version", null)
		var schema_version_valid := false
		if typeof(schema_version) == TYPE_INT:
			schema_version_valid = int(schema_version) >= 1
		elif typeof(schema_version) == TYPE_FLOAT:
			var schema_version_int := int(schema_version)
			schema_version_valid = (
				schema_version_int >= 1
				and is_equal_approx(
					float(schema_version),
					float(schema_version_int)
				)
			)

		if not schema_version_valid:
			invalid.append(path + " schema_version must be a positive integer")

		var version_label := str(record.get("version_label", "")).strip_edges()
		if version_label.is_empty():
			invalid.append(path + " empty version_label")
		elif status == "controlled" and not _is_semver(version_label):
			invalid.append(path + " controlled asset requires semantic version label")
		elif status == "baseline_unversioned" and version_label != "baseline":
			invalid.append(path + " baseline_unversioned asset must use version_label=baseline")

		var previous_version = record.get("previous_version", null)
		if previous_version != null and str(previous_version).strip_edges().is_empty():
			invalid.append(path + " previous_version cannot be an empty string")

		if status == "controlled" and previous_version != null:
			invalid.append(path + " initial controlled record must have null previous_version")

		if str(record.get("introduced_reference", "")).strip_edges().is_empty():
			invalid.append(path + " empty introduced_reference")

		if str(record.get("baseline_reference", "")).strip_edges().is_empty():
			invalid.append(path + " empty baseline_reference")

		if str(record.get("effective_date", "")).strip_edges().is_empty():
			invalid.append(path + " empty effective_date")
		elif not _is_iso_date(str(record.get("effective_date", ""))):
			invalid.append(path + " invalid effective_date")

		var lifecycle := str(record.get("lifecycle_status", ""))
		if not ALLOWED_LIFECYCLE_STATUSES.has(lifecycle):
			invalid.append(path + " invalid lifecycle_status: " + lifecycle)

		if str(record.get("change_authority", "")).strip_edges().is_empty():
			invalid.append(path + " empty change_authority")

		var compatibility := str(record.get("compatibility", ""))
		if not ALLOWED_COMPATIBILITY_POLICIES.has(compatibility):
			invalid.append(path + " invalid compatibility: " + compatibility)

		if str(record.get("notes", "")).strip_edges().is_empty():
			invalid.append(path + " empty notes")

		if status == "controlled" and revision_state != "controlled":
			invalid.append(path + " controlled status requires controlled revision_state")

		if status == "baseline_unversioned" and revision_state != "explicit_baseline":
			invalid.append(path + " baseline_unversioned requires explicit_baseline revision_state")

	invalid.sort()
	return invalid


func get_missing_source_paths() -> Array:
	var missing: Array = []

	for record in records:
		var path := _normalize_path(str(record.get("path", "")))
		if path.is_empty():
			continue
		if not FileAccess.file_exists(path):
			missing.append(path)

	missing.sort()
	return missing


func get_missing_inventory_paths() -> Array:
	var missing: Array = []
	var inventory_paths := _load_inventory_paths()
	var versioning_paths := _record_paths()

	for path in inventory_paths:
		if not versioning_paths.has(path):
			missing.append(path)

	missing.sort()
	return missing


func get_extra_versioning_paths() -> Array:
	var extra: Array = []
	var inventory_paths := _load_inventory_paths()

	for path in _record_paths().keys():
		if not inventory_paths.has(path):
			extra.append(str(path))

	extra.sort()
	return extra


func get_inventory_mismatches() -> Array:
	var mismatches: Array = []
	var inventory := _load_inventory()
	if inventory.is_empty():
		mismatches.append("inventory could not be loaded")
		return mismatches

	var inventory_by_path: Dictionary = {}
	for item in inventory.get("entries", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		inventory_by_path[_normalize_path(str(item.get("path", "")))] = item

	for record in records:
		var path := _normalize_path(str(record.get("path", "")))
		if not inventory_by_path.has(path):
			continue
		var inventory_entry: Dictionary = inventory_by_path[path]
		if str(record.get("domain", "")) != str(inventory_entry.get("domain", "")):
			mismatches.append(path + " domain mismatch")
		if str(record.get("asset_type", "")) != str(inventory_entry.get("asset_type", "")):
			mismatches.append(path + " asset_type mismatch")

	mismatches.sort()
	return mismatches


func get_provenance_baseline_mismatches() -> Array:
	var mismatches: Array = []
	if not FileAccess.file_exists(PROVENANCE_PATH):
		mismatches.append("provenance registry missing")
		return mismatches

	var file := FileAccess.open(PROVENANCE_PATH, FileAccess.READ)
	if file == null:
		mismatches.append("provenance registry could not be opened")
		return mismatches

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		mismatches.append("provenance registry is not a dictionary")
		return mismatches

	var provenance_by_path: Dictionary = {}
	for record in parsed.get("records", []):
		if typeof(record) != TYPE_DICTIONARY:
			continue
		provenance_by_path[_normalize_path(str(record.get("path", "")))] = record

	for record in records:
		var path := _normalize_path(str(record.get("path", "")))
		if not provenance_by_path.has(path):
			mismatches.append(path + " missing provenance record")
			continue

		var provenance_record: Dictionary = provenance_by_path[path]
		var expected_reference := str(provenance_record.get("source_version", ""))
		var actual_reference := str(record.get("baseline_reference", ""))
		if expected_reference != actual_reference:
			mismatches.append(path + " baseline_reference disagrees with provenance")

	mismatches.sort()
	return mismatches


func _load() -> void:
	load_error = ""
	version = 0
	registry_id = ""
	policy = {}
	records = []

	if not FileAccess.file_exists(VERSIONING_PATH):
		load_error = "Versioning registry file not found: " + VERSIONING_PATH
		return

	var file := FileAccess.open(VERSIONING_PATH, FileAccess.READ)
	if file == null:
		load_error = "Unable to open versioning registry: " + VERSIONING_PATH
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = "Versioning registry root is not a dictionary"
		return

	version = int(parsed.get("version", 0))
	registry_id = str(parsed.get("registry_id", ""))
	policy = parsed.get("policy", {})
	records = parsed.get("records", [])

	if typeof(policy) != TYPE_DICTIONARY:
		load_error = "Versioning registry policy is not a dictionary"
		return

	if typeof(records) != TYPE_ARRAY:
		load_error = "Versioning registry records is not an array"
		records = []


func _load_inventory() -> Dictionary:
	if not FileAccess.file_exists(INVENTORY_PATH):
		return {}

	var file := FileAccess.open(INVENTORY_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _load_inventory_paths() -> Dictionary:
	var paths: Dictionary = {}
	var inventory := _load_inventory()

	for entry in inventory.get("entries", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var path := _normalize_path(str(entry.get("path", "")))
		if not path.is_empty():
			paths[path] = true

	return paths


func _record_paths() -> Dictionary:
	var paths: Dictionary = {}

	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var path := _normalize_path(str(record.get("path", "")))
		if not path.is_empty():
			paths[path] = true

	return paths


func _normalize_path(path: String) -> String:
	var value := path.strip_edges().replace("\\", "/")
	if value.begins_with("res://"):
		return value
	if value.begins_with("data/"):
		return "res://" + value
	return value


func _is_iso_date(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^\\d{4}-\\d{2}-\\d{2}$")
	return regex.search(value) != null


func _is_semver(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^v?\\d+\\.\\d+\\.\\d+$")
	return regex.search(value) != null
