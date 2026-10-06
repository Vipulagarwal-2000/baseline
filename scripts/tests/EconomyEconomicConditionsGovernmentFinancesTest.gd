class_name EconomyEconomicConditionsGovernmentFinancesTest
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
	label: String,
	tax_rate: float,
	spending_rate: float,
	starting_treasury: float,
	starting_debt: float
) -> Dictionary:

	economy.set_state(
		"gdp",
		gdp_value
	)

	economy.set_state(
		"treasury",
		starting_treasury
	)

	economy.set_state(
		"government_debt",
		starting_debt
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

	var actual_revenue: float = float(
		economy.get_state(
			"government_revenue",
			-1.0
		)
	)

	var actual_spending: float = float(
		economy.get_state(
			"government_spending",
			-1.0
		)
	)

	var actual_budget: float = float(
		economy.get_state(
			"budget_balance",
			-1.0
		)
	)

	var actual_treasury: float = float(
		economy.get_state(
			"treasury",
			-1.0
		)
	)

	var actual_debt: float = float(
		economy.get_state(
			"government_debt",
			-1.0
		)
	)

	var expected_revenue: float = actual_gdp * tax_rate
	var expected_spending: float = actual_gdp * spending_rate
	var expected_budget: float = expected_revenue - expected_spending
	var expected_treasury: float = starting_treasury + expected_budget
	var expected_debt: float = maxf(
		starting_debt - expected_budget,
		0.0
	)

	_out([
		label,
		" GDP=",
		actual_gdp,
		" revenue=",
		actual_revenue,
		" spending=",
		actual_spending,
		" budget=",
		actual_budget,
		" treasury=",
		actual_treasury,
		" debt=",
		actual_debt
	])

	if is_equal_approx(
		actual_revenue,
		expected_revenue
	):
		_out([
			"PASS: ",
			label,
			" GDP -> government revenue"
		])
	else:
		_out([
			"FAIL: ",
			label,
			" GDP -> government revenue | expected=",
			expected_revenue,
			" actual=",
			actual_revenue
		])

	if is_equal_approx(
		actual_spending,
		expected_spending
	):
		_out([
			"PASS: ",
			label,
			" GDP -> government spending"
		])
	else:
		_out([
			"FAIL: ",
			label,
			" GDP -> government spending | expected=",
			expected_spending,
			" actual=",
			actual_spending
		])

	if is_equal_approx(
		actual_budget,
		expected_budget
	):
		_out([
			"PASS: ",
			label,
			" revenue/spending -> budget balance"
		])
	else:
		_out([
			"FAIL: ",
			label,
			" budget balance | expected=",
			expected_budget,
			" actual=",
			actual_budget
		])

	if is_equal_approx(
		actual_treasury,
		expected_treasury
	):
		_out([
			"PASS: ",
			label,
			" budget balance -> treasury"
		])
	else:
		_out([
			"FAIL: ",
			label,
			" treasury | expected=",
			expected_treasury,
			" actual=",
			actual_treasury
		])

	if is_equal_approx(
		actual_debt,
		expected_debt
	):
		_out([
			"PASS: ",
			label,
			" budget balance -> government debt"
		])
	else:
		_out([
			"FAIL: ",
			label,
			" government debt | expected=",
			expected_debt,
			" actual=",
			actual_debt
		])

	var result: Dictionary = {
		"gdp": actual_gdp,
		"revenue": actual_revenue,
		"spending": actual_spending,
		"budget": actual_budget,
		"treasury": actual_treasury,
		"debt": actual_debt
	}

	return result


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
		"ECONOMY INTEGRATION — ECONOMIC CONDITIONS -> GOVERNMENT FINANCES TEST"
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

	const TAX_RATE: float = 0.15
	const SPENDING_RATE: float = 0.10
	const STARTING_TREASURY: float = 100.0
	const STARTING_DEBT: float = 500.0

	# Keep GDP unchanged during each controlled run. The test
	# isolates the economic-condition -> government-finance chain.
	economy.set_state(
		"growth_rate",
		0.0
	)

	economy.set_state(
		"inflation",
		0.0
	)

	economy.set_state(
		"unemployment",
		0.0
	)

	economy.set_state(
		"investment_rate",
		0.0
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
		"investment_to_capacity_rate",
		0.01
	)

	economy.set_state(
		"tax_revenue_rate",
		TAX_RATE
	)

	economy.set_state(
		"government_spending_rate",
		SPENDING_RATE
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

	var weak: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		900.0,
		"Weak economic condition",
		TAX_RATE,
		SPENDING_RATE,
		STARTING_TREASURY,
		STARTING_DEBT
	)

	var baseline: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		1000.0,
		"Baseline economic condition",
		TAX_RATE,
		SPENDING_RATE,
		STARTING_TREASURY,
		STARTING_DEBT
	)

	var strong: Dictionary = _run_condition(
		world,
		economy_system,
		economy,
		1100.0,
		"Strong economic condition",
		TAX_RATE,
		SPENDING_RATE,
		STARTING_TREASURY,
		STARTING_DEBT
	)

	if (
		float(weak["gdp"]) < float(baseline["gdp"])
		and float(baseline["gdp"]) < float(strong["gdp"])
	):
		_out([
			"PASS: Economic condition changes GDP monotonically."
		])
	else:
		_out([
			"FAIL: Controlled economic conditions did not preserve GDP ordering."
		])
		passed = false

	if (
		float(weak["revenue"]) < float(baseline["revenue"])
		and float(baseline["revenue"]) < float(strong["revenue"])
	):
		_out([
			"PASS: Economic condition monotonically changes government revenue."
		])
	else:
		_out([
			"FAIL: Government revenue does not track economic conditions monotonically."
		])
		passed = false

	if (
		float(weak["spending"]) < float(baseline["spending"])
		and float(baseline["spending"]) < float(strong["spending"])
	):
		_out([
			"PASS: Economic condition monotonically changes government spending."
		])
	else:
		_out([
			"FAIL: Government spending does not track economic conditions monotonically."
		])
		passed = false

	if (
		float(weak["budget"]) < float(baseline["budget"])
		and float(baseline["budget"]) < float(strong["budget"])
	):
		_out([
			"PASS: Economic condition monotonically changes budget balance."
		])
	else:
		_out([
			"FAIL: Budget balance does not track economic conditions monotonically."
		])
		passed = false

	if (
		float(weak["treasury"]) < float(baseline["treasury"])
		and float(baseline["treasury"]) < float(strong["treasury"])
	):
		_out([
			"PASS: Economic condition monotonically changes treasury."
		])
	else:
		_out([
			"FAIL: Treasury does not track economic conditions monotonically."
		])
		passed = false

	if (
		float(weak["debt"]) > float(baseline["debt"])
		and float(baseline["debt"]) > float(strong["debt"])
	):
		_out([
			"PASS: Economic condition monotonically changes government debt."
		])
	else:
		_out([
			"FAIL: Government debt does not track economic conditions monotonically."
		])
		passed = false

	economy.state = original_economy_state

	if passed:
		_out([
			"EconomyEconomicConditionsGovernmentFinancesTest: PASS"
		])
	else:
		_out([
			"EconomyEconomicConditionsGovernmentFinancesTest: FAIL"
		])

	return passed
