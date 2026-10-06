class_name AIFeedbackStep17_2Test
extends RefCounted


# ============================================================
# STEP 17.2 — AI FEEDBACK
# ============================================================
#
# Real monthly chain:
#
#   DECISIONS
#       ↓
#   AIDecisionSystem selects an option
#       ↓
#   SimulationEngine.process_ai_action_issuance()
#       ↓
#   ActionManager queue
#       ↓
#   next-month ACTIONS phase
#       ↓
#   authoritative world-state change
#       ↓
#   process_action_feedback()
#       ↓
#   AI memory / decision trajectory
#       ↓
#   next DECISIONS phase
#       ↓
#   new AI action for the changed environment
#
# This test does not construct a second AI executor and does not manually
# execute ActionManager or domain systems.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 17.2 — AI FEEDBACK"
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
		"India/China AI fixture available: "
		+ (
			"PASS"
			if countries_available
			else "FAIL"
		)
	)

	if not countries_available:
		return false

	var ai_system = simulation.get_system(
		"ai_decision_system"
	)
	var decision_system = simulation.get_system(
		"decision_system"
	)
	var memory_system = simulation.get_system(
		"ai_memory_system"
	)
	var trajectory_system = simulation.get_system(
		"decision_trajectory_system"
	)

	var systems_available: bool = (
		ai_system is AIDecisionSystem
		and decision_system is DecisionSystem
		and memory_system is AIMemorySystem
		and trajectory_system is DecisionTrajectorySystem
	)

	TestLogger.write_line(
		"Registered AI feedback systems available: "
		+ (
			"PASS"
			if systems_available
			else "FAIL"
		)
	)

	if not systems_available:
		return false

	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)

	var elapsed_before: int = world.get_elapsed_months()

	# First real monthly tick:
	# DecisionSystem prepares the live options.
	# AIDecisionSystem selects one.
	# SimulationEngine automatically admits the selected AI action after
	# the DECISIONS phase for execution on the next monthly tick.
	simulation.tick_month()

	var pending_actions_after_decision: Array = (
		simulation.get_pending_actions()
	)

	var first_ai_action: SimAction = null

	for action_variant in pending_actions_after_decision:
		if action_variant == null:
			continue

		if not action_variant is SimAction:
			continue

		var candidate: SimAction = action_variant as SimAction

		if candidate.actor_id != actor.id:
			continue

		first_ai_action = candidate
		break

	var ai_action_issued: bool = (
		first_ai_action != null
		and first_ai_action.state == SimAction.STATE_QUEUED
		and not str(first_ai_action.action_type).is_empty()
	)

	TestLogger.write_line(
		"Real AI decision automatically enters ActionManager queue: "
		+ (
			"PASS"
			if ai_action_issued
			else "FAIL"
		)
	)

	if not ai_action_issued:
		return false

	var ai_action_type: String = first_ai_action.action_type
	var ai_action_target: String = first_ai_action.target_id
	var ai_action_id: int = first_ai_action.get_instance_id()

	TestLogger.write_line(
		"Queued AI action type: "
		+ ai_action_type
	)

	TestLogger.write_line(
		"Queued AI action target: "
		+ ai_action_target
	)

	# Capture the current evaluation of the same decision category before
	# the queued action executes. This is the environment that the next
	# AI decision must react to.
	var decision_category: String = _normalize_action_category(
		ai_action_type
	)

	var decision_before: DecisionOption = DecisionOption.new(
		"step17_2_pre_action_evaluation",
		"Step 17.2 Pre-Action Evaluation",
		decision_category
	)

	decision_before.actor_id = actor.id
	decision_before.target_id = ai_action_target
	decision_before.base_score = 1.0
	decision_before.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var score_before: float = decision_system.evaluate_option(
		world,
		actor,
		decision_before
	)

	var relationship_score_before: float = (
		decision_before.relationship_score
	)

	# Second real monthly tick:
	# ACTIONS resolves the previously queued AI action.
	# process_action_feedback() records the terminal outcome.
	# DECISIONS then evaluates the changed world and issues the next AI
	# action during the same normal monthly cycle.
	simulation.tick_month()

	var relationship_after: float = actor.get_relationship(
		target.id,
		0.0
	)

	var first_action_completed: bool = (
		first_ai_action.state == SimAction.STATE_COMPLETED
	)

	var relationship_changed: bool = (
		not is_equal_approx(
			relationship_after,
			relationship_before
		)
	)

	TestLogger.write_line(
		"AI action completes through registered ACTIONS phase: "
		+ (
			"PASS"
			if first_action_completed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"AI action changes authoritative world state: "
		+ (
			"PASS"
			if relationship_changed
			else "FAIL"
		)
	)

	var outcome: Dictionary = simulation.action_manager.get_action_outcome(
		first_ai_action
	)

	var outcome_recorded: bool = (
		not outcome.is_empty()
		and str(outcome.get("status", "")) == SimAction.STATE_COMPLETED
	)

	TestLogger.write_line(
		"AI action has terminal outcome record: "
		+ (
			"PASS"
			if outcome_recorded
			else "FAIL"
		)
	)

	var memory_entries: Array = memory_system.get_action_outcome_memories(
		actor
	)

	var memory_has_action: bool = _contains_action_id(
		memory_entries,
		ai_action_id
	)

	TestLogger.write_line(
		"AI memory receives completed action outcome: "
		+ (
			"PASS"
			if memory_has_action
			else "FAIL"
		)
	)

	var trajectory_feedback: Array = trajectory_system.get_action_outcome_feedback(
		actor
	)

	var trajectory_has_action: bool = _contains_action_id(
		trajectory_feedback,
		ai_action_id
	)

	TestLogger.write_line(
		"Decision trajectory receives AI action outcome feedback: "
		+ (
			"PASS"
			if trajectory_has_action
			else "FAIL"
		)
	)

	# The second DECISIONS phase must have created a new executable AI
	# action after observing the changed world. It must not be the same
	# action instance.
	var pending_actions_after_feedback: Array = (
		simulation.get_pending_actions()
	)

	var next_ai_action: SimAction = null

	for action_variant in pending_actions_after_feedback:
		if action_variant == null:
			continue

		if not action_variant is SimAction:
			continue

		var candidate: SimAction = action_variant as SimAction

		if candidate.actor_id != actor.id:
			continue

		if candidate.get_instance_id() == ai_action_id:
			continue

		next_ai_action = candidate
		break

	var next_ai_action_issued: bool = (
		next_ai_action != null
		and next_ai_action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"Next AI decision produces a new queued action: "
		+ (
			"PASS"
			if next_ai_action_issued
			else "FAIL"
		)
	)

	var decision_after: DecisionOption = DecisionOption.new(
		"step17_2_post_action_evaluation",
		"Step 17.2 Post-Action Evaluation",
		decision_category
	)

	decision_after.actor_id = actor.id
	decision_after.target_id = ai_action_target
	decision_after.base_score = 1.0
	decision_after.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var score_after: float = decision_system.evaluate_option(
		world,
		actor,
		decision_after
	)

	var relationship_score_after: float = (
		decision_after.relationship_score
	)

	var decision_environment_changed: bool = (
		not is_equal_approx(
			relationship_score_after,
			relationship_score_before
		)
	)

	TestLogger.write_line(
		"Next decision evaluation observes the changed AI world state: "
		+ (
			"PASS"
			if decision_environment_changed
			else "FAIL"
		)
	)

	var elapsed_after: int = world.get_elapsed_months()

	var two_month_feedback_chain: bool = (
		elapsed_after == elapsed_before + 2
	)

	TestLogger.write_line(
		"AI feedback persists across the two-tick action/response chain: "
		+ (
			"PASS"
			if two_month_feedback_chain
			else "FAIL"
		)
	)

	var passed: bool = (
		ai_action_issued
		and first_action_completed
		and relationship_changed
		and outcome_recorded
		and memory_has_action
		and trajectory_has_action
		and next_ai_action_issued
		and decision_environment_changed
		and two_month_feedback_chain
	)

	TestLogger.write_line(
		"Step 17.2 AI Feedback test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed


static func _normalize_action_category(
	action_type: String
) -> String:

	match action_type:
		"diplomatic_outreach":
			return "diplomatic"

		"expand_trade":
			return "economic"

		_:
			return action_type


static func _contains_action_id(
	entries: Array,
	action_id: int
) -> bool:

	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		var value: Variant = entry.get(
			"action_id",
			-1
		)

		if typeof(value) == TYPE_INT:
			if int(value) == action_id:
				return true

	return false
