class_name ConcurrentActionCancellationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 16.5 — CANCELLATION / INTERRUPTION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var fixture: Dictionary = _create_fixture()
	var test_world: WorldState = fixture["world"] as WorldState
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var manager_available: bool = manager != null
	TestLogger.write_line(
		"ActionManager available: "
		+ ("PASS" if manager_available else "FAIL")
	)
	if not manager_available:
		return false

	# ------------------------------------------------------------
	# 1. QUEUED CANCELLATION WITH CONCURRENT ACTIONS
	# ------------------------------------------------------------

	var queued_cancel: SimAction = _new_action(
		actor,
		target,
		"step16_5_queued_cancel",
		3
	)
	queued_cancel.resource_requirements = {
		"steel": 30.0
	}

	var sibling_action: SimAction = _new_action(
		actor,
		target,
		"step16_5_sibling",
		3
	)

	var first_admitted: bool = isolated_simulation.add_action(queued_cancel)
	var sibling_admitted: bool = isolated_simulation.add_action(sibling_action)
	var reservation_before_cancel: bool = manager.has_action_reservation(
		queued_cancel
	)
	var capacity_before_cancel: int = manager.get_concurrent_action_count(
		actor.id
	)
	var relationship_before_cancel: float = actor.get_relationship(
		target.id,
		0.0
	)

	var cancel_result: bool = manager.cancel_action(
		queued_cancel,
		"Step 16.5 queued cancellation."
	)

	var queued_cancel_pass: bool = (
		first_admitted
		and sibling_admitted
		and reservation_before_cancel
		and capacity_before_cancel == 2
		and cancel_result
		and queued_cancel.state == SimAction.STATE_CANCELLED
		and queued_cancel.failure_reason == "Step 16.5 queued cancellation."
		and not manager.has_action_reservation(queued_cancel)
		and manager.get_concurrent_action_count(actor.id) == 1
		and manager.get_pending_count() == 1
		and is_equal_approx(
			actor.get_relationship(target.id, 0.0),
			relationship_before_cancel
		)
	)

	TestLogger.write_line(
		"Queued cancellation releases reservation and concurrent capacity without affecting sibling action: "
		+ ("PASS" if queued_cancel_pass else "FAIL")
	)

	# The released resource/capacity must be reusable immediately.
	var replacement_after_cancel: SimAction = _new_action(
		actor,
		target,
		"step16_5_replacement_after_cancel",
		3
	)
	replacement_after_cancel.resource_requirements = {
		"steel": 30.0
	}

	var replacement_admitted: bool = isolated_simulation.add_action(
		replacement_after_cancel
	)
	var replacement_pass: bool = (
		replacement_admitted
		and replacement_after_cancel.state == SimAction.STATE_QUEUED
		and manager.has_action_reservation(replacement_after_cancel)
		and manager.get_concurrent_action_count(actor.id) == 2
	)

	TestLogger.write_line(
		"Released queued-action capacity and reservation can be reused immediately: "
		+ ("PASS" if replacement_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. ACTIVE INTERRUPTION PRESERVES PARTIAL PROGRESS
	# ------------------------------------------------------------

	# Isolate this case from the queued-cancellation siblings.
	var interruption_fixture: Dictionary = _create_fixture()
	var interruption_world: WorldState = interruption_fixture["world"] as WorldState
	var interruption_simulation: SimulationEngine = interruption_fixture["simulation"] as SimulationEngine
	var interruption_actor: SimEntity = interruption_fixture["actor"] as SimEntity
	var interruption_target: SimEntity = interruption_fixture["target"] as SimEntity
	var interruption_manager: ActionManager = interruption_fixture["manager"] as ActionManager

	var interrupt_action: SimAction = _new_action(
		interruption_actor,
		interruption_target,
		"step16_5_active_interrupt",
		3
	)
	interrupt_action.resource_requirements = {
		"fuel": 15.0
	}

	var surviving_action: SimAction = _new_action(
		interruption_actor,
		interruption_target,
		"step16_5_surviving_active",
		3
	)

	var interrupt_admitted: bool = interruption_simulation.add_action(
		interrupt_action
	)
	var surviving_admitted: bool = interruption_simulation.add_action(
		surviving_action
	)

	interruption_simulation.tick_month()

	var progress_before_interrupt: float = interrupt_action.progress
	var remaining_before_interrupt: int = interrupt_action.duration_months
	var surviving_progress_before_interrupt: float = surviving_action.progress
	var surviving_state_before_interrupt: String = surviving_action.state
	var relationship_before_interrupt: float = interruption_actor.get_relationship(
		interruption_target.id,
		0.0
	)
	var reservation_before_interrupt: bool = interruption_manager.has_action_reservation(
		interrupt_action
	)
	var capacity_before_interrupt: int = interruption_manager.get_concurrent_action_count(
		interruption_actor.id
	)

	var interrupt_result: bool = interruption_manager.interrupt_action(
		interrupt_action,
		"Step 16.5 active interruption."
	)

	# The interrupted action must stop immediately, while the remaining
	# concurrent action continues through the next normal monthly pass.
	interruption_simulation.tick_month()

	var active_interrupt_pass: bool = (
		interrupt_admitted
		and surviving_admitted
		and surviving_action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(progress_before_interrupt, 1.0 / 3.0)
		and remaining_before_interrupt == 2
		and surviving_progress_before_interrupt > 0.0
		and surviving_state_before_interrupt == SimAction.STATE_ACTIVE
		and reservation_before_interrupt
		and capacity_before_interrupt == 2
		and interrupt_result
		and interrupt_action.state == SimAction.STATE_INTERRUPTED
		and interrupt_action.failure_reason == "Step 16.5 active interruption."
		and is_equal_approx(interrupt_action.progress, progress_before_interrupt)
		and interrupt_action.duration_months == remaining_before_interrupt
		and not interruption_manager.has_action_reservation(interrupt_action)
		and interruption_manager.get_concurrent_action_count(
			interruption_actor.id
		) == 1
		and interruption_manager.get_pending_count() == 1
		and surviving_action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(
			surviving_action.progress,
			2.0 / 3.0
		)
		and surviving_action.progress > surviving_progress_before_interrupt
		and is_equal_approx(
			interruption_actor.get_relationship(
				interruption_target.id,
				0.0
			),
			relationship_before_interrupt
		)
		and interruption_world != null
	)

	TestLogger.write_line(
		"Active interruption preserves partial progress, releases reservation/capacity, and leaves concurrent sibling execution intact: "
		+ ("PASS" if active_interrupt_pass else "FAIL")
	)

	# Released interruption reservation/capacity must also be reusable.
	var replacement_after_interrupt: SimAction = _new_action(
		interruption_actor,
		interruption_target,
		"step16_5_replacement_after_interrupt",
		2
	)
	replacement_after_interrupt.resource_requirements = {
		"fuel": 15.0
	}

	var replacement_interrupt_admitted: bool = interruption_simulation.add_action(
		replacement_after_interrupt
	)
	var replacement_interrupt_pass: bool = (
		replacement_interrupt_admitted
		and replacement_after_interrupt.state == SimAction.STATE_QUEUED
		and interruption_manager.has_action_reservation(
			replacement_after_interrupt
		)
		and interruption_manager.get_concurrent_action_count(
			interruption_actor.id
		) == 2
	)

	TestLogger.write_line(
		"Released interruption capacity and reservation can be reused: "
		+ ("PASS" if replacement_interrupt_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. TERMINAL STATES ARE STABLE AND NON-REUSABLE
	# ------------------------------------------------------------

	var cancelled_reason: String = queued_cancel.failure_reason
	var cancelled_readd: bool = manager.add_action(
		queued_cancel,
		test_world
	)
	var cancelled_retry: bool = manager.cancel_action(
		queued_cancel,
		"Second cancellation must not mutate terminal action."
	)

	var cancelled_terminal_pass: bool = (
		not cancelled_readd
		and not cancelled_retry
		and queued_cancel.state == SimAction.STATE_CANCELLED
		and queued_cancel.failure_reason == cancelled_reason
		and not manager.has_action_reservation(queued_cancel)
	)

	TestLogger.write_line(
		"Cancelled action remains terminal and non-reusable: "
		+ ("PASS" if cancelled_terminal_pass else "FAIL")
	)

	var interrupted_reason: String = interrupt_action.failure_reason
	var interrupted_readd: bool = interruption_manager.add_action(
		interrupt_action,
		interruption_world
	)
	var interrupted_retry: bool = interruption_manager.interrupt_action(
		interrupt_action,
		"Second interruption must not mutate terminal action."
	)

	var interrupted_terminal_pass: bool = (
		not interrupted_readd
		and not interrupted_retry
		and interrupt_action.state == SimAction.STATE_INTERRUPTED
		and interrupt_action.failure_reason == interrupted_reason
		and not interruption_manager.has_action_reservation(interrupt_action)
	)

	TestLogger.write_line(
		"Interrupted action remains terminal and non-reusable: "
		+ ("PASS" if interrupted_terminal_pass else "FAIL")
	)

	var overall_pass: bool = (
		queued_cancel_pass
		and replacement_pass
		and active_interrupt_pass
		and replacement_interrupt_pass
		and cancelled_terminal_pass
		and interrupted_terminal_pass
	)

	TestLogger.write_line(
		"Step 16.5 Cancellation / Interruption overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 2

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_5_actor",
		"Step 16.5 Actor",
		"country"
	)

	var target: SimEntity = SimEntity.new(
		"step16_5_target",
		"Step 16.5 Target",
		"country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	resources.set_state(
		"stockpile",
		{
			"steel": 50.0,
			"fuel": 25.0
		}
	)

	actor.add_component(resources)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(
		test_world
	)
	var manager: ActionManager = isolated_simulation.action_manager

	return {
		"world": test_world,
		"simulation": isolated_simulation,
		"actor": actor,
		"target": target,
		"manager": manager
	}


static func _new_action(
	actor: SimEntity,
	target: SimEntity,
	action_type: String,
	duration: int
) -> SimAction:
	return SimAction.new(
		action_type,
		actor.id,
		target.id,
		0.0,
		duration
	)
