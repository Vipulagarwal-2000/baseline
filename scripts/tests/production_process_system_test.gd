class_name ProductionProcessSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS SYSTEM TEST"
	)

	# ============================================================
	# BASIC VALIDATION
	# ============================================================

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
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

	var resources = india.get_component(
		"resources"
	)

	var industry = india.get_component(
		"industry"
	)

	if resources == null:
		TestLogger.write_line(
			"India resource component: FAIL"
		)
		return false

	if industry == null:
		TestLogger.write_line(
			"India industry component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India resource component: PASS"
	)

	TestLogger.write_line(
		"India industry component: PASS"
	)

	# ============================================================
	# SAVE ORIGINAL STATE
	# ============================================================

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

	var original_infrastructure_capacity = resources.get_state(
		"infrastructure_capacity",
		{}
	).duplicate(true)

	var infrastructure = india.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		TestLogger.write_line(
			"India infrastructure component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India infrastructure component: PASS"
	)

	var population = india.get_component(
		"population"
	)

	var economy = india.get_component(
		"economy"
	)

	var original_effective_labor_capacity := 0.0
	var original_effective_skilled_labor_capacity := 0.0
	var original_investment_capacity := 0.0
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

	if population != null:
		original_effective_labor_capacity = float(
			population.get_state(
				"effective_labor_capacity",
				0.0
			)
		)
		original_effective_skilled_labor_capacity = float(
			population.get_state(
				"effective_skilled_labor_capacity",
				0.0
			)
		)

	if economy != null:
		original_investment_capacity = float(
			economy.get_state(
				"investment_capacity",
				0.0
			)
		)

	# Establish neutral capacity baselines so these tests isolate the
	# production behaviors they are intended to verify.
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

	var original_process_maintenance_capacity = infrastructure.get_state(
		"process_maintenance_capacity",
		{}
	).duplicate(true)

	# The production-system tests isolate production from monthly maintenance.
	# Establish a fully maintained baseline explicitly.
	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)

	# ============================================================
	# CREATE SYSTEM
	# ============================================================

	var production_process_system = (
		ProductionProcessSystem.new()
	)

	# ============================================================
	# HELPER STATE
	# ============================================================

	var processes: Dictionary = {}

	for process_id in original_processes.keys():

		var original_process = original_processes[process_id]

		if typeof(original_process) == TYPE_DICTIONARY:

			processes[process_id] = (
				original_process.duplicate(true)
			)

			processes[process_id]["active"] = false

	# ============================================================
	# TEST 1 — FULL INPUT AVAILABILITY
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var full_process_adoption = (
		original_process_adoption.duplicate(true)
	)

	full_process_adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		full_process_adoption
	)

	var full_stockpile = (
		original_stockpile.duplicate(true)
	)

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

	var steel = float(
		full_result.get(
			"steel",
			0.0
		)
	)

	var remaining_iron = float(
		full_result.get(
			"iron",
			0.0
		)
	)

	var remaining_coal = float(
		full_result.get(
			"coal",
			0.0
		)
	)

	var production_passed = (
		is_equal_approx(
			steel,
			10.0
		)
	)

	var iron_consumption_passed = (
		is_equal_approx(
			remaining_iron,
			0.0
		)
	)

	var coal_consumption_passed = (
		is_equal_approx(
			remaining_coal,
			0.0
		)
	)

	TestLogger.write_line(
		"Steel production: "
		+ (
			"PASS"
			if production_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(steel)
	)

	TestLogger.write_line(
		"Iron consumption: "
		+ (
			"PASS"
			if iron_consumption_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(remaining_iron)
	)

	TestLogger.write_line(
		"Coal consumption: "
		+ (
			"PASS"
			if coal_consumption_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(remaining_coal)
	)

	# ============================================================
	# TEST 2 — PROCESS ADOPTION SCALING
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var half_process_adoption = (
		original_process_adoption.duplicate(true)
	)

	half_process_adoption["steel_basic"] = 0.5

	industry.set_state(
		"process_adoption",
		half_process_adoption
	)

	var adoption_stockpile = (
		original_stockpile.duplicate(true)
	)

	adoption_stockpile["iron"] = 20.0
	adoption_stockpile["coal"] = 10.0
	adoption_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		adoption_stockpile
	)

	production_process_system.process_month(
		world
	)

	var adoption_result = resources.get_state(
		"stockpile",
		{}
	)

	var adoption_steel = float(
		adoption_result.get(
			"steel",
			0.0
		)
	)

	var adoption_iron = float(
		adoption_result.get(
			"iron",
			0.0
		)
	)

	var adoption_coal = float(
		adoption_result.get(
			"coal",
			0.0
		)
	)

	var adoption_production_passed = (
		is_equal_approx(
			adoption_steel,
			5.0
		)
	)

	var adoption_iron_passed = (
		is_equal_approx(
			adoption_iron,
			10.0
		)
	)

	var adoption_coal_passed = (
		is_equal_approx(
			adoption_coal,
			5.0
		)
	)

	TestLogger.write_line(
		"Process adoption production: "
		+ (
			"PASS"
			if adoption_production_passed
			else "FAIL"
		)
		+ " | adoption=0.5 expected=5.0 actual="
		+ str(adoption_steel)
	)

	TestLogger.write_line(
		"Process adoption iron consumption: "
		+ (
			"PASS"
			if adoption_iron_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(adoption_iron)
	)

	TestLogger.write_line(
		"Process adoption coal consumption: "
		+ (
			"PASS"
			if adoption_coal_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(adoption_coal)
	)

	# ============================================================
	# TEST 3 — INPUT BOTTLENECK
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var bottleneck_process_adoption = (
		original_process_adoption.duplicate(true)
	)

	bottleneck_process_adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		bottleneck_process_adoption
	)

	var bottleneck_stockpile = (
		original_stockpile.duplicate(true)
	)

	bottleneck_stockpile["iron"] = 10.0
	bottleneck_stockpile["coal"] = 10.0
	bottleneck_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		bottleneck_stockpile
	)

	production_process_system.process_month(
		world
	)

	var bottleneck_result = resources.get_state(
		"stockpile",
		{}
	)

	var bottleneck_steel = float(
		bottleneck_result.get(
			"steel",
			0.0
		)
	)

	var bottleneck_iron = float(
		bottleneck_result.get(
			"iron",
			0.0
		)
	)

	var bottleneck_coal = float(
		bottleneck_result.get(
			"coal",
			0.0
		)
	)

	var bottleneck_production_passed = (
		is_equal_approx(
			bottleneck_steel,
			5.0
		)
	)

	var bottleneck_iron_passed = (
		is_equal_approx(
			bottleneck_iron,
			0.0
		)
	)

	var bottleneck_coal_passed = (
		is_equal_approx(
			bottleneck_coal,
			5.0
		)
	)

	TestLogger.write_line(
		"Input bottleneck production: "
		+ (
			"PASS"
			if bottleneck_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(bottleneck_steel)
	)

	TestLogger.write_line(
		"Input bottleneck iron consumption: "
		+ (
			"PASS"
			if bottleneck_iron_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(bottleneck_iron)
	)

	TestLogger.write_line(
		"Input bottleneck coal consumption: "
		+ (
			"PASS"
			if bottleneck_coal_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(bottleneck_coal)
	)

	# ============================================================
	# TEST 4 — PROCESS EFFICIENCY
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 0.5
	}

	industry.set_state(
		"processes",
		processes
	)

	var efficiency_stockpile = (
		original_stockpile.duplicate(true)
	)

	efficiency_stockpile["iron"] = 20.0
	efficiency_stockpile["coal"] = 10.0
	efficiency_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		efficiency_stockpile
	)

	production_process_system.process_month(
		world
	)

	var efficiency_result = resources.get_state(
		"stockpile",
		{}
	)

	var efficiency_steel = float(
		efficiency_result.get(
			"steel",
			0.0
		)
	)

	var efficiency_iron = float(
		efficiency_result.get(
			"iron",
			0.0
		)
	)

	var efficiency_coal = float(
		efficiency_result.get(
			"coal",
			0.0
		)
	)

	var efficiency_production_passed = (
		is_equal_approx(
			efficiency_steel,
			5.0
		)
	)

	var efficiency_iron_passed = (
		is_equal_approx(
			efficiency_iron,
			10.0
		)
	)

	var efficiency_coal_passed = (
		is_equal_approx(
			efficiency_coal,
			5.0
		)
	)

	TestLogger.write_line(
		"Efficiency production: "
		+ (
			"PASS"
			if efficiency_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(efficiency_steel)
	)

	TestLogger.write_line(
		"Efficiency iron consumption: "
		+ (
			"PASS"
			if efficiency_iron_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(efficiency_iron)
	)

	TestLogger.write_line(
		"Efficiency coal consumption: "
		+ (
			"PASS"
			if efficiency_coal_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(efficiency_coal)
	)

	# ============================================================
	# TEST 5 — CATALOG EFFICIENCY
	# ============================================================

	var original_catalog_definition: Dictionary = (
		production_process_system.catalog.get_process(
			"steel_basic"
		)
	)

	var modified_catalog_definition: Dictionary = (
		original_catalog_definition.duplicate(true)
	)

	modified_catalog_definition["efficiency"] = 0.5

	production_process_system.catalog.processes[
		"steel_basic"
	] = modified_catalog_definition

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var catalog_efficiency_stockpile = (
		original_stockpile.duplicate(true)
	)

	catalog_efficiency_stockpile["iron"] = 20.0
	catalog_efficiency_stockpile["coal"] = 10.0
	catalog_efficiency_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		catalog_efficiency_stockpile
	)

	production_process_system.process_month(
		world
	)

	var catalog_efficiency_result = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var catalog_efficiency_steel = float(
		catalog_efficiency_result.get(
			"steel",
			0.0
		)
	)

	var catalog_efficiency_iron = float(
		catalog_efficiency_result.get(
			"iron",
			0.0
		)
	)

	var catalog_efficiency_coal = float(
		catalog_efficiency_result.get(
			"coal",
			0.0
		)
	)

	var catalog_efficiency_production_passed = (
		is_equal_approx(
			catalog_efficiency_steel,
			5.0
		)
	)

	var catalog_efficiency_iron_passed = (
		is_equal_approx(
			catalog_efficiency_iron,
			10.0
		)
	)

	var catalog_efficiency_coal_passed = (
		is_equal_approx(
			catalog_efficiency_coal,
			5.0
		)
	)

	TestLogger.write_line(
		"Catalog efficiency production: "
		+ (
			"PASS"
			if catalog_efficiency_production_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(catalog_efficiency_steel)
	)

	TestLogger.write_line(
		"Catalog efficiency iron consumption: "
		+ (
			"PASS"
			if catalog_efficiency_iron_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(catalog_efficiency_iron)
	)

	TestLogger.write_line(
		"Catalog efficiency coal consumption: "
		+ (
			"PASS"
			if catalog_efficiency_coal_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(catalog_efficiency_coal)
	)

	production_process_system.catalog.processes[
		"steel_basic"
	] = original_catalog_definition

	# ============================================================
	# TEST 6 — INFRASTRUCTURE CAPACITY SCALING
	# ============================================================

	var infrastructure_catalog_definition: Dictionary = (
		original_catalog_definition.duplicate(true)
	)

	infrastructure_catalog_definition["infrastructure_usage"] = {
		"steel_mill": 1.0
	}

	production_process_system.catalog.processes[
		"steel_basic"
	] = infrastructure_catalog_definition

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var infrastructure_process_adoption = (
		original_process_adoption.duplicate(true)
	)

	infrastructure_process_adoption["steel_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		infrastructure_process_adoption
	)

	var infrastructure_capacity = (
		original_infrastructure_capacity.duplicate(true)
	)

	infrastructure_capacity["steel_mill"] = 0.5

	resources.set_state(
		"infrastructure_capacity",
		infrastructure_capacity
	)

	var infrastructure_stockpile = (
		original_stockpile.duplicate(true)
	)

	infrastructure_stockpile["iron"] = 20.0
	infrastructure_stockpile["coal"] = 10.0
	infrastructure_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		infrastructure_stockpile
	)

	production_process_system.process_month(
		world
	)

	var infrastructure_result = resources.get_state(
		"stockpile",
		{}
	)

	var infrastructure_steel = float(
		infrastructure_result.get(
			"steel",
			0.0
		)
	)

	var infrastructure_iron = float(
		infrastructure_result.get(
			"iron",
			0.0
		)
	)

	var infrastructure_coal = float(
		infrastructure_result.get(
			"coal",
			0.0
		)
	)

	var infrastructure_production_passed = (
		is_equal_approx(
			infrastructure_steel,
			5.0
		)
	)

	var infrastructure_iron_passed = (
		is_equal_approx(
			infrastructure_iron,
			10.0
		)
	)

	var infrastructure_coal_passed = (
		is_equal_approx(
			infrastructure_coal,
			5.0
		)
	)

	TestLogger.write_line(
		"Infrastructure capacity production: "
		+ (
			"PASS"
			if infrastructure_production_passed
			else "FAIL"
		)
		+ " | infrastructure=0.5 expected=5.0 actual="
		+ str(infrastructure_steel)
	)

	TestLogger.write_line(
		"Infrastructure capacity iron consumption: "
		+ (
			"PASS"
			if infrastructure_iron_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(infrastructure_iron)
	)

	TestLogger.write_line(
		"Infrastructure capacity coal consumption: "
		+ (
			"PASS"
			if infrastructure_coal_passed
			else "FAIL"
		)
		+ " | expected=5.0 actual="
		+ str(infrastructure_coal)
	)

	production_process_system.catalog.processes[
		"steel_basic"
	] = original_catalog_definition

	# ============================================================
	# TEST 7 — INACTIVE PROCESS
	# ============================================================

	processes["steel_basic"] = {
		"active": false,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var inactive_stockpile = (
		original_stockpile.duplicate(true)
	)

	inactive_stockpile["iron"] = 20.0
	inactive_stockpile["coal"] = 10.0
	inactive_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		inactive_stockpile
	)

	production_process_system.process_month(
		world
	)

	var inactive_result = resources.get_state(
		"stockpile",
		{}
	)

	var inactive_steel = float(
		inactive_result.get(
			"steel",
			0.0
		)
	)

	var inactive_iron = float(
		inactive_result.get(
			"iron",
			0.0
		)
	)

	var inactive_coal = float(
		inactive_result.get(
			"coal",
			0.0
		)
	)

	var inactive_production_passed = (
		is_equal_approx(
			inactive_steel,
			0.0
		)
	)

	var inactive_iron_passed = (
		is_equal_approx(
			inactive_iron,
			20.0
		)
	)

	var inactive_coal_passed = (
		is_equal_approx(
			inactive_coal,
			10.0
		)
	)

	TestLogger.write_line(
		"Inactive process production: "
		+ (
			"PASS"
			if inactive_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(inactive_steel)
	)

	TestLogger.write_line(
		"Inactive process iron unchanged: "
		+ (
			"PASS"
			if inactive_iron_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(inactive_iron)
	)

	TestLogger.write_line(
		"Inactive process coal unchanged: "
		+ (
			"PASS"
			if inactive_coal_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(inactive_coal)
	)

	# ============================================================
	# TEST 8 — ZERO EFFICIENCY
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 0.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var zero_efficiency_stockpile = (
		original_stockpile.duplicate(true)
	)

	zero_efficiency_stockpile["iron"] = 20.0
	zero_efficiency_stockpile["coal"] = 10.0
	zero_efficiency_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		zero_efficiency_stockpile
	)

	production_process_system.process_month(
		world
	)

	var zero_efficiency_result = resources.get_state(
		"stockpile",
		{}
	)

	var zero_efficiency_steel = float(
		zero_efficiency_result.get(
			"steel",
			0.0
		)
	)

	var zero_efficiency_iron = float(
		zero_efficiency_result.get(
			"iron",
			0.0
		)
	)

	var zero_efficiency_coal = float(
		zero_efficiency_result.get(
			"coal",
			0.0
		)
	)

	var zero_efficiency_production_passed = (
		is_equal_approx(
			zero_efficiency_steel,
			0.0
		)
	)

	var zero_efficiency_iron_passed = (
		is_equal_approx(
			zero_efficiency_iron,
			20.0
		)
	)

	var zero_efficiency_coal_passed = (
		is_equal_approx(
			zero_efficiency_coal,
			10.0
		)
	)

	TestLogger.write_line(
		"Zero efficiency production: "
		+ (
			"PASS"
			if zero_efficiency_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(zero_efficiency_steel)
	)

	TestLogger.write_line(
		"Zero efficiency iron unchanged: "
		+ (
			"PASS"
			if zero_efficiency_iron_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(zero_efficiency_iron)
	)

	TestLogger.write_line(
		"Zero efficiency coal unchanged: "
		+ (
			"PASS"
			if zero_efficiency_coal_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(zero_efficiency_coal)
	)

	# ============================================================
	# TEST 9 — NEGATIVE CAPACITY
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": -10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var negative_capacity_stockpile = (
		original_stockpile.duplicate(true)
	)

	negative_capacity_stockpile["iron"] = 20.0
	negative_capacity_stockpile["coal"] = 10.0
	negative_capacity_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		negative_capacity_stockpile
	)

	production_process_system.process_month(
		world
	)

	var negative_capacity_result = resources.get_state(
		"stockpile",
		{}
	)

	var negative_capacity_steel = float(
		negative_capacity_result.get(
			"steel",
			0.0
		)
	)

	var negative_capacity_iron = float(
		negative_capacity_result.get(
			"iron",
			0.0
		)
	)

	var negative_capacity_coal = float(
		negative_capacity_result.get(
			"coal",
			0.0
		)
	)

	var negative_capacity_production_passed = (
		is_equal_approx(
			negative_capacity_steel,
			0.0
		)
	)

	var negative_capacity_iron_passed = (
		is_equal_approx(
			negative_capacity_iron,
			20.0
		)
	)

	var negative_capacity_coal_passed = (
		is_equal_approx(
			negative_capacity_coal,
			10.0
		)
	)

	TestLogger.write_line(
		"Negative capacity production: "
		+ (
			"PASS"
			if negative_capacity_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(negative_capacity_steel)
	)

	TestLogger.write_line(
		"Negative capacity iron unchanged: "
		+ (
			"PASS"
			if negative_capacity_iron_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(negative_capacity_iron)
	)

	TestLogger.write_line(
		"Negative capacity coal unchanged: "
		+ (
			"PASS"
			if negative_capacity_coal_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(negative_capacity_coal)
	)

	# ============================================================
	# TEST 10 — MISSING INPUT RESOURCE
	# ============================================================

	processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var missing_input_stockpile = (
		original_stockpile.duplicate(true)
	)

	missing_input_stockpile["iron"] = 20.0
	missing_input_stockpile["coal"] = 0.0
	missing_input_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		missing_input_stockpile
	)

	production_process_system.process_month(
		world
	)

	var missing_input_result = resources.get_state(
		"stockpile",
		{}
	)

	var missing_input_steel = float(
		missing_input_result.get(
			"steel",
			0.0
		)
	)

	var missing_input_iron = float(
		missing_input_result.get(
			"iron",
			0.0
		)
	)

	var missing_input_coal = float(
		missing_input_result.get(
			"coal",
			0.0
		)
	)

	var missing_input_production_passed = (
		is_equal_approx(
			missing_input_steel,
			0.0
		)
	)

	var missing_input_iron_passed = (
		is_equal_approx(
			missing_input_iron,
			20.0
		)
	)

	var missing_input_coal_passed = (
		is_equal_approx(
			missing_input_coal,
			0.0
		)
	)

	TestLogger.write_line(
		"Missing input production: "
		+ (
			"PASS"
			if missing_input_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(missing_input_steel)
	)

	TestLogger.write_line(
		"Missing input iron unchanged: "
		+ (
			"PASS"
			if missing_input_iron_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(missing_input_iron)
	)

	TestLogger.write_line(
		"Missing input coal unchanged: "
		+ (
			"PASS"
			if missing_input_coal_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(missing_input_coal)
	)

	# ============================================================
	# TEST 11 — UNKNOWN PROCESS
	# ============================================================

	processes["steel_basic"] = {
		"active": false,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	processes["unknown_process"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		processes
	)

	var unknown_process_stockpile = (
		original_stockpile.duplicate(true)
	)

	unknown_process_stockpile["iron"] = 20.0
	unknown_process_stockpile["coal"] = 10.0
	unknown_process_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		unknown_process_stockpile
	)

	production_process_system.process_month(
		world
	)

	var unknown_process_result = resources.get_state(
		"stockpile",
		{}
	)

	var unknown_process_steel = float(
		unknown_process_result.get(
			"steel",
			0.0
		)
	)

	var unknown_process_iron = float(
		unknown_process_result.get(
			"iron",
			0.0
		)
	)

	var unknown_process_coal = float(
		unknown_process_result.get(
			"coal",
			0.0
		)
	)

	var unknown_process_production_passed = (
		is_equal_approx(
			unknown_process_steel,
			0.0
		)
	)

	var unknown_process_iron_passed = (
		is_equal_approx(
			unknown_process_iron,
			20.0
		)
	)

	var unknown_process_coal_passed = (
		is_equal_approx(
			unknown_process_coal,
			10.0
		)
	)

	TestLogger.write_line(
		"Unknown process production: "
		+ (
			"PASS"
			if unknown_process_production_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(unknown_process_steel)
	)

	TestLogger.write_line(
		"Unknown process iron unchanged: "
		+ (
			"PASS"
			if unknown_process_iron_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(unknown_process_iron)
	)

	TestLogger.write_line(
		"Unknown process coal unchanged: "
		+ (
			"PASS"
			if unknown_process_coal_passed
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(unknown_process_coal)
	)

	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

	resources.set_state(
		"stockpile",
		original_stockpile
	)

	resources.set_state(
		"infrastructure_capacity",
		original_infrastructure_capacity
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
		original_process_maintenance_capacity
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

	# ============================================================
	# FINAL RESULT
	# ============================================================

	var production_execution_passed = (
		production_passed
		and adoption_production_passed
		and efficiency_production_passed
		and catalog_efficiency_production_passed
	)

	var input_consumption_all_passed = (
		iron_consumption_passed
		and coal_consumption_passed
		and adoption_iron_passed
		and adoption_coal_passed
		and efficiency_iron_passed
		and efficiency_coal_passed
		and catalog_efficiency_iron_passed
		and catalog_efficiency_coal_passed
	)

	var input_bottleneck_all_passed = (
		bottleneck_production_passed
		and bottleneck_iron_passed
		and bottleneck_coal_passed
	)

	var inactive_process_all_passed = (
		inactive_production_passed
		and inactive_iron_passed
		and inactive_coal_passed
	)

	var zero_efficiency_all_passed = (
		zero_efficiency_production_passed
		and zero_efficiency_iron_passed
		and zero_efficiency_coal_passed
	)

	var negative_capacity_all_passed = (
		negative_capacity_production_passed
		and negative_capacity_iron_passed
		and negative_capacity_coal_passed
	)

	var missing_input_all_passed = (
		missing_input_production_passed
		and missing_input_iron_passed
		and missing_input_coal_passed
	)

	var unknown_process_all_passed = (
		unknown_process_production_passed
		and unknown_process_iron_passed
		and unknown_process_coal_passed
	)

	var infrastructure_capacity_all_passed = (
		infrastructure_production_passed
		and infrastructure_iron_passed
		and infrastructure_coal_passed
	)

	var passed = (
		production_execution_passed
		and input_consumption_all_passed
		and input_bottleneck_all_passed
		and infrastructure_capacity_all_passed
		and inactive_process_all_passed
		and zero_efficiency_all_passed
		and negative_capacity_all_passed
		and missing_input_all_passed
		and unknown_process_all_passed
	)

	TestLogger.section(
		"PRODUCTION PROCESS SYSTEM TEST RESULT"
	)

	TestLogger.write_line(
		"Production execution: "
		+ (
			"PASS"
			if production_execution_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Input consumption: "
		+ (
			"PASS"
			if input_consumption_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Input bottleneck: "
		+ (
			"PASS"
			if input_bottleneck_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Catalog efficiency: "
		+ (
			"PASS"
			if catalog_efficiency_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Process adoption: "
		+ (
			"PASS"
			if adoption_production_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Infrastructure capacity: "
		+ (
			"PASS"
			if infrastructure_capacity_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Inactive process: "
		+ (
			"PASS"
			if inactive_process_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Zero efficiency: "
		+ (
			"PASS"
			if zero_efficiency_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Negative capacity: "
		+ (
			"PASS"
			if negative_capacity_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Missing input resource: "
		+ (
			"PASS"
			if missing_input_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Unknown process: "
		+ (
			"PASS"
			if unknown_process_all_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"ProductionProcessSystem test passed: "
		+ str(passed)
	)

	return passed
