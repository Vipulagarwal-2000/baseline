class_name MilitaryHistorySystem
extends SimulationSystem


func _init():
	super("military_history_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("MilitaryHistorySystem: World is null.")
		return

	_process_completed_conflicts(world)
	_process_military_events(world)


# ============================================================
# COMPLETED CONFLICTS
# ============================================================

func _process_completed_conflicts(
	world: WorldState
) -> void:

	if typeof(world.completed_conflicts) != TYPE_ARRAY:
		return

	for conflict in world.completed_conflicts:

		if conflict == null:
			continue

		if not conflict is MilitaryConflict:
			continue

		if not conflict.is_completed():
			continue

		_record_conflict_history(
			world,
			conflict
		)


func _record_conflict_history(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	var history_key = (
		"military_history_conflict_"
		+ conflict.id
	)

	if world.has_metadata(history_key):
		return

	var entry = {
		"type": "conflict_resolved",
		"date": {
			"year": world.get_year(),
			"month": world.get_month(),
			"day": world.get_day()
		},
		"conflict_id": conflict.id,
		"attacker_id": conflict.attacker_id,
		"defender_id": conflict.defender_id,
		"outcome": conflict.outcome,
		"termination_reason": conflict.termination_reason,
		"duration_months": conflict.duration_months
	}

	_store_history_entry(
		world,
		entry
	)

	world.set_metadata(
		history_key,
		true
	)


# ============================================================
# MILITARY EVENTS
# ============================================================

func _process_military_events(
	world: WorldState
) -> void:

	if typeof(world.active_events) != TYPE_ARRAY:
		return

	for event in world.active_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.event_type != "military":
			continue

		_record_military_event(
			world,
			event
		)


func _record_military_event(
	world: WorldState,
	event: SimulationEvent
) -> void:

	var history_key = (
		"military_history_event_"
		+ event.id
	)

	if world.has_metadata(history_key):
		return

	var entry = {
		"type": "military_event",
		"date": {
			"year": world.get_year(),
			"month": world.get_month(),
			"day": world.get_day()
		},
		"event_id": event.id,
		"event_type": event.get_metadata_value(
			"military_event_type",
			"general"
		),
		"actors": event.actor_ids.duplicate(),
		"targets": event.target_ids.duplicate(),
		"metadata": event.metadata.duplicate(true)
	}

	_store_history_entry(
		world,
		entry
	)

	world.set_metadata(
		history_key,
		true
	)


# ============================================================
# HISTORY STORAGE
# ============================================================

func _store_history_entry(
	world: WorldState,
	entry: Dictionary
) -> void:

	var history = world.get_metadata(
		"military_history",
		[]
	)

	if typeof(history) != TYPE_ARRAY:
		history = []

	history.append(
		entry.duplicate(true)
	)

	world.set_metadata(
		"military_history",
		history
	)


# ============================================================
# PUBLIC ACCESS
# ============================================================

func get_history(
	world: WorldState
) -> Array:

	if world == null:
		return []

	var history = world.get_metadata(
		"military_history",
		[]
	)

	if typeof(history) != TYPE_ARRAY:
		return []

	return history
