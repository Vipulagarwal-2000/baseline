class_name RegionalTerrainSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.3
# REGIONAL TERRAIN SYSTEM
# ============================================================
#
# Terrain is localized here, not copied into Country entities and not
# written into Region metadata as a second authority.
#
# Regions use an explicit terrain profile. Provinces inherit their
# parent region profile in this MVP unless a future province-specific
# override is provided.
#
# Monthly simulation is intentionally inert in 12.3. Later systems can
# consume the terrain state without creating another terrain authority.
# ============================================================


func _init() -> void:
	super("regional_terrain_system")


func process_month(world: WorldState) -> void:
	# Terrain is static seed state in this step. Damage/reconstruction
	# and dynamic physical consequences belong to later branches.
	if world == null:
		return


func initialize_world(
	world: WorldState,
	definitions: Array
) -> bool:
	if world == null:
		return false

	if world.get_region_count() <= 0:
		return false

	if world.get_regional_terrain_count() > 0:
		return false

	var profiles := _build_profile_map(definitions)
	if profiles.is_empty():
		return false

	for region_id in _sorted_region_ids(world):
		if not _initialize_region_from_profiles(world, region_id, profiles):
			return false

	return validate_world(world)


func initialize_region(
	world: WorldState,
	region_id: String,
	definitions: Array
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if world.has_regional_terrain(region_id):
		return false

	var profiles := _build_profile_map(definitions)
	if profiles.is_empty():
		return false

	return _initialize_region_from_profiles(
		world,
		region_id,
		profiles
	)


func get_terrain_state(
	world: WorldState,
	region_id: String
) -> RegionalTerrainState:
	if world == null:
		return null

	return world.get_regional_terrain(region_id) as RegionalTerrainState


func get_terrain_snapshot(
	world: WorldState,
	region_id: String
) -> Dictionary:
	var state := get_terrain_state(world, region_id)
	if state == null:
		return {}

	return state.to_snapshot_dict()


func validate_world(world: WorldState) -> bool:
	if world == null:
		return false

	if world.get_regional_terrain_count() != world.get_region_count():
		return false

	for region_id in _sorted_region_ids(world):
		var region := world.get_region(region_id) as Region
		var terrain := world.get_regional_terrain(region_id) as RegionalTerrainState

		if region == null or terrain == null:
			return false

		if not terrain.is_valid():
			return false

		if terrain.region_id != region.id:
			return false

		if terrain.structural_country_id != region.country_id:
			return false

		if region.is_region():
			if terrain.source_profile_id != region.id:
				return false

			if terrain.inherited_from_parent:
				return false
		else:
			if terrain.source_profile_id != region.parent_region_id:
				return false

			if not terrain.inherited_from_parent:
				return false

			if not world.has_region(region.parent_region_id):
				return false

	return true


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	for region_id in _sorted_region_ids(world):
		var state := get_terrain_state(world, region_id)
		if state == null:
			continue

		snapshot[region_id] = state.to_snapshot_dict()

	return snapshot


func _initialize_region_from_profiles(
	world: WorldState,
	region_id: String,
	profiles: Dictionary
) -> bool:
	var region := world.get_region(region_id) as Region
	if region == null:
		return false

	var source_profile_id := region.id
	var inherited := false

	if region.is_province():
		source_profile_id = region.parent_region_id
		inherited = true
	elif not region.is_region():
		return false

	var profile_value = profiles.get(region.country_id, {})
	if typeof(profile_value) != TYPE_DICTIONARY:
		return false

	var country_profiles: Dictionary = profile_value
	var profile = country_profiles.get(source_profile_id, null)
	if typeof(profile) != TYPE_DICTIONARY:
		return false

	var terrain_data = profile.get("terrain", null)
	if typeof(terrain_data) != TYPE_DICTIONARY:
		return false

	var terrain_state := RegionalTerrainState.new(
		region.id,
		region.country_id,
		source_profile_id,
		inherited
	)

	if not terrain_state.apply_profile(terrain_data):
		return false

	return world.add_regional_terrain(terrain_state)


func _build_profile_map(definitions: Array) -> Dictionary:
	var profiles_by_country: Dictionary = {}

	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			return {}

		var definition: Dictionary = definition_value
		var country_id := str(definition.get("country_id", ""))
		var profiles = definition.get("profiles", null)

		if country_id.is_empty() or typeof(profiles) != TYPE_ARRAY:
			return {}

		if profiles_by_country.has(country_id):
			return {}

		var country_profiles: Dictionary = {}
		for profile_value in profiles:
			if typeof(profile_value) != TYPE_DICTIONARY:
				return {}

			var profile: Dictionary = profile_value
			var region_id := str(profile.get("region_id", ""))
			if region_id.is_empty() or country_profiles.has(region_id):
				return {}

			country_profiles[region_id] = profile

		if country_profiles.is_empty():
			return {}

		profiles_by_country[country_id] = country_profiles

	return profiles_by_country


func _sorted_region_ids(world: WorldState) -> Array[String]:
	var ids: Array[String] = []
	if world == null:
		return ids

	for key in world.regions.keys():
		ids.append(str(key))

	ids.sort()
	return ids
