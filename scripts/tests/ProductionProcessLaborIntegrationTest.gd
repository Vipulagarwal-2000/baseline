class_name ProductionProcessLaborIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS LABOR INTEGRATION TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
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

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if population == null or resources == null or industry == null:
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

	var original_labor_capacity = population.get_state(
		"effective_labor_capacity",
		0.0
	)

	var original_skilled_labor_capacity = population.get_state(
		"effective_skilled_labor_capacity",
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

	var labor_definition := original_definition.duplicate(true)
	labor_definition["labor_requirement"] = 1.0
	labor_definition["labor_skill_requirement"] = 0.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = labor_definition

	# ------------------------------------------------------------
	# TEST 1 — LABOR CAPACITY BOTTLENECK
	# ------------------------------------------------------------

	population.set_state(
		"effective_labor_capacity",
		5.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		5.0
	)

	var labor_stockpile = original_stockpile.duplicate(true)
	labor_stockpile["iron"] = 20.0
	labor_stockpile["coal"] = 10.0
	labor_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		labor_stockpile
	)

	production_process_system.process_month(
		world
	)

	var labor_result = resources.get_state(
		"stockpile",
		{}
	)

	var labor_steel = float(
		labor_result.get(
			"steel",
			0.0
		)
	)

	var labor_factor = production_process_system._get_labor_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var labor_capacity_passed := is_equal_approx(
		labor_steel,
		5.0
	)

	var labor_factor_passed := is_equal_approx(
		labor_factor,
		0.50
	)

	TestLogger.write_line(
		"Labor capacity limits production: "
		+ (
			"PASS"
			if labor_capacity_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(labor_steel)
	)

	TestLogger.write_line(
		"Labor bottleneck factor = 0.50: "
		+ (
			"PASS"
			if labor_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(labor_factor)
	)

	# ------------------------------------------------------------
	# TEST 2 — SKILLED LABOR BOTTLENECK
	# ------------------------------------------------------------

	labor_definition["labor_requirement"] = 0.0
	labor_definition["labor_skill_requirement"] = 1.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = labor_definition

	population.set_state(
		"effective_labor_capacity",
		10.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		2.0
	)

	var skilled_stockpile = original_stockpile.duplicate(true)
	skilled_stockpile["iron"] = 20.0
	skilled_stockpile["coal"] = 10.0
	skilled_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		skilled_stockpile
	)

	production_process_system.process_month(
		world
	)

	var skilled_result = resources.get_state(
		"stockpile",
		{}
	)

	var skilled_steel = float(
		skilled_result.get(
			"steel",
			0.0
		)
	)

	var skilled_factor = production_process_system._get_labor_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var skilled_production_passed := is_equal_approx(
		skilled_steel,
		2.0
	)

	var skilled_factor_passed := is_equal_approx(
		skilled_factor,
		0.20
	)

	TestLogger.write_line(
		"Skilled labor limits production: "
		+ (
			"PASS"
			if skilled_production_passed
			else "FAIL"
		)
		+ " | expected=2.0 actual="
		+ str(skilled_steel)
	)

	TestLogger.write_line(
		"Skilled labor bottleneck factor = 0.20: "
		+ (
			"PASS"
			if skilled_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(skilled_factor)
	)

	# ------------------------------------------------------------
	# TEST 3 — NO LABOR REQUIREMENT IS NEUTRAL
	# ------------------------------------------------------------

	labor_definition["labor_requirement"] = 0.0
	labor_definition["labor_skill_requirement"] = 0.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = labor_definition

	population.set_state(
		"effective_labor_capacity",
		0.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
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

	var neutral_factor = production_process_system._get_labor_capacity_factor(
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
		"No labor requirement remains neutral: "
		+ (
			"PASS"
			if neutral_production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(neutral_steel)
	)

	TestLogger.write_line(
		"No labor requirement factor = 1.0: "
		+ (
			"PASS"
			if neutral_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(neutral_factor)
	)

	# Restore state.
	population.set_state(
		"effective_labor_capacity",
		original_labor_capacity
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		original_skilled_labor_capacity
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
		labor_capacity_passed
		and labor_factor_passed
		and skilled_production_passed
		and skilled_factor_passed
		and neutral_production_passed
		and neutral_factor_passed
	)
