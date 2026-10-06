class_name BasicPriceFormationTest
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

	var system = simulation.get_system("basic_price_formation_system")
	var registered_system_passed: bool = (
		system != null
		and system is BasicPriceFormationSystem
	)

	_log_result(
		"Registered BasicPriceFormationSystem available",
		registered_system_passed
	)
	all_passed = all_passed and registered_system_passed
	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()
	var test_entity := SimEntity.new(
		"step_5_7_basic_price_formation_test",
		"Step 5.7 Basic Price Formation Test",
		"country"
	)
	var resources := ResourceComponent.new(test_entity.id)
	test_entity.add_component(resources)
	world.entities.clear()
	world.add_entity(test_entity)

	# Case 1: balanced supply and demand leaves the base price unchanged.
	resources.set_state(
		"base_price",
		{"iron": 10.0}
	)
	resources.set_state(
		"resolved_supply",
		{"iron": 100.0}
	)
	resources.set_state(
		"resolved_demand",
		{"iron": 100.0}
	)
	resources.set_state(
		"resolved_surplus",
		{"iron": 0.0}
	)
	resources.set_state(
		"resolved_shortage_ratio",
		{"iron": 0.0}
	)
	system.process_month(world)

	var balanced_price_passed: bool = (
		_approx_equal(
			float(resources.get_state("current_price", {}).get("iron", -1.0)),
			10.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"scarcity_price_modifier",
					{}
				).get("iron", -1.0)
			),
			1.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"surplus_price_modifier",
					{}
				).get("iron", -1.0)
			),
			1.0
		)
	)
	_log_result(
		"Balanced supply and demand preserve the base price",
		balanced_price_passed
	)
	all_passed = all_passed and balanced_price_passed

	# Case 2: a 50% shortage produces a 1.5x scarcity price.
	resources.set_state(
		"resolved_supply",
		{"iron": 50.0}
	)
	resources.set_state(
		"resolved_demand",
		{"iron": 100.0}
	)
	resources.set_state(
		"resolved_surplus",
		{"iron": 0.0}
	)
	resources.set_state(
		"resolved_shortage_ratio",
		{"iron": 50.0}
	)
	system.process_month(world)

	var shortage_price_passed: bool = (
		_approx_equal(
			float(resources.get_state("current_price", {}).get("iron", -1.0)),
			15.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"scarcity_price_modifier",
					{}
				).get("iron", -1.0)
			),
			1.5
		)
		and _approx_equal(
			float(
				resources.get_state(
					"surplus_price_modifier",
					{}
				).get("iron", -1.0)
			),
			1.0
		)
	)
	_log_result(
		"Shortage raises price above the base price",
		shortage_price_passed
	)
	all_passed = all_passed and shortage_price_passed

	# Case 3: surplus lowers price without going below the defined floor.
	resources.set_state(
		"base_price",
		{"iron": 10.0}
	)
	resources.set_state(
		"resolved_supply",
		{"iron": 150.0}
	)
	resources.set_state(
		"resolved_demand",
		{"iron": 100.0}
	)
	resources.set_state(
		"resolved_surplus",
		{"iron": 50.0}
	)
	resources.set_state(
		"resolved_shortage_ratio",
		{"iron": 0.0}
	)
	system.process_month(world)

	var surplus_price_passed: bool = (
		_approx_equal(
			float(resources.get_state("current_price", {}).get("iron", -1.0)),
			50.0 / 6.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"surplus_price_modifier",
					{}
				).get("iron", -1.0)
			),
			5.0 / 6.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"price_modifier",
					{}
				).get("iron", -1.0)
			),
			5.0 / 6.0
		)
	)
	_log_result(
		"Surplus lowers price through a bounded surplus modifier",
		surplus_price_passed
	)
	all_passed = all_passed and surplus_price_passed

	# Case 4: extreme shortage is bounded at the 2x price ceiling.
	resources.set_state(
		"resolved_supply",
		{"iron": 0.0}
	)
	resources.set_state(
		"resolved_demand",
		{"iron": 100.0}
	)
	resources.set_state(
		"resolved_surplus",
		{"iron": 0.0}
	)
	resources.set_state(
		"resolved_shortage_ratio",
		{"iron": 100.0}
	)
	system.process_month(world)

	var ceiling_passed: bool = (
		_approx_equal(
			float(resources.get_state("price_modifier", {}).get("iron", -1.0)),
			2.0
		)
		and _approx_equal(
			float(resources.get_state("current_price", {}).get("iron", -1.0)),
			20.0
		)
	)
	_log_result(
		"Extreme shortage respects the price ceiling",
		ceiling_passed
	)
	all_passed = all_passed and ceiling_passed

	# Case 5: the price layer does not mutate the Step 5.5 physical resolution.
	var supply_before: float = float(
		resources.get_state("resolved_supply", {}).get("iron", -1.0)
	)
	var demand_before: float = float(
		resources.get_state("resolved_demand", {}).get("iron", -1.0)
	)
	var shortage_before: float = float(
		resources.get_state("resolved_shortage_ratio", {}).get("iron", -1.0)
	)
	system.process_month(world)
	var physical_state_preserved_passed: bool = (
		_approx_equal(
			float(resources.get_state("resolved_supply", {}).get("iron", -1.0)),
			supply_before
		)
		and _approx_equal(
			float(resources.get_state("resolved_demand", {}).get("iron", -1.0)),
			demand_before
		)
		and _approx_equal(
			float(
				resources.get_state(
					"resolved_shortage_ratio",
					{}
				).get("iron", -1.0)
			),
			shortage_before
		)
	)
	_log_result(
		"Price formation does not mutate supply/demand resolution",
		physical_state_preserved_passed
	)
	all_passed = all_passed and physical_state_preserved_passed

	# Case 6: stale price state clears when no price inputs remain.
	resources.set_state("base_price", {})
	resources.set_state("resolved_supply", {})
	resources.set_state("resolved_demand", {})
	resources.set_state("resolved_surplus", {})
	resources.set_state("resolved_shortage_ratio", {})
	system.process_month(world)
	var stale_clear_passed: bool = (
		resources.get_state("current_price", {}).is_empty()
		and resources.get_state("price_modifier", {}).is_empty()
		and resources.get_state("price_formation_ledger", {}).is_empty()
	)
	_log_result(
		"Basic price formation does not retain stale previous-cycle values",
		stale_clear_passed
	)
	all_passed = all_passed and stale_clear_passed

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	_log_result("Step 5.7 fixture state restored", true)
	TestLogger.write_line(
		"Basic Price Formation 5.7 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)
	return all_passed
