class_name ConflictTest
extends RefCounted


static func run(world: WorldState, simulation: SimulationEngine) -> bool:

	TestLogger.section("BASIC CONFLICT TEST")

	if world == null:
		TestLogger.write_line("World exists: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation exists: FAIL")
		return false

	var conflict_system = simulation.get_system("conflict_system")

	var system_exists = conflict_system != null
	TestLogger.write_line(
		"Conflict system registration: "
		+ ("PASS" if system_exists else "FAIL")
	)

	if not system_exists:
		return false

	var attacker = world.get_entity("india")
	var defender = world.get_entity("china")

	var countries_exist = (
		attacker != null
		and defender != null
	)

	TestLogger.write_line(
		"Conflict participants exist: "
		+ ("PASS" if countries_exist else "FAIL")
	)

	if not countries_exist:
		return false

	var military_a = attacker.get_component("military")
	var military_d = defender.get_component("military")

	var military_exists = (
		military_a != null
		and military_d != null
	)

	TestLogger.write_line(
		"Military components exist: "
		+ ("PASS" if military_exists else "FAIL")
	)

	if not military_exists:
		return false

	var conflict_id = "test_india_china_conflict"

	var started = conflict_system.start_conflict(
		world,
		conflict_id,
		"india",
		"china"
	)

	TestLogger.write_line(
		"Conflict started: "
		+ ("PASS" if started else "FAIL")
	)

	if not started:
		return false

	var conflict = null

	for candidate in world.active_conflicts:
		if candidate == null:
			continue

		if not candidate is MilitaryConflict:
			continue

		if candidate.id == conflict_id:
			conflict = candidate
			break

	var stored = conflict != null

	TestLogger.write_line(
		"Conflict stored in world: "
		+ ("PASS" if stored else "FAIL")
	)

	if not stored:
		return false

	var initial_duration = conflict.duration_months

	var initial_attacker_readiness = float(
		military_a.get_state(
			"readiness",
			0.0
		)
	)

	var initial_defender_readiness = float(
		military_d.get_state(
			"readiness",
			0.0
		)
	)

	conflict_system.process_month(world)

	var duration_changed = (
		conflict.duration_months
		> initial_duration
	)

	TestLogger.write_line(
		"Conflict duration advanced: "
		+ ("PASS" if duration_changed else "FAIL")
	)

	var history_created = (
		conflict.history.size()
		> 0
	)

	TestLogger.write_line(
		"Conflict history created: "
		+ ("PASS" if history_created else "FAIL")
	)

	var pressure_changed = (
		conflict.attacker_pressure > 0.0
		or conflict.defender_pressure > 0.0
	)

	TestLogger.write_line(
		"Conflict pressure calculated: "
		+ ("PASS" if pressure_changed else "FAIL")
	)

	var attacker_readiness_after = float(
		military_a.get_state(
			"readiness",
			0.0
		)
	)

	var defender_readiness_after = float(
		military_d.get_state(
			"readiness",
			0.0
		)
	)

	var readiness_changed = (
		attacker_readiness_after != initial_attacker_readiness
		or defender_readiness_after != initial_defender_readiness
	)

	TestLogger.write_line(
		"Military readiness affected: "
		+ ("PASS" if readiness_changed else "FAIL")
	)

	var pressure_values_valid = (
		conflict.attacker_pressure >= 0.0
		and conflict.attacker_pressure <= 1.0
		and conflict.defender_pressure >= 0.0
		and conflict.defender_pressure <= 1.0
	)

	TestLogger.write_line(
		"Conflict pressure range valid: "
		+ ("PASS" if pressure_values_valid else "FAIL")
	)

	var intensity_valid = (
		conflict.intensity >= 0.0
		and conflict.intensity <= 1.0
	)

	TestLogger.write_line(
		"Conflict intensity range valid: "
		+ ("PASS" if intensity_valid else "FAIL")
	)

	var passed = (
		system_exists
		and countries_exist
		and military_exists
		and started
		and stored
		and duration_changed
		and history_created
		and pressure_changed
		and readiness_changed
		and pressure_values_valid
		and intensity_valid
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		"BASIC CONFLICT TEST RESULT"
	)
	TestLogger.write_line(
		"Basic conflict test passed: "
		+ ("true" if passed else "false")
	)

	return passed
