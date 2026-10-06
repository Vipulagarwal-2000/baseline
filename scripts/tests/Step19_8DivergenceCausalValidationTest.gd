class_name Step19_8DivergenceCausalValidationTest
extends RefCounted


# ============================================================
# STEP 19.8 — DIVERGENCE CAUSAL VALIDATION
# ============================================================
#
# Controlled branch experiment:
#
# identical baseline world
#        ↓
# two legitimate DecisionOption branches
#        ↓
# same executable diplomatic action contract
#        ↓
# different controlled action intensity
#        ↓
# registered ActionManager admission
#        ↓
# normal monthly ACTIONS execution
#        ↓
# authoritative bilateral relationship divergence
#        ↓
# divergence persists across multiple monthly ticks
#        ↓
# existing DivergenceAnalyzer detects the branch difference
#
# No second action engine, decision engine, divergence engine, or
# domain authority is introduced.
#
# Branches are built from the existing DecisionOption contract:
#   - same actor
#   - same target
#   - same executable action kind
#   - different controlled decision intensity
#
# Each branch runs in an independently bootstrapped copy of the
# current live project context, so Branch B starts from exactly the
# same world baseline rather than from Branch A's mutated state.
# ============================================================

const TARGET_COUNTRY_ID: String = "india"
const TARGET_RELATIONSHIP_ID: String = "china"

const BRANCH_A_ID: String = "diplomatic_outreach_limited"
const BRANCH_B_ID: String = "diplomatic_outreach_strong"

const BRANCH_A_VALUE: float = 0.20
const BRANCH_B_VALUE: float = 0.80

const MONTHS_TO_VALIDATE: int = 3
const MIN_NONZERO_DIVERGENCE: float = 0.000001
const MIN_SCORE_DIVERGENCE: float = 0.000001

const REQUIRED_SYSTEMS: Array[String] = [
	"decision_system",
	"ai_decision_system",
	"country_strategy_system",
]

const MAIN_SCRIPT: Script = preload("res://scripts/main.gd")


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + _pass_fail(passed)
	)


static func _approx(
	actual: float,
	expected: float,
	tolerance: float = 0.000001
) -> bool:
	return absf(actual - expected) <= tolerance


static func _get_relationship(
	country,
	target_id: String
) -> float:
	if country == null:
		return 0.0

	return float(
		country.get_relationship(
			target_id,
			0.0
		)
	)


static func _get_registered_system(
	simulation: SimulationEngine,
	system_name: String
) -> SimulationSystem:
	if simulation == null:
		return null

	return simulation.get_system(system_name) as SimulationSystem


static func _find_diplomatic_seed_option(
	decision_system: DecisionSystem,
	world: WorldState,
	country
) -> DecisionOption:
	if decision_system == null:
		return null

	if world == null or country == null:
		return null

	# Use the registered DecisionSystem to generate the live decision
	# collection. This is metadata preparation only; no time is advanced.
	decision_system.process_month(world)

	var options: Variant = country.get_sim_metadata(
		"decision_options",
		[]
	)

	if typeof(options) != TYPE_ARRAY:
		return null

	for option_variant in options:
		var option: DecisionOption = option_variant as DecisionOption
		if option == null:
			continue

		if option.action_type != "diplomatic":
			continue

		return option

	return null


static func _build_branch_option(
	seed_option: DecisionOption,
	branch_id: String,
	branch_value: float,
	actor_id: String,
	target_id: String,
	branch_name: String
) -> DecisionOption:
	if seed_option == null:
		return null

	var option: DecisionOption = DecisionOption.new(
		branch_id,
		branch_name,
		"diplomatic"
	)

	option.description = seed_option.description
	option.actor_id = actor_id
	option.target_id = target_id
	option.base_score = seed_option.base_score
	option.metadata = seed_option.metadata.duplicate(true)

	# Use the existing DecisionOption → SimAction payload contract.
	option.metadata["action"] = {
		"value": branch_value,
		"duration_months": 1,
		"executable_action_type": "diplomatic_outreach"
	}

	return option


static func _bootstrap_context() -> Dictionary:
	# Reuse the live project's own main.gd bootstrap so both branches use
	# the same registered systems, data loading, ordering, and authority
	# setup as the active simulator.
	var bootstrap: Node = MAIN_SCRIPT.new() as Node

	if bootstrap == null:
		return {}

	var context: Variant = bootstrap.call("_create_simulation_context")

	if typeof(context) != TYPE_DICTIONARY:
		return {}

	return context


static func _capture_initial_branch_snapshot(
	simulation: SimulationEngine
) -> WorldSnapshot:
	if simulation == null:
		return null

	return simulation.capture_baseline()


static func _run_branch(
	world: WorldState,
	simulation: SimulationEngine,
	decision_system: DecisionSystem,
	branch_option: DecisionOption
) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"action": null,
		"completion": false,
		"relationship_history": [],
		"snapshots": [],
		"failure_reason": ""
	}

	if world == null or simulation == null:
		result["failure_reason"] = "branch world/simulation unavailable"
		return result

	if decision_system == null:
		result["failure_reason"] = "decision system unavailable"
		return result

	if branch_option == null:
		result["failure_reason"] = "branch decision unavailable"
		return result

	# Evaluate through the registered DecisionSystem / DecisionEvaluator
	# boundary before issuing the action.
	decision_system.evaluate_option(
		world,
		world.get_entity(TARGET_COUNTRY_ID),
		branch_option
	)

	var ranked: Array = decision_system.rank_options(
		world,
		world.get_entity(TARGET_COUNTRY_ID),
		[branch_option]
	)

	if ranked.size() != 1:
		result["failure_reason"] = "decision option could not be ranked"
		return result

	var issue_result: Dictionary = simulation.issue_player_action(
		TARGET_COUNTRY_ID,
		branch_option
	)

	if not bool(issue_result.get("success", false)):
		result["failure_reason"] = str(
			issue_result.get(
				"failure_reason",
				"player action issuance failed"
			)
		)
		return result

	var action: SimAction = issue_result.get("action", null) as SimAction
	if action == null:
		result["failure_reason"] = "issued action is null"
		return result

	result["action"] = action

	var admission_contract_valid: bool = (
		action.actor_id == TARGET_COUNTRY_ID
		and action.target_id == TARGET_RELATIONSHIP_ID
		and action.action_type == "diplomatic_outreach"
		and _approx(action.value, branch_option.metadata["action"]["value"])
		and action.duration_months == 1
	)

	if not admission_contract_valid:
		result["failure_reason"] = "executable action contract mismatch"
		return result

	for month_index in range(MONTHS_TO_VALIDATE):
		simulation.tick_month()

		var current_country = world.get_entity(
			TARGET_COUNTRY_ID
		)

		var relationship_now: float = _get_relationship(
			current_country,
			TARGET_RELATIONSHIP_ID
		)

		result["relationship_history"].append(
			relationship_now
		)

		var latest_snapshot: WorldSnapshot = (
			simulation.get_latest_snapshot()
		)

		if latest_snapshot != null:
			result["snapshots"].append(
				latest_snapshot
			)

		if month_index == 0:
			result["completion"] = (
				action.state == SimAction.STATE_COMPLETED
			)

	result["success"] = true
	return result


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 19.8 — DIVERGENCE CAUSAL VALIDATION"
	)

	var passed: bool = true

	# ------------------------------------------------------------
	# Runner-world isolation
	# ------------------------------------------------------------
	#
	# 19.8 deliberately operates on two independently bootstrapped
	# contexts so the primary active test-suite world is not consumed
	# by Branch A and then reused for Branch B.
	#
	# Capture the active-suite world only to prove that the test itself
	# leaves that fixture untouched.
	# ------------------------------------------------------------

	var primary_before: WorldSnapshot = WorldSnapshot.new()
	primary_before.capture(world)

	# ------------------------------------------------------------
	# Bootstrap two independent live simulator contexts
	# ------------------------------------------------------------

	var context_a: Dictionary = _bootstrap_context()
	var context_b: Dictionary = _bootstrap_context()

	var world_a: WorldState = context_a.get("world", null) as WorldState
	var simulation_a: SimulationEngine = context_a.get(
		"simulation",
		null
	) as SimulationEngine

	var world_b: WorldState = context_b.get("world", null) as WorldState
	var simulation_b: SimulationEngine = context_b.get(
		"simulation",
		null
	) as SimulationEngine

	var contexts_available: bool = (
		world_a != null
		and simulation_a != null
		and world_b != null
		and simulation_b != null
	)

	_log_result(
		"Two independent live simulation contexts available",
		contexts_available
	)
	passed = passed and contexts_available

	if not contexts_available:
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation overall: FAIL"
		)
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation test: FAIL"
		)
		return false

	# ------------------------------------------------------------
	# Registered architecture availability
	# ------------------------------------------------------------

	for system_name in REQUIRED_SYSTEMS:
		var available_a = _get_registered_system(
			simulation_a,
			system_name
		)
		var available_b = _get_registered_system(
			simulation_b,
			system_name
		)

		var system_pass: bool = (
			available_a != null
			and available_b != null
		)

		_log_result(
			"Registered " + system_name + " exists in both branches",
			system_pass
		)

		passed = passed and system_pass

	var india_a = world_a.get_entity(TARGET_COUNTRY_ID)
	var india_b = world_b.get_entity(TARGET_COUNTRY_ID)

	var china_a = world_a.get_entity(TARGET_RELATIONSHIP_ID)
	var china_b = world_b.get_entity(TARGET_RELATIONSHIP_ID)

	var countries_available: bool = (
		india_a != null
		and india_b != null
		and china_a != null
		and china_b != null
	)

	_log_result(
		"India / China branch fixtures available",
		countries_available
	)
	passed = passed and countries_available

	if not countries_available:
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation overall: FAIL"
		)
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation test: FAIL"
		)
		return false

	# ------------------------------------------------------------
	# Baseline equality
	# ------------------------------------------------------------

	var baseline_a: WorldSnapshot = _capture_initial_branch_snapshot(
		simulation_a
	)
	var baseline_b: WorldSnapshot = _capture_initial_branch_snapshot(
		simulation_b
	)

	var baseline_match: bool = (
		baseline_a != null
		and baseline_b != null
		and baseline_a.date == baseline_b.date
		and baseline_a.entities == baseline_b.entities
		and baseline_a.trade_agreements == baseline_b.trade_agreements
		and baseline_a.trade_routes == baseline_b.trade_routes
		and baseline_a.trade_transactions == baseline_b.trade_transactions
	)

	_log_result(
		"Branch A and Branch B begin from an identical authoritative baseline",
		baseline_match
	)
	passed = passed and baseline_match

	var baseline_relation_a: float = _get_relationship(
		india_a,
		TARGET_RELATIONSHIP_ID
	)
	var baseline_relation_b: float = _get_relationship(
		india_b,
		TARGET_RELATIONSHIP_ID
	)

	var baseline_relation_match: bool = _approx(
		baseline_relation_a,
		baseline_relation_b
	)

	_log_result(
		"Branch bilateral relationship starts equal",
		baseline_relation_match
	)
	passed = passed and baseline_relation_match

	# ------------------------------------------------------------
	# Decision branch construction through the existing decision layer
	# ------------------------------------------------------------

	var decision_system_a: DecisionSystem = _get_registered_system(
		simulation_a,
		"decision_system"
	) as DecisionSystem

	var decision_system_b: DecisionSystem = _get_registered_system(
		simulation_b,
		"decision_system"
	) as DecisionSystem

	var seed_option_a: DecisionOption = _find_diplomatic_seed_option(
		decision_system_a,
		world_a,
		india_a
	)

	var seed_option_b: DecisionOption = _find_diplomatic_seed_option(
		decision_system_b,
		world_b,
		india_b
	)

	var seed_options_available: bool = (
		seed_option_a != null
		and seed_option_b != null
	)

	_log_result(
		"Registered DecisionSystem provides a diplomatic branch seed in both worlds",
		seed_options_available
	)
	passed = passed and seed_options_available

	if not seed_options_available:
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation overall: FAIL"
		)
		TestLogger.write_line(
			"Step 19.8 Divergence Causal Validation test: FAIL"
		)
		return false

	var branch_a_option: DecisionOption = _build_branch_option(
		seed_option_a,
		BRANCH_A_ID,
		BRANCH_A_VALUE,
		TARGET_COUNTRY_ID,
		TARGET_RELATIONSHIP_ID,
		"Limited Diplomatic Outreach"
	)

	var branch_b_option: DecisionOption = _build_branch_option(
		seed_option_b,
		BRANCH_B_ID,
		BRANCH_B_VALUE,
		TARGET_COUNTRY_ID,
		TARGET_RELATIONSHIP_ID,
		"Strong Diplomatic Outreach"
	)

	var decision_branches_valid: bool = (
		branch_a_option != null
		and branch_b_option != null
		and branch_a_option.id != branch_b_option.id
		and branch_a_option.actor_id == branch_b_option.actor_id
		and branch_a_option.target_id == branch_b_option.target_id
		and branch_a_option.action_type == branch_b_option.action_type
		and branch_a_option.metadata.has("action")
		and branch_b_option.metadata.has("action")
	)

	_log_result(
		"Two distinct DecisionOption branches share the same valid action contract",
		decision_branches_valid
	)
	passed = passed and decision_branches_valid

	# ------------------------------------------------------------
	# Branch execution
	# ------------------------------------------------------------

	var branch_a_result: Dictionary = _run_branch(
		world_a,
		simulation_a,
		decision_system_a,
		branch_a_option
	)

	var branch_b_result: Dictionary = _run_branch(
		world_b,
		simulation_b,
		decision_system_b,
		branch_b_option
	)

	var action_a: SimAction = branch_a_result.get(
		"action",
		null
	) as SimAction

	var action_b: SimAction = branch_b_result.get(
		"action",
		null
	) as SimAction

	var action_contract_pass: bool = (
		bool(branch_a_result.get("success", false))
		and bool(branch_b_result.get("success", false))
		and action_a != null
		and action_b != null
		and action_a.action_type == "diplomatic_outreach"
		and action_b.action_type == "diplomatic_outreach"
		and _approx(action_a.value, BRANCH_A_VALUE)
		and _approx(action_b.value, BRANCH_B_VALUE)
	)

	_log_result(
		"Both decision branches enter the normal executable action contract",
		action_contract_pass
	)
	passed = passed and action_contract_pass

	var action_targets_pass: bool = (
		action_a != null
		and action_b != null
		and action_a.actor_id == TARGET_COUNTRY_ID
		and action_b.actor_id == TARGET_COUNTRY_ID
		and action_a.target_id == TARGET_RELATIONSHIP_ID
		and action_b.target_id == TARGET_RELATIONSHIP_ID
	)

	_log_result(
		"Both branches target the same authoritative country relationship",
		action_targets_pass
	)
	passed = passed and action_targets_pass

	var action_completion_pass: bool = (
		bool(branch_a_result.get("completion", false))
		and bool(branch_b_result.get("completion", false))
	)

	_log_result(
		"Both branch actions complete through the registered monthly ACTIONS phase",
		action_completion_pass
	)
	passed = passed and action_completion_pass

	# ------------------------------------------------------------
	# Persistent divergence
	# ------------------------------------------------------------

	var rel_history_a: Array = branch_a_result.get(
		"relationship_history",
		[]
	)
	var rel_history_b: Array = branch_b_result.get(
		"relationship_history",
		[]
	)

	var histories_complete: bool = (
		rel_history_a.size() == MONTHS_TO_VALIDATE
		and rel_history_b.size() == MONTHS_TO_VALIDATE
	)

	_log_result(
		"Both branches produce three comparable monthly relationship observations",
		histories_complete
	)
	passed = passed and histories_complete

	var divergence_observed: bool = false
	var divergence_persistent: bool = true

	if histories_complete:
		for index in range(MONTHS_TO_VALIDATE):
			var a_value: float = float(rel_history_a[index])
			var b_value: float = float(rel_history_b[index])
			var delta: float = a_value - b_value

			var month_diverged: bool = absf(delta) >= MIN_NONZERO_DIVERGENCE

			TestLogger.write_line(
				"19.8 branch month "
				+ str(index + 1)
				+ " relationship | A="
				+ str(a_value)
				+ " B="
				+ str(b_value)
				+ " delta="
				+ str(delta)
				+ " | "
				+ _pass_fail(month_diverged)
			)

			if month_diverged:
				divergence_observed = true
			else:
				divergence_persistent = false

	var first_delta: float = 0.0
	if histories_complete and MONTHS_TO_VALIDATE > 0:
		first_delta = (
			float(rel_history_a[0])
			- float(rel_history_b[0])
		)

	var branch_direction_pass: bool = (
		divergence_observed
		and absf(first_delta) >= MIN_NONZERO_DIVERGENCE
	)

	_log_result(
		"Different decision intensities create authoritative relationship divergence",
		branch_direction_pass
	)
	passed = passed and branch_direction_pass

	_log_result(
		"Relationship divergence persists across all tested months",
		divergence_persistent
	)
	passed = passed and divergence_persistent

	# ------------------------------------------------------------
	# Existing DivergenceAnalyzer
	# ------------------------------------------------------------

	var latest_a: WorldSnapshot = (
		simulation_a.get_latest_snapshot()
	)
	var latest_b: WorldSnapshot = (
		simulation_b.get_latest_snapshot()
	)

	var divergence_analysis_pass: bool = (
		latest_a != null
		and latest_b != null
		and latest_a.date == latest_b.date
	)

	_log_result(
		"Branch end snapshots exist at the same simulation date",
		divergence_analysis_pass
	)
	passed = passed and divergence_analysis_pass

	if divergence_analysis_pass:
		var analyzer: DivergenceAnalyzer = DivergenceAnalyzer.new()

		# Analyze Branch A as baseline and Branch B as current. The existing
		# analyzer then exposes the bilateral relationship delta without
		# introducing a second divergence calculation.
		var branch_divergence: Dictionary = analyzer.analyze_world(
			latest_a,
			latest_b
		)

		var india_result: Dictionary = (
			branch_divergence.get(
				"entities",
				{}
			).get(
				TARGET_COUNTRY_ID,
				{}
			)
		)

		var relationship_result: Dictionary = (
			india_result.get(
				"relationships",
				{}
			).get(
				TARGET_RELATIONSHIP_ID,
				{}
			)
		)

		var analyzer_change: float = float(
			relationship_result.get(
				"change",
				0.0
			)
		)

		var analyzer_detects_divergence: bool = (
			absf(analyzer_change) >= MIN_NONZERO_DIVERGENCE
		)

		TestLogger.write_line(
			"Existing DivergenceAnalyzer detects branch relationship divergence: "
			+ _pass_fail(analyzer_detects_divergence)
			+ " | change="
			+ str(analyzer_change)
		)

		passed = passed and analyzer_detects_divergence

	# ------------------------------------------------------------
	# Downstream observation through decision scoring
	# ------------------------------------------------------------

	# The branch state is now different. Re-evaluate the same target
	# through the real DecisionEvaluator so the test proves that the
	# downstream decision layer can observe the changed authoritative
	# relationship rather than merely storing two numbers.
	var final_option_a: DecisionOption = _build_branch_option(
		seed_option_a,
		"diplomatic_observation_a",
		0.20,
		TARGET_COUNTRY_ID,
		TARGET_RELATIONSHIP_ID,
		"Diplomatic Observation A"
	)

	var final_option_b: DecisionOption = _build_branch_option(
		seed_option_b,
		"diplomatic_observation_b",
		0.20,
		TARGET_COUNTRY_ID,
		TARGET_RELATIONSHIP_ID,
		"Diplomatic Observation B"
	)

	var final_score_a: float = decision_system_a.evaluate_option(
		world_a,
		india_a,
		final_option_a
	)

	var final_score_b: float = decision_system_b.evaluate_option(
		world_b,
		india_b,
		final_option_b
	)

	var relationship_score_delta: float = (
		final_option_b.relationship_score
		- final_option_a.relationship_score
	)

	var final_score_delta: float = (
		final_score_b
		- final_score_a
	)

	var expected_relationship_score_delta: float = (
		float(rel_history_b[MONTHS_TO_VALIDATE - 1])
		- float(rel_history_a[MONTHS_TO_VALIDATE - 1])
	) / 200.0

	var decision_relationship_dimension_observes: bool = (
		absf(relationship_score_delta) >= MIN_SCORE_DIVERGENCE
		and absf(relationship_score_delta - expected_relationship_score_delta) <= 0.000001
	)

	var decision_observes_divergence: bool = (
		decision_relationship_dimension_observes
	)

	TestLogger.write_line(
		"Downstream DecisionEvaluator observes divergent relationship state: "
		+ _pass_fail(decision_observes_divergence)
		+ " | relationship_score_A="
		+ str(final_option_a.relationship_score)
		+ " relationship_score_B="
		+ str(final_option_b.relationship_score)
		+ " relationship_score_delta="
		+ str(relationship_score_delta)
		+ " expected_delta="
		+ str(expected_relationship_score_delta)
		+ " final_score_delta="
		+ str(final_score_delta)
	)
	passed = passed and decision_observes_divergence

	# ------------------------------------------------------------
	# Primary suite fixture preservation
	# ------------------------------------------------------------

	var primary_after: WorldSnapshot = WorldSnapshot.new()
	primary_after.capture(world)

	var primary_restored: bool = (
		primary_before.date == primary_after.date
		and primary_before.entities == primary_after.entities
		and primary_before.trade_agreements == primary_after.trade_agreements
		and primary_before.trade_routes == primary_after.trade_routes
		and primary_before.trade_transactions == primary_after.trade_transactions
	)

	_log_result(
		"Step 19.8 leaves the active suite fixture unchanged",
		primary_restored
	)
	passed = passed and primary_restored

	TestLogger.write_line(
		"19.8 DIAGNOSTIC | baseline_relation="
		+ str(baseline_relation_a)
		+ " branch_A_month3="
		+ str(
			float(
				rel_history_a[MONTHS_TO_VALIDATE - 1]
				if histories_complete
				else baseline_relation_a
			)
		)
		+ " branch_B_month3="
		+ str(
			float(
				rel_history_b[MONTHS_TO_VALIDATE - 1]
				if histories_complete
				else baseline_relation_b
			)
		)
	)

	TestLogger.write_line(
		"Step 19.8 Divergence Causal Validation overall: "
		+ ("PASS" if passed else "FAIL")
	)

	TestLogger.write_line(
		"Step 19.8 Divergence Causal Validation test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
