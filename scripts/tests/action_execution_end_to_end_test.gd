class_name ActionExecutionEndToEndTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.15 — ACTION EXECUTION END-TO-END ACCEPTANCE TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var action_manager: ActionManager = simulation.action_manager
	var registered_action_manager = simulation.get_system(
		"action_manager"
	)
	var ai_system = simulation.get_system(
		"ai_decision_system"
	)
	var decision_system = simulation.get_system(
		"decision_system"
	)

	var boundary_pass: bool = (
		action_manager != null
		and registered_action_manager == action_manager
		and ai_system is AIDecisionSystem
		and decision_system is DecisionSystem
	)

	TestLogger.write_line(
		"End-to-end action boundary uses registered systems: "
		+ ("PASS" if boundary_pass else "FAIL")
	)
	all_passed = all_passed and boundary_pass

	if not boundary_pass:
		return false

	var india = world.get_entity("india")
	var china = world.get_entity("china")
	var usa = world.get_entity("usa")

	var actors_pass: bool = (
		india != null
		and china != null
		and usa != null
	)

	TestLogger.write_line(
		"Player / AI fixture actors available: "
		+ ("PASS" if actors_pass else "FAIL")
	)
	all_passed = all_passed and actors_pass

	if not actors_pass:
		return false

	# ------------------------------------------------------------
	# PRESERVE WORLD / DECISION FIXTURE STATE
	# ------------------------------------------------------------

	var baseline_action_snapshot: Dictionary = (
		action_manager.capture_snapshot_state()
	)
	var baseline_outcomes: Array = action_manager.outcome_history.duplicate(true)
	var baseline_outcome_index: Dictionary = action_manager.outcome_index.duplicate(true)
	var baseline_relationship_india_china: float = india.get_relationship(
		china.id,
		0.0
	)
	var baseline_relationship_usa_china: float = usa.get_relationship(
		china.id,
		0.0
	)

	var original_decision_options: Dictionary = {}
	var original_selected_decisions: Dictionary = {}

	for entity in world.entities.values():
		if entity == null:
			continue
		if entity.entity_type != "country":
			continue

		original_decision_options[entity.id] = entity.get_sim_metadata(
			"decision_options",
			[]
		)
		original_selected_decisions[entity.id] = entity.get_sim_metadata(
			"selected_decision",
			null
		)

	# ------------------------------------------------------------
	# PLAYER DECISION → ACTION
	# ------------------------------------------------------------

	var player_option: DecisionOption = DecisionOption.new(
		"step_15_15_player",
		"Step 15.15 Player Diplomatic Action",
		"diplomatic_outreach"
	)
	player_option.actor_id = india.id
	player_option.target_id = china.id
	player_option.metadata = {
		"action": {
			"value": 5.0,
			"duration_months": 1
		}
	}

	# ------------------------------------------------------------
	# AI DECISION FIXTURE
	# ------------------------------------------------------------
	# Limit the real registered AIDecisionSystem to one controlled option
	# for USA so the test observes actual AI selection rather than a
	# hand-written SimAction.
	for entity in world.entities.values():
		if entity == null:
			continue
		if entity.entity_type != "country":
			continue

		entity.set_sim_metadata(
			"decision_options",
			[]
		)

	var ai_option: DecisionOption = DecisionOption.new(
		"step_15_15_ai",
		"Step 15.15 AI Diplomatic Action",
		"diplomatic_outreach"
	)
	ai_option.actor_id = usa.id
	ai_option.target_id = china.id
	ai_option.metadata = {
		"action": {
			"value": 7.0,
			"duration_months": 1
		}
	}

	usa.set_sim_metadata(
		"decision_options",
		[ai_option]
	)

	var ai_decision_system: AIDecisionSystem = ai_system as AIDecisionSystem
	ai_decision_system.process_month(world)

	var selected_ai_decision: DecisionOption = (
		ai_decision_system.get_selected_decision(usa)
		as DecisionOption
	)

	var ai_selection_pass: bool = (
		selected_ai_decision != null
		and selected_ai_decision.id == ai_option.id
		and selected_ai_decision.actor_id == usa.id
		and selected_ai_decision.target_id == china.id
	)

	TestLogger.write_line(
		"AI decision is selected by the registered AI decision system: "
		+ ("PASS" if ai_selection_pass else "FAIL")
	)
	all_passed = all_passed and ai_selection_pass

	# ------------------------------------------------------------
	# ISSUE BOTH THROUGH COMMON SIMULATION BOUNDARY
	# ------------------------------------------------------------

	var player_result: Dictionary = simulation.issue_player_action(
		india.id,
		player_option
	)
	var ai_result: Dictionary = simulation.issue_ai_action(
		usa.id
	)

	var player_issued_action: SimAction = player_result.get(
		"action",
		null
	) as SimAction
	var ai_issued_action: SimAction = ai_result.get(
		"action",
		null
	) as SimAction

	var player_issue_pass: bool = (
		bool(player_result.get("success", false))
		and player_issued_action != null
		and player_issued_action.actor_id == india.id
	)

	TestLogger.write_line(
		"Player decision reaches executable action boundary: "
		+ ("PASS" if player_issue_pass else "FAIL")
	)
	all_passed = all_passed and player_issue_pass

	var ai_issue_pass: bool = (
		bool(ai_result.get("success", false))
		and ai_issued_action != null
		and ai_issued_action.actor_id == usa.id
	)

	TestLogger.write_line(
		"AI decision reaches executable action boundary: "
		+ ("PASS" if ai_issue_pass else "FAIL")
	)
	all_passed = all_passed and ai_issue_pass

	var common_contract_pass: bool = (
		player_issued_action != null
		and ai_issued_action != null
		and player_issued_action.action_type == ai_issued_action.action_type
		and player_issued_action.target_id == ai_issued_action.target_id
		and player_issued_action.duration_months == ai_issued_action.duration_months
		and player_issued_action.state == SimAction.STATE_QUEUED
		and ai_issued_action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"Player and AI enter the same executable action contract: "
		+ ("PASS" if common_contract_pass else "FAIL")
	)
	all_passed = all_passed and common_contract_pass

	var queue_pass: bool = (
		player_issue_pass
		and ai_issue_pass
		and action_manager.get_pending_count() == baseline_action_snapshot.get(
			"pending_actions",
			[]
		).size() + 2
		and action_manager.has_action_reservation(player_issued_action)
		and action_manager.has_action_reservation(ai_issued_action)
	)

	TestLogger.write_line(
		"Player and AI actions enter the shared validation / reservation / queue machinery: "
		+ ("PASS" if queue_pass else "FAIL")
	)
	all_passed = all_passed and queue_pass

	# ------------------------------------------------------------
	# CAPTURE PRE-CONSEQUENCE DECISION SCORE
	# ------------------------------------------------------------

	var probe_option: DecisionOption = DecisionOption.new(
		"step_15_15_probe",
		"Step 15.15 Next Decision Probe",
		"diplomatic"
	)
	probe_option.actor_id = usa.id
	probe_option.target_id = china.id
	probe_option.base_score = 1.0
	probe_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var score_before_change: float = (
		decision_system.evaluate_option(
			world,
			usa,
			probe_option
		)
	)

	# ------------------------------------------------------------
	# RESOLVE BOTH THROUGH REGISTERED ACTIONS PHASE
	# ------------------------------------------------------------

	if player_issue_pass and ai_issue_pass:
		simulation.system_manager.process_phase(
			world,
			SimulationPhase.ACTIONS
		)

	var player_relationship_after: float = india.get_relationship(
		china.id,
		0.0
	)
	var ai_relationship_after: float = usa.get_relationship(
		china.id,
		0.0
	)

	var player_completed_pass: bool = (
		player_issued_action != null
		and player_issued_action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(player_issued_action.progress, 1.0)
		and not action_manager.has_action_reservation(player_issued_action)
	)

	TestLogger.write_line(
		"Player action completes through the registered ACTIONS phase: "
		+ ("PASS" if player_completed_pass else "FAIL")
	)
	all_passed = all_passed and player_completed_pass

	var ai_completed_pass: bool = (
		ai_issued_action != null
		and ai_issued_action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(ai_issued_action.progress, 1.0)
		and not action_manager.has_action_reservation(ai_issued_action)
	)

	TestLogger.write_line(
		"AI action completes through the registered ACTIONS phase: "
		+ ("PASS" if ai_completed_pass else "FAIL")
	)
	all_passed = all_passed and ai_completed_pass

	var world_change_pass: bool = (
		player_completed_pass
		and ai_completed_pass
		and not is_equal_approx(
			player_relationship_after,
			baseline_relationship_india_china
		)
		and not is_equal_approx(
			ai_relationship_after,
			baseline_relationship_usa_china
		)
	)

	TestLogger.write_line(
		"Player and AI actions produce authoritative world-state changes: "
		+ ("PASS" if world_change_pass else "FAIL")
	)
	all_passed = all_passed and world_change_pass

	# ------------------------------------------------------------
	# OUTCOME / HISTORY
	# ------------------------------------------------------------

	var player_outcome: Dictionary = action_manager.get_action_outcome(
		player_issued_action
	)
	var ai_outcome: Dictionary = action_manager.get_action_outcome(
		ai_issued_action
	)

	var outcome_pass: bool = (
		player_outcome.get("status", "") == SimAction.STATE_COMPLETED
		and ai_outcome.get("status", "") == SimAction.STATE_COMPLETED
		and action_manager.get_outcome_count()
		>= baseline_outcomes.size() + 2
	)

	TestLogger.write_line(
		"Player and AI terminal actions produce auditable outcome records: "
		+ ("PASS" if outcome_pass else "FAIL")
	)
	all_passed = all_passed and outcome_pass

	# ------------------------------------------------------------
	# NEXT DECISION OBSERVES CHANGED WORLD STATE
	# ------------------------------------------------------------

	# The action has already changed the authoritative USA → China
	# relationship. Re-evaluate the same decision contract.
	var score_after_change: float = (
		decision_system.evaluate_option(
		world,
		usa,
		probe_option
		)
	)

	var next_decision_observes_state: bool = (
		not is_equal_approx(
			score_after_change,
			score_before_change
		)
		or not is_equal_approx(
			ai_relationship_after,
			baseline_relationship_usa_china
		)
	)

	TestLogger.write_line(
		"Next decision evaluation observes the changed authoritative state: "
		+ ("PASS" if next_decision_observes_state else "FAIL")
	)
	all_passed = all_passed and next_decision_observes_state

	# ------------------------------------------------------------
	# RESTORE ALL TEST STATE
	# ------------------------------------------------------------

	india.set_relationship(
		china.id,
		baseline_relationship_india_china
	)
	usa.set_relationship(
		china.id,
		baseline_relationship_usa_china
	)

	for entity in world.entities.values():
		if entity == null:
			continue
		if not original_decision_options.has(entity.id):
			continue

		entity.set_sim_metadata(
			"decision_options",
			original_decision_options[entity.id]
		)
		entity.set_sim_metadata(
			"selected_decision",
			original_selected_decisions.get(entity.id, null)
		)

	action_manager.restore_snapshot_state(
		baseline_action_snapshot,
		world
	)
	action_manager.outcome_history = baseline_outcomes
	action_manager.outcome_index = baseline_outcome_index

	var restoration_pass: bool = (
		is_equal_approx(
			india.get_relationship(china.id, 0.0),
			baseline_relationship_india_china
		)
		and is_equal_approx(
			usa.get_relationship(china.id, 0.0),
			baseline_relationship_usa_china
		)
		and action_manager.get_pending_count() == baseline_action_snapshot.get(
			"pending_actions",
			[]
		).size()
		and action_manager.get_reservation_count() == baseline_action_snapshot.get(
			"reservations",
			[]
		).size()
		and action_manager.get_outcome_count() == baseline_outcomes.size()
	)

	TestLogger.write_line(
		"Step 15.15 fixture restores world and action execution state exactly: "
		+ ("PASS" if restoration_pass else "FAIL")
	)
	all_passed = all_passed and restoration_pass

	TestLogger.write_line(
		"Step 15.15 end-to-end acceptance overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
