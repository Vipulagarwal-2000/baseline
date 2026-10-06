class_name ActionContentionTest
extends RefCounted


# ============================================================
# STEP 16.3 — CONTENTION TEST
# ============================================================
#
# Step 16.1 established bounded concurrent execution capacity.
# Step 16.2 established that compatible actions may coexist.
# Step 16.3 proves the next boundary:
#
#   concurrently admissible actions must still contend for the
#   authoritative resources they reserve.
#
# The test deliberately creates pairs of actions where each action
# is individually affordable, but the second action becomes
# inadmissible because the first action has already committed the
# contested state.
#
# No parallel contention authority is introduced. The existing
# ActionManager reservation/commitment ledger remains authoritative.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 16.3 — ACTION CONTENTION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var resource_contention_pass: bool = _run_resource_contention_case()
	var budget_contention_pass: bool = _run_budget_contention_case()
	var capability_contention_pass: bool = _run_capability_contention_case()
	var capacity_contention_pass: bool = _run_capacity_contention_case()
	var combined_contention_pass: bool = _run_combined_contention_case()
	var released_reservation_pass: bool = _run_release_after_completion_case()

	TestLogger.write_line(
		"Step 16.3 resource contention: "
		+ ("PASS" if resource_contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Step 16.3 budget contention: "
		+ ("PASS" if budget_contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Step 16.3 capability contention: "
		+ ("PASS" if capability_contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Step 16.3 domain-capacity contention: "
		+ ("PASS" if capacity_contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Step 16.3 combined reservation contention: "
		+ ("PASS" if combined_contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Step 16.3 released reservation becomes available after completion: "
		+ ("PASS" if released_reservation_pass else "FAIL")
	)

	var overall_pass: bool = (
		resource_contention_pass
		and budget_contention_pass
		and capability_contention_pass
		and capacity_contention_pass
		and combined_contention_pass
		and released_reservation_pass
	)

	TestLogger.write_line(
		"Step 16.3 Contention overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 5

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_3_actor",
		"Step 16.3 Actor",
		"country"
	)

	var target: SimEntity = SimEntity.new(
		"step16_3_target",
		"Step 16.3 Target",
		"country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	var economy: SimComponent = EconomyComponent.new(actor.id)
	var industry: SimComponent = IndustryComponent.new(actor.id)
	var infrastructure: SimComponent = InfrastructureComponent.new(actor.id)

	resources.set_state(
		"stockpile",
		{
			"steel": 50.0,
			"fuel": 25.0
		}
	)

	economy.set_state("treasury", 1000.0)
	economy.set_state("investment_capacity", 10.0)
	economy.set_state("industrial_capacity", 20.0)
	infrastructure.set_state("administrative_capacity", 5.0)

	actor.add_component(resources)
	actor.add_component(economy)
	actor.add_component(industry)
	actor.add_component(infrastructure)

	actor.set_sim_metadata(
		"capabilities",
		{
			"administrative": 1.0,
			"military": 1.0
		}
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)
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
	action_type: String
) -> SimAction:
	return SimAction.new(
		action_type,
		actor.id,
		target.id,
		0.0,
		2
	)


static func _run_resource_contention_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_resource_first"
	)
	first_action.resource_requirements = {
		"steel": 30.0
	}

	var second_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_resource_second"
	)
	second_action.resource_requirements = {
		"steel": 25.0
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var second_result: bool = isolated_simulation.add_action(second_action)

	var reservation: Dictionary = manager.get_action_reservation(first_action)
	var contention_passed: bool = (
		first_result
		and not second_result
		and first_action.state == SimAction.STATE_QUEUED
		and second_action.state == SimAction.STATE_FAILED
		and second_action.failure_reason
			== "Action commitment failed: reservation exceeds available resource: steel"
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
		and float(reservation.get("resources", {}).get("steel", 0.0)) == 30.0
	)

	TestLogger.write_line(
		"Two individually affordable actions cannot jointly oversubscribe reserved resource stock: "
		+ ("PASS" if contention_passed else "FAIL")
	)

	return contention_passed


static func _run_budget_contention_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_budget_first"
	)
	first_action.cost = 700.0

	var second_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_budget_second"
	)
	second_action.cost = 400.0

	var first_result: bool = isolated_simulation.add_action(first_action)
	var second_result: bool = isolated_simulation.add_action(second_action)

	var contention_passed: bool = (
		first_result
		and not second_result
		and first_action.state == SimAction.STATE_QUEUED
		and second_action.state == SimAction.STATE_FAILED
		and second_action.failure_reason
			== "Action commitment failed: reservation exceeds available treasury."
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Two individually affordable actions cannot jointly oversubscribe treasury: "
		+ ("PASS" if contention_passed else "FAIL")
	)

	return contention_passed


static func _run_capability_contention_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_capability_first"
	)
	first_action.capability_requirements = {
		"administrative": 0.7
	}

	var second_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_capability_second"
	)
	second_action.capability_requirements = {
		"administrative": 0.5
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var second_result: bool = isolated_simulation.add_action(second_action)

	var contention_passed: bool = (
		first_result
		and not second_result
		and first_action.state == SimAction.STATE_QUEUED
		and second_action.state == SimAction.STATE_FAILED
		and second_action.failure_reason
			== "Action commitment failed: reservation exceeds available capability: administrative"
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Capability reservation prevents concurrent administrative over-allocation: "
		+ ("PASS" if contention_passed else "FAIL")
	)

	return contention_passed


static func _run_capacity_contention_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_capacity_first"
	)
	first_action.capacity_requirements = {
		"industrial_capacity": 12.0
	}

	var second_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_capacity_second"
	)
	second_action.capacity_requirements = {
		"industrial_capacity": 9.0
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var second_result: bool = isolated_simulation.add_action(second_action)

	var contention_passed: bool = (
		first_result
		and not second_result
		and first_action.state == SimAction.STATE_QUEUED
		and second_action.state == SimAction.STATE_FAILED
		and second_action.failure_reason
			== "Action commitment failed: reservation exceeds available capacity: industrial_capacity"
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Domain capacity reservation prevents concurrent industrial over-allocation: "
		+ ("PASS" if contention_passed else "FAIL")
	)

	return contention_passed


static func _run_combined_contention_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_combined_first"
	)
	first_action.resource_requirements = {
		"steel": 30.0
	}
	first_action.cost = 400.0
	first_action.capability_requirements = {
		"administrative": 0.4
	}
	first_action.capacity_requirements = {
		"industrial_capacity": 8.0
	}

	var second_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_combined_second"
	)
	second_action.resource_requirements = {
		"steel": 25.0
	}
	second_action.cost = 500.0
	second_action.capability_requirements = {
		"administrative": 0.7
	}
	second_action.capacity_requirements = {
		"industrial_capacity": 8.0
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var second_result: bool = isolated_simulation.add_action(second_action)
	var second_reservation: Dictionary = manager.get_action_reservation(second_action)

	var contention_passed: bool = (
		first_result
		and not second_result
		and second_action.state == SimAction.STATE_FAILED
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
		and second_reservation.is_empty()
		and manager.has_action_reservation(first_action)
	)

	TestLogger.write_line(
		"Combined resource/budget/capability/capacity contention rejects the conflicting action without partial reservation: "
		+ ("PASS" if contention_passed else "FAIL")
	)

	return contention_passed


static func _run_release_after_completion_case() -> bool:
	var fixture: Dictionary = _create_fixture()
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target: SimEntity = fixture["target"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var first_action: SimAction = _new_action(
		actor,
		target,
		"diplomatic_outreach"
	)
	first_action.resource_requirements = {
		"steel": 30.0
	}

	var blocked_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_release_blocked"
	)
	blocked_action.resource_requirements = {
		"steel": 25.0
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var blocked_result: bool = isolated_simulation.add_action(blocked_action)

	isolated_simulation.tick_month()
	isolated_simulation.tick_month()

	var released_first_pass: bool = (
		first_result
		and not blocked_result
		and first_action.state == SimAction.STATE_COMPLETED
		and manager.get_reservation_count() == 0
		and manager.get_pending_count() == 0
	)

	var readmission_action: SimAction = _new_action(
		actor,
		target,
		"step16_3_release_reuse"
	)
	readmission_action.resource_requirements = {
		"steel": 25.0
	}

	var readmission_result: bool = isolated_simulation.add_action(
		readmission_action
	)

	var reuse_pass: bool = (
		released_first_pass
		and readmission_result
		and readmission_action.state == SimAction.STATE_QUEUED
		and manager.get_reservation_count() == 1
		and manager.get_pending_count() == 1
	)

	return reuse_pass
