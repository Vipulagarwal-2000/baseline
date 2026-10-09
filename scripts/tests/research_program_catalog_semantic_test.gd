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


static func _visit_program_dependencies(
	program_id: String,
	catalog: ResearchProgramCatalog,
	states: Dictionary,
	path: Array
) -> bool:
	var state: int = int(states.get(program_id, 0))
	if state == 1:
		TestLogger.write_line(
			"Research program dependency graph is acyclic: FAIL | cycle="
			+ str(path)
			+ " -> "
			+ program_id
		)
		return false
	if state == 2:
		return true

	states[program_id] = 1
	path.append(program_id)
	var passed: bool = true
	var definition: Dictionary = catalog.get_program(program_id)
	var dependencies_value: Variant = definition.get("prerequisites", [])
	if typeof(dependencies_value) != TYPE_ARRAY:
		passed = false
	else:
		for raw_dependency in (dependencies_value as Array):
			var dependency_id: String = str(raw_dependency)
			if not catalog.has_program(dependency_id):
				TestLogger.write_line(
					"Research program dependency resolves: "
					+ program_id
					+ " -> "
					+ dependency_id
					+ ": FAIL"
				)
				passed = false
				continue

			if not _visit_program_dependencies(
				dependency_id,
				catalog,
				states,
				path
			):
				passed = false

	path.pop_back()
	states[program_id] = 2
	return passed


static func _collect_transitive_program_prerequisites(
	program_id: String,
	catalog: ResearchProgramCatalog,
	collected: Dictionary
) -> void:
	var definition: Dictionary = catalog.get_program(program_id)
	var dependencies_value: Variant = definition.get("prerequisites", [])
	if typeof(dependencies_value) != TYPE_ARRAY:
		return

	for raw_dependency in (dependencies_value as Array):
		var dependency_id: String = str(raw_dependency)
		if collected.has(dependency_id):
			continue
		if not catalog.has_program(dependency_id):
			continue

		collected[dependency_id] = true
		_collect_transitive_program_prerequisites(
			dependency_id,
			catalog,
			collected
		)


static func _index_of_string(values: Array, sought: String) -> int:
	for index in range(values.size()):
		if str(values[index]) == sought:
			return index
	return -1


static func _validate_program_registry(
	catalog: ResearchProgramCatalog,
	registry: CanonicalIdRegistry
) -> bool:
	var passed: bool = true
	var catalog_ids: Array = catalog.get_program_ids()
	var registered_ids: Array = registry.get_domain_ids("research_program")

	if registry.get_domain_status("research_program") != "active":
		TestLogger.write_line(
			"Research-program canonical ID domain is active: FAIL | status="
			+ registry.get_domain_status("research_program")
		)
		passed = false
	else:
		TestLogger.write_line("Research-program canonical ID domain is active: PASS")

	if catalog_ids != registered_ids:
		TestLogger.write_line(
			"Canonical research-program IDs exactly match catalog IDs: FAIL | catalog="
			+ str(catalog_ids)
			+ " registry="
			+ str(registered_ids)
		)
		passed = false
	else:
		TestLogger.write_line("Canonical research-program IDs exactly match catalog IDs: PASS")

	for program_id_value in catalog_ids:
		var program_id: String = str(program_id_value)
		if not registry.matches_id_format("research_program", program_id):
			TestLogger.write_line(
				"Research program ID follows canonical format: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
		if not registry.has_id("research_program", program_id):
			TestLogger.write_line(
				"Research program ID exists in canonical registry: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

	return passed


static func _validate_program_dependency_graph(
	catalog: ResearchProgramCatalog
) -> bool:
	var passed: bool = true
	var states: Dictionary = {}

	for program_id_value in catalog.get_program_ids():
		var program_id: String = str(program_id_value)
		var definition: Dictionary = catalog.get_program(program_id)
		var dependencies_value: Variant = definition.get("prerequisites", [])

		if not _is_string_array(dependencies_value):
			TestLogger.write_line(
				"Research program dependencies are canonical string references: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
			continue

		var dependencies: Array = dependencies_value as Array
		if _has_duplicates(dependencies):
			TestLogger.write_line(
				"Research program dependencies contain no duplicates: "
				+ program_id
				+ ": FAIL"
			)
			passed = false

		if not _visit_program_dependencies(
			program_id,
			catalog,
			states,
			[]
		):
			passed = false

	if passed:
		TestLogger.write_line("Research program dependency graph is resolved and acyclic: PASS")
	return passed


static func _validate_technology_outputs(
	catalog: ResearchProgramCatalog,
	technology_catalog: TechnologyCatalog,
	registry: CanonicalIdRegistry
) -> Dictionary:
	var passed: bool = true
	var output_owner: Dictionary = {}

	for program_id_value in catalog.get_program_ids():
		var program_id: String = str(program_id_value)
		var definition: Dictionary = catalog.get_program(program_id)
		var outputs_value: Variant = definition.get("technology_outputs", [])
		if not _is_string_array(outputs_value):
			TestLogger.write_line(
				"Research program technology output list is valid: "
				+ program_id
				+ ": FAIL"
			)
			passed = false
			continue

		for raw_technology_id in (outputs_value as Array):
			var technology_id: String = str(raw_technology_id)
			if not technology_catalog.has_technology(technology_id):
				TestLogger.write_line(
					"Research program output resolves to a technology definition: "
					+ program_id
					+ " -> "
					+ technology_id
					+ ": FAIL"
				)
				passed = false
				continue

			if not registry.has_id("technology", technology_id):
				TestLogger.write_line(
					"Research program output resolves to a canonical technology ID: "
					+ program_id
					+ " -> "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

			if output_owner.has(technology_id):
				TestLogger.write_line(
					"Each technology has at most one program owner: "
					+ technology_id
					+ ": FAIL | owners="
					+ str(output_owner[technology_id])
					+ ","
					+ program_id
				)
				passed = false
			else:
				output_owner[technology_id] = program_id

	var expected_technology_ids: Array = technology_catalog.get_technology_ids()
	var covered_technology_ids: Array = output_owner.keys()
	expected_technology_ids.sort()
	covered_technology_ids.sort()
	if covered_technology_ids != expected_technology_ids:
		TestLogger.write_line(
			"Research programs cover every technology-catalog definition exactly once: FAIL | expected="
			+ str(expected_technology_ids)
			+ " covered="
			+ str(covered_technology_ids)
		)
		passed = false
	else:
		TestLogger.write_line(
			"Research programs cover every technology-catalog definition exactly once: PASS | count="
			+ str(covered_technology_ids.size())
		)

	return {
		"passed": passed,
		"owner_by_technology": output_owner
	}


static func _validate_cost_and_duration_summaries(
	catalog: ResearchProgramCatalog,
	technology_catalog: TechnologyCatalog
) -> bool:
	var passed: bool = true

	for program_id_value in catalog.get_program_ids():
		var program_id: String = str(program_id_value)
		var definition: Dictionary = catalog.get_program(program_id)
		var outputs_value: Variant = definition.get("technology_outputs", [])
		if typeof(outputs_value) != TYPE_ARRAY:
			passed = false
			continue

		var calculated_cost: float = 0.0
		var calculated_duration: int = 0
		var targets_valid: bool = true

		for raw_technology_id in (outputs_value as Array):
			var technology_id: String = str(raw_technology_id)
			var technology_definition: Dictionary = technology_catalog.get_technology(technology_id)
			if technology_definition.is_empty():
				targets_valid = false
				continue

			var cost_value: Variant = technology_definition.get("research_cost", null)
			var duration_value: Variant = technology_definition.get("research_duration_months", null)
			if (
				(typeof(cost_value) != TYPE_INT and typeof(cost_value) != TYPE_FLOAT)
				or (typeof(duration_value) != TYPE_INT and typeof(duration_value) != TYPE_FLOAT)
			):
				targets_valid = false
				continue

			calculated_cost += float(cost_value)
			calculated_duration += int(duration_value)

		var declared_cost_value: Variant = definition.get("research_cost", null)
		var declared_duration_value: Variant = definition.get("research_duration_months", null)
		var cost_matches: bool = (
			targets_valid
			and (typeof(declared_cost_value) == TYPE_INT or typeof(declared_cost_value) == TYPE_FLOAT)
			and is_equal_approx(float(declared_cost_value), calculated_cost)
		)
		var duration_matches: bool = (
			targets_valid
			and (typeof(declared_duration_value) == TYPE_INT or typeof(declared_duration_value) == TYPE_FLOAT)
			and int(declared_duration_value) == calculated_duration
			and is_equal_approx(float(declared_duration_value), float(calculated_duration))
		)

		if not cost_matches:
			TestLogger.write_line(
				"Research program cost equals the sum of direct technology costs only: "
				+ program_id
				+ ": FAIL | declared="
				+ str(declared_cost_value)
				+ " calculated="
				+ str(calculated_cost)
			)
			passed = false

		if not duration_matches:
			TestLogger.write_line(
				"Research program duration equals the sum of direct technology durations only: "
				+ program_id
				+ ": FAIL | declared="
				+ str(declared_duration_value)
				+ " calculated="
				+ str(calculated_duration)
			)
			passed = false

	if passed:
		TestLogger.write_line("Research program cost/duration estimates match authoritative technology definitions: PASS")
	return passed


static func _validate_technology_prerequisite_placement(
	catalog: ResearchProgramCatalog,
	technology_catalog: TechnologyCatalog,
	owner_by_technology: Dictionary
) -> bool:
	var passed: bool = true

	for program_id_value in catalog.get_program_ids():
		var program_id: String = str(program_id_value)
		var definition: Dictionary = catalog.get_program(program_id)
		var outputs_value: Variant = definition.get("technology_outputs", [])
		if typeof(outputs_value) != TYPE_ARRAY:
			passed = false
			continue

		var outputs: Array = outputs_value as Array
		var ancestor_programs: Dictionary = {}
		_collect_transitive_program_prerequisites(
			program_id,
			catalog,
			ancestor_programs
		)

		for raw_technology_id in outputs:
			var technology_id: String = str(raw_technology_id)
			var technology_definition: Dictionary = technology_catalog.get_technology(technology_id)
			var prerequisites_value: Variant = technology_definition.get("prerequisites", [])
			if typeof(prerequisites_value) != TYPE_ARRAY:
				TestLogger.write_line(
					"Technology prerequisite list is an array for program output: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false
				continue

			for raw_prerequisite_id in (prerequisites_value as Array):
				var prerequisite_technology_id: String = str(raw_prerequisite_id)
				var prerequisite_owner: String = str(
					owner_by_technology.get(prerequisite_technology_id, "")
				)
				if prerequisite_owner.is_empty():
					TestLogger.write_line(
						"Technology prerequisite is covered by a research program: "
						+ technology_id
						+ " <- "
						+ prerequisite_technology_id
						+ ": FAIL"
					)
					passed = false
					continue

				if prerequisite_owner == program_id:
					var prerequisite_index: int = _index_of_string(
						outputs,
						prerequisite_technology_id
					)
					var target_index: int = _index_of_string(outputs, technology_id)
					if prerequisite_index >= target_index:
						TestLogger.write_line(
							"Within-program technology prerequisite appears before dependent output: "
							+ technology_id
							+ " <- "
							+ prerequisite_technology_id
							+ ": FAIL"
						)
						passed = false
				elif not ancestor_programs.has(prerequisite_owner):
					TestLogger.write_line(
						"Cross-program technology prerequisite is provided by a prerequisite program: "
						+ technology_id
						+ " <- "
						+ prerequisite_technology_id
						+ " | owner="
						+ prerequisite_owner
						+ ": FAIL"
					)
					passed = false

	if passed:
		TestLogger.write_line("Technology prerequisites are represented by same-program outputs or transitive prerequisite programs: PASS")
	return passed


static func run() -> bool:
	var catalog: ResearchProgramCatalog = ResearchProgramCatalog.new()
	var registry: CanonicalIdRegistry = CanonicalIdRegistry.new()
	var technology_catalog: TechnologyCatalog = TechnologyCatalog.new()
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
	if not technology_catalog.is_loaded():
		TestLogger.write_line(
			"Technology catalog available for research-program semantic validation: FAIL | "
			+ technology_catalog.get_load_error()
		)
		return false

	if not _validate_program_registry(catalog, registry):
		passed = false
	if not _validate_program_dependency_graph(catalog):
		passed = false

	var coverage_result: Dictionary = _validate_technology_outputs(
		catalog,
		technology_catalog,
		registry
	)
	var output_coverage_passed: bool = bool(coverage_result.get("passed", false))
	var owner_value: Variant = coverage_result.get("owner_by_technology", {})
	var owner_by_technology: Dictionary = {}
	if typeof(owner_value) == TYPE_DICTIONARY:
		owner_by_technology = owner_value as Dictionary
	if not output_coverage_passed:
		passed = false

	if not _validate_cost_and_duration_summaries(catalog, technology_catalog):
		passed = false
	if not _validate_technology_prerequisite_placement(
		catalog,
		technology_catalog,
		owner_by_technology
	):
		passed = false

	return _finish_result(passed, "ResearchProgramCatalogSemanticTest")


static func _finish_result(passed: bool, test_name: String) -> bool:
	if passed:
		TestLogger.write_line("All research program catalog semantic checks: PASS")

	TestLogger.write_line(
		test_name + ": " + ("PASS" if passed else "FAIL")
	)
	return passed
