class_name EconomyComponent
extends SimComponent


func _init(owner: String = ""):
	super("economy", owner)

	state = {
		# Core economy
		"gdp": 0.0,
		"growth_rate": 0.0,
		"inflation": 0.0,
		"unemployment": 0.0,
		"gdp_per_capita": 0.0,
		"effective_growth_rate": 0.0,

		# Production
		"industrial_capacity": 0.0,
		"agricultural_capacity": 0.0,
		"production_efficiency": 0.0,
		"economic_efficiency": 0.0,

		# Government finance
		"government_revenue": 0.0,
		"government_spending": 0.0,
		"budget_balance": 0.0,
		"treasury": 0.0,
		"government_debt": 0.0,
		"tax_revenue_rate": 0.10,
		"government_spending_rate": 0.10,
		
		
		




		# Investment
		"investment": 0.0,
		"public_investment": 0.0,
		"private_investment": 0.0,
		"investment_rate": 0.10,
		"investment_capacity": 0.0,
"investment_to_capacity_rate": 0.01,
"unallocated_industrial_capacity": 0.0,


		# Step 6.1 — currency identity
		# Currency identity is part of the country's financial/economic state so
		# it is automatically covered by the existing component snapshot model.
		"currency_id": "",
		"currency_name": "",
		"currency_symbol": "",

		# Monetary conditions
		"money_supply": 0.0,
		"purchasing_power": 1.0,
		# Step 5.9 — purchasing-power diagnostics derived from existing
		# labor income, population consumption, and Step 5.7 prices.
		"population_consumption_cost": 0.0,
		"base_population_consumption_cost": 0.0,
		"consumption_price_index": 1.0,
		"real_labor_income": 0.0,
		"real_average_wage": 0.0,
		"purchasing_power_index": 1.0,
		"income_coverage_ratio": 0.0,
		"purchasing_power_ledger": {},

		# Step 9.3 — income -> purchasing power -> consumption feedback
		"population_consumption_demand_factor": 1.0,
		"population_consumption_feedback_revision": 0,
		"population_consumption_feedback_ledger": {},
		"population_consumption_feedback_last_result": {},

		# Step 5.8 — aggregate labor income / wage flow
		"base_wage_rate": 1.0,
		"skilled_wage_premium": 0.50,
		"employed_labor_units": 0.0,
		"skilled_labor_units": 0.0,
		"unskilled_labor_units": 0.0,
		"labor_income": 0.0,
		"skilled_labor_income": 0.0,
		"unskilled_labor_income": 0.0,
		"average_wage": 0.0,
		"labor_income_by_process": {},
		"income_wage_ledger": {},
		"income_flow_reconciliation_error": 0.0,

		# Economic pressure
		"economic_pressure": 0.0,
		"resource_efficiency": 1.0,
		"technology_efficiency": 1.0,
		"infrastructure_efficiency": 1.0,
		"trade_efficiency": 1.0
	}
