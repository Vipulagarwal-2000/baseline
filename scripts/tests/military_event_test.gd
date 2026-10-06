class_name MilitaryEventTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section("MILITARY EVENT TEST")

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
		+ ("PASS" if systems_available else "FAIL")
	)

	if not systems_available:
		return false

	var attacker = world.get_entity("india")
	var defender = world.get_entity("china")

	var participants_exist = (
		attacker != null
		and defender != null
	)

	TestLogger.write_line(
		"Conflict participants exist: "
		+ ("PASS" if participants_exist else "FAIL")
	)

	if not participants_exist:
		return false

	var initial_event_count = (
		world.active_events.size()
	)

	var conflict_id = (
		"military_event_test_conflict"
	)

	var conflict = conflict_system.start_conflict(
		world,
		conflict_id,
		attacker.id,
		defender.id
	)

	var conflict_started = (
		conflict != null
	)

	TestLogger.write_line(
		"Conflict started: "
		+ ("PASS" if conflict_started else "FAIL")
	)

	if not conflict_started:
		return false

	military_event_system.process_month(world)

	var event_found = false
	var matching_event = null

	for event in world.active_events:
		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.id != (
			"military_conflict_started_"
			+ conflict_id
		):
			continue

		event_found = true
		matching_event = event
		break

	TestLogger.write_line(
		"Conflict-started event created: "
		+ ("PASS" if event_found else "FAIL")
	)

	if not event_found:
		return false

	var event_type_correct = (
		matching_event.event_type == "military"
		and matching_event.get_metadata_value(
			"military_event_type",
			""
		) == "conflict_started"
	)

	TestLogger.write_line(
		"Military event metadata correct: "
		+ ("PASS" if event_type_correct else "FAIL")
	)

	var actors_correct = (
		matching_event.has_actor(
			attacker.id
		)
		and matching_event.has_target(
			defender.id
		)
	)

	TestLogger.write_line(
		"Event actors and targets correct: "
		+ ("PASS" if actors_correct else "FAIL")
	)

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

	var event_count_after_first = (
		world.active_events.size()
	)

	military_event_system.process_month(world)

	var event_count_after_second = (
		world.active_events.size()
	)

	var no_duplicate = (
		event_count_after_second
		== event_count_after_first
	)

	TestLogger.write_line(
		"Duplicate event prevented: "
		+ ("PASS" if no_duplicate else "FAIL")
	)

	var event_added = (
		event_count_after_first
		> initial_event_count
	)

	TestLogger.write_line(
		"Event added to world: "
		+ ("PASS" if event_added else "FAIL")
	)

	var passed = (
		event_found
		and event_type_correct
		and actors_correct
		and conflict_reference_correct
		and no_duplicate
		and event_added
	)

	TestLogger.section(
		"MILITARY EVENT TEST RESULT"
	)

	TestLogger.write_line(
		"Military event test passed: "
		+ str(passed)
	)

	return passed
