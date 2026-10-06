class_name MilitaryGovernmentFeedbackTest
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
	_out(["MILITARY → GOVERNMENT FEEDBACK TEST"])
	_out(["================================"])

	if world == null:
		push_error(
			"MilitaryGovernmentFeedbackTest: World is null."
		)
		return

	if simulation == null:
		push_error(
			"MilitaryGovernmentFeedbackTest: Simulation is null."
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
			"MilitaryGovernmentFeedbackTest: India not found."
		)
		return

	var government = india.get_component(
		"government"
	)

	var military = india.get_component(
		"military"
	)

	if government == null:
		push_error(
			"MilitaryGovernmentFeedbackTest: "
			+ "Government component missing."
		)
		return

	if military == null:
		push_error(
			"MilitaryGovernmentFeedbackTest: "
			+ "Military component missing."
		)
		return

	_out([
		"India government component: PASS"
	])

	_out([
		"India military component: PASS"
	])


	# ========================================================
	# INITIAL STATE
	# ========================================================

	var initial_pressure = float(
		government.get_state(
			"political_pressure",
			0.30
		)
	)

	var initial_stability = float(
		government.get_state(
			"stability",
			0.70
		)
	)

	var initial_approval = float(
		government.get_state(
			"approval",
			0.60
		)
	)

	var initial_military_pressure = float(
		military.get_state(
			"military_pressure",
			0.20
		)
	)

	var initial_war_exhaustion = float(
		military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var initial_at_war = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	_out([""])
	_out(["Initial government state:"])

	_out([
		"Political pressure: ",
		initial_pressure
	])

	_out([
		"Stability: ",
		initial_stability
	])

	_out([
		"Approval: ",
		initial_approval
	])

	_out([""])
	_out(["Initial military state:"])

	_out([
		"Military pressure: ",
		initial_military_pressure
	])

	_out([
		"War exhaustion: ",
		initial_war_exhaustion
	])

	_out([
		"At war: ",
		initial_at_war
	])


	# ========================================================
	# BASELINE MILITARY BURDEN
	# ========================================================

	var initial_burden = float(
		government.get_state(
			"military_burden",
			0.0
		)
	)

	_out([
		"Initial military burden: ",
		initial_burden
	])


	# ========================================================
	# CONTROLLED MILITARY SHOCK
	# ========================================================

	_out([""])
	_out([
		"Applying controlled military burden shock..."
	])

	military.set_state(
		"military_pressure",
		0.90
	)

	military.set_state(
		"war_exhaustion",
		0.60
	)

	military.set_state(
		"at_war",
		true
	)

	_out([
		"Military pressure set to: ",
		military.get_state(
			"military_pressure",
			0.0
		)
	])

	_out([
		"War exhaustion set to: ",
		military.get_state(
			"war_exhaustion",
			0.0
		)
	])

	_out([
		"At war set to: ",
		military.get_state(
			"at_war",
			false
		)
	])


	# ========================================================
	# RUN ONE MONTH
	# ========================================================

	var date_before = world.get_date_string()

	simulation.tick_month()

	var date_after = world.get_date_string()

	_out([""])
	_out([
		"Military → government test tick: ",
		date_before,
		" -> ",
		date_after
	])


	# ========================================================
	# FINAL STATE
	# ========================================================

	var final_pressure = float(
		government.get_state(
			"political_pressure",
			0.0
		)
	)

	var final_stability = float(
		government.get_state(
			"stability",
			0.0
		)
	)

	var final_approval = float(
		government.get_state(
			"approval",
			0.0
		)
	)

	var final_burden = float(
		government.get_state(
			"military_burden",
			0.0
		)
	)

	_out([""])
	_out([
		"Government state after military shock:"
	])

	_out([
		"Political pressure: ",
		final_pressure
	])

	_out([
		"Stability: ",
		final_stability
	])

	_out([
		"Approval: ",
		final_approval
	])

	_out([
		"Military burden: ",
		final_burden
	])


	# ========================================================
	# MILITARY BURDEN TEST
	# ========================================================

	var burden_response = (
		final_burden > initial_burden
	)

	_out([""])
	_out([
		"Military burden causal response: ",
		"PASS" if burden_response else "FAIL"
	])


	# ========================================================
	# POLITICAL PRESSURE TEST
	# ========================================================

	var pressure_response = (
		final_pressure > initial_pressure
	)

	_out([
		"Military → political pressure response: ",
		"PASS" if pressure_response else "FAIL"
	])


	# ========================================================
	# GOVERNMENT STATE RANGE TESTS
	#
	# Stability and approval are affected by multiple
	# government signals. Therefore the test does not
	# require them to decrease after a military shock.
	# It verifies that the values remain valid and that
	# the government continues responding through pressure.
	# ========================================================

	var stability_range = (
		final_stability >= 0.0
		and final_stability <= 1.0
	)

	var approval_range = (
		final_approval >= 0.0
		and final_approval <= 1.0
	)

	_out([
		"Government stability range: ",
		"PASS" if stability_range else "FAIL"
	])

	_out([
		"Government approval range: ",
		"PASS" if approval_range else "FAIL"
	])


	# ========================================================
	# MILITARY BURDEN RANGE
	# ========================================================

	var burden_range = (
		final_burden >= 0.0
		and final_burden <= 1.0
	)

	_out([
		"Military burden range: ",
		"PASS" if burden_range else "FAIL"
	])


	# ========================================================
	# GOVERNMENT RESPONSE CONSISTENCY
	#
	# The primary observable Government response to the
	# military burden in this MVP is increased political
	# pressure. Stability and approval remain bounded
	# because other government signals also affect them.
	# ========================================================

	var government_response = (
		burden_response
		and pressure_response
	)

	_out([
		"Military → government response path: ",
		"PASS" if government_response else "FAIL"
	])


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var passed = (
		burden_response
		and pressure_response
		and stability_range
		and approval_range
		and burden_range
		and government_response
	)

	_out([""])
	_out(["================================"])

	if passed:
		_out([
			"MILITARY → GOVERNMENT "
			+ "FEEDBACK TEST PASSED"
		])
	else:
		_out([
			"MILITARY → GOVERNMENT "
			+ "FEEDBACK TEST FAILED"
		])

	_out(["================================"])
