class_name GovernmentPolicyActivationTest
extends RefCounted


# ============================================================
# GOVERNMENT — STEP 8.2 TEST
# ============================================================
#
# Validates the smallest government policy activation/change
# mechanism built on the Step 8.1 policy-definition state.
#
# Step 8.2 intentionally does NOT:
# - charge policy costs
# - apply policy effects
# - modify economy / military / trade / population state
# - implement policy duration progression
# - simulate parliament, parties, elections, ministries, or
#   constitutional mechanics
#
# Activation means:
#
# Government defines policies
#       -> activates one definition as the current policy
#       -> activating another definition for the same category/target
#          changes the current policy
#
# Different category/target pairs may be active simultaneously.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT POLICY ACTIVATION / CHANGE TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation available: PASS"
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

	var government = india.get_component(
		"government"
	)

	if government == null:
		TestLogger.write_line(
			"India government component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India government component: PASS"
	)

	var original_state: Dictionary = (
		government.state.duplicate(true)
	)

	# --------------------------------------------------------
	# CONTROLLED DEFINITIONS
	# --------------------------------------------------------

	var policy_a_id: String = (
		"industrial_subsidy_8_2_a"
	)

	var policy_b_id: String = (
		"industrial_subsidy_8_2_b"
	)

	var policy_c_id: String = (
		"military_posture_8_2"
	)

	var policy_a = GovernmentPolicyDefinition.new(
		policy_a_id,
		"industrial",
		"steel_production",
		0.05,
		{
			"treasury": 10.0
		},
		12,
		{
			"production_multiplier": 1.05
		},
		{
			"source": "step_8_2_test"
		}
	)

	var policy_b = GovernmentPolicyDefinition.new(
		policy_b_id,
		"industrial",
		"steel_production",
		0.10,
		{
			"treasury": 20.0
		},
		24,
		{
			"production_multiplier": 1.10
		},
		{
			"source": "step_8_2_test"
		}
	)

	var policy_c = GovernmentPolicyDefinition.new(
		policy_c_id,
		"military",
		"posture",
		0.30,
		{
			"treasury": 15.0
		},
		6,
		{
			"readiness_multiplier": 1.10
		},
		{
			"source": "step_8_2_test"
		}
	)

	var definitions_registered: bool = (
		government.define_policy(policy_a)
		and government.define_policy(policy_b)
		and government.define_policy(policy_c)
	)

	TestLogger.write_line(
		"Controlled Step 8.2 policy definitions register: "
		+ (
			"PASS"
			if definitions_registered
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and definitions_registered
	)

	# --------------------------------------------------------
	# INITIAL STATE
	# --------------------------------------------------------

	var initial_active: Dictionary = government.get_active_policies()

	var initial_active_pass: bool = (
		initial_active.is_empty()
	)

	TestLogger.write_line(
		"No policy is active before explicit activation: "
		+ (
			"PASS"
			if initial_active_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and initial_active_pass
	)

	# --------------------------------------------------------
	# ACTIVATE FIRST POLICY
	# --------------------------------------------------------

	var activate_a_pass: bool = (
		government.activate_policy(policy_a_id)
		and government.is_policy_active(policy_a_id)
	)

	TestLogger.write_line(
		"Explicit policy activation changes current policy state: "
		+ (
			"PASS"
			if activate_a_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and activate_a_pass
	)

	var target_key: String = (
		"industrial::steel_production"
	)

	var active_a: Dictionary = government.get_active_policy(
		target_key
	)

	var active_a_state_pass: bool = (
		str(
			active_a.get(
				"policy_id",
				""
			)
		) == policy_a_id
		and is_equal_approx(
			float(
				active_a.get(
					"value",
					0.0
				)
			),
			0.05
		)
		and int(
			active_a.get(
				"duration_months",
				0
			)
		) == 12
		and bool(
			active_a.get(
				"active",
				false
			)
		)
	)

	TestLogger.write_line(
		"Activated policy state preserves definition values: "
		+ (
			"PASS"
			if active_a_state_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and active_a_state_pass
	)

	var revision_after_a: int = int(
		government.get_state(
			"policy_activation_revision",
			0
		)
	)

	var activation_revision_pass: bool = (
		revision_after_a == 1
	)

	TestLogger.write_line(
		"First activation increments activation revision: "
		+ (
			"PASS"
			if activation_revision_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and activation_revision_pass
	)

	# --------------------------------------------------------
	# IDEMPOTENT RE-ACTIVATION
	# --------------------------------------------------------

	var reactivation_result: bool = government.activate_policy(
		policy_a_id
	)

	var reactivation_revision: int = int(
		government.get_state(
			"policy_activation_revision",
			0
		)
	)

	var idempotent_pass: bool = (
		reactivation_result
		and reactivation_revision == revision_after_a
	)

	TestLogger.write_line(
		"Re-activating the current policy is idempotent: "
		+ (
			"PASS"
			if idempotent_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and idempotent_pass
	)

	# --------------------------------------------------------
	# CHANGE CURRENT POLICY FOR SAME TARGET
	# --------------------------------------------------------

	var change_b_pass: bool = (
		government.activate_policy(policy_b_id)
		and government.is_policy_active(policy_b_id)
		and not government.is_policy_active(policy_a_id)
	)

	TestLogger.write_line(
		"Activating a new policy for the same target changes current policy: "
		+ (
			"PASS"
			if change_b_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and change_b_pass
	)

	var active_b: Dictionary = government.get_active_policy(
		target_key
	)

	var changed_state_pass: bool = (
		str(
			active_b.get(
				"policy_id",
				""
			)
		) == policy_b_id
		and is_equal_approx(
			float(
				active_b.get(
					"value",
					0.0
				)
			),
			0.10
		)
		and int(
			active_b.get(
				"duration_months",
				0
			)
		) == 24
	)

	TestLogger.write_line(
		"Changed policy state contains replacement definition values: "
		+ (
			"PASS"
			if changed_state_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and changed_state_pass
	)

	var revision_after_b: int = int(
		government.get_state(
			"policy_activation_revision",
			0
		)
	)

	var change_revision_pass: bool = (
		revision_after_b == 2
	)

	TestLogger.write_line(
		"Policy change increments activation revision once: "
		+ (
			"PASS"
			if change_revision_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and change_revision_pass
	)

	var ledger: Dictionary = government.get_state(
		"policy_activation_ledger",
		{}
	)

	var change_ledger_entry: Dictionary = ledger.get(
		"2",
		{}
	)

	var ledger_pass: bool = (
		str(
			change_ledger_entry.get(
				"action",
				""
			)
		) == "changed"
		and str(
			change_ledger_entry.get(
				"previous_policy_id",
				""
			)
		) == policy_a_id
		and str(
			change_ledger_entry.get(
				"policy_id",
				""
			)
		) == policy_b_id
	)

	TestLogger.write_line(
		"Policy change ledger records previous and new policy: "
		+ (
			"PASS"
			if ledger_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and ledger_pass
	)

	# --------------------------------------------------------
	# MULTIPLE TARGETS MAY COEXIST
	# --------------------------------------------------------

	var coexist_pass: bool = (
		government.activate_policy(policy_c_id)
		and government.is_policy_active(policy_b_id)
		and government.is_policy_active(policy_c_id)
		and government.get_active_policies().size() == 2
	)

	TestLogger.write_line(
		"Different policy targets can be active simultaneously: "
		+ (
			"PASS"
			if coexist_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and coexist_pass
	)

	# --------------------------------------------------------
	# UNKNOWN POLICY PROTECTION
	# --------------------------------------------------------

	var revision_before_unknown: int = int(
		government.get_state(
			"policy_activation_revision",
			0
		)
	)

	var unknown_result: bool = government.activate_policy(
		"unknown_policy_8_2"
	)

	var revision_after_unknown: int = int(
		government.get_state(
			"policy_activation_revision",
			0
		)
	)

	var unknown_policy_pass: bool = (
		not unknown_result
		and revision_before_unknown == revision_after_unknown
	)

	TestLogger.write_line(
		"Undefined policy cannot be activated: "
		+ (
			"PASS"
			if unknown_policy_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and unknown_policy_pass
	)

	# --------------------------------------------------------
	# DEFINITION STATE REMAINS UNCHANGED
	# --------------------------------------------------------

	var definition_a_after: Dictionary = government.get_policy_definition(
		policy_a_id
	)

	var definition_b_after: Dictionary = government.get_policy_definition(
		policy_b_id
	)

	var definitions_unchanged_pass: bool = (
		is_equal_approx(
			float(
				definition_a_after.get(
					"value",
					0.0
				)
			),
			0.05
		)
		and is_equal_approx(
			float(
				definition_b_after.get(
					"value",
					0.0
			)
			),
			0.10
		)
	)

	TestLogger.write_line(
		"Activation does not mutate policy definitions: "
		+ (
			"PASS"
			if definitions_unchanged_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and definitions_unchanged_pass
	)

	# --------------------------------------------------------
	# CORE GOVERNMENT STATE / COST / EFFECT BOUNDARY
	# --------------------------------------------------------

	var core_state_unchanged_pass: bool = (
		is_equal_approx(
			float(
				government.get_state(
					"stability",
					0.0
				)
			),
			float(
				original_state.get(
					"stability",
					0.0
				)
			)
		)
		and is_equal_approx(
			float(
				government.get_state(
					"approval",
					0.0
				)
			),
			float(
				original_state.get(
					"approval",
					0.0
				)
			)
		)
		and is_equal_approx(
			float(
				government.get_state(
					"political_pressure",
					0.0
				)
			),
			float(
				original_state.get(
					"political_pressure",
					0.0
				)
			)
		)
	)

	TestLogger.write_line(
		"Activation does not apply policy effects or political changes: "
		+ (
			"PASS"
			if core_state_unchanged_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and core_state_unchanged_pass
	)

	# --------------------------------------------------------
	# DEEP-COPY ISOLATION
	# --------------------------------------------------------

	var mutable_active: Dictionary = government.get_active_policies()

	if mutable_active.has(
		"military::posture"
	):
		mutable_active[
			"military::posture"
		]["value"] = 99.0

	var stored_c: Dictionary = government.get_active_policy(
		"military::posture"
	)

	var active_isolation_pass: bool = is_equal_approx(
		float(
			stored_c.get(
				"value",
				0.0
			)
		),
		0.30
	)

	TestLogger.write_line(
		"Active policy retrieval is deep-copy isolated: "
		+ (
			"PASS"
			if active_isolation_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and active_isolation_pass
	)

	# --------------------------------------------------------
	# SNAPSHOT REPRESENTATION
	# --------------------------------------------------------

	var snapshot = WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_isolated_ok: bool = false

	var india_snapshot: Dictionary = snapshot.entities.get(
		"india",
		{}
	)

	var component_snapshots: Dictionary = india_snapshot.get(
		"components",
		{}
	)

	var government_snapshot: Dictionary = component_snapshots.get(
		"government",
		{}
	)

	var snapshot_state: Dictionary = government_snapshot.get(
		"state",
		{}
	)

	var snapshot_active_policies: Dictionary = snapshot_state.get(
		"active_policies",
		{}
	)

	var snapshot_capture_pass: bool = (
		snapshot_active_policies.has(
			"industrial::steel_production"
		)
		and snapshot_active_policies.has(
			"military::posture"
		)
		and str(
			 snapshot_active_policies[
				 "industrial::steel_production"
			].get(
				 "policy_id",
				 ""
			)
		) == policy_b_id
	)

	TestLogger.write_line(
		"WorldSnapshot preserves active policy state: "
		+ (
			"PASS"
			if snapshot_capture_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and snapshot_capture_pass
	)

	if snapshot_active_policies.has(
		"industrial::steel_production"
	):
		snapshot_active_policies[
			"industrial::steel_production"
		]["policy_id"] = "mutated_snapshot"

	var live_active_after_snapshot_mutation: Dictionary = (
		government.get_active_policy(
			"industrial::steel_production"
		)
	)

	snapshot_isolated_ok = (
		str(
			live_active_after_snapshot_mutation.get(
				"policy_id",
				""
			)
		) == policy_b_id
	)

	TestLogger.write_line(
		"WorldSnapshot active policy state is deep-copy isolated: "
		+ (
			"PASS"
			if snapshot_isolated_ok
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and snapshot_isolated_ok
	)

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = (
		original_state
	)

	var restoration_pass: bool = (
		government.get_active_policies().is_empty()
		and int(
			government.get_state(
				"policy_activation_revision",
				0
			)
		) == int(
			original_state.get(
				"policy_activation_revision",
				0
			)
		)
	)

	TestLogger.write_line(
		"Step 8.2 government state restoration: "
		+ (
			"PASS"
			if restoration_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and restoration_pass
	)

	# --------------------------------------------------------
	# THREE-COUNTRY STRUCTURAL CHECK
	# --------------------------------------------------------

	var country_ids: Array[String] = [
		"china",
		"india",
		"usa"
	]

	var world_clean: bool = true

	for country_id in country_ids:

		if world.get_entity(
			country_id
		) == null:

			world_clean = false
			break

	TestLogger.write_line(
		"Three-country world remains structurally clean: "
		+ (
			"PASS"
			if world_clean
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and world_clean
	)

	TestLogger.section(
		"GOVERNMENT POLICY ACTIVATION / CHANGE RESULT"
	)

	TestLogger.write_line(
		"Government Policy Activation / Change 8.2 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
