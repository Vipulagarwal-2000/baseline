class_name EventChoiceExecutor
extends RefCounted


# ============================================================
# E9 — CHOICE EXECUTION
# ============================================================
#
# Bounded branch execution:
#
# Event
#   ↓
# selected choice
#   ↓
# choice conditions
#   ↓
# choice effects
#
# Only the explicitly selected choice is considered for execution.
# Unselected branches are not evaluated and cannot mutate state.
#
# E9 reuses:
# - E5 EventTriggerEvaluator for condition evaluation
# - E7 EventEffectExecutor for authoritative state mutation
#
# E9 does not implement:
# - random selection
# - cooldowns
# - history persistence
# - monthly scheduling
# ============================================================


static func execute_selected_choice(
	event_definition: EventDefinition,
	choices: Array,
	selected_choice_id: String,
	world: WorldState,
	target_id: String
) -> EventChoiceResult:

	var normalized_choice_id: String = selected_choice_id.strip_edges()
	var result: EventChoiceResult = EventChoiceResult.new(
		normalized_choice_id
	)

	if event_definition == null:
		result.failure_reason = "missing_event_definition"
		return result

	if world == null:
		result.failure_reason = "missing_world"
		return result

	if target_id.strip_edges().is_empty():
		result.failure_reason = "missing_target"
		return result

	if normalized_choice_id.is_empty():
		result.failure_reason = "missing_selected_choice"
		return result

	var selected_choice: EventChoice = _find_choice(
		choices,
		normalized_choice_id
	)

	if selected_choice == null:
		result.failure_reason = "selected_choice_not_found"
		return result

	if not selected_choice.is_valid():
		result.failure_reason = "invalid_selected_choice"
		return result

	# Only the selected choice reaches this condition gate.
	var eligible: bool = EventTriggerEvaluator.evaluate_conditions(
		event_definition,
		selected_choice.conditions,
		world,
		target_id
	)

	result.eligible = eligible

	if not eligible:
		result.status = EventChoiceResult.STATUS_BLOCKED
		result.effects_executed = false
		result.failure_reason = "choice_conditions_not_met"
		return result

	var effects_applied: bool = EventEffectExecutor.execute_effects(
		selected_choice.effects,
		world,
		target_id
	)

	if not effects_applied:
		result.status = EventChoiceResult.STATUS_FAILED
		result.effects_executed = false
		result.failure_reason = "choice_effect_execution_failed"
		return result

	result.status = EventChoiceResult.STATUS_EXECUTED
	result.effects_executed = true
	result.failure_reason = ""

	return result


static func _find_choice(
	choices: Array,
	selected_choice_id: String
) -> EventChoice:
	for choice_value in choices:
		if choice_value == null:
			continue

		if not (choice_value is EventChoice):
			continue

		var choice: EventChoice = choice_value

		if choice.id == selected_choice_id:
			return choice

	return null
