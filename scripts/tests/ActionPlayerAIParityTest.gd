class_name ActionPlayerAIParityTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.10 — PLAYER / AI PARITY TEST"
	)

	var input_context_pass: bool = (
		world != null
		and simulation != null
	)

	TestLogger.write_line(
		"World available: "
		+ ("PASS" if world != null else "FAIL")
	)
	TestLogger.write_line(
		"Simulation available: "
		+ ("PASS" if simulation != null else "FAIL")
	)

	if not input_context_pass:
		TestLogger.write_line(
			"Step 15.10 Player / AI Parity test: FAIL"
		)
		return false

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------
	# Use two identical isolated worlds. The player and AI paths are
	# intentionally separated so their execution results can be compared
	# without one path changing the other's starting state.

	var config: SimulationConfig = SimulationConfig.create_default()
	var player_world: WorldState = WorldState.new(config)
	var ai_world: WorldState = WorldState.new(config)

	var player_actor: SimEntity = SimEntity.new(
		"step15_10_player_actor",
		"Step 15.10 Player Actor",
		"country"
	)
	var player_target: SimEntity = SimEntity.new(
		"step15_10_player_target",
		"Step 15.10 Player Target",
		"country"
	)

	var ai_actor: SimEntity = SimEntity.new(
		"step15_10_ai_actor",
		"Step 15.10 AI Actor",
		"country"
	)
	var ai_target: SimEntity = SimEntity.new(
		"step15_10_ai_target",
		"Step 15.10 AI Target",
		"country"
	)

	player_world.add_entity(player_actor)
	player_world.add_entity(player_target)
	ai_world.add_entity(ai_actor)
	ai_world.add_entity(ai_target)

	player_actor.set_relationship(
		player_target.id,
		0.0
	)
	ai_actor.set_relationship(
		ai_target.id,
		0.0
	)

	var player_simulation: SimulationEngine = SimulationEngine.new(
		player_world
	)
	var ai_simulation: SimulationEngine = SimulationEngine.new(
		ai_world
	)

	# ------------------------------------------------------------
	# COMMON DECISION INPUT
	# ------------------------------------------------------------

	var player_option: DecisionOption = DecisionOption.new(
		"step15_10_diplomatic",
		"Step 15.10 Diplomatic Outreach",
		"diplomatic_outreach"
	)
	player_option.actor_id = player_actor.id
	player_option.target_id = player_target.id
	player_option.metadata = {
		"action": {
			"value": 10.0,
			"duration": 1
		}
	}

	var ai_option: DecisionOption = DecisionOption.new(
		"step15_10_diplomatic",
		"Step 15.10 Diplomatic Outreach",
		"diplomatic_outreach"
	)
	ai_option.actor_id = ai_actor.id
	ai_option.target_id = ai_target.id
	ai_option.metadata = {
		"action": {
			"value": 10.0,
			"duration": 1
		}
	}

	# ------------------------------------------------------------
	# PLAYER PATH
	# ------------------------------------------------------------
	# Player selection is represented by explicitly selecting the common
	# DecisionOption. Conversion then uses DecisionSystem's existing common
	# decision -> SimAction path.

	var player_decision_system: DecisionSystem = DecisionSystem.new()
	var player_action: SimAction = (
		player_decision_system.convert_decision_to_action(
			player_option,
			"1950-01-01"
		)
	)

	var player_conversion_pass: bool = (
		player_action != null
		and player_action.actor_id == player_actor.id
		and player_action.action_type == "diplomatic_outreach"
		and player_action.target_id == player_target.id
		and player_action.duration_months == 1
	)

	TestLogger.write_line(
		"Player selection converts to executable SimAction: "
		+ ("PASS" if player_conversion_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# AI PATH
	# ------------------------------------------------------------
	# The AI receives the same executable intent through its normal
	# selected-decision mechanism. The option list contains one valid option,
	# so the AI selection machinery selects it without introducing a second
	# execution path.

	ai_actor.set_sim_metadata(
		"decision_options",
		[ai_option]
	)

	var ai_decision_system: AIDecisionSystem = AIDecisionSystem.new()
	ai_decision_system.process_month(ai_world)

	var ai_action: SimAction = ai_decision_system.get_selected_action(
		ai_actor,
		"1950-01-01"
	)

	var ai_conversion_pass: bool = (
		ai_action != null
		and ai_action.actor_id == ai_actor.id
		and ai_action.action_type == "diplomatic_outreach"
		and ai_action.target_id == ai_target.id
		and ai_action.duration_months == 1
	)

	TestLogger.write_line(
		"AI selection converts to executable SimAction: "
		+ ("PASS" if ai_conversion_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# COMMON CONTRACT PARITY
	# ------------------------------------------------------------

	var contract_parity_pass: bool = (
		player_action != null
		and ai_action != null
		and player_action.action_type == ai_action.action_type
		and player_action.duration_months == ai_action.duration_months
		and is_equal_approx(player_action.value, ai_action.value)
		and player_action.effects == ai_action.effects
		and player_action.resource_requirements == ai_action.resource_requirements
		and player_action.financial_requirements == ai_action.financial_requirements
		and player_action.capability_requirements == ai_action.capability_requirements
		and player_action.capacity_requirements == ai_action.capacity_requirements
		and player_action.state == SimAction.STATE_QUEUED
		and ai_action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"Player and AI actions share the same executable contract: "
		+ ("PASS" if contract_parity_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# COMMON EXECUTION PATH
	# ------------------------------------------------------------
	# Both paths enter SimulationEngine.add_action(), which delegates to the
	# same registered ActionManager machinery. No player-specific or AI-specific
	# executor is introduced.

	var player_submitted: bool = player_simulation.add_action(
		player_action
	)
	var ai_submitted: bool = ai_simulation.add_action(
		ai_action
	)

	var common_submission_pass: bool = (
		player_submitted
		and ai_submitted
		and player_simulation.get_system("action_manager") != null
		and ai_simulation.get_system("action_manager") != null
		and player_simulation.action_manager is ActionManager
		and ai_simulation.action_manager is ActionManager
	)

	TestLogger.write_line(
		"Player and AI actions enter the same ActionManager machinery: "
		+ ("PASS" if common_submission_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# COMMON MONTHLY RESOLUTION
	# ------------------------------------------------------------

	var player_diplomatic_before: float = player_actor.get_relationship_dimension(
		player_target.id,
		"diplomatic",
		0.0
	)
	var ai_diplomatic_before: float = ai_actor.get_relationship_dimension(
		ai_target.id,
		"diplomatic",
		0.0
	)

	var player_before: float = player_actor.get_relationship(
		player_target.id,
		0.0
	)
	var ai_before: float = ai_actor.get_relationship(
		ai_target.id,
		0.0
	)

	player_simulation.tick_month()
	ai_simulation.tick_month()

	var player_diplomatic_after: float = player_actor.get_relationship_dimension(
		player_target.id,
		"diplomatic",
		0.0
	)
	var ai_diplomatic_after: float = ai_actor.get_relationship_dimension(
		ai_target.id,
		"diplomatic",
		0.0
	)

	var player_after: float = player_actor.get_relationship(
		player_target.id,
		0.0
	)
	var ai_after: float = ai_actor.get_relationship(
		ai_target.id,
		0.0
	)

	# Diplomatic outreach applies its raw action effect to the authoritative
	# diplomatic dimension. Overall relationship remains a derived aggregate.
	var player_execution_pass: bool = is_equal_approx(
		player_diplomatic_after,
		player_diplomatic_before + 10.0
	)
	var ai_execution_pass: bool = is_equal_approx(
		ai_diplomatic_after,
		ai_diplomatic_before + 10.0
	)

	var player_derived_change_pass: bool = not is_equal_approx(
		player_after,
		player_before
	)
	var ai_derived_change_pass: bool = not is_equal_approx(
		ai_after,
		ai_before
	)

	TestLogger.write_line(
		"Player action resolves through normal monthly ACTIONS phase: "
		+ ("PASS" if player_execution_pass else "FAIL")
	)
	TestLogger.write_line(
		"AI action resolves through normal monthly ACTIONS phase: "
		+ ("PASS" if ai_execution_pass else "FAIL")
	)
	TestLogger.write_line(
		"Player derived overall relationship reflects diplomatic effect: "
		+ ("PASS" if player_derived_change_pass else "FAIL")
	)
	TestLogger.write_line(
		"AI derived overall relationship reflects diplomatic effect: "
		+ ("PASS" if ai_derived_change_pass else "FAIL")
	)

	var result_parity_pass: bool = (
		player_execution_pass
		and ai_execution_pass
		and player_derived_change_pass
		and ai_derived_change_pass
		and is_equal_approx(
			player_diplomatic_after - player_diplomatic_before,
			ai_diplomatic_after - ai_diplomatic_before
		)
		and player_action.state == SimAction.STATE_COMPLETED
		and ai_action.state == SimAction.STATE_COMPLETED
		and player_simulation.get_pending_action_count() == 0
		and ai_simulation.get_pending_action_count() == 0
		and player_simulation.action_manager.get_reservation_count() == 0
		and ai_simulation.action_manager.get_reservation_count() == 0
	)

	TestLogger.write_line(
		"Player and AI produce equivalent completion / cleanup behavior: "
		+ ("PASS" if result_parity_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# FINAL CONTRACT
	# ------------------------------------------------------------

	var passed: bool = (
		input_context_pass
		and player_conversion_pass
		and ai_conversion_pass
		and contract_parity_pass
		and common_submission_pass
		and player_execution_pass
		and ai_execution_pass
		and result_parity_pass
	)

	TestLogger.write_line(
		"Step 15.10 Player / AI Parity test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
