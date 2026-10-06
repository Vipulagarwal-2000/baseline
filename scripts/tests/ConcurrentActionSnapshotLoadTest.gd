class_name ConcurrentActionSnapshotLoadTest
extends RefCounted


# ============================================================
# STEP 16.6 — SNAPSHOT / LOAD TEST
# ============================================================
#
# Step 16.6 verifies that the existing WorldSnapshot / ActionManager
# snapshot boundary preserves concurrent executable-action state.
#
# The test intentionally uses the existing snapshot architecture:
#
#   SimulationEngine
#       -> SnapshotManager
#       -> WorldSnapshot
#       -> ActionManager.capture_snapshot_state()
#
# and restores through:
#
#   SimulationEngine.restore_action_snapshot_state()
#       -> ActionManager.restore_snapshot_state()
#
# No second persistence system is introduced.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "STEP 16.6 — SNAPSHOT / LOAD TEST"
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
	var target_a: SimEntity = fixture["target_a"] as SimEntity
	var target_b: SimEntity = fixture["target_b"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	var fixture_available: bool = (
		test_world != null
		and isolated_simulation != null
		and actor != null
		and target_a != null
		and target_b != null
		and manager != null
	)

	TestLogger.write_line(
        "Concurrent snapshot fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	# ------------------------------------------------------------
	# 1. ADMIT MULTIPLE CONCURRENT ACTIONS
	# ------------------------------------------------------------

	var action_a: SimAction = SimAction.new(
		"step16_6_snapshot_a",
		actor.id,
		target_a.id,
		0.0,
		3
	)
	action_a.priority = 5
	action_a.resource_requirements = {
		"steel": 20.0
	}

	var action_b: SimAction = SimAction.new(
		"step16_6_snapshot_b",
		actor.id,
		target_b.id,
		0.0,
		3
	)
	action_b.priority = 5
	action_b.resource_requirements = {
		"steel": 20.0
	}

	var admitted_a: bool = isolated_simulation.add_action(action_a)
	var admitted_b: bool = isolated_simulation.add_action(action_b)

	var admission_pass: bool = (
		admitted_a
		and admitted_b
		and manager.get_pending_count() == 2
		and manager.get_reservation_count() == 2
		and manager.get_concurrent_action_count(actor.id) == 2
	)

	TestLogger.write_line(
        "Multiple compatible actions are admitted before snapshot: "
		+ ("PASS" if admission_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. ADVANCE ONCE AND CAPTURE ACTIVE CONCURRENT STATE
	# ------------------------------------------------------------

	isolated_simulation.tick_month()

	var pre_snapshot_state: Dictionary = isolated_simulation.get_action_snapshot_state()
	var pending_value: Variant = pre_snapshot_state.get("pending_actions", [])
	var reservations_value: Variant = pre_snapshot_state.get("reservations", [])

	var capture_pass: bool = false
	if typeof(pending_value) == TYPE_ARRAY and typeof(reservations_value) == TYPE_ARRAY:
		var pending_snapshot: Array = pending_value
		var reservations_snapshot: Array = reservations_value
		capture_pass = (
			pending_snapshot.size() == 2
			and reservations_snapshot.size() == 2
			and action_a.state == SimAction.STATE_ACTIVE
			and action_b.state == SimAction.STATE_ACTIVE
			and is_equal_approx(action_a.progress, 1.0 / 3.0)
			and is_equal_approx(action_b.progress, 1.0 / 3.0)
			and action_a.duration_months == 2
			and action_b.duration_months == 2
		)

	TestLogger.write_line(
        "Snapshot captures concurrent active actions, progress, duration, and reservations: "
		+ ("PASS" if capture_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. SNAPSHOT DEEP-COPY ISOLATION
	# ------------------------------------------------------------

	var external_snapshot_state: Dictionary = (
		isolated_simulation.get_action_snapshot_state()
	)
	var external_pending: Variant = external_snapshot_state.get(
		"pending_actions",
		[]
	)
	if typeof(external_pending) == TYPE_ARRAY:
		var external_pending_array: Array = external_pending
		external_pending_array.clear()
		external_snapshot_state["pending_actions"] = external_pending_array

	var stored_snapshot_state: Dictionary = (
		isolated_simulation.get_action_snapshot_state()
	)
	var stored_pending: Variant = stored_snapshot_state.get(
		"pending_actions",
		[]
	)

	var deep_copy_pass: bool = (
		typeof(stored_pending) == TYPE_ARRAY
		and (stored_pending as Array).size() == 2
	)

	TestLogger.write_line(
        "Snapshot action state remains isolated from external mutation: "
		+ ("PASS" if deep_copy_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. MUTATE LIVE EXECUTION STATE AFTER SNAPSHOT
	# ------------------------------------------------------------

	isolated_simulation.tick_month()

	var live_mutation_pass: bool = (
		is_equal_approx(action_a.progress, 2.0 / 3.0)
		and is_equal_approx(action_b.progress, 2.0 / 3.0)
		and action_a.duration_months == 1
		and action_b.duration_months == 1
	)

	TestLogger.write_line(
        "Live concurrent actions can diverge after snapshot capture: "
		+ ("PASS" if live_mutation_pass else "FAIL")
	)

	# Remove one live action so restore must reconstruct it from the snapshot.
	var interrupted_live_action: bool = manager.interrupt_action(
		action_a,
        "Step 16.6 live-state mutation before restore."
	)

	var live_divergence_structure_pass: bool = (
		interrupted_live_action
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
		and manager.get_concurrent_action_count(actor.id) == 1
	)

	TestLogger.write_line(
        "Live mutation can alter concurrent membership before restore: "
		+ ("PASS" if live_divergence_structure_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. RESTORE THE CAPTURED SNAPSHOT
	# ------------------------------------------------------------

	var snapshot_count: int = isolated_simulation.get_snapshot_count()
	var restore_result: bool = isolated_simulation.restore_action_snapshot_state(
		snapshot_count - 2
	)

	var restored_actions: Array = manager.get_pending_actions()
	var restored_a: SimAction = null
	var restored_b: SimAction = null

	for action_variant in restored_actions:
		var candidate: SimAction = action_variant as SimAction
		if candidate == null:
			continue
		if candidate.action_type == "step16_6_snapshot_a":
			restored_a = candidate
		elif candidate.action_type == "step16_6_snapshot_b":
			restored_b = candidate

	var restore_state_pass: bool = (
		restore_result
		and restored_actions.size() == 2
		and restored_a != null
		and restored_b != null
		and restored_a.state == SimAction.STATE_ACTIVE
		and restored_b.state == SimAction.STATE_ACTIVE
		and is_equal_approx(restored_a.progress, 1.0 / 3.0)
		and is_equal_approx(restored_b.progress, 1.0 / 3.0)
		and restored_a.duration_months == 2
		and restored_b.duration_months == 2
		and restored_a.total_duration_months == 3
		and restored_b.total_duration_months == 3
		and restored_a.priority == 5
		and restored_b.priority == 5
		and manager.get_reservation_count() == 2
		and manager.get_concurrent_action_count(actor.id) == 2
	)

	TestLogger.write_line(
        "Restored concurrent action state, progress, duration, priority, reservations, and capacity occupancy: "
		+ ("PASS" if restore_state_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 6. DETERMINISTIC RESOLUTION ORDER SURVIVES RESTORE
	# ------------------------------------------------------------

	var resolution_order: Array = manager.get_deterministic_resolution_order()
	var resolution_pass: bool = false

	if resolution_order.size() == 2:
		var first_entry: Dictionary = resolution_order[0] as Dictionary
		var second_entry: Dictionary = resolution_order[1] as Dictionary
		resolution_pass = (
			str(first_entry.get("action_type", "")) == "step16_6_snapshot_a"
			and str(second_entry.get("action_type", "")) == "step16_6_snapshot_b"
			and int(first_entry.get("priority", 0)) == 5
			and int(second_entry.get("priority", 0)) == 5
			and int(first_entry.get("admission_order", -1))
			< int(second_entry.get("admission_order", -1))
		)

	TestLogger.write_line(
        "Deterministic admission order and priority survive snapshot restore: "
		+ ("PASS" if resolution_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 7. NEW ADMISSION AFTER RESTORE KEEPS ORDERING CONTINUITY
	# ------------------------------------------------------------

	var action_c: SimAction = SimAction.new(
		"step16_6_snapshot_c",
		actor.id,
		target_a.id,
		0.0,
		2
	)
	action_c.priority = 5
	action_c.resource_requirements = {
		"steel": 20.0
	}

	var admitted_after_restore: bool = isolated_simulation.add_action(action_c)
	var post_restore_resolution: Array = manager.get_deterministic_resolution_order()
	var ordering_continuity_pass: bool = false

	if post_restore_resolution.size() == 3:
		var first_post: Dictionary = post_restore_resolution[0] as Dictionary
		var second_post: Dictionary = post_restore_resolution[1] as Dictionary
		var third_post: Dictionary = post_restore_resolution[2] as Dictionary
		ordering_continuity_pass = (
			admitted_after_restore
			and str(first_post.get("action_type", "")) == "step16_6_snapshot_a"
			and str(second_post.get("action_type", "")) == "step16_6_snapshot_b"
			and str(third_post.get("action_type", "")) == "step16_6_snapshot_c"
			and int(first_post.get("admission_order", -1))
			< int(second_post.get("admission_order", -1))
			and int(second_post.get("admission_order", -1))
			< int(third_post.get("admission_order", -1))
		)

	TestLogger.write_line(
        "New admission after restore continues deterministic ordering: "
		+ ("PASS" if ordering_continuity_pass else "FAIL")
	)

	var overall_pass: bool = (
		admission_pass
		and capture_pass
		and deep_copy_pass
		and live_mutation_pass
		and live_divergence_structure_pass
		and restore_state_pass
		and resolution_pass
		and ordering_continuity_pass
	)

	TestLogger.write_line(
        "Step 16.6 Snapshot / Load overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 4

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_6_actor",
		"Step 16.6 Actor",
        "country"
	)

	var target_a: SimEntity = SimEntity.new(
		"step16_6_target_a",
		"Step 16.6 Target A",
        "country"
	)

	var target_b: SimEntity = SimEntity.new(
		"step16_6_target_b",
		"Step 16.6 Target B",
        "country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	resources.set_state(
		"stockpile",
		{
			"steel": 100.0,
			"fuel": 50.0
		}
	)
	actor.add_component(resources)

	test_world.add_entity(actor)
	test_world.add_entity(target_a)
	test_world.add_entity(target_b)

	actor.set_relationship(target_a.id, 0.0)
	actor.set_relationship(target_b.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(
		test_world
	)
	var manager: ActionManager = isolated_simulation.action_manager

	return {
		"world": test_world,
		"simulation": isolated_simulation,
		"actor": actor,
		"target_a": target_a,
		"target_b": target_b,
		"manager": manager
	}
