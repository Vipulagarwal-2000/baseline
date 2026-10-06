class_name ActionAIFeedbackTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.13 — AI FEEDBACK TEST"
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

	var actor = world.get_entity(
		"india"
	)

	var target = world.get_entity(
		"china"
	)

	if actor == null or target == null:
		TestLogger.write_line(
			"India/China fixture available: FAIL"
		)
		return false

	var memory_system = simulation.get_system(
		"ai_memory_system"
	)

	if memory_system == null:
		memory_system = AIMemorySystem.new()
		simulation.register_system(
			memory_system,
			SimulationPhase.DECISIONS,
			30
		)

	var trajectory_system = simulation.get_system(
		"decision_trajectory_system"
	)

	if trajectory_system == null:
		trajectory_system = DecisionTrajectorySystem.new()
		simulation.register_system(
			trajectory_system,
			SimulationPhase.DECISIONS,
			31
		)

	var decision_system = simulation.get_system(
		"decision_system"
	)

	if decision_system == null:
		decision_system = DecisionSystem.new()
		simulation.register_system(
			decision_system,
			SimulationPhase.DECISIONS,
			20
		)

	# Preserve the shared simulation's transient action execution state.
	# This legacy feedback fixture advances one real monthly tick; Step 17.2
	# may automatically admit new AI actions during that tick. Those actions
	# must not leak into the following Step 15 fixtures.
	var baseline_action_snapshot: Dictionary = (
		simulation.action_manager.capture_snapshot_state()
	)
	var baseline_outcomes: Array = simulation.action_manager.outcome_history.duplicate(true)
	var baseline_outcome_index: Dictionary = simulation.action_manager.outcome_index.duplicate(true)
	var baseline_pending_count: int = simulation.action_manager.get_pending_count()
	var baseline_reservation_count: int = simulation.action_manager.get_reservation_count()

	var trajectory_fixture: DecisionTrajectory = DecisionTrajectory.new(
		"feedback_diplomatic_china",
		"India-China diplomatic feedback",
		"diplomatic"
	)

	trajectory_fixture.actor_id = actor.id
	trajectory_fixture.target_id = target.id
	trajectory_fixture.value = 0.5

	var trajectory_added: bool = (
		trajectory_system.add_trajectory(
			actor,
			trajectory_fixture
		)
	)

	TestLogger.write_line(
		"Matching decision trajectory created: "
		+ (
			"PASS"
			if trajectory_added
			else "FAIL"
		)
	)

	var option_before: DecisionOption = DecisionOption.new(
		"feedback_diplomatic_outreach",
		"Feedback Diplomatic Outreach",
		"diplomatic"
	)

	option_before.actor_id = actor.id
	option_before.target_id = target.id
	option_before.base_score = 1.0
	option_before.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var score_before: float = (
		decision_system.evaluate_option(
			world,
			actor,
			option_before
		)
	)

	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)

	# Decision evaluation remains category-level; execution uses the supported concrete action type.
	var action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		10.0,
		1
	)

	var submitted: bool = simulation.add_action(
		action
	)

	simulation.tick_month()

	var outcome: Dictionary = simulation.action_manager.get_action_outcome(
		action
	)

	var action_completed: bool = (
		submitted
		and action.state == SimAction.STATE_COMPLETED
		and not outcome.is_empty()
	)

	TestLogger.write_line(
		"Completed action produces authoritative outcome: "
		+ (
			"PASS"
			if action_completed
			else "FAIL"
		)
	)

	var memory_entries: Array = (
		memory_system.get_action_outcome_memories(
			actor
		)
	)

	var memory_has_action: bool = false

	for memory_variant in memory_entries:
		if typeof(memory_variant) != TYPE_DICTIONARY:
			continue

		var memory_entry: Dictionary = memory_variant
		var action_id_value: Variant = memory_entry.get(
			"action_id",
			-1
		)

		if typeof(action_id_value) == TYPE_INT:
			if int(action_id_value) == action.get_instance_id():
				memory_has_action = true
				break

	TestLogger.write_line(
		"AI memory receives completed action outcome: "
		+ (
			"PASS"
			if memory_has_action
			else "FAIL"
		)
	)

	var trajectory_feedback: Array = (
		trajectory_system.get_action_outcome_feedback(
			actor
		)
	)

	var trajectory_has_action: bool = false

	for feedback_variant in trajectory_feedback:
		if typeof(feedback_variant) != TYPE_DICTIONARY:
			continue

		var feedback: Dictionary = feedback_variant
		var action_id_value: Variant = feedback.get(
			"action_id",
			-1
		)

		if typeof(action_id_value) == TYPE_INT:
			if int(action_id_value) == action.get_instance_id():
				trajectory_has_action = true
				break

	TestLogger.write_line(
		"Decision trajectory receives action outcome feedback: "
		+ (
			"PASS"
			if trajectory_has_action
			else "FAIL"
		)
	)

	var relationship_after: float = actor.get_relationship(
		target.id,
		0.0
	)

	var option_after: DecisionOption = DecisionOption.new(
		"feedback_diplomatic_outreach_next",
		"Feedback Diplomatic Outreach Next",
		"diplomatic"
	)

	option_after.actor_id = actor.id
	option_after.target_id = target.id
	option_after.base_score = 1.0
	option_after.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var score_after: float = (
		decision_system.evaluate_option(
			world,
			actor,
			option_after
		)
	)

	var relationship_changed: bool = (
		relationship_after != relationship_before
	)

	var decision_re_evaluated: bool = (
		not is_equal_approx(
			score_after,
			score_before
		)
	)

	TestLogger.write_line(
		"Authoritative world state changed from action: "
		+ (
			"PASS"
			if relationship_changed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Next decision evaluation observes changed world state: "
		+ (
			"PASS"
			if decision_re_evaluated
			else "FAIL"
		)
	)

	var memory_count_before_duplicate: int = (
		memory_system.get_action_outcome_memories(
			actor
		).size()
	)

	var trajectory_count_before_duplicate: int = (
		trajectory_system.get_action_outcome_feedback(
			actor
		).size()
	)

	simulation.process_action_feedback()

	var memory_count_after_duplicate: int = (
		memory_system.get_action_outcome_memories(
			actor
		).size()
	)

	var trajectory_count_after_duplicate: int = (
		trajectory_system.get_action_outcome_feedback(
			actor
		).size()
	)

	var duplicate_feedback_blocked: bool = (
		memory_count_before_duplicate
		== memory_count_after_duplicate
		and trajectory_count_before_duplicate
		== trajectory_count_after_duplicate
	)

	TestLogger.write_line(
		"Repeated feedback processing is idempotent: "
		+ (
			"PASS"
			if duplicate_feedback_blocked
			else "FAIL"
		)
	)

	var passed: bool = (
		trajectory_added
		and action_completed
		and memory_has_action
		and trajectory_has_action
		and relationship_changed
		and decision_re_evaluated
		and duplicate_feedback_blocked
	)

	# Restore only transient action/history state. The verified AI feedback
	# records remain in their dedicated systems; the shared ActionManager
	# returns to exactly the state it had before this test.
	simulation.action_manager.restore_snapshot_state(
		baseline_action_snapshot,
		world
	)
	simulation.action_manager.outcome_history = baseline_outcomes
	simulation.action_manager.outcome_index = baseline_outcome_index

	var restoration_passed: bool = (
		simulation.action_manager.get_pending_count() == baseline_pending_count
		and simulation.action_manager.get_reservation_count() == baseline_reservation_count
		and simulation.action_manager.get_outcome_count() == baseline_outcomes.size()
	)

	TestLogger.write_line(
		"Step 15.13 transient action state restores exactly: "
		+ ("PASS" if restoration_passed else "FAIL")
	)

	passed = passed and restoration_passed

	TestLogger.write_line(
		"Step 15.13 AI Feedback test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
