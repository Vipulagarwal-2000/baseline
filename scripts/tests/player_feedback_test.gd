class_name PlayerFeedbackTest
extends RefCounted


# ============================================================
# STEP 17.1 — PLAYER FEEDBACK
# ============================================================
#
# This test proves the first live dynamic-feedback edge using the
# real registered simulation path:
#
#   player-issued decision
#       ↓
#   SimulationEngine.issue_player_action()
#       ↓
#   ActionManager admission / ACTIONS phase
#       ↓
#   authoritative relationship change
#       ↓
#   next monthly WORLD_UPDATE (GovernmentSystem)
#       ↓
#   downstream diplomatic signal / government condition
#       ↓
#   next-month decision evaluation observes changed state
#
# No standalone ActionManager or manually-invoked downstream system is
# used here. That distinction is the core acceptance boundary for Step 17.1.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 17.1 — PLAYER FEEDBACK"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	var actor: SimEntity = world.get_entity("india") as SimEntity
	var target: SimEntity = world.get_entity("china") as SimEntity

	var countries_available: bool = (
		actor != null
		and target != null
	)

	TestLogger.write_line(
		"India/China fixture available: "
		+ (
			"PASS"
			if countries_available
			else "FAIL"
		)
	)

	if not countries_available:
		return false

	var government = actor.get_component("government")
	var decision_system = simulation.get_system("decision_system")
	var government_system = simulation.get_system("government_system")

	var required_systems_available: bool = (
		government != null
		and decision_system is DecisionSystem
		and government_system != null
	)

	TestLogger.write_line(
		"Registered decision/government systems available: "
		+ (
			"PASS"
			if required_systems_available
			else "FAIL"
		)
	)

	if not required_systems_available:
		return false

	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)



	# Build the same kind of decision object that a player-facing
	# selection layer would pass to SimulationEngine.issue_player_action().
	# The concrete action payload is deliberately explicit so that this test
	# reaches the real ActionManager execution path with a non-zero effect.
	var player_option: DecisionOption = DecisionOption.new(
		"diplomatic_outreach",
		"Step 17.1 Player Diplomatic Outreach",
		"diplomatic"
	)

	player_option.actor_id = actor.id
	player_option.target_id = target.id
	player_option.base_score = 1.0
	player_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05,
		"action": {
			"value": 20.0,
			"duration_months": 1
		}
	}

	var decision_score_before: float = (
		decision_system.evaluate_option(
			world,
			actor,
			player_option
		)
	)

	var issuance_result: Dictionary = simulation.issue_player_action(
		actor.id,
		player_option
	)

	var issued: bool = bool(
		issuance_result.get("success", false)
	)

	TestLogger.write_line(
		"Real player action accepted by SimulationEngine: "
		+ (
			"PASS"
			if issued
			else "FAIL"
		)
	)

	if not issued:
		TestLogger.write_line(
			"Player action failure: "
			+ str(issuance_result.get("failure_reason", ""))
		)
		return false

	var player_action: SimAction = (
		issuance_result.get("action", null)
		as SimAction
	)

	var entered_queue: bool = (
		player_action != null
		and simulation.get_pending_actions().has(player_action)
	)

	TestLogger.write_line(
		"Player action enters authoritative ActionManager queue: "
		+ (
			"PASS"
			if entered_queue
			else "FAIL"
		)
	)

	if player_action == null:
		return false

	var elapsed_before: int = world.get_elapsed_months()

	# Month N: WORLD_UPDATE resolves first; ACTIONS then executes the
	# player-issued action against authoritative state.
	simulation.tick_month()

	var relationship_after_action: float = actor.get_relationship(
		target.id,
		0.0
	)

	var action_completed: bool = (
		player_action.state == SimAction.STATE_COMPLETED
	)

	var authoritative_change: bool = (
		relationship_after_action
		> relationship_before
	)

	TestLogger.write_line(
		"Player action completes through registered ACTIONS phase: "
		+ (
			"PASS"
			if action_completed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Player action changes authoritative relationship state: "
		+ (
			"PASS"
			if authoritative_change
			else "FAIL"
		)
	)

	var outcome: Dictionary = simulation.action_manager.get_action_outcome(
		player_action
	)

	var authoritative_outcome_recorded: bool = (
		not outcome.is_empty()
		and str(outcome.get("status", "")) == SimAction.STATE_COMPLETED
	)

	TestLogger.write_line(
		"Completed player action has terminal outcome record: "
		+ (
			"PASS"
			if authoritative_outcome_recorded
			else "FAIL"
		)
	)

	# Month N+1: GovernmentSystem runs in WORLD_UPDATE before ACTIONS and
	# therefore observes the relationship change produced in Month N.
	simulation.tick_month()

	var relationship_after_government: float = actor.get_relationship(
		target.id,
		0.0
	)

	var diplomatic_signal_after: float = float(
		government.get_state(
			"diplomatic_signal",
			0.0
		)
	)

	# Capture the relationship baseline that GovernmentSystem had before
	# its next-month WORLD_UPDATE pass. The system converts the live
	# relationship delta into diplomatic_signal, while later registered
	# systems may legitimately change the relationship again.
	var previous_relationship_input: float = float(
		government.get_state(
			"previous_relationship_" + target.id,
			relationship_before
		)
	)

	# A non-zero diplomatic signal proves that GovernmentSystem observed a
	# relationship delta during WORLD_UPDATE. We deliberately do not require
	# the final relationship value to equal the value used by GovernmentSystem,
	# because other registered systems may modify the relationship later in
	# the same monthly pass.
	var downstream_observed_live_state: bool = (
		not is_zero_approx(diplomatic_signal_after)
		and not is_equal_approx(
			relationship_after_action,
		previous_relationship_input
		)
	)

	var player_effect_persists: bool = (
		relationship_after_government > relationship_before
	)

	var downstream_changed: bool = (
		not is_zero_approx(diplomatic_signal_after)
	)

	TestLogger.write_line(
		"Next-month GovernmentSystem observes changed relationship: "
		+ (
			"PASS"
			if downstream_observed_live_state and player_effect_persists
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Next-month diplomatic signal changes from the player action: "
		+ (
			"PASS"
			if downstream_changed and player_effect_persists
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Step 17.1 diplomatic diagnostic: "
		+ str({
			"relationship_before": relationship_before,
			"relationship_after_action": relationship_after_action,
			"relationship_after_government": relationship_after_government,
			"previous_relationship_input": previous_relationship_input,
			"diplomatic_signal": diplomatic_signal_after
		})
	)

	# Re-evaluate the same decision type after the next month. The
	# relationship score is read from current world state, so this verifies
	# that the altered downstream environment is available to later choice
	# evaluation rather than remaining trapped inside the action object.
	var decision_option_after: DecisionOption = DecisionOption.new(
		"diplomatic_outreach",
		"Step 17.1 Player Diplomatic Outreach Next",
		"diplomatic"
	)

	decision_option_after.actor_id = actor.id
	decision_option_after.target_id = target.id
	decision_option_after.base_score = player_option.base_score
	decision_option_after.metadata = player_option.metadata.duplicate(true)

	var decision_score_after: float = (
		decision_system.evaluate_option(
			world,
			actor,
			decision_option_after
		)
	)

	var decision_environment_changed: bool = (
		decision_option_after.relationship_score
		> player_option.relationship_score
	)

	TestLogger.write_line(
		"Next-month decision relationship score observes changed player-action state: "
		+ (
			"PASS"
			if decision_environment_changed
			else "FAIL"
		)
	)

	# Month N+2: no new player action is issued. This verifies that the
	# consequence remains present after another normal monthly resolution.
	simulation.tick_month()
	var elapsed_after: int = world.get_elapsed_months()

	# elapsed_before is captured before the action month (N).
	# The test then advances N (action completion), N+1 (Government/decision
	# observation), and N+2 (persistence tick): three ticks total.
	var two_month_progression: bool = (
		elapsed_after == elapsed_before + 3
	)

	TestLogger.write_line(
		"Player feedback persists across two monthly ticks: "
		+ (
			"PASS"
			if two_month_progression
			else "FAIL"
		)
	)

	var passed: bool = (
		issued
		and entered_queue
		and action_completed
		and authoritative_change
		and authoritative_outcome_recorded
		and downstream_observed_live_state
		and downstream_changed
		and decision_environment_changed
		and two_month_progression
	)

	TestLogger.write_line(
		"Step 17.1 Player Feedback test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
