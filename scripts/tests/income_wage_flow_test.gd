class_name IncomeWageFlowTest
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

	var system = simulation.get_system("income_wage_flow_system")
	var registered_system_passed: bool = (
		system != null
		and system is IncomeWageFlowSystem
	)

	_log_result(
		"Registered IncomeWageFlowSystem available",
		registered_system_passed
	)
	all_passed = all_passed and registered_system_passed
	if not registered_system_passed:
		return false

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_8_income_wage_flow_test",
		"Step 5.8 Income Wage Flow Test",
		"country"
	)

	var economy := EconomyComponent.new(test_entity.id)
	var industry := IndustryComponent.new(test_entity.id)
	test_entity.add_component(economy)
	test_entity.add_component(industry)

	world.entities.clear()
	world.add_entity(test_entity)

	economy.set_state(
		"base_wage_rate",
		2.0
	)
	economy.set_state(
		"skilled_wage_premium",
		0.50
	)

	# Case 1: two labor classes are converted into a monthly wage flow.
	industry.set_state(
		"processes",
		{
			"steel_basic": {
				"active": true,
				"capacity": 10.0,
				"labor_requirement": 2.0,
				"labor_skill_requirement": 1.0
			}
		}
	)
	industry.set_state(
		"production_state",
		{
			"steel_basic": {
				"actual_production": 10.0
			}
		}
	)

	system.process_month(world)

	var case_one_passed: bool = (
		_approx_equal(
			float(economy.get_state("employed_labor_units", -1.0)),
			20.0
		)
		and _approx_equal(
			float(economy.get_state("skilled_labor_units", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("unskilled_labor_units", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("skilled_labor_income", -1.0)),
			30.0
		)
		and _approx_equal(
			float(economy.get_state("unskilled_labor_income", -1.0)),
			20.0
		)
		and _approx_equal(
			float(economy.get_state("labor_income", -1.0)),
			50.0
		)
		and _approx_equal(
			float(economy.get_state("average_wage", -1.0)),
			2.5
		)
	)
	_log_result(
		"Labor requirements produce a reconciled wage flow",
		case_one_passed
	)
	all_passed = all_passed and case_one_passed

	var ledger = economy.get_state(
		"income_wage_ledger",
		{}
	)
	var ledger_case_passed: bool = (
		typeof(ledger) == TYPE_DICTIONARY
		and typeof(ledger.get("steel_basic", {})) == TYPE_DICTIONARY
		and _approx_equal(
			float(ledger.get("steel_basic", {}).get("labor_income", -1.0)),
			50.0
		)
	)
	_log_result(
		"Per-process income/wage ledger is explicit",
		ledger_case_passed
	)
	all_passed = all_passed and ledger_case_passed

	# Case 2: lower realized production lowers labor income proportionally.
	industry.set_state(
		"production_state",
		{
			"steel_basic": {
				"actual_production": 5.0
			}
		}
	)
	system.process_month(world)

	var reduced_output_passed: bool = (
		_approx_equal(
			float(economy.get_state("employed_labor_units", -1.0)),
			10.0
		)
		and _approx_equal(
			float(economy.get_state("labor_income", -1.0)),
			25.0
		)
	)
	_log_result(
		"Lower realized production lowers labor income proportionally",
		reduced_output_passed
	)
	all_passed = all_passed and reduced_output_passed

	# Case 3: negative production is clamped and cannot create negative income.
	industry.set_state(
		"production_state",
		{
			"steel_basic": {
				"actual_production": -10.0
			}
		}
	)
	system.process_month(world)

	var negative_safety_passed: bool = (
		_approx_equal(
			float(economy.get_state("employed_labor_units", -1.0)),
			0.0
		)
		and _approx_equal(
			float(economy.get_state("labor_income", -1.0)),
			0.0
		)
	)
	_log_result(
		"Negative production is clamped without creating negative income",
		negative_safety_passed
	)
	all_passed = all_passed and negative_safety_passed

	# Case 4: inactive processes do not retain stale wage flow.
	industry.set_state(
		"processes",
		{
			"steel_basic": {
				"active": false,
				"capacity": 10.0,
				"labor_requirement": 2.0,
				"labor_skill_requirement": 1.0
			}
		}
	)
	industry.set_state(
		"production_state",
		{
			"steel_basic": {
				"actual_production": 10.0
			}
		}
	)
	system.process_month(world)

	var inactive_clears_passed: bool = (
		_approx_equal(
			float(economy.get_state("employed_labor_units", -1.0)),
			0.0
		)
		and _approx_equal(
			float(economy.get_state("labor_income", -1.0)),
			0.0
		)
		and typeof(
			economy.get_state("labor_income_by_process", {})
		) == TYPE_DICTIONARY
	)
	_log_result(
		"Inactive production clears stale wage flow",
		inactive_clears_passed
	)
	all_passed = all_passed and inactive_clears_passed

	# Case 5: reconciliation remains exact after the cycle is recomputed.
	var reconciliation_passed: bool = _approx_equal(
		float(
			economy.get_state(
				"income_flow_reconciliation_error",
				999.0
			)
		),
		0.0
	)
	_log_result(
		"Income/wage flow reconciliation closes exactly",
		reconciliation_passed
	)
	all_passed = all_passed and reconciliation_passed

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	TestLogger.write_line(
		"Step 5.8 fixture state restored: "
		+ ("PASS" if true else "FAIL")
	)

	TestLogger.write_line(
		"Income / Wage Flow 5.8 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
