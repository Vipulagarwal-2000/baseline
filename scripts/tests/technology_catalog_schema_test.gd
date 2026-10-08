class_name TechnologyCatalogSchemaTest
extends RefCounted


static func run() -> bool:
	var catalog: TechnologyCatalog = TechnologyCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Technology catalog loads: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	TestLogger.write_line("Technology catalog loads: PASS")

	if catalog.get_catalog_version() < 1:
		TestLogger.write_line("Technology catalog version is positive: FAIL")
		passed = false
	else:
		TestLogger.write_line("Technology catalog version is positive: PASS")

	if catalog.get_catalog_id().strip_edges().is_empty():
		TestLogger.write_line("Technology catalog id is non-empty: FAIL")
		passed = false
	else:
		TestLogger.write_line("Technology catalog id is non-empty: PASS")

	var semantic_contract: Dictionary = catalog.get_semantic_contract()
	var required_contract_fields: Array = [
		"identity_semantics",
		"research_cost_semantics",
		"research_duration_semantics",
		"prerequisite_semantics",
		"technology_level_semantics",
		"capability_semantics",
		"effect_semantics",
		"historical_start_semantics",
		"historical_end_semantics",
		"enabled_semantics",
		"effect_values_are_unitless",
		"provenance_semantics",
		"definition_version_semantics"
	]

	for field_name in required_contract_fields:
		if not semantic_contract.has(field_name):
			TestLogger.write_line(
				"Technology semantic contract field present: "
				+ field_name
				+ ": FAIL"
			)
			passed = false

	var required_fields: Array = [
		"id",
		"name",
		"description",
		"research_cost",
		"research_duration_months",
		"prerequisites",
		"required_technology_level",
		"capabilities",
		"effects",
		"historical_start_year",
		"historical_end_year",
		"enabled",
		"provenance",
		"definition_version"
	]

	var technology_ids: Array = catalog.get_technology_ids()
	if technology_ids.is_empty():
		TestLogger.write_line("Technology catalog contains definitions: FAIL")
		return false

	TestLogger.write_line(
		"Technology catalog contains definitions: PASS | count="
		+ str(technology_ids.size())
	)

	for technology_id in technology_ids:
		var definition: Dictionary = catalog.get_technology(str(technology_id))

		for field_name in required_fields:
			if not definition.has(field_name):
				TestLogger.write_line(
					"Technology catalog field present: "
					+ str(technology_id)
					+ " -> "
					+ field_name
					+ ": FAIL"
				)
				passed = false

		var definition_id: String = str(definition.get("id", ""))
		if definition_id != str(technology_id):
			TestLogger.write_line(
				"Technology definition id matches catalog key: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		for text_field in ["id", "name", "description"]:
			var text_value: String = str(definition.get(text_field, ""))
			if text_value.strip_edges().is_empty():
				TestLogger.write_line(
					"Technology text field is non-empty: "
					+ str(technology_id)
					+ " -> "
					+ text_field
					+ ": FAIL"
				)
				passed = false

		for numeric_field in [
			"research_cost",
			"required_technology_level",
			"historical_start_year",
			"historical_end_year"
		]:
			var numeric_value: Variant = definition.get(numeric_field, null)
			if numeric_value == null or (
				typeof(numeric_value) != TYPE_INT
				and typeof(numeric_value) != TYPE_FLOAT
			):
				TestLogger.write_line(
					"Technology numeric field has numeric type: "
					+ str(technology_id)
					+ " -> "
					+ numeric_field
					+ ": FAIL"
				)
				passed = false

		var duration: Variant = definition.get("research_duration_months", null)
		if typeof(duration) != TYPE_INT or int(duration) <= 0:
			TestLogger.write_line(
				"Technology research duration is a positive integer: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		var prerequisites: Variant = definition.get("prerequisites", null)
		if typeof(prerequisites) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology prerequisites are an array: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		var capabilities: Variant = definition.get("capabilities", null)
		if typeof(capabilities) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology capabilities are an array: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		var effects: Variant = definition.get("effects", null)
		if typeof(effects) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology effects are a dictionary: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		var enabled: Variant = definition.get("enabled", null)
		if typeof(enabled) != TYPE_BOOL:
			TestLogger.write_line(
				"Technology enabled flag is boolean: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

		var provenance: Variant = definition.get("provenance", null)
		if typeof(provenance) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology provenance is an object: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false
		else:
			var provenance_map: Dictionary = provenance as Dictionary
			for provenance_field in ["status", "source_reference", "confidence"]:
				if str(provenance_map.get(provenance_field, "")).strip_edges().is_empty():
					TestLogger.write_line(
						"Technology provenance field is non-empty: "
						+ str(technology_id)
						+ " -> "
						+ provenance_field
						+ ": FAIL"
					)
					passed = false

		var definition_version: Variant = definition.get("definition_version", null)
		if (
			typeof(definition_version) != TYPE_INT
			and typeof(definition_version) != TYPE_FLOAT
		) or int(definition_version) < 1:
			TestLogger.write_line(
				"Technology definition version is positive: "
				+ str(technology_id)
				+ ": FAIL"
			)
			passed = false

	if passed:
		TestLogger.write_line("All technology catalog schema checks: PASS")

	TestLogger.write_line(
		"TechnologyCatalogSchemaTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
