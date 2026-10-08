class_name ResearchProgramCatalog
extends RefCounted


const CATALOG_PATH: String = (
	"res://data/research_programs/research_program_catalog.json"
)

var programs: Dictionary = {}
var semantic_contract: Dictionary = {}
var catalog_version: int = 0
var catalog_id: String = ""
var load_error: String = ""


func _init() -> void:
	_load_catalog()


func is_loaded() -> bool:
	return (
		load_error.is_empty()
		and catalog_version > 0
		and not catalog_id.is_empty()
	)


func get_load_error() -> String:
	return load_error


func get_catalog_version() -> int:
	return catalog_version


func get_catalog_id() -> String:
	return catalog_id


func get_semantic_contract() -> Dictionary:
	return semantic_contract.duplicate(true)


func has_program(program_id: String) -> bool:
	return programs.has(program_id)


func get_program(program_id: String) -> Dictionary:
	if not programs.has(program_id):
		return {}

	var definition: Variant = programs[program_id]
	if typeof(definition) != TYPE_DICTIONARY:
		return {}

	return (definition as Dictionary).duplicate(true)


func get_program_ids() -> Array:
	var ids: Array = programs.keys()
	ids.sort()
	return ids


func get_program_count() -> int:
	return programs.size()


func get_unknown_program_ids(program_ids: Array) -> Array:
	var unknown: Array = []

	for raw_id in program_ids:
		var program_id: String = str(raw_id)

		if program_id.is_empty():
			continue

		if not has_program(program_id):
			unknown.append(program_id)

	unknown.sort()
	return unknown


func _load_catalog() -> void:
	programs = {}
	semantic_contract = {}
	catalog_version = 0
	catalog_id = ""
	load_error = ""

	if not FileAccess.file_exists(CATALOG_PATH):
		load_error = (
			"ResearchProgramCatalog: Catalog file not found: "
			+ CATALOG_PATH
		)
		return

	var file: FileAccess = FileAccess.open(
		CATALOG_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"ResearchProgramCatalog: Could not open catalog."
		)
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"ResearchProgramCatalog: Catalog root must be a dictionary."
		)
		return

	var root: Dictionary = parsed as Dictionary

	var parsed_version: Variant = root.get("version", 0)

	if (
		typeof(parsed_version) != TYPE_INT
		and typeof(parsed_version) != TYPE_FLOAT
	):
		load_error = (
			"ResearchProgramCatalog: 'version' must be numeric."
		)
		return

	catalog_version = int(parsed_version)

	if catalog_version < 1:
		load_error = (
			"ResearchProgramCatalog: 'version' must be positive."
		)
		return

	var parsed_catalog_id: Variant = root.get(
		"catalog_id",
		""
	)

	catalog_id = str(parsed_catalog_id)

	if catalog_id.is_empty():
		load_error = (
			"ResearchProgramCatalog: 'catalog_id' must be non-empty."
		)
		return

	var parsed_contract: Variant = root.get(
		"semantic_contract",
		{}
	)

	if typeof(parsed_contract) != TYPE_DICTIONARY:
		load_error = (
			"ResearchProgramCatalog: "
			+ "'semantic_contract' must be a dictionary."
		)
		return

	semantic_contract = (
		parsed_contract as Dictionary
	).duplicate(true)

	var parsed_programs: Variant = root.get(
		"programs",
		{}
	)

	if typeof(parsed_programs) != TYPE_DICTIONARY:
		load_error = (
			"ResearchProgramCatalog: "
			+ "'programs' must be a dictionary."
		)
		return

	var program_map: Dictionary = parsed_programs as Dictionary

	for raw_id in program_map.keys():
		var program_id: String = str(raw_id)
		var raw_definition: Variant = program_map[raw_id]

		if typeof(raw_definition) != TYPE_DICTIONARY:
			load_error = (
				"ResearchProgramCatalog: Invalid definition for "
				+ program_id
			)
			return

		programs[program_id] = (
			raw_definition as Dictionary
		).duplicate(true)
