class_name CountryAggregationSystem
extends SimulationSystem


# ============================================================
# WORLD SIMULATOR — STEP 12.9
# COUNTRY-LEVEL AGGREGATION SYSTEM
# ============================================================
#
# Explicit authority handoff:
#
#     parent regional state
#            |
#            v
#     deterministic aggregate
#            |
#            v
#     existing country components
#
# Country components remain the authoritative country state.
# This system does not create a second country inventory/economy/
# population/infrastructure authority.
# ============================================================


const WORLD_UPDATE_PRIORITY: int = 95
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


func _init() -> void:
	super("country_aggregation_system")


func process_month(world: WorldState) -> void:
	# Step 12.9 is an explicit handoff operation at the current MVP
	# boundary. The preceding regional layers are still initialization /
	# localization layers, so monthly country dynamics must not be
	# overwritten by a static regional snapshot.
	if world == null:
		return


func aggregate_world(world: WorldState) -> bool:
	if world == null:
		return false

	var country_ids: Array[String] = _get_country_ids_from_parent_regions(world)
	if country_ids.is_empty():
		return false

	var aggregates: Dictionary = {}
	for country_id in country_ids:
		var aggregate_state: CountryAggregationState = build_country_aggregate(
			world,
			country_id
		)
		if aggregate_state == null:
			return false
		if not aggregate_state.is_valid():
			return false
		aggregates[country_id] = aggregate_state

	var country_snapshots: Dictionary = _capture_country_component_states(
		world,
		country_ids
	)

	for country_id in country_ids:
		var aggregate_to_apply: CountryAggregationState = aggregates[country_id] as CountryAggregationState
		if not _apply_country_aggregate(world, aggregate_to_apply):
			_restore_country_component_states(world, country_snapshots)
			return false

	for country_id in country_ids:
		var applied_aggregate: CountryAggregationState = aggregates[country_id] as CountryAggregationState
		if not validate_country_aggregate(world, applied_aggregate):
			_restore_country_component_states(world, country_snapshots)
			return false

	return validate_world(world)


func aggregate_country(world: WorldState, country_id: String) -> bool:
	if world == null or country_id.is_empty():
		return false

	var aggregate_state: CountryAggregationState = build_country_aggregate(
		world,
		country_id
	)
	if aggregate_state == null:
		return false
	if not aggregate_state.is_valid():
		return false

	var country_snapshots: Dictionary = _capture_country_component_states(
		world,
		[country_id]
	)

	if not _apply_country_aggregate(world, aggregate_state):
		_restore_country_component_states(world, country_snapshots)
		return false

	if not validate_country_aggregate(world, aggregate_state):
		_restore_country_component_states(world, country_snapshots)
		return false

	return true


func build_country_aggregate(
	world: WorldState,
	country_id: String
) -> CountryAggregationState:
	if world == null or country_id.is_empty():
		return null

	var country = world.get_entity(country_id)
	if country == null:
		return null

	if country.get_component("population") == null:
		return null
	if country.get_component("resources") == null:
		return null
	if country.get_component("infrastructure") == null:
		return null
	if country.get_component("industry") == null:
		return null

	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return null

	var aggregate_state: CountryAggregationState = CountryAggregationState.new(
		country_id
	)
	aggregate_state.parent_region_ids = region_ids.duplicate(true)

	var population_weighted_urbanization: float = 0.0
	var population_total: float = 0.0
	var immigration_total: float = 0.0
	var emigration_total: float = 0.0

	var infrastructure_weight_total: float = 0.0
	var infrastructure_weighted_totals: Dictionary = {}
	for key in INFRASTRUCTURE_KEYS:
		infrastructure_weighted_totals[key] = 0.0

	for region_id in region_ids:
		var population_state: RegionalPopulationState = world.get_regional_population(
			region_id
		) as RegionalPopulationState
		if population_state == null:
			return null
		if not population_state.is_valid():
			return null
		if population_state.structural_country_id != country_id:
			return null

		var regional_population: float = maxf(population_state.population, 0.0)
		population_total += regional_population
		population_weighted_urbanization += (
			regional_population * maxf(population_state.urbanization, 0.0)
		)
		immigration_total += maxf(population_state.migration_in, 0.0)
		emigration_total += maxf(population_state.migration_out, 0.0)

		var resource_state: RegionalResourceState = world.get_regional_resource(
			region_id
		) as RegionalResourceState
		if resource_state == null:
			return null
		if not resource_state.is_valid():
			return null
		if resource_state.structural_country_id != country_id:
			return null

		_add_dictionary_values(
			aggregate_state.resource_production,
			resource_state.production_by_resource
		)
		_add_dictionary_values(
			aggregate_state.resource_reserves,
			resource_state.reserves_by_resource
		)
		_add_dictionary_values(
			aggregate_state.resource_stockpile,
			resource_state.stockpile_by_resource
		)

		var infrastructure_state: RegionalInfrastructureState = world.get_regional_infrastructure(
			region_id
		) as RegionalInfrastructureState
		if infrastructure_state == null:
			return null
		if not infrastructure_state.is_valid():
			return null
		if infrastructure_state.structural_country_id != country_id:
			return null

		var weight: float = maxf(infrastructure_state.aggregation_weight, 0.0)
		infrastructure_weight_total += weight
		for key in INFRASTRUCTURE_KEYS:
			infrastructure_weighted_totals[key] = (
				float(infrastructure_weighted_totals[key])
				+ float(infrastructure_state.get(key)) * weight
			)

		var industry_state: RegionalIndustryState = world.get_regional_industry(
			region_id
		) as RegionalIndustryState
		if industry_state == null:
			return null
		if not industry_state.is_valid():
			return null
		if industry_state.structural_country_id != country_id:
			return null

		for process_id_value in industry_state.processes.keys():
			var process_id: String = str(process_id_value)
			var process_value: Variant = industry_state.processes[process_id_value]
			if not process_value is Dictionary:
				return null
			var process: Dictionary = process_value
			var regional_capacity: float = maxf(
				float(process.get("capacity", 0.0)),
				0.0
			)
			aggregate_state.industry_process_capacity[process_id] = (
				float(aggregate_state.industry_process_capacity.get(process_id, 0.0))
				+ regional_capacity
			)

	if population_total < EPSILON:
		aggregate_state.urbanization = 0.0
	else:
		aggregate_state.urbanization = population_weighted_urbanization / population_total

	aggregate_state.population = population_total
	aggregate_state.immigration = immigration_total
	aggregate_state.emigration = emigration_total
	aggregate_state.net_migration = immigration_total - emigration_total

	if infrastructure_weight_total <= EPSILON:
		return null
	aggregate_state.infrastructure_weight_total = infrastructure_weight_total

	for key in INFRASTRUCTURE_KEYS:
		aggregate_state.infrastructure[key] = clampf(
			float(infrastructure_weighted_totals[key]) / infrastructure_weight_total,
			0.0,
			1.0
		)

	aggregate_state.infrastructure_total_capacity = _derive_total_capacity(
		aggregate_state.infrastructure
	)

	return aggregate_state


func validate_country_aggregate(
	world: WorldState,
	expected: CountryAggregationState
) -> bool:
	if world == null or expected == null:
		return false
	if not expected.is_valid():
		return false

	var country = world.get_entity(expected.country_id)
	if country == null:
		return false

	var population_component = country.get_component("population")
	var resource_component = country.get_component("resources")
	var infrastructure_component = country.get_component("infrastructure")
	var industry_component = country.get_component("industry")

	if population_component == null:
		return false
	if resource_component == null:
		return false
	if infrastructure_component == null:
		return false
	if industry_component == null:
		return false

	if not is_equal_approx(
		float(population_component.get_state("population", 0.0)),
		expected.population
	):
		return false
	if not is_equal_approx(
		float(population_component.get_state("urbanization", 0.0)),
		expected.urbanization
	):
		return false
	if not is_equal_approx(
		float(population_component.get_state("immigration", 0.0)),
		expected.immigration
	):
		return false
	if not is_equal_approx(
		float(population_component.get_state("emigration", 0.0)),
		expected.emigration
	):
		return false

	if not _dictionary_matches(
		resource_component.get_state("production", {}) as Dictionary,
		expected.resource_production
	):
		return false
	if not _dictionary_matches(
		resource_component.get_state("reserves", {}) as Dictionary,
		expected.resource_reserves
	):
		return false
	if not _dictionary_matches(
		resource_component.get_state("stockpile", {}) as Dictionary,
		expected.resource_stockpile
	):
		return false

	for key in INFRASTRUCTURE_KEYS:
		if not is_equal_approx(
			float(infrastructure_component.get_state(key, 0.0)),
			float(expected.infrastructure[key])
		):
			return false
	if not is_equal_approx(
		float(infrastructure_component.get_state("total_capacity", 0.0)),
		expected.infrastructure_total_capacity
	):
		return false

	var country_processes_value: Variant = industry_component.get_state(
		"processes",
		{}
	)
	if not country_processes_value is Dictionary:
		return false
	var country_processes: Dictionary = country_processes_value

	if country_processes.size() != expected.industry_process_capacity.size():
		return false

	for process_id_value in expected.industry_process_capacity.keys():
		var process_id: String = str(process_id_value)
		if not country_processes.has(process_id):
			return false
		var process_value: Variant = country_processes[process_id]
		if not process_value is Dictionary:
			return false
		var process: Dictionary = process_value
		if not is_equal_approx(
			float(process.get("capacity", 0.0)),
			float(expected.industry_process_capacity[process_id_value])
		):
			return false

	return true


func validate_world(world: WorldState) -> bool:
	if world == null:
		return false
	if world.get_region_count() <= 0:
		return false

	var country_ids: Array[String] = _get_country_ids_from_parent_regions(world)
	if country_ids.is_empty():
		return false

	for country_id in country_ids:
		if not _validate_parent_region_inputs(world, country_id):
			return false

	return true


func validate_regional_source_reconciliation(world: WorldState) -> bool:
	if world == null:
		return false

	var country_ids: Array[String] = _get_country_ids_from_parent_regions(world)
	for country_id in country_ids:
		if not _validate_population_source_reconciliation(world, country_id):
			return false
		if not _validate_resource_source_reconciliation(world, country_id):
			return false
		if not _validate_infrastructure_source_reconciliation(world, country_id):
			return false
		if not _validate_industry_source_reconciliation(world, country_id):
			return false

	return true


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	var country_ids: Array[String] = _get_country_ids_from_parent_regions(world)
	for country_id in country_ids:
		snapshot[country_id] = _capture_one_country_component_state(
			world,
			country_id
		)

	return snapshot


func get_country_aggregate_snapshot(
	world: WorldState,
	country_id: String
) -> Dictionary:
	if world == null:
		return {}
	return _capture_one_country_component_state(world, country_id)


func _apply_country_aggregate(
	world: WorldState,
	aggregate_state: CountryAggregationState
) -> bool:
	var country = world.get_entity(aggregate_state.country_id)
	if country == null:
		return false

	var population_component = country.get_component("population")
	var resource_component = country.get_component("resources")
	var infrastructure_component = country.get_component("infrastructure")
	var industry_component = country.get_component("industry")

	if population_component == null:
		return false
	if resource_component == null:
		return false
	if infrastructure_component == null:
		return false
	if industry_component == null:
		return false

	population_component.set_state("population", aggregate_state.population)
	population_component.set_state("urbanization", aggregate_state.urbanization)
	population_component.set_state("immigration", aggregate_state.immigration)
	population_component.set_state("emigration", aggregate_state.emigration)
	population_component.set_state("net_migration", aggregate_state.net_migration)

	resource_component.set_state(
		"production",
		aggregate_state.resource_production.duplicate(true)
	)
	resource_component.set_state(
		"reserves",
		aggregate_state.resource_reserves.duplicate(true)
	)
	resource_component.set_state(
		"stockpile",
		aggregate_state.resource_stockpile.duplicate(true)
	)

	for key in INFRASTRUCTURE_KEYS:
		infrastructure_component.set_state(
			key,
			float(aggregate_state.infrastructure[key])
		)
	infrastructure_component.set_state(
		"total_capacity",
		aggregate_state.infrastructure_total_capacity
	)

	var process_value: Variant = industry_component.get_state("processes", {})
	if not process_value is Dictionary:
		return false
	var processes: Dictionary = (process_value as Dictionary).duplicate(true)

	for process_id_value in aggregate_state.industry_process_capacity.keys():
		var process_id: String = str(process_id_value)
		if not processes.has(process_id):
			return false
		var existing_process_value: Variant = processes[process_id]
		if not existing_process_value is Dictionary:
			return false
		var existing_process: Dictionary = (existing_process_value as Dictionary).duplicate(true)
		existing_process["capacity"] = float(
			aggregate_state.industry_process_capacity[process_id_value]
		)
		processes[process_id] = existing_process

	industry_component.set_state("processes", processes)
	return true


func _validate_parent_region_inputs(
	world: WorldState,
	country_id: String
) -> bool:
	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	for region_id in region_ids:
		var region: Region = world.get_region(region_id) as Region
		if region == null:
			return false
		if not region.is_region():
			return false
		if region.country_id != country_id:
			return false

		var population_state: RegionalPopulationState = world.get_regional_population(region_id) as RegionalPopulationState
		if population_state == null or not population_state.is_valid():
			return false
		if population_state.structural_country_id != country_id:
			return false

		var resource_state: RegionalResourceState = world.get_regional_resource(region_id) as RegionalResourceState
		if resource_state == null or not resource_state.is_valid():
			return false
		if resource_state.structural_country_id != country_id:
			return false

		var infrastructure_state: RegionalInfrastructureState = world.get_regional_infrastructure(region_id) as RegionalInfrastructureState
		if infrastructure_state == null or not infrastructure_state.is_valid():
			return false
		if infrastructure_state.structural_country_id != country_id:
			return false

		var industry_state: RegionalIndustryState = world.get_regional_industry(region_id) as RegionalIndustryState
		if industry_state == null or not industry_state.is_valid():
			return false
		if industry_state.structural_country_id != country_id:
			return false

	return true


func _validate_population_source_reconciliation(
	world: WorldState,
	country_id: String
) -> bool:
	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var source_population: float = -1.0
	var share_total: float = 0.0
	var population_total: float = 0.0
	var immigration_total: float = 0.0
	var emigration_total: float = 0.0

	for region_id in region_ids:
		var state: RegionalPopulationState = world.get_regional_population(region_id) as RegionalPopulationState
		if state == null:
			return false
		if source_population < 0.0:
			source_population = state.source_country_population
		elif not is_equal_approx(source_population, state.source_country_population):
			return false
		share_total += state.allocation_share
		population_total += state.population
		immigration_total += state.migration_in
		emigration_total += state.migration_out

	if not is_equal_approx(share_total, 1.0):
		return false
	if not is_equal_approx(population_total, source_population):
		return false
	if source_population < 0.0:
		return false
	if immigration_total < 0.0 or emigration_total < 0.0:
		return false
	return true


func _validate_resource_source_reconciliation(
	world: WorldState,
	country_id: String
) -> bool:
	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var source_production: Dictionary = {}
	var source_reserves: Dictionary = {}
	var source_stockpile: Dictionary = {}
	var seeded: bool = false
	var regional_production: Dictionary = {}
	var regional_reserves: Dictionary = {}
	var regional_stockpile: Dictionary = {}

	for region_id in region_ids:
		var state: RegionalResourceState = world.get_regional_resource(region_id) as RegionalResourceState
		if state == null:
			return false
		if not seeded:
			source_production = state.source_country_resource_state.get("production", {}).duplicate(true)
			source_reserves = state.source_country_resource_state.get("reserves", {}).duplicate(true)
			source_stockpile = state.source_country_resource_state.get("stockpile", {}).duplicate(true)
			seeded = true
		else:
			if state.source_country_resource_state.get("production", {}) != source_production:
				return false
			if state.source_country_resource_state.get("reserves", {}) != source_reserves:
				return false
			if state.source_country_resource_state.get("stockpile", {}) != source_stockpile:
				return false

		_add_dictionary_values(regional_production, state.production_by_resource)
		_add_dictionary_values(regional_reserves, state.reserves_by_resource)
		_add_dictionary_values(regional_stockpile, state.stockpile_by_resource)

	if not _dictionary_matches_source_scaled_to_regions(
		region_ids.size(),
		regional_production,
		source_production,
		world,
		country_id,
		"production"
	):
		return false
	if not _dictionary_matches_source_scaled_to_regions(
		region_ids.size(),
		regional_reserves,
		source_reserves,
		world,
		country_id,
		"reserves"
	):
		return false
	if not _dictionary_matches_source_scaled_to_regions(
		region_ids.size(),
		regional_stockpile,
		source_stockpile,
		world,
		country_id,
		"stockpile"
	):
		return false

	return true


func _dictionary_matches_source_scaled_to_regions(
	_region_count: int,
	regional: Dictionary,
	source: Dictionary,
	world: WorldState,
	country_id: String,
	kind: String
) -> bool:
	if world == null or country_id.is_empty() or kind.is_empty():
		return false

	if regional.size() != source.size():
		return false

	for key_value in source.keys():
		var key: String = str(key_value)
		var source_value: float = maxf(float(source[key_value]), 0.0)
		var regional_value: float = float(regional.get(key, 0.0))
		if is_nan(regional_value) or is_inf(regional_value):
			return false
		if regional_value < -EPSILON:
			return false
		if not is_equal_approx(regional_value, source_value):
			return false

	return true


func _validate_infrastructure_source_reconciliation(
	world: WorldState,
	country_id: String
) -> bool:
	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var source: Dictionary = {}
	var seeded: bool = false
	var weight_total: float = 0.0
	var weighted: Dictionary = {}
	for key in INFRASTRUCTURE_KEYS:
		weighted[key] = 0.0

	for region_id in region_ids:
		var state: RegionalInfrastructureState = world.get_regional_infrastructure(region_id) as RegionalInfrastructureState
		if state == null:
			return false
		if not seeded:
			source = state.source_country_infrastructure_state.duplicate(true)
			seeded = true
		else:
			if state.source_country_infrastructure_state != source:
				return false

		weight_total += state.aggregation_weight
		for key in INFRASTRUCTURE_KEYS:
			weighted[key] = float(weighted[key]) + float(state.get(key)) * state.aggregation_weight

	if not is_equal_approx(weight_total, 1.0):
		return false

	for key in INFRASTRUCTURE_KEYS:
		var source_value: float = float(source.get(key, 0.0))
		if not is_equal_approx(float(weighted[key]), source_value):
			return false

	return true


func _validate_industry_source_reconciliation(
	world: WorldState,
	country_id: String
) -> bool:
	var region_ids: Array[String] = _get_parent_region_ids(world, country_id)
	if region_ids.is_empty():
		return false

	var source_processes: Dictionary = {}
	var seeded: bool = false
	var summed_capacity: Dictionary = {}

	for region_id in region_ids:
		var state: RegionalIndustryState = world.get_regional_industry(region_id) as RegionalIndustryState
		if state == null:
			return false
		if not seeded:
			source_processes = state.source_country_industry_state.get("processes", {}).duplicate(true)
			seeded = true
		else:
			if state.source_country_industry_state.get("processes", {}) != source_processes:
				return false

		for process_id_value in state.processes.keys():
			var process_id: String = str(process_id_value)
			var process_value: Variant = state.processes[process_id_value]
			if not process_value is Dictionary:
				return false
			var process: Dictionary = process_value
			summed_capacity[process_id] = float(summed_capacity.get(process_id, 0.0)) + float(process.get("capacity", 0.0))

	for process_id_value in source_processes.keys():
		var process_id: String = str(process_id_value)
		var source_value: Variant = source_processes[process_id_value]
		if not source_value is Dictionary:
			return false
		var source_process: Dictionary = source_value
		if not summed_capacity.has(process_id):
			return false
		if not is_equal_approx(
			float(summed_capacity[process_id]),
			float(source_process.get("capacity", 0.0))
		):
			return false

	return true


func _derive_total_capacity(infrastructure_values: Dictionary) -> float:
	var total: float = 0.0
	for key in INFRASTRUCTURE_KEYS:
		total += float(infrastructure_values.get(key, 0.0))
	return total / float(INFRASTRUCTURE_KEYS.size())


func _dictionary_matches(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key_value in expected.keys():
		var key: String = str(key_value)
		if not actual.has(key):
			return false
		if not is_equal_approx(float(actual[key]), float(expected[key_value])):
			return false
	return true


func _add_dictionary_values(target: Dictionary, source: Dictionary) -> void:
	for key_value in source.keys():
		var key: String = str(key_value)
		target[key] = float(target.get(key, 0.0)) + maxf(float(source[key_value]), 0.0)


func _get_country_ids_from_parent_regions(world: WorldState) -> Array[String]:
	var ids: Array[String] = []
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null or not region.is_region():
			continue
		if not ids.has(region.country_id):
			ids.append(region.country_id)
	ids.sort()
	return ids


func _get_parent_region_ids(
	world: WorldState,
	country_id: String
) -> Array[String]:
	var ids: Array[String] = []
	for value in world.regions.values():
		var region: Region = value as Region
		if region == null:
			continue
		if not region.is_region():
			continue
		if region.country_id != country_id:
			continue
		ids.append(region.id)
	ids.sort()
	return ids


func _capture_country_component_states(
	world: WorldState,
	country_ids: Array[String]
) -> Dictionary:
	var snapshot: Dictionary = {}
	for country_id in country_ids:
		snapshot[country_id] = _capture_one_country_component_state(world, country_id)
	return snapshot


func _capture_one_country_component_state(
	world: WorldState,
	country_id: String
) -> Dictionary:
	var result: Dictionary = {}
	var country = world.get_entity(country_id)
	if country == null:
		return result

	for component_id in ["population", "resources", "infrastructure", "industry"]:
		var component = country.get_component(component_id)
		if component == null:
			return {}
		result[component_id] = component.state.duplicate(true)
	return result


func _restore_country_component_states(
	world: WorldState,
	snapshot: Dictionary
) -> void:
	for country_id_value in snapshot.keys():
		var country_id: String = str(country_id_value)
		var country = world.get_entity(country_id)
		if country == null:
			continue
		var country_snapshot: Dictionary = snapshot[country_id_value]
		for component_id_value in country_snapshot.keys():
			var component_id: String = str(component_id_value)
			var component = country.get_component(component_id)
			if component == null:
				continue
			component.state = (country_snapshot[component_id_value] as Dictionary).duplicate(true)
