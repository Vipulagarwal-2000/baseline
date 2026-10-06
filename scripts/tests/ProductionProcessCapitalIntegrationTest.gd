class_name ProductionProcessCapitalIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS CAPITAL INTEGRATION TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	var population = india.get_component(
		"population"
	)

	var resources = india.get_component(
		"resources"
	)

	var industry = india.get_component(
		"industry"
	)

	var economy = india.get_component(
		"economy"
	)

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if (
		population == null
		or resources == null
		or industry == null
		or economy == null
	):
		TestLogger.write_line(
			"Required components: FAIL"
		)
		return false

	if production_process_system == null:
		TestLogger.write_line(
			"Production Process System registered: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required components and registered system: PASS"
	)

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

	var original_investment_capacity = economy.get_state(
		"investment_capacity",
		0.0
	)

	var original_definition: Dictionary = (
		production_process_system.catalog.get_process(
			"steel_basic"
		)
	)

	var processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process = original_processes[process_id]
		if typeof(original_process) == TYPE_DICTIONARY:
			processes[process_id] = original_process.duplicate(true)
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

	var adoption = original_process_adoption.duplicate(true)
	adoption["steel_basic"] = 1.0
	industry.set_state(
		"process_adoption",
		adoption
	)

	# Keep labor neutral so this test measures capital alone.
	population.set_state(
		"effective_labor_capacity",
		100.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		100.0
	)

	var capital_definition := original_definition.duplicate(true)
	capital_definition["labor_requirement"] = 0.0
	capital_definition["labor_skill_requirement"] = 0.0
	capital_definition["capital_requirement"] = 1.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = capital_definition

	# ------------------------------------------------------------
	# TEST 1 — CAPITAL CAPACITY BOTTLENECK
	# ------------------------------------------------------------

	economy.set_state(
		"investment_capacity",
		5.0
	)

	var capital_stockpile = original_stockpile.duplicate(true)
	capital_stockpile["iron"] = 20.0
	capital_stockpile["coal"] = 10.0
	capital_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		capital_stockpile
	)

	production_process_system.process_month(
		world
	)

	var capital_result = resources.get_state(
		"stockpile",
		{}
	)

	var capital_steel = float(
		capital_result.get(
			"steel",
			0.0
		)
	)

	var capital_factor = production_process_system._get_capital_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var capital_pool_after = float(
		economy.get_state(
			"investment_capacity",
			0.0
		)
	)

	var capital_production_passed := is_equal_approx(
		capital_steel,
		5.0
	)

	var capital_factor_passed := is_equal_approx(
		capital_factor,
		0.50
	)

	var capital_pool_unchanged_passed := is_equal_approx(
		capital_pool_after,
		5.0
	)

	TestLogger.write_line(
		"Capital capacity limits production: "
		+ (
			"PASS"
			if capital_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(capital_steel)
	)

	TestLogger.write_line(
		"Capital bottleneck factor = 0.50: "
		+ (
			"PASS"
			if capital_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(capital_factor)
	)

	TestLogger.write_line(
		"Capital capacity pool is not consumed: "
		+ (
			"PASS"
			if capital_pool_unchanged_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(capital_pool_after)
	)

	# ------------------------------------------------------------
	# TEST 2 — CAPITAL REQUIREMENT SCALING
	# ------------------------------------------------------------

	capital_definition["capital_requirement"] = 2.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = capital_definition

	economy.set_state(
		"investment_capacity",
		10.0
	)

	var scaled_stockpile = original_stockpile.duplicate(true)
	scaled_stockpile["iron"] = 20.0
	scaled_stockpile["coal"] = 10.0
	scaled_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		scaled_stockpile
	)

	production_process_system.process_month(
		world
	)

	var scaled_result = resources.get_state(
		"stockpile",
		{}
	)

	var scaled_steel = float(
		scaled_result.get(
			"steel",
			0.0
		)
	)

	var scaled_factor = production_process_system._get_capital_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var scaled_production_passed := is_equal_approx(
		scaled_steel,
		5.0
	)

	var scaled_factor_passed := is_equal_approx(
		scaled_factor,
		0.50
	)

	TestLogger.write_line(
		"Higher capital requirement scales bottleneck: "
		+ (
			"PASS"
			if scaled_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(scaled_steel)
	)

	TestLogger.write_line(
		"Capital requirement = 2.0 gives factor 0.50: "
		+ (
			"PASS"
			if scaled_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(scaled_factor)
	)

	# ------------------------------------------------------------
	# TEST 3 — NO CAPITAL REQUIREMENT IS NEUTRAL
	# ------------------------------------------------------------

	capital_definition["capital_requirement"] = 0.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = capital_definition

	economy.set_state(
		"investment_capacity",
		0.0
	)

	var neutral_stockpile = original_stockpile.duplicate(true)
	neutral_stockpile["iron"] = 20.0
	neutral_stockpile["coal"] = 10.0
	neutral_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		neutral_stockpile
	)

	production_process_system.process_month(
		world
	)

	var neutral_result = resources.get_state(
		"stockpile",
		{}
	)

	var neutral_steel = float(
		neutral_result.get(
			"steel",
			0.0
		)
	)

	var neutral_factor = production_process_system._get_capital_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var neutral_production_passed := is_equal_approx(
		neutral_steel,
		10.0
	)

	var neutral_factor_passed := is_equal_approx(
		neutral_factor,
		1.0
	)

	TestLogger.write_line(
		"No capital requirement remains neutral: "
		+ (
			"PASS"
			if neutral_production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(neutral_steel)
	)

	TestLogger.write_line(
		"No capital requirement factor = 1.0: "
		+ (
			"PASS"
			if neutral_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(neutral_factor)
	)

	# Restore state.
	economy.set_state(
		"investment_capacity",
		original_investment_capacity
	)

	resources.set_state(
		"stockpile",
		original_stockpile
	)

	industry.set_state(
		"processes",
		original_processes
	)

	industry.set_state(
		"process_adoption",
		original_process_adoption
	)

	production_process_system.catalog.processes[
		"steel_basic"
	] = original_definition

	return (
		capital_production_passed
		and capital_factor_passed
		and capital_pool_unchanged_passed
		and scaled_production_passed
		and scaled_factor_passed
		and neutral_production_passed
		and neutral_factor_passed
	)
