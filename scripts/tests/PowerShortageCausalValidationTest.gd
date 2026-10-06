class_name Step19_3PowerShortageCausalValidationTest
extends RefCounted


static func _world_year(world: WorldState) -> int:
	var date_value = world.get("date")
	if typeof(date_value) == TYPE_OBJECT and "year" in date_value:
		return int(date_value.year)
	if typeof(date_value) == TYPE_DICTIONARY:
		return int(date_value.get("year", 0))
	return 0


static func _has_positive_power_requirement(
	definition: Dictionary
) -> bool:
	var raw_energy_requirement = definition.get(
		"energy_requirement",
		{}
	)

	if typeof(raw_energy_requirement) != TYPE_DICTIONARY:
		return false

	for raw_value in raw_energy_requirement.values():
		if (
			typeof(raw_value) == TYPE_INT
			or typeof(raw_value) == TYPE_FLOAT
		) and float(raw_value) > 0.0:
			return true

	return false


static func _candidate_complexity(
	definition: Dictionary
) -> int:
	var score: int = 0
	var dictionary_fields: Array[String] = [
		"technology_requirements",
		"capability_requirements",
		"infrastructure_requirements",
		"infrastructure_usage",
		"equipment_requirement",
		"maintenance_requirement",
		"labor_skill_requirement"
	]

	for field_name in dictionary_fields:
		var raw_value = definition.get(field_name, {})
		if typeof(raw_value) == TYPE_DICTIONARY and not raw_value.is_empty():
			score += raw_value.size()
		elif raw_value != null and typeof(raw_value) != TYPE_DICTIONARY:
			score += 1

	return score


static func _find_live_energy_process(
	world: WorldState,
	industry,
	production_process_system
) -> Dictionary:
	if production_process_system == null or production_process_system.catalog == null:
		return {}

	var processes = industry.get_state("processes", {})
	if typeof(processes) != TYPE_DICTIONARY:
		return {}

	var year := _world_year(world)
	var available_ids: Array = []
	if year > 0:
		available_ids = production_process_system.catalog.get_available_process_ids(year)
	else:
		available_ids = production_process_system.catalog.get_process_ids()

	var available_set: Dictionary = {}
	for raw_id in available_ids:
		available_set[str(raw_id)] = true

	var selected: Dictionary = {}
	var selected_score: int = 2147483647

	for raw_process_id in processes.keys():
		var process_id := str(raw_process_id)
		if not available_set.has(process_id):
			continue

		var instance = processes[raw_process_id]
		if typeof(instance) != TYPE_DICTIONARY:
			continue
		if not bool(instance.get("active", false)):
			continue

		var capacity := float(instance.get("capacity", 0.0))
		if capacity <= 0.0:
			continue

		var adoption_state = industry.get_state("process_adoption", {})
		if typeof(adoption_state) != TYPE_DICTIONARY:
			adoption_state = {}
		var adoption := float(
			adoption_state.get(
				process_id,
				1.0
			)
		)
		if adoption <= 0.0:
			continue

		var definition: Dictionary = production_process_system.catalog.get_process(process_id)
		if definition.is_empty():
			continue

		var category := str(definition.get("category", "")).to_lower()
		if category == "extraction":
			continue

		if not _has_positive_power_requirement(definition):
			continue

		var score := _candidate_complexity(definition)
		if score < selected_score:
			selected_score = score
			selected = {
				"id": process_id,
				"instance": instance.duplicate(true),
				"definition": definition.duplicate(true),
				"adoption": adoption,
				"capacity": capacity,
				"complexity": score
			}

	return selected


static func _configure_isolated_fixture(
	world: WorldState,
	industry,
	population,
	economy,
	infrastructure,
	resources,
	original_industry_state: Dictionary,
	original_population_state: Dictionary,
	original_economy_state: Dictionary,
	original_infrastructure_state: Dictionary,
	original_resource_state: Dictionary,
	process_id: String,
	process_definition: Dictionary,
	process_instance: Dictionary,
	process_adoption: float
) -> void:
	industry.state = original_industry_state.duplicate(true)
	if population != null:
		population.state = original_population_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	infrastructure.state = original_infrastructure_state.duplicate(true)
	resources.state = original_resource_state.duplicate(true)

	var raw_process_state = industry.get_state("processes", {})
	var processes: Dictionary = {}
	if typeof(raw_process_state) == TYPE_DICTIONARY:
		processes = raw_process_state.duplicate(true)
	for raw_process_id in processes.keys():
		var existing_process = processes[raw_process_id]
		if typeof(existing_process) == TYPE_DICTIONARY:
			existing_process["active"] = false
			processes[raw_process_id] = existing_process

	var capacity := maxf(float(process_instance.get("capacity", 0.0)), 0.0)
	var selected_instance := process_instance.duplicate(true)
	selected_instance["active"] = true
	# Step 19.3 scenario intervention: derive the selected process power
	# requirement from the authoritative baseline infrastructure power and
	# installed process capacity. This gives the baseline a neutral power
	# factor of 1.0 and makes the intervention a pure live-power reduction.
	var baseline_power := clampf(
		float(original_infrastructure_state.get("power", 0.0)),
		0.0,
		1.0
	)
	var scenario_power_requirement := 0.0
	if capacity > 0.0:
		scenario_power_requirement = baseline_power / capacity
	selected_instance["power_requirement"] = scenario_power_requirement
	processes[process_id] = selected_instance
	industry.set_state("processes", processes)

	var raw_adoption_state = industry.get_state("process_adoption", {})
	var adoption: Dictionary = {}
	if typeof(raw_adoption_state) == TYPE_DICTIONARY:
		adoption = raw_adoption_state.duplicate(true)
	adoption[process_id] = clampf(process_adoption, 0.0, 1.0)
	industry.set_state("process_adoption", adoption)
	industry.set_state("production_state", {})
	industry.set_state("production_totals", {})

	# Keep the live process requirements intact. Only raise the existing
	# physical capacity pools high enough to remove unrelated bottlenecks.
	var labor_requirement = process_definition.get("labor_requirement", 0.0)
	if population != null and (
		typeof(labor_requirement) == TYPE_INT
		or typeof(labor_requirement) == TYPE_FLOAT
	):
		var required_labor := maxf(float(labor_requirement) * capacity, 0.0)
		var original_labor := float(
			original_population_state.get("effective_labor_capacity", 0.0)
		)
		population.set_state(
			"effective_labor_capacity",
			maxf(original_labor, required_labor * 2.0 + 1.0)
		)

	var capital_requirement = process_definition.get("capital_requirement", 0.0)
	if (
		typeof(capital_requirement) == TYPE_INT
		or typeof(capital_requirement) == TYPE_FLOAT
	):
		var required_capital := maxf(float(capital_requirement) * capacity, 0.0)
		var original_capital := float(
			original_economy_state.get("investment_capacity", 0.0)
		)
		economy.set_state(
			"investment_capacity",
			maxf(original_capital, required_capital * 2.0 + 1.0)
		)

	# Clear only derived output fields that could carry state from an earlier
	# focused test. GDP, treasury, pressure, and other authoritative values
	# remain at the saved baseline.
	economy.set_state("physical_production_output", 0.0)
	economy.set_state("physical_production_capacity", 0.0)
	economy.set_state("production_output_factor", 0.0)

	# Make the selected process inputs abundant using requirements derived
	# from the live catalog and live installed capacity. No fixed production
	# or GDP expectation is embedded here.
	var production: Dictionary = resources.get_state("production", {}).duplicate(true)
	var reserves: Dictionary = resources.get_state("reserves", {}).duplicate(true)
	var stockpile: Dictionary = resources.get_state("stockpile", {}).duplicate(true)
	var accessibility: Dictionary = resources.get_state("accessibility", {}).duplicate(true)
	var quality: Dictionary = resources.get_state("quality", {}).duplicate(true)
	var infrastructure_capacity: Dictionary = resources.get_state("infrastructure_capacity", {}).duplicate(true)

	var inputs = process_definition.get("inputs", {})
	if typeof(inputs) == TYPE_DICTIONARY:
		for raw_resource_name in inputs.keys():
			var resource_name := str(raw_resource_name)
			var input_rate := float(inputs[raw_resource_name])
			if input_rate <= 0.0:
				continue

			var required_supply := input_rate * capacity
			var buffer := required_supply * 4.0 + 1.0
			production[resource_name] = maxf(
				float(production.get(resource_name, 0.0)),
				buffer
			)
			reserves[resource_name] = maxf(
				float(reserves.get(resource_name, 0.0)),
				buffer
			)
			stockpile[resource_name] = maxf(
				float(stockpile.get(resource_name, 0.0)),
				buffer
			)
			accessibility[resource_name] = 1.0
			quality[resource_name] = 1.0
			infrastructure_capacity[resource_name] = 1.0

	resources.set_state("production", production)
	resources.set_state("reserves", reserves)
	resources.set_state("stockpile", stockpile)
	resources.set_state("accessibility", accessibility)
	resources.set_state("quality", quality)
	resources.set_state("infrastructure_capacity", infrastructure_capacity)
	resources.set_state("consumption", {})
	resources.set_state("imports", {})
	resources.set_state("exports", {})
	resources.set_state("population_demand", {})
	resources.set_state("production_process_demand", {})


static func _run_period(
	world: WorldState,
	resource_system,
	production_process_system,
	economy_system,
	resources,
	industry,
	economy,
	infrastructure,
	power_level: float,
	process_id: String
) -> Dictionary:
	infrastructure.set_state("power", power_level)

	resource_system.process_month(world)
	production_process_system.process_month(world)
	economy_system.process_month(world)

	var outcome: Dictionary = industry.get_production_outcome(process_id)
	var shortages: Dictionary = resources.get_state("shortages", {})

	return {
		"power": float(infrastructure.get_state("power", 0.0)),
		"process_output": float(outcome.get("actual_production", 0.0)),
		"process_status": str(outcome.get("status", "")),
		"operational_factor": float(outcome.get("operational_factor", 1.0)),
		"resource_constraint_factor": float(outcome.get("resource_constraint_factor", 1.0)),
		"power_constraint_factor": float(outcome.get("power_constraint_factor", 1.0)),
		"physical_output": float(economy.get_state("physical_production_output", 0.0)),
		"production_output_factor": float(economy.get_state("production_output_factor", 0.0)),
		"economic_pressure": float(economy.get_state("economic_pressure", 0.0)),
		"gdp": float(economy.get_state("gdp", 0.0)),
		"shortages": shortages.duplicate(true)
	}


static func _all_shortages_neutral(result: Dictionary) -> bool:
	var shortages = result.get("shortages", {})
	if typeof(shortages) != TYPE_DICTIONARY:
		return false

	for raw_value in shortages.values():
		if float(raw_value) > 0.01:
			return false

	return true


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section("STEP 19.3 — POWER SHORTAGE CAUSAL VALIDATION")

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false
	TestLogger.write_line("World / Simulation available: PASS")

	var india = world.get_entity("india")
	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false
	TestLogger.write_line("India available: PASS")

	var resources = india.get_component("resources")
	var industry = india.get_component("industry")
	var infrastructure = india.get_component("infrastructure")
	var population = india.get_component("population")
	var economy = india.get_component("economy")

	if resources == null or industry == null or infrastructure == null or economy == null:
		TestLogger.write_line("Required causal-chain components available: FAIL")
		return false
	TestLogger.write_line("Required causal-chain components available: PASS")

	var resource_system = simulation.get_system("resource_system")
	var production_process_system = simulation.get_system("production_process_system")
	var economy_system = simulation.get_system("economy_system")

	if resource_system == null or production_process_system == null or economy_system == null:
		TestLogger.write_line("Registered causal systems available: FAIL")
		return false
	TestLogger.write_line("Registered causal systems available: PASS")

	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_population_state: Dictionary = {}
	if population != null:
		original_population_state = population.state.duplicate(true)
	var original_date = world.get("date")
	if typeof(original_date) == TYPE_DICTIONARY:
		original_date = original_date.duplicate(true)

	var candidate := _find_live_energy_process(
		world,
		industry,
		production_process_system
	)
	if candidate.is_empty():
		TestLogger.write_line("Live active production process selected for power-capacity intervention: FAIL")
		return false

	var process_id := str(candidate["id"])
	var process_definition: Dictionary = candidate["definition"]
	var process_instance: Dictionary = candidate["instance"]
	var process_capacity := float(candidate["capacity"])
	var process_adoption := float(candidate["adoption"])

	TestLogger.write_line(
		"Live active production process selected for power-capacity intervention: PASS"
		+ " | process=" + process_id
		+ " capacity=" + str(process_capacity)
		+ " adoption=" + str(process_adoption)
		+ " catalog_complexity=" + str(int(candidate["complexity"]))
	)

	var baseline_power := float(
		original_infrastructure_state.get("power", 0.0)
	)
	if baseline_power <= 0.0:
		TestLogger.write_line(
			"Positive live power baseline exists for causal intervention: FAIL"
			+ " | baseline_power=" + str(baseline_power)
		)
		return false

	var shock_power := baseline_power * 0.5

	_configure_isolated_fixture(
		world,
		industry,
		population,
		economy,
		infrastructure,
		resources,
		original_industry_state,
		original_population_state,
		original_economy_state,
		original_infrastructure_state,
		original_resource_state,
		process_id,
		process_definition,
		process_instance,
		process_adoption
	)
	var baseline := _run_period(
		world,
		resource_system,
		production_process_system,
		economy_system,
		resources,
		industry,
		economy,
		infrastructure,
		baseline_power,
		process_id
	)

	_configure_isolated_fixture(
		world,
		industry,
		population,
		economy,
		infrastructure,
		resources,
		original_industry_state,
		original_population_state,
		original_economy_state,
		original_infrastructure_state,
		original_resource_state,
		process_id,
		process_definition,
		process_instance,
		process_adoption
	)
	var shock := _run_period(
		world,
		resource_system,
		production_process_system,
		economy_system,
		resources,
		industry,
		economy,
		infrastructure,
		shock_power,
		process_id
	)

	var baseline_pass: bool = (
		baseline["power"] > 0.0
		and baseline["process_status"] == "produced"
		and baseline["process_output"] > 0.0
		and baseline["physical_output"] > 0.0
		and baseline["resource_constraint_factor"] >= 0.99
		and baseline["power_constraint_factor"] >= 0.99
		and _all_shortages_neutral(baseline)
	)

	TestLogger.write_line(
		"Baseline live power supports production without a resource shortage: "
		+ ("PASS" if baseline_pass else "FAIL")
		+ " | power=" + str(baseline["power"])
		+ " process_output=" + str(baseline["process_output"])
		+ " resource_constraint_factor=" + str(baseline["resource_constraint_factor"])
	)

	var resource_path_unchanged: bool = (
		absf(
			shock["resource_constraint_factor"]
			- baseline["resource_constraint_factor"]
		) <= 0.0001
		and _all_shortages_neutral(shock)
	)

	TestLogger.write_line(
		"Power intervention does not introduce a competing resource shortage: "
		+ ("PASS" if resource_path_unchanged else "FAIL")
		+ " | baseline_resource_factor=" + str(baseline["resource_constraint_factor"])
		+ " shock_resource_factor=" + str(shock["resource_constraint_factor"])
	)

	var shock_pass: bool = (
		shock["power"] < baseline["power"]
		and shock["power_constraint_factor"] < baseline["power_constraint_factor"]
		and shock["process_output"] < baseline["process_output"]
	)

	TestLogger.write_line(
		"Lower live power -> lower authoritative process production: "
		+ ("PASS" if shock_pass else "FAIL")
		+ " | power=" + str(baseline["power"]) + "->" + str(shock["power"])
		+ " process_output=" + str(baseline["process_output"]) + "->" + str(shock["process_output"])
	)

	var downstream_pass: bool = (
		shock["physical_output"] < baseline["physical_output"]
		and shock["production_output_factor"] < baseline["production_output_factor"]
		and shock["gdp"] < baseline["gdp"]
		and shock["economic_pressure"] > baseline["economic_pressure"]
	)

	TestLogger.write_line(
		"Lower production -> lower physical output -> economic consequence: "
		+ ("PASS" if downstream_pass else "FAIL")
		+ " | physical_output=" + str(baseline["physical_output"]) + "->" + str(shock["physical_output"])
		+ " output_factor=" + str(baseline["production_output_factor"]) + "->" + str(shock["production_output_factor"])
		+ " gdp=" + str(baseline["gdp"]) + "->" + str(shock["gdp"])
		+ " pressure=" + str(baseline["economic_pressure"]) + "->" + str(shock["economic_pressure"])
	)

	var monotonic_pass: bool = (
		shock["power"] < baseline["power"]
		and shock["process_output"] < baseline["process_output"]
		and shock["physical_output"] < baseline["physical_output"]
		and shock["gdp"] < baseline["gdp"]
		and shock["economic_pressure"] > baseline["economic_pressure"]
	)

	TestLogger.write_line(
		"Full causal direction remains monotonic under the live power intervention: "
		+ ("PASS" if monotonic_pass else "FAIL")
	)

	# Restore the exact saved component/world state. The test never mutates
	# the catalog or simulation date, so the live model remains the source of truth.
	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	infrastructure.state = original_infrastructure_state.duplicate(true)
	if population != null:
		population.state = original_population_state.duplicate(true)
	world.set("date", original_date)

	var restoration_pass: bool = (
		resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
		and infrastructure.state == original_infrastructure_state
	)
	if population != null:
		restoration_pass = restoration_pass and population.state == original_population_state

	TestLogger.write_line(
		"Step 19.3 fixture restoration: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	var passed: bool = (
		baseline_pass
		and resource_path_unchanged
		and shock_pass
		and downstream_pass
		and monotonic_pass
		and restoration_pass
	)

	TestLogger.write_line(
		"Step 19.3 Power Shortage Causal Validation test passed: "
		+ ("true" if passed else "false")
	)

	return passed
