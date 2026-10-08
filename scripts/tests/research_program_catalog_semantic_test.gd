class_name ResearchProgramCatalogSemanticTest
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
	var catalog: ResearchProgramCatalog = (
		ResearchProgramCatalog.new()
	)

	var registry: CanonicalIdRegistry = (
		CanonicalIdRegistry.new()
	)

	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Research program catalog available for semantic validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry available for research-program semantic validation: FAIL | "
			+ registry.get_load_error()
		)
		return false

	# ------------------------------------------------------------
	# Phase 4.5A intentionally stops at the foundation boundary.
	#
	# The current authoritative runtime contains ResearchSystem,
	# ResearchComponent, and ResearchProject, but it does not contain
	# a named research-program definition set. This catalog therefore
	# permits an empty program map until actual program content is
	# established in the next research-program content pass.
	# ------------------------------------------------------------

	if not registry.is_domain_reserved_unmodeled(
		"research_program"
	):
		TestLogger.write_line(
			"Research-program canonical domain remains reserved during 4.5A foundation: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Research-program canonical domain remains reserved during 4.5A foundation: PASS"
		)

	var registry_ids: Array = registry.get_domain_ids(
		"research_program"
	)

	if not registry_ids.is_empty():
		TestLogger.write_line(
			"Research-program canonical registry has no premature content IDs: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Research-program canonical registry has no premature content IDs: PASS"
		)

	var program_ids: Array = catalog.get_program_ids()

	for program_id_value in program_ids:
		var program_id: String = str(program_id_value)

		if not registry.matches_id_format(
			"research_program",
			program_id
		):
			TestLogger.write_line(
				"Research program ID format is canonical: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		var definition: Dictionary = (
			catalog.get_program(program_id)
		)

		var definition_id: String = str(
			definition.get(
				"id",
				""
			)
		)

		if definition_id != program_id:
			TestLogger.write_line(
				"Research program definition identity matches catalog key: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		var prerequisites_value: Variant = (
			definition.get(
				"prerequisites",
				[]
			)
		)

		if definition.has("prerequisites"):
			if not _is_string_array(
				prerequisites_value
			):
				TestLogger.write_line(
					"Research program prerequisites are canonical string references: "
					+ program_id
					+ ": FAIL"
				)
				passed = false
			else:
				var prerequisites: Array = (
					prerequisites_value as Array
				)

				if _has_duplicates(prerequisites):
					TestLogger.write_line(
						"Research program prerequisites contain no duplicates: "
						+ program_id
						+ ": FAIL"
					)
					passed = false

	return _finish_result(
		passed,
		"ResearchProgramCatalogSemanticTest"
	)


static func _finish_result(
	passed: bool,
	test_name: String
) -> bool:
	if passed:
		TestLogger.write_line(
			"All research program catalog semantic checks: PASS"
		)

	TestLogger.write_line(
		test_name
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
