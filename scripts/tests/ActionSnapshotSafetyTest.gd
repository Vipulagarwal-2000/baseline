class_name ActionSnapshotSafetyTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.12 — ACTION SNAPSHOT SAFETY TEST"
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
			"Step 15.12 Snapshot Safety test: FAIL"
		)
		return false

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------

	var config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(config)
	var test_actor: SimEntity = SimEntity.new(
		"step15_12_actor",
		"Step 15.12 Actor",
		"country"
	)
	var test_target: SimEntity = SimEntity.new(
		"step15_12_target",
		"Step 15.12 Target",
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
	# ACTIVE ACTION SNAPSHOT
	# ------------------------------------------------------------

	var action: SimAction = SimAction.new(
		"diplomatic_outreach",
		test_actor.id,
		test_target.id,
		0.0,
		3
	)

	var submitted: bool = isolated_simulation.add_action(action)
	isolated_simulation.tick_month()

	var snapshot: WorldSnapshot = isolated_simulation.get_latest_snapshot()
	var snapshot_state: Dictionary = isolated_simulation.get_action_snapshot_state()
	var pending_after_capture: Array = manager.get_pending_actions()

	var active_action_pass: bool = (
		submitted
		and snapshot != null
		and not snapshot_state.is_empty()
		and pending_after_capture.size() == 1
		and pending_after_capture[0].state == SimAction.STATE_ACTIVE
		and is_equal_approx(
			float(pending_after_capture[0].progress),
			1.0 / 3.0
		)
		and pending_after_capture[0].duration_months == 2
		and manager.get_reservation_count() == 1
	)

	TestLogger.write_line(
		"Active action, progress, status, and reservation captured in snapshot: "
		+ ("PASS" if active_action_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# SNAPSHOT DEEP-COPY ISOLATION
	# ------------------------------------------------------------

	var snapshot_copy: Dictionary = isolated_simulation.get_action_snapshot_state()
	var pending_snapshot_value: Variant = snapshot_copy.get(
		"pending_actions",
		[]
	)
	var reservations_snapshot_value: Variant = snapshot_copy.get(
		"reservations",
		[]
	)

	if typeof(pending_snapshot_value) == TYPE_ARRAY:
		var pending_snapshot: Array = pending_snapshot_value
		if not pending_snapshot.is_empty():
			var action_record: Dictionary = pending_snapshot[0]
			action_record["progress"] = 0.95
			pending_snapshot[0] = action_record
			snapshot_copy["pending_actions"] = pending_snapshot

	if typeof(reservations_snapshot_value) == TYPE_ARRAY:
		var reservations_snapshot: Array = reservations_snapshot_value
		if not reservations_snapshot.is_empty():
			var reservation_entry: Dictionary = reservations_snapshot[0]
			var reservation_value: Variant = reservation_entry.get(
				"reservation",
				{}
			)
			if typeof(reservation_value) == TYPE_DICTIONARY:
				var reservation: Dictionary = reservation_value
				reservation["status"] = "tampered"
				reservation_entry["reservation"] = reservation
				reservations_snapshot[0] = reservation_entry
			snapshot_copy["reservations"] = reservations_snapshot

	var live_actions_after_copy: Array = manager.get_pending_actions()
	var live_action: SimAction = null
	if live_actions_after_copy.size() == 1:
		live_action = live_actions_after_copy[0] as SimAction

	var live_reservation_status: String = ""
	if live_action != null:
		live_reservation_status = str(
			manager.get_action_reservation(live_action).get(
				"status",
				""
			)
		)

	var deep_copy_pass: bool = (
		live_action != null
		and is_equal_approx(float(live_action.progress), 1.0 / 3.0)
		and live_reservation_status == ActionManager.RESERVATION_STATUS_COMMITTED
	)

	TestLogger.write_line(
		"Snapshot action state is deep-copy isolated from live execution state: "
		+ ("PASS" if deep_copy_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# MUTATE LIVE STATE, THEN RESTORE
	# ------------------------------------------------------------

	var cancelled: bool = false
	if live_action != null:
		cancelled = manager.cancel_action(
			live_action,
			"Controlled Step 15.12 snapshot restore."
		)

	var mutated_before_restore_pass: bool = (
		cancelled
		and manager.get_pending_count() == 0
		and manager.get_reservation_count() == 0
	)

	TestLogger.write_line(
		"Live action state can diverge from captured snapshot: "
		+ ("PASS" if mutated_before_restore_pass else "FAIL")
	)

	var restored: bool = isolated_simulation.restore_action_snapshot_state(0)
	var restored_actions: Array = manager.get_pending_actions()
	var restored_action: SimAction = null
	if restored_actions.size() == 1:
		restored_action = restored_actions[0] as SimAction

	var restored_reservation: Dictionary = {}
	if restored_action != null:
		restored_reservation = manager.get_action_reservation(
			restored_action
		)

	var restoration_pass: bool = (
		restored
		and restored_action != null
		and restored_action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(float(restored_action.progress), 1.0 / 3.0)
		and restored_action.duration_months == 2
		and restored_action.total_duration_months == 3
		and restored_action.start_date == "1950-01-01"
		and manager.get_pending_count() == 1
		and manager.get_reservation_count() == 1
		and restored_reservation.get(
			"status",
			""
		) == ActionManager.RESERVATION_STATUS_COMMITTED
	)

	TestLogger.write_line(
		"Active action, progress, status, and reservation restore correctly: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# RESTORED SNAPSHOT REMAINS ISOLATED
	# ------------------------------------------------------------

	if restored_action != null:
		restored_action.progress = 0.90

	var restored_snapshot_check: Dictionary = isolated_simulation.get_action_snapshot_state(0)
	var restored_snapshot_pending_value: Variant = restored_snapshot_check.get(
		"pending_actions",
		[]
	)
	var restored_snapshot_progress: float = -1.0
	if typeof(restored_snapshot_pending_value) == TYPE_ARRAY:
		var restored_pending: Array = restored_snapshot_pending_value
		if not restored_pending.is_empty():
			var restored_record: Dictionary = restored_pending[0]
			var progress_value: Variant = restored_record.get(
				"progress",
				-1.0
			)
			if typeof(progress_value) == TYPE_INT or typeof(progress_value) == TYPE_FLOAT:
				restored_snapshot_progress = float(progress_value)

	var restored_snapshot_isolation_pass: bool = (
		is_equal_approx(restored_snapshot_progress, 1.0 / 3.0)
		and isolated_simulation.get_snapshot_count() == 1
	)

	TestLogger.write_line(
		"Restored snapshot remains isolated from later live mutations: "
		+ ("PASS" if restored_snapshot_isolation_pass else "FAIL")
	)

	var passed: bool = (
		active_action_pass
		and deep_copy_pass
		and mutated_before_restore_pass
		and restoration_pass
		and restored_snapshot_isolation_pass
	)

	TestLogger.write_line(
		"Step 15.12 Snapshot Safety test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
