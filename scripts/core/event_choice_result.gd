class_name EventChoiceResult
extends RefCounted


# ============================================================
# E9 — MINIMUM CHOICE EXECUTION RESULT
# ============================================================

const STATUS_EXECUTED: String = "executed"
const STATUS_BLOCKED: String = "blocked"
const STATUS_REJECTED: String = "rejected"
const STATUS_FAILED: String = "failed"


var choice_id: String = ""
var status: String = STATUS_REJECTED
var eligible: bool = false
var effects_executed: bool = false
var failure_reason: String = ""


func _init(
	result_choice_id: String = ""
) -> void:
	choice_id = result_choice_id


func is_successful() -> bool:
	return status == STATUS_EXECUTED


func is_blocked() -> bool:
	return status == STATUS_BLOCKED


func is_rejected() -> bool:
	return status == STATUS_REJECTED


func is_failed() -> bool:
	return status == STATUS_FAILED


func to_dict() -> Dictionary:
	return {
		"choice_id": choice_id,
		"status": status,
		"eligible": eligible,
		"effects_executed": effects_executed,
		"failure_reason": failure_reason,
	}
