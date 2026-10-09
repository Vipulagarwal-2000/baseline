class_name PolicyCatalog
extends RefCounted


const CATALOG_PATH: String = "res://data/policies/policy_catalog.json"

var policies: Dictionary = {}
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


func has_policy(policy_id: String) -> bool:
	return policies.has(policy_id)


func get_policy(policy_id: String) -> Dictionary:
	if not policies.has(policy_id):
		return {}

	var definition: Variant = policies[policy_id]
	if typeof(definition) != TYPE_DICTIONARY:
		return {}

	return (definition as Dictionary).duplicate(true)


func get_policy_ids() -> Array:
	var ids: Array = policies.keys()
	ids.sort()
	return ids


func get_policy_count() -> int:
	return policies.size()


func get_unknown_policy_ids(policy_ids: Array) -> Array:
	var unknown: Array = []

	for raw_id in policy_ids:
		var policy_id: String = str(raw_id)
		if policy_id.is_empty():
			continue

		if not has_policy(policy_id):
			unknown.append(policy_id)

	unknown.sort()
	return unknown


func _load_catalog() -> void:
	policies = {}
	semantic_contract = {}
	catalog_version = 0
	catalog_id = ""
	load_error = ""

	if not FileAccess.file_exists(CATALOG_PATH):
		load_error = (
			"PolicyCatalog: Catalog file not found: "
			+ CATALOG_PATH
		)
		return

	var file: FileAccess = FileAccess.open(
		CATALOG_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = "PolicyCatalog: Could not open catalog."
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = "PolicyCatalog: Catalog root must be a dictionary."
		return

	var root: Dictionary = parsed as Dictionary
	var parsed_version: Variant = root.get("version", 0)
	if typeof(parsed_version) != TYPE_INT and typeof(parsed_version) != TYPE_FLOAT:
		load_error = "PolicyCatalog: 'version' must be numeric."
		return

	catalog_version = int(parsed_version)
	if catalog_version < 1:
		load_error = "PolicyCatalog: 'version' must be positive."
		return

	var parsed_catalog_id: Variant = root.get("catalog_id", "")
	catalog_id = str(parsed_catalog_id).strip_edges()
	if catalog_id.is_empty():
		load_error = "PolicyCatalog: 'catalog_id' must be non-empty."
		return

	var parsed_contract: Variant = root.get("semantic_contract", {})
	if typeof(parsed_contract) != TYPE_DICTIONARY:
		load_error = "PolicyCatalog: 'semantic_contract' must be a dictionary."
		return

	semantic_contract = (parsed_contract as Dictionary).duplicate(true)

	var parsed_policies: Variant = root.get("policies", null)
	if typeof(parsed_policies) != TYPE_DICTIONARY:
		load_error = "PolicyCatalog: 'policies' must be a dictionary."
		return

	var policy_map: Dictionary = parsed_policies as Dictionary
	for raw_id in policy_map.keys():
		var policy_id: String = str(raw_id)
		var raw_definition: Variant = policy_map[raw_id]

		if typeof(raw_definition) != TYPE_DICTIONARY:
			load_error = (
				"PolicyCatalog: Invalid definition for "
				+ policy_id
			)
			return

		policies[policy_id] = (
			(raw_definition as Dictionary).duplicate(true)
		)
