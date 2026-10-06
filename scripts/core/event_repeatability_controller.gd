class_name EventRepeatabilityController
extends RefCounted


# ============================================================
# E11 — REPEATABILITY / COOLDOWN GATE
# ============================================================
#
# This layer answers:
#
#   "May this event/target key fire at this tick?"
#
# It does NOT:
# - execute the event
# - evaluate conditions
# - apply effects
# - write HistorySystem
# - advance simulation time
# - own EventDefinition data
#
# State is keyed by event id + target id so separate targets have
# independent repeatability histories.
# ============================================================


var _last_fired_tick: Dictionary = {}


# ============================================================
# FIRE ELIGIBILITY
# ============================================================

func can_fire(
	policy: EventRepeatabilityPolicy,
	event_id: String,
	target_id: String,
	current_tick: int
) -> bool:

	if policy == null:
		return false

	if not policy.is_valid():
		return false

	var key: String = _make_key(
		event_id,
		target_id
	)

	if key.is_empty():
		return false

	if policy.mode == EventRepeatabilityPolicy.MODE_REPEATABLE:
		return true

	if not _last_fired_tick.has(key):
		return true

	var last_tick: int = int(
		_last_fired_tick.get(key)
	)

	var elapsed_ticks: int = current_tick - last_tick

	if elapsed_ticks < 0:
		return false

	match policy.mode:
		EventRepeatabilityPolicy.MODE_ONE_TIME:
			return false

		EventRepeatabilityPolicy.MODE_COOLDOWN:
			return elapsed_ticks > policy.cooldown_ticks

		EventRepeatabilityPolicy.MODE_MINIMUM_INTERVAL:
			return elapsed_ticks >= (
				policy.minimum_interval_ticks
			)

	return false


# ============================================================
# RECORD SUCCESSFUL FIRE
# ============================================================

func record_fire(
	policy: EventRepeatabilityPolicy,
	event_id: String,
	target_id: String,
	current_tick: int
) -> bool:

	if policy == null:
		return false

	if not policy.is_valid():
		return false

	if not can_fire(
		policy,
		event_id,
		target_id,
		current_tick
	):
		return false

	var key: String = _make_key(
		event_id,
		target_id
	)

	_last_fired_tick[key] = current_tick
	return true


# ============================================================
# STATE ACCESS
# ============================================================

func has_fired(
	event_id: String,
	target_id: String
) -> bool:

	var key: String = _make_key(
		event_id,
		target_id
	)

	if key.is_empty():
		return false

	return _last_fired_tick.has(key)


func get_last_fired_tick(
	event_id: String,
	target_id: String
) -> int:

	var key: String = _make_key(
		event_id,
		target_id
	)

	if key.is_empty():
		return -1

	if not _last_fired_tick.has(key):
		return -1

	return int(
		_last_fired_tick.get(key)
	)


func clear(
	event_id: String,
	target_id: String
) -> void:

	var key: String = _make_key(
		event_id,
		target_id
	)

	if key.is_empty():
		return

	_last_fired_tick.erase(key)


func clear_all() -> void:
	_last_fired_tick.clear()


func snapshot_state() -> Dictionary:
	return _last_fired_tick.duplicate(true)


func restore_state(
	state: Dictionary
) -> void:
	_last_fired_tick = state.duplicate(true)


# ============================================================
# KEY
# ============================================================

static func _make_key(
	event_id: String,
	target_id: String
) -> String:

	var normalized_event_id: String = (
		event_id.strip_edges()
	)

	var normalized_target_id: String = (
		target_id.strip_edges()
	)

	if normalized_event_id.is_empty():
		return ""

	if normalized_target_id.is_empty():
		return normalized_event_id

	return (
		normalized_event_id
		+ "|"
		+ normalized_target_id
	)
