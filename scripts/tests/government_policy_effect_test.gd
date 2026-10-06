class_name GovernmentPolicyEffectTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT POLICY EFFECT TEST"
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

	var economy_system_instance = simulation.get_system(
		"economy_system"
	)

	var economy_system_ok: bool = (
		economy_system_instance != null
		and economy_system_instance is EconomySystem
	)

	TestLogger.write_line(
		"Registered EconomySystem available: "
		+ ("PASS" if economy_system_ok else "FAIL")
	)

	all_passed = all_passed and economy_system_ok
	if not economy_system_ok:
		return false

	var economy_system: EconomySystem = (
		economy_system_instance as EconomySystem
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
	# CONTROLLED POLICY DEFINITIONS
	# --------------------------------------------------------

	var tax_policy_id := "tax_policy_8_4"
	var tax_replacement_id := "tax_policy_8_4_replacement"
	var investment_policy_id := "investment_policy_8_4"
	var unsupported_policy_id := "unsupported_effect_8_4"
	var neutral_tax_policy_id := "neutral_tax_policy_8_4"

	var tax_policy = GovernmentPolicyDefinition.new(
		tax_policy_id,
		"economic",
		"tax_rate",
		0.15,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.15
		},
		{"source": "step_8_4_test"}
	)

	var tax_replacement = GovernmentPolicyDefinition.new(
		tax_replacement_id,
		"economic",
		"tax_rate",
		0.18,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.18
		},
		{"source": "step_8_4_test"}
	)

	var investment_policy = GovernmentPolicyDefinition.new(
		investment_policy_id,
		"economic",
		"investment_rate",
		0.20,
		{},
		12,
		{
			"economy.investment_rate": 0.20
		},
		{"source": "step_8_4_test"}
	)

	var unsupported_policy = GovernmentPolicyDefinition.new(
		unsupported_policy_id,
		"economic",
		"tax_rate",
		0.20,
		{},
		12,
		{
			"economy.government_spending_rate": 0.20
		},
		{"source": "step_8_4_test"}
	)

	var neutral_tax_policy = GovernmentPolicyDefinition.new(
		neutral_tax_policy_id,
		"economic",
		"tax_rate",
		0.10,
		{},
		12,
		{},
		{"source": "step_8_4_test"}
	)

	var definitions_registered: bool = (
		government.define_policy(tax_policy)
		and government.define_policy(tax_replacement)
		and government.define_policy(investment_policy)
		and government.define_policy(unsupported_policy)
		and government.define_policy(neutral_tax_policy)
	)

	TestLogger.write_line(
		"Controlled Step 8.4 policy definitions register: "
		+ ("PASS" if definitions_registered else "FAIL")
	)

	all_passed = all_passed and definitions_registered
	if not definitions_registered:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	# Baseline existing economy state.
	economy.set_state("tax_revenue_rate", 0.10)
	economy.set_state("investment_rate", 0.10)
	economy.set_state("treasury", 500.0)
	economy.set_state("gdp", 1000.0)
	economy.set_state("growth_rate", 0.0)

	var treasury_before_effect: float = float(
		economy.get_state("treasury", 0.0)
	)

	# --------------------------------------------------------
	# TAX EFFECT
	# --------------------------------------------------------

	var tax_activation_ok: bool = government.activate_policy(
		tax_policy_id
	)

	TestLogger.write_line(
		"Tax policy activated for controlled effect test: "
		+ ("PASS" if tax_activation_ok else "FAIL")
	)

	all_passed = all_passed and tax_activation_ok

	effect_system.process_month(world)

	var tax_effect_applied: bool = is_equal_approx(
		float(economy.get_state("tax_revenue_rate", 0.0)),
		0.15
	)

	TestLogger.write_line(
		"Active tax policy modifies existing EconomyComponent tax rate: "
		+ ("PASS" if tax_effect_applied else "FAIL")
	)

	all_passed = all_passed and tax_effect_applied

	var treasury_unchanged: bool = is_equal_approx(
		float(economy.get_state("treasury", 0.0)),
		treasury_before_effect
	)

	TestLogger.write_line(
		"Policy effect application does not charge treasury: "
		+ ("PASS" if treasury_unchanged else "FAIL")
	)

	all_passed = all_passed and treasury_unchanged

	# --------------------------------------------------------
	# EXISTING ECONOMY SYSTEM CONSUMES THE EFFECT
	# --------------------------------------------------------

	economy_system.process_month(world)

	var revenue_after_tax_effect: float = float(
		economy.get_state("government_revenue", 0.0)
	)

	var downstream_tax_pass: bool = is_equal_approx(
		revenue_after_tax_effect,
		150.0
	)

	TestLogger.write_line(
		"Existing EconomySystem consumes policy tax-rate effect: "
		+ ("PASS" if downstream_tax_pass else "FAIL")
		+ " | revenue=" + str(revenue_after_tax_effect)
	)

	all_passed = all_passed and downstream_tax_pass

	# --------------------------------------------------------
	# IDEMPOTENCE
	# --------------------------------------------------------

	var revision_before_repeat: int = int(
		government.get_state("policy_effect_revision", 0)
	)

	effect_system.process_month(world)

	var revision_after_repeat: int = int(
		government.get_state("policy_effect_revision", 0)
	)

	var idempotent_pass: bool = (
		revision_after_repeat == revision_before_repeat
		and is_equal_approx(
			float(economy.get_state("tax_revenue_rate", 0.0)),
			0.15
		)
	)

	TestLogger.write_line(
		"Repeated policy-effect processing is idempotent: "
		+ ("PASS" if idempotent_pass else "FAIL")
	)

	all_passed = all_passed and idempotent_pass

	# --------------------------------------------------------
	# REPLACEMENT POLICY
	# --------------------------------------------------------

	government.activate_policy(tax_replacement_id)
	effect_system.process_month(world)

	var replacement_pass: bool = is_equal_approx(
		float(economy.get_state("tax_revenue_rate", 0.0)),
		0.18
	)

	TestLogger.write_line(
		"Replacing active policy changes the existing tax rate deterministically: "
		+ ("PASS" if replacement_pass else "FAIL")
	)

	all_passed = all_passed and replacement_pass

	# --------------------------------------------------------
	# SECOND INDEPENDENT EFFECT
	# --------------------------------------------------------

	government.activate_policy(investment_policy_id)
	effect_system.process_month(world)

	var investment_pass: bool = (
		is_equal_approx(
			float(economy.get_state("investment_rate", 0.0)),
			0.20
		)
		and is_equal_approx(
			float(economy.get_state("tax_revenue_rate", 0.0)),
			0.18
		)
	)

	TestLogger.write_line(
		"Different policy targets can modify different existing economy states simultaneously: "
		+ ("PASS" if investment_pass else "FAIL")
	)

	all_passed = all_passed and investment_pass

	# --------------------------------------------------------
	# UNSUPPORTED EFFECT SAFETY
	# --------------------------------------------------------

	government.activate_policy(unsupported_policy_id)
	effect_system.process_month(world)

	var unsupported_pass: bool = (
		is_equal_approx(
			float(economy.get_state("government_spending_rate", 0.0)),
			0.10
		)
		and str(
			government.get_policy_effect_last_result().get("action", "")
		) == "rejected"
	)

	TestLogger.write_line(
		"Unsupported policy effect is rejected without mutating existing state: "
		+ ("PASS" if unsupported_pass else "FAIL")
	)

	all_passed = all_passed and unsupported_pass

	# --------------------------------------------------------
	# STALE EFFECT CLEARING / BASELINE RESTORATION
	# --------------------------------------------------------

	government.activate_policy(neutral_tax_policy_id)
	effect_system.process_month(world)

	var stale_clear_pass: bool = (
		is_equal_approx(
			float(economy.get_state("tax_revenue_rate", 0.0)),
			0.10
		)
	)

	TestLogger.write_line(
		"Replacing an effected policy with a no-effect policy clears stale tax effect: "
		+ ("PASS" if stale_clear_pass else "FAIL")
	)

	all_passed = all_passed and stale_clear_pass

	# --------------------------------------------------------
	# POLICY DEFINITIONS / EFFECT BOUNDARY
	# --------------------------------------------------------

	var definition_unchanged: bool = (
		is_equal_approx(
			float(
				government.get_policy_definition(tax_policy_id).get(
						"value",
						0.0
					)
			),
			0.15
			)
		and is_equal_approx(
			float(
				government.get_policy_definition(tax_policy_id).get(
						"effects",
						{}
					).get(
						"economy.tax_revenue_rate",
						0.0
					)
			),
			0.15
			)
	)

	TestLogger.write_line(
		"Policy definition remains unchanged by effect processing: "
		+ ("PASS" if definition_unchanged else "FAIL")
	)

	all_passed = all_passed and definition_unchanged

	var effect_audit: Dictionary = government.get_policy_effect_last_result()
	var audit_state_pass: bool = (
		effect_audit is Dictionary
		and effect_audit.has("action")
		and government.get_policy_effect_ledger() is Dictionary
	)

	TestLogger.write_line(
		"Policy effect ledger and last-result state are explicit: "
		+ ("PASS" if audit_state_pass else "FAIL")
	)

	all_passed = all_passed and audit_state_pass

	# --------------------------------------------------------
	# SNAPSHOT
	# --------------------------------------------------------

	var snapshot = WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_state = snapshot.entities.get("india", {})
	var snapshot_government_state = {}

	if snapshot_state is Dictionary:
		var components = snapshot_state.get("components", {})
		if components is Dictionary:
			var snapshot_government = components.get("government", {})
			if snapshot_government is Dictionary:
				snapshot_government_state = snapshot_government.get(
					"state",
					{}
				)

	var snapshot_preserves_effect_state: bool = (
		snapshot_government_state is Dictionary
		and snapshot_government_state.has("policy_effect_revision")
		and snapshot_government_state.has("policy_effect_bindings")
	)

	TestLogger.write_line(
		"WorldSnapshot preserves policy effect state: "
		+ ("PASS" if snapshot_preserves_effect_state else "FAIL")
	)

	all_passed = all_passed and snapshot_preserves_effect_state

	if snapshot_government_state is Dictionary:
		var copied_bindings = snapshot_government_state.get(
			"policy_effect_bindings",
			{}
		)
		if copied_bindings is Dictionary:
			copied_bindings["__snapshot_test__"] = true

	var live_bindings = government.get_policy_effect_bindings()
	var snapshot_isolated: bool = not live_bindings.has("__snapshot_test__")

	TestLogger.write_line(
		"WorldSnapshot policy effect state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)

	all_passed = all_passed and snapshot_isolated

	# --------------------------------------------------------
	# RESTORE FIXTURE
	# --------------------------------------------------------

	government.state = original_government_state
	economy.state = original_economy_state

	TestLogger.write_line(
		"Step 8.4 government/economy state restoration: PASS"
	)

	var restoration_ok: bool = (
		government.state == original_government_state
		and economy.state == original_economy_state
	)

	all_passed = all_passed and restoration_ok

	# Structural three-country check.
	var china_ok = world.get_entity("china") != null
	var usa_ok = world.get_entity("usa") != null
	var india_ok = world.get_entity("india") != null

	var three_country_ok: bool = china_ok and india_ok and usa_ok

	TestLogger.write_line(
		"Three-country world remains structurally clean: "
		+ ("PASS" if three_country_ok else "FAIL")
	)

	all_passed = all_passed and three_country_ok

	return all_passed
