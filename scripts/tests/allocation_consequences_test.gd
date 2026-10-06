class_name AllocationConsequencesTest
extends RefCounted


const EPSILON: float = 0.000001


static func _approx_equal(
	actual: float,
	expected: float
) -> bool:
	return is_equal_approx(
		actual,
		expected
	)


static func _log_result(
	label: String,
	passed: bool
) -> void:
	TestLogger.write_line(
		label
		+ ": "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)


static func _get_dictionary(
	resources: ResourceComponent,
	state_name: String
) -> Dictionary:
	var value: Variant = resources.get_state(
		state_name,
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value as Dictionary


static func _get_nested_dictionary(
	container: Dictionary,
	key: String
) -> Dictionary:
	var value: Variant = container.get(
		key,
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value as Dictionary


static func _get_number(
	container: Dictionary,
	key: String,
	default_value: float
) -> float:
	var value: Variant = container.get(
		key,
		default_value
	)

	return float(value)


static func _get_array(
	container: Dictionary,
	key: String
) -> Array:
	var value: Variant = container.get(
		key,
		[]
	)

	if typeof(value) != TYPE_ARRAY:
		return []

	return value as Array


static func _max_reconciliation_error(
	errors: Dictionary
) -> float:

	var maximum: float = 0.0

	for value in errors.values():

		maximum = maxf(
			maximum,
			absf(float(value))
		)

	return maximum


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"ALLOCATION CONSEQUENCES TEST"
	)

	if world == null or simulation == null:

		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)

		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	# ============================================================
	# REGISTERED SYSTEMS
	# ============================================================

	var allocation_system_instance: SimulationSystem = simulation.get_system(
		"allocation_consequences_system"
	)

	var allocation_system_ok: bool = (
		allocation_system_instance != null
		and allocation_system_instance is AllocationConsequencesSystem
	)

	_log_result(
		"Registered AllocationConsequencesSystem available",
		allocation_system_ok
	)

	if not allocation_system_ok:
		return false

	var allocation_system: AllocationConsequencesSystem = (
		allocation_system_instance as AllocationConsequencesSystem
	)

	var consumption_system: SimulationSystem = simulation.get_system(
		"aggregate_consumption_system"
	)

	var consumption_system_ok: bool = (
		consumption_system != null
		and consumption_system is AggregateConsumptionSystem
	)

	_log_result(
		"Registered AggregateConsumptionSystem available",
		consumption_system_ok
	)

	if not consumption_system_ok:
		return false

	var production_system: SimulationSystem = simulation.get_system(
		"production_process_system"
	)

	var production_system_ok: bool = (
		production_system != null
		and production_system is ProductionProcessSystem
	)

	_log_result(
		"Registered ProductionProcessSystem available",
		production_system_ok
	)

	if not production_system_ok:
		return false

	var purchasing_power_system: SimulationSystem = simulation.get_system(
		"purchasing_power_system"
	)

	var purchasing_power_ok: bool = (
		purchasing_power_system != null
		and purchasing_power_system is PurchasingPowerSystem
	)

	_log_result(
		"Registered PurchasingPowerSystem available",
		purchasing_power_ok
	)

	if not purchasing_power_ok:
		return false

	var military_system: SimulationSystem = simulation.get_system(
		"military_system"
	)

	var military_system_ok: bool = (
		military_system != null
		and military_system is MilitarySystem
	)

	_log_result(
		"Registered MilitarySystem available",
		military_system_ok
	)

	if not military_system_ok:
		return false

	# ============================================================
	# ISOLATED FIXTURE WORLD
	# ============================================================

	var fixture_world: WorldState = WorldState.new(
		SimulationConfig.create_default()
	)

	# ------------------------------------------------------------
	# ENTITY A — POPULATION / INDUSTRY / GOVERNMENT-RESOURCE FLOW
	# ------------------------------------------------------------

	var industry_entity: SimEntity = SimEntity.new(
		"step_7_4_allocation_consequences_industry",
		"Step 7.4 Allocation Consequences Industry Fixture",
		"country"
	)

	var industry_resources: ResourceComponent = ResourceComponent.new(
		industry_entity.id
	)

	var industry_component: IndustryComponent = IndustryComponent.new(
		industry_entity.id
	)

	var population_component: PopulationComponent = PopulationComponent.new(
		industry_entity.id
	)

	var economy_component: EconomyComponent = EconomyComponent.new(
		industry_entity.id
	)

	var infrastructure_component: InfrastructureComponent = InfrastructureComponent.new(
		industry_entity.id
	)

	industry_entity.add_component(
		industry_resources
	)
	industry_entity.add_component(
		industry_component
	)
	industry_entity.add_component(
		population_component
	)
	industry_entity.add_component(
		economy_component
	)
	industry_entity.add_component(
		infrastructure_component
	)

	fixture_world.add_entity(
		industry_entity
	)

	# ------------------------------------------------------------
	# Entity A physical/economic fixture.
	# ------------------------------------------------------------

	industry_resources.set_state(
		"domestic_accessible_supply",
		{
			"food": 10.0,
			"iron": 10.0,
			"coal": 5.0
		}
	)

	industry_resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {
				"food": 20.0
			},
			"industry": {
				"iron": 20.0,
				"coal": 10.0
			},
			"government": {
				"food": 10.0
			},
			"military": {}
		}
	)

	industry_resources.set_state(
		"priority_allocated_supply_by_category",
		{
			"food": {
				"population": 10.0,
				"government": 0.0
			},
			"iron": {
				"industry": 10.0
			},
			"coal": {
				"industry": 5.0
			}
		}
	)

	industry_resources.set_state(
		"priority_allocation_unmet_by_category",
		{
			"food": {
				"population": 10.0,
				"government": 10.0
			},
			"iron": {
				"industry": 10.0
			},
			"coal": {
				"industry": 5.0
			}
		}
	)

	industry_resources.set_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{
			"food": {
				"population": 0.5,
				"government": 0.0
			},
			"iron": {
				"industry": 0.5
			},
			"coal": {
				"industry": 0.5
			}
		}
	)

	industry_resources.set_state(
		"priority_allocation_shortfall_ratio_by_category",
		{
			"food": {
				"population": 0.5,
				"government": 1.0
			},
			"iron": {
				"industry": 0.5
			},
			"coal": {
				"industry": 0.5
			}
		}
	)

	industry_resources.set_state(
		"priority_allocation_remaining_supply",
		{
			"food": 0.0,
			"iron": 0.0,
			"coal": 0.0
		}
	)

	industry_resources.set_state(
		"priority_allocation_exhausted",
		{
			"food": true,
			"iron": true,
			"coal": true
		}
	)

	industry_resources.set_state(
		"production_process_resource_availability",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)

	industry_resources.set_state(
		"stockpile",
		{
			"iron": 20.0,
			"coal": 10.0,
			"steel": 0.0
		}
	)

	industry_resources.set_state(
		"base_price",
		{
			"food": 2.0
		}
	)

	industry_resources.set_state(
		"current_price",
		{
			"food": 2.0
		}
	)

	population_component.set_state(
		"effective_labor_capacity",
		100.0
	)

	population_component.set_state(
		"effective_skilled_labor_capacity",
		100.0
	)

	economy_component.set_state(
		"labor_income",
		100.0
	)

	economy_component.set_state(
		"average_wage",
		10.0
	)

	economy_component.set_state(
		"employed_labor_units",
		10.0
	)

	economy_component.set_state(
		"investment_capacity",
		100.0
	)

	infrastructure_component.set_state(
		"power",
		1.0
	)

	infrastructure_component.set_state(
		"process_maintenance_capacity",
		{}
	)

	industry_component.set_state(
		"processes",
		{
			"steel_basic": {
				"active": true,
				"capacity": 10.0,
				"efficiency": 1.0
			}
		}
	)

	industry_component.set_state(
		"process_adoption",
		{
			"steel_basic": 1.0
		}
	)

	# ------------------------------------------------------------
	# ENTITY B — MILITARY CONSEQUENCE
	# ------------------------------------------------------------

	var military_entity: SimEntity = SimEntity.new(
		"step_7_4_allocation_consequences_military",
		"Step 7.4 Allocation Consequences Military Fixture",
		"country"
	)

	var military_resources: ResourceComponent = ResourceComponent.new(
		military_entity.id
	)

	var military_component: MilitaryComponent = MilitaryComponent.new(
		military_entity.id
	)

	military_entity.add_component(
		military_resources
	)
	military_entity.add_component(
		military_component
	)

	fixture_world.add_entity(
		military_entity
	)

	military_resources.set_state(
		"domestic_accessible_supply",
		{
			"oil": 4.0
		}
	)

	military_resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {},
			"industry": {},
			"government": {},
			"military": {
				"oil": 10.0
			}
		}
	)

	military_resources.set_state(
		"priority_allocated_supply_by_category",
		{
			"oil": {
				"military": 4.0
			}
		}
	)

	military_resources.set_state(
		"priority_allocation_unmet_by_category",
		{
			"oil": {
				"military": 6.0
			}
		}
	)

	military_resources.set_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{
			"oil": {
				"military": 0.4
			}
		}
	)

	military_resources.set_state(
		"priority_allocation_shortfall_ratio_by_category",
		{
			"oil": {
				"military": 0.6
			}
		}
	)

	military_resources.set_state(
		"priority_allocation_remaining_supply",
		{
			"oil": 0.0
		}
	)

	military_resources.set_state(
		"priority_allocation_exhausted",
		{
			"oil": true
		}
	)

	military_resources.set_state(
		"net_balance",
		{
			"oil": 4.0
		}
	)

	# ============================================================
	# CONSEQUENCE RESOLUTION
	# ============================================================

	allocation_system.process_month(
		fixture_world
	)

	var industry_allocated: Dictionary = _get_dictionary(
		industry_resources,
		"allocation_consequence_allocated_by_category"
	)

	var industry_unmet: Dictionary = _get_dictionary(
		industry_resources,
		"allocation_consequence_unmet_by_category"
	)

	var industry_fulfillment: Dictionary = _get_dictionary(
		industry_resources,
		"allocation_consequence_fulfillment_ratio_by_category"
	)

	var industry_ratios_ok: bool = (
		_approx_equal(
			_get_number(_get_nested_dictionary(industry_fulfillment, "food"), "population", -1.0),
			0.5
		)
		and _approx_equal(
			_get_number(_get_nested_dictionary(industry_fulfillment, "food"), "government", -1.0),
			0.0
		)
		and _approx_equal(
			_get_number(_get_nested_dictionary(industry_fulfillment, "iron"), "industry", -1.0),
			0.5
		)
	)

	_log_result(
		"Allocation consequence fulfillment ratios are propagated by resource/category",
		industry_ratios_ok
	)

	var unmet_propagation_ok: bool = (
		_approx_equal(
			_get_number(_get_nested_dictionary(industry_unmet, "food"), "population", -1.0),
			10.0
		)
		and _approx_equal(
			_get_number(_get_nested_dictionary(industry_unmet, "food"), "government", -1.0),
			10.0
		)
		and _approx_equal(
			_get_number(_get_nested_dictionary(industry_allocated, "iron"), "industry", -1.0),
			10.0
		)
	)

	_log_result(
		"Aggregate unmet allocation is explicitly propagated to downstream consumers",
		unmet_propagation_ok
	)

	var reconciliation_ok: bool = (
		_max_reconciliation_error(
			_get_dictionary(
				industry_resources,
				"allocation_consequence_reconciliation_error"
			)
		) <= EPSILON
		and
		_max_reconciliation_error(
			_get_dictionary(
				military_resources,
				"allocation_consequence_reconciliation_error"
			)
		) <= EPSILON
	)

	_log_result(
		"Allocation consequence ledger reconciles allocated, unmet and remaining supply",
		reconciliation_ok
	)

	# ============================================================
	# IDEMPOTENCE
	# ============================================================

	var before_repeat: Dictionary = (
		_get_dictionary(
			industry_resources,
			"allocation_consequence_ledger"
		).duplicate(true)
	)

	allocation_system.process_month(
		fixture_world
	)

	var after_repeat: Dictionary = (
		_get_dictionary(
			industry_resources,
			"allocation_consequence_ledger"
		).duplicate(true)
	)

	var idempotence_ok: bool = (
		before_repeat == after_repeat
	)

	_log_result(
		"Repeated allocation consequence processing is deterministic and idempotent",
		idempotence_ok
	)

	# ============================================================
	# DOWNSTREAM POPULATION / GOVERNMENT CONSEQUENCES
	# ============================================================

	consumption_system.process_month(
		fixture_world
	)

	var industry_consumption: Dictionary = _get_dictionary(
		industry_resources,
		"consumption_by_category"
	)

	var population_consumption_ok: bool = (
		_approx_equal(
			_get_number(_get_nested_dictionary(industry_consumption, "population"), "food", -1.0),
			10.0
		)
	)

	var government_consumption_ok: bool = (
		_approx_equal(
			_get_number(_get_nested_dictionary(industry_consumption, "government"), "food", 0.0),
			0.0
		)
		and _approx_equal(
			_get_number(_get_dictionary(industry_resources, "government_resource_allocation_ratio"), "food", -1.0),
			0.0
		)
	)

	_log_result(
		"Population consumption uses allocated essential supply",
		population_consumption_ok
	)

	_log_result(
		"Government resource use exposes the allocated government pool",
		government_consumption_ok
	)

	# ============================================================
	# DOWNSTREAM CRITICAL PRODUCTION CONSEQUENCE
	# ============================================================

	production_system.process_month(
		fixture_world
	)

	var production_outcome: Dictionary = industry_component.get_production_outcome(
		"steel_basic"
	)

	var actual_production: float = _get_number(production_outcome, "actual_production", 0.0)

	var production_allocation_factor: float = _get_number(production_outcome, "allocation_constraint_factor", 1.0)

	var production_constraint_sources: Array = _get_array(
		production_outcome,
		"constraint_sources"
	)

	var production_consequence_ok: bool = (
		_approx_equal(
			actual_production,
			5.0
		)
		and _approx_equal(
			production_allocation_factor,
			0.5
		)
		and production_constraint_sources.has(
			"allocation_shortfall"
		)
	)

	_log_result(
		"Critical-production allocation constrains production through the existing production path",
		production_consequence_ok
	)

	# ============================================================
	# PURCHASING POWER CONSEQUENCE
	# ============================================================

	purchasing_power_system.process_month(
		fixture_world
	)

	var population_consumption_cost: float = float(
		economy_component.get_state(
			"population_consumption_cost",
			-1.0
		)
	)

	var purchasing_power_consequence_ok: bool = (
		_approx_equal(
			population_consumption_cost,
			20.0
		)
		and
		_approx_equal(
			float(
				economy_component.get_state(
					"income_coverage_ratio",
					-1.0
				)
			),
			5.0
		)
	)

	_log_result(
		"Allocated population consumption flows into the existing purchasing-power chain",
		purchasing_power_consequence_ok
	)

	# ============================================================
	# DOWNSTREAM MILITARY CONSEQUENCE
	# ============================================================

	military_resources.set_state(
		"production_process_resource_availability",
		{}
	)

	military_system.process_month(
		fixture_world
	)

	var military_allocation_factor: float = float(
		military_component.get_state(
			"resource_allocation_fulfillment",
			-1.0
		)
	)

	var military_resource_security: float = float(
		military_component.get_state(
			"resource_security",
			-1.0
		)
	)

	var military_consequence_ok: bool = (
		_approx_equal(
			military_allocation_factor,
			0.4
		)
		and
		_approx_equal(
			military_resource_security,
			0.4
		)
	)

	_log_result(
		"Military resource allocation constrains the existing military resource-security path",
		military_consequence_ok
	)

	# ============================================================
	# SNAPSHOT REPRESENTATION
	# ============================================================

	var fixture_snapshot: WorldSnapshot = WorldSnapshot.new()

	fixture_snapshot.capture(
		fixture_world
	)

	var industry_snapshot: Dictionary = (
		fixture_snapshot.entities.get(
			industry_entity.id,
			{}
		) as Dictionary
	)

	var industry_component_snapshot: Dictionary = _get_nested_dictionary(
		industry_snapshot,
		"components"
	)

	var industry_resource_snapshot: Dictionary = _get_nested_dictionary(
		industry_component_snapshot,
		"resources"
	)

	var industry_resource_state_snapshot: Dictionary = _get_nested_dictionary(
		industry_resource_snapshot,
		"state"
	)

	var snapshot_ok: bool = (
		industry_resource_state_snapshot.has(
			"allocation_consequence_allocated_by_category"
		)
		and industry_resource_state_snapshot.has(
			"allocation_consequence_unmet_by_category"
		)
		and industry_resource_state_snapshot.has(
			"allocation_consequence_ledger"
		)
		and industry_resource_state_snapshot.has(
			"critical_production_allocation_ratio"
		)
	)

	_log_result(
		"Allocation consequence state remains represented in world snapshot state",
		snapshot_ok
	)

	# ============================================================
	# STALE-STATE CLEARING
	# ============================================================

	for entity in fixture_world.entities.values():

		var resources: ResourceComponent = entity.get_component(
			"resources"
		) as ResourceComponent

		if resources == null:
			continue

		resources.set_state(
			"priority_allocated_supply_by_category",
			{}
		)

		resources.set_state(
			"priority_allocation_unmet_by_category",
			{}
		)

		resources.set_state(
			"priority_allocation_fulfillment_ratio_by_category",
			{}
		)

		resources.set_state(
			"priority_allocation_shortfall_ratio_by_category",
			{}
		)

		resources.set_state(
			"priority_allocation_remaining_supply",
			{}
		)

	allocation_system.process_month(
		fixture_world
	)

	var stale_cleared_ok: bool = (
		_get_dictionary(
			industry_resources,
			"allocation_consequence_allocated_by_category"
		).is_empty()
		and
		_get_dictionary(
			industry_resources,
			"critical_production_allocation_ratio"
		).is_empty()
		and
		_get_dictionary(
			military_resources,
			"military_resource_allocation_ratio"
		).is_empty()
	)

	_log_result(
		"Cleared upstream allocation state clears stale consequence state",
		stale_cleared_ok
	)

	# ============================================================
	# THREE-COUNTRY WORLD VALIDATION
	# ============================================================

	var three_country_world_ok: bool = (
		world.entities.size() == 3
		and world.entities.has("china")
		and world.entities.has("india")
		and world.entities.has("usa")
	)

	_log_result(
		"Three-country world validation remains structurally clean",
		three_country_world_ok
	)

	var all_passed: bool = (
		allocation_system_ok
		and consumption_system_ok
		and production_system_ok
		and purchasing_power_ok
		and military_system_ok
		and industry_ratios_ok
		and unmet_propagation_ok
		and reconciliation_ok
		and idempotence_ok
		and population_consumption_ok
		and government_consumption_ok
		and production_consequence_ok
		and purchasing_power_consequence_ok
		and military_consequence_ok
		and snapshot_ok
		and stale_cleared_ok
		and three_country_world_ok
	)

	TestLogger.write_line(
		"Allocation Consequences 7.4 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
