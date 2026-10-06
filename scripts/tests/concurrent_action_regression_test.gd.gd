class_name ConcurrentActionRegressionTest
extends RefCounted


# ============================================================
# STEP 16.7 — CONCURRENT ACTION REGRESSION / ACCEPTANCE TEST
# ============================================================
#
# Step 16.7 is the consolidated acceptance boundary for Step 16.
# It deliberately reuses the verified Step 16 test contracts rather
# than introducing a second action engine or duplicate state authority.
#
# Acceptance matrix:
#   1. one action
#   2. multiple compatible actions
#   3. resource collision
#   4. capacity collision
#   5. budget collision
#   6. invalid oversubscription
#   7. deterministic completion order
#   8. same-month idempotence of terminal processing
#   9. concurrent snapshot / load
#
# Existing authorities remain authoritative:
#   ActionManager -> action lifecycle / reservation / queue / resolution
#   ActionSystem  -> authoritative world-state effect application
#   WorldSnapshot -> existing persistence boundary
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 16.7 — CONCURRENT ACTION REGRESSION / ACCEPTANCE TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var one_action_pass: bool = _run_one_action_case()
	var multiple_compatible_pass: bool = _run_multiple_compatible_actions_case()

	# The following three checks deliberately reuse the dedicated Step 16.3
	# contention fixture. That fixture independently exercises the authoritative
	# resource, treasury, capability and domain-capacity reservation paths.
	var contention_pass: bool = ActionContentionTest.run(
		world,
		simulation
	)

	var capacity_pass: bool = ActionCapacityTest.run(
		world,
		simulation
	)

	var deterministic_pass: bool = DeterministicActionResolutionTest.run(
		world,
		simulation
	)

	var idempotence_pass: bool = _run_same_month_terminal_idempotence_case()

	var snapshot_load_pass: bool = ConcurrentActionSnapshotLoadTest.run(
		world,
		simulation
	)

	TestLogger.write_line(
		"One action enters and resolves through the existing ActionManager path: "
		+ ("PASS" if one_action_pass else "FAIL")
	)

	TestLogger.write_line(
		"Multiple compatible actions coexist in one monthly execution window: "
		+ ("PASS" if multiple_compatible_pass else "FAIL")
	)

	TestLogger.write_line(
		"Resource collision is rejected through the authoritative reservation ledger: "
		+ ("PASS" if contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Capacity collision is rejected without over-allocation: "
		+ ("PASS" if capacity_pass else "FAIL")
	)

	TestLogger.write_line(
		"Budget collision is rejected through the authoritative financial reservation path: "
		+ ("PASS" if contention_pass else "FAIL")
	)

	TestLogger.write_line(
		"Invalid oversubscription is rejected without partial commitment: "
		+ ("PASS" if contention_pass and capacity_pass else "FAIL")
	)

	TestLogger.write_line(
		"Completion / outcome order follows deterministic resolution policy: "
		+ ("PASS" if deterministic_pass else "FAIL")
	)

	TestLogger.write_line(
		"Repeated same-date terminal processing is idempotent: "
		+ ("PASS" if idempotence_pass else "FAIL")
	)

	TestLogger.write_line(
		"Concurrent snapshot / load preserves executable state: "
		+ ("PASS" if snapshot_load_pass else "FAIL")
	)

	var overall_pass: bool = (
		one_action_pass
		and multiple_compatible_pass
		and contention_pass
		and capacity_pass
		and deterministic_pass
		and idempotence_pass
		and snapshot_load_pass
	)

	TestLogger.write_line(
		"Step 16.7 Concurrent Action Regression overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


static func _run_one_action_case() -> bool:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 3

	var test_world: WorldState = WorldState.new(config)
	var actor: SimEntity = SimEntity.new(
		"step16_7_single_actor",
		"Step 16.7 Single Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step16_7_single_target",
		"Step 16.7 Single Target",
		"country"
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = simulation.action_manager

	if manager == null:
		return false

	var action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		5.0,
		1
	)

	var admitted: bool = simulation.add_action(action)
	var admitted_state_ok: bool = (
		admitted
		and action.state == SimAction.STATE_QUEUED
		and manager.get_pending_count() == 1
	)

	simulation.tick_month()

	return (
		admitted_state_ok
		and action.state == SimAction.STATE_COMPLETED
		and manager.get_pending_count() == 0
		and manager.get_outcome_count() == 1
	)


static func _run_multiple_compatible_actions_case() -> bool:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 5

	var test_world: WorldState = WorldState.new(config)
	var actor: SimEntity = SimEntity.new(
		"step16_7_multi_actor",
		"Step 16.7 Multi Actor",
		"country"
	)
	test_world.add_entity(actor)

	var targets: Array[SimEntity] = []
	for index in range(3):
		var target: SimEntity = SimEntity.new(
			"step16_7_multi_target_" + str(index + 1),
			"Step 16.7 Multi Target " + str(index + 1),
			"country"
		)
		test_world.add_entity(target)
		actor.set_relationship(target.id, 0.0)
		targets.append(target)

	var simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = simulation.action_manager

	if manager == null:
		return false

	var actions: Array[SimAction] = []
	for target_variant in targets:
		var target: SimEntity = target_variant as SimEntity
		var action: SimAction = SimAction.new(
			"diplomatic_outreach",
			actor.id,
			target.id,
			1.0,
			2
		)
		actions.append(action)

	var admissions_ok: bool = true
	for action_variant in actions:
		var action: SimAction = action_variant as SimAction
		if not simulation.add_action(action):
			admissions_ok = false

	var before_tick_ok: bool = (
		admissions_ok
		and manager.get_pending_count() == 3
		and manager.get_concurrent_action_count(actor.id) == 3
	)

	simulation.tick_month()

	var progress_ok: bool = true
	for action_variant in actions:
		var action: SimAction = action_variant as SimAction
		if action.state != SimAction.STATE_ACTIVE:
			progress_ok = false
		if not is_equal_approx(action.progress, 0.5):
			progress_ok = false

	return before_tick_ok and progress_ok


static func _run_same_month_terminal_idempotence_case() -> bool:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 3

	var test_world: WorldState = WorldState.new(config)
	var actor: SimEntity = SimEntity.new(
		"step16_7_idempotence_actor",
		"Step 16.7 Idempotence Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step16_7_idempotence_target",
		"Step 16.7 Idempotence Target",
		"country"
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = simulation.action_manager

	if manager == null:
		return false

	var action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		7.0,
		1
	)

	if not simulation.add_action(action):
		return false

	simulation.tick_month()

	var relationship_after_first: float = actor.get_relationship(
		target.id,
		0.0
	)
	var outcomes_after_first: int = manager.get_outcome_count()
	var pending_after_first: int = manager.get_pending_count()

	# Re-run the authoritative ActionManager directly without advancing
	# WorldState time. The already-terminal action is no longer pending, so
	# the second same-date call must not create another effect/outcome.
	manager.process_month(test_world)

	var relationship_after_repeat: float = actor.get_relationship(
		target.id,
		0.0
	)

	return (
		action.state == SimAction.STATE_COMPLETED
		and pending_after_first == 0
		and outcomes_after_first == 1
		and manager.get_outcome_count() == outcomes_after_first
		and is_equal_approx(
			relationship_after_repeat,
			relationship_after_first
		)
	)
