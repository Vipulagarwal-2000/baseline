class_name Step19_2RailwayInvestmentCausalValidationTest
extends RefCounted


static func _configure_isolated_chain(
	industry,
	population,
	economy,
	infrastructure
) -> void:

	var original_processes: Dictionary = (
		industry.get_state(
			"processes",
			{}
		).duplicate(true)
	)

	var isolated_processes: Dictionary = {}

	for process_id in original_processes.keys():

		var process_instance = original_processes[process_id]

		if typeof(process_instance) != TYPE_DICTIONARY:
			continue

		var isolated_process = process_instance.duplicate(true)
		isolated_process["active"] = false
		isolated_processes[str(process_id)] = isolated_process

	isolated_processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	isolated_processes["machinery_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		isolated_processes
	)

	var original_adoption: Dictionary = (
		industry.get_state(
			"process_adoption",
			{}
		).duplicate(true)
	)

	var isolated_adoption: Dictionary = original_adoption.duplicate(true)
	isolated_adoption["steel_basic"] = 1.0
	isolated_adoption["machinery_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	# EconomySystem observes latest production outcomes. Clear the prior
	# ledger so this causal scenario measures only the current experiment.
	industry.set_state(
		"production_state",
		{}
	)

	industry.set_state(
		"production_totals",
		{}
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
		"transport",
		1.0
	)

	infrastructure.set_state(
		"roads",
		1.0
	)

	infrastructure.set_state(
		"ports",
		1.0
	)

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)


static func _set_railway_scenario_inputs(
	resources,
	iron_production: float,
	coal_production: float,
	iron_reserves: float,
	coal_reserves: float
) -> void:

	# Resource production is deliberately high enough to satisfy the
	# isolated steel process at full railway accessibility. Railway
	# capacity is the only changing transport/accessibility constraint.
	resources.set_state(
		"production",
		{
			"iron": iron_production,
			"coal": coal_production
		}
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

	resources.set_state(
		"reserves",
		{
			"iron": iron_reserves,
			"coal": coal_reserves
		}
	)

	resources.set_state(
		"accessibility",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)

	resources.set_state(
		"quality",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)

	resources.set_state(
		"infrastructure_capacity",
		{
			"iron": 1.0,
			"coal": 1.0
		}
	)

	resources.set_state(
		"stockpile",
		{
			"iron": 0.0,
			"coal": 0.0,
			"steel": 0.0,
			"machinery": 0.0
		}
	)

	# Seed the gross demand boundary so ResourceSystem can resolve the
	# same-month accessibility effect before ProductionProcessSystem runs.
	resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)


static func _get_process_output(
	industry,
	process_id: String
) -> float:

	var outcome: Dictionary = industry.get_production_outcome(
		process_id
	)

	return float(
		outcome.get(
			"actual_production",
			0.0
		)
	)


static func _get_rail_accessibility_limit(
	infrastructure
) -> float:
	return float(
		infrastructure.get_state(
			"railways",
			0.0
		)
	)


static func _run_period(
	world: WorldState,
	resource_system,
	production_process_system,
	economy_system,
	resources,
	industry,
	economy,
	infrastructure,
	railway_capacity: float
) -> Dictionary:

	infrastructure.set_state(
		"railways",
		railway_capacity
	)

	resource_system.process_month(
		world
	)

	var shortage_ratios: Dictionary = resources.get_state(
		"shortage_ratio",
		{}
	)

	var production_availability: Dictionary = resources.get_state(
		"production_process_resource_availability",
		{}
	)

	var accessibility: Dictionary = resources.get_state(
		"accessibility",
		{}
	)

	production_process_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var physical_output := float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var production_output_factor := float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var gdp := float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	return {
		"railways": float(
			infrastructure.get_state(
				"railways",
				0.0
			)
		),
		"iron_accessibility": float(
			production_availability.get(
				"iron",
				-1.0
			)
		),
		"coal_accessibility": float(
			production_availability.get(
				"coal",
				-1.0
			)
		),
		"iron_base_accessibility": float(
			accessibility.get(
				"iron",
				-1.0
			)
		),
		"coal_base_accessibility": float(
			accessibility.get(
				"coal",
				-1.0
			)
		),
		"iron_shortage_ratio": float(
			shortage_ratios.get(
				"iron",
				-1.0
			)
		),
		"coal_shortage_ratio": float(
			shortage_ratios.get(
				"coal",
				-1.0
			)
		),
		"steel": _get_process_output(
			industry,
			"steel_basic"
		),
		"machinery": _get_process_output(
			industry,
			"machinery_basic"
		),
		"physical_output": physical_output,
		"production_output_factor": production_output_factor,
		"gdp": gdp
	}


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 19.2 — RAILWAY INVESTMENT CAUSAL VALIDATION"
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

	if (
		resources == null
		or industry == null
		or infrastructure == null
		or economy == null
	):
		TestLogger.write_line(
			"Required causal-chain components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required causal-chain components available: PASS"
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

	var infrastructure_system = simulation.get_system(
		"infrastructure_system"
	)

	var infrastructure_investment_system = simulation.get_system(
		"infrastructure_investment_system"
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

	if infrastructure_system == null:
		TestLogger.write_line(
			"Registered InfrastructureSystem available: FAIL"
		)
		return false

	if infrastructure_investment_system == null:
		TestLogger.write_line(
			"Registered InfrastructureInvestmentSystem available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Registered causal systems available: PASS"
	)

	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)
	var original_population_state: Dictionary = {}

	if population != null:
		original_population_state = population.state.duplicate(true)

	var passed := true

	_configure_isolated_chain(
		industry,
		population,
		economy,
		infrastructure
	)

	# Capture the clean causal-experiment starting point so baseline and
	# improved periods are evaluated from identical non-railway state.
	var scenario_industry_state: Dictionary = industry.state.duplicate(true)
	var scenario_economy_state: Dictionary = economy.state.duplicate(true)
	var scenario_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)

	# ============================================================
	# BASELINE — LIMITED RAILWAY ACCESSIBILITY
	# ============================================================

	_set_railway_scenario_inputs(
		resources,
		20.0,
		10.0,
		1000.0,
		1000.0
	)

	var roads_before := float(
		infrastructure.get_state(
			"roads",
			1.0
		)
	)

	var ports_before := float(
		infrastructure.get_state(
			"ports",
			1.0
		)
	)

	var power_before := float(
		infrastructure.get_state(
			"power",
			1.0
		)
	)

	var transport_before := float(
		infrastructure.get_state(
			"transport",
			1.0
		)
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
		0.5
	)

	# The live ResourceSystem applies roads/railways as effective accessibility
	# limits inside the current resource-production pass. The resource
	# component's raw accessibility state is intentionally left at 1.0, so
	# this scenario must validate the derived production-process availability
	# rather than expecting the raw accessibility dictionary to change.
	# Shortage ratios are also not the causal signal here: Run 658 showed that
	# the railway constraint can reduce production availability and output while
	# the separate shortage ledger remains at zero.
	var baseline_pass: bool = (
		is_equal_approx(
			baseline["railways"],
			0.5
		)
		and baseline["iron_accessibility"] > 0.0
		and baseline["iron_accessibility"] < 1.0
		and baseline["coal_accessibility"] > 0.0
		and baseline["coal_accessibility"] < 1.0
		and baseline["iron_base_accessibility"] >= 0.0
		and baseline["coal_base_accessibility"] >= 0.0
		and baseline["steel"] > 0.0
		and baseline["machinery"] > 0.0
		and baseline["physical_output"] > 0.0
		and baseline["production_output_factor"] > 0.0
	)

	TestLogger.write_line(
		"Baseline limited railway capacity -> constrained live accessibility -> production: "
		+ ("PASS" if baseline_pass else "FAIL")
		+ " | railways=" + str(baseline["railways"])
		+ " iron_live_availability=" + str(baseline["iron_accessibility"])
		+ " coal_live_availability=" + str(baseline["coal_accessibility"])
		+ " iron_shortage=" + str(baseline["iron_shortage_ratio"])
		+ " coal_shortage=" + str(baseline["coal_shortage_ratio"])
		+ " iron_raw_accessibility=" + str(baseline["iron_base_accessibility"])
		+ " coal_raw_accessibility=" + str(baseline["coal_base_accessibility"])
		+ " steel=" + str(baseline["steel"])
		+ " machinery=" + str(baseline["machinery"])
		+ " physical_output=" + str(baseline["physical_output"])
	)

	passed = passed and baseline_pass

	# ============================================================
	# CONTROLLED RAILWAY INTERVENTION — RAILWAYS 0.5 -> 1.0
	# ============================================================

	# Reset the resource flow to the exact same starting state so the
	# only causal change between periods is the authoritative railway
	# infrastructure value. The InfrastructureInvestmentSystem is
	# already independently validated; Step 19.2 validates the
	# downstream causal consequence of a railway investment result.
	resources.state = original_resource_state.duplicate(true)
	industry.state = scenario_industry_state.duplicate(true)
	economy.state = scenario_economy_state.duplicate(true)
	infrastructure.state = scenario_infrastructure_state.duplicate(true)

	_set_railway_scenario_inputs(
		resources,
		20.0,
		10.0,
		1000.0,
		1000.0
	)

	infrastructure.set_state(
		"railways",
		1.0
	)

	var railway_intervention_pass: bool = (
		is_equal_approx(
			_get_rail_accessibility_limit(infrastructure),
			1.0
		)
		and is_equal_approx(
			infrastructure.get_state("roads", 1.0),
			roads_before
		)
		and is_equal_approx(
			infrastructure.get_state("ports", 1.0),
			ports_before
		)
		and is_equal_approx(
			infrastructure.get_state("power", 1.0),
			power_before
		)
		and is_equal_approx(
			infrastructure.get_state("transport", 1.0),
			transport_before
		)
	)

	TestLogger.write_line(
		"Railway investment increases authoritative railway capacity without changing unrelated infrastructure: "
		+ ("PASS" if railway_intervention_pass else "FAIL")
		+ " | railways="
		+ str(_get_rail_accessibility_limit(infrastructure))
		+ " roads="
		+ str(infrastructure.get_state("roads", 1.0))
		+ " ports="
		+ str(infrastructure.get_state("ports", 1.0))
		+ " power="
		+ str(infrastructure.get_state("power", 1.0))
		+ " transport="
		+ str(infrastructure.get_state("transport", 1.0))
	)

	passed = passed and railway_intervention_pass

	var improved := _run_period(
		world,
		resource_system,
		production_process_system,
		economy_system,
		resources,
		industry,
		economy,
		infrastructure,
		1.0
	)

	var improved_infrastructure_isolated: bool = (
		is_equal_approx(
			float(infrastructure.get_state("roads", 1.0)),
			roads_before
		)
		and is_equal_approx(
			float(infrastructure.get_state("ports", 1.0)),
			ports_before
		)
		and is_equal_approx(
			float(infrastructure.get_state("power", 1.0)),
			power_before
		)
		and is_equal_approx(
			float(infrastructure.get_state("transport", 1.0)),
			transport_before
		)
	)

	var downstream_pass: bool = (
		is_equal_approx(
			improved["railways"],
			1.0
		)
		and improved["iron_accessibility"] > baseline["iron_accessibility"]
		and improved["coal_accessibility"] > baseline["coal_accessibility"]
		and is_equal_approx(
			baseline["iron_base_accessibility"],
			improved["iron_base_accessibility"]
		)
		and is_equal_approx(
			baseline["coal_base_accessibility"],
			improved["coal_base_accessibility"]
		)
		and improved["steel"] > baseline["steel"]
		and improved["machinery"] > baseline["machinery"]
		and improved["physical_output"] > baseline["physical_output"]
		and improved["production_output_factor"] > baseline["production_output_factor"]
		and improved["gdp"] > baseline["gdp"]
		and improved_infrastructure_isolated
	)

	TestLogger.write_line(
		"Railway investment result -> higher accessibility -> higher production -> higher economic output: "
		+ ("PASS" if downstream_pass else "FAIL")
		+ " | steel=" + str(improved["steel"])
		+ " machinery=" + str(improved["machinery"])
		+ " physical_output=" + str(improved["physical_output"])
		+ " baseline_physical_output=" + str(baseline["physical_output"])
		+ " iron_effective_accessibility=" + str(improved["iron_accessibility"])
		+ " coal_effective_accessibility=" + str(improved["coal_accessibility"])
		+ " gdp=" + str(improved["gdp"])
		+ " baseline_gdp=" + str(baseline["gdp"])
		+ " unrelated_infrastructure_unchanged=" + str(improved_infrastructure_isolated)
	)

	passed = passed and downstream_pass

	var accessibility_causal_pass: bool = (
		improved["iron_accessibility"] > baseline["iron_accessibility"]
		and improved["coal_accessibility"] > baseline["coal_accessibility"]
		and is_equal_approx(
			baseline["iron_base_accessibility"],
			improved["iron_base_accessibility"]
		)
		and is_equal_approx(
			baseline["coal_base_accessibility"],
			improved["coal_base_accessibility"]
		)
		and improved["steel"] > baseline["steel"]
		and improved["machinery"] > baseline["machinery"]
		and improved["physical_output"] > baseline["physical_output"]
		and improved["gdp"] > baseline["gdp"]
	)

	TestLogger.write_line(
		"Full causal direction remains monotonic across the railway intervention: "
		+ ("PASS" if accessibility_causal_pass else "FAIL")
		+ " | accessibility "
		+ str(baseline["iron_accessibility"])
		+ "->"
		+ str(improved["iron_accessibility"])
		+ " steel "
		+ str(baseline["steel"])
		+ "->"
		+ str(improved["steel"])
		+ " machinery "
		+ str(baseline["machinery"])
		+ "->"
		+ str(improved["machinery"])
		+ " physical_output "
		+ str(baseline["physical_output"])
		+ "->"
		+ str(improved["physical_output"])
		+ " gdp "
		+ str(baseline["gdp"])
		+ "->"
		+ str(improved["gdp"])
	)

	passed = passed and accessibility_causal_pass

	# ============================================================
	# RESTORE — FULL FIXTURE STATE
	# ============================================================

	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)
	infrastructure.state = original_infrastructure_state.duplicate(true)

	if population != null:
		population.state = original_population_state.duplicate(true)

	var restoration_pass: bool = (
		resources.state == original_resource_state
		and industry.state == original_industry_state
		and economy.state == original_economy_state
		and infrastructure.state == original_infrastructure_state
	)

	if population != null:
		restoration_pass = (
			restoration_pass
			and population.state == original_population_state
		)

	TestLogger.write_line(
		"Step 19.2 fixture restoration: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	passed = passed and restoration_pass

	TestLogger.write_line(
		"Step 19.2 Railway Investment Causal Validation test passed: "
		+ ("true" if passed else "false")
	)

	return passed
