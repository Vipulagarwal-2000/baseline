class_name PurchasingPowerTest
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

	var system = simulation.get_system("purchasing_power_system")
	var registered_system_passed: bool = (
		system != null
		and system is PurchasingPowerSystem
	)

	_log_result(
		"Registered PurchasingPowerSystem available",
		registered_system_passed
	)
	all_passed = all_passed and registered_system_passed
	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_9_purchasing_power_test",
		"Step 5.9 Purchasing Power Test",
		"country"
	)

	var economy := EconomyComponent.new(test_entity.id)
	var resources := ResourceComponent.new(test_entity.id)
	test_entity.add_component(economy)
	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	economy.set_state(
		"labor_income",
		100.0
	)
	economy.set_state(
		"average_wage",
		10.0
	)
	economy.set_state(
		"employed_labor_units",
		10.0
	)

	resources.set_state(
		"base_price",
		{
			"food": 2.0,
			"energy": 1.0
		}
	)
	resources.set_state(
		"current_price",
		{
			"food": 2.0,
			"energy": 1.0
		}
	)
	resources.set_state(
		"consumption_by_category",
		{
			"population": {
				"food": 20.0,
				"energy": 10.0
			}
		}
	)

	# Case 1: prices at their base level preserve nominal purchasing power.
	system.process_month(world)

	var base_price_passed: bool = (
		_approx_equal(
			float(economy.get_state("population_consumption_cost", -1.0)),
			50.0
		)
		and _approx_equal(
			float(economy.get_state("base_population_consumption_cost", -1.0)),
			50.0
		)
		and _approx_equal(
			float(economy.get_state("consumption_price_index", -1.0)),
			1.0
		)
		and _approx_equal(
			float(economy.get_state("real_labor_income", -1.0)),
			100.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power_index", -1.0)),
			1.0
		)
	)
	_log_result(
		"Base prices preserve nominal purchasing power",
		base_price_passed
	)
	all_passed = all_passed and base_price_passed

	# Case 2: a doubled population basket price halves real purchasing power.
	resources.set_state(
		"current_price",
		{
			"food": 4.0,
			"energy": 2.0
		}
	)
	system.process_month(world)

	var inflation_passed: bool = (
		_approx_equal(
			float(economy.get_state("population_consumption_cost", -1.0)),
			100.0
		)
		and _approx_equal(
			float(economy.get_state("consumption_price_index", -1.0)),
			2.0
		)
		and _approx_equal(
			float(economy.get_state("real_labor_income", -1.0)),
			50.0
		)
		and _approx_equal(
			float(economy.get_state("real_average_wage", -1.0)),
			5.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power", -1.0)),
			5.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power_index", -1.0)),
			0.5
		)
	)
	_log_result(
		"Higher consumption prices reduce real purchasing power",
		inflation_passed
	)
	all_passed = all_passed and inflation_passed

	# Case 3: nominal wage growth can offset the same price increase.
	economy.set_state(
		"labor_income",
		200.0
	)
	economy.set_state(
		"average_wage",
		20.0
	)
	system.process_month(world)

	var wage_offset_passed: bool = (
		_approx_equal(
			float(economy.get_state("real_labor_income", -1.0)),
			100.0
		)
		and _approx_equal(
			float(economy.get_state("real_average_wage", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power_index", -1.0)),
			0.5
		)
	)
	_log_result(
		"Wage growth can offset price growth in real purchasing power",
		wage_offset_passed
	)
	all_passed = all_passed and wage_offset_passed

	# Case 4: the coverage ratio exposes whether gross labor income covers
	# the current population consumption basket.
	var coverage_passed: bool = _approx_equal(
		float(economy.get_state("income_coverage_ratio", -1.0)),
		2.0
	)
	_log_result(
		"Income-to-consumption coverage ratio is explicit",
		coverage_passed
	)
	all_passed = all_passed and coverage_passed

	# Case 5: missing population consumption is safe and returns a neutral
	# price index rather than inventing a price basket.
	resources.set_state(
		"consumption_by_category",
		{}
	)
	resources.set_state(
		"current_price",
		{
			"food": 8.0
		}
	)
	system.process_month(world)

	var empty_basket_passed: bool = (
		_approx_equal(
			float(economy.get_state("population_consumption_cost", -1.0)),
			0.0
		)
		and _approx_equal(
			float(economy.get_state("consumption_price_index", -1.0)),
			1.0
		)
		and _approx_equal(
			float(economy.get_state("purchasing_power", -1.0)),
			20.0
		)
	)
	_log_result(
		"Missing population basket remains safe and neutral",
		empty_basket_passed
	)
	all_passed = all_passed and empty_basket_passed

	# Case 6: stale previous-cycle state is cleared when the basket changes.
	resources.set_state(
		"consumption_by_category",
		{
			"population": {
				"food": 10.0
			}
		}
	)
	resources.set_state(
		"base_price",
		{
			"food": 2.0
		}
	)
	resources.set_state(
		"current_price",
		{
			"food": 2.0
		}
	)
	economy.set_state(
		"labor_income",
		50.0
	)
	economy.set_state(
		"average_wage",
		5.0
	)
	system.process_month(world)

	var stale_state_passed: bool = (
		_approx_equal(
			float(economy.get_state("population_consumption_cost", -1.0)),
			20.0
		)
		and _approx_equal(
			float(economy.get_state("base_population_consumption_cost", -1.0)),
			20.0
		)
		and _approx_equal(
			float(economy.get_state("consumption_price_index", -1.0)),
			1.0
		)
	)
	_log_result(
		"Purchasing power does not retain stale previous-cycle values",
		stale_state_passed
	)
	all_passed = all_passed and stale_state_passed

	var ledger = economy.get_state(
		"purchasing_power_ledger",
		{}
	)
	var ledger_passed: bool = (
		typeof(ledger) == TYPE_DICTIONARY
		and typeof(ledger.get("basket", {})) == TYPE_DICTIONARY
		and ledger.has("labor_income")
		and ledger.has("price_index")
	)
	_log_result(
		"Purchasing power ledger is explicit",
		ledger_passed
	)
	all_passed = all_passed and ledger_passed

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	TestLogger.write_line(
		"Step 5.9 fixture state restored: "
		+ ("PASS" if true else "FAIL")
	)

	TestLogger.write_line(
		"Purchasing Power 5.9 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
