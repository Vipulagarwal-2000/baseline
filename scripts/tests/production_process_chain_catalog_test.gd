class_name ProductionProcessChainCatalogTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS CHAIN CATALOG TEST"
	)

	var catalog := ProductionProcessCatalog.new()

	var machinery_exists := catalog.has_process(
		"machinery_basic"
	)

	TestLogger.write_line(
		"Machinery process exists: "
		+ ("PASS" if machinery_exists else "FAIL")
	)

	if not machinery_exists:
		TestLogger.write_line(
			"ProductionProcessChainCatalog test: FAIL"
		)
		return false

	var machinery_definition: Dictionary = (
		catalog.get_process(
			"machinery_basic"
		)
	)

	var inputs = machinery_definition.get(
		"inputs",
		{}
	)

	var outputs = machinery_definition.get(
		"outputs",
		{}
	)

	var steel_input_passed := (
		typeof(inputs) == TYPE_DICTIONARY
		and is_equal_approx(
			float(inputs.get("steel", 0.0)),
			2.0
		)
	)

	var machinery_output_passed := (
		typeof(outputs) == TYPE_DICTIONARY
		and is_equal_approx(
			float(outputs.get("machinery", 0.0)),
			1.0
		)
	)

	var availability_passed := (
		int(
			machinery_definition.get(
				"available_from",
				0
			)
		) == 1950
	)

	TestLogger.write_line(
		"Machinery steel input: "
		+ (
			"PASS"
			if steel_input_passed
			else "FAIL"
		)
		+ " | expected=2.0 actual="
		+ str(
			float(
				inputs.get(
					"steel",
					0.0
				)
			)
		)
	)

	TestLogger.write_line(
		"Machinery output: "
		+ (
			"PASS"
			if machinery_output_passed
			else "FAIL"
		)
		+ " | expected=1.0 actual="
		+ str(
			float(
				outputs.get(
					"machinery",
					0.0
				)
			)
		)
	)

	TestLogger.write_line(
		"1950 machinery availability: "
		+ (
			"PASS"
			if availability_passed
			else "FAIL"
		)
	)

	var result := (
		machinery_exists
		and steel_input_passed
		and machinery_output_passed
		and availability_passed
	)

	TestLogger.write_line(
		"ProductionProcessChainCatalog test passed: "
		+ str(result)
	)

	TestLogger.write_line(
		"Production Process Chain Catalog test: "
		+ ("PASS" if result else "FAIL")
	)

	return result
