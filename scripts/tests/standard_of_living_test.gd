class_name StandardOfLivingTest
extends RefCounted


# ============================================================
# POPULATION — STEP 9.1 TEST
# ============================================================
# Validates:
# - registered system
# - aggregate standard-of-living index
# - existing income / resource / labor / public-service inputs
# - deterministic calculation
# - repeated processing idempotence
# - stale resource-input clearing
# - WorldSnapshot representation
# - snapshot deep-copy isolation
# - population state restoration
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STANDARD OF LIVING 9.1 TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation available: PASS"
	)

	var system_instance = simulation.get_system(
		"standard_of_living_system"
	)

	var system_ok: bool = (
		system_instance != null
		and system_instance is StandardOfLivingSystem
	)

	TestLogger.write_line(
		"Registered StandardOfLivingSystem available: "
		+ (
			"PASS"
			if system_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and system_ok

	if not system_ok:
		return false

	var system: StandardOfLivingSystem = (
		system_instance as StandardOfLivingSystem
	)

	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var population = india.get_component(
		"population"
	)

	var economy = india.get_component(
		"economy"
	)

	var resources = india.get_component(
		"resources"
	)

	var government = india.get_component(
		"government"
	)

	var components_ok: bool = (
		population != null
		and economy != null
		and resources != null
		and government != null
	)

	TestLogger.write_line(
		"India population/economy/resources/government components available: "
		+ (
			"PASS"
			if components_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and components_ok

	if not components_ok:
		return false

	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)
	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)
	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)
	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# Controlled fixture
	# ------------------------------------------------------------

	economy.set_state(
		"income_coverage_ratio",
		0.80
	)
	economy.set_state(
		"purchasing_power_index",
		0.80
	)
	economy.set_state(
		"consumption_price_index",
		1.20
	)

	population.set_state(
		"labor_state",
		{
			"labor_force": 100.0,
			"employed_labor": 90.0
		}
	)

	resources.set_state(
		"population_resource_demand",
		{
			"food": 100.0,
			"coal": 20.0,
			"oil": 10.0
		}
	)

	resources.set_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{
			"food": {
				"population": 0.75
			},
			"coal": {
				"population": 0.60
			},
			"oil": {
				"population": 0.90
			}
		}
	)

	resources.set_state(
		"actual_consumption",
		{
			"food": 75.0,
			"coal": 12.0,
			"oil": 9.0
		}
	)

	government.set_state(
		"public_service_capacity",
		0.50
	)

	system.process_month(
		world
	)

	var income_score := float(
		population.get_state(
			"standard_of_living_income_score",
			-1.0
		)
	)

	var food_score := float(
		population.get_state(
			"standard_of_living_food_availability",
			-1.0
		)
	)

	var essential_score := float(
		population.get_state(
			"standard_of_living_essential_goods_availability",
			-1.0
		)
	)

	var employment_score := float(
		population.get_state(
			"standard_of_living_employment_score",
			-1.0
		)
	)

	var public_service_score := float(
		population.get_state(
			"standard_of_living_public_service_score",
			-1.0
		)
	)

	var price_pressure := float(
		population.get_state(
			"standard_of_living_price_pressure",
			-1.0
		)
	)

	var expected_index := (
		0.80
		+ 0.75
		+ 0.70
		+ 0.90
		+ 0.50
		- 0.20
	) / 5.0

	var actual_index := float(
		population.get_state(
			"standard_of_living_index",
			-1.0
		)
	)

	var formula_ok: bool = (
		is_equal_approx(
			income_score,
			0.80
		)
		and is_equal_approx(
			food_score,
			0.75
		)
		and is_equal_approx(
			essential_score,
			0.70
		)
		and is_equal_approx(
			employment_score,
			0.90
		)
		and is_equal_approx(
			public_service_score,
			0.50
		)
		and is_equal_approx(
			price_pressure,
			0.20
		)
		and is_equal_approx(
			actual_index,
			expected_index
		)
	)

	TestLogger.write_line(
		"Controlled Step 9.1 standard-of-living formula resolves deterministically: "
		+ (
			"PASS"
			if formula_ok
			else "FAIL"
		)
		+ " | expected="
		+ str(expected_index)
		+ " actual="
		+ str(actual_index)
	)

	all_passed = all_passed and formula_ok

	var revision_before_repeat := int(
		population.get_state(
			"standard_of_living_revision",
			0
		)
	)

	system.process_month(
		world
	)

	var repeated_index := float(
		population.get_state(
			"standard_of_living_index",
			-1.0
		)
	)

	var repeated_revision := int(
		population.get_state(
			"standard_of_living_revision",
			0
		)
	)

	var idempotent_ok: bool = (
		is_equal_approx(
			repeated_index,
			expected_index
		)
		and repeated_revision == revision_before_repeat
	)

	TestLogger.write_line(
		"Repeated standard-of-living processing is idempotent: "
		+ (
			"PASS"
			if idempotent_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and idempotent_ok

	# ------------------------------------------------------------
	# Stale-state clearing:
	# remove all non-food population demand and fulfillment state.
	# The system must recompute essential-goods availability rather
	# than retain the prior 0.70 value.
	# ------------------------------------------------------------

	resources.set_state(
		"population_resource_demand",
		{
			"food": 100.0
		}
	)

	resources.set_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{
			"food": {
				"population": 0.40
			}
		}
	)

	resources.set_state(
		"actual_consumption",
		{
			"food": 40.0
		}
	)

	system.process_month(
		world
	)

	var stale_cleared_essential := float(
		population.get_state(
			"standard_of_living_essential_goods_availability",
			-1.0
		)
	)

	var stale_clearing_ok: bool = (
		is_equal_approx(
			stale_cleared_essential,
			0.40
		)
	)

	TestLogger.write_line(
		"Clearing non-food population demand clears stale essential-goods state: "
		+ (
			"PASS"
			if stale_clearing_ok
			else "FAIL"
		)
		+ " | actual="
		+ str(stale_cleared_essential)
	)

	all_passed = all_passed and stale_clearing_ok

	var ledger = population.get_state(
		"standard_of_living_ledger",
		{}
	)

	var ledger_ok: bool = (
		ledger is Dictionary
		and ledger.has("income_score")
		and ledger.has("food_availability")
		and ledger.has("essential_goods_availability")
		and ledger.has("employment_score")
		and ledger.has("public_service_score")
		and ledger.has("price_pressure")
		and ledger.has("standard_of_living_index")
	)

	TestLogger.write_line(
		"Standard-of-living ledger and result state are explicit: "
		+ (
			"PASS"
			if ledger_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and ledger_ok

	var snapshot := WorldSnapshot.new()
	snapshot.capture(
		world
	)

	var entity_snapshot = snapshot.entities.get(
		"india",
		{}
	)

	var snapshot_components = entity_snapshot.get(
		"components",
		{}
	)

	var snapshot_population = snapshot_components.get(
		"population",
		{}
	)

	var snapshot_state = snapshot_population.get(
		"state",
		{}
	)

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has(
			"standard_of_living_index"
		)
		and snapshot_state.has(
			"standard_of_living_ledger"
		)
		and snapshot_state.has(
			"standard_of_living_revision"
		)
	)

	TestLogger.write_line(
		"WorldSnapshot preserves standard-of-living state: "
		+ (
			"PASS"
			if snapshot_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_ok

	var live_index := float(
		population.get_state(
			"standard_of_living_index",
			0.0
		)
	)

	if snapshot_state is Dictionary:
		snapshot_state[
			"standard_of_living_index"
		] = -999.0

	var snapshot_isolated_ok: bool = is_equal_approx(
		population.get_state(
			"standard_of_living_index",
			0.0
		),
		live_index
	)

	TestLogger.write_line(
		"WorldSnapshot standard-of-living state is deep-copy isolated: "
		+ (
			"PASS"
			if snapshot_isolated_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_isolated_ok

	population.state = original_population_state
	economy.state = original_economy_state
	resources.state = original_resource_state
	government.state = original_government_state

	var restored_ok: bool = (
		population.state == original_population_state
		and economy.state == original_economy_state
		and resources.state == original_resource_state
		and government.state == original_government_state
	)

	TestLogger.write_line(
		"Step 9.1 population/economy/resource/government state restoration: "
		+ (
			"PASS"
			if restored_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and restored_ok

	return all_passed
