class_name IntegratedPhysicalEconomyProductionEconomicOutputTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — PRODUCTION -> ECONOMIC OUTPUT TEST"
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

	if resources == null or industry == null or infrastructure == null or economy == null:
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

	var original_production_state: Dictionary = (
		industry.get_state(
			"production_state",
			{}
		).duplicate(true)
	)

	var original_production_totals: Dictionary = (
		industry.get_state(
			"production_totals",
			{}
		).duplicate(true)
	)

	var original_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)

	var original_resource_production: Dictionary = (
		resources.get_state(
			"production",
			{}
		).duplicate(true)
	)

	var original_resource_consumption: Dictionary = (
		resources.get_state(
			"consumption",
			{}
		).duplicate(true)
	)

	var original_resource_imports: Dictionary = (
		resources.get_state(
			"imports",
			{}
		).duplicate(true)
	)

	var original_resource_exports: Dictionary = (
		resources.get_state(
			"exports",
			{}
		).duplicate(true)
	)

	var original_process_demand: Dictionary = (
		resources.get_state(
			"production_process_demand",
			{}
		).duplicate(true)
	)

	var original_process_shortages: Dictionary = (
		resources.get_state(
			"production_process_shortages",
			{}
		).duplicate(true)
	)

	var original_process_shortage_ratio: Dictionary = (
		resources.get_state(
			"production_process_shortage_ratio",
			{}
		).duplicate(true)
	)

	var original_process_availability: Dictionary = (
		resources.get_state(
			"production_process_resource_availability",
			{}
		).duplicate(true)
	)

	var original_resource_efficiency := float(
		resources.get_state(
			"resource_efficiency",
			1.0
		)
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

	var original_technology_effects: Dictionary = {}
	if research != null:
		original_technology_effects = (
			research.get_state(
				"technology_effects",
				{}
			).duplicate(true)
		)

	# Save the economy states touched by EconomySystem. Keeping this
	# explicit avoids relying on the internal component representation.
	var economy_state_keys := [
		"industrial_capacity",
		"agricultural_capacity",
		"production_efficiency",
		"resource_efficiency",
		"technology_efficiency",
		"infrastructure_efficiency",
		"trade_efficiency",
		"economic_efficiency",
		"gdp",
		"gdp_per_capita",
		"growth_rate",
		"effective_growth_rate",
		"inflation",
		"unemployment",
		"tax_revenue_rate",
		"government_revenue",
		"government_spending_rate",
		"government_spending",
		"budget_balance",
		"treasury",
		"government_debt",
		"investment_rate",
		"investment",
		"investment_to_capacity_rate",
		"investment_capacity",
		"unallocated_industrial_capacity",
		"physical_production_output",
		"physical_production_capacity",
		"production_output_factor"
	]

	var original_economy_state: Dictionary = {}
	for state_key in economy_state_keys:
		original_economy_state[state_key] = economy.get_state(
			state_key,
		null
		)

	# Isolate one industrial transformation process. This keeps the
	# test tied to the authoritative production engine instead of using
	# manually injected economic output values.
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

	resources.set_state(
		"resource_efficiency",
		1.0
	)

	# Isolate generic resource flows so the Step 2.3 test measures only
	# production-process input availability.
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

	if research != null:
		research.set_state(
			"technology_effects",
			{
				"industrial_production_efficiency": 1.0
			}
		)

	# Fix the macro test conditions so the only changing driver is
	# realized physical production.
	economy.set_state(
		"gdp",
		1000.0
	)
	economy.set_state(
		"growth_rate",
		12.0
	)
	economy.set_state(
		"investment_rate",
		0.0
	)
	# Neutralize capital as a production constraint. The existing
	# ProductionProcessSystem bridge uses EconomyComponent.investment_capacity
	# as the available physical capital-capacity pool.
	economy.set_state(
		"investment_capacity",
		1000.0
	)

	economy.set_state(
		"resource_efficiency",
		1.0
	)

	# Start the first controlled monthly resource cycle without stale
	# production-demand/shortage state from earlier tests. ResourceSystem
	# resolves the previous cycle; ProductionProcessSystem then executes
	# against the resulting availability state.
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

	var all_passed := true

	# ============================================================
	# TEST 1 — FULL PRODUCTION -> FULL ECONOMIC OUTPUT FACTOR
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

	resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	resource_system.process_month(
		world
	)

	production_process_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var full_output := float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var full_capacity := float(
		economy.get_state(
			"physical_production_capacity",
			0.0
		)
	)

	var full_factor := float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var full_growth := float(
		economy.get_state(
			"effective_growth_rate",
			0.0
		)
	)

	var full_gdp := float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	var full_pass := (
		is_equal_approx(full_output, 10.0)
		and is_equal_approx(full_capacity, 10.0)
		and is_equal_approx(full_factor, 1.0)
		and is_equal_approx(full_growth, 12.0)
		and is_equal_approx(full_gdp, 1010.0)
	)

	TestLogger.write_line(
		"Full production produces full economic output: "
		+ ("PASS" if full_pass else "FAIL")
		+ " | output="
		+ str(full_output)
		+ " capacity="
		+ str(full_capacity)
		+ " factor="
		+ str(full_factor)
		+ " growth="
		+ str(full_growth)
		+ " gdp="
		+ str(full_gdp)
	)

	if not full_pass:
		all_passed = false

	# ============================================================
	# TEST 2 — RESOURCE SHORTAGE -> LOWER PRODUCTION -> LOWER GDP
	# ============================================================

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

	resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	economy.set_state(
		"gdp",
		1000.0
	)

	resource_system.process_month(
		world
	)

	production_process_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var shortage_output := float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var shortage_capacity := float(
		economy.get_state(
			"physical_production_capacity",
			0.0
		)
	)

	var shortage_factor := float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var shortage_growth := float(
		economy.get_state(
			"effective_growth_rate",
			0.0
		)
	)

	var shortage_gdp := float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	var shortage_pass := (
		is_equal_approx(shortage_output, 2.5)
		and is_equal_approx(shortage_capacity, 10.0)
		and is_equal_approx(shortage_factor, 0.25)
		and is_equal_approx(shortage_growth, 3.0)
		and is_equal_approx(shortage_gdp, 1002.5)
	)

	TestLogger.write_line(
		"Resource-constrained production lowers economic output: "
		+ ("PASS" if shortage_pass else "FAIL")
		+ " | output="
		+ str(shortage_output)
		+ " capacity="
		+ str(shortage_capacity)
		+ " factor="
		+ str(shortage_factor)
		+ " growth="
		+ str(shortage_growth)
		+ " gdp="
		+ str(shortage_gdp)
	)

	if not shortage_pass:
		all_passed = false

	# ============================================================
	# TEST 3 — INPUT RECOVERY RESTORES ECONOMIC OUTPUT
	# ============================================================

	resources.set_state(
		"stockpile",
		full_stockpile
	)

	resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	economy.set_state(
		"gdp",
		1000.0
	)

	resource_system.process_month(
		world
	)

	production_process_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var recovery_factor := float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var recovery_gdp := float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	var recovery_pass := (
		is_equal_approx(recovery_factor, 1.0)
		and is_equal_approx(recovery_gdp, 1010.0)
	)

	TestLogger.write_line(
		"Production recovery restores economic output: "
		+ ("PASS" if recovery_pass else "FAIL")
		+ " | factor="
		+ str(recovery_factor)
		+ " gdp="
		+ str(recovery_gdp)
	)

	if not recovery_pass:
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
		"production_state",
		original_production_state
	)

	industry.set_state(
		"production_totals",
		original_production_totals
	)

	resources.set_state(
		"stockpile",
		original_stockpile
	)

	# Restore generic resource flows changed by Step 2.3 isolation.
	resources.set_state(
		"production",
		original_resource_production
	)

	resources.set_state(
		"consumption",
		original_resource_consumption
	)

	resources.set_state(
		"imports",
		original_resource_imports
	)

	resources.set_state(
		"exports",
		original_resource_exports
	)

	resources.set_state(
		"production_process_demand",
		original_process_demand
	)

	resources.set_state(
		"production_process_shortages",
		original_process_shortages
	)

	resources.set_state(
		"production_process_shortage_ratio",
		original_process_shortage_ratio
	)

	resources.set_state(
		"production_process_resource_availability",
		original_process_availability
	)

	resources.set_state(
		"resource_efficiency",
		original_resource_efficiency
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

	if research != null:
		research.set_state(
			"technology_effects",
			original_technology_effects
		)

	for state_key in economy_state_keys:
		economy.set_state(
			state_key,
			original_economy_state[state_key]
		)

	TestLogger.write_line(
		"Integrated Physical Economy — Production -> Economic Output test passed: "
		+ str(all_passed)
	)

	return all_passed
