class_name ResourceSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"RESOURCE SYSTEM TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	var country = world.get_entity("india")

	if country == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var resources = country.get_component(
		"resources"
	)

	if resources == null:
		TestLogger.write_line(
			"India resource component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India resource component: PASS"
	)

	var production = resources.get_state(
		"production",
		{}
	)

	var test_resource = "coal"

	if not production.has(test_resource):
		TestLogger.write_line(
			"Coal production available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Coal production available: PASS"
	)


	# ============================================================
	# SAVE ORIGINAL STATE
	# ============================================================

	var original_production = resources.get_state(
		"production",
		{}
	).duplicate(true)

	var original_consumption = resources.get_state(
		"consumption",
		{}
	).duplicate(true)

	var original_imports = resources.get_state(
		"imports",
		{}
	).duplicate(true)

	var original_exports = resources.get_state(
		"exports",
		{}
	).duplicate(true)

	var original_extraction = resources.get_state(
		"extraction_capacity",
		{}
	).duplicate(true)

	var original_processing = resources.get_state(
		"processing_capacity",
		{}
	).duplicate(true)

	var original_production_efficiency = resources.get_state(
		"production_efficiency",
		{}
	).duplicate(true)

	var original_technology_efficiency = resources.get_state(
		"technology_efficiency",
		{}
	).duplicate(true)

	var original_infrastructure_capacity = resources.get_state(
		"infrastructure_capacity",
		{}
	).duplicate(true)

	var original_quality = resources.get_state(
		"quality",
		{}
	).duplicate(true)

	var original_accessibility = resources.get_state(
		"accessibility",
		{}
	).duplicate(true)

	var infrastructure_component = country.get_component(
		"infrastructure"
	)

	if infrastructure_component == null:
		TestLogger.write_line(
			"India infrastructure component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India infrastructure component: PASS"
	)

	var original_specialized_infrastructure = infrastructure_component.get_state(
		"transport",
		0.0
	)

	var original_roads_infrastructure = infrastructure_component.get_state(
		"roads",
		0.0
	)

	var original_railways_infrastructure = infrastructure_component.get_state(
		"railways",
		0.0
	)

	var original_ports_infrastructure = infrastructure_component.get_state(
		"ports",
		0.0
	)

	var original_power_infrastructure = infrastructure_component.get_state(
		"power",
		0.0
	)

	# ResourceSystem incorporates specialized transport, power, roads and railways
	# into production. Neutralize these infrastructure values so each test
	# section isolates the mechanism it is testing.
	infrastructure_component.set_state(
		"transport",
		1.0
	)

	infrastructure_component.set_state(
		"roads",
		1.0
	)

	infrastructure_component.set_state(
		"railways",
		1.0
	)

	infrastructure_component.set_state(
		"ports",
		1.0
	)

	infrastructure_component.set_state(
		"power",
		1.0
	)

	var original_actual_production = resources.get_state(
		"actual_production",
		{}
	).duplicate(true)

	var original_reserves = resources.get_state(
		"reserves",
		{}
	).duplicate(true)

	var original_stockpile = resources.get_state(
		"stockpile",
		{}
	).duplicate(true)

	var original_net_balance = resources.get_state(
		"net_balance",
		{}
	).duplicate(true)

	var original_shortages = resources.get_state(
		"shortages",
		{}
	).duplicate(true)

	var original_shortage_ratio = resources.get_state(
		"shortage_ratio",
		{}
	).duplicate(true)

	var original_reserve_depletion = resources.get_state(
		"reserve_depletion",
		{}
	).duplicate(true)

	var original_surplus = resources.get_state(
		"surplus",
		{}
	).duplicate(true)

	var original_reserve_ratio = resources.get_state(
		"reserve_ratio",
		{}
	).duplicate(true)

	var original_max_stockpile_capacity = resources.get_state(
		"max_stockpile_capacity",
		{}
	).duplicate(true)

	var original_storage_overflow = resources.get_state(
		"storage_overflow",
		{}
	).duplicate(true)


	var requested_production = float(
		production.get(
			test_resource,
			0.0
		)
	)

	var resource_system = ResourceSystem.new()

	var all_passed := true
	var full_lifecycle_pass := false


	# ============================================================
	# COMMON TEST CONFIGURATION
	# ============================================================

	var extraction_capacity = (
		original_extraction.duplicate(true)
	)

	var processing_capacity = (
		original_processing.duplicate(true)
	)

	var production_efficiency = (
		original_production_efficiency.duplicate(true)
	)

	var technology_efficiency = (
		original_technology_efficiency.duplicate(true)
	)

	var infrastructure_capacity = (
		original_infrastructure_capacity.duplicate(true)
	)

	var quality = (
		original_quality.duplicate(true)
	)

	var accessibility = (
		original_accessibility.duplicate(true)
	)


	extraction_capacity[test_resource] = (
		requested_production
	)

	processing_capacity[test_resource] = (
		requested_production
	)

	production_efficiency[test_resource] = 1.0
	technology_efficiency[test_resource] = 1.0
	infrastructure_capacity[test_resource] = 1.0
	quality[test_resource] = 1.0
	accessibility[test_resource] = 1.0


	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resources.set_state(
		"production_efficiency",
		production_efficiency
	)

	resources.set_state(
		"technology_efficiency",
		technology_efficiency
	)

	resources.set_state(
		"infrastructure_capacity",
		infrastructure_capacity
	)

	resources.set_state(
		"quality",
		quality
	)

	resources.set_state(
		"accessibility",
		accessibility
	)


	# ============================================================
	# 1. CAPACITY INITIALIZATION
	# ============================================================

	TestLogger.section(
		"1. CAPACITY INITIALIZATION"
	)

	extraction_capacity.clear()
	processing_capacity.clear()

	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resource_system.process_month(
		world
	)

	var initialized_extraction = resources.get_state(
		"extraction_capacity",
		{}
	)

	var initialized_processing = resources.get_state(
		"processing_capacity",
		{}
	)

	var extraction_initialized = is_equal_approx(
		float(
			initialized_extraction.get(
				test_resource,
				-1.0
			)
		),
		requested_production
	)

	var processing_initialized = is_equal_approx(
		float(
			initialized_processing.get(
				test_resource,
				-1.0
			)
		),
		requested_production
	)

	var capacity_initialization_pass = (
		extraction_initialized
		and processing_initialized
	)

	TestLogger.write_line(
		"Extraction capacity initialization: "
		+ (
			"PASS"
			if extraction_initialized
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Processing capacity initialization: "
		+ (
			"PASS"
			if processing_initialized
			else "FAIL"
		)
	)

	if not capacity_initialization_pass:
		all_passed = false


	# ============================================================
	# 2. EXTRACTION CONSTRAINT
	# ============================================================

	TestLogger.section(
		"2. EXTRACTION CONSTRAINT"
	)

	extraction_capacity[test_resource] = 10.0
	processing_capacity[test_resource] = 20.0

	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resource_system.process_month(
		world
	)

	var actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_extraction = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var extraction_constraint_pass = is_equal_approx(
		actual_extraction,
		min(
			requested_production,
			10.0
		)
	)

	TestLogger.write_line(
		"Extraction bottleneck: "
		+ (
			"PASS"
			if extraction_constraint_pass
			else "FAIL"
		)
		+ " | actual="
		+ str(actual_extraction)
	)

	if not extraction_constraint_pass:
		all_passed = false


	# ============================================================
	# 3. PROCESSING CONSTRAINT
	# ============================================================

	TestLogger.section(
		"3. PROCESSING CONSTRAINT"
	)

	extraction_capacity[test_resource] = 20.0
	processing_capacity[test_resource] = 8.0

	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resource_system.process_month(
		world
	)

	actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_processing = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var processing_constraint_pass = is_equal_approx(
		actual_processing,
		min(
			requested_production,
			8.0
		)
	)

	TestLogger.write_line(
		"Processing bottleneck: "
		+ (
			"PASS"
			if processing_constraint_pass
			else "FAIL"
		)
		+ " | actual="
		+ str(actual_processing)
	)

	if not processing_constraint_pass:
		all_passed = false


	# ============================================================
	# 4. MINIMUM CAPACITY
	# ============================================================

	TestLogger.section(
		"4. MINIMUM CAPACITY"
	)

	extraction_capacity[test_resource] = 6.0
	processing_capacity[test_resource] = 8.0

	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resource_system.process_month(
		world
	)

	actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_minimum = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var minimum_capacity_pass = is_equal_approx(
		actual_minimum,
		min(
			requested_production,
			6.0,
			8.0
		)
	)

	TestLogger.write_line(
		"Minimum capacity constraint: "
		+ (
			"PASS"
			if minimum_capacity_pass
			else "FAIL"
		)
		+ " | actual="
		+ str(actual_minimum)
	)

	if not minimum_capacity_pass:
		all_passed = false


	# ============================================================
	# 5. PRODUCTION EFFICIENCY
	# ============================================================

	TestLogger.section(
		"5. PRODUCTION EFFICIENCY"
	)

	extraction_capacity[test_resource] = (
		requested_production
	)

	processing_capacity[test_resource] = (
		requested_production
	)

	production_efficiency[test_resource] = 0.50

	resources.set_state(
		"extraction_capacity",
		extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		processing_capacity
	)

	resources.set_state(
		"production_efficiency",
		production_efficiency
	)

	resource_system.process_month(
		world
	)

	actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_efficiency = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var efficiency_pass = is_equal_approx(
		actual_efficiency,
		requested_production * 0.50
	)

	TestLogger.write_line(
		"50% production efficiency: "
		+ (
			"PASS"
			if efficiency_pass
			else "FAIL"
		)
		+ " | actual="
		+ str(actual_efficiency)
	)

	if not efficiency_pass:
		all_passed = false


	# ============================================================
	# 6. TECHNOLOGY EFFICIENCY
	# ============================================================

	TestLogger.section(
		"6. TECHNOLOGY EFFICIENCY"
	)

	production_efficiency[test_resource] = 1.0
	technology_efficiency[test_resource] = 0.50

	resources.set_state(
		"production_efficiency",
		production_efficiency
	)

	resources.set_state(
		"technology_efficiency",
		technology_efficiency
	)

	resource_system.process_month(
		world
	)

	actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_technology = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var technology_pass = is_equal_approx(
		actual_technology,
		requested_production * 0.50
	)

	TestLogger.write_line(
		"50% technology efficiency: "
		+ (
			"PASS"
			if technology_pass
			else "FAIL"
		)
		+ " | actual="
		+ str(actual_technology)
	)

	if not technology_pass:
		all_passed = false
		
		
		
		
	# ============================================================
	# 7. INFRASTRUCTURE CAPACITY
	# ============================================================

	TestLogger.section(
	"7. INFRASTRUCTURE CAPACITY"
)

	production_efficiency[test_resource] = 1.0
	technology_efficiency[test_resource] = 1.0
	infrastructure_capacity[test_resource] = 0.50

	resources.set_state(
	"production_efficiency",
	production_efficiency
)

	resources.set_state(
	"technology_efficiency",
	technology_efficiency
)

	resources.set_state(
	"infrastructure_capacity",
	infrastructure_capacity
)

	resource_system.process_month(
	world
)

	actual_production = resources.get_state(
	"actual_production",
	{}
)
	
	var actual_infrastructure = float(
	actual_production.get(
		test_resource,
		-1.0
	)
)

	var expected_infrastructure = (
	requested_production * 0.50
)

	var infrastructure_pass = is_equal_approx(
	actual_infrastructure,
	expected_infrastructure
)

	TestLogger.write_line(
	"50% infrastructure capacity: "
	+ (
		"PASS"
		if infrastructure_pass
		else "FAIL"
	)
	+ " | expected="
	+ str(expected_infrastructure)
	+ " actual="
	+ str(actual_infrastructure)
)

	if not infrastructure_pass:
		all_passed = false
		
		
	# ============================================================
	# 8. QUALITY
	# ============================================================

	TestLogger.section(
	"8. RESOURCE QUALITY"
)

	production_efficiency[test_resource] = 1.0
	technology_efficiency[test_resource] = 1.0
	infrastructure_capacity[test_resource] = 1.0
	accessibility[test_resource] = 1.0
	quality[test_resource] = 0.50

	resources.set_state(
	"production_efficiency",
	production_efficiency
)

	resources.set_state(
	"technology_efficiency",
	technology_efficiency
)

	resources.set_state(
	"infrastructure_capacity",
	infrastructure_capacity
)

	resources.set_state(
	"accessibility",
	accessibility
)

	resources.set_state(
	"quality",
	quality
)

	resource_system.process_month(
	world
)

	actual_production = resources.get_state(
	"actual_production",
	{}
)

	var actual_quality = float(
	actual_production.get(
		test_resource,
		-1.0
	)
)

	var expected_quality = (
	requested_production * 0.50
)

	var quality_pass = is_equal_approx(
	actual_quality,
	expected_quality
)

	TestLogger.write_line(
	"50% resource quality: "
	+ (
		"PASS"
		if quality_pass
		else "FAIL"
	)
	+ " | expected="
	+ str(expected_quality)
	+ " actual="
	+ str(actual_quality)
)

	if not quality_pass:
		all_passed = false


	# ============================================================
	# 9. ACCESSIBILITY
	# ============================================================

	TestLogger.section(
	"9. RESOURCE ACCESSIBILITY"
)

	quality[test_resource] = 1.0
	accessibility[test_resource] = 0.50

	resources.set_state(
	"quality",
	quality
)

	resources.set_state(
	"accessibility",
	accessibility
)

	resource_system.process_month(
	world
)

	actual_production = resources.get_state(
	"actual_production",
	{}
)

	var actual_accessibility = float(
	actual_production.get(
		test_resource,
		-1.0
	)
)

	var expected_accessibility = (
	requested_production * 0.50
)

	var accessibility_pass = is_equal_approx(
	actual_accessibility,
	expected_accessibility
)

	TestLogger.write_line(
	"50% resource accessibility: "
	+ (
		"PASS"
		if accessibility_pass
		else "FAIL"
	)
	+ " | expected="
	+ str(expected_accessibility)
	+ " actual="
	+ str(actual_accessibility)
)

	if not accessibility_pass:
		all_passed = false
		
		
	# ============================================================
	# 10. RESERVES VS STOCKPILE
	# ============================================================

	TestLogger.section(
	"10. RESERVES VS STOCKPILE"
)

	# Save a separate working copy for the resource-flow cases. The original
	# dictionaries were captured near the start of the test and are restored
	# again at the end so later test cases cannot inherit mutated flow state.

	var test_reserves = resources.get_state(
	"reserves",
	{}
).duplicate(true)

	var test_stockpile = resources.get_state(
	"stockpile",
	{}
).duplicate(true)

	var consumption = original_consumption.duplicate(true)
	var imports = original_imports.duplicate(true)
	var exports = original_exports.duplicate(true)

	consumption[test_resource] = 0.0
	imports[test_resource] = 0.0
	exports[test_resource] = 0.0

	resources.set_state(
	"consumption",
	consumption
)

	resources.set_state(
	"imports",
	imports
)

	resources.set_state(
	"exports",
	exports
)

	extraction_capacity[test_resource] = 20.0
	processing_capacity[test_resource] = 20.0

	production_efficiency[test_resource] = 1.0
	technology_efficiency[test_resource] = 1.0
	infrastructure_capacity[test_resource] = 1.0
	quality[test_resource] = 1.0
	accessibility[test_resource] = 1.0

	resources.set_state(
	"extraction_capacity",
	extraction_capacity
)

	resources.set_state(
	"processing_capacity",
	processing_capacity
)

	resources.set_state(
	"production_efficiency",
	production_efficiency
)

	resources.set_state(
	"technology_efficiency",
	technology_efficiency
)

	resources.set_state(
	"infrastructure_capacity",
	infrastructure_capacity
)

	resources.set_state(
	"quality",
	quality
)

	resources.set_state(
	"accessibility",
	accessibility
)


	# ============================================================
	# CASE 1 — RESERVES LIMIT PRODUCTION
	# ============================================================

	test_reserves[test_resource] = 5.0
	test_stockpile[test_resource] = 100.0

	resources.set_state(
	"reserves",
	test_reserves
)

	resources.set_state(
	"stockpile",
	test_stockpile
)
	
	resource_system.process_month(
	world
)

	actual_production = resources.get_state(
	"actual_production",
	{}
)

	var actual_reserve_limited_production = float(
	actual_production.get(
		test_resource,
		-1.0
	)
)

	var expected_reserve_limited_production = 5.0

	var reserve_limit_pass = is_equal_approx(
	actual_reserve_limited_production,
	expected_reserve_limited_production
)

	TestLogger.write_line(
	"Low reserves limit production: "
	+ (
		"PASS"
		if reserve_limit_pass
		else "FAIL"
	)
	+ " | expected="
	+ str(expected_reserve_limited_production)
	+ " actual="
	+ str(actual_reserve_limited_production)
)


	var actual_remaining_reserves = float(
	resources.get_state(
		"reserves",
		{}
	).get(
		test_resource,
		-1.0
	)
)

	var reserve_depleted_pass = is_equal_approx(
	actual_remaining_reserves,
	0.0
)

	TestLogger.write_line(
	"Produced amount removed from reserves: "
	+ (
		"PASS"
		if reserve_depleted_pass
		else "FAIL"
	)
	+ " | expected=0.0 actual="
	+ str(actual_remaining_reserves)
)


	var actual_stockpile_after_production = float(
	resources.get_state(
		"stockpile",
		{}
	).get(
		test_resource,
		-1.0
	)
)
	
	var stockpile_increase_pass = is_equal_approx(
	actual_stockpile_after_production,
	105.0
)

	TestLogger.write_line(
	"Stockpile receives produced resource: "
	+ (
		"PASS"
		if stockpile_increase_pass
		else "FAIL"
	)
	+ " | expected=105.0 actual="
	+ str(actual_stockpile_after_production)
)


	# ============================================================
	# CASE 2 — STOCKPILE DOES NOT COUNT AS RESERVES
	# ============================================================

	TestLogger.section(
	"CASE 2 — STOCKPILE / RESERVE SEPARATION"
)

	test_reserves[test_resource] = 100.0
	test_stockpile[test_resource] = 5.0

	resources.set_state(
	"reserves",
	test_reserves
)

	resources.set_state(
	"stockpile",
	test_stockpile
)

	resource_system.process_month(
	world
)

	actual_production = resources.get_state(
	"actual_production",
	{}
)

	var actual_separation_production = float(
	actual_production.get(
		test_resource,
		-1.0
	)
)

	var expected_separation_production = 20.0

	var separation_production_pass = is_equal_approx(
	actual_separation_production,
	expected_separation_production
)

	TestLogger.write_line(
	"Production uses reserves, not stockpile: "
	+ (
		"PASS"
		if separation_production_pass
		else "FAIL"
	)
	+ " | expected="
	+ str(expected_separation_production)
	+ " actual="
	+ str(actual_separation_production)
)


	# ============================================================
	# RESTORE RESOURCE FLOW STATE
	# ============================================================

	resources.set_state(
	"consumption",
	original_consumption
)

	resources.set_state(
	"imports",
	original_imports
)

	resources.set_state(
	"exports",
	original_exports
)

	TestLogger.write_line(
	"Original resource flow state restored: PASS"
)


	var reserves_stockpile_pass = (
	reserve_limit_pass
	and reserve_depleted_pass
	and stockpile_increase_pass
	and separation_production_pass
)

	if not reserves_stockpile_pass:
		all_passed = false


	# ============================================================
	# 11. INTEGRATED ACTUAL PRODUCTION
	# ============================================================

	TestLogger.section(
		"11. INTEGRATED ACTUAL PRODUCTION"
	)

	# capacity limit = min(20, 18, 16) = 16
	# actual production = 16 * 0.80 * 0.75 = 9.6

	extraction_capacity[test_resource] = 18.0
	processing_capacity[test_resource] = 16.0
	production_efficiency[test_resource] = 0.80
	technology_efficiency[test_resource] = 0.75
	infrastructure_capacity[test_resource] = 1.0
	quality[test_resource] = 1.0
	accessibility[test_resource] = 1.0

	resources.set_state("extraction_capacity", extraction_capacity)
	resources.set_state("processing_capacity", processing_capacity)
	resources.set_state("production_efficiency", production_efficiency)
	resources.set_state("technology_efficiency", technology_efficiency)
	resources.set_state("infrastructure_capacity", infrastructure_capacity)
	resources.set_state("quality", quality)
	resources.set_state("accessibility", accessibility)

	resource_system.process_month(world)

	actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_integrated_production = float(
		actual_production.get(
			test_resource,
			-1.0
		)
	)

	var expected_integrated_production = 9.6

	var integrated_production_pass = is_equal_approx(
		actual_integrated_production,
		expected_integrated_production
	)

	TestLogger.write_line(
		"Integrated production calculation: "
		+ (
			"PASS"
			if integrated_production_pass
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_integrated_production)
		+ " actual="
		+ str(actual_integrated_production)
	)

	if not integrated_production_pass:
		all_passed = false


	# ============================================================
	# 12. SUPPLY / SHORTAGE CALCULATION
	# ============================================================

	TestLogger.section(
		"12. SUPPLY / SHORTAGE CALCULATION"
	)

	# Use local dictionaries for this section so the test is independent
	# of the scope used by the reserves / stockpile test above.
	var supply_extraction_capacity = resources.get_state(
		"extraction_capacity",
		{}
	).duplicate(true)

	var supply_processing_capacity = resources.get_state(
		"processing_capacity",
		{}
	).duplicate(true)

	var supply_production_efficiency = resources.get_state(
		"production_efficiency",
		{}
	).duplicate(true)

	var supply_technology_efficiency = resources.get_state(
		"technology_efficiency",
		{}
	).duplicate(true)

	var supply_infrastructure_capacity = resources.get_state(
		"infrastructure_capacity",
		{}
	).duplicate(true)

	var supply_quality = resources.get_state(
		"quality",
		{}
	).duplicate(true)

	var supply_accessibility = resources.get_state(
		"accessibility",
		{}
	).duplicate(true)

	var supply_reserves = resources.get_state(
		"reserves",
		{}
	).duplicate(true)

	var supply_stockpile = resources.get_state(
		"stockpile",
		{}
	).duplicate(true)

	var supply_consumption = resources.get_state(
		"consumption",
		{}
	).duplicate(true)

	var supply_imports = resources.get_state(
		"imports",
		{}
	).duplicate(true)

	var supply_exports = resources.get_state(
		"exports",
		{}
	).duplicate(true)

	# CASE 1: supply covers demand
	# production=10, stockpile=5, imports=2
	# available supply=17
	# consumption=10, exports=2
	# total demand=12
	# expected stockpile=5, shortage=0

	supply_extraction_capacity[test_resource] = 10.0
	supply_processing_capacity[test_resource] = 10.0
	supply_production_efficiency[test_resource] = 1.0
	supply_technology_efficiency[test_resource] = 1.0
	supply_infrastructure_capacity[test_resource] = 1.0
	supply_quality[test_resource] = 1.0
	supply_accessibility[test_resource] = 1.0
	supply_reserves[test_resource] = 100.0
	supply_stockpile[test_resource] = 5.0
	supply_consumption[test_resource] = 10.0
	supply_imports[test_resource] = 2.0
	supply_exports[test_resource] = 2.0

	resources.set_state("extraction_capacity", supply_extraction_capacity)
	resources.set_state("processing_capacity", supply_processing_capacity)
	resources.set_state("production_efficiency", supply_production_efficiency)
	resources.set_state("technology_efficiency", supply_technology_efficiency)
	resources.set_state("infrastructure_capacity", supply_infrastructure_capacity)
	resources.set_state("quality", supply_quality)
	resources.set_state("accessibility", supply_accessibility)
	resources.set_state("reserves", supply_reserves)
	resources.set_state("stockpile", supply_stockpile)
	resources.set_state("consumption", supply_consumption)
	resources.set_state("imports", supply_imports)
	resources.set_state("exports", supply_exports)

	resource_system.process_month(world)

	supply_stockpile = resources.get_state("stockpile", {})
	var supply_shortages = resources.get_state("shortages", {})
	var supply_shortage_ratio = resources.get_state("shortage_ratio", {})

	var supply_case_stockpile = float(
		supply_stockpile.get(test_resource, -1.0)
	)

	var supply_case_shortage = float(
		supply_shortages.get(test_resource, -1.0)
	)

	var supply_case_ratio = float(
		supply_shortage_ratio.get(test_resource, -1.0)
	)

	var supply_case_stockpile_pass = is_equal_approx(
		supply_case_stockpile,
		5.0
	)

	var supply_case_shortage_pass = is_equal_approx(
		supply_case_shortage,
		0.0
	)

	var supply_case_ratio_pass = is_equal_approx(
		supply_case_ratio,
		0.0
	)

	TestLogger.write_line(
		"Supply covers demand: "
		+ (
			"PASS"
			if supply_case_stockpile_pass
			and supply_case_shortage_pass
			and supply_case_ratio_pass
			else "FAIL"
		)
		+ " | expected_stockpile=5.0 actual_stockpile="
		+ str(supply_case_stockpile)
		+ " expected_shortage=0.0 actual_shortage="
		+ str(supply_case_shortage)
	)

	# CASE 2: supply is below demand
	# production=10, stockpile=5, imports=2
	# available supply=17
	# consumption=15, exports=3
	# total demand=18
	# expected shortage=1, stockpile=0
	# expected shortage ratio=(1/18)*100 = 5.555...

	supply_reserves[test_resource] = 100.0
	supply_stockpile[test_resource] = 5.0
	supply_consumption[test_resource] = 15.0
	supply_imports[test_resource] = 2.0
	supply_exports[test_resource] = 3.0

	resources.set_state("reserves", supply_reserves)
	resources.set_state("stockpile", supply_stockpile)
	resources.set_state("consumption", supply_consumption)
	resources.set_state("imports", supply_imports)
	resources.set_state("exports", supply_exports)

	resource_system.process_month(world)

	supply_stockpile = resources.get_state("stockpile", {})
	supply_shortages = resources.get_state("shortages", {})
	supply_shortage_ratio = resources.get_state("shortage_ratio", {})

	var shortage_case_stockpile = float(
		supply_stockpile.get(test_resource, -1.0)
	)

	var shortage_case_amount = float(
		supply_shortages.get(test_resource, -1.0)
	)

	var shortage_case_ratio = float(
		supply_shortage_ratio.get(test_resource, -1.0)
	)

	var expected_shortage_ratio = (1.0 / 18.0) * 100.0

	var shortage_amount_pass = is_equal_approx(
		shortage_case_amount,
		1.0
	)

	var shortage_stockpile_pass = is_equal_approx(
		shortage_case_stockpile,
		0.0
	)

	var shortage_ratio_pass = is_equal_approx(
		shortage_case_ratio,
		expected_shortage_ratio
	)

	TestLogger.write_line(
		"Supply shortage calculation: "
		+ (
			"PASS"
			if shortage_amount_pass
			and shortage_stockpile_pass
			and shortage_ratio_pass
			else "FAIL"
		)
		+ " | expected_shortage=1.0 actual_shortage="
		+ str(shortage_case_amount)
		+ " expected_stockpile=0.0 actual_stockpile="
		+ str(shortage_case_stockpile)
	)

	var supply_shortage_pass = (
		supply_case_stockpile_pass
		and supply_case_shortage_pass
		and supply_case_ratio_pass
		and shortage_amount_pass
		and shortage_stockpile_pass
		and shortage_ratio_pass
	)

	if not supply_shortage_pass:
		all_passed = false


	# ============================================================
	# 13. SURPLUS CALCULATION
	# ============================================================

	TestLogger.section(
		"13. SURPLUS CALCULATION"
	)

	# Supply case:
	# production=10, stockpile=5, imports=2
	# available supply=17
	# consumption=10, exports=2
	# total demand=12
	# expected stockpile=5
	# expected surplus=5
	# expected shortage=0

	var surplus_extraction_capacity = resources.get_state(
		"extraction_capacity",
		{}
	).duplicate(true)

	var surplus_processing_capacity = resources.get_state(
		"processing_capacity",
		{}
	).duplicate(true)

	var surplus_production_efficiency = resources.get_state(
		"production_efficiency",
		{}
	).duplicate(true)

	var surplus_technology_efficiency = resources.get_state(
		"technology_efficiency",
		{}
	).duplicate(true)

	var surplus_infrastructure_capacity = resources.get_state(
		"infrastructure_capacity",
		{}
	).duplicate(true)

	var surplus_quality = resources.get_state(
		"quality",
		{}
	).duplicate(true)

	var surplus_accessibility = resources.get_state(
		"accessibility",
		{}
	).duplicate(true)

	var surplus_reserves = resources.get_state(
		"reserves",
		{}
	).duplicate(true)

	var surplus_stockpile = resources.get_state(
		"stockpile",
		{}
	).duplicate(true)

	var surplus_consumption = resources.get_state(
		"consumption",
		{}
	).duplicate(true)

	var surplus_imports = resources.get_state(
		"imports",
		{}
	).duplicate(true)

	var surplus_exports = resources.get_state(
		"exports",
		{}
	).duplicate(true)

	surplus_extraction_capacity[test_resource] = 10.0
	surplus_processing_capacity[test_resource] = 10.0
	surplus_production_efficiency[test_resource] = 1.0
	surplus_technology_efficiency[test_resource] = 1.0
	surplus_infrastructure_capacity[test_resource] = 1.0
	surplus_quality[test_resource] = 1.0
	surplus_accessibility[test_resource] = 1.0
	surplus_reserves[test_resource] = 100.0
	surplus_stockpile[test_resource] = 5.0
	surplus_consumption[test_resource] = 10.0
	surplus_imports[test_resource] = 2.0
	surplus_exports[test_resource] = 2.0

	resources.set_state(
		"extraction_capacity",
		surplus_extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		surplus_processing_capacity
	)

	resources.set_state(
		"production_efficiency",
		surplus_production_efficiency
	)

	resources.set_state(
		"technology_efficiency",
		surplus_technology_efficiency
	)

	resources.set_state(
		"infrastructure_capacity",
		surplus_infrastructure_capacity
	)

	resources.set_state(
		"quality",
		surplus_quality
	)

	resources.set_state(
		"accessibility",
		surplus_accessibility
	)

	resources.set_state(
		"reserves",
		surplus_reserves
	)

	resources.set_state(
		"stockpile",
		surplus_stockpile
	)

	resources.set_state(
		"consumption",
		surplus_consumption
	)

	resources.set_state(
		"imports",
		surplus_imports
	)

	resources.set_state(
		"exports",
		surplus_exports
	)

	resource_system.process_month(world)

	var surplus_result_stockpile = resources.get_state(
		"stockpile",
		{}
	)

	var surplus_result = resources.get_state(
		"surplus",
		{}
	)

	var surplus_result_shortages = resources.get_state(
		"shortages",
		{}
	)

	var actual_surplus_stockpile = float(
		surplus_result_stockpile.get(
			test_resource,
			-1.0
		)
	)

	var actual_surplus = float(
		surplus_result.get(
			test_resource,
			-1.0
		)
	)

	var actual_surplus_shortage = float(
		surplus_result_shortages.get(
			test_resource,
			-1.0
		)
	)

	var surplus_stockpile_pass = is_equal_approx(
		actual_surplus_stockpile,
		5.0
	)

	var surplus_amount_pass = is_equal_approx(
		actual_surplus,
		5.0
	)

	var surplus_shortage_pass = is_equal_approx(
		actual_surplus_shortage,
		0.0
	)

	var surplus_pass = (
		surplus_stockpile_pass
		and surplus_amount_pass
		and surplus_shortage_pass
	)

	TestLogger.write_line(
		"Surplus calculation: "
		+ (
			"PASS"
			if surplus_pass
			else "FAIL"
		)
		+ " | expected_surplus=5.0 actual_surplus="
		+ str(actual_surplus)
		+ " expected_stockpile=5.0 actual_stockpile="
		+ str(actual_surplus_stockpile)
	)

	TestLogger.write_line(
		"No shortage during surplus: "
		+ (
			"PASS"
			if surplus_shortage_pass
			else "FAIL"
		)
		+ " | expected_shortage=0.0 actual_shortage="
		+ str(actual_surplus_shortage)
	)

	if not surplus_pass:
		all_passed = false

	# ============================================================
	# 14. NET BALANCE
	# ============================================================

	TestLogger.section(
		"14. NET BALANCE"
	)

	# Case 1: positive net balance
	var balance_extraction_capacity = resources.get_state("extraction_capacity", {}).duplicate(true)
	var balance_processing_capacity = resources.get_state("processing_capacity", {}).duplicate(true)
	var balance_production_efficiency = resources.get_state("production_efficiency", {}).duplicate(true)
	var balance_technology_efficiency = resources.get_state("technology_efficiency", {}).duplicate(true)
	var balance_infrastructure_capacity = resources.get_state("infrastructure_capacity", {}).duplicate(true)
	var balance_quality = resources.get_state("quality", {}).duplicate(true)
	var balance_accessibility = resources.get_state("accessibility", {}).duplicate(true)
	var balance_reserves = resources.get_state("reserves", {}).duplicate(true)
	var balance_stockpile = resources.get_state("stockpile", {}).duplicate(true)
	var balance_consumption = resources.get_state("consumption", {}).duplicate(true)
	var balance_imports = resources.get_state("imports", {}).duplicate(true)
	var balance_exports = resources.get_state("exports", {}).duplicate(true)

	balance_extraction_capacity[test_resource] = 10.0
	balance_processing_capacity[test_resource] = 10.0
	balance_production_efficiency[test_resource] = 1.0
	balance_technology_efficiency[test_resource] = 1.0
	balance_infrastructure_capacity[test_resource] = 1.0
	balance_quality[test_resource] = 1.0
	balance_accessibility[test_resource] = 1.0
	balance_reserves[test_resource] = 100.0
	balance_stockpile[test_resource] = 0.0
	balance_consumption[test_resource] = 8.0
	balance_imports[test_resource] = 5.0
	balance_exports[test_resource] = 2.0

	resources.set_state("extraction_capacity", balance_extraction_capacity)
	resources.set_state("processing_capacity", balance_processing_capacity)
	resources.set_state("production_efficiency", balance_production_efficiency)
	resources.set_state("technology_efficiency", balance_technology_efficiency)
	resources.set_state("infrastructure_capacity", balance_infrastructure_capacity)
	resources.set_state("quality", balance_quality)
	resources.set_state("accessibility", balance_accessibility)
	resources.set_state("reserves", balance_reserves)
	resources.set_state("stockpile", balance_stockpile)
	resources.set_state("consumption", balance_consumption)
	resources.set_state("imports", balance_imports)
	resources.set_state("exports", balance_exports)

	resource_system.process_month(world)

	var positive_balance_state = resources.get_state("net_balance", {})
	var actual_positive_balance = float(positive_balance_state.get(test_resource, -999.0))
	var positive_balance_pass = is_equal_approx(actual_positive_balance, 5.0)

	TestLogger.write_line(
		"Positive net balance: "
		+ ("PASS" if positive_balance_pass else "FAIL")
		+ " | expected=5.0 actual="
		+ str(actual_positive_balance)
	)

	# Case 2: negative net balance
	balance_extraction_capacity[test_resource] = 5.0
	balance_processing_capacity[test_resource] = 5.0
	balance_reserves[test_resource] = 100.0
	balance_stockpile[test_resource] = 0.0
	balance_consumption[test_resource] = 8.0
	balance_imports[test_resource] = 1.0
	balance_exports[test_resource] = 2.0

	resources.set_state("extraction_capacity", balance_extraction_capacity)
	resources.set_state("processing_capacity", balance_processing_capacity)
	resources.set_state("reserves", balance_reserves)
	resources.set_state("stockpile", balance_stockpile)
	resources.set_state("consumption", balance_consumption)
	resources.set_state("imports", balance_imports)
	resources.set_state("exports", balance_exports)

	resource_system.process_month(world)

	var negative_balance_state = resources.get_state("net_balance", {})
	var actual_negative_balance = float(negative_balance_state.get(test_resource, -999.0))
	var negative_balance_pass = is_equal_approx(actual_negative_balance, -4.0)

	TestLogger.write_line(
		"Negative net balance: "
		+ ("PASS" if negative_balance_pass else "FAIL")
		+ " | expected=-4.0 actual="
		+ str(actual_negative_balance)
	)

	var net_balance_pass = positive_balance_pass and negative_balance_pass
	if not net_balance_pass:
		all_passed = false

	# ============================================================
	# 15. RESERVE DEPLETION / RESERVE RATIO
	# ============================================================

	TestLogger.section(
		"15. RESERVE DEPLETION / RESERVE RATIO"
	)

	var reserve_test_extraction = resources.get_state(
		"extraction_capacity", {}
	).duplicate()
	var reserve_test_processing = resources.get_state(
		"processing_capacity", {}
	).duplicate()
	var reserve_test_reserves = resources.get_state(
		"reserves", {}
	).duplicate()
	var reserve_test_stockpile = resources.get_state(
		"stockpile", {}
	).duplicate()
	var reserve_test_consumption = resources.get_state(
		"consumption", {}
	).duplicate()
	var reserve_test_imports = resources.get_state(
		"imports", {}
	).duplicate()
	var reserve_test_exports = resources.get_state(
		"exports", {}
	).duplicate()

	reserve_test_extraction[test_resource] = 20.0
	reserve_test_processing[test_resource] = 20.0
	reserve_test_reserves[test_resource] = 100.0
	reserve_test_stockpile[test_resource] = 0.0
	reserve_test_consumption[test_resource] = 0.0
	reserve_test_imports[test_resource] = 0.0
	reserve_test_exports[test_resource] = 0.0

	resources.set_state(
		"extraction_capacity",
		reserve_test_extraction
	)
	resources.set_state(
		"processing_capacity",
		reserve_test_processing
	)
	resources.set_state(
		"reserves",
		reserve_test_reserves
	)
	resources.set_state(
		"stockpile",
		reserve_test_stockpile
	)
	resources.set_state(
		"consumption",
		reserve_test_consumption
	)
	resources.set_state(
		"imports",
		reserve_test_imports
	)
	resources.set_state(
		"exports",
		reserve_test_exports
	)

	# Case 1: normal depletion
	resource_system.process_month(world)

	var reserve_depletion_state = resources.get_state(
		"reserve_depletion",
		{}
	)
	var reserve_ratio_state = resources.get_state(
		"reserve_ratio",
		{}
	)
	var reserves_after_depletion = resources.get_state(
		"reserves",
		{}
	)

	var actual_reserve_depletion = float(
		reserve_depletion_state.get(test_resource, -1.0)
	)
	var actual_reserve_ratio = float(
		reserve_ratio_state.get(test_resource, -1.0)
	)
	var actual_remaining_reserves_part15 = float(
		reserves_after_depletion.get(test_resource, -1.0)
	)

	var depletion_pass = is_equal_approx(
		actual_reserve_depletion,
		20.0
	)
	var ratio_pass = is_equal_approx(
		actual_reserve_ratio,
		0.8
	)
	var remaining_reserves_pass = is_equal_approx(
		actual_remaining_reserves_part15,
		80.0
	)

	TestLogger.write_line(
		"Reserve depletion recorded: "
		+ ("PASS" if depletion_pass else "FAIL")
		+ " | expected=20.0 actual="
		+ str(actual_reserve_depletion)
	)

	TestLogger.write_line(
		"Reserve ratio calculated: "
		+ ("PASS" if ratio_pass else "FAIL")
		+ " | expected=0.8 actual="
		+ str(actual_reserve_ratio)
	)

	TestLogger.write_line(
		"Remaining reserves calculated: "
		+ ("PASS" if remaining_reserves_pass else "FAIL")
		+ " | expected=80.0 actual="
		+ str(actual_remaining_reserves_part15)
	)

	# Case 2: production cannot exceed available reserves
	reserve_test_reserves[test_resource] = 5.0
	reserve_test_extraction[test_resource] = 20.0
	reserve_test_processing[test_resource] = 20.0

	resources.set_state(
		"reserves",
		reserve_test_reserves
	)
	resources.set_state(
		"extraction_capacity",
		reserve_test_extraction
	)
	resources.set_state(
		"processing_capacity",
		reserve_test_processing
	)

	resource_system.process_month(world)

	var capped_reserve_depletion_state = resources.get_state(
		"reserve_depletion",
		{}
	)
	var capped_reserve_state = resources.get_state(
		"reserves",
		{}
	)
	var capped_ratio_state = resources.get_state(
		"reserve_ratio",
		{}
	)

	var capped_depletion = float(
		capped_reserve_depletion_state.get(test_resource, -1.0)
	)
	var capped_remaining = float(
		capped_reserve_state.get(test_resource, -1.0)
	)
	var capped_ratio = float(
		capped_ratio_state.get(test_resource, -1.0)
	)

	var depletion_cap_pass = is_equal_approx(
		capped_depletion,
		5.0
	)
	var zero_remaining_pass = is_equal_approx(
		capped_remaining,
		0.0
	)
	var zero_ratio_pass = is_equal_approx(
		capped_ratio,
		0.0
	)

	TestLogger.write_line(
		"Reserve depletion capped by reserves: "
		+ ("PASS" if depletion_cap_pass else "FAIL")
		+ " | expected=5.0 actual="
		+ str(capped_depletion)
	)

	TestLogger.write_line(
		"Reserves cannot become negative: "
		+ ("PASS" if zero_remaining_pass else "FAIL")
		+ " | expected=0.0 actual="
		+ str(capped_remaining)
	)

	TestLogger.write_line(
		"Zero reserves produce zero reserve ratio: "
		+ ("PASS" if zero_ratio_pass else "FAIL")
		+ " | expected=0.0 actual="
		+ str(capped_ratio)
	)

	var reserve_depletion_ratio_pass = (
		depletion_pass
		and ratio_pass
		and remaining_reserves_pass
		and depletion_cap_pass
		and zero_remaining_pass
		and zero_ratio_pass
	)

	if not reserve_depletion_ratio_pass:
		all_passed = false


	# ============================================================
	# 16. RESOURCE-EFFECT MODIFIERS
	# ============================================================

	TestLogger.section(
		"16. RESOURCE-EFFECT MODIFIERS"
	)

	var modifier_extraction_part16 = resources.get_state(
		"extraction_capacity", {}
	).duplicate()
	var modifier_processing_part16 = resources.get_state(
		"processing_capacity", {}
	).duplicate()
	var modifier_production_efficiency_part16 = resources.get_state(
		"production_efficiency", {}
	).duplicate()
	var modifier_technology_efficiency_part16 = resources.get_state(
		"technology_efficiency", {}
	).duplicate()
	var modifier_infrastructure_part16 = resources.get_state(
		"infrastructure_capacity", {}
	).duplicate()
	var modifier_quality_part16 = resources.get_state(
		"quality", {}
	).duplicate()
	var modifier_accessibility_part16 = resources.get_state(
		"accessibility", {}
	).duplicate()
	var modifier_reserves_part16 = resources.get_state(
		"reserves", {}
	).duplicate()
	var modifier_stockpile_part16 = resources.get_state(
		"stockpile", {}
	).duplicate()
	var modifier_consumption_part16 = resources.get_state(
		"consumption", {}
	).duplicate()
	var modifier_imports_part16 = resources.get_state(
		"imports", {}
	).duplicate()
	var modifier_exports_part16 = resources.get_state(
		"exports", {}
	).duplicate()

	# Isolate the modifier test from unrelated country resources.
	# Section 16 is testing the aggregate effect of test_resource itself.
	# Other resources are therefore neutralized so their existing shortages
	# cannot lower the aggregate modifiers being asserted here.
	var modifier_production_part16 = resources.get_state(
		"production", {}
	).duplicate()

	for resource_name in modifier_production_part16.keys():
		if resource_name == test_resource:
			continue

		var neutral_production = float(
			modifier_production_part16.get(resource_name, 0.0)
		)

		modifier_extraction_part16[resource_name] = max(
			neutral_production,
			1.0
		)
		modifier_processing_part16[resource_name] = max(
			neutral_production,
			1.0
		)
		modifier_production_efficiency_part16[resource_name] = 1.0
		modifier_technology_efficiency_part16[resource_name] = 1.0
		modifier_infrastructure_part16[resource_name] = 1.0
		modifier_quality_part16[resource_name] = 1.0
		modifier_accessibility_part16[resource_name] = 1.0
		modifier_reserves_part16[resource_name] = 100000.0
		modifier_stockpile_part16[resource_name] = 0.0
		modifier_consumption_part16[resource_name] = neutral_production
		modifier_imports_part16[resource_name] = 0.0
		modifier_exports_part16[resource_name] = 0.0

	# Case 1: no shortage should leave all aggregate modifiers at 1.0.
	modifier_extraction_part16[test_resource] = 10.0
	modifier_processing_part16[test_resource] = 10.0
	modifier_production_efficiency_part16[test_resource] = 1.0
	modifier_technology_efficiency_part16[test_resource] = 1.0
	modifier_infrastructure_part16[test_resource] = 1.0
	modifier_quality_part16[test_resource] = 1.0
	modifier_accessibility_part16[test_resource] = 1.0
	modifier_reserves_part16[test_resource] = 100.0
	modifier_stockpile_part16[test_resource] = 10.0
	modifier_consumption_part16[test_resource] = 10.0
	modifier_imports_part16[test_resource] = 0.0
	modifier_exports_part16[test_resource] = 0.0

	resources.set_state(
		"extraction_capacity",
		modifier_extraction_part16
	)
	resources.set_state(
		"processing_capacity",
		modifier_processing_part16
	)
	resources.set_state(
		"production_efficiency",
		modifier_production_efficiency_part16
	)
	resources.set_state(
		"technology_efficiency",
		modifier_technology_efficiency_part16
	)
	resources.set_state(
		"infrastructure_capacity",
		modifier_infrastructure_part16
	)
	resources.set_state(
		"quality",
		modifier_quality_part16
	)
	resources.set_state(
		"accessibility",
		modifier_accessibility_part16
	)
	resources.set_state(
		"reserves",
		modifier_reserves_part16
	)
	resources.set_state(
		"stockpile",
		modifier_stockpile_part16
	)
	resources.set_state(
		"consumption",
		modifier_consumption_part16
	)
	resources.set_state(
		"imports",
		modifier_imports_part16
	)
	resources.set_state(
		"exports",
		modifier_exports_part16
	)

	resource_system.process_month(world)

	var no_shortage_resource_efficiency = float(
		resources.get_state(
			"resource_efficiency",
			-1.0
		)
	)
	var no_shortage_industrial_modifier = float(
		resources.get_state(
			"industrial_resource_modifier",
			-1.0
		)
	)
	var no_shortage_military_modifier = float(
		resources.get_state(
			"military_resource_modifier",
			-1.0
		)
	)
	var no_shortage_transport_modifier = float(
		resources.get_state(
			"transport_resource_modifier",
			-1.0
		)
	)

	var no_shortage_pass = (
		is_equal_approx(no_shortage_resource_efficiency, 1.0)
		and is_equal_approx(no_shortage_industrial_modifier, 1.0)
		and is_equal_approx(no_shortage_military_modifier, 1.0)
		and is_equal_approx(no_shortage_transport_modifier, 1.0)
	)

	TestLogger.write_line(
		"No-shortage modifiers remain neutral: "
		+ ("PASS" if no_shortage_pass else "FAIL")
		+ " | expected=1.0,1.0,1.0,1.0 actual="
		+ str(no_shortage_resource_efficiency)
		+ ","
		+ str(no_shortage_industrial_modifier)
		+ ","
		+ str(no_shortage_military_modifier)
		+ ","
		+ str(no_shortage_transport_modifier)
	)

	# Case 2: 50% shortage should produce the documented continuous modifiers.
	# shortage = 10 / 20 = 50%
	# resource efficiency = 0.75
	# industrial modifier = 0.80
	# military modifier = 0.85
	# transport modifier = 0.75
	modifier_stockpile_part16[test_resource] = 0.0
	modifier_consumption_part16[test_resource] = 20.0
	modifier_reserves_part16[test_resource] = 100.0

	resources.set_state(
		"stockpile",
		modifier_stockpile_part16
	)
	resources.set_state(
		"consumption",
		modifier_consumption_part16
	)
	resources.set_state(
		"reserves",
		modifier_reserves_part16
	)

	resource_system.process_month(world)

	var shortage_resource_efficiency = float(
		resources.get_state(
			"resource_efficiency",
			-1.0
		)
	)
	var shortage_industrial_modifier = float(
		resources.get_state(
			"industrial_resource_modifier",
			-1.0
		)
	)
	var shortage_military_modifier = float(
		resources.get_state(
			"military_resource_modifier",
			-1.0
		)
	)
	var shortage_transport_modifier = float(
		resources.get_state(
			"transport_resource_modifier",
			-1.0
		)
	)

	var shortage_modifier_pass = (
		is_equal_approx(shortage_resource_efficiency, 0.75)
		and is_equal_approx(shortage_industrial_modifier, 0.80)
		and is_equal_approx(shortage_military_modifier, 0.85)
		and is_equal_approx(shortage_transport_modifier, 0.75)
	)

	TestLogger.write_line(
		"50% shortage modifiers calculated: "
		+ ("PASS" if shortage_modifier_pass else "FAIL")
		+ " | expected=0.75,0.80,0.85,0.75 actual="
		+ str(shortage_resource_efficiency)
		+ ","
		+ str(shortage_industrial_modifier)
		+ ","
		+ str(shortage_military_modifier)
		+ ","
		+ str(shortage_transport_modifier)
	)

	var resource_effect_modifiers_pass = (
		no_shortage_pass
		and shortage_modifier_pass
	)

	if not resource_effect_modifiers_pass:
		all_passed = false


	# ============================================================
	# 17. MULTI-RESOURCE INDEPENDENCE
	# ============================================================

	TestLogger.section(
		"17. MULTI-RESOURCE INDEPENDENCE"
	)

	var independence_production_part17 = resources.get_state(
		"production", {}
	).duplicate()
	var independence_consumption_part17 = resources.get_state(
		"consumption", {}
	).duplicate()
	var independence_imports_part17 = resources.get_state(
		"imports", {}
	).duplicate()
	var independence_exports_part17 = resources.get_state(
		"exports", {}
	).duplicate()
	var independence_reserves_part17 = resources.get_state(
		"reserves", {}
	).duplicate()
	var independence_stockpile_part17 = resources.get_state(
		"stockpile", {}
	).duplicate()

	# Coal: deliberate shortage.
	independence_production_part17["coal"] = 10.0
	independence_consumption_part17["coal"] = 20.0
	independence_imports_part17["coal"] = 0.0
	independence_exports_part17["coal"] = 0.0
	independence_reserves_part17["coal"] = 100.0
	independence_stockpile_part17["coal"] = 0.0

	# Oil: independent balanced supply.
	independence_production_part17["oil"] = 5.0
	independence_consumption_part17["oil"] = 5.0
	independence_imports_part17["oil"] = 0.0
	independence_exports_part17["oil"] = 0.0
	independence_reserves_part17["oil"] = 100.0
	independence_stockpile_part17["oil"] = 10.0

	# Neutralize production constraints for both resources so the
	# independence test controls the intended production values.
	var independence_extraction_part17 = resources.get_state(
		"extraction_capacity", {}
	).duplicate()
	var independence_processing_part17 = resources.get_state(
		"processing_capacity", {}
	).duplicate()
	var independence_production_efficiency_part17 = resources.get_state(
		"production_efficiency", {}
	).duplicate()
	var independence_technology_efficiency_part17 = resources.get_state(
		"technology_efficiency", {}
	).duplicate()
	var independence_infrastructure_part17 = resources.get_state(
		"infrastructure_capacity", {}
	).duplicate()
	var independence_quality_part17 = resources.get_state(
		"quality", {}
	).duplicate()
	var independence_accessibility_part17 = resources.get_state(
		"accessibility", {}
	).duplicate()

	independence_extraction_part17["coal"] = 10.0
	independence_processing_part17["coal"] = 10.0
	independence_extraction_part17["oil"] = 5.0
	independence_processing_part17["oil"] = 5.0
	independence_production_efficiency_part17["coal"] = 1.0
	independence_production_efficiency_part17["oil"] = 1.0
	independence_technology_efficiency_part17["coal"] = 1.0
	independence_technology_efficiency_part17["oil"] = 1.0
	independence_infrastructure_part17["coal"] = 1.0
	independence_infrastructure_part17["oil"] = 1.0
	independence_quality_part17["coal"] = 1.0
	independence_quality_part17["oil"] = 1.0
	independence_accessibility_part17["coal"] = 1.0
	independence_accessibility_part17["oil"] = 1.0

	resources.set_state(
		"extraction_capacity",
		independence_extraction_part17
	)
	resources.set_state(
		"processing_capacity",
		independence_processing_part17
	)
	resources.set_state(
		"production_efficiency",
		independence_production_efficiency_part17
	)
	resources.set_state(
		"technology_efficiency",
		independence_technology_efficiency_part17
	)
	resources.set_state(
		"infrastructure_capacity",
		independence_infrastructure_part17
	)
	resources.set_state(
		"quality",
		independence_quality_part17
	)
	resources.set_state(
		"accessibility",
		independence_accessibility_part17
	)

	resources.set_state(
		"production",
		independence_production_part17
	)
	resources.set_state(
		"consumption",
		independence_consumption_part17
	)
	resources.set_state(
		"imports",
		independence_imports_part17
	)
	resources.set_state(
		"exports",
		independence_exports_part17
	)
	resources.set_state(
		"reserves",
		independence_reserves_part17
	)
	resources.set_state(
		"stockpile",
		independence_stockpile_part17
	)

	resource_system.process_month(world)

	var independence_actual_production_part17 = resources.get_state(
		"actual_production",
	{}
	)
	var independence_stockpile_result_part17 = resources.get_state(
		"stockpile",
	{}
	)
	var independence_shortages_part17 = resources.get_state(
		"shortages",
	{}
	)
	var independence_net_balance_part17 = resources.get_state(
		"net_balance",
	{}
	)

	var coal_production_independent_pass = is_equal_approx(
		float(independence_actual_production_part17.get("coal", -1.0)),
		10.0
	)
	var oil_production_independent_pass = is_equal_approx(
		float(independence_actual_production_part17.get("oil", -1.0)),
		5.0
	)
	var coal_shortage_independent_pass = is_equal_approx(
		float(independence_shortages_part17.get("coal", -1.0)),
		10.0
	)
	var oil_shortage_independent_pass = is_equal_approx(
		float(independence_shortages_part17.get("oil", -1.0)),
		0.0
	)
	var coal_stockpile_independent_pass = is_equal_approx(
		float(independence_stockpile_result_part17.get("coal", -1.0)),
		0.0
	)
	var oil_stockpile_independent_pass = is_equal_approx(
		float(independence_stockpile_result_part17.get("oil", -1.0)),
		10.0
	)
	var coal_balance_independent_pass = is_equal_approx(
		float(independence_net_balance_part17.get("coal", -1.0)),
		-10.0
	)
	var oil_balance_independent_pass = is_equal_approx(
		float(independence_net_balance_part17.get("oil", -1.0)),
		0.0
	)

	var multi_resource_independence_pass = (
		coal_production_independent_pass
		and oil_production_independent_pass
		and coal_shortage_independent_pass
		and oil_shortage_independent_pass
		and coal_stockpile_independent_pass
		and oil_stockpile_independent_pass
		and coal_balance_independent_pass
		and oil_balance_independent_pass
	)

	TestLogger.write_line(
		"Multi-resource state independence: "
		+ (
			"PASS"
			if multi_resource_independence_pass
			else "FAIL"
		)
		+ " | coal_shortage="
		+ str(float(independence_shortages_part17.get("coal", -1.0)))
		+ " oil_shortage="
		+ str(float(independence_shortages_part17.get("oil", -1.0)))
		+ " coal_stockpile="
		+ str(float(independence_stockpile_result_part17.get("coal", -1.0)))
		+ " oil_stockpile="
		+ str(float(independence_stockpile_result_part17.get("oil", -1.0)))
	)

	if not multi_resource_independence_pass:
		all_passed = false



	# ============================================================
	# 18. FULL MONTHLY RESOURCE LIFECYCLE
	# ============================================================

	TestLogger.section(
		"18. FULL MONTHLY RESOURCE LIFECYCLE"
	)

	# One complete monthly flow:
	# reserves -> production -> stockpile -> imports
	# -> consumption / exports -> final stockpile
	# -> surplus / shortage -> net balance -> modifiers
	#
	# Test resource:
	# starting reserves = 100
	# requested production = 10
	# extraction capacity = 10
	# processing capacity = 10
	# all efficiency modifiers = 1.0
	# starting stockpile = 20
	# imports = 3
	# consumption = 8
	# exports = 2
	#
	# Expected:
	# actual production = 10
	# remaining reserves = 90
	# reserve depletion = 10
	# final stockpile = 23
	# shortage = 0
	# surplus = 23
	# net balance = 3
	# reserve ratio = 0.9
	# all resource-effect modifiers = 1.0

	var lifecycle_production: Dictionary = resources.get_state(
		"production",
		{}
	).duplicate(true)
	var lifecycle_consumption: Dictionary = resources.get_state(
		"consumption",
		{}
	).duplicate(true)
	var lifecycle_imports: Dictionary = resources.get_state(
		"imports",
		{}
	).duplicate(true)
	var lifecycle_exports: Dictionary = resources.get_state(
		"exports",
		{}
	).duplicate(true)
	var lifecycle_reserves: Dictionary = resources.get_state(
		"reserves",
		{}
	).duplicate(true)
	var lifecycle_stockpile: Dictionary = resources.get_state(
		"stockpile",
		{}
	).duplicate(true)
	var lifecycle_extraction_capacity: Dictionary = resources.get_state(
		"extraction_capacity",
		{}
	).duplicate(true)
	var lifecycle_processing_capacity: Dictionary = resources.get_state(
		"processing_capacity",
		{}
	).duplicate(true)
	var lifecycle_production_efficiency: Dictionary = resources.get_state(
		"production_efficiency",
		{}
	).duplicate(true)
	var lifecycle_technology_efficiency: Dictionary = resources.get_state(
		"technology_efficiency",
		{}
	).duplicate(true)
	var lifecycle_infrastructure_capacity: Dictionary = resources.get_state(
		"infrastructure_capacity",
		{}
	).duplicate(true)
	var lifecycle_quality: Dictionary = resources.get_state(
		"quality",
		{}
	).duplicate(true)
	var lifecycle_accessibility: Dictionary = resources.get_state(
		"accessibility",
		{}
	).duplicate(true)

	lifecycle_production[test_resource] = 10.0
	lifecycle_consumption[test_resource] = 8.0
	lifecycle_imports[test_resource] = 3.0
	lifecycle_exports[test_resource] = 2.0
	lifecycle_reserves[test_resource] = 100.0
	lifecycle_stockpile[test_resource] = 20.0
	lifecycle_extraction_capacity[test_resource] = 10.0
	lifecycle_processing_capacity[test_resource] = 10.0
	lifecycle_production_efficiency[test_resource] = 1.0
	lifecycle_technology_efficiency[test_resource] = 1.0
	lifecycle_infrastructure_capacity[test_resource] = 1.0
	lifecycle_quality[test_resource] = 1.0
	lifecycle_accessibility[test_resource] = 1.0

	resources.set_state("production", lifecycle_production)
	resources.set_state("consumption", lifecycle_consumption)
	resources.set_state("imports", lifecycle_imports)
	resources.set_state("exports", lifecycle_exports)
	resources.set_state("reserves", lifecycle_reserves)
	resources.set_state("stockpile", lifecycle_stockpile)
	resources.set_state("extraction_capacity", lifecycle_extraction_capacity)
	resources.set_state("processing_capacity", lifecycle_processing_capacity)
	resources.set_state("production_efficiency", lifecycle_production_efficiency)
	resources.set_state("technology_efficiency", lifecycle_technology_efficiency)
	resources.set_state("infrastructure_capacity", lifecycle_infrastructure_capacity)
	resources.set_state("quality", lifecycle_quality)
	resources.set_state("accessibility", lifecycle_accessibility)

	resource_system.process_month(world)

	var lifecycle_actual_production := float(
		resources.get_state(
			"actual_production",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_remaining_reserves := float(
		resources.get_state(
			"reserves",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_depletion := float(
		resources.get_state(
			"reserve_depletion",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_final_stockpile := float(
		resources.get_state(
			"stockpile",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_shortage := float(
		resources.get_state(
			"shortages",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_surplus := float(
		resources.get_state(
			"surplus",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_net_balance := float(
		resources.get_state(
			"net_balance",
			{}
		).get(
			test_resource,
			-999.0
		)
	)

	var lifecycle_reserve_ratio := float(
		resources.get_state(
			"reserve_ratio",
			{}
		).get(
			test_resource,
			-1.0
		)
	)

	var lifecycle_resource_efficiency := float(
		resources.get_state(
			"resource_efficiency",
			-1.0
		)
	)

	var lifecycle_industrial_modifier := float(
		resources.get_state(
			"industrial_resource_modifier",
			-1.0
		)
	)

	var lifecycle_military_modifier := float(
		resources.get_state(
			"military_resource_modifier",
			-1.0
		)
	)

	var lifecycle_transport_modifier := float(
		resources.get_state(
			"transport_resource_modifier",
			-1.0
		)
	)

	var lifecycle_production_pass := is_equal_approx(
		lifecycle_actual_production,
		10.0
	)

	var lifecycle_reserves_pass := is_equal_approx(
		lifecycle_remaining_reserves,
		90.0
	)

	var lifecycle_depletion_pass := is_equal_approx(
		lifecycle_depletion,
		10.0
	)

	var lifecycle_stockpile_pass := is_equal_approx(
		lifecycle_final_stockpile,
		23.0
	)

	var lifecycle_shortage_pass := is_equal_approx(
		lifecycle_shortage,
		0.0
	)

	var lifecycle_surplus_pass := is_equal_approx(
		lifecycle_surplus,
		23.0
	)

	var lifecycle_net_balance_pass := is_equal_approx(
		lifecycle_net_balance,
		3.0
	)

	var lifecycle_reserve_ratio_pass := is_equal_approx(
		lifecycle_reserve_ratio,
		0.9
	)

	var lifecycle_modifiers_pass = (
		is_equal_approx(
			lifecycle_resource_efficiency,
			1.0
		)
		and is_equal_approx(
			lifecycle_industrial_modifier,
			1.0
		)
		and is_equal_approx(
			lifecycle_military_modifier,
			1.0
		)
		and is_equal_approx(
			lifecycle_transport_modifier,
			1.0
		)
	)

	full_lifecycle_pass = (
		lifecycle_production_pass
		and lifecycle_reserves_pass
		and lifecycle_depletion_pass
		and lifecycle_stockpile_pass
		and lifecycle_shortage_pass
		and lifecycle_surplus_pass
		and lifecycle_net_balance_pass
		and lifecycle_reserve_ratio_pass
		and lifecycle_modifiers_pass
	)

	TestLogger.write_line(
		"Full monthly lifecycle: "
		+ (
			"PASS"
			if full_lifecycle_pass
			else "FAIL"
		)
		+ " | production="
		+ str(lifecycle_actual_production)
		+ " reserves="
		+ str(lifecycle_remaining_reserves)
		+ " stockpile="
		+ str(lifecycle_final_stockpile)
		+ " shortage="
		+ str(lifecycle_shortage)
		+ " surplus="
		+ str(lifecycle_surplus)
		+ " net_balance="
		+ str(lifecycle_net_balance)
	)

	if not full_lifecycle_pass:
		all_passed = false

	# ============================================================
	# 19. TRANSPORT INFRASTRUCTURE
	# ============================================================

	TestLogger.section(
		"19. TRANSPORT INFRASTRUCTURE"
	)

	# Controlled test:
	# transport infrastructure = 0.50
	# all resource production modifiers = 1.0
	#
	# Expected behavior:
	# transport infrastructure should reduce effective
	# resource production to 50%.

	var transport_production = (
		original_production.duplicate(true)
	)

	var transport_extraction_capacity = (
		original_extraction.duplicate(true)
	)

	var transport_processing_capacity = (
		original_processing.duplicate(true)
	)

	var transport_production_efficiency = (
		original_production_efficiency.duplicate(true)
	)

	var transport_technology_efficiency = (
		original_technology_efficiency.duplicate(true)
	)

	var transport_infrastructure_capacity = (
		original_infrastructure_capacity.duplicate(true)
	)

	var transport_quality = (
		original_quality.duplicate(true)
	)

	var transport_accessibility = (
		original_accessibility.duplicate(true)
	)

	# Explicitly restore the controlled production request because section 18
	# intentionally changes production[test_resource] to 10.0.
	transport_production[test_resource] = requested_production

	transport_extraction_capacity[test_resource] = (
		requested_production
	)

	transport_processing_capacity[test_resource] = (
		requested_production
	)

	transport_production_efficiency[test_resource] = 1.0
	transport_technology_efficiency[test_resource] = 1.0
	transport_infrastructure_capacity[test_resource] = 1.0
	transport_quality[test_resource] = 1.0
	transport_accessibility[test_resource] = 1.0

	resources.set_state(
		"production",
		transport_production
	)

	resources.set_state(
		"extraction_capacity",
		transport_extraction_capacity
	)

	resources.set_state(
		"processing_capacity",
		transport_processing_capacity
	)

	resources.set_state(
		"production_efficiency",
		transport_production_efficiency
	)

	resources.set_state(
		"technology_efficiency",
		transport_technology_efficiency
	)

	resources.set_state(
		"infrastructure_capacity",
		transport_infrastructure_capacity
	)

	resources.set_state(
		"quality",
		transport_quality
	)

	resources.set_state(
		"accessibility",
		transport_accessibility
	)

	infrastructure_component.set_state(
		"transport",
		0.50
	)

	# Isolate the transport effect from stockpile/flow state inherited from
	# section 18. The transport test is about production capacity only.
	var transport_reserves = original_reserves.duplicate(true)
	var transport_stockpile = original_stockpile.duplicate(true)
	var transport_consumption = original_consumption.duplicate(true)
	var transport_imports = original_imports.duplicate(true)
	var transport_exports = original_exports.duplicate(true)

	transport_reserves[test_resource] = 100.0
	transport_stockpile[test_resource] = 0.0
	transport_consumption[test_resource] = 0.0
	transport_imports[test_resource] = 0.0
	transport_exports[test_resource] = 0.0

	resources.set_state("reserves", transport_reserves)
	resources.set_state("stockpile", transport_stockpile)
	resources.set_state("consumption", transport_consumption)
	resources.set_state("imports", transport_imports)
	resources.set_state("exports", transport_exports)

	# Diagnostic: verify every transport-test input immediately before
	# ResourceSystem processes the month. This isolates state/setup issues
	# from ResourceSystem calculation issues.
	TestLogger.write_line(
		"Transport diagnostic | requested="
		+ str(requested_production)
		+ " extraction="
		+ str(
			float(
				resources.get_state(
					"extraction_capacity",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " processing="
		+ str(
			float(
				resources.get_state(
					"processing_capacity",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " generic_infrastructure="
		+ str(
			float(
				resources.get_state(
					"infrastructure_capacity",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " transport="
		+ str(
			float(
				infrastructure_component.get_state(
					"transport",
					-1.0
				)
			)
		)
		+ " production_efficiency="
		+ str(
			float(
				resources.get_state(
					"production_efficiency",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " technology_efficiency="
		+ str(
			float(
				resources.get_state(
					"technology_efficiency",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " quality="
		+ str(
			float(
				resources.get_state(
					"quality",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " accessibility="
		+ str(
			float(
				resources.get_state(
					"accessibility",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
	)

	resource_system.process_month(
		world
	)

	var post_transport_infrastructure = resources.get_state(
		"infrastructure_capacity",
		{}
	)

	TestLogger.write_line(
		"Transport post-state | actual_production="
		+ str(
			float(
				resources.get_state(
					"actual_production",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " extraction="
		+ str(
			float(
				resources.get_state(
					"extraction_capacity",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " processing="
		+ str(
			float(
				resources.get_state(
					"processing_capacity",
					{}
				).get(
					test_resource,
					-1.0
				)
			)
		)
		+ " generic_infrastructure="
		+ str(
			float(
				post_transport_infrastructure.get(
					test_resource,
					-1.0
				)
			)
		)
		+ " transport="
		+ str(
			float(
				infrastructure_component.get_state(
					"transport",
					-1.0
				)
			)
		)
	)

	var transport_actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_transport_production := float(
		transport_actual_production.get(
			test_resource,
			-1.0
		)
	)

	var expected_transport_production :float= (
		requested_production * 0.50
	)

	var transport_infrastructure_pass := is_equal_approx(
		actual_transport_production,
		expected_transport_production
	)

	TestLogger.write_line(
		"50% transport infrastructure limits resource production: "
		+ (
			"PASS"
			if transport_infrastructure_pass
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_transport_production)
		+ " actual="
		+ str(actual_transport_production)
	)

	if not transport_infrastructure_pass:
		all_passed = false


	# ============================================================
	# 20. ROADS INFRASTRUCTURE
	# ============================================================

	TestLogger.section(
		"20. ROADS INFRASTRUCTURE"
	)

	# Controlled test: roads = 0.50, transport = 1.0,
	# resource accessibility = 1.0, all other modifiers = 1.0.
	# Roads should constrain effective resource accessibility to 0.50.

	var roads_production = original_production.duplicate(true)
	var roads_extraction_capacity = original_extraction.duplicate(true)
	var roads_processing_capacity = original_processing.duplicate(true)
	var roads_production_efficiency = original_production_efficiency.duplicate(true)
	var roads_technology_efficiency = original_technology_efficiency.duplicate(true)
	var roads_infrastructure_capacity = original_infrastructure_capacity.duplicate(true)
	var roads_quality = original_quality.duplicate(true)
	var roads_accessibility = original_accessibility.duplicate(true)

	roads_production[test_resource] = requested_production
	roads_extraction_capacity[test_resource] = requested_production
	roads_processing_capacity[test_resource] = requested_production
	roads_production_efficiency[test_resource] = 1.0
	roads_technology_efficiency[test_resource] = 1.0
	roads_infrastructure_capacity[test_resource] = 1.0
	roads_quality[test_resource] = 1.0
	roads_accessibility[test_resource] = 1.0

	resources.set_state("production", roads_production)
	resources.set_state("extraction_capacity", roads_extraction_capacity)
	resources.set_state("processing_capacity", roads_processing_capacity)
	resources.set_state("production_efficiency", roads_production_efficiency)
	resources.set_state("technology_efficiency", roads_technology_efficiency)
	resources.set_state("infrastructure_capacity", roads_infrastructure_capacity)
	resources.set_state("quality", roads_quality)
	resources.set_state("accessibility", roads_accessibility)

	infrastructure_component.set_state(
		"transport",
		1.0
	)

	infrastructure_component.set_state(
		"roads",
		0.50
	)

	var roads_reserves = original_reserves.duplicate(true)
	var roads_stockpile = original_stockpile.duplicate(true)
	var roads_consumption = original_consumption.duplicate(true)
	var roads_imports = original_imports.duplicate(true)
	var roads_exports = original_exports.duplicate(true)

	roads_reserves[test_resource] = 100.0
	roads_stockpile[test_resource] = 0.0
	roads_consumption[test_resource] = 0.0
	roads_imports[test_resource] = 0.0
	roads_exports[test_resource] = 0.0

	resources.set_state("reserves", roads_reserves)
	resources.set_state("stockpile", roads_stockpile)
	resources.set_state("consumption", roads_consumption)
	resources.set_state("imports", roads_imports)
	resources.set_state("exports", roads_exports)

	resource_system.process_month(world)

	var roads_actual_production = resources.get_state(
		"actual_production",
		{}
	)

	var actual_roads_production := float(
		roads_actual_production.get(
			test_resource,
			-1.0
		)
	)

	var expected_roads_production: float = (
		requested_production * 0.50
	)

	var roads_infrastructure_pass := is_equal_approx(
		actual_roads_production,
		expected_roads_production
	)

	TestLogger.write_line(
		"50% roads infrastructure limits resource accessibility: "
		+ (
			"PASS"
			if roads_infrastructure_pass
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_roads_production)
		+ " actual="
		+ str(actual_roads_production)
	)

	if not roads_infrastructure_pass:
		all_passed = false


	# ============================================================
	# 21. RAILWAYS INFRASTRUCTURE
	# ============================================================

	TestLogger.section(
		"21. RAILWAYS INFRASTRUCTURE"
	)

	# Controlled test: railways = 0.50, transport = 1.0, roads = 1.0,
	# resource accessibility = 1.0, all other modifiers = 1.0.
	# Railways should constrain effective resource accessibility to 0.50.

	var railways_production = original_production.duplicate(true)
	var railways_extraction_capacity = original_extraction.duplicate(true)
	var railways_processing_capacity = original_processing.duplicate(true)
	var railways_production_efficiency = original_production_efficiency.duplicate(true)
	var railways_technology_efficiency = original_technology_efficiency.duplicate(true)
	var railways_infrastructure_capacity = original_infrastructure_capacity.duplicate(true)
	var railways_quality = original_quality.duplicate(true)
	var railways_accessibility = original_accessibility.duplicate(true)

	railways_production[test_resource] = requested_production
	railways_extraction_capacity[test_resource] = requested_production
	railways_processing_capacity[test_resource] = requested_production
	railways_production_efficiency[test_resource] = 1.0
	railways_technology_efficiency[test_resource] = 1.0
	railways_infrastructure_capacity[test_resource] = 1.0
	railways_quality[test_resource] = 1.0
	railways_accessibility[test_resource] = 1.0

	resources.set_state("production", railways_production)
	resources.set_state("extraction_capacity", railways_extraction_capacity)
	resources.set_state("processing_capacity", railways_processing_capacity)
	resources.set_state("production_efficiency", railways_production_efficiency)
	resources.set_state("technology_efficiency", railways_technology_efficiency)
	resources.set_state("infrastructure_capacity", railways_infrastructure_capacity)
	resources.set_state("quality", railways_quality)
	resources.set_state("accessibility", railways_accessibility)

	infrastructure_component.set_state(
		"transport",
		1.0
	)

	infrastructure_component.set_state(
		"roads",
		1.0
	)

	infrastructure_component.set_state(
		"railways",
		0.50
	)

	var railways_reserves = original_reserves.duplicate(true)
	var railways_stockpile = original_stockpile.duplicate(true)
	var railways_consumption = original_consumption.duplicate(true)
	var railways_imports = original_imports.duplicate(true)
	var railways_exports = original_exports.duplicate(true)

	railways_reserves[test_resource] = 100.0
	railways_stockpile[test_resource] = 0.0
	railways_consumption[test_resource] = 0.0
	railways_imports[test_resource] = 0.0
	railways_exports[test_resource] = 0.0

	resources.set_state("reserves", railways_reserves)
	resources.set_state("stockpile", railways_stockpile)
	resources.set_state("consumption", railways_consumption)
	resources.set_state("imports", railways_imports)
	resources.set_state("exports", railways_exports)

	resource_system.process_month(world)

	var railways_actual_production_state = resources.get_state(
		"actual_production",
		{}
	)

	var actual_railways_production := float(
		railways_actual_production_state.get(
			test_resource,
			-1.0
		)
	)

	var expected_railways_production: float = (
		requested_production * 0.50
	)

	var railways_infrastructure_pass := is_equal_approx(
		actual_railways_production,
		expected_railways_production
	)

	TestLogger.write_line(
		"50% railways infrastructure limits resource accessibility: "
		+ (
			"PASS"
			if railways_infrastructure_pass
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_railways_production)
		+ " actual="
		+ str(actual_railways_production)
	)

	if not railways_infrastructure_pass:
		all_passed = false


	# ============================================================
	# 22. POWER INFRASTRUCTURE
	# ============================================================

	TestLogger.section(
		"22. POWER INFRASTRUCTURE"
	)

	# Power infrastructure acts as a direct production-capacity
	# constraint at the ResourceSystem level. This verifies causal
	# integration of the infrastructure value rather than merely
	# verifying that the value exists on InfrastructureComponent.

	infrastructure_component.set_state(
		"transport",
		1.0
	)

	infrastructure_component.set_state(
		"roads",
		1.0
	)

	infrastructure_component.set_state(
		"railways",
		1.0
	)

	infrastructure_component.set_state(
		"ports",
		1.0
	)

	infrastructure_component.set_state(
		"power",
		0.50
	)

	var power_production = original_production.duplicate(true)
	var power_extraction = original_extraction.duplicate(true)
	var power_processing = original_processing.duplicate(true)
	var power_efficiency = original_production_efficiency.duplicate(true)
	var power_technology = original_technology_efficiency.duplicate(true)
	var power_infrastructure = original_infrastructure_capacity.duplicate(true)
	var power_quality = original_quality.duplicate(true)
	var power_accessibility = original_accessibility.duplicate(true)
	var power_reserves = original_reserves.duplicate(true)
	var power_stockpile = original_stockpile.duplicate(true)
	var power_consumption = original_consumption.duplicate(true)
	var power_imports = original_imports.duplicate(true)
	var power_exports = original_exports.duplicate(true)

	power_production[test_resource] = requested_production
	power_extraction[test_resource] = requested_production
	power_processing[test_resource] = requested_production
	power_efficiency[test_resource] = 1.0
	power_technology[test_resource] = 1.0
	power_infrastructure[test_resource] = 1.0
	power_quality[test_resource] = 1.0
	power_accessibility[test_resource] = 1.0
	power_reserves[test_resource] = 100.0
	power_stockpile[test_resource] = 0.0
	power_consumption[test_resource] = 0.0
	power_imports[test_resource] = 0.0
	power_exports[test_resource] = 0.0

	resources.set_state("production", power_production)
	resources.set_state("extraction_capacity", power_extraction)
	resources.set_state("processing_capacity", power_processing)
	resources.set_state("production_efficiency", power_efficiency)
	resources.set_state("technology_efficiency", power_technology)
	resources.set_state("infrastructure_capacity", power_infrastructure)
	resources.set_state("quality", power_quality)
	resources.set_state("accessibility", power_accessibility)
	resources.set_state("reserves", power_reserves)
	resources.set_state("stockpile", power_stockpile)
	resources.set_state("consumption", power_consumption)
	resources.set_state("imports", power_imports)
	resources.set_state("exports", power_exports)

	resource_system.process_month(world)

	var power_actual_production_state = resources.get_state(
		"actual_production",
		{}
	)

	var actual_power_production := float(
		power_actual_production_state.get(
			test_resource,
			-1.0
		)
	)

	var expected_power_production: float = (
		requested_production * 0.50
	)

	var power_infrastructure_pass := is_equal_approx(
		actual_power_production,
		expected_power_production
	)

	TestLogger.write_line(
		"50% power infrastructure limits resource production: "
		+ (
			"PASS"
			if power_infrastructure_pass
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_power_production)
		+ " actual="
		+ str(actual_power_production)
	)

	if not power_infrastructure_pass:
		all_passed = false


	# ============================================================
	# 22.5 PORTS INFRASTRUCTURE
	# ============================================================

	TestLogger.section(
		"22. PORTS INFRASTRUCTURE"
	)

	# Ports constrain international throughput rather than acting as a
	# direct domestic production multiplier.

	# Reset power to neutral after the dedicated power test above so
	# the ports and later storage tests measure only their own behavior.
	infrastructure_component.set_state(
		"power",
		1.0
	)

	infrastructure_component.set_state(
		"transport",
		1.0
	)

	infrastructure_component.set_state(
		"roads",
		1.0
	)

	infrastructure_component.set_state(
		"railways",
		1.0
	)

	infrastructure_component.set_state(
		"ports",
		0.50
	)

	# ------------------------------------------------------------
	# 22A. IMPORT THROUGHPUT
	# ------------------------------------------------------------

	var port_import_production = original_production.duplicate(true)
	var port_import_extraction = original_extraction.duplicate(true)
	var port_import_processing = original_processing.duplicate(true)
	var port_import_efficiency = original_production_efficiency.duplicate(true)
	var port_import_technology = original_technology_efficiency.duplicate(true)
	var port_import_infrastructure = original_infrastructure_capacity.duplicate(true)
	var port_import_quality = original_quality.duplicate(true)
	var port_import_accessibility = original_accessibility.duplicate(true)
	var port_import_reserves = original_reserves.duplicate(true)
	var port_import_stockpile = original_stockpile.duplicate(true)
	var port_import_consumption = original_consumption.duplicate(true)
	var port_imports = original_imports.duplicate(true)
	var port_exports = original_exports.duplicate(true)

	port_import_production[test_resource] = 0.0
	port_import_extraction[test_resource] = 0.0
	port_import_processing[test_resource] = 0.0
	port_import_efficiency[test_resource] = 1.0
	port_import_technology[test_resource] = 1.0
	port_import_infrastructure[test_resource] = 1.0
	port_import_quality[test_resource] = 1.0
	port_import_accessibility[test_resource] = 1.0
	port_import_reserves[test_resource] = 0.0
	port_import_stockpile[test_resource] = 0.0
	port_import_consumption[test_resource] = 15.0
	port_imports[test_resource] = 20.0
	port_exports[test_resource] = 0.0

	resources.set_state("production", port_import_production)
	resources.set_state("extraction_capacity", port_import_extraction)
	resources.set_state("processing_capacity", port_import_processing)
	resources.set_state("production_efficiency", port_import_efficiency)
	resources.set_state("technology_efficiency", port_import_technology)
	resources.set_state("infrastructure_capacity", port_import_infrastructure)
	resources.set_state("quality", port_import_quality)
	resources.set_state("accessibility", port_import_accessibility)
	resources.set_state("reserves", port_import_reserves)
	resources.set_state("stockpile", port_import_stockpile)
	resources.set_state("consumption", port_import_consumption)
	resources.set_state("imports", port_imports)
	resources.set_state("exports", port_exports)

	resource_system.process_month(world)

	var port_import_shortages = resources.get_state(
		"shortages",
		{}
	)

	var port_import_stockpile_state = resources.get_state(
		"stockpile",
		{}
	)

	var actual_import_shortage := float(
		port_import_shortages.get(
			test_resource,
			-1.0
		)
	)

	var actual_import_stockpile := float(
		port_import_stockpile_state.get(
			test_resource,
			-1.0
		)
	)

	# Requested imports = 20, ports = 50%, so only 10 arrive.
	# Consumption = 15 therefore leaves shortage = 5.
	var import_throughput_pass := (
		is_equal_approx(actual_import_shortage, 5.0)
		and is_equal_approx(actual_import_stockpile, 0.0)
	)

	TestLogger.write_line(
		"50% port import throughput: "
		+ (
			"PASS"
			if import_throughput_pass
			else "FAIL"
		)
		+ " | expected_shortage=5.0 actual_shortage="
		+ str(actual_import_shortage)
		+ " expected_stockpile=0.0 actual_stockpile="
		+ str(actual_import_stockpile)
	)

	if not import_throughput_pass:
		all_passed = false


	# ------------------------------------------------------------
	# 22B. EXPORT THROUGHPUT
	# ------------------------------------------------------------

	var port_export_production = original_production.duplicate(true)
	var port_export_extraction = original_extraction.duplicate(true)
	var port_export_processing = original_processing.duplicate(true)
	var port_export_efficiency = original_production_efficiency.duplicate(true)
	var port_export_technology = original_technology_efficiency.duplicate(true)
	var port_export_infrastructure = original_infrastructure_capacity.duplicate(true)
	var port_export_quality = original_quality.duplicate(true)
	var port_export_accessibility = original_accessibility.duplicate(true)
	var port_export_reserves = original_reserves.duplicate(true)
	var port_export_stockpile = original_stockpile.duplicate(true)
	var port_export_consumption = original_consumption.duplicate(true)
	var port_export_imports = original_imports.duplicate(true)
	var port_export_exports = original_exports.duplicate(true)

	port_export_production[test_resource] = 20.0
	port_export_extraction[test_resource] = 20.0
	port_export_processing[test_resource] = 20.0
	port_export_efficiency[test_resource] = 1.0
	port_export_technology[test_resource] = 1.0
	port_export_infrastructure[test_resource] = 1.0
	port_export_quality[test_resource] = 1.0
	port_export_accessibility[test_resource] = 1.0
	port_export_reserves[test_resource] = 100.0
	port_export_stockpile[test_resource] = 0.0
	port_export_consumption[test_resource] = 0.0
	port_export_imports[test_resource] = 0.0
	port_export_exports[test_resource] = 20.0

	resources.set_state("production", port_export_production)
	resources.set_state("extraction_capacity", port_export_extraction)
	resources.set_state("processing_capacity", port_export_processing)
	resources.set_state("production_efficiency", port_export_efficiency)
	resources.set_state("technology_efficiency", port_export_technology)
	resources.set_state("infrastructure_capacity", port_export_infrastructure)
	resources.set_state("quality", port_export_quality)
	resources.set_state("accessibility", port_export_accessibility)
	resources.set_state("reserves", port_export_reserves)
	resources.set_state("stockpile", port_export_stockpile)
	resources.set_state("consumption", port_export_consumption)
	resources.set_state("imports", port_export_imports)
	resources.set_state("exports", port_export_exports)

	resource_system.process_month(world)

	var port_export_stockpile_state = resources.get_state(
		"stockpile",
		{}
	)

	var port_export_balance_state = resources.get_state(
		"net_balance",
		{}
	)

	var actual_export_stockpile := float(
		port_export_stockpile_state.get(
			test_resource,
			-1.0
		)
	)

	var actual_export_balance := float(
		port_export_balance_state.get(
			test_resource,
			-1.0
		)
	)

	# Produced = 20, requested exports = 20, ports = 50%, so only
	# 10 are exported and 10 remain in country stockpile.
	var export_throughput_pass := (
		is_equal_approx(actual_export_stockpile, 10.0)
		and is_equal_approx(actual_export_balance, 10.0)
	)

	TestLogger.write_line(
		"50% port export throughput: "
		+ (
			"PASS"
			if export_throughput_pass
			else "FAIL"
		)
		+ " | expected_stockpile=10.0 actual_stockpile="
		+ str(actual_export_stockpile)
		+ " expected_net_balance=10.0 actual_net_balance="
		+ str(actual_export_balance)
	)

	if not export_throughput_pass:
		all_passed = false

	var ports_infrastructure_pass := (
		import_throughput_pass
		and export_throughput_pass
	)

	TestLogger.write_line(
		"Ports infrastructure bottleneck: "
		+ (
			"PASS"
			if ports_infrastructure_pass
			else "FAIL"
		)
	)

	if not ports_infrastructure_pass:
		all_passed = false


	# ============================================================
	# 23. STORAGE / MAXIMUM STOCKPILE CAPACITY
	# ============================================================

	TestLogger.section(
		"23. STORAGE / MAXIMUM STOCKPILE CAPACITY"
	)

	# Storage capacity is represented as an absolute maximum stockpile
	# amount for this test. ResourceSystem should enforce the limit after
	# production/import supply is added and before final stockpile state.
	#
	# Controlled coal capacity = 10 units.
	# This section intentionally defines the required behavior before
	# ResourceSystem integration, so failures are expected at this stage.

	var storage_production = original_production.duplicate(true)
	var storage_consumption = original_consumption.duplicate(true)
	var storage_imports = original_imports.duplicate(true)
	var storage_exports = original_exports.duplicate(true)
	var storage_extraction = original_extraction.duplicate(true)
	var storage_processing = original_processing.duplicate(true)
	var storage_efficiency = original_production_efficiency.duplicate(true)
	var storage_technology = original_technology_efficiency.duplicate(true)
	var storage_infrastructure = original_infrastructure_capacity.duplicate(true)
	var storage_quality = original_quality.duplicate(true)
	var storage_accessibility = original_accessibility.duplicate(true)
	var storage_reserves = original_reserves.duplicate(true)
	var storage_stockpile = original_stockpile.duplicate(true)
	var storage_max_capacity = original_max_stockpile_capacity.duplicate(true)

	storage_efficiency[test_resource] = 1.0
	storage_technology[test_resource] = 1.0
	storage_infrastructure[test_resource] = 1.0
	storage_quality[test_resource] = 1.0
	storage_accessibility[test_resource] = 1.0
	storage_max_capacity[test_resource] = 10.0
	storage_exports[test_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_consumption[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("production", storage_production)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("production_efficiency", storage_efficiency)
	resources.set_state("technology_efficiency", storage_technology)
	resources.set_state("infrastructure_capacity", storage_infrastructure)
	resources.set_state("quality", storage_quality)
	resources.set_state("accessibility", storage_accessibility)
	resources.set_state("reserves", storage_reserves)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("max_stockpile_capacity", storage_max_capacity)

	# ------------------------------------------------------------
	# 23.1 Stockpile below maximum capacity
	# ------------------------------------------------------------

	storage_production[test_resource] = 2.0
	storage_extraction[test_resource] = 2.0
	storage_processing[test_resource] = 2.0
	storage_stockpile[test_resource] = 5.0
	storage_consumption[test_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	var storage_state = resources.get_state("stockpile", {})
	var actual_storage_below_capacity = float(
		storage_state.get(test_resource, -1.0)
	)
	var storage_below_capacity_pass = is_equal_approx(
		actual_storage_below_capacity,
		7.0
	)

	TestLogger.write_line(
		"Stockpile below capacity: "
		+ ("PASS" if storage_below_capacity_pass else "FAIL")
		+ " | expected=7.0 actual="
		+ str(actual_storage_below_capacity)
	)

	if not storage_below_capacity_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.2 Production overflow
	# ------------------------------------------------------------

	storage_production[test_resource] = 5.0
	storage_extraction[test_resource] = 5.0
	storage_processing[test_resource] = 5.0
	storage_stockpile[test_resource] = 8.0
	storage_consumption[test_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	storage_state = resources.get_state("stockpile", {})
	var actual_production_overflow_stockpile = float(
		storage_state.get(test_resource, -1.0)
	)
	var production_overflow_pass = is_equal_approx(
		actual_production_overflow_stockpile,
		10.0
	)

	TestLogger.write_line(
		"Production overflow capped: "
		+ ("PASS" if production_overflow_pass else "FAIL")
		+ " | expected_stockpile=10.0 actual_stockpile="
		+ str(actual_production_overflow_stockpile)
	)

	if not production_overflow_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.3 Import overflow
	# ------------------------------------------------------------

	storage_production[test_resource] = 0.0
	storage_extraction[test_resource] = 0.0
	storage_processing[test_resource] = 0.0
	storage_stockpile[test_resource] = 7.0
	storage_consumption[test_resource] = 0.0
	storage_imports[test_resource] = 6.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	storage_state = resources.get_state("stockpile", {})
	var actual_import_overflow_stockpile = float(
		storage_state.get(test_resource, -1.0)
	)
	var import_overflow_pass = is_equal_approx(
		actual_import_overflow_stockpile,
		10.0
	)

	TestLogger.write_line(
		"Import overflow capped: "
		+ ("PASS" if import_overflow_pass else "FAIL")
		+ " | expected_stockpile=10.0 actual_stockpile="
		+ str(actual_import_overflow_stockpile)
	)

	if not import_overflow_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.4 Consumption frees storage before new supply
	# ------------------------------------------------------------

	storage_production[test_resource] = 6.0
	storage_extraction[test_resource] = 6.0
	storage_processing[test_resource] = 6.0
	storage_stockpile[test_resource] = 10.0
	storage_consumption[test_resource] = 4.0
	storage_imports[test_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	storage_state = resources.get_state("stockpile", {})
	var actual_consumption_recovery_stockpile = float(
		storage_state.get(test_resource, -1.0)
	)
	var consumption_recovery_pass = is_equal_approx(
		actual_consumption_recovery_stockpile,
		10.0
	)

	TestLogger.write_line(
		"Consumption frees storage: "
		+ ("PASS" if consumption_recovery_pass else "FAIL")
		+ " | expected_stockpile=10.0 actual_stockpile="
		+ str(actual_consumption_recovery_stockpile)
	)

	if not consumption_recovery_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.5 Zero storage capacity blocks stockpiling
	# ------------------------------------------------------------

	storage_max_capacity[test_resource] = 0.0
	storage_production[test_resource] = 5.0
	storage_extraction[test_resource] = 5.0
	storage_processing[test_resource] = 5.0
	storage_stockpile[test_resource] = 0.0
	storage_consumption[test_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("max_stockpile_capacity", storage_max_capacity)
	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	storage_state = resources.get_state("stockpile", {})
	var actual_zero_capacity_stockpile = float(
		storage_state.get(test_resource, -1.0)
	)
	var zero_capacity_pass = is_equal_approx(
		actual_zero_capacity_stockpile,
		0.0
	)

	TestLogger.write_line(
		"Zero storage capacity blocks stockpiling: "
		+ ("PASS" if zero_capacity_pass else "FAIL")
		+ " | expected_stockpile=0.0 actual_stockpile="
		+ str(actual_zero_capacity_stockpile)
	)

	if not zero_capacity_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.6 Multi-resource independence
	# ------------------------------------------------------------

	var secondary_resource = "oil"
	storage_max_capacity[test_resource] = 10.0
	storage_max_capacity[secondary_resource] = 30.0
	storage_production[test_resource] = 15.0
	storage_production[secondary_resource] = 15.0
	storage_extraction[test_resource] = 15.0
	storage_extraction[secondary_resource] = 15.0
	storage_processing[test_resource] = 15.0
	storage_processing[secondary_resource] = 15.0

	# Neutralize oil's existing resource-specific modifiers so this
	# subsection isolates storage behavior rather than production
	# efficiency/accessibility from the world fixture.
	storage_efficiency[secondary_resource] = 1.0
	storage_technology[secondary_resource] = 1.0
	storage_infrastructure[secondary_resource] = 1.0
	storage_quality[secondary_resource] = 1.0
	storage_accessibility[secondary_resource] = 1.0
	storage_stockpile[test_resource] = 0.0
	storage_stockpile[secondary_resource] = 0.0
	storage_consumption[test_resource] = 0.0
	storage_consumption[secondary_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_imports[secondary_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_exports[secondary_resource] = 0.0
	storage_reserves[test_resource] = 100.0
	storage_reserves[secondary_resource] = 100.0

	resources.set_state("max_stockpile_capacity", storage_max_capacity)
	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	storage_state = resources.get_state("stockpile", {})
	var actual_coal_independence = float(
		storage_state.get(test_resource, -1.0)
	)
	var actual_oil_independence = float(
		storage_state.get(secondary_resource, -1.0)
	)
	var multi_resource_storage_pass = (
		is_equal_approx(actual_coal_independence, 10.0)
		and is_equal_approx(actual_oil_independence, 15.0)
	)

	TestLogger.write_line(
		"Multi-resource storage independence: "
		+ ("PASS" if multi_resource_storage_pass else "FAIL")
		+ " | coal_expected=10.0 coal_actual="
		+ str(actual_coal_independence)
		+ " oil_expected=15.0 oil_actual="
		+ str(actual_oil_independence)
	)

	if not multi_resource_storage_pass:
		all_passed = false

	# ------------------------------------------------------------
	# 23.7 Explicit storage overflow accounting
	# ------------------------------------------------------------

	TestLogger.section(
		"23.7 STORAGE OVERFLOW ACCOUNTING"
	)

	# Capacity = 10, starting stockpile = 8, production = 5.
	# Supply before storage limit = 13.
	# Final stockpile = 10.
	# Explicit overflow = 3.

	storage_max_capacity[test_resource] = 10.0
	storage_production[test_resource] = 5.0
	storage_extraction[test_resource] = 5.0
	storage_processing[test_resource] = 5.0
	storage_stockpile[test_resource] = 8.0
	storage_consumption[test_resource] = 0.0
	storage_imports[test_resource] = 0.0
	storage_exports[test_resource] = 0.0
	storage_reserves[test_resource] = 100.0

	resources.set_state("max_stockpile_capacity", storage_max_capacity)
	resources.set_state("production", storage_production)
	resources.set_state("extraction_capacity", storage_extraction)
	resources.set_state("processing_capacity", storage_processing)
	resources.set_state("stockpile", storage_stockpile)
	resources.set_state("consumption", storage_consumption)
	resources.set_state("imports", storage_imports)
	resources.set_state("exports", storage_exports)
	resources.set_state("reserves", storage_reserves)

	resource_system.process_month(world)

	var overflow_stockpile_state = resources.get_state("stockpile", {})
	var overflow_state = resources.get_state("storage_overflow", {})

	var actual_overflow_stockpile = float(
		overflow_stockpile_state.get(test_resource, -1.0)
	)
	var actual_storage_overflow = float(
		overflow_state.get(test_resource, -1.0)
	)

	var overflow_stockpile_pass = is_equal_approx(
		actual_overflow_stockpile,
		10.0
	)
	var storage_overflow_pass = is_equal_approx(
		actual_storage_overflow,
		3.0
	)

	TestLogger.write_line(
		"Overflow leaves stockpile at maximum capacity: "
		+ ("PASS" if overflow_stockpile_pass else "FAIL")
		+ " | expected_stockpile=10.0 actual_stockpile="
		+ str(actual_overflow_stockpile)
	)

	TestLogger.write_line(
		"Storage overflow explicitly recorded: "
		+ ("PASS" if storage_overflow_pass else "FAIL")
		+ " | expected_overflow=3.0 actual_overflow="
		+ str(actual_storage_overflow)
	)

	var storage_overflow_accounting_pass = (
		overflow_stockpile_pass
		and storage_overflow_pass
	)

	if not storage_overflow_accounting_pass:
		all_passed = false

	var maximum_stockpile_capacity_pass := (
		storage_below_capacity_pass
		and production_overflow_pass
		and import_overflow_pass
		and consumption_recovery_pass
		and zero_capacity_pass
		and multi_resource_storage_pass
	)

	TestLogger.write_line(
		"Maximum stockpile capacity: "
		+ ("PASS" if maximum_stockpile_capacity_pass else "FAIL")
	)

	TestLogger.write_line(
		"Storage overflow accounting: "
		+ ("PASS" if storage_overflow_accounting_pass else "FAIL")
	)

	# RESTORE ORIGINAL STATE
	# ============================================================

	resources.set_state(
		"production",
		original_production
	)

	resources.set_state(
		"consumption",
		original_consumption
	)

	resources.set_state(
		"imports",
		original_imports
	)

	resources.set_state(
		"exports",
		original_exports
	)

	resources.set_state(
		"extraction_capacity",
		original_extraction
	)

	resources.set_state(
	"processing_capacity",
	original_processing
)

	resources.set_state(
	"production_efficiency",
	original_production_efficiency
)

	resources.set_state(
	"technology_efficiency",
	original_technology_efficiency
)

	resources.set_state(
	"infrastructure_capacity",
	original_infrastructure_capacity
)

	resources.set_state(
	"quality",
	original_quality
)

	resources.set_state(
	"accessibility",
	original_accessibility
)

	infrastructure_component.set_state(
		"transport",
		original_specialized_infrastructure
)

	infrastructure_component.set_state(
		"roads",
		original_roads_infrastructure
	)

	infrastructure_component.set_state(
		"railways",
		original_railways_infrastructure
	)

	infrastructure_component.set_state(
		"ports",
		original_ports_infrastructure
	)

	infrastructure_component.set_state(
		"power",
		original_power_infrastructure
	)

	resources.set_state(
	"actual_production",
	original_actual_production
)

	resources.set_state(
	"reserves",
	original_reserves
)

	resources.set_state(
	"stockpile",
	original_stockpile
)

	resources.set_state(
	"net_balance",
	original_net_balance
)

	resources.set_state(
	"shortages",
	original_shortages
)

	resources.set_state(
	"shortage_ratio",
	original_shortage_ratio
)

	resources.set_state(
	"reserve_depletion",
	original_reserve_depletion
)

	resources.set_state(
	"surplus",
	original_surplus
)

	resources.set_state(
	"reserve_ratio",
	original_reserve_ratio
)

	resources.set_state(
	"max_stockpile_capacity",
	original_max_stockpile_capacity
)

	resources.set_state(
	"storage_overflow",
	original_storage_overflow
)

	TestLogger.write_line(
	"Original resource state restored: PASS"
)


	# ============================================================
	# RESULT
	# ============================================================

	TestLogger.section(
		"RESOURCE SYSTEM TEST RESULT"
	)

	TestLogger.write_line(
		"Capacity initialization: "
		+ (
			"PASS"
			if capacity_initialization_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Extraction constraint: "
		+ (
			"PASS"
			if extraction_constraint_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Processing constraint: "
		+ (
			"PASS"
			if processing_constraint_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Minimum capacity: "
		+ (
			"PASS"
			if minimum_capacity_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Production efficiency: "
		+ (
			"PASS"
			if efficiency_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Technology efficiency: "
		+ (
			"PASS"
			if technology_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Integrated production calculation: "
		+ (
			"PASS"
			if integrated_production_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Supply / shortage calculation: "
		+ (
			"PASS"
			if supply_shortage_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Surplus calculation: "
		+ (
			"PASS"
			if surplus_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Net balance: "
		+ (
			"PASS"
			if net_balance_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Reserve depletion / reserve ratio: "
		+ (
			"PASS"
			if reserve_depletion_ratio_pass
			else "FAIL"
		)
	)


	TestLogger.write_line(
		"Resource-effect modifiers: "
		+ (
			"PASS"
			if resource_effect_modifiers_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Multi-resource independence: "
		+ (
			"PASS"
			if multi_resource_independence_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Full monthly lifecycle: "
		+ (
			"PASS"
			if full_lifecycle_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Infrastructure capacity: "
		+ (
			"PASS"
			if infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Resource quality: "
		+ (
			"PASS"
			if quality_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Resource accessibility: "
		+ (
			"PASS"
			if accessibility_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Transport infrastructure: "
		+ (
			"PASS"
			if transport_infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Roads infrastructure: "
		+ (
			"PASS"
			if roads_infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Railways infrastructure: "
		+ (
			"PASS"
			if railways_infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Power infrastructure: "
		+ (
			"PASS"
			if power_infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Ports infrastructure: "
		+ (
			"PASS"
			if ports_infrastructure_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Maximum stockpile capacity: "
		+ (
			"PASS"
			if maximum_stockpile_capacity_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Storage overflow accounting: "
		+ (
			"PASS"
			if storage_overflow_accounting_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Reserves / stockpile separation: "
		+ (
			"PASS"
			if reserves_stockpile_pass
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Resource System test passed: "
		+ str(all_passed)
	)

	return all_passed
