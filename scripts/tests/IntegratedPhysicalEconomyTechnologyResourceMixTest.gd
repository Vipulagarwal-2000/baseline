class_name IntegratedPhysicalEconomyTechnologyResourceMixTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — TECHNOLOGY TRANSITION -> RESOURCE MIX TEST"
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

	var original_allocation: Dictionary = (
		industry.get_state(
			"process_adoption_allocation",
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

	var original_catalog_old = null
	var original_catalog_new = null
	var catalog_had_old :float= production_process_system.catalog.processes.has(
		"step2_6_old_steel"
	)
	var catalog_had_new :float= production_process_system.catalog.processes.has(
		"step2_6_new_steel"
	)

	if catalog_had_old:
		original_catalog_old = production_process_system.catalog.processes[
			"step2_6_old_steel"
		].duplicate(true)

	if catalog_had_new:
		original_catalog_new = production_process_system.catalog.processes[
			"step2_6_new_steel"
		].duplicate(true)

	# Controlled old technology:
	# 1 steel requires 2 iron + 2 coal.
	var old_process_definition := {
		"inputs": {
			"iron": 2.0,
			"coal": 2.0
		},
		"outputs": {
			"steel": 1.0
		},
		"byproducts": {},
		"efficiency": 1.0,
		"production_stage": 20,
		"available_from": 1950,
		"technology_requirements": {},
		"capability_requirements": {},
		"infrastructure_requirements": {},
		"infrastructure_usage": {},
		"labor_requirement": 0.0,
		"labor_skill_requirement": {},
		"capital_requirement": 0.0,
		"energy_requirement": 0.0,
		"maintenance_requirement": {},
		"reliability": 1.0,
		"category": "manufacturing"
	}

	# Controlled new technology:
	# 1 steel requires 1 iron + 0.5 coal + 0.5 electricity.
	var new_process_definition := {
		"inputs": {
			"iron": 1.0,
			"coal": 0.5,
			"electricity": 0.5
		},
		"outputs": {
			"steel": 1.0
		},
		"byproducts": {},
		"efficiency": 1.0,
		"production_stage": 20,
		"available_from": 1950,
		"technology_requirements": {},
		"capability_requirements": {},
		"infrastructure_requirements": {},
		"infrastructure_usage": {},
		"labor_requirement": 0.0,
		"labor_skill_requirement": {},
		"capital_requirement": 0.0,
		"energy_requirement": 0.0,
		"maintenance_requirement": {},
		"reliability": 1.0,
		"category": "manufacturing"
	}

	production_process_system.catalog.processes[
		"step2_6_old_steel"
	] = old_process_definition.duplicate(true)

	production_process_system.catalog.processes[
		"step2_6_new_steel"
	] = new_process_definition.duplicate(true)

	# Isolate the entity to exactly two competing production processes.
	var isolated_processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process = original_processes[process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		isolated_processes[str(process_id)] = (
			original_process.duplicate(true)
		)
		isolated_processes[str(process_id)]["active"] = false

	isolated_processes["step2_6_old_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	isolated_processes["step2_6_new_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)

	# Neutralize unrelated physical-capacity constraints.
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
		{}
	)

	var all_passed := true
	var previous_coal_demand := 1.0e30
	var previous_electricity_demand := -1.0e30

	# Four-month linear transition:
	# old process 1.00 -> 0.00
	# new process 0.00 -> 1.00
	for month in range(0, 5):
		var old_adoption := IndustryComponent.calculate_transition_adoption(
			1.0,
			0.0,
			month,
			4
		)

		var new_adoption := IndustryComponent.calculate_transition_adoption(
			0.0,
			1.0,
			month,
			4
		)

		var adoption := {
			"step2_6_old_steel": old_adoption,
			"step2_6_new_steel": new_adoption
		}

		industry.set_state(
			"process_adoption",
			adoption
		)
		industry.set_state(
			"process_adoption_allocation",
			adoption.duplicate(true)
		)

		# Reset inputs each month so the test measures the technology mix,
		# not depletion from the preceding production run.
		var month_stockpile: Dictionary = (
			original_stockpile.duplicate(true)
		)
		month_stockpile["iron"] = 100.0
		month_stockpile["coal"] = 100.0
		month_stockpile["electricity"] = 100.0
		month_stockpile["steel"] = 0.0

		resources.set_state(
			"stockpile",
			month_stockpile
		)

		production_process_system.process_month(
			world
		)

		var demand: Dictionary = resources.get_state(
			"production_process_demand",
			{}
		)

		var iron_demand := float(
			demand.get("iron", 0.0)
		)
		var coal_demand := float(
			demand.get("coal", 0.0)
		)
		var electricity_demand := float(
			demand.get("electricity", 0.0)
		)

		# Both processes have capacity 10 and efficiency 1.0, so total
		# steel output stays at 10 while the input mix changes.
		var expected_iron := (
			(10.0 * old_adoption * 2.0)
			+ (10.0 * new_adoption * 1.0)
		)
		var expected_coal := (
			(10.0 * old_adoption * 2.0)
			+ (10.0 * new_adoption * 0.5)
		)
		var expected_electricity := (
			10.0 * new_adoption * 0.5
		)

		var old_outcome: Dictionary = industry.get_production_outcome(
			"step2_6_old_steel"
		)
		var new_outcome: Dictionary = industry.get_production_outcome(
			"step2_6_new_steel"
		)

		var total_production := (
			float(old_outcome.get("actual_production", 0.0))
			+ float(new_outcome.get("actual_production", 0.0))
		)

		var month_passed := (
			is_equal_approx(old_adoption + new_adoption, 1.0)
			and is_equal_approx(iron_demand, expected_iron)
			and is_equal_approx(coal_demand, expected_coal)
			and is_equal_approx(electricity_demand, expected_electricity)
			and is_equal_approx(total_production, 10.0)
			and coal_demand <= previous_coal_demand + 0.000001
			and electricity_demand + 0.000001 >= previous_electricity_demand
		)

		TestLogger.write_line(
			"Technology transition month "
			+ str(month)
			+ " resource mix: "
			+ ("PASS" if month_passed else "FAIL")
			+ " | old_adoption="
			+ str(old_adoption)
			+ " new_adoption="
			+ str(new_adoption)
			+ " iron="
			+ str(iron_demand)
			+ " coal="
			+ str(coal_demand)
			+ " electricity="
			+ str(electricity_demand)
			+ " production="
			+ str(total_production)
		)

		if not month_passed:
			all_passed = false

		previous_coal_demand = coal_demand
		previous_electricity_demand = electricity_demand

	# Explicit endpoints make the intended transformation easy to diagnose.
	var endpoint_demand_start: Dictionary = {
		"iron": 20.0,
		"coal": 20.0,
		"electricity": 0.0
	}
	var endpoint_demand_end: Dictionary = {
		"iron": 10.0,
		"coal": 5.0,
		"electricity": 5.0
	}

	# Re-run the endpoint adoption states to assert the complete before/after mix.
	industry.set_state(
		"process_adoption",
		{
			"step2_6_old_steel": 1.0,
			"step2_6_new_steel": 0.0
		}
	)
	var start_stockpile: Dictionary = original_stockpile.duplicate(true)
	start_stockpile["iron"] = 100.0
	start_stockpile["coal"] = 100.0
	start_stockpile["electricity"] = 100.0
	start_stockpile["steel"] = 0.0
	resources.set_state("stockpile", start_stockpile)
	production_process_system.process_month(world)
	var start_demand: Dictionary = resources.get_state(
		"production_process_demand",
		{}
	)

	industry.set_state(
		"process_adoption",
		{
			"step2_6_old_steel": 0.0,
			"step2_6_new_steel": 1.0
		}
	)
	var end_stockpile: Dictionary = original_stockpile.duplicate(true)
	end_stockpile["iron"] = 100.0
	end_stockpile["coal"] = 100.0
	end_stockpile["electricity"] = 100.0
	end_stockpile["steel"] = 0.0
	resources.set_state("stockpile", end_stockpile)
	production_process_system.process_month(world)
	var end_demand: Dictionary = resources.get_state(
		"production_process_demand",
		{}
	)

	var endpoint_passed := (
		is_equal_approx(float(start_demand.get("iron", 0.0)), endpoint_demand_start["iron"])
		and is_equal_approx(float(start_demand.get("coal", 0.0)), endpoint_demand_start["coal"])
		and is_equal_approx(float(start_demand.get("electricity", 0.0)), endpoint_demand_start["electricity"])
		and is_equal_approx(float(end_demand.get("iron", 0.0)), endpoint_demand_end["iron"])
		and is_equal_approx(float(end_demand.get("coal", 0.0)), endpoint_demand_end["coal"])
		and is_equal_approx(float(end_demand.get("electricity", 0.0)), endpoint_demand_end["electricity"])
	)

	TestLogger.write_line(
		"Technology transition changes endpoint resource mix: "
		+ ("PASS" if endpoint_passed else "FAIL")
		+ " | start={"
		+ "iron=" + str(start_demand.get("iron", 0.0))
		+ ", coal=" + str(start_demand.get("coal", 0.0))
		+ ", electricity=" + str(start_demand.get("electricity", 0.0))
		+ "} end={"
		+ "iron=" + str(end_demand.get("iron", 0.0))
		+ ", coal=" + str(end_demand.get("coal", 0.0))
		+ ", electricity=" + str(end_demand.get("electricity", 0.0))
		+ "}"
	)

	if not endpoint_passed:
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
	industry.set_state(
		"process_adoption_allocation",
		original_allocation
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

	if catalog_had_old:
		production_process_system.catalog.processes[
			"step2_6_old_steel"
		] = original_catalog_old
	else:
		production_process_system.catalog.processes.erase(
			"step2_6_old_steel"
		)

	if catalog_had_new:
		production_process_system.catalog.processes[
			"step2_6_new_steel"
		] = original_catalog_new
	else:
		production_process_system.catalog.processes.erase(
			"step2_6_new_steel"
		)

	TestLogger.write_line(
		"Integrated Physical Economy — Technology Transition -> Resource Mix test passed: "
		+ ("true" if all_passed else "false")
	)

	return all_passed
