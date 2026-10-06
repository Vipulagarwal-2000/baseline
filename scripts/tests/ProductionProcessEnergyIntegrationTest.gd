class_name ProductionProcessEnergyIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS ENERGY INTEGRATION TEST"
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

	var infrastructure = india.get_component(
		"infrastructure"
	)

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if (
		population == null
		or resources == null
		or industry == null
		or infrastructure == null
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

	var original_power = infrastructure.get_state(
		"power",
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

	# Keep labor neutral so this test isolates infrastructure power capacity.
	population.set_state(
		"effective_labor_capacity",
		100.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		100.0
	)

	var energy_definition := original_definition.duplicate(true)
	energy_definition["labor_requirement"] = 0.0
	energy_definition["labor_skill_requirement"] = 0.0
	energy_definition["power_requirement"] = 0.10

	production_process_system.catalog.processes[
		"steel_basic"
	] = energy_definition

	# ------------------------------------------------------------
	# TEST 1 — POWER CAPACITY BOTTLENECK
	# ------------------------------------------------------------

	infrastructure.set_state(
		"power",
		0.50
	)

	var energy_stockpile = original_stockpile.duplicate(true)
	energy_stockpile["iron"] = 20.0
	energy_stockpile["coal"] = 10.0
	energy_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		energy_stockpile
	)

	production_process_system.process_month(
		world
	)

	var energy_result = resources.get_state(
		"stockpile",
		{}
	)

	var energy_steel = float(
		energy_result.get(
			"steel",
			0.0
		)
	)

	var energy_factor = production_process_system._get_energy_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var energy_pool_after = float(
		infrastructure.get_state(
			"power",
			0.0
		)
	)

	var energy_production_passed := is_equal_approx(
		energy_steel,
		5.0
	)

	var energy_factor_passed := is_equal_approx(
		energy_factor,
		0.50
	)

	var energy_pool_unchanged_passed := is_equal_approx(
		energy_pool_after,
		0.50
	)

	TestLogger.write_line(
		"Power availability limits production: "
		+ (
			"PASS"
			if energy_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(energy_steel)
	)

	TestLogger.write_line(
		"Energy bottleneck factor = 0.50: "
		+ (
			"PASS"
			if energy_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(energy_factor)
	)

	TestLogger.write_line(
		"Power capacity is not consumed: "
		+ (
			"PASS"
			if energy_pool_unchanged_passed
			else "FAIL"
		)
		+ " | expected=0.50 actual="
		+ str(energy_pool_after)
	)

	# ------------------------------------------------------------
	# TEST 2 — POWER REQUIREMENT SCALING
	# ------------------------------------------------------------

	energy_definition["power_requirement"] = 0.20

	production_process_system.catalog.processes[
		"steel_basic"
	] = energy_definition

	infrastructure.set_state(
		"power",
		1.0
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

	var scaled_factor = production_process_system._get_energy_capacity_factor(
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
		"Higher power requirement scales bottleneck: "
		+ (
			"PASS"
			if scaled_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(scaled_steel)
	)

	TestLogger.write_line(
		"Power requirement = 0.20 gives factor 0.50: "
		+ (
			"PASS"
			if scaled_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(scaled_factor)
	)

	# ------------------------------------------------------------
	# TEST 3 — NO POWER REQUIREMENT IS NEUTRAL
	# ------------------------------------------------------------

	energy_definition["power_requirement"] = 0.0

	production_process_system.catalog.processes[
		"steel_basic"
	] = energy_definition

	infrastructure.set_state(
		"power",
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

	var neutral_factor = production_process_system._get_energy_capacity_factor(
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

	var live_energy_requirement = production_process_system.catalog.get_process(
		"steel_basic"
	).get(
		"energy_requirement",
		{}
	)

	var energy_schema_passed := (
		typeof(live_energy_requirement) == TYPE_DICTIONARY
	)

	TestLogger.write_line(
		"Energy requirement remains resource-map schema: "
		+ ("PASS" if energy_schema_passed else "FAIL")
		+ " | type=" + str(typeof(live_energy_requirement))
	)

	TestLogger.write_line(
		"No power requirement remains neutral: "
		+ (
			"PASS"
			if neutral_production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(neutral_steel)
	)

	TestLogger.write_line(
		"No power requirement factor = 1.0: "
		+ (
			"PASS"
			if neutral_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(neutral_factor)
	)

	# Restore state.
	infrastructure.set_state(
		"power",
		original_power
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
		energy_production_passed
		and energy_factor_passed
		and energy_pool_unchanged_passed
		and scaled_production_passed
		and scaled_factor_passed
		and neutral_production_passed
		and neutral_factor_passed
		and energy_schema_passed
	)
