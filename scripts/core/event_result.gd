class_name EventResult
extends RefCounted


# ============================================================
# E12 — EVENT RESULT / HISTORY CONTRACT
# ============================================================
#
# EventResult remains the result object produced by E8/E9.
#
# E12 enriches it so a history layer can consume the result
# without becoming responsible for event execution logic.
#
# Existing E8 fields are preserved:
# - event_id
# - target_id
# - status
# - eligible
# - effects_executed
# - failure_reason
#
# E12 additions:
# - applied_effects
# - selected_choice_id
# - tick
# - date
# - source
#
# HistorySystem integration is deliberately performed through the
# EventHistoryBridge contract rather than by embedding HistorySystem
# logic into EventResult.
# ============================================================


const STATUS_EXECUTED: String = "executed"
const STATUS_BLOCKED: String = "blocked"
const STATUS_REJECTED: String = "rejected"
const STATUS_FAILED: String = "failed"


var event_id: String = ""
var target_id: String = ""
var status: String = STATUS_REJECTED
var eligible: bool = false
var effects_executed: bool = false
var failure_reason: String = ""


# E12 history-oriented fields.
var applied_effects: Array = []
var selected_choice_id: String = ""
var tick: int = -1
var date: String = ""
var source: String = "event_framework"


func _init(
	result_event_id: String = "",
	result_target_id: String = ""
) -> void:
	event_id = result_event_id
	target_id = result_target_id


func is_successful() -> bool:
	return status == STATUS_EXECUTED


func is_blocked() -> bool:
	return status == STATUS_BLOCKED


func is_rejected() -> bool:
	return status == STATUS_REJECTED


func is_failed() -> bool:
	return status == STATUS_FAILED


func set_applied_effects(
	effects: Array
) -> void:
	applied_effects = effects.duplicate(true)


func set_selected_choice(
	choice_id: String
) -> void:
	selected_choice_id = choice_id.strip_edges()


func set_context(
	result_tick: int,
	result_date: String,
	result_source: String = "event_framework"
) -> void:
	tick = result_tick
	date = result_date
	source = result_source


# ============================================================
# HISTORY PAYLOAD
# ============================================================

func to_history_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"status": status,
		"target": target_id,
		"eligible": eligible,
		"effects_executed": effects_executed,
		"effects": applied_effects.duplicate(true),
		"choice": selected_choice_id,
		"date": date,
		"tick": tick,
		"source": source,
		"failure_reason": failure_reason,
	}


func to_dict() -> Dictionary:
	return to_history_dict()
