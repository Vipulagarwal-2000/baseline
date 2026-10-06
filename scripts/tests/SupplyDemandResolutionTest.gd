class_name SupplyDemandResolutionTest
extends RefCounted


static func _approx_equal(actual: float, expected: float) -> bool:
	return is_equal_approx(actual, expected)


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation
) -> bool:

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var system = simulation.get_system(
		"supply_demand_resolution_system"
	)

	var registered_system_passed: bool = (
		system != null
		and system is SupplyDemandResolutionSystem
	)

	_log_result(
		"Registered SupplyDemandResolutionSystem available",
		registered_system_passed
	)
	all_passed = all_passed and registered_system_passed

	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_5_supply_demand_test",
		"Step 5.5 Supply Demand Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)
	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# ------------------------------------------------------------
	# Case 1 — supply exceeds combined domestic + export demand.
	# ------------------------------------------------------------
	resources.set_state(
		"available_supply",
		{
			"iron": 100.0,
			"coal": 40.0
		}
	)
	resources.set_state(
		"actual_consumption",
		{
			"iron": 60.0,
			"coal": 10.0
		}
	)
	resources.set_state(
		"exports",
		{
			"iron": 20.0,
			"coal": 5.0
		}
	)
	resources.set_state(
		"aggregate_demand",
		{
			"iron": 80.0,
			"coal": 15.0
		}
	)

	system.process_month(world)

	var resolved_supply: Dictionary = resources.get_state(
		"resolved_supply",
		{}
	)
	var resolved_demand: Dictionary = resources.get_state(
		"resolved_demand",
		{}
	)
	var fulfilled: Dictionary = resources.get_state(
		"resolved_fulfilled_demand",
		{}
	)
	var unmet: Dictionary = resources.get_state(
		"resolved_unmet_demand",
		{}
	)
	var surplus: Dictionary = resources.get_state(
		"resolved_surplus",
		{}
	)
	var ratios: Dictionary = resources.get_state(
		"resolved_shortage_ratio",
		{}
	)
	var ledger: Dictionary = resources.get_state(
		"supply_demand_ledger",
		{}
	)

	var surplus_case_passed: bool = (
		_approx_equal(float(resolved_supply.get("iron", -1.0)), 100.0)
		and _approx_equal(float(resolved_demand.get("iron", -1.0)), 80.0)
		and _approx_equal(float(fulfilled.get("iron", -1.0)), 80.0)
		and _approx_equal(float(unmet.get("iron", -1.0)), 0.0)
		and _approx_equal(float(surplus.get("iron", -1.0)), 20.0)
		and _approx_equal(float(ratios.get("iron", -1.0)), 0.0)
		and _approx_equal(float(ledger.get("iron", {}).get("reconciliation_error", 999.0)), 0.0)
	)

	_log_result(
		"Supply exceeds demand and leaves a surplus",
		surplus_case_passed
	)
	all_passed = all_passed and surplus_case_passed

	var category_combination_passed: bool = (
		_approx_equal(float(ledger.get("iron", {}).get("domestic_demand", -1.0)), 60.0)
		and _approx_equal(float(ledger.get("iron", {}).get("export_demand", -1.0)), 20.0)
		and _approx_equal(float(ledger.get("iron", {}).get("resolved_demand", -1.0)), 80.0)
	)

	_log_result(
		"Domestic and export demand combine without double-counting",
		category_combination_passed
	)
	all_passed = all_passed and category_combination_passed

	# ------------------------------------------------------------
	# Case 2 — demand exceeds supply.
	# ------------------------------------------------------------
	resources.set_state(
		"available_supply",
		{
			"iron": 50.0
		}
	)
	resources.set_state(
		"actual_consumption",
		{
			"iron": 60.0
		}
	)
	resources.set_state(
		"exports",
		{
			"iron": 20.0
		}
	)
	resources.set_state(
		"aggregate_demand",
		{
			"iron": 80.0
		}
	)

	system.process_month(world)

	resolved_demand = resources.get_state("resolved_demand", {})
	fulfilled = resources.get_state("resolved_fulfilled_demand", {})
	unmet = resources.get_state("resolved_unmet_demand", {})
	surplus = resources.get_state("resolved_surplus", {})
	ratios = resources.get_state("resolved_shortage_ratio", {})
	ledger = resources.get_state("supply_demand_ledger", {})

	var shortage_case_passed: bool = (
		_approx_equal(float(resolved_demand.get("iron", -1.0)), 80.0)
		and _approx_equal(float(fulfilled.get("iron", -1.0)), 50.0)
		and _approx_equal(float(unmet.get("iron", -1.0)), 30.0)
		and _approx_equal(float(surplus.get("iron", -1.0)), 0.0)
		and _approx_equal(float(ratios.get("iron", -1.0)), 37.5)
		and _approx_equal(float(ledger.get("iron", {}).get("reconciliation_error", 999.0)), 0.0)
	)

	_log_result(
		"Demand exceeds supply and records unmet demand",
		shortage_case_passed
	)
	all_passed = all_passed and shortage_case_passed

	# ------------------------------------------------------------
	# Case 3 — zero demand produces a pure supply surplus.
	# ------------------------------------------------------------
	resources.set_state(
		"available_supply",
		{
			"oil": 25.0
		}
	)
	resources.set_state(
		"actual_consumption",
		{}
	)
	resources.set_state(
		"exports",
		{}
	)
	resources.set_state(
		"aggregate_demand",
		{}
	)

	system.process_month(world)

	var zero_demand_fulfilled: Dictionary = resources.get_state(
		"resolved_fulfilled_demand",
		{}
	)
	var zero_demand_unmet: Dictionary = resources.get_state(
		"resolved_unmet_demand",
		{}
	)
	var zero_demand_surplus: Dictionary = resources.get_state(
		"resolved_surplus",
		{}
	)

	var zero_demand_passed: bool = (
		_approx_equal(float(zero_demand_fulfilled.get("oil", -1.0)), 0.0)
		and _approx_equal(float(zero_demand_unmet.get("oil", -1.0)), 0.0)
		and _approx_equal(float(zero_demand_surplus.get("oil", -1.0)), 25.0)
	)

	_log_result(
		"Zero demand produces no shortage and preserves supply as surplus",
		zero_demand_passed
	)
	all_passed = all_passed and zero_demand_passed

	# ------------------------------------------------------------
	# Case 4 — resolution must not mutate the physical stockpile or the
	# Step 5.4 consumption request.
	# ------------------------------------------------------------
	resources.set_state(
		"stockpile",
		{
			"iron": 30.0
		}
	)
	resources.set_state(
		"available_supply",
		{
			"iron": 30.0
		}
	)
	resources.set_state(
		"actual_consumption",
		{
			"iron": 20.0
		}
	)
	resources.set_state(
		"consumption",
		{
			"iron": 20.0
		}
	)
	resources.set_state(
		"exports",
		{}
	)
	resources.set_state(
		"aggregate_demand",
		{
			"iron": 20.0
		}
	)

	system.process_month(world)

	var state_preservation_passed: bool = (
		_approx_equal(
			float(resources.get_state("stockpile", {}).get("iron", -1.0)),
			30.0
		)
		and _approx_equal(
			float(resources.get_state("consumption", {}).get("iron", -1.0)),
			20.0
		)
	)

	_log_result(
		"Resolution does not mutate physical stockpile or consumption request",
		state_preservation_passed
	)
	all_passed = all_passed and state_preservation_passed

	# ------------------------------------------------------------
	# Case 5 — stale resolution state clears when no resource inputs remain.
	# ------------------------------------------------------------
	resources.set_state("available_supply", {})
	resources.set_state("actual_consumption", {})
	resources.set_state("exports", {})
	resources.set_state("aggregate_demand", {})

	system.process_month(world)

	var stale_clear_passed: bool = (
		resources.get_state("resolved_supply", {}).is_empty()
		and resources.get_state("resolved_demand", {}).is_empty()
		and _approx_equal(
			float(resources.get_state("supply_demand_total_supply", -1.0)),
			0.0
		)
		and _approx_equal(
			float(resources.get_state("supply_demand_total_demand", -1.0)),
			0.0
		)
	)

	_log_result(
		"Supply/demand resolution does not retain stale previous-cycle values",
		stale_clear_passed
	)
	all_passed = all_passed and stale_clear_passed

	# Restore exact world entity dictionary.
	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	_log_result(
		"Step 5.5 fixture state restored",
		true
	)

	TestLogger.write_line(
		"Supply / Demand Resolution 5.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
