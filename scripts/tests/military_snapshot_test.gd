class_name MilitarySnapshotTest
extends RefCounted


func run(world: WorldState) -> bool:

	TestLogger.section(
		"MILITARY SNAPSHOT TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World: FAIL"
		)
		return false

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line(
			"India: FAIL"
		)
		return false

	TestLogger.write_line(
		"India found: " + india.name
	)

	var military = india.get_component(
		"military"
	)

	if military == null:
		TestLogger.write_line(
			"Military component: FAIL"
		)
		return false

	TestLogger.write_line(
		"Military component: FOUND"
	)


	# ========================================================
	# CAPTURE FIRST SNAPSHOT
	# ========================================================

	var snapshot_1 = WorldSnapshot.new()

	snapshot_1.capture(world)

	var military_snapshot_1 = (
		snapshot_1.get_military_snapshot(
			"india"
		)
	)

	if military_snapshot_1.is_empty():

		TestLogger.write_line(
			"Military snapshot capture: FAIL"
		)

		return false

	TestLogger.write_line(
		"Military snapshot capture: PASS"
	)


	# ========================================================
	# READ ORIGINAL MILITARY POWER
	# ========================================================

	var original_power = float(
		military.get_state(
			"military_power",
			0.0
		)
	)

	TestLogger.write_line(
		"Original military power: "
		+ str(original_power)
	)


	# ========================================================
	# CHANGE MILITARY POWER
	# ========================================================

	var changed_power = clamp(
		original_power + 0.10,
		0.0,
		1.0
	)

	military.set_state(
		"military_power",
		changed_power
	)

	TestLogger.write_line(
		"Changed military power: "
		+ str(changed_power)
	)


	# ========================================================
	# CAPTURE SECOND SNAPSHOT
	# ========================================================

	var snapshot_2 = WorldSnapshot.new()

	snapshot_2.capture(world)

	var military_snapshot_2 = (
		snapshot_2.get_military_snapshot(
			"india"
		)
	)

	if military_snapshot_2.is_empty():

		TestLogger.write_line(
			"Second military snapshot: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		return false

	TestLogger.write_line(
		"Second military snapshot: PASS"
	)


	# ========================================================
	# COMPARE MILITARY POWER
	# ========================================================

	var state_1 = military_snapshot_1.get(
		"state",
		{}
	)

	var state_2 = military_snapshot_2.get(
		"state",
		{}
	)

	var snapshot_power_1 = float(
		state_1.get(
			"military_power",
			0.0
		)
	)

	var snapshot_power_2 = float(
		state_2.get(
			"military_power",
			0.0
		)
	)

	var power_change = (
		snapshot_power_2
		- snapshot_power_1
	)

	TestLogger.write_line(
		"Snapshot military power 1: "
		+ str(snapshot_power_1)
	)

	TestLogger.write_line(
		"Snapshot military power 2: "
		+ str(snapshot_power_2)
	)

	TestLogger.write_line(
		"Detected military power change: "
		+ str(power_change)
	)


	# ========================================================
	# VERIFY CHANGE
	# ========================================================

	var change_detected = (
		not is_zero_approx(power_change)
	)

	if change_detected:

		TestLogger.write_line(
			"Military state change detection: PASS"
		)

	else:

		TestLogger.write_line(
			"Military state change detection: FAIL"
		)

		military.set_state(
			"military_power",
			original_power
		)

		return false


	# ========================================================
	# RESTORE ORIGINAL STATE
	# ========================================================

	military.set_state(
		"military_power",
		original_power
	)

	TestLogger.write_line(
		"Original military state restored."
	)


	TestLogger.section(
		"MILITARY SNAPSHOT TEST PASSED"
	)

	return true
