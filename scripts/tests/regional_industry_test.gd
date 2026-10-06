class_name RegionalIndustryTest
extends RefCounted


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section("REGIONALIZATION — STEP 12.7 INDUSTRY TEST")
	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")
	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var system_instance = simulation.get_system("regional_industry_system")
	var system_ok: bool = system_instance != null and system_instance is RegionalIndustrySystem
	TestLogger.write_line("Registered RegionalIndustrySystem available: " + ("PASS" if system_ok else "FAIL"))
	all_passed = all_passed and system_ok
	if not system_ok:
		return false
	var system: RegionalIndustrySystem = system_instance as RegionalIndustrySystem

	var expected_counts: Dictionary = {"china":6,"india":6,"usa":4}
	var registry_ok: bool = world.get_regional_industry_count() == 16
	TestLogger.write_line("Regional industry registry initialized for all parent regions: " + ("PASS" if registry_ok else "FAIL"))
	all_passed = all_passed and registry_ok

	for country_id_value in expected_counts.keys():
		var country_id: String = str(country_id_value)
		var expected: int = int(expected_counts[country_id_value])
		var actual: int = 0
		for value in world.regions.values():
			var region: Region = value as Region
			if region != null and region.is_region() and region.country_id == country_id:
				actual += 1
		var ok: bool = actual == expected
		TestLogger.write_line(country_id.capitalize() + " regional industry count = " + str(expected) + ": " + ("PASS" if ok else "FAIL"))
		all_passed = all_passed and ok

	var source_snapshots: Dictionary = {}
	for country_id_value in ["china","india","usa"]:
		var country_id: String = str(country_id_value)
		var country = world.get_entity(country_id)
		var industry = country.get_component("industry") if country != null else null
		var ok: bool = country != null and industry != null
		TestLogger.write_line(country_id.capitalize() + " industry component available: " + ("PASS" if ok else "FAIL"))
		all_passed = all_passed and ok
		if not ok:
			continue
		var processes: Variant = industry.get_state("processes", {})
		var adoption: Variant = industry.get_state("process_adoption", {})
		var target: Variant = industry.get_state("process_adoption_target", {})
		var rate: Variant = industry.get_state("process_adoption_rate", {})
		if not processes is Dictionary:
			all_passed = false
			continue
		source_snapshots[country_id] = {
			"processes": (processes as Dictionary).duplicate(true),
			"process_adoption": (adoption as Dictionary).duplicate(true) if adoption is Dictionary else {},
			"process_adoption_target": (target as Dictionary).duplicate(true) if target is Dictionary else {},
			"process_adoption_rate": (rate as Dictionary).duplicate(true) if rate is Dictionary else {}
		}

	var reconciliation_ok: bool = true
	for country_id_value in ["china","india","usa"]:
		var country_id: String = str(country_id_value)
		var country_region_ids: Array = []
		for value in world.regions.values():
			var region: Region = value as Region
			if region != null and region.is_region() and region.country_id == country_id:
				country_region_ids.append(region.id)
		country_region_ids.sort()
		if country_region_ids.is_empty():
			reconciliation_ok = false
			continue
		var seeded_state: RegionalIndustryState = system.get_industry_state(world, str(country_region_ids[0]))
		if seeded_state == null or not seeded_state.source_country_industry_state.has("processes"):
			reconciliation_ok = false
			continue
		var seeded_processes: Dictionary = seeded_state.source_country_industry_state["processes"]
		var totals: Dictionary = system.get_country_capacity_total(world, country_id)
		for process_id_value in seeded_processes.keys():
			var process_id: String = str(process_id_value)
			var source_process: Dictionary = seeded_processes[process_id_value] as Dictionary
			var expected_capacity: float = maxf(float(source_process.get("capacity",0.0)),0.0)
			var actual_capacity: float = float(totals.get(process_id,0.0))
			if not is_equal_approx(expected_capacity, actual_capacity):
				reconciliation_ok = false
	TestLogger.write_line("Regional process capacities reconcile exactly to seeded country IndustryComponent: " + ("PASS" if reconciliation_ok else "FAIL"))
	all_passed = all_passed and reconciliation_ok

	var initial_validation: bool = system.validate_world(world)
	TestLogger.write_line("Initial regional industry validation: " + ("PASS" if initial_validation else "FAIL"))
	all_passed = all_passed and initial_validation

	var province_ok: bool = true
	for value in world.regions.values():
		var region: Region = value as Region
		if region != null and region.is_province() and world.has_regional_industry(region.id):
			province_ok = false
	TestLogger.write_line("Province nodes remain without duplicate industry authority: " + ("PASS" if province_ok else "FAIL"))
	all_passed = all_passed and province_ok

	var bounded_ok: bool = true
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		var state: RegionalIndustryState = system.get_industry_state(world, region.id)
		if state == null:
			bounded_ok = false
			continue
		for process_value in state.processes.values():
			if not process_value is Dictionary:
				bounded_ok = false
				continue
			var process: Dictionary = process_value
			var share: float = float(process.get("capacity_share",-1.0))
			var adoption: float = float(process.get("adoption",-1.0))
			if share < 0.0 or share > 1.0 or adoption < 0.0 or adoption > 1.0:
				bounded_ok = false
	TestLogger.write_line("Regional industry capacity shares and adoption remain bounded: " + ("PASS" if bounded_ok else "FAIL"))
	all_passed = all_passed and bounded_ok

	# Cross-layer snapshot preservation.
	var hierarchy_before: Dictionary = {}
	var ownership_before: Dictionary = {}
	var terrain_before: Dictionary = {}
	var population_before: Dictionary = {}
	var resource_before: Dictionary = {}
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue
		hierarchy_before[region.id] = {"country_id":region.country_id,"parent_region_id":region.parent_region_id,"level":region.level,"source_geography_key":region.source_geography_key}
		if world.has_regional_ownership(region.id):
			var ownership: RegionalOwnershipState = world.get_regional_ownership(region.id) as RegionalOwnershipState
			if ownership != null: ownership_before[region.id] = ownership.to_snapshot_dict()
		if world.has_regional_terrain(region.id):
			var terrain: RegionalTerrainState = world.get_regional_terrain(region.id) as RegionalTerrainState
			if terrain != null: terrain_before[region.id] = terrain.to_snapshot_dict()
		if world.has_regional_population(region.id):
			var population: RegionalPopulationState = world.get_regional_population(region.id) as RegionalPopulationState
			if population != null: population_before[region.id] = population.to_snapshot_dict()
		if world.has_regional_resource(region.id):
			var resource_state: RegionalResourceState = world.get_regional_resource(region.id) as RegionalResourceState
			if resource_state != null: resource_before[region.id] = resource_state.to_snapshot_dict()

	var duplicate_rejected: bool = not system.initialize_world(world, [])
	TestLogger.write_line("Second industry initialization is rejected without duplication: " + ("PASS" if duplicate_rejected else "FAIL"))
	all_passed = all_passed and duplicate_rejected

	var snapshot: Dictionary = system.snapshot_world(world)
	var snapshot_isolated: bool = true
	if not snapshot.is_empty():
		var ids: Array = snapshot.keys()
		var first_id: String = str(ids[0])
		var first_snapshot: Dictionary = snapshot[first_id] as Dictionary
		var process_value: Variant = first_snapshot.get("processes", {})
		if process_value is Dictionary and not (process_value as Dictionary).is_empty():
			var process_ids: Array = (process_value as Dictionary).keys()
			var process_id: String = str(process_ids[0])
			var process: Dictionary = (process_value as Dictionary)[process_id] as Dictionary
			var original: float = float(process.get("capacity",0.0))
			process["capacity"] = original + 999999.0
			var live: RegionalIndustryState = system.get_industry_state(world, first_id)
			if live != null and is_equal_approx(float((live.processes[process_id] as Dictionary).get("capacity",0.0)), original + 999999.0):
				snapshot_isolated = false
	TestLogger.write_line("Industry snapshot is isolated from live state: " + ("PASS" if snapshot_isolated else "FAIL"))
	all_passed = all_passed and snapshot_isolated

	var mutation_state: RegionalIndustryState = system.get_industry_state(world, "china_northwest")
	var mutation_ok: bool = mutation_state != null
	var mutation_baseline: Dictionary = {}
	if mutation_state != null:
		mutation_baseline = mutation_state.to_snapshot_dict()
		var mutation_process_ids: Array = mutation_state.processes.keys()
		mutation_process_ids.sort()
		if mutation_process_ids.is_empty():
			mutation_ok = false
		else:
			var mutation_process_id: String = str(mutation_process_ids[0])
			var before_process_value: Variant = mutation_state.processes.get(mutation_process_id, null)
			if not before_process_value is Dictionary:
				mutation_ok = false
			else:
				var before_process: Dictionary = before_process_value
				var original_capacity: float = float(before_process.get("capacity", 0.0))
				mutation_ok = mutation_state.set_process_capacity(
					mutation_process_id,
					original_capacity + 1.0
				)
				var after_process_value: Variant = mutation_state.processes.get(mutation_process_id, null)
				if not after_process_value is Dictionary:
					mutation_ok = false
				else:
					var after_process: Dictionary = after_process_value
					mutation_ok = mutation_ok and is_equal_approx(
						float(after_process.get("capacity", 0.0)),
						original_capacity + 1.0
					)
	TestLogger.write_line("Explicit regional industry mutation changes industry state: " + ("PASS" if mutation_ok else "FAIL"))
	all_passed = all_passed and mutation_ok

	var hierarchy_after: Dictionary = {}
	for value in world.regions.values():
		var region: Region = value as Region
		if region != null:
			hierarchy_after[region.id] = {"country_id":region.country_id,"parent_region_id":region.parent_region_id,"level":region.level,"source_geography_key":region.source_geography_key}
	var hierarchy_ok: bool = hierarchy_before == hierarchy_after
	TestLogger.write_line("Industry mutation does not rewrite region hierarchy: " + ("PASS" if hierarchy_ok else "FAIL"))
	all_passed = all_passed and hierarchy_ok

	if mutation_state != null:
		mutation_state.processes = (mutation_baseline["processes"] as Dictionary).duplicate(true)
		mutation_state.process_adoption = (mutation_baseline["process_adoption"] as Dictionary).duplicate(true)
		mutation_state.process_adoption_target = (mutation_baseline["process_adoption_target"] as Dictionary).duplicate(true)
		mutation_state.process_adoption_rate = (mutation_baseline["process_adoption_rate"] as Dictionary).duplicate(true)
	var restored: bool = mutation_state == null or mutation_state.to_snapshot_dict() == mutation_baseline
	TestLogger.write_line("Industry fixture restores exact baseline: " + ("PASS" if restored else "FAIL"))
	all_passed = all_passed and restored


	# Direct layer comparisons.
	var layers_ok: bool = true
	for id_value in ownership_before.keys():
		var id: String = str(id_value)
		var current: RegionalOwnershipState = world.get_regional_ownership(id) as RegionalOwnershipState
		if current == null or current.to_snapshot_dict() != ownership_before[id]: layers_ok = false
	for id_value in terrain_before.keys():
		var id: String = str(id_value)
		var current: RegionalTerrainState = world.get_regional_terrain(id) as RegionalTerrainState
		if current == null or current.to_snapshot_dict() != terrain_before[id]: layers_ok = false
	for id_value in population_before.keys():
		var id: String = str(id_value)
		var current: RegionalPopulationState = world.get_regional_population(id) as RegionalPopulationState
		if current == null or current.to_snapshot_dict() != population_before[id]: layers_ok = false
	for id_value in resource_before.keys():
		var id: String = str(id_value)
		var current: RegionalResourceState = world.get_regional_resource(id) as RegionalResourceState
		if current == null or current.to_snapshot_dict() != resource_before[id]: layers_ok = false
	TestLogger.write_line("Existing regional ownership/terrain/population/resource state remains unchanged: " + ("PASS" if layers_ok else "FAIL"))
	all_passed = all_passed and layers_ok

	var country_sources_preserved: bool = true
	for country_id_value in source_snapshots.keys():
		var country_id: String = str(country_id_value)
		var country = world.get_entity(country_id)
		var industry = country.get_component("industry") if country != null else null
		if industry == null:
			country_sources_preserved = false
			continue
		var current_state: Dictionary = system._source_snapshot(country_id, world)
		if current_state != source_snapshots[country_id]:
			country_sources_preserved = false
	TestLogger.write_line("Country IndustryComponent remains authoritative and unchanged: " + ("PASS" if country_sources_preserved else "FAIL"))
	all_passed = all_passed and country_sources_preserved

	var before_month: Dictionary = system.snapshot_world(world)
	system.process_month(world)
	var after_month: Dictionary = system.snapshot_world(world)
	var inert: bool = before_month == after_month
	TestLogger.write_line("Step 12.7 monthly processing remains inert: " + ("PASS" if inert else "FAIL"))
	all_passed = all_passed and inert

	var final_validation: bool = system.validate_world(world)
	TestLogger.write_line("Final regional industry validation: " + ("PASS" if final_validation else "FAIL"))
	all_passed = all_passed and final_validation
	TestLogger.write_line("Regionalization 12.7 overall: " + ("PASS" if all_passed else "FAIL"))
	return all_passed
