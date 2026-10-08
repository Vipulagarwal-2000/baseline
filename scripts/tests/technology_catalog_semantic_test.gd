class_name TechnologyCatalogSemanticTest
extends RefCounted


static func _is_string_array(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false

	var values: Array = value as Array
	for entry in values:
		if typeof(entry) != TYPE_STRING:
			return false
		if str(entry).strip_edges().is_empty():
			return false

	return true


static func _has_duplicates(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		var key: String = str(value)
		if seen.has(key):
			return true
		seen[key] = true
	return false


static func _is_effect_map(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false

	var effects: Dictionary = value as Dictionary
	for effect_id_value in effects.keys():
		if str(effect_id_value).strip_edges().is_empty():
			return false

	return true


static func _collect_effect_ids(structural_semantics: Dictionary) -> Dictionary:
	var effect_ids: Dictionary = {}
	var categories: Array[String] = [
		"research_effects",
		"production_effects",
		"resource_effects",
		"infrastructure_effects",
		"military_effects",
		"economic_effects"
	]

	for category_name in categories:
		var value: Variant = structural_semantics.get(category_name, {})
		if typeof(value) != TYPE_DICTIONARY:
			continue

		var category: Dictionary = value as Dictionary
		for effect_id_value in category.keys():
			var effect_id: String = str(effect_id_value)
			effect_ids[effect_id] = int(effect_ids.get(effect_id, 0)) + 1

	return effect_ids


static func _validate_structural_semantics(
	technology_id: String,
	definition: Dictionary
) -> bool:
	var passed: bool = true
	var structural_value: Variant = definition.get("structural_semantics", null)

	if typeof(structural_value) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Technology structural semantic profile exists: "
			+ technology_id + ": FAIL"
		)
		return false

	TestLogger.write_line(
		"Technology structural semantic profile exists: "
		+ technology_id + ": PASS"
	)

	var structural_semantics: Dictionary = structural_value as Dictionary
	var domain: String = str(structural_semantics.get("domain", "")).strip_edges()

	if domain.is_empty():
		TestLogger.write_line(
			"Technology structural domain is non-empty: "
			+ technology_id + ": FAIL"
		)
		passed = false

	var effect_categories: Array[String] = [
		"research_effects",
		"production_effects",
		"resource_effects",
		"infrastructure_effects",
		"military_effects",
		"economic_effects"
	]

	for category_name in effect_categories:
		var category_value: Variant = structural_semantics.get(category_name, null)
		if not _is_effect_map(category_value):
			TestLogger.write_line(
				"Technology structural effect category is a valid map: "
				+ technology_id + " -> " + category_name + ": FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Technology structural effect category is a valid map: "
				+ technology_id + " -> " + category_name + ": PASS"
			)

	var partitioned_effects: Dictionary = _collect_effect_ids(structural_semantics)
	var legacy_value: Variant = definition.get("effects", {})

	if typeof(legacy_value) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Technology legacy effects map remains a dictionary: "
			+ technology_id + ": FAIL"
		)
		passed = false
	else:
		var legacy: Dictionary = legacy_value as Dictionary

		for effect_id_value in legacy.keys():
			var effect_id: String = str(effect_id_value)
			var occurrences: int = int(partitioned_effects.get(effect_id, 0))
			if occurrences != 1:
				TestLogger.write_line(
					"Technology legacy effect maps to exactly one structural category: "
					+ technology_id + " -> " + effect_id + ": FAIL"
				)
				passed = false

		for structural_effect_id in partitioned_effects.keys():
			if not legacy.has(str(structural_effect_id)):
				TestLogger.write_line(
					"Technology structural effect introduces no unsupported legacy key: "
					+ technology_id + " -> " + str(structural_effect_id) + ": FAIL"
				)
				passed = false

	for field_name in [
		"research_capacity_requirements",
		"institution_requirements",
		"adoption_requirements"
	]:
		var requirement_value: Variant = structural_semantics.get(field_name, null)
		if typeof(requirement_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology requirement semantics are explicit maps: "
				+ technology_id + " -> " + field_name + ": FAIL"
			)
			passed = false
			continue

		var requirement_map: Dictionary = requirement_value as Dictionary
		if str(requirement_map.get("status", "")).strip_edges().is_empty():
			TestLogger.write_line(
				"Technology requirement semantics declare status: "
				+ technology_id + " -> " + field_name + ": FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Technology requirement semantics declare status: "
				+ technology_id + " -> " + field_name + ": PASS"
			)

	for field_name in ["transition", "obsolescence"]:
		var value: Variant = structural_semantics.get(field_name, null)
		if typeof(value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology " + field_name + " semantics are explicit: "
				+ technology_id + ": FAIL"
			)
			passed = false
			continue

		var semantics: Dictionary = value as Dictionary
		if str(semantics.get("status", "")).strip_edges().is_empty():
			TestLogger.write_line(
				"Technology " + field_name + " semantics declare status: "
				+ technology_id + ": FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Technology " + field_name + " semantics declare status: "
				+ technology_id + ": PASS"
			)

	for field_name in ["affected_processes","replaced_processes"]:
		var list_value: Variant = structural_semantics.get(field_name, null)
		if typeof(list_value) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology process relationship field is an array: "
				+ technology_id + " -> " + field_name + ": FAIL"
			)
			passed = false
			continue

		var process_ids: Array = list_value as Array
		if _has_duplicates(process_ids):
			TestLogger.write_line(
				"Technology process relationship field contains no duplicates: "
				+ technology_id + " -> " + field_name + ": FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Technology process relationship field contains no duplicates: "
				+ technology_id + " -> " + field_name + ": PASS"
			)

		for process_id_value in process_ids:
			if typeof(process_id_value) != TYPE_STRING:
				TestLogger.write_line(
					"Technology process relationship identifiers are strings: "
					+ technology_id + " -> " + field_name + ": FAIL"
				)
				passed = false
			elif str(process_id_value).strip_edges().is_empty():
				TestLogger.write_line(
					"Technology process relationship identifiers are non-empty: "
					+ technology_id + " -> " + field_name + ": FAIL"
				)
				passed = false

	return passed


static func run() -> bool:
	var catalog: TechnologyCatalog = TechnologyCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Technology catalog available for semantic validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	var registry: CanonicalIdRegistry = CanonicalIdRegistry.new()
	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry available for technology semantic validation: FAIL | "
			+ registry.get_load_error()
		)
		return false

	var technology_ids: Array = catalog.get_technology_ids()

	for technology_id_value in technology_ids:
		var technology_id: String = str(technology_id_value)
		var definition: Dictionary = catalog.get_technology(technology_id)

		if not registry.matches_id_format("technology", technology_id):
			TestLogger.write_line(
				"Technology ID format is canonical: "
				+ technology_id + ": FAIL"
			)
			passed = false

		if not registry.has_id("technology", technology_id):
			TestLogger.write_line(
				"Technology catalog ID resolves to canonical registry: "
				+ technology_id + ": FAIL"
			)
			passed = false

		var prerequisites_value: Variant = definition.get("prerequisites", [])
		if not _is_string_array(prerequisites_value):
			TestLogger.write_line(
				"Technology prerequisites are canonical string references: "
				+ technology_id + ": FAIL"
			)
			passed = false
		else:
			var prerequisites: Array = prerequisites_value as Array
			if _has_duplicates(prerequisites):
				TestLogger.write_line(
					"Technology prerequisites contain no duplicates: "
					+ technology_id + ": FAIL"
				)
				passed = false

			for prerequisite_value in prerequisites:
				var prerequisite_id: String = str(prerequisite_value)
				if not catalog.has_technology(prerequisite_id):
					TestLogger.write_line(
						"Technology prerequisite resolves to catalog definition: "
						+ technology_id + " -> " + prerequisite_id + ": FAIL"
					)
					passed = false

		var capabilities_value: Variant = definition.get("capabilities", [])
		if not _is_string_array(capabilities_value):
			TestLogger.write_line(
				"Technology capabilities are non-empty string identifiers: "
				+ technology_id + ": FAIL"
			)
			passed = false
		else:
			var capabilities: Array = capabilities_value as Array
			if capabilities.is_empty():
				TestLogger.write_line(
					"Technology capabilities are non-empty: "
					+ technology_id + ": FAIL"
				)
				passed = false
			if _has_duplicates(capabilities):
				TestLogger.write_line(
					"Technology capabilities contain no duplicates: "
					+ technology_id + ": FAIL"
				)
				passed = false

		var effects_value: Variant = definition.get("effects", {})
		if typeof(effects_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology effects preserve dictionary semantics: "
				+ technology_id + ": FAIL"
			)
			passed = false
		else:
			var effects: Dictionary = effects_value as Dictionary
			for effect_id_value in effects.keys():
				if str(effect_id_value).strip_edges().is_empty():
					TestLogger.write_line(
						"Technology effect identifier is non-empty: "
						+ technology_id + ": FAIL"
					)
					passed = false

		var start_year: int = int(definition.get("historical_start_year", 0))
		var end_year: int = int(definition.get("historical_end_year", 0))
		if start_year <= 0:
			TestLogger.write_line(
				"Technology historical start year is positive: "
				+ technology_id + ": FAIL"
			)
			passed = false

		if end_year != 0 and end_year < start_year:
			TestLogger.write_line(
				"Technology historical end year is valid or unbounded: "
				+ technology_id + ": FAIL"
			)
			passed = false

		var research_cost: float = float(
			definition.get("research_cost", -1.0)
		)
		if research_cost < 0.0:
			TestLogger.write_line(
				"Technology research cost is non-negative: "
				+ technology_id + ": FAIL"
			)
			passed = false

		var required_level: float = float(
			definition.get("required_technology_level", -1.0)
		)
		if required_level < 0.0:
			TestLogger.write_line(
				"Technology level threshold is non-negative: "
				+ technology_id + ": FAIL"
			)
			passed = false

		if not _validate_structural_semantics(
			technology_id,
			definition
		):
			passed = false

	if registry.has_id("technology", "advanced_steelmaking") and not catalog.has_technology("advanced_steelmaking"):
		TestLogger.write_line(
			"Reference-only advanced_steelmaking identity remains outside catalog: PASS"
		)

	if passed:
		TestLogger.write_line(
			"All technology catalog semantic checks: PASS"
		)

	TestLogger.write_line(
		"TechnologyCatalogSemanticTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
