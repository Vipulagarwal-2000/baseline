class_name MilitaryInfluenceTest
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
	_out(["MILITARY → INFLUENCE TEST"])
	_out(["================================"])

	if world == null:
		push_error(
			"MilitaryInfluenceTest: World is null."
		)
		return

	if simulation == null:
		push_error(
			"MilitaryInfluenceTest: Simulation is null."
		)
		return


	# ========================================================
	# FIND COUNTRIES
	# ========================================================

	var india = world.get_entity("india")
	var china = world.get_entity("china")

	if india == null:
		push_error(
			"MilitaryInfluenceTest: India not found."
		)
		return

	if china == null:
		push_error(
			"MilitaryInfluenceTest: China not found."
		)
		return


	# ========================================================
	# CHECK COMPONENTS
	# ========================================================

	var india_military = (
		india.get_component("military")
	)

	var india_economy = (
		india.get_component("economy")
	)

	var china_economy = (
		china.get_component("economy")
	)

	if india_military == null:
		push_error(
			"MilitaryInfluenceTest: "
			+ "India military component missing."
		)
		return

	if india_economy == null:
		push_error(
			"MilitaryInfluenceTest: "
			+ "India economy component missing."
		)
		return

	if china_economy == null:
		push_error(
			"MilitaryInfluenceTest: "
			+ "China economy component missing."
		)
		return

	_out(["India military component: PASS"])
	_out(["India economy component: PASS"])
	_out(["China economy component: PASS"])


	# ========================================================
	# CHECK INFLUENCE SYSTEM
	# ========================================================

	var influence_system = (
		simulation.get_system(
			"influence_system"
		)
	)

	if influence_system == null:
		push_error(
			"MilitaryInfluenceTest: "
			+ "InfluenceSystem not found."
		)
		return

	_out(["Influence system: PASS"])


	# ========================================================
	# CHECK RELATIONSHIP
	# ========================================================

	var relationship_data = (
		india.get_relationship_data(
			"china"
		)
	)

	if relationship_data.is_empty():
		push_error(
			"MilitaryInfluenceTest: "
			+ "India → China relationship missing."
		)
		return

	_out(["India → China relationship: PASS"])


	# ========================================================
	# BASELINE MILITARY STATE
	# ========================================================

	var original_military_power = float(
		india_military.get_state(
			"military_power",
			0.0
		)
	)

	var original_defensive_capability = float(
		india_military.get_state(
			"defensive_capability",
			0.0
		)
	)

	var original_power_projection = float(
		india_military.get_state(
			"power_projection",
			0.0
		)
	)

	_out([""])
	_out(["Initial military state:"])
	_out([
		"Military power: ",
		original_military_power
	])

	_out([
		"Defensive capability: ",
		original_defensive_capability
	])

	_out([
		"Power projection: ",
		original_power_projection
	])


	# ========================================================
	# BASELINE INFLUENCE
	# ========================================================

	influence_system.process_month(
		world
	)

	var baseline_influence = (
		influence_system.get_influence(
			india,
			"china"
		)
	)

	_out([""])
	_out([
		"Baseline India → China influence: ",
		baseline_influence
	])


	# ========================================================
	# LOW MILITARY CAPABILITY TEST
	# ========================================================

	india_military.set_state(
		"military_power",
		0.10
	)

	india_military.set_state(
		"defensive_capability",
		0.10
	)

	india_military.set_state(
		"power_projection",
		0.10
	)

	influence_system.process_month(
		world
	)

	var low_military_influence = (
		influence_system.get_influence(
			india,
			"china"
		)
	)

	_out([""])
	_out([
		"Low military capability influence: ",
		low_military_influence
	])


	# ========================================================
	# HIGH MILITARY CAPABILITY TEST
	# ========================================================

	india_military.set_state(
		"military_power",
		0.90
	)

	india_military.set_state(
		"defensive_capability",
		0.90
	)

	india_military.set_state(
		"power_projection",
		0.90
	)

	influence_system.process_month(
		world
	)

	var high_military_influence = (
		influence_system.get_influence(
			india,
			"china"
		)
	)

	_out([""])
	_out([
		"High military capability influence: ",
		high_military_influence
	])


	# ========================================================
	# CAUSAL RESPONSE
	# ========================================================

	var military_influence_response = (
		high_military_influence
		> low_military_influence
	)

	_out([
		"Military capability → influence response: ",
		"PASS"
		if military_influence_response
		else "FAIL"
	])


	# ========================================================
	# EXPECTED FACTOR TEST
	# ========================================================

	var expected_military_capability = (
		0.90 * 0.35
		+ 0.90 * 0.20
		+ 0.90 * 0.45
	)

	var expected_military_factor = (
		0.80
		+ expected_military_capability * 0.40
	)

	expected_military_factor = clamp(
		expected_military_factor,
		0.80,
		1.20
	)

	var low_military_capability = (
		0.10 * 0.35
		+ 0.10 * 0.20
		+ 0.10 * 0.45
	)

	var low_military_factor = (
		0.80
		+ low_military_capability * 0.40
	)

	low_military_factor = clamp(
		low_military_factor,
		0.80,
		1.20
	)

	_out([""])
	_out([
		"Expected low military factor: ",
		low_military_factor
	])

	_out([
		"Expected high military factor: ",
		expected_military_factor
	])


	# ========================================================
	# BASELINE FACTOR CALCULATION
	# ========================================================

	var relationship = float(
		relationship_data.get(
			"overall",
			0.0
		)
	)

	var relationship_factor = clamp(
		(relationship + 100.0) / 200.0,
		0.0,
		1.0
	)

	var diplomatic = float(
		relationship_data.get(
			"diplomatic",
			0.0
		)
	)

	var diplomatic_factor = clamp(
		(diplomatic + 100.0) / 200.0,
		0.0,
		1.0
	)

	var india_gdp = float(
		india_economy.get_state(
			"gdp",
			0.0
		)
	)

	var china_gdp = float(
		china_economy.get_state(
			"gdp",
			0.0
		)
	)

	var economic_power_factor = 1.0

	if india_gdp > 0.0 \
	and china_gdp > 0.0:

		var total_gdp = (
			india_gdp
			+ china_gdp
		)

		if total_gdp > 0.0:

			var india_share = (
				india_gdp
				/ total_gdp
			)

			economic_power_factor = (
				0.5
				+ india_share
			)

	var geographic_accessibility = max(
		0.0,
		float(
			relationship_data.get(
				"influence_accessibility",
				1.0
			)
		)
	)

	var strategic_interest = max(
		0.0,
		float(
			relationship_data.get(
				"strategic_interest",
				1.0
			)
		)
	)

	var relationship_power_projection = max(
		0.0,
		float(
			relationship_data.get(
				"power_projection",
				1.0
			)
		)
	)

	var shared_influence_base = (
		100.0
		* relationship_factor
		* diplomatic_factor
		* economic_power_factor
		* geographic_accessibility
		* strategic_interest
		* relationship_power_projection
	)

	var expected_low_influence = (
		shared_influence_base
		* low_military_factor
	)

	var expected_high_influence = (
		shared_influence_base
		* expected_military_factor
	)

	var low_formula_pass = is_equal_approx(
		low_military_influence,
		expected_low_influence
	)

	var high_formula_pass = is_equal_approx(
		high_military_influence,
		expected_high_influence
	)

	_out([
		"Low military influence formula: ",
		"PASS"
		if low_formula_pass
		else "FAIL"
	])

	_out([
		"High military influence formula: ",
		"PASS"
		if high_formula_pass
		else "FAIL"
	])


	# ========================================================
	# RANGE TEST
	# ========================================================

	var influence_range = (
		low_military_influence >= 0.0
		and low_military_influence <= 100.0
		and high_military_influence >= 0.0
		and high_military_influence <= 100.0
	)

	_out([
		"Influence range: ",
		"PASS"
		if influence_range
		else "FAIL"
	])


	# ========================================================
	# RESTORE MILITARY STATE
	# ========================================================

	india_military.set_state(
		"military_power",
		original_military_power
	)

	india_military.set_state(
		"defensive_capability",
		original_defensive_capability
	)

	india_military.set_state(
		"power_projection",
		original_power_projection
	)

	influence_system.process_month(
		world
	)

	_out([""])
	_out(["Original military state restored."])


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var passed = (
		military_influence_response
		and low_formula_pass
		and high_formula_pass
		and influence_range
	)

	_out([""])
	_out(["================================"])

	if passed:
		_out([
			"MILITARY → INFLUENCE TEST PASSED"
		])
	else:
		_out([
			"MILITARY → INFLUENCE TEST FAILED"
		])

	_out(["================================"])
