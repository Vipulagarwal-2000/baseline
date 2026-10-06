class_name GeographySystem
extends SimulationSystem


const EARTH_RADIUS_KM: float = 6371.0


func _init():

	super(
		"geography_system"
	)


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"GeographySystem: World is null."
		)

		return


	var entities = (
		world.entities.values()
	)


	for source in entities:

		var source_geography = (
			source.get_component(
				"geography"
			)
		)

		if source_geography == null:

			continue


		for target in entities:

			if source == target:

				continue


			var target_geography = (
				target.get_component(
					"geography"
				)
			)

			if target_geography == null:

				continue


			_update_geographic_relationship(
				source,
				target,
				source_geography,
				target_geography
			)


# ============================================================
# UPDATE GEOGRAPHIC RELATIONSHIP
# ============================================================

func _update_geographic_relationship(
	source,
	target,
	source_geography: GeographyComponent,
	target_geography: GeographyComponent
) -> void:

	var source_id = str(
		source.id
	)

	var target_id = str(
		target.id
	)


	var distance_km = (
		_calculate_distance(
			source_geography,
			target_geography
		)
	)


	var shared_border = (
		source_geography.has_neighbor(
			target_id
		)
		and
		target_geography.has_neighbor(
			source_id
		)
	)


	var accessibility = (
		_calculate_accessibility(
			distance_km,
			shared_border
		)
	)


	# --------------------------------------------------------
	# Store geographic information on the relationship.
	# --------------------------------------------------------

	var relationship_data = (
		source.get_relationship_data(
			target_id
		)
	)


	if relationship_data.is_empty():

		relationship_data = {
			"overall": 0.0,

			"diplomatic": 0.0,

			"economic": 0.0,

			"military": 0.0,

			"trade": 0.0,

			"political": 0.0,

			"cultural": 0.0,

			"trust": 0.0,

			"hostility": 0.0
		}


	relationship_data[
		"distance_km"
	] = distance_km


	relationship_data[
		"shared_border"
	] = shared_border


	relationship_data[
		"influence_accessibility"
	] = accessibility


	source.relationships[
		target_id
	] = relationship_data


	# --------------------------------------------------------
	# Also store the distance in the geography component.
	# --------------------------------------------------------

	var distances = (
		source_geography.get_state(
			"distances",
			{}
		)
	)


	if typeof(
		distances
	) != TYPE_DICTIONARY:

		distances = {}


	distances[
		target_id
	] = distance_km


	source_geography.set_state(
		"distances",
		distances
	)


# ============================================================
# DISTANCE CALCULATION
# ============================================================

func _calculate_distance(
	source_geography: GeographyComponent,
	target_geography: GeographyComponent
) -> float:

	var source_latitude = (
		source_geography.get_latitude()
	)

	var source_longitude = (
		source_geography.get_longitude()
	)

	var target_latitude = (
		target_geography.get_latitude()
	)

	var target_longitude = (
		target_geography.get_longitude()
	)


	var latitude_1 = deg_to_rad(
		source_latitude
	)

	var latitude_2 = deg_to_rad(
		target_latitude
	)


	var latitude_difference = deg_to_rad(
		target_latitude
		- source_latitude
	)


	var longitude_difference = deg_to_rad(
		target_longitude
		- source_longitude
	)


	var a = (
		sin(
			latitude_difference / 2.0
		)
		* sin(
			latitude_difference / 2.0
		)
	)


	a += (
		cos(latitude_1)
		* cos(latitude_2)
		* sin(
			longitude_difference / 2.0
		)
		* sin(
			longitude_difference / 2.0
		)
	)


	var c = (
		2.0
		* atan2(
			sqrt(a),
			sqrt(
				max(
					0.0,
					1.0 - a
				)
			)
		)
	)


	return max(
		0.0,
		EARTH_RADIUS_KM * c
	)


# ============================================================
# ACCESSIBILITY
# ============================================================

func _calculate_accessibility(
	distance_km: float,
	shared_border: bool
) -> float:

	# --------------------------------------------------------
	# Shared borders create very high geographic accessibility.
	# --------------------------------------------------------

	if shared_border:

		return 1.0


	# --------------------------------------------------------
	# Distance gradually reduces accessibility.
	#
	# This is intentionally a simple first model.
	# Technology, naval power, air power, infrastructure,
	# alliances and trade routes can later modify it.
	# --------------------------------------------------------

	var distance_factor = 1.0 / (
		1.0
		+ distance_km / 5000.0
	)


	return clamp(
		distance_factor,
		0.05,
		1.0
	)
