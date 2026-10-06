class_name MilitaryStrategyTest
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
	_out(["MILITARY → STRATEGY TEST"])
	_out(["================================"])

	if world == null:
		push_error(
			"MilitaryStrategyTest: World is null."
		)
		return

	if simulation == null:
		push_error(
			"MilitaryStrategyTest: Simulation is null."
		)
		return


	# ========================================================
	# FIND COUNTRY
	# ========================================================

	var india = world.get_entity("india")

	if india == null:
		push_error(
			"MilitaryStrategyTest: India not found."
		)
		return


	# ========================================================
	# CHECK SYSTEM
	# ========================================================

	var country_strategy_system = (
		simulation.get_system(
			"country_strategy_system"
		)
	)

	if country_strategy_system == null:
		push_error(
			"MilitaryStrategyTest: "
			+ "CountryStrategySystem not found."
		)
		return

	_out([
		"Country strategy system: PASS"
	])


	# ========================================================
	# CHECK COMPONENTS
	# ========================================================

	var military = (
		india.get_component("military")
	)

	if military == null:
		push_error(
			"MilitaryStrategyTest: "
			+ "India military component missing."
		)
		return

	_out([
		"India military component: PASS"
	])


	# ========================================================
	# RUN STRATEGY SYSTEM
	# ========================================================

	country_strategy_system.process_month(
		world
	)


	# ========================================================
	# CHECK STRATEGY PROFILE
	# ========================================================

	var profile = (
		country_strategy_system.get_strategy_profile(
			india
		)
	)

	if profile == null:
		push_error(
			"MilitaryStrategyTest: "
			+ "Strategy profile was not created."
		)
		return

	_out([
		"Strategy profile: PASS"
	])

	var military_priority = (
		profile.get_priority(
			"military"
		)
	)

	var military_action_preference = (
		profile.get_behavior("military_action")
	)

	var defensive_orientation = (
		profile.get_behavior(
			"defensive_orientation"
		)
	)

	_out([""])
	_out([
		"Military priority: ",
		military_priority
	])

	_out([
		"Military action preference: ",
		military_action_preference
	])

	_out([
		"Defensive orientation: ",
		defensive_orientation
	])


	# ========================================================
	# READ MILITARY STRATEGY SIGNAL
	# ========================================================

	var baseline_signal_data = (
		country_strategy_system.get_military_strategy_signal(
			india
		)
	)

	var signal_exists = (
		not baseline_signal_data.is_empty()
	)

	_out([""])
	_out([
		"Military strategy signal exists: ",
		"PASS"
		if signal_exists
		else "FAIL"
	])

	if not signal_exists:
		push_error(
			"MilitaryStrategyTest: "
			+ "Military strategy signal missing."
		)
		return


	# ========================================================
	# READ BASELINE SIGNALS
	# ========================================================

	var baseline_capability_signal = (
		country_strategy_system.get_military_strategy_value(
			india,
			"capability_signal"
		)
	)

	var baseline_strain_signal = (
		country_strategy_system.get_military_strategy_value(
			india,
			"strain_signal"
		)
	)

	var baseline_defensive_need = (
		country_strategy_system.get_military_strategy_value(
			india,
			"defensive_need"
		)
	)

	var baseline_projection_opportunity = (
		country_strategy_system.get_military_strategy_value(
			india,
			"projection_opportunity"
		)
	)

	var baseline_priority_signal = (
		country_strategy_system.get_military_strategy_value(
			india,
			"military_priority_signal"
		)
	)

	_out([""])
	_out(["Baseline military strategy signals:"])

	_out([
		"Capability signal: ",
		baseline_capability_signal
	])

	_out([
		"Strain signal: ",
		baseline_strain_signal
	])

	_out([
		"Defensive need: ",
		baseline_defensive_need
	])

	_out([
		"Projection opportunity: ",
		baseline_projection_opportunity
	])

	_out([
		"Military priority signal: ",
		baseline_priority_signal
	])


	# ========================================================
	# BASELINE RANGE TEST
	# ========================================================

	var baseline_range_pass = (
		baseline_capability_signal >= 0.0
		and baseline_capability_signal <= 1.0
		and baseline_strain_signal >= 0.0
		and baseline_strain_signal <= 1.0
		and baseline_defensive_need >= 0.0
		and baseline_defensive_need <= 1.0
		and baseline_projection_opportunity >= 0.0
		and baseline_projection_opportunity <= 1.0
		and baseline_priority_signal >= 0.0
		and baseline_priority_signal <= 1.0
	)

	_out([
		"Military strategy signal range: ",
		"PASS"
		if baseline_range_pass
		else "FAIL"
	])


	# ========================================================
	# STORE ORIGINAL MILITARY STATE
	# ========================================================

	var original_pressure = float(
		military.get_state(
			"military_pressure",
			0.20
		)
	)

	var original_exhaustion = float(
		military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var original_at_war = bool(
		military.get_state(
			"at_war",
			false
		)
	)


	# ========================================================
	# APPLY CONTROLLED MILITARY STRAIN SHOCK
	# ========================================================

	_out([""])
	_out([
		"Applying controlled military strategy shock..."
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
	# REPROCESS STRATEGY
	# ========================================================

	country_strategy_system.process_month(
		world
	)


	# ========================================================
	# READ SHOCKED SIGNALS
	# ========================================================

	var shocked_strain_signal = (
		country_strategy_system.get_military_strategy_value(
			india,
			"strain_signal"
		)
	)

	var shocked_priority_signal = (
		country_strategy_system.get_military_strategy_value(
			india,
			"military_priority_signal"
		)
	)

	var shocked_defensive_need = (
		country_strategy_system.get_military_strategy_value(
			india,
			"defensive_need"
		)
	)

	_out([""])
	_out(["Military strategy signals after shock:"])

	_out([
		"Strain signal: ",
		shocked_strain_signal
	])

	_out([
		"Defensive need: ",
		shocked_defensive_need
	])

	_out([
		"Military priority signal: ",
		shocked_priority_signal
	])


	# ========================================================
	# STRAIN RESPONSE TEST
	# ========================================================

	var strain_response_pass = (
		shocked_strain_signal
		> baseline_strain_signal
	)

	_out([
		"Military pressure → strain response: ",
		"PASS"
		if strain_response_pass
		else "FAIL"
	])


	# ========================================================
	# DEFENSIVE NEED RESPONSE TEST
	# ========================================================

	var defensive_response_pass = (
		shocked_defensive_need
		> baseline_defensive_need
	)

	_out([
		"Military pressure → defensive need response: ",
		"PASS"
		if defensive_response_pass
		else "FAIL"
	])


	# ========================================================
	# OVERALL PRIORITY RESPONSE TEST
	# ========================================================

	var priority_response_pass = (
		shocked_priority_signal
		> baseline_priority_signal
	)

	_out([
		"Military conditions → strategy priority response: ",
		"PASS"
		if priority_response_pass
		else "FAIL"
	])


	# ========================================================
	# SHOCKED RANGE TEST
	# ========================================================

	var shocked_range_pass = (
		shocked_strain_signal >= 0.0
		and shocked_strain_signal <= 1.0
		and shocked_defensive_need >= 0.0
		and shocked_defensive_need <= 1.0
		and shocked_priority_signal >= 0.0
		and shocked_priority_signal <= 1.0
	)

	_out([
		"Shocked strategy signal range: ",
		"PASS"
		if shocked_range_pass
		else "FAIL"
	])


	# ========================================================
	# RESTORE ORIGINAL MILITARY STATE
	# ========================================================

	military.set_state(
		"military_pressure",
		original_pressure
	)

	military.set_state(
		"war_exhaustion",
		original_exhaustion
	)

	military.set_state(
		"at_war",
		original_at_war
	)

	country_strategy_system.process_month(
		world
	)

	_out([""])
	_out([
		"Original military state restored."
	])


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var passed = (
		signal_exists
		and baseline_range_pass
		and strain_response_pass
		and defensive_response_pass
		and priority_response_pass
		and shocked_range_pass
	)

	_out([""])
	_out(["================================"])

	if passed:
		_out([
			"MILITARY → STRATEGY TEST PASSED"
		])
	else:
		_out([
			"MILITARY → STRATEGY TEST FAILED"
		])

	_out(["================================"])
