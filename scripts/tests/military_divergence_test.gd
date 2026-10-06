class_name MilitaryDivergenceTest
extends RefCounted


func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"MILITARY → DIVERGENCE TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Simulation: FAIL"
		)
		return false

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line(
			"India: FAIL"
		)
		return false

	TestLogger.write_line(
		"India found: " + india.name
	)

	var military = india.get_component(
		"military"
	)

	if military == null:
		TestLogger.write_line(
			"Military component: FAIL"
		)
		return false

	TestLogger.write_line(
		"Military component: FOUND"
	)


	# ========================================================
	# BASELINE SNAPSHOT
	# ========================================================

	var baseline = WorldSnapshot.new()

	baseline.capture(world)

	var baseline_military = (
		baseline.get_military_snapshot(
			"india"
		)
	)

	if baseline_military.is_empty():

		TestLogger.write_line(
			"Baseline military snapshot: FAIL"
		)

		return false

	TestLogger.write_line(
		"Baseline military snapshot: PASS"
	)


	# ========================================================
	# ORIGINAL STATE
	# ========================================================

	var original_power = float(
		military.get_state(
			"military_power",
			0.0
		)
	)

	var original_readiness = float(
		military.get_state(
			"readiness",
			0.0
		)
	)

	TestLogger.write_line(
		"Baseline military power: "
		+ str(original_power)
	)

	TestLogger.write_line(
		"Baseline readiness: "
		+ str(original_readiness)
	)


	# ========================================================
	# APPLY CONTROLLED MILITARY CHANGE
	# ========================================================

	var changed_power = clamp(
		original_power + 0.10,
		0.0,
		1.0
	)

	var changed_readiness = clamp(
		original_readiness - 0.10,
		0.0,
		1.0
	)

	military.set_state(
		"military_power",
		changed_power
	)

	military.set_state(
		"readiness",
		changed_readiness
	)

	TestLogger.write_line(
		"Changed military power: "
		+ str(changed_power)
	)

	TestLogger.write_line(
		"Changed readiness: "
		+ str(changed_readiness)
	)


	# ========================================================
	# CURRENT SNAPSHOT
	# ========================================================

	var current = WorldSnapshot.new()

	current.capture(world)

	var current_military = (
		current.get_military_snapshot(
			"india"
		)
	)

	if current_military.is_empty():

		TestLogger.write_line(
			"Current military snapshot: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	TestLogger.write_line(
		"Current military snapshot: PASS"
	)


	# ========================================================
	# DIVERGENCE ANALYSIS
	# ========================================================

	var analyzer = DivergenceAnalyzer.new()

	var divergence = analyzer.analyze_world(
		baseline,
		current
	)

	if divergence.is_empty():

		TestLogger.write_line(
			"Divergence result: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	TestLogger.write_line(
		"Divergence analysis: PASS"
	)


	# ========================================================
	# FIND INDIA
	# ========================================================

	var entities = divergence.get(
		"entities",
		{}
	)

	if not entities.has("india"):

		TestLogger.write_line(
			"India divergence entry: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	TestLogger.write_line(
		"India divergence entry: PASS"
	)


	var india_result = entities["india"]

	var components = india_result.get(
		"components",
		{}
	)

	if not components.has("military"):

		TestLogger.write_line(
			"Military divergence component: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	TestLogger.write_line(
		"Military divergence component: PASS"
	)


	# ========================================================
	# CHECK MILITARY POWER CHANGE
	# ========================================================

	var military_result = components["military"]

	if not military_result.has(
		"military_power"
	):

		TestLogger.write_line(
			"Military power divergence: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	var power_result = military_result[
		"military_power"
	]

	var detected_power_change = float(
		power_result.get(
			"absolute_change",
			0.0
		)
	)

	TestLogger.write_line(
		"Detected military power divergence: "
		+ str(detected_power_change)
	)


	var power_passed = is_equal_approx(
		detected_power_change,
		0.10
	)

	TestLogger.write_line(
		"Military power divergence detection: "
		+ (
			"PASS"
			if power_passed
			else "FAIL"
		)
	)


	# ========================================================
	# CHECK READINESS CHANGE
	# ========================================================

	if not military_result.has(
		"readiness"
	):

		TestLogger.write_line(
			"Readiness divergence: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		military.set_state(
			"readiness",
			original_readiness
		)

		return false

	var readiness_result = military_result[
		"readiness"
	]

	var detected_readiness_change = float(
		readiness_result.get(
			"absolute_change",
			0.0
		)
	)

	TestLogger.write_line(
		"Detected readiness divergence: "
		+ str(detected_readiness_change)
	)


	var readiness_passed = is_equal_approx(
		detected_readiness_change,
		-0.10
	)

	TestLogger.write_line(
		"Military readiness divergence detection: "
		+ (
			"PASS"
			if readiness_passed
			else "FAIL"
		)
	)


	# ========================================================
	# WORLD DIVERGENCE
	# ========================================================

	var world_divergence = float(
		divergence.get(
			"world_divergence",
			0.0
		)
	)

	TestLogger.write_line(
		"World divergence: "
		+ str(world_divergence)
	)

	var world_divergence_valid = (
		world_divergence > 0.0
	)

	TestLogger.write_line(
		"World divergence generated: "
		+ (
			"PASS"
			if world_divergence_valid
			else "FAIL"
		)
	)


	# ========================================================
	# RESTORE ORIGINAL STATE
	# ========================================================

	military.set_state(
		"military_power",
		original_power
	)

	military.set_state(
		"readiness",
		original_readiness
	)

	TestLogger.write_line(
		"Original military state restored."
	)


	var passed = (
		power_passed
		and readiness_passed
		and world_divergence_valid
	)

	TestLogger.section(
		"MILITARY → DIVERGENCE TEST "
		+ (
			"PASSED"
			if passed
			else "FAILED"
		)
	)

	return passed
