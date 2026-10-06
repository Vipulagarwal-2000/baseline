class_name DecisionActionConversionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.2 — DECISION → EXECUTABLE ACTION CONVERSION TEST"
	)

	if world == null:
		TestLogger.write_line(
			"Decision → Action conversion test: FAILED — world is null."
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Decision → Action conversion test: FAILED — simulation is null."
		)
		return false

	var decision_system = simulation.get_system(
		"decision_system"
	)

	var ai_system = simulation.get_system(
		"ai_decision_system"
	)

	var systems_available: bool = (
		decision_system != null
		and ai_system != null
	)

	TestLogger.write_line(
		"DecisionSystem available: "
		+ (
			"PASS"
			if decision_system != null
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"AIDecisionSystem available: "
		+ (
			"PASS"
			if ai_system != null
			else "FAIL"
		)
	)

	if not systems_available:
		TestLogger.write_line(
			"Decision → Action conversion test: FAILED — required systems missing."
		)
		return false

	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"Decision → Action conversion test: FAILED — India not found."
		)
		return false

	# Preserve existing AI decision metadata because this test writes
	# only the selected-decision slot temporarily.
	var original_selected_decision = india.get_sim_metadata(
		"selected_decision",
		null
	)

	var option := DecisionOption.new(
		"step15_2_trade",
		"Step 15.2 Trade",
		"economic"
	)

	option.actor_id = "india"
	option.target_id = "china"

	option.metadata = {
		"action": {
			"value": 12.5,
			"duration": 3,
			"cost": 25.0,
			"resource_requirements": {
				"steel": 10.0
			},
			"financial_requirements": {
				"treasury": 25.0
			},
			"capability_requirements": {
				"administrative": 0.20
			},
			"capacity_requirements": {
				"economic": 0.15
			},
			"effects": {
				"trade_relationship": 0.10
			},
			"completion_result": {
				"result_type": "trade_expansion"
			}
		}
	}

	var expected_start_date := "1950-01-01"

	# --------------------------------------------------
	# DIRECT DECISION OBJECT CONVERSION
	# --------------------------------------------------

	var direct_action: SimAction = (
		option.to_executable_action(
			expected_start_date
		)
	)

	var direct_conversion_pass: bool = (
		direct_action != null
		and direct_action.actor == "india"
		and direct_action.kind == "economic"
		and direct_action.target == "china"
		and direct_action.duration == 3
		and is_equal_approx(
			direct_action.value,
			12.5
		)
	)

	TestLogger.write_line(
		"DecisionOption converts to SimAction: "
		+ (
			"PASS"
			if direct_conversion_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Converted actor/kind/target/duration preserved: "
		+ (
			"PASS"
			if direct_conversion_pass
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# DECISION SYSTEM CONVERSION PATH
	# --------------------------------------------------

	var decision_action: SimAction = (
		decision_system.convert_decision_to_action(
			option,
			expected_start_date
		)
	)

	var decision_system_conversion_pass: bool = (
		decision_action != null
		and decision_action.actor == direct_action.actor
		and decision_action.kind == direct_action.kind
		and decision_action.target == direct_action.target
		and decision_action.duration == direct_action.duration
		and is_equal_approx(
			decision_action.value,
			direct_action.value
		)
	)

	TestLogger.write_line(
		"DecisionSystem uses common conversion path: "
		+ (
			"PASS"
			if decision_system_conversion_pass
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# AI SELECTED DECISION CONVERSION PATH
	# --------------------------------------------------

	india.set_sim_metadata(
		"selected_decision",
		option
	)

	var ai_action: SimAction = (
		ai_system.get_selected_action(
			india,
			expected_start_date
		)
	)

	var ai_conversion_pass: bool = (
		ai_action != null
		and ai_action.actor == direct_action.actor
		and ai_action.kind == direct_action.kind
		and ai_action.target == direct_action.target
		and ai_action.duration == direct_action.duration
		and is_equal_approx(
			ai_action.value,
			direct_action.value
		)
	)

	TestLogger.write_line(
		"AI selected decision converts through same action contract: "
		+ (
			"PASS"
			if ai_conversion_pass
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# PAYLOAD PRESERVATION
	# --------------------------------------------------

	var payload_pass: bool = (
		is_equal_approx(
			direct_action.cost,
			25.0
		)
		and direct_action.resource_requirements.get(
			"steel",
			0.0
		) == 10.0
		and direct_action.financial_requirements.get(
			"treasury",
			0.0
		) == 25.0
		and direct_action.capability_requirements.get(
			"administrative",
			0.0
		) == 0.20
		and direct_action.capacity_requirements.get(
			"economic",
			0.0
		) == 0.15
		and direct_action.effects.get(
			"trade_relationship",
			0.0
		) == 0.10
		and direct_action.completion_result.get(
			"result_type",
			""
		) == "trade_expansion"
	)

	TestLogger.write_line(
		"Decision action payload preserved: "
		+ (
			"PASS"
			if payload_pass
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# RUNTIME INITIAL STATE
	# --------------------------------------------------

	var lifecycle_state_pass: bool = (
		direct_action.state == SimAction.STATE_QUEUED
		and is_zero_approx(
			direct_action.progress
		)
		and direct_action.start_date == expected_start_date
		and direct_action.failure_reason.is_empty()
	)

	TestLogger.write_line(
		"Converted action starts as queued with zero progress: "
		+ (
			"PASS"
			if lifecycle_state_pass
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# PLAYER / AI PARITY
	# --------------------------------------------------

	var parity_pass: bool = (
		decision_action != null
		and ai_action != null
		and decision_action.action_type
			== ai_action.action_type
		and decision_action.actor_id
			== ai_action.actor_id
		and decision_action.target_id
			== ai_action.target_id
		and decision_action.duration_months
			== ai_action.duration_months
		and is_equal_approx(
			decision_action.cost,
			ai_action.cost
		)
	)

	TestLogger.write_line(
		"Player/AI conversion paths produce the same SimAction contract: "
		+ (
			"PASS"
			if parity_pass
			else "FAIL"
		)
	)

	# Verify fresh mutable payloads are not shared between conversions.
	var isolation_pass: bool = true

	decision_action.effects["temporary"] = 1.0

	isolation_pass = (
		not ai_action.effects.has(
			"temporary"
		)
	)

	TestLogger.write_line(
		"Converted action payloads are instance-isolated: "
		+ (
			"PASS"
			if isolation_pass
			else "FAIL"
		)
	)

	# Restore fixture state.
	india.set_sim_metadata(
		"selected_decision",
		original_selected_decision
	)

	var passed: bool = (
		direct_conversion_pass
		and decision_system_conversion_pass
		and ai_conversion_pass
		and payload_pass
		and lifecycle_state_pass
		and parity_pass
		and isolation_pass
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		"Step 15.2 Decision → Action Conversion test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
