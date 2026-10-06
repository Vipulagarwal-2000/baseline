class_name ActionFailureCancellationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.9 — FAILURE / CANCELLATION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var test_config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(test_config)

	var actor: SimEntity = SimEntity.new(
		"step15_9_actor",
		"Step 15.9 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_9_target",
		"Step 15.9 Target",
		"country"
	)

	var government: SimComponent = GovernmentComponent.new(actor.id)
	government.set_state("policy_capacity", 1.0)
	government.set_state("institutional_strength", 1.0)
	government.set_state("executive_strength", 1.0)
	government.set_state("reform_flexibility", 1.0)
	actor.add_component(government)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = isolated_simulation.action_manager
	var manager_available: bool = manager != null

	TestLogger.write_line(
		"ActionManager available: "
		+ ("PASS" if manager_available else "FAIL")
	)
	if manager == null:
		return false

	# ------------------------------------------------------------
	# QUEUED CANCELLATION
	# ------------------------------------------------------------

	var cancel_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		10.0,
		3
	)
	var cancel_added: bool = isolated_simulation.add_action(cancel_action)
	var reservation_before_cancel: bool = manager.has_action_reservation(
		cancel_action
	)
	var relationship_before_cancel: float = actor.get_relationship(
		target.id,
		0.0
	)
	var cancel_result: bool = manager.cancel_action(
		cancel_action,
		"Test cancellation before execution."
	)
	var queued_cancel_pass: bool = (
		cancel_added
		and reservation_before_cancel
		and cancel_result
		and cancel_action.state == SimAction.STATE_CANCELLED
		and cancel_action.failure_reason == "Test cancellation before execution."
		and not manager.has_action_reservation(cancel_action)
		and manager.get_pending_count() == 0
		and is_equal_approx(
			actor.get_relationship(target.id, 0.0),
			relationship_before_cancel
		)
	)

	TestLogger.write_line(
		"Queued cancellation preserves world state and releases reservation: "
		+ ("PASS" if queued_cancel_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# ACTIVE INTERRUPTION
	# ------------------------------------------------------------

	var interrupt_action_instance: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		9.0,
		3
	)
	var interrupt_added: bool = isolated_simulation.add_action(
		interrupt_action_instance
	)

	isolated_simulation.tick_month()

	var interruption_started_pass: bool = (
		interrupt_added
		and interrupt_action_instance.state == SimAction.STATE_ACTIVE
		and is_equal_approx(interrupt_action_instance.progress, 1.0 / 3.0)
		and interrupt_action_instance.duration_months == 2
		and manager.has_action_reservation(interrupt_action_instance)
	)

	var relationship_before_interrupt: float = actor.get_relationship(
		target.id,
		0.0
	)
	var interrupt_result: bool = manager.interrupt_action(
		interrupt_action_instance,
		"Test interruption after month one."
	)
	var active_interrupt_pass: bool = (
		interruption_started_pass
		and interrupt_result
		and interrupt_action_instance.state == SimAction.STATE_INTERRUPTED
		and interrupt_action_instance.failure_reason == "Test interruption after month one."
		and not manager.has_action_reservation(interrupt_action_instance)
		and manager.get_pending_count() == 0
		and is_equal_approx(
			actor.get_relationship(target.id, 0.0),
			relationship_before_interrupt
		)
	)

	TestLogger.write_line(
		"Active interruption preserves partial progress and releases reservation: "
		+ ("PASS" if active_interrupt_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# EXECUTION FAILURE
	# ------------------------------------------------------------

	var failing_action: SimAction = SimAction.new(
		"unknown_step15_9_action",
		actor.id,
		target.id,
		25.0,
		1
	)
	var failing_added: bool = isolated_simulation.add_action(failing_action)
	var relationship_before_failure: float = actor.get_relationship(
		target.id,
		0.0
	)

	isolated_simulation.tick_month()

	var execution_failure_pass: bool = (
		failing_added
		and failing_action.state == SimAction.STATE_FAILED
		and not failing_action.failure_reason.is_empty()
		and failing_action.completion_result.get(
			"effect_applied",
			true
		) == false
		and not manager.has_action_reservation(failing_action)
		and manager.get_pending_count() == 0
		and is_equal_approx(
			actor.get_relationship(target.id, 0.0),
			relationship_before_failure
		)
	)

	TestLogger.write_line(
		"Execution failure becomes failed without world-state mutation: "
		+ ("PASS" if execution_failure_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# TERMINAL STATE PRESERVATION / IDEMPOTENCE
	# ------------------------------------------------------------

	var cancellation_reason_before_retry: String = cancel_action.failure_reason
	var retry_result: bool = manager.add_action(
		cancel_action,
		test_world
	)
	var terminal_state_preservation_pass: bool = (
		not retry_result
		and cancel_action.state == SimAction.STATE_CANCELLED
		and cancel_action.failure_reason == cancellation_reason_before_retry
		and not manager.has_action_reservation(cancel_action)
		and manager.get_pending_count() == 0
	)

	var cancel_again_result: bool = manager.cancel_action(
		cancel_action,
		"Second cancellation must not mutate a terminal action."
	)
	var idempotence_pass: bool = (
		not cancel_again_result
		and cancel_action.state == SimAction.STATE_CANCELLED
		and cancel_action.failure_reason == cancellation_reason_before_retry
	)

	TestLogger.write_line(
		"Terminal cancellation state remains stable and non-reusable: "
		+ ("PASS" if terminal_state_preservation_pass else "FAIL")
	)

	TestLogger.write_line(
		"Repeated cancellation does not mutate terminal action: "
		+ ("PASS" if idempotence_pass else "FAIL")
	)

	var passed: bool = (
		manager_available
		and queued_cancel_pass
		and active_interrupt_pass
		and execution_failure_pass
		and terminal_state_preservation_pass
		and idempotence_pass
	)

	TestLogger.write_line(
		"Step 15.9 Failure / Cancellation test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
