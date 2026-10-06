class_name IntegratedPhysicalEconomyResourceShortageConstraintTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — RESOURCE SHORTAGE -> PRODUCTION CONSTRAINT TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var resources = india.get_component("resources")
	var industry = india.get_component("industry")
	var infrastructure = india.get_component("infrastructure")
	var population = india.get_component("population")
	var economy = india.get_component("economy")

	if resources == null or industry == null or infrastructure == null:
		TestLogger.write_line(
			"Required physical-economy components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required physical-economy components available: PASS"
	)

	var resource_system = simulation.get_system(
		"resource_system"
	)

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if resource_system == null:
		TestLogger.write_line(
			"Registered ResourceSystem available: FAIL"
		)
		return false

	if production_process_system == null:
		TestLogger.write_line(
			"Registered ProductionProcessSystem available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Registered ResourceSystem available: PASS"
	)

	TestLogger.write_line(
		"Registered ProductionProcessSystem available: PASS"
	)

	var original_processes: Dictionary = (
		industry.get_state(
			"processes",
			{}
		).duplicate(true)
	)

	var original_adoption: Dictionary = (
		industry.get_state(
			"process_adoption",
			{}
		).duplicate(true)
	)

	var original_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)

	var original_production: Dictionary = (
		resources.get_state(
			"production",
			{}
		).duplicate(true)
	)

	var original_consumption: Dictionary = (
		resources.get_state(
			"consumption",
			{}
		).duplicate(true)
	)

	var original_imports: Dictionary = (
		resources.get_state(
			"imports",
			{}
		).duplicate(true)
	)

	var original_exports: Dictionary = (
		resources.get_state(
			"exports",
			{}
		).duplicate(true)
	)

	var original_process_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		).duplicate(true)
	)

	var original_process_shortages: Dictionary = (
		resources.get_state(
			"production_process_shortages",
			{}
		).duplicate(true)
	)

	var original_process_shortage_ratio: Dictionary = (
		resources.get_state(
			"production_process_shortage_ratio",
			{}
		).duplicate(true)
	)

	var original_process_availability: Dictionary = (
		resources.get_state(
			"production_process_resource_availability",
			{}
		).duplicate(true)
	)

	var original_labor_capacity := 0.0
	var original_skilled_labor_capacity := 0.0
	if population != null:
		original_labor_capacity = float(
			population.get_state(
				"effective_labor_capacity",
				0.0
			)
		)
		original_skilled_labor_capacity = float(
			population.get_state(
				"effective_skilled_labor_capacity",
				0.0
			)
		)

	var original_investment_capacity := 0.0
	if economy != null:
		original_investment_capacity = float(
			economy.get_state(
				"investment_capacity",
				0.0
			)
		)

	var original_power := float(
		infrastructure.get_state(
			"power",
			0.0
		)
	)

	var original_industrial := float(
		infrastructure.get_state(
			"industrial",
			0.0
		)
	)

	var original_maintenance: Dictionary = (
		infrastructure.get_state(
			"process_maintenance_capacity",
			{}
		).duplicate(true)
	)

	# Isolate one industrial process so the test measures the actual
	# ResourceSystem -> ProductionProcessSystem shortage link.
	var isolated_processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process = original_processes[process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		isolated_processes[str(process_id)] = (
			original_process.duplicate(true)
		)
		isolated_processes[str(process_id)]["active"] = false

	isolated_processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)

	var isolated_adoption: Dictionary = (
		original_adoption.duplicate(true)
	)
	isolated_adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	# Neutralize unrelated live capacity constraints.
	if population != null:
		population.set_state(
			"effective_labor_capacity",
			1000.0
		)
		population.set_state(
			"effective_skilled_labor_capacity",
			1000.0
		)

	if economy != null:
		economy.set_state(
			"investment_capacity",
			1000.0
		)

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

	# Isolate the resource flow so ordinary consumption/import/export
	# pressure cannot be mistaken for the Step 2.2 production shortage.
	resources.set_state(
		"production",
		{}
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
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	var shortage_stockpile := original_stockpile.duplicate(true)
	shortage_stockpile["iron"] = 5.0
	shortage_stockpile["coal"] = 10.0
	shortage_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		shortage_stockpile
	)

	# ------------------------------------------------------------
	# TEST 1 — RESOURCE SYSTEM EXPOSES PRODUCTION AVAILABILITY
	# ------------------------------------------------------------

	resource_system.process_month(world)

	var production_shortages: Dictionary = resources.get_state(
		"production_process_shortages",
		{}
	)

	var shortage_ratios: Dictionary = resources.get_state(
		"production_process_shortage_ratio",
		{}
	)

	var availability: Dictionary = resources.get_state(
		"production_process_resource_availability",
		{}
	)

	var iron_shortage := float(
		production_shortages.get(
			"iron",
			0.0
		)
	)
	var coal_shortage := float(
		production_shortages.get(
			"coal",
			0.0
		)
	)

	var iron_ratio := float(
		shortage_ratios.get(
			"iron",
			0.0
		)
	)
	var iron_availability := float(
		availability.get(
			"iron",
			1.0
		)
	)
	var coal_availability := float(
		availability.get(
			"coal",
			1.0
		)
	)

	var shortage_state_pass := (
		is_equal_approx(iron_shortage, 15.0)
		and is_equal_approx(coal_shortage, 0.0)
		and is_equal_approx(iron_ratio, 75.0)
		and is_equal_approx(iron_availability, 0.25)
		and is_equal_approx(coal_availability, 1.0)
	)

	TestLogger.write_line(
		"Resource shortage availability state: "
		+ ("PASS" if shortage_state_pass else "FAIL")
		+ " | iron_shortage=15 actual="
		+ str(iron_shortage)
		+ " iron_availability=0.25 actual="
		+ str(iron_availability)
		+ " iron_shortage_ratio=75 actual="
		+ str(iron_ratio)
	)

	# ------------------------------------------------------------
	# TEST 2 — RESOURCE SHORTAGE CONSTRAINS PRODUCTION
	# ------------------------------------------------------------

	production_process_system.process_month(world)

	var production_outcome: Dictionary = industry.get_production_outcome(
		"steel_basic"
	)

	var actual_production := float(
		production_outcome.get(
			"actual_production",
			0.0
		)
	)

	var resource_constraint_factor := float(
		production_outcome.get(
			"resource_constraint_factor",
			1.0
		)
	)

	var constraint_sources: Array = production_outcome.get(
		"constraint_sources",
		[]
	)

	var demand_after_production: Dictionary = resources.get_state(
		"production_process_demand",
		{}
	)

	var constrained_production_pass := (
		is_equal_approx(actual_production, 2.5)
		and is_equal_approx(resource_constraint_factor, 0.25)
		and constraint_sources.has("resource_shortage")
		and is_equal_approx(
			float(demand_after_production.get("iron", 0.0)),
			20.0
		)
		and is_equal_approx(
			float(demand_after_production.get("coal", 0.0)),
			10.0
		)
	)

	TestLogger.write_line(
		"Resource shortage constrains production while gross demand remains visible: "
		+ ("PASS" if constrained_production_pass else "FAIL")
		+ " | expected_production=2.5 actual="
		+ str(actual_production)
		+ " resource_constraint_factor=0.25 actual="
		+ str(resource_constraint_factor)
	)

	# ------------------------------------------------------------
	# RESTORE ORIGINAL STATE
	# ------------------------------------------------------------

	industry.set_state(
		"processes",
		original_processes
	)
	industry.set_state(
		"process_adoption",
		original_adoption
	)

	resources.set_state(
		"stockpile",
		original_stockpile
	)
	resources.set_state(
		"production",
		original_production
	)
	resources.set_state(
		"consumption",
		original_consumption
	)
	resources.set_state(
		"imports",
		original_imports
	)
	resources.set_state(
		"exports",
		original_exports
	)
	resources.set_state(
		"production_process_demand",
		original_process_demand
	)
	resources.set_state(
		"production_process_shortages",
		original_process_shortages
	)
	resources.set_state(
		"production_process_shortage_ratio",
		original_process_shortage_ratio
	)
	resources.set_state(
		"production_process_resource_availability",
		original_process_availability
	)

	if population != null:
		population.set_state(
			"effective_labor_capacity",
			original_labor_capacity
		)
		population.set_state(
			"effective_skilled_labor_capacity",
			original_skilled_labor_capacity
		)

	if economy != null:
		economy.set_state(
			"investment_capacity",
			original_investment_capacity
		)

	infrastructure.set_state(
		"power",
		original_power
	)
	infrastructure.set_state(
		"industrial",
		original_industrial
	)
	infrastructure.set_state(
		"process_maintenance_capacity",
		original_maintenance
	)

	var all_passed := (
		shortage_state_pass
		and constrained_production_pass
	)

	TestLogger.write_line(
		"Integrated Physical Economy — Resource Shortage -> Production Constraint test passed: "
		+ str(all_passed)
	)

	return all_passed
