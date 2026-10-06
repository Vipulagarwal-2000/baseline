class_name AIMemorySystem
extends SimulationSystem


func _init():
	super("ai_memory_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("AIMemorySystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		_record_decision_memory(
			world,
			entity
		)


func _record_decision_memory(
	world: WorldState,
	entity
) -> void:

	if world == null:
		return

	if entity == null:
		return

	var selected_decision = entity.get_sim_metadata(
		"selected_decision",
		null
	)

	if selected_decision == null:
		return

	if not selected_decision is DecisionOption:
		return

	var memory_entry = {
		"type": "ai_decision",
		"year": world.get_year(),
		"month": world.get_month(),
		"day": world.get_day(),
		"action_id": selected_decision.id,
		"action_type": selected_decision.action_type,
		"target_id": selected_decision.target_id,
		"score": selected_decision.final_score
	}

	entity.add_memory(
		memory_entry
	)


func record_event_memory(
	entity,
	event_type: String,
	data: Dictionary = {}
) -> void:

	if entity == null:
		return

	var entry = {
		"type": event_type,
		"data": data.duplicate(true)
	}

	entity.add_memory(
		entry
	)


func get_decision_memories(
	entity
) -> Array:

	if entity == null:
		return []

	return entity.get_memory_by_type(
		"ai_decision"
	)

# ============================================================
# STEP 15.13 — ACTION OUTCOME FEEDBACK
# ============================================================

func record_action_outcome_memory(
	world: WorldState,
	outcome: Dictionary
) -> bool:
	if world == null:
		return false

	if outcome.is_empty():
		return false

	var actor_id: String = str(
		outcome.get(
			"actor",
			""
		)
	)

	if actor_id.is_empty():
		return false

	var entity = world.get_entity(
		actor_id
	)

	if entity == null:
		return false

	var action_id_value: Variant = outcome.get(
		"action_id",
		-1
	)

	if typeof(action_id_value) != TYPE_INT:
		return false

	var action_id: int = int(action_id_value)

	var existing_memories: Array = get_action_outcome_memories(
		entity
	)

	for existing_variant in existing_memories:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue

		var existing: Dictionary = existing_variant
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

	var memory_entry: Dictionary = {
		"type": "ai_action_outcome",
		"feedback_source": "action_manager",
		"action_id": action_id,
		"actor": str(outcome.get("actor", "")),
		"action_type": str(outcome.get("type", "")),
		"target_id": str(outcome.get("target", "")),
		"start": str(outcome.get("start", "")),
		"end": str(outcome.get("end", "")),
		"status": str(outcome.get("status", "")),
		"cost": float(outcome.get("cost", 0.0)),
		"actual_effect": actual_effect,
		"failure_reason": str(outcome.get("failure_reason", "")),
		"completion_result": completion_result
	}

	entity.add_memory(
		memory_entry
	)

	entity.set_sim_metadata(
		"latest_ai_action_outcome",
		memory_entry.duplicate(true)
	)

	return true


func get_action_outcome_memories(
	entity
) -> Array:
	if entity == null:
		return []

	return entity.get_memory_by_type(
		"ai_action_outcome"
	)


func get_latest_action_outcome_memory(
	entity
) -> Dictionary:
	if entity == null:
		return {}

	var value: Variant = entity.get_sim_metadata(
		"latest_ai_action_outcome",
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	var result: Dictionary = value
	return result.duplicate(true)
