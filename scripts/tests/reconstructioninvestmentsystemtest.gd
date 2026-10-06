class_name InfrastructureReconstructionInvestmentTest
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


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func _approx(actual: float, expected: float, tolerance: float = 0.000001) -> bool:
	return abs(actual - expected) <= tolerance


static func _prepare_infrastructure_fixture(infrastructure: InfrastructureComponent) -> void:
	var conditions: Dictionary = {}
	var damage: Dictionary = {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		conditions[infrastructure_type] = 1.0
		damage[infrastructure_type] = 0.0
		infrastructure.set_state(infrastructure_type, 1.0)

	infrastructure.set_state("infrastructure_condition", conditions)
	infrastructure.set_state("infrastructure_damage", damage)
	infrastructure.set_state("infrastructure_damage_total", 0.0)
	infrastructure.set_state("infrastructure_damage_records", [])
	infrastructure.set_state("effective_infrastructure_capacity", {})
	infrastructure.set_state("total_capacity", 1.0)
	infrastructure.set_state("reconstruction_projects", [])


static func _prepare_economy_fixture(economy) -> void:
	economy.set_state("investment", 100.0)
	economy.set_state("infrastructure_investment_rate", 0.25)
	economy.set_state("infrastructure_investment_budget", 0.0)
	economy.set_state("infrastructure_investment_this_month", 0.0)
	economy.set_state("treasury", 500.0)
	economy.set_state("unallocated_industrial_capacity", 10.0)


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section(
		"INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.5 TEST"
	)

	if world == null or simulation == null:
		_log_result("World and Simulation available", false)
		return false

	_log_result("World and Simulation available", true)

	var damage_system_instance = simulation.get_system("infrastructure_damage_system")
	var infrastructure_system_instance = simulation.get_system("infrastructure_system")
	var investment_system_instance = simulation.get_system("infrastructure_investment_system")
	var reconstruction_system_instance = simulation.get_system("infrastructure_reconstruction_investment_system")

	var systems_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
		and infrastructure_system_instance != null
		and infrastructure_system_instance is InfrastructureSystem
		and investment_system_instance != null
		and investment_system_instance is InfrastructureInvestmentSystem
		and reconstruction_system_instance != null
		and reconstruction_system_instance is InfrastructureReconstructionInvestmentSystem
	)

	_log_result(
		"Registered damage / infrastructure / investment / reconstruction systems available",
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
	var economy = india.get_component("economy")

	var components_ok: bool = infrastructure != null and economy != null
	_log_result("India infrastructure/economy components available", components_ok)
	if not components_ok:
		return false

	var damage_system: InfrastructureDamageSystem = damage_system_instance as InfrastructureDamageSystem
	var infrastructure_system: InfrastructureSystem = infrastructure_system_instance as InfrastructureSystem
	var investment_system: InfrastructureInvestmentSystem = investment_system_instance as InfrastructureInvestmentSystem
	var reconstruction_system: InfrastructureReconstructionInvestmentSystem = reconstruction_system_instance as InfrastructureReconstructionInvestmentSystem

	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()
	var original_active_conflicts: Array = world.active_conflicts.duplicate()
	var original_completed_conflicts: Array = world.completed_conflicts.duplicate()

	var passed: bool = true

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------
	_prepare_infrastructure_fixture(infrastructure)
	_prepare_economy_fixture(economy)

	# ------------------------------------------------------------
	# STEP 14.1/14.2 DAMAGE STATE
	# ------------------------------------------------------------
	var fixture_event: SimulationEvent = SimulationEvent.new(
		"step14_5_fixture_event",
		"Step 14.5 Reconstruction Investment Fixture",
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
		"damage_event_14_5_transport",
		"controlled_reconstruction_investment_fixture"
	)

	_log_result(
		"Step 14.1 source creates controlled transport damage",
		damage_created
	)
	passed = passed and damage_created

	infrastructure_system.process_month(world)

	var damaged_effective_transport: float = float(
		infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		).get("transport", 0.0)
	)

	var damage_fixture_pass: bool = _approx(
		damaged_effective_transport,
		0.50
	)

	_log_result(
		"Damaged infrastructure provides a reconstruction target at 50% effective transport capacity",
		damage_fixture_pass
	)
	passed = passed and damage_fixture_pass

	# ------------------------------------------------------------
	# EXISTING INVESTMENT MACHINERY
	# ------------------------------------------------------------
	investment_system.process_month(world)

	var monthly_allocation: float = investment_system.get_monthly_allocation(india)
	var investment_budget: float = investment_system.get_investment_budget(india)
	var investment_flow: float = float(economy.get_state("investment", -1.0))

	var investment_allocation_pass: bool = (
		_approx(monthly_allocation, 25.0)
		and _approx(investment_budget, 25.0)
		and _approx(investment_flow, 100.0)
	)

	_log_result(
		"Existing InfrastructureInvestmentSystem creates the reconstruction funding pool without changing investment flow",
		investment_allocation_pass
	)
	passed = passed and investment_allocation_pass

	# ------------------------------------------------------------
	# RECONSTRUCTION INVESTMENT COMMITMENT
	# ------------------------------------------------------------
	var treasury_before: float = float(economy.get_state("treasury", -1.0))
	var raw_transport_before: float = float(infrastructure.get_state("transport", -1.0))
	var damage_before: float = float(
		infrastructure.get_state("infrastructure_damage", {}).get(
			"transport",
			-1.0
		)
	)

	var created_project: Dictionary = reconstruction_system.create_reconstruction_project(
		india,
		"transport",
		0.50,
		20.0,
		2
	)

	var project_created: bool = not created_project.is_empty()
	_log_result(
		"Reconstruction investment project is created from the existing investment budget",
		project_created
	)
	passed = passed and project_created

	var budget_after: float = float(economy.get_state("infrastructure_investment_budget", -1.0))
	var treasury_after: float = float(economy.get_state("treasury", -1.0))
	var raw_transport_after: float = float(infrastructure.get_state("transport", -1.0))
	var damage_after: float = float(
		infrastructure.get_state("infrastructure_damage", {}).get(
			"transport",
			-1.0
		)
	)

	var funding_pass: bool = (
		_approx(budget_after, 5.0)
		and _approx(treasury_after, treasury_before)
		and _approx(raw_transport_after, raw_transport_before)
		and _approx(damage_after, damage_before)
		and _approx(float(created_project.get("investment_funded", -1.0)), 20.0)
		and str(created_project.get("funding_source", "")) == "infrastructure_investment"
	)

	_log_result(
		"Reconstruction consumes existing investment budget while preserving treasury, raw capacity, and damage state",
		funding_pass
	)
	passed = passed and funding_pass

	var progress_initial_pass: bool = (
		_approx(float(created_project.get("progress", -1.0)), 0.0)
		and str(created_project.get("status", "")) == "active"
	)
	_log_result(
		"Committed reconstruction project starts active without immediate physical recovery",
		progress_initial_pass
	)
	passed = passed and progress_initial_pass

	# ------------------------------------------------------------
	# MULTI-MONTH INVESTMENT PROJECT PROGRESS
	# ------------------------------------------------------------
	reconstruction_system.process_month(world)

	var month_one_projects: Array = reconstruction_system.get_projects(india)
	var month_one_project: Dictionary = month_one_projects[0] if not month_one_projects.is_empty() else {}

	var month_one_pass: bool = (
		_approx(float(month_one_project.get("progress", -1.0)), 0.5)
		and str(month_one_project.get("status", "")) == "active"
		and _approx(
			float(infrastructure.get_state("transport", -1.0)),
			raw_transport_before
		)
		and _approx(
			float(infrastructure.get_state("infrastructure_damage", {}).get("transport", -1.0)),
			damage_before
		)
	)

	_log_result(
		"Month 1 reconstruction investment progresses without applying recovery early",
		month_one_pass
	)
	passed = passed and month_one_pass

	# ------------------------------------------------------------
	# INSUFFICIENT BUDGET SAFETY
	# ------------------------------------------------------------
	var rejected_project: Dictionary = reconstruction_system.create_reconstruction_project(
		india,
		"transport",
		0.10,
		10.0,
		1
	)

	var insufficient_budget_pass: bool = (
		rejected_project.is_empty()
		and _approx(
			float(economy.get_state("infrastructure_investment_budget", -1.0)),
			5.0
		)
	)

	_log_result(
		"Insufficient reconstruction investment budget rejects a new commitment without mutation",
		insufficient_budget_pass
	)
	passed = passed and insufficient_budget_pass

	# ------------------------------------------------------------
	# RESTORATION
	# ------------------------------------------------------------
	infrastructure.state = original_infrastructure_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	world.active_events = original_active_events.duplicate()
	world.completed_events = original_completed_events.duplicate()
	world.active_conflicts = original_active_conflicts.duplicate()
	world.completed_conflicts = original_completed_conflicts.duplicate()

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and economy.state == original_economy_state
		and world.active_events == original_active_events
		and world.completed_events == original_completed_events
		and world.active_conflicts == original_active_conflicts
		and world.completed_conflicts == original_completed_conflicts
	)

	_log_result("Step 14.5 fixture restoration", restoration_ok)
	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 14.5 reconstruction investment overall: "
		+ ("PASS" if passed else "FAIL")
	)
	TestLogger.write_line(
		"Infrastructure Reconstruction Investment 14.5 test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
