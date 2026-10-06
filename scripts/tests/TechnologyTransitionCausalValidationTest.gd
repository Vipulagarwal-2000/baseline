class_name Step19_4TechnologyTransitionCausalValidationTest
extends RefCounted


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func _set_period_state(
	industry,
	resources,
	infrastructure,
	economy,
	adoption: Dictionary,
	infrastructure_capacity: float,
	original_resource_state: Dictionary,
	original_economy_state: Dictionary
) -> void:
	industry.set_state(
		"process_adoption",
		adoption.duplicate(true)
	)
	industry.set_state(
		"process_adoption_allocation",
		adoption.duplicate(true)
	)
	industry.set_state("production_state", {})
	industry.set_state("production_totals", {})

	var stockpile: Dictionary = (
		original_resource_state.get(
			"stockpile",
			{}
		).duplicate(true)
	)
	stockpile["iron"] = 1000.0
	stockpile["coal"] = 1000.0
	stockpile["electricity"] = 1000.0
	stockpile["steel"] = 0.0

	resources.set_state(
		"stockpile",
		stockpile
	)
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
		"critical_production_allocation_ratio",
		{}
	)
	# Process-specific capacity is authoritative on InfrastructureComponent.
	# ResourceComponent.infrastructure_capacity remains only as the legacy
	# compatibility bridge for names that have no explicit process capacity.
	infrastructure.set_state(
		"process_infrastructure_capacity",
		{
			"modern_steelworks": infrastructure_capacity
		}
	)

	resources.set_state(
		"infrastructure_capacity",
		{}
	)

	# Keep GDP and derived physical-economy fields identical at the start of
	# each controlled period so comparisons isolate the technology fixture.
	economy.state = original_economy_state.duplicate(true)
	economy.set_state(
		"physical_production_output",
		0.0
	)
	economy.set_state(
		"physical_production_capacity",
		0.0
	)
	economy.set_state(
		"production_output_factor",
		0.0
	)


static func _run_period(
	world: WorldState,
	resource_system,
	production_process_system,
	economy_system,
	industry,
	resources,
	infrastructure,
	economy,
	adoption: Dictionary,
	infrastructure_capacity: float,
	original_resource_state: Dictionary,
	original_economy_state: Dictionary
) -> Dictionary:
	_set_period_state(
		industry,
		resources,
		infrastructure,
		economy,
		adoption,
		infrastructure_capacity,
		original_resource_state,
		original_economy_state
	)

	# Run the same registered monthly systems that own the live economy.
	resource_system.process_month(world)
	production_process_system.process_month(world)
	economy_system.process_month(world)

	var demand: Dictionary = resources.get_state(
		"production_process_demand",
		{}
	)

	var old_outcome: Dictionary = industry.get_production_outcome(
		"step19_4_old_steel"
	)
	var new_outcome: Dictionary = industry.get_production_outcome(
		"step19_4_new_steel"
	)

	var old_output: float = float(
		old_outcome.get(
			"actual_production",
			0.0
		)
	)
	var new_output: float = float(
		new_outcome.get(
			"actual_production",
			0.0
		)
	)

	return {
		"old_adoption": float(adoption.get("step19_4_old_steel", 0.0)),
		"new_adoption": float(adoption.get("step19_4_new_steel", 0.0)),
		"old_output": old_output,
		"new_output": new_output,
		"total_output": old_output + new_output,
		"iron_demand": float(demand.get("iron", 0.0)),
		"coal_demand": float(demand.get("coal", 0.0)),
		"electricity_demand": float(demand.get("electricity", 0.0)),
		"new_power_constraint_factor": float(
			new_outcome.get(
				"power_constraint_factor",
				1.0
			)
		),
		"new_operational_factor": float(
			new_outcome.get(
				"operational_factor",
				1.0
			)
		),
		"new_operational_constraint_factor": float(
			new_outcome.get(
				"operational_constraint_factor",
				1.0
			)
		),
		"new_constraint_sources": (
			new_outcome.get(
				"constraint_sources",
				[]
			)
		),
		"new_status": str(
			new_outcome.get(
				"status",
				""
			)
		),
		"physical_output": float(
			economy.get_state(
				"physical_production_output",
				0.0
			)
		),
		"physical_capacity": float(
			economy.get_state(
				"physical_production_capacity",
				0.0
			)
		),
		"output_factor": float(
			economy.get_state(
				"production_output_factor",
				0.0
			)
		),
		"gdp": float(
			economy.get_state(
				"gdp",
				0.0
			)
		)
	}


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 19.4 — TECHNOLOGY TRANSITION CAUSAL VALIDATION"
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

	var resource_system = simulation.get_system(
		"resource_system"
	)
	var production_process_system = simulation.get_system(
		"production_process_system"
	)
	var economy_system = simulation.get_system(
		"economy_system"
	)

	var required_available: bool = (
		resources != null
		and industry != null
		and infrastructure != null
		and economy != null
		and resource_system != null
		and production_process_system != null
		and economy_system != null
	)

	TestLogger.write_line(
		"Required causal-chain components and systems available: "
		+ _pass_fail(required_available)
	)

	if not required_available:
		return false

	var original_date = world.get("date")
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_population_state: Dictionary = {}
	if population != null:
		original_population_state = population.state.duplicate(true)

	var catalog_had_old: bool = bool(
		production_process_system.catalog.processes.has(
			"step19_4_old_steel"
		)
	)
	var catalog_had_new: bool = bool(
		production_process_system.catalog.processes.has(
			"step19_4_new_steel"
		)
	)

	var original_catalog_old: Dictionary = {}
	var original_catalog_new: Dictionary = {}

	if catalog_had_old:
		original_catalog_old = production_process_system.catalog.processes[
			"step19_4_old_steel"
		].duplicate(true)
	if catalog_had_new:
		original_catalog_new = production_process_system.catalog.processes[
			"step19_4_new_steel"
		].duplicate(true)

	# Controlled old technology:
	# 1 steel = 2 iron + 2 coal.
	# It uses one unit of the existing industrial infrastructure capacity.
	var old_process_definition: Dictionary = {
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
		"infrastructure_usage": {
			"modern_steelworks": 1.0
		},
		"labor_requirement": 0.0,
		"labor_skill_requirement": {},
		"capital_requirement": 0.0,
		"energy_requirement": {},
		"power_requirement": 0.0,
		"maintenance_requirement": {},
		"reliability": 1.0,
		"category": "manufacturing"
	}

	# Controlled new technology:
	# 1 steel = 1 iron + 0.5 coal + 0.5 electricity.
	# It requires twice the installed industrial-capacity usage of the old
	# process, intentionally creating a new infrastructure bottleneck when
	# the transition reaches the new technology.
	var new_process_definition: Dictionary = {
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
		"infrastructure_usage": {
			"modern_steelworks": 2.0
		},
		"labor_requirement": 0.0,
		"labor_skill_requirement": {},
		"capital_requirement": 0.0,
		"energy_requirement": {},
		"power_requirement": 0.0,
		"maintenance_requirement": {},
		"reliability": 1.0,
		"category": "manufacturing"
	}

	production_process_system.catalog.processes[
		"step19_4_old_steel"
	] = old_process_definition.duplicate(true)
	production_process_system.catalog.processes[
		"step19_4_new_steel"
	] = new_process_definition.duplicate(true)

	var isolated_processes: Dictionary = {}
	for raw_process_id in original_industry_state.get("processes", {}).keys():
		var original_process = original_industry_state["processes"][raw_process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue
		isolated_processes[str(raw_process_id)] = original_process.duplicate(true)
		isolated_processes[str(raw_process_id)]["active"] = false

	isolated_processes["step19_4_old_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}
	isolated_processes["step19_4_new_steel"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)

	if population != null:
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

	var all_passed: bool = true
	var previous_coal_demand: float = 1.0e30
	var previous_electricity_demand: float = -1.0e30
	var previous_total_output: float = 1.0e30
	var first_result: Dictionary = {}
	var final_result: Dictionary = {}

	# Four-month controlled transition:
	# old 1.00 -> 0.00
	# new 0.00 -> 1.00
	for month in range(0, 5):
		var old_adoption: float = IndustryComponent.calculate_transition_adoption(
			1.0,
			0.0,
			month,
			4
		)
		var new_adoption: float = IndustryComponent.calculate_transition_adoption(
			0.0,
			1.0,
			month,
			4
		)

		var adoption: Dictionary = {
			"step19_4_old_steel": old_adoption,
			"step19_4_new_steel": new_adoption
		}

		var result: Dictionary = _run_period(
			world,
			resource_system,
			production_process_system,
			economy_system,
			industry,
			resources,
			infrastructure,
			economy,
			adoption,
			1.0,
			original_resource_state,
			original_economy_state
		)

		if month == 0:
			first_result = result.duplicate(true)
		if month == 4:
			final_result = result.duplicate(true)

		# Infrastructure usage is an upstream operational-capacity
		# constraint in ProductionProcessSystem. The new technology
		# therefore exposes only 50% of its nominal capacity while the
		# available modern_steelworks capacity remains at 1.0.
		var effective_new_capacity: float = 10.0 * new_adoption * 0.5
		var expected_iron: float = (
			10.0 * old_adoption * 2.0
			+ effective_new_capacity * 1.0
		)
		var expected_coal: float = (
			10.0 * old_adoption * 2.0
			+ effective_new_capacity * 0.5
		)
		var expected_electricity: float = (
			effective_new_capacity * 0.5
		)

		var expected_new_output: float = effective_new_capacity
		var expected_old_output: float = 10.0 * old_adoption
		var expected_total_output: float = expected_old_output + expected_new_output

		var mix_passed: bool = (
			is_equal_approx(old_adoption + new_adoption, 1.0)
			and is_equal_approx(result["iron_demand"], expected_iron)
			and is_equal_approx(result["coal_demand"], expected_coal)
			and is_equal_approx(result["electricity_demand"], expected_electricity)
			and is_equal_approx(result["old_output"], expected_old_output)
			and is_equal_approx(result["new_output"], expected_new_output)
			and is_equal_approx(result["total_output"], expected_total_output)
			and result["coal_demand"] <= previous_coal_demand + 0.000001
			and result["electricity_demand"] + 0.000001 >= previous_electricity_demand
		)

		TestLogger.write_line(
			"Technology transition month "
			+ str(month)
			+ " preserves adoption/resource/production causality: "
			+ _pass_fail(mix_passed)
			+ " | old_adoption=" + str(old_adoption)
			+ " new_adoption=" + str(new_adoption)
			+ " iron=" + str(result["iron_demand"])
			+ " coal=" + str(result["coal_demand"])
			+ " electricity=" + str(result["electricity_demand"])
			+ " output=" + str(result["total_output"])
		)

		if not mix_passed:
			all_passed = false

		var physical_monotonic: bool = (
			result["total_output"] <= previous_total_output + 0.000001
		)
		if not physical_monotonic:
			all_passed = false

		previous_coal_demand = result["coal_demand"]
		previous_electricity_demand = result["electricity_demand"]
		previous_total_output = result["total_output"]

	# The old technology operates at full capacity under the same
	# infrastructure availability; the new technology reaches a 0.50
	# operational factor because its infrastructure usage doubles.
	var new_technology_bottleneck_passed: bool = (
		final_result["new_adoption"] >= 0.99
		and final_result["new_status"] == "produced"
		and final_result["new_operational_constraint_factor"] <= 0.500001
		and final_result["new_constraint_sources"].has(
			"infrastructure_usage:modern_steelworks"
		)
		and final_result["total_output"] < first_result["total_output"]
	)

	TestLogger.write_line(
		"Technology transition introduces the new infrastructure-usage constraint as an authoritative production consequence: "
		+ _pass_fail(new_technology_bottleneck_passed)
		+ " | final_new_adoption=" + str(final_result.get("new_adoption", 0.0))
		+ " operational_constraint_factor=" + str(final_result.get("new_operational_constraint_factor", 0.0))
		+ " output=" + str(final_result.get("total_output", 0.0))
	)

	all_passed = all_passed and new_technology_bottleneck_passed

	var economic_consequence_passed: bool = (
		final_result["physical_output"] < first_result["physical_output"]
		and final_result["output_factor"] < first_result["output_factor"]
		and is_equal_approx(final_result["output_factor"], 0.5)
		and final_result["gdp"] < first_result["gdp"]
	)

	TestLogger.write_line(
		"Technology transition -> lower physical output -> lower economic output: "
		+ _pass_fail(economic_consequence_passed)
		+ " | physical_output=" + str(first_result["physical_output"])
		+ "->" + str(final_result["physical_output"])
		+ " output_factor=" + str(first_result["output_factor"])
		+ "->" + str(final_result["output_factor"])
		+ " gdp=" + str(first_result["gdp"])
		+ "->" + str(final_result["gdp"])
	)

	all_passed = all_passed and economic_consequence_passed

	# Recovery: restore sufficient infrastructure for the fully adopted
	# technology. This must recover the same production/economic chain
	# without changing the technology adoption state.
	var recovery_adoption: Dictionary = {
		"step19_4_old_steel": 0.0,
		"step19_4_new_steel": 1.0
	}

	var recovery_result: Dictionary = _run_period(
		world,
		resource_system,
		production_process_system,
		economy_system,
		industry,
		resources,
		infrastructure,
		economy,
		recovery_adoption,
		2.0,
		original_resource_state,
		original_economy_state
	)

	var recovery_passed: bool = (
		recovery_result["new_adoption"] >= 0.99
		and is_equal_approx(recovery_result["new_operational_constraint_factor"], 1.0)
		and is_equal_approx(recovery_result["new_output"], 10.0)
		and is_equal_approx(recovery_result["total_output"], 10.0)
		and is_equal_approx(recovery_result["output_factor"], 1.0)
		and recovery_result["gdp"] > final_result["gdp"]
	)

	TestLogger.write_line(
		"Infrastructure recovery restores fully adopted technology production and economic output: "
		+ _pass_fail(recovery_passed)
		+ " | recovery_output=" + str(recovery_result["total_output"])
		+ " recovery_factor=" + str(recovery_result["output_factor"])
		+ " recovery_gdp=" + str(recovery_result["gdp"])
	)

	all_passed = all_passed and recovery_passed

	# Restore the exact pre-test state. No world date is advanced by this
	# scenario, and temporary catalog entries are removed/restored.
	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	infrastructure.state = original_infrastructure_state.duplicate(true)
	if population != null:
		population.state = original_population_state.duplicate(true)
	world.set("date", original_date)

	if catalog_had_old:
		production_process_system.catalog.processes[
			"step19_4_old_steel"
		] = original_catalog_old
	else:
		production_process_system.catalog.processes.erase(
			"step19_4_old_steel"
		)

	if catalog_had_new:
		production_process_system.catalog.processes[
			"step19_4_new_steel"
		] = original_catalog_new
	else:
		production_process_system.catalog.processes.erase(
			"step19_4_new_steel"
		)

	var restoration_passed: bool = (
		resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
		and infrastructure.state == original_infrastructure_state
	)
	if population != null:
		restoration_passed = restoration_passed and population.state == original_population_state

	TestLogger.write_line(
		"Step 19.4 fixture restoration: "
		+ _pass_fail(restoration_passed)
	)

	all_passed = all_passed and restoration_passed

	TestLogger.write_line(
		"Step 19.4 Technology Transition Causal Validation test passed: "
		+ ("true" if all_passed else "false")
	)

	return all_passed
