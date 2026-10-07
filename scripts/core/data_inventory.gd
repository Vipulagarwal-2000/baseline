class_name DataInventory
extends RefCounted


const DATA_ROOT_PATH := "res://data"
const INVENTORY_PATH := "res://data/data_inventory.json"

const REQUIRED_ENTRY_FIELDS: Array = [
	"path",
	"format",
	"asset_type",
	"domain",
	"scope",
	"source_role",
	"status"
]

var metadata: Dictionary = {}
var entries: Array = []
var expected_families: Array = []
var load_error: String = ""

var _entry_by_path: Dictionary = {}


func _init() -> void:
	_load_inventory()


func is_loaded() -> bool:
	return load_error.is_empty() and not metadata.is_empty()


func get_load_error() -> String:
	return load_error


func get_inventory_path() -> String:
	return INVENTORY_PATH


func get_metadata() -> Dictionary:
	return metadata.duplicate(true)


func get_entries() -> Array:
	return entries.duplicate(true)


func get_expected_families() -> Array:
	return expected_families.duplicate(true)


func get_entry_count() -> int:
	return entries.size()


func has_path(path: String) -> bool:
	return _entry_by_path.has(_normalize_path(path))


func get_entry(path: String) -> Dictionary:
	var normalized_path := _normalize_path(path)

	if not _entry_by_path.has(normalized_path):
		return {}

	return _entry_by_path[normalized_path].duplicate(true)


func get_inventory_paths() -> Array:
	var paths: Array = []

	for entry in entries:
		paths.append(str(entry.get("path", "")))

	paths.sort()
	return paths


func discover_data_files() -> Array:
	var discovered: Array = []

	if not DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(DATA_ROOT_PATH)
	):
		return discovered

	_collect_files(DATA_ROOT_PATH, discovered)

	discovered.sort()
	return discovered


func get_missing_inventory_paths() -> Array:
	var missing: Array = []

	for entry in entries:
		var raw_path := str(entry.get("path", ""))
		var path := _normalize_path(raw_path)

		if path.is_empty():
			continue

		if not FileAccess.file_exists(path):
			missing.append(path)

	missing.sort()
	return missing


func get_untracked_data_files() -> Array:
	var inventory_paths := {}
	for path in get_inventory_paths():
		inventory_paths[_normalize_path(path)] = true

	var untracked: Array = []

	for discovered_path in discover_data_files():
		var normalized_path := _normalize_path(discovered_path)

		if not inventory_paths.has(normalized_path):
			untracked.append(normalized_path)

	untracked.sort()
	return untracked


func get_duplicate_inventory_paths() -> Array:
	var counts: Dictionary = {}

	for entry in entries:
		var path := _normalize_path(
			str(entry.get("path", ""))
		)

		if path.is_empty():
			continue

		counts[path] = int(counts.get(path, 0)) + 1

	var duplicates: Array = []

	for path in counts.keys():
		if int(counts[path]) > 1:
			duplicates.append(str(path))

	duplicates.sort()
	return duplicates


func get_invalid_entries() -> Array:
	var invalid: Array = []

	for index in range(entries.size()):
		var entry = entries[index]

		if typeof(entry) != TYPE_DICTIONARY:
			invalid.append(
				"entry[" + str(index) + "]"
			)
			continue

		for field_name in REQUIRED_ENTRY_FIELDS:
			if not entry.has(field_name):
				invalid.append(
					"entry["
					+ str(index)
					+ "] missing "
					+ field_name
				)
				continue

			if str(entry[field_name]).strip_edges() == "":
				invalid.append(
					"entry["
					+ str(index)
					+ "] empty "
					+ field_name
				)

		var path := _normalize_path(
			str(entry.get("path", ""))
		)

		if not path.begins_with(
			"res://data/"
		):
			invalid.append(
				"entry["
				+ str(index)
				+ "] path outside data root"
			)

	invalid.sort()
	return invalid


func _load_inventory() -> void:
	metadata = {}
	entries = []
	expected_families = []
	load_error = ""
	_entry_by_path = {}

	if not FileAccess.file_exists(INVENTORY_PATH):
		load_error = (
			"DataInventory: Inventory file not found: "
			+ INVENTORY_PATH
		)
		return

	var file := FileAccess.open(
		INVENTORY_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"DataInventory: Could not open inventory file."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"DataInventory: Inventory root must be a dictionary."
		)
		return

	metadata = parsed.duplicate(true)

	var parsed_entries = parsed.get(
		"entries",
		[]
	)

	if typeof(parsed_entries) != TYPE_ARRAY:
		load_error = (
			"DataInventory: 'entries' must be an array."
		)
		metadata = {}
		return

	entries = parsed_entries.duplicate(true)

	var parsed_expected_families = parsed.get(
		"expected_families",
		[]
	)

	if typeof(parsed_expected_families) == TYPE_ARRAY:
		expected_families = (
			parsed_expected_families.duplicate(true)
		)

	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var path := _normalize_path(
			str(entry.get("path", ""))
		)

		if path.is_empty():
			continue

		_entry_by_path[path] = entry.duplicate(true)


func _collect_files(
	current_path: String,
	output: Array
) -> void:

	var directory := DirAccess.open(
		current_path
	)

	if directory == null:
		return

	directory.list_dir_begin()

	while true:

		var file_name := directory.get_next()

		if file_name.is_empty():
			break

		if (
			file_name == "."
			or file_name == ".."
		):
			continue

		if file_name.begins_with("."):
			continue

		var child_path := (
			current_path
			+ "/"
			+ file_name
		)

		if directory.current_is_dir():

			_collect_files(
				child_path,
				output
			)

			continue

		if _should_ignore_file(file_name):
			continue

		var normalized_path := _normalize_path(
			child_path
		)

		if normalized_path == INVENTORY_PATH:
			continue

		output.append(normalized_path)

	directory.list_dir_end()


func _should_ignore_file(
	file_name: String
) -> bool:

	var lower_name := file_name.to_lower()

	if lower_name.ends_with(".uid"):
		return true

	if lower_name.ends_with(".tmp"):
		return true

	return false


func _normalize_path(path: String) -> String:
	var normalized := path.strip_edges()

	if normalized.is_empty():
		return ""

	if normalized.begins_with("res://"):
		return normalized

	if normalized.begins_with("data/"):
		return "res://" + normalized

	return normalized
