class_name EventExecutor
extends RefCounted


# ============================================================
# E8 — EVENT EXECUTION
# ============================================================
#
# Complete bounded E8 flow:
#
# EventDefinition
#       ↓
# condition evaluation
#       ↓
# eligible?
#   NO  → blocked EventResult
#   YES → effect execution
#       ↓
# executed EventResult
#
# E8 deliberately does NOT own:
# - choices
# - randomness
# - cooldowns
# - history persistence
# - monthly simulation scheduling
#
# E7 remains the sole generic effect executor.
# E12 will extend EventResult/history behavior.
# ============================================================


static func execute(
	event_definition: EventDefinition,
	conditions: Array,
	effects: Array,
	world: WorldState,
	target_id: String
) -> EventResult:

	var result: EventResult = EventResult.new(
		_get_event_id(event_definition),
		target_id
	)

	if event_definition == null:
		result.status = EventResult.STATUS_REJECTED
		result.failure_reason = "missing_event_definition"
		return result

	if not _is_valid_event_definition(event_definition):
		result.status = EventResult.STATUS_REJECTED
		result.failure_reason = "invalid_event_definition"
		return result

	if world == null:
		result.status = EventResult.STATUS_REJECTED
		result.failure_reason = "missing_world"
		return result

	if target_id.strip_edges().is_empty():
		result.status = EventResult.STATUS_REJECTED
		result.failure_reason = "missing_target"
		return result

	# ------------------------------------------------------------
	# CONDITION EVALUATION
	# ------------------------------------------------------------

	var eligible: bool = EventTriggerEvaluator.evaluate_conditions(
		event_definition,
		conditions,
		world,
		target_id
	)

	result.eligible = eligible

	if not eligible:
		result.status = EventResult.STATUS_BLOCKED
		result.effects_executed = false
		result.failure_reason = "conditions_not_met"
		return result

	# ------------------------------------------------------------
	# EFFECT EXECUTION
	# ------------------------------------------------------------

	var effects_applied: bool = EventEffectExecutor.execute_effects(
		effects,
		world,
		target_id
	)

	if not effects_applied:
		result.status = EventResult.STATUS_FAILED
		result.effects_executed = false
		result.failure_reason = "effect_execution_failed"
		return result

	result.status = EventResult.STATUS_EXECUTED
	result.effects_executed = true
	result.failure_reason = ""

	return result


static func _is_valid_event_definition(
	event_definition: EventDefinition
) -> bool:
	if event_definition == null:
		return false

	return not event_definition.id.strip_edges().is_empty()


static func _get_event_id(
	event_definition: EventDefinition
) -> String:
	if event_definition == null:
		return ""
	return str(event_definition.id).strip_edges()
