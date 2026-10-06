class_name InventoryStockBufferSemanticsTest
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
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var resource_system = simulation.get_system("resource_system")
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

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_2_inventory_test",
		"Step 5.2 Inventory Test",
		"country"
	)

	var resources := ResourceComponent.new(test_entity.id)
	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# ------------------------------------------------------------
	# Case 1 — reserve, stockpile and commitment are distinct buffers
	# ------------------------------------------------------------
	resources.set_state("production", {"iron": 10.0})
	resources.set_state("consumption", {"iron": 8.0})
	resources.set_state("reserves", {"iron": 100.0})
	resources.set_state("stockpile", {"iron": 40.0})
	resources.set_state("imports", {"iron": 5.0})
	resources.set_state("exports", {"iron": 2.0})
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
	resources.set_state("committed_stockpile", {"iron": 15.0})

	resource_system.process_month(world)

	var ledger: Dictionary = resources.get_state(
		"inventory_buffer_ledger",
		{}
	)
	var iron_ledger: Dictionary = ledger.get("iron", {})

	var buffer_distinction_passed := (
		_approx_equal(float(iron_ledger.get("opening_stockpile", -1.0)), 40.0)
		and _approx_equal(float(iron_ledger.get("opening_committed_quantity", -1.0)), 15.0)
		and _approx_equal(float(iron_ledger.get("opening_secured_commitment", -1.0)), 15.0)
		and _approx_equal(float(iron_ledger.get("opening_commitment_shortfall", -1.0)), 0.0)
		and _approx_equal(float(iron_ledger.get("opening_available_stockpile", -1.0)), 25.0)
		and _approx_equal(float(resources.get_state("available_stockpile", {}).get("iron", -1.0)), 25.0)
		and _approx_equal(float(resources.get_state("available_supply", {}).get("iron", -1.0)), 40.0)
	)

	_log_result(
		"Stockpile, committed quantity and available supply remain distinct",
		buffer_distinction_passed
	)
	all_passed = all_passed and buffer_distinction_passed

	# Reserve stock is not double-counted as available stored inventory.
	var reserve_not_double_counted_passed := (
		_approx_equal(
			float(iron_ledger.get("opening_stockpile", -1.0)),
			40.0
		)
		and not _approx_equal(
			float(iron_ledger.get("opening_available_stockpile", -1.0)),
			140.0
		)
	)

	_log_result(
		"Reserves are not double-counted into the stockpile buffer",
		reserve_not_double_counted_passed
	)
	all_passed = all_passed and reserve_not_double_counted_passed

	# ------------------------------------------------------------
	# Case 2 — commitment exceeds physical stock
	# ------------------------------------------------------------
	resources.set_state("production", {"iron": 0.0})
	resources.set_state("consumption", {"iron": 1.0})
	resources.set_state("reserves", {"iron": 100.0})
	resources.set_state("stockpile", {"iron": 10.0})
	resources.set_state("imports", {"iron": 0.0})
	resources.set_state("exports", {"iron": 0.0})
	resources.set_state("trade_imports", {"iron": 0.0})
	resources.set_state("trade_exports", {"iron": 0.0})
	resources.set_state("extraction_capacity", {"iron": 0.0})
	resources.set_state("processing_capacity", {"iron": 0.0})
	resources.set_state("committed_stockpile", {"iron": 16.0})

	resource_system.process_month(world)

	ledger = resources.get_state("inventory_buffer_ledger", {})
	iron_ledger = ledger.get("iron", {})

	var overcommitment_passed := (
		_approx_equal(float(iron_ledger.get("opening_secured_commitment", -1.0)), 10.0)
		and _approx_equal(float(iron_ledger.get("opening_commitment_shortfall", -1.0)), 6.0)
		and _approx_equal(float(iron_ledger.get("opening_available_stockpile", -1.0)), 0.0)
		and _approx_equal(float(iron_ledger.get("closing_stockpile", -1.0)), 9.0)
		and _approx_equal(float(iron_ledger.get("closing_secured_commitment", -1.0)), 9.0)
		and _approx_equal(float(iron_ledger.get("closing_commitment_shortfall", -1.0)), 7.0)
		and _approx_equal(float(iron_ledger.get("closing_available_stockpile", -1.0)), 0.0)
	)

	_log_result(
		"Unsecured commitments are explicitly recorded instead of creating stock",
		overcommitment_passed
	)
	all_passed = all_passed and overcommitment_passed

	# ------------------------------------------------------------
	# Case 3 — existing Step 5.1 physical settlement still closes
	# ------------------------------------------------------------
	var stock_flow_ledger: Dictionary = resources.get_state(
		"stock_flow_ledger",
		{}
	)
	var physical_ledger: Dictionary = stock_flow_ledger.get("iron", {})

	var physical_settlement_preserved_passed := (
		_approx_equal(float(physical_ledger.get("reconciliation_error", 999.0)), 0.0)
		and _approx_equal(float(physical_ledger.get("closing_stockpile", -1.0)), 9.0)
	)

	_log_result(
		"Step 5.1 physical stock/flow reconciliation remains intact",
		physical_settlement_preserved_passed
	)
	all_passed = all_passed and physical_settlement_preserved_passed

	# Restore world so the active suite remains isolated.
	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	var restored := (
		world.has_entity("step_5_2_inventory_test") == false
		and world.entities.size() == original_entities.size()
	)

	_log_result(
		"Step 5.2 fixture state restored",
		restored
	)
	all_passed = all_passed and restored

	TestLogger.write_line(
		"Inventory / Stock Buffer Semantics 5.2 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
