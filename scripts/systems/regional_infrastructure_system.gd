class_name RegionalInfrastructureSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.6
# REGIONAL INFRASTRUCTURE LOCALIZATION
# ============================================================
#
# Country InfrastructureComponent remains the authoritative country
# baseline. Step 12.6 localizes its normalized infrastructure indices to
# parent regions using explicit simulation-calibration profiles.
#
# No province-level authority, infrastructure investment, maintenance,
# damage, or monthly infrastructure mutation is introduced here.
# ============================================================


const EPSILON: float = 0.000001


func _init() -> void:
	super("regional_infrastructure_system")


func process_month(world: WorldState) -> void:
	# Step 12.6 is a localization/seed layer only.
	if world == null:
		return


func initialize_world(world: WorldState, definitions: Array) -> bool:
	if world == null:
		return false
	if world.get_region_count() <= 0:
		return false
	if world.get_regional_infrastructure_count() > 0:
		return false

	var profiles: Dictionary = _build_profile_map(definitions)
	if profiles.is_empty():
		return false

	if not _validate_profile_map_against_world(world, profiles):
		return false

	for country_id in _sorted_country_ids(profiles):
		var country = world.get_entity(country_id)
		if country == null:
			return false

		var infrastructure = country.get_component("infrastructure")
		if infrastructure == null:
			return false

		if not _initialize_country_infrastructure(
			world,
			country_id,
			infrastructure,
			profiles[country_id]
		):
			return false

	return validate_world(world)


func get_infrastructure_state(
	world: WorldState,
	region_id: String
) -> RegionalInfrastructureState:
	if world == null:
		return null
	return world.get_regional_infrastructure(region_id) as RegionalInfrastructureState


func get_infrastructure_snapshot(world: WorldState, region_id: String) -> Dictionary:
	var state: RegionalInfrastructureState = get_infrastructure_state(world, region_id)
	if state == null:
		return {}
	return state.to_snapshot_dict()


func get_country_infrastructure_average(
	world: WorldState,
	country_id: String
) -> Dictionary:
	var result: Dictionary = {
		"transport": 0.0,
		"railways": 0.0,
		"roads": 0.0,
		"ports": 0.0,
		"power": 0.0,
		"industrial": 0.0,
		"storage": 0.0,
		"total_capacity": 0.0
	}

	for region_id in _sorted_parent_region_ids(world, country_id):
		var state: RegionalInfrastructureState = get_infrastructure_state(
			world,
			region_id
		)
		if state == null:
			continue

		result["transport"] += state.transport * state.aggregation_weight
		result["railways"] += state.railways * state.aggregation_weight
		result["roads"] += state.roads * state.aggregation_weight
		result["ports"] += state.ports * state.aggregation_weight
		result["power"] += state.power * state.aggregation_weight
		result["industrial"] += state.industrial * state.aggregation_weight
		result["storage"] += state.storage * state.aggregation_weight
		result["total_capacity"] += state.total_capacity * state.aggregation_weight

	return result


func validate_world(world: WorldState) -> bool:
	if world == null:
		return false

	var expected_state_count: int = 0

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			return false

		if region.is_province():
			if world.has_regional_infrastructure(region.id):
				return false
			continue

		if not region.is_region():
			return false

		expected_state_count += 1

		var state: RegionalInfrastructureState = get_infrastructure_state(
			world,
			region.id
		)
		if state == null or not state.is_valid():
			return false

		if state.structural_country_id != region.country_id:
			return false

	if world.get_regional_infrastructure_count() != expected_state_count:
		return false

	for country_id in _sorted_country_ids_from_regions(world):
		var country = world.get_entity(country_id)
		if country == null:
			return false

		var infrastructure = country.get_component("infrastructure")
		if infrastructure == null:
			return false

		var source_state: Dictionary = {}
		var region_ids: Array = _sorted_parent_region_ids(world, country_id)
		if region_ids.is_empty():
			return false

		var first_state: RegionalInfrastructureState = get_infrastructure_state(
			world,
			region_ids[0]
		)
		if first_state == null:
			return false

		source_state = first_state.source_country_infrastructure_state
		if not _validate_source_state(source_state):
			return false

		var weight_total: float = 0.0
		for region_id in region_ids:
			var state: RegionalInfrastructureState = get_infrastructure_state(
				world,
				region_id
			)
			if state == null:
				return false
			if state.source_country_infrastructure_state != source_state:
				return false
			weight_total += state.aggregation_weight

		if not is_equal_approx(weight_total, 1.0):
			return false

		var regional_average: Dictionary = get_country_infrastructure_average(
			world,
			country_id
		)

		var source_transport: float = float(source_state["transport"])
		var source_railways: float = float(source_state["railways"])
		var source_roads: float = float(source_state["roads"])
		var source_ports: float = float(source_state["ports"])
		var source_power: float = float(source_state["power"])
		var source_industrial: float = float(source_state["industrial"])
		var source_storage: float = float(source_state["storage"])
		var derived_source_total_capacity: float = first_state.derived_source_total_capacity

		if not is_equal_approx(regional_average["transport"], source_transport):
			return false
		if not is_equal_approx(regional_average["railways"], source_railways):
			return false
		if not is_equal_approx(regional_average["roads"], source_roads):
			return false
		if not is_equal_approx(regional_average["ports"], source_ports):
			return false
		if not is_equal_approx(regional_average["power"], source_power):
			return false
		if not is_equal_approx(regional_average["industrial"], source_industrial):
			return false
		if not is_equal_approx(regional_average["storage"], source_storage):
			return false

		# Existing InfrastructureSystem derives country total_capacity as the
		# arithmetic mean of the seven infrastructure dimensions. Step 12.6
		# must preserve that invariant in the regional weighted aggregate.
		if not is_equal_approx(regional_average["total_capacity"], derived_source_total_capacity):
			return false

	return true


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	for country_id in _sorted_country_ids_from_regions(world):
		for region_id in _sorted_parent_region_ids(world, country_id):
			var state: RegionalInfrastructureState = get_infrastructure_state(
				world,
				region_id
			)
			if state != null:
				snapshot[region_id] = state.to_snapshot_dict()

	return snapshot


func _initialize_country_infrastructure(
	world: WorldState,
	country_id: String,
	infrastructure_component,
	country_profiles: Dictionary
) -> bool:
	var region_ids: Array = _sorted_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var country_infrastructure_state: Dictionary = {}
	var required_keys: Array = [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage",
        "total_capacity"
	]

	for key in required_keys:
		var value: Variant = infrastructure_component.get_state(key, null)
		if value == null:
			return false
		var numeric_type: int = typeof(value)
		if numeric_type != TYPE_FLOAT and numeric_type != TYPE_INT:
			return false
		var numeric_value: float = float(value)
		if numeric_value < 0.0 or numeric_value > 1.0:
			return false
		country_infrastructure_state[key] = numeric_value

	for region_id in region_ids:
		var region: Region = world.get_region(region_id) as Region
		var profile_value: Variant = country_profiles.get(region_id, null)
		if region == null or not profile_value is Dictionary:
			return false

		var profile: Dictionary = profile_value
		var weight_value: Variant = profile.get("aggregation_weight", null)
		var infrastructure_value: Variant = profile.get("infrastructure", null)
		if weight_value == null or not infrastructure_value is Dictionary:
			return false
		if typeof(weight_value) != TYPE_FLOAT and typeof(weight_value) != TYPE_INT:
			return false

		var regional_infrastructure: Dictionary = infrastructure_value
		var state := RegionalInfrastructureState.new(
			region.id,
			region.country_id
		)

		if not state.apply_localization(
			country_infrastructure_state,
			float(weight_value),
			regional_infrastructure
		):
			return false

		if not world.add_regional_infrastructure(state):
			return false

	return true


func _build_profile_map(definitions: Array) -> Dictionary:
	var profiles_by_country: Dictionary = {}
	var loader := RegionalInfrastructureDataLoader.new()

	for definition_value in definitions:
		if not definition_value is Dictionary:
			return {}
		var definition: Dictionary = definition_value
		if not loader.validate_infrastructure_profile(definition):
			return {}

		var country_id: String = str(definition.get("country_id", ""))
		if profiles_by_country.has(country_id):
			return {}

		var regional_profiles: Dictionary = {}
		var profiles_value: Variant = definition.get("profiles", [])
		if not profiles_value is Array:
			return {}

		for profile_value in profiles_value as Array:
			if not profile_value is Dictionary:
				return {}
			var profile: Dictionary = profile_value
			var region_id: String = str(profile.get("region_id", ""))
			if region_id.is_empty() or regional_profiles.has(region_id):
				return {}
			regional_profiles[region_id] = profile

		profiles_by_country[country_id] = regional_profiles

	return profiles_by_country


func _validate_profile_map_against_world(
	world: WorldState,
	profiles_by_country: Dictionary
) -> bool:
	var world_country_ids: Dictionary = {}

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		world_country_ids[region.country_id] = true

	for country_id_value in world_country_ids.keys():
		var country_id: String = str(country_id_value)
		if not profiles_by_country.has(country_id):
			return false

		var expected_ids: Dictionary = {}
		for value in world.regions.values():
			var region: Region = value as Region
			if region == null or not region.is_region():
				continue
			if region.country_id == country_id:
				expected_ids[region.id] = true

		var supplied: Dictionary = profiles_by_country[country_id]
		if supplied.size() != expected_ids.size():
			return false

		for expected_region_id in expected_ids.keys():
			if not supplied.has(expected_region_id):
				return false

	for country_id_value in profiles_by_country.keys():
		var country_id: String = str(country_id_value)
		if not world_country_ids.has(country_id):
			return false

	return true


func _validate_source_state(source_state: Dictionary) -> bool:
	var required_keys: Array = [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage",
        "total_capacity"
	]

	for key in required_keys:
		var value: Variant = source_state.get(key, null)
		if value == null:
			return false
		var numeric_type: int = typeof(value)
		if numeric_type != TYPE_FLOAT and numeric_type != TYPE_INT:
			return false
		var numeric_value: float = float(value)
		if numeric_value < 0.0 or numeric_value > 1.0:
			return false

	return true


func _sorted_country_ids(profiles_by_country: Dictionary) -> Array:
	var ids: Array = []
	for country_id in profiles_by_country.keys():
		ids.append(str(country_id))
	ids.sort()
	return ids


func _sorted_country_ids_from_regions(world: WorldState) -> Array:
	var id_map: Dictionary = {}
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		id_map[region.country_id] = true

	var ids: Array = []
	for country_id in id_map.keys():
		ids.append(str(country_id))
	ids.sort()
	return ids


func _sorted_parent_region_ids(
	world: WorldState,
	country_id: String
) -> Array:
	var ids: Array = []
	if world == null:
		return ids

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		if region.country_id == country_id:
			ids.append(region.id)

	ids.sort()
	return ids
