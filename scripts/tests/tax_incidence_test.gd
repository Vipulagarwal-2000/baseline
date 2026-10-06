class_name TaxIncidenceTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT TAX INCIDENCE TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var tax_system_instance = simulation.get_system(
		"tax_incidence_system"
	)

	var tax_system_ok: bool = (
		tax_system_instance != null
		and tax_system_instance is TaxIncidenceSystem
	)

	TestLogger.write_line(
		"Registered TaxIncidenceSystem available: "
		+ ("PASS" if tax_system_ok else "FAIL")
	)

	all_passed = all_passed and tax_system_ok
	if not tax_system_ok:
		return false

	var tax_system: TaxIncidenceSystem = (
		tax_system_instance as TaxIncidenceSystem
	)

	var effect_system_instance = simulation.get_system(
		"government_policy_effect_system"
	)

	var effect_system_ok: bool = (
		effect_system_instance != null
		and effect_system_instance is GovernmentPolicyEffectSystem
	)

	TestLogger.write_line(
		"Registered GovernmentPolicyEffectSystem available: "
		+ ("PASS" if effect_system_ok else "FAIL")
	)

	all_passed = all_passed and effect_system_ok
	if not effect_system_ok:
		return false

	var effect_system: GovernmentPolicyEffectSystem = (
		effect_system_instance as GovernmentPolicyEffectSystem
	)

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false

	TestLogger.write_line("India available: PASS")

	var government = india.get_component("government")
	var economy = india.get_component("economy")

	var components_ok: bool = (
		government != null
		and economy != null
	)

	TestLogger.write_line(
		"India government/economy components available: "
		+ ("PASS" if components_ok else "FAIL")
	)

	all_passed = all_passed and components_ok
	if not components_ok:
		return false

	var original_government_state: Dictionary = government.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	# --------------------------------------------------------
	# CONTROLLED FIXTURE
	# --------------------------------------------------------

	var baseline_policy_id := "tax_incidence_policy_8_5"
	var replacement_policy_id := "tax_incidence_replacement_8_5"
	var zero_tax_policy_id := "tax_incidence_zero_8_5"

	var baseline_policy = GovernmentPolicyDefinition.new(
		baseline_policy_id,
		"economic",
		"tax_rate",
		0.25,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.25
		},
		{"source": "step_8_5_test"}
	)

	var replacement_policy = GovernmentPolicyDefinition.new(
		replacement_policy_id,
		"economic",
		"tax_rate",
		0.40,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.40
		},
		{"source": "step_8_5_test"}
	)

	var zero_tax_policy = GovernmentPolicyDefinition.new(
		zero_tax_policy_id,
		"economic",
		"tax_rate",
		0.0,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.0
		},
		{"source": "step_8_5_test"}
	)

	var definitions_registered: bool = (
		government.define_policy(baseline_policy)
		and government.define_policy(replacement_policy)
		and government.define_policy(zero_tax_policy)
	)

	TestLogger.write_line(
		"Controlled Step 8.5 policy definitions register: "
		+ ("PASS" if definitions_registered else "FAIL")
	)

	all_passed = all_passed and definitions_registered
	if not definitions_registered:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	# Gross labor-income fixture.
	economy.set_state("labor_income", 200.0)
	economy.set_state("average_wage", 20.0)
	economy.set_state("employed_labor_units", 10.0)
	economy.set_state("population_consumption_cost", 80.0)
	economy.set_state("consumption_price_index", 2.0)
	economy.set_state("tax_revenue_rate", 0.10)
	economy.set_state("government_revenue", 100.0)
	economy.set_state("treasury", 500.0)

	var original_labor_income: float = float(
		economy.get_state("labor_income", 0.0)
	)
	var original_government_revenue: float = float(
		economy.get_state("government_revenue", 0.0)
	)
	var original_treasury: float = float(
		economy.get_state("treasury", 0.0)
	)

	# --------------------------------------------------------
	# POLICY -> TAX RATE -> INCIDENCE
	# --------------------------------------------------------

	var activation_ok: bool = government.activate_policy(
		baseline_policy_id
	)

	TestLogger.write_line(
		"Controlled tax policy activation succeeds: "
		+ ("PASS" if activation_ok else "FAIL")
	)

	all_passed = all_passed and activation_ok
	if not activation_ok:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	effect_system.process_month(world)

	var tax_rate_after_effect: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)

	var effect_rate_ok: bool = is_equal_approx(
		tax_rate_after_effect,
		0.25
	)

	TestLogger.write_line(
		"Existing tax-rate effect reaches tax-incidence input: "
		+ ("PASS" if effect_rate_ok else "FAIL")
	)

	all_passed = all_passed and effect_rate_ok

	tax_system.process_month(world)

	var tax_amount: float = float(
		economy.get_state("labor_income_tax", 0.0)
	)
	var disposable_income: float = float(
		economy.get_state("disposable_labor_income", 0.0)
	)
	var real_disposable_income: float = float(
		economy.get_state("real_disposable_labor_income", 0.0)
	)
	var real_disposable_wage: float = float(
		economy.get_state("real_disposable_average_wage", 0.0)
	)
	var purchasing_power: float = float(
		economy.get_state("purchasing_power", 0.0)
	)
	var coverage_ratio: float = float(
		economy.get_state("income_coverage_ratio", 0.0)
	)

	var tax_amount_ok: bool = is_equal_approx(tax_amount, 50.0)
	TestLogger.write_line(
		"25% income tax produces exact labor-income tax: "
		+ ("PASS" if tax_amount_ok else "FAIL")
		+ " | expected=50.0 actual="
		+ str(tax_amount)
	)
	all_passed = all_passed and tax_amount_ok

	var disposable_ok: bool = is_equal_approx(disposable_income, 150.0)
	TestLogger.write_line(
		"Disposable labor income equals gross income minus tax: "
		+ ("PASS" if disposable_ok else "FAIL")
		+ " | expected=150.0 actual="
		+ str(disposable_income)
	)
	all_passed = all_passed and disposable_ok

	var real_income_ok: bool = is_equal_approx(real_disposable_income, 75.0)
	TestLogger.write_line(
		"Disposable real labor income uses existing price index: "
		+ ("PASS" if real_income_ok else "FAIL")
		+ " | expected=75.0 actual="
		+ str(real_disposable_income)
	)
	all_passed = all_passed and real_income_ok

	var purchasing_power_ok: bool = is_equal_approx(
		purchasing_power,
		7.5
	)
	TestLogger.write_line(
		"Post-tax real purchasing power is reduced through existing state: "
		+ ("PASS" if purchasing_power_ok else "FAIL")
		+ " | expected=7.5 actual="
		+ str(purchasing_power)
	)
	all_passed = all_passed and purchasing_power_ok

	var real_wage_ok: bool = is_equal_approx(
		real_disposable_wage,
		7.5
	)
	TestLogger.write_line(
		"Post-tax real average wage is derived: "
		+ ("PASS" if real_wage_ok else "FAIL")
	)
	all_passed = all_passed and real_wage_ok

	var coverage_ok: bool = is_equal_approx(
		coverage_ratio,
		1.875
	)
	TestLogger.write_line(
		"Disposable income coverage ratio uses post-tax income: "
		+ ("PASS" if coverage_ok else "FAIL")
		+ " | expected=1.875 actual="
		+ str(coverage_ratio)
	)
	all_passed = all_passed and coverage_ok

	var tax_ledger = economy.get_state(
		"tax_incidence_ledger",
		{}
	)
	var ledger_ok: bool = (
		tax_ledger is Dictionary
		and is_equal_approx(
			float(tax_ledger.get("labor_income_tax", 0.0)),
			50.0
		)
		and is_equal_approx(
			float(tax_ledger.get("disposable_labor_income", 0.0)),
			150.0
		)
	)

	TestLogger.write_line(
		"Tax incidence ledger records gross/tax/disposable flow: "
		+ ("PASS" if ledger_ok else "FAIL")
	)
	all_passed = all_passed and ledger_ok

	# Tax incidence must not rewrite the gross income owner or fiscal balance.
	var gross_unchanged: bool = is_equal_approx(
		float(economy.get_state("labor_income", 0.0)),
		original_labor_income
	)
	var revenue_unchanged: bool = is_equal_approx(
		float(economy.get_state("government_revenue", 0.0)),
		original_government_revenue
	)
	var treasury_unchanged: bool = is_equal_approx(
		float(economy.get_state("treasury", 0.0)),
		original_treasury
	)

	TestLogger.write_line(
		"Tax incidence preserves gross labor income: "
		+ ("PASS" if gross_unchanged else "FAIL")
	)
	TestLogger.write_line(
		"Tax incidence does not rewrite government revenue: "
		+ ("PASS" if revenue_unchanged else "FAIL")
	)
	TestLogger.write_line(
		"Tax incidence does not charge treasury: "
		+ ("PASS" if treasury_unchanged else "FAIL")
	)
	all_passed = all_passed and gross_unchanged and revenue_unchanged and treasury_unchanged

	# Idempotence.
	tax_system.process_month(world)
	var repeated_tax: float = float(
		economy.get_state("labor_income_tax", 0.0)
	)
	var repeated_disposable: float = float(
		economy.get_state("disposable_labor_income", 0.0)
	)
	var idempotent: bool = (
		is_equal_approx(repeated_tax, 50.0)
		and is_equal_approx(repeated_disposable, 150.0)
	)

	TestLogger.write_line(
		"Repeated tax-incidence processing does not double-tax income: "
		+ ("PASS" if idempotent else "FAIL")
	)
	all_passed = all_passed and idempotent

	# --------------------------------------------------------
	# POLICY REPLACEMENT
	# --------------------------------------------------------

	var replacement_ok: bool = government.activate_policy(
		replacement_policy_id
	)
	all_passed = all_passed and replacement_ok
	effect_system.process_month(world)
	tax_system.process_month(world)

	var replacement_tax: float = float(
		economy.get_state("labor_income_tax", 0.0)
	)
	var replacement_disposable: float = float(
		economy.get_state("disposable_labor_income", 0.0)
	)

	var replacement_values_ok: bool = (
		is_equal_approx(replacement_tax, 80.0)
		and is_equal_approx(replacement_disposable, 120.0)
	)

	TestLogger.write_line(
		"Replacing tax policy changes incidence deterministically: "
		+ ("PASS" if replacement_values_ok else "FAIL")
		+ " | tax=" + str(replacement_tax)
		+ " disposable=" + str(replacement_disposable)
	)
	all_passed = all_passed and replacement_values_ok

	# --------------------------------------------------------
	# ZERO-TAX RECOVERY / STALE-STATE CLEARING
	# --------------------------------------------------------

	var zero_tax_activation_ok: bool = government.activate_policy(
		zero_tax_policy_id
	)
	all_passed = all_passed and zero_tax_activation_ok
	effect_system.process_month(world)
	tax_system.process_month(world)

	var zero_tax: float = float(
		economy.get_state("labor_income_tax", 0.0)
	)
	var zero_tax_disposable: float = float(
		economy.get_state("disposable_labor_income", 0.0)
	)
	var zero_tax_power: float = float(
		economy.get_state("purchasing_power", 0.0)
	)

	var zero_tax_ok: bool = (
		is_equal_approx(zero_tax, 0.0)
		and is_equal_approx(zero_tax_disposable, 200.0)
		and is_equal_approx(zero_tax_power, 10.0)
	)

	TestLogger.write_line(
		"Removing tax restores disposable income and purchasing power: "
		+ ("PASS" if zero_tax_ok else "FAIL")
	)
	all_passed = all_passed and zero_tax_ok

	# --------------------------------------------------------
	# SNAPSHOT REPRESENTATION / DEEP COPY
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get(
		"india",
		{}
	)
	var snapshot_components = entity_snapshot.get(
		"components",
		{}
	)
	var snapshot_economy = snapshot_components.get(
		"economy",
		{}
	)
	var snapshot_state = snapshot_economy.get(
		"state",
		{}
	)

	var snapshot_has_tax_state: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("tax_incidence_ledger")
		and snapshot_state.has("disposable_labor_income")
	)

	TestLogger.write_line(
		"WorldSnapshot preserves tax-incidence state: "
		+ ("PASS" if snapshot_has_tax_state else "FAIL")
	)
	all_passed = all_passed and snapshot_has_tax_state

	if snapshot_state is Dictionary:
		snapshot_state["disposable_labor_income"] = -999.0

	var live_after_snapshot_mutation: float = float(
		economy.get_state("disposable_labor_income", 0.0)
	)
	var snapshot_isolated: bool = (
		is_equal_approx(live_after_snapshot_mutation, 200.0)
	)

	TestLogger.write_line(
		"WorldSnapshot tax-incidence state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = original_government_state
	economy.state = original_economy_state

	# Direct deep equality is the authoritative restoration check.
	var restored: bool = (
		economy.state == original_economy_state
		and government.state == original_government_state
	)

	TestLogger.write_line(
		"Step 8.5 government/economy state restoration: "
		+ ("PASS" if restored else "FAIL")
	)
	all_passed = all_passed and restored

	# --------------------------------------------------------
	# THREE-COUNTRY STRUCTURAL CHECK
	# --------------------------------------------------------

	var countries_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null:
			countries_ok = false
			break
		if entity.get_component("economy") == null:
			countries_ok = false
			break
		if entity.get_component("government") == null:
			countries_ok = false
			break

	TestLogger.write_line(
		"Three-country world remains structurally clean: "
		+ ("PASS" if countries_ok else "FAIL")
	)
	all_passed = all_passed and countries_ok

	TestLogger.write_line(
		"Tax Incidence 8.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
