class_name CountryAggregationTest
extends RefCounted


# ============================================================
# WORLD SIMULATOR — STEP 12.9 TEST
# COUNTRY-LEVEL AGGREGATION
# ============================================================
#
# This test is built directly against CountryAggregationState and
# CountryAggregationSystem. It does not assume that the mutable
# country components still equal the original regional seed after
# earlier tests have run.
# ============================================================


const TARGET_COUNTRY_ID: String = "india"
const EPSILON: float = 0.000001
const INFRASTRUCTURE_KEYS: Array[String] = [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section("REGIONALIZATION — STEP 12.9 COUNTRY AGGREGATION TEST")

	var all_passed: bool = true

	var system: CountryAggregationSystem = null
	if simulation != null:
		system = simulation.get_system("country_aggregation_system") as CountryAggregationSystem
	if system == null:
		all_passed = false
	TestLogger.write_line(
		"Registered CountryAggregationSystem available: "
		+ ("PASS" if system != null else "FAIL")
	)
	if system == null:
		return false

	var regional_valid: bool = system.validate_world(world)
	_log("Regional parent-region inputs are structurally valid", regional_valid)
	all_passed = all_passed and regional_valid

	var source_reconciles: bool = system.validate_regional_source_reconciliation(world)
	_log(
		"Regional seed source snapshots reconcile independently of later mutable country state",
		source_reconciles
	)
	all_passed = all_passed and source_reconciles

	var parent_only: bool = _validate_parent_only_registries(world)
	_log("12.9 uses parent regions only", parent_only)
	all_passed = all_passed and parent_only

	var countries_ready: bool = _validate_country_components(world)
	_log("China/India/USA required country components are available", countries_ready)
	all_passed = all_passed and countries_ready

	var regional_before: Dictionary = _capture_regional_state(world)
	var country_before: Dictionary = _capture_country_state(world)
	var hierarchy_before: Dictionary = _capture_hierarchy(world)
	var ownership_before: Dictionary = _capture_optional_registry(world, "regional_ownership")
	var terrain_before: Dictionary = _capture_optional_registry(world, "regional_terrain")
	var transport_before: Dictionary = _capture_transport(world)

	# ------------------------------------------------------------
	# Controlled India fixture.
	# ------------------------------------------------------------
	var india_population_before: RegionalPopulationState = world.get_regional_population("india_north") as RegionalPopulationState
	var india_resource_before: RegionalResourceState = world.get_regional_resource("india_north") as RegionalResourceState
	var india_infrastructure_before: RegionalInfrastructureState = world.get_regional_infrastructure("india_north") as RegionalInfrastructureState
	var india_industry_before: RegionalIndustryState = world.get_regional_industry("india_north") as RegionalIndustryState

	var fixture_ready: bool = india_population_before != null
	if india_resource_before == null:
		fixture_ready = false
	if india_infrastructure_before == null:
		fixture_ready = false
	if india_industry_before == null:
		fixture_ready = false
	_log("Controlled regional aggregation fixture is available", fixture_ready)
	all_passed = all_passed and fixture_ready
	if not fixture_ready:
		return false

	var original_population: float = india_population_before.population
	var original_food: float = float(india_resource_before.production_by_resource.get("food", 0.0))
	var original_transport: float = india_infrastructure_before.transport

	var first_process_id: String = ""
	if not india_industry_before.processes.is_empty():
		first_process_id = str(india_industry_before.processes.keys()[0])
	var original_process_capacity: float = 0.0
	if not first_process_id.is_empty():
		var process_value: Variant = india_industry_before.processes[first_process_id]
		if process_value is Dictionary:
			original_process_capacity = float((process_value as Dictionary).get("capacity", 0.0))

	india_population_before.population = original_population * 0.90
	india_resource_before.production_by_resource["food"] = original_food * 0.80
	india_infrastructure_before.transport = clampf(original_transport * 0.75, 0.0, 1.0)
	india_infrastructure_before.total_capacity = _derive_infrastructure_total(india_infrastructure_before)

	if not first_process_id.is_empty():
		india_industry_before.set_process_capacity(
			first_process_id,
			original_process_capacity * 0.70
		)

	var aggregate_state: CountryAggregationState = system.build_country_aggregate(
		world,
		TARGET_COUNTRY_ID
	)
	var aggregate_built: bool = aggregate_state != null and aggregate_state.is_valid()
	_log("CountryAggregationState builds successfully from mutated regional state", aggregate_built)
	all_passed = all_passed and aggregate_built

	if not aggregate_built:
		_restore_regional_state(world, regional_before)
		return false

	# Population.
	var population_expected: float = _sum_population(world, TARGET_COUNTRY_ID)
	_log(
		"Population aggregation matches parent-region sum",
		is_equal_approx(aggregate_state.population, population_expected)
	)
	all_passed = all_passed and is_equal_approx(aggregate_state.population, population_expected)

	# Resource food check.
	var production_expected: float = _sum_resource(world, TARGET_COUNTRY_ID, "food", "production")
	var production_ok: bool = is_equal_approx(
		float(aggregate_state.resource_production.get("food", 0.0)),
		production_expected
	)
	_log("Resource production aggregation matches parent-region sum", production_ok)
	all_passed = all_passed and production_ok

	# Infrastructure check.
	var transport_expected: float = _weighted_infrastructure(
		world,
		TARGET_COUNTRY_ID,
		"transport"
	)
	var transport_ok: bool = is_equal_approx(
		float(aggregate_state.infrastructure.get("transport", 0.0)),
		transport_expected
	)
	_log("Infrastructure aggregation uses explicit regional weights", transport_ok)
	all_passed = all_passed and transport_ok

	var total_capacity_expected: float = _derive_infrastructure_total_dict(
		aggregate_state.infrastructure
	)
	var total_capacity_ok: bool = is_equal_approx(
		aggregate_state.infrastructure_total_capacity,
		total_capacity_expected
	)
	_log("Country infrastructure total_capacity is derived from seven dimensions", total_capacity_ok)
	all_passed = all_passed and total_capacity_ok

	# Industry check.
	var industry_expected: float = _sum_industry_capacity(
		world,
		TARGET_COUNTRY_ID,
		first_process_id
	)
	var industry_ok: bool = first_process_id.is_empty()
	if not first_process_id.is_empty():
		industry_ok = is_equal_approx(
			float(aggregate_state.industry_process_capacity.get(first_process_id, 0.0)),
			industry_expected
		)
	_log("Industry process capacity aggregates from parent regions", industry_ok)
	all_passed = all_passed and industry_ok

	# Apply explicit country handoff.
	var aggregate_applied: bool = system.aggregate_country(
		world,
		TARGET_COUNTRY_ID
	)
	_log("Explicit country aggregation succeeds", aggregate_applied)
	all_passed = all_passed and aggregate_applied

	var country_matches: bool = system.validate_country_aggregate(
		world,
		aggregate_state
	)
	_log("Country components match the calculated aggregation result", country_matches)
	all_passed = all_passed and country_matches

	# Other countries are untouched by aggregate_country(india).
	var china_usa_unchanged: bool = _compare_non_target_countries(
		world,
		country_before,
		TARGET_COUNTRY_ID
	)
	_log("Explicit India aggregation does not mutate China/USA", china_usa_unchanged)
	all_passed = all_passed and china_usa_unchanged

	# Earlier regional layers remain untouched.
	var hierarchy_ok: bool = hierarchy_before == _capture_hierarchy(world)
	_log("Aggregation preserves regional hierarchy", hierarchy_ok)
	all_passed = all_passed and hierarchy_ok

	var ownership_ok: bool = ownership_before == _capture_optional_registry(world, "regional_ownership")
	_log("Aggregation preserves regional ownership state", ownership_ok)
	all_passed = all_passed and ownership_ok

	var terrain_ok: bool = terrain_before == _capture_optional_registry(world, "regional_terrain")
	_log("Aggregation preserves regional terrain state", terrain_ok)
	all_passed = all_passed and terrain_ok

	var transport_preserved_ok: bool = transport_before == _capture_transport(world)
	_log("Aggregation preserves regional transport state", transport_preserved_ok)
	all_passed = all_passed and transport_preserved_ok

	# Idempotence on the same regional state.
	var aggregate_before_repeat: Dictionary = system.get_country_aggregate_snapshot(
		world,
		TARGET_COUNTRY_ID
	)
	var repeat_ok: bool = system.aggregate_country(world, TARGET_COUNTRY_ID)
	var aggregate_after_repeat: Dictionary = system.get_country_aggregate_snapshot(
		world,
		TARGET_COUNTRY_ID
	)
	var idempotent: bool = repeat_ok and aggregate_before_repeat == aggregate_after_repeat
	_log("Repeated aggregation is idempotent", idempotent)
	all_passed = all_passed and idempotent

	# Monthly hook must remain inert.
	var monthly_before: Dictionary = system.snapshot_world(world)
	system.process_month(world)
	var monthly_after: Dictionary = system.snapshot_world(world)
	var monthly_inert: bool = monthly_before == monthly_after
	_log("12.9 monthly hook remains inert at current authority boundary", monthly_inert)
	all_passed = all_passed and monthly_inert

	# Snapshot isolation.
	var snapshot: Dictionary = system.snapshot_world(world)
	var snapshot_isolated: bool = _mutate_snapshot_without_live_change(
		system,
		world,
		snapshot,
		TARGET_COUNTRY_ID
	)
	_log("Country aggregation snapshot is deep-copy isolated", snapshot_isolated)
	all_passed = all_passed and snapshot_isolated

	# Restore the entire fixture exactly.
	_restore_regional_state(world, regional_before)
	_restore_country_state(world, country_before)

	var regional_restored: bool = regional_before == _capture_regional_state(world)
	var country_restored: bool = country_before == _capture_country_state(world)
	_log("Regional fixture restores exactly", regional_restored)
	all_passed = all_passed and regional_restored
	_log("Country fixture restores exactly", country_restored)
	all_passed = all_passed and country_restored

	# Final validation checks structural regional authority, not stale country
	# equality after restoration.
	var final_validation: bool = system.validate_world(world)
	_log("Final 12.9 world validation succeeds after restoration", final_validation)
	all_passed = all_passed and final_validation

	TestLogger.write_line(
		"Regionalization 12.9 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)
	TestLogger.write_line(
		"Regionalization 12.9 test: "
		+ ("PASS" if all_passed else "FAIL")
	)
	return all_passed


static func _validate_country_components(world: WorldState) -> bool:
	for country_id in ["china", "india", "usa"]:
		var country = world.get_entity(country_id)
		if country == null:
			return false
		if country.get_component("population") == null:
			return false
		if country.get_component("resources") == null:
			return false
		if country.get_component("infrastructure") == null:
			return false
		if country.get_component("industry") == null:
			return false
	return true


static func _validate_parent_only_registries(world: WorldState) -> bool:
	var registries: Array = [
		world.regional_population,
		world.regional_resources,
		world.regional_infrastructure,
		world.regional_industry
	]
	for registry_value in registries:
		if not registry_value is Dictionary:
			return false
		var registry: Dictionary = registry_value
		if registry.size() != 16:
			return false
		for key_value in registry.keys():
			var region: Region = world.get_region(str(key_value)) as Region
			if region == null or not region.is_region():
				return false
	return true


static func _capture_country_state(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	for country_id in ["china", "india", "usa"]:
		var country = world.get_entity(country_id)
		if country == null:
			return {}
		snapshot[country_id] = {
			"population": country.get_component("population").state.duplicate(true),
			"resources": country.get_component("resources").state.duplicate(true),
			"infrastructure": country.get_component("infrastructure").state.duplicate(true),
			"industry": country.get_component("industry").state.duplicate(true)
		}
	return snapshot


static func _restore_country_state(world: WorldState, snapshot: Dictionary) -> void:
	for country_id_value in snapshot.keys():
		var country = world.get_entity(str(country_id_value))
		if country == null:
			continue
		var state: Dictionary = snapshot[country_id_value]
		country.get_component("population").state = state["population"].duplicate(true)
		country.get_component("resources").state = state["resources"].duplicate(true)
		country.get_component("infrastructure").state = state["infrastructure"].duplicate(true)
		country.get_component("industry").state = state["industry"].duplicate(true)


static func _capture_regional_state(world: WorldState) -> Dictionary:
	var result: Dictionary = {
		"population": {},
		"resources": {},
		"infrastructure": {},
		"industry": {}
	}
	for id_value in world.regional_population.keys():
		var id: String = str(id_value)
		var state: RegionalPopulationState = world.get_regional_population(id) as RegionalPopulationState
		result["population"][id] = state.to_snapshot_dict()
	for id_value in world.regional_resources.keys():
		var id: String = str(id_value)
		var state: RegionalResourceState = world.get_regional_resource(id) as RegionalResourceState
		result["resources"][id] = state.to_snapshot_dict()
	for id_value in world.regional_infrastructure.keys():
		var id: String = str(id_value)
		var state: RegionalInfrastructureState = world.get_regional_infrastructure(id) as RegionalInfrastructureState
		result["infrastructure"][id] = state.to_snapshot_dict()
	for id_value in world.regional_industry.keys():
		var id: String = str(id_value)
		var state: RegionalIndustryState = world.get_regional_industry(id) as RegionalIndustryState
		result["industry"][id] = state.to_snapshot_dict()
	return result


static func _restore_regional_state(world: WorldState, snapshot: Dictionary) -> void:
	for id_value in snapshot.get("population", {}).keys():
		var id: String = str(id_value)
		var state: RegionalPopulationState = world.get_regional_population(id) as RegionalPopulationState
		var saved: Dictionary = snapshot["population"][id_value]
		state.population = float(saved.get("population", 0.0))
		state.urbanization = float(saved.get("urbanization", 0.0))
		state.migration_in = float(saved.get("migration_in", 0.0))
		state.migration_out = float(saved.get("migration_out", 0.0))
	for id_value in snapshot.get("resources", {}).keys():
		var id: String = str(id_value)
		var state: RegionalResourceState = world.get_regional_resource(id) as RegionalResourceState
		var saved: Dictionary = snapshot["resources"][id_value]
		state.production_by_resource = saved.get("production_by_resource", {}).duplicate(true)
		state.reserves_by_resource = saved.get("reserves_by_resource", {}).duplicate(true)
		state.stockpile_by_resource = saved.get("stockpile_by_resource", {}).duplicate(true)
	for id_value in snapshot.get("infrastructure", {}).keys():
		var id: String = str(id_value)
		var state: RegionalInfrastructureState = world.get_regional_infrastructure(id) as RegionalInfrastructureState
		var saved: Dictionary = snapshot["infrastructure"][id_value]
		for key in INFRASTRUCTURE_KEYS:
			state.set(key, float(saved.get(key, 0.0)))
		state.total_capacity = float(saved.get("total_capacity", 0.0))
	for id_value in snapshot.get("industry", {}).keys():
		var id: String = str(id_value)
		var state: RegionalIndustryState = world.get_regional_industry(id) as RegionalIndustryState
		var saved: Dictionary = snapshot["industry"][id_value]
		state.processes = saved.get("processes", {}).duplicate(true)


static func _capture_hierarchy(world: WorldState) -> Dictionary:
	var result: Dictionary = {}
	for id_value in world.regions.keys():
		var id: String = str(id_value)
		var region: Region = world.get_region(id) as Region
		result[id] = region.to_snapshot_dict()
	return result


static func _capture_optional_registry(world: WorldState, registry_name: String) -> Dictionary:
	var registry: Variant = world.get(registry_name)
	if not registry is Dictionary:
		return {}
	var result: Dictionary = {}
	var typed_registry: Dictionary = registry
	for key_value in typed_registry.keys():
		var value = typed_registry[key_value]
		if value != null and value.has_method("to_snapshot_dict"):
			result[str(key_value)] = value.to_snapshot_dict()
	return result


static func _capture_transport(world: WorldState) -> Dictionary:
	var result: Dictionary = {"nodes": {}, "routes": {}}
	for key_value in world.regional_transport_nodes.keys():
		var key: String = str(key_value)
		var node = world.regional_transport_nodes[key_value]
		if node != null and node.has_method("to_snapshot_dict"):
			result["nodes"][key] = node.to_snapshot_dict()
	for key_value in world.regional_transport_routes.keys():
		var key: String = str(key_value)
		var route = world.regional_transport_routes[key_value]
		if route != null and route.has_method("to_snapshot_dict"):
			result["routes"][key] = route.to_snapshot_dict()
	return result


static func _compare_non_target_countries(
	world: WorldState,
	before: Dictionary,
	target_country_id: String
) -> bool:
	for country_id_value in before.keys():
		var country_id: String = str(country_id_value)
		if country_id == target_country_id:
			continue
		var country = world.get_entity(country_id)
		if country == null:
			return false
		var current: Dictionary = {
			"population": country.get_component("population").state.duplicate(true),
			"resources": country.get_component("resources").state.duplicate(true),
			"infrastructure": country.get_component("infrastructure").state.duplicate(true),
			"industry": country.get_component("industry").state.duplicate(true)
		}
		if current != before[country_id_value]:
			return false
	return true


static func _mutate_snapshot_without_live_change(
	system: CountryAggregationSystem,
	world: WorldState,
	snapshot: Dictionary,
	country_id: String
) -> bool:
	var country_snapshot: Dictionary = snapshot.get(country_id, {})
	var population_value: Variant = country_snapshot.get("population", null)
	if not population_value is Dictionary:
		return false
	var population: Dictionary = population_value
	population["population"] = -999.0
	var live: Dictionary = system.get_country_aggregate_snapshot(world, country_id)
	var live_population: Dictionary = live.get("population", {})
	return float(live_population.get("population", 0.0)) >= 0.0


static func _sum_population(world: WorldState, country_id: String) -> float:
	var total: float = 0.0
	for id_value in world.regional_population.keys():
		var id: String = str(id_value)
		var region: Region = world.get_region(id) as Region
		if region != null and region.is_region() and region.country_id == country_id:
			var state: RegionalPopulationState = world.get_regional_population(id) as RegionalPopulationState
			total += state.population
	return total


static func _sum_resource(
	world: WorldState,
	country_id: String,
	resource_id: String,
	kind: String
) -> float:
	var total: float = 0.0
	for id_value in world.regional_resources.keys():
		var id: String = str(id_value)
		var region: Region = world.get_region(id) as Region
		if region == null or not region.is_region() or region.country_id != country_id:
			continue
		var state: RegionalResourceState = world.get_regional_resource(id) as RegionalResourceState
		if kind == "production":
			total += float(state.production_by_resource.get(resource_id, 0.0))
		elif kind == "reserves":
			total += float(state.reserves_by_resource.get(resource_id, 0.0))
		else:
			total += float(state.stockpile_by_resource.get(resource_id, 0.0))
	return total


static func _weighted_infrastructure(
	world: WorldState,
	country_id: String,
	key: String
) -> float:
	var total_weight: float = 0.0
	var weighted_value: float = 0.0
	for id_value in world.regional_infrastructure.keys():
		var id: String = str(id_value)
		var region: Region = world.get_region(id) as Region
		if region == null or not region.is_region() or region.country_id != country_id:
			continue
		var state: RegionalInfrastructureState = world.get_regional_infrastructure(id) as RegionalInfrastructureState
		total_weight += state.aggregation_weight
		weighted_value += float(state.get(key)) * state.aggregation_weight
	if total_weight <= EPSILON:
		return 0.0
	return weighted_value / total_weight


static func _sum_industry_capacity(
	world: WorldState,
	country_id: String,
	process_id: String
) -> float:
	if process_id.is_empty():
		return 0.0
	var total: float = 0.0
	for id_value in world.regional_industry.keys():
		var id: String = str(id_value)
		var region: Region = world.get_region(id) as Region
		if region == null or not region.is_region() or region.country_id != country_id:
			continue
		var state: RegionalIndustryState = world.get_regional_industry(id) as RegionalIndustryState
		var process_value: Variant = state.processes.get(process_id, null)
		if process_value is Dictionary:
			total += float((process_value as Dictionary).get("capacity", 0.0))
	return total


static func _derive_infrastructure_total(state: RegionalInfrastructureState) -> float:
	return (
		state.transport
		+ state.railways
		+ state.roads
		+ state.ports
		+ state.power
		+ state.industrial
		+ state.storage
	) / 7.0


static func _derive_infrastructure_total_dict(values: Dictionary) -> float:
	var total: float = 0.0
	for key in INFRASTRUCTURE_KEYS:
		total += float(values.get(key, 0.0))
	return total / 7.0


static func _log(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)
