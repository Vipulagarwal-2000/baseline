class_name ActionValidationTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.4 — ACTION VALIDATION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var test_config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(test_config)

	var actor: SimEntity = SimEntity.new(
		"step15_4_actor",
		"Step 15.4 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_4_target",
		"Step 15.4 Target",
		"country"
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = isolated_simulation.action_manager

	var manager_available: bool = manager != null
	TestLogger.write_line(
		"ActionManager available: "
		+ ("PASS" if manager_available else "FAIL")
	)

	# ------------------------------------------------------------
	# VALID ACTION
	# ------------------------------------------------------------

	var valid_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		5.0,
		1
	)
	valid_action.cost = 0.0

	var valid_result: bool = isolated_simulation.add_action(valid_action)
	var valid_action_pass: bool = (
		valid_result
		and valid_action.failure_reason.is_empty()
		and valid_action.state == SimAction.STATE_QUEUED
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Valid action passes structural validation and enters queue: "
		+ ("PASS" if valid_action_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# INVALID ACTOR
	# ------------------------------------------------------------

	var missing_actor_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		"missing_actor",
		target.id,
		5.0,
		1
	)
	var missing_actor_result: bool = isolated_simulation.add_action(
		missing_actor_action
	)
	var missing_actor_pass: bool = (
		not missing_actor_result
		and missing_actor_action.state == SimAction.STATE_FAILED
		and missing_actor_action.failure_reason
			== "Action validation failed: actor does not exist: missing_actor"
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Missing actor is rejected with explicit failure reason: "
		+ ("PASS" if missing_actor_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# INVALID TARGET
	# ------------------------------------------------------------

	var missing_target_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		"missing_target",
		5.0,
		1
	)
	var missing_target_result: bool = isolated_simulation.add_action(
		missing_target_action
	)
	var missing_target_pass: bool = (
		not missing_target_result
		and missing_target_action.state == SimAction.STATE_FAILED
		and missing_target_action.failure_reason
			== "Action validation failed: target does not exist: missing_target"
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Missing target is rejected with explicit failure reason: "
		+ ("PASS" if missing_target_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# INVALID ACTION TYPE
	# ------------------------------------------------------------

	var missing_type_action: SimAction = SimAction.new(
		"",
		actor.id,
		target.id,
		5.0,
		1
	)
	var missing_type_result: bool = isolated_simulation.add_action(
		missing_type_action
	)
	var missing_type_pass: bool = (
		not missing_type_result
		and missing_type_action.state == SimAction.STATE_FAILED
		and missing_type_action.failure_reason
			== "Action validation failed: action type is required."
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Missing action type is rejected with explicit failure reason: "
		+ ("PASS" if missing_type_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# INVALID DURATION
	# ------------------------------------------------------------

	var invalid_duration_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		5.0,
		0
	)
	var invalid_duration_result: bool = isolated_simulation.add_action(
		invalid_duration_action
	)
	var invalid_duration_pass: bool = (
		not invalid_duration_result
		and invalid_duration_action.state == SimAction.STATE_FAILED
		and invalid_duration_action.failure_reason
			== "Action validation failed: duration must be greater than zero."
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Non-positive duration is rejected with explicit failure reason: "
		+ ("PASS" if invalid_duration_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# INVALID COST
	# ------------------------------------------------------------

	var invalid_cost_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		5.0,
		1
	)
	invalid_cost_action.cost = -1.0
	var invalid_cost_result: bool = isolated_simulation.add_action(
		invalid_cost_action
	)
	var invalid_cost_pass: bool = (
		not invalid_cost_result
		and invalid_cost_action.state == SimAction.STATE_FAILED
		and invalid_cost_action.failure_reason
			== "Action validation failed: cost cannot be negative."
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Negative cost is rejected with explicit failure reason: "
		+ ("PASS" if invalid_cost_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# OPTIONAL TARGET CONTRACT
	# ------------------------------------------------------------

	var no_target_action: SimAction = SimAction.new(
		"economic_policy",
		actor.id,
		"",
		1.0,
		1
	)
	var no_target_result: bool = isolated_simulation.add_action(no_target_action)
	var no_target_pass: bool = (
		no_target_result
		and no_target_action.failure_reason.is_empty()
		and no_target_action.state == SimAction.STATE_QUEUED
		and isolated_simulation.get_pending_action_count() == 2
	)

	TestLogger.write_line(
		"Empty target remains valid for targetless action contracts: "
		+ ("PASS" if no_target_pass else "FAIL")
	)

	var passed: bool = (
		manager_available
		and valid_action_pass
		and missing_actor_pass
		and missing_target_pass
		and missing_type_pass
		and invalid_duration_pass
		and invalid_cost_pass
		and no_target_pass
	)

	TestLogger.write_line(
		"Step 15.4 Action Validation test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
