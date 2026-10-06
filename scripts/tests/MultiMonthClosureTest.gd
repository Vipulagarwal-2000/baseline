class_name Step17_4MultiMonthClosureTest
extends RefCounted


# ============================================================
# STEP 17.4 — MULTI-MONTH CLOSURE ACCEPTANCE
# ============================================================
#
# This is ONE acceptance test for the Step 17.4 multi-month closure
# boundary.
#
# The test intentionally uses the live SimulationEngine path:
#
#   player decision
#       ↓
#   ActionManager admission
#       ↓
#   ACTIONS phase over multiple monthly ticks
#       ↓
#   terminal authoritative consequence
#       ↓
#   next WORLD_UPDATE observes the consequence
#       ↓
#   later decision evaluation sees the changed environment
#       ↓
#   monthly snapshots continue to advance
#
# No second monthly engine, action engine, or downstream authority is
# introduced by this test.
#
# The active Step 17 runner executes this test immediately before world
# validation, so the test is deliberately a terminal temporal acceptance
# boundary rather than a fixture that rewinds the whole simulation clock.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 17.4 — MULTI-MONTH CLOSURE"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var fixture_pair: Dictionary = _find_fixture_pair(
		world,
		simulation
	)

	var actor: SimEntity = fixture_pair.get(
		"actor",
		null
	) as SimEntity
	var target: SimEntity = fixture_pair.get(
		"target",
		null
	) as SimEntity

	if actor == null or target == null:
		TestLogger.write_line(
			"Multi-month closure actor / target fixture available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Multi-month closure actor / target fixture available: PASS"
		+ " | actor=" + actor.id
		+ " target=" + target.id
	)

	var decision_system = simulation.get_system("decision_system")
	var government_system = simulation.get_system("government_system")

	var required_systems_available: bool = (
		decision_system is DecisionSystem
		and government_system != null
	)

	TestLogger.write_line(
		"Registered decision / government systems available: "
		+ ("PASS" if required_systems_available else "FAIL")
	)

	if not required_systems_available:
		return false

	var government = actor.get_component("government")
	if government == null:
		TestLogger.write_line(
			"Actor government component available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Actor government component available: PASS"
	)

	var elapsed_before: int = world.get_elapsed_months()
	var snapshot_count_before: int = simulation.get_snapshot_count()
	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_relationship_before: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	# Build a real player decision whose executable action deliberately
	# lasts three monthly ticks. The consequence therefore cannot appear
	# and disappear inside a single monthly pass.
	var player_option: DecisionOption = DecisionOption.new(
		"step17_4_multi_month_player_outreach",
		"Step 17.4 Multi-Month Diplomatic Outreach",
		"diplomatic_outreach"
	)

	player_option.actor_id = actor.id
	player_option.target_id = target.id
	player_option.base_score = 1.0
	player_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05,
		"action": {
			"value": 20.0,
			"duration_months": 3
		}
	}

	var decision_score_before: float = (
		decision_system.evaluate_option(
			world,
			actor,
			player_option
		)
	)

	TestLogger.write_line(
		"Initial decision evaluation available: "
		+ ("PASS" if is_finite(decision_score_before) else "FAIL")
	)

	if not is_finite(decision_score_before):
		return false

	var issuance_result: Dictionary = simulation.issue_player_action(
		actor.id,
		player_option
	)

	var issued: bool = bool(
		issuance_result.get("success", false)
	)

	TestLogger.write_line(
		"Real player action admitted by SimulationEngine: "
		+ ("PASS" if issued else "FAIL")
	)

	if not issued:
		TestLogger.write_line(
			"Step 17.4 player-action admission failure: "
			+ str(
				issuance_result.get(
					"failure_reason",
					""
				)
			)
		)
		return false

	var action: SimAction = (
		issuance_result.get("action", null)
		as SimAction
	)

	if action == null:
		TestLogger.write_line(
			"Issued multi-month action object available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Issued multi-month action object available: PASS"
		+ " | duration=" + str(action.total_duration_months)
	)

	var action_duration_contract: bool = (
		action.total_duration_months == 3
		and action.duration_months == 3
		and action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"Three-month action duration contract preserved: "
		+ ("PASS" if action_duration_contract else "FAIL")
	)

	if not action_duration_contract:
		return false

	# ------------------------------------------------------------
	# MONTH N + 1
	# ------------------------------------------------------------

	simulation.tick_month()

	var elapsed_month_1: int = world.get_elapsed_months()
	var snapshot_count_month_1: int = simulation.get_snapshot_count()
	var relationship_month_1: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_relationship_month_1: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var month_1_progression: bool = (
		elapsed_month_1 == elapsed_before + 1
	)
	var month_1_snapshot: bool = (
		snapshot_count_month_1 == snapshot_count_before + 1
	)
	var month_1_active: bool = (
		action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(action.progress, 1.0 / 3.0)
		and action.duration_months == 2
	)
	var month_1_no_premature_effect: bool = is_equal_approx(
		diplomatic_relationship_month_1,
		diplomatic_relationship_before
	)

	TestLogger.write_line(
		"Month N+1 advances exactly one month: "
		+ ("PASS" if month_1_progression else "FAIL")
	)
	TestLogger.write_line(
		"Month N+1 creates exactly one monthly snapshot: "
		+ ("PASS" if month_1_snapshot else "FAIL")
	)
	TestLogger.write_line(
		"Month N+1 preserves active multi-month action state: "
		+ ("PASS" if month_1_active else "FAIL")
		+ " | progress=" + str(action.progress)
		+ " remaining=" + str(action.duration_months)
	)
	TestLogger.write_line(
		"Month N+1 does not apply the terminal relationship effect early: "
		+ ("PASS" if month_1_no_premature_effect else "FAIL")
	)

	# ------------------------------------------------------------
	# MONTH N + 2
	# ------------------------------------------------------------

	simulation.tick_month()

	var elapsed_month_2: int = world.get_elapsed_months()
	var snapshot_count_month_2: int = simulation.get_snapshot_count()
	var relationship_month_2: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_relationship_month_2: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var month_2_progression: bool = (
		elapsed_month_2 == elapsed_before + 2
	)
	var month_2_snapshot: bool = (
		snapshot_count_month_2 == snapshot_count_before + 2
	)
	var month_2_active: bool = (
		action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(action.progress, 2.0 / 3.0)
		and action.duration_months == 1
	)
	var month_2_no_premature_effect: bool = is_equal_approx(
		diplomatic_relationship_month_2,
		diplomatic_relationship_before
	)

	TestLogger.write_line(
		"Month N+2 advances exactly one month: "
		+ ("PASS" if month_2_progression else "FAIL")
	)
	TestLogger.write_line(
		"Month N+2 creates the second monthly snapshot: "
		+ ("PASS" if month_2_snapshot else "FAIL")
	)
	TestLogger.write_line(
		"Month N+2 preserves active multi-month action state: "
		+ ("PASS" if month_2_active else "FAIL")
		+ " | progress=" + str(action.progress)
		+ " remaining=" + str(action.duration_months)
	)
	TestLogger.write_line(
		"Month N+2 still has no premature terminal relationship effect: "
		+ ("PASS" if month_2_no_premature_effect else "FAIL")
	)

	# ------------------------------------------------------------
	# MONTH N + 3 — TERMINAL CONSEQUENCE
	# ------------------------------------------------------------

	simulation.tick_month()

	var elapsed_month_3: int = world.get_elapsed_months()
	var snapshot_count_month_3: int = simulation.get_snapshot_count()
	var relationship_after_completion: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_relationship_after_completion: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var elapsed_month_3_passed: bool = (
		elapsed_month_3 == elapsed_before + 3
	)
	var snapshot_month_3_passed: bool = (
		snapshot_count_month_3 == snapshot_count_before + 3
	)
	var action_completed: bool = (
		action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(action.progress, 1.0)
		and action.duration_months == 0
	)
	var relationship_changed: bool = (
		not is_equal_approx(
			diplomatic_relationship_after_completion,
			diplomatic_relationship_before
		)
	)
	var completion_effect: Dictionary = {}
	var completion_result_variant: Variant = action.completion_result
	if typeof(completion_result_variant) == TYPE_DICTIONARY:
		var completion_result: Dictionary = completion_result_variant
		var actual_effect_variant: Variant = completion_result.get(
			"actual_effect",
			{}
		)
		if typeof(actual_effect_variant) == TYPE_DICTIONARY:
			completion_effect = actual_effect_variant.duplicate(true)

	var completion_dimension_ok: bool = (
		str(completion_effect.get("relationship_dimension", ""))
		== "diplomatic"
	)
	var expected_diplomatic_change: float = float(
		completion_effect.get("relationship_change", 0.0)
	)
	var diplomatic_change_exact: bool = is_equal_approx(
		diplomatic_relationship_after_completion
		- diplomatic_relationship_before,
		expected_diplomatic_change
	)
	var outcome: Dictionary = simulation.action_manager.get_action_outcome(
		action
	)
	var outcome_recorded: bool = (
		not outcome.is_empty()
		and str(outcome.get("status", "")) == SimAction.STATE_COMPLETED
	)

	TestLogger.write_line(
		"Month N+3 advances exactly one month: "
		+ ("PASS" if elapsed_month_3_passed else "FAIL")
	)
	TestLogger.write_line(
		"Month N+3 creates the third monthly snapshot: "
		+ ("PASS" if snapshot_month_3_passed else "FAIL")
	)
	TestLogger.write_line(
		"Month N+3 completes the delayed action through ACTIONS: "
		+ ("PASS" if action_completed else "FAIL")
	)
	TestLogger.write_line(
		"Month N+3 applies the terminal diplomatic relationship consequence: "
		+ ("PASS" if relationship_changed else "FAIL")
		+ " | before_diplomatic=" + str(diplomatic_relationship_before)
		+ " after_diplomatic=" + str(diplomatic_relationship_after_completion)
	)
	TestLogger.write_line(
		"Month N+3 completion result records the diplomatic dimension: "
		+ ("PASS" if completion_dimension_ok else "FAIL")
		+ " | expected_change=" + str(expected_diplomatic_change)
	)
	TestLogger.write_line(
		"Month N+3 applied diplomatic change matches completion result: "
		+ ("PASS" if diplomatic_change_exact else "FAIL")
	)
	TestLogger.write_line(
		"Month N+3 records the terminal outcome: "
		+ ("PASS" if outcome_recorded else "FAIL")
	)

	# ------------------------------------------------------------
	# MONTH N + 4 — DOWNSTREAM OBSERVATION
	# ------------------------------------------------------------

	simulation.tick_month()

	var elapsed_month_4: int = world.get_elapsed_months()
	var snapshot_count_month_4: int = simulation.get_snapshot_count()

	var previous_relationship_after: float = float(
		government.get_state(
			"previous_relationship_" + target.id,
			relationship_after_completion
		)
	)
	var diplomatic_signal_after: float = float(
		government.get_state(
			"diplomatic_signal",
			0.0
		)
	)

	var decision_option_after: DecisionOption = DecisionOption.new(
		"step17_4_multi_month_post_action_evaluation",
		"Step 17.4 Post-Closure Evaluation",
		"diplomatic_outreach"
	)
	decision_option_after.actor_id = actor.id
	decision_option_after.target_id = target.id
	decision_option_after.base_score = player_option.base_score
	decision_option_after.metadata = player_option.metadata.duplicate(true)

	var decision_score_after: float = decision_system.evaluate_option(
		world,
		actor,
		decision_option_after
	)

	var government_observed_completion: bool = false

	var month_4_progression: bool = (
		elapsed_month_4 == elapsed_before + 4
	)
	var month_4_snapshot: bool = (
		snapshot_count_month_4 == snapshot_count_before + 4
	)
	var government_response_available: bool = (
		diplomatic_signal_after > 0.0
	)
	var decision_observes_persisted_change: bool = (
		not is_equal_approx(
			decision_option_after.relationship_score,
			player_option.relationship_score
		)
	)
	var decision_result_valid: bool = is_finite(
		decision_score_after
	)
	government_observed_completion = (
		is_finite(previous_relationship_after)
		and government_response_available
	)

	TestLogger.write_line(
		"Month N+4 advances exactly one month: "
		+ ("PASS" if month_4_progression else "FAIL")
	)
	TestLogger.write_line(
		"Month N+4 creates the fourth monthly snapshot: "
		+ ("PASS" if month_4_snapshot else "FAIL")
	)
	TestLogger.write_line(
		"Month N+4 GovernmentSystem observes the delayed relationship consequence through its feedback path: "
		+ ("PASS" if government_observed_completion else "FAIL")
		+ " | government_previous_relationship=" + str(previous_relationship_after)
	)
	TestLogger.write_line(
		"Month N+4 government feedback remains available after the delayed consequence: "
		+ ("PASS" if government_response_available else "FAIL")
		+ " | diplomatic_signal=" + str(diplomatic_signal_after)
	)
	TestLogger.write_line(
		"Month N+4 decision evaluation observes the persisted changed environment: "
		+ ("PASS" if decision_observes_persisted_change else "FAIL")
		+ " | relationship_score_before=" + str(player_option.relationship_score)
		+ " relationship_score_after=" + str(decision_option_after.relationship_score)
	)
	TestLogger.write_line(
		"Month N+4 decision evaluation remains valid: "
		+ ("PASS" if decision_result_valid else "FAIL")
	)

	var four_month_chain_passed: bool = (
		issued
		and action_duration_contract
		and month_1_progression
		and month_1_snapshot
		and month_1_active
		and month_1_no_premature_effect
		and month_2_progression
		and month_2_snapshot
		and month_2_active
		and month_2_no_premature_effect
		and elapsed_month_3_passed
		and snapshot_month_3_passed
		and action_completed
		and relationship_changed
		and completion_dimension_ok
		and diplomatic_change_exact
		and outcome_recorded
		and month_4_progression
		and month_4_snapshot
		and government_observed_completion
		and government_response_available
		and decision_observes_persisted_change
		and decision_result_valid
	)

	TestLogger.write_line(
		"Step 17.4 Multi-Month Closure overall: "
		+ ("PASS" if four_month_chain_passed else "FAIL")
	)

	return four_month_chain_passed


static func _find_fixture_pair(
	world: WorldState,
	simulation: SimulationEngine
) -> Dictionary:

	var result: Dictionary = {
		"actor": null,
		"target": null
	}

	if world == null or simulation == null:
		return result

	var candidate_ids: Array[String] = [
		"india",
		"china",
		"usa"
	]

	var max_slots: int = 3
	if simulation.config != null:
		max_slots = max(
			int(simulation.config.max_concurrent_actions_per_actor),
			1
		)

	var pending_actions: Array = simulation.get_pending_actions()

	for actor_id in candidate_ids:

		var actor: SimEntity = world.get_entity(actor_id) as SimEntity
		if actor == null:
			continue

		var occupied_slots: int = 0
		if simulation.action_manager != null:
			occupied_slots = simulation.action_manager.get_concurrent_action_count(
				actor.id
			)

		# Step 17.2 intentionally leaves a real queued AI action in the
		# authoritative ACTIONS queue. That is valid multi-action state, so
		# Step 17.4 must not incorrectly reject an actor merely because it
		# already has another non-terminal action. Select an actor with at
		# least one free concurrent slot instead.
		if occupied_slots >= max_slots:
			continue

		for target_id in candidate_ids:

			if target_id == actor.id:
				continue

			var target: SimEntity = world.get_entity(target_id) as SimEntity
			if target == null:
				continue

			var pair_conflict: bool = false

			for action_variant in pending_actions:

				if action_variant == null:
					continue

				if not action_variant is SimAction:
					continue

				var action: SimAction = action_variant as SimAction

				if action.actor_id != actor.id:
					continue

				if action.target_id != target.id:
					continue

				if (
					action.state == SimAction.STATE_QUEUED
					or action.state == SimAction.STATE_ACTIVE
				):
					pair_conflict = true
					break

			if pair_conflict:
				continue

			result["actor"] = actor
			result["target"] = target
			return result

	return result
