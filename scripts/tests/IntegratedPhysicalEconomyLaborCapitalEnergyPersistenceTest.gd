class_name IntegratedPhysicalEconomyLaborCapitalEnergyPersistenceTest
extends RefCounted


static func _log(message: String) -> void:
	TestLogger.write_line(message)


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func run(
	world = null,
	simulation = null
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — LABOR / CAPITAL / ENERGY PERSISTENCE TEST"
	)

	if world == null or simulation == null:
		_log("World / Simulation available: FAIL")
		return false

	_log("World / Simulation available: PASS")

	var india = world.get_entity("india")

	if india == null:
		_log("India available: FAIL")
		return false

	_log("India available: PASS")

	var population = india.get_component("population")
	var economy = india.get_component("economy")
	var infrastructure = india.get_component("infrastructure")
	var resources = india.get_component("resources")
	var industry = india.get_component("industry")

	var production_process_system: ProductionProcessSystem = (
		simulation.get_system(
			"production_process_system"
		) as ProductionProcessSystem
	)

	var required_components_available: bool = (
		population != null
		and economy != null
		and infrastructure != null
		and resources != null
		and industry != null
	)

	_log(
		"Required physical-economy components available: "
		+ _pass_fail(required_components_available)
	)

	if not required_components_available:
		return false

	var production_system_available: bool = (
		production_process_system != null
	)

	_log(
		"Registered ProductionProcessSystem available: "
		+ _pass_fail(production_system_available)
	)

	if not production_system_available:
		return false

	# ------------------------------------------------------------
	# SAVE COMPLETE TESTED COMPONENT STATE
	# ------------------------------------------------------------

	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)

	var original_industry_state: Dictionary = (
		industry.state.duplicate(true)
	)

	var catalog: ProductionProcessCatalog = (
		production_process_system.catalog
	)

	if catalog == null:
		_log("Production process catalog available: FAIL")
		return false

	var original_definition: Dictionary = (
		catalog.get_process(
			"steel_basic"
		).duplicate(true)
	)

	# ------------------------------------------------------------
	# CONTROLLED PROCESS
	# ------------------------------------------------------------
	#
	# The temporary process makes all three target constraints active:
	#
	# labor:
	#   capacity = 5
	#   requirement = 1 per unit
	#   factor = 0.50
	#
	# capital:
	#   investment_capacity = 5
	#   requirement = 1 per unit
	#   factor = 0.50
	#
	# energy / power-capacity bridge:
	#   power = 0.50
	#   power requirement = 0.10 per unit of process capacity
	#   factor = 0.50
	#
	# Keep energy_requirement as the canonical resource-demand map.
	# This test isolates the power-capacity bottleneck through the
	# explicit power_requirement field.
	#
	# Combined expected physical factor:
	#
	#   0.50 * 0.50 * 0.50 = 0.125
	#
	# Base capacity:
	#   10 units
	#
	# Expected physical production:
	#   10 * 0.125 = 1.25
	# ------------------------------------------------------------

	var processes: Dictionary = {}

	for process_id in original_industry_state.get(
		"processes",
		{}
	).keys():

		var original_process = (
			original_industry_state["processes"][process_id]
		)

		if typeof(original_process) == TYPE_DICTIONARY:
			processes[process_id] = (
				original_process.duplicate(true)
			)
			processes[process_id]["active"] = false

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var adoption: Dictionary = (
		original_industry_state.get(
			"process_adoption",
			{}
		).duplicate(true)
	)

	adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		adoption
	)

	var controlled_definition: Dictionary = (
		original_definition.duplicate(true)
	)

	controlled_definition["technology_requirements"] = {}
	controlled_definition["capability_requirements"] = {}
	controlled_definition["infrastructure_requirements"] = {}
	controlled_definition["infrastructure_usage"] = {
		"modern_steelworks": 1.0
	}
	controlled_definition["labor_requirement"] = 1.0
	controlled_definition["labor_skill_requirement"] = {}
	controlled_definition["capital_requirement"] = 1.0
	controlled_definition["energy_requirement"] = (
		original_definition.get(
			"energy_requirement",
			{}
		).duplicate(true)
	)
	controlled_definition["power_requirement"] = 0.10
	controlled_definition["maintenance_requirement"] = {}
	controlled_definition["reliability"] = 1.0

	catalog.processes["steel_basic"] = (
		controlled_definition
	)

	# Neutralize unrelated production gates.
	infrastructure.set_state(
		"modern_steelworks",
		1.0
	)

	infrastructure.set_state(
		"industrial",
		1.0
	)

	infrastructure.set_state(
		"power",
		0.50
	)

	population.set_state(
		"effective_labor_capacity",
		5.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		100.0
	)

	economy.set_state(
		"investment_capacity",
		5.0
	)

	# Explicitly provide the process-use infrastructure capacity so this
	# test isolates labor/capital/energy rather than the infrastructure
	# bridge already validated by Step 2.4.
	resources.set_state(
		"infrastructure_capacity",
		{
			"modern_steelworks": 1.0
		}
	)

	var all_passed := true
	var expected_monthly_production := 1.25

	# ------------------------------------------------------------
	# THREE MONTHS — SAME BOTTLENECK MUST PERSIST
	# ------------------------------------------------------------

	for month_index in range(1, 4):

		var monthly_stockpile: Dictionary = (
			original_resource_state.get(
				"stockpile",
				{}
			).duplicate(true)
		)

		monthly_stockpile["iron"] = 20.0
		monthly_stockpile["coal"] = 10.0
		monthly_stockpile["steel"] = 0.0

		resources.set_state(
			"stockpile",
			monthly_stockpile
		)

		production_process_system.process_month(
			world
		)

		var outcome: Dictionary = (
			industry.get_production_outcome(
				"steel_basic"
			)
		)

		var actual_production: float = float(
			outcome.get(
				"actual_production",
				0.0
			)
		)

		var labor_factor: float = (
			production_process_system._get_labor_capacity_factor(
				"steel_basic",
				india,
				10.0
			)
		)

		var capital_factor: float = (
			production_process_system._get_capital_capacity_factor(
				"steel_basic",
				india,
				10.0
			)
		)

		var energy_factor: float = (
			production_process_system._get_energy_capacity_factor(
				"steel_basic",
				india,
				10.0
			)
		)

		var expected_combined_factor: float = (
			labor_factor
			* capital_factor
			* energy_factor
		)

		var month_passed: bool = (
			is_equal_approx(
				labor_factor,
				0.50
			)
			and is_equal_approx(
				capital_factor,
				0.50
			)
			and is_equal_approx(
				energy_factor,
				0.50
			)
			and is_equal_approx(
				expected_combined_factor,
				0.125
			)
			and is_equal_approx(
				actual_production,
				expected_monthly_production
			)
		)

		_log(
			"Month "
			+ str(month_index)
			+ " constraint persistence: "
			+ _pass_fail(month_passed)
			+ " | labor_factor=0.50 actual="
			+ str(labor_factor)
			+ " | capital_factor=0.50 actual="
			+ str(capital_factor)
			+ " | energy_factor=0.50 actual="
			+ str(energy_factor)
			+ " | combined_factor=0.125 actual="
			+ str(expected_combined_factor)
			+ " | production=1.25 actual="
			+ str(actual_production)
		)

		all_passed = all_passed and month_passed

	# ------------------------------------------------------------
	# RECOVERY — REMOVE ALL THREE BOTTLENECKS
	# ------------------------------------------------------------

	population.set_state(
		"effective_labor_capacity",
		100.0
	)

	economy.set_state(
		"investment_capacity",
		100.0
	)

	infrastructure.set_state(
		"power",
		1.0
	)

	var recovery_stockpile: Dictionary = (
		original_resource_state.get(
			"stockpile",
			{}
		).duplicate(true)
	)

	recovery_stockpile["iron"] = 20.0
	recovery_stockpile["coal"] = 10.0
	recovery_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		recovery_stockpile
	)

	production_process_system.process_month(
		world
	)

	var recovery_outcome: Dictionary = (
		industry.get_production_outcome(
			"steel_basic"
		)
	)

	var recovery_output: float = float(
		recovery_outcome.get(
			"actual_production",
			0.0
		)
	)

	var recovery_passed: bool = is_equal_approx(
		recovery_output,
		10.0
	)

	_log(
		"Constraint recovery restores production: "
		+ _pass_fail(recovery_passed)
		+ " | expected=10.0 actual="
		+ str(recovery_output)
	)

	all_passed = all_passed and recovery_passed

	# ------------------------------------------------------------
	# RESTORE EVERYTHING
	# ------------------------------------------------------------

	population.state.clear()
	for key in original_population_state.keys():
		population.state[key] = (
			original_population_state[key]
		)

	economy.state.clear()
	for key in original_economy_state.keys():
		economy.state[key] = (
			original_economy_state[key]
		)

	infrastructure.state.clear()
	for key in original_infrastructure_state.keys():
		infrastructure.state[key] = (
			original_infrastructure_state[key]
		)

	resources.state.clear()
	for key in original_resource_state.keys():
		resources.state[key] = (
			original_resource_state[key]
		)

	industry.state.clear()
	for key in original_industry_state.keys():
		industry.state[key] = (
			original_industry_state[key]
		)

	catalog.processes["steel_basic"] = (
		original_definition
	)

	_log(
		"Integrated Physical Economy — Labor / Capital / Energy Persistence test passed: "
		+ str(all_passed)
	)

	return all_passed
