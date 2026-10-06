class_name MilitaryPressureEventTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"MILITARY PRESSURE EVENT TEST"
	)

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

	var military_event_system = simulation.get_system(
		"military_event_system"
	)

	var system_available = (
		military_event_system != null
	)

	TestLogger.write_line(
		"Military event system available: "
		+ (
			"PASS"
			if system_available
			else "FAIL"
		)
	)

	if not system_available:
		return false

	var india = world.get_entity("india")

	var country_exists = (
		india != null
	)

	TestLogger.write_line(
		"India exists: "
		+ (
			"PASS"
			if country_exists
			else "FAIL"
		)
	)

	if not country_exists:
		return false

	var military = india.get_component(
		"military"
	)

	var military_exists = (
		military != null
	)

	TestLogger.write_line(
		"India military component exists: "
		+ (
			"PASS"
			if military_exists
			else "FAIL"
		)
	)

	if not military_exists:
		return false

	var original_pressure = float(
		military.get_state(
			"military_pressure",
			0.0
		)
	)

	var high_pressure = 0.80

	military.set_state(
		"military_pressure",
		high_pressure
	)

	TestLogger.write_line(
		"Military pressure raised above threshold: PASS"
	)

	var event_count_before = (
		world.active_events.size()
	)

	military_event_system.process_month(
		world
	)

	var expected_event_id = (
		"military_pressure_high_"
		+ india.id
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
		"High-pressure event created: "
		+ (
			"PASS"
			if event_found
			else "FAIL"
		)
	)

	if not event_found:
		military.set_state(
			"military_pressure",
			original_pressure
		)
		return false

	var event_type_correct = (
		matching_event.event_type == "military"
		and matching_event.get_metadata_value(
			"military_event_type",
			""
		) == "military_pressure_high"
	)

	TestLogger.write_line(
		"Military event metadata correct: "
		+ (
			"PASS"
			if event_type_correct
			else "FAIL"
		)
	)

	var actor_correct = (
		matching_event.has_actor(
			india.id
		)
	)

	TestLogger.write_line(
		"Country actor correct: "
		+ (
			"PASS"
			if actor_correct
			else "FAIL"
		)
	)

	var pressure_metadata_correct = is_equal_approx(
		float(
			matching_event.get_metadata_value(
				"military_pressure",
				-1.0
			)
		),
		high_pressure
	)

	TestLogger.write_line(
		"Pressure metadata correct: "
		+ (
			"PASS"
			if pressure_metadata_correct
			else "FAIL"
		)
	)

	var event_count_after_first = (
		world.active_events.size()
	)

	var event_added = (
		event_count_after_first
		> event_count_before
	)

	TestLogger.write_line(
		"Event added to world: "
		+ (
			"PASS"
			if event_added
			else "FAIL"
		)
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

	military.set_state(
		"military_pressure",
		original_pressure
	)

	var passed = (
		event_found
		and event_type_correct
		and actor_correct
		and pressure_metadata_correct
		and event_added
		and duplicate_prevented
	)

	TestLogger.section(
		"MILITARY PRESSURE EVENT RESULT"
	)

	TestLogger.write_line(
		"Military pressure event test passed: "
		+ str(passed)
	)

	return passed
