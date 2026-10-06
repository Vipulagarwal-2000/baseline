class_name ActionReservationCommitmentTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.6 — RESERVATION / COMMITMENT TEST"
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
		"step15_6_actor",
		"Step 15.6 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_6_target",
		"Step 15.6 Target",
		"country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	var economy: SimComponent = EconomyComponent.new(actor.id)
	var industry: SimComponent = IndustryComponent.new(actor.id)
	var infrastructure: SimComponent = InfrastructureComponent.new(actor.id)

	resources.set_state("stockpile", {"steel": 50.0})
	economy.set_state("treasury", 1000.0)
	economy.set_state("investment_capacity", 10.0)
	industry.set_state("industrial_capacity", 20.0)
	infrastructure.set_state("administrative_capacity", 5.0)

	actor.add_component(resources)
	actor.add_component(economy)
	actor.add_component(industry)
	actor.add_component(infrastructure)
	actor.set_sim_metadata(
		"capabilities",
		{
			"administrative": 1.0
		}
	)

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
	# 1. RESERVE + COMMIT
	# ------------------------------------------------------------
	var first_action: SimAction = SimAction.new(
		"step15_6_reserved_action",
		actor.id,
		"",
		0.0,
		2
	)
	first_action.cost = 200.0
	first_action.resource_requirements = {
		"steel": 30.0
	}
	first_action.financial_requirements = {
		"treasury": 200.0
	}
	first_action.capability_requirements = {
		"administrative": 0.2
	}
	first_action.capacity_requirements = {
		"investment_capacity": 2.0
	}

	var first_result: bool = isolated_simulation.add_action(first_action)
	var first_reservation: Dictionary = manager.get_action_reservation(first_action)
	var first_commit_pass: bool = (
		first_result
		and first_action.state == SimAction.STATE_QUEUED
		and isolated_simulation.get_pending_action_count() == 1
		and manager.get_reservation_count() == 1
		and str(first_reservation.get("status", ""))
			== ActionManager.RESERVATION_STATUS_COMMITTED
		and float(first_reservation.get("resources", {}).get("steel", 0.0)) == 30.0
		and float(first_reservation.get("financial", {}).get("treasury", 0.0)) == 200.0
		and float(first_reservation.get("capabilities", {}).get("administrative", 0.0)) == 0.2
		and float(first_reservation.get("capacity", {}).get("investment_capacity", 0.0)) == 2.0
	)

	TestLogger.write_line(
		"Validate → reserve → commit admits first action: "
		+ ("PASS" if first_commit_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. RESOURCE CONTENTION
	# ------------------------------------------------------------
	var resource_conflict_action: SimAction = SimAction.new(
		"step15_6_resource_conflict",
		actor.id,
		"",
		0.0,
		2
	)
	resource_conflict_action.resource_requirements = {
		"steel": 25.0
	}

	var resource_conflict_result: bool = isolated_simulation.add_action(
		resource_conflict_action
	)
	var resource_conflict_pass: bool = (
		not resource_conflict_result
		and resource_conflict_action.state == SimAction.STATE_FAILED
		and resource_conflict_action.failure_reason
			== "Action commitment failed: reservation exceeds available resource: steel"
		and isolated_simulation.get_pending_action_count() == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Reserved resource contention is rejected before queue admission: "
		+ ("PASS" if resource_conflict_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. FINANCIAL CONTENTION
	# ------------------------------------------------------------
	var financial_conflict_action: SimAction = SimAction.new(
		"step15_6_financial_conflict",
		actor.id,
		"",
		0.0,
		2
	)
	financial_conflict_action.cost = 850.0

	var financial_conflict_result: bool = isolated_simulation.add_action(
		financial_conflict_action
	)
	var financial_conflict_pass: bool = (
		not financial_conflict_result
		and financial_conflict_action.state == SimAction.STATE_FAILED
		and financial_conflict_action.failure_reason
			== "Action commitment failed: reservation exceeds available treasury."
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Reserved treasury contention is rejected before queue admission: "
		+ ("PASS" if financial_conflict_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. CAPABILITY CONTENTION
	# ------------------------------------------------------------
	var capability_conflict_action: SimAction = SimAction.new(
		"step15_6_capability_conflict",
		actor.id,
		"",
		0.0,
		2
	)
	capability_conflict_action.capability_requirements = {
		"administrative": 0.9
	}

	var capability_conflict_result: bool = isolated_simulation.add_action(
		capability_conflict_action
	)
	var capability_conflict_pass: bool = (
		not capability_conflict_result
		and capability_conflict_action.state == SimAction.STATE_FAILED
		and capability_conflict_action.failure_reason
			== "Action commitment failed: reservation exceeds available capability: administrative"
	)

	TestLogger.write_line(
		"Reserved capability contention is rejected before queue admission: "
		+ ("PASS" if capability_conflict_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. CAPACITY CONTENTION
	# ------------------------------------------------------------
	var capacity_conflict_action: SimAction = SimAction.new(
		"step15_6_capacity_conflict",
		actor.id,
		"",
		0.0,
		2
	)
	capacity_conflict_action.capacity_requirements = {
		"investment_capacity": 9.0
	}

	var capacity_conflict_result: bool = isolated_simulation.add_action(
		capacity_conflict_action
	)
	var capacity_conflict_pass: bool = (
		not capacity_conflict_result
		and capacity_conflict_action.state == SimAction.STATE_FAILED
		and capacity_conflict_action.failure_reason
			== "Action commitment failed: reservation exceeds available capacity: investment_capacity"
	)

	TestLogger.write_line(
		"Reserved capacity contention is rejected before queue admission: "
		+ ("PASS" if capacity_conflict_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 6. DUPLICATE RESERVATION PROTECTION
	# ------------------------------------------------------------
	var duplicate_result: bool = isolated_simulation.add_action(first_action)
	var duplicate_pass: bool = (
		not duplicate_result
		and first_action.state == SimAction.STATE_FAILED
		and first_action.failure_reason
			== "Action commitment failed: action is already reserved."
		and isolated_simulation.get_pending_action_count() == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Duplicate reservation of the same action is rejected: "
		+ ("PASS" if duplicate_pass else "FAIL")
	)

	# Restore the first action to its committed queued state for lifecycle test.
	first_action.state = SimAction.STATE_QUEUED
	first_action.failure_reason = ""

	# ------------------------------------------------------------
	# 7. RELEASE + RE-ADMISSION
	# ------------------------------------------------------------
	var release_pass: bool = manager.release_action_reservation(first_action)
	manager.pending_actions.erase(first_action)
	var released_state_pass: bool = (
		release_pass
		and manager.get_reservation_count() == 0
		and isolated_simulation.get_pending_action_count() == 0
	)

	TestLogger.write_line(
		"Reservation release clears commitment state: "
		+ ("PASS" if released_state_pass else "FAIL")
	)

	var readmit_action: SimAction = SimAction.new(
		"step15_6_readmit",
		actor.id,
		"",
		0.0,
		2
	)
	readmit_action.resource_requirements = {"steel": 40.0}

	var readmit_result: bool = isolated_simulation.add_action(readmit_action)
	var readmit_pass: bool = (
		readmit_result
		and readmit_action.state == SimAction.STATE_QUEUED
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Released resources become reservable again: "
		+ ("PASS" if readmit_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 8. ACTIVE LIFECYCLE + RELEASE ON COMPLETION
	# ------------------------------------------------------------
	manager.release_action_reservation(readmit_action)
	manager.pending_actions.erase(readmit_action)

	var lifecycle_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		5.0,
		2
	)
	var lifecycle_result: bool = isolated_simulation.add_action(lifecycle_action)

	isolated_simulation.tick_month()
	var active_pass: bool = (
		lifecycle_result
		and lifecycle_action.state == SimAction.STATE_ACTIVE
		and lifecycle_action.duration_months == 1
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Committed action becomes active on the normal ACTIONS tick: "
		+ ("PASS" if active_pass else "FAIL")
	)

	isolated_simulation.tick_month()
	var completed_pass: bool = (
		lifecycle_action.state == SimAction.STATE_COMPLETED
		and lifecycle_action.duration_months == 0
		and isolated_simulation.get_pending_action_count() == 0
		and manager.get_reservation_count() == 0
	)

	TestLogger.write_line(
		"Completed action releases its reservation and leaves the queue: "
		+ ("PASS" if completed_pass else "FAIL")
	)

	var passed: bool = (
		manager_available
		and first_commit_pass
		and resource_conflict_pass
		and financial_conflict_pass
		and capability_conflict_pass
		and capacity_conflict_pass
		and duplicate_pass
		and released_state_pass
		and readmit_pass
		and active_pass
		and completed_pass
	)

	TestLogger.write_line(
		"Step 15.6 Reservation / Commitment test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
