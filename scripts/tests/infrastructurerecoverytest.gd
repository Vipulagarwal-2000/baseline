class_name InfrastructureRecoveryTest
extends RefCounted


const INFRASTRUCTURE_TYPES: Array[String] = [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func _approx(actual: float, expected: float, tolerance: float = 0.000001) -> bool:
	return abs(actual - expected) <= tolerance


static func _prepare_infrastructure_fixture(
	infrastructure: InfrastructureComponent
) -> void:
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
	infrastructure.set_state("reconstruction_projects", [])


static func _prepare_resource_fixture(resources: ResourceComponent) -> void:
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


static func _prepare_industry_fixture(industry: IndustryComponent) -> void:
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
		infrastructure.set_state("process_maintenance_capacity", {"machinery": 1.0})


static func _prepare_economy_fixture(entity) -> void:
	var economy = entity.get_component("economy")
	if economy == null:
		return

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


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section(
		"INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.6 RECOVERY TEST"
	)

	if world == null or simulation == null:
		_log_result("World and Simulation available", false)
		return false
	_log_result("World and Simulation available", true)

	var damage_system_instance = simulation.get_system("infrastructure_damage_system")
	var infrastructure_system_instance = simulation.get_system("infrastructure_system")
	var investment_system_instance = simulation.get_system("infrastructure_investment_system")
	var reconstruction_system_instance = simulation.get_system("infrastructure_reconstruction_investment_system")
	var recovery_system_instance = simulation.get_system("infrastructure_recovery_system")
	var resource_system_instance = simulation.get_system("resource_system")
	var production_system_instance = simulation.get_system("production_process_system")
	var economy_system_instance = simulation.get_system("economy_system")

	var systems_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
		and infrastructure_system_instance != null
		and infrastructure_system_instance is InfrastructureSystem
		and investment_system_instance != null
		and investment_system_instance is InfrastructureInvestmentSystem
		and reconstruction_system_instance != null
		and reconstruction_system_instance is InfrastructureReconstructionInvestmentSystem
		and recovery_system_instance != null
		and recovery_system_instance is InfrastructureRecoverySystem
		and resource_system_instance != null
		and resource_system_instance is ResourceSystem
		and production_system_instance != null
		and production_system_instance is ProductionProcessSystem
		and economy_system_instance != null
		and economy_system_instance is EconomySystem
	)

	_log_result(
		"Registered damage / infrastructure / investment / reconstruction / recovery / downstream systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var india = world.get_entity("india")
	if india == null:
		_log_result("India available", false)
		return false
	_log_result("India available", true)

	var infrastructure: InfrastructureComponent = india.get_component("infrastructure")
	var resources: ResourceComponent = india.get_component("resources")
	var industry: IndustryComponent = india.get_component("industry")
	var economy = india.get_component("economy")

	var components_ok: bool = (
		infrastructure != null
		and resources != null
		and industry != null
		and economy != null
	)
	_log_result("India infrastructure/resource/industry/economy components available", components_ok)
	if not components_ok:
		return false

	var damage_system: InfrastructureDamageSystem = damage_system_instance as InfrastructureDamageSystem
	var infrastructure_system: InfrastructureSystem = infrastructure_system_instance as InfrastructureSystem
	var investment_system: InfrastructureInvestmentSystem = investment_system_instance as InfrastructureInvestmentSystem
	var reconstruction_system: InfrastructureReconstructionInvestmentSystem = reconstruction_system_instance as InfrastructureReconstructionInvestmentSystem
	var recovery_system: InfrastructureRecoverySystem = recovery_system_instance as InfrastructureRecoverySystem
	var resource_system: ResourceSystem = resource_system_instance as ResourceSystem
	var production_system: ProductionProcessSystem = production_system_instance as ProductionProcessSystem
	var economy_system: EconomySystem = economy_system_instance as EconomySystem

	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	var passed: bool = true

	_prepare_infrastructure_fixture(infrastructure)
	_prepare_resource_fixture(resources)
	_prepare_industry_fixture(industry)
	_prepare_supporting_capacity_fixtures(india)
	_prepare_economy_fixture(india)

	# Capture the controlled undamaged economic baseline using the actual
	# installed EconomySystem rather than assuming a hard-coded effective
	# growth value. This keeps the test valid when the existing economy
	# formula derives production efficiency from the live industry fixture.
	var fixture_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var fixture_resource_state: Dictionary = resources.state.duplicate(true)
	var fixture_industry_state: Dictionary = industry.state.duplicate(true)
	var fixture_economy_state: Dictionary = economy.state.duplicate(true)

	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system.process_month(world)

	var baseline_growth: float = float(economy.get_state("effective_growth_rate", 0.0))
	var baseline_output_state: Dictionary = industry.get_state("production_state", {}) as Dictionary
	var baseline_process: Dictionary = baseline_output_state.get("steel_basic", {}) as Dictionary
	var baseline_output: float = float(baseline_process.get("actual_production", 0.0))

	infrastructure.state = fixture_infrastructure_state.duplicate(true)
	resources.state = fixture_resource_state.duplicate(true)
	industry.state = fixture_industry_state.duplicate(true)
	economy.state = fixture_economy_state.duplicate(true)

	var fixture_event: SimulationEvent = SimulationEvent.new(
		"step14_6_fixture_event",
		"Step 14.6 Infrastructure Recovery Fixture",
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
		"damage_event_14_6_transport",
		"controlled_recovery_fixture"
	)
	_log_result("Step 14.1 source creates controlled 50% transport damage", damage_created)
	passed = passed and damage_created

	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system.process_month(world)

	var damaged_effective_transport: float = float(
		(infrastructure.get_state("effective_infrastructure_capacity", {}) as Dictionary).get(
			"transport",
			0.0
		)
	)
	var damaged_output_state: Dictionary = industry.get_state("production_state", {}) as Dictionary
	var damaged_process: Dictionary = damaged_output_state.get("steel_basic", {}) as Dictionary
	var damaged_output: float = float(damaged_process.get("actual_production", 0.0))
	var damaged_growth: float = float(economy.get_state("effective_growth_rate", 0.0))
	var damaged_gdp: float = float(economy.get_state("gdp", 0.0))

	var damaged_baseline_pass: bool = (
		_approx(damaged_effective_transport, 0.50)
		and damaged_output < 10.0
		and damaged_growth < 12.0
		and damaged_gdp < 1010.0
	)
	_log_result(
		"Immediate damage reduces effective capacity, physical production, and economic output",
		damaged_baseline_pass
	)
	passed = passed and damaged_baseline_pass

	# Existing investment machinery supplies the reconstruction budget.
	economy.set_state("investment", 100.0)
	economy.set_state("infrastructure_investment_rate", 0.25)
	economy.set_state("infrastructure_investment_budget", 0.0)
	investment_system.process_month(world)

	var project: Dictionary = reconstruction_system.create_reconstruction_project(
		india,
		"transport",
		0.50,
		20.0,
		2
	)
	var project_created: bool = not project.is_empty()
	_log_result("Reconstruction project is funded through existing investment machinery", project_created)
	passed = passed and project_created

	var raw_transport: float = float(infrastructure.get_state("transport", 0.0))

	# ------------------------------------------------------------
	# RECOVERY MONTH 1
	# ------------------------------------------------------------
	reconstruction_system.process_month(world)
	recovery_system.process_month(world)
	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system.process_month(world)

	var month_one_damage: float = float(
		(infrastructure.get_state("infrastructure_damage", {}) as Dictionary).get(
			"transport",
			1.0
		)
	)
	var month_one_effective: float = float(
		(infrastructure.get_state("effective_infrastructure_capacity", {}) as Dictionary).get(
			"transport",
			0.0
		)
	)
	var month_one_state: Dictionary = industry.get_state("production_state", {}) as Dictionary
	var month_one_process: Dictionary = month_one_state.get("steel_basic", {}) as Dictionary
	var month_one_output: float = float(month_one_process.get("actual_production", 0.0))
	var month_one_growth: float = float(economy.get_state("effective_growth_rate", 0.0))
	var month_one_gdp: float = float(economy.get_state("gdp", 0.0))

	var month_one_pass: bool = (
		_approx(month_one_damage, 0.25)
		and _approx(month_one_effective, 0.75)
		and month_one_output > damaged_output
		and month_one_growth > damaged_growth
		and month_one_gdp > damaged_gdp
		and _approx(float(infrastructure.get_state("transport", 0.0)), raw_transport)
	)
	_log_result(
		"Month 1 reconstruction progressively restores damage, capacity, production, and economic performance",
		month_one_pass
	)
	passed = passed and month_one_pass

	# ------------------------------------------------------------
	# RECOVERY MONTH 2 — FULL COMPLETION
	# ------------------------------------------------------------
	reconstruction_system.process_month(world)
	recovery_system.process_month(world)
	infrastructure_system.process_month(world)
	resource_system.process_month(world)
	production_system.process_month(world)
	economy_system.process_month(world)

	var final_damage: float = float(
		(infrastructure.get_state("infrastructure_damage", {}) as Dictionary).get(
			"transport",
			1.0
		)
	)
	var final_effective_transport: float = float(
		(infrastructure.get_state("effective_infrastructure_capacity", {}) as Dictionary).get(
			"transport",
			0.0
		)
	)
	var final_state: Dictionary = industry.get_state("production_state", {}) as Dictionary
	var final_process: Dictionary = final_state.get("steel_basic", {}) as Dictionary
	var final_output: float = float(final_process.get("actual_production", 0.0))
	var final_output_factor: float = float(economy.get_state("production_output_factor", 0.0))
	var final_growth: float = float(economy.get_state("effective_growth_rate", 0.0))
	var final_gdp: float = float(economy.get_state("gdp", 0.0))

	var projects: Array = reconstruction_system.get_projects(india)
	var final_project: Dictionary = projects[0] if not projects.is_empty() else {}

	var final_pass: bool = (
		_approx(final_damage, 0.0)
		and _approx(final_effective_transport, 1.0)
		and _approx(final_output, baseline_output)
		and _approx(final_output_factor, 1.0)
		and _approx(final_growth, baseline_growth)
		and final_gdp > month_one_gdp
		and _approx(float(infrastructure.get_state("transport", 0.0)), raw_transport)
		and str(final_project.get("status", "")) == "recovered"
		and bool(final_project.get("recovery_completed", false))
		and _approx(float(final_project.get("applied_damage_reduction", 0.0)), 0.50)
	)
	_log_result(
		"Month 2 completes reconstruction and restores full physical/economic performance",
		final_pass
	)
	passed = passed and final_pass

	# ------------------------------------------------------------
	# IDEMPOTENCE / OVER-RECOVERY SAFETY
	# ------------------------------------------------------------
	recovery_system.process_month(world)
	infrastructure_system.process_month(world)

	var idempotent_damage: float = float(
		(infrastructure.get_state("infrastructure_damage", {}) as Dictionary).get(
			"transport",
			1.0
		)
	)
	var idempotence_pass: bool = _approx(idempotent_damage, 0.0)
	_log_result("Completed recovery does not over-recover or reintroduce damage", idempotence_pass)
	passed = passed and idempotence_pass

	infrastructure.state = original_infrastructure_state.duplicate(true)
	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	world.active_events = world.active_events.filter(func(event): return event != fixture_event)

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
	)
	_log_result("Step 14.6 fixture restoration", restoration_ok)
	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 14.6 recovery overall: " + ("PASS" if passed else "FAIL")
	)
	TestLogger.write_line(
		"Infrastructure Recovery 14.6 test: " + ("PASS" if passed else "FAIL")
	)

	return passed
