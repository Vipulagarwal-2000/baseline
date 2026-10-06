class_name ActionOutcomeHistoryTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.11 — ACTION OUTCOME / HISTORY TEST"
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
			"Step 15.11 Action Outcome / History test: FAIL"
		)
		return false

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------

	var config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(config)
	var test_actor: SimEntity = SimEntity.new(
		"step15_11_actor",
		"Step 15.11 Actor",
		"country"
	)
	var test_target: SimEntity = SimEntity.new(
		"step15_11_target",
		"Step 15.11 Target",
		"country"
	)

	test_world.add_entity(test_actor)
	test_world.add_entity(test_target)

	test_actor.set_relationship(
		test_target.id,
		0.0
	)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(
		test_world
	)
	var manager: ActionManager = isolated_simulation.action_manager

	# ------------------------------------------------------------
	# SUCCESSFUL COMPLETION
	# ------------------------------------------------------------

	var successful_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		test_actor.id,
		test_target.id,
		12.0,
		1
	)

	var submitted: bool = isolated_simulation.add_action(
		successful_action
	)

	var start_date_pass: bool = (
		submitted
		and successful_action.start_date == "1950-01-01"
	)

	TestLogger.write_line(
		"Successful action receives authoritative start date: "
		+ ("PASS" if start_date_pass else "FAIL")
	)

	var relationship_before: float = test_actor.get_relationship(
		test_target.id,
		0.0
	)

	isolated_simulation.tick_month()

	var relationship_after: float = test_actor.get_relationship(
		test_target.id,
		0.0
	)

	var outcome: Dictionary = manager.get_action_outcome(
		successful_action
	)
	var completion_result_value: Variant = outcome.get(
		"completion_result",
		{}
	)
	var actual_effect_value: Variant = outcome.get(
		"actual_effect",
		{}
	)

	var completion_result_ok: bool = false
	if typeof(completion_result_value) == TYPE_DICTIONARY:
		var completion_result: Dictionary = completion_result_value
		completion_result_ok = (
			completion_result.get("effect_applied", false) == true
		)

	var actual_effect_ok: bool = false
	if typeof(actual_effect_value) == TYPE_DICTIONARY:
		var actual_effect: Dictionary = actual_effect_value
		var relationship_change_value: Variant = actual_effect.get(
			"relationship_change",
			0.0
		)
		if typeof(relationship_change_value) == TYPE_INT or typeof(relationship_change_value) == TYPE_FLOAT:
			actual_effect_ok = float(relationship_change_value) > 0.0

	var completed_record_pass: bool = (
		successful_action.state == SimAction.STATE_COMPLETED
		and relationship_after > relationship_before
		and not outcome.is_empty()
		and outcome.get("action_id", -1) == successful_action.get_instance_id()
		and outcome.get("actor", "") == test_actor.id
		and outcome.get("type", "") == "diplomatic_outreach"
		and outcome.get("target", "") == test_target.id
		and outcome.get("start", "") == "1950-01-01"
		and outcome.get("end", "") == "1950-02-01"
		and outcome.get("status", "") == SimAction.STATE_COMPLETED
		and is_equal_approx(float(outcome.get("cost", -1.0)), 0.0)
		and outcome.get("failure_reason", "") == ""
		and completion_result_ok
		and actual_effect_ok
	)

	TestLogger.write_line(
		"Completed action creates an auditable outcome record: "
		+ ("PASS" if completed_record_pass else "FAIL")
	)

	var single_record_pass: bool = (
		manager.get_outcome_count() == 1
	)

	TestLogger.write_line(
		"Completed action is recorded exactly once: "
		+ ("PASS" if single_record_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# DEEP-COPY ISOLATION
	# ------------------------------------------------------------

	var history_copy: Array = manager.get_outcome_history()
	if not history_copy.is_empty():
		var copied_entry: Dictionary = history_copy[0]
		copied_entry["status"] = "tampered"
		history_copy[0] = copied_entry

	var history_isolation_pass: bool = (
		manager.get_action_outcome(successful_action).get(
			"status",
			""
		) == SimAction.STATE_COMPLETED
	)

	TestLogger.write_line(
		"Outcome history access is deep-copy isolated: "
		+ ("PASS" if history_isolation_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# EXECUTION FAILURE
	# ------------------------------------------------------------

	var failing_action: SimAction = SimAction.new(
		"unknown_step15_11_action",
		test_actor.id,
		test_target.id,
		5.0,
		1
	)

	var failing_submitted: bool = isolated_simulation.add_action(
		failing_action
	)

	# The unknown action type is valid through the generic Step 15.4
	# structural contract and therefore enters the normal queue.
	# ActionSystem rejects it at execution time, which is the intended
	# authoritative failure path covered by Step 15.9.
	isolated_simulation.tick_month()

	var failing_outcome: Dictionary = manager.get_action_outcome(
		failing_action
	)
	var failure_reason_value: Variant = failing_outcome.get(
		"failure_reason",
		""
	)

	var failure_record_pass: bool = (
		failing_submitted
		and failing_action.state == SimAction.STATE_FAILED
		and failing_outcome.get("status", "") == SimAction.STATE_FAILED
		and failing_outcome.get("start", "") == "1950-02-01"
		and failing_outcome.get("end", "") == "1950-03-01"
		and typeof(failure_reason_value) == TYPE_STRING
		and not str(failure_reason_value).is_empty()
	)

	TestLogger.write_line(
		"Execution failure creates an auditable failure record: "
		+ ("PASS" if failure_record_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# CANCELLATION
	# ------------------------------------------------------------

	var cancelled_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		test_actor.id,
		test_target.id,
		0.0,
		3
	)

	var cancelled_submitted: bool = isolated_simulation.add_action(
		cancelled_action
	)

	var cancelled: bool = manager.cancel_action(
		cancelled_action,
		"Controlled Step 15.11 cancellation."
	)

	var cancelled_outcome: Dictionary = manager.get_action_outcome(
		cancelled_action
	)
	var cancelled_completion_result: Variant = cancelled_outcome.get(
		"completion_result",
		{}
	)

	var cancellation_record_pass: bool = (
		cancelled_submitted
		and cancelled
		and cancelled_outcome.get("status", "") == SimAction.STATE_CANCELLED
		and cancelled_outcome.get("failure_reason", "") == "Controlled Step 15.11 cancellation."
		and typeof(cancelled_completion_result) == TYPE_DICTIONARY
	)

	TestLogger.write_line(
		"Cancelled action creates an auditable outcome record: "
		+ ("PASS" if cancellation_record_pass else "FAIL")
	)

	var total_record_count_pass: bool = (
		manager.get_outcome_count() == 3
	)

	TestLogger.write_line(
		"Outcome ledger contains successful, failed, and cancelled terminal records: "
		+ ("PASS" if total_record_count_pass else "FAIL")
	)

	var passed: bool = (
		input_context_pass
		and start_date_pass
		and completed_record_pass
		and single_record_pass
		and history_isolation_pass
		and failure_record_pass
		and cancellation_record_pass
		and total_record_count_pass
	)

	TestLogger.write_line(
		"Step 15.11 Action Outcome / History test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
