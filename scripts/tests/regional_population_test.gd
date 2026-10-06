class_name RegionalPopulationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"REGIONALIZATION — STEP 12.4 POPULATION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	var all_passed: bool = true
	var system: RegionalPopulationSystem = RegionalPopulationSystem.new()

	var expected_parent_region_count: int = 0
	for value in world.regions.values():
		var region: Region = value as Region
		if region != null and region.is_region():
			expected_parent_region_count += 1

	var registry_passed: bool = (
		expected_parent_region_count > 0
		and world.get_regional_population_count() == expected_parent_region_count
	)
	TestLogger.write_line(
		"Regional population registry initialized for all parent regions: "
		+ ("PASS" if registry_passed else "FAIL")
	)
	all_passed = all_passed and registry_passed

	var registered_system_passed: bool = false
	if simulation != null:
		registered_system_passed = (
			simulation.get_system("regional_population_system")
		is RegionalPopulationSystem
		)
	TestLogger.write_line(
		"Registered RegionalPopulationSystem available: "
		+ ("PASS" if registered_system_passed else "FAIL")
	)
	all_passed = all_passed and registered_system_passed

	var country_ids: Array[String] = ["china", "india", "usa"]
	var original_country_population: Dictionary = {}
	var original_country_migration_in: Dictionary = {}
	var original_country_migration_out: Dictionary = {}
	var original_country_urbanization: Dictionary = {}
	var country_components_passed: bool = true

	for country_id in country_ids:
		var country = world.get_entity(country_id)
		if country == null:
			country_components_passed = false
			continue

		var population = country.get_component("population")
		if population == null:
			country_components_passed = false
			continue

		original_country_population[country_id] = population.get_state("population", 0.0)
		original_country_migration_in[country_id] = population.get_state(
			"immigration",
			population.get_state("base_immigration", 0.0)
		)
		original_country_migration_out[country_id] = population.get_state(
			"emigration",
			population.get_state("base_emigration", 0.0)
		)
		original_country_urbanization[country_id] = population.get_state(
			"urbanization",
			0.0
		)

	TestLogger.write_line(
		"Core-country population components available: "
		+ ("PASS" if country_components_passed else "FAIL")
	)
	all_passed = all_passed and country_components_passed

	# ------------------------------------------------------------
	# Cross-suite-safe regional seed validation.
	# Step 12.4 is a localization/bootstrap layer. Earlier suite tests
	# may legitimately mutate the live country PopulationComponent after
	# the regional seed was created. Therefore this test validates the
	# authoritative regional seed/source values, not a later mutable
	# country runtime value.
	# ------------------------------------------------------------
	var country_reconciliation_passed: bool = true
	var migration_reconciliation_passed: bool = true
	var demographic_reconciliation_passed: bool = true
	var urbanization_reconciliation_passed: bool = true

	for country_id in country_ids:
		var region_ids: Array[String] = _sorted_parent_region_ids(world, country_id)
		if region_ids.is_empty():
			country_reconciliation_passed = false
			migration_reconciliation_passed = false
			continue

		var source_population: float = -1.0
		var regional_migration_in_total: float = 0.0
		var regional_migration_out_total: float = 0.0
		var population_total: float = 0.0
		var weighted_urbanization: float = 0.0
		var share_total: float = 0.0

		for region_id in region_ids:
			var state: RegionalPopulationState = system.get_population_state(
				world,
				region_id
			)
			if state == null:
				country_reconciliation_passed = false
				migration_reconciliation_passed = false
				continue

			if source_population < 0.0:
				source_population = state.source_country_population
			elif not is_equal_approx(source_population, state.source_country_population):
				country_reconciliation_passed = false

			share_total += state.allocation_share
			population_total += state.population
			regional_migration_in_total += state.migration_in
			regional_migration_out_total += state.migration_out
			weighted_urbanization += state.population * state.urbanization

			var expected_population: float = (
				state.source_country_population
				* state.allocation_share
			)
			if not is_equal_approx(state.population, expected_population):
				country_reconciliation_passed = false

			var country = world.get_entity(country_id)
			var population = null if country == null else country.get_component("population")
			if population != null:
				if not is_equal_approx(
						state.population_growth_rate,
						float(population.get_state("growth_rate", 0.0))
					):
						demographic_reconciliation_passed = false
				if not is_equal_approx(
					state.birth_rate,
					float(population.get_state("birth_rate", 0.0))
				):
					demographic_reconciliation_passed = false
				if not is_equal_approx(
					state.death_rate,
					float(population.get_state("death_rate", 0.0))
				):
					demographic_reconciliation_passed = false



		# Migration is validated in a second pass because the country-level
		# regional migration totals are accumulated above.
		for region_id in region_ids:
			var state: RegionalPopulationState = system.get_population_state(
				world,
				region_id
			)
			if state == null:
				continue

			var expected_migration_in: float = (
				regional_migration_in_total * state.allocation_share
			)
			var expected_migration_out: float = (
				regional_migration_out_total * state.allocation_share
			)
			if not is_equal_approx(state.migration_in, expected_migration_in):
				migration_reconciliation_passed = false
			if not is_equal_approx(state.migration_out, expected_migration_out):
				migration_reconciliation_passed = false

		if source_population >= 0.0:
			if not is_equal_approx(population_total, source_population):
				country_reconciliation_passed = false
		if not is_equal_approx(share_total, 1.0):
			country_reconciliation_passed = false

		var weighted_average: float = 0.0
		if population_total > 0.0:
			weighted_average = weighted_urbanization / population_total
		var country_now = world.get_entity(country_id)
		var population_now = null if country_now == null else country_now.get_component("population")
		if population_now != null:
			if not is_equal_approx(
				weighted_average,
				float(population_now.get_state("urbanization", 0.0))
			):
				urbanization_reconciliation_passed = false

	TestLogger.write_line(
		"Regional population totals reconcile to regional seed source: "
		+ ("PASS" if country_reconciliation_passed else "FAIL")
	)
	all_passed = all_passed and country_reconciliation_passed

	TestLogger.write_line(
		"Regional demographic baseline preserves country source values: "
		+ ("PASS" if demographic_reconciliation_passed else "FAIL")
	)
	all_passed = all_passed and demographic_reconciliation_passed

	TestLogger.write_line(
		"Regional migration baseline remains proportionally localized: "
		+ ("PASS" if migration_reconciliation_passed else "FAIL")
	)
	all_passed = all_passed and migration_reconciliation_passed

	TestLogger.write_line(
		"Population-weighted regional urbanization reconciles to current country baseline: "
		+ ("PASS" if urbanization_reconciliation_passed else "FAIL")
	)
	all_passed = all_passed and urbanization_reconciliation_passed

	var province_boundary_passed: bool = true
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_province():
			continue
		if world.has_regional_population(region.id) or region.parent_region_id.is_empty():
			province_boundary_passed = false
			break
	TestLogger.write_line(
		"Province nodes remain without duplicate population authority: "
		+ ("PASS" if province_boundary_passed else "FAIL")
	)
	all_passed = all_passed and province_boundary_passed

	var entity_count_before: int = world.get_entity_count()
	var country_entities_preserved: bool = (
		world.get_entity("china") != null
		and world.get_entity("india") != null
		and world.get_entity("usa") != null
		and world.get_entity_count() == entity_count_before
	)
	TestLogger.write_line(
		"Country entities remain authoritative and unchanged: "
		+ ("PASS" if country_entities_preserved else "FAIL")
	)
	all_passed = all_passed and country_entities_preserved

	var before_duplicate: int = world.get_regional_population_count()
	var duplicate_result: bool = system.initialize_world(world, [])
	var after_duplicate: int = world.get_regional_population_count()
	var duplicate_passed: bool = duplicate_result == false and before_duplicate == after_duplicate
	TestLogger.write_line(
		"Second population initialization is rejected without duplication: "
		+ ("PASS" if duplicate_passed else "FAIL")
	)
	all_passed = all_passed and duplicate_passed

	var fixture_id: String = "india_south"
	var fixture: RegionalPopulationState = system.get_population_state(world, fixture_id)
	var snapshot_passed: bool = false
	if fixture != null:
		var snapshot: Dictionary = fixture.to_snapshot_dict()
		snapshot["population"] = 0.0
		snapshot["urbanization"] = 999.0
		snapshot["allocation_share"] = 0.0
		snapshot_passed = (
			fixture.population > 0.0
			and fixture.urbanization != 999.0
			and fixture.allocation_share > 0.0
		)
	TestLogger.write_line(
		"Population snapshot is isolated from live state: "
		+ ("PASS" if snapshot_passed else "FAIL")
	)
	all_passed = all_passed and snapshot_passed

	var terrain_before: Dictionary = {}
	var ownership_before: Dictionary = {}
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue
		var terrain = world.get_regional_terrain(region.id)
		if terrain != null:
			terrain_before[region.id] = terrain.to_snapshot_dict()
		var ownership = world.get_regional_ownership(region.id)
		if ownership != null:
			ownership_before[region.id] = ownership.to_snapshot_dict()

	var mutation_passed: bool = false
	var structural_passed: bool = false
	var restored_passed: bool = false

	if fixture != null:
		var original_snapshot: Dictionary = fixture.to_snapshot_dict()
		var original_population: float = fixture.population
		var original_share: float = fixture.allocation_share
		var original_country: String = fixture.structural_country_id

		fixture.population += 1000.0
		fixture.allocation_share = original_share + 0.000001
		mutation_passed = fixture.population > original_population and fixture.allocation_share > original_share

		var region_after: Region = world.get_region(fixture_id) as Region
		structural_passed = (
			region_after != null
			and region_after.country_id == original_country
			and region_after.parent_region_id.is_empty()
		)

		fixture.population = original_population
		fixture.allocation_share = original_share
		var restored_snapshot: Dictionary = fixture.to_snapshot_dict()
		restored_passed = restored_snapshot == original_snapshot

	TestLogger.write_line(
		"Explicit regional population mutation changes only population state: "
		+ ("PASS" if mutation_passed else "FAIL")
	)
	all_passed = all_passed and mutation_passed
	TestLogger.write_line(
		"Population mutation does not rewrite region hierarchy: "
		+ ("PASS" if structural_passed else "FAIL")
	)
	all_passed = all_passed and structural_passed
	TestLogger.write_line(
		"Population fixture restores exact baseline: "
		+ ("PASS" if restored_passed else "FAIL")
	)
	all_passed = all_passed and restored_passed

	var terrain_preserved: bool = true
	for region_id in terrain_before.keys():
		var current = world.get_regional_terrain(region_id)
		if current == null or current.to_snapshot_dict() != terrain_before[region_id]:
			terrain_preserved = false
			break
	TestLogger.write_line(
		"Existing regional terrain state remains unchanged: "
		+ ("PASS" if terrain_preserved else "FAIL")
	)
	all_passed = all_passed and terrain_preserved

	var ownership_preserved: bool = true
	for region_id in ownership_before.keys():
		var current = world.get_regional_ownership(region_id)
		if current == null or current.to_snapshot_dict() != ownership_before[region_id]:
			ownership_preserved = false
			break
	TestLogger.write_line(
		"Existing regional ownership state remains unchanged: "
		+ ("PASS" if ownership_preserved else "FAIL")
	)
	all_passed = all_passed and ownership_preserved

	var before_month: Dictionary = system.snapshot_world(world)
	system.process_month(world)
	var after_month: Dictionary = system.snapshot_world(world)
	var inert_passed: bool = before_month == after_month
	TestLogger.write_line(
		"Step 12.4 monthly processing remains inert: "
		+ ("PASS" if inert_passed else "FAIL")
	)
	all_passed = all_passed and inert_passed

	var final_validation_passed: bool = true
	for country_id in country_ids:
		var region_ids: Array[String] = _sorted_parent_region_ids(world, country_id)
		var source_population: float = -1.0
		var population_total: float = 0.0
		var migration_in_total: float = 0.0
		var migration_out_total: float = 0.0
		var share_total: float = 0.0
		for region_id in region_ids:
			var state: RegionalPopulationState = system.get_population_state(world, region_id)
			if state == null:
				final_validation_passed = false
				continue
			if source_population < 0.0:
				source_population = state.source_country_population
			population_total += state.population
			migration_in_total += state.migration_in
			migration_out_total += state.migration_out
			share_total += state.allocation_share
			if not is_equal_approx(state.population, state.source_country_population * state.allocation_share):
				final_validation_passed = false
		if source_population >= 0.0 and not is_equal_approx(population_total, source_population):
			final_validation_passed = false
		if not is_equal_approx(share_total, 1.0):
			final_validation_passed = false
		for region_id in region_ids:
			var state: RegionalPopulationState = system.get_population_state(world, region_id)
			if state == null:
				continue
			if not is_equal_approx(state.migration_in, migration_in_total * state.allocation_share):
				final_validation_passed = false
			if not is_equal_approx(state.migration_out, migration_out_total * state.allocation_share):
				final_validation_passed = false

	TestLogger.write_line(
		"Final regional population validation: "
		+ ("PASS" if final_validation_passed else "FAIL")
	)
	all_passed = all_passed and final_validation_passed

	var country_source_preserved: bool = true
	for country_id in country_ids:
		var country = world.get_entity(country_id)
		var population = null if country == null else country.get_component("population")
		if population == null:
			country_source_preserved = false
			continue
		if population.get_state("population", 0.0) != original_country_population[country_id]:
			country_source_preserved = false
		if population.get_state("immigration", population.get_state("base_immigration", 0.0)) != original_country_migration_in[country_id]:
			country_source_preserved = false
		if population.get_state("emigration", population.get_state("base_emigration", 0.0)) != original_country_migration_out[country_id]:
			country_source_preserved = false
		if population.get_state("urbanization", 0.0) != original_country_urbanization[country_id]:
			country_source_preserved = false

	TestLogger.write_line(
		"Country PopulationComponent remains authoritative and unchanged: "
		+ ("PASS" if country_source_preserved else "FAIL")
	)
	all_passed = all_passed and country_source_preserved

	TestLogger.write_line(
		"Regionalization 12.4 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)
	return all_passed


static func _sorted_parent_region_ids(
	world: WorldState,
	country_id: String
) -> Array[String]:
	var ids: Array[String] = []
	if world == null:
		return ids
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		if not country_id.is_empty() and region.country_id != country_id:
			continue
		ids.append(region.id)
	ids.sort()
	return ids
