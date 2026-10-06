class_name MilitaryGovernmentTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


func run(world: WorldState, simulation) -> bool:

	_out([""])
	_out(["================================"])
	_out(["MILITARY GOVERNMENT TEST"])
	_out(["================================"])

	if world == null:
		_out(["World state: FAIL | world is null"])
		return false

	if simulation == null:
		_out(["Simulation: FAIL | simulation is null"])
		return false

	var india = world.get_entity("india")

	if india == null:
		_out(["India entity: FAIL"])
		return false

	var government = india.get_component("government")
	var military = india.get_component("military")

	if government == null:
		_out(["India government component: FAIL"])
		return false

	if military == null:
		_out(["India military component: FAIL"])
		return false

	_out(["India government component: PASS"])
	_out(["India military component: PASS"])


	# ============================================================
	# GOVERNMENT INPUTS
	# ============================================================

	var policy_capacity = float(
		government.get_state(
			"policy_capacity",
			0.50
		)
	)

	var institutional_strength = float(
		government.get_state(
			"institutional_strength",
			0.50
		)
	)

	var government_mobilization = float(
		government.get_state(
			"mobilization_capacity",
			0.50
		)
	)

	var political_pressure = float(
		government.get_state(
			"political_pressure",
			0.30
		)
	)

	_out([""])
	_out(["Government inputs:"])
	_out(["Policy capacity: ", policy_capacity])
	_out(["Institutional strength: ", institutional_strength])
	_out(["Mobilization capacity: ", government_mobilization])
	_out(["Political pressure: ", political_pressure])


	var inputs_valid = (
		policy_capacity >= 0.0
		and policy_capacity <= 1.0
		and institutional_strength >= 0.0
		and institutional_strength <= 1.0
		and government_mobilization >= 0.0
		and government_mobilization <= 1.0
		and political_pressure >= 0.0
		and political_pressure <= 1.0
	)

	if inputs_valid:
		_out(["Government input ranges: PASS"])
	else:
		_out(["Government input ranges: FAIL"])
		return false


	# ============================================================
	# EXPECTED GOVERNMENT SPENDING FACTOR
	# ============================================================

	var expected_spending_factor = (
		policy_capacity * 0.35
		+ institutional_strength * 0.25
		+ government_mobilization * 0.25
		+ (1.0 - political_pressure) * 0.15
	)

	expected_spending_factor = clamp(
		expected_spending_factor,
		0.0,
		1.0
	)

	_out([""])
	_out([
		"Expected government spending factor: ",
		expected_spending_factor
	])


	# ============================================================
	# MILITARY INITIAL STATE
	# ============================================================

	var military_spending_before = float(
		military.get_state(
			"military_spending",
			0.30
		)
	)

	var readiness_before = float(
		military.get_state(
			"readiness",
			0.60
		)
	)

	var mobilization_before = float(
		military.get_state(
			"mobilization_capacity",
			0.50
		)
	)

	_out([""])
	_out(["Military state before tick:"])
	_out(["Military spending: ", military_spending_before])
	_out(["Readiness: ", readiness_before])
	_out(["Mobilization capacity: ", mobilization_before])


	# ============================================================
	# RUN ONE MONTH
	# ============================================================

	var date_before = world.get_date_string()

	simulation.tick_month()

	var date_after = world.get_date_string()

	_out([""])
	_out([
		"Government → military test tick: ",
		date_before,
		" -> ",
		date_after
	])


	# ============================================================
	# MILITARY RESULTS
	# ============================================================

	var military_spending_after = float(
		military.get_state(
			"military_spending",
			0.0
		)
	)

	var readiness_after = float(
		military.get_state(
			"readiness",
			0.0
		)
	)

	var mobilization_after = float(
		military.get_state(
			"mobilization_capacity",
			0.0
		)
	)

	var actual_spending_factor = float(
		military.get_state(
			"government_spending_factor",
			-1.0
		)
	)

	var military_pressure = float(
		military.get_state(
			"military_pressure",
			0.0
		)
	)

	_out([""])
	_out(["Military state after tick:"])
	_out(["Military spending: ", military_spending_after])
	_out(["Readiness: ", readiness_after])
	_out(["Mobilization capacity: ", mobilization_after])
	_out(["Military pressure: ", military_pressure])
	_out([
		"Government spending factor: ",
		actual_spending_factor
	])


	# ============================================================
	# SPENDING FACTOR TEST
	# ============================================================

	var spending_factor_matches = is_equal_approx(
		actual_spending_factor,
		expected_spending_factor
	)

	if spending_factor_matches:
		_out(["Government → spending factor formula: PASS"])
	else:
		_out(["Government → spending factor formula: FAIL"])
		_out([
			"Expected: ",
			expected_spending_factor
		])
		_out([
			"Actual: ",
			actual_spending_factor
		])
		return false


	# ============================================================
	# SPENDING CAUSAL TEST
	# ============================================================

	var spending_changed = not is_equal_approx(
		military_spending_before,
		military_spending_after
	)

	if spending_changed:
		_out([
			"Government → military spending causal response: PASS"
		])
	else:
		_out([
			"Government → military spending causal response: FAIL"
		])
		return false


	# ============================================================
	# READINESS RANGE
	# ============================================================

	var readiness_valid = (
		readiness_after >= 0.0
		and readiness_after <= 1.0
	)

	if readiness_valid:
		_out(["Government-adjusted readiness range: PASS"])
	else:
		_out(["Government-adjusted readiness range: FAIL"])
		return false


	# ============================================================
	# MOBILIZATION RANGE
	# ============================================================

	var mobilization_valid = (
		mobilization_after >= 0.0
		and mobilization_after <= 1.0
	)

	if mobilization_valid:
		_out([
			"Government-adjusted mobilization range: PASS"
		])
	else:
		_out([
			"Government-adjusted mobilization range: FAIL"
		])
		return false


	# ============================================================
	# MILITARY PRESSURE RANGE
	# ============================================================

	var pressure_valid = (
		military_pressure >= 0.0
		and military_pressure <= 1.0
	)

	if pressure_valid:
		_out(["Military pressure range: PASS"])
	else:
		_out(["Military pressure range: FAIL"])
		return false


	# ============================================================
	# FINAL RESULT
	# ============================================================

	_out([""])
	_out(["MILITARY GOVERNMENT TEST PASSED"])
	_out(["================================"])

	return true
