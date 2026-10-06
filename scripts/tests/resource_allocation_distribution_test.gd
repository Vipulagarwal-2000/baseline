class_name ResourceAllocationDistributionTest
extends RefCounted


static func _approx_equal(actual: float, expected: float) -> bool:
	return is_equal_approx(actual, expected)


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func run(world: WorldState, simulation) -> bool:

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
		"resource_allocation_distribution_system"
	)
	var registered_system_passed: bool = (
		system != null
		and system is ResourceAllocationDistributionSystem
	)

	_log_result(
		"Registered ResourceAllocationDistributionSystem available",
		registered_system_passed
	)
	all_passed = all_passed and registered_system_passed
	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_10_resource_allocation_test",
		"Step 5.10 Resource Allocation Test",
		"country"
	)

	var resources := ResourceComponent.new(test_entity.id)
	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	resources.set_state(
		"resolved_supply",
		{"coal": 100.0}
	)
	resources.set_state(
		"exports",
		{"coal": 20.0}
	)
	resources.set_state(
		"accessibility",
		{"coal": 1.0}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {"coal": 20.0},
			"industry": {"coal": 30.0},
			"government": {"coal": 10.0},
			"military": {"coal": 10.0},
			"exports": {"coal": 20.0}
		}
	)

	var original_supply: float = float(
		resources.get_state("resolved_supply", {}).get("coal", -1.0)
	)
	var original_exports: float = float(
		resources.get_state("exports", {}).get("coal", -1.0)
	)

	# Case 1: full accessibility. Twenty export units are reserved first;
	# the remaining 80 units can satisfy the 70 domestic demand units.
	system.process_month(world)

	var allocated_full: Dictionary = resources.get_state(
		"allocated_supply_by_category",
		{}
	)
	var unmet_full: Dictionary = resources.get_state(
		"allocation_unmet_by_category",
		{}
	)

	var full_access_passed: bool = (
		_approx_equal(
			float(resources.get_state("domestic_accessible_supply", {}).get("coal", -1.0)),
			80.0
		)
		and _approx_equal(
			float(resources.get_state("allocated_supply_total", {}).get("coal", -1.0)),
			70.0
		)
		and _approx_equal(
			float(allocated_full.get("population", {}).get("coal", -1.0)),
			20.0
		)
		and _approx_equal(
			float(allocated_full.get("industry", {}).get("coal", -1.0)),
			30.0
		)
		and _approx_equal(
			float(allocated_full.get("government", {}).get("coal", -1.0)),
			10.0
		)
		and _approx_equal(
			float(allocated_full.get("military", {}).get("coal", -1.0)),
			10.0
		)
		and _approx_equal(
			float(unmet_full.get("population", {}).get("coal", -1.0)),
			0.0
		)
		and _approx_equal(
			float(resources.get_state("unallocated_accessible_supply", {}).get("coal", -1.0)),
			10.0
		)
	)
	_log_result(
		"Full accessibility allocates available domestic supply without double-claiming exports",
		full_access_passed
	)
	all_passed = all_passed and full_access_passed

	# Case 2: accessibility becomes 50%. Allocation is proportional across
	# the existing domestic demand categories rather than inventing priority.
	resources.set_state(
		"accessibility",
		{"coal": 0.5}
	)
	system.process_month(world)

	var allocated_partial: Dictionary = resources.get_state(
		"allocated_supply_by_category",
		{}
	)
	var unmet_partial: Dictionary = resources.get_state(
		"allocation_unmet_by_category",
		{}
	)

	var partial_access_passed: bool = (
		_approx_equal(
			float(resources.get_state("domestic_accessible_supply", {}).get("coal", -1.0)),
			40.0
		)
		and _approx_equal(
			float(resources.get_state("allocated_supply_total", {}).get("coal", -1.0)),
			40.0
		)
		and _approx_equal(
			float(allocated_partial.get("population", {}).get("coal", -1.0)),
			40.0 * (20.0 / 70.0)
		)
		and _approx_equal(
			float(allocated_partial.get("industry", {}).get("coal", -1.0)),
			40.0 * (30.0 / 70.0)
		)
		and _approx_equal(
			float(allocated_partial.get("government", {}).get("coal", -1.0)),
			40.0 * (10.0 / 70.0)
		)
		and _approx_equal(
			float(allocated_partial.get("military", {}).get("coal", -1.0)),
			40.0 * (10.0 / 70.0)
		)
		and _approx_equal(
			float(resources.get_state("domestic_distribution_total_unmet", -1.0)),
			30.0
		)
		and _approx_equal(
			float(unmet_partial.get("industry", {}).get("coal", -1.0)),
			30.0 * (30.0 / 70.0)
		)
	)
	_log_result(
		"Reduced accessibility lowers effective domestic supply and allocates it proportionally",
		partial_access_passed
	)
	all_passed = all_passed and partial_access_passed

	# Case 3: zero accessibility blocks domestic distribution without
	# creating additional supply.
	resources.set_state(
		"accessibility",
		{"coal": 0.0}
	)
	system.process_month(world)

	var zero_access_passed: bool = (
		_approx_equal(
			float(resources.get_state("domestic_accessible_supply", {}).get("coal", -1.0)),
			0.0
		)
		and _approx_equal(
			float(resources.get_state("allocated_supply_total", {}).get("coal", -1.0)),
			0.0
		)
		and _approx_equal(
			float(resources.get_state("domestic_distribution_total_unmet", -1.0)),
			70.0
		)
	)
	_log_result(
		"Zero accessibility prevents domestic allocation safely",
		zero_access_passed
	)
	all_passed = all_passed and zero_access_passed

	# Case 4: malformed accessibility is bounded into the existing 0..1
	# access contract rather than creating impossible accessible supply.
	resources.set_state(
		"accessibility",
		{"coal": 2.0}
	)
	system.process_month(world)

	var bounded_access_passed: bool = (
		_approx_equal(
			float(resources.get_state("domestic_accessible_supply", {}).get("coal", -1.0)),
			80.0
		)
	)
	_log_result(
		"Accessibility is bounded to the valid 0..1 range",
		bounded_access_passed
	)
	all_passed = all_passed and bounded_access_passed

	# Case 5: allocation must not mutate the upstream physical resolution.
	var upstream_state_unchanged_passed: bool = (
		_approx_equal(
			float(resources.get_state("resolved_supply", {}).get("coal", -1.0)),
			original_supply
		)
		and _approx_equal(
			float(resources.get_state("exports", {}).get("coal", -1.0)),
			original_exports
		)
	)
	_log_result(
		"Allocation does not mutate resolved supply or export state",
		upstream_state_unchanged_passed
	)
	all_passed = all_passed and upstream_state_unchanged_passed

	# Case 6: stale allocation state must clear when no input resource state
	# remains in the next cycle.
	resources.set_state("resolved_supply", {})
	resources.set_state("exports", {})
	resources.set_state("aggregate_demand_by_category", {})
	resources.set_state("accessibility", {})
	system.process_month(world)

	var stale_state_passed: bool = (
		typeof(resources.get_state("domestic_accessible_supply", {})) == TYPE_DICTIONARY
		and resources.get_state("domestic_accessible_supply", {}).is_empty()
		and typeof(resources.get_state("allocated_supply_by_category", {})) == TYPE_DICTIONARY
		and resources.get_state("allocated_supply_by_category", {}).get("population", {}).is_empty()
		and _approx_equal(
			float(resources.get_state("domestic_distribution_total_allocated", -1.0)),
			0.0
		)
	)
	_log_result(
		"Resource allocation does not retain stale previous-cycle values",
		stale_state_passed
	)
	all_passed = all_passed and stale_state_passed

	var ledger = resources.get_state(
		"domestic_distribution_ledger",
		{}
	)
	var ledger_passed: bool = (
		typeof(ledger) == TYPE_DICTIONARY
		and ledger.is_empty()
	)
	_log_result(
		"Domestic distribution ledger clears with empty input",
		ledger_passed
	)
	all_passed = all_passed and ledger_passed

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	TestLogger.write_line(
		"Step 5.10 fixture state restored: PASS"
	)

	TestLogger.write_line(
		"Resource Allocation / Domestic Distribution 5.10 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
