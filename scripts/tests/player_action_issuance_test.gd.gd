class_name PlayerActionIssuanceTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.14 — PLAYER-ISSUED ACTION PATHWAY TEST"
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

	var path_boundary_passed: bool = (
		action_manager != null
		and registered_action_manager == action_manager
	)
	TestLogger.write_line(
		"Player issuance uses the registered ActionManager instance: "
		+ ("PASS" if path_boundary_passed else "FAIL")
	)
	all_passed = all_passed and path_boundary_passed

	if action_manager == null:
		return false

	var india = world.get_entity("india")
	var china = world.get_entity("china")

	var countries_passed: bool = (
		india != null
		and china != null
	)
	TestLogger.write_line(
		"Player action fixture actors available: "
		+ ("PASS" if countries_passed else "FAIL")
	)
	all_passed = all_passed and countries_passed

	if not countries_passed:
		return false

	# This fixture intentionally uses a zero-value diplomatic action.
	# It exercises the full admission and registered ACTIONS-phase
	# execution pathway without permanently changing relationship state.
	var option: DecisionOption = DecisionOption.new(
		"step_15_14_player_fixture",
		"Player diplomatic outreach",
		"diplomatic_outreach"
	)
	option.actor_id = "india"
	option.target_id = "china"
	option.metadata = {
		"action": {
			"value": 0.0,
			"duration_months": 1
		}
	}

	var baseline_action_snapshot: Dictionary = (
		action_manager.capture_snapshot_state()
	)
	var baseline_outcomes: Array = action_manager.outcome_history.duplicate(true)
	var baseline_outcome_index: Dictionary = action_manager.outcome_index.duplicate(true)
	var baseline_pending_count: int = action_manager.get_pending_count()
	var baseline_reservation_count: int = action_manager.get_reservation_count()

	var issuance_result: Dictionary = simulation.issue_player_action(
		"india",
		option
	)

	var issuance_success: bool = bool(
		issuance_result.get("success", false)
	)
	var issued_action: SimAction = issuance_result.get(
		"action",
		null
	) as SimAction

	TestLogger.write_line(
		"Player DecisionOption is accepted by the single issuance path: "
		+ ("PASS" if issuance_success else "FAIL")
	)
	all_passed = all_passed and issuance_success

	var conversion_passed: bool = (
		issued_action != null
		and issued_action.actor_id == "india"
		and issued_action.action_type == "diplomatic_outreach"
		and issued_action.target_id == "china"
		and issued_action.duration_months == 1
		and issued_action.state == SimAction.STATE_QUEUED
		and is_zero_approx(issued_action.progress)
	)
	TestLogger.write_line(
		"Player decision converts to the common executable action contract: "
		+ ("PASS" if conversion_passed else "FAIL")
	)
	all_passed = all_passed and conversion_passed

	var admission_passed: bool = (
		issuance_success
		and issued_action != null
		and action_manager.get_pending_count() == baseline_pending_count + 1
		and action_manager.has_action_reservation(issued_action)
		and action_manager.get_reservation_count() == baseline_reservation_count + 1
		and not issued_action.start_date.is_empty()
	)
	TestLogger.write_line(
		"Player-issued action enters existing validation / reservation / queue machinery: "
		+ ("PASS" if admission_passed else "FAIL")
	)
	all_passed = all_passed and admission_passed

	# Execute only the existing ACTIONS phase. Do not tick the whole
	# simulation so this test remains isolated from unrelated monthly systems.
	if issuance_success:
		simulation.system_manager.process_phase(
			world,
			SimulationPhase.ACTIONS
		)

	var execution_passed: bool = (
		issued_action != null
		and issued_action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(issued_action.progress, 1.0)
		and action_manager.get_pending_count() == baseline_pending_count
		and action_manager.get_reservation_count() == baseline_reservation_count
		and action_manager.get_action_outcome(issued_action).get(
			"status",
			""
		) == SimAction.STATE_COMPLETED
	)
	TestLogger.write_line(
		"Player-issued action resolves through the normal ACTIONS phase: "
		+ ("PASS" if execution_passed else "FAIL")
	)
	all_passed = all_passed and execution_passed

	var invalid_option: DecisionOption = DecisionOption.new(
		"step_15_14_invalid_actor",
		"Invalid player action",
		"diplomatic_outreach"
	)
	invalid_option.actor_id = "china"
	invalid_option.target_id = "india"

	var pending_before_invalid: int = action_manager.get_pending_count()
	var reservation_before_invalid: int = action_manager.get_reservation_count()
	var invalid_result: Dictionary = simulation.issue_player_action(
		"india",
		invalid_option
	)

	var invalid_rejection_passed: bool = (
		not bool(invalid_result.get("success", false))
		and pending_before_invalid == action_manager.get_pending_count()
		and reservation_before_invalid == action_manager.get_reservation_count()
		and not str(invalid_result.get("failure_reason", "")).is_empty()
	)
	TestLogger.write_line(
		"Mismatched player decision is rejected without queue mutation: "
		+ ("PASS" if invalid_rejection_passed else "FAIL")
	)
	all_passed = all_passed and invalid_rejection_passed

	var blocked_option: DecisionOption = DecisionOption.new(
		"step_15_14_blocked",
		"Blocked player action",
		"diplomatic_outreach"
	)
	blocked_option.actor_id = "india"
	blocked_option.target_id = "china"
	blocked_option.block("fixture blocked")

	var pending_before_blocked: int = action_manager.get_pending_count()
	var blocked_result: Dictionary = simulation.issue_player_action(
		"india",
		blocked_option
	)

	var blocked_rejection_passed: bool = (
		not bool(blocked_result.get("success", false))
		and pending_before_blocked == action_manager.get_pending_count()
		and str(blocked_result.get("failure_reason", "")) ==
		"Player action issuance failed: decision is unavailable."
	)
	TestLogger.write_line(
		"Unavailable player decision is rejected without queue mutation: "
		+ ("PASS" if blocked_rejection_passed else "FAIL")
	)
	all_passed = all_passed and blocked_rejection_passed

	# Restore transient action/history state so the full-suite world is unchanged.
	action_manager.restore_snapshot_state(
		baseline_action_snapshot,
		world
	)
	action_manager.outcome_history = baseline_outcomes
	action_manager.outcome_index = baseline_outcome_index

	var restoration_passed: bool = (
		action_manager.get_pending_count() == baseline_pending_count
		and action_manager.get_reservation_count() == baseline_reservation_count
		and action_manager.get_outcome_count() == baseline_outcomes.size()
	)
	TestLogger.write_line(
		"Player issuance fixture restores action execution state exactly: "
		+ ("PASS" if restoration_passed else "FAIL")
	)
	all_passed = all_passed and restoration_passed

	TestLogger.write_line(
		"Step 15.14 player-issued action pathway overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
