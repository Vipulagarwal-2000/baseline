class_name RegionalIndustrySystem
extends SimulationSystem

const EPSILON: float = 0.000001


func _init() -> void:
	super("regional_industry_system")


func process_month(world: WorldState) -> void:
	# Step 12.7 is localization/seed only. Existing country ProductionProcessSystem
	# and IndustryComponent remain the active monthly authorities until Step 12.9.
	if world == null:
		return


func initialize_world(world: WorldState, definitions: Array) -> bool:
	if world == null or world.get_region_count() <= 0:
		return false
	if world.get_regional_industry_count() > 0:
		return false
	var profiles: Dictionary = _build_profile_map(definitions)
	if profiles.is_empty() or not _validate_profile_map_against_world(world, profiles):
		return false
	var catalog := ProductionProcessCatalog.new()
	for country_id in _sorted_country_ids(profiles):
		var country = world.get_entity(country_id)
		if country == null:
			return false
		var industry = country.get_component("industry")
		if industry == null:
			return false
		var processes_value: Variant = industry.get_state("processes", {})
		if not processes_value is Dictionary:
			return false
		var definitions_for_country: Dictionary = {}
		for process_id_value in (processes_value as Dictionary).keys():
			var process_id: String = str(process_id_value)
			var definition: Dictionary = catalog.get_process(process_id)
			definitions_for_country[process_id] = definition
		if not _initialize_country_industry(world, country_id, industry, definitions_for_country, profiles[country_id]):
			return false
	return validate_world(world)


func get_industry_state(world: WorldState, region_id: String) -> RegionalIndustryState:
	if world == null:
		return null
	return world.get_regional_industry(region_id) as RegionalIndustryState


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot
	for country_id in _sorted_country_ids_from_regions(world):
		for region_id in _sorted_parent_region_ids(world, country_id):
			var state: RegionalIndustryState = get_industry_state(world, region_id)
			if state != null:
				snapshot[region_id] = state.to_snapshot_dict()
	return snapshot


func get_country_capacity_total(world: WorldState, country_id: String) -> Dictionary:
	var totals: Dictionary = {}
	for region_id in _sorted_parent_region_ids(world, country_id):
		var state: RegionalIndustryState = get_industry_state(world, region_id)
		if state == null:
			continue
		for process_id_value in state.processes.keys():
			var process_id: String = str(process_id_value)
			var process_value: Variant = state.processes[process_id_value]
			if not process_value is Dictionary:
				continue
			var process: Dictionary = process_value
			totals[process_id] = float(totals.get(process_id, 0.0)) + float(process.get("capacity", 0.0))
	return totals


func validate_world(world: WorldState) -> bool:
	if world == null:
		return false
	var expected_state_count: int = 0
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			return false
		if region.is_province():
			if world.has_regional_industry(region.id):
				return false
			continue
		if not region.is_region():
			return false
		expected_state_count += 1
		var state: RegionalIndustryState = get_industry_state(world, region.id)
		if state == null or not state.is_valid():
			return false
		if state.structural_country_id != region.country_id:
			return false
	if world.get_regional_industry_count() != expected_state_count:
		return false

	for country_id in _sorted_country_ids_from_regions(world):
		var region_ids: Array = _sorted_parent_region_ids(world, country_id)
		if region_ids.is_empty():
			return false
		var first_state: RegionalIndustryState = get_industry_state(world, region_ids[0])
		if first_state == null:
			return false
		var seeded_source: Dictionary = first_state.source_country_industry_state
		if not seeded_source.has("processes") or not seeded_source["processes"] is Dictionary:
			return false
		var seeded_processes: Dictionary = seeded_source["processes"]
		var regional_capacity: Dictionary = get_country_capacity_total(world, country_id)
		for process_id_value in seeded_processes.keys():
			var process_id: String = str(process_id_value)
			var source_value: Variant = seeded_processes[process_id_value]
			if not source_value is Dictionary:
				return false
			var source_process: Dictionary = source_value
			var expected_capacity: float = maxf(float(source_process.get("capacity", 0.0)), 0.0)
			var actual_capacity: float = float(regional_capacity.get(process_id, 0.0))
			if not is_equal_approx(expected_capacity, actual_capacity):
				return false

		for region_id in region_ids:
			var state: RegionalIndustryState = get_industry_state(world, region_id)
			if state == null or state.source_country_industry_state != seeded_source:
				return false
	return true


func _source_snapshot(country_id: String, world: WorldState) -> Dictionary:
	var country = world.get_entity(country_id)
	if country == null:
		return {}
	var industry = country.get_component("industry")
	if industry == null:
		return {}
	var processes: Variant = industry.get_state("processes", {})
	var adoption: Variant = industry.get_state("process_adoption", {})
	var target: Variant = industry.get_state("process_adoption_target", {})
	var rate: Variant = industry.get_state("process_adoption_rate", {})
	return {
		"processes": processes.duplicate(true) if processes is Dictionary else {},
		"process_adoption": adoption.duplicate(true) if adoption is Dictionary else {},
		"process_adoption_target": target.duplicate(true) if target is Dictionary else {},
		"process_adoption_rate": rate.duplicate(true) if rate is Dictionary else {}
	}


func _initialize_country_industry(world: WorldState, country_id: String, industry, process_definitions: Dictionary, country_profiles: Dictionary) -> bool:
	var region_ids: Array = _sorted_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false
	var processes_value: Variant = industry.get_state("processes", {})
	var adoption_value: Variant = industry.get_state("process_adoption", {})
	var target_value: Variant = industry.get_state("process_adoption_target", {})
	var rate_value: Variant = industry.get_state("process_adoption_rate", {})
	if not processes_value is Dictionary:
		return false
	var source_state: Dictionary = {
		"processes": (processes_value as Dictionary).duplicate(true),
		"process_adoption": (adoption_value as Dictionary).duplicate(true) if adoption_value is Dictionary else {},
		"process_adoption_target": (target_value as Dictionary).duplicate(true) if target_value is Dictionary else {},
		"process_adoption_rate": (rate_value as Dictionary).duplicate(true) if rate_value is Dictionary else {}
	}
	for region_id in region_ids:
		var region: Region = world.get_region(region_id) as Region
		var profile_value: Variant = country_profiles.get(region_id, null)
		if region == null or not profile_value is Dictionary:
			return false
		var profile: Dictionary = profile_value
		var shares_value: Variant = profile.get("capacity_share_by_process", null)
		if not shares_value is Dictionary:
			return false
		var state := RegionalIndustryState.new(region.id, region.country_id)
		if not state.apply_localization(source_state, process_definitions, shares_value as Dictionary):
			return false
		if not world.add_regional_industry(state):
			return false
	return true


func _build_profile_map(definitions: Array) -> Dictionary:
	var profiles_by_country: Dictionary = {}
	var loader := RegionalIndustryDataLoader.new()
	for definition_value in definitions:
		if not definition_value is Dictionary:
			return {}
		var definition: Dictionary = definition_value
		if not loader.validate_industry_profile(definition):
			return {}
		var country_id: String = str(definition.get("country_id", ""))
		if profiles_by_country.has(country_id):
			return {}
		var regional_profiles: Dictionary = {}
		var profiles_value: Variant = definition.get("profiles", [])
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


func _validate_profile_map_against_world(world: WorldState, profiles_by_country: Dictionary) -> bool:
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
		if not world_country_ids.has(str(country_id_value)):
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


func _sorted_parent_region_ids(world: WorldState, country_id: String) -> Array:
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
