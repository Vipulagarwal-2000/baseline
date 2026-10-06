class_name MilitaryGoalTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


func run_test(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["================================"])
	_out(["MILITARY → GOALS TEST"])
	_out(["================================"])


	if world == null:

		push_error(
			"MilitaryGoalTest: World is null."
		)

		return false


	if simulation == null:

		push_error(
			"MilitaryGoalTest: Simulation is null."
		)

		return false


	# ========================================================
	# GET INDIA
	# ========================================================

	var india = world.get_entity("india")


	if india == null:

		push_error(
			"MilitaryGoalTest: India not found."
		)

		return false


	_out([
		"India found: ",
		india.name
	])


	# ========================================================
	# GET SYSTEMS
	# ========================================================

	var strategy_system = (
		simulation.get_system(
			"country_strategy_system"
		)
	)

	var goal_system = (
		simulation.get_system(
			"goal_system"
		)
	)


	if strategy_system == null:

		push_error(
			"MilitaryGoalTest: CountryStrategySystem not found."
		)

		return false


	if goal_system == null:

		push_error(
			"MilitaryGoalTest: GoalSystem not found."
		)

		return false


	_out([
		"CountryStrategySystem found: PASS"
	])

	_out([
		"GoalSystem found: PASS"
	])


	# ========================================================
	# FIND OR CREATE MILITARY GOAL
	# ========================================================

	var military_goal = null


	for goal in india.goals:

		if goal == null:
			continue


		if not goal is SimGoal:
			continue


		if goal.goal_type == "military":

			military_goal = goal

			break


	if military_goal == null:

		military_goal = SimGoal.new(
			"test_military_security",
			"Military Security",
			"military"
		)

		military_goal.set_priority(
			0.60
		)

		military_goal.set_importance(
			0.80
		)

		india.goals.append(
			military_goal
		)


		_out([
			"Created temporary military goal."
		])

	else:

		_out([
			"Existing military goal found: ",
			military_goal.id
		])


	# ========================================================
	# BASELINE
	# ========================================================

	var base_priority = (
		military_goal.priority
	)


	_out([
		"Base goal priority: ",
		base_priority
	])


	if base_priority < 0.0:

		push_error(
			"MilitaryGoalTest: Invalid base priority."
		)

		return false


	if base_priority > 1.0:

		push_error(
			"MilitaryGoalTest: Invalid base priority range."
		)

		return false


	# ========================================================
	# SAVE MILITARY STATE
	# ========================================================

	var military = india.get_component(
		"military"
	)


	if military == null:

		push_error(
			"MilitaryGoalTest: India military component missing."
		)

		return false


	var original_pressure = float(
		military.get_state(
			"military_pressure",
			0.20
		)
	)


	var original_exhaustion = float(
		military.get_state(
			"war_exhaustion",
			0.00
		)
	)


	var original_at_war = bool(
		military.get_state(
			"at_war",
			false
		)
	)


	# ========================================================
	# BASELINE STRATEGY
	# ========================================================

	strategy_system.process_month(
		world
	)


	goal_system.process_month(
		world
	)


	var baseline_dynamic_modifier = (
		goal_system.get_dynamic_goal_modifier(
			india,
			military_goal
		)
	)


	var baseline_effective_priority = (
		goal_system.get_effective_goal_priority(
			india,
			military_goal
		)
	)


	_out([
		"Baseline dynamic modifier: ",
		baseline_dynamic_modifier
	])

	_out([
		"Baseline effective priority: ",
		baseline_effective_priority
	])


	# ========================================================
	# MILITARY SHOCK
	# ========================================================

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
		"Applied military shock."
	])


	# ========================================================
	# UPDATE STRATEGY
	# ========================================================

	strategy_system.process_month(
		world
	)


	var strategy_signal = india.get_sim_metadata(
		"military_strategy_signal",
		{}
	)


	if typeof(strategy_signal) != TYPE_DICTIONARY:

		push_error(
			"MilitaryGoalTest: Military strategy signal missing."
		)

		return false


	var shocked_priority_signal = float(
		strategy_signal.get(
			"military_priority_signal",
			0.0
		)
	)


	_out([
		"Shocked military priority signal: ",
		shocked_priority_signal
	])


	# ========================================================
	# UPDATE GOALS
	# ========================================================

	goal_system.process_month(
		world
	)


	var shocked_dynamic_modifier = (
		goal_system.get_dynamic_goal_modifier(
			india,
			military_goal
		)
	)


	var shocked_effective_priority = (
		goal_system.get_effective_goal_priority(
			india,
			military_goal
		)
	)


	_out([
		"Shocked dynamic modifier: ",
		shocked_dynamic_modifier
	])

	_out([
		"Shocked effective priority: ",
		shocked_effective_priority
	])


	# ========================================================
	# TEST 1 — MILITARY SIGNAL EXISTS
	# ========================================================

	if shocked_priority_signal <= 0.0:

		push_error(
			"MilitaryGoalTest: Military priority signal did not activate."
		)

		return false


	_out([
		"Military strategy signal activation: PASS"
	])


	# ========================================================
	# TEST 2 — DYNAMIC MODIFIER INCREASES
	# ========================================================

	if shocked_dynamic_modifier <= baseline_dynamic_modifier:

		push_error(
			"MilitaryGoalTest: Military goal modifier did not increase."
		)

		return false


	_out([
		"Military goal dynamic modifier response: PASS"
	])


	# ========================================================
	# TEST 3 — EFFECTIVE PRIORITY INCREASES
	# ========================================================

	if shocked_effective_priority <= baseline_effective_priority:

		push_error(
			"MilitaryGoalTest: Effective military goal priority did not increase."
		)

		return false


	_out([
		"Military goal effective priority response: PASS"
	])


	# ========================================================
	# TEST 4 — BASE PRIORITY IS UNCHANGED
	# ========================================================

	if not is_equal_approx(
		military_goal.priority,
		base_priority
	):

		push_error(
			"MilitaryGoalTest: Base goal priority was modified."
		)

		return false


	_out([
		"Base goal priority preservation: PASS"
	])


	# ========================================================
	# TEST 5 — EFFECTIVE PRIORITY RANGE
	# ========================================================

	if shocked_effective_priority < 0.0:

		push_error(
			"MilitaryGoalTest: Effective priority below 0."
		)

		return false


	if shocked_effective_priority > 1.0:

		push_error(
			"MilitaryGoalTest: Effective priority above 1."
		)

		return false


	_out([
		"Effective priority range: PASS"
	])


	# ========================================================
	# RESTORE MILITARY STATE
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


	strategy_system.process_month(
		world
	)


	goal_system.process_month(
		world
	)


	var restored_dynamic_modifier = (
		goal_system.get_dynamic_goal_modifier(
			india,
			military_goal
		)
	)


	var restored_effective_priority = (
		goal_system.get_effective_goal_priority(
			india,
			military_goal
		)
	)


	_out([
		"Restored dynamic modifier: ",
		restored_dynamic_modifier
	])

	_out([
		"Restored effective priority: ",
		restored_effective_priority
	])


	# ========================================================
	# TEST 6 — RESTORATION
	# ========================================================

	if not is_equal_approx(
		restored_effective_priority,
		baseline_effective_priority
	):

		push_error(
			"MilitaryGoalTest: Goal priority did not restore."
		)

		return false


	_out([
		"Military goal restoration: PASS"
	])


	# ========================================================
	# TEST 7 — BASE GOAL STILL UNCHANGED
	# ========================================================

	if not is_equal_approx(
		military_goal.priority,
		base_priority
	):

		push_error(
			"MilitaryGoalTest: Base priority changed after restoration."
		)

		return false


	_out([
		"Final base priority preservation: PASS"
	])


	_out([""])
	_out([
		"MILITARY → GOALS TEST PASSED"
	])
	_out([""])

	return true
