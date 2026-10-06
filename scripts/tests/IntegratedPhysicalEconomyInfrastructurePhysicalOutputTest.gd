class_name IntegratedPhysicalEconomyInfrastructurePhysicalOutputTest
extends RefCounted


static func _log(message: String) -> void:
	TestLogger.write_line(message)


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func run(
	world = null,
	simulation = null
) -> bool:

	TestLogger.section(
		"INTEGRATED PHYSICAL ECONOMY — INFRASTRUCTURE -> PHYSICAL OUTPUT TEST"
	)

	var all_passed := true

	if world == null:
		_log("World / Simulation available: FAIL | world is null")
		return false

	if simulation == null:
		_log("World / Simulation available: FAIL | simulation is null")
		return false

	_log("World / Simulation available: PASS")

	var india = world.get_entity("india")

	var infrastructure = (
		india.get_component("infrastructure")
		if india != null
		else null
	)

	var resources = (
		india.get_component("resources")
		if india != null
		else null
	)

	var industry = (
		india.get_component("industry")
		if india != null
		else null
	)

	if india == null:
		_log("India available: FAIL")
		return false

	_log("India available: PASS")

	var infrastructure_system: InfrastructureSystem = (
		simulation.get_system(
			"infrastructure_system"
		) as InfrastructureSystem
	)

	var production_process_system: ProductionProcessSystem = (
		simulation.get_system(
			"production_process_system"
		) as ProductionProcessSystem
	)

	var infrastructure_system_available: bool = (
		infrastructure_system != null
	)

	var production_system_available: bool = (
		production_process_system != null
	)

	_log(
		"Registered InfrastructureSystem available: "
		+ _pass_fail(infrastructure_system_available)
	)

	_log(
		"Registered ProductionProcessSystem available: "
		+ _pass_fail(production_system_available)
	)

	if not infrastructure_system_available:
		return false

	if not production_system_available:
		return false

	if infrastructure == null or resources == null or industry == null:
		_log("Required physical-economy components available: FAIL")
		return false

	_log("Required physical-economy components available: PASS")

	# ------------------------------------------------------------
	# SAVE ORIGINAL STATE
	# ------------------------------------------------------------

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	var original_resource_production: Dictionary = (
		resources.get_state(
			"production",
			{}
		).duplicate(true)
	)

	var original_resource_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
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

	var catalog: ProductionProcessCatalog = (
		production_process_system.catalog
	)

	if catalog == null:
		_log("Production process catalog available: FAIL")
		return false

	var temporary_process_id := (
		"step2_4_infrastructure_output_process"
	)

	var had_original_definition: bool = catalog.processes.has(
		temporary_process_id
	)

	var original_definition: Variant = (
		catalog.processes.get(
			temporary_process_id,
			null
		)
	)

	# ------------------------------------------------------------
	# CONTROLLED TEMPORARY PROCESS
	# ------------------------------------------------------------
	#
	# The process has a single infrastructure-usage requirement.
	# No labor, capital, energy, maintenance, technology, or capability
	# requirements are introduced so infrastructure is the only changing
	# physical bottleneck in this test.
	# ------------------------------------------------------------

	catalog.processes[temporary_process_id] = {
		"name": "Step 2.4 Infrastructure Output Process",
		"category": "manufacturing",
		"production_stage": 20,
		"available_from": 1950,
		"available_until": null,
		"technology_requirements": {},
		"capability_requirements": {},
		"infrastructure_requirements": {},
		"infrastructure_usage": {
			"modern_steelworks": 1.0
		},
		"inputs": {},
		"outputs": {
			"step2_4_output": 1.0
		},
		"byproducts": {},
		"labor_requirement": 0.0,
		"labor_skill_requirement": {},
		"capital_requirement": 0.0,
		"equipment_requirement": {},
		"energy_requirement": {},
		"land_requirement": 0.0,
		"maintenance_requirement": {},
		"operating_cost": 0.0,
		"transition_cost": 0.0,
		"efficiency": 1.0,
		"duration": 1.0,
		"reliability": 1.0,
		"seasonality": {},
		"waste": {},
		"displacement": {},
		"obsolescence": 0.0
	}

	industry.set_state(
		"processes",
		{
			temporary_process_id: {
				"active": true,
				"capacity": 100.0,
				"efficiency": 1.0
			}
		}
	)

	industry.set_state(
		"process_adoption",
		{
			temporary_process_id: 1.0
		}
	)

	# The InfrastructureSystem syncs capacity entries for resource names.
	# Add both the infrastructure requirement and the test output resource
	# to the generic resource production map so the registered bridge
	# exposes infrastructure capacity to ProductionProcessSystem.
	resources.set_state(
		"production",
		{
			"modern_steelworks": 0.0,
			"step2_4_output": 0.0
		}
	)

	resources.set_state(
		"stockpile",
		{
			"step2_4_output": 0.0
		}
	)

	# ------------------------------------------------------------
	# TEST 1 — FULL INFRASTRUCTURE
	# ------------------------------------------------------------

	for infrastructure_name in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage"
	]:
		infrastructure.set_state(
			infrastructure_name,
			1.0
		)

	infrastructure_system.process_month(
		world
	)

	var full_resource_capacity: Dictionary = (
		resources.get_state(
			"infrastructure_capacity",
			{}
		)
	)

	var full_infrastructure_factor: float = float(
		full_resource_capacity.get(
			"modern_steelworks",
			0.0
		)
	)

	production_process_system.process_month(
		world
	)

	var full_outcome: Dictionary = (
		industry.get_production_outcome(
			temporary_process_id
		)
	)

	var full_output: float = float(
		full_outcome.get(
			"actual_production",
			0.0
		)
	)

	var full_pass: bool = (
		is_equal_approx(
			full_infrastructure_factor,
			1.0
		)
		and is_equal_approx(
			full_output,
			100.0
		)
	)

	_log(
		"Full infrastructure preserves physical output: "
		+ _pass_fail(full_pass)
		+ " | infrastructure_capacity=1.0 actual="
		+ str(full_infrastructure_factor)
		+ " | output=100.0 actual="
		+ str(full_output)
	)

	all_passed = all_passed and full_pass

	# ------------------------------------------------------------
	# TEST 2 — INFRASTRUCTURE REDUCTION
	# ------------------------------------------------------------

	for infrastructure_name in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage"
	]:
		infrastructure.set_state(
			infrastructure_name,
			0.5
		)

	infrastructure_system.process_month(
		world
	)

	var constrained_resource_capacity: Dictionary = (
		resources.get_state(
			"infrastructure_capacity",
			{}
		)
	)

	var constrained_infrastructure_factor: float = float(
		constrained_resource_capacity.get(
			"modern_steelworks",
			0.0
		)
	)

	production_process_system.process_month(
		world
	)

	var constrained_outcome: Dictionary = (
		industry.get_production_outcome(
			temporary_process_id
		)
	)

	var constrained_output: float = float(
		constrained_outcome.get(
			"actual_production",
			0.0
		)
	)

	var constrained_pass: bool = (
		is_equal_approx(
			constrained_infrastructure_factor,
			0.5
		)
		and is_equal_approx(
			constrained_output,
			50.0
		)
	)

	_log(
		"Infrastructure reduction lowers physical output: "
		+ _pass_fail(constrained_pass)
		+ " | infrastructure_capacity=0.5 actual="
		+ str(constrained_infrastructure_factor)
		+ " | output=50.0 actual="
		+ str(constrained_output)
	)

	all_passed = all_passed and constrained_pass

	# ------------------------------------------------------------
	# TEST 3 — RECOVERY
	# ------------------------------------------------------------

	for infrastructure_name in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage"
	]:
		infrastructure.set_state(
			infrastructure_name,
			1.0
		)

	infrastructure_system.process_month(
		world
	)

	production_process_system.process_month(
		world
	)

	var recovery_outcome: Dictionary = (
		industry.get_production_outcome(
			temporary_process_id
		)
	)

	var recovery_output: float = float(
		recovery_outcome.get(
			"actual_production",
			0.0
		)
	)

	var recovery_pass := is_equal_approx(
		recovery_output,
		100.0
	)

	_log(
		"Infrastructure recovery restores physical output: "
		+ _pass_fail(recovery_pass)
		+ " | output=100.0 actual="
		+ str(recovery_output)
	)

	all_passed = all_passed and recovery_pass

	# ------------------------------------------------------------
	# RESTORE ALL STATE
	# ------------------------------------------------------------

	infrastructure.state.clear()

	for key in original_infrastructure_state.keys():
		infrastructure.state[key] = (
			original_infrastructure_state[key]
		)

	resources.set_state(
		"production",
		original_resource_production
	)

	resources.set_state(
		"stockpile",
		original_resource_stockpile
	)

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

	if had_original_definition:
		catalog.processes[temporary_process_id] = (
			original_definition
		)
	else:
		catalog.processes.erase(
			temporary_process_id
		)

	_log(
		"Integrated Physical Economy — Infrastructure -> Physical Output test passed: "
		+ str(all_passed)
	)

	return all_passed
