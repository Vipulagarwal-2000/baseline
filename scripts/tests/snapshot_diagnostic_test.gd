class_name SnapshotDiagnosticTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> void:

	_out([""])
	_out(["================================"])
	_out(["SNAPSHOT DIAGNOSTIC TEST"])
	_out(["================================"])

	if world == null:
		_out(["ERROR: World is null."])
		return

	if simulation == null:
		_out(["ERROR: SimulationEngine is null."])
		return

	var snapshot_manager = simulation.snapshot_manager

	if snapshot_manager == null:
		_out(["ERROR: SnapshotManager is null."])
		return


	# ============================================================
	# BASELINE
	# ============================================================

	var baseline = (
		snapshot_manager.get_baseline_snapshot()
	)

	if baseline == null:
		_out(["ERROR: Baseline snapshot is null."])
	else:
		_out([
			"Baseline entity_count: ",
			baseline.entity_count
		])

		_out([
			"Baseline entities.size(): ",
			baseline.entities.size()
		])

		_out([
			"Baseline entity IDs: ",
			baseline.entities.keys()
		])


	# ============================================================
	# LATEST
	# ============================================================

	var latest = (
		snapshot_manager.get_latest_snapshot()
	)

	if latest == null:
		_out(["ERROR: Latest snapshot is null."])
	else:
		_out([
			"Latest entity_count: ",
			latest.entity_count
		])

		_out([
			"Latest entities.size(): ",
			latest.entities.size()
		])

		_out([
			"Latest entity IDs: ",
			latest.entities.keys()
		])


	# ============================================================
	# WORLD
	# ============================================================

	_out([
		"World entity count: ",
		world.entities.size()
	])

	_out([
		"World entity IDs: ",
		world.entities.keys()
	])


	# ============================================================
	# MATCHING
	# ============================================================

	if baseline != null and latest != null:

		var matching_count := 0

		for entity_id in latest.entities.keys():

			if baseline.entities.has(entity_id):

				matching_count += 1

				_out([
					"Matching entity: ",
					entity_id
				])

		_out([
			"Matching entities: ",
			matching_count
		])


	# ============================================================
	# RESULT
	# ============================================================

	var passed: bool = (
		baseline != null
		and latest != null
		and baseline.entities.size() > 0
		and latest.entities.size() > 0
	)

	_out([""])
	_out(["================================"])
	_out(["SNAPSHOT DIAGNOSTIC RESULT"])
	_out(["================================"])

	_out([
		"Snapshot data available: ",
		passed
	])

	if passed:
		_out([
			"Snapshot diagnostic: PASS"
		])
	else:
		_out([
			"Snapshot diagnostic: FAILED"
		])

	_out([
		"Snapshot diagnostic test complete."
	])
