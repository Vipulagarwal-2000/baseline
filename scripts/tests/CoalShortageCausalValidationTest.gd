class_name Step19_1CoalShortageCausalValidationTest
extends RefCounted


static func _restore_component_state(
	component,
	original_state: Dictionary
) -> void:

	if component == null:
		return

	for key in component.state.keys():
		if not original_state.has(key):
			component.state.erase(key)

	for key in original_state.keys():
		component.set_state(
			key,
			original_state[key]
		)


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

	var isolated_adoption: Dictionary = (
		original_adoption.duplicate(true)
	)

	isolated_adoption["steel_basic"] = 1.0
	isolated_adoption["machinery_basic"] = 1.0

	industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	# The economic output observer consumes IndustryComponent.production_state,
	# which intentionally stores the latest recorded outcome per process.
	# The isolated Step 19.1 fixture disables every legacy process, so any
	# pre-existing outcome would be stale state from an earlier test and
	# would contaminate the causal-chain measurement. Start the scenario
	# with a clean current-period production ledger. The original state is
	# restored at the end of this test.
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
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)


static func _set_coal_scenario_inputs(
	resources,
	coal_stockpile: float
) -> void:

	# Keep the resource boundary intentionally narrow:
	# coal is the only general-consumption shortage signal.
	# Iron is fully available to isolate coal as the causal bottleneck.
	resources.set_state(
		"production",
		{}
	)

	resources.set_state(
		"consumption",
		{
			"coal": 10.0
		}
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
		{}
	)

	resources.set_state(
		"stockpile",
		{
			"iron": 20.0,
			"coal": coal_stockpile,
			"steel": 0.0,
			"machinery": 0.0
		}
	)

	# This is the previous production-run demand consumed by
	# ResourceSystem. Do not seed steel demand here: that would create
	# a stale zero-steel availability state before the same-month chain
	# executes. Machinery still remains physically constrained by the
	# actual steel stockpile produced by steel_basic.
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


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 19.1 — COAL SHORTAGE CAUSAL VALIDATION"
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
		"Registered causal systems available: PASS"
	)

	# Full mutable-state snapshot for mutation-safe regression execution.
	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)

	var original_industry_state: Dictionary = (
		industry.state.duplicate(true)
	)

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	var original_population_state: Dictionary = {}

	if population != null:
		original_population_state = (
			population.state.duplicate(true)
		)

	var passed := true

	_configure_isolated_chain(
		industry,
		population,
		economy,
		infrastructure
	)

	# ============================================================
	# BASELINE — COAL AVAILABLE
	# ============================================================

	_set_coal_scenario_inputs(
		resources,
		20.0
	)

	resource_system.process_month(
		world
	)

	var baseline_shortage_ratios: Dictionary = resources.get_state(
		"shortage_ratio",
		{}
	)

	var baseline_production_availability: Dictionary = resources.get_state(
		"production_process_resource_availability",
		{}
	)

	var baseline_coal_shortage_ratio := float(
		baseline_shortage_ratios.get(
			"coal",
			-1.0
		)
	)

	var baseline_iron_shortage_ratio := float(
		baseline_shortage_ratios.get(
			"iron",
			-1.0
		)
	)

	var baseline_coal_availability := float(
		baseline_production_availability.get(
			"coal",
			-1.0
		)
	)

	var baseline_iron_availability := float(
		baseline_production_availability.get(
			"iron",
			-1.0
		)
	)

	production_process_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var baseline_steel_output := _get_process_output(
		industry,
		"steel_basic"
	)

	var baseline_machinery_output := _get_process_output(
		industry,
		"machinery_basic"
	)

	var baseline_physical_output := float(
		economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var baseline_production_output_factor := float(
		economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var baseline_economic_pressure := float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	var baseline_pass := (
		is_equal_approx(
			baseline_coal_shortage_ratio,
			0.0
		)
		and is_equal_approx(
			baseline_iron_shortage_ratio,
			0.0
		)
		and is_equal_approx(
			baseline_coal_availability,
			1.0
		)
		and is_equal_approx(
			baseline_iron_availability,
			1.0
		)
		and is_equal_approx(
			baseline_steel_output,
			10.0
		)
		and is_equal_approx(
			baseline_machinery_output,
			5.0
		)
		and baseline_physical_output > 0.0
		and baseline_production_output_factor > 0.0
		and is_equal_approx(
			baseline_economic_pressure,
			0.0
		)
	)

	TestLogger.write_line(
		"Baseline coal availability -> steel -> machinery -> economy: "
		+ ("PASS" if baseline_pass else "FAIL")
		+ " | coal_shortage="
		+ str(baseline_coal_shortage_ratio)
		+ " coal_availability="
		+ str(baseline_coal_availability)
		+ " steel="
		+ str(baseline_steel_output)
		+ " machinery="
		+ str(baseline_machinery_output)
		+ " physical_output="
		+ str(baseline_physical_output)
		+ " output_factor="
		+ str(baseline_production_output_factor)
		+ " economic_pressure="
		+ str(baseline_economic_pressure)
	)

	passed = passed and baseline_pass

	# ============================================================
	# SHOCK — COAL SHORTAGE
	# ============================================================

	_set_coal_scenario_inputs(
		resources,
		5.0
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

	var coal_shortage_ratio := float(
		shortage_ratios.get(
			"coal",
			-1.0
		)
	)

	var iron_shortage_ratio := float(
		shortage_ratios.get(
			"iron",
			-1.0
		)
	)

	var coal_availability := float(
		production_availability.get(
			"coal",
			-1.0
		)
	)

	var iron_availability := float(
		production_availability.get(
			"iron",
			-1.0
		)
	)

	var shock_resource_pass := (
		is_equal_approx(
			coal_shortage_ratio,
			50.0
		)
		and is_equal_approx(
			iron_shortage_ratio,
			0.0
		)
		and is_equal_approx(
			coal_availability,
			0.0
		)
		and is_equal_approx(
			iron_availability,
			1.0
		)
	)

	TestLogger.write_line(
		"Coal shortage is authoritative and isolated to coal: "
		+ ("PASS" if shock_resource_pass else "FAIL")
		+ " | coal_shortage_ratio=50 actual="
		+ str(coal_shortage_ratio)
		+ " coal_availability=0 actual="
		+ str(coal_availability)
		+ " iron_shortage_ratio=0 actual="
		+ str(iron_shortage_ratio)
	)

	passed = passed and shock_resource_pass

	production_process_system.process_month(
		world
	)

	var shock_steel_output := _get_process_output(
		industry,
		"steel_basic"
	)

	var shock_machinery_output := _get_process_output(
		industry,
		"machinery_basic"
	)

	var shock_steel_stockpile := float(
		resources.get_state(
			"stockpile",
			{}
		).get(
			"steel",
			-1.0
		)
	)

	var shock_iron_stockpile := float(
		resources.get_state(
			"stockpile",
			{}
		).get(
			"iron",
			-1.0
		)
	)

	var shock_production_pass := (
		is_equal_approx(
			shock_steel_output,
			0.0
		)
		and is_equal_approx(
			shock_machinery_output,
			0.0
		)
		and is_equal_approx(
			shock_steel_stockpile,
			0.0
		)
		and is_equal_approx(
			shock_iron_stockpile,
			20.0
		)
	)

	TestLogger.write_line(
		"Coal shortage -> steel constraint -> machinery constraint: "
		+ ("PASS" if shock_production_pass else "FAIL")
		+ " | steel="
		+ str(shock_steel_output)
		+ " machinery="
		+ str(shock_machinery_output)
		+ " steel_stockpile="
		+ str(shock_steel_stockpile)
		+ " iron_stockpile="
		+ str(shock_iron_stockpile)
	)

	passed = passed and shock_production_pass

	# Physical-output state is authored by EconomySystem. Resolve the
	# economy boundary before reading physical_production_output and
	# production_output_factor; otherwise those fields still describe the
	# previous baseline period.
	economy_system.process_month(
		world
	)

	var shock_physical_output := float(
		economy.get_state(
			"physical_production_output",
			-1.0
		)
	)

	var shock_output_factor := float(
		economy.get_state(
			"production_output_factor",
			-1.0
		)
	)

	var shock_physical_output_pass := (
		shock_physical_output < baseline_physical_output
		and shock_output_factor < baseline_production_output_factor
	)

	TestLogger.write_line(
		"Coal shortage -> lower physical output: "
		+ ("PASS" if shock_physical_output_pass else "FAIL")
		+ " | baseline_output="
		+ str(baseline_physical_output)
		+ " shock_output="
		+ str(shock_physical_output)
		+ " baseline_factor="
		+ str(baseline_production_output_factor)
		+ " shock_factor="
		+ str(shock_output_factor)
	)

	passed = passed and shock_physical_output_pass

	var shock_economic_pressure := float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	var shock_economy_pass := (
		is_equal_approx(
			shock_economic_pressure,
			0.50
		)
		and shock_economic_pressure > baseline_economic_pressure
		and shock_output_factor < baseline_production_output_factor
	)

	TestLogger.write_line(
		"Lower physical output -> economic pressure: "
		+ ("PASS" if shock_economy_pass else "FAIL")
		+ " | expected_pressure=0.50 actual="
		+ str(shock_economic_pressure)
		+ " baseline_pressure="
		+ str(baseline_economic_pressure)
		+ " baseline_output_factor="
		+ str(baseline_production_output_factor)
		+ " shock_output_factor="
		+ str(shock_output_factor)
	)

	passed = passed and shock_economy_pass

	# ============================================================
	# RECOVERY — COAL RESTORED
	# ============================================================

	_set_coal_scenario_inputs(
		resources,
		20.0
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

	var recovered_shortage_ratios: Dictionary = resources.get_state(
		"shortage_ratio",
		{}
	)

	var recovered_coal_shortage_ratio := float(
		recovered_shortage_ratios.get(
			"coal",
			-1.0
		)
	)

	var recovered_steel_output := _get_process_output(
		industry,
		"steel_basic"
	)

	var recovered_machinery_output := _get_process_output(
		industry,
		"machinery_basic"
	)

	var recovered_physical_output := float(
		economy.get_state(
			"physical_production_output",
			-1.0
		)
	)

	var recovered_economic_pressure := float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	var recovered_output_factor := float(
		economy.get_state(
			"production_output_factor",
			-1.0
		)
	)

	var recovery_pass := (
		is_equal_approx(
			recovered_coal_shortage_ratio,
			0.0
		)
		and is_equal_approx(
			recovered_steel_output,
			10.0
		)
		and is_equal_approx(
			recovered_machinery_output,
			5.0
		)
		and recovered_physical_output > shock_physical_output
		and is_equal_approx(
			recovered_physical_output,
			baseline_physical_output
		)
		and is_equal_approx(
			recovered_output_factor,
			baseline_production_output_factor
		)
		and is_equal_approx(
			recovered_economic_pressure,
			0.0
		)
	)

	TestLogger.write_line(
		"Coal recovery -> production recovery -> economic pressure recovery: "
		+ ("PASS" if recovery_pass else "FAIL")
		+ " | coal_shortage_ratio="
		+ str(recovered_coal_shortage_ratio)
		+ " steel="
		+ str(recovered_steel_output)
		+ " machinery="
		+ str(recovered_machinery_output)
		+ " physical_output="
		+ str(recovered_physical_output)
		+ " baseline_physical_output="
		+ str(baseline_physical_output)
		+ " output_factor="
		+ str(recovered_output_factor)
		+ " economic_pressure="
		+ str(recovered_economic_pressure)
	)

	passed = passed and recovery_pass

	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

	_restore_component_state(
		resources,
		original_resource_state
	)

	_restore_component_state(
		industry,
		original_industry_state
	)

	_restore_component_state(
		economy,
		original_economy_state
	)

	_restore_component_state(
		infrastructure,
		original_infrastructure_state
	)

	if population != null:
		_restore_component_state(
			population,
			original_population_state
		)

	TestLogger.write_line(
		"Step 19.1 Coal Shortage Causal Validation test passed: "
		+ str(passed)
	)

	return passed
