class_name MilitaryIntegrationTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["============================================================"])
	_out(["MILITARY INTEGRATION TEST"])
	_out(["============================================================"])


	if world == null:

		push_error(
			"MilitaryIntegrationTest: World is null."
		)

		return false


	if simulation == null:

		push_error(
			"MilitaryIntegrationTest: Simulation is null."
		)

		return false


	var all_passed = true


	# ============================================================
	# TEST 1 — WORLD AVAILABILITY
	# ============================================================

	_out([""])
	_out(["TEST 1 — World availability"])


	if world.entities.is_empty():

		push_error(
			"MilitaryIntegrationTest: No entities found."
		)

		all_passed = false

	else:

		_out([
			"World entities: ",
			world.entities.size()
		])

		_out([
			"World availability: PASS"
		])


	# ============================================================
	# TEST 2 — MILITARY COMPONENT AVAILABILITY
	# ============================================================

	_out([""])
	_out(["TEST 2 — Military component availability"])


	var military_count = 0


	for entity in world.entities.values():

		if entity == null:
			continue

		var military = entity.get_component(
			"military"
		)

		if military != null:

			military_count += 1


	if military_count == 0:

		push_error(
			"MilitaryIntegrationTest: No military components found."
		)

		all_passed = false

	else:

		_out([
			"Military components found: ",
			military_count
		])

		_out([
			"Military component availability: PASS"
		])


	# ============================================================
	# TEST 3 — GEOGRAPHY SYSTEM AVAILABILITY
	# ============================================================

	_out([""])
	_out(["TEST 3 — Geography system availability"])


	var geography_system = simulation.get_system(
		"geography_system"
	)


	if geography_system == null:

		push_error(
			"MilitaryIntegrationTest: Geography system not found."
		)

		all_passed = false

	else:

		_out([
			"Geography system: PASS"
		])


	# ============================================================
	# FUTURE INTEGRATION TESTS
	# ============================================================
	#
	# These will be added one at a time.
	#
	# 01 Geography → Military
	# 02 Government → Military
	# 03 Military → Government
	# 04 Military → Capability
	# 05 Military → Influence
	# 06 Military → Relationships
	# 07 Military → Diplomacy
	# 08 Military → AI Goals
	# 09 Military → Strategy
	# 10 Military → Decision Evaluation
	# 11 Basic Conflict
	# 12 War Exhaustion
	# 13 Military Events
	# 14 Military History
	# 15 Military Snapshots
	# 16 Military Divergence
	# 17 Country-specific military data
	#
	# ============================================================


	_out([""])
	_out(["============================================================"])


	if all_passed:

		_out([
			"MILITARY INTEGRATION TEST PASSED"
		])

	else:

		_out([
			"MILITARY INTEGRATION TEST FAILED"
		])


	_out(["============================================================"])


	return all_passed
