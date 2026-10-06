class_name GovernmentPolicyDefinitionTest
extends RefCounted


# ============================================================
# GOVERNMENT — STEP 8.1 TEST
# ============================================================
#
# Validates:
# - existing GovernmentComponent remains intact
# - valid data-driven policy definition creation
# - required schema fields
# - definition registration / lookup
# - deep-copy isolation
# - serialization round-trip
# - duplicate protection
# - invalid definition rejection
# - definition revision / ledger
# - WorldSnapshot representation
# - definition-only boundary (no activation)
# - state restoration
# - three-country structural integrity
#
# Step 8.1 intentionally does NOT activate, charge for, or apply
# policies. Those behaviors belong to later Step 8 substeps.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"GOVERNMENT POLICY DEFINITION TEST"
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

	var policy_id: String = (
		"industrial_subsidy_8_1_test"
	)

	# --------------------------------------------------------
	# VALID POLICY DEFINITION
	# --------------------------------------------------------

	var policy = GovernmentPolicyDefinition.new(
		policy_id,
		"industrial",
		"steel_production",
		0.05,
		{
			"treasury": 10.0,
			"administrative": 2.0
		},
		12,
		{
			"production_multiplier": 1.05
		},
		{
			"source": "step_8_1_test"
		}
	)

	var valid_definition_pass: bool = (
		policy.is_valid()
		and policy.policy_id == policy_id
		and policy.category == "industrial"
		and policy.target == "steel_production"
		and is_equal_approx(
			policy.value,
			0.05
		)
		and policy.duration_months == 12
	)

	TestLogger.write_line(
		"Valid policy definition schema: "
		+ (
			"PASS"
			if valid_definition_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and valid_definition_pass
	)

	# --------------------------------------------------------
	# SERIALIZATION ROUND-TRIP
	# --------------------------------------------------------

	var round_trip_policy = (
		GovernmentPolicyDefinition.from_dict(
			policy.to_dict()
		)
	)

	var round_trip_pass: bool = (
		round_trip_policy != null
		and round_trip_policy.is_valid()
		and round_trip_policy.policy_id == policy_id
		and round_trip_policy.category == "industrial"
		and round_trip_policy.target == "steel_production"
		and is_equal_approx(
			round_trip_policy.value,
			0.05
		)
		and round_trip_policy.duration_months == 12
		and float(
			round_trip_policy.cost.get(
				"treasury",
				-1.0
			)
		) == 10.0
		and is_equal_approx(
			float(
				round_trip_policy.effects.get(
					"production_multiplier",
					0.0
				)
			),
			1.05
		)
	)

	TestLogger.write_line(
		"Policy definition serialization round-trip: "
		+ (
			"PASS"
			if round_trip_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and round_trip_pass
	)

	# --------------------------------------------------------
	# DEFINE POLICY IN REAL GOVERNMENT COMPONENT
	# --------------------------------------------------------

	var define_pass: bool = (
		government.define_policy(
			policy
		)
	)

	TestLogger.write_line(
		"Policy definition registers in GovernmentComponent: "
		+ (
			"PASS"
			if define_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and define_pass
	)

	var has_definition_pass: bool = (
		government.has_policy_definition(
			policy_id
		)
	)

	TestLogger.write_line(
		"Defined policy can be retrieved by ID: "
		+ (
			"PASS"
			if has_definition_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and has_definition_pass
	)

	var stored: Dictionary = (
		government.get_policy_definition(
			policy_id
		)
	)

	var stored_values_pass: bool = (
		stored.get(
			"policy_id",
			""
		) == policy_id
		and stored.get(
			"category",
			""
		) == "industrial"
		and stored.get(
			"target",
			""
		) == "steel_production"
		and is_equal_approx(
			float(
				stored.get(
					"value",
					0.0
				)
			),
			0.05
		)
		and int(
			stored.get(
				"duration_months",
				-1
			)
		) == 12
		and float(
			stored.get(
				"cost",
				{}
			).get(
				"treasury",
				-1.0
			)
		) == 10.0
	)

	TestLogger.write_line(
		"Policy definition values are preserved: "
		+ (
			"PASS"
			if stored_values_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and stored_values_pass
	)

	# --------------------------------------------------------
	# DEEP-COPY ISOLATION
	# --------------------------------------------------------

	var retrieved_copy: Dictionary = (
		government.get_policy_definition(
			policy_id
		)
	)

	retrieved_copy["value"] = 0.90

	var retrieved_effects: Dictionary = (
		retrieved_copy.get(
			"effects",
			{}
		)
	)

	retrieved_effects[
		"production_multiplier"
	] = 9.0

	var unchanged_copy_pass: bool = (
		is_equal_approx(
			float(
				government.get_policy_definition(
					policy_id
				).get(
					"value",
					0.0
				)
			),
			0.05
		)
		and is_equal_approx(
			float(
				government.get_policy_definition(
					policy_id
				).get(
					"effects",
					{}
				).get(
					"production_multiplier",
					0.0
				)
			),
			1.05
		)
	)

	TestLogger.write_line(
		"Policy definition retrieval is deep-copy isolated: "
		+ (
			"PASS"
			if unchanged_copy_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and unchanged_copy_pass
	)

	# --------------------------------------------------------
	# DUPLICATE PROTECTION
	# --------------------------------------------------------

	var revision_before_duplicate: int = int(
		government.get_state(
			"policy_definition_revision",
			0
		)
	)

	var duplicate_pass: bool = (
		not government.define_policy(
			policy
		)
	)

	var revision_after_duplicate: int = int(
		government.get_state(
			"policy_definition_revision",
			0
		)
	)

	var duplicate_revision_pass: bool = (
		revision_before_duplicate == 1
		and revision_after_duplicate == 1
		and duplicate_pass
	)

	TestLogger.write_line(
		"Duplicate policy ID is rejected without revision change: "
		+ (
			"PASS"
			if duplicate_revision_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and duplicate_revision_pass
	)

	# --------------------------------------------------------
	# INVALID DEFINITIONS
	# --------------------------------------------------------

	var invalid_empty_id = (
		GovernmentPolicyDefinition.new(
			"",
			"industrial",
			"steel_production",
			0.05,
			{},
			12,
			{}
		)
	)

	var invalid_empty_category = (
		GovernmentPolicyDefinition.new(
			"invalid_empty_category_8_1",
			"",
			"steel_production",
			0.05,
			{},
			12,
			{}
		)
	)

	var invalid_empty_target = (
		GovernmentPolicyDefinition.new(
			"invalid_empty_target_8_1",
			"industrial",
			"",
			0.05,
			{},
			12,
			{}
		)
	)

	var invalid_negative_cost = (
		GovernmentPolicyDefinition.new(
			"invalid_negative_cost_8_1",
			"industrial",
			"steel_production",
			0.05,
			{
				"treasury": -1.0
			},
			12,
			{}
		)
	)

	var invalid_rejection_pass: bool = (
		not invalid_empty_id.is_valid()
		and not invalid_empty_category.is_valid()
		and not invalid_empty_target.is_valid()
		and not invalid_negative_cost.is_valid()
		and not government.define_policy(
			invalid_empty_id
		)
		and not government.define_policy(
			invalid_empty_category
		)
		and not government.define_policy(
			invalid_empty_target
		)
		and not government.define_policy(
			invalid_negative_cost
		)
	)

	TestLogger.write_line(
		"Invalid policy definitions are rejected safely: "
		+ (
			"PASS"
			if invalid_rejection_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and invalid_rejection_pass
	)

	# --------------------------------------------------------
	# REVISION / LEDGER
	# --------------------------------------------------------

	var revision: int = int(
		government.get_state(
			"policy_definition_revision",
			0
		)
	)

	var ledger: Dictionary = (
		government.get_state(
			"policy_definition_ledger",
			{}
		)
	)

	var revision_ledger_pass: bool = (
		revision == 1
		and ledger.has(
			policy_id
		)
		and ledger[policy_id].get(
			"action",
			""
		) == "defined"
		and int(
			ledger[policy_id].get(
				"revision",
				0
			)
		) == 1
	)

	TestLogger.write_line(
		"Policy definition revision and ledger are explicit: "
		+ (
			"PASS"
			if revision_ledger_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and revision_ledger_pass
	)

	# --------------------------------------------------------
	# SNAPSHOT REPRESENTATION
	# --------------------------------------------------------

	var snapshot = WorldSnapshot.new()

	snapshot.capture(
		world
	)

	var snapshot_pass: bool = false

	if snapshot.entities.has(
		india.id
	):

		var india_snapshot: Dictionary = (
			snapshot.entities[
				india.id
			]
		)

		var components: Dictionary = (
			india_snapshot.get(
				"components",
				{}
			)
		)

		var government_snapshot: Dictionary = (
			components.get(
				"government",
				{}
			)
		)

		var snapshot_state: Dictionary = (
			government_snapshot.get(
				"state",
				{}
			)
		)

		var snapshot_definitions: Dictionary = (
			snapshot_state.get(
				"policy_definitions",
				{}
			)
		)

		snapshot_pass = (
			snapshot_definitions.has(
				policy_id
			)
			and snapshot_definitions[
				policy_id
			].get(
				"target",
				""
			) == "steel_production"
		)

	TestLogger.write_line(
		"Policy definition is represented in WorldSnapshot state: "
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

	# --------------------------------------------------------
	# SNAPSHOT DEEP-COPY ISOLATION
	# --------------------------------------------------------

	if snapshot.entities.has(
		india.id
	):

		var india_snapshot_mutable: Dictionary = (
			snapshot.entities[
				india.id
			]
		)

		var component_snapshot_mutable: Dictionary = (
			india_snapshot_mutable.get(
				"components",
				{}
			)
		)

		var government_snapshot_mutable: Dictionary = (
			component_snapshot_mutable.get(
				"government",
				{}
			)
		)

		var snapshot_state_mutable: Dictionary = (
			government_snapshot_mutable.get(
				"state",
				{}
			)
		)

		var snapshot_policy_definitions_mutable: Dictionary = (
			snapshot_state_mutable.get(
				"policy_definitions",
				{}
			)
		)

		if snapshot_policy_definitions_mutable.has(
			policy_id
		):

			snapshot_policy_definitions_mutable[
				policy_id
			]["value"] = 0.99

	var snapshot_isolation_pass: bool = is_equal_approx(
		float(
			government.get_policy_definition(
				policy_id
			).get(
				"value",
				0.0
			)
		),
		0.05
	)

	TestLogger.write_line(
		"WorldSnapshot policy state is deep-copy isolated: "
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
	# STEP 8.1 BOUNDARY
	# --------------------------------------------------------

	var active_policies = government.get_state(
		"active_policies",
		null
	)

	var no_activation_pass: bool = (
		active_policies == null
		or not (
			active_policies is Dictionary
			and active_policies.has(
				policy_id
			)
		)
	)

	TestLogger.write_line(
		"Policy definition does not implicitly activate the policy: "
		+ (
			"PASS"
			if no_activation_pass
			else "FAIL"
		)
	)

	all_passed = (
		all_passed
		and no_activation_pass
	)

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = (
		original_state
	)

	var restoration_pass: bool = (
		not government.has_policy_definition(
			policy_id
		)
		and int(
			government.get_state(
				"policy_definition_revision",
				0
			)
		) == int(
			original_state.get(
				"policy_definition_revision",
				0
			)
		)
	)

	TestLogger.write_line(
		"Step 8.1 government state restoration: "
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
		"GOVERNMENT POLICY DEFINITION RESULT"
	)

	TestLogger.write_line(
		"Government Policy Definition 8.1 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
