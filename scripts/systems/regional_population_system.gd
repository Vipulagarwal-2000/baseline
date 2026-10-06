class_name RegionalPopulationSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.4
# REGIONAL POPULATION LOCALIZATION
# ============================================================
#
# Step 12.4 seeds the current authoritative country population
# into the broad parent regions established by Step 12.1.
#
# Country-level demographic/migration systems remain authoritative.
# This system is a localization/bootstrap layer and is intentionally
# inert during monthly processing.
#
# Parent regions carry the Step 12.4 population authority.
# Child province/state nodes do not receive an independent population
# count yet, preventing parent/child double counting.
# ============================================================


const EPSILON: float = 0.000001


func _init() -> void:
	super("regional_population_system")


func process_month(
	world: WorldState
) -> void:
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
	if world.get_regional_population_count() > 0:
		return false

	var profiles := _build_profile_map(definitions)
	if profiles.is_empty():
		return false

	if not _validate_profile_map_against_world(world, profiles):
		return false

	for country_id in _sorted_country_ids(profiles):
		var country = world.get_entity(country_id)
		if country == null:
			return false

		var population_component = country.get_component("population")
		if population_component == null:
			return false

		if not _initialize_country_population(
			world,
			country_id,
			population_component,
			profiles[country_id]
		):
			return false

	return validate_world(world)


func get_population_state(
	world: WorldState,
	region_id: String
) -> RegionalPopulationState:
	if world == null:
		return null
	return world.get_regional_population(region_id) as RegionalPopulationState


func get_population_snapshot(
	world: WorldState,
	region_id: String
) -> Dictionary:
	var state := get_population_state(world, region_id)
	if state == null:
		return {}
	return state.to_snapshot_dict()


func get_country_population_total(
	world: WorldState,
	country_id: String
) -> float:
	var total := 0.0
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state := get_population_state(world, region_id)
		if state != null:
			total += state.population
	return total


func get_country_migration_in_total(
	world: WorldState,
	country_id: String
) -> float:
	var total := 0.0
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state := get_population_state(world, region_id)
		if state != null:
			total += state.migration_in
	return total


func get_country_migration_out_total(
	world: WorldState,
	country_id: String
) -> float:
	var total := 0.0
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state := get_population_state(world, region_id)
		if state != null:
			total += state.migration_out
	return total


func validate_world(
	world: WorldState
) -> bool:
	if world == null:
		return false

	var parent_region_ids_by_country: Dictionary = {}

	for value in world.regions.values():
		var region := value as Region
		if region == null:
			return false

		if region.is_province():
			if world.has_regional_population(region.id):
				return false
			continue

		if not region.is_region():
			return false

		if not parent_region_ids_by_country.has(region.country_id):
			parent_region_ids_by_country[region.country_id] = []

		parent_region_ids_by_country[region.country_id].append(region.id)

	var expected_state_count := 0

	for country_id in parent_region_ids_by_country.keys():
		var region_ids: Array = parent_region_ids_by_country[country_id]
		expected_state_count += region_ids.size()

		var country = world.get_entity(country_id)
		if country == null:
			return false

		var population = country.get_component("population")
		if population == null:
			return false

		var country_population := maxf(
			float(population.get_state("population", 0.0)),
			0.0
		)
		var country_immigration := maxf(
			float(population.get_state(
				"immigration",
				population.get_state("base_immigration", 0.0)
			)),
			0.0
		)
		var country_emigration := maxf(
			float(population.get_state(
				"emigration",
				population.get_state("base_emigration", 0.0)
			)),
			0.0
		)
		var country_urbanization := maxf(
			float(population.get_state("urbanization", 0.0)),
			0.0
		)

		var population_total := 0.0
		var migration_in_total := 0.0
		var migration_out_total := 0.0
		var share_total := 0.0
		var weighted_urbanization := 0.0

		for region_id in region_ids:
			var region := world.get_region(region_id) as Region
			var state := get_population_state(world, region_id)

			if region == null or state == null:
				return false

			if state.structural_country_id != region.country_id:
				return false
			if not state.is_valid():
				return false

			share_total += state.allocation_share
			population_total += state.population
			migration_in_total += state.migration_in
			migration_out_total += state.migration_out
			weighted_urbanization += state.population * state.urbanization

			if not is_equal_approx(
				state.population,
				country_population * state.allocation_share
			):
				return false

		if not is_equal_approx(share_total, 1.0):
			return false
		if not is_equal_approx(population_total, country_population):
			return false
		if not is_equal_approx(migration_in_total, country_immigration):
			return false
		if not is_equal_approx(migration_out_total, country_emigration):
			return false

		var weighted_average_urbanization := 0.0
		if population_total > EPSILON:
			weighted_average_urbanization = weighted_urbanization / population_total

		if not is_equal_approx(
			weighted_average_urbanization,
			country_urbanization
		):
			return false

	return (
		world.get_regional_population_count()
		== expected_state_count
	)


func snapshot_world(
	world: WorldState
) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	for country_id in _sorted_country_ids_from_world(world):
		for region_id in _sorted_parent_region_ids(world, country_id):
			var state := get_population_state(world, region_id)
			if state != null:
				snapshot[region_id] = state.to_snapshot_dict()

	return snapshot


func _initialize_country_population(
	world: WorldState,
	country_id: String,
	population_component,
	country_profiles: Dictionary
) -> bool:
	var region_ids := _sorted_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	for region_id in region_ids:
		var region := world.get_region(region_id) as Region
		var profile = country_profiles.get(region_id, null)

		if region == null or typeof(profile) != TYPE_DICTIONARY:
			return false

		var share := float(profile.get("population_share", -1.0))
		var urbanization := float(profile.get("urbanization", -1.0))

		if share < 0.0 or share > 1.0 or urbanization < 0.0:
			return false

		var country_population := maxf(
			float(population_component.get_state("population", 0.0)),
			0.0
		)
		var country_growth_rate := maxf(
			float(population_component.get_state("growth_rate", 0.0)),
			0.0
		)
		var country_birth_rate := maxf(
			float(population_component.get_state("birth_rate", 0.0)),
			0.0
		)
		var country_death_rate := maxf(
			float(population_component.get_state("death_rate", 0.0)),
			0.0
		)
		var country_immigration := maxf(
			float(population_component.get_state(
				"immigration",
				population_component.get_state("base_immigration", 0.0)
			)),
			0.0
		)
		var country_emigration := maxf(
			float(population_component.get_state(
				"emigration",
				population_component.get_state("base_emigration", 0.0)
			)),
			0.0
		)

		var state := RegionalPopulationState.new(
			region.id,
			region.country_id
		)

		if not state.apply_localization(
			country_population,
			share,
			urbanization,
			country_growth_rate,
			country_birth_rate,
			country_death_rate,
			country_immigration * share,
			country_emigration * share
		):
			return false

		if not world.add_regional_population(state):
			return false

	return true


func _validate_profile_map_against_world(
	world: WorldState,
	profiles_by_country: Dictionary
) -> bool:
	var country_ids: Dictionary = {}

	for value in world.regions.values():
		var region := value as Region
		if region == null or not region.is_region():
			continue
		country_ids[region.country_id] = true

	for country_id in country_ids.keys():
		if not profiles_by_country.has(country_id):
			return false

		var expected_ids: Dictionary = {}
		for value in world.regions.values():
			var region := value as Region
			if region == null or not region.is_region():
				continue
			if region.country_id == country_id:
				expected_ids[region.id] = true

		var supplied_profiles: Dictionary = profiles_by_country[country_id]
		if supplied_profiles.size() != expected_ids.size():
			return false

		for region_id in expected_ids.keys():
			if not supplied_profiles.has(region_id):
				return false

	for country_id in profiles_by_country.keys():
		if not country_ids.has(country_id):
			return false

	return true


func _build_profile_map(
	definitions: Array
) -> Dictionary:
	var profiles_by_country: Dictionary = {}

	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			return {}

		var definition: Dictionary = definition_value
		if not RegionalPopulationDataLoader.new().validate_population_profile(definition):
			return {}

		var country_id := str(definition.get("country_id", ""))
		if profiles_by_country.has(country_id):
			return {}

		var country_profiles: Dictionary = {}
		for profile_value in definition.get("profiles", []):
			var profile: Dictionary = profile_value
			country_profiles[str(profile.get("region_id", ""))] = profile

		profiles_by_country[country_id] = country_profiles

	return profiles_by_country


func _sorted_country_ids(
	profiles: Dictionary
) -> Array[String]:
	var ids: Array[String] = []
	for key in profiles.keys():
		ids.append(str(key))
	ids.sort()
	return ids


func _sorted_country_ids_from_world(
	world: WorldState
) -> Array[String]:
	var ids: Array[String] = []
	if world == null:
		return ids

	for value in world.entities.values():
		if value == null:
			continue
		var entity_type := str(value.entity_type)
		if entity_type == "country":
			ids.append(str(value.id))

	ids.sort()
	return ids


func _sorted_parent_region_ids(
	world: WorldState,
	country_id: String
) -> Array[String]:
	var ids: Array[String] = []
	if world == null:
		return ids

	for value in world.regions.values():
		var region := value as Region
		if region == null or not region.is_region():
			continue

		if not country_id.is_empty() and region.country_id != country_id:
			continue

		ids.append(region.id)

	ids.sort()
	return ids
