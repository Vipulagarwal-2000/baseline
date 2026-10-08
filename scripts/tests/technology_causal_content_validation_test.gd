class_name TechnologyCausalContentValidationTest
extends RefCounted


const PRODUCTION_PROCESS_CATALOG_PATH: String = (
	"res://data/production_processes/production_processes.json"
)


static func _is_numeric(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_INT
		or typeof(value) == TYPE_FLOAT
	)


static func _visit_prerequisites(
	technology_id: String,
	catalog: TechnologyCatalog,
	states: Dictionary,
	path: Array
) -> bool:
	var state: int = int(
		states.get(
			technology_id,
			0
		)
	)

	if state == 1:
		TestLogger.write_line(
			"Technology prerequisite graph is acyclic: FAIL | cycle="
			+ str(path)
			+ " -> "
			+ technology_id
		)
		return false

	if state == 2:
		return true

	states[technology_id] = 1
	path.append(technology_id)

	var definition: Dictionary = catalog.get_technology(
		technology_id
	)

	var prerequisites_value: Variant = (
		definition.get(
			"prerequisites",
			[]
		)
	)

	if typeof(prerequisites_value) != TYPE_ARRAY:
		path.pop_back()
		states[technology_id] = 2
		return false

	var prerequisites: Array = (
		prerequisites_value as Array
	)

	for raw_prerequisite_id in prerequisites:
		var prerequisite_id: String = str(
			raw_prerequisite_id
		)

		if not catalog.has_technology(
			prerequisite_id
		):
			TestLogger.write_line(
				"Technology prerequisite resolves during causal traversal: "
				+ technology_id
				+ " -> "
				+ prerequisite_id
				+ ": FAIL"
			)
			path.pop_back()
			states[technology_id] = 2
			return false

		if not _visit_prerequisites(
			prerequisite_id,
			catalog,
			states,
			path
		):
			path.pop_back()
			states[technology_id] = 2
			return false

	path.pop_back()
	states[technology_id] = 2
	return true


static func _validate_prerequisite_structure(
	catalog: TechnologyCatalog
) -> bool:
	var passed: bool = true
	var states: Dictionary = {}

	for technology_id_value in catalog.get_technology_ids():
		var technology_id: String = str(
			technology_id_value
		)

		if not _visit_prerequisites(
			technology_id,
			catalog,
			states,
			[]
		):
			passed = false

		var definition: Dictionary = (
			catalog.get_technology(
				technology_id
			)
		)

		var start_year: int = int(
			definition.get(
				"historical_start_year",
				0
			)
		)

		var prerequisites_value: Variant = (
			definition.get(
				"prerequisites",
				[]
			)
		)

		if typeof(prerequisites_value) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology prerequisite ordering data is an array: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
			continue

		for raw_prerequisite_id in (
			prerequisites_value as Array
		):
			var prerequisite_id: String = str(
				raw_prerequisite_id
			)

			var prerequisite_definition: Dictionary = (
				catalog.get_technology(
					prerequisite_id
				)
			)

			var prerequisite_start_year: int = int(
				prerequisite_definition.get(
					"historical_start_year",
					0
				)
			)

			if prerequisite_start_year > start_year:
				TestLogger.write_line(
					"Technology prerequisite begins no later than dependent technology: "
					+ technology_id
					+ " <- "
					+ prerequisite_id
					+ ": FAIL"
				)
				passed = false

	return passed


static func _validate_effect_values(
	catalog: TechnologyCatalog
) -> bool:
	var passed: bool = true

	for technology_id_value in catalog.get_technology_ids():
		var technology_id: String = str(
			technology_id_value
		)

		var definition: Dictionary = (
			catalog.get_technology(
				technology_id
			)
		)

		var effects_value: Variant = (
			definition.get(
				"effects",
				{}
			)
		)

		if typeof(effects_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology effects are a dictionary for causal validation: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
			continue

		var effects: Dictionary = effects_value as Dictionary

		for effect_id_value in effects.keys():
			var effect_id: String = str(
				effect_id_value
			)

			if effect_id.strip_edges().is_empty():
				TestLogger.write_line(
					"Technology effect ID is non-empty for causal validation: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

			var effect_value: Variant = effects[effect_id_value]

			if not _is_numeric(effect_value):
				TestLogger.write_line(
					"Technology effect value is numeric for current effect runtime: "
					+ technology_id
					+ " -> "
					+ effect_id
					+ ": FAIL"
				)
				passed = false

	return passed


static func _validate_process_technology_references(
	catalog: TechnologyCatalog,
	process_catalog: ProductionProcessCatalog,
	registry: CanonicalIdRegistry
) -> bool:
	var passed: bool = true
	var process_ids: Array = process_catalog.get_process_ids()
	process_ids.sort()

	for process_id_value in process_ids:
		var process_id: String = str(
			process_id_value
		)

		var definition: Dictionary = (
			process_catalog.get_process(
				process_id
			)
		)

		var requirements_value: Variant = (
			definition.get(
				"technology_requirements",
				{}
			)
		)

		if typeof(requirements_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Process technology requirements are dictionaries: "
				+ process_id
				+ ": FAIL"
			)
			passed = false
			continue

		var requirements: Dictionary = (
			requirements_value as Dictionary
		)

		var process_start_year: int = int(
			definition.get(
				"available_from",
				0
			)
		)

		for raw_technology_id in requirements.keys():
			var technology_id: String = str(
				raw_technology_id
			)

			if not registry.has_id(
				"technology",
				technology_id
			):
				TestLogger.write_line(
					"Production process technology reference is canonical: "
					+ process_id
					+ " -> "
					+ technology_id
					+ ": FAIL"
				)
				passed = false
				continue

			var requirement_value: Variant = (
				requirements[raw_technology_id]
			)

			if not _is_numeric(
				requirement_value
			) or float(requirement_value) <= 0.0:
				TestLogger.write_line(
					"Production process technology requirement is positive numeric: "
					+ process_id
					+ " -> "
					+ technology_id
					+ ": FAIL"
				)
				passed = false
				continue

			if catalog.has_technology(
				technology_id
			):
				var technology_definition: Dictionary = (
					catalog.get_technology(
						technology_id
					)
				)

				var technology_start_year: int = int(
					technology_definition.get(
						"historical_start_year",
						0
					)
				)

				if (
					process_start_year > 0
					and technology_start_year > 0
					and process_start_year < technology_start_year
				):
					TestLogger.write_line(
						"Production process is not available before its resolved technology: "
						+ process_id
						+ " -> "
						+ technology_id
						+ ": FAIL"
					)
					passed = false
			else:
				var registry_entry: Dictionary = (
					registry.get_entry(
						"technology",
						technology_id
					)
				)

				var source_paths_value: Variant = (
					registry_entry.get(
						"source_paths",
						[]
					)
				)

				var reference_is_process_owned: bool = false

				if typeof(source_paths_value) == TYPE_ARRAY:
					var source_paths: Array = (
						source_paths_value as Array
					)

					for raw_source_path in source_paths:
						if str(raw_source_path) == PRODUCTION_PROCESS_CATALOG_PATH:
							reference_is_process_owned = true
							break

				var registry_status: String = str(
					registry_entry.get(
						"status",
						""
					)
				)

				if (
					registry_status != "canonical_existing"
					or not reference_is_process_owned
				):
					TestLogger.write_line(
						"Unresolved production-process technology reference is explicitly process-owned: "
						+ process_id
						+ " -> "
						+ technology_id
						+ ": FAIL"
					)
					passed = false
				else:
					TestLogger.write_line(
						"Reference-only production-process technology boundary is explicit: "
						+ process_id
						+ " -> "
						+ technology_id
						+ ": PASS"
					)

	return passed


static func run() -> bool:
	var catalog: TechnologyCatalog = TechnologyCatalog.new()
	var process_catalog: ProductionProcessCatalog = (
		ProductionProcessCatalog.new()
	)
	var registry: CanonicalIdRegistry = (
		CanonicalIdRegistry.new()
	)

	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Technology catalog loads for causal validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	if not process_catalog.has_process(
		"advanced_steel_production"
	):
		TestLogger.write_line(
			"Production process catalog contains the advanced steel boundary process: FAIL"
		)
		return false

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry loads for technology causal validation: FAIL | "
			+ registry.get_load_error()
		)
		return false

	if _validate_prerequisite_structure(
		catalog
	):
		TestLogger.write_line(
			"Technology prerequisite graph is acyclic and historically ordered: PASS"
		)
	else:
		passed = false

	if _validate_effect_values(
		catalog
	):
		TestLogger.write_line(
			"Technology effects remain compatible with current effect runtime semantics: PASS"
		)
	else:
		passed = false

	if _validate_process_technology_references(
		catalog,
		process_catalog,
		registry
	):
		TestLogger.write_line(
			"Production-process technology references satisfy causal content boundaries: PASS"
		)
	else:
		passed = false

	TestLogger.write_line(
		"TechnologyCausalContentValidationTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
