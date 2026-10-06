class_name RegionalResourceTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.5 TEST
# REGIONAL RESOURCE LOCALIZATION
# ============================================================
#
# This test intentionally validates Step 12.5 as a localization seed
# layer. It does not require the inert regional state to track later
# country-level ResourceSystem mutations in the same test run.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section("REGIONALIZATION — STEP 12.5 RESOURCE TEST")

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var system_instance = simulation.get_system("regional_resource_system")
	var system_ok: bool = (
		system_instance != null
		and system_instance is RegionalResourceSystem
	)
	TestLogger.write_line(
		"Registered RegionalResourceSystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)
	all_passed = all_passed and system_ok
	if not system_ok:
		return false

	var system: RegionalResourceSystem = system_instance as RegionalResourceSystem

	var expected_parent_regions: Dictionary = {
		"china": 6,
		"india": 6,
		"usa": 4
	}
	var expected_total: int = 16

	var registry_ok: bool = (
		world.get_regional_resource_count() == expected_total
	)
	TestLogger.write_line(
		"Regional resource registry initialized for all parent regions: "
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
			+ " regional resource count = "
			+ str(expected_count)
			+ ": "
			+ ("PASS" if count_ok else "FAIL")
		)
		all_passed = all_passed and count_ok

	# ------------------------------------------------------------
	# Country source state must exist.
	# ------------------------------------------------------------
	var source_snapshots: Dictionary = {}
	for country_id in ["china", "india", "usa"]:
		var country = world.get_entity(country_id)
		var resources = null
		if country != null:
			resources = country.get_component("resources")

		var source_ok: bool = country != null and resources != null
		TestLogger.write_line(
			country_id.capitalize()
			+ " resource component available: "
			+ ("PASS" if source_ok else "FAIL")
		)
		all_passed = all_passed and source_ok

		if not source_ok:
			continue

		var production_value: Variant = resources.get_state("production", {})
		var reserves_value: Variant = resources.get_state("reserves", {})
		var stockpile_value: Variant = resources.get_state("stockpile", {})

		if not production_value is Dictionary:
			source_ok = false
		if not reserves_value is Dictionary:
			source_ok = false
		if not stockpile_value is Dictionary:
			source_ok = false

		if source_ok:
			source_snapshots[country_id] = {
				"production": (production_value as Dictionary).duplicate(true),
				"reserves": (reserves_value as Dictionary).duplicate(true),
				"stockpile": (stockpile_value as Dictionary).duplicate(true)
			}

	# ------------------------------------------------------------
	# Reconciliation against the exact Step 12.5 seed source.
	#
	# The active suite runs other resource/trade tests before Step 12.5,
	# so the live country ResourceComponent may legitimately differ from
	# the snapshot that was used to initialize the regional seed. The
	# RegionalResourceState stores that authoritative initialization seed
	# in source_country_resource_state. Reconciliation must use that seed.
	# ------------------------------------------------------------
	var seed_snapshots: Dictionary = {}
	var reconciliation_ok: bool = true

	for country_id in ["china", "india", "usa"]:
		var parent_region_ids: Array = []
		for value in world.regions.values():
			var region: Region = value as Region
			if region == null or not region.is_region():
				continue
			if region.country_id == country_id:
				parent_region_ids.append(region.id)
		parent_region_ids.sort()

		if parent_region_ids.is_empty():
			reconciliation_ok = false
			continue

		var seed_state: RegionalResourceState = system.get_resource_state(
			world,
			str(parent_region_ids[0])
		)
		if seed_state == null:
			reconciliation_ok = false
			continue

		var seed_source: Dictionary = seed_state.source_country_resource_state
		if not seed_source.has("production") or not seed_source.has("reserves") or not seed_source.has("stockpile"):
			reconciliation_ok = false
			continue

		if not seed_source["production"] is Dictionary:
			reconciliation_ok = false
			continue
		if not seed_source["reserves"] is Dictionary:
			reconciliation_ok = false
			continue
		if not seed_source["stockpile"] is Dictionary:
			reconciliation_ok = false
			continue

		seed_snapshots[country_id] = seed_source.duplicate(true)

		for region_id_value in parent_region_ids:
			var region_id: String = str(region_id_value)
			var state: RegionalResourceState = system.get_resource_state(
				world,
				region_id
			)
			if state == null or state.source_country_resource_state != seed_source:
				reconciliation_ok = false

		var regional_production: Dictionary = system.get_country_production_total(
			world,
			country_id
		)
		var regional_reserves: Dictionary = system.get_country_reserve_total(
			world,
			country_id
		)
		var regional_stockpile: Dictionary = system.get_country_stockpile_total(
			world,
			country_id
		)

		if not _dictionary_reconciles(
			seed_source["production"] as Dictionary,
			regional_production
		):
			reconciliation_ok = false
		if not _dictionary_reconciles(
			seed_source["reserves"] as Dictionary,
			regional_reserves
		):
			reconciliation_ok = false
		if not _dictionary_reconciles(
			seed_source["stockpile"] as Dictionary,
			regional_stockpile
		):
			reconciliation_ok = false

	TestLogger.write_line(
		"Regional production/reserves/stockpile reconcile to exact Step 12.5 seed source: "
		+ ("PASS" if reconciliation_ok else "FAIL")
	)
	all_passed = all_passed and reconciliation_ok

	# ------------------------------------------------------------
	# System validation.
	# ------------------------------------------------------------
	var initial_validation: bool = system.validate_world(world)
	TestLogger.write_line(
		"Initial regional resource validation: "
		+ ("PASS" if initial_validation else "FAIL")
	)
	all_passed = all_passed and initial_validation

	# ------------------------------------------------------------
	# Calibration bounds and province authority boundary.
	# ------------------------------------------------------------
	var accessibility_ok: bool = true
	var import_dependency_ok: bool = true
	var province_authority_ok: bool = true

	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue

		if region.is_province():
			if world.has_regional_resource(region.id):
				province_authority_ok = false
			continue

		if not region.is_region():
			continue

		var state: RegionalResourceState = system.get_resource_state(
			world,
			region.id
		)
		if state == null:
			accessibility_ok = false
			import_dependency_ok = false
			continue

		for factor_value in state.resource_accessibility.values():
			var factor: float = float(factor_value)
			if factor < 0.0 or factor > 1.0:
				accessibility_ok = false

		for factor_value in state.local_import_dependency.values():
			var factor: float = float(factor_value)
			if factor < 0.0 or factor > 1.0:
				import_dependency_ok = false

	TestLogger.write_line(
		"Regional resource accessibility remains bounded 0..1: "
		+ ("PASS" if accessibility_ok else "FAIL")
	)
	TestLogger.write_line(
		"Local import-dependency calibration remains bounded 0..1: "
		+ ("PASS" if import_dependency_ok else "FAIL")
	)
	TestLogger.write_line(
		"Province nodes remain without duplicate resource authority: "
		+ ("PASS" if province_authority_ok else "FAIL")
	)
	all_passed = (
		all_passed
		and accessibility_ok
		and import_dependency_ok
		and province_authority_ok
	)

	# ------------------------------------------------------------
	# Existing regional state snapshots.
	# ------------------------------------------------------------
	var hierarchy_before: Dictionary = {}
	var terrain_before: Dictionary = {}
	var ownership_before: Dictionary = {}
	var population_before: Dictionary = {}

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

		if world.has_regional_terrain(region.id):
			var terrain: RegionalTerrainState = (
				world.get_regional_terrain(region.id)
				as RegionalTerrainState
			)
			if terrain != null:
				terrain_before[region.id] = terrain.to_snapshot_dict()

		if world.has_regional_ownership(region.id):
			var ownership: RegionalOwnershipState = (
				world.get_regional_ownership(region.id)
				as RegionalOwnershipState
			)
			if ownership != null:
				ownership_before[region.id] = ownership.to_snapshot_dict()

		if world.has_regional_population(region.id):
			var population: RegionalPopulationState = (
				world.get_regional_population(region.id)
				as RegionalPopulationState
			)
			if population != null:
				population_before[region.id] = population.to_snapshot_dict()

	# ------------------------------------------------------------
	# Duplicate initialization.
	# ------------------------------------------------------------
	var duplicate_rejected: bool = not system.initialize_world(world, [])
	TestLogger.write_line(
		"Second resource initialization is rejected without duplication: "
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
		var snapshot_production_value: Variant = first_snapshot.get(
			"production_by_resource",
			{}
		)
		if snapshot_production_value is Dictionary:
			var snapshot_production: Dictionary = snapshot_production_value
			if snapshot_production.has("food"):
				snapshot_production["food"] = 999999.0
			var live_state: RegionalResourceState = system.get_resource_state(
				world,
				first_id
			)
			if live_state != null:
				if is_equal_approx(
					float(live_state.production_by_resource.get("food", 0.0)),
					999999.0
				):
					snapshot_isolated = false

	TestLogger.write_line(
		"Resource snapshot is isolated from live state: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated

	# ------------------------------------------------------------
	# Explicit regional mutation fixture.
	# ------------------------------------------------------------
	var mutation_region_id: String = "china_northwest"
	var mutation_state: RegionalResourceState = system.get_resource_state(
		world,
		mutation_region_id
	)
	var mutation_ok: bool = mutation_state != null
	var mutation_baseline: Dictionary = {}

	if mutation_state != null:
		mutation_baseline = mutation_state.to_snapshot_dict()
		var mutation_production: Dictionary = (
			mutation_state.production_by_resource.duplicate(true)
		)
		mutation_production["oil"] = float(
			mutation_production.get("oil", 0.0)
		) + 1.0
		mutation_state.production_by_resource = mutation_production

		mutation_ok = mutation_ok and (
			float(mutation_state.production_by_resource.get("oil", 0.0))
			> float(
				mutation_baseline["production_by_resource"]
				.get("oil", 0.0)
			)
		)

	TestLogger.write_line(
		"Explicit regional resource mutation changes resource state: "
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
		"Resource mutation does not rewrite region hierarchy: "
		+ ("PASS" if hierarchy_preserved else "FAIL")
	)
	all_passed = all_passed and hierarchy_preserved

	if mutation_state != null:
		mutation_state.production_by_resource = (
			mutation_baseline["production_by_resource"].duplicate(true)
		)
		mutation_state.reserves_by_resource = (
			mutation_baseline["reserves_by_resource"].duplicate(true)
		)
		mutation_state.stockpile_by_resource = (
			mutation_baseline["stockpile_by_resource"].duplicate(true)
		)
		mutation_state.resource_accessibility = (
			mutation_baseline["resource_accessibility"].duplicate(true)
		)
		mutation_state.local_import_dependency = (
			mutation_baseline["local_import_dependency"].duplicate(true)
		)

	var fixture_restored: bool = true
	if mutation_state != null:
		fixture_restored = (
			mutation_state.to_snapshot_dict() == mutation_baseline
		)

	TestLogger.write_line(
		"Resource fixture restores exact baseline: "
		+ ("PASS" if fixture_restored else "FAIL")
	)
	all_passed = all_passed and fixture_restored

	# ------------------------------------------------------------
	# Existing regional layers must remain unchanged.
	# ------------------------------------------------------------
	var terrain_preserved: bool = true
	var ownership_preserved: bool = true
	var population_preserved: bool = true

	for region_id_value in terrain_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalTerrainState = (
			world.get_regional_terrain(region_id)
			as RegionalTerrainState
		)
		if current == null or current.to_snapshot_dict() != terrain_before[region_id]:
			terrain_preserved = false

	for region_id_value in ownership_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalOwnershipState = (
			world.get_regional_ownership(region_id)
			as RegionalOwnershipState
		)
		if current == null or current.to_snapshot_dict() != ownership_before[region_id]:
			ownership_preserved = false

	for region_id_value in population_before.keys():
		var region_id: String = str(region_id_value)
		var current: RegionalPopulationState = (
			world.get_regional_population(region_id)
			as RegionalPopulationState
		)
		if current == null or current.to_snapshot_dict() != population_before[region_id]:
			population_preserved = false

	TestLogger.write_line(
		"Existing regional terrain state remains unchanged: "
		+ ("PASS" if terrain_preserved else "FAIL")
	)
	TestLogger.write_line(
		"Existing regional ownership state remains unchanged: "
		+ ("PASS" if ownership_preserved else "FAIL")
	)
	TestLogger.write_line(
		"Existing regional population state remains unchanged: "
		+ ("PASS" if population_preserved else "FAIL")
	)
	all_passed = (
		all_passed
		and terrain_preserved
		and ownership_preserved
		and population_preserved
	)

	# ------------------------------------------------------------
	# Country ResourceComponent must remain untouched by regional init.
	# ------------------------------------------------------------
	var country_sources_preserved: bool = true
	for country_id_value in source_snapshots.keys():
		var country_id: String = str(country_id_value)
		var country = world.get_entity(country_id)
		if country == null:
			country_sources_preserved = false
			continue

		var resources = country.get_component("resources")
		if resources == null:
			country_sources_preserved = false
			continue

		var baseline: Dictionary = source_snapshots[country_id]
		for key in baseline.keys():
			var current_state: Variant = resources.get_state(key, {})
			if current_state != baseline[key]:
				country_sources_preserved = false

	TestLogger.write_line(
		"Country ResourceComponent remains authoritative and unchanged: "
		+ ("PASS" if country_sources_preserved else "FAIL")
	)
	all_passed = all_passed and country_sources_preserved

	# ------------------------------------------------------------
	# Monthly processing is intentionally inert.
	# ------------------------------------------------------------
	var before_month: Dictionary = system.snapshot_world(world)
	system.process_month(world)
	var after_month: Dictionary = system.snapshot_world(world)
	var monthly_inert: bool = before_month == after_month
	TestLogger.write_line(
		"Step 12.5 monthly processing remains inert: "
		+ ("PASS" if monthly_inert else "FAIL")
	)
	all_passed = all_passed and monthly_inert

	# ------------------------------------------------------------
	# Final validation.
	# ------------------------------------------------------------
	var final_validation: bool = system.validate_world(world)
	TestLogger.write_line(
		"Final regional resource validation: "
		+ ("PASS" if final_validation else "FAIL")
	)
	all_passed = all_passed and final_validation

	TestLogger.write_line(
		"Regionalization 12.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _dictionary_reconciles(
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
