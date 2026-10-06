class_name TaxIncidenceSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.5
# TAX INCIDENCE
# ============================================================
#
# This system connects the existing government tax-rate state to
# the existing income / purchasing-power state.
#
# MVP boundary:
#   gross labor income
#        ↓
#   existing tax rate
#        ↓
#   labor-income tax
#        ↓
#   disposable labor income
#        ↓
#   disposable real income / purchasing power
#
# It does not create a second income or consumption model, and it
# does not alter government revenue or treasury. EconomySystem owns
# government revenue; this system only models the economic actor's
# incidence using existing labor-income and purchasing-power state.
#
# The existing EconomyComponent.tax_revenue_rate is used as the
# single controlled MVP tax-rate input. More detailed tax structures
# remain outside Step 8.5.
# ============================================================

const EPSILON: float = 0.000001


func _init() -> void:
	super("tax_incidence_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var economy = entity.get_component("economy")

		if economy == null:
			continue

		_process_entity(
			economy
		)


func _process_entity(economy) -> void:

	var gross_labor_income: float = maxf(
		float(
			economy.get_state(
				"labor_income",
				0.0
			)
		),
		0.0
	)

	var gross_average_wage: float = maxf(
		float(
			economy.get_state(
				"average_wage",
				0.0
			)
		),
		0.0
	)

	var employed_labor_units: float = maxf(
		float(
			economy.get_state(
				"employed_labor_units",
				0.0
			)
		),
		0.0
	)

	var raw_tax_rate = economy.get_state(
		"tax_revenue_rate",
		0.10
	)

	var tax_rate: float = clamp(
		float(raw_tax_rate),
		0.0,
		1.0
	)

	var labor_income_tax: float = (
		gross_labor_income
		* tax_rate
	)

	labor_income_tax = clamp(
		labor_income_tax,
		0.0,
		gross_labor_income
	)

	var disposable_labor_income: float = maxf(
		gross_labor_income
		- labor_income_tax,
		0.0
	)

	var disposable_average_wage: float = (
		gross_average_wage
		* (1.0 - tax_rate)
	)

	disposable_average_wage = maxf(
		disposable_average_wage,
		0.0
	)

	var consumption_price_index: float = maxf(
		float(
			economy.get_state(
				"consumption_price_index",
				1.0
			)
		),
		EPSILON
	)

	var population_consumption_cost: float = maxf(
		float(
			economy.get_state(
				"population_consumption_cost",
				0.0
			)
		),
		0.0
	)

	var real_disposable_labor_income: float = (
		disposable_labor_income
		/ consumption_price_index
	)

	var real_disposable_average_wage: float = (
		disposable_average_wage
		/ consumption_price_index
	)

	var disposable_purchasing_power: float = maxf(
		real_disposable_average_wage,
		0.0
	)

	var purchasing_power_index: float = 0.0
	if gross_average_wage > EPSILON:
		purchasing_power_index = (
		disposable_purchasing_power
		/ gross_average_wage
	)

	var disposable_income_share: float = 0.0
	if gross_labor_income > EPSILON:
		disposable_income_share = (
		disposable_labor_income
		/ gross_labor_income
	)

	var income_coverage_ratio: float = 0.0
	if population_consumption_cost > EPSILON:
		income_coverage_ratio = (
		disposable_labor_income
		/ population_consumption_cost
	)

	var ledger: Dictionary = {
		"gross_labor_income": gross_labor_income,
		"gross_average_wage": gross_average_wage,
		"employed_labor_units": employed_labor_units,
		"tax_rate": tax_rate,
		"labor_income_tax": labor_income_tax,
		"disposable_labor_income": disposable_labor_income,
		"disposable_average_wage": disposable_average_wage,
		"consumption_price_index": consumption_price_index,
		"real_disposable_labor_income": real_disposable_labor_income,
		"real_disposable_average_wage": real_disposable_average_wage,
		"purchasing_power": disposable_purchasing_power,
		"purchasing_power_index": purchasing_power_index,
		"disposable_income_share": disposable_income_share,
		"population_consumption_cost": population_consumption_cost,
		"income_coverage_ratio": income_coverage_ratio
	}

	economy.set_state(
		"labor_income_tax_rate",
		tax_rate
	)
	economy.set_state(
		"labor_income_tax",
		labor_income_tax
	)
	economy.set_state(
		"disposable_labor_income",
		disposable_labor_income
	)
	economy.set_state(
		"disposable_average_wage",
		disposable_average_wage
	)
	economy.set_state(
		"real_disposable_labor_income",
		real_disposable_labor_income
	)
	economy.set_state(
		"real_disposable_average_wage",
		real_disposable_average_wage
	)

	# Existing purchasing-power state now represents the post-tax
	# purchasing-power outcome after tax incidence has been applied.
	economy.set_state(
		"purchasing_power",
		disposable_purchasing_power
	)
	economy.set_state(
		"purchasing_power_index",
		purchasing_power_index
	)
	economy.set_state(
		"income_coverage_ratio",
		income_coverage_ratio
	)
	economy.set_state(
		"tax_incidence_ledger",
		ledger
	)
