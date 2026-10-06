class_name GovernmentSpendingAllocationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT SPENDING ALLOCATION TEST"
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

	var allocation_system_instance = simulation.get_system(
		"government_spending_allocation_system"
	)

	var allocation_system_ok: bool = (
		allocation_system_instance != null
		and allocation_system_instance is GovernmentSpendingAllocationSystem
	)

	TestLogger.write_line(
		"Registered GovernmentSpendingAllocationSystem available: "
		+ ("PASS" if allocation_system_ok else "FAIL")
	)

	all_passed = all_passed and allocation_system_ok
	if not allocation_system_ok:
		return false

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

	var allocation_system: GovernmentSpendingAllocationSystem = (
		allocation_system_instance as GovernmentSpendingAllocationSystem
	)
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

	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)
	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)

	var allocation_policy_id := (
		"government_spending_allocation_8_6"
	)
	var replacement_policy_id := (
		"government_spending_replacement_8_6"
	)

	var allocation_policy = GovernmentPolicyDefinition.new(
		allocation_policy_id,
		"fiscal",
		"government_spending_allocation",
		1.0,
		{},
		12,
		{
			"government.spending.infrastructure_share": 0.30,
			"government.spending.military_share": 0.20,
			"government.spending.public_services_share": 0.30,
			"government.spending.administration_share": 0.20
		},
		{"source": "step_8_6_test"}
	)

	var replacement_policy = GovernmentPolicyDefinition.new(
		replacement_policy_id,
		"fiscal",
		"government_spending_allocation",
		1.0,
		{},
		12,
		{
			"government.spending.infrastructure_share": 0.25,
			"government.spending.military_share": 0.25,
			"government.spending.public_services_share": 0.25,
			"government.spending.administration_share": 0.25
		},
		{"source": "step_8_6_test"}
	)

	var definitions_registered: bool = (
		government.define_policy(allocation_policy)
		and government.define_policy(replacement_policy)
	)

	TestLogger.write_line(
		"Controlled Step 8.6 allocation policies register: "
		+ ("PASS" if definitions_registered else "FAIL")
	)

	all_passed = all_passed and definitions_registered
	if not definitions_registered:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	economy.set_state(
		"government_spending",
		100.0
	)
	economy.set_state(
		"treasury",
		500.0
	)
	economy.set_state(
		"government_debt",
		200.0
	)
	economy.set_state(
		"government_revenue",
		150.0
	)

	var original_treasury: float = float(
		economy.get_state("treasury", 0.0)
	)
	var original_debt: float = float(
		economy.get_state("government_debt", 0.0)
	)
	var original_revenue: float = float(
		economy.get_state("government_revenue", 0.0)
	)

	var activation_ok: bool = government.activate_policy(
		allocation_policy_id
	)

	TestLogger.write_line(
		"Controlled spending-allocation policy activation succeeds: "
		+ ("PASS" if activation_ok else "FAIL")
	)

	all_passed = all_passed and activation_ok
	if not activation_ok:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	effect_system.process_month(world)

	var shares = government.get_state(
		"government_spending_allocation_shares",
		{}
	)

	var shares_ok: bool = (
		shares is Dictionary
		and is_equal_approx(
			float(shares.get("infrastructure", 0.0)),
			0.30
		)
		and is_equal_approx(
			float(shares.get("military", 0.0)),
			0.20
		)
		and is_equal_approx(
			float(shares.get("public_services", 0.0)),
			0.30
		)
		and is_equal_approx(
			float(shares.get("administration", 0.0)),
			0.20
		)
	)

	TestLogger.write_line(
		"Policy effects set the four spending shares: "
		+ ("PASS" if shares_ok else "FAIL")
	)

	all_passed = all_passed and shares_ok

	allocation_system.process_month(world)

	var allocations = government.get_state(
		"government_spending_allocation",
		{}
	)

	var allocation_total: float = float(
		government.get_state(
			"government_spending_allocation_total",
			0.0
		)
	)

	var amounts_ok: bool = (
		allocations is Dictionary
		and is_equal_approx(
			float(allocations.get("infrastructure", 0.0)),
			30.0
		)
		and is_equal_approx(
			float(allocations.get("military", 0.0)),
			20.0
		)
		and is_equal_approx(
			float(allocations.get("public_services", 0.0)),
			30.0
		)
		and is_equal_approx(
			float(allocations.get("administration", 0.0)),
			20.0
		)
		and is_equal_approx(
			allocation_total,
			100.0
		)
	)

	TestLogger.write_line(
		"Government spending is allocated exactly across categories: "
		+ ("PASS" if amounts_ok else "FAIL")
	)

	all_passed = all_passed and amounts_ok

	var allocation_reconciles: bool = (
		is_equal_approx(
			float(allocations.get("infrastructure", 0.0))
			+ float(allocations.get("military", 0.0))
			+ float(allocations.get("public_services", 0.0))
			+ float(allocations.get("administration", 0.0)),
			100.0
		)
	)

	TestLogger.write_line(
		"Allocated categories reconcile exactly to total spending: "
		+ ("PASS" if allocation_reconciles else "FAIL")
	)

	all_passed = all_passed and allocation_reconciles

	var treasury_unchanged: bool = is_equal_approx(
		float(economy.get_state("treasury", 0.0)),
		original_treasury
	)
	var debt_unchanged: bool = is_equal_approx(
		float(economy.get_state("government_debt", 0.0)),
		original_debt
	)
	var revenue_unchanged: bool = is_equal_approx(
		float(economy.get_state("government_revenue", 0.0)),
		original_revenue
	)

	TestLogger.write_line(
		"Spending allocation does not charge treasury: "
		+ ("PASS" if treasury_unchanged else "FAIL")
	)
	TestLogger.write_line(
		"Spending allocation does not rewrite government debt: "
		+ ("PASS" if debt_unchanged else "FAIL")
	)
	TestLogger.write_line(
		"Spending allocation does not rewrite government revenue: "
		+ ("PASS" if revenue_unchanged else "FAIL")
	)

	all_passed = (
		all_passed
		and treasury_unchanged
		and debt_unchanged
		and revenue_unchanged
	)

	var revision_before_repeat: int = int(
		government.get_state(
			"government_spending_allocation_revision",
			0
		)
	)

	allocation_system.process_month(world)

	var revision_after_repeat: int = int(
		government.get_state(
			"government_spending_allocation_revision",
			0
		)
	)

	var repeated_allocations = government.get_state(
		"government_spending_allocation",
		{}
	)

	var idempotent: bool = (
		revision_after_repeat == revision_before_repeat
		and repeated_allocations == allocations
	)

	TestLogger.write_line(
		"Repeated spending-allocation processing is idempotent: "
		+ ("PASS" if idempotent else "FAIL")
	)

	all_passed = all_passed and idempotent

	# --------------------------------------------------------
	# POLICY REPLACEMENT
	# --------------------------------------------------------

	var replacement_activation_ok: bool = government.activate_policy(
		replacement_policy_id
	)

	effect_system.process_month(world)
	allocation_system.process_month(world)

	var replacement_allocations = government.get_state(
		"government_spending_allocation",
		{}
	)

	var replacement_ok: bool = (
		replacement_activation_ok
		and is_equal_approx(
			float(replacement_allocations.get("infrastructure", 0.0)),
			25.0
		)
		and is_equal_approx(
			float(replacement_allocations.get("military", 0.0)),
			25.0
		)
		and is_equal_approx(
			float(replacement_allocations.get("public_services", 0.0)),
			25.0
		)
		and is_equal_approx(
			float(replacement_allocations.get("administration", 0.0)),
			25.0
		)
	)

	TestLogger.write_line(
		"Replacing allocation policy changes category amounts deterministically: "
		+ ("PASS" if replacement_ok else "FAIL")
	)

	all_passed = all_passed and replacement_ok

	# --------------------------------------------------------
	# INVALID SHARE SUM
	# --------------------------------------------------------

	var pre_invalid_allocation: Dictionary = (
		government.get_state(
			"government_spending_allocation",
			{}
		).duplicate(true)
	)

	government.set_state(
		"government_spending_allocation_shares",
		{
			"infrastructure": 0.40,
			"military": 0.30,
			"public_services": 0.20,
			"administration": 0.20
		}
	)

	allocation_system.process_month(world)

	var post_invalid_allocation: Dictionary = (
		government.get_state(
			"government_spending_allocation",
			{}
		).duplicate(true)
	)

	var invalid_rejected_without_mutation: bool = (
		post_invalid_allocation == pre_invalid_allocation
	)

	TestLogger.write_line(
		"Invalid share total is rejected without mutating allocation amounts: "
		+ ("PASS" if invalid_rejected_without_mutation else "FAIL")
	)

	all_passed = all_passed and invalid_rejected_without_mutation

	# Restore valid shares for downstream checks.
	government.set_state(
		"government_spending_allocation_shares",
		{
			"infrastructure": 0.25,
			"military": 0.25,
			"public_services": 0.25,
			"administration": 0.25
		}
	)
	allocation_system.process_month(world)

	# --------------------------------------------------------
	# ZERO SPENDING SAFETY
	# --------------------------------------------------------

	economy.set_state(
		"government_spending",
		0.0
	)

	allocation_system.process_month(world)

	var zero_allocations = government.get_state(
		"government_spending_allocation",
		{}
	)

	var zero_safe: bool = (
		is_equal_approx(
			float(zero_allocations.get("infrastructure", 0.0)),
			0.0
		)
		and is_equal_approx(
			float(zero_allocations.get("military", 0.0)),
			0.0
		)
		and is_equal_approx(
			float(zero_allocations.get("public_services", 0.0)),
			0.0
		)
		and is_equal_approx(
			float(zero_allocations.get("administration", 0.0)),
			0.0
		)
	)

	TestLogger.write_line(
		"Zero government spending produces zero category allocations safely: "
		+ ("PASS" if zero_safe else "FAIL")
	)

	all_passed = all_passed and zero_safe

	# Restore positive spending before snapshot.
	economy.set_state(
		"government_spending",
		100.0
	)
	allocation_system.process_month(world)

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

	var snapshot_government = snapshot_components.get(
		"government",
		{}
	)

	var snapshot_state = snapshot_government.get(
		"state",
		{}
	)

	var snapshot_has_allocation_state: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has(
			"government_spending_allocation"
		)
		and snapshot_state.has(
			"government_spending_allocation_shares"
		)
		and snapshot_state.has(
			"government_spending_allocation_ledger"
		)
	)

	TestLogger.write_line(
		"WorldSnapshot preserves spending-allocation state: "
		+ ("PASS" if snapshot_has_allocation_state else "FAIL")
	)

	all_passed = all_passed and snapshot_has_allocation_state

	if snapshot_state is Dictionary:
		var snapshot_allocations = snapshot_state.get(
			"government_spending_allocation",
			{}
		)

		if snapshot_allocations is Dictionary:
			snapshot_allocations["infrastructure"] = -999.0
			snapshot_state["government_spending_allocation"] = (
				snapshot_allocations
			)

	var live_infrastructure: float = float(
		government.get_state(
			"government_spending_allocation",
			{}
		).get(
			"infrastructure",
			0.0
		)
	)

	var snapshot_isolated: bool = (
		live_infrastructure >= 0.0
	)

	TestLogger.write_line(
		"WorldSnapshot spending-allocation state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)

	all_passed = all_passed and snapshot_isolated

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = original_government_state
	economy.state = original_economy_state

	var restored: bool = (
		government.state == original_government_state
		and economy.state == original_economy_state
	)

	TestLogger.write_line(
		"Step 8.6 government/economy state restoration: "
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
		"Government Spending Allocation 8.6 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
