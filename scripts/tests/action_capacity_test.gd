class_name ActionCapacityTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 16.1 — ACTION CAPACITY TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------

	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 3

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_1_actor",
		"Step 16.1 Actor",
		"country"
	)

	var actor_two: SimEntity = SimEntity.new(
		"step16_1_actor_two",
		"Step 16.1 Actor Two",
		"country"
	)

	test_world.add_entity(actor)
	test_world.add_entity(actor_two)

	var targets: Array[SimEntity] = []

	for index in range(4):
		var target: SimEntity = SimEntity.new(
			"step16_1_target_" + str(index + 1),
			"Step 16.1 Target " + str(index + 1),
			"country"
		)
		test_world.add_entity(target)
		actor.set_relationship(target.id, 0.0)
		targets.append(target)

	var actor_two_target: SimEntity = SimEntity.new(
		"step16_1_actor_two_target",
		"Step 16.1 Actor Two Target",
		"country"
	)
	test_world.add_entity(actor_two_target)
	actor_two.set_relationship(actor_two_target.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(
		test_world
	)

	var manager: ActionManager = isolated_simulation.action_manager

	if manager == null:
		TestLogger.write_line("ActionManager available: FAIL")
		return false

	TestLogger.write_line("ActionManager available: PASS")

	# ------------------------------------------------------------
	# 1. CONFIGURED CAPACITY
	# ------------------------------------------------------------

	var configured_limit: int = manager.get_action_capacity_limit(
		test_world,
		actor.id
	)

	var configured_capacity_pass: bool = (
		configured_limit == 3
	)

	TestLogger.write_line(
		"Configured concurrent action capacity is bounded at 3: "
		+ ("PASS" if configured_capacity_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. FIRST THREE ACTIONS ADMIT
	# ------------------------------------------------------------

	var admitted_actions: Array[SimAction] = []

	for index in range(3):
		var target: SimEntity = targets[index]
		var action: SimAction = SimAction.new(
			"diplomatic_outreach",
			actor.id,
			target.id,
			1.0,
			2
		)

		var admitted: bool = isolated_simulation.add_action(action)

		if admitted:
			admitted_actions.append(action)

	TestLogger.write_line(
		"Three compatible actions can coexist within the actor capacity: "
		+ (
			"PASS"
			if admitted_actions.size() == 3
			else "FAIL"
		)
	)

	var occupancy_after_three: int = (
		manager.get_concurrent_action_count(actor.id)
	)

	TestLogger.write_line(
		"Concurrent occupancy reaches the configured limit: "
		+ (
			"PASS"
			if occupancy_after_three == 3
			else "FAIL"
		)
	)

	# ------------------------------------------------------------
	# 3. FOURTH ACTION IS REJECTED
	# ------------------------------------------------------------

	var blocked_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		targets[3].id,
		1.0,
		2
	)

	var blocked_result: bool = isolated_simulation.add_action(
		blocked_action
	)

	var blocked_pass: bool = (
		not blocked_result
		and blocked_action.state == SimAction.STATE_FAILED
		and blocked_action.failure_reason
			== "Action admission failed: concurrent action capacity exceeded (active=3, limit=3)."
		and manager.get_concurrent_action_count(actor.id) == 3
		and manager.get_pending_count() == 3
	)

	TestLogger.write_line(
		"Fourth action is rejected without mutating concurrent occupancy: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. CAPACITY IS ACTOR-SCOPED
	# ------------------------------------------------------------

	var second_actor_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor_two.id,
		actor_two_target.id,
		1.0,
		2
	)

	var second_actor_result: bool = isolated_simulation.add_action(
		second_actor_action
	)

	var actor_scoping_pass: bool = (
		second_actor_result
		and manager.get_concurrent_action_count(actor_two.id) == 1
		and manager.get_concurrent_action_count(actor.id) == 3
	)

	TestLogger.write_line(
		"Action capacity is scoped independently per actor: "
		+ ("PASS" if actor_scoping_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. ACTOR-LEVEL OVERRIDE USES EXISTING METADATA
	# ------------------------------------------------------------

	var override_actor: SimEntity = SimEntity.new(
		"step16_1_override_actor",
		"Step 16.1 Override Actor",
		"country"
	)

	var override_target_a: SimEntity = SimEntity.new(
		"step16_1_override_target_a",
		"Step 16.1 Override Target A",
		"country"
	)

	var override_target_b: SimEntity = SimEntity.new(
		"step16_1_override_target_b",
		"Step 16.1 Override Target B",
		"country"
	)

	test_world.add_entity(override_actor)
	test_world.add_entity(override_target_a)
	test_world.add_entity(override_target_b)

	override_actor.set_relationship(
		override_target_a.id,
		0.0
	)
	override_actor.set_relationship(
		override_target_b.id,
		0.0
	)

	override_actor.set_sim_metadata(
		"max_concurrent_actions",
		1
	)

	var override_limit: int = manager.get_action_capacity_limit(
		test_world,
		override_actor.id
	)

	var override_action_a: SimAction = SimAction.new(
		"diplomatic_outreach",
		override_actor.id,
		override_target_a.id,
		1.0,
		2
	)

	var override_action_b: SimAction = SimAction.new(
		"diplomatic_outreach",
		override_actor.id,
		override_target_b.id,
		1.0,
		2
	)

	var override_first_result: bool = isolated_simulation.add_action(
		override_action_a
	)
	var override_second_result: bool = isolated_simulation.add_action(
		override_action_b
	)

	var override_pass: bool = (
		override_limit == 1
		and override_first_result
		and not override_second_result
		and override_action_b.state == SimAction.STATE_FAILED
		and manager.get_concurrent_action_count(
			override_actor.id
		) == 1
	)

	TestLogger.write_line(
		"Actor-level action-capacity override is enforced: "
		+ ("PASS" if override_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 6. COMPLETION RELEASES CAPACITY
	# ------------------------------------------------------------

	var release_simulation: SimulationEngine = isolated_simulation

	# The three original actions have two-month durations. After one
	# tick they are active with one month remaining; after the second
	# tick they complete and release their occupied slots.
	release_simulation.tick_month()
	release_simulation.tick_month()

	var occupancy_after_completion: int = (
		manager.get_concurrent_action_count(actor.id)
	)

	var capacity_release_pass: bool = (
		occupancy_after_completion == 0
		and manager.get_pending_count() == 0
	)

	TestLogger.write_line(
		"Completed actions release their concurrent capacity slots: "
		+ (
			"PASS"
			if capacity_release_pass
			else "FAIL"
		)
	)

	# ------------------------------------------------------------
	# 7. CAPACITY SLOT CAN BE REUSED
	# ------------------------------------------------------------

	var replacement_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		targets[3].id,
		1.0,
		2
	)

	var replacement_result: bool = isolated_simulation.add_action(
		replacement_action
	)

	var replacement_pass: bool = (
		replacement_result
		and manager.get_concurrent_action_count(actor.id) == 1
		and replacement_action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"Released action capacity can be reused by a later action: "
		+ ("PASS" if replacement_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# FINAL RESULT
	# ------------------------------------------------------------

	var overall_pass: bool = (
		configured_capacity_pass
		and admitted_actions.size() == 3
		and occupancy_after_three == 3
		and blocked_pass
		and actor_scoping_pass
		and override_pass
		and capacity_release_pass
		and replacement_pass
	)

	TestLogger.write_line(
		"Step 16.1 Action Capacity overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass
