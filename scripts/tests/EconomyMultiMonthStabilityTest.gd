class_name EconomyMultiMonthStabilityTest
extends RefCounted


static func _out(values: Array) -> void:
	var message: String = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func _is_valid_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)


static func _expected_fiscal_factor(
	budget_balance: float,
	gdp: float
) -> float:

	if gdp <= 0.0:
		return 1.0

	return clamp(
		1.0
		+ (
			budget_balance
			/ gdp
		),
		0.0,
		1.0
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"ECONOMY INTEGRATION — MULTI-MONTH STABILITY TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var economy = india.get_component(
		"economy"
	)

	var industry = india.get_component(
		"industry"
	)

	var resources = india.get_component(
		"resources"
	)

	var research = india.get_component(
		"research"
	)

	var infrastructure = india.get_component(
		"infrastructure"
	)

	if (
		economy == null
		or industry == null
		or resources == null
		or research == null
		or infrastructure == null
	):
		TestLogger.write_line(
			"Required economy components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required economy components available: PASS"
	)

	var economy_system = simulation.get_system(
		"economy_system"
	)

	if economy_system == null:
		TestLogger.write_line(
			"Registered EconomySystem available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Registered EconomySystem available: PASS"
	)

	# Preserve every mutable component state touched by this isolated
	# multi-month run. The active world must be identical after the test.
	var original_economy_state: Dictionary = economy.state.duplicate(true)
	var original_industry_state: Dictionary = industry.state.duplicate(true)
	var original_resource_state: Dictionary = resources.state.duplicate(true)
	var original_research_state: Dictionary = research.state.duplicate(true)
	var original_infrastructure_state: Dictionary = infrastructure.state.duplicate(true)

	# ------------------------------------------------------------
	# CONTROLLED ECONOMIC CHAIN
	# ------------------------------------------------------------
	#
	# The test runs the registered EconomySystem for 12 consecutive
	# monthly updates. It deliberately keeps physical production neutral
	# so Step 3.6 validates persistence/stability of the existing economy
	# chain rather than introducing another production model.
	#
	# Fiscal conditions change by phase:
	#   Months 1-4  balanced budget
	#   Months 5-8  fiscal deficit
	#   Months 9-12 fiscal surplus
	#
	# Growth remains positive and deterministic so GDP, revenue,
	# investment, treasury, debt and investment capacity can be checked
	# month-by-month using the already implemented Step 3.1-3.5 formulas.
	# ------------------------------------------------------------

	industry.set_state(
		"processes",
		{
			"step3_6_stability_process": {
				"active": true,
				"capacity": 100.0,
				"efficiency": 1.0
			}
		}
	)

	industry.set_state(
		"production_state",
		{}
	)

	industry.set_state(
		"production_totals",
		{}
	)

	resources.set_state(
		"resource_efficiency",
		1.0
	)

	research.set_state(
		"technology_effects",
		{
			"industrial_production_efficiency": 1.0
		}
	)

	infrastructure.set_state(
		"industrial",
		1.0
	)

	economy.set_state(
		"gdp",
		1000.0
	)

	economy.set_state(
		"growth_rate",
		6.0
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
		"tax_revenue_rate",
		0.10
	)

	economy.set_state(
		"government_spending_rate",
		0.10
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
		500.0
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

	var passed: bool = true

	var previous_gdp: float = 1000.0
	var previous_treasury: float = 0.0
	var previous_debt: float = 500.0
	var previous_investment_capacity: float = 0.0

	var debt_after_balanced_phase: float = previous_debt
	var debt_after_deficit_phase: float = previous_debt
	var treasury_after_deficit_phase: float = previous_treasury

	for month_index in range(12):

		var tax_rate: float = 0.10
		var spending_rate: float = 0.10
		var phase: String = "BALANCED"

		if month_index >= 4 and month_index < 8:
			tax_rate = 0.05
			spending_rate = 0.15
			phase = "DEFICIT"
		elif month_index >= 8:
			tax_rate = 0.15
			spending_rate = 0.05
			phase = "SURPLUS"

		economy.set_state(
			"tax_revenue_rate",
			tax_rate
		)

		economy.set_state(
			"government_spending_rate",
			spending_rate
		)

		economy_system.process_month(
			world
		)

		var current_gdp: float = float(
			economy.get_state(
				"gdp",
				-1.0
			)
		)

		var effective_growth_rate: float = float(
			economy.get_state(
			"effective_growth_rate",
			-1.0
		)
		)

		var government_revenue: float = float(
			economy.get_state(
			"government_revenue",
			-1.0
		)
		)

		var government_spending: float = float(
			economy.get_state(
			"government_spending",
			-1.0
		)
		)

		var budget_balance: float = float(
			economy.get_state(
			"budget_balance",
			-1.0
		)
		)

		var investment: float = float(
			economy.get_state(
			"investment",
			-1.0
		)
		)

		var fiscal_factor: float = float(
			economy.get_state(
			"government_finance_investment_factor",
			-1.0
		)
		)

		var limited_investment: float = float(
			economy.get_state(
			"government_finance_limited_investment",
			-1.0
		)
		)

		var investment_capacity: float = float(
			economy.get_state(
			"investment_capacity",
			-1.0
		)
		)

		var unallocated_capacity: float = float(
			economy.get_state(
			"unallocated_industrial_capacity",
			-1.0
		)
		)

		var industrial_capacity: float = float(
			economy.get_state(
			"industrial_capacity",
			-1.0
		)
		)

		var production_efficiency: float = float(
			economy.get_state(
			"production_efficiency",
			-1.0
		)
		)

		var economic_efficiency: float = float(
			economy.get_state(
			"economic_efficiency",
			-1.0
		)
		)

		var economic_pressure: float = float(
			economy.get_state(
			"economic_pressure",
			-1.0
		)
		)

		var production_output_factor: float = float(
			economy.get_state(
			"production_output_factor",
			-1.0
		)
		)

		var treasury: float = float(
			economy.get_state(
			"treasury",
			-1.0
		)
		)

		var government_debt: float = float(
			economy.get_state(
			"government_debt",
			-1.0
		)
		)

		# ---------------------------
		# Core finite-value checks
		# ---------------------------

		var values_to_validate: Array[float] = [
			current_gdp,
			effective_growth_rate,
			government_revenue,
			government_spending,
			budget_balance,
			investment,
			fiscal_factor,
			limited_investment,
			investment_capacity,
			unallocated_capacity,
			industrial_capacity,
			production_efficiency,
			economic_efficiency,
			economic_pressure,
			production_output_factor,
			treasury,
			government_debt
		]

		for value in values_to_validate:
			if not _is_valid_number(value):
				passed = false

		if current_gdp <= 0.0:
			passed = false

		if government_debt < 0.0:
			passed = false

		if fiscal_factor < 0.0 or fiscal_factor > 1.0:
			passed = false

		if economic_pressure < 0.0 or economic_pressure > 1.0:
			passed = false

		if production_output_factor < 0.0 or production_output_factor > 1.0:
			passed = false

		# ---------------------------
		# Month-local identities
		# ---------------------------

		var expected_gdp: float = (
			previous_gdp
			+ (
				previous_gdp
				* (0.06 / 12.0)
			)
		)

		var expected_revenue: float = (
			current_gdp
			* tax_rate
		)

		var expected_spending: float = (
			current_gdp
			* spending_rate
		)

		var expected_budget: float = (
			expected_revenue
			- expected_spending
		)

		var expected_investment: float = (
			current_gdp
			* 0.10
		)

		var expected_factor: float = _expected_fiscal_factor(
			expected_budget,
			current_gdp
		)

		var expected_limited_investment: float = (
			expected_investment
			* expected_factor
		)

		var expected_new_capacity: float = (
			expected_limited_investment
			* 0.01
		)

		var expected_treasury: float = (
			previous_treasury
			+ expected_budget
		)

		var expected_debt: float = max(
			previous_debt
			- expected_budget,
			0.0
		)

		var expected_investment_capacity: float = (
			previous_investment_capacity
			+ expected_new_capacity
		)

		if not is_equal_approx(
			current_gdp,
			expected_gdp
		):
			passed = false

		if not is_equal_approx(
			government_revenue,
			expected_revenue
		):
			passed = false

		if not is_equal_approx(
			government_spending,
			expected_spending
		):
			passed = false

		if not is_equal_approx(
			budget_balance,
			expected_budget
		):
			passed = false

		if not is_equal_approx(
			investment,
			expected_investment
		):
			passed = false

		if not is_equal_approx(
			fiscal_factor,
			expected_factor
		):
			passed = false

		if not is_equal_approx(
			limited_investment,
			expected_limited_investment
		):
			passed = false

		if not is_equal_approx(
			investment_capacity,
			expected_investment_capacity
		):
			passed = false

		if not is_equal_approx(
			unallocated_capacity,
		expected_investment_capacity
		):
			passed = false

		var expected_industrial_capacity: float = (
			100.0
			+ previous_investment_capacity
		)

		if not is_equal_approx(
			industrial_capacity,
			expected_industrial_capacity
		):
			passed = false

		if not is_equal_approx(
			production_efficiency,
			1.0
		):
			passed = false

		if not is_equal_approx(
			economic_efficiency,
			1.0
		):
			passed = false

		if not is_equal_approx(
			economic_pressure,
			0.0
		):
			passed = false

		if not is_equal_approx(
			production_output_factor,
			1.0
		):
			passed = false

		if not is_equal_approx(
			treasury,
			expected_treasury
		):
			passed = false

		if not is_equal_approx(
			government_debt,
			expected_debt
		):
			passed = false

		# GDP and investment capacity are persistent stocks: each month's
		# starting stock is the previous month's ending stock.
		if current_gdp <= previous_gdp:
			passed = false

		if investment_capacity < previous_investment_capacity:
			passed = false

		_out([
			"Month ",
			month_index + 1,
			" [",
			phase,
			"]",
			" GDP=",
			current_gdp,
			" budget=",
			budget_balance,
			" treasury=",
			treasury,
			" debt=",
			government_debt,
			" investment=",
			investment,
			" fiscal_factor=",
			fiscal_factor,
			" investment_capacity=",
			investment_capacity
		])

		if (
			not is_equal_approx(
				budget_balance,
				expected_budget
			)
			or not is_equal_approx(
				investment_capacity,
				expected_investment_capacity
			)
		):
			_out([
				"FAIL: Month ",
				month_index + 1,
				" multi-month state identity."
			])
		else:
			_out([
				"PASS: Month ",
				month_index + 1,
				" multi-month state identity."
			])

		if month_index == 3:
			debt_after_balanced_phase = government_debt

		if month_index == 7:
			debt_after_deficit_phase = government_debt
			treasury_after_deficit_phase = treasury

		previous_gdp = current_gdp
		previous_treasury = treasury
		previous_debt = government_debt
		previous_investment_capacity = investment_capacity

	# ------------------------------------------------------------
	# Cross-phase stability checks
	# ------------------------------------------------------------

	if not is_equal_approx(
		debt_after_balanced_phase,
		500.0
	):
		_out([
			"FAIL: Balanced-budget phase changed government debt."
		])
		passed = false
	else:
		_out([
			"PASS: Balanced-budget phase preserves government debt."
		])

	if debt_after_deficit_phase <= debt_after_balanced_phase:
		_out([
			"FAIL: Deficit phase did not increase government debt."
		])
		passed = false
	else:
		_out([
			"PASS: Deficit phase increases government debt."
		])

	if treasury_after_deficit_phase >= 0.0:
		_out([
			"FAIL: Deficit phase did not reduce treasury below its starting balance."
		])
		passed = false
	else:
		_out([
			"PASS: Deficit phase carries treasury depletion across months."
		])

	var final_debt: float = float(
		economy.get_state(
			"government_debt",
			-1.0
		)
	)

	if final_debt >= debt_after_deficit_phase:
		_out([
			"FAIL: Surplus phase did not reduce government debt from the deficit-phase peak."
		])
		passed = false
	else:
		_out([
			"PASS: Surplus phase reduces government debt after the deficit phase."
		])

	var final_investment_capacity: float = float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	if final_investment_capacity <= 0.0:
		_out([
			"FAIL: Investment capacity did not accumulate across the multi-month run."
		])
		passed = false
	else:
		_out([
			"PASS: Investment capacity accumulates across the multi-month run."
		])
	# Restore complete mutable state before returning to the active suite.
	economy.state = original_economy_state
	industry.state = original_industry_state
	resources.state = original_resource_state
	research.state = original_research_state
	infrastructure.state = original_infrastructure_state

	if passed:
		_out([
			"EconomyMultiMonthStabilityTest: PASS"
		])
	else:
		_out([
			"EconomyMultiMonthStabilityTest: FAIL"
		])

	return passed
