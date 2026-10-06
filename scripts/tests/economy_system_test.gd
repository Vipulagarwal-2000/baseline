class_name EconomySystemTest
extends RefCounted


func run_test(world) -> bool:

	print("")
	print("====================================================")
	print("ECONOMY SYSTEM TEST")
	print("====================================================")

	var passed := true

	if world == null:
		push_error("EconomySystemTest: World is null.")
		return false

	var india = world.entities.get("india")

	if india == null:
		push_error("EconomySystemTest: India not found.")
		return false

	print("EconomySystemTest: India found.")


	# ----------------------------------------------------
	# COMPONENTS
	# ----------------------------------------------------

	var economy = india.get_component("economy")
	var industry = india.get_component("industry")
	var resources = india.get_component("resources")
	var research = india.get_component("research")
	var infrastructure = india.get_component("infrastructure")

	if economy == null:
		push_error("EconomySystemTest: Economy component missing.")
		return false

	if industry == null:
		push_error("EconomySystemTest: Industry component missing.")
		return false

	if resources == null:
		push_error("EconomySystemTest: Resource component missing.")
		return false

	if research == null:
		push_error("EconomySystemTest: Research component missing.")
		return false

	if infrastructure == null:
		push_error("EconomySystemTest: Infrastructure component missing.")
		return false


	# ----------------------------------------------------
	# SAVE ORIGINAL STATE
	# ----------------------------------------------------

	var original_processes = industry.get_state(
		"processes",
		{}
	)

	var original_resource_efficiency = resources.get_state(
		"resource_efficiency",
		1.0
	)

	var original_technology_effects = research.get_state(
		"technology_effects",
		{}
	)

	var original_technologies = research.get_state(
		"technologies",
		{}
	)

	var original_gdp = economy.get_state(
		"gdp",
		0.0
	)

	var original_growth_rate = economy.get_state(
		"growth_rate",
		0.0
	)

	var original_inflation = economy.get_state(
		"inflation",
		0.0
	)

	var original_unemployment = economy.get_state(
		"unemployment",
		0.0
	)

	var original_industrial_infrastructure = infrastructure.get_state(
		"industrial",
		1.0
	)

	var original_effective_growth_rate = economy.get_state(
		"effective_growth_rate",
		0.0
	)

	var original_gdp_per_capita = economy.get_state(
		"gdp_per_capita",
		0.0
	)

	# ----------------------------------------------------
	# STEP 2.3 PRODUCTION OUTPUT STATE
	# ----------------------------------------------------
	# EconomySystem now reads realized physical production from
	# IndustryComponent.production_state. This legacy economy test
	# does not execute ProductionProcessSystem, so keep that state
	# isolated and neutral for the economy-only calculations.
	var original_production_state = industry.get_state(
		"production_state",
		{}
	)

	var original_physical_production_output = economy.get_state(
		"physical_production_output",
		0.0
	)

	var original_physical_production_capacity = economy.get_state(
		"physical_production_capacity",
		0.0
	)

	var original_production_output_factor = economy.get_state(
		"production_output_factor",
		1.0
	)

	var original_investment_rate = economy.get_state(
		"investment_rate",
		0.10
	)

	var original_investment = economy.get_state(
		"investment",
		0.0
	)

	var original_investment_capacity = economy.get_state(
		"investment_capacity",
		0.0
	)

	var original_unallocated_industrial_capacity = economy.get_state(
		"unallocated_industrial_capacity",
		0.0
	)

	var original_investment_to_capacity_rate = economy.get_state(
		"investment_to_capacity_rate",
		0.01
	)

	var original_tax_revenue_rate = economy.get_state(
		"tax_revenue_rate",
		0.10
	)

	var original_government_revenue = economy.get_state(
		"government_revenue",
		0.0
	)

	var original_government_spending_rate = economy.get_state(
		"government_spending_rate",
		0.10
	)

	var original_government_spending = economy.get_state(
		"government_spending",
		0.0
	)

	var original_budget_balance = economy.get_state(
		"budget_balance",
		0.0
	)

	var original_treasury = economy.get_state(
		"treasury",
		0.0
	)

	var original_government_debt = economy.get_state(
		"government_debt",
		0.0
	)


	# ----------------------------------------------------
	# CONTROLLED INDUSTRY STATE
	# ----------------------------------------------------

	var test_processes := {
		"test_process_a": {
			"active": true,
			"capacity": 100.0,
			"efficiency": 0.70
		},
		"test_process_b": {
			"active": true,
			"capacity": 50.0,
			"efficiency": 0.90
		},
		"test_process_inactive": {
			"active": false,
			"capacity": 1000.0,
			"efficiency": 1.0
		}
	}

	industry.set_state(
		"processes",
		test_processes
	)


	# ----------------------------------------------------
	# CONTROLLED RESOURCE STATE
	# ----------------------------------------------------

	var expected_resource_efficiency := 0.65

	resources.set_state(
		"resource_efficiency",
		expected_resource_efficiency
	)


	# ----------------------------------------------------
	# CONTROLLED TECHNOLOGY STATE
	# ----------------------------------------------------

	var technology_effects := {
		"industrial_production_efficiency": 1.10
	}

	research.set_state(
		"technology_effects",
		technology_effects
	)

	research.set_state(
		"technologies",
		{
			"industrial_machinery": true
		}
	)


	# ----------------------------------------------------
	# CONTROLLED INVESTMENT CAPACITY STATE
	# ----------------------------------------------------

	# Step 2.3 isolation:
	# No ProductionProcessSystem pass is performed by this legacy test.
	# Therefore EconomySystem must see no realized production outcome
	# and retain the neutral production-output factor of 1.0.
	industry.set_state(
		"production_state",
		{}
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


	# ----------------------------------------------------
	# BASELINE INDUSTRIAL INFRASTRUCTURE STATE
	# ----------------------------------------------------
	# EconomySystem now applies InfrastructureComponent.industrial
	# to usable process capacity. Keep the baseline economy checks
	# neutral so they measure the controlled process capacities
	# directly. The dedicated 50% infrastructure test below then
	# verifies the causal infrastructure constraint.
	infrastructure.set_state(
		"industrial",
		1.0
	)


	# ----------------------------------------------------
	# CONTROLLED TAX REVENUE STATE
	# ----------------------------------------------------

	var controlled_tax_revenue_rate: float = 0.10

	economy.set_state(
		"tax_revenue_rate",
		controlled_tax_revenue_rate
	)


	# ----------------------------------------------------
	# CONTROLLED GOVERNMENT SPENDING STATE
	# ----------------------------------------------------

	var controlled_government_spending_rate: float = 0.10

	economy.set_state(
		"government_spending_rate",
		controlled_government_spending_rate
	)


	# ----------------------------------------------------
	# TECHNOLOGY EFFECT SYSTEM
	# ----------------------------------------------------

	var technology_effect_system = TechnologyEffectSystem.new()

	technology_effect_system.process_month(world)

	var refreshed_effects = research.get_state(
		"technology_effects",
		{}
	)

	if typeof(refreshed_effects) == TYPE_DICTIONARY:
		print("PASS: Technology effects dictionary exists.")
	else:
		push_error(
			"FAIL: Technology effects dictionary missing."
		)
		passed = false


	var expected_technology_efficiency := float(
		refreshed_effects.get(
			"industrial_production_efficiency",
			1.0
		)
	)

	if is_equal_approx(
		expected_technology_efficiency,
		1.10
	):
		print(
			"PASS: Industrial production technology effect = ",
			expected_technology_efficiency
		)
	else:
		push_error(
			"FAIL: Industrial production technology effect. "
			+ "Expected 1.1, got "
			+ str(expected_technology_efficiency)
		)
		passed = false


	# ----------------------------------------------------
	# ECONOMY SYSTEM
	# ----------------------------------------------------

	var economy_system := EconomySystem.new()

	economy_system.process_month(world)


	# ----------------------------------------------------
	# INDUSTRIAL CAPACITY
	# ----------------------------------------------------

	# Starting investment capacity is explicitly controlled
	# to zero, so only active industry processes contribute
	# during this first monthly pass.

	var expected_industrial_capacity := 150.0

	var actual_industrial_capacity := float(
		economy.get_state(
			"industrial_capacity",
			-1.0
		)
	)


	if is_equal_approx(
		actual_industrial_capacity,
		expected_industrial_capacity
	):
		print(
			"PASS: Industrial capacity = ",
			actual_industrial_capacity
		)
	else:
		push_error(
			"FAIL: Industrial capacity. "
			+ "Expected "
			+ str(expected_industrial_capacity)
			+ ", got "
			+ str(actual_industrial_capacity)
		)
		passed = false


	# ----------------------------------------------------
	# PRODUCTION EFFICIENCY
	# ----------------------------------------------------

	var expected_production_efficiency := (
		(
			100.0 * 0.70
		)
		+
		(
			50.0 * 0.90
		)
	) / 150.0

	var actual_production_efficiency := float(
		economy.get_state(
			"production_efficiency",
			-1.0
		)
	)

	if is_equal_approx(
		actual_production_efficiency,
		expected_production_efficiency
	):
		print(
			"PASS: Production efficiency = ",
			actual_production_efficiency
		)
	else:
		push_error(
			"FAIL: Production efficiency. "
			+ "Expected "
			+ str(expected_production_efficiency)
			+ ", got "
			+ str(actual_production_efficiency)
		)
		passed = false


	# ----------------------------------------------------
	# RESOURCE EFFICIENCY
	# ----------------------------------------------------

	var actual_resource_efficiency := float(
		economy.get_state(
			"resource_efficiency",
			-1.0
		)
	)

	if is_equal_approx(
		actual_resource_efficiency,
		expected_resource_efficiency
	):
		print(
			"PASS: Resource efficiency = ",
			actual_resource_efficiency
		)
	else:
		push_error(
			"FAIL: Resource efficiency. "
			+ "Expected "
			+ str(expected_resource_efficiency)
			+ ", got "
			+ str(actual_resource_efficiency)
		)
		passed = false


	# ----------------------------------------------------
	# TECHNOLOGY EFFICIENCY
	# ----------------------------------------------------

	var actual_technology_efficiency := float(
		economy.get_state(
			"technology_efficiency",
			-1.0
		)
	)

	if is_equal_approx(
		actual_technology_efficiency,
		expected_technology_efficiency
	):
		print(
			"PASS: Technology efficiency = ",
			actual_technology_efficiency
		)
	else:
		push_error(
			"FAIL: Technology efficiency. "
			+ "Expected "
			+ str(expected_technology_efficiency)
			+ ", got "
			+ str(actual_technology_efficiency)
		)
		passed = false


	# ----------------------------------------------------
	# ECONOMIC EFFICIENCY
	# ----------------------------------------------------

	var expected_economic_efficiency := (
		expected_production_efficiency
		* expected_resource_efficiency
		* expected_technology_efficiency
	)

	var actual_economic_efficiency := float(
		economy.get_state(
			"economic_efficiency",
			-1.0
		)
	)

	if is_equal_approx(
		actual_economic_efficiency,
		expected_economic_efficiency
	):
		print(
			"PASS: Economic efficiency = ",
			actual_economic_efficiency
		)
	else:
		push_error(
			"FAIL: Economic efficiency. "
			+ "Expected "
			+ str(expected_economic_efficiency)
			+ ", got "
			+ str(actual_economic_efficiency)
		)
		passed = false


	# ----------------------------------------------------
	# RESET INVESTMENT CAPACITY
	# ----------------------------------------------------

	# The previous economy pass may have generated investment
	# capacity from the real world GDP.
	#
	# Reset both capacity pools here so the controlled
	# GDP/investment test starts from a deterministic zero
	# baseline. The first real-world economy pass above
	# may have created capacity from India's actual GDP.

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


	# ----------------------------------------------------
	# INDUSTRIAL INFRASTRUCTURE → PRODUCTIVE CAPACITY
	# ----------------------------------------------------

	# Keep investment capacity at zero so this test measures only
	# the effect of specialized industrial infrastructure on the
	# active production-capacity pool.

	infrastructure.set_state(
		"industrial",
		0.50
	)

	economy_system.process_month(world)

	var expected_industrial_capacity_with_infrastructure: float = 75.0

	var actual_industrial_capacity_with_infrastructure := float(
		economy.get_state(
			"industrial_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		actual_industrial_capacity_with_infrastructure,
		expected_industrial_capacity_with_infrastructure
	):
		print(
			"PASS: 50% industrial infrastructure limits productive capacity = ",
			actual_industrial_capacity_with_infrastructure
		)
	else:
		push_error(
			"FAIL: Industrial infrastructure productive capacity. "
			+ "Expected "
			+ str(expected_industrial_capacity_with_infrastructure)
			+ ", got "
			+ str(actual_industrial_capacity_with_infrastructure)
		)
		passed = false


	# The specialized-infrastructure test must not silently alter
	# the configured production-process capacities themselves.
	var process_a_capacity_after_infrastructure_test := float(
		test_processes["test_process_a"].get(
			"capacity",
			-1.0
		)
	)

	var process_b_capacity_after_infrastructure_test := float(
		test_processes["test_process_b"].get(
			"capacity",
			-1.0
		)
	)

	if (
		is_equal_approx(
			process_a_capacity_after_infrastructure_test,
			100.0
		)
		and
		is_equal_approx(
			process_b_capacity_after_infrastructure_test,
			50.0
		)
	):
		print(
			"PASS: Industrial infrastructure does not rewrite process capacities."
		)
	else:
		push_error(
			"FAIL: Industrial infrastructure rewrote process capacities."
		)
		passed = false


	# Restore neutral industrial infrastructure before the
	# following GDP/economic integration tests.
	infrastructure.set_state(
		"industrial",
		1.0
	)

	economy.set_state(
		"investment_capacity",
		0.0
	)

# The preceding industrial-infrastructure test runs a real
# economy pass while India has its live GDP. That pass generates
# real-world unallocated investment capacity. Clear it here so
# the controlled GDP/investment section starts from a deterministic
# zero baseline as intended.
	economy.set_state(
		"unallocated_industrial_capacity",
		0.0
	)


	# ----------------------------------------------------
	# GDP / ECONOMIC EFFICIENCY INTEGRATION
	# ----------------------------------------------------

	var controlled_gdp: float = 1000.0
	var controlled_growth_rate: float = 12.0
	var controlled_inflation: float = 0.0
	var controlled_unemployment: float = 0.0
	var controlled_investment_rate: float = 0.10

	economy.set_state(
		"gdp",
		controlled_gdp
	)

	economy.set_state(
		"growth_rate",
		controlled_growth_rate
	)

	economy.set_state(
		"inflation",
		controlled_inflation
	)

	economy.set_state(
		"unemployment",
		controlled_unemployment
	)

	economy.set_state(
		"investment_rate",
		controlled_investment_rate
	)

	economy_system.process_month(world)


	# ----------------------------------------------------
	# EFFECTIVE GROWTH RATE
	# ----------------------------------------------------

	var expected_effective_growth_rate: float = (
		controlled_growth_rate
		* expected_economic_efficiency
	)

	var actual_effective_growth_rate := float(
		economy.get_state(
			"effective_growth_rate",
			-1.0
		)
	)

	if is_equal_approx(
		actual_effective_growth_rate,
		expected_effective_growth_rate
	):
		print(
			"PASS: Efficiency-adjusted growth rate = ",
			actual_effective_growth_rate
		)
	else:
		push_error(
			"FAIL: Efficiency-adjusted growth rate. "
			+ "Expected "
			+ str(expected_effective_growth_rate)
			+ ", got "
			+ str(actual_effective_growth_rate)
		)
		passed = false


	# ----------------------------------------------------
	# GDP RESPONSE
	# ----------------------------------------------------

	var expected_gdp: float = (
		controlled_gdp
		+
		(
			controlled_gdp
			* expected_effective_growth_rate
			/ 12.0
			/ 100.0
		)
	)

	var actual_gdp := float(
		economy.get_state(
			"gdp",
			-1.0
		)
	)

	if is_equal_approx(
		actual_gdp,
		expected_gdp
	):
		print(
			"PASS: GDP responds to economic efficiency = ",
			actual_gdp
		)
	else:
		push_error(
			"FAIL: GDP response to economic efficiency. "
			+ "Expected "
			+ str(expected_gdp)
			+ ", got "
			+ str(actual_gdp)
		)
		passed = false


	# ----------------------------------------------------
	# GDP → GOVERNMENT REVENUE
	# ----------------------------------------------------

	var expected_government_revenue: float = (
		actual_gdp
		* controlled_tax_revenue_rate
	)

	var actual_government_revenue := float(
		economy.get_state(
			"government_revenue",
			-1.0
		)
	)

	if is_equal_approx(
		actual_government_revenue,
		expected_government_revenue
	):
		print(
			"PASS: GDP → government revenue = ",
			actual_government_revenue
		)
	else:
		push_error(
			"FAIL: GDP → government revenue. "
			+ "Expected "
			+ str(expected_government_revenue)
			+ ", got "
			+ str(actual_government_revenue)
		)
		passed = false


	# ----------------------------------------------------
	# GDP → GOVERNMENT SPENDING
	# ----------------------------------------------------

	var expected_government_spending: float = (
		actual_gdp
		* controlled_government_spending_rate
	)

	var actual_government_spending := float(
		economy.get_state(
			"government_spending",
			-1.0
		)
	)

	if is_equal_approx(
		actual_government_spending,
		expected_government_spending
	):
		print(
			"PASS: GDP → government spending = ",
			actual_government_spending
		)
	else:
		push_error(
			"FAIL: GDP → government spending. "
			+ "Expected "
			+ str(expected_government_spending)
			+ ", got "
			+ str(actual_government_spending)
		)
		passed = false


	# ----------------------------------------------------
	# GOVERNMENT REVENUE / SPENDING → BUDGET BALANCE
	# ----------------------------------------------------

	var expected_budget_balance: float = (
		expected_government_revenue
		- expected_government_spending
	)

	var actual_budget_balance := float(
		economy.get_state(
			"budget_balance",
			-1.0
		)
	)

	if is_equal_approx(
		actual_budget_balance,
		expected_budget_balance
	):
		print(
			"PASS: Government revenue - government spending = budget balance = ",
			actual_budget_balance
		)
	else:
		push_error(
			"FAIL: Government revenue - government spending = budget balance. "
			+ "Expected "
			+ str(expected_budget_balance)
			+ ", got "
			+ str(actual_budget_balance)
		)
		passed = false


	# ----------------------------------------------------
	# GDP → INVESTMENT INTEGRATION
	# ----------------------------------------------------

	var expected_investment: float = (
		actual_gdp
		* controlled_investment_rate
	)

	var actual_investment := float(
		economy.get_state(
			"investment",
			-1.0
		)
	)

	if is_equal_approx(
		actual_investment,
		expected_investment
	):
		print(
			"PASS: GDP → investment = ",
			actual_investment
		)
	else:
		push_error(
			"FAIL: GDP → investment. "
			+ "Expected "
			+ str(expected_investment)
			+ ", got "
			+ str(actual_investment)
		)
		passed = false


	# ----------------------------------------------------
	# INVESTMENT → INDUSTRIAL CAPACITY
	# ----------------------------------------------------

	# New capacity created from this month's investment
	# becomes usable during the NEXT monthly economy pass.

	var expected_investment_capacity_added: float = (
		actual_investment
		* 0.01
	)

	var actual_investment_capacity := float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		actual_investment_capacity,
		expected_investment_capacity_added
	):
		print(
			"PASS: Investment → capacity = ",
			actual_investment_capacity
		)
	else:
		push_error(
			"FAIL: Investment → capacity. "
			+ "Expected "
			+ str(expected_investment_capacity_added)
			+ ", got "
			+ str(actual_investment_capacity)
		)
		passed = false


	# ----------------------------------------------------
	# INVESTMENT → UNALLOCATED INDUSTRIAL CAPACITY
	# ----------------------------------------------------

	var actual_unallocated_capacity := float(
		economy.get_state(
			"unallocated_industrial_capacity",
			-1.0
		)
	)

	var expected_unallocated_capacity: float = (
		expected_investment_capacity_added
	)

	if is_equal_approx(
		actual_unallocated_capacity,
		expected_unallocated_capacity
	):
		print(
			"PASS: New investment enters unallocated capacity = ",
			actual_unallocated_capacity
		)
	else:
		push_error(
			"FAIL: Investment → unallocated capacity. "
			+ "Expected "
			+ str(expected_unallocated_capacity)
			+ ", got "
			+ str(actual_unallocated_capacity)
		)
		passed = false


	# New capacity should remain unallocated. The economy system must
	# not silently assign it to an existing production process.

	var process_a_after_first_pass = test_processes.get(
		"test_process_a",
		{}
	)

	var process_b_after_first_pass = test_processes.get(
		"test_process_b",
		{}
	)

	var process_a_capacity_after_first_pass := float(
		process_a_after_first_pass.get(
			"capacity",
			-1.0
		)
	)

	var process_b_capacity_after_first_pass := float(
		process_b_after_first_pass.get(
			"capacity",
			-1.0
		)
	)

	if (
		is_equal_approx(
			process_a_capacity_after_first_pass,
			100.0
		)
		and
		is_equal_approx(
			process_b_capacity_after_first_pass,
			50.0
		)
	):
		print(
			"PASS: Unallocated capacity is not assigned to processes."
		)
	else:
		push_error(
			"FAIL: Unallocated capacity was assigned to a process."
		)
		passed = false


	# ----------------------------------------------------
	# INVESTMENT CAPACITY ACCUMULATION
	# ----------------------------------------------------

	var previous_investment_capacity := (
		actual_investment_capacity
	)

	economy_system.process_month(world)

	var second_month_industrial_capacity := float(
		economy.get_state(
			"industrial_capacity",
			-1.0
		)
	)

	var expected_second_month_industrial_capacity: float = (
		150.0
		+
		previous_investment_capacity
	)

	if is_equal_approx(
		second_month_industrial_capacity,
		expected_second_month_industrial_capacity
	):
		print(
			"PASS: Previous investment capacity becomes active = ",
			second_month_industrial_capacity
		)
	else:
		push_error(
			"FAIL: Previous investment capacity activation. "
			+ "Expected "
			+ str(expected_second_month_industrial_capacity)
			+ ", got "
			+ str(second_month_industrial_capacity)
		)
		passed = false


	var second_month_investment := float(
		economy.get_state(
			"investment",
			-1.0
		)
	)

	var expected_accumulated_capacity: float = (
		previous_investment_capacity
		+
		(
			second_month_investment
			* 0.01
		)
	)

	var accumulated_investment_capacity := float(
		economy.get_state(
			"investment_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		accumulated_investment_capacity,
		expected_accumulated_capacity
	):
		print(
			"PASS: Investment capacity accumulates = ",
			accumulated_investment_capacity
		)
	else:
		push_error(
			"FAIL: Investment capacity accumulation. "
			+ "Expected "
			+ str(expected_accumulated_capacity)
			+ ", got "
			+ str(accumulated_investment_capacity)
		)
		passed = false


	# ----------------------------------------------------
	# UNALLOCATED CAPACITY ACCUMULATION
	# ----------------------------------------------------

	var second_month_new_investment_capacity: float = (
		second_month_investment
		* 0.01
	)

	var expected_second_month_unallocated_capacity: float = (
		actual_unallocated_capacity
		+
		second_month_new_investment_capacity
	)


	var accumulated_unallocated_capacity := float(
		economy.get_state(
			"unallocated_industrial_capacity",
			-1.0
		)
	)

	if is_equal_approx(
		accumulated_unallocated_capacity,
		expected_second_month_unallocated_capacity
	):
		print(
			"PASS: Unallocated capacity accumulates = ",
			accumulated_unallocated_capacity
		)
	else:
		push_error(
			"FAIL: Unallocated capacity accumulation. "
			+ "Expected "
			+ str(expected_second_month_unallocated_capacity)
			+ ", got "
			+ str(accumulated_unallocated_capacity)
		)
		passed = false


	# Existing unallocated capacity should still not be consumed or
	# assigned to the controlled production processes.

	var process_a_after_second_pass = test_processes.get(
		"test_process_a",
		{}
	)

	var process_b_after_second_pass = test_processes.get(
		"test_process_b",
		{}
	)

	var process_a_capacity_after_second_pass := float(
		process_a_after_second_pass.get(
			"capacity",
			-1.0
		)
	)

	var process_b_capacity_after_second_pass := float(
		process_b_after_second_pass.get(
			"capacity",
			-1.0
		)
	)

	if (
		is_equal_approx(
			process_a_capacity_after_second_pass,
			100.0
		)
		and
		is_equal_approx(
			process_b_capacity_after_second_pass,
			50.0
		)
	):
		print(
			"PASS: Existing unallocated capacity remains unassigned."
		)
	else:
		push_error(
			"FAIL: Existing unallocated capacity was assigned to a process."
		)
		passed = false


	# ----------------------------------------------------
	# TREASURY INTEGRATION
	# ----------------------------------------------------
	#
	# Treasury should carry the government's accumulated
	# cash position across monthly economy updates.
	#
	# Test both directions:
	# 1. A surplus increases treasury.
	# 2. A deficit decreases treasury.
	#
	# Use a fixed GDP and zero growth so the treasury
	# calculation is deterministic and isolated.
	# ----------------------------------------------------

	var treasury_test_gdp: float = 1000.0
	var treasury_test_growth_rate: float = 0.0
	var treasury_starting_value: float = 100.0

	economy.set_state(
		"gdp",
		treasury_test_gdp
	)

	economy.set_state(
		"growth_rate",
		treasury_test_growth_rate
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
		"treasury",
		treasury_starting_value
	)

	# ----------------------------------------------------
	# TREASURY SURPLUS
	# ----------------------------------------------------

	var treasury_surplus_tax_rate: float = 0.20
	var treasury_surplus_spending_rate: float = 0.10

	economy.set_state(
		"tax_revenue_rate",
		treasury_surplus_tax_rate
	)

	economy.set_state(
		"government_spending_rate",
		treasury_surplus_spending_rate
	)

	economy_system.process_month(world)

	var expected_surplus_budget_balance: float = (
		treasury_test_gdp
		* treasury_surplus_tax_rate
		-
		treasury_test_gdp
		* treasury_surplus_spending_rate
	)

	var expected_treasury_after_surplus: float = (
		treasury_starting_value
		+ expected_surplus_budget_balance
	)

	var actual_treasury_after_surplus := float(
		economy.get_state(
			"treasury",
			-1.0
		)
	)

	if is_equal_approx(
		actual_treasury_after_surplus,
		expected_treasury_after_surplus
	):
		print(
			"PASS: Treasury increases by budget surplus = ",
			actual_treasury_after_surplus
		)
	else:
		push_error(
			"FAIL: Treasury surplus accumulation. "
			+ "Expected "
			+ str(expected_treasury_after_surplus)
			+ ", got "
			+ str(actual_treasury_after_surplus)
		)
		passed = false


	# ----------------------------------------------------
	# TREASURY DEFICIT
	# ----------------------------------------------------

	var treasury_deficit_tax_rate: float = 0.05
	var treasury_deficit_spending_rate: float = 0.15

	economy.set_state(
		"tax_revenue_rate",
		treasury_deficit_tax_rate
	)

	economy.set_state(
		"government_spending_rate",
		treasury_deficit_spending_rate
	)

	economy_system.process_month(world)

	var expected_deficit_budget_balance: float = (
		treasury_test_gdp
		* treasury_deficit_tax_rate
		-
		treasury_test_gdp
		* treasury_deficit_spending_rate
	)

	var expected_treasury_after_deficit: float = (
		expected_treasury_after_surplus
		+ expected_deficit_budget_balance
	)

	var actual_treasury_after_deficit := float(
		economy.get_state(
			"treasury",
			-1.0
		)
	)

	if is_equal_approx(
		actual_treasury_after_deficit,
		expected_treasury_after_deficit
	):
		print(
			"PASS: Treasury decreases by budget deficit = ",
			actual_treasury_after_deficit
		)
	else:
		push_error(
			"FAIL: Treasury deficit accumulation. "
			+ "Expected "
			+ str(expected_treasury_after_deficit)
			+ ", got "
			+ str(actual_treasury_after_deficit)
		)
		passed = false


	# ----------------------------------------------------
	# GOVERNMENT DEBT INTEGRATION
	# ----------------------------------------------------
	#
	# Basic debt rule:
	# New debt = previous debt - budget balance
	#
	# A budget surplus reduces debt.
	# A budget deficit increases debt.
	# Debt cannot become negative.
	# ----------------------------------------------------

	var debt_starting_value: float = 500.0

	economy.set_state(
		"government_debt",
		debt_starting_value
	)

	# ----------------------------------------------------
	# DEBT SURPLUS
	# ----------------------------------------------------

	economy.set_state(
		"tax_revenue_rate",
		treasury_surplus_tax_rate
	)

	economy.set_state(
		"government_spending_rate",
		treasury_surplus_spending_rate
	)

	economy_system.process_month(world)

	var expected_debt_after_surplus: float = (
		debt_starting_value
		- expected_surplus_budget_balance
	)

	var actual_debt_after_surplus := float(
		economy.get_state(
			"government_debt",
			-1.0
		)
	)

	if is_equal_approx(
		actual_debt_after_surplus,
		expected_debt_after_surplus
	):
		print(
			"PASS: Government debt decreases by budget surplus = ",
			actual_debt_after_surplus
		)
	else:
		push_error(
			"FAIL: Government debt surplus response. "
			+ "Expected "
			+ str(expected_debt_after_surplus)
			+ ", got "
			+ str(actual_debt_after_surplus)
		)
		passed = false

	# ----------------------------------------------------
	# DEBT DEFICIT
	# ----------------------------------------------------

	economy.set_state(
		"tax_revenue_rate",
		treasury_deficit_tax_rate
	)

	economy.set_state(
		"government_spending_rate",
		treasury_deficit_spending_rate
	)

	economy_system.process_month(world)

	var expected_debt_after_deficit: float = (
		expected_debt_after_surplus
		- expected_deficit_budget_balance
	)

	var actual_debt_after_deficit := float(
		economy.get_state(
			"government_debt",
			-1.0
		)
	)

	if is_equal_approx(
		actual_debt_after_deficit,
		expected_debt_after_deficit
	):
		print(
			"PASS: Government debt increases by budget deficit = ",
			actual_debt_after_deficit
		)
	else:
		push_error(
			"FAIL: Government debt deficit response. "
			+ "Expected "
			+ str(expected_debt_after_deficit)
			+ ", got "
			+ str(actual_debt_after_deficit)
		)
		passed = false

	# ----------------------------------------------------
	# DEBT FLOOR
	# ----------------------------------------------------

	economy.set_state(
		"government_debt",
		50.0
	)

	economy.set_state(
		"tax_revenue_rate",
		0.20
	)

	economy.set_state(
		"government_spending_rate",
		0.10
	)

	economy_system.process_month(world)

	var actual_debt_floor := float(
		economy.get_state(
			"government_debt",
			-1.0
		)
	)

	if is_equal_approx(
		actual_debt_floor,
		0.0
	):
		print(
			"PASS: Government debt cannot become negative = ",
			actual_debt_floor
		)
	else:
		push_error(
			"FAIL: Government debt floor. "
			+ "Expected 0.0, got "
			+ str(actual_debt_floor)
		)
		passed = false


	# ----------------------------------------------------
	# RESTORE ORIGINAL STATE
	# ----------------------------------------------------

	industry.set_state(
		"processes",
		original_processes
	)

	resources.set_state(
		"resource_efficiency",
		original_resource_efficiency
	)

	infrastructure.set_state(
		"industrial",
		original_industrial_infrastructure
	)

	research.set_state(
		"technology_effects",
		original_technology_effects
	)

	research.set_state(
		"technologies",
		original_technologies
	)

	economy.set_state(
		"gdp",
		original_gdp
	)

	economy.set_state(
		"growth_rate",
		original_growth_rate
	)

	economy.set_state(
		"inflation",
		original_inflation
	)

	economy.set_state(
		"unemployment",
		original_unemployment
	)

	economy.set_state(
		"effective_growth_rate",
		original_effective_growth_rate
	)

	economy.set_state(
		"gdp_per_capita",
		original_gdp_per_capita
	)

	# Restore Step 2.3 production/economic-output state.
	industry.set_state(
		"production_state",
		original_production_state
	)

	economy.set_state(
		"physical_production_output",
		original_physical_production_output
	)

	economy.set_state(
		"physical_production_capacity",
		original_physical_production_capacity
	)

	economy.set_state(
		"production_output_factor",
		original_production_output_factor
	)

	economy.set_state(
		"investment_rate",
		original_investment_rate
	)

	economy.set_state(
		"investment",
		original_investment
	)

	economy.set_state(
		"investment_capacity",
		original_investment_capacity
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		original_unallocated_industrial_capacity
	)

	economy.set_state(
		"investment_to_capacity_rate",
		original_investment_to_capacity_rate
	)

	economy.set_state(
		"tax_revenue_rate",
		original_tax_revenue_rate
	)

	economy.set_state(
		"government_revenue",
		original_government_revenue
	)

	economy.set_state(
		"government_spending_rate",
		original_government_spending_rate
	)

	economy.set_state(
		"government_spending",
		original_government_spending
	)

	economy.set_state(
		"budget_balance",
		original_budget_balance
	)

	economy.set_state(
		"treasury",
		original_treasury
	)

	economy.set_state(
		"government_debt",
		original_government_debt
	)


	# ----------------------------------------------------
	# RESULT
	# ----------------------------------------------------

	if passed:
		print("EconomySystemTest: PASS")
	else:
		print("EconomySystemTest: FAIL")

	print("====================================================")

	return passed
