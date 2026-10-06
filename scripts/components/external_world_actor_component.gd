class_name ExternalWorldActorComponent
extends SimComponent


# ============================================================
# STEP 10.2 — EXTERNAL ACTOR REPRESENTATION
# ============================================================
#
# Lightweight persistent state only.
# This component contains only information that can matter to the
# international/external-world layer of the MVP.
#
# It deliberately does not model:
# population, domestic economy, government, industry,
# infrastructure, military, research, technology, or geography.
# ============================================================

const STATE_VERSION: int = 1


func _init(owner: String = "") -> void:
	super._init(
		"external_world_actor",
		owner
	)

	state = {
		"state_version": STATE_VERSION,
		"resource_status": {},
		"strategic_status": {},
		"trade_capacity": {},
		"event_state": {}
	}

	baseline_state = state.duplicate(true)


# ============================================================
# RELEVANT RESOURCE STATUS
# ============================================================

func set_resource_status(
	resource_id: String,
	status
) -> void:
	if resource_id.is_empty():
		return

	var values: Dictionary = get_state(
		"resource_status",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		values = {}

	values[resource_id] = (
		status.duplicate(true)
		if status is Dictionary
		else status
	)

	set_state(
		"resource_status",
		values
	)


func get_resource_status(
	resource_id: String,
	default_value = null
):
	var values: Dictionary = get_state(
		"resource_status",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		return default_value

	return values.get(
		resource_id,
		default_value
	)


# ============================================================
# RELEVANT STRATEGIC STATUS
# ============================================================

func set_strategic_status(
	key: String,
	value
) -> void:
	if key.is_empty():
		return

	var values: Dictionary = get_state(
		"strategic_status",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		values = {}

	values[key] = (
		value.duplicate(true)
		if value is Dictionary
		else value
	)

	set_state(
		"strategic_status",
		values
	)


func get_strategic_status(
	key: String,
	default_value = null
):
	var values: Dictionary = get_state(
		"strategic_status",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		return default_value

	return values.get(
		key,
		default_value
	)


# ============================================================
# RELEVANT TRADE CAPACITY
# ============================================================

func set_trade_capacity(
	resource_id: String,
	monthly_capacity: float
) -> void:
	if resource_id.is_empty():
		return

	var values: Dictionary = get_state(
		"trade_capacity",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		values = {}

	values[resource_id] = maxf(
		0.0,
		monthly_capacity
	)

	set_state(
		"trade_capacity",
		values
	)


func get_trade_capacity(
	resource_id: String,
	default_value: float = 0.0
) -> float:
	var values: Dictionary = get_state(
		"trade_capacity",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		return default_value

	return float(
		values.get(
			resource_id,
			default_value
		)
	)


# ============================================================
# RELEVANT EVENT STATE
# ============================================================

func set_event_state(
	key: String,
	value
) -> void:
	if key.is_empty():
		return

	var values: Dictionary = get_state(
		"event_state",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		values = {}

	values[key] = (
		value.duplicate(true)
		if value is Dictionary
		else value
	)

	set_state(
		"event_state",
		values
	)


func get_event_state(
	key: String,
	default_value = null
):
	var values: Dictionary = get_state(
		"event_state",
		{}
	)

	if typeof(values) != TYPE_DICTIONARY:
		return default_value

	return values.get(
		key,
		default_value
	)


# ============================================================
# SNAPSHOT RESTORE SUPPORT
# ============================================================

func apply_snapshot_state(
	snapshot: Dictionary
) -> bool:
	if snapshot.is_empty():
		return false

	var snapshot_state = snapshot.get(
		"state",
		{}
	)

	if typeof(snapshot_state) != TYPE_DICTIONARY:
		return false

	var restored_state: Dictionary = {
		"state_version": int(
			snapshot_state.get(
				"state_version",
				STATE_VERSION
			)
		),
		"resource_status": snapshot_state.get(
			"resource_status",
			{}
		).duplicate(true),
		"strategic_status": snapshot_state.get(
			"strategic_status",
			{}
		).duplicate(true),
		"trade_capacity": snapshot_state.get(
			"trade_capacity",
			{}
		).duplicate(true),
		"event_state": snapshot_state.get(
			"event_state",
			{}
		).duplicate(true)
	}

	state = restored_state.duplicate(true)
	baseline_state = restored_state.duplicate(true)

	return true
