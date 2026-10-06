class_name EconomyGovernmentFinancesInvestmentCapacityTest
extends RefCounted


static func _out(values: Array) -> void:
	var message: String = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func _run_condition(
	world: WorldState,
	economy_system: EconomySystem,
	economy,
	gdp_value: float,
	tax_rate: float,
	spending_rate: float,
	label: String
) -> Dictionary:

	economy.set_state(
		"gdp",
		gdp_value
	)

	economy.set_state(
		"growth_rate",
		0.0
	)

	economy.set_state(
		"tax_revenue_rate",
		tax_rate
	)

	economy.set_state(
		"government_spending_rate",
		spending_rate
	)

	economy.set_state(
		"investment_rate",
		0.10
	)

	economy.set_state(
		"investment_to_capacity_rate",
		0.01
	)

	economy.set_state(
		"investment_capacity",
		0.0
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		0.0
	)

	economy.set_state(
		"treasury",
		0.0
	)

	economy.set_state(
		"government_debt",
		0.0
	)

	economy.set_state(
		"physical_production_output",
		0.0
	)

	economy.set_state(
		"physical_production_capacity",
		0.0
	)

	economy.set_state(
		"production_output_factor",
		1.0
	)

	economy_system.process_month(
		world
	)

	var actual_gdp: float = float(
		economy.get_state(
			"gdp",
			-1.0
		)
	)

	var actual_investment: float = float(
		economy.get_state(
			"investment",
			-1.0
		)
	)

	var actual_budget: float = float(
		economy.get_state(
			"budget_balance",
			-1.0
		)
	)

	var actual_factor: float = float(
		economy.get_state(
			"government_finance_investment_factor",
			-1.0
		)
	)

	var actual_limited_investment: float = float(
		economy.get_state(
			"government_finance_limited_investment",
			-1.0
		)
	)

	var actual_new_capacity: float = float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	var expected_investment: float = actual_gdp * 0.10
	var expected_budget: float = (
		actual_gdp * tax_rate
		- actual_gdp * spending_rate
	)

	var expected_factor: float = clamp(
		1.0
		+ (
			expected_budget
			/ actual_gdp
		),
		0.0,
		1.0
	)

	var expected_limited_investment: float = (
		expected_investment
		* expected_factor
	)

	var expected_new_capacity: float = (
		expected_limited_investment
		* 0.01
	)

	_out([
		label,
		" GDP=",
		actual_gdp,
		" budget=",
		actual_budget,
		" investment=",
		actual_investment,
		" fiscal_factor=",
		actual_factor,
		" limited_investment=",
		actual_limited_investment,
		" investment_capacity=",
		actual_new_capacity
	])

	if is_equal_approx(
		actual_investment,
		expected_investment
	):
		_out([
			"PASS: ",
			label,
			" planned investment remains GDP-driven."
		])
	else:
		_out([
			"FAIL: ",
			label,
			" planned investment changed unexpectedly | expected=",
			expected_investment,
			" actual=",
			actual_investment
		])

	var scenario_passed: bool = true

	if not is_equal_approx(
		actual_budget,
		expected_budget
	):
		scenario_passed = false

	if not is_equal_approx(
		actual_factor,
		expected_factor
	):
		scenario_passed = false

	if not is_equal_approx(
		actual_limited_investment,
		expected_limited_investment
	):
		scenario_passed = false

	if not is_equal_approx(
		actual_new_capacity,
		expected_new_capacity
	):
		scenario_passed = false

	if scenario_passed:
		_out([
			"PASS: ",
			label,
			" government finances -> investment capacity."
		])
	else:
		_out([
			"FAIL: ",
			label,
			" government-finance investment-capacity response."
		])

	return {
		"passed": scenario_passed,
		"budget": actual_budget,
		"investment": actual_investment,
		"factor": actual_factor,
		"limited_investment": actual_limited_investment,
		"capacity": actual_new_capacity
	}


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([
		""
	])
	_out([
		"===================================================="
	])
	_out([
		"ECONOMY INTEGRATION — GOVERNMENT FINANCES -> INVESTMENT CAPACITY TEST"
	])
	_out([
		"===================================================="
	])

	var passed: bool = true

	if world == null:
		_out([
			"FAIL: World is null."
		])
		return false

	if simulation == null:
		_out([
			"FAIL: SimulationEngine is null."
		])
		return false

	var india = world.get_entity(
		"india"
	)

	if india == null:
		_out([
			"FAIL: India not found."
		])
		return false

	var economy = india.get_component(
		"economy"
	)

	if economy == null:
		_out([
			"FAIL: Economy component missing."
		])
		return false

	var economy_system = simulation.get_system(
		"economy_system"
	)

	if economy_system == null:
		_out([
			"FAIL: Registered EconomySystem missing."
		])
		return false

	var original_economy_state = economy.state.duplicate(
		true
	)

	# Balanced budget: neutral fiscal factor, full planned investment.
	var balanced: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		1000.0,
		0.10,
		0.10,
		"Balanced government finances"
	)

	if not bool(balanced["passed"]):
		passed = false

	# Fiscal surplus does not create capacity above planned investment.
	var surplus: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		1000.0,
		0.15,
		0.05,
		"Government fiscal surplus"
	)

	if not bool(surplus["passed"]):
		passed = false

	# Fiscal deficit constrains the amount that can become productive
	# capacity while planned investment itself remains GDP-driven.
	var deficit: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		1000.0,
		0.05,
		0.15,
		"Government fiscal deficit"
	)

	if not bool(deficit["passed"]):
		passed = false

	if (
		float(deficit["factor"])
		< float(balanced["factor"])
		and
		float(deficit["capacity"])
		< float(balanced["capacity"])
	):
		_out([
			"PASS: Fiscal deficit reduces investment capacity."
		])
	else:
		_out([
			"FAIL: Fiscal deficit did not reduce investment capacity."
		])
		passed = false

	if (
		is_equal_approx(
			float(surplus["factor"]),
			1.0
		)
		and
		is_equal_approx(
			float(surplus["capacity"]),
			float(balanced["capacity"])
		)
	):
		_out([
			"PASS: Fiscal surplus preserves full planned investment capacity without over-creation."
		])
	else:
		_out([
			"FAIL: Fiscal surplus changed capacity outside the Step 3.5 boundary."
		])
		passed = false

	economy.state = original_economy_state

	if passed:
		_out([
			"EconomyGovernmentFinancesInvestmentCapacityTest: PASS"
		])
	else:
		_out([
			"EconomyGovernmentFinancesInvestmentCapacityTest: FAIL"
		])

	return passed
