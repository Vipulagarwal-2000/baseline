class_name Step19_5WarMilitaryBurdenCausalValidationTest
extends RefCounted


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]

const CONFLICT_ID := "step19_5_war_burden_fixture_conflict"
const DAMAGE_ID := "step19_5_war_burden_transport_damage"
const TARGET_COUNTRY_ID := "india"
const ATTACKER_COUNTRY_ID := "china"
const CONTROLLED_MILITARY_SPENDING := 0.80
const CONTROLLED_CONFLICT_INTENSITY := 0.80
const CONTROLLED_TRANSPORT_DAMAGE := 0.50


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func _get_float_state(
	component,
	key: String,
	default_value: float = 0.0
) -> float:
	if component == null:
		return default_value
	return float(component.get_state(key, default_value))


static func _get_category_total(resources, category: String) -> float:
	if resources == null:
		return 0.0

	var totals = resources.get_state(
		"consumption_total_by_category",
		{}
	)
	if typeof(totals) != TYPE_DICTIONARY:
		return 0.0

	return maxf(
		0.0,
		float(totals.get(category, 0.0))
	)


static func _get_production_output(industry) -> float:
	if industry == null:
		return 0.0

	var production_state = industry.get_state(
		"production_state",
		{}
	)
	if typeof(production_state) != TYPE_DICTIONARY:
		return 0.0

	var total: float = 0.0
	for raw_process_id in production_state.keys():
		var outcome = production_state[raw_process_id]
		if typeof(outcome) != TYPE_DICTIONARY:
			continue
		total += maxf(
			0.0,
			float(outcome.get("actual_production", 0.0))
		)

	return total


static func _get_effective_transport(infrastructure) -> float:
	if infrastructure == null:
		return 0.0

	var effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)
	if typeof(effective_capacity) != TYPE_DICTIONARY:
		return _get_float_state(
			infrastructure,
			"transport",
			0.0
		)

	return float(
		effective_capacity.get(
			"transport",
			_get_float_state(infrastructure, "transport", 0.0)
		)
	)


static func _capture_component_states(entity) -> Dictionary:
	var snapshot: Dictionary = {}
	if entity == null:
		return snapshot

	for component_id in entity.components.keys():
		var component = entity.components[component_id]
		if component == null:
			continue
		snapshot[str(component_id)] = component.state.duplicate(true)

	return snapshot


static func _restore_component_states(
	entity,
	original_component_states: Dictionary
) -> void:
	if entity == null:
		return

	for component_id in original_component_states.keys():
		var component = entity.get_component(str(component_id))
		if component == null:
			continue
		component.state = original_component_states[component_id].duplicate(true)


static func _restore_world_state(
	world: WorldState,
	india,
	original_component_states: Dictionary,
	original_active_events: Array,
	original_completed_events: Array,
	original_active_conflicts: Array,
	original_completed_conflicts: Array
) -> void:
	_restore_component_states(india, original_component_states)
	world.active_events = original_active_events.duplicate()
	world.completed_events = original_completed_events.duplicate()
	world.active_conflicts = original_active_conflicts.duplicate()
	world.completed_conflicts = original_completed_conflicts.duplicate()


static func _prepare_infrastructure_fixture(infrastructure) -> void:
	var conditions: Dictionary = {}
	var damage: Dictionary = {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		conditions[infrastructure_type] = 1.0
		damage[infrastructure_type] = 0.0
		infrastructure.set_state(infrastructure_type, 1.0)

	infrastructure.set_state("infrastructure_condition", conditions)
	infrastructure.set_state("infrastructure_damage", damage)
	infrastructure.set_state("infrastructure_damage_total", 0.0)
	infrastructure.set_state("effective_infrastructure_capacity", {})
	infrastructure.set_state("total_capacity", 1.0)


static func _prepare_resource_fixture(resources) -> void:
	resources.set_state(
		"production",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)
	resources.set_state("consumption", {})
	resources.set_state("imports", {})
	resources.set_state("exports", {})
	resources.set_state("trade_imports", {})
	resources.set_state("trade_exports", {})
	resources.set_state(
		"stockpile",
		{
			"iron": 0.0,
			"coal": 0.0,
			"steel": 0.0
		}
	)
	resources.set_state(
		"reserves",
		{
			"iron": 1000.0,
			"coal": 1000.0
		}
	)
	resources.set_state(
		"extraction_capacity",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)
	resources.set_state(
		"processing_capacity",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)
	resources.set_state(
		"production_efficiency",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)
	resources.set_state(
		"technology_efficiency",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)
	resources.set_state(
		"quality",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)
	resources.set_state(
		"accessibility",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)
	resources.set_state("max_stockpile_capacity", {})
	resources.set_state("production_process_demand", {})
	resources.set_state("production_process_shortages", {})
	resources.set_state("production_process_shortage_ratio", {})
	resources.set_state("production_process_resource_availability", {})
	resources.set_state("infrastructure_capacity", {})


static func _prepare_industry_fixture(industry) -> void:
	var processes = industry.get_state("processes", {})
	if typeof(processes) != TYPE_DICTIONARY:
		processes = {}

	var isolated_processes: Dictionary = {}
	for raw_process_id in processes.keys():
		var original_process = processes[raw_process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue
		isolated_processes[str(raw_process_id)] = original_process.duplicate(true)
		isolated_processes[str(raw_process_id)]["active"] = false

	isolated_processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state("processes", isolated_processes)
	industry.set_state("process_adoption", {"steel_basic": 1.0})
	industry.set_state("production_state", {})
	industry.set_state("production_totals", {})


static func _prepare_supporting_capacity_fixtures(entity) -> void:
	var population = entity.get_component("population")
	if population != null:
		population.set_state("effective_labor_capacity", 1000.0)
		population.set_state("effective_skilled_labor_capacity", 1000.0)

	var economy = entity.get_component("economy")
	if economy != null:
		economy.set_state("investment_capacity", 1000.0)
		economy.set_state("resource_efficiency", 1.0)

	var infrastructure = entity.get_component("infrastructure")
	if infrastructure != null:
		infrastructure.set_state("power", 1.0)
		infrastructure.set_state("industrial", 1.0)
		infrastructure.set_state(
			"process_maintenance_capacity",
			{
				"machinery": 1.0,
				"maintenance": 1.0
			}
		)


static func _configure_military_scenario(
	military,
	at_war: bool,
	spending: float
) -> void:
	military.set_state("at_war", at_war)
	military.set_state("military_spending", clampf(spending, 0.0, 1.0))


static func _run_military_resolution_pass(
	world: WorldState,
	systems: Dictionary
) -> void:
	# This path follows the validated cross-domain order for the military
	# demand/consumption branch. Production consequence is intentionally
	# tested separately so the two causal mechanisms do not contaminate each
	# other.
	systems["infrastructure_system"].process_month(world)
	if systems.get("infrastructure_bottleneck_system") != null:
		systems["infrastructure_bottleneck_system"].process_month(world)

	systems["resource_system"].process_month(world)
	systems["military_resource_demand_system"].process_month(world)
	systems["production_process_system"].process_month(world)
	systems["aggregate_demand_system"].process_month(world)

	# Allocation consequence state must be produced before AggregateConsumptionSystem
	# reads it. Otherwise the consumption stage can consume stale allocation state
	# restored from the pre-test snapshot rather than the current month's war demand.
	if systems.get("supply_demand_resolution_system") != null:
		systems["supply_demand_resolution_system"].process_month(world)
	if systems.get("resource_allocation_distribution_system") != null:
		systems["resource_allocation_distribution_system"].process_month(world)
	if systems.get("domestic_accessibility_system") != null:
		systems["domestic_accessibility_system"].process_month(world)
	if systems.get("scarce_resource_allocation_system") != null:
		systems["scarce_resource_allocation_system"].process_month(world)
	if systems.get("priority_class_allocation_system") != null:
		systems["priority_class_allocation_system"].process_month(world)
	if systems.get("allocation_consequences_system") != null:
		systems["allocation_consequences_system"].process_month(world)

	systems["aggregate_consumption_system"].process_month(world)
	systems["economy_system"].process_month(world)

	if systems.get("military_production_capacity_system") != null:
		systems["military_production_capacity_system"].process_month(world)
	if systems.get("military_resource_readiness_system") != null:
		systems["military_resource_readiness_system"].process_month(world)
	if systems.get("military_transport_logistics_system") != null:
		systems["military_transport_logistics_system"].process_month(world)
	if systems.get("military_port_naval_logistics_system") != null:
		systems["military_port_naval_logistics_system"].process_month(world)
	if systems.get("military_power_infrastructure_system") != null:
		systems["military_power_infrastructure_system"].process_month(world)

	systems["military_system"].process_month(world)
	systems["military_economic_pressure_system"].process_month(world)


static func _run_physical_production_pass(
	world: WorldState,
	systems: Dictionary
) -> void:
	# This is the already-verified Step 14.3 causal ordering:
	# Infrastructure -> Resource -> Production -> Economy.
	systems["infrastructure_system"].process_month(world)
	systems["resource_system"].process_month(world)
	systems["production_process_system"].process_month(world)
	systems["economy_system"].process_month(world)


static func _resolve_systems(simulation: SimulationEngine) -> Dictionary:
	var result: Dictionary = {}
	var system_ids: Array[String] = [
		"infrastructure_system",
		"infrastructure_damage_system",
		"resource_system",
		"production_process_system",
		"economy_system",
		"military_resource_demand_system",
		"aggregate_demand_system",
		"aggregate_consumption_system",
		"military_system",
		"military_economic_pressure_system",
		"infrastructure_bottleneck_system",
		"military_production_capacity_system",
		"military_resource_readiness_system",
		"military_transport_logistics_system",
		"military_port_naval_logistics_system",
		"military_power_infrastructure_system",
		"supply_demand_resolution_system",
		"resource_allocation_distribution_system",
		"domestic_accessibility_system",
		"scarce_resource_allocation_system",
		"priority_class_allocation_system",
		"allocation_consequences_system"
	]

	for system_id in system_ids:
		result[system_id] = simulation.get_system(system_id)

	return result


static func _required_systems_available(systems: Dictionary) -> bool:
	var required: Array[String] = [
		"infrastructure_system",
		"infrastructure_damage_system",
		"resource_system",
		"production_process_system",
		"economy_system",
		"military_resource_demand_system",
		"aggregate_demand_system",
		"aggregate_consumption_system",
		"military_system",
		"military_economic_pressure_system"
	]

	for system_id in required:
		if systems.get(system_id) == null:
			return false

	return true


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section("STEP 19.5 — WAR / MILITARY BURDEN CAUSAL VALIDATION")

	if world == null or simulation == null:
		_log_result("World / Simulation available", false)
		return false
	_log_result("World / Simulation available", true)

	var systems: Dictionary = _resolve_systems(simulation)
	var systems_ok: bool = _required_systems_available(systems)
	_log_result("Required Step 19.5 causal systems available", systems_ok)
	if not systems_ok:
		return false

	var india = world.get_entity(TARGET_COUNTRY_ID)
	if india == null:
		_log_result("India available", false)
		return false
	_log_result("India available", true)

	var military = india.get_component("military")
	var resources = india.get_component("resources")
	var infrastructure = india.get_component("infrastructure")
	var industry = india.get_component("industry")
	var economy = india.get_component("economy")

	var components_ok: bool = (
		military != null
		and resources != null
		and infrastructure != null
		and industry != null
		and economy != null
	)
	_log_result(
		"India military/resource/infrastructure/industry/economy components available",
		components_ok
	)
	if not components_ok:
		return false

	var original_component_states: Dictionary = _capture_component_states(india)
	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()
	var original_active_conflicts: Array = world.active_conflicts.duplicate()
	var original_completed_conflicts: Array = world.completed_conflicts.duplicate()

	var passed: bool = true

	# ============================================================
	# 19.5.1 — MILITARY DEMAND / CONSUMPTION RESPONSE
	# ============================================================

	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	_configure_military_scenario(
		military,
		false,
		_get_float_state(military, "military_spending", 0.30)
	)

	_run_military_resolution_pass(world, systems)

	var baseline_demand: float = _get_float_state(
		military,
		"resource_demand_total",
		0.0
	)
	var baseline_military_consumption: float = _get_category_total(
		resources,
		"military"
	)
	var baseline_military_burden: float = _get_float_state(
		military,
		"military_economic_burden",
		0.0
	)
	var baseline_economic_pressure: float = _get_float_state(
		economy,
		"economic_pressure",
		0.0
	)

	_log_result(
		"Baseline peacetime military demand is measurable",
		baseline_demand > 0.0
	)
	passed = passed and baseline_demand > 0.0

	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	_configure_military_scenario(
		military,
		true,
		CONTROLLED_MILITARY_SPENDING
	)

	_run_military_resolution_pass(world, systems)

	var war_demand: float = _get_float_state(
		military,
		"resource_demand_total",
		0.0
	)
	var war_military_consumption: float = _get_category_total(
		resources,
		"military"
	)
	var war_multiplier: float = _get_float_state(
		military,
		"resource_demand_war_multiplier",
		0.0
	)
	var war_military_burden: float = _get_float_state(
		military,
		"military_economic_burden",
		0.0
	)
	var war_economic_pressure: float = _get_float_state(
		economy,
		"economic_pressure",
		0.0
	)

	var demand_pass: bool = war_demand > baseline_demand
	_log_result("War activity increases authoritative military resource demand", demand_pass)
	passed = passed and demand_pass

	var multiplier_pass: bool = is_equal_approx(war_multiplier, 1.50)
	_log_result(
		"War demand uses the existing bounded 1.50 activity multiplier",
		multiplier_pass
	)
	passed = passed and multiplier_pass

	var consumption_pass: bool = war_military_consumption > baseline_military_consumption
	_log_result(
		"Higher military demand becomes higher domestic military resource consumption",
		consumption_pass
	)
	passed = passed and consumption_pass

	var burden_pass: bool = war_military_burden > baseline_military_burden
	_log_result(
		"Authoritative military economic burden increases under controlled war state",
		burden_pass
	)
	passed = passed and burden_pass

	var economic_pressure_pass: bool = war_economic_pressure > baseline_economic_pressure
	_log_result(
		"War / military burden increases economic pressure",
		economic_pressure_pass
	)
	passed = passed and economic_pressure_pass

	# ============================================================
	# 19.5.3 + 19.5.4 — CONFLICT / LOGISTICS / DAMAGE
	# ============================================================

	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	_configure_military_scenario(
		military,
		true,
		CONTROLLED_MILITARY_SPENDING
	)

	var fixture_conflict := MilitaryConflict.new(
		CONFLICT_ID,
		ATTACKER_COUNTRY_ID,
		TARGET_COUNTRY_ID
	)
	fixture_conflict.set_intensity(CONTROLLED_CONFLICT_INTENSITY)
	fixture_conflict.activate()
	world.add_active_conflict(fixture_conflict)

	var conflict_damage_created: bool = (
		systems["infrastructure_damage_system"].apply_conflict_damage(
			world,
			TARGET_COUNTRY_ID,
			"transport",
			CONTROLLED_TRANSPORT_DAMAGE,
			fixture_conflict,
			DAMAGE_ID,
			"step19_5_controlled_war_burden_fixture"
		)
	)

	_log_result(
		"Registered military conflict creates controlled transport burden",
		conflict_damage_created
	)
	passed = passed and conflict_damage_created

	_run_military_resolution_pass(world, systems)

	var war_logistics_modifier: float = _get_float_state(
		military,
		"transport_logistics_modifier",
		1.0
	)
	var war_logistics_constraint: float = _get_float_state(
		military,
		"transport_logistics_constraint",
		0.0
	)
	var effective_transport: float = _get_effective_transport(infrastructure)
	var raw_transport: float = _get_float_state(infrastructure, "transport", 0.0)

	var logistics_pass: bool = (
		war_logistics_modifier < 1.0
		and war_logistics_constraint > 0.0
	)
	_log_result(
		"War conflict burden increases strategic logistics pressure",
		logistics_pass
	)
	passed = passed and logistics_pass

	var effective_transport_pass: bool = (
		effective_transport < raw_transport
		and effective_transport < 1.0
	)
	_log_result(
		"Conflict burden reduces effective transport capacity without rewriting raw capacity",
		effective_transport_pass
	)
	passed = passed and effective_transport_pass

	var damage_state = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	var recorded_damage: float = 0.0
	if typeof(damage_state) == TYPE_DICTIONARY:
		recorded_damage = float(damage_state.get("transport", 0.0))

	var damage_record_pass: bool = is_equal_approx(
		recorded_damage,
		CONTROLLED_TRANSPORT_DAMAGE
	)
	_log_result(
		"Conflict damage is recorded as an attributable infrastructure burden",
		damage_record_pass
	)
	passed = passed and damage_record_pass

	var raw_transport_preserved: bool = is_equal_approx(
		raw_transport,
		_get_float_state(infrastructure, "transport", raw_transport)
	)
	# The previous line intentionally compares the live authoritative raw key;
	# use the pre-test snapshot for the actual preservation assertion below.
	var original_raw_transport: float = float(
		original_component_states["infrastructure"].get("transport", 0.0)
	)
	raw_transport_preserved = is_equal_approx(raw_transport, original_raw_transport)
	_log_result(
		"War damage does not overwrite authoritative raw transport capacity",
		raw_transport_preserved
	)
	passed = passed and raw_transport_preserved

	# ============================================================
	# 19.5.5 + 19.5.6 — TRANSPORT DAMAGE -> RESOURCE -> PRODUCTION -> GDP
	# ============================================================
	# This sub-experiment deliberately isolates the physical chain from the
	# military consumption chain. It reuses the validated Step 14.3 fixture.

	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)

	# Baseline physical month.
	_run_physical_production_pass(world, systems)

	var baseline_physical_output: float = _get_production_output(industry)
	var baseline_gdp: float = _get_float_state(economy, "gdp", 0.0)
	var baseline_iron: float = float(
		resources.get_state("actual_production", {}).get("iron", 0.0)
	)
	var baseline_coal: float = float(
		resources.get_state("actual_production", {}).get("coal", 0.0)
	)
	var baseline_total_capacity: float = _get_float_state(
		infrastructure,
		"total_capacity",
		0.0
	)

	var baseline_physical_pass: bool = (
		is_equal_approx(baseline_total_capacity, 1.0)
		and is_equal_approx(baseline_iron, 20.0)
		and is_equal_approx(baseline_coal, 10.0)
		and baseline_physical_output > 0.0
	)
	_log_result(
		"Isolated peacetime transport-production baseline is valid",
		baseline_physical_pass
	)
	passed = passed and baseline_physical_pass

	# Restore the complete pre-test state before the damaged economic comparison.
	# This keeps both GDP observations anchored to the same starting GDP; without
	# this restore the damaged case starts one monthly growth step later and can
	# still have a numerically higher GDP despite lower production.
	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)
	_configure_military_scenario(military, true, CONTROLLED_MILITARY_SPENDING)

	var physical_conflict := MilitaryConflict.new(
		CONFLICT_ID + "_physical",
		ATTACKER_COUNTRY_ID,
		TARGET_COUNTRY_ID
	)
	physical_conflict.set_intensity(CONTROLLED_CONFLICT_INTENSITY)
	physical_conflict.activate()
	world.add_active_conflict(physical_conflict)

	var physical_damage_created: bool = (
		systems["infrastructure_damage_system"].apply_conflict_damage(
			world,
			TARGET_COUNTRY_ID,
			"transport",
			CONTROLLED_TRANSPORT_DAMAGE,
			physical_conflict,
			DAMAGE_ID + "_physical",
			"step19_5_isolated_physical_chain"
		)
	)
	passed = passed and physical_damage_created

	# Month N: infrastructure and ResourceSystem settle the physical supply shock.
	_run_physical_production_pass(world, systems)

	var damaged_total_capacity: float = _get_float_state(
		infrastructure,
		"total_capacity",
		0.0
	)
	var damaged_effective_transport: float = _get_effective_transport(infrastructure)
	var damaged_iron: float = float(
		resources.get_state("actual_production", {}).get("iron", 0.0)
	)
	var damaged_coal: float = float(
		resources.get_state("actual_production", {}).get("coal", 0.0)
	)

	var expected_total_capacity: float = (
		0.5 + 1.0 + 1.0 + 1.0 + 1.0 + 1.0 + 1.0
	) / 7.0

	var damage_capacity_pass: bool = (
		is_equal_approx(damaged_effective_transport, 0.5)
		and is_equal_approx(damaged_total_capacity, expected_total_capacity)
		and damaged_iron < baseline_iron
		and damaged_coal < baseline_coal
	)
	_log_result(
		"Conflict damage reduces effective infrastructure and physical resource production",
		damage_capacity_pass
	)
	passed = passed and damage_capacity_pass

	var damaged_physical_output: float = _get_production_output(industry)
	var damaged_gdp: float = _get_float_state(economy, "gdp", 0.0)

	var production_pass: bool = damaged_physical_output < baseline_physical_output
	_log_result(
		"War / infrastructure burden produces lower realized production",
		production_pass
	)
	passed = passed and production_pass

	var economic_output_pass: bool = damaged_gdp < baseline_gdp
	_log_result(
		"Lower production propagates into lower GDP",
		economic_output_pass
	)
	passed = passed and economic_output_pass

	# ============================================================
	# DIAGNOSTICS
	# ============================================================

	TestLogger.write_line(
		"Step 19.5 diagnostics | "
		+ "military_demand=" + str(baseline_demand) + "->" + str(war_demand)
		+ " military_consumption=" + str(baseline_military_consumption) + "->" + str(war_military_consumption)
		+ " logistics_modifier=" + str(war_logistics_modifier)
		+ " effective_transport=" + str(effective_transport) + "->" + str(damaged_effective_transport)
		+ " resource_iron=" + str(baseline_iron) + "->" + str(damaged_iron)
		+ " resource_coal=" + str(baseline_coal) + "->" + str(damaged_coal)
		+ " production=" + str(baseline_physical_output) + "->" + str(damaged_physical_output)
		+ " gdp=" + str(baseline_gdp) + "->" + str(damaged_gdp)
		+ " military_burden=" + str(baseline_military_burden) + "->" + str(war_military_burden)
		+ " economic_pressure=" + str(baseline_economic_pressure) + "->" + str(war_economic_pressure)
	)

	# ============================================================
	# EXACT RESTORATION
	# ============================================================

	_restore_world_state(
		world,
		india,
		original_component_states,
		original_active_events,
		original_completed_events,
		original_active_conflicts,
		original_completed_conflicts
	)

	var restoration_ok: bool = (
		world.active_events == original_active_events
		and world.completed_events == original_completed_events
		and world.active_conflicts == original_active_conflicts
		and world.completed_conflicts == original_completed_conflicts
	)

	for component_id in original_component_states.keys():
		var component = india.get_component(str(component_id))
		if component == null or component.state != original_component_states[component_id]:
			restoration_ok = false
			break

	_log_result("Step 19.5 fixture restoration", restoration_ok)
	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 19.5 War / Military Burden Causal Validation test passed: "
		+ ("true" if passed else "false")
	)
	return passed
