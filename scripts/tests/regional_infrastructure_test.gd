class_name RegionalInfrastructureTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.6 TEST
# REGIONAL INFRASTRUCTURE LOCALIZATION
# ============================================================
#
# Validates:
# - system registration
# - parent-region-only authority
# - weighted country reconstruction
# - source-state preservation
# - component bounds
# - derived total capacity
# - duplicate initialization protection
# - snapshot isolation
# - mutation/restoration
# - hierarchy preservation
# - preservation of 12.2 ownership, 12.3 terrain,
#   12.4 population and 12.5 resource state
# - inert monthly processing
# - final validation
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section("REGIONALIZATION — STEP 12.6 INFRASTRUCTURE TEST")

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var system_instance = simulation.get_system("regional_infrastructure_system")
	var system_ok: bool = (
		system_instance != null
		and system_instance is RegionalInfrastructureSystem
	)
	TestLogger.write_line(
		"Registered RegionalInfrastructureSystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)
	all_passed = all_passed and system_ok
	if not system_ok:
		return false

	var system: RegionalInfrastructureSystem = (
		system_instance as RegionalInfrastructureSystem
	)

	var expected_parent_regions: Dictionary = {
		"china": 6,
		"india": 6,
		"usa": 4
	}
	var expected_registry_total: int = 16

	var registry_ok: bool = (
		world.get_regional_infrastructure_count() == expected_registry_total
	)
	TestLogger.write_line(
		"Regional infrastructure registry initialized for all parent regions: "
		+ ("PASS" if registry_ok else "FAIL")
	)
	all_passed = all_passed and registry_ok

	for country_id_value in expected_parent_regions.keys():
		var country_id: String = str(country_id_value)
		var expected_count: int = int(expected_parent_regions[country_id])
		var actual_count: int = 0
		for value in world.regions.values():
			var region: Region = value as Region
			if region == null:
				continue
			if region.is_region() and region.country_id == country_id:
				actual_count += 1

		var count_ok: bool = actual_count == expected_count
		TestLogger.write_line(
			country_id.capitalize()
			+ " regional infrastructure count = "
			+ str(expected_count)
			+ ": "
			+ ("PASS" if count_ok else "FAIL")
		)
		all_passed = all_passed and count_ok

	# ------------------------------------------------------------
	# Country source state and cross-layer snapshots.
	# ------------------------------------------------------------
	var country_sources: Dictionary = {}
	for country_id in ["china", "india", "usa"]:
		var country = world.get_entity(country_id)
		var infrastructure = null
		if country != null:
			infrastructure = country.get_component("infrastructure")

		var source_ok: bool = country != null and infrastructure != null
		TestLogger.write_line(
			country_id.capitalize()
			+ " infrastructure component available: "
			+ ("PASS" if source_ok else "FAIL")
		)
		all_passed = all_passed and source_ok

		if not source_ok:
			continue

		var source: Dictionary = {}
		for key in [
			"transport",
			"railways",
			"roads",
			"ports",
			"power",
			"industrial",
			"storage",
			"total_capacity"
		]:
			var value: Variant = infrastructure.get_state(key, null)
			if value == null:
				source_ok = false
				break
			source[key] = float(value)

		if source_ok:
			country_sources[country_id] = source

	var hierarchy_before: Dictionary = {}
	var ownership_before: Dictionary = {}
	var terrain_before: Dictionary = {}
	var population_before: Dictionary = {}
	var resource_before: Dictionary = {}

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue

		hierarchy_before[region.id] = {
			"country_id": region.country_id,
			"parent_region_id": region.parent_region_id,
			"level": region.level,
			"source_geography_key": region.source_geography_key
		}

		if world.has_regional_ownership(region.id):
			var ownership: RegionalOwnershipState = (
				world.get_regional_ownership(region.id)
				as RegionalOwnershipState
			)
			if ownership != null:
				ownership_before[region.id] = ownership.to_snapshot_dict()

		if world.has_regional_terrain(region.id):
			var terrain: RegionalTerrainState = (
				world.get_regional_terrain(region.id)
				as RegionalTerrainState
			)
			if terrain != null:
				terrain_before[region.id] = terrain.to_snapshot_dict()

		if world.has_regional_population(region.id):
			var population: RegionalPopulationState = (
				world.get_regional_population(region.id)
				as RegionalPopulationState
			)
			if population != null:
				population_before[region.id] = population.to_snapshot_dict()

		if world.has_regional_resource(region.id):
			var resource: RegionalResourceState = (
				world.get_regional_resource(region.id)
				as RegionalResourceState
			)
			if resource != null:
				resource_before[region.id] = resource.to_snapshot_dict()

	# ------------------------------------------------------------
	# Seed-source and weighted reconstruction.
	# ------------------------------------------------------------
	var reconstruction_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var region_ids: Array = _parent_region_ids(world, country_id)
		if region_ids.is_empty():
			reconstruction_ok = false
			continue

		var first_state: RegionalInfrastructureState = system.get_infrastructure_state(
			world,
			region_ids[0]
		)
		if first_state == null:
			reconstruction_ok = false
			continue

		var source_state: Dictionary = first_state.source_country_infrastructure_state
		var weight_total: float = 0.0
		for region_id in region_ids:
			var state: RegionalInfrastructureState = system.get_infrastructure_state(
				world,
				region_id
			)
			if state == null:
				reconstruction_ok = false
				continue

			weight_total += state.aggregation_weight
			if state.source_country_infrastructure_state != source_state:
				reconstruction_ok = false

		var regional_average: Dictionary = system.get_country_infrastructure_average(
			world,
			country_id
		)

		for key in [
			"transport",
			"railways",
			"roads",
			"ports",
			"power",
			"industrial",
			"storage"
		]:
			if not is_equal_approx(
				float(source_state[key]),
				float(regional_average.get(key, -999.0))
			):
				reconstruction_ok = false

		if not is_equal_approx(
			first_state.derived_source_total_capacity,
			float(regional_average.get("total_capacity", -999.0))
		):
			reconstruction_ok = false

		if not is_equal_approx(weight_total, 1.0):
			reconstruction_ok = false

	TestLogger.write_line(
		"Regional weighted infrastructure reconstructs seeded country baseline: "
		+ ("PASS" if reconstruction_ok else "FAIL")
	)
	all_passed = all_passed and reconstruction_ok

	var total_capacity_derivation_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var region_ids: Array = _parent_region_ids(world, country_id)
		if region_ids.is_empty():
			total_capacity_derivation_ok = false
			continue
		var first_state: RegionalInfrastructureState = system.get_infrastructure_state(
			world,
			region_ids[0]
		)
		if first_state == null:
			total_capacity_derivation_ok = false
			continue
		var expected_source_total_capacity: float = (
			float(first_state.source_country_infrastructure_state["transport"])
			+ float(first_state.source_country_infrastructure_state["railways"])
			+ float(first_state.source_country_infrastructure_state["roads"])
			+ float(first_state.source_country_infrastructure_state["ports"])
			+ float(first_state.source_country_infrastructure_state["power"])
			+ float(first_state.source_country_infrastructure_state["industrial"])
			+ float(first_state.source_country_infrastructure_state["storage"])
		) / 7.0
		if not is_equal_approx(
			expected_source_total_capacity,
			first_state.derived_source_total_capacity
		):
			total_capacity_derivation_ok = false

	TestLogger.write_line(
		"Country total_capacity is treated as a derived seven-dimension infrastructure value: "
		+ ("PASS" if total_capacity_derivation_ok else "FAIL")
	)
	all_passed = all_passed and total_capacity_derivation_ok

	# ------------------------------------------------------------
	# Bounds, derived capacity, province boundary.
	# ------------------------------------------------------------
	var bounds_ok: bool = true
	var total_capacity_ok: bool = true
	var province_authority_ok: bool = true

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue

		if region.is_province():
			if world.has_regional_infrastructure(region.id):
				province_authority_ok = false
			continue

		if not region.is_region():
			continue

		var state: RegionalInfrastructureState = system.get_infrastructure_state(
			world,
			region.id
		)
		if state == null:
			bounds_ok = false
			total_capacity_ok = false
			continue

		for component_value in [
			state.transport,
			state.railways,
			state.roads,
			state.ports,
			state.power,
			state.industrial,
			state.storage,
			state.total_capacity
		]:
			var component: float = float(component_value)
			if component < 0.0 or component > 1.0:
				bounds_ok = false

		var expected_regional_total_capacity: float = (
			state.transport
			+ state.railways
			+ state.roads
			+ state.ports
			+ state.power
			+ state.industrial
			+ state.storage
		) / 7.0
		if not is_equal_approx(expected_regional_total_capacity, state.total_capacity):
			total_capacity_ok = false

	TestLogger.write_line(
		"Regional infrastructure dimensions remain bounded 0..1: "
		+ ("PASS" if bounds_ok else "FAIL")
	)
	TestLogger.write_line(
		"Regional total capacity is derived from seven infrastructure dimensions: "
		+ ("PASS" if total_capacity_ok else "FAIL")
	)
	TestLogger.write_line(
		"Province nodes remain without duplicate infrastructure authority: "
		+ ("PASS" if province_authority_ok else "FAIL")
	)
	all_passed = all_passed and bounds_ok and total_capacity_ok and province_authority_ok

	# ------------------------------------------------------------
	# Initial validation.
	# ------------------------------------------------------------
	var initial_validation: bool = system.validate_world(world)
	TestLogger.write_line(
		"Initial regional infrastructure validation: "
		+ ("PASS" if initial_validation else "FAIL")
	)
	all_passed = all_passed and initial_validation

	# ------------------------------------------------------------
	# Duplicate initialization.
	# ------------------------------------------------------------
	var duplicate_rejected: bool = not system.initialize_world(world, [])
	TestLogger.write_line(
		"Second infrastructure initialization is rejected without duplication: "
		+ ("PASS" if duplicate_rejected else "FAIL")
	)
	all_passed = all_passed and duplicate_rejected

	# ------------------------------------------------------------
	# Snapshot isolation.
	# ------------------------------------------------------------
	var snapshot: Dictionary = system.snapshot_world(world)
	var snapshot_isolated: bool = true
	if not snapshot.is_empty():
		var snapshot_keys: Array = snapshot.keys()
		var first_id: String = str(snapshot_keys[0])
		var first_snapshot: Dictionary = snapshot[first_id]
		var snapshot_value: float = float(first_snapshot.get("transport", -1.0))
		first_snapshot["transport"] = snapshot_value + 0.25

		var live_state: RegionalInfrastructureState = system.get_infrastructure_state(
			world,
			first_id
		)
		if live_state != null and not is_equal_approx(
			live_state.transport,
			snapshot_value
		):
			snapshot_isolated = false

	TestLogger.write_line(
		"Infrastructure snapshot is isolated from live state: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated

	# ------------------------------------------------------------
	# Explicit mutation fixture.
	# ------------------------------------------------------------
	var mutation_region_id: String = "china_northwest"
	var mutation_state: RegionalInfrastructureState = (
		system.get_infrastructure_state(world, mutation_region_id)
	)
	var mutation_ok: bool = mutation_state != null
	var mutation_baseline: Dictionary = {}

	if mutation_state != null:
		mutation_baseline = mutation_state.to_snapshot_dict()
		var new_roads: float = minf(
			1.0,
			mutation_state.roads + 0.05
		)
		mutation_state.roads = new_roads
		mutation_state.total_capacity = (
			mutation_state.transport
			+ mutation_state.railways
			+ mutation_state.roads
			+ mutation_state.ports
			+ mutation_state.power
			+ mutation_state.industrial
			+ mutation_state.storage
		) / 7.0

		mutation_ok = mutation_ok and (
			mutation_state.roads > float(mutation_baseline["roads"])
		)

	TestLogger.write_line(
		"Explicit regional infrastructure mutation changes infrastructure state: "
		+ ("PASS" if mutation_ok else "FAIL")
	)
	all_passed = all_passed and mutation_ok

	var hierarchy_after_mutation: Dictionary = {}
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue
		hierarchy_after_mutation[region.id] = {
			"country_id": region.country_id,
			"parent_region_id": region.parent_region_id,
			"level": region.level,
			"source_geography_key": region.source_geography_key
		}

	var hierarchy_preserved: bool = (
		hierarchy_before == hierarchy_after_mutation
	)
	TestLogger.write_line(
		"Infrastructure mutation does not rewrite region hierarchy: "
		+ ("PASS" if hierarchy_preserved else "FAIL")
	)
	all_passed = all_passed and hierarchy_preserved

	if mutation_state != null:
		mutation_state.transport = float(mutation_baseline["transport"])
		mutation_state.railways = float(mutation_baseline["railways"])
		mutation_state.roads = float(mutation_baseline["roads"])
		mutation_state.ports = float(mutation_baseline["ports"])
		mutation_state.power = float(mutation_baseline["power"])
		mutation_state.industrial = float(mutation_baseline["industrial"])
		mutation_state.storage = float(mutation_baseline["storage"])
		mutation_state.total_capacity = float(mutation_baseline["total_capacity"])

	var fixture_restored: bool = true
	if mutation_state != null:
		fixture_restored = mutation_state.to_snapshot_dict() == mutation_baseline

	TestLogger.write_line(
		"Infrastructure fixture restores exact baseline: "
		+ ("PASS" if fixture_restored else "FAIL")
	)
	all_passed = all_passed and fixture_restored

	# ------------------------------------------------------------
	# Existing regional state must remain unchanged.
	# ------------------------------------------------------------
	var ownership_preserved: bool = true
	var terrain_preserved: bool = true
	var population_preserved: bool = true
	var resource_preserved: bool = true

	for region_id_value in ownership_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalOwnershipState = (
			world.get_regional_ownership(region_id)
			as RegionalOwnershipState
		)
		if current == null or current.to_snapshot_dict() != ownership_before[region_id]:
			ownership_preserved = false

	for region_id_value in terrain_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalTerrainState = (
			world.get_regional_terrain(region_id)
			as RegionalTerrainState
		)
		if current == null or current.to_snapshot_dict() != terrain_before[region_id]:
			terrain_preserved = false

	for region_id_value in population_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalPopulationState = (
			world.get_regional_population(region_id)
			as RegionalPopulationState
		)
		if current == null or current.to_snapshot_dict() != population_before[region_id]:
			population_preserved = false

	for region_id_value in resource_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalResourceState = (
			world.get_regional_resource(region_id)
			as RegionalResourceState
		)
		if current == null or current.to_snapshot_dict() != resource_before[region_id]:
			resource_preserved = false

	TestLogger.write_line(
		"Existing regional ownership state remains unchanged: "
		+ ("PASS" if ownership_preserved else "FAIL")
	)
	TestLogger.write_line(
		"Existing regional terrain state remains unchanged: "
		+ ("PASS" if terrain_preserved else "FAIL")
	)
	TestLogger.write_line(
		"Existing regional population state remains unchanged: "
		+ ("PASS" if population_preserved else "FAIL")
	)
	TestLogger.write_line(
		"Existing regional resource state remains unchanged: "
		+ ("PASS" if resource_preserved else "FAIL")
	)
	all_passed = (
		all_passed
		and ownership_preserved
		and terrain_preserved
		and population_preserved
		and resource_preserved
	)

	# ------------------------------------------------------------
	# Country infrastructure component remains unchanged.
	# ------------------------------------------------------------
	var country_sources_preserved: bool = true
	for country_id_value in country_sources.keys():
		var country_id: String = str(country_id_value)
		var country = world.get_entity(country_id)
		if country == null:
			country_sources_preserved = false
			continue

		var infrastructure = country.get_component("infrastructure")
		if infrastructure == null:
			country_sources_preserved = false
			continue

		var baseline: Dictionary = country_sources[country_id]
		for key in baseline.keys():
			var current_value: float = float(
				infrastructure.get_state(key, -999.0)
			)
			if not is_equal_approx(current_value, float(baseline[key])):
				country_sources_preserved = false

	TestLogger.write_line(
		"Country InfrastructureComponent remains authoritative and unchanged: "
		+ ("PASS" if country_sources_preserved else "FAIL")
	)
	all_passed = all_passed and country_sources_preserved

	# ------------------------------------------------------------
	# Monthly processing remains inert.
	# ------------------------------------------------------------
	var before_month: Dictionary = system.snapshot_world(world)
	system.process_month(world)
	var after_month: Dictionary = system.snapshot_world(world)
	var monthly_inert: bool = before_month == after_month
	TestLogger.write_line(
		"Step 12.6 monthly processing remains inert: "
		+ ("PASS" if monthly_inert else "FAIL")
	)
	all_passed = all_passed and monthly_inert

	# ------------------------------------------------------------
	# Final validation.
	# ------------------------------------------------------------
	var final_validation: bool = system.validate_world(world)
	TestLogger.write_line(
		"Final regional infrastructure validation: "
		+ ("PASS" if final_validation else "FAIL")
	)
	all_passed = all_passed and final_validation

	TestLogger.write_line(
		"Regionalization 12.6 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _parent_region_ids(
	world: WorldState,
	country_id: String
) -> Array:
	var ids: Array = []
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		if region.country_id == country_id:
			ids.append(region.id)
	ids.sort()
	return ids
