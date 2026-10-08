class_name ResearchProgramCatalogSchemaTest
extends RefCounted


static func run() -> bool:
	var catalog: ResearchProgramCatalog = (
		ResearchProgramCatalog.new()
	)

	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Research program catalog loads: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Research program catalog loads: PASS"
	)

	if catalog.get_catalog_version() < 1:
		TestLogger.write_line(
			"Research program catalog version is positive: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Research program catalog version is positive: PASS"
		)

	if catalog.get_catalog_id().strip_edges().is_empty():
		TestLogger.write_line(
			"Research program catalog id is non-empty: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Research program catalog id is non-empty: PASS"
		)

	var semantic_contract: Dictionary = (
		catalog.get_semantic_contract()
	)

	var required_contract_fields: Array = [
		"identity_semantics",
		"target_semantics",
		"eligibility_semantics",
		"progress_semantics",
		"execution_semantics",
		"completion_semantics",
		"activation_semantics",
		"provenance_semantics",
		"definition_version_semantics"
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

	var program_ids: Array = (
		catalog.get_program_ids()
	)

	var root_definition_map: Dictionary = {}
	for program_id_value in program_ids:
		var program_id: String = str(program_id_value)

		var definition: Dictionary = (
			catalog.get_program(program_id)
		)

		if definition.is_empty():
			TestLogger.write_line(
				"Research program definition is a dictionary: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
			continue

		root_definition_map[program_id] = definition

	TestLogger.write_line(
		"Research program definition map is readable: PASS | count="
		+ str(root_definition_map.size())
	)

	for program_id in root_definition_map.keys():
		var definition: Dictionary = (
			root_definition_map[program_id]
		)

		var definition_id: String = str(
			definition.get(
				"id",
				""
			)
		)

		if definition_id != str(program_id):
			TestLogger.write_line(
				"Research program definition id matches catalog key: "
				+ str(program_id)
				+ ": FAIL"
			)
			passed = false

	return _finish_result(
		passed,
		"ResearchProgramCatalogSchemaTest"
	)


static func _finish_result(
	passed: bool,
	test_name: String
) -> bool:
	if passed:
		TestLogger.write_line(
			"All research program catalog schema checks: PASS"
		)

	TestLogger.write_line(
		test_name
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
