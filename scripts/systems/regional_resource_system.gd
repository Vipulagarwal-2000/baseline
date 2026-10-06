class_name RegionalResourceSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.5
# REGIONAL RESOURCE LOCALIZATION
# ============================================================
#
# Initialization only:
#   country ResourceComponent
#          -> calibration shares
#          -> parent-region RegionalResourceState
#
# The system intentionally does not run regional resource flows in
# Step 12.5. Existing country-level ResourceSystem behavior remains
# authoritative until the later regional authority handoff point.
# ============================================================


const EPSILON: float = 0.000001


func _init() -> void:
	super("regional_resource_system")


func process_month(world: WorldState) -> void:
	# Step 12.5 is a localization/seed layer only.
	if world == null:
		return


func initialize_world(world: WorldState, definitions: Array) -> bool:
	if world == null:
		return false
	if world.get_region_count() <= 0:
		return false
	if world.get_regional_resource_count() > 0:
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

		var resources = country.get_component("resources")
		if resources == null:
			return false

		if not _initialize_country_resources(
			world,
			country_id,
			resources,
			profiles[country_id]
		):
			return false

	return validate_world(world)


func get_resource_state(
	world: WorldState,
	region_id: String
) -> RegionalResourceState:
	if world == null:
		return null
	return world.get_regional_resource(region_id) as RegionalResourceState


func get_resource_snapshot(
	world: WorldState,
	region_id: String
) -> Dictionary:
	var state: RegionalResourceState = get_resource_state(world, region_id)
	if state == null:
		return {}
	return state.to_snapshot_dict()


func get_country_production_total(
	world: WorldState,
	country_id: String
) -> Dictionary:
	var total: Dictionary = {}
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state: RegionalResourceState = get_resource_state(
			world,
			region_id
		)
		if state == null:
			continue
		_add_dictionary_values(total, state.production_by_resource)
	return total


func get_country_reserve_total(
	world: WorldState,
	country_id: String
) -> Dictionary:
	var total: Dictionary = {}
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state: RegionalResourceState = get_resource_state(
			world,
			region_id
		)
		if state == null:
			continue
		_add_dictionary_values(total, state.reserves_by_resource)
	return total


func get_country_stockpile_total(
	world: WorldState,
	country_id: String
) -> Dictionary:
	var total: Dictionary = {}
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state: RegionalResourceState = get_resource_state(
			world,
			region_id
		)
		if state == null:
			continue
		_add_dictionary_values(total, state.stockpile_by_resource)
	return total


func validate_world(world: WorldState) -> bool:
	if world == null:
		return false

	var expected_state_count: int = 0

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			return false

		if region.is_province():
			if world.has_regional_resource(region.id):
				return false
			continue

		if not region.is_region():
			return false

		expected_state_count += 1

		var state: RegionalResourceState = get_resource_state(
			world,
			region.id
		)
		if state == null or not state.is_valid():
			return false

		if state.structural_country_id != region.country_id:
			return false

	if world.get_regional_resource_count() != expected_state_count:
		return false

	# Validate each country's regional allocation against the source
	# baseline captured by the regional state at initialization. This
	# avoids creating a second live authority between this inert seed
	# layer and the country ResourceSystem.
	for country_id in _sorted_country_ids_from_regions(world):
		var region_ids: Array = _sorted_parent_region_ids(
			world,
			country_id
		)
		if region_ids.is_empty():
			return false

		var first_state: RegionalResourceState = get_resource_state(
			world,
			region_ids[0]
		)
		if first_state == null:
			return false

		var source_state: Dictionary = first_state.source_country_resource_state
		if not _validate_source_state(source_state):
			return false

		for region_id in region_ids:
			var state: RegionalResourceState = get_resource_state(
				world,
				region_id
			)
			if state == null:
				return false
			if state.source_country_resource_state != source_state:
				return false

		var source_production: Dictionary = source_state["production"]
		var source_reserves: Dictionary = source_state["reserves"]
		var source_stockpile: Dictionary = source_state["stockpile"]

		var regional_production: Dictionary = get_country_production_total(
			world,
			country_id
		)
		var regional_reserves: Dictionary = get_country_reserve_total(
			world,
			country_id
		)
		var regional_stockpile: Dictionary = get_country_stockpile_total(
			world,
			country_id
		)

		if not _dictionary_reconciles(
			source_production,
			regional_production
		):
			return false

		if not _dictionary_reconciles(
			source_reserves,
			regional_reserves
		):
			return false

		if not _dictionary_reconciles(
			source_stockpile,
			regional_stockpile
		):
			return false

		for region_id in region_ids:
			var state: RegionalResourceState = get_resource_state(
				world,
				region_id
			)
			if state == null:
				return false

			for resource_name in source_production.keys():
				if not state.resource_accessibility.has(resource_name):
					return false
				if not state.local_import_dependency.has(resource_name):
					return false

	return true


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	for country_id in _sorted_country_ids_from_regions(world):
		for region_id in _sorted_parent_region_ids(world, country_id):
			var state: RegionalResourceState = get_resource_state(
				world,
				region_id
			)
			if state != null:
				snapshot[region_id] = state.to_snapshot_dict()

	return snapshot


func _initialize_country_resources(
	world: WorldState,
	country_id: String,
	resource_component,
	country_profiles: Dictionary
) -> bool:
	var region_ids: Array = _sorted_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var production_value: Variant = resource_component.get_state(
		"production",
		{}
	)
	var reserves_value: Variant = resource_component.get_state(
		"reserves",
		{}
	)
	var stockpile_value: Variant = resource_component.get_state(
		"stockpile",
		{}
	)

	if not production_value is Dictionary:
		return false
	if not reserves_value is Dictionary:
		return false
	if not stockpile_value is Dictionary:
		return false

	var country_resource_state: Dictionary = {
		"production": (production_value as Dictionary).duplicate(true),
		"reserves": (reserves_value as Dictionary).duplicate(true),
		"stockpile": (stockpile_value as Dictionary).duplicate(true)
	}

	for region_id in region_ids:
		var region: Region = world.get_region(region_id) as Region
		var profile_value: Variant = country_profiles.get(region_id, null)

		if region == null or not profile_value is Dictionary:
			return false

		var profile: Dictionary = profile_value
		var production_share_value: Variant = profile.get(
			"production_share",
			null
		)
		var reserve_share_value: Variant = profile.get(
			"reserve_share",
			null
		)
		var accessibility_value: Variant = profile.get(
			"resource_accessibility",
			null
		)
		var import_dependency_value: Variant = profile.get(
			"local_import_dependency",
			null
		)
		var stockpile_share: float = float(
			profile.get("stockpile_share", -1.0)
		)

		if not production_share_value is Dictionary:
			return false
		if not reserve_share_value is Dictionary:
			return false
		if not accessibility_value is Dictionary:
			return false
		if not import_dependency_value is Dictionary:
			return false

		var state := RegionalResourceState.new(
			region.id,
			region.country_id
		)

		var localized: bool = state.apply_localization(
			country_resource_state,
			production_share_value as Dictionary,
			reserve_share_value as Dictionary,
			stockpile_share,
			accessibility_value as Dictionary,
			import_dependency_value as Dictionary
		)
		if not localized:
			return false

		if not world.add_regional_resource(state):
			return false

	return true


func _build_profile_map(definitions: Array) -> Dictionary:
	var profiles_by_country: Dictionary = {}
	var loader := RegionalResourceDataLoader.new()

	for definition_value in definitions:
		if not definition_value is Dictionary:
			return {}

		var definition: Dictionary = definition_value
		if not loader.validate_resource_profile(definition):
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
	if not source_state.has("production"):
		return false
	if not source_state.has("reserves"):
		return false
	if not source_state.has("stockpile"):
		return false

	if not source_state["production"] is Dictionary:
		return false
	if not source_state["reserves"] is Dictionary:
		return false
	if not source_state["stockpile"] is Dictionary:
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


func _add_dictionary_values(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = float(target.get(key, 0.0)) + float(source[key])


func _dictionary_reconciles(
	expected: Dictionary,
	actual: Dictionary
) -> bool:
	for key in expected.keys():
		var expected_value: float = maxf(float(expected[key]), 0.0)
		var actual_value: float = float(actual.get(key, 0.0))
		if not is_equal_approx(expected_value, actual_value):
			return false

	for key in actual.keys():
		if not expected.has(key):
			if not is_equal_approx(float(actual[key]), 0.0):
				return false

	return true
