class_name ResourceStockFlowAccountingTest
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

	var all_passed := true

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

	var resource_system = simulation.get_system(
		"resource_system"
	)

	var registered_system_passed := (
		resource_system != null
		and resource_system is ResourceSystem
	)

	_log_result(
		"Registered ResourceSystem available",
		registered_system_passed
	)

	all_passed = all_passed and registered_system_passed

	if not registered_system_passed:
		return false

	# Use an isolated temporary entity while still executing the registered
	# ResourceSystem. This prevents the accounting fixture from contaminating
	# the real three-country world used by the rest of the suite.
	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_1_accounting_test",
		"Step 5.1 Accounting Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)

	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# ------------------------------------------------------------
	# Controlled monthly resource fixture
	# ------------------------------------------------------------
	resources.set_state("production", {"iron": 10.0})
	resources.set_state("consumption", {"iron": 6.0})
	resources.set_state("reserves", {"iron": 50.0})
	resources.set_state("stockpile", {"iron": 20.0})
	resources.set_state("imports", {"iron": 5.0})
	resources.set_state("exports", {"iron": 4.0})
	resources.set_state("trade_imports", {"iron": 0.0})
	resources.set_state("trade_exports", {"iron": 0.0})
	resources.set_state("extraction_capacity", {"iron": 10.0})
	resources.set_state("processing_capacity", {"iron": 10.0})
	resources.set_state("production_efficiency", {"iron": 1.0})
	resources.set_state("technology_efficiency", {"iron": 1.0})
	resources.set_state("infrastructure_capacity", {"iron": 1.0})
	resources.set_state("quality", {"iron": 1.0})
	resources.set_state("accessibility", {"iron": 1.0})
	resources.set_state("production_process_demand", {})
	resources.set_state("max_stockpile_capacity", {})

	resource_system.process_month(world)

	var ledger: Dictionary = resources.get_state(
		"stock_flow_ledger",
		{}
	)

	var iron_ledger: Dictionary = ledger.get(
		"iron",
		{}
	)

	var normal_case_passed := (
		_approx_equal(
			float(iron_ledger.get("opening_stockpile", -1.0)),
			20.0
		)
		and _approx_equal(
			float(iron_ledger.get("production", -1.0)),
			10.0
		)
		and _approx_equal(
			float(iron_ledger.get("imports", -1.0)),
			5.0
		)
		and _approx_equal(
			float(iron_ledger.get("consumption", -1.0)),
			6.0
		)
		and _approx_equal(
			float(iron_ledger.get("exports", -1.0)),
			4.0
		)
		and _approx_equal(
			float(iron_ledger.get("closing_stockpile", -1.0)),
			25.0
		)
	)

	_log_result(
		"Normal stock/flow ledger records all monthly flows",
		normal_case_passed
	)
	all_passed = all_passed and normal_case_passed

	var normal_reconciliation_passed := (
		_approx_equal(
			float(iron_ledger.get("fulfilled_demand", -1.0)),
			10.0
		)
		and _approx_equal(
			float(iron_ledger.get("shortage", -1.0)),
			0.0
		)
		and _approx_equal(
			float(iron_ledger.get("storage_overflow", -1.0)),
			0.0
		)
		and _approx_equal(
			float(iron_ledger.get("physical_net_change", -1.0)),
			5.0
		)
		and _approx_equal(
			float(iron_ledger.get("reconciliation_error", 999.0)),
			0.0
		)
	)

	_log_result(
		"Normal stock/flow reconciliation closes exactly",
		normal_reconciliation_passed
	)
	all_passed = all_passed and normal_reconciliation_passed

	var normal_reserve_reconciliation_passed := (
		_approx_equal(
			float(iron_ledger.get("opening_reserves", -1.0)),
			50.0
		)
		and _approx_equal(
			float(iron_ledger.get("reserve_depletion", -1.0)),
			10.0
		)
		and _approx_equal(
			float(iron_ledger.get("closing_reserves", -1.0)),
			40.0
		)
		and _approx_equal(
			float(iron_ledger.get("reserve_reconciliation_error", 999.0)),
			0.0
		)
	)

	_log_result(
		"Reserve stock/flow reconciliation closes exactly",
		normal_reserve_reconciliation_passed
	)
	all_passed = all_passed and normal_reserve_reconciliation_passed

	# ------------------------------------------------------------
	# Shortage case
	# ------------------------------------------------------------
	resources.set_state("production", {"iron": 3.0})
	resources.set_state("consumption", {"iron": 7.0})
	resources.set_state("reserves", {"iron": 10.0})
	resources.set_state("stockpile", {"iron": 2.0})
	resources.set_state("imports", {"iron": 1.0})
	resources.set_state("exports", {"iron": 0.0})
	resources.set_state("trade_imports", {"iron": 0.0})
	resources.set_state("trade_exports", {"iron": 0.0})
	resources.set_state("extraction_capacity", {"iron": 3.0})
	resources.set_state("processing_capacity", {"iron": 3.0})

	resource_system.process_month(world)

	ledger = resources.get_state(
		"stock_flow_ledger",
		{}
	)
	iron_ledger = ledger.get(
		"iron",
		{}
	)

	var shortage_case_passed := (
		_approx_equal(
			float(iron_ledger.get("opening_stockpile", -1.0)),
			2.0
		)
		and _approx_equal(
			float(iron_ledger.get("production", -1.0)),
			3.0
		)
		and _approx_equal(
			float(iron_ledger.get("imports", -1.0)),
			1.0
		)
		and _approx_equal(
			float(iron_ledger.get("fulfilled_demand", -1.0)),
			6.0
		)
		and _approx_equal(
			float(iron_ledger.get("shortage", -1.0)),
			1.0
		)
		and _approx_equal(
			float(iron_ledger.get("closing_stockpile", -1.0)),
			0.0
		)
		and _approx_equal(
			float(iron_ledger.get("reconciliation_error", 999.0)),
			0.0
		)
	)

	_log_result(
		"Shortage case records fulfilled demand without losing the unfulfilled flow",
		shortage_case_passed
	)
	all_passed = all_passed and shortage_case_passed

	# ------------------------------------------------------------
	# Storage overflow case
	# ------------------------------------------------------------
	resources.set_state("production", {"iron": 20.0})
	resources.set_state("consumption", {"iron": 0.0})
	resources.set_state("reserves", {"iron": 100.0})
	resources.set_state("stockpile", {"iron": 20.0})
	resources.set_state("imports", {"iron": 0.0})
	resources.set_state("exports", {"iron": 0.0})
	resources.set_state("trade_imports", {"iron": 0.0})
	resources.set_state("trade_exports", {"iron": 0.0})
	resources.set_state("extraction_capacity", {"iron": 20.0})
	resources.set_state("processing_capacity", {"iron": 20.0})
	resources.set_state("max_stockpile_capacity", {"iron": 30.0})

	resource_system.process_month(world)

	ledger = resources.get_state(
		"stock_flow_ledger",
		{}
	)
	iron_ledger = ledger.get(
		"iron",
		{}
	)

	var overflow_case_passed := (
		_approx_equal(
			float(iron_ledger.get("opening_stockpile", -1.0)),
			20.0
		)
		and _approx_equal(
			float(iron_ledger.get("closing_stockpile", -1.0)),
			30.0
		)
		and _approx_equal(
			float(iron_ledger.get("storage_overflow", -1.0)),
			10.0
		)
		and _approx_equal(
			float(iron_ledger.get("reconciliation_error", 999.0)),
			0.0
		)
	)

	_log_result(
		"Storage overflow remains explicitly accounted",
		overflow_case_passed
	)
	all_passed = all_passed and overflow_case_passed

	# Restore the world before returning so later tests see the exact
	# same entity dictionary they started with.
	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	# The explicit individual assertions above are authoritative. The final
	# state-restoration assertion protects the active suite from fixture leakage.
	var restored := (
		world.has_entity("step_5_1_accounting_test") == false
		and world.entities.size() == original_entities.size()
	)

	_log_result(
		"Step 5.1 fixture state restored",
		restored
	)
	all_passed = all_passed and restored

	TestLogger.write_line(
		"Resource Stock / Flow Accounting 5.1 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
