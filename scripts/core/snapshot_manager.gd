class_name SnapshotManager
extends RefCounted


# ============================================================
# SNAPSHOTS
# ============================================================

var snapshots: Array = []

var baseline_snapshot: WorldSnapshot = null


# Maximum number of normal snapshots retained.
var maximum_snapshots: int = 120


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	max_snapshots: int = 120
):

	maximum_snapshots = max(
		1,
		max_snapshots
	)


# ============================================================
# CAPTURE WORLD
# ============================================================

func capture_world(
	world: WorldState
) -> WorldSnapshot:

	if world == null:

		push_error(
			"SnapshotManager: World is null."
		)

		return null


	var snapshot = WorldSnapshot.new()

	snapshot.capture(
		world
	)

	snapshots.append(
		snapshot
	)


	_trim_snapshots()


	return snapshot


# ============================================================
# CAPTURE BASELINE
# ============================================================

func capture_baseline(
	world: WorldState
) -> WorldSnapshot:

	if world == null:

		push_error(
			"SnapshotManager: World is null."
		)

		return null


	# --------------------------------------------------------
	# Prevent accidental duplicate baseline
	# --------------------------------------------------------

	if baseline_snapshot != null:

		push_error(
			"SnapshotManager: Baseline already exists."
		)

		return baseline_snapshot


	var snapshot = WorldSnapshot.new()

	snapshot.capture(
		world
	)


	baseline_snapshot = snapshot

	snapshots.append(
		snapshot
	)


	return baseline_snapshot


# ============================================================
# GET BASELINE
# ============================================================

func get_baseline_snapshot():

	return baseline_snapshot


# ============================================================
# GET LATEST SNAPSHOT
# ============================================================

func get_latest_snapshot():

	if snapshots.is_empty():

		return null


	return snapshots[
		snapshots.size() - 1
	]


# ============================================================
# GET SNAPSHOT BY INDEX
# ============================================================

func get_snapshot(
	index: int
):

	if index < 0:

		return null


	if index >= snapshots.size():

		return null


	return snapshots[
		index
	]


# ============================================================
# SNAPSHOT COUNT
# ============================================================

func get_snapshot_count() -> int:

	return snapshots.size()


# ============================================================
# RETENTION
# ============================================================

func _trim_snapshots() -> void:

	# Nothing to trim.
	if snapshots.size() <= maximum_snapshots + 1:

		return


	while snapshots.size() > maximum_snapshots + 1:

		# Never remove the baseline.
		if snapshots[0] == baseline_snapshot:

			if snapshots.size() <= 1:

				break

			snapshots.remove_at(1)

		else:

			snapshots.remove_at(0)


# ============================================================
# CLEAR
# ============================================================

func clear_snapshots() -> void:

	snapshots.clear()

	baseline_snapshot = null
