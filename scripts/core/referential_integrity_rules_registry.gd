class_name ReferentialIntegrityRulesRegistry
extends RefCounted


const RULES_PATH := "res://data/referential_integrity_rules.json"

const REQUIRED_RULE_FIELDS: Array = [
	"rule_id",
	"source_domain",
	"source_paths",
	"selector",
	"mode",
	"target_domain",
	"description"
]

const ALLOWED_MODES: Array = [
	"value",
	"map_keys",
	"root_map_keys",
	"array_item_field",
	"array_map_keys",
	"nested_root_map_keys",
	"array_item_field_nested"
]


var version: int = 0
var registry_id: String = ""
var policy: Dictionary = {}
var rules: Array = []
var load_error: String = ""


func _init() -> void:
	_load()


func is_loaded() -> bool:
	return load_error.is_empty() and not rules.is_empty()


func get_load_error() -> String:
	return load_error


func get_version() -> int:
	return version


func get_registry_id() -> String:
	return registry_id


func get_policy() -> Dictionary:
	return policy.duplicate(true)


func get_rules() -> Array:
	return rules.duplicate(true)


func get_rule_count() -> int:
	return rules.size()


func get_invalid_rules() -> Array:
	var invalid: Array = []
	var seen_ids: Dictionary = {}

	for index in range(rules.size()):
		var rule = rules[index]

		if typeof(rule) != TYPE_DICTIONARY:
			invalid.append(
				"rule[" + str(index) + "] is not a dictionary"
			)
			continue

		for field_name in REQUIRED_RULE_FIELDS:
			if not rule.has(field_name):
				invalid.append(
					"rule["
					+ str(index)
					+ "] missing "
					+ field_name
				)

		var rule_id := str(
			rule.get(
				"rule_id",
				""
			)
		)

		if rule_id.is_empty():
			invalid.append(
				"rule[" + str(index) + "] empty rule_id"
			)
		elif seen_ids.has(rule_id):
			invalid.append(
				"duplicate rule_id: "
				+ rule_id
			)
		else:
			seen_ids[rule_id] = true

		var source_paths = rule.get(
			"source_paths",
			[]
		)

		if typeof(source_paths) != TYPE_ARRAY or source_paths.is_empty():
			invalid.append(
				rule_id + " source_paths must be non-empty"
			)

		var mode := str(
			rule.get(
				"mode",
				""
			)
		)

		if not ALLOWED_MODES.has(mode):
			invalid.append(
				rule_id
				+ " invalid mode: "
				+ mode
			)

		if str(
			rule.get(
				"target_domain",
				""
			)
		).is_empty():
			invalid.append(
				rule_id + " empty target_domain"
			)

	invalid.sort()
	return invalid


func get_missing_source_paths() -> Array:
	var missing: Array = []

	for rule in rules:
		var rule_id := str(
			rule.get(
				"rule_id",
				""
			)
		)

		var source_paths = rule.get(
			"source_paths",
			[]
		)

		if typeof(source_paths) != TYPE_ARRAY:
			continue

		for raw_path in source_paths:
			var path := str(raw_path)

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
						rule_id
						+ " -> "
						+ path
					)

	missing.sort()
	return missing


func has_rule(rule_id: String) -> bool:
	for rule in rules:
		if str(
			rule.get(
				"rule_id",
				""
			)
		) == rule_id:
			return true

	return false


func _load() -> void:
	version = 0
	registry_id = ""
	policy = {}
	rules = []
	load_error = ""

	if not FileAccess.file_exists(RULES_PATH):
		load_error = (
			"ReferentialIntegrityRulesRegistry: file not found: "
			+ RULES_PATH
		)
		return

	var file := FileAccess.open(
		RULES_PATH,
		FileAccess.READ
	)

	if file == null:
		load_error = (
			"ReferentialIntegrityRulesRegistry: could not open file."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = (
			"ReferentialIntegrityRulesRegistry: root must be a dictionary."
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

	var parsed_rules = parsed.get(
		"rules",
		[]
	)

	if typeof(parsed_rules) != TYPE_ARRAY:
		load_error = (
			"ReferentialIntegrityRulesRegistry: 'rules' must be an array."
		)
		return

	rules = parsed_rules.duplicate(true)
