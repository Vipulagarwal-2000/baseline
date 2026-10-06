class_name SimComponent
extends RefCounted


var component_type: String
var owner_id: String = ""


# Current simulation state.
var state: Dictionary = {}


# Historical / starting baseline values.
var baseline_state: Dictionary = {}


# What the component is capable of doing.
var capabilities: Dictionary = {}


# Restrictions or limitations.
var constraints: Dictionary = {}


# Historical changes to this component.
var history: Array = []


func _init(
	type: String,
	owner: String = ""
):
	component_type = type
	owner_id = owner


# ============================================================
# CURRENT STATE
# ============================================================

func set_state(
	key: String,
	value
) -> void:

	state[key] = value


func get_state(
	key: String,
	default_value = null
):
	return state.get(
		key,
		default_value
	)


func has_state(
	key: String
) -> bool:

	return state.has(key)


func remove_state(
	key: String
) -> void:

	state.erase(key)


# ============================================================
# BASELINE STATE
# ============================================================

func set_baseline(
	key: String,
	value
) -> void:

	if key.is_empty():
		return

	baseline_state[key] = value


func get_baseline(
	key: String,
	default_value = null
):
	if key.is_empty():
		return default_value

	return baseline_state.get(
		key,
		default_value
	)


func has_baseline(
	key: String
) -> bool:

	return baseline_state.has(key)


func remove_baseline(
	key: String
) -> void:

	baseline_state.erase(key)


func get_change_from_baseline(
	key: String,
	default_value: float = 0.0
) -> float:

	var current_value = float(
		get_state(
			key,
			default_value
		)
	)

	var baseline_value = float(
		get_baseline(
			key,
			default_value
		)
	)

	return current_value - baseline_value


func get_percentage_change_from_baseline(
	key: String,
	default_value: float = 0.0
) -> float:

	var current_value = float(
		get_state(
			key,
			default_value
		)
	)

	var baseline_value = float(
		get_baseline(
			key,
			default_value
		)
	)

	if is_zero_approx(baseline_value):
		return 0.0

	return (
		(current_value - baseline_value)
		/ baseline_value
	) * 100.0


# ============================================================
# CAPABILITIES
# ============================================================

func set_capability(
	capability_id: String,
	available: bool
) -> void:

	capabilities[capability_id] = available


func has_capability(
	capability_id: String
) -> bool:

	return capabilities.get(
		capability_id,
		false
	)


# ============================================================
# CONSTRAINTS
# ============================================================

func set_constraint(
	constraint_id: String,
	value
) -> void:

	constraints[constraint_id] = value


func get_constraint(
	constraint_id: String,
	default_value = null
):
	return constraints.get(
		constraint_id,
		default_value
	)


# ============================================================
# HISTORY
# ============================================================

func add_history_entry(
	entry
) -> void:

	history.append(
		entry
	)
