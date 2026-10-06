class_name IncomeConsumptionFeedbackTest
extends RefCounted


# ============================================================
# POPULATION — STEP 9.3 TEST
# INCOME -> PURCHASING POWER -> CONSUMPTION
# ============================================================
#
# Validates:
# - registered Step 9.3 system
# - bounded consumption-demand factor from existing purchasing-power state
# - AggregateDemandSystem consumes the factor
# - AggregateConsumptionSystem receives the scaled population demand
# - baseline demand remains intact above full affordability
# - idempotence
# - ledger/result state
# - WorldSnapshot representation
# - snapshot deep-copy isolation
# - state restoration
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INCOME -> PURCHASING POWER -> CONSUMPTION 9.3 TEST"
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

	var feedback_instance = simulation.get_system(
		"income_consumption_feedback_system"
	)

	var feedback_ok: bool = (
		feedback_instance != null
		and feedback_instance is IncomeConsumptionFeedbackSystem
	)

	TestLogger.write_line(
		"Registered IncomeConsumptionFeedbackSystem available: "
		+ (
			"PASS"
			if feedback_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and feedback_ok

	var demand_instance = simulation.get_system(
		"aggregate_demand_system"
	)

	var demand_ok: bool = (
		demand_instance != null
		and demand_instance is AggregateDemandSystem
	)

	TestLogger.write_line(
		"Registered AggregateDemandSystem available: "
		+ (
			"PASS"
			if demand_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and demand_ok

	var consumption_instance = simulation.get_system(
		"aggregate_consumption_system"
	)

	var consumption_ok: bool = (
		consumption_instance != null
		and consumption_instance is AggregateConsumptionSystem
	)

	TestLogger.write_line(
		"Registered AggregateConsumptionSystem available: "
		+ (
			"PASS"
			if consumption_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and consumption_ok

	if not feedback_ok or not demand_ok or not consumption_ok:
		return false

	var feedback: IncomeConsumptionFeedbackSystem = (
		feedback_instance as IncomeConsumptionFeedbackSystem
	)
	var demand_system: AggregateDemandSystem = (
		demand_instance as AggregateDemandSystem
	)
	var consumption_system: AggregateConsumptionSystem = (
		consumption_instance as AggregateConsumptionSystem
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

	var economy = india.get_component(
		"economy"
	)
	var resources = india.get_component(
		"resources"
	)

	var components_ok: bool = (
		economy != null
		and resources != null
	)

	TestLogger.write_line(
		"India economy/resources components available: "
		+ (
			"PASS"
			if components_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and components_ok

	if not components_ok:
		return false

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)
	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# Controlled upstream purchasing-power fixture
	# ------------------------------------------------------------

	economy.set_state(
		"population_consumption_cost",
		100.0
	)
	economy.set_state(
		"income_coverage_ratio",
		0.50
	)
	economy.set_state(
		"purchasing_power_index",
		0.80
	)

	feedback.process_month(
		world
	)

	var factor := float(
		economy.get_state(
			"population_consumption_demand_factor",
			-1.0
		)
	)

	var factor_ok: bool = is_equal_approx(
		factor,
		0.50
	)

	TestLogger.write_line(
		"Purchasing power resolves bounded consumption factor: "
		+ (
			"PASS"
			if factor_ok
			else "FAIL"
		)
		+ " | expected=0.5 actual="
		+ str(factor)
	)

	all_passed = all_passed and factor_ok

	# ------------------------------------------------------------
	# Population demand -> effective aggregate demand
	# ------------------------------------------------------------

	resources.set_state(
		"population_resource_demand",
		{
			"food": 100.0,
			"cloth": 40.0
		}
	)

	# Keep the already-verified baseline consumption path active.
	resources.set_state(
		"allocation_consequence_allocated_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_unmet_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_fulfillment_ratio_by_category",
		{}
	)

	demand_system.process_month(
		world
	)

	var aggregate_by_category_value: Variant = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)

	var population_aggregate: Dictionary = {}

	if aggregate_by_category_value is Dictionary:
		var category_map: Dictionary = aggregate_by_category_value
		var value: Variant = category_map.get(
			"population",
			{}
		)
		if value is Dictionary:
			population_aggregate = value

	var food_effective := float(
		population_aggregate.get(
			"food",
			0.0
		)
	)
	var cloth_effective := float(
		population_aggregate.get(
			"cloth",
			0.0
		)
	)

	var effective_demand_ok: bool = (
		is_equal_approx(food_effective, 50.0)
		and is_equal_approx(cloth_effective, 20.0)
	)

	TestLogger.write_line(
		"Purchasing-power feedback scales population demand: "
		+ (
			"PASS"
			if effective_demand_ok
			else "FAIL"
		)
		+ " | food="
		+ str(food_effective)
		+ " cloth="
		+ str(cloth_effective)
	)

	all_passed = all_passed and effective_demand_ok

	# ------------------------------------------------------------
	# Consumption follows the adjusted demand
	# ------------------------------------------------------------

	consumption_system.process_month(
		world
	)

	var consumption_by_category_value: Variant = resources.get_state(
		"consumption_by_category",
		{}
	)
	var population_consumption: Dictionary = {}

	if consumption_by_category_value is Dictionary:
		var consumption_categories: Dictionary = (
			consumption_by_category_value
		)
		var value: Variant = consumption_categories.get(
			"population",
			{}
		)
		if value is Dictionary:
			population_consumption = value

	var consumed_food := float(
		population_consumption.get(
			"food",
			0.0
		)
	)
	var consumed_cloth := float(
		population_consumption.get(
			"cloth",
			0.0
		)
	)

	var adjusted_consumption_ok: bool = (
		is_equal_approx(consumed_food, 50.0)
		and is_equal_approx(consumed_cloth, 20.0)
	)

	TestLogger.write_line(
		"Adjusted population demand reaches aggregate consumption: "
		+ (
			"PASS"
			if adjusted_consumption_ok
			else "FAIL"
		)
		+ " | food="
		+ str(consumed_food)
		+ " cloth="
		+ str(consumed_cloth)
	)

	all_passed = all_passed and adjusted_consumption_ok

	# Baseline cannot expand above the original population demand.
	economy.set_state(
		"income_coverage_ratio",
		2.0
	)
	economy.set_state(
		"purchasing_power_index",
		2.0
	)

	feedback.process_month(
		world
	)

	var capped_factor := float(
		economy.get_state(
			"population_consumption_demand_factor",
			-1.0
		)
	)

	var capped_ok: bool = is_equal_approx(
		capped_factor,
		1.0
	)

	TestLogger.write_line(
		"High purchasing power does not create above-baseline consumption demand: "
		+ (
			"PASS"
			if capped_ok
			else "FAIL"
		)
		+ " | factor="
		+ str(capped_factor)
	)

	all_passed = all_passed and capped_ok

	# ------------------------------------------------------------
	# Idempotence
	# ------------------------------------------------------------

	var revision_before_repeat := int(
		economy.get_state(
			"population_consumption_feedback_revision",
			0
		)
	)

	feedback.process_month(
		world
	)

	var repeated_revision := int(
		economy.get_state(
			"population_consumption_feedback_revision",
			0
		)
	)

	var repeated_factor := float(
		economy.get_state(
			"population_consumption_demand_factor",
			-1.0
		)
	)

	var idempotent_ok: bool = (
		repeated_revision == revision_before_repeat
		and is_equal_approx(repeated_factor, 1.0)
	)

	TestLogger.write_line(
		"Repeated income-to-consumption feedback processing is idempotent: "
		+ (
			"PASS"
			if idempotent_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and idempotent_ok

	# ------------------------------------------------------------
	# Ledger / result state
	# ------------------------------------------------------------

	var ledger_value: Variant = economy.get_state(
		"population_consumption_feedback_ledger",
		{}
	)
	var last_result_value: Variant = economy.get_state(
		"population_consumption_feedback_last_result",
		{}
	)

	var ledger_result_ok: bool = (
		ledger_value is Dictionary
		and ledger_value.has("income_coverage_ratio")
		and ledger_value.has("purchasing_power_index")
		and ledger_value.has("consumption_demand_factor")
		and last_result_value is Dictionary
		and last_result_value.has("action")
		and last_result_value.has("revision")
		and last_result_value.has("inputs")
	)

	TestLogger.write_line(
		"Income-consumption feedback ledger and result state are explicit: "
		+ (
			"PASS"
			if ledger_result_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and ledger_result_ok

	# ------------------------------------------------------------
	# WorldSnapshot representation
	# ------------------------------------------------------------

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
	var snapshot_economy = snapshot_components.get(
		"economy",
		{}
	)
	var snapshot_state = snapshot_economy.get(
		"state",
		{}
	)

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has(
			"population_consumption_demand_factor"
		)
		and snapshot_state.has(
			"population_consumption_feedback_revision"
		)
		and snapshot_state.has(
			"population_consumption_feedback_ledger"
		)
	)

	TestLogger.write_line(
		"WorldSnapshot preserves income-consumption feedback state: "
		+ (
			"PASS"
			if snapshot_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_ok

	var live_factor := float(
		economy.get_state(
			"population_consumption_demand_factor",
			0.0
		)
	)

	if snapshot_state is Dictionary:
		snapshot_state[
			"population_consumption_demand_factor"
		] = -999.0

	var snapshot_isolated_ok: bool = is_equal_approx(
		economy.get_state(
			"population_consumption_demand_factor",
			0.0
		),
		live_factor
	)

	TestLogger.write_line(
		"WorldSnapshot income-consumption feedback state is deep-copy isolated: "
		+ (
			"PASS"
			if snapshot_isolated_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_isolated_ok

	# ------------------------------------------------------------
	# State restoration
	# ------------------------------------------------------------

	economy.state = original_economy_state
	resources.state = original_resource_state

	var restored_ok: bool = (
		economy.state == original_economy_state
		and resources.state == original_resource_state
	)

	TestLogger.write_line(
		"Step 9.3 economy/resource state restoration: "
		+ (
			"PASS"
			if restored_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and restored_ok

	return all_passed
