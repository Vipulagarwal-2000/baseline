class_name AIMonthlyExecutionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> void:

	TestLogger.section(
		"AI MONTHLY EXECUTION TEST"
	)

	if world == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — world is null."
		)

		return

	if simulation == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — simulation is null."
		)

		return


	# --------------------------------------------------
	# FIND INDIA
	# --------------------------------------------------

	var india = world.get_entity(
		"india"
	)

	if india == null:

		TestLogger.write_line(
			"India: FAILED — country not found."
		)

		return

	TestLogger.write_line(
		"India found: "
		+ str(india.name)
	)


	# --------------------------------------------------
	# FIND REQUIRED SYSTEMS
	# --------------------------------------------------

	var strategy_system = simulation.get_system(
		"country_strategy_system"
	)

	var goal_system = simulation.get_system(
		"goal_system"
	)

	var decision_system = simulation.get_system(
		"decision_system"
	)

	var ai_system = simulation.get_system(
		"ai_decision_system"
	)


	TestLogger.write_line(
		"Strategy system: "
		+ (
			"FOUND"
			if strategy_system != null
			else "MISSING"
		)
	)

	TestLogger.write_line(
		"Goal system: "
		+ (
			"FOUND"
			if goal_system != null
			else "MISSING"
		)
	)

	TestLogger.write_line(
		"Decision system: "
		+ (
			"FOUND"
			if decision_system != null
			else "MISSING"
		)
	)

	TestLogger.write_line(
		"AI decision system: "
		+ (
			"FOUND"
			if ai_system != null
			else "MISSING"
		)
	)


	if strategy_system == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — strategy system missing."
		)

		return

	if goal_system == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — goal system missing."
		)

		return

	if decision_system == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — decision system missing."
		)

		return

	if ai_system == null:

		TestLogger.write_line(
			"AI monthly execution test: FAILED — AI decision system missing."
		)

		return


	# --------------------------------------------------
	# CLEAR OLD DECISION STATE
	# --------------------------------------------------

	india.set_sim_metadata(
		"decision_options",
		[]
	)

	india.set_sim_metadata(
		"selected_decision",
		null
	)


	# --------------------------------------------------
	# RECORD START DATE
	# --------------------------------------------------

	var start_date = world.get_date_string()

	TestLogger.write_line("")
	TestLogger.write_line(
		"Start date: "
		+ str(start_date)
	)


	# --------------------------------------------------
	# VERIFY STRATEGY BEFORE TICK
	# --------------------------------------------------

	var strategy_before = india.get_sim_metadata(
		"strategy_profile",
		null
	)

	var goal_count_before = india.goals.size()


	TestLogger.write_line(
		"Strategy profile before tick: "
		+ (
			"EXISTS"
			if strategy_before != null
			else "MISSING"
		)
	)

	TestLogger.write_line(
		"Goal count before tick: "
		+ str(goal_count_before)
	)


	# --------------------------------------------------
	# RUN ONE REAL SIMULATION MONTH
	# --------------------------------------------------

	TestLogger.write_line("")

	TestLogger.write_line(
		"Running one normal simulation.tick_month()..."
	)

	simulation.tick_month()


	# --------------------------------------------------
	# DATE CHECK
	# --------------------------------------------------

	var end_date = world.get_date_string()

	TestLogger.write_line("")
	TestLogger.write_line(
		"End date: "
		+ str(end_date)
	)

	var date_advanced = (
		end_date != start_date
	)

	TestLogger.write_line(
		"Monthly tick advanced date: "
		+ (
			"PASS"
			if date_advanced
			else "FAIL"
		)
	)


	# --------------------------------------------------
	# STRATEGY CHECK
	# --------------------------------------------------

	var strategy_after = india.get_sim_metadata(
		"strategy_profile",
		null
	)

	var strategy_exists = (
		strategy_after != null
	)

	TestLogger.write_line(
		"Strategy recalculated/present: "
		+ (
			"PASS"
			if strategy_exists
			else "FAIL"
		)
	)


	# --------------------------------------------------
	# GOAL CHECK
	# --------------------------------------------------

	var goal_count_after = india.goals.size()

	TestLogger.write_line(
		"Goal count after tick: "
		+ str(goal_count_after)
	)

	var goals_present = (
		goal_count_after > 0
	)

	TestLogger.write_line(
		"Goals available after monthly tick: "
		+ (
			"PASS"
			if goals_present
			else "FAIL"
		)
	)


	# --------------------------------------------------
	# DECISION OPTIONS CHECK
	# --------------------------------------------------

	var options = india.get_sim_metadata(
		"decision_options",
		[]
	)

	if typeof(options) != TYPE_ARRAY:
		options = []

	TestLogger.write_line(
		"Decision options after tick: "
		+ str(options.size())
	)

	var options_generated = (
		options.size() > 0
	)

	TestLogger.write_line(
		"Decision options generated: "
		+ (
			"PASS"
			if options_generated
			else "FAIL"
		)
	)


	# --------------------------------------------------
	# SELECTED DECISION CHECK
	# --------------------------------------------------

	var selected_decision = india.get_sim_metadata(
		"selected_decision",
		null
	)

	var decision_selected = (
		selected_decision != null
	)

	TestLogger.write_line(
		"AI selected decision: "
		+ (
			"PASS"
			if decision_selected
			else "FAIL"
		)
	)


	if selected_decision != null:

		TestLogger.write_line(
			"Selected decision ID: "
			+ str(selected_decision.id)
		)

		TestLogger.write_line(
			"Selected action type: "
			+ str(selected_decision.action_type)
		)


	# --------------------------------------------------
	# FINAL RESULT
	# --------------------------------------------------

	var passed = (
		date_advanced
		and strategy_exists
		and goals_present
		and options_generated
		and decision_selected
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		"================================"
	)

	if passed:

		TestLogger.write_line(
			"AI MONTHLY EXECUTION TEST PASSED"
		)

	else:

		TestLogger.write_line(
			"AI MONTHLY EXECUTION TEST FAILED"
		)

	TestLogger.write_line(
		"================================"
	)
