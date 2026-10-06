class_name EventSynchronizer
extends SimulationSystem


func _init():
	super("event_synchronizer")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("EventSynchronizer: World is null.")
		return

	_process_active_events(world)
	_process_scheduled_events(world)
	_process_completed_events(world)


# ============================================================
# ACTIVE EVENTS
# ============================================================

func _process_active_events(world: WorldState) -> void:
	var active_events = world.active_events

	if typeof(active_events) != TYPE_ARRAY:
		return

	for event in active_events:
		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.is_finished():
			continue

		# Scheduled events must wait for their trigger date.
		if event.scheduled:
			if not _is_event_due(world, event):
				continue

		# Inactive events are trigger candidates.
		if event.state == "inactive":
			if not _conditions_satisfied(world, event):
				continue

		_process_event(world, event)


func _process_event(
	world: WorldState,
	event: SimulationEvent
) -> void:

	if event == null:
		return

	match event.state:

		"inactive":
			event.activate()

			_record_event_history(
				world,
				event,
				"activated"
			)

		"active":
			_process_active_event(world, event)

		"awaiting_decision":
			_process_decision_event(
				world,
				event
			)

		"resolving":
			_resolve_event(
				world,
				event
			)

		_:
			pass


func _process_active_event(
	world: WorldState,
	event: SimulationEvent
) -> void:

	if event.has_decisions():
		event.set_awaiting_decision()

		_record_event_history(
			world,
			event,
			"awaiting_decision"
		)

		return

	event.set_resolving()

	_record_event_history(
		world,
		event,
		"resolving"
	)


func _process_decision_event(
	_world: WorldState,
	event: SimulationEvent
) -> void:

	if event == null:
		return

	# Decision resolution will be handled
	# by the future Decision & Crisis Manager.
	pass


func _resolve_event(
	world: WorldState,
	event: SimulationEvent
) -> void:

	if event == null:
		return

	event.complete()

	_record_event_history(
		world,
		event,
		"completed"
	)

	_move_event_to_completed(
		world,
		event
	)


# ============================================================
# CONDITION EVALUATION
# ============================================================

func _conditions_satisfied(
	world: WorldState,
	event: SimulationEvent
) -> bool:

	if world == null:
		return false

	if event == null:
		return false

	if not event.has_conditions():
		return true

	var conditions = event.get_conditions()

	for condition in conditions:

		if typeof(condition) != TYPE_DICTIONARY:
			return false

		if not _evaluate_condition(
			world,
			condition
		):
			return false

	return true


func _evaluate_condition(
	world: WorldState,
	condition: Dictionary
) -> bool:

	if world == null:
		return false

	if condition.is_empty():
		return false

	var condition_type = str(
		condition.get("type", "")
	)

	match condition_type:

		"minimum_value":
			return _evaluate_minimum_value_condition(
				world,
				condition
			)

		_:
			return false




func evaluate_event_conditions(
	world: WorldState,
	event: SimulationEvent
) -> bool:

	if world == null:
		return false

	if event == null:
		return false

	return _conditions_satisfied(
		world,
		event
	)


func get_condition_results(
	world: WorldState,
	event: SimulationEvent
) -> Array:

	var results: Array = []

	if world == null:
		return results

	if event == null:
		return results

	var conditions = event.get_conditions()

	for condition in conditions:

		if typeof(condition) != TYPE_DICTIONARY:
			results.append({
				"passed": false,
				"reason": "Invalid condition format"
			})
			continue

		var passed = _evaluate_condition(
			world,
			condition
		)

		results.append({
			"passed": passed,
			"condition": condition.duplicate(true)
		})

	return results







func _evaluate_minimum_value_condition(
	world: WorldState,
	condition: Dictionary
) -> bool:

	var target_type = str(
		condition.get(
			"target_type",
			""
		)
	)

	var target_id = str(
		condition.get(
			"target_id",
			""
		)
	)

	var value_key = str(
		condition.get(
			"value_key",
			""
		)
	)

	var minimum_value = float(
		condition.get(
			"minimum",
			0.0
		)
	)

	if target_type.is_empty():
		return false

	if value_key.is_empty():
		return false

	var current_value = _get_condition_value(
		world,
		target_type,
		target_id,
		value_key
	)

	if current_value == null:
		return false

	return float(current_value) >= minimum_value


func _get_condition_value(
	world: WorldState,
	target_type: String,
	target_id: String,
	value_key: String
):

	match target_type:

		"world":
			return world.get_global_variable(
				value_key,
				null
			)

		"country":
			var country = world.get_entity(
				target_id
			)

			if country == null:
				return null

			return _get_entity_condition_value(
				country,
				value_key
			)

		"entity":
			var entity = world.get_entity(
				target_id
			)

			if entity == null:
				return null

			return _get_entity_condition_value(
				entity,
				value_key
			)

		_:
			return null



func explain_condition(
	world: WorldState,
	condition: Dictionary
) -> Dictionary:

	if world == null:
		return {
			"passed": false,
			"reason": "World is null"
		}

	if condition.is_empty():
		return {
			"passed": false,
			"reason": "Condition is empty"
		}

	var condition_type = str(
		condition.get("type", "")
	)

	if condition_type != "minimum_value":
		return {
			"passed": false,
			"reason": "Unsupported condition type",
			"type": condition_type
		}

	var target_type = str(
		condition.get("target_type", "")
	)

	var target_id = str(
		condition.get("target_id", "")
	)

	var value_key = str(
		condition.get("value_key", "")
	)

	var minimum_value = float(
		condition.get("minimum", 0.0)
	)

	var current_value = _get_condition_value(
		world,
		target_type,
		target_id,
		value_key
	)

	if current_value == null:
		return {
			"passed": false,
			"reason": "Target value not found",
			"type": condition_type,
			"target_type": target_type,
			"target_id": target_id,
			"value_key": value_key,
			"required": minimum_value
		}

	var actual_value = float(current_value)

	return {
		"passed": actual_value >= minimum_value,
		"type": condition_type,
		"target_type": target_type,
		"target_id": target_id,
		"value_key": value_key,
		"actual": actual_value,
		"required": minimum_value
	}

func _get_entity_condition_value(
	entity,
	value_key: String
):

	# Component state lookup.
	for component in entity.components.values():

		if component == null:
			continue

		if component.has_state(value_key):
			return component.get_state(
				value_key,
				null
			)

	# Simulation metadata lookup.
	var metadata_value = entity.get_sim_metadata(
		value_key,
		null
	)

	if metadata_value != null:
		return metadata_value

	return null


# ============================================================
# SCHEDULED EVENTS
# ============================================================

func _process_scheduled_events(
	world: WorldState
) -> void:

	var active_events = world.active_events

	if typeof(active_events) != TYPE_ARRAY:
		return

	for event in active_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if not event.scheduled:
			continue

		if event.is_finished():
			continue

		if not _is_event_due(
			world,
			event
		):
			continue

		if event.state != "inactive":
			continue

		if not _conditions_satisfied(
			world,
			event
		):
			continue

		event.activate()

		_record_event_history(
			world,
			event,
			"scheduled_trigger"
		)


func _is_event_due(
	world: WorldState,
	event: SimulationEvent
) -> bool:

	if world == null:
		return false

	if event == null:
		return false

	if not event.scheduled:
		return false

	if event.trigger_year <= 0:
		return false

	var current_year = world.get_year()
	var current_month = world.get_month()
	var current_day = world.get_day()

	if current_year > event.trigger_year:
		return true

	if current_year < event.trigger_year:
		return false

	if event.trigger_month > 0:

		if current_month > event.trigger_month:
			return true

		if current_month < event.trigger_month:
			return false

	if event.trigger_day > 0:
		return current_day >= event.trigger_day

	return true


# ============================================================
# COMPLETED EVENTS
# ============================================================

func _process_completed_events(
	world: WorldState
) -> void:

	var active_events = world.active_events

	if typeof(active_events) != TYPE_ARRAY:
		return

	var events_to_move: Array = []

	for event in active_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.is_finished():
			events_to_move.append(event)

	for event in events_to_move:

		_move_event_to_completed(
			world,
			event
		)


func _move_event_to_completed(
	world: WorldState,
	event: SimulationEvent
) -> void:

	if world == null:
		return

	if event == null:
		return

	if world.active_events.has(event):
		world.active_events.erase(event)

	if not world.completed_events.has(event):
		world.completed_events.append(event)


# ============================================================
# EVENT MANAGEMENT
# ============================================================

func add_event(
	world: WorldState,
	event: SimulationEvent
) -> bool:

	if world == null:
		return false

	if event == null:
		return false

	if event.id.is_empty():
		return false

	for existing_event in world.active_events:

		if existing_event == null:
			continue

		if not existing_event is SimulationEvent:
			continue

		if existing_event.id == event.id:
			return false

	for existing_event in world.completed_events:

		if existing_event == null:
			continue

		if not existing_event is SimulationEvent:
			continue

		if existing_event.id == event.id:
			return false

	world.active_events.append(event)

	return true


func remove_event(
	world: WorldState,
	event_id: String
) -> bool:

	if world == null:
		return false

	for index in range(
		world.active_events.size()
	):

		var event = world.active_events[index]

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.id == event_id:
			world.active_events.remove_at(index)
			return true

	return false


func get_event(
	world: WorldState,
	event_id: String
):

	if world == null:
		return null

	for event in world.active_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.id == event_id:
			return event

	for event in world.completed_events:

		if event == null:
			continue

		if not event is SimulationEvent:
			continue

		if event.id == event_id:
			return event

	return null


func get_active_events(
	world: WorldState
) -> Array:

	if world == null:
		return []

	return world.active_events


func get_completed_events(
	world: WorldState
) -> Array:

	if world == null:
		return []

	return world.completed_events


# ============================================================
# HISTORY
# ============================================================

func _record_event_history(
	world: WorldState,
	event: SimulationEvent,
	action: String
) -> void:

	if world == null:
		return

	if event == null:
		return

	var entry = {
		"type": "event_state_change",
		"event_id": event.id,
		"event_name": event.name,
		"action": action,
		"state": event.state,
		"year": world.get_year(),
		"month": world.get_month(),
		"day": world.get_day(),
		"stage": event.current_stage
	}

	event.add_history_entry(entry)
