class_name TechnologyCatalogRuntimeParityTest
extends RefCounted


static func _arrays_match(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false

	for index in range(left.size()):
		if left[index] != right[index]:
			return false

	return true


static func _effects_match(
	catalog_effects: Dictionary,
	runtime_effects: Dictionary
) -> bool:
	if catalog_effects.size() != runtime_effects.size():
		return false

	for effect_id in runtime_effects.keys():
		if not catalog_effects.has(effect_id):
			return false

		var catalog_value: Variant = catalog_effects[effect_id]
		var runtime_value: Variant = runtime_effects[effect_id]

		if (
			(typeof(catalog_value) == TYPE_INT
			or typeof(catalog_value) == TYPE_FLOAT)
			and (
				typeof(runtime_value) == TYPE_INT
				or typeof(runtime_value) == TYPE_FLOAT
			)
		):
			if not is_equal_approx(
				float(catalog_value),
				float(runtime_value)
			):
				return false
		elif catalog_value != runtime_value:
			return false

	return true


static func run() -> bool:
	var catalog: TechnologyCatalog = TechnologyCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Technology catalog loads for runtime parity validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	var runtime_library: TechnologyLibrary = (
		DefaultTechnologies.create_library()
	)

	if runtime_library == null:
		TestLogger.write_line(
			"Default technology library is available: FAIL"
		)
		return false

	var catalog_ids: Array = catalog.get_technology_ids()
	var runtime_technologies: Array = (
		runtime_library.get_all_technologies()
	)

	var runtime_ids: Array = []

	for raw_technology in runtime_technologies:
		if raw_technology == null:
			continue

		var runtime_technology: TechnologyData = (
			raw_technology as TechnologyData
		)

		if runtime_technology == null:
			continue

		runtime_ids.append(runtime_technology.id)

	runtime_ids.sort()

	if catalog_ids != runtime_ids:
		TestLogger.write_line(
			"Technology catalog IDs match DefaultTechnologies IDs: FAIL"
			+ " | catalog="
			+ str(catalog_ids)
			+ " runtime="
			+ str(runtime_ids)
		)
		passed = false
	else:
		TestLogger.write_line(
			"Technology catalog IDs match DefaultTechnologies IDs: PASS"
		)

	for raw_technology in runtime_technologies:
		if raw_technology == null:
			continue

		var runtime_technology: TechnologyData = (
			raw_technology as TechnologyData
		)

		if runtime_technology == null:
			continue

		var technology_id: String = runtime_technology.id

		if not catalog.has_technology(technology_id):
			TestLogger.write_line(
				"Runtime technology has catalog definition: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
			continue

		var catalog_definition: Dictionary = (
			catalog.get_technology(technology_id)
		)

		var catalog_name: String = str(
			catalog_definition.get("name", "")
		)
		if catalog_name != runtime_technology.name:
			TestLogger.write_line(
				"Technology name parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_description: String = str(
			catalog_definition.get("description", "")
		)
		if catalog_description != runtime_technology.description:
			TestLogger.write_line(
				"Technology description parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_research_cost: float = float(
			catalog_definition.get("research_cost", -1.0)
		)
		if not is_equal_approx(
			catalog_research_cost,
			runtime_technology.research_cost
		):
			TestLogger.write_line(
				"Technology research cost parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_duration: int = int(
			catalog_definition.get(
				"research_duration_months",
				-1
			)
		)
		if catalog_duration != runtime_technology.research_duration_months:
			TestLogger.write_line(
				"Technology research duration parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_prerequisites_value: Variant = (
			catalog_definition.get("prerequisites", [])
		)

		if typeof(catalog_prerequisites_value) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology prerequisite parity data is an array: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var catalog_prerequisites: Array = (
				catalog_prerequisites_value as Array
			)
			if not _arrays_match(
				catalog_prerequisites,
				runtime_technology.prerequisites
			):
				TestLogger.write_line(
					"Technology prerequisite parity: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

		var catalog_level: float = float(
			catalog_definition.get(
				"required_technology_level",
				-1.0
			)
		)
		if not is_equal_approx(
			catalog_level,
			runtime_technology.required_technology_level
		):
			TestLogger.write_line(
				"Technology level threshold parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_capabilities_value: Variant = (
			catalog_definition.get("capabilities", [])
		)

		if typeof(catalog_capabilities_value) != TYPE_ARRAY:
			TestLogger.write_line(
				"Technology capability parity data is an array: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var catalog_capabilities: Array = (
				catalog_capabilities_value as Array
			)
			if not _arrays_match(
				catalog_capabilities,
				runtime_technology.capabilities
			):
				TestLogger.write_line(
					"Technology capability parity: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

		var catalog_effects_value: Variant = (
			catalog_definition.get("effects", {})
		)

		if typeof(catalog_effects_value) != TYPE_DICTIONARY:
			TestLogger.write_line(
				"Technology effect parity data is a dictionary: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false
		else:
			var catalog_effects: Dictionary = (
				catalog_effects_value as Dictionary
			)
			if not _effects_match(
				catalog_effects,
				runtime_technology.effects
			):
				TestLogger.write_line(
					"Technology effect parity: "
					+ technology_id
					+ ": FAIL"
				)
				passed = false

		var catalog_start_year: int = int(
			catalog_definition.get(
				"historical_start_year",
				0
			)
		)
		if catalog_start_year != runtime_technology.historical_start_year:
			TestLogger.write_line(
				"Technology historical start parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_end_year: int = int(
			catalog_definition.get(
				"historical_end_year",
				0
			)
		)
		if catalog_end_year != runtime_technology.historical_end_year:
			TestLogger.write_line(
				"Technology historical end parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

		var catalog_enabled: bool = bool(
			catalog_definition.get(
				"enabled",
				false
			)
		)
		if catalog_enabled != runtime_technology.enabled:
			TestLogger.write_line(
				"Technology enabled-state parity: "
				+ technology_id
				+ ": FAIL"
			)
			passed = false

	if passed:
		TestLogger.write_line(
			"All technology catalog/runtime parity checks: PASS"
		)

	TestLogger.write_line(
		"TechnologyCatalogRuntimeParityTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
