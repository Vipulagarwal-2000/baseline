class_name IntegratedPhysicalEconomyMultiMonthInteractionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — MULTI-MONTH INTERACTION TEST"
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
	var research = india.get_component("research")

	if (
		resources == null
		or industry == null
		or infrastructure == null
		or population == null
		or economy == null
	):
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

	var economy_system = simulation.get_system(
		"economy_system"
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

	if economy_system == null:
		TestLogger.write_line(
			"Registered EconomySystem available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Registered ResourceSystem available: PASS"
	)

	TestLogger.write_line(
		"Registered ProductionProcessSystem available: PASS"
	)

	TestLogger.write_line(
		"Registered EconomySystem available: PASS"
	)

	# Preserve the complete mutable component states touched by the test.
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_population_state: Dictionary = population.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_production_state: Dictionary = industry.get_state("production_state", {}).duplicate(true)
	var original_production_totals: Dictionary = industry.get_state("production_totals", {}).duplicate(true)
	var original_resource_efficiency: float = float(resources.get_state("resource_efficiency", 1.0))
	var original_technology_effects: Dictionary = {}
	if research != null:
		original_technology_effects = research.get_state("technology_effects", {}).duplicate(true)

	var original_old_process = null
	var original_new_process = null

	var catalog_had_old: bool = bool(
		production_process_system.catalog.processes.has(
			"step2_7_old_steel"
		)
	)

	var catalog_had_new: bool = bool(
		production_process_system.catalog.processes.has(
			"step2_7_new_steel"
		)
	)

	if catalog_had_old:
		original_old_process = (
			production_process_system.catalog.processes[
				"step2_7_old_steel"
			].duplicate(true)
		)

	if catalog_had_new:
		original_new_process = (
			production_process_system.catalog.processes[
				"step2_7_new_steel"
			].duplicate(true)
		)

	# Controlled old process:
	# 1 steel = 2 iron + 2 coal.
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

	# Controlled new process:
	# 1 steel = 1 iron + 0.5 coal + 0.5 electricity.
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
		"step2_7_old_steel"
	] = old_process_definition.duplicate(true)

	production_process_system.catalog.processes[
		"step2_7_new_steel"
	] = new_process_definition.duplicate(true)

	# Isolate the industrial structure to the two competing processes.
	var isolated_processes: Dictionary = {}

	for process_id in original_industry_state.get("processes", {}).keys():
		var original_process = original_industry_state[
			"processes"
		][process_id]

		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		isolated_processes[str(process_id)] = (
			original_process.duplicate(true)
		)
		isolated_processes[str(process_id)]["active"] = false

	isolated_processes["step2_7_old_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	isolated_processes["step2_7_new_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)

	# Step 2.7 isolation: EconomySystem reads the latest persisted
	# production outcomes, not only the current process definitions.
	# Clear inherited outcome state so earlier tests cannot contribute
	# capacity or output to this scenario.
	industry.set_state(
		"production_state",
		{}
	)
	industry.set_state(
		"production_totals",
		{}
	)

	# Neutralize non-resource production constraints.
	population.set_state(
		"effective_labor_capacity",
		1000.0
	)
	population.set_state(
		"effective_skilled_labor_capacity",
		1000.0
	)

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

	# Neutralize economic/resource efficiency modifiers so the only
	# changing economic driver is realized physical production.
	resources.set_state(
		"resource_efficiency",
		1.0
	)

	if research != null:
		research.set_state(
		"technology_effects",
		{
			"industrial_production_efficiency": 1.0
		}
		)

	# Start from clean process-feedback state.
	resources.set_state(
		"production_process_demand",
		{}
	)
	resources.set_state(
		"production_process_shortages",
		{}
	)
	resources.set_state(
		"production_process_shortage_ratio",
		{}
	)
	resources.set_state(
		"production_process_resource_availability",
		{}
	)

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

	# Continuous stockpile: do NOT reset it between months. ProductionProcessSystem
	# consumes the realized physical inputs, allowing the resource state produced
	# by one month to become the supply condition for the next month.
	var stockpile: Dictionary = (
		original_resource_state.get(
			"stockpile",
			{}
		).duplicate(true)
	)
	stockpile["iron"] = 100.0
	stockpile["coal"] = 60.0
	stockpile["electricity"] = 10.0
	stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		stockpile
	)

	economy.set_state(
		"gdp",
		1000.0
	)
	economy.set_state(
		"growth_rate",
		12.0
	)
	economy.set_state(
		"economic_efficiency",
		1.0
	)

	var all_passed := true

	# These values are the expected results of the existing system-order
	# semantics:
	# ResourceSystem resolves the previous month's gross process demand first;
	# ProductionProcessSystem then applies that availability signal and finally
	# enforces the live stockpile input guard while consuming the realized inputs.
	var expected_production := [
		10.0,
		10.0,
		10.0,
		9.0,
		3.857142857142857,
		1.8928571428571423
	]

	var expected_factors := [
		1.0,
		1.0,
		1.0,
		0.9,
		0.3857142857142857,
		0.18928571428571423
	]

	# EconomySystem reconstructs pre-resource physical capacity from the
	# persisted ProductionProcessSystem outcomes. The controlled scenario
	# has two 10-capacity processes whose adoption shares sum to 1.0, so
	# physical capacity remains 10.0 even when resource availability lowers
	# realized output.
	var expected_physical_capacity := [
		10.0,
		10.0,
		10.0,
		10.0,
		10.0,
		10.0
	]

	var expected_gdp := [
		1010.0,
		1020.1,
		1030.301,
		1039.573709,
		1043.5834933061426,
		1045.558847775615
	]

	var expected_coal_demand := [
		20.0,
		16.25,
		12.5,
		8.75,
		5.0,
		5.0
	]

	var expected_electricity_demand := [
		0.0,
		1.25,
		2.5,
		3.75,
		5.0,
		5.0
	]

	var expected_coal_availability := [
		1.0,
		1.0,
		1.0,
		0.9,
		0.3857142857142857,
		0.28928571428571426
	]

	var expected_electricity_availability := [
		1.0,
		1.0,
		1.0,
		1.0,
		0.7666666666666667,
		0.18928571428571428
	]

	for month in range(0, 6):

		var transition_month :int= min(month, 4)

		var old_adoption := IndustryComponent.calculate_transition_adoption(
			1.0,
			0.0,
			transition_month,
			4
		)

		var new_adoption := IndustryComponent.calculate_transition_adoption(
			0.0,
			1.0,
			transition_month,
			4
		)

		var adoption := {
			"step2_7_old_steel": old_adoption,
			"step2_7_new_steel": new_adoption
		}

		industry.set_state(
			"process_adoption",
			adoption
		)
		industry.set_state(
			"process_adoption_allocation",
			adoption.duplicate(true)
		)

		resource_system.process_month(world)

		var availability: Dictionary = resources.get_state(
			"production_process_resource_availability",
			{}
		)

		var coal_availability := float(
			availability.get("coal", 1.0)
		)
		var electricity_availability := float(
			availability.get("electricity", 1.0)
		)

		production_process_system.process_month(world)

		var demand: Dictionary = resources.get_state(
			"production_process_demand",
			{}
		)

		var coal_demand := float(
			demand.get("coal", 0.0)
		)
		var electricity_demand := float(
			demand.get("electricity", 0.0)
		)

		var old_outcome: Dictionary = industry.get_production_outcome(
			"step2_7_old_steel"
		)
		var new_outcome: Dictionary = industry.get_production_outcome(
			"step2_7_new_steel"
		)

		var total_production := (
			float(old_outcome.get("actual_production", 0.0))
			+ float(new_outcome.get("actual_production", 0.0))
		)

		economy_system.process_month(world)

		var production_factor := float(
			economy.get_state(
				"production_output_factor",
				1.0
			)
		)
		var physical_capacity := float(
			economy.get_state(
				"physical_production_capacity",
				0.0
			)
		)
		var gdp := float(
			economy.get_state(
				"gdp",
				0.0
			)
		)

		var month_passed := (
			is_equal_approx(
				old_adoption + new_adoption,
				1.0
			)
			and is_equal_approx(
				coal_availability,
				expected_coal_availability[month]
			)
			and is_equal_approx(
				electricity_availability,
				expected_electricity_availability[month]
			)
			and is_equal_approx(
				coal_demand,
				expected_coal_demand[month]
			)
			and is_equal_approx(
				electricity_demand,
				expected_electricity_demand[month]
			)
			and is_equal_approx(
				total_production,
				expected_production[month]
			)
			and is_equal_approx(
				production_factor,
				expected_factors[month]
			)
			and is_equal_approx(
				physical_capacity,
				expected_physical_capacity[month]
			)
			and is_equal_approx(
				gdp,
				expected_gdp[month]
			)
		)

		TestLogger.write_line(
			"Multi-month physical economy month "
			+ str(month)
			+ ": "
			+ ("PASS" if month_passed else "FAIL")
			+ " | old_adoption="
			+ str(old_adoption)
			+ " new_adoption="
			+ str(new_adoption)
			+ " coal_availability="
			+ str(coal_availability)
			+ " electricity_availability="
			+ str(electricity_availability)
			+ " coal_demand="
			+ str(coal_demand)
			+ " electricity_demand="
			+ str(electricity_demand)
			+ " production="
			+ str(total_production)
			+ " physical_capacity="
			+ str(physical_capacity)
			+ " output_factor="
			+ str(production_factor)
			+ " gdp="
			+ str(gdp)
		)

		if not month_passed:
			all_passed = false

	# Confirm that the limiting resource changes during the transition.
	# Month 3/4: coal is tighter than electricity.
	# Month 5: electricity is tighter than coal.
	var shortage_ratios: Dictionary = resources.get_state(
		"production_process_shortage_ratio",
		{}
	)

	var final_coal_shortage_ratio := float(
		shortage_ratios.get("coal", 0.0)
	)
	var final_electricity_shortage_ratio := float(
		shortage_ratios.get("electricity", 0.0)
	)

	var bottleneck_shift_passed := (
		final_electricity_shortage_ratio > final_coal_shortage_ratio
	)

	TestLogger.write_line(
		"Technology transition shifts the limiting resource to electricity: "
		+ ("PASS" if bottleneck_shift_passed else "FAIL")
		+ " | final_coal_shortage_ratio="
		+ str(final_coal_shortage_ratio)
		+ " final_electricity_shortage_ratio="
		+ str(final_electricity_shortage_ratio)
	)

	if not bottleneck_shift_passed:
		all_passed = false

	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

	resources.state = original_resource_state
	industry.state = original_industry_state
	infrastructure.state = original_infrastructure_state
	population.state = original_population_state
	economy.state = original_economy_state

	# Explicit restoration is kept here as documentation of the state
	# isolated by this test. The complete component-state restoration above
	# remains the authoritative cleanup operation.
	industry.set_state(
		"production_state",
		original_production_state
	)
	industry.set_state(
		"production_totals",
		original_production_totals
	)
	resources.set_state(
		"resource_efficiency",
		original_resource_efficiency
	)
	if research != null:
		research.set_state(
		"technology_effects",
		original_technology_effects
		)

	if catalog_had_old:
		production_process_system.catalog.processes[
			"step2_7_old_steel"
		] = original_old_process
	else:
		production_process_system.catalog.processes.erase(
			"step2_7_old_steel"
		)

	if catalog_had_new:
		production_process_system.catalog.processes[
			"step2_7_new_steel"
		] = original_new_process
	else:
		production_process_system.catalog.processes.erase(
			"step2_7_new_steel"
		)

	TestLogger.write_line(
		"Integrated Physical Economy — Multi-Month Interaction test passed: "
		+ ("true" if all_passed else "false")
	)

	return all_passed
