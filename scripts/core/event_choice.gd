class_name EventChoice
extends RefCounted


# ============================================================
# E9 — CHOICE MODEL
# ============================================================
#
# Declarative branch:
#   choice
#       ↓
#   choice conditions
#       ↓
#   choice effects
#
# E9 does not execute choices from JSON or monthly simulation.
# EventChoiceExecutor owns branch evaluation/execution.
# ============================================================


var id: String = ""
var name: String = ""
var description: String = ""

# Conditions use the same EventCondition model established by E4/E5.
var conditions: Array = []

# Effects use the declarative EventEffect model established by E6.
var effects: Array = []

var metadata: Dictionary = {}


func _init(
	choice_id: String = "",
	choice_name: String = "",
	choice_description: String = "",
	choice_conditions: Array = [],
	choice_effects: Array = [],
	choice_metadata: Dictionary = {}
) -> void:
	id = choice_id.strip_edges()
	name = choice_name.strip_edges()
	description = choice_description
	conditions = choice_conditions.duplicate()
	effects = choice_effects.duplicate()
	metadata = choice_metadata.duplicate(true)


# ============================================================
# VALIDATION
# ============================================================

func is_valid() -> bool:
	if id.is_empty():
		return false

	if name.is_empty():
		return false

	for condition in conditions:
		if condition == null:
			return false

		if not (condition is EventCondition):
			return false

		if not condition.is_valid():
			return false

	for effect in effects:
		if effect == null:
			return false

		if not (effect is EventEffect):
			return false

		if not effect.is_valid():
			return false

	return true


func set_metadata_value(
	key: String,
	value
) -> void:
	var normalized_key: String = key.strip_edges()
	if normalized_key.is_empty():
		return

	metadata[normalized_key] = value


func get_metadata_value(
	key: String,
	default_value = null
):
	return metadata.get(key, default_value)


func has_metadata_value(
	key: String
) -> bool:
	return metadata.has(key)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"conditions": conditions.duplicate(),
		"effects": effects.duplicate(),
		"metadata": metadata.duplicate(true),
	}
