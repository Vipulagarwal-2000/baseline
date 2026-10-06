class_name ProductionProcessChainExecutionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS CHAIN EXECUTION TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var india = world.get_entity("india")
	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false

	var resources = india.get_component("resources")
	var industry = india.get_component("industry")
	var infrastructure = india.get_component("infrastructure")

	if resources == null:
		TestLogger.write_line("India resource component: FAIL")
		return false
	if industry == null:
		TestLogger.write_line("India industry component: FAIL")
		return false
	if infrastructure == null:
		TestLogger.write_line("India infrastructure component: FAIL")
		return false

	TestLogger.write_line("India resource component: PASS")
	TestLogger.write_line("India industry component: PASS")
	TestLogger.write_line("India infrastructure component: PASS")

	var population = india.get_component("population")
	var economy = india.get_component("economy")

	var original_effective_labor_capacity := 0.0
	var original_effective_skilled_labor_capacity := 0.0
	var original_investment_capacity := 0.0
	var original_power := float(infrastructure.get_state("power", 0.0))
	var original_industrial := float(infrastructure.get_state("industrial", 0.0))

	if population != null:
		original_effective_labor_capacity = float(
			population.get_state("effective_labor_capacity", 0.0)
		)
		original_effective_skilled_labor_capacity = float(
			population.get_state("effective_skilled_labor_capacity", 0.0)
		)

	if economy != null:
		original_investment_capacity = float(
			economy.get_state("investment_capacity", 0.0)
		)

	# Neutralize unrelated physical capacity gates for this chain-order test.
	if population != null:
		population.set_state("effective_labor_capacity", 1000.0)
		population.set_state("effective_skilled_labor_capacity", 1000.0)

	if economy != null:
		economy.set_state("investment_capacity", 1000.0)

	infrastructure.set_state("power", 1.0)
	infrastructure.set_state("industrial", 1.0)

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if production_process_system == null:
		production_process_system = ProductionProcessSystem.new()

	var original_stockpile = resources.get_state(
		"stockpile",
		{}
	).duplicate(true)
	var original_processes = industry.get_state(
		"processes",
		{}
	).duplicate(true)
	var original_process_adoption = industry.get_state(
		"process_adoption",
		{}
	).duplicate(true)
	var original_maintenance = infrastructure.get_state(
		"process_maintenance_capacity",
		{}
	).duplicate(true)

	var processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process = original_processes[process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue
		processes[str(process_id)] = original_process.duplicate(true)
		processes[str(process_id)]["active"] = false

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	processes["machinery_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state("processes", processes)

	var adoption = original_process_adoption.duplicate(true)
	adoption["steel_basic"] = 1.0
	adoption["machinery_basic"] = 1.0
	industry.set_state("process_adoption", adoption)

	# Explicitly establish fully maintained production infrastructure for
	# this isolated chain test.
	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)

	var stockpile = original_stockpile.duplicate(true)
	stockpile["iron"] = 20.0
	stockpile["coal"] = 10.0
	stockpile["steel"] = 0.0
	stockpile["machinery"] = 0.0

	resources.set_state("stockpile", stockpile)

	var process_order := [
		"machinery_basic",
		"steel_basic"
	]

	TestLogger.write_line(
		"Configured process order: " + str(process_order)
	)

	# The system sorts by catalog production_stage, so steel_basic runs
	# before machinery_basic even though the configured dictionary/order is
	# intentionally reversed.
	production_process_system.process_month(world)

	var result = resources.get_state("stockpile", {})
	var iron_after := float(result.get("iron", 0.0))
	var coal_after := float(result.get("coal", 0.0))
	var steel_after := float(result.get("steel", 0.0))
	var machinery_after := float(result.get("machinery", 0.0))

	var iron_passed := is_equal_approx(iron_after, 0.0)
	var coal_passed := is_equal_approx(coal_after, 0.0)
	var steel_passed := is_equal_approx(steel_after, 0.0)
	var machinery_passed := is_equal_approx(machinery_after, 5.0)

	TestLogger.write_line(
		"Stage-order iron consumption: "
		+ ("PASS" if iron_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(iron_after)
	)
	TestLogger.write_line(
		"Stage-order coal consumption: "
		+ ("PASS" if coal_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(coal_after)
	)
	TestLogger.write_line(
		"Stage-order steel production: "
		+ ("PASS" if steel_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(steel_after)
	)
	TestLogger.write_line(
		"Stage-order machinery production: "
		+ ("PASS" if machinery_passed else "FAIL")
		+ " | expected=5.0 actual=" + str(machinery_after)
	)

	var passed := (
		iron_passed
		and coal_passed
		and steel_passed
		and machinery_passed
	)

	TestLogger.write_line(
		"ProductionProcessChainExecution stage-order test passed: "
		+ str(passed)
	)

	resources.set_state("stockpile", original_stockpile)
	industry.set_state("processes", original_processes)
	industry.set_state("process_adoption", original_process_adoption)
	infrastructure.set_state(
		"process_maintenance_capacity",
		original_maintenance
	)

	if population != null:
		population.set_state(
			"effective_labor_capacity",
			original_effective_labor_capacity
		)
		population.set_state(
			"effective_skilled_labor_capacity",
			original_effective_skilled_labor_capacity
		)

	if economy != null:
		economy.set_state(
			"investment_capacity",
			original_investment_capacity
		)

	infrastructure.set_state("power", original_power)
	infrastructure.set_state("industrial", original_industrial)

	return passed
