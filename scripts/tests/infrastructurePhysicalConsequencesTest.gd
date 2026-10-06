class_name InfrastructurePhysicalConsequencesTest
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


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INFRASTRUCTURE DAMAGE — STEP 14.3 PHYSICAL CONSEQUENCES TEST"
	)

	if world == null:
		_log_result(
			"World available",
			false
		)
		return false

	if simulation == null:
		_log_result(
			"Simulation available",
			false
		)
		return false

	_log_result(
		"World available",
		true
	)
	_log_result(
		"Simulation available",
		true
	)

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

	var systems_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
		and infrastructure_system_instance != null
		and infrastructure_system_instance is InfrastructureSystem
		and resource_system_instance != null
		and resource_system_instance is ResourceSystem
		and production_system_instance != null
		and production_system_instance is ProductionProcessSystem
	)

	_log_result(
		"Registered infrastructure / resource / production systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var india = world.get_entity("india")

	if india == null:
		_log_result(
			"India available",
			false
		)
		return false

	_log_result(
		"India available",
		true
	)

	var infrastructure: InfrastructureComponent = india.get_component(
		"infrastructure"
	)
	var resources: ResourceComponent = india.get_component(
		"resources"
	)
	var industry: IndustryComponent = india.get_component(
		"industry"
	)

	var components_ok: bool = (
		infrastructure != null
		and resources != null
		and industry != null
	)

	_log_result(
		"India infrastructure/resource/industry components available",
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

	# Preserve all state touched by the controlled fixture.
	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)
	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)
	var original_industry_state: Dictionary = (
		industry.state.duplicate(true)
	)

	var population = india.get_component("population")
	var economy = india.get_component("economy")

	var original_population_state: Dictionary = {}
	if population != null:
		original_population_state = population.state.duplicate(true)

	var original_economy_state: Dictionary = {}
	if economy != null:
		original_economy_state = economy.state.duplicate(true)

	var original_active_events: Array = (
		world.active_events.duplicate()
	)
	var original_completed_events: Array = (
		world.completed_events.duplicate()
	)
	var original_active_conflicts: Array = (
		world.active_conflicts.duplicate()
	)
	var original_completed_conflicts: Array = (
		world.completed_conflicts.duplicate()
	)

	var passed := true

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------

	_prepare_infrastructure_fixture(
		infrastructure
	)
	_prepare_resource_fixture(
		resources
	)
	_prepare_industry_fixture(
		industry
	)
	_prepare_supporting_capacity_fixtures(
		india
	)

	# ------------------------------------------------------------
	# BASELINE — NO DAMAGE
	# ------------------------------------------------------------

	infrastructure_system.process_month(
		world
	)
	resource_system.process_month(
		world
	)

	var baseline_infrastructure_capacity: float = float(
		infrastructure.get_state(
			"total_capacity",
			0.0
		)
	)

	var baseline_effective_transport: float = float(
		infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		).get(
			"transport",
			0.0
		)
	)

	var baseline_iron_production: float = float(
		resources.get_state(
			"actual_production",
			{}
		).get(
			"iron",
			0.0
		)
	)

	var baseline_coal_production: float = float(
		resources.get_state(
			"actual_production",
			{}
		).get(
			"coal",
			0.0
		)
	)

	var baseline_resource_pass: bool = (
		_approx(
			baseline_infrastructure_capacity,
			1.0
		)
		and _approx(
			baseline_effective_transport,
			1.0
		)
		and _approx(
			baseline_iron_production,
			20.0
		)
		and _approx(
			baseline_coal_production,
			10.0
		)
	)

	_log_result(
		"Undamaged infrastructure preserves baseline resource production",
		baseline_resource_pass
	)

	passed = passed and baseline_resource_pass

	# The undamaged ResourceSystem pass filled the stockpile. Verify the
	# authoritative physical production engine can turn those inputs into
	# the full basic-steel output before introducing damage.
	production_system.process_month(
		world
	)

	var baseline_steel_production: float = float(
		industry.get_production_outcome(
			"steel_basic"
		).get(
			"actual_production",
			0.0
		)
	)

	var baseline_industry_pass: bool = _approx(
		baseline_steel_production,
		10.0
	)

	_log_result(
		"Undamaged infrastructure preserves baseline industrial production",
		baseline_industry_pass
	)

	passed = passed and baseline_industry_pass

	# ------------------------------------------------------------
	# RESET CONTROLLED FLOWS FOR DAMAGED MONTH
	# ------------------------------------------------------------

	_prepare_resource_fixture(
		resources
	)
	_prepare_industry_fixture(
		industry
	)
	_prepare_supporting_capacity_fixtures(
		india
	)

	# Keep infrastructure at the clean pre-damage state before the causal
	# event is applied.
	_prepare_infrastructure_fixture(
		infrastructure
	)

	# ------------------------------------------------------------
	# STEP 14.1 SOURCE — TRANSPORT DAMAGE
	# ------------------------------------------------------------

	var fixture_event := SimulationEvent.new(
		"step14_3_fixture_event",
		"Step 14.3 Infrastructure Damage Fixture",
		"infrastructure_damage"
	)

	fixture_event.add_target(
		"india"
	)
	fixture_event.activate()
	world.add_active_event(
		fixture_event
	)

	var damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.50,
		fixture_event,
		"damage_event_14_3_transport",
		"controlled_physical_consequence_fixture"
	)

	_log_result(
		"Step 14.1 damage source creates the Step 14.3 fixture damage",
		damage_created
	)

	passed = passed and damage_created

	# ------------------------------------------------------------
	# DAMAGE -> EFFECTIVE INFRASTRUCTURE -> RESOURCE PRODUCTION
	# ------------------------------------------------------------

	infrastructure_system.process_month(
		world
	)
	resource_system.process_month(
		world
	)

	var damaged_total_capacity: float = float(
		infrastructure.get_state(
			"total_capacity",
			0.0
		)
	)

	var damaged_transport_capacity: float = float(
		infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		).get(
			"transport",
			0.0
		)
	)

	var damaged_resource_infrastructure_capacity: float = float(
		resources.get_state(
			"infrastructure_capacity",
			{}
		).get(
			"iron",
			0.0
		)
	)

	var expected_total_capacity := (
		0.5
		+ 1.0
		+ 1.0
		+ 1.0
		+ 1.0
		+ 1.0
		+ 1.0
	) / 7.0

	var damaged_capacity_pass: bool = (
		_approx(
			damaged_transport_capacity,
			0.5
		)
		and _approx(
			damaged_total_capacity,
			expected_total_capacity
		)
		and _approx(
			damaged_resource_infrastructure_capacity,
			expected_total_capacity
		)
	)

	_log_result(
		"Damage propagates into effective infrastructure and resource capacity",
		damaged_capacity_pass
	)

	passed = passed and damaged_capacity_pass

	# ResourceSystem multiplies:
	# generic infrastructure capacity
	# × specialized transport capacity
	# × specialized power capacity
	# for this controlled fixture.
	var expected_iron_production: float = (
		20.0
		* expected_total_capacity
		* 0.50
	)

	var expected_coal_production: float = (
		10.0
		* expected_total_capacity
		* 0.50
	)

	var damaged_iron_production: float = float(
		resources.get_state(
			"actual_production",
			{}
		).get(
			"iron",
			0.0
		)
	)

	var damaged_coal_production: float = float(
		resources.get_state(
			"actual_production",
			{}
		).get(
			"coal",
			0.0
		)
	)

	var resource_consequence_pass: bool = (
		_approx(
			damaged_iron_production,
			expected_iron_production
		)
		and _approx(
			damaged_coal_production,
			expected_coal_production
		)
		and damaged_iron_production < baseline_iron_production
		and damaged_coal_production < baseline_coal_production
	)

	_log_result(
		"Transport damage reduces actual physical resource production",
		resource_consequence_pass
	)

	passed = passed and resource_consequence_pass

	# ------------------------------------------------------------
	# RESOURCE CONSEQUENCE -> INDUSTRIAL PRODUCTION
	# ------------------------------------------------------------

	production_system.process_month(
		world
	)

	var damaged_steel_production: float = float(
		industry.get_production_outcome(
			"steel_basic"
		).get(
			"actual_production",
			0.0
		)
	)

	var expected_damaged_steel: float = min(
		expected_iron_production / 2.0,
		expected_coal_production
	)

	var industrial_consequence_pass: bool = (
		_approx(
			damaged_steel_production,
			expected_damaged_steel
		)
		and damaged_steel_production < baseline_steel_production
	)

	_log_result(
		"Reduced resource production constrains downstream industrial production",
		industrial_consequence_pass
	)

	passed = passed and industrial_consequence_pass

	# ------------------------------------------------------------
	# NO RAW CAPACITY MUTATION
	# ------------------------------------------------------------

	var raw_transport_preserved: bool = _approx(
		float(
			infrastructure.get_state(
				"transport",
				0.0
			)
		),
		1.0
	)

	_log_result(
		"Damage consequence path does not overwrite raw transport capacity",
		raw_transport_preserved
	)

	passed = passed and raw_transport_preserved

	# ------------------------------------------------------------
	# RESTORATION
	# ------------------------------------------------------------

	infrastructure.state = (
		original_infrastructure_state.duplicate(true)
	)
	resources.state = (
		original_resource_state.duplicate(true)
	)
	industry.state = (
		original_industry_state.duplicate(true)
	)

	if population != null:
		population.state = (
			original_population_state.duplicate(true)
		)

	if economy != null:
		economy.state = (
			original_economy_state.duplicate(true)
		)

	world.active_events = (
		original_active_events.duplicate()
	)
	world.completed_events = (
		original_completed_events.duplicate()
	)
	world.active_conflicts = (
		original_active_conflicts.duplicate()
	)
	world.completed_conflicts = (
		original_completed_conflicts.duplicate()
	)

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and resources.state == original_resource_state
		and industry.state == original_industry_state
		and (
			population == null
			or population.state == original_population_state
		)
		and (
			economy == null
			or economy.state == original_economy_state
		)
		and world.active_events == original_active_events
		and world.completed_events == original_completed_events
		and world.active_conflicts == original_active_conflicts
		and world.completed_conflicts == original_completed_conflicts
	)

	_log_result(
		"Step 14.3 fixture restoration",
		restoration_ok
	)

	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 14.3 physical consequences overall: "
		+ ("PASS" if passed else "FAIL")
	)

	TestLogger.write_line(
		"Infrastructure Physical Consequences 14.3 test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
