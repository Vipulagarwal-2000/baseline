class_name CapacityUtilizationTest
extends RefCounted


static func _approx_equal(actual: float, expected: float) -> bool:
	return is_equal_approx(actual, expected)


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(label + ": " + ("PASS" if passed else "FAIL"))


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

	var system = simulation.get_system("capacity_utilization_system")
	var registered_system_passed: bool = (
		system != null
		and system is CapacityUtilizationSystem
	)

	_log_result("Registered CapacityUtilizationSystem available", registered_system_passed)
	all_passed = all_passed and registered_system_passed
	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()
	var test_entity := SimEntity.new(
		"step_5_6_capacity_utilization_test",
		"Step 5.6 Capacity Utilization Test",
		"country"
	)
	var industry := IndustryComponent.new(test_entity.id)
	var resources := ResourceComponent.new(test_entity.id)
	test_entity.add_component(industry)
	test_entity.add_component(resources)
	world.entities.clear()
	world.add_entity(test_entity)

	# Case 1: installed > effective > actual.
	industry.set_state("processes", {"steel_basic": {"capacity": 100.0}})
	industry.set_state(
		"production_state",
		{"steel_basic": {
			"status": "produced",
			"blocked": false,
			"effective_capacity": 80.0,
			"actual_production": 60.0,
			"reason": ""
		}}
	)
	system.process_month(world)

	var basic_passed: bool = (
		_approx_equal(float(resources.get_state("installed_capacity", -1.0)), 100.0)
		and _approx_equal(float(resources.get_state("effective_capacity", -1.0)), 80.0)
		and _approx_equal(float(resources.get_state("actual_capacity_production", -1.0)), 60.0)
		and _approx_equal(float(resources.get_state("unused_effective_capacity", -1.0)), 20.0)
		and _approx_equal(float(resources.get_state("capacity_gap", -1.0)), 20.0)
		and _approx_equal(float(resources.get_state("capacity_utilization", -1.0)), 75.0)
		and _approx_equal(float(resources.get_state("installed_capacity_utilization", -1.0)), 60.0)
		and _approx_equal(float(resources.get_state("effective_capacity_ratio", -1.0)), 80.0)
	)
	_log_result("Installed, effective and actual capacity remain distinct", basic_passed)
	all_passed = all_passed and basic_passed

	var ledger: Dictionary = resources.get_state("capacity_utilization_ledger", {})
	var steel_ledger: Dictionary = ledger.get("steel_basic", {})
	var ledger_passed: bool = (
		_approx_equal(float(steel_ledger.get("installed_capacity", -1.0)), 100.0)
		and _approx_equal(float(steel_ledger.get("effective_capacity", -1.0)), 80.0)
		and _approx_equal(float(steel_ledger.get("actual_production", -1.0)), 60.0)
		and _approx_equal(float(steel_ledger.get("capacity_utilization", -1.0)), 75.0)
	)
	_log_result("Per-process capacity utilization ledger is explicit", ledger_passed)
	all_passed = all_passed and ledger_passed

	# Case 2: malformed external outcome cannot produce >100% utilization.
	industry.set_state(
		"production_state",
		{"steel_basic": {
			"status": "produced",
			"blocked": false,
			"effective_capacity": 50.0,
			"actual_production": 75.0,
			"reason": "external_fixture"
		}}
	)
	system.process_month(world)
	var bounded_passed: bool = (
		_approx_equal(float(resources.get_state("capacity_utilization", -1.0)), 100.0)
		and _approx_equal(float(resources.get_state("installed_capacity", -1.0)), 100.0)
		and _approx_equal(float(resources.get_state("effective_capacity", -1.0)), 50.0)
	)
	_log_result("Capacity utilization remains bounded at 100 percent", bounded_passed)
	all_passed = all_passed and bounded_passed

	# Case 3: zero effective capacity is safe.
	industry.set_state(
		"production_state",
		{"steel_basic": {
			"status": "blocked",
			"blocked": true,
			"effective_capacity": 0.0,
			"actual_production": 0.0,
			"reason": "capacity_block"
		}}
	)
	system.process_month(world)
	var zero_capacity_passed: bool = (
		_approx_equal(float(resources.get_state("installed_capacity", -1.0)), 100.0)
		and _approx_equal(float(resources.get_state("effective_capacity", -1.0)), 0.0)
		and _approx_equal(float(resources.get_state("actual_capacity_production", -1.0)), 0.0)
		and _approx_equal(float(resources.get_state("capacity_utilization", -1.0)), 0.0)
		and _approx_equal(float(resources.get_state("effective_capacity_ratio", -1.0)), 0.0)
	)
	_log_result("Zero effective capacity produces zero utilization safely", zero_capacity_passed)
	all_passed = all_passed and zero_capacity_passed

	# Case 4: stale diagnostics clear.
	industry.set_state("production_state", {})
	industry.set_state("processes", {})
	system.process_month(world)
	var stale_clear_passed: bool = (
		_approx_equal(float(resources.get_state("installed_capacity", -1.0)), 0.0)
		and _approx_equal(float(resources.get_state("effective_capacity", -1.0)), 0.0)
		and _approx_equal(float(resources.get_state("actual_capacity_production", -1.0)), 0.0)
		and resources.get_state("capacity_utilization_ledger", {}).is_empty()
	)
	_log_result("Capacity utilization does not retain stale previous-cycle values", stale_clear_passed)
	all_passed = all_passed and stale_clear_passed

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	_log_result("Step 5.6 fixture state restored", true)
	TestLogger.write_line(
		"Capacity Utilization 5.6 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)
	return all_passed
