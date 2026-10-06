class_name MilitaryRelationshipTest
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
	_out(["MILITARY → RELATIONSHIP TEST"])
	_out(["================================"])

	if world == null:
		push_error(
			"MilitaryRelationshipTest: World is null."
		)
		return

	if simulation == null:
		push_error(
			"MilitaryRelationshipTest: Simulation is null."
		)
		return


	# ========================================================
	# FIND COUNTRIES
	# ========================================================

	var india = world.get_entity("india")
	var china = world.get_entity("china")

	if india == null:
		push_error(
			"MilitaryRelationshipTest: India not found."
		)
		return

	if china == null:
		push_error(
			"MilitaryRelationshipTest: China not found."
		)
		return


	# ========================================================
	# CHECK SYSTEM
	# ========================================================

	var military_relationship_system = (
		simulation.get_system(
			"military_relationship_system"
		)
	)

	if military_relationship_system == null:
		push_error(
			"MilitaryRelationshipTest: "
			+ "MilitaryRelationshipSystem not found."
		)
		return

	_out([
		"Military relationship system: PASS"
	])


	# ========================================================
	# CHECK MILITARY COMPONENTS
	# ========================================================

	var india_military = (
		india.get_component("military")
	)

	var china_military = (
		china.get_component("military")
	)

	if india_military == null:
		push_error(
			"MilitaryRelationshipTest: "
			+ "India military component missing."
		)
		return

	if china_military == null:
		push_error(
			"MilitaryRelationshipTest: "
			+ "China military component missing."
		)
		return

	_out([
		"India military component: PASS"
	])

	_out([
		"China military component: PASS"
	])


	# ========================================================
	# READ MILITARY CAPABILITIES
	# ========================================================

	var india_power = clamp(
		float(
			india_military.get_state(
				"military_power",
				0.0
			)
		),
		0.0,
		1.0
	)

	var india_defense = clamp(
		float(
			india_military.get_state(
				"defensive_capability",
				0.0
			)
		),
		0.0,
		1.0
	)

	var india_projection = clamp(
		float(
			india_military.get_state(
				"power_projection",
				0.0
			)
		),
		0.0,
		1.0
	)

	var india_mobilization = clamp(
		float(
			india_military.get_state(
				"mobilization_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)


	var china_power = clamp(
		float(
			china_military.get_state(
				"military_power",
				0.0
			)
		),
		0.0,
		1.0
	)

	var china_defense = clamp(
		float(
			china_military.get_state(
				"defensive_capability",
				0.0
			)
		),
		0.0,
		1.0
	)

	var china_projection = clamp(
		float(
			china_military.get_state(
				"power_projection",
				0.0
			)
		),
		0.0,
		1.0
	)

	var china_mobilization = clamp(
		float(
			china_military.get_state(
				"mobilization_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)


	_out([""])
	_out(["India military state:"])
	_out([
		"Military power: ",
		india_power
	])
	_out([
		"Defensive capability: ",
		india_defense
	])
	_out([
		"Power projection: ",
		india_projection
	])
	_out([
		"Mobilization capacity: ",
		india_mobilization
	])

	_out([""])
	_out(["China military state:"])
	_out([
		"Military power: ",
		china_power
	])
	_out([
		"Defensive capability: ",
		china_defense
	])
	_out([
		"Power projection: ",
		china_projection
	])
	_out([
		"Mobilization capacity: ",
		china_mobilization
	])


	# ========================================================
	# CALCULATE EXPECTED CAPABILITIES
	# ========================================================

	var india_capability = (
		india_power * 0.35
		+ india_defense * 0.20
		+ india_projection * 0.30
		+ india_mobilization * 0.15
	)

	india_capability = clamp(
		india_capability,
		0.0,
		1.0
	)


	var china_capability = (
		china_power * 0.35
		+ china_defense * 0.20
		+ china_projection * 0.30
		+ china_mobilization * 0.15
	)

	china_capability = clamp(
		china_capability,
		0.0,
		1.0
	)


	_out([""])
	_out([
		"India military capability: ",
		india_capability
	])

	_out([
		"China military capability: ",
		china_capability
	])


	# ========================================================
	# EXPECTED RELATIVE RELATIONSHIP
	# ========================================================

	var total_capability = (
		india_capability
		+ china_capability
	)

	var expected_india_to_china = 0.0
	var expected_china_to_india = 0.0

	if total_capability > 0.0:

		var india_share = (
			india_capability
			/ total_capability
		)

		var china_share = (
			china_capability
			/ total_capability
		)

		expected_india_to_china = (
			india_share - 0.5
		) * 200.0

		expected_china_to_india = (
			china_share - 0.5
		) * 200.0


	# ========================================================
	# RUN SYSTEM
	# ========================================================

	military_relationship_system.process_month(
		world
	)


	# ========================================================
	# READ RELATIONSHIP DIMENSIONS
	# ========================================================

	var india_to_china = (
		india.get_relationship_dimension(
			"china",
			"military",
			0.0
		)
	)

	var china_to_india = (
		china.get_relationship_dimension(
			"india",
			"military",
			0.0
		)
	)


	_out([""])
	_out([
		"India → China military relationship: ",
		india_to_china
	])

	_out([
		"China → India military relationship: ",
		china_to_india
	])


	# ========================================================
	# FORMULA TEST
	# ========================================================

	var india_formula_pass = is_equal_approx(
		india_to_china,
		expected_india_to_china
	)

	var china_formula_pass = is_equal_approx(
		china_to_india,
		expected_china_to_india
	)

	_out([""])
	_out([
		"India → China relationship formula: ",
		"PASS"
		if india_formula_pass
		else "FAIL"
	])

	_out([
		"China → India relationship formula: ",
		"PASS"
		if china_formula_pass
		else "FAIL"
	])


	# ========================================================
	# RECIPROCAL TEST
	# ========================================================

	var reciprocal_pass = is_equal_approx(
		india_to_china,
		-china_to_india
	)

	_out([
		"Reciprocal military relationship: ",
		"PASS"
		if reciprocal_pass
		else "FAIL"
	])


	# ========================================================
	# RANGE TEST
	# ========================================================

	var range_pass = (
		india_to_china >= -100.0
		and india_to_china <= 100.0
		and china_to_india >= -100.0
		and china_to_india <= 100.0
	)

	_out([
		"Military relationship range: ",
		"PASS"
		if range_pass
		else "FAIL"
	])


	# ========================================================
	# OVERALL RELATIONSHIP PRESERVATION TEST
	# ========================================================

	var india_relationship_data = (
		india.get_relationship_data(
			"china"
		)
	)

	var china_relationship_data = (
		china.get_relationship_data(
			"india"
		)
	)

	var india_military_dimension_exists = (
		india_relationship_data.has(
			"military"
		)
	)

	var china_military_dimension_exists = (
		china_relationship_data.has(
			"military"
		)
	)

	_out([
		"India relationship military dimension: ",
		"PASS"
		if india_military_dimension_exists
		else "FAIL"
	])

	_out([
		"China relationship military dimension: ",
		"PASS"
		if china_military_dimension_exists
		else "FAIL"
	])


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var passed = (
		india_formula_pass
		and china_formula_pass
		and reciprocal_pass
		and range_pass
		and india_military_dimension_exists
		and china_military_dimension_exists
	)

	_out([""])
	_out(["================================"])

	if passed:
		_out([
			"MILITARY → RELATIONSHIP TEST PASSED"
		])
	else:
		_out([
			"MILITARY → RELATIONSHIP TEST FAILED"
		])

	_out(["================================"])
