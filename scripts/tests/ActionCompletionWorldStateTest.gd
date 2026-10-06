class_name ActionCompletionWorldStateTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.8 — COMPLETION / WORLD-STATE CHANGE TEST"
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
		"step15_8_actor",
		"Step 15.8 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_8_target",
		"Step 15.8 Target",
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

	var completion_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		12.0,
		1
	)

	var queued: bool = isolated_simulation.add_action(completion_action)
	var queued_pass: bool = (
		queued
		and completion_action.state == SimAction.STATE_QUEUED
		and manager.get_pending_count() == 1
	)

	TestLogger.write_line(
		"Validated action enters completion queue: "
		+ ("PASS" if queued_pass else "FAIL")
	)

	var diplomatic_before: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)
	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)

	isolated_simulation.tick_month()

	var diplomatic_after: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)
	var relationship_after: float = actor.get_relationship(
		target.id,
		0.0
	)

	var diplomatic_effect_pass: bool = is_equal_approx(
		diplomatic_after,
		diplomatic_before + 12.0
	)
	var derived_relationship_changed_pass: bool = not is_equal_approx(
		relationship_after,
		relationship_before
	)

	var world_change_pass: bool = (
		diplomatic_effect_pass
		and derived_relationship_changed_pass
	)

	TestLogger.write_line(
		"Completed action changes authoritative diplomatic relationship dimension: "
		+ ("PASS" if diplomatic_effect_pass else "FAIL")
	)
	TestLogger.write_line(
		"Derived overall relationship reflects the completed diplomatic effect: "
		+ ("PASS" if derived_relationship_changed_pass else "FAIL")
	)

	var actual_effect: Dictionary = completion_action.completion_result.get(
		"actual_effect",
		{}
	)

	var completion_result_pass: bool = (
		completion_action.state == SimAction.STATE_COMPLETED
		and completion_action.completion_result.get(
			"effect_applied",
			false
		) == true
		and completion_action.completion_result.get(
			"action_type",
			""
		) == "diplomatic_outreach"
		and completion_action.completion_result.get(
			"actor_id",
			""
		) == actor.id
		and completion_action.completion_result.get(
			"target_id",
			""
		) == target.id
		and str(actual_effect.get(
			"relationship_dimension",
			""
		)) == "diplomatic"
	)

	TestLogger.write_line(
		"Completion result records the applied authoritative effect: "
		+ ("PASS" if completion_result_pass else "FAIL")
	)

	var queue_cleanup_pass: bool = (
		manager.get_pending_count() == 0
		and manager.get_reservation_count() == 0
	)

	TestLogger.write_line(
		"Completed action leaves queue and releases reservation: "
		+ ("PASS" if queue_cleanup_pass else "FAIL")
	)

	var passed: bool = (
		manager_available
		and queued_pass
		and world_change_pass
		and completion_result_pass
		and queue_cleanup_pass
	)

	TestLogger.write_line(
		"Step 15.8 Completion / World-State Change test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
