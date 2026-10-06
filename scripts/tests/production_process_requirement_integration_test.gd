class_name ProductionProcessRequirementIntegrationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS REQUIREMENT INTEGRATION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	var india: SimEntity = world.get_entity("india") as SimEntity

	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false

	TestLogger.write_line("India available: PASS")

	var resources: ResourceComponent = india.get_component("resources") as ResourceComponent
	var industry: IndustryComponent = india.get_component("industry") as IndustryComponent
	var technology_adoption: TechnologyAdoptionComponent = india.get_component("technology_adoption") as TechnologyAdoptionComponent
	var infrastructure: SimComponent = india.get_component("infrastructure") as SimComponent

	if resources == null:
		TestLogger.write_line("India resource component: FAIL")
		return false

	if industry == null:
		TestLogger.write_line("India industry component: FAIL")
		return false

	if technology_adoption == null:
		TestLogger.write_line("Technology adoption component: FAIL")
		return false

	if infrastructure == null:
		TestLogger.write_line("India infrastructure component: FAIL")
		return false

	TestLogger.write_line("India resource component: PASS")
	TestLogger.write_line("India industry component: PASS")
	TestLogger.write_line("Technology adoption component: PASS")

	var original_stockpile: Dictionary = resources.get_state("stockpile", {}).duplicate(true)
	var original_processes: Dictionary = industry.get_state("processes", {}).duplicate(true)
	var original_adoption: Dictionary = technology_adoption.get_state("adoption", {}).duplicate(true)
	var original_capabilities_value: Variant = india.get_sim_metadata(
		"capabilities",
		null
	)
	var original_capabilities: Dictionary = {}
	if typeof(original_capabilities_value) == TYPE_DICTIONARY:
		original_capabilities = original_capabilities_value.duplicate(true)
	var original_infrastructure: Dictionary = resources.get_state("infrastructure_capacity", {}).duplicate(true)
	var original_process_maintenance_capacity: Dictionary = infrastructure.get_state(
		"process_maintenance_capacity",
		{}
	).duplicate(true)

	var original_date: Variant = world.get("date")
	var saved_year: Variant = null
	var saved_month: Variant = null
	var saved_day: Variant = null

	if typeof(original_date) == TYPE_OBJECT:
		if "year" in original_date:
			saved_year = original_date.year
		if "month" in original_date:
			saved_month = original_date.month
		if "day" in original_date:
			saved_day = original_date.day
	elif typeof(original_date) == TYPE_DICTIONARY:
		original_date = original_date.duplicate(true)

	var processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process: Variant = original_processes[process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue
		processes[str(process_id)] = original_process.duplicate(true)
		processes[str(process_id)]["active"] = false

	processes["advanced_steel_production"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	industry.set_state("processes", processes)

	if typeof(original_date) == TYPE_OBJECT:
		if "year" in original_date:
			original_date.year = 1955
		if "month" in original_date:
			original_date.month = 1
		if "day" in original_date:
			original_date.day = 1
	elif typeof(original_date) == TYPE_DICTIONARY:
		original_date["year"] = 1955
		original_date["month"] = 1
		original_date["day"] = 1
		world.set("date", original_date)

	var stockpile: Dictionary = original_stockpile.duplicate(true)
	stockpile["iron"] = 100.0
	stockpile["coal"] = 100.0
	stockpile["steel"] = 0.0

	resources.set_state("stockpile", stockpile)
	technology_adoption.set_state("adoption", {})
	india.set_sim_metadata("capabilities", {})
	resources.set_state("infrastructure_capacity", {})
	infrastructure.set_state(
		"process_maintenance_capacity",
		{}
	)

	var production_process_system: ProductionProcessSystem = ProductionProcessSystem.new()
	var original_advanced_catalog_exists: bool = production_process_system.catalog.processes.has(
		"advanced_steel_production"
	)
	var original_advanced_catalog_definition: Dictionary = {}
	if original_advanced_catalog_exists:
		var original_advanced_catalog_value: Variant = production_process_system.catalog.processes.get(
			"advanced_steel_production",
			{}
		)
		if typeof(original_advanced_catalog_value) == TYPE_DICTIONARY:
			original_advanced_catalog_definition = original_advanced_catalog_value.duplicate(true)

	# This test is specifically isolating technology, capability,
	# infrastructure, and equipment requirements. The separate physical
	# capacity gates are neutralized so they do not mask those requirement tests.
	var controlled_advanced_catalog_definition: Dictionary = (
		original_advanced_catalog_definition.duplicate(true)
	)

	controlled_advanced_catalog_definition["labor_requirement"] = 0.0
	controlled_advanced_catalog_definition["labor_skill_requirement"] = 0.0
	controlled_advanced_catalog_definition["capital_requirement"] = 0.0
	controlled_advanced_catalog_definition["power_requirement"] = 0.0

	production_process_system.catalog.processes[
		"advanced_steel_production"
	] = controlled_advanced_catalog_definition

	# TEST 1 — ALL REQUIREMENTS MISSING
	production_process_system.process_month(world)

	var steel_1: float = float(
		resources.get_state("stockpile", {}).get("steel", 0.0)
	)

	var missing_requirements_block_passed: bool = is_equal_approx(steel_1, 0.0)

	TestLogger.write_line(
		"All requirements missing blocks production: "
		+ ("PASS" if missing_requirements_block_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(steel_1)
	)

	# TEST 2 — TECHNOLOGY ONLY
	technology_adoption.set_adoption("advanced_steelmaking", 1.0)
	resources.set_state("stockpile", stockpile.duplicate(true))
	production_process_system.process_month(world)

	var steel_2: float = float(
		resources.get_state("stockpile", {}).get("steel", 0.0)
	)

	var technology_only_block_passed: bool = is_equal_approx(steel_2, 0.0)

	TestLogger.write_line(
		"Technology alone remains blocked: "
		+ ("PASS" if technology_only_block_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(steel_2)
	)

	# TEST 3 — TECHNOLOGY + CAPABILITY
	india.set_sim_metadata(
		"capabilities",
		{
			"advanced_metallurgy": 0.5
		}
	)

	resources.set_state("stockpile", stockpile.duplicate(true))
	production_process_system.process_month(world)

	var steel_3: float = float(
		resources.get_state("stockpile", {}).get("steel", 0.0)
	)

	var infrastructure_block_passed: bool = is_equal_approx(steel_3, 0.0)

	TestLogger.write_line(
		"Technology + capability remain blocked: "
		+ ("PASS" if infrastructure_block_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(steel_3)
	)

	# TEST 4 — TECHNOLOGY + CAPABILITY + INFRASTRUCTURE, NO EQUIPMENT
	resources.set_state(
		"infrastructure_capacity",
		{
			"modern_steelworks": 1.0
		}
	)

	resources.set_state("stockpile", stockpile.duplicate(true))
	production_process_system.process_month(world)

	var steel_4: float = float(
		resources.get_state("stockpile", {}).get("steel", 0.0)
	)

	var equipment_block_passed: bool = is_equal_approx(steel_4, 0.0)

	TestLogger.write_line(
		"Technology + capability + infrastructure without equipment remain blocked: "
		+ ("PASS" if equipment_block_passed else "FAIL")
		+ " | expected=0.0 actual=" + str(steel_4)
	)

	# TEST 5 — ALL REQUIREMENTS SATISFIED
	india.set_sim_metadata(
		"capabilities",
		{
			"advanced_metallurgy": 0.5,
			"advanced_steel_equipment": 1.0
		}
	)

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)

	resources.set_state(
		"infrastructure_capacity",
		{
			"modern_steelworks": 1.0
		}
	)

	resources.set_state("stockpile", stockpile.duplicate(true))
	production_process_system.process_month(world)

	var steel_5: float = float(
		resources.get_state("stockpile", {}).get("steel", 0.0)
	)

	var expected_production: float = 10.0 * 1.10
	var all_requirements_passed: bool = is_equal_approx(
		steel_5,
		expected_production
	)

	TestLogger.write_line(
		"All requirements satisfied allow production: "
		+ ("PASS" if all_requirements_passed else "FAIL")
		+ " | expected=" + str(expected_production)
		+ " actual=" + str(steel_5)
	)

	if original_advanced_catalog_exists:
		production_process_system.catalog.processes[
			"advanced_steel_production"
		] = original_advanced_catalog_definition
	else:
		production_process_system.catalog.processes.erase(
			"advanced_steel_production"
		)

	resources.set_state("stockpile", original_stockpile)
	resources.set_state("infrastructure_capacity", original_infrastructure)
	industry.set_state("processes", original_processes)
	technology_adoption.set_state("adoption", original_adoption)
	india.set_sim_metadata("capabilities", original_capabilities)
	infrastructure.set_state(
		"process_maintenance_capacity",
		original_process_maintenance_capacity
	)

	if typeof(original_date) == TYPE_OBJECT:
		if saved_year != null and "year" in original_date:
			original_date.year = saved_year
		if saved_month != null and "month" in original_date:
			original_date.month = saved_month
		if saved_day != null and "day" in original_date:
			original_date.day = saved_day
	elif typeof(original_date) == TYPE_DICTIONARY:
		world.set("date", original_date)

	var passed: bool = (
		missing_requirements_block_passed
		and technology_only_block_passed
		and infrastructure_block_passed
		and equipment_block_passed
		and all_requirements_passed
	)

	TestLogger.section(
		"PRODUCTION PROCESS REQUIREMENT INTEGRATION RESULT"
	)

	TestLogger.write_line(
		"Missing requirements block production: "
		+ ("PASS" if missing_requirements_block_passed else "FAIL")
	)
	TestLogger.write_line(
		"Technology-only state remains blocked: "
		+ ("PASS" if technology_only_block_passed else "FAIL")
	)
	TestLogger.write_line(
		"Technology + capability remain blocked: "
		+ ("PASS" if infrastructure_block_passed else "FAIL")
	)
	TestLogger.write_line(
		"Equipment requirement blocks production: "
		+ ("PASS" if equipment_block_passed else "FAIL")
	)
	TestLogger.write_line(
		"All requirements allow production: "
		+ ("PASS" if all_requirements_passed else "FAIL")
	)
	TestLogger.write_line(
		"ProductionProcessRequirementIntegrationTest: " + str(passed)
	)

	return passed
