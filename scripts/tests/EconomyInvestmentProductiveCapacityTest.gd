class_name EconomyInvestmentProductiveCapacityTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	print("")
	print("====================================================")
	print("ECONOMY INTEGRATION — INVESTMENT -> PRODUCTIVE CAPACITY TEST")
	print("====================================================")

	var passed := true

	if world == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: World is null."
		)
		return false

	if simulation == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: SimulationEngine is null."
		)
		return false

	var india = world.get_entity(
		"india"
	)

	if india == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: India not found."
		)
		return false

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

	if economy == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Economy component missing."
		)
		return false

	if industry == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Industry component missing."
		)
		return false

	if resources == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Resource component missing."
		)
		return false

	if research == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Research component missing."
		)
		return false

	if infrastructure == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Infrastructure component missing."
		)
		return false

	# Use the registered EconomySystem. This test does not instantiate
	# an isolated economy implementation.
	var economy_system = simulation.get_system(
		"economy_system"
	)

	if economy_system == null:
		push_error(
			"EconomyInvestmentProductiveCapacityTest: Registered EconomySystem missing."
		)
		return false

	# Preserve complete mutable component state so this integration test
	# cannot alter the following active tests or the final world validation.
	var original_economy_state = economy.state.duplicate(true)
	var original_industry_state = industry.state.duplicate(true)
	var original_resource_state = resources.state.duplicate(true)
	var original_research_state = research.state.duplicate(true)
	var original_infrastructure_state = infrastructure.state.duplicate(true)

	# ------------------------------------------------------------
	# CONTROLLED ECONOMIC INPUTS
	# ------------------------------------------------------------

	industry.set_state(
		"processes",
		{
			"investment_test_process_a": {
				"active": true,
				"capacity": 100.0,
				"efficiency": 1.0
			},
			"investment_test_process_b": {
				"active": true,
				"capacity": 50.0,
				"efficiency": 1.0
			}
		}
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
		"tax_revenue_rate",
		0.0
	)

	economy.set_state(
		"government_spending_rate",
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

	# ------------------------------------------------------------
	# MONTH 1 — INVESTMENT IS CREATED
	# ------------------------------------------------------------

	economy_system.process_month(
		world
	)

	var first_month_investment = float(
		economy.get_state(
			"investment",
			-1.0
		)
	)

	var first_month_expected_investment = 100.0

	if is_equal_approx(
		first_month_investment,
		first_month_expected_investment
	):
		print(
			"PASS: Controlled GDP creates expected investment = ",
			first_month_investment
		)
	else:
		push_error(
			"FAIL: Controlled investment. Expected "
			+ str(first_month_expected_investment)
			+ ", got "
			+ str(first_month_investment)
		)
		passed = false

	var first_month_new_capacity = (
		first_month_investment
		* 0.01
	)

	var first_month_investment_capacity = float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		first_month_investment_capacity,
		first_month_new_capacity
	):
		print(
			"PASS: New investment becomes productive-capacity stock = ",
			first_month_investment_capacity
		)
	else:
		push_error(
			"FAIL: Investment-capacity creation. Expected "
			+ str(first_month_new_capacity)
			+ ", got "
			+ str(first_month_investment_capacity)
		)
		passed = false

	var first_month_unallocated_capacity = float(
		economy.get_state(
			"unallocated_industrial_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		first_month_unallocated_capacity,
		first_month_new_capacity
	):
		print(
			"PASS: New capacity enters the unallocated industrial-capacity pool = ",
			first_month_unallocated_capacity
		)
	else:
		push_error(
			"FAIL: Unallocated industrial capacity. Expected "
			+ str(first_month_new_capacity)
			+ ", got "
			+ str(first_month_unallocated_capacity)
		)
		passed = false

	# Capacity created during the current month must not be activated
	# until the next monthly economy pass.
	var first_month_industrial_capacity = float(
		economy.get_state(
			"industrial_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		first_month_industrial_capacity,
		150.0
	):
		print(
			"PASS: Current-month investment does not activate immediately = ",
			first_month_industrial_capacity
		)
	else:
		push_error(
			"FAIL: Current-month investment activated too early. Expected 150.0, got "
			+ str(first_month_industrial_capacity)
		)
		passed = false

	# The EconomySystem must not rewrite the configured process capacities.
	var process_a = industry.get_state(
		"processes",
		{}
	).get(
		"investment_test_process_a",
		{}
	)

	var process_b = industry.get_state(
		"processes",
		{}
	).get(
		"investment_test_process_b",
		{}
	)

	if (
		is_equal_approx(
			float(process_a.get("capacity", -1.0)),
			100.0
		)
		and
		is_equal_approx(
			float(process_b.get("capacity", -1.0)),
			50.0
		)
	):
		print(
			"PASS: Investment does not rewrite existing process capacities."
		)
	else:
		push_error(
			"FAIL: Investment rewrote configured process capacities."
		)
		passed = false

	# ------------------------------------------------------------
	# MONTH 2 — PREVIOUS INVESTMENT BECOMES ACTIVE
	# ------------------------------------------------------------

	economy_system.process_month(
		world
	)

	var second_month_industrial_capacity = float(
		economy.get_state(
			"industrial_capacity",
			-1.0
		)
	)

	var expected_second_month_industrial_capacity = (
		150.0
		+ first_month_new_capacity
	)

	if is_equal_approx(
		second_month_industrial_capacity,
		expected_second_month_industrial_capacity
	):
		print(
			"PASS: Previous investment increases productive capacity next month = ",
			second_month_industrial_capacity
		)
	else:
		push_error(
			"FAIL: Previous investment activation. Expected "
			+ str(expected_second_month_industrial_capacity)
			+ ", got "
			+ str(second_month_industrial_capacity)
		)
		passed = false

	var second_month_investment_capacity = float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	var expected_second_month_investment_capacity = (
		first_month_new_capacity
		+ 1.0
	)

	if is_equal_approx(
		second_month_investment_capacity,
		expected_second_month_investment_capacity
	):
		print(
			"PASS: Investment-capacity stock accumulates across months = ",
			second_month_investment_capacity
		)
	else:
		push_error(
			"FAIL: Investment-capacity accumulation. Expected "
			+ str(expected_second_month_investment_capacity)
			+ ", got "
			+ str(second_month_investment_capacity)
		)
		passed = false

	var second_month_unallocated_capacity = float(
		economy.get_state(
			"unallocated_industrial_capacity",
			-1.0
		)
	)

	var expected_second_month_unallocated_capacity = 2.0

	if is_equal_approx(
		second_month_unallocated_capacity,
		expected_second_month_unallocated_capacity
	):
		print(
			"PASS: Unallocated industrial capacity accumulates across months = ",
			second_month_unallocated_capacity
		)
	else:
		push_error(
			"FAIL: Unallocated-capacity accumulation. Expected "
			+ str(expected_second_month_unallocated_capacity)
			+ ", got "
			+ str(second_month_unallocated_capacity)
		)
		passed = false

	if passed:
		print(
			"Economy Integration — Investment -> Productive Capacity test passed: true"
		)
	else:
		print(
			"Economy Integration — Investment -> Productive Capacity test passed: false"
		)

	# Restore every mutable component state touched by this isolated test.
	economy.state = original_economy_state
	industry.state = original_industry_state
	resources.state = original_resource_state
	research.state = original_research_state
	infrastructure.state = original_infrastructure_state

	return passed
