class_name InfrastructureEconomicConsequencesTest
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


static func _log_result(
	label: String,
	passed: bool
) -> void:
	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)


static func _approx(
	actual: float,
	expected: float,
	tolerance: float = 0.000001
) -> bool:
	return abs(actual - expected) <= tolerance


static func _log_diagnostics(
	label: String,
	values: Dictionary
) -> void:
	var parts: Array[String] = []
	for key in values.keys():
		parts.append(str(key) + "=" + str(values[key]))
	TestLogger.write_line(
		"14.4 DIAGNOSTIC [" + label + "]: " + ", ".join(parts)
	)


static func _prepare_infrastructure_fixture(
	infrastructure: InfrastructureComponent
) -> void:
	var conditions: Dictionary = {}
	var damage: Dictionary = {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		conditions[infrastructure_type] = 1.0
		damage[infrastructure_type] = 0.0
		infrastructure.set_state(
			infrastructure_type,
			1.0
		)

	infrastructure.set_state(
		"infrastructure_condition",
		conditions
	)
	infrastructure.set_state(
		"infrastructure_damage",
		damage
	)
	infrastructure.set_state(
		"infrastructure_damage_total",
		0.0
	)
	infrastructure.set_state(
		"effective_infrastructure_capacity",
		{}
	)
	infrastructure.set_state(
		"total_capacity",
		1.0
	)


static func _prepare_resource_fixture(
	resources: ResourceComponent
) -> void:
	resources.set_state(
		"production",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)
	resources.set_state(
		"consumption",
		{}
	)
	resources.set_state(
		"imports",
		{}
	)
	resources.set_state(
		"exports",
		{}
	)
	resources.set_state(
		"trade_imports",
		{}
	)
	resources.set_state(
		"trade_exports",
		{}
	)
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
	resources.set_state(
		"max_stockpile_capacity",
		{}
	)
	resources.set_state(
		"production_process_demand",
		{}
	)
	resources.set_state(
		"production_process_shortages",
		{}
	)
	resources.set_state(
		"production_process_shortage_ratio",
		{}
	)
	resources.set_state(
		"production_process_resource_availability",
		{}
	)
	resources.set_state(
		"infrastructure_capacity",
		{}
	)


static func _prepare_industry_fixture(
	industry: IndustryComponent
) -> void:
	var processes = industry.get_state(
		"processes",
		{}
	)

	if typeof(processes) != TYPE_DICTIONARY:
		processes = {}

	var isolated_processes: Dictionary = {}

	for raw_process_id in processes.keys():
		var original_process = processes[raw_process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		isolated_processes[str(raw_process_id)] = (
			original_process.duplicate(true)
		)
		isolated_processes[str(raw_process_id)]["active"] = false

	isolated_processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)
	industry.set_state(
		"process_adoption",
		{
			"steel_basic": 1.0
		}
	)
	industry.set_state(
		"production_state",
		{}
	)
	industry.set_state(
		"production_totals",
		{}
	)


static func _prepare_supporting_capacity_fixtures(
	entity
) -> void:

	var population = entity.get_component(
		"population"
	)

	if population != null:
		population.set_state(
			"effective_labor_capacity",
			1000.0
		)
		population.set_state(
			"effective_skilled_labor_capacity",
			1000.0
		)

	var economy = entity.get_component(
		"economy"
	)

	if economy != null:
		economy.set_state(
			"investment_capacity",
			1000.0
		)
		economy.set_state(
			"resource_efficiency",
			1.0
		)

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure != null:
		infrastructure.set_state(
			"power",
			1.0
		)
		infrastructure.set_state(
			"industrial",
			1.0
		)
		infrastructure.set_state(
			"process_maintenance_capacity",
			{
				"machinery": 1.0
			}
		)


static func _prepare_economy_fixture(
	entity
) -> void:

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		return

	economy.set_state(
		"gdp",
		1000.0
	)
	economy.set_state(
		"growth_rate",
		12.0
	)
	economy.set_state(
		"inflation",
		0.0
	)
	economy.set_state(
		"unemployment",
		0.0
	)
	economy.set_state(
		"tax_revenue_rate",
		0.0
	)
	economy.set_state(
		"government_spending_rate",
		0.0
	)
	economy.set_state(
		"investment_rate",
		0.0
	)
	economy.set_state(
		"investment_to_capacity_rate",
		0.0
	)
	# ProductionProcessSystem uses the existing EconomyComponent
	# investment_capacity as its capital-capacity pool. Keep that
	# pool sufficiently large so capital is neutral in this test;
	# infrastructure damage remains the only causal perturbation.
	economy.set_state(
		"investment_capacity",
		1000.0
	)
	economy.set_state(
		"unallocated_industrial_capacity",
		0.0
	)
	economy.set_state(
		"treasury",
		0.0
	)
	economy.set_state(
		"government_debt",
		0.0
	)
	economy.set_state(
		"resource_efficiency",
		1.0
	)
	economy.set_state(
		"trade_efficiency",
		1.0
	)
	economy.set_state(
		"infrastructure_efficiency",
		1.0
	)


static func _prepare_research_fixture(
	entity
) -> void:

	var research = entity.get_component(
		"research"
	)

	if research == null:
		return

	research.set_state(
		"technology_effects",
		{
			"industrial_production_efficiency": 1.0
		}
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INFRASTRUCTURE DAMAGE / ECONOMIC CONSEQUENCES — STEP 14.4 TEST"
	)

	if world == null:
		_log_result("World available", false)
		return false

	if simulation == null:
		_log_result("Simulation available", false)
		return false

	_log_result("World available", true)
	_log_result("Simulation available", true)

	var damage_system_instance = simulation.get_system(
		"infrastructure_damage_system"
	)
	var infrastructure_system_instance = simulation.get_system(
		"infrastructure_system"
	)
	var resource_system_instance = simulation.get_system(
		"resource_system"
	)
	var production_system_instance = simulation.get_system(
		"production_process_system"
	)
	var economy_system_instance = simulation.get_system(
		"economy_system"
	)

	var systems_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
		and infrastructure_system_instance != null
		and infrastructure_system_instance is InfrastructureSystem
		and resource_system_instance != null
		and resource_system_instance is ResourceSystem
		and production_system_instance != null
		and production_system_instance is ProductionProcessSystem
		and economy_system_instance != null
		and economy_system_instance is EconomySystem
	)

	_log_result(
		"Registered damage / infrastructure / resource / production / economy systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var india = world.get_entity("india")

	if india == null:
		_log_result("India available", false)
		return false

	_log_result("India available", true)

	var infrastructure: InfrastructureComponent = india.get_component(
		"infrastructure"
	)
	var resources: ResourceComponent = india.get_component(
		"resources"
	)
	var industry: IndustryComponent = india.get_component(
		"industry"
	)
	var economy = india.get_component(
		"economy"
	)
	var population = india.get_component(
		"population"
	)
	var research = india.get_component(
		"research"
	)

	var components_ok: bool = (
		infrastructure != null
		and resources != null
		and industry != null
		and economy != null
	)

	_log_result(
		"India infrastructure/resource/industry/economy components available",
		components_ok
	)

	if not components_ok:
		return false

	var damage_system: InfrastructureDamageSystem = (
		damage_system_instance as InfrastructureDamageSystem
	)
	var infrastructure_system: InfrastructureSystem = (
		infrastructure_system_instance as InfrastructureSystem
	)
	var resource_system: ResourceSystem = (
		resource_system_instance as ResourceSystem
	)
	var production_system: ProductionProcessSystem = (
		production_system_instance as ProductionProcessSystem
	)
	var economy_system: EconomySystem = (
		economy_system_instance as EconomySystem
	)

	# Preserve all state touched by the controlled fixture.
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	var original_population_state: Dictionary = {}
	if population != null:
		original_population_state = population.state.duplicate(true)

	var original_research_state: Dictionary = {}
	if research != null:
		original_research_state = research.state.duplicate(true)

	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()
	var original_active_conflicts: Array = world.active_conflicts.duplicate()
	var original_completed_conflicts: Array = world.completed_conflicts.duplicate()

	var passed := true

	# ------------------------------------------------------------
	# CONTROLLED BASELINE FIXTURE
	# ------------------------------------------------------------

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)
	_prepare_economy_fixture(india)
	_prepare_research_fixture(india)

	# ------------------------------------------------------------
	# BASELINE — NO DAMAGE
	# ------------------------------------------------------------

	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system._update_economy(
		india,
		economy
	)

	var baseline_physical_output: float = float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)
	var baseline_physical_capacity: float = float(
		economy.get_state(
			"physical_production_capacity",
			0.0
		)
	)
	var baseline_output_factor: float = float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)
	var baseline_economic_efficiency: float = float(
		economy.get_state(
			"economic_efficiency",
			0.0
		)
	)
	var baseline_effective_growth: float = float(
		economy.get_state(
			"effective_growth_rate",
			0.0
		)
	)
	var baseline_gdp: float = float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	var baseline_formula_gdp: float = (
		1000.0
		* (
			1.0
			+ (
				baseline_effective_growth
				/ 12.0
				/ 100.0
			)
		)
	)

	_log_diagnostics(
		"BASELINE",
		{
			"physical_output": baseline_physical_output,
			"physical_capacity": baseline_physical_capacity,
			"output_factor": baseline_output_factor,
			"economic_efficiency": baseline_economic_efficiency,
			"effective_growth": baseline_effective_growth,
			"gdp": baseline_gdp,
			"formula_gdp": baseline_formula_gdp,
			"raw_transport": float(infrastructure.get_state("transport", 0.0)),
			"raw_industrial": float(infrastructure.get_state("industrial", 0.0)),
			"resource_production": resources.get_state("production", {}),
			"production_state": industry.get_state("production_state", {}),
		}
	)

	var baseline_pass: bool = (
		baseline_physical_output > 0.0
		and baseline_physical_capacity > 0.0
		and baseline_output_factor > 0.0
		and _approx(
			baseline_output_factor,
			1.0
		)
		and _approx(
			baseline_economic_efficiency,
			1.0
		)
		and baseline_effective_growth > 0.0
		and _approx(
			baseline_gdp,
			baseline_formula_gdp
		)
	)

	_log_result(
		"Undamaged physical production produces neutral full-capacity economic output",
		baseline_pass
	)
	passed = passed and baseline_pass

	# ------------------------------------------------------------
	# RESET TO SAME STARTING ECONOMIC STATE
	# ------------------------------------------------------------

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)
	_prepare_economy_fixture(india)
	_prepare_research_fixture(india)

	# ------------------------------------------------------------
	# STEP 14.1 SOURCE — TRANSPORT DAMAGE
	# ------------------------------------------------------------

	var fixture_event := SimulationEvent.new(
		"step14_4_fixture_event",
		"Step 14.4 Infrastructure Damage / Economic Fixture",
		"infrastructure_damage"
	)

	fixture_event.add_target("india")
	fixture_event.activate()
	world.add_active_event(fixture_event)

	var damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.50,
		fixture_event,
		"damage_event_14_4_transport",
		"controlled_economic_consequence_fixture"
	)

	_log_result(
		"Step 14.1 damage source creates the Step 14.4 controlled damage",
		damage_created
	)
	passed = passed and damage_created

	# ------------------------------------------------------------
	# DAMAGE -> PHYSICAL PRODUCTION -> ECONOMIC OUTPUT
	# ------------------------------------------------------------

	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system._update_economy(
		india,
		economy
	)

	var damaged_physical_output: float = float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)
	var damaged_physical_capacity: float = float(
		economy.get_state(
			"physical_production_capacity",
			0.0
		)
	)
	var damaged_output_factor: float = float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)
	var damaged_economic_efficiency: float = float(
		economy.get_state(
			"economic_efficiency",
			0.0
		)
	)
	var damaged_effective_growth: float = float(
		economy.get_state(
			"effective_growth_rate",
			0.0
		)
	)
	var damaged_gdp: float = float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	_log_diagnostics(
		"DAMAGED",
		{
			"physical_output": damaged_physical_output,
			"physical_capacity": damaged_physical_capacity,
			"output_factor": damaged_output_factor,
			"economic_efficiency": damaged_economic_efficiency,
			"effective_growth": damaged_effective_growth,
			"gdp": damaged_gdp,
			"formula_gdp": 1000.0 * (1.0 + (damaged_effective_growth / 12.0 / 100.0)),
			"raw_transport": float(infrastructure.get_state("transport", 0.0)),
			"effective_transport": float(infrastructure.get_state("effective_infrastructure_capacity", {}).get("transport", 0.0)),
			"total_infrastructure_capacity": float(infrastructure.get_state("total_capacity", 0.0)),
			"resource_production": resources.get_state("production", {}),
			"production_state": industry.get_state("production_state", {}),
		}
	)

	var damage_physical_consequence_pass: bool = (
		_approx(
			float(
				infrastructure.get_state(
					"transport",
					0.0
				)
			),
			1.0
		)
		and damaged_physical_output < baseline_physical_output
		and damaged_output_factor < baseline_output_factor
		and damaged_economic_efficiency <= baseline_economic_efficiency + 0.000001
	)

	_log_result(
		"Damaged infrastructure lowers realized physical production and production output factor without rewriting raw/economic-efficiency state",
		damage_physical_consequence_pass
	)
	passed = passed and damage_physical_consequence_pass

	var economic_consequence_pass: bool = (
		damaged_effective_growth < baseline_effective_growth
		and damaged_gdp < baseline_gdp
		and damaged_physical_capacity > 0.0
	)

	_log_result(
		"Reduced physical production lowers effective growth and GDP",
		economic_consequence_pass
	)
	passed = passed and economic_consequence_pass

	var damaged_formula_gdp: float = (
		1000.0
		* (
			1.0
			+ (
				damaged_effective_growth
				/ 12.0
				/ 100.0
			)
		)
	)

	var macro_formula_pass: bool = _approx(
		damaged_gdp,
		damaged_formula_gdp
	)

	_log_result(
		"Economic consequence follows the existing EconomySystem GDP formula",
		macro_formula_pass
	)
	passed = passed and macro_formula_pass

	# ------------------------------------------------------------
	# RECOVERY — CLEAN INFRASTRUCTURE RESTORED
	# ------------------------------------------------------------

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)
	_prepare_economy_fixture(india)
	_prepare_research_fixture(india)

	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system._update_economy(
		india,
		economy
	)

	var recovered_output: float = float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)
	var recovered_factor: float = float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)
	var recovered_growth: float = float(
		economy.get_state(
			"effective_growth_rate",
			0.0
		)
	)
	var recovered_gdp: float = float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	_log_diagnostics(
		"RECOVERY",
		{
			"physical_output": recovered_output,
			"output_factor": recovered_factor,
			"effective_growth": recovered_growth,
			"gdp": recovered_gdp,
			"raw_transport": float(infrastructure.get_state("transport", 0.0)),
			"resource_production": resources.get_state("production", {}),
			"production_state": industry.get_state("production_state", {}),
		}
	)

	var recovery_pass: bool = (
		_approx(
			recovered_output,
			baseline_physical_output
		)
		and _approx(
			recovered_factor,
			baseline_output_factor
		)
		and _approx(
			recovered_growth,
			baseline_effective_growth
		)
		and _approx(
			recovered_gdp,
			baseline_gdp
		)
	)

	_log_result(
		"Restoring infrastructure restores physical and economic output under the existing chain",
		recovery_pass
	)
	passed = passed and recovery_pass

	# ------------------------------------------------------------
	# RESTORATION
	# ------------------------------------------------------------

	infrastructure.state = original_infrastructure_state.duplicate(true)
	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)

	if population != null:
		population.state = original_population_state.duplicate(true)

	if research != null:
		research.state = original_research_state.duplicate(true)

	world.active_events = original_active_events.duplicate()
	world.completed_events = original_completed_events.duplicate()
	world.active_conflicts = original_active_conflicts.duplicate()
	world.completed_conflicts = original_completed_conflicts.duplicate()

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
		and (
			population == null
			or population.state == original_population_state
		)
		and (
			research == null
			or research.state == original_research_state
		)
		and world.active_events == original_active_events
		and world.completed_events == original_completed_events
		and world.active_conflicts == original_active_conflicts
		and world.completed_conflicts == original_completed_conflicts
	)

	_log_result(
		"Step 14.4 fixture restoration",
		restoration_ok
	)
	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 14.4 infrastructure economic consequences overall: "
		+ ("PASS" if passed else "FAIL")
	)

	TestLogger.write_line(
		"Infrastructure Economic Consequences 14.4 test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
