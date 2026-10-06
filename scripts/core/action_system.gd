class_name ActionSystem
extends RefCounted


func execute_action(
	world: WorldState,
	action: SimAction
) -> bool:

	if world == null:
		push_error("ActionSystem: World is null.")
		return false

	if action == null:
		push_error("ActionSystem: Action is null.")
		return false

	var actor = world.get_entity(action.actor_id)

	if actor == null:
		push_error(
			"ActionSystem: Actor not found: "
			+ action.actor_id
		)
		return false

	# A zero-value action with no effect payload is a valid no-op
	# completion. This preserves the generic duration/progress contract
	# while still allowing non-zero or effect-bearing actions to reach
	# authoritative domain execution and fail explicitly when unsupported.
	if action.effects.is_empty() and is_zero_approx(action.value):
		action.completion_result = {
			"status": "completed",
			"effect_applied": false,
			"action_type": action.action_type,
			"actor_id": action.actor_id,
			"target_id": action.target_id,
			"value": action.value
		}
		return true

	var target = world.get_entity(action.target_id)

	if target == null:
		push_error(
			"ActionSystem: Target not found: "
			+ action.target_id
		)
		return false


	# --------------------------------------------------------
	# Diplomatic outreach
	# --------------------------------------------------------

	if action.action_type == "diplomatic_outreach":

		var implementation_modifier = _get_government_implementation(
			actor,
			"diplomatic"
		)

		var effective_value = action.value * implementation_modifier

		actor.change_relationship_dimension(
			target.id,
			"diplomatic",
			effective_value
		)

		action.completion_result = {
			"actual_effect": {
				"relationship_change": effective_value,
				"relationship_dimension": "diplomatic",
				"implementation_modifier": implementation_modifier
			},
			"action_type": action.action_type,
			"actor_id": action.actor_id,
			"target_id": action.target_id,
			"value": action.value
		}

		return true


	# --------------------------------------------------------
	# Unknown action
	# --------------------------------------------------------

	push_error(
		"ActionSystem: Unknown action type: "
		+ action.action_type
	)

	return false


func _get_government_implementation(
	actor: SimEntity,
	action_category: String
) -> float:

	var government = actor.get_component("government")

	if government == null:
		return 1.0

	var policy_capacity = float(
		government.get_state(
			"policy_capacity",
			0.50
		)
	)

	var institutional_strength = float(
		government.get_state(
			"institutional_strength",
			0.50
		)
	)

	var executive_strength = float(
		government.get_state(
			"executive_strength",
			0.50
		)
	)

	var reform_flexibility = float(
		government.get_state(
			"reform_flexibility",
			0.50
		)
	)

	var implementation = 0.0


	if action_category == "diplomatic":

		implementation = (
			policy_capacity * 0.40
			+ institutional_strength * 0.25
			+ executive_strength * 0.15
			+ reform_flexibility * 0.20
		)

	else:

		implementation = (
			policy_capacity * 0.50
			+ institutional_strength * 0.30
			+ executive_strength * 0.20
		)


	return clamp(
		implementation,
		0.25,
		1.00
	)
