class_name ConflictResolvedEventTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"CONFLICT RESOLVED EVENT TEST"
	)

	# ============================================================
	# BASIC VALIDATION
	# ============================================================

	if world == null:
		TestLogger.write_line(
			"World exists: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Simulation exists: FAIL"
		)
		return false

	var conflict_system = simulation.get_system(
		"conflict_system"
	)

	var military_event_system = simulation.get_system(
		"military_event_system"
	)

	var systems_available = (
		conflict_system != null
		and military_event_system != null
	)

	TestLogger.write_line(
		"Conflict and military event systems available: "
		+ (
			"PASS"
			if systems_available
			else "FAIL"
		)
	)

	if not systems_available:
		return false

	# ============================================================
	# PARTICIPANTS
	# ============================================================

	var attacker = world.get_entity(
		"india"
	)

	var defender = world.get_entity(
		"china"
	)

	var participants_exist = (
		attacker != null
		and defender != null
	)

	TestLogger.write_line(
		"Conflict participants exist: "
		+ (
			"PASS"
			if participants_exist
			else "FAIL"
		)
	)

	if not participants_exist:
		return false

	# ============================================================
	# START CONFLICT
	# ============================================================

	var conflict_id = (
		"conflict_resolved_event_test"
	)

	var conflict_started = (
		conflict_system.start_conflict(
			world,
			conflict_id,
			attacker.id,
			defender.id
		)
	)

	TestLogger.write_line(
		"Conflict started: "
		+ (
			"PASS"
			if conflict_started
			else "FAIL"
		)
	)

	if not conflict_started:
		return false

	# ============================================================
	# RETRIEVE ACTUAL CONFLICT OBJECT
	# ============================================================

	var conflict = null

	for active_conflict in world.active_conflicts:

		if active_conflict == null:
			continue

		if not active_conflict is MilitaryConflict:
			continue

		if active_conflict.id != conflict_id:
			continue

		conflict = active_conflict
		break

	var conflict_found = (
		conflict != null
	)

	TestLogger.write_line(
		"Conflict retrieved from world: "
		+ (
			"PASS"
			if conflict_found
			else "FAIL"
		)
	)

	if not conflict_found:
		return false

	# ============================================================
	# RESOLVE CONFLICT
	# ============================================================

	conflict.complete(
		"attacker_advantage",
		"test_resolution"
	)

	var conflict_completed = (
		conflict.is_completed()
	)

	TestLogger.write_line(
		"Conflict marked completed: "
		+ (
			"PASS"
			if conflict_completed
			else "FAIL"
		)
	)

	if not conflict_completed:
		return false

	# ============================================================
	# MOVE TO COMPLETED CONFLICTS
	# ============================================================

	world.active_conflicts.erase(
		conflict
	)

	world.add_completed_conflict(
		conflict
	)

	var completed_conflict_found = false

	for completed_conflict in world.completed_conflicts:

		if completed_conflict == null:
			continue

		if not completed_conflict is MilitaryConflict:
			continue

		if completed_conflict.id != conflict_id:
			continue

		completed_conflict_found = true
		break

	TestLogger.write_line(
		"Conflict stored in completed conflicts: "
		+ (
			"PASS"
			if completed_conflict_found
			else "FAIL"
		)
	)

	if not completed_conflict_found:
		return false

	# ============================================================
	# GENERATE EVENT
	# ============================================================

	military_event_system.process_month(
		world
	)

	var expected_event_id = (
		"military_conflict_resolved_"
		+ conflict_id
	)

	var event_found = false
	var matching_event = null

	for event in world.active_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.id != expected_event_id:
			continue

		event_found = true
		matching_event = event
		break

	TestLogger.write_line(
		"Conflict-resolved event created: "
		+ (
			"PASS"
			if event_found
			else "FAIL"
		)
	)

	if not event_found:
		return false

	# ============================================================
	# EVENT TYPE
	# ============================================================

	var event_type_correct = (
		matching_event.event_type == "military"
		and matching_event.get_metadata_value(
			"military_event_type",
			""
		) == "conflict_resolved"
	)

	TestLogger.write_line(
		"Military event metadata correct: "
		+ (
			"PASS"
			if event_type_correct
			else "FAIL"
		)
	)

	# ============================================================
	# ACTORS / TARGETS
	# ============================================================

	var participants_correct = (
		matching_event.has_actor(
			attacker.id
		)
		and matching_event.has_target(
			defender.id
		)
	)

	TestLogger.write_line(
		"Event actors and targets correct: "
		+ (
			"PASS"
			if participants_correct
			else "FAIL"
		)
	)

	# ============================================================
	# OUTCOME
	# ============================================================

	var outcome_correct = (
		matching_event.get_metadata_value(
			"outcome",
			""
		) == "attacker_advantage"
	)

	TestLogger.write_line(
		"Conflict outcome preserved: "
		+ (
			"PASS"
			if outcome_correct
			else "FAIL"
		)
	)

	# ============================================================
	# TERMINATION REASON
	# ============================================================

	var reason_correct = (
		matching_event.get_metadata_value(
			"termination_reason",
			""
		) == "test_resolution"
	)

	TestLogger.write_line(
		"Termination reason preserved: "
		+ (
			"PASS"
			if reason_correct
			else "FAIL"
		)
	)

	# ============================================================
	# CONFLICT REFERENCE
	# ============================================================

	var conflict_reference_correct = (
		matching_event.get_metadata_value(
			"conflict_id",
			""
		) == conflict_id
	)

	TestLogger.write_line(
		"Conflict reference correct: "
		+ (
			"PASS"
			if conflict_reference_correct
			else "FAIL"
		)
	)

	# ============================================================
	# DURATION
	# ============================================================

	var duration_correct = (
		int(
			matching_event.get_metadata_value(
				"duration_months",
				-1
			)
		)
		== conflict.duration_months
	)

	TestLogger.write_line(
		"Conflict duration preserved: "
		+ (
			"PASS"
			if duration_correct
			else "FAIL"
		)
	)

	# ============================================================
	# DUPLICATE PREVENTION
	# ============================================================

	var event_count_after_first = (
		world.active_events.size()
	)

	military_event_system.process_month(
		world
	)

	var event_count_after_second = (
		world.active_events.size()
	)

	var duplicate_prevented = (
		event_count_after_second
		== event_count_after_first
	)

	TestLogger.write_line(
		"Duplicate event prevented: "
		+ (
			"PASS"
			if duplicate_prevented
			else "FAIL"
		)
	)

	# ============================================================
	# FINAL RESULT
	# ============================================================

	var passed = (
		conflict_started
		and conflict_found
		and conflict_completed
		and completed_conflict_found
		and event_found
		and event_type_correct
		and participants_correct
		and outcome_correct
		and reason_correct
		and conflict_reference_correct
		and duration_correct
		and duplicate_prevented
	)

	TestLogger.section(
		"CONFLICT RESOLVED EVENT RESULT"
	)

	TestLogger.write_line(
		"Conflict resolved event test passed: "
		+ str(passed)
	)

	return passed
