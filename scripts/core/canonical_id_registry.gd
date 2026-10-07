class_name CanonicalIdRegistry
extends RefCounted


const REGISTRY_PATH := "res://data/canonical_ids.json"

var registry: Dictionary = {}
var id_policy: Dictionary = {}
var domains: Dictionary = {}
var load_error: String = ""


func _init() -> void:
	_load_registry()


func is_loaded() -> bool:
	return load_error.is_empty() and not domains.is_empty()


func get_load_error() -> String:
	return load_error


func get_version() -> int:
	return int(registry.get("version", 0))


func get_registry_id() -> String:
	return str(registry.get("registry_id", ""))


func get_id_policy() -> Dictionary:
	return id_policy.duplicate(true)


func get_domains() -> Array:
	var result: Array = domains.keys()
	result.sort()
	return result


func has_domain(domain: String) -> bool:
	return domains.has(domain)


func get_domain_status(domain: String) -> String:
	if not domains.has(domain):
		return ""
	return str(domains[domain].get("status", ""))


func is_domain_reserved_unmodeled(domain: String) -> bool:
	return get_domain_status(domain) == "reserved_unmodeled"


func get_domain_ids(domain: String) -> Array:
	if not domains.has(domain):
		return []

	var entries = domains[domain].get("entries", {})
	if typeof(entries) != TYPE_DICTIONARY:
		return []

	var ids: Array = entries.keys()
	ids.sort()
	return ids


func has_id(domain: String, identifier: String) -> bool:
	if not domains.has(domain):
		return false

	var entries = domains[domain].get("entries", {})
	if typeof(entries) != TYPE_DICTIONARY:
		return false

	return entries.has(identifier)


func get_entry(domain: String, identifier: String) -> Dictionary:
	if not has_id(domain, identifier):
		return {}

	return domains[domain]["entries"][identifier].duplicate(true)


func get_unknown_ids(domain: String, identifiers: Array) -> Array:
	var unknown: Array = []

	for raw_identifier in identifiers:
		var identifier := str(raw_identifier)
		if identifier.is_empty():
			continue

		if not has_id(domain, identifier):
			unknown.append(identifier)

	unknown.sort()
	return unknown


func matches_id_format(domain: String, identifier: String) -> bool:
	if not has_domain(domain):
		return false

	var pattern := str(domains[domain].get("id_pattern", ""))
	if pattern == "^[A-Z]{3}$":
		return _matches_currency_format(identifier)

	return _matches_lower_snake_case(identifier)


func get_entry_count(domain: String) -> int:
	return get_domain_ids(domain).size()


func _load_registry() -> void:
	registry = {}
	id_policy = {}
	domains = {}
	load_error = ""

	if not FileAccess.file_exists(REGISTRY_PATH):
		load_error = (
			"CanonicalIdRegistry: Registry file not found: "
			+ REGISTRY_PATH
		)
		return

	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file == null:
		load_error = "CanonicalIdRegistry: Could not open registry file."
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		load_error = "CanonicalIdRegistry: Registry root must be a dictionary."
		return

	registry = parsed.duplicate(true)

	var parsed_policy = parsed.get("id_policy", {})
	if typeof(parsed_policy) != TYPE_DICTIONARY:
		load_error = "CanonicalIdRegistry: 'id_policy' must be a dictionary."
		registry = {}
		return

	id_policy = parsed_policy.duplicate(true)

	var parsed_domains = parsed.get("domains", {})
	if typeof(parsed_domains) != TYPE_DICTIONARY:
		load_error = "CanonicalIdRegistry: 'domains' must be a dictionary."
		registry = {}
		return

	for domain_name in parsed_domains.keys():
		var definition = parsed_domains[domain_name]
		if typeof(definition) != TYPE_DICTIONARY:
			load_error = (
				"CanonicalIdRegistry: Invalid domain definition: "
				+ str(domain_name)
			)
			return

		var entries = definition.get("entries", {})
		if typeof(entries) != TYPE_DICTIONARY:
			load_error = (
				"CanonicalIdRegistry: Domain entries must be a dictionary: "
				+ str(domain_name)
			)
			return

		domains[str(domain_name)] = definition.duplicate(true)


func _matches_lower_snake_case(identifier: String) -> bool:
	if identifier.is_empty():
		return false

	var previous_was_separator := false

	for index in range(identifier.length()):
		var code := identifier.unicode_at(index)
		var is_lower_alpha := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		var is_separator := code == 95

		if index == 0 and not is_lower_alpha:
			return false

		if is_separator:
			if previous_was_separator:
				return false
			previous_was_separator = true
			continue

		if not is_lower_alpha and not is_digit:
			return false

		previous_was_separator = false

	return not previous_was_separator


func _matches_currency_format(identifier: String) -> bool:
	if identifier.length() != 3:
		return false

	for index in range(identifier.length()):
		var code := identifier.unicode_at(index)
		if code < 65 or code > 90:
			return false

	return true
