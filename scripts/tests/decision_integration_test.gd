class_name DecisionIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> void:

	print("")
	print("================================")
	print("DECISION / AI INTEGRATION TEST")
	print("================================")

	if world == null:
		print("ERROR: World is null.")
		return

	if simulation == null:
		print("ERROR: SimulationEngine is null.")
		return

	var india = world.get_entity("india")

	if india == null:
		print("ERROR: India not found.")
		return

	print("India found: ", india.name)


	# --------------------------------------------------
	# FIND SYSTEMS
	# --------------------------------------------------

	var goal_system = _find_system(
		world,
		simulation,
		"goal_system"
	)

	var strategy_system = _find_system(
		world,
		simulation,
		"country_strategy_system"
	)

	var decision_system = _find_system(
		world,
		simulation,
		"decision_system"
	)

	var trajectory_system = _find_system(
		world,
		simulation,
		"decision_trajectory_system"
	)

	var ai_system = _find_system(
		world,
		simulation,
		"ai_decision_system"
	)

	var memory_system = _find_system(
		world,
		simulation,
		"ai_memory_system"
	)

	var government_system = _find_government_system(
		world,
		simulation
	)


	# --------------------------------------------------
	# GOAL
	# --------------------------------------------------

	var economic_goal = SimGoal.new(
		"india_economic_growth",
		"Economic Growth",
		"economic"
	)

	economic_goal.set_description(
		"Improve India's economic position."
	)

	economic_goal.set_priority(
		0.8
	)

	economic_goal.set_importance(
		0.9
	)

	if goal_system != null:

		var goal_added = goal_system.add_goal(
			india,
			economic_goal
		)

		print(
			"Goal added through GoalSystem: ",
			goal_added
		)

	else:

		print(
			"Goal system not directly accessible; adding goal manually."
		)

		if not india.goals.has(
			economic_goal
		):
			india.goals.append(
				economic_goal
			)

	print(
		"Goal count: ",
		india.goals.size()
	)


	# --------------------------------------------------
	# STRATEGY
	# --------------------------------------------------

	if strategy_system != null:
		strategy_system.process_month(world)

		strategy_system.set_priority(
		india,
		"economic",
		0.7
	)

		strategy_system.set_priority(
		india,
		"diplomatic",
		0.6
	)

		strategy_system.set_behavior(
		india,
		"risk_tolerance",
		0.5
	)

	var strategy_profile = india.get_sim_metadata(
		"strategy_profile",
		null
	)

	if strategy_profile != null:

		if strategy_profile is CountryStrategyProfile:

			print(
				"Economic priority: ",
				strategy_profile.economic_priority
			)

			print(
				"Diplomatic priority: ",
				strategy_profile.diplomatic_priority
			)

			print(
				"Risk tolerance: ",
				strategy_profile.risk_tolerance
			)

		else:

			print(
				"Strategy profile: INVALID TYPE"
			)

	else:

		print(
			"Strategy profile: NOT FOUND"
		)


	# --------------------------------------------------
	# DECISION OPTIONS
	# --------------------------------------------------

	var options: Array = []


	var trade_option = DecisionOption.new(
		"expand_trade",
		"Expand Trade",
		"economic"
	)

	trade_option.description = "Increase economic cooperation and trade with China."

	trade_option.actor_id = "india"
	trade_option.target_id = "china"

	trade_option.base_score = 1.0

	trade_option.metadata = {
		"risk": 0.20,
		"uncertainty": 0.10
	}


	var diplomatic_option = DecisionOption.new(
		"diplomatic_outreach",
		"Diplomatic Outreach",
		"diplomatic"
	)

	diplomatic_option.description = "Improve diplomatic relations with China."

	diplomatic_option.actor_id = "india"
	diplomatic_option.target_id = "china"

	diplomatic_option.base_score = 1.0

	diplomatic_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}


	options.append(
		trade_option
	)

	options.append(
		diplomatic_option
	)

	print(
		"Decision options created: ",
		options.size()
	)


	# Store options in simulation metadata.

	india.set_sim_metadata(
		"decision_options",
		options
	)


	# --------------------------------------------------
	# EVALUATE OPTIONS
	# --------------------------------------------------

	if decision_system != null:

		var ranked_options = decision_system.rank_options(
			world,
			india,
			options
		)

		print(
			"Ranked options: ",
			ranked_options.size()
		)

		for option in ranked_options:

			print(
				"Option: ",
				option.id,
				" | Score: ",
				option.final_score
			)

	
	# --------------------------------------------------
	# MILITARY → AI DECISION EVALUATION
	# --------------------------------------------------

	print("")
	print("==============================")
	print("MILITARY → AI DECISION EVALUATION")
	print("==============================")

	var military_evaluator = DecisionEvaluator.new()

	var india_military = india.get_component(
		"military"
	)

	if india_military == null:

		print(
			"India military component: MISSING"
		)

	else:

		print(
			"India military component: FOUND"
		)

		var military_option = DecisionOption.new(
			"military_diagnostic",
			"Military Diagnostic",
			"military"
		)

		military_option.actor_id = "india"
		military_option.target_id = "china"
		military_option.base_score = 1.0

		# --------------------------------------------------
		# BASELINE
		# --------------------------------------------------

		var baseline_military_score = (
			military_evaluator.evaluate_option(
				world,
				india,
				military_option
			)
		)

		print("")
		print(
			"Baseline military AI score: ",
			baseline_military_score
		)

		# --------------------------------------------------
		# READ BASELINE STRATEGY SIGNAL
		# --------------------------------------------------

		var baseline_strategy_signal = (
			india.get_sim_metadata(
				"military_strategy_signal",
				{}
			)
		)

		var baseline_priority_signal = 0.0

		if typeof(baseline_strategy_signal) == TYPE_DICTIONARY:

			baseline_priority_signal = clamp(
				float(
					baseline_strategy_signal.get(
						"military_priority_signal",
						0.0
					)
				),
				0.0,
				1.0
			)

		print(
			"Baseline military priority signal: ",
			baseline_priority_signal
		)

		# --------------------------------------------------
		# STORE ORIGINAL MILITARY STATE
		# --------------------------------------------------

		var original_pressure = float(
			india_military.get_state(
				"military_pressure",
				0.20
			)
		)

		var original_exhaustion = float(
			india_military.get_state(
				"war_exhaustion",
				0.0
			))

		var original_at_war = bool(
			india_military.get_state(
				"at_war",
				false
			))

		# --------------------------------------------------
		# APPLY CONTROLLED MILITARY SHOCK
		# --------------------------------------------------

		print("")
		print(
			"Applying military decision shock..."
		)

		india_military.set_state(
			"military_pressure",
			0.90
		)

		india_military.set_state(
			"war_exhaustion",
			0.60
		)

		india_military.set_state(
			"at_war",
			true
		)

		# Recalculate the dynamic strategy signal
		# before evaluating the decision again.

		if strategy_system != null:

			strategy_system.process_month(
				world
			)

		# --------------------------------------------------
		# SHOCKED EVALUATION
		# --------------------------------------------------

		var shocked_military_score = (
			military_evaluator.evaluate_option(
				world,
				india,
				military_option
			)
		)

		var shocked_strategy_signal = (
			india.get_sim_metadata(
				"military_strategy_signal",
				{}
			)
		)

		var shocked_priority_signal = 0.0

		if typeof(shocked_strategy_signal) == TYPE_DICTIONARY:

			shocked_priority_signal = clamp(
				float(
					shocked_strategy_signal.get(
						"military_priority_signal",
						0.0
					)
				),
				0.0,
				1.0
			)

		print("")
		print(
			"Shocked military priority signal: ",
			shocked_priority_signal
		)

		print(
			"Shocked military AI score: ",
			shocked_military_score
		)

		# --------------------------------------------------
		# STRATEGY SIGNAL RESPONSE
		# --------------------------------------------------

		var strategy_signal_response_pass = (
			shocked_priority_signal
			> baseline_priority_signal
		)

		print(
			"Military conditions → strategy signal: ",
			"PASS"
			if strategy_signal_response_pass
			else "FAIL"
		)

		# --------------------------------------------------
		# AI SCORE RESPONSE
		# --------------------------------------------------

		var military_score_response_pass = (
			shocked_military_score
			> baseline_military_score
		)

		print(
			"Strategy signal → military AI score: ",
			"PASS"
			if military_score_response_pass
			else "FAIL"
		)

		# --------------------------------------------------
		# RANGE TEST
		# --------------------------------------------------

		var military_score_range_pass = (
			baseline_military_score >= -INF
			and shocked_military_score >= -INF
		)

		print(
			"Military AI score range: ",
			"PASS"
			if military_score_range_pass
			else "FAIL"
		)

		# --------------------------------------------------
		# RESTORE ORIGINAL MILITARY STATE
		# --------------------------------------------------

		india_military.set_state(
			"military_pressure",
			original_pressure
		)

		india_military.set_state(
			"war_exhaustion",
			original_exhaustion
		)

		india_military.set_state(
			"at_war",
			original_at_war
		)

		if strategy_system != null:

			strategy_system.process_month(
				world
			)

		print("")
		print(
			"Original military state restored."
		)

		# --------------------------------------------------
		# FINAL MILITARY EVALUATION RESULT
		# --------------------------------------------------

		var military_ai_test_passed = (
			strategy_signal_response_pass
			and military_score_response_pass
			and military_score_range_pass
		)

		print("")
		print("==============================")

		if military_ai_test_passed:

			print(
				"MILITARY → AI DECISION EVALUATION PASSED"
			)

		else:

			print(
				"MILITARY → AI DECISION EVALUATION FAILED"
			)

		print("==============================")



	# --------------------------------------------------
	# MILITARY → GOALS
	# --------------------------------------------------

	print("")
	print("==============================")
	print("MILITARY → GOALS")
	print("==============================")

	if goal_system == null:

		print(
			"Goal system: MISSING"
		)

	else:

		print(
			"Goal system: FOUND"
		)


	if strategy_system == null:

		print(
			"Strategy system: MISSING"
		)

	else:

		print(
			"Strategy system: FOUND"
		)


	var military_goal = SimGoal.new(
		"india_military_security_test",
		"Military Security",
		"military"
	)

	military_goal.set_description(
		"Test goal for military security."
	)

	military_goal.set_priority(
		0.60
	)

	military_goal.set_importance(
		0.80
	)


	# --------------------------------------------------
	# ADD TEST GOAL
	# --------------------------------------------------

	var military_goal_added = false

	if goal_system != null:

		military_goal_added = goal_system.add_goal(
			india,
			military_goal
		)

	else:

		if not india.goals.has(
			military_goal
		):

			india.goals.append(
				military_goal
			)

			military_goal_added = true


	print(
		"Military goal added: ",
		military_goal_added
	)


	# --------------------------------------------------
	# BASE PRIORITY
	# --------------------------------------------------

	var base_military_goal_priority = (
		military_goal.priority
	)

	print(
		"Base military goal priority: ",
		base_military_goal_priority
	)


	# --------------------------------------------------
	# BASELINE GOAL PROCESSING
	# --------------------------------------------------

	if strategy_system != null:

		strategy_system.process_month(
			world
		)

	if goal_system != null:

		goal_system.process_month(
			world
		)


	var baseline_dynamic_modifier = 0.0
	var baseline_effective_priority = (
		military_goal.priority
	)


	if goal_system != null:

		baseline_dynamic_modifier = (
			goal_system.get_dynamic_goal_modifier(
				india,
				military_goal
			)
		)

		baseline_effective_priority = (
			goal_system.get_effective_goal_priority(
				india,
				military_goal
			)
		)


	print(
		"Baseline dynamic modifier: ",
		baseline_dynamic_modifier
	)

	print(
		"Baseline effective priority: ",
		baseline_effective_priority
	)


	# --------------------------------------------------
	# STORE ORIGINAL MILITARY STATE
	# --------------------------------------------------

	var goal_original_pressure = float(
		india_military.get_state(
			"military_pressure",
			0.20
		)
	)

	var goal_original_exhaustion = float(
		india_military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var goal_original_at_war = bool(
		india_military.get_state(
			"at_war",
			false
		)
	)


	# --------------------------------------------------
	# APPLY CONTROLLED MILITARY SHOCK
	# --------------------------------------------------

	print("")
	print(
		"Applying military → goals shock..."
	)


	india_military.set_state(
		"military_pressure",
		0.90
	)

	india_military.set_state(
		"war_exhaustion",
		0.60
	)

	india_military.set_state(
		"at_war",
		true
	)


	# --------------------------------------------------
	# MILITARY → STRATEGY
	# --------------------------------------------------

	if strategy_system != null:

		strategy_system.process_month(
			world
		)


	var shocked_strategy_signal = (
		india.get_sim_metadata(
			"military_strategy_signal",
			{}
		)
	)

	var shocked_priority_signal = 0.0


	if typeof(shocked_strategy_signal) == TYPE_DICTIONARY:

		shocked_priority_signal = clamp(
			float(
				shocked_strategy_signal.get(
					"military_priority_signal",
					0.0
				)
			),
			0.0,
			1.0
		)


	print(
		"Shocked military priority signal: ",
		shocked_priority_signal
	)


	# --------------------------------------------------
	# STRATEGY → GOALS
	# --------------------------------------------------

	if goal_system != null:

		goal_system.process_month(
			world
		)


	var shocked_dynamic_modifier = 0.0
	var shocked_effective_priority = (
		military_goal.priority
	)


	if goal_system != null:

		shocked_dynamic_modifier = (
			goal_system.get_dynamic_goal_modifier(
				india,
				military_goal
			)
		)

		shocked_effective_priority = (
			goal_system.get_effective_goal_priority(
				india,
				military_goal
			)


	)


	print(
		"Shocked dynamic modifier: ",
		shocked_dynamic_modifier
	)

	print(
		"Shocked effective priority: ",
		shocked_effective_priority
	)


	# --------------------------------------------------
	# TEST — STRATEGY SIGNAL ACTIVATED
	# --------------------------------------------------

	var goal_strategy_signal_pass = (
		shocked_priority_signal
		> 0.0
	)

	print(
		"Military conditions → strategy signal: ",
		"PASS"
		if goal_strategy_signal_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# TEST — GOAL MODIFIER INCREASED
	# --------------------------------------------------

	var goal_modifier_response_pass = (
		shocked_dynamic_modifier
		> baseline_dynamic_modifier
	)

	print(
		"Strategy signal → military goal modifier: ",
		"PASS"
		if goal_modifier_response_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# TEST — EFFECTIVE PRIORITY INCREASED
	# --------------------------------------------------

	var goal_priority_response_pass = (
		shocked_effective_priority
		> baseline_effective_priority
	)

	print(
		"Military conditions → effective goal priority: ",
		"PASS"
		if goal_priority_response_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# TEST — BASE PRIORITY PRESERVED
	# --------------------------------------------------

	var goal_base_priority_preserved = (
		is_equal_approx(
			military_goal.priority,
			base_military_goal_priority
		)
	)

	print(
		"Base military goal priority preserved: ",
		"PASS"
		if goal_base_priority_preserved
		else "FAIL"
	)


	# --------------------------------------------------
	# TEST — RANGE
	# --------------------------------------------------

	var goal_priority_range_pass = (
		shocked_effective_priority >= 0.0
		and shocked_effective_priority <= 1.0
		and shocked_dynamic_modifier >= 0.0
		and shocked_dynamic_modifier <= 0.25
	)

	print(
		"Military goal priority range: ",
		"PASS"
		if goal_priority_range_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# RESTORE MILITARY STATE
	# --------------------------------------------------

	india_military.set_state(
		"military_pressure",
		goal_original_pressure
	)

	india_military.set_state(
		"war_exhaustion",
		goal_original_exhaustion
	)

	india_military.set_state(
		"at_war",
		goal_original_at_war
	)


	# Rebuild strategy after restoration.

	if strategy_system != null:

		strategy_system.process_month(
			world
		)


	if goal_system != null:

		goal_system.process_month(
			world
		)


	var restored_dynamic_modifier = 0.0
	var restored_effective_priority = (
		military_goal.priority
	)


	if goal_system != null:

		restored_dynamic_modifier = (
			goal_system.get_dynamic_goal_modifier(
				india,
				military_goal
			)
		)

		restored_effective_priority = (
			goal_system.get_effective_goal_priority(
				india,
				military_goal
			)


	)


	print("")
	print(
		"Restored dynamic modifier: ",
		restored_dynamic_modifier
	)

	print(
		"Restored effective priority: ",
		restored_effective_priority
	)


	# --------------------------------------------------
	# TEST — RESTORATION
	# --------------------------------------------------

	var goal_restoration_pass = (
		is_equal_approx(
			restored_effective_priority,
			baseline_effective_priority
		)
	)

	print(
		"Military goal priority restoration: ",
		"PASS"
		if goal_restoration_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# FINAL MILITARY → GOALS RESULT
	# --------------------------------------------------

	var military_goal_test_passed = (
		goal_strategy_signal_pass
		and goal_modifier_response_pass
		and goal_priority_response_pass
		and goal_base_priority_preserved
		and goal_priority_range_pass
		and goal_restoration_pass
	)

	print("")
	print("==============================")

	if military_goal_test_passed:

		print(
			"MILITARY → GOALS PASSED"
		)

	else:

		print(
			"MILITARY → GOALS FAILED"
		)

	print("==============================")




	# --------------------------------------------------
	# MILITARY → AI CHOOSER INTEGRATION
	# --------------------------------------------------

	print("")
	print("==============================")
	print("MILITARY → AI CHOOSER INTEGRATION")
	print("==============================")


	var chooser = AIDecisionMaker.new()


	# --------------------------------------------------
	# CREATE COMPETING MILITARY OPTION
	# --------------------------------------------------

	var chooser_military_option = DecisionOption.new(
		"chooser_military",
		"Military Action",
		"military"
	)

	chooser_military_option.actor_id = "india"
	chooser_military_option.target_id = "china"

	# Deliberately lower baseline score.
	#
	# Military → Goals now contributes dynamic goal
	# pressure, so this must be lower than the previous
	# 0.75 calibration.
	chooser_military_option.base_score = 0.25

	chooser_military_option.metadata = {
		"risk": 0.0,
		"uncertainty": 0.0
	}


	# --------------------------------------------------
	# CREATE COMPETING DIPLOMATIC OPTION
	# --------------------------------------------------

	var chooser_diplomatic_option = DecisionOption.new(
		"chooser_diplomatic",
		"Diplomatic Action",
		"diplomatic"
	)

	chooser_diplomatic_option.actor_id = "india"
	chooser_diplomatic_option.target_id = "china"

	chooser_diplomatic_option.base_score = 1.0

	chooser_diplomatic_option.metadata = {
		"risk": 0.20,
		"uncertainty": 0.20
	}


	var chooser_options: Array = [
		chooser_military_option,
		chooser_diplomatic_option
	]


	# --------------------------------------------------
	# STORE ORIGINAL MILITARY STATE
	# --------------------------------------------------

	var chooser_original_pressure = 0.20

	var chooser_original_exhaustion = 0.0

	var chooser_original_at_war = false


	if india_military != null:

		chooser_original_pressure = float(
			india_military.get_state(
				"military_pressure",
				0.20
			)
		)

		chooser_original_exhaustion = float(
			india_military.get_state(
				"war_exhaustion",
				0.0
			)
		)

		chooser_original_at_war = bool(
			india_military.get_state(
				"at_war",
				false
			)
		)


	# --------------------------------------------------
	# BASELINE CHOOSER
	# --------------------------------------------------

	var chooser_baseline_selected = (
		chooser.choose_action(
			world,
			india,
			chooser_options
		)
	)


	print(
		"Baseline AI selection: ",
		chooser_baseline_selected.id
		if chooser_baseline_selected != null
		else "NONE"
	)

	print(
		"Baseline military final score: ",
		chooser_military_option.final_score
	)

	print(
		"Baseline diplomatic final score: ",
		chooser_diplomatic_option.final_score
	)


	# --------------------------------------------------
	# BASELINE SELECTION TEST
	# --------------------------------------------------

	var baseline_diplomatic_pass = (
		chooser_baseline_selected != null
		and chooser_baseline_selected.id
		== "chooser_diplomatic"
	)

	print(
		"Baseline diplomacy selected: ",
		"PASS"
		if baseline_diplomatic_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# APPLY CONTROLLED MILITARY SHOCK
	# --------------------------------------------------

	if india_military != null:

		print("")
		print(
			"Applying controlled military shock..."
		)

		india_military.set_state(
			"military_pressure",
			0.90
		)

		india_military.set_state(
			"war_exhaustion",
			0.60
		)

		india_military.set_state(
			"at_war",
			true
		)


	# --------------------------------------------------
	# UPDATE MILITARY STRATEGY
	# --------------------------------------------------

	if strategy_system != null:

		strategy_system.process_month(
			world
		)


	# --------------------------------------------------
	# UPDATE DYNAMIC GOALS
	# --------------------------------------------------

	if goal_system != null:

		goal_system.process_month(
			world
		)


	# --------------------------------------------------
	# SHOCKED CHOOSER
	# --------------------------------------------------

	var chooser_shocked_selected = (
		chooser.choose_action(
			world,
			india,
			chooser_options
		)
	)


	print("")

	print(
		"Shocked AI selection: ",
		chooser_shocked_selected.id
		if chooser_shocked_selected != null
		else "NONE"
	)

	print(
		"Shocked military final score: ",
		chooser_military_option.final_score
	)

	print(
		"Shocked diplomatic final score: ",
		chooser_diplomatic_option.final_score
	)


	# --------------------------------------------------
	# MILITARY SCORE RESPONSE
	# --------------------------------------------------

	var chooser_military_score_increased = (
		chooser_military_option.final_score
		>
		chooser_diplomatic_option.final_score
	)


	print(
		"Military option overtakes diplomacy: ",
		"PASS"
		if chooser_military_score_increased
		else "FAIL"
	)


	# --------------------------------------------------
	# VERIFY MILITARY SELECTION
	# --------------------------------------------------

	var chooser_selects_military_pass = (
		chooser_shocked_selected != null
		and chooser_shocked_selected.id
		== "chooser_military"
	)


	print(
		"Military conditions → military decision selection: ",
		"PASS"
		if chooser_selects_military_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# VERIFY MILITARY OPTION WAS EVALUATED
	# --------------------------------------------------

	var chooser_evaluates_military_pass = (
		chooser_military_option.final_score > 0.0
	)


	print(
		"AI chooser evaluates military option: ",
		"PASS"
		if chooser_evaluates_military_pass
		else "FAIL"
	)


	# --------------------------------------------------
	# RESTORE ORIGINAL MILITARY STATE
	# --------------------------------------------------

	if india_military != null:

		india_military.set_state(
			"military_pressure",
			chooser_original_pressure
		)

		india_military.set_state(
			"war_exhaustion",
			chooser_original_exhaustion
		)

		india_military.set_state(
			"at_war",
			chooser_original_at_war
		)


	# Rebuild strategy and goal signals after restoration.

	if strategy_system != null:

		strategy_system.process_month(
			world
		)


	if goal_system != null:

		goal_system.process_month(
			world
		)


	print("")

	print(
		"Chooser military state restored."
	)


	# --------------------------------------------------
	# FINAL CHOOSER TEST
	# --------------------------------------------------

	var military_chooser_test_passed = (
		baseline_diplomatic_pass
		and chooser_military_score_increased
		and chooser_selects_military_pass
		and chooser_evaluates_military_pass
	)


	print("")
	print("==============================")


	if military_chooser_test_passed:

		print(
			"MILITARY → AI CHOOSER INTEGRATION PASSED"
		)

	else:

		print(
			"MILITARY → AI CHOOSER INTEGRATION FAILED"
		)


	print("==============================")
	
	
	
	
	
	
	# --------------------------------------------------
	# DECISION TRAJECTORY
	# --------------------------------------------------

	var trajectory = DecisionTrajectory.new(
		"india_china_trade",
		"India-China Trade Agreement",
		"trade_agreement"
	)

	trajectory.actor_id = "india"
	trajectory.target_id = "china"

	trajectory.description = (
		"Tracks the trajectory of an India-China trade agreement."
	)

	print(
		"Initial trajectory: ",
		trajectory.get_value()
	)


	if trajectory_system != null:

		var trajectory_added = trajectory_system.add_trajectory(
			india,
			trajectory
		)

		print(
			"Trajectory added: ",
			trajectory_added
		)

		trajectory_system.change_trajectory(
			india,
			"india_china_trade",
			-0.07,
			"external_actor"
		)

		print(
			"After external actor: ",
			trajectory.get_value()
		)

		trajectory_system.change_trajectory(
			india,
			"india_china_trade",
			0.12,
			"player"
		)

		print(
			"After player decision: ",
			trajectory.get_value()
		)

	else:

		trajectory.add_external_actor_contribution(
			-0.07
		)

		print(
			"After external actor: ",
			trajectory.get_value()
		)

		trajectory.add_player_contribution(
			0.12
		)

		print(
			"After player decision: ",
			trajectory.get_value()
		)


	# --------------------------------------------------
	# AI DECISION
	# --------------------------------------------------

	var selected = null

	if ai_system != null:

		selected = ai_system.decision_maker.choose_action(
			world,
			india,
			options
		)

	else:

		var decision_maker = AIDecisionMaker.new()

		selected = decision_maker.choose_action(
			world,
			india,
			options
		)


	# --------------------------------------------------
	# AI SELECTION DIAGNOSTICS
	# --------------------------------------------------

	if selected == null:

		print(
			"AI selected decision: NONE"
		)

	else:

		print(
			"AI selected decision: ",
			selected.id
		)

		print(
			"AI selected action: ",
			selected.action_type
		)

		print(
			"AI selected score: ",
			selected.final_score
		)


	# --------------------------------------------------
	# GOVERNMENT × AI DIAGNOSTIC
	# --------------------------------------------------

	print("")
	print("==============================")
	print("GOVERNMENT × AI DIAGNOSTIC")
	print("==============================")

	var government_diagnostic = DecisionEvaluator.new()

	for country_id in ["china", "india", "usa"]:

		var diagnostic_country = world.get_entity(
			country_id
		)

		if diagnostic_country == null:

			print(
				country_id,
				": NOT FOUND"
			)

			continue

		var government = diagnostic_country.get_component(
			"government"
		)

		if government == null:

			print(
				country_id,
				": GOVERNMENT COMPONENT MISSING"
			)

			continue

		var diagnostic_option = DecisionOption.new(
			"diagnostic_diplomatic",
			"Diplomatic Diagnostic",
			"diplomatic"
		)

		diagnostic_option.actor_id = country_id
		diagnostic_option.target_id = "china"

		var diagnostic_score = government_diagnostic.evaluate_option(
			world,
			diagnostic_country,
			diagnostic_option
		)

		print("")
		print(
			"Country: ",
			diagnostic_country.name
		)

		print(
			"Government type: ",
			government.get_state(
				"government_type",
				"unknown"
			)
		)

		print(
			"Policy capacity: ",
			government.get_state(
				"policy_capacity",
				0.0
			)
		)

		print(
			"Political pressure: ",
			government.get_state(
				"political_pressure",
				0.0
			)
		)

		print(
			"Institutional strength: ",
			government.get_state(
				"institutional_strength",
				0.0
			)
		)

		print(
			"Government-adjusted score: ",
			diagnostic_score
		)


	# --------------------------------------------------
	# GOVERNMENT FEEDBACK LOOP DIAGNOSTIC
	# --------------------------------------------------

	print("")
	print("==============================")
	print("GOVERNMENT FEEDBACK LOOP")
	print("==============================")

	var feedback_government = india.get_component(
		"government"
	)

	if feedback_government == null:

		print(
			"Government component: MISSING"
		)

	else:

		print("")
		print("Initial government state:")

		print(
			"Stability: ",
			feedback_government.get_state(
				"stability",
				0.0
			)
		)

		print(
			"Approval: ",
			feedback_government.get_state(
				"approval",
				0.0
			)
		)

		print(
			"Political pressure: ",
			feedback_government.get_state(
				"political_pressure",
				0.0
			)
		)

		print(
			"India → China relationship: ",
			india.get_relationship(
				"china",
				0.0
			)
		)

		if government_system == null:

			print(
				"Government system: NOT FOUND"
			)

		else:

			print(
				"Government system: FOUND"
			)

		# Create one diplomatic action.
		#
		# SimAction requires:
		# type, actor, target, action_value, duration

		var feedback_action = SimAction.new(
			"diplomatic_outreach",
			"india",
			"china",
			8.0,
			1
		)

		var feedback_action_manager = ActionManager.new()

		feedback_action_manager.add_action(
			feedback_action
		)


		for feedback_month in range(1, 4):

			print("")
			print(
				"--- Feedback Month ",
				feedback_month,
				" ---"
			)


			# ------------------------------------------
			# ACTION
			# ------------------------------------------

			feedback_action_manager.process_month(
				world
			)

			print(
				"Relationship after action: ",
				india.get_relationship(
					"china",
					0.0
				)
			)


			# ------------------------------------------
			# GOVERNMENT UPDATE
			# ------------------------------------------
			#
			# ActionManager only resolves the action.
			# It does not execute the registered
			# simulation systems.
			#
			# Therefore explicitly run GovernmentSystem
			# here so the changed relationship can feed
			# back into domestic government state.

			if government_system != null:

				government_system.process_month(
					world
				)

			print(
				"Stability: ",
				feedback_government.get_state(
					"stability",
					0.0
				)
			)

			print(
				"Approval: ",
				feedback_government.get_state(
					"approval",
					0.0
				)
			)

			print(
				"Political pressure: ",
				feedback_government.get_state(
					"political_pressure",
					0.0
				)
			)


			# ------------------------------------------
			# AI RE-EVALUATION
			# ------------------------------------------

			var feedback_evaluator = DecisionEvaluator.new()

			var feedback_option = DecisionOption.new(
				"feedback_diplomatic",
				"Feedback Diplomatic Action",
				"diplomatic"
			)

			feedback_option.actor_id = "india"
			feedback_option.target_id = "china"
			feedback_option.base_score = 1.0

			var feedback_score = feedback_evaluator.evaluate_option(
				world,
				india,
				feedback_option
			)

			print(
				"AI diplomatic score: ",
				feedback_score
			)


			# ------------------------------------------
			# ADVANCE WORLD DATE
			# ------------------------------------------

			if feedback_month < 3:

				world.advance_month()

				print(
					"Date: ",
					world.get_date_string()
				)


	print("")
	print(
		"Government feedback loop diagnostic complete."
	)


	# --------------------------------------------------
	# STORE SELECTED DECISION
	# --------------------------------------------------

	india.set_sim_metadata(
		"selected_decision",
		selected
	)

	print(
		"Stored selected decision: ",
		india.get_sim_metadata(
			"selected_decision",
			null
		) != null
	)


	# --------------------------------------------------
	# AI MEMORY
	# --------------------------------------------------

	print(
		"Selected decision before memory: ",
		india.get_sim_metadata(
			"selected_decision",
			null
		) != null
	)


	if memory_system != null:

		memory_system._record_decision_memory(
			world,
			india
		)

	else:

		var temporary_memory_system = AIMemorySystem.new()

		temporary_memory_system._record_decision_memory(
			world,
			india
		)


	print(
		"Memory count after recording: ",
		india.get_memory_count()
	)


	var decision_memories: Array = []

	if memory_system != null:

		decision_memories = memory_system.get_decision_memories(
			india
		)

	else:

		decision_memories = india.get_memory_by_type(
			"ai_decision"
		)


	print(
		"AI decision memories: ",
		decision_memories.size()
	)


	# --------------------------------------------------
	# FINAL RESULT
	# --------------------------------------------------

	print("")
	print("================================")
	print("INTEGRATION RESULT")
	print("================================")

	print(
		"Goals: ",
		india.goals.size()
	)

	print(
		"Decision options: ",
		options.size()
	)

	print(
		"Selected decision: ",
		india.get_sim_metadata(
			"selected_decision",
			null
		) != null
	)

	print(
		"Trajectory: ",
		trajectory.get_value()
	)

	print(
		"Memory entries: ",
		india.get_memory_count()
	)

	print(
		"Decision/AI integration test complete."
	)


# --------------------------------------------------
# FIND REGISTERED SYSTEM
# --------------------------------------------------

static func _find_system(
	world: WorldState,
	simulation: SimulationEngine,
	system_name: String
):

	if simulation == null:
		return null

	return simulation.get_system(
		system_name
	)


# --------------------------------------------------
# FIND GOVERNMENT SYSTEM
# --------------------------------------------------

static func _find_government_system(
	world: WorldState,
	simulation: SimulationEngine
):

	return _find_system(
		world,
		simulation,
		"government_system"
	)
