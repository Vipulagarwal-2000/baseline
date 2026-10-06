class_name ProductionProcessMaintenanceIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS MAINTENANCE INTEGRATION TEST"
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

	var original_maintenance_capacity = infrastructure.get_state(
		"process_maintenance_capacity",
		{}
	).duplicate(true)

	var original_definition: Dictionary = (
		production_process_system.catalog.get_process(
			"steel_basic"
		)
	)

	var processes: Dictionary = {}

	for process_id in original_processes.keys():

		var original_process = original_processes[process_id]

		if typeof(original_process) != TYPE_DICTIONARY:
			continue

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

	var adoption = original_process_adoption.duplicate(true)

	adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		adoption
	)

	# Keep labor neutral so the test isolates maintenance/reliability.
	population.set_state(
		"effective_labor_capacity",
		100.0
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		100.0
	)

	# Remove other physical capacity bottlenecks for this test.
	var maintenance_definition := original_definition.duplicate(true)

	maintenance_definition["labor_requirement"] = 0.0
	maintenance_definition["labor_skill_requirement"] = 0.0
	maintenance_definition["capital_requirement"] = 0.0
	maintenance_definition["energy_requirement"] = 0.0
	maintenance_definition["maintenance_requirement"] = {
		"machinery": 0.1
	}
	maintenance_definition["reliability"] = 0.90

	production_process_system.catalog.processes[
		"steel_basic"
	] = maintenance_definition


	# ============================================================
	# TEST 1 — NO MAINTENANCE CAPACITY
	# ============================================================

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 0.0
		}
	)

	var zero_maintenance_stockpile = original_stockpile.duplicate(true)
	zero_maintenance_stockpile["iron"] = 20.0
	zero_maintenance_stockpile["coal"] = 10.0
	zero_maintenance_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		zero_maintenance_stockpile
	)

	production_process_system.process_month(
		world
	)

	var zero_result = resources.get_state(
		"stockpile",
		{}
	)

	var zero_production := float(
		zero_result.get(
			"steel",
			0.0
		)
	)

	var zero_factor :float= production_process_system._get_maintenance_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var zero_production_passed := is_equal_approx(
		zero_production,
		0.0
	)

	var zero_factor_passed := is_equal_approx(
		zero_factor,
		0.0
	)

	TestLogger.write_line(
		"Zero maintenance capacity blocks production: "
		+ (
			"PASS"
			if zero_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(zero_production)
	)

	TestLogger.write_line(
		"Maintenance bottleneck factor = 0.00: "
		+ (
			"PASS"
			if zero_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(zero_factor)
	)


	# ============================================================
	# TEST 2 — PARTIAL MAINTENANCE
	# ============================================================

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 0.5
		}
	)

	var partial_stockpile = original_stockpile.duplicate(true)
	partial_stockpile["iron"] = 20.0
	partial_stockpile["coal"] = 10.0
	partial_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		partial_stockpile
	)

	production_process_system.process_month(
		world
	)

	var partial_result = resources.get_state(
		"stockpile",
		{}
	)

	var partial_production := float(
		partial_result.get(
			"steel",
			0.0
		)
	)

	var partial_factor :float= production_process_system._get_maintenance_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var partial_reliability :float= production_process_system._get_reliability_factor(
		"steel_basic",
		india,
		partial_factor
	)

	# maintenance_factor = 0.50
	# reliability = 0.90
	# reliability_factor = 1 - (1 - 0.90) * (1 - 0.50) = 0.95
	# production = 10 * 0.50 * 0.95 = 4.75
	var expected_partial_production := 4.75

	var partial_production_passed := is_equal_approx(
		partial_production,
		expected_partial_production
	)

	var partial_factor_passed := is_equal_approx(
		partial_factor,
		0.50
	)

	var partial_reliability_passed := is_equal_approx(
		partial_reliability,
		0.95
	)

	TestLogger.write_line(
		"Partial maintenance limits production: "
		+ (
			"PASS"
			if partial_production_passed
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_partial_production)
		+ " actual="
		+ str(partial_production)
	)

	TestLogger.write_line(
		"Maintenance bottleneck factor = 0.50: "
		+ (
			"PASS"
			if partial_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(partial_factor)
	)

	TestLogger.write_line(
		"Deterministic reliability factor = 0.95: "
		+ (
			"PASS"
			if partial_reliability_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(partial_reliability)
	)


	# ============================================================
	# TEST 3 — FULL MAINTENANCE
	# ============================================================

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)

	var full_stockpile = original_stockpile.duplicate(true)
	full_stockpile["iron"] = 20.0
	full_stockpile["coal"] = 10.0
	full_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		full_stockpile
	)

	production_process_system.process_month(
		world
	)

	var full_result = resources.get_state(
		"stockpile",
		{}
	)

	var full_production := float(
		full_result.get(
			"steel",
			0.0
		)
	)

	var full_factor :float= production_process_system._get_maintenance_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var full_reliability :float= production_process_system._get_reliability_factor(
		"steel_basic",
		india,
		full_factor
	)

	var full_production_passed := is_equal_approx(
		full_production,
		10.0
	)

	var full_factor_passed := is_equal_approx(
		full_factor,
		1.0
	)

	var full_reliability_passed := is_equal_approx(
		full_reliability,
		1.0
	)

	TestLogger.write_line(
		"Full maintenance restores production capacity: "
		+ (
			"PASS"
			if full_production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(full_production)
	)

	TestLogger.write_line(
		"Maintenance bottleneck factor = 1.00: "
		+ (
			"PASS"
			if full_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(full_factor)
	)

	TestLogger.write_line(
		"Full maintenance removes maintenance-exposed reliability penalty: "
		+ (
			"PASS"
			if full_reliability_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(full_reliability)
	)


	# ============================================================
	# TEST 4 — NO MAINTENANCE REQUIREMENT REMAINS NEUTRAL
	# ============================================================

	var neutral_definition := maintenance_definition.duplicate(true)
	neutral_definition["maintenance_requirement"] = {}

	production_process_system.catalog.processes[
		"steel_basic"
	] = neutral_definition

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 0.0
		}
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

	var neutral_production := float(
		neutral_result.get(
			"steel",
			0.0
		)
	)

	var neutral_factor :float= production_process_system._get_maintenance_capacity_factor(
		"steel_basic",
		india,
		10.0
	)

	var neutral_production_passed := is_equal_approx(
		neutral_production,
		10.0
	)

	var neutral_factor_passed := is_equal_approx(
		neutral_factor,
		1.0
	)

	TestLogger.write_line(
		"No maintenance requirement remains neutral: "
		+ (
			"PASS"
			if neutral_production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(neutral_production)
	)

	TestLogger.write_line(
		"No maintenance requirement factor = 1.00: "
		+ (
			"PASS"
			if neutral_factor_passed
			else "FAIL"
		)
		+ " | actual="
		+ str(neutral_factor)
	)


	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

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

	infrastructure.set_state(
		"process_maintenance_capacity",
		original_maintenance_capacity
	)

	production_process_system.catalog.processes[
		"steel_basic"
	] = original_definition

	var passed := (
		zero_production_passed
		and zero_factor_passed
		and partial_production_passed
		and partial_factor_passed
		and partial_reliability_passed
		and full_production_passed
		and full_factor_passed
		and full_reliability_passed
		and neutral_production_passed
		and neutral_factor_passed
	)

	TestLogger.section(
		"PRODUCTION PROCESS MAINTENANCE INTEGRATION RESULT"
	)

	TestLogger.write_line(
		"Zero maintenance blocks production: "
		+ (
			"PASS"
			if zero_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Partial maintenance bottlenecks production: "
		+ (
			"PASS"
			if partial_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Deterministic reliability effect: "
		+ (
			"PASS"
			if partial_reliability_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Full maintenance restores production: "
		+ (
			"PASS"
			if full_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Processes without maintenance requirements remain neutral: "
		+ (
			"PASS"
			if neutral_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"ProductionProcessMaintenanceIntegrationTest: "
		+ str(passed)
	)

	return passed
