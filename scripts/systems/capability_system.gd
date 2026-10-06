class_name CapabilitySystem
extends SimulationSystem


func _init():
	super("capability_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("CapabilitySystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		_rebuild_entity_capabilities(entity)


func _rebuild_entity_capabilities(entity) -> void:
	if entity == null:
		return

	var capabilities: Dictionary = {}

	# ============================================================
	# RESEARCH CAPABILITIES
	# ============================================================

	var research = entity.get_component("research")

	if research != null:
		var research_capabilities = (
			research.get_research_capabilities()
		)

		if typeof(research_capabilities) == TYPE_DICTIONARY:
			for capability_id in research_capabilities.keys():
				if bool(
					research_capabilities[
						capability_id
					]
				):
					capabilities[
						str(capability_id)
					] = true


	# ============================================================
	# INDUSTRIAL EQUIPMENT CAPABILITIES
	# ============================================================

	var industry = entity.get_component("industry")

	if industry != null:
		var equipment_capabilities = (
			industry.get_state(
				"equipment_capabilities",
				{}
			)
		)

		if typeof(equipment_capabilities) == TYPE_DICTIONARY:
			for equipment_id in equipment_capabilities.keys():

				var equipment_value = (
					equipment_capabilities[
						equipment_id
					]
				)

				var equipment_key := str(
					equipment_id
				)

				if (
					typeof(equipment_value)
					== TYPE_INT
					or
					typeof(equipment_value)
					== TYPE_FLOAT
				):
					capabilities[
						equipment_key
					] = maxf(
						float(equipment_value),
						0.0
					)

				elif typeof(equipment_value) == TYPE_BOOL:
					capabilities[
						equipment_key
					] = bool(
						equipment_value
					)


	entity.set_sim_metadata(
		"capabilities",
		capabilities
	)

	_update_capability_scores(entity)


func _update_capability_scores(entity) -> void:
	var capability_scores: Dictionary = {}

	var research_score = (
		_get_research_capability_score(entity)
	)

	capability_scores[
		"research"
	] = research_score

	var military_scores = (
		_get_military_capability_scores(
			entity
		)
	)

	for capability_id in military_scores.keys():
		capability_scores[
			capability_id
		] = military_scores[
			capability_id
		]

	entity.set_sim_metadata(
		"capability_scores",
		capability_scores
	)


func _get_research_capability_score(entity) -> float:
	var research = entity.get_component(
		"research"
	)

	if research == null:
		return 0.0

	var technology_level := clampf(
		float(
			research.get_state(
				"technology_level",
				0.0
			)
		),
		0.0,
		100.0
	)

	return clampf(
		technology_level / 100.0,
		0.0,
		1.0
	)


func _get_military_capability_scores(
	entity
) -> Dictionary:

	var scores := {}

	var military = entity.get_component(
		"military"
	)

	if military == null:
		scores[
			"military_power"
		] = 0.0

		scores[
			"military_defense"
		] = 0.0

		scores[
			"military_projection"
		] = 0.0

		scores[
			"military_mobilization"
		] = 0.0

		return scores

	var military_power := clampf(
		float(
			military.get_state(
				"military_power",
				0.0
			)
		),
		0.0,
		1.0
	)

	var defensive_capability := clampf(
		float(
			military.get_state(
				"defensive_capability",
				0.0
			)
		),
		0.0,
		1.0
	)

	var power_projection := clampf(
		float(
			military.get_state(
				"power_projection",
				0.0
			)
		),
		0.0,
		1.0
	)

	var mobilization_capacity := clampf(
		float(
			military.get_state(
				"mobilization_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)

	scores[
		"military_power"
	] = military_power

	scores[
		"military_defense"
	] = defensive_capability

	scores[
		"military_projection"
	] = power_projection

	scores[
		"military_mobilization"
	] = mobilization_capacity

	return scores


func has_capability(
	entity,
	capability_id: String
) -> bool:

	if (
		entity == null
		or capability_id.is_empty()
	):
		return false

	var capabilities = (
		entity.get_sim_metadata(
			"capabilities",
			{}
		)
	)

	if typeof(capabilities) != TYPE_DICTIONARY:
		return false

	return bool(
		capabilities.get(
			capability_id,
			false
		)
	)


func get_capabilities(entity) -> Dictionary:
	if entity == null:
		return {}

	var capabilities = (
		entity.get_sim_metadata(
			"capabilities",
			{}
		)
	)

	if typeof(capabilities) != TYPE_DICTIONARY:
		return {}

	return capabilities


func get_capability_scores(entity) -> Dictionary:
	if entity == null:
		return {}

	var capability_scores = (
		entity.get_sim_metadata(
			"capability_scores",
			{}
		)
	)

	if typeof(capability_scores) != TYPE_DICTIONARY:
		return {}

	return capability_scores


func get_capability_score(
	entity,
	capability_id: String
) -> float:

	if (
		entity == null
		or capability_id.is_empty()
	):
		return 0.0

	var capability_scores = (
		get_capability_scores(entity)
	)

	return clampf(
		float(
			capability_scores.get(
				capability_id,
				0.0
			)
		),
		0.0,
		1.0
	)
