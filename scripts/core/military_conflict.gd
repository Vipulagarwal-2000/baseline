class_name MilitaryConflict
extends RefCounted


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""

var attacker_id: String = ""
var defender_id: String = ""


# ============================================================
# STATE
# ============================================================

var state: String = "active"

var active: bool = false
var completed: bool = false
var cancelled: bool = false


# ============================================================
# TIMING
# ============================================================

var start_year: int = 0
var start_month: int = 0
var start_day: int = 0

var end_year: int = 0
var end_month: int = 0
var end_day: int = 0

var duration_months: int = 0


# ============================================================
# CONFLICT PRESSURE
# ============================================================

var attacker_pressure: float = 0.0
var defender_pressure: float = 0.0

var intensity: float = 0.50


# ============================================================
# OUTCOME
# ============================================================

var outcome: String = ""

var termination_reason: String = ""


# ============================================================
# HISTORY
# ============================================================

var history: Array = []


# ============================================================
# METADATA
# ============================================================

var metadata: Dictionary = {}


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	conflict_id: String = "",
	attacker: String = "",
	defender: String = ""
):
	id = conflict_id
	attacker_id = attacker
	defender_id = defender


# ============================================================
# STATE MANAGEMENT
# ============================================================

func activate() -> void:
	active = true
	completed = false
	cancelled = false
	state = "active"


func complete(
	result: String = "",
	reason: String = ""
) -> void:
	active = false
	completed = true
	cancelled = false
	state = "completed"

	outcome = result
	termination_reason = reason


func cancel(
	reason: String = ""
) -> void:
	active = false
	completed = false
	cancelled = true
	state = "cancelled"

	termination_reason = reason


func is_active() -> bool:
	return active


func is_completed() -> bool:
	return completed


func is_cancelled() -> bool:
	return cancelled


func is_finished() -> bool:
	return completed or cancelled


# ============================================================
# TIMING
# ============================================================

func set_start_date(
	year: int,
	month: int,
	day: int = 1
) -> void:
	start_year = year
	start_month = month
	start_day = day


func set_end_date(
	year: int,
	month: int,
	day: int = 1
) -> void:
	end_year = year
	end_month = month
	end_day = day


func increment_duration() -> void:
	duration_months += 1


# ============================================================
# PRESSURE
# ============================================================

func set_attacker_pressure(value: float) -> void:
	attacker_pressure = clamp(
		value,
		0.0,
		1.0
	)


func set_defender_pressure(value: float) -> void:
	defender_pressure = clamp(
		value,
		0.0,
		1.0
	)


func set_intensity(value: float) -> void:
	intensity = clamp(
		value,
		0.0,
		1.0
	)


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


func has_metadata_value(
	key: String
) -> bool:
	if key.is_empty():
		return false

	return metadata.has(key)


func remove_metadata_value(
	key: String
) -> void:
	if key.is_empty():
		return

	metadata.erase(key)
