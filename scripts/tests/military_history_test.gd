class_name MilitaryHistoryTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"MILITARY HISTORY TEST"
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

	var military_history_system = simulation.get_system(
		"military_history_system"
	)

	var system_available = (
		military_history_system != null
	)

	TestLogger.write_line(
		"Military history system available: "
		+ (
			"PASS"
			if system_available
			else "FAIL"
		)
	)

	if not system_available:
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
		"History test participants exist: "
		+ (
			"PASS"
			if participants_exist
			else "FAIL"
		)
	)

	if not participants_exist:
		return false

	# ============================================================
	# CREATE COMPLETED CONFLICT
	# ============================================================

	var conflict_id = (
		"military_history_test_conflict"
	)

	var conflict_system = simulation.get_system(
		"conflict_system"
	)

	if conflict_system == null:
		TestLogger.write_line(
			"Conflict system available: FAIL"
		)
		return false

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
		"Conflict retrieved: "
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
		"history_test_resolution"
	)

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
		"Completed conflict stored: "
		+ (
			"PASS"
			if completed_conflict_found
			else "FAIL"
		)
	)

	if not completed_conflict_found:
		return false

	# ============================================================
	# PROCESS HISTORY
	# ============================================================

	military_history_system.process_month(
		world
	)

	var history = (
		military_history_system.get_history(
			world
		)
	)

	var history_exists = (
		typeof(history) == TYPE_ARRAY
		and not history.is_empty()
	)

	TestLogger.write_line(
		"Military history exists: "
		+ (
			"PASS"
			if history_exists
			else "FAIL"
		)
	)

	if not history_exists:
		return false

	# ============================================================
	# FIND CONFLICT HISTORY ENTRY
	# ============================================================

	var conflict_history_found = false
	var conflict_history_entry = {}

	for entry in history:

		if typeof(entry) != TYPE_DICTIONARY:
			continue

		if entry.get(
			"type",
			""
		) != "conflict_resolved":
			continue

		if entry.get(
			"conflict_id",
			""
		) != conflict_id:
			continue

		conflict_history_found = true
		conflict_history_entry = entry
		break

	TestLogger.write_line(
		"Conflict history entry created: "
		+ (
			"PASS"
			if conflict_history_found
			else "FAIL"
		)
	)

	if not conflict_history_found:
		return false

	# ============================================================
	# VERIFY PARTICIPANTS
	# ============================================================

	var participants_correct = (
		conflict_history_entry.get(
			"attacker_id",
			""
		) == attacker.id
		and
		conflict_history_entry.get(
			"defender_id",
			""
		) == defender.id
	)

	TestLogger.write_line(
		"History participants correct: "
		+ (
			"PASS"
			if participants_correct
			else "FAIL"
		)
	)

	# ============================================================
	# VERIFY OUTCOME
	# ============================================================

	var outcome_correct = (
		conflict_history_entry.get(
			"outcome",
			""
		) == "attacker_advantage"
	)

	TestLogger.write_line(
		"History outcome correct: "
		+ (
			"PASS"
			if outcome_correct
			else "FAIL"
		)
	)

	# ============================================================
	# VERIFY TERMINATION REASON
	# ============================================================

	var reason_correct = (
		conflict_history_entry.get(
			"termination_reason",
			""
		) == "history_test_resolution"
	)

	TestLogger.write_line(
		"History termination reason correct: "
		+ (
			"PASS"
			if reason_correct
			else "FAIL"
		)
	)

	# ============================================================
	# DUPLICATE PREVENTION
	# ============================================================

	var history_count_before = (
		history.size()
	)

	military_history_system.process_month(
		world
	)

	var history_after = (
		military_history_system.get_history(
			world
		)
	)

	var history_count_after = (
		history_after.size()
	)

	var duplicate_prevented = (
		history_count_after
		== history_count_before
	)

	TestLogger.write_line(
		"Duplicate history prevented: "
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
		system_available
		and participants_exist
		and conflict_started
		and conflict_found
		and completed_conflict_found
		and history_exists
		and conflict_history_found
		and participants_correct
		and outcome_correct
		and reason_correct
		and duplicate_prevented
	)

	TestLogger.section(
		"MILITARY HISTORY TEST RESULT"
	)

	TestLogger.write_line(
		"Military history test passed: "
		+ str(passed)
	)

	return passed
