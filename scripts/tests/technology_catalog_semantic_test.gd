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
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		if not registry.has_id("technology", technology_id):
			TestLogger.write_line(
				"Technology catalog ID resolves to canonical registry: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var prerequisites_value: Variant = definition.get("prerequisites", [])
		if not _is_string_array(prerequisites_value):
			TestLogger.write_line(
				"Technology prerequisites are canonical string references: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var prerequisites: Array = prerequisites_value as Array
			if _has_duplicates(prerequisites):
				TestLogger.write_line(
					"Technology prerequisites contain no duplicates: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

			for prerequisite_value in prerequisites:
				var prerequisite_id: String = str(prerequisite_value)
				if not catalog.has_technology(prerequisite_id):
					TestLogger.write_line(
						"Technology prerequisite resolves to catalog definition: "
						+ technology_id
						+ " -> "
						+ prerequisite_id
						+ ": FAIL"
					)
					passed = false

		var capabilities_value: Variant = definition.get("capabilities", [])
		if not _is_string_array(capabilities_value):
			TestLogger.write_line(
				"Technology capabilities are non-empty string identifiers: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var capabilities: Array = capabilities_value as Array
			if capabilities.is_empty():
				TestLogger.write_line(
					"Technology capabilities are non-empty: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false
			if _has_duplicates(capabilities):
				TestLogger.write_line(
					"Technology capabilities contain no duplicates: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

		var effects_value: Variant = definition.get("effects", {})
		if typeof(effects_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology effects preserve dictionary semantics: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var effects: Dictionary = effects_value as Dictionary
			for effect_id_value in effects.keys():
				var effect_id: String = str(effect_id_value)
				if effect_id.strip_edges().is_empty():
					TestLogger.write_line(
						"Technology effect identifier is non-empty: "
						+ technology_id
						+ ": FAIL"
					)
					passed = false

		var start_year: int = int(definition.get("historical_start_year", 0))
		var end_year: int = int(definition.get("historical_end_year", 0))
		if start_year <= 0:
			TestLogger.write_line(
				"Technology historical start year is positive: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		if end_year != 0 and end_year < start_year:
			TestLogger.write_line(
				"Technology historical end year is valid or unbounded: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var research_cost: float = float(
			definition.get("research_cost", -1.0)
		)
		if research_cost < 0.0:
			TestLogger.write_line(
				"Technology research cost is non-negative: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var required_level: float = float(
			definition.get("required_technology_level", -1.0)
		)
		if required_level < 0.0:
			TestLogger.write_line(
				"Technology level threshold is non-negative: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

	# The canonical registry intentionally contains advanced_steelmaking as a
	# reference identity owned by the production-process catalog. It is not
	# promoted into the technology definition catalog until a TechnologyData
	# definition exists for it. This test therefore requires the reverse
	# direction (catalog -> canonical IDs) but does not require every canonical
	# technology identity to have a full catalog definition yet.
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
