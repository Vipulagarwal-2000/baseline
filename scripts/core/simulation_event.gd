class_name SimulationEvent
extends RefCounted


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""
var name: String = ""
var description: String = ""
var event_type: String = "general"


# ============================================================
# STATE
# ============================================================

var state: String = "inactive"
var active: bool = false
var completed: bool = false
var cancelled: bool = false


# ============================================================
# TIMING
# ============================================================

var trigger_year: int = 0
var trigger_month: int = 0
var trigger_day: int = 0
var scheduled: bool = false


# ============================================================
# SIMULATION BEHAVIOR
# ============================================================

var pause_simulation: bool = false
var priority: int = 0
var current_stage: int = 0
var total_stages: int = 1


# ============================================================
# ACTORS
# ============================================================

var actor_ids: Array = []
var target_ids: Array = []


# ============================================================
# CONDITIONS / EFFECTS
# ============================================================

var conditions: Array = []

# "all" = every condition must pass
# "any" = at least one condition must pass
var condition_mode: String = "all"

var effects: Array = []
var decisions: Array = []
var follow_up_events: Array = []


# ============================================================
# METADATA
# ============================================================

var metadata: Dictionary = {}


# ============================================================
# HISTORY
# ============================================================

var history: Array = []


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	event_id: String = "",
	event_name: String = "",
	type: String = "general"
):
	id = event_id
	name = event_name
	event_type = type


# ============================================================
# STATE MANAGEMENT
# ============================================================

func activate() -> void:
	active = true
	completed = false
	cancelled = false
	state = "active"


func complete() -> void:
	active = false
	completed = true
	cancelled = false
	state = "completed"


func cancel() -> void:
	active = false
	completed = false
	cancelled = true
	state = "cancelled"


func set_awaiting_decision() -> void:
	active = true
	completed = false
	cancelled = false
	state = "awaiting_decision"


func set_resolving() -> void:
	active = true
	completed = false
	cancelled = false
	state = "resolving"


func is_active() -> bool:
	return active


func is_completed() -> bool:
	return completed


func is_cancelled() -> bool:
	return cancelled


func is_finished() -> bool:
	return completed or cancelled


# ============================================================
# STAGE MANAGEMENT
# ============================================================

func advance_stage() -> void:
	if current_stage < total_stages - 1:
		current_stage += 1


func set_stage(stage_index: int) -> void:
	if total_stages <= 0:
		total_stages = 1

	current_stage = clamp(
		stage_index,
		0,
		total_stages - 1
	)


func is_final_stage() -> bool:
	return current_stage >= total_stages - 1


# ============================================================
# ACTORS
# ============================================================

func add_actor(actor_id: String) -> void:
	if actor_id.is_empty():
		return

	if not actor_ids.has(actor_id):
		actor_ids.append(actor_id)


func add_target(target_id: String) -> void:
	if target_id.is_empty():
		return

	if not target_ids.has(target_id):
		target_ids.append(target_id)


func has_actor(actor_id: String) -> bool:
	return actor_ids.has(actor_id)


func has_target(target_id: String) -> bool:
	return target_ids.has(target_id)


# ============================================================
# CONDITIONS
# ============================================================

func add_condition(condition) -> void:
	if condition == null:
		return

	conditions.append(condition)


func clear_conditions() -> void:
	conditions.clear()


func get_conditions() -> Array:
	return conditions


func get_condition_count() -> int:
	return conditions.size()


func has_conditions() -> bool:
	return not conditions.is_empty()


# ============================================================
# CONDITION MODE
# ============================================================

func set_condition_mode(mode: String) -> void:
	if mode != "all" and mode != "any":
		return

	condition_mode = mode


func get_condition_mode() -> String:
	return condition_mode


func conditions_require_all() -> bool:
	return condition_mode == "all"


func conditions_require_any() -> bool:
	return condition_mode == "any"


# ============================================================
# SIMPLE CONDITION BUILDER
# ============================================================

func add_minimum_condition(
	target_type: String,
	target_id: String,
	value_key: String,
	minimum_value: float
) -> void:

	var condition = {
		"type": "minimum_value",
		"target_type": target_type,
		"target_id": target_id,
		"value_key": value_key,
		"minimum": minimum_value
	}

	add_condition(condition)


# ============================================================
# EFFECTS
# ============================================================

func add_effect(effect) -> void:
	if effect == null:
		return

	effects.append(effect)


func clear_effects() -> void:
	effects.clear()


# ============================================================
# DECISIONS
# ============================================================

func add_decision(decision) -> void:
	if decision == null:
		return

	decisions.append(decision)


func has_decisions() -> bool:
	return not decisions.is_empty()


func clear_decisions() -> void:
	decisions.clear()


# ============================================================
# FOLLOW-UP EVENTS
# ============================================================

func add_follow_up_event(event_id: String) -> void:
	if event_id.is_empty():
		return

	if not follow_up_events.has(event_id):
		follow_up_events.append(event_id)


# ============================================================
# METADATA
# ============================================================

func set_metadata_value(
	key: String,
	value
) -> void:

	if key.is_empty():
		return

	metadata[key] = value


func get_metadata_value(
	key: String,
	default_value = null
):

	if key.is_empty():
		return default_value

	return metadata.get(
		key,
		default_value
	)


func has_metadata_value(key: String) -> bool:

	if key.is_empty():
		return false

	return metadata.has(key)


func remove_metadata_value(key: String) -> void:

	if key.is_empty():
		return

	metadata.erase(key)


# ============================================================
# HISTORY
# ============================================================

func add_history_entry(
	entry: Dictionary
) -> void:

	if entry.is_empty():
		return

	history.append(
		entry.duplicate(true)
	)


func get_history() -> Array:
	return history


# ============================================================
# DESCRIPTION
# ============================================================

func get_state_description() -> String:

	return "%s | State: %s | Stage: %d/%d" % [
		name,
		state,
		current_stage + 1,
		total_stages
	]
