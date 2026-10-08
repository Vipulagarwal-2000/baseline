class_name TechnologyCatalog
extends RefCounted


const CATALOG_PATH: String = "res://data/technologies/technology_catalog.json"

var technologies: Dictionary = {}
var semantic_contract: Dictionary = {}
var catalog_version: int = 0
var catalog_id: String = ""
var load_error: String = ""


func _init() -> void:
	_load_catalog()


func is_loaded() -> bool:
	return load_error.is_empty() and not technologies.is_empty()


func get_load_error() -> String:
	return load_error


func get_catalog_version() -> int:
	return catalog_version


func get_catalog_id() -> String:
	return catalog_id


func get_semantic_contract() -> Dictionary:
	return semantic_contract.duplicate(true)


func has_technology(technology_id: String) -> bool:
	return technologies.has(technology_id)


func get_technology(technology_id: String) -> Dictionary:
	if not technologies.has(technology_id):
		return {}

	var definition: Variant = technologies[technology_id]
	if typeof(definition) != TYPE_DICTIONARY:
		return {}

	return (definition as Dictionary).duplicate(true)


func get_technology_ids() -> Array:
	var ids: Array = technologies.keys()
	ids.sort()
	return ids


func get_technology_count() -> int:
	return technologies.size()


func get_unknown_technology_ids(technology_ids: Array) -> Array:
	var unknown: Array = []

	for raw_id in technology_ids:
		var technology_id: String = str(raw_id)
		if technology_id.is_empty():
			continue

		if not has_technology(technology_id):
			unknown.append(technology_id)

	unknown.sort()
	return unknown


func _load_catalog() -> void:
	technologies = {}
	semantic_contract = {}
	catalog_version = 0
	catalog_id = ""
	load_error = ""

	if not FileAccess.file_exists(CATALOG_PATH):
		load_error = (
			"TechnologyCatalog: Catalog file not found: "
			+ CATALOG_PATH
		)
		return

	var file: FileAccess = FileAccess.open(
		CATALOG_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = "TechnologyCatalog: Could not open catalog."
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = "TechnologyCatalog: Catalog root must be a dictionary."
		return

	var root: Dictionary = parsed as Dictionary

	var parsed_version: Variant = root.get("version", 0)
	if typeof(parsed_version) != TYPE_INT and typeof(parsed_version) != TYPE_FLOAT:
		load_error = "TechnologyCatalog: 'version' must be numeric."
		return

	catalog_version = int(parsed_version)
	if catalog_version < 1:
		load_error = "TechnologyCatalog: 'version' must be positive."
		return

	var parsed_catalog_id: Variant = root.get("catalog_id", "")
	catalog_id = str(parsed_catalog_id)
	if catalog_id.is_empty():
		load_error = "TechnologyCatalog: 'catalog_id' must be non-empty."
		return

	var parsed_contract: Variant = root.get("semantic_contract", {})
	if typeof(parsed_contract) != TYPE_DICTIONARY:
		load_error = "TechnologyCatalog: 'semantic_contract' must be a dictionary."
		return

	semantic_contract = (parsed_contract as Dictionary).duplicate(true)

	var parsed_technologies: Variant = root.get("technologies", {})
	if typeof(parsed_technologies) != TYPE_DICTIONARY:
		load_error = "TechnologyCatalog: 'technologies' must be a dictionary."
		return

	var technology_map: Dictionary = parsed_technologies as Dictionary
	if technology_map.is_empty():
		load_error = "TechnologyCatalog: 'technologies' must not be empty."
		return

	for raw_id in technology_map.keys():
		var technology_id: String = str(raw_id)
		var raw_definition: Variant = technology_map[raw_id]

		if typeof(raw_definition) != TYPE_DICTIONARY:
			load_error = (
				"TechnologyCatalog: Invalid definition for "
				+ technology_id
			)
			return

		var definition: Dictionary = (raw_definition as Dictionary).duplicate(true)
		technologies[technology_id] = definition
