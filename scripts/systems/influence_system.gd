class_name InfluenceSystem
extends SimulationSystem


# ============================================================
# INITIALIZATION
# ============================================================

func _init():

	super(
		"influence_system"
	)


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"InfluenceSystem: World is null."
		)

		return


	for entity in world.entities.values():

		_calculate_entity_influence(
			entity,
			world
		)


# ============================================================
# CALCULATE ENTITY INFLUENCE
# ============================================================

func _calculate_entity_influence(
	entity,
	world: WorldState
) -> void:

	if entity == null:

		return


	var relationships = (
		entity.get_all_relationships()
	)


	if typeof(
		relationships
	) != TYPE_DICTIONARY:

		return


	for target_id in relationships.keys():

		var target = (
			world.get_entity(
				str(target_id)
			)
		)


		if target == null:

			continue


		var relationship_data = (
			entity.get_relationship_data(
				str(target_id)
			)
		)


		if relationship_data.is_empty():

			continue


		var influence = (
			_calculate_influence(
				entity,
				target,
				relationship_data
			)
		)


		relationship_data[
			"influence"
		] = influence


		relationships[
			target_id
		] = relationship_data


# ============================================================
# CALCULATE INFLUENCE
# ============================================================

func _calculate_influence(
	source,
	target,
	relationship_data: Dictionary
) -> float:

	# --------------------------------------------------------
	# RELATIONSHIP FACTOR
	#
	# Converts -100 ... +100 into 0 ... 1.
	# --------------------------------------------------------

	var relationship = float(
		relationship_data.get(
			"overall",
			0.0
		)
	)


	var relationship_factor = (
		relationship + 100.0
	) / 200.0


	relationship_factor = clamp(
		relationship_factor,
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# DIPLOMATIC FACTOR
	# --------------------------------------------------------

	var diplomatic = float(
		relationship_data.get(
			"diplomatic",
			0.0
		)
	)


	var diplomatic_factor = (
		diplomatic + 100.0
	) / 200.0


	diplomatic_factor = clamp(
		diplomatic_factor,
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# ECONOMIC POWER
	# --------------------------------------------------------

	var source_gdp = (
		_get_gdp(
			source
		)
	)


	var target_gdp = (
		_get_gdp(
			target
		)
	)


	var economic_power_factor = 1.0


	if source_gdp > 0.0 \
	and target_gdp > 0.0:

		var total_gdp = (
			source_gdp
			+ target_gdp
		)


		if total_gdp > 0.0:

			var source_share = (
				source_gdp
				/ total_gdp
			)


			economic_power_factor = (
				0.5
				+ source_share
			)


	# --------------------------------------------------------
	# GEOGRAPHIC ACCESSIBILITY
	# --------------------------------------------------------

	var geographic_accessibility = float(
		relationship_data.get(
			"influence_accessibility",
			1.0
		)
	)


	var strategic_interest = float(
		relationship_data.get(
			"strategic_interest",
			1.0
		)
	)


	geographic_accessibility = max(
		0.0,
		geographic_accessibility
	)


	strategic_interest = max(
		0.0,
		strategic_interest
	)


	# --------------------------------------------------------
	# MILITARY INFLUENCE
	#
	# Military contributes to influence through:
	#
	#   military power
	#   defensive capability
	#   power projection
	#
	# The effect is deliberately moderate so military power
	# supports influence rather than completely determining it.
	# --------------------------------------------------------

	var military_influence_factor = (
		_get_military_influence_factor(
			source
		)
	)


	# --------------------------------------------------------
	# LEGACY RELATIONSHIP POWER PROJECTION
	#
	# Preserve the existing relationship-level field.
	#
	# If present, it can still modify the result.
	# Default remains 1.0.
	# --------------------------------------------------------

	var relationship_power_projection = float(
		relationship_data.get(
			"power_projection",
			1.0
		)
	)


	relationship_power_projection = max(
		0.0,
		relationship_power_projection
	)


	# --------------------------------------------------------
	# FINAL INFLUENCE
	# --------------------------------------------------------

	var influence = (
		100.0
		* relationship_factor
		* diplomatic_factor
		* economic_power_factor
		* geographic_accessibility
		* strategic_interest
		* relationship_power_projection
		* military_influence_factor
	)


	return clamp(
		influence,
		0.0,
		100.0
	)


# ============================================================
# MILITARY INFLUENCE FACTOR
# ============================================================

func _get_military_influence_factor(
	entity
) -> float:

	if entity == null:

		return 1.0


	var military = entity.get_component(
		"military"
	)


	if military == null:

		return 1.0


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


	# Military influence capability.
	#
	# Power projection receives the highest weight because
	# influence is partly about the ability to project power
	# beyond the country's immediate territory.
	#
	# Defensive capability still contributes, but less than
	# projection.
	#
	# Military power provides the underlying capability.

	var military_capability = (
		military_power * 0.35
		+ defensive_capability * 0.20
		+ power_projection * 0.45
	)


	military_capability = clamp(
		military_capability,
		0.0,
		1.0
	)


	# Convert 0...1 military capability into a moderate
	# influence multiplier.
	#
	# 0.0 capability -> 0.80 multiplier
	# 0.5 capability -> 1.00 multiplier
	# 1.0 capability -> 1.20 multiplier

	var military_influence_factor = (
		0.80
		+ military_capability * 0.40
	)


	return clamp(
		military_influence_factor,
		0.80,
		1.20
	)


# ============================================================
# GET GDP
# ============================================================

func _get_gdp(
	entity
) -> float:

	if entity == null:

		return 0.0


	var economy = (
		entity.get_component(
			"economy"
		)
	)


	if economy == null:

		return 0.0


	return max(
		0.0,
		float(
			economy.get_state(
				"gdp",
				0.0
			)
		)
	)


# ============================================================
# GET INFLUENCE
# ============================================================

func get_influence(
	entity,
	target_id: String
) -> float:

	if entity == null:

		return 0.0


	var relationship_data = (
		entity.get_relationship_data(
			target_id
		)
	)


	if relationship_data.is_empty():

		return 0.0


	return float(
		relationship_data.get(
			"influence",
			0.0
		)
	)


# ============================================================
# GET ALL INFLUENCE
# ============================================================

func get_all_influence(
	entity
) -> Dictionary:

	var result: Dictionary = {}


	if entity == null:

		return result


	var relationships = (
		entity.get_all_relationships()
	)


	if typeof(
		relationships
	) != TYPE_DICTIONARY:

		return result


	for target_id in relationships.keys():

		result[
			str(target_id)
		] = get_influence(
			entity,
			str(target_id)
		)


	return result
