class_name Step19_7RecoveryCausalValidationTest
extends RefCounted


# ============================================================
# STEP 19.7 — RECOVERY CAUSAL VALIDATION
# ============================================================
#
# Controlled causal experiment:
#
# infrastructure damage
#     -> effective capacity loss
#     -> lower physical production
#     -> lower economic output
#     -> existing investment machinery creates recovery funding pool
#     -> reconstruction project is committed
#     -> monthly reconstruction progress
#     -> InfrastructureRecoverySystem reduces authoritative damage
#     -> next-cycle InfrastructureSystem refreshes effective capacity
#     -> ResourceSystem / ProductionProcessSystem / EconomySystem
#        restore physical and economic performance
#
# Architectural timing contract validated here:
#   InfrastructureSystem         = order 26
#   ResourceSystem               = order 30
#   ProductionProcessSystem     = order 35
#   EconomySystem                = order 57
#   ReconstructionInvestment    = order 98
#   InfrastructureRecovery      = order 99
#
# Therefore recovery at order 99 cannot retroactively change the
# effective infrastructure capacity already computed at order 26.
# The recovered damage becomes physically visible to downstream
# systems on the next monthly cycle.
#
# Authority rules:
#   InfrastructureInvestmentSystem owns creation of the investment pool.
#   InfrastructureReconstructionInvestmentSystem owns reconstruction
#       funding / project progress only.
#   InfrastructureRecoverySystem owns physical damage reduction.
#   InfrastructureSystem owns effective infrastructure capacity.
#   ResourceSystem owns resource-flow consequences.
#   ProductionProcessSystem owns realized production.
#   EconomySystem owns GDP / growth consequences.
#
# No second recovery, infrastructure, production, resource, or economy
# authority is introduced by this test.
# ============================================================

const TARGET_COUNTRY_ID := "india"
const TARGET_INFRASTRUCTURE_TYPE := "transport"
const DAMAGE_FRACTION := 0.50
const RECONSTRUCTION_COST := 20.0
const RECONSTRUCTION_MONTHS := 2
const INFRASTRUCTURE_INVESTMENT := 100.0
const INFRASTRUCTURE_INVESTMENT_RATE := 0.25


const EXPECTED_ORDER: Dictionary = {
	"infrastructure_system": 26,
	"resource_system": 30,
	"production_process_system": 35,
	"economy_system": 57,
	"infrastructure_reconstruction_investment_system": 98,
	"infrastructure_recovery_system": 99,
}


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + _pass_fail(passed)
	)


static func _approx(
	actual: float,
	expected: float,
	tolerance: float = 0.000001
) -> bool:
	return abs(actual - expected) <= tolerance


static func _float_state(
	component,
	key: String,
	default_value: float = 0.0
) -> float:
	if component == null:
		return default_value
	return float(
		component.get_state(
			key,
			default_value
		)
	)


static func _advance_test_month(world: WorldState) -> void:
	if world == null:
		return
	var next_month: int = int(world.current_date.get("month", 1)) + 1
	var year: int = int(world.current_date.get("year", 1950))
	if next_month > 12:
		next_month = 1
		year += 1
	world.current_date["year"] = year
	world.current_date["month"] = next_month
	world.current_date["day"] = int(world.current_date.get("day", 1))


static func _set_infrastructure_fixture(
	infrastructure: InfrastructureComponent
) -> void:
	var conditions: Dictionary = {}
	var damage: Dictionary = {}

	for infrastructure_type in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage"
	]:
		conditions[infrastructure_type] = 1.0
		damage[infrastructure_type] = 0.0
		infrastructure.set_state(infrastructure_type, 1.0)

	infrastructure.set_state("infrastructure_condition", conditions)
	infrastructure.set_state("infrastructure_damage", damage)
	infrastructure.set_state("infrastructure_damage_total", 0.0)
	infrastructure.set_state("infrastructure_damage_records", [])
	infrastructure.set_state("effective_infrastructure_capacity", {})
	infrastructure.set_state("infrastructure_capacity", {})
	infrastructure.set_state("total_capacity", 1.0)
	infrastructure.set_state("process_maintenance_capacity", {"machinery": 1.0})
	infrastructure.set_state("reconstruction_projects", [])


static func _set_resource_fixture(
	resources: ResourceComponent
) -> void:
	resources.set_state("production", {"iron": 20.0, "coal": 10.0})
	resources.set_state("consumption", {})
	resources.set_state("imports", {})
	resources.set_state("exports", {})
	resources.set_state("trade_imports", {})
	resources.set_state("trade_exports", {})
	resources.set_state("stockpile", {
		"iron": 0.0,
		"coal": 0.0,
		"steel": 0.0
	})
	resources.set_state("reserves", {
		"iron": 1000.0,
		"coal": 1000.0
	})
	resources.set_state("extraction_capacity", {
		"iron": 20.0,
		"coal": 10.0
	})
	resources.set_state("processing_capacity", {
		"iron": 20.0,
		"coal": 10.0
	})
	resources.set_state("production_efficiency", {
		"iron": 1.0,
		"coal": 1.0
	})
	resources.set_state("technology_efficiency", {
		"iron": 1.0,
		"coal": 1.0
	})
	resources.set_state("quality", {
		"iron": 1.0,
		"coal": 1.0
	})
	resources.set_state("accessibility", {
		"iron": 1.0,
		"coal": 1.0
	})
	resources.set_state("max_stockpile_capacity", {})
	resources.set_state("production_process_demand", {})
	resources.set_state("production_process_shortages", {})
	resources.set_state("production_process_shortage_ratio", {})
	resources.set_state("production_process_resource_availability", {})
	resources.set_state("infrastructure_capacity", {})


static func _set_industry_fixture(
	industry: IndustryComponent
) -> void:
	var processes_value: Variant = industry.get_state("processes", {})
	var processes: Dictionary = {}

	if typeof(processes_value) == TYPE_DICTIONARY:
		for raw_process_id in (processes_value as Dictionary).keys():
			var original_process = (processes_value as Dictionary)[raw_process_id]
			if typeof(original_process) != TYPE_DICTIONARY:
				continue
			processes[str(raw_process_id)] = original_process.duplicate(true)
			processes[str(raw_process_id)]["active"] = false

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state("processes", processes)
	industry.set_state("process_adoption", {"steel_basic": 1.0})
	industry.set_state("production_state", {})
	industry.set_state("production_totals", {})


static func _set_supporting_capacity_fixture(
	india
) -> void:
	var population = india.get_component("population")
	if population != null:
		population.set_state("effective_labor_capacity", 1000.0)
		population.set_state("effective_skilled_labor_capacity", 1000.0)

	var economy = india.get_component("economy")
	if economy != null:
		economy.set_state("investment_capacity", 1000.0)
		economy.set_state("resource_efficiency", 1.0)

	var infrastructure = india.get_component("infrastructure")
	if infrastructure != null:
		infrastructure.set_state("power", 1.0)
		infrastructure.set_state("industrial", 1.0)
		infrastructure.set_state(
			"process_maintenance_capacity",
			{"machinery": 1.0}
		)


static func _set_economy_fixture(
	economy
) -> void:
	economy.set_state("gdp", 1000.0)
	economy.set_state("growth_rate", 12.0)
	economy.set_state("inflation", 0.0)
	economy.set_state("unemployment", 0.0)
	economy.set_state("tax_revenue_rate", 0.0)
	economy.set_state("government_spending_rate", 0.0)
	economy.set_state("investment_rate", 0.0)
	economy.set_state("investment_to_capacity_rate", 0.0)
	economy.set_state("investment_capacity", 1000.0)
	economy.set_state("unallocated_industrial_capacity", 0.0)
	economy.set_state("treasury", 0.0)
	economy.set_state("government_debt", 0.0)
	economy.set_state("resource_efficiency", 1.0)
	economy.set_state("trade_efficiency", 1.0)
	economy.set_state("infrastructure_efficiency", 1.0)
	economy.set_state("production_efficiency", 1.0)
	economy.set_state("technology_efficiency", 1.0)
	economy.set_state("investment", INFRASTRUCTURE_INVESTMENT)
	economy.set_state(
		"infrastructure_investment_rate",
		INFRASTRUCTURE_INVESTMENT_RATE
	)
	economy.set_state("infrastructure_investment_budget", 0.0)
	economy.set_state("infrastructure_investment_this_month", 0.0)


static func _get_transport_effective(
	infrastructure: InfrastructureComponent
) -> float:
	var effective_state: Variant = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)
	if typeof(effective_state) != TYPE_DICTIONARY:
		return 0.0
	return float(
		(effective_state as Dictionary).get(
			TARGET_INFRASTRUCTURE_TYPE,
			0.0
		)
	)


static func _get_transport_damage(
	infrastructure: InfrastructureComponent
) -> float:
	var damage_state: Variant = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	if typeof(damage_state) != TYPE_DICTIONARY:
		return 0.0
	return float(
		(damage_state as Dictionary).get(
			TARGET_INFRASTRUCTURE_TYPE,
			0.0
		)
	)


static func _get_steel_output(
	industry: IndustryComponent
) -> float:
	var state: Variant = industry.get_state("production_state", {})
	if typeof(state) != TYPE_DICTIONARY:
		return 0.0
	var steel_state: Variant = (state as Dictionary).get("steel_basic", {})
	if typeof(steel_state) != TYPE_DICTIONARY:
		return 0.0
	return float(
		(steel_state as Dictionary).get(
			"actual_production",
			0.0
		)
	)


static func _get_project(
	reconstruction_system: InfrastructureReconstructionInvestmentSystem,
	india
) -> Dictionary:
	var projects: Array = reconstruction_system.get_projects(india)
	if projects.is_empty():
		return {}
	var last_value: Variant = projects[projects.size() - 1]
	if typeof(last_value) != TYPE_DICTIONARY:
		return {}
	return (last_value as Dictionary)


static func _run_downstream_chain(
	infrastructure_system: InfrastructureSystem,
	resource_system: ResourceSystem,
	production_system: ProductionProcessSystem,
	economy_system: EconomySystem,
	world: WorldState
) -> void:
	# This sequence matches the authoritative registered WORLD_UPDATE order
	# for these downstream systems. It is deliberately explicit so the test
	# can isolate the recovery timing boundary at orders 98 -> 99 -> 26(next).
	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system.process_month(world)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 19.7 — RECOVERY CAUSAL VALIDATION"
	)

	if world == null:
		_log_result("World available", false)
		return false
	if simulation == null:
		_log_result("Simulation available", false)
		return false

	_log_result("World available", true)
	_log_result("Simulation available", true)

	var infrastructure_system := simulation.get_system(
		"infrastructure_system"
	) as InfrastructureSystem
	var resource_system := simulation.get_system(
		"resource_system"
	) as ResourceSystem
	var production_system := simulation.get_system(
		"production_process_system"
	) as ProductionProcessSystem
	var economy_system := simulation.get_system(
		"economy_system"
	) as EconomySystem
	var investment_system := simulation.get_system(
		"infrastructure_investment_system"
	) as InfrastructureInvestmentSystem
	var reconstruction_system := simulation.get_system(
		"infrastructure_reconstruction_investment_system"
	) as InfrastructureReconstructionInvestmentSystem
	var recovery_system := simulation.get_system(
		"infrastructure_recovery_system"
	) as InfrastructureRecoverySystem
	var damage_system := simulation.get_system(
		"infrastructure_damage_system"
	) as InfrastructureDamageSystem

	var systems_available: bool = (
		infrastructure_system != null
		and resource_system != null
		and production_system != null
		and economy_system != null
		and investment_system != null
		and reconstruction_system != null
		and recovery_system != null
		and damage_system != null
	)
	_log_result(
		"Registered infrastructure / investment / reconstruction / recovery / downstream systems available",
		systems_available
	)
	if not systems_available:
		return false

	var order_entries: Array = simulation.get_system_order()
	var observed_orders: Dictionary = {}
	for entry_value in order_entries:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		observed_orders[str(entry.get("name", ""))] = int(entry.get("order", -1))

	var order_contract_pass: bool = true
	for system_name in EXPECTED_ORDER.keys():
		var expected_order: int = int(EXPECTED_ORDER[system_name])
		var actual_order: int = int(observed_orders.get(system_name, -1))
		if actual_order != expected_order:
			order_contract_pass = false
			TestLogger.write_line(
				"19.7 ORDER DIAGNOSTIC: "
				+ str(system_name)
				+ " expected="
				+ str(expected_order)
				+ " actual="
				+ str(actual_order)
			)
	_log_result(
		"Recovery causal systems retain the registered order contract",
		order_contract_pass
	)
	if not order_contract_pass:
		return false

	var india = world.get_entity(TARGET_COUNTRY_ID)
	if india == null:
		_log_result("India available", false)
		return false
	_log_result("India available", true)

	var infrastructure: InfrastructureComponent = india.get_component("infrastructure")
	var resources: ResourceComponent = india.get_component("resources")
	var industry: IndustryComponent = india.get_component("industry")
	var economy = india.get_component("economy")

	var components_available: bool = (
		infrastructure != null
		and resources != null
		and industry != null
		and economy != null
	)
	_log_result(
		"India infrastructure/resource/industry/economy components available",
		components_available
	)
	if not components_available:
		return false

	# ============================================================
	# EXACT RESTORATION SNAPSHOT
	# ============================================================
	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_active_events: Array = world.active_events.duplicate(true)

	var passed: bool = true

	# ============================================================
	# CONTROLLED FIXTURE
	# ============================================================
	_set_infrastructure_fixture(infrastructure)
	_set_resource_fixture(resources)
	_set_industry_fixture(industry)
	_set_supporting_capacity_fixture(india)
	_set_economy_fixture(economy)

	# Establish the controlled undamaged baseline using the actual live
	# infrastructure -> resource -> production -> economy authorities.
	_run_downstream_chain(
		infrastructure_system,
		resource_system,
		production_system,
		economy_system,
		world
	)

	var baseline_transport: float = _get_transport_effective(infrastructure)
	var baseline_production: float = _get_steel_output(industry)
	var baseline_growth: float = _float_state(
		economy,
		"effective_growth_rate",
		0.0
	)
	var baseline_output_factor: float = _float_state(
		economy,
		"production_output_factor",
		1.0
	)
	var baseline_gdp: float = _float_state(economy, "gdp", 0.0)

	var baseline_pass: bool = (
		_approx(baseline_transport, 1.0)
		and baseline_production > 0.0
		and baseline_growth > 0.0
		and baseline_gdp > 0.0
	)
	_log_result(
		"Controlled undamaged baseline resolves through the live physical/economic chain",
		baseline_pass
	)
	passed = passed and baseline_pass

	# Freeze the baseline state before creating the crisis so that the
	# comparison is against the same controlled world configuration.

	# ============================================================
	# CRISIS CREATION
	# ============================================================
	var fixture_event: SimulationEvent = SimulationEvent.new(
		"step19_7_recovery_fixture_event",
		"Step 19.7 Recovery Fixture",
		"infrastructure_damage"
	)
	fixture_event.add_target(TARGET_COUNTRY_ID)
	fixture_event.activate()
	world.add_active_event(fixture_event)

	var damage_created: bool = damage_system.apply_event_damage(
		world,
		TARGET_COUNTRY_ID,
		TARGET_INFRASTRUCTURE_TYPE,
		DAMAGE_FRACTION,
		fixture_event,
		"damage_event_19_7_transport",
		"controlled_recovery_causal_fixture"
	)
	_log_result(
		"Controlled infrastructure crisis creates attributable transport damage",
		damage_created
	)
	passed = passed and damage_created

	# Damage is created late in WORLD_UPDATE in the live architecture, so the
	# following downstream refresh is the first cycle in which the damage is
	# visible to effective infrastructure and its consumers.
	_run_downstream_chain(
		infrastructure_system,
		resource_system,
		production_system,
		economy_system,
		world
	)

	var damaged_transport: float = _get_transport_effective(infrastructure)
	var damaged_production: float = _get_steel_output(industry)
	var damaged_growth: float = _float_state(
		economy,
		"effective_growth_rate",
		0.0
	)
	var damaged_gdp: float = _float_state(economy, "gdp", 0.0)
	var damaged_output_factor: float = _float_state(
		economy,
		"production_output_factor",
		1.0
	)
	var damaged_damage: float = _get_transport_damage(infrastructure)

	# GDP is a cumulative state and this causal probe advances the live
	# economy by another monthly resolution. Therefore absolute GDP must not
	# be compared directly to the prior month's baseline GDP: a damaged month
	# can still have a higher GDP level than the previous month while its
	# growth/output performance is materially worse. The authoritative
	# economic-performance indicators for this same-cycle crisis comparison
	# are effective growth and production output factor.
	var crisis_pass: bool = (
		_approx(damaged_damage, DAMAGE_FRACTION)
		and damaged_transport < baseline_transport
		and damaged_production < baseline_production
		and damaged_growth < baseline_growth
		and damaged_output_factor < baseline_output_factor
	)
	TestLogger.write_line(
		"19.7 CRISIS DIAGNOSTIC: "
		+ "transport=" + str(baseline_transport) + "->" + str(damaged_transport)
		+ " production=" + str(baseline_production) + "->" + str(damaged_production)
		+ " effective_growth=" + str(baseline_growth) + "->" + str(damaged_growth)
		+ " output_factor=" + str(baseline_output_factor) + "->" + str(damaged_output_factor)
		+ " gdp_level=" + str(baseline_gdp) + "->" + str(damaged_gdp)
		+ " damage=" + str(damaged_damage)
	)
	_log_result(
		"Infrastructure damage lowers effective capacity, physical production, and economic performance",
		crisis_pass
	)
	passed = passed and crisis_pass

	# ============================================================
	# EXISTING INVESTMENT MACHINERY CREATES RECOVERY FUNDING
	# ============================================================
	economy.set_state("investment", INFRASTRUCTURE_INVESTMENT)
	economy.set_state(
		"infrastructure_investment_rate",
		INFRASTRUCTURE_INVESTMENT_RATE
	)
	economy.set_state("infrastructure_investment_budget", 0.0)
	investment_system.process_month(world)

	var monthly_allocation: float = investment_system.get_monthly_allocation(india)
	var investment_budget: float = investment_system.get_investment_budget(india)
	var investment_flow: float = _float_state(
		economy,
		"investment",
		-1.0
	)

	var investment_pool_pass: bool = (
		_approx(monthly_allocation, 25.0)
		and _approx(investment_budget, 25.0)
		and _approx(investment_flow, INFRASTRUCTURE_INVESTMENT)
	)
	_log_result(
		"Existing InfrastructureInvestmentSystem creates the recovery funding pool without changing investment flow",
		investment_pool_pass
	)
	passed = passed and investment_pool_pass

	# ============================================================
	# RECOVERY COMMITMENT
	# ============================================================
	var treasury_before_commit: float = _float_state(economy, "treasury", -1.0)
	var raw_transport_before_commit: float = _float_state(
		infrastructure,
		TARGET_INFRASTRUCTURE_TYPE,
		-1.0
	)
	var damage_before_commit: float = _get_transport_damage(infrastructure)

	var created_project: Dictionary = reconstruction_system.create_reconstruction_project(
		india,
		TARGET_INFRASTRUCTURE_TYPE,
		DAMAGE_FRACTION,
		RECONSTRUCTION_COST,
		RECONSTRUCTION_MONTHS
	)

	var project_created: bool = not created_project.is_empty()
	_log_result(
		"Reconstruction commitment is created from the existing investment budget",
		project_created
	)
	passed = passed and project_created

	var budget_after_commit: float = investment_system.get_investment_budget(india)
	var treasury_after_commit: float = _float_state(economy, "treasury", -1.0)
	var raw_transport_after_commit: float = _float_state(
		infrastructure,
		TARGET_INFRASTRUCTURE_TYPE,
		-1.0
	)
	var damage_after_commit: float = _get_transport_damage(infrastructure)

	var commitment_boundary_pass: bool = (
		_approx(budget_after_commit, 5.0)
		and _approx(treasury_after_commit, treasury_before_commit)
		and _approx(raw_transport_after_commit, raw_transport_before_commit)
		and _approx(damage_after_commit, damage_before_commit)
		and _approx(float(created_project.get("investment_funded", -1.0)), RECONSTRUCTION_COST)
		and str(created_project.get("funding_source", "")) == "infrastructure_investment"
		and str(created_project.get("status", "")) == "active"
		and _approx(float(created_project.get("progress", -1.0)), 0.0)
	)
	_log_result(
		"Recovery commitment changes funding/project state but does not directly restore physical infrastructure",
		commitment_boundary_pass
	)
	passed = passed and commitment_boundary_pass

	# Insufficient budget must reject a second commitment without mutation.
	var rejected_before_projects: Array = reconstruction_system.get_projects(india).duplicate(true)
	var rejected_before_budget: float = investment_system.get_investment_budget(india)
	var rejected_project: Dictionary = reconstruction_system.create_reconstruction_project(
		india,
		TARGET_INFRASTRUCTURE_TYPE,
		0.10,
		10.0,
		1
	)
	var rejected_after_projects: Array = reconstruction_system.get_projects(india).duplicate(true)
	var rejected_after_budget: float = investment_system.get_investment_budget(india)

	var insufficient_budget_pass: bool = (
		rejected_project.is_empty()
		and rejected_after_projects == rejected_before_projects
		and _approx(rejected_after_budget, rejected_before_budget)
	)
	_log_result(
		"Insufficient reconstruction budget rejects a second commitment without mutation",
		insufficient_budget_pass
	)
	passed = passed and insufficient_budget_pass

	# ============================================================
	# RECOVERY CYCLE 1 — PROGRESS, THEN RECOVERY, THEN NEXT-CYCLE REFRESH
	# ============================================================
	_advance_test_month(world)

	reconstruction_system.process_month(world)

	var month_one_project: Dictionary = _get_project(
		reconstruction_system,
		india
	)
	var month_one_progress_pass: bool = (
		_approx(float(month_one_project.get("progress", -1.0)), 0.5)
		and str(month_one_project.get("status", "")) == "active"
		and _approx(_get_transport_damage(infrastructure), DAMAGE_FRACTION)
		and _approx(_get_transport_effective(infrastructure), damaged_transport)
	)
	_log_result(
		"Recovery month 1 advances reconstruction progress without recovery yet",
		month_one_progress_pass
	)
	passed = passed and month_one_progress_pass

	recovery_system.process_month(world)

	var month_one_recovered_damage: float = _get_transport_damage(infrastructure)
	var month_one_project_after_recovery: Dictionary = _get_project(
		reconstruction_system,
		india
	)

	var expected_month_one_damage: float = DAMAGE_FRACTION * 0.50
	var recovery_ledger_pass: bool = (
		_approx(month_one_recovered_damage, expected_month_one_damage)
		and _approx(
			float(month_one_project_after_recovery.get("applied_damage_reduction", -1.0)),
			DAMAGE_FRACTION * 0.50
		)
		and _approx(
			_get_transport_effective(infrastructure),
			damaged_transport
		)
	)
	_log_result(
		"Recovery authority reduces damage but cannot retroactively rewrite the already-computed same-cycle effective capacity",
		recovery_ledger_pass
	)
	passed = passed and recovery_ledger_pass

	# The next-cycle refresh is the point where InfrastructureSystem sees the
	# damage reduction made at order 99 and propagates it downstream.
	_run_downstream_chain(
		infrastructure_system,
		resource_system,
		production_system,
		economy_system,
		world
	)

	var month_one_effective_transport: float = _get_transport_effective(infrastructure)
	var month_one_production: float = _get_steel_output(industry)
	var month_one_growth: float = _float_state(
		economy,
		"effective_growth_rate",
		0.0
	)
	var month_one_gdp: float = _float_state(economy, "gdp", 0.0)

	var month_one_downstream_pass: bool = (
		_approx(month_one_effective_transport, 0.75)
		and month_one_production > damaged_production
		and month_one_growth > damaged_growth
		and month_one_gdp > damaged_gdp
		and _approx(
			_float_state(infrastructure, TARGET_INFRASTRUCTURE_TYPE, 0.0),
			raw_transport_before_commit
		)
	)
	_log_result(
		"Next-cycle infrastructure refresh restores capacity and improves physical/economic performance",
		month_one_downstream_pass
	)
	passed = passed and month_one_downstream_pass

	# ============================================================
	# RECOVERY CYCLE 2 — COMPLETE RECOVERY
	# ============================================================
	_advance_test_month(world)

	reconstruction_system.process_month(world)
	recovery_system.process_month(world)

	var final_damage: float = _get_transport_damage(infrastructure)
	var final_project: Dictionary = _get_project(
		reconstruction_system,
		india
	)

	var recovery_completion_pass: bool = (
		_approx(final_damage, 0.0)
		and _approx(
			float(final_project.get("applied_damage_reduction", -1.0)),
			DAMAGE_FRACTION
		)
		and str(final_project.get("status", "")) == "recovered"
		and bool(final_project.get("recovery_completed", false))
		and _approx(float(final_project.get("progress", -1.0)), 1.0)
	)
	_log_result(
		"Second reconstruction cycle completes the recovery ledger and clears attributable damage",
		recovery_completion_pass
	)
	passed = passed and recovery_completion_pass

	_run_downstream_chain(
		infrastructure_system,
		resource_system,
		production_system,
		economy_system,
		world
	)

	var final_transport: float = _get_transport_effective(infrastructure)
	var final_production: float = _get_steel_output(industry)
	var final_growth: float = _float_state(
		economy,
		"effective_growth_rate",
		0.0
	)
	var final_gdp: float = _float_state(economy, "gdp", 0.0)
	var final_output_factor: float = _float_state(
		economy,
		"production_output_factor",
		0.0
	)

	var final_performance_pass: bool = (
		_approx(final_transport, baseline_transport)
		and _approx(final_production, baseline_production)
		and _approx(final_growth, baseline_growth)
		and _approx(final_output_factor, 1.0)
		and final_gdp > month_one_gdp
		and final_gdp > damaged_gdp
		and _approx(
			_float_state(infrastructure, TARGET_INFRASTRUCTURE_TYPE, 0.0),
			raw_transport_before_commit
		)
	)
	_log_result(
		"Completed recovery restores effective infrastructure, physical production, and economic performance",
		final_performance_pass
	)
	passed = passed and final_performance_pass

	# ============================================================
	# IDEMPOTENCE / NO OVER-RECOVERY
	# ============================================================
	recovery_system.process_month(world)
	infrastructure_system.process_month(world)
	var idempotent_damage: float = _get_transport_damage(infrastructure)
	var idempotent_transport: float = _get_transport_effective(infrastructure)

	var idempotence_pass: bool = (
		_approx(idempotent_damage, 0.0)
		and _approx(idempotent_transport, baseline_transport)
	)
	_log_result(
		"Completed recovery is idempotent and does not over-recover infrastructure",
		idempotence_pass
	)
	passed = passed and idempotence_pass

	# ============================================================
	# FIXTURE RESTORATION
	# ============================================================
	infrastructure.state = original_infrastructure_state.duplicate(true)
	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	world.current_date = original_date.duplicate(true)
	world.active_events = original_active_events.duplicate(true)

	var restoration_pass: bool = (
		infrastructure.state == original_infrastructure_state
		and resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
		and world.current_date == original_date
		and world.active_events == original_active_events
	)
	_log_result(
		"Step 19.7 fixture restoration",
		restoration_pass
	)
	passed = passed and restoration_pass

	TestLogger.write_line(
		"Step 19.7 recovery overall: "
		+ ("PASS" if passed else "FAIL")
	)
	TestLogger.write_line(
		"Step 19.7 Recovery Causal Validation test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
