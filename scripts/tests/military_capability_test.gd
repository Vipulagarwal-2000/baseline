class_name MilitaryCapabilityTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> void:

	_out([""])
	_out(["================================"])
	_out(["MILITARY → CAPABILITY TEST"])
	_out(["================================"])

	if world == null:
		push_error(
			"MilitaryCapabilityTest: World is null."
		)
		return

	if simulation == null:
		push_error(
			"MilitaryCapabilityTest: Simulation is null."
		)
		return

	var india = null

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.id == "india":
			india = entity
			break

	if india == null:
		push_error(
			"MilitaryCapabilityTest: India not found."
		)
		return

	var military = india.get_component(
		"military"
	)

	if military == null:
		push_error(
			"MilitaryCapabilityTest: "
			+ "Military component missing."
		)
		return

	_out([
		"India military component: PASS"
	])


	# ========================================================
	# CAPABILITY SYSTEM
	# ========================================================

	var capability_system = simulation.get_system(
		"capability_system"
	)

	if capability_system == null:
		push_error(
			"MilitaryCapabilityTest: "
			+ "CapabilitySystem not found."
		)
		return

	_out([
		"Capability system: PASS"
	])


	# ========================================================
	# INITIAL MILITARY STATE
	# ========================================================

	var military_power = float(
		military.get_state(
			"military_power",
			0.0
		)
	)

	var defensive_capability = float(
		military.get_state(
			"defensive_capability",
			0.0
		)
	)

	var power_projection = float(
		military.get_state(
			"power_projection",
			0.0
		)
	)

	var mobilization_capacity = float(
		military.get_state(
			"mobilization_capacity",
			0.0
		)
	)

	_out([""])
	_out(["Military source values:"])

	_out([
		"Military power: ",
		military_power
	])

	_out([
		"Defensive capability: ",
		defensive_capability
	])

	_out([
		"Power projection: ",
		power_projection
	])

	_out([
		"Mobilization capacity: ",
		mobilization_capacity
	])


	# ========================================================
	# REBUILD CAPABILITIES
	# ========================================================

	capability_system.process_month(
		world
	)

	var capability_scores = (
		capability_system.get_capability_scores(
			india
		)
	)

	_out([""])
	_out(["Capability scores:"])

	_out([
		"Military power capability: ",
		capability_scores.get(
			"military_power",
			-1.0
		)
	])

	_out([
		"Military defense capability: ",
		capability_scores.get(
			"military_defense",
			-1.0
		)
	])

	_out([
		"Military projection capability: ",
		capability_scores.get(
			"military_projection",
			-1.0
		)
	])

	_out([
		"Military mobilization capability: ",
		capability_scores.get(
			"military_mobilization",
			-1.0
		)
	])


	# ========================================================
	# FORMULA TESTS
	# ========================================================

	var military_power_score = (
		capability_system.get_capability_score(
			india,
			"military_power"
		)
	)

	var defense_score = (
		capability_system.get_capability_score(
			india,
			"military_defense"
		)
	)

	var projection_score = (
		capability_system.get_capability_score(
			india,
			"military_projection"
		)
	)

	var mobilization_score = (
		capability_system.get_capability_score(
			india,
			"military_mobilization"
		)
	)

	var military_power_formula = is_equal_approx(
		military_power_score,
		military_power
	)

	var defense_formula = is_equal_approx(
		defense_score,
		defensive_capability
	)

	var projection_formula = is_equal_approx(
		projection_score,
		power_projection
	)

	var mobilization_formula = is_equal_approx(
		mobilization_score,
		mobilization_capacity
	)

	_out([""])

	_out([
		"Military power → capability formula: ",
		"PASS" if military_power_formula else "FAIL"
	])

	_out([
		"Defensive capability → capability formula: ",
		"PASS" if defense_formula else "FAIL"
	])

	_out([
		"Power projection → capability formula: ",
		"PASS" if projection_formula else "FAIL"
	])

	_out([
		"Mobilization → capability formula: ",
		"PASS" if mobilization_formula else "FAIL"
	])


	# ========================================================
	# RANGE TESTS
	# ========================================================

	var power_range = (
		military_power_score >= 0.0
		and military_power_score <= 1.0
	)

	var defense_range = (
		defense_score >= 0.0
		and defense_score <= 1.0
	)

	var projection_range = (
		projection_score >= 0.0
		and projection_score <= 1.0
	)

	var mobilization_range = (
		mobilization_score >= 0.0
		and mobilization_score <= 1.0
	)

	_out([
		"Military power capability range: ",
		"PASS" if power_range else "FAIL"
	])

	_out([
		"Military defense capability range: ",
		"PASS" if defense_range else "FAIL"
	])

	_out([
		"Military projection capability range: ",
		"PASS" if projection_range else "FAIL"
	])

	_out([
		"Military mobilization capability range: ",
		"PASS" if mobilization_range else "FAIL"
	])


	# ========================================================
	# RESEARCH CAPABILITY PRESERVATION
	# ========================================================

	var boolean_capabilities = (
		capability_system.get_capabilities(
			india
		)
	)

	var research_score = (
		capability_system.get_capability_score(
			india,
			"research"
		)
	)

	var research_capability_exists = (
		research_score >= 0.0
		and research_score <= 1.0
	)

	var boolean_capabilities_preserved = (
		typeof(boolean_capabilities)
		== TYPE_DICTIONARY
	)

	_out([
		"Research capability score range: ",
		"PASS"
		if research_capability_exists
		else "FAIL"
	])

	_out([
		"Existing boolean capabilities preserved: ",
		"PASS"
		if boolean_capabilities_preserved
		else "FAIL"
	])


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var passed = (
		military_power_formula
		and defense_formula
		and projection_formula
		and mobilization_formula
		and power_range
		and defense_range
		and projection_range
		and mobilization_range
		and research_capability_exists
		and boolean_capabilities_preserved
	)

	_out([""])
	_out(["================================"])

	if passed:
		_out([
			"MILITARY → CAPABILITY TEST PASSED"
		])
	else:
		_out([
			"MILITARY → CAPABILITY TEST FAILED"
		])

	_out(["================================"])
