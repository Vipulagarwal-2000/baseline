class_name IntegratedPhysicalEconomyProductionResourceDemandTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — PRODUCTION -> RESOURCE DEMAND TEST"
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

	var production_process_system = simulation.get_system(
		"production_process_system"
	)

	if production_process_system == null:
		TestLogger.write_line(
			"Registered ProductionProcessSystem available: FAIL"
		)
		return false

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

	var original_process_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
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

	# Isolate the production process so this test measures only the
	# ProductionProcessSystem -> ResourceComponent demand connection.
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

	var all_passed := true

	# ============================================================
	# TEST 1 — FULL ADOPTION CREATES GROSS INPUT DEMAND
	# ============================================================

	var full_stockpile: Dictionary = (
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

	var full_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		)
	)

	var full_iron_demand := float(
		full_demand.get(
			"iron",
			0.0
		)
	)
	var full_coal_demand := float(
		full_demand.get(
			"coal",
			0.0
		)
	)

	var full_outcome: Dictionary = industry.get_production_outcome(
		"steel_basic"
	)
	var full_production := float(
		full_outcome.get(
			"actual_production",
			0.0
		)
	)

	var full_demand_pass := (
		is_equal_approx(full_iron_demand, 20.0)
		and is_equal_approx(full_coal_demand, 10.0)
		and is_equal_approx(full_production, 10.0)
	)

	TestLogger.write_line(
		"Full-adoption production creates gross resource demand: "
		+ ("PASS" if full_demand_pass else "FAIL")
		+ " | expected_iron=20.0 actual_iron="
		+ str(full_iron_demand)
		+ " expected_coal=10.0 actual_coal="
		+ str(full_coal_demand)
		+ " production=10.0 actual="
		+ str(full_production)
	)

	if not full_demand_pass:
		all_passed = false

	# ============================================================
	# TEST 2 — PROCESS ADOPTION CHANGES RESOURCE DEMAND
	# ============================================================

	isolated_adoption["steel_basic"] = 0.50
	industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	var half_stockpile: Dictionary = (
		original_stockpile.duplicate(true)
	)
	half_stockpile["iron"] = 20.0
	half_stockpile["coal"] = 10.0
	half_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		half_stockpile
	)

	production_process_system.process_month(
		world
	)

	var half_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		)
	)

	var half_iron_demand := float(
		half_demand.get(
			"iron",
			0.0
		)
	)
	var half_coal_demand := float(
		half_demand.get(
			"coal",
			0.0
		)
	)

	var half_outcome: Dictionary = industry.get_production_outcome(
		"steel_basic"
	)
	var half_production := float(
		half_outcome.get(
			"actual_production",
			0.0
		)
	)

	var half_demand_pass := (
		is_equal_approx(half_iron_demand, 10.0)
		and is_equal_approx(half_coal_demand, 5.0)
		and is_equal_approx(half_production, 5.0)
	)

	TestLogger.write_line(
		"50% process adoption reduces resource demand proportionally: "
		+ ("PASS" if half_demand_pass else "FAIL")
		+ " | expected_iron=10.0 actual_iron="
		+ str(half_iron_demand)
		+ " expected_coal=5.0 actual_coal="
		+ str(half_coal_demand)
		+ " production=5.0 actual="
		+ str(half_production)
	)

	if not half_demand_pass:
		all_passed = false

	# ============================================================
	# TEST 3 — GROSS DEMAND PERSISTS WHEN INPUTS ARE SCARCE
	# ============================================================

	isolated_adoption["steel_basic"] = 1.0
	industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	var shortage_stockpile: Dictionary = (
		original_stockpile.duplicate(true)
	)
	shortage_stockpile["iron"] = 5.0
	shortage_stockpile["coal"] = 10.0
	shortage_stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		shortage_stockpile
	)

	production_process_system.process_month(
		world
	)

	var shortage_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		)
	)

	var shortage_iron_demand := float(
		shortage_demand.get(
			"iron",
			0.0
		)
	)
	var shortage_coal_demand := float(
		shortage_demand.get(
			"coal",
			0.0
		)
	)

	var shortage_outcome: Dictionary = industry.get_production_outcome(
		"steel_basic"
	)
	var shortage_production := float(
		shortage_outcome.get(
			"actual_production",
			0.0
		)
	)

	var shortage_pass := (
		is_equal_approx(shortage_iron_demand, 20.0)
		and is_equal_approx(shortage_coal_demand, 10.0)
		and is_equal_approx(shortage_production, 2.5)
	)

	TestLogger.write_line(
		"Resource shortage constrains output while gross demand remains visible: "
		+ ("PASS" if shortage_pass else "FAIL")
		+ " | expected_iron=20.0 actual_iron="
		+ str(shortage_iron_demand)
		+ " expected_coal=10.0 actual_coal="
		+ str(shortage_coal_demand)
		+ " expected_production=2.5 actual="
		+ str(shortage_production)
	)

	if not shortage_pass:
		all_passed = false

	# ============================================================
	# TEST 4 — DEMAND STATE CLEARS WHEN PRODUCTION BECOMES INACTIVE
	# ============================================================

	isolated_processes["steel_basic"]["active"] = false
	industry.set_state(
		"processes",
		isolated_processes
	)

	resources.set_state(
		"stockpile",
		shortage_stockpile
	)

	production_process_system.process_month(
		world
	)

	var cleared_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		)
	)

	var cleared_demand_pass := cleared_demand.is_empty()

	TestLogger.write_line(
		"Inactive production clears stale resource demand: "
		+ ("PASS" if cleared_demand_pass else "FAIL")
		+ " | actual="
		+ str(cleared_demand)
	)

	if not cleared_demand_pass:
		all_passed = false

	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

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
		"production_process_demand",
		original_process_demand
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

	TestLogger.write_line(
		"Integrated Physical Economy — Production -> Resource Demand test passed: "
		+ str(all_passed)
	)

	return all_passed
