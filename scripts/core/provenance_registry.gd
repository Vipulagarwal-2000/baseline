class_name ProvenanceRegistry
extends RefCounted


const PROVENANCE_PATH := "res://data/provenance_registry.json"
const INVENTORY_PATH := "res://data/data_inventory.json"

const REQUIRED_RECORD_FIELDS: Array = [
	"path",
	"domain",
	"asset_type",
	"provenance_status",
	"origin_type",
	"origin_description",
	"source_reference",
	"source_version",
	"as_of_date",
	"transformation",
	"attribution",
	"license",
	"notes"
]

const ALLOWED_PROVENANCE_STATUSES: Array = [
	"architecture_control",
	"verified_internal",
	"validation_support",
	"unattributed_baseline",
	"externally_verified"
]

const ALLOWED_ORIGIN_TYPES: Array = [
	"internal_architecture",
	"internal_domain_catalog",
	"validation_support",
	"existing_project_baseline",
	"derived_internal",
	"external_source",
	"generated_registry"
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
		if _normalize_path(
			str(record.get("path", ""))
		) == normalized_path:
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
			invalid.append(
				"record["
				+ str(index)
				+ "] is not a dictionary"
			)
			continue

		for field_name in REQUIRED_RECORD_FIELDS:
			if not record.has(field_name):
				invalid.append(
					"record["
					+ str(index)
					+ "] missing "
					+ field_name
				)

		var path := _normalize_path(
			str(record.get("path", ""))
		)

		if path.is_empty():
			invalid.append(
				"record["
				+ str(index)
				+ "] empty path"
			)
		elif seen_paths.has(path):
			invalid.append(
				"duplicate provenance path: "
				+ path
			)
		else:
			seen_paths[path] = true

		if not path.begins_with("res://data/"):
			invalid.append(
				path
				+ " outside data root"
			)

		var status := str(
			record.get(
				"provenance_status",
				""
			)
		)

		if not ALLOWED_PROVENANCE_STATUSES.has(status):
			invalid.append(
				path
				+ " invalid provenance_status: "
				+ status
			)

		var origin_type := str(
			record.get(
				"origin_type",
				""
			)
		)

		if not ALLOWED_ORIGIN_TYPES.has(origin_type):
			invalid.append(
				path
				+ " invalid origin_type: "
				+ origin_type
			)

		if str(
			record.get(
				"origin_description",
				""
			)
		).strip_edges().is_empty():
			invalid.append(
				path + " empty origin_description"
			)

		var source_reference := str(
			record.get(
				"source_reference",
				""
			)
		).strip_edges()

		if (
			origin_type == "external_source"
			and source_reference.is_empty()
		):
			invalid.append(
				path
				+ " external source requires source_reference"
			)

		if str(
			record.get(
				"as_of_date",
				""
			)
		).strip_edges().is_empty():
			invalid.append(
				path + " empty as_of_date"
			)
		elif not _is_iso_date(
			str(record.get("as_of_date", ""))
		):
			invalid.append(
				path + " invalid as_of_date"
			)

		if str(
			record.get(
				"license",
				""
			)
		).strip_edges().is_empty():
			invalid.append(
				path + " empty license state"
			)

		if (
			status == "externally_verified"
			and origin_type != "external_source"
		):
			invalid.append(
				path
				+ " externally_verified status requires external_source origin_type"
			)

	invalid.sort()
	return invalid


func get_missing_source_paths() -> Array:
	var missing: Array = []

	for record in records:
		var path := _normalize_path(
			str(record.get("path", ""))
		)

		if path.is_empty():
			continue

		if not FileAccess.file_exists(path):
			missing.append(path)

	missing.sort()
	return missing


func get_missing_inventory_paths() -> Array:
	var missing: Array = []
	var inventory_paths := _load_inventory_paths()
	var provenance_paths := _record_paths()

	for path in inventory_paths:
		if not provenance_paths.has(path):
			missing.append(path)

	missing.sort()
	return missing


func get_extra_provenance_paths() -> Array:
	var extra: Array = []
	var inventory_paths := _load_inventory_paths()

	for path in _record_paths().keys():
		if not inventory_paths.has(path):
			extra.append(str(path))

	extra.sort()
	return extra


func get_inventory_metadata_mismatches() -> Array:
	var mismatches: Array = []
	var inventory_by_path := _load_inventory_entries()

	for record in records:
		var path := _normalize_path(
			str(record.get("path", ""))
		)

		if not inventory_by_path.has(path):
			continue

		var inventory_entry: Dictionary = inventory_by_path[path]

		var inventory_domain := str(
			inventory_entry.get(
				"domain",
				""
			)
		)

		var provenance_domain := str(
			record.get(
				"domain",
				""
			)
		)

		if inventory_domain != provenance_domain:
			mismatches.append(
				path
				+ " domain mismatch: inventory="
				+ inventory_domain
				+ " provenance="
				+ provenance_domain
			)

		var inventory_asset_type := str(
			inventory_entry.get(
				"asset_type",
				""
			)
		)

		var provenance_asset_type := str(
			record.get(
				"asset_type",
				""
			)
		)

		if inventory_asset_type != provenance_asset_type:
			mismatches.append(
				path
				+ " asset_type mismatch: inventory="
				+ inventory_asset_type
				+ " provenance="
				+ provenance_asset_type
			)

	mismatches.sort()
	return mismatches


func get_status_counts() -> Dictionary:
	var counts: Dictionary = {}

	for status in ALLOWED_PROVENANCE_STATUSES:
		counts[status] = 0

	for record in records:
		var status := str(
			record.get(
				"provenance_status",
				""
			)
		)

		if not counts.has(status):
			counts[status] = 0

		counts[status] = int(counts[status]) + 1

	return counts


func _load() -> void:
	version = 0
	registry_id = ""
	policy = {}
	records = []
	load_error = ""

	if not FileAccess.file_exists(PROVENANCE_PATH):
		load_error = (
			"ProvenanceRegistry: file not found: "
			+ PROVENANCE_PATH
		)
		return

	var file := FileAccess.open(
		PROVENANCE_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"ProvenanceRegistry: could not open file."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"ProvenanceRegistry: root must be a dictionary."
		)
		return

	version = int(
		parsed.get(
			"version",
			0
		)
	)

	registry_id = str(
		parsed.get(
			"registry_id",
			""
		)
	)

	var parsed_policy = parsed.get(
		"policy",
		{}
	)

	if typeof(parsed_policy) == TYPE_DICTIONARY:
		policy = parsed_policy.duplicate(true)

	var parsed_records = parsed.get(
		"records",
		[]
	)

	if typeof(parsed_records) != TYPE_ARRAY:
		load_error = (
			"ProvenanceRegistry: 'records' must be an array."
		)
		return

	records = parsed_records.duplicate(true)


func _load_inventory_paths() -> Dictionary:
	var paths: Dictionary = {}
	var entries := _load_inventory_entries()

	for path in entries.keys():
		paths[str(path)] = true

	return paths


func _load_inventory_entries() -> Dictionary:
	var entries_by_path: Dictionary = {}

	if not FileAccess.file_exists(INVENTORY_PATH):
		return entries_by_path

	var file := FileAccess.open(
		INVENTORY_PATH,
		FileAccess.READ
	)

	if file == null:
		return entries_by_path

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return entries_by_path

	var parsed_entries = parsed.get(
		"entries",
		[]
	)

	if typeof(parsed_entries) != TYPE_ARRAY:
		return entries_by_path

	for entry in parsed_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var path := _normalize_path(
			str(entry.get("path", ""))
		)

		if path.is_empty():
			continue

		entries_by_path[path] = entry.duplicate(true)

	return entries_by_path


func _record_paths() -> Dictionary:
	var paths: Dictionary = {}

	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue

		var path := _normalize_path(
			str(record.get("path", ""))
		)

		if path.is_empty():
			continue

		paths[path] = true

	return paths


func _normalize_path(path: String) -> String:
	var normalized := path.strip_edges()

	if normalized.is_empty():
		return ""

	if normalized.begins_with("res://"):
		return normalized

	if normalized.begins_with("data/"):
		return "res://" + normalized

	return normalized


func _is_iso_date(value: String) -> bool:
	if value.length() != 10:
		return false

	if value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
		return false

	for index in [0, 1, 2, 3, 5, 6, 8, 9]:
		var character := value.substr(index, 1)
		if character < "0" or character > "9":
			return false

	return true
