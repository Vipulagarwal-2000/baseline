class_name PopulationComponent
extends SimComponent


func _init(owner: String = ""):
	super("population", owner)

	state = {
		"population": 0.0,
		"growth_rate": 0.0,
		"birth_rate": 0.0,
		"death_rate": 0.0,
		"urbanization": 0.0,

		"base_immigration": 0.0,
		"base_emigration": 0.0,

		"immigration": 0.0,
		"emigration": 0.0,
		"net_migration": 0.0,
		
		
		"migration_capacity": 0.0,
		"migration_capacity_used": 0.0,
		"migration_policy": 1.0,

		"natural_growth_rate": 0.0,
		"natural_population_change": 0.0,
		"monthly_population_change": 0.0,

		# ====================================================
		# STEP 9.1 — STANDARD OF LIVING
		# ====================================================

		"standard_of_living_index": 0.0,
		"standard_of_living_income_score": 0.0,
		"standard_of_living_food_availability": 0.0,
		"standard_of_living_essential_goods_availability": 0.0,
		"standard_of_living_employment_score": 0.0,
		"standard_of_living_public_service_score": 0.0,
		"standard_of_living_price_pressure": 0.0,
		"standard_of_living_revision": 0,
		"standard_of_living_ledger": {},
		"standard_of_living_last_result": {},

		# ====================================================
		# STEP 9.2 — WELFARE EFFECT
		# ====================================================

		"welfare_effect": 0.0,
		"welfare_pressure": 0.0,
		"welfare_revision": 0,
		"welfare_ledger": {},
		"welfare_last_result": {}
	}
