class_name ExternalEventImpactComponent
extends SimComponent


# ============================================================
# STEP 10.3 — EXTERNAL EVENT CAUSALITY
# CORE-COUNTRY IMPACT LEDGER
# ============================================================
#
# This component records material consequences caused by external
# actors without modifying or duplicating the authoritative country
# components.
#
# It is intentionally a derived consequence layer for Step 10.3.
# Later steps may consume these impacts to drive existing resource,
# trade, production, economic, population, or government systems.
# ============================================================

const STATE_VERSION: int = 1


func _init(owner: String = "") -> void:
	super._init(
		"external_event_impact",
		owner
	)

	state = {
		"state_version": STATE_VERSION,
		"active_impacts": {},
		"resolved_impacts": {},
		"applied_event_ids": [],
		"resource_impacts": {},
		"trade_impacts": {},
		"strategic_impacts": {},
		"event_ledger": []
	}

	baseline_state = state.duplicate(true)


# ============================================================
# IDEMPOTENCE
# ============================================================

func is_event_applied(event_id: String) -> bool:
	if event_id.is_empty():
		return false

	var applied: Array = get_state(
		"applied_event_ids",
		[]
	)

	if typeof(applied) != TYPE_ARRAY:
		return false

	return applied.has(event_id)


# ============================================================
# EXTERNAL EVENT RECORDING
# ============================================================

func record_external_event(
	event_id: String,
	actor_id: String,
	event_name: String,
	impact: Dictionary
) -> bool:
	if event_id.is_empty():
		return false

	if actor_id.is_empty():
		return false

	if is_event_applied(event_id):
		return false

	var applied: Array = get_state(
		"applied_event_ids",
		[]
	)

	if typeof(applied) != TYPE_ARRAY:
		applied = []

	applied.append(event_id)
	set_state(
		"applied_event_ids",
		applied
	)

	var ledger: Array = get_state(
		"event_ledger",
		[]
	)

	if typeof(ledger) != TYPE_ARRAY:
		ledger = []

	ledger.append({
		"event_id": event_id,
		"actor_id": actor_id,
		"event_name": event_name,
		"impact": impact.duplicate(true)
	})

	set_state(
		"event_ledger",
		ledger
	)

	_apply_resource_impact(
		impact.get("resource", {}),
		event_id,
		actor_id
	)

	_apply_trade_impact(
		impact.get("trade", {}),
		event_id,
		actor_id
	)

	_apply_strategic_impact(
		impact.get("strategic", {}),
		event_id,
		actor_id
	)

	var active_impacts: Dictionary = get_state(
		"active_impacts",
		{}
	)

	if typeof(active_impacts) != TYPE_DICTIONARY:
		active_impacts = {}

	active_impacts[event_id] = {
		"actor_id": actor_id,
		"event_name": event_name,
		"impact": impact.duplicate(true)
	}

	set_state(
		"active_impacts",
		active_impacts
	)

	return true


func resolve_external_event(
	event_id: String
) -> bool:
	if event_id.is_empty():
		return false

	var active_impacts: Dictionary = get_state(
		"active_impacts",
		{}
	)

	if typeof(active_impacts) != TYPE_DICTIONARY:
		return false

	if not active_impacts.has(event_id):
		return false

	var resolved_impacts: Dictionary = get_state(
		"resolved_impacts",
		{}
	)

	if typeof(resolved_impacts) != TYPE_DICTIONARY:
		resolved_impacts = {}

	resolved_impacts[event_id] = active_impacts[event_id].duplicate(true)
	active_impacts.erase(event_id)

	set_state(
		"resolved_impacts",
		resolved_impacts
	)

	set_state(
		"active_impacts",
		active_impacts
	)

	return true


func get_event_ledger() -> Array:
	var ledger = get_state(
		"event_ledger",
		[]
	)

	if typeof(ledger) != TYPE_ARRAY:
		return []

	return ledger.duplicate(true)


# ============================================================
# RESOURCE IMPACT
# ============================================================

func _apply_resource_impact(
	resource_impact_value,
	event_id: String,
	actor_id: String
) -> void:
	if typeof(resource_impact_value) != TYPE_DICTIONARY:
		return

	var resource_impact: Dictionary = resource_impact_value
	var resource_id: String = str(
		resource_impact.get("resource_id", "")
	)

	if resource_id.is_empty():
		return

	var blocked_quantity: float = maxf(
		0.0,
		float(
			resource_impact.get(
				"blocked_quantity",
				0.0
			)
		)
	)

	var severity: float = clampf(
		float(
			resource_impact.get(
				"severity",
				0.0
			)
		),
		0.0,
		1.0
	)

	var resource_impacts: Dictionary = get_state(
		"resource_impacts",
		{}
	)

	if typeof(resource_impacts) != TYPE_DICTIONARY:
		resource_impacts = {}

	var current: Dictionary = resource_impacts.get(
		resource_id,
		{
			"blocked_quantity": 0.0,
			"severity": 0.0,
			"sources": []
		}
	)

	if typeof(current) != TYPE_DICTIONARY:
		current = {
			"blocked_quantity": 0.0,
			"severity": 0.0,
			"sources": []
		}

	var sources: Array = current.get(
		"sources",
		[]
	)

	if typeof(sources) != TYPE_ARRAY:
		sources = []

	sources.append({
		"event_id": event_id,
		"actor_id": actor_id,
		"blocked_quantity": blocked_quantity
	})

	current["blocked_quantity"] = (
		float(current.get("blocked_quantity", 0.0))
		+ blocked_quantity
	)

	current["severity"] = maxf(
		float(current.get("severity", 0.0)),
		severity
	)

	current["sources"] = sources
	resource_impacts[resource_id] = current

	set_state(
		"resource_impacts",
		resource_impacts
	)


func get_resource_impact(
	resource_id: String,
	default_value: Dictionary = {}
) -> Dictionary:
	var resource_impacts: Dictionary = get_state(
		"resource_impacts",
		{}
	)

	if typeof(resource_impacts) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	var value = resource_impacts.get(
		resource_id,
		default_value
	)

	if typeof(value) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	return value.duplicate(true)


# ============================================================
# TRADE IMPACT
# ============================================================

func _apply_trade_impact(
	trade_impact_value,
	event_id: String,
	actor_id: String
) -> void:
	if typeof(trade_impact_value) != TYPE_DICTIONARY:
		return

	var trade_impact: Dictionary = trade_impact_value
	var resource_id: String = str(
		trade_impact.get("resource_id", "")
	)

	if resource_id.is_empty():
		return

	var capacity_reduction: float = maxf(
		0.0,
		float(
			trade_impact.get(
				"capacity_reduction",
				0.0
			)
		)
	)

	var trade_impacts: Dictionary = get_state(
		"trade_impacts",
		{}
	)

	if typeof(trade_impacts) != TYPE_DICTIONARY:
		trade_impacts = {}

	var current: Dictionary = trade_impacts.get(
		resource_id,
		{
			"capacity_reduction": 0.0,
			"sources": []
		}
	)

	if typeof(current) != TYPE_DICTIONARY:
		current = {
			"capacity_reduction": 0.0,
			"sources": []
		}

	var sources: Array = current.get(
		"sources",
		[]
	)

	if typeof(sources) != TYPE_ARRAY:
		sources = []

	sources.append({
		"event_id": event_id,
		"actor_id": actor_id,
		"capacity_reduction": capacity_reduction
	})

	current["capacity_reduction"] = (
		float(current.get("capacity_reduction", 0.0))
		+ capacity_reduction
	)
	current["sources"] = sources

	trade_impacts[resource_id] = current

	set_state(
		"trade_impacts",
		trade_impacts
	)


func get_trade_impact(
	resource_id: String,
	default_value: Dictionary = {}
) -> Dictionary:
	var trade_impacts: Dictionary = get_state(
		"trade_impacts",
		{}
	)

	if typeof(trade_impacts) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	var value = trade_impacts.get(
		resource_id,
		default_value
	)

	if typeof(value) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	return value.duplicate(true)


# ============================================================
# STRATEGIC IMPACT
# ============================================================

func _apply_strategic_impact(
	strategic_impact_value,
	event_id: String,
	actor_id: String
) -> void:
	if typeof(strategic_impact_value) != TYPE_DICTIONARY:
		return

	var strategic_impact: Dictionary = strategic_impact_value
	var key: String = str(
		strategic_impact.get("key", "")
	)

	if key.is_empty():
		return

	var value: float = float(
		strategic_impact.get(
			"value",
			0.0
		)
	)

	var strategic_impacts: Dictionary = get_state(
		"strategic_impacts",
		{}
	)

	if typeof(strategic_impacts) != TYPE_DICTIONARY:
		strategic_impacts = {}

	var current: Dictionary = strategic_impacts.get(
		key,
		{
			"value": 0.0,
			"sources": []
		}
	)

	if typeof(current) != TYPE_DICTIONARY:
		current = {
			"value": 0.0,
			"sources": []
		}

	var sources: Array = current.get(
		"sources",
		[]
	)

	if typeof(sources) != TYPE_ARRAY:
		sources = []

	sources.append({
		"event_id": event_id,
		"actor_id": actor_id,
		"value": value
	})

	current["value"] = float(
		current.get("value", 0.0)
	) + value
	current["sources"] = sources

	strategic_impacts[key] = current

	set_state(
		"strategic_impacts",
		strategic_impacts
	)


func get_strategic_impact(
	key: String,
	default_value: Dictionary = {}
) -> Dictionary:
	var strategic_impacts: Dictionary = get_state(
		"strategic_impacts",
		{}
	)

	if typeof(strategic_impacts) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	var value = strategic_impacts.get(
		key,
		default_value
	)

	if typeof(value) != TYPE_DICTIONARY:
		return default_value.duplicate(true)

	return value.duplicate(true)


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
		"active_impacts": snapshot_state.get(
			"active_impacts",
			{}
		).duplicate(true),
		"resolved_impacts": snapshot_state.get(
			"resolved_impacts",
			{}
		).duplicate(true),
		"applied_event_ids": snapshot_state.get(
			"applied_event_ids",
			[]
		).duplicate(true),
		"resource_impacts": snapshot_state.get(
			"resource_impacts",
			{}
		).duplicate(true),
		"trade_impacts": snapshot_state.get(
			"trade_impacts",
			{}
		).duplicate(true),
		"strategic_impacts": snapshot_state.get(
			"strategic_impacts",
			{}
		).duplicate(true),
		"event_ledger": snapshot_state.get(
			"event_ledger",
			[]
		).duplicate(true)
	}

	state = restored_state.duplicate(true)
	baseline_state = restored_state.duplicate(true)

	return true
