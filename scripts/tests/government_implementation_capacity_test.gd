class_name GovernmentImplementationCapacityTest
extends RefCounted


# ============================================================
# GOVERNMENT — STEP 8.9 TEST
# ============================================================
# Validates the smallest implementation-capacity bridge:
# - explicit government implementation-capacity state
# - registered implementation-capacity system
# - opt-in policy effect scaling
# - intended effect -> actual effect
# - zero / half / full capacity behavior
# - replacement of policy effect remains deterministic
# - repeated processing is idempotent
# - no unintended mutation for non-opt-in policies
# - WorldSnapshot representation and deep-copy isolation
# - government state restoration
# - three-country structural integrity
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
	) -> bool:

	TestLogger.section(
        "GOVERNMENT IMPLEMENTATION CAPACITY TEST"
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

	var implementation_system_instance = simulation.get_system(
        "government_implementation_capacity_system"
	)
	var effect_system_instance = simulation.get_system(
        "government_policy_effect_system"
	)

	var implementation_system_ok: bool = (
		implementation_system_instance != null
		and implementation_system_instance is GovernmentImplementationCapacitySystem
	)
	var effect_system_ok: bool = (
		effect_system_instance != null
		and effect_system_instance is GovernmentPolicyEffectSystem
	)

	TestLogger.write_line(
        "Registered GovernmentImplementationCapacitySystem available: "
		+ ("PASS" if implementation_system_ok else "FAIL")
	)
	TestLogger.write_line(
        "Registered GovernmentPolicyEffectSystem available: "
		+ ("PASS" if effect_system_ok else "FAIL")
	)

	all_passed = all_passed and implementation_system_ok and effect_system_ok

	if not implementation_system_ok or not effect_system_ok:
		return false

	var implementation_system: GovernmentImplementationCapacitySystem = (
		implementation_system_instance as GovernmentImplementationCapacitySystem
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
	var components_ok: bool = government != null and economy != null
	TestLogger.write_line(
        "India government/economy components available: "
		+ ("PASS" if components_ok else "FAIL")
	)
	all_passed = all_passed and components_ok
	if not components_ok:
		return false

	var original_government_state: Dictionary = government.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	# Ensure a known baseline for this isolated test.
	government.state = original_government_state.duplicate(true)
	economy.set_state("tax_revenue_rate", 0.10)
	government.set_implementation_capacity(0.50)

	var policy_id: String = "implementation_capacity_tax_8_9_test"
	var policy = GovernmentPolicyDefinition.new(
		policy_id,
		"fiscal",
		"tax_revenue_rate",
		0.30,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.30
		},
		{
			"implementation_capacity_enabled": true,
			"source": "step_8_9_test"
		}
	)

	var define_ok: bool = government.define_policy(policy)
	var activate_ok: bool = define_ok and government.activate_policy(policy_id)

	TestLogger.write_line(
        "Controlled Step 8.9 implementation-capacity policy registers and activates: "
		+ ("PASS" if activate_ok else "FAIL")
	)
	all_passed = all_passed and activate_ok

	implementation_system.process_month(world)

	var factor_state = government.get_policy_implementation_factors()
	var target_key: String = "fiscal::tax_revenue_rate"
	var factor_entry = factor_state.get(target_key, {})
	var factor_ok: bool = (
		factor_entry is Dictionary
		and factor_entry.get("enabled", false) == true
		and is_equal_approx(
			float(factor_entry.get("factor", -1.0)),
			0.50
		)
	)
	TestLogger.write_line(
        "Implementation-capacity factor resolves to 0.50: "
		+ ("PASS" if factor_ok else "FAIL")
	)
	all_passed = all_passed and factor_ok

	effect_system.process_month(world)

	var half_capacity_value: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)
	var half_capacity_ok: bool = is_equal_approx(
		half_capacity_value,
		0.20
	)
	TestLogger.write_line(
        "Intended effect 0.30 with 0.50 capacity produces actual 0.20 from 0.10 baseline: "
		+ ("PASS" if half_capacity_ok else "FAIL")
		+ " | actual="
		+ str(half_capacity_value)
	)
	all_passed = all_passed and half_capacity_ok

	var effect_result = government.get_policy_effect_last_result()
	var recorded_actual_ok: bool = false
	var changes_value = effect_result.get("changes", []) if effect_result is Dictionary else []
	if changes_value is Array:
		for change in changes_value:
			if change is Dictionary and str(change.get("effect_key", "")) == "economy.tax_revenue_rate":
				recorded_actual_ok = (
					is_equal_approx(float(change.get("intended_value", -1.0)), 0.30)
					and is_equal_approx(float(change.get("implementation_capacity_factor", -1.0)), 0.50)
					and is_equal_approx(float(change.get("actual_value", -1.0)), 0.20)
				)
				break

	TestLogger.write_line(
        "Policy effect result records intended, capacity and actual effect: "
		+ ("PASS" if recorded_actual_ok else "FAIL")
	)
	all_passed = all_passed and recorded_actual_ok

	var revision_before_repeat: int = int(
		government.get_state(
			"policy_effect_revision",
			0
		)
	)
	effect_system.process_month(world)
	var repeated_value: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)
	var repeated_revision: int = int(
		government.get_state(
			"policy_effect_revision",
			0
		)
	)
	var idempotent_ok: bool = (
		is_equal_approx(repeated_value, 0.20)
		and repeated_revision == revision_before_repeat
	)
	TestLogger.write_line(
        "Repeated implementation-capacity processing is idempotent: "
		+ ("PASS" if idempotent_ok else "FAIL")
	)
	all_passed = all_passed and idempotent_ok

	government.set_implementation_capacity(0.0)
	implementation_system.process_month(world)
	effect_system.process_month(world)
	var zero_capacity_value: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)
	var zero_capacity_ok: bool = is_equal_approx(
		zero_capacity_value,
		0.10
	)
	TestLogger.write_line(
        "Zero implementation capacity produces baseline actual effect: "
		+ ("PASS" if zero_capacity_ok else "FAIL")
		+ " | actual="
		+ str(zero_capacity_value)
	)
	all_passed = all_passed and zero_capacity_ok

	government.set_implementation_capacity(1.0)
	implementation_system.process_month(world)
	effect_system.process_month(world)
	var full_capacity_value: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)
	var full_capacity_ok: bool = is_equal_approx(
		full_capacity_value,
		0.30
	)
	TestLogger.write_line(
        "Full implementation capacity produces full intended effect: "
		+ ("PASS" if full_capacity_ok else "FAIL")
		+ " | actual="
		+ str(full_capacity_value)
	)
	all_passed = all_passed and full_capacity_ok

	var no_capacity_policy = GovernmentPolicyDefinition.new(
		"implementation_capacity_disabled_8_9_test",
		"fiscal",
		"tax_revenue_rate",
		0.25,
		{},
		12,
		{
			"economy.tax_revenue_rate": 0.25
		},
		{
			"implementation_capacity_enabled": false,
			"source": "step_8_9_test"
		}
	)

	var disabled_define_ok: bool = government.define_policy(no_capacity_policy)
	var disabled_activate_ok: bool = disabled_define_ok and government.activate_policy(
        "implementation_capacity_disabled_8_9_test"
	)

	government.set_implementation_capacity(0.25)
	implementation_system.process_month(world)
	effect_system.process_month(world)

	var disabled_value: float = float(
		economy.get_state("tax_revenue_rate", 0.0)
	)
	var disabled_ok: bool = (
		disabled_activate_ok
		and is_equal_approx(disabled_value, 0.25)
	)
	TestLogger.write_line(
        "Non-opt-in policy retains full intended effect: "
		+ ("PASS" if disabled_ok else "FAIL")
		+ " | actual="
		+ str(disabled_value)
	)
	all_passed = all_passed and disabled_ok

	var implementation_revision: int = int(
		government.get_state(
			"implementation_capacity_revision",
			0
		)
	)
	var implementation_ledger = government.get_implementation_capacity_ledger()
	var implementation_result = government.get_implementation_capacity_last_result()
	var audit_ok: bool = (
		implementation_revision >= 1
		and implementation_ledger is Dictionary
		and implementation_result is Dictionary
		and implementation_result.has("action")
	)
	TestLogger.write_line(
        "Implementation-capacity ledger and last-result state are explicit: "
		+ ("PASS" if audit_ok else "FAIL")
	)
	all_passed = all_passed and audit_ok

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get("india", {})
	var snapshot_components = entity_snapshot.get("components", {})
	var snapshot_government = snapshot_components.get("government", {})
	var snapshot_state = snapshot_government.get("state", {})

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("implementation_capacity")
		and snapshot_state.has("implementation_capacity_ledger")
		and snapshot_state.has("policy_implementation_factors")
	)
	TestLogger.write_line(
        "WorldSnapshot preserves implementation-capacity state: "
		+ ("PASS" if snapshot_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_ok

	var live_capacity: float = government.get_implementation_capacity()
	if snapshot_state is Dictionary:
		snapshot_state["implementation_capacity"] = -999.0

	var snapshot_isolated_ok: bool = is_equal_approx(
		government.get_implementation_capacity(),
		live_capacity
	)
	TestLogger.write_line(
        "WorldSnapshot implementation-capacity state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated_ok

	government.state = original_government_state
	economy.state = original_economy_state

	var restored_ok: bool = (
		government.state == original_government_state
		and economy.state == original_economy_state
	)
	TestLogger.write_line(
        "Step 8.9 government/economy state restoration: "
		+ ("PASS" if restored_ok else "FAIL")
	)
	all_passed = all_passed and restored_ok

	var countries_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null:
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
        "Government Implementation Capacity 8.9 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
