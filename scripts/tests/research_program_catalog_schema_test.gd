class_name ResearchProgramCatalogSchemaTest
extends RefCounted


static func _is_numeric(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_INT
		or typeof(value) == TYPE_FLOAT
	)


static func _is_positive_whole_number(value: Variant) -> bool:
	if not _is_numeric(value):
		return false

	var numeric_value: float = float(value)
	return numeric_value > 0.0 and is_equal_approx(
		numeric_value,
		floor(numeric_value)
	)


static func _is_string_array(
	value: Variant,
	allow_empty: bool = true
) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false

	var values: Array = value as Array
	if not allow_empty and values.is_empty():
		return false

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
	var catalog: ResearchProgramCatalog = ResearchProgramCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Research program catalog loads: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	TestLogger.write_line("Research program catalog loads: PASS")

	if catalog.get_catalog_version() < 2:
		TestLogger.write_line("Research program catalog content schema version is at least 2: FAIL")
		passed = false
	else:
		TestLogger.write_line("Research program catalog content schema version is at least 2: PASS")

	if catalog.get_catalog_id().strip_edges().is_empty():
		TestLogger.write_line("Research program catalog id is non-empty: FAIL")
		passed = false
	else:
		TestLogger.write_line("Research program catalog id is non-empty: PASS")

	var semantic_contract: Dictionary = catalog.get_semantic_contract()
	var required_contract_fields: Array = [
		"identity_semantics",
		"target_semantics",
		"eligibility_semantics",
		"progress_semantics",
		"execution_semantics",
		"completion_semantics",
		"activation_semantics",
		"provenance_semantics",
		"definition_version_semantics",
		"research_cost_semantics",
		"research_duration_semantics",
		"research_capacity_requirement_semantics",
		"research_funding_requirement_semantics",
		"researcher_requirement_semantics",
		"institution_requirement_semantics",
		"prerequisite_semantics",
		"technology_output_semantics",
		"actor_eligibility_semantics",
		"aggregation_semantics",
		"threshold_provenance_semantics",
		"technology_gate_semantics"
	]

	for field_name_value in required_contract_fields:
		var field_name: String = str(field_name_value)
		if not semantic_contract.has(field_name):
			TestLogger.write_line(
				"Research program semantic contract field present: "
				+ field_name
				+ ": FAIL"
			)
			passed = false

	var program_ids: Array = catalog.get_program_ids()
	if program_ids.size() != 6:
		TestLogger.write_line(
			"Phase 4.5B contains six canonical research programs: FAIL | count="
			+ str(program_ids.size())
		)
		passed = false
	else:
		TestLogger.write_line("Phase 4.5B contains six canonical research programs: PASS")

	if program_ids.is_empty():
		TestLogger.write_line("Research program catalog contains definitions: FAIL")
		return false

	var required_fields: Array = [
		"id",
		"name",
		"description",
		"domain",
		"prerequisites",
		"research_cost",
		"research_duration_months",
		"research_capacity_requirement",
		"research_funding_requirement",
		"researcher_requirement",
		"institution_requirement",
		"technology_outputs",
		"authority_eligibility",
		"enabled",
		"provenance",
		"definition_version"
	]

	for program_id_value in program_ids:
		var program_id: String = str(program_id_value)
		var definition: Dictionary = catalog.get_program(program_id)

		if definition.is_empty():
			TestLogger.write_line(
				"Research program definition is a readable dictionary: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
			continue

		for field_name_value in required_fields:
			var field_name: String = str(field_name_value)
			if not definition.has(field_name):
				TestLogger.write_line(
					"Research program required field exists: "
					+ program_id
					+ " -> "
					+ field_name
					+ ": FAIL"
				)
				passed = false

		var definition_id: String = str(definition.get("id", ""))
		if definition_id != program_id:
			TestLogger.write_line(
				"Research program definition id matches catalog key: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		for text_field_value in ["id", "name", "description", "domain"]:
			var text_field: String = str(text_field_value)
			var text_value: String = str(definition.get(text_field, ""))
			if text_value.strip_edges().is_empty():
				TestLogger.write_line(
					"Research program text field is non-empty: "
					+ program_id
					+ " -> "
					+ text_field
					+ ": FAIL"
				)
				passed = false

		var prerequisites_value: Variant = definition.get("prerequisites", null)
		if not _is_string_array(prerequisites_value):
			TestLogger.write_line(
				"Research program prerequisites are a string array: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
		elif _has_duplicates(prerequisites_value as Array):
			TestLogger.write_line(
				"Research program prerequisites contain no duplicates: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		var outputs_value: Variant = definition.get("technology_outputs", null)
		if not _is_string_array(outputs_value, false):
			TestLogger.write_line(
				"Research program technology outputs are a non-empty string array: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
		elif _has_duplicates(outputs_value as Array):
			TestLogger.write_line(
				"Research program technology outputs contain no duplicates: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		for numeric_field_value in [
			"research_cost",
			"research_capacity_requirement",
			"research_funding_requirement",
			"researcher_requirement",
			"institution_requirement"
		]:
			var numeric_field: String = str(numeric_field_value)
			var numeric_value: Variant = definition.get(numeric_field, null)
			if not _is_numeric(numeric_value) or float(numeric_value) <= 0.0:
				TestLogger.write_line(
					"Research program field is positive numeric: "
					+ program_id
					+ " -> "
					+ numeric_field
					+ ": FAIL"
				)
				passed = false

		var duration_value: Variant = definition.get("research_duration_months", null)
		if not _is_positive_whole_number(duration_value):
			TestLogger.write_line(
				"Research program duration is a positive whole number of months: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		var eligibility_value: Variant = definition.get("authority_eligibility", null)
		if typeof(eligibility_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Research program authority eligibility is a dictionary: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
		else:
			var eligibility: Dictionary = eligibility_value as Dictionary
			var eligibility_ok: bool = (
				str(eligibility.get("actor_scope", "")) == "country"
				and str(eligibility.get("required_component", "")) == "research"
				and typeof(eligibility.get("player_controlled", null)) == TYPE_BOOL
				and typeof(eligibility.get("ai_controlled", null)) == TYPE_BOOL
				and bool(eligibility.get("player_controlled", false))
				and bool(eligibility.get("ai_controlled", false))
			)
			if not eligibility_ok:
				TestLogger.write_line(
					"Research program eligibility explicitly permits player and AI country actors with a research component: "
					+ program_id
					+ ": FAIL"
				)
				passed = false

		var enabled_value: Variant = definition.get("enabled", null)
		if typeof(enabled_value) != TYPE_BOOL:
			TestLogger.write_line(
				"Research program enabled flag is boolean: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		var provenance_value: Variant = definition.get("provenance", null)
		if typeof(provenance_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Research program provenance is a dictionary: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
		else:
			var provenance: Dictionary = provenance_value as Dictionary
			for provenance_field_value in ["status", "source_reference", "confidence"]:
				var provenance_field: String = str(provenance_field_value)
				if str(provenance.get(provenance_field, "")).strip_edges().is_empty():
					TestLogger.write_line(
						"Research program provenance field is non-empty: "
						+ program_id
						+ " -> "
						+ provenance_field
						+ ": FAIL"
					)
					passed = false

		var definition_version_value: Variant = definition.get("definition_version", null)
		if not _is_positive_whole_number(definition_version_value):
			TestLogger.write_line(
				"Research program definition version is a positive whole number: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

	TestLogger.write_line(
		"Research program definitions have complete Phase 4.5B schema: "
		+ ("PASS" if passed else "FAIL")
	)

	return _finish_result(passed, "ResearchProgramCatalogSchemaTest")


static func _finish_result(passed: bool, test_name: String) -> bool:
	if passed:
		TestLogger.write_line("All research program catalog schema checks: PASS")

	TestLogger.write_line(
		test_name + ": " + ("PASS" if passed else "FAIL")
	)
	return passed
