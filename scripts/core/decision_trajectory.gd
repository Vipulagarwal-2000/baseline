class_name DecisionTrajectory
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""

var actor_id: String = ""
var target_id: String = ""

var situation_type: String = ""

var value: float = 0.5
var minimum_value: float = 0.0
var maximum_value: float = 1.0

var player_contribution: float = 0.0
var ai_contribution: float = 0.0
var environmental_contribution: float = 0.0
var external_actor_contribution: float = 0.0
var uncertainty: float = 0.0

var history: Array = []
var active: bool = true
var resolved: bool = false


func _init(
	trajectory_id: String = "",
	trajectory_name: String = "",
	type: String = ""
):
	id = trajectory_id
	name = trajectory_name
	situation_type = type


func set_value(new_value: float) -> void:
	value = clamp(
		new_value,
		minimum_value,
		maximum_value
	)


func change_value(change: float) -> void:
	set_value(value + change)


func add_player_contribution(change: float) -> void:
	player_contribution += change
	_apply_contribution(
		"player",
		change
	)


func add_ai_contribution(change: float) -> void:
	ai_contribution += change
	_apply_contribution(
		"ai",
		change
	)


func add_environmental_contribution(change: float) -> void:
	environmental_contribution += change
	_apply_contribution(
		"environment",
		change
	)


func add_external_actor_contribution(change: float) -> void:
	external_actor_contribution += change
	_apply_contribution(
		"external_actor",
		change
	)


func set_uncertainty(new_value: float) -> void:
	uncertainty = clamp(
		new_value,
		0.0,
		1.0
	)


func _apply_contribution(
	source: String,
	change: float
) -> void:

	var previous_value = value

	change_value(change)

	var entry = {
		"source": source,
		"change": change,
		"previous_value": previous_value,
		"new_value": value
	}

	history.append(entry)


func get_history() -> Array:
	return history


func get_value() -> float:
	return value


func is_active() -> bool:
	return active


func activate() -> void:
	active = true


func deactivate() -> void:
	active = false


func resolve() -> void:
	resolved = true
	active = false


func is_resolved() -> bool:
	return resolved

# ============================================================
# STEP 15.13 — ACTION OUTCOME FEEDBACK
# ============================================================

func record_action_outcome_feedback(
	outcome: Dictionary
) -> bool:
	if outcome.is_empty():
		return false

	var action_id_value: Variant = outcome.get(
		"action_id",
		-1
	)

	if typeof(action_id_value) != TYPE_INT:
		return false

	var action_id: int = int(action_id_value)

	for existing_variant in history:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue

		var existing: Dictionary = existing_variant

		if str(
			existing.get(
				"source",
				""
			)
		) != "action_outcome":
			continue

		var existing_id_value: Variant = existing.get(
			"action_id",
			-1
		)

		if typeof(existing_id_value) == TYPE_INT:
			if int(existing_id_value) == action_id:
				return false

	var actual_effect_value: Variant = outcome.get(
		"actual_effect",
		{}
	)

	var actual_effect: Dictionary = {}
	if typeof(actual_effect_value) == TYPE_DICTIONARY:
		actual_effect = actual_effect_value.duplicate(true)

	var completion_result_value: Variant = outcome.get(
		"completion_result",
		{}
	)

	var completion_result: Dictionary = {}
	if typeof(completion_result_value) == TYPE_DICTIONARY:
		completion_result = completion_result_value.duplicate(true)

	var entry: Dictionary = {
		"source": "action_outcome",
		"action_id": action_id,
		"status": str(outcome.get("status", "")),
		"start": str(outcome.get("start", "")),
		"end": str(outcome.get("end", "")),
		"actual_effect": actual_effect,
		"failure_reason": str(
			outcome.get(
				"failure_reason",
				""
			)
		),
		"completion_result": completion_result,
		"previous_value": value,
		"new_value": value
	}

	history.append(entry)
	return true


func get_action_outcome_feedback() -> Array:
	var result: Array = []

	for entry_variant in history:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant

		if str(
			entry.get(
				"source",
				""
			)
		) != "action_outcome":
			continue

		result.append(
			entry.duplicate(true)
		)

	return result
