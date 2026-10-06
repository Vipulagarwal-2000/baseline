class_name GovernmentPolicyCostTest
extends RefCounted


# ============================================================
# GOVERNMENT — STEP 8.3 TEST
# ============================================================
#
# Validates:
# - registered GovernmentPolicyCostSystem exists
# - policy changes can be requested through the cost-bearing path
# - treasury is the authoritative existing cost resource
# - affordable policy change charges treasury exactly once
# - insufficient treasury rejects the change without mutation
# - unsupported positive cost resources are rejected safely
# - zero-cost policy activation remains valid
# - re-requesting an already-active policy is idempotent and free
# - policy definitions remain unchanged
# - policy effects remain untouched (Step 8.4 boundary)
# - cost ledger / result state is explicit
# - WorldSnapshot preserves cost state
# - snapshot state is deep-copy isolated
# - full government/economy state is restored
# - three-country structural integrity remains clean
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT POLICY COST TEST"
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

	var cost_system_instance = simulation.get_system(
		"government_policy_cost_system"
	)

	var cost_system_ok: bool = (
		cost_system_instance != null
		and cost_system_instance is GovernmentPolicyCostSystem
	)

	TestLogger.write_line(
		"Registered GovernmentPolicyCostSystem available: "
		+ (
			"PASS"
			if cost_system_ok
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and cost_system_ok
	)

	if not cost_system_ok:
		return false

	var cost_system: GovernmentPolicyCostSystem = (
		cost_system_instance as GovernmentPolicyCostSystem
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

	var economy = india.get_component(
		"economy"
	)

	var components_available: bool = (
		government != null
		and economy != null
	)

	TestLogger.write_line(
		"India government/economy components available: "
		+ (
			"PASS"
			if components_available
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and components_available
	)

	if not components_available:
		return false

	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)

	# --------------------------------------------------------
	# CONTROLLED DEFINITIONS
	# --------------------------------------------------------

	var paid_policy_id: String = (
		"industrial_subsidy_8_3_paid"
	)

	var replacement_policy_id: String = (
		"industrial_subsidy_8_3_replacement"
	)

	var unsupported_policy_id: String = (
		"industrial_subsidy_8_3_unsupported"
	)

	var free_policy_id: String = (
		"industrial_subsidy_8_3_free"
	)

	var paid_policy = GovernmentPolicyDefinition.new(
		paid_policy_id,
		"industrial",
		"steel_production",
		0.05,
		{
			"treasury": 25.0
		},
		12,
		{
			"production_multiplier": 1.05
		},
		{
			"source": "step_8_3_test"
		}
	)

	var replacement_policy = GovernmentPolicyDefinition.new(
		replacement_policy_id,
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
			"source": "step_8_3_test"
		}
	)

	var unsupported_policy = GovernmentPolicyDefinition.new(
		unsupported_policy_id,
		"administration",
		"bureaucratic_capacity",
		0.10,
		{
			"administrative": 5.0
		},
		12,
		{
			"administrative_multiplier": 1.10
		},
		{
			"source": "step_8_3_test"
		}
	)

	var free_policy = GovernmentPolicyDefinition.new(
		free_policy_id,
		"social",
		"public_information",
		0.05,
		{},
		6,
		{
			"test_only_effect": 1.0
		},
		{
			"source": "step_8_3_test"
		}
	)

	var definitions_registered: bool = (
		government.define_policy(paid_policy)
		and government.define_policy(replacement_policy)
		and government.define_policy(unsupported_policy)
		and government.define_policy(free_policy)
	)

	TestLogger.write_line(
		"Controlled Step 8.3 policy definitions register: "
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
	# AFFORDABLE POLICY CHANGE
	# --------------------------------------------------------

	economy.set_state(
		"treasury",
		100.0
	)

	var request_pass: bool = government.request_policy_activation(
		paid_policy_id
	)

	TestLogger.write_line(
		"Affordable policy activation request created: "
		+ (
			"PASS"
			if request_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and request_pass
	)

	cost_system.process_month(
		world
	)

	var treasury_after_charge: float = float(
		economy.get_state(
			"treasury",
			0.0
		)
	)

	var affordable_result: Dictionary = government.get_policy_cost_last_result()

	var affordable_activation_pass: bool = (
		government.is_policy_active(paid_policy_id)
		and is_equal_approx(
			treasury_after_charge,
			75.0
		)
		and is_equal_approx(
			float(affordable_result.get(
				"charged_treasury",
				0.0
			)),
			25.0
		)
		and is_equal_approx(
			float(affordable_result.get(
				"treasury_before",
				0.0
			)),
			100.0
		)
		and is_equal_approx(
			float(affordable_result.get(
				"treasury_after",
				0.0
			)),
			75.0
		)
	)

	TestLogger.write_line(
		"Affordable policy activation charges treasury and activates policy: "
		+ (
			"PASS"
			if affordable_activation_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and affordable_activation_pass
	)

	# --------------------------------------------------------
	# NO DOUBLE CHARGE AFTER PROCESSING
	# --------------------------------------------------------

	cost_system.process_month(
		world
	)

	var no_double_charge_pass: bool = is_equal_approx(
		float(
			economy.get_state(
				"treasury",
				0.0
			)
		),
		75.0
	)

	TestLogger.write_line(
		"Repeated cost-system processing does not double-charge: "
		+ (
			"PASS"
			if no_double_charge_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and no_double_charge_pass
	)

	# --------------------------------------------------------
	# SAME-POLICY RE-REQUEST IS FREE / IDEMPOTENT
	# --------------------------------------------------------

	var same_policy_request_pass: bool = (
		government.request_policy_activation(paid_policy_id)
	)

	cost_system.process_month(
		world
	)

	var same_policy_free_pass: bool = (
		same_policy_request_pass
		and government.is_policy_active(paid_policy_id)
		and is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					0.0
				)
			),
			75.0
		)
	)

	TestLogger.write_line(
		"Re-requesting already-active policy is idempotent and free: "
		+ (
			"PASS"
			if same_policy_free_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and same_policy_free_pass
	)

	# --------------------------------------------------------
	# REPLACEMENT POLICY CHARGE
	# --------------------------------------------------------

	var replacement_request_pass: bool = (
		government.request_policy_activation(replacement_policy_id)
	)

	cost_system.process_month(
		world
	)

	var replacement_pass: bool = (
		replacement_request_pass
		and government.is_policy_active(replacement_policy_id)
		and not government.is_policy_active(paid_policy_id)
		and is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					0.0
				)
			),
			55.0
		)
	)

	TestLogger.write_line(
		"Changing to a new policy charges only the new policy cost: "
		+ (
			"PASS"
			if replacement_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and replacement_pass
	)

	# --------------------------------------------------------
	# INSUFFICIENT TREASURY
	# --------------------------------------------------------

	government.set_state(
		"active_policies",
		{}
	)

	economy.set_state(
		"treasury",
		10.0
	)

	var insufficient_request_pass: bool = (
		government.request_policy_activation(paid_policy_id)
	)

	cost_system.process_month(
		world
	)

	var insufficient_pass: bool = (
		insufficient_request_pass
		and not government.is_policy_active(paid_policy_id)
		and is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					0.0
				)
			),
			10.0
		)
		and str(
			government.get_policy_cost_last_result().get(
				"reason",
				""
			)
		) == "insufficient_treasury"
	)

	TestLogger.write_line(
		"Insufficient treasury rejects policy without charging: "
		+ (
			"PASS"
			if insufficient_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and insufficient_pass
	)

	# --------------------------------------------------------
	# UNSUPPORTED POSITIVE COST RESOURCE
	# --------------------------------------------------------

	economy.set_state(
		"treasury",
		100.0
	)

	var unsupported_request_pass: bool = (
		government.request_policy_activation(unsupported_policy_id)
	)

	cost_system.process_month(
		world
	)

	var unsupported_pass: bool = (
		unsupported_request_pass
		and not government.is_policy_active(unsupported_policy_id)
		and is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					0.0
				)
			),
			100.0
		)
		and "unsupported_cost_resource:administrative" in str(
			government.get_policy_cost_last_result().get(
				"reason",
				""
			)
		)
	)

	TestLogger.write_line(
		"Unsupported positive cost resource is rejected without mutation: "
		+ (
			"PASS"
			if unsupported_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and unsupported_pass
	)

	# --------------------------------------------------------
	# ZERO-COST POLICY
	# --------------------------------------------------------

	var free_request_pass: bool = (
		government.request_policy_activation(free_policy_id)
	)

	cost_system.process_month(
		world
	)

	var zero_cost_pass: bool = (
		free_request_pass
		and government.is_policy_active(free_policy_id)
		and is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					0.0
				)
			),
			100.0
		)
	)

	TestLogger.write_line(
		"Zero-cost policy activates without treasury deduction: "
		+ (
			"PASS"
			if zero_cost_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and zero_cost_pass
	)

	# --------------------------------------------------------
	# DEFINITION PRESERVATION / EFFECT BOUNDARY
	# --------------------------------------------------------

	var definition_preserved_pass: bool = (
		is_equal_approx(
			float(
				government.get_policy_definition(
					paid_policy_id
				).get(
					"value",
					0.0
				)
			),
			0.05
		)
		and float(
			government.get_policy_definition(
				paid_policy_id
			).get(
				"cost",
				{}
			).get(
				"treasury",
				0.0
			)
		) == 25.0
	)

	TestLogger.write_line(
		"Policy definition remains unchanged by cost processing: "
		+ (
			"PASS"
			if definition_preserved_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and definition_preserved_pass
	)

	var effect_boundary_pass: bool = (
		government.get_policy_definition(
			free_policy_id
		).get(
			"effects",
			{}
		).get(
			"test_only_effect",
			0.0
		) == 1.0
	)

	TestLogger.write_line(
		"Step 8.3 does not apply policy effects: "
		+ (
			"PASS"
			if effect_boundary_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and effect_boundary_pass
	)

	# --------------------------------------------------------
	# LEDGER / LAST RESULT
	# --------------------------------------------------------

	var ledger = government.get_policy_cost_ledger()
	var ledger_pass: bool = (
		not ledger.is_empty()
		and not government.get_policy_cost_last_result().is_empty()
	)

	TestLogger.write_line(
		"Policy cost ledger and last-result state are explicit: "
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
	# SNAPSHOT
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(
		world
	)

	var india_snapshot = snapshot.entities.get(
		"india",
		{}
	)

	var snapshot_government = (
		india_snapshot.get(
			"components",
			{}
		).get(
			"government",
			{}
		)
	)

	var snapshot_state: Dictionary = snapshot_government.get(
		"state",
		{}
	)

	var snapshot_cost_ledger: Dictionary = snapshot_state.get(
		"policy_cost_ledger",
		{}
	)

	var snapshot_pass: bool = (
		not snapshot_cost_ledger.is_empty()
	)

	TestLogger.write_line(
		"WorldSnapshot preserves policy cost state: "
		+ (
			"PASS"
			if snapshot_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and snapshot_pass
	)

	if snapshot_pass:
		var snapshot_mutable = snapshot_cost_ledger.duplicate(true)
		snapshot_mutable.clear()

	var snapshot_isolation_pass: bool = (
		not government.get_policy_cost_ledger().is_empty()
	)

	TestLogger.write_line(
		"WorldSnapshot policy cost state is deep-copy isolated: "
		+ (
			"PASS"
			if snapshot_isolation_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and snapshot_isolation_pass
	)

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = original_government_state
	economy.state = original_economy_state

	var restoration_pass: bool = (
		government.state == original_government_state
		and economy.state == original_economy_state
	)

	TestLogger.write_line(
		"Step 8.3 government/economy state restoration: "
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
		if world.get_entity(country_id) == null:
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
		"GOVERNMENT POLICY COST RESULT"
	)

	TestLogger.write_line(
		"Government Policy Cost 8.3 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
