class_name MilitaryRelationshipSystem
extends SimulationSystem


# ============================================================
# INITIALIZATION
# ============================================================

func _init():
	super("military_relationship_system")


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"MilitaryRelationshipSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_update_entity_relationships(
			entity,
			world
		)


# ============================================================
# UPDATE ENTITY RELATIONSHIPS
# ============================================================

func _update_entity_relationships(
	source,
	world: WorldState
) -> void:

	var source_military = (
		source.get_component("military")
	)

	if source_military == null:
		return

	var source_capability = (
		_get_military_capability(
			source_military
		)
	)

	var relationships = (
		source.get_all_relationships()
	)

	if typeof(relationships) != TYPE_DICTIONARY:
		return

	for target_id in relationships.keys():

		var target = (
			world.get_entity(
				str(target_id)
			)
		)

		if target == null:
			continue

		var target_military = (
			target.get_component("military")
		)

		if target_military == null:
			continue

		var target_capability = (
			_get_military_capability(
				target_military
			)
		)

		var military_relationship = (
			_calculate_military_relationship(
				source_capability,
				target_capability
			)
		)

		source.set_relationship_dimension(
			str(target_id),
			"military",
			military_relationship
		)


# ============================================================
# MILITARY CAPABILITY
# ============================================================

func _get_military_capability(
	military
) -> float:

	if military == null:
		return 0.0

	var military_power = clamp(
		float(
			military.get_state(
				"military_power",
				0.0
			)
		),
		0.0,
		1.0
	)

	var defensive_capability = clamp(
		float(
			military.get_state(
				"defensive_capability",
				0.0
			)
		),
		0.0,
		1.0
	)

	var power_projection = clamp(
		float(
			military.get_state(
				"power_projection",
				0.0
			)
		),
		0.0,
		1.0
	)

	var mobilization_capacity = clamp(
		float(
			military.get_state(
				"mobilization_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)

	var capability = (
		military_power * 0.35
		+ defensive_capability * 0.20
		+ power_projection * 0.30
		+ mobilization_capacity * 0.15
	)

	return clamp(
		capability,
		0.0,
		1.0
	)


# ============================================================
# MILITARY RELATIONSHIP
# ============================================================

func _calculate_military_relationship(
	source_capability: float,
	target_capability: float
) -> float:

	var total_capability = (
		source_capability
		+ target_capability
	)

	if total_capability <= 0.0:
		return 0.0

	var relative_share = (
		source_capability
		/ total_capability
	)

	# Convert relative military capability into
	# a -100 ... +100 relationship dimension.
	#
	# Equal capability = 0
	# Source stronger = positive
	# Source weaker = negative

	var military_relationship = (
		relative_share - 0.5
	) * 200.0

	return clamp(
		military_relationship,
		-100.0,
		100.0
	)
