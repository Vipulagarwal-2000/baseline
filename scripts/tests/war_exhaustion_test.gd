class_name WarExhaustionTest
extends RefCounted


static func run(world: WorldState, simulation: SimulationEngine) -> bool:

	TestLogger.section("WAR EXHAUSTION TEST")

	if world == null:
		TestLogger.write_line("World exists: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation exists: FAIL")
		return false

	var conflict_system = simulation.get_system(
		"conflict_system"
	)

	var military_system = simulation.get_system(
		"military_system"
	)

	var systems_exist = (
		conflict_system != null
		and military_system != null
	)

	TestLogger.write_line(
		"Conflict and military systems available: "
		+ ("PASS" if systems_exist else "FAIL")
	)

	if not systems_exist:
		return false

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
		"War participants exist: "
		+ ("PASS" if participants_exist else "FAIL")
	)

	if not participants_exist:
		return false

	var attacker_military = attacker.get_component(
		"military"
	)

	var defender_military = defender.get_component(
		"military"
	)

	var military_components_exist = (
		attacker_military != null
		and defender_military != null
	)

	TestLogger.write_line(
		"Military components available: "
		+ ("PASS" if military_components_exist else "FAIL")
	)

	if not military_components_exist:
		return false

	var conflict_id = "war_exhaustion_test_conflict"

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

	var attacker_at_war = bool(
		attacker_military.get_state(
			"at_war",
			false
		)
	)

	var defender_at_war = bool(
		defender_military.get_state(
			"at_war",
			false
		)
	)

	var at_war_synchronized = (
		attacker_at_war
		and defender_at_war
	)

	TestLogger.write_line(
		"Both countries marked at war: "
		+ ("PASS" if at_war_synchronized else "FAIL")
	)

	var initial_attacker_exhaustion = float(
		attacker_military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var initial_defender_exhaustion = float(
		defender_military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	TestLogger.write_line(
		"Initial attacker exhaustion: "
		+ str(initial_attacker_exhaustion)
	)

	TestLogger.write_line(
		"Initial defender exhaustion: "
		+ str(initial_defender_exhaustion)
	)

	# MilitarySystem is earlier in the monthly order.
	# Run it once while both countries are at war.
	military_system.process_month(
		world
	)

	var attacker_exhaustion_after = float(
		attacker_military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var defender_exhaustion_after = float(
		defender_military.get_state(
			"war_exhaustion",
			0.0
		)
	)

	var attacker_exhaustion_increased = (
		attacker_exhaustion_after
		> initial_attacker_exhaustion
	)

	var defender_exhaustion_increased = (
		defender_exhaustion_after
		> initial_defender_exhaustion
	)

	TestLogger.write_line(
		"Attacker war exhaustion increased: "
		+ ("PASS" if attacker_exhaustion_increased else "FAIL")
	)

	TestLogger.write_line(
		"Defender war exhaustion increased: "
		+ ("PASS" if defender_exhaustion_increased else "FAIL")
	)

	# End the conflict explicitly so the test can verify
	# that the war-state synchronization is reversible.
	var conflict = null

	for candidate in world.active_conflicts:

		if candidate == null:
			continue

		if not candidate is MilitaryConflict:
			continue

		if candidate.id == conflict_id:
			conflict = candidate
			break

	var conflict_found = conflict != null

	TestLogger.write_line(
		"Test conflict found: "
		+ ("PASS" if conflict_found else "FAIL")
	)

	if conflict_found:
		conflict.complete(
			"test_complete",
			"war_exhaustion_test"
		)

		conflict_system._clear_conflict_war_state(
			world,
			conflict
		)

	var attacker_at_war_after = bool(
		attacker_military.get_state(
			"at_war",
			false
		)
	)

	var defender_at_war_after = bool(
		defender_military.get_state(
			"at_war",
			false
		)
	)

	var war_state_cleared = (
		not attacker_at_war_after
		and not defender_at_war_after
	)

	TestLogger.write_line(
		"War state cleared after conflict: "
		+ ("PASS" if war_state_cleared else "FAIL")
	)

	var passed = (
		systems_exist
		and participants_exist
		and military_components_exist
		and started
		and at_war_synchronized
		and attacker_exhaustion_increased
		and defender_exhaustion_increased
		and conflict_found
		and war_state_cleared
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		"WAR EXHAUSTION TEST RESULT"
	)

	TestLogger.write_line(
		"War exhaustion test passed: "
		+ ("true" if passed else "false")
	)

	return passed
