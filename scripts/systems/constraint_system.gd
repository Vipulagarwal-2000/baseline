class_name ConstraintSystem
extends SimulationSystem


func _init():
	super("constraint_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("ConstraintSystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		_evaluate_entity_constraints(
			world,
			entity
		)


func _evaluate_entity_constraints(
	world: WorldState,
	entity
) -> void:

	var results: Dictionary = {}

	for component in entity.components.values():

		if component == null:
			continue

		var constraints = component.constraints

		if typeof(constraints) != TYPE_DICTIONARY:
			continue

		for constraint_id in constraints.keys():

			var constraint_value = constraints[
				constraint_id
			]

			var result = evaluate_constraint(
				world,
				entity,
				str(constraint_id),
				constraint_value
			)

			results[str(constraint_id)] = result

	entity.set_sim_metadata(
		"constraint_results",
		results
	)


func evaluate_constraint(
	world: WorldState,
	entity,
	constraint_id: String,
	constraint_value
) -> bool:

	if world == null:
		return false

	if entity == null:
		return false

	if constraint_id.is_empty():
		return false

	match constraint_id:

		"requires_capability":
			return _check_required_capability(
				entity,
				constraint_value
			)

		"minimum_year":
			return world.get_year() >= int(
				constraint_value
			)

		"maximum_year":
			return world.get_year() <= int(
				constraint_value
			)

		_:
			return _check_component_state_constraint(
				entity,
				constraint_id,
				constraint_value
			)


func _check_required_capability(
	entity,
	capability_id
) -> bool:

	var capabilities = entity.get_sim_metadata(
		"capabilities",
		{}
	)

	if typeof(capabilities) != TYPE_DICTIONARY:
		return false

	if typeof(capability_id) == TYPE_STRING:
		return bool(
			capabilities.get(
				capability_id,
				false
			)
		)

	if typeof(capability_id) == TYPE_ARRAY:

		for capability in capability_id:

			if not bool(
				capabilities.get(
					str(capability),
					false
				)
			):
				return false

		return true

	return false


func _check_component_state_constraint(
	entity,
	constraint_id: String,
	constraint_value
) -> bool:

	if typeof(constraint_value) != TYPE_DICTIONARY:
		return false

	var component_type = str(
		constraint_value.get(
			"component",
			""
		)
	)

	var state_key = str(
		constraint_value.get(
			"state",
			""
		)
	)

	var minimum_value = float(
		constraint_value.get(
			"minimum",
			0.0
		)
	)

	if component_type.is_empty():
		return false

	if state_key.is_empty():
		return false

	var component = entity.get_component(
		component_type
	)

	if component == null:
		return false

	var current_value = float(
		component.get_state(
			state_key,
			0.0
		)
	)

	return current_value >= minimum_value


func can_satisfy(
	world: WorldState,
	entity,
	constraint_id: String,
	constraint_value
) -> bool:

	return evaluate_constraint(
		world,
		entity,
		constraint_id,
		constraint_value
	)


func get_constraint_results(
	entity
) -> Dictionary:

	if entity == null:
		return {}

	var results = entity.get_sim_metadata(
		"constraint_results",
		{}
	)

	if typeof(results) != TYPE_DICTIONARY:
		return {}

	return results
