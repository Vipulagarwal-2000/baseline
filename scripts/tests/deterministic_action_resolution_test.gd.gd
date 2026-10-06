class_name DeterministicActionResolutionTest
extends RefCounted


# ============================================================
# STEP 16.4 — DETERMINISTIC ACTION RESOLUTION TEST
# ============================================================
#
# Step 16.1 establishes bounded concurrent capacity.
# Step 16.2 establishes concurrent admission.
# Step 16.3 establishes reservation-based contention.
#
# Step 16.4 establishes the deterministic resolution policy:
#
#   1. admission order is preserved as the queue authority
#   2. higher action priority resolves before lower priority
#   3. equal-priority actions resolve by admission order
#   4. reservations already committed at admission are not
#      retroactively displaced by later priority changes
#   5. completion/outcome records follow the deterministic
#      resolution order for the monthly pass
#
# No second action queue or domain authority is introduced.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 16.4 — DETERMINISTIC ACTION RESOLUTION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var fixture: Dictionary = _create_fixture()
	var test_world: WorldState = fixture["world"] as WorldState
	var isolated_simulation: SimulationEngine = fixture["simulation"] as SimulationEngine
	var actor: SimEntity = fixture["actor"] as SimEntity
	var target_a: SimEntity = fixture["target_a"] as SimEntity
	var target_b: SimEntity = fixture["target_b"] as SimEntity
	var target_c: SimEntity = fixture["target_c"] as SimEntity
	var target_d: SimEntity = fixture["target_d"] as SimEntity
	var manager: ActionManager = fixture["manager"] as ActionManager

	if (
		test_world == null
		or isolated_simulation == null
		or actor == null
		or target_a == null
		or target_b == null
		or target_c == null
		or target_d == null
		or manager == null
	):
		TestLogger.write_line("Deterministic resolution fixture available: FAIL")
		return false

	TestLogger.write_line("Deterministic resolution fixture available: PASS")

	# ------------------------------------------------------------
	# 1. ADMISSION ORDER IS THE QUEUE AUTHORITY
	# ------------------------------------------------------------

	var action_a: SimAction = _new_action(
		actor,
		target_a,
		"step16_4_admission_a",
		1
	)
	var action_b: SimAction = _new_action(
		actor,
		target_b,
		"step16_4_admission_b",
		5
	)
	var action_c: SimAction = _new_action(
		actor,
		target_c,
		"step16_4_admission_c",
		5
	)
	var action_d: SimAction = _new_action(
		actor,
		target_d,
		"step16_4_admission_d",
		-1
	)

	var add_a: bool = isolated_simulation.add_action(action_a)
	var add_b: bool = isolated_simulation.add_action(action_b)
	var add_c: bool = isolated_simulation.add_action(action_c)
	var add_d: bool = isolated_simulation.add_action(action_d)

	var pending_before_resolution: Array = manager.get_pending_actions()
	var admission_order_pass: bool = (
		add_a
		and add_b
		and add_c
		and add_d
		and pending_before_resolution.size() == 4
		and pending_before_resolution[0] == action_a
		and pending_before_resolution[1] == action_b
		and pending_before_resolution[2] == action_c
		and pending_before_resolution[3] == action_d
	)

	TestLogger.write_line(
		"Admission order remains insertion-ordered before resolution: "
		+ ("PASS" if admission_order_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. PRIORITY OVERRIDES ADMISSION ORDER FOR RESOLUTION
	# ------------------------------------------------------------

	var resolution_preview: Array = manager.get_deterministic_resolution_order()
	var priority_resolution_pass: bool = false

	if resolution_preview.size() == 4:
		var first_resolution: Dictionary = resolution_preview[0] as Dictionary
		var second_resolution: Dictionary = resolution_preview[1] as Dictionary
		var third_resolution: Dictionary = resolution_preview[2] as Dictionary
		var fourth_resolution: Dictionary = resolution_preview[3] as Dictionary

		priority_resolution_pass = (
			str(first_resolution.get("action_type", "")) == "step16_4_admission_b"
			and str(second_resolution.get("action_type", "")) == "step16_4_admission_c"
			and str(third_resolution.get("action_type", "")) == "step16_4_admission_a"
			and str(fourth_resolution.get("action_type", "")) == "step16_4_admission_d"
			and int(first_resolution.get("priority", 0)) == 5
			and int(second_resolution.get("priority", 0)) == 5
			and int(third_resolution.get("priority", 0)) == 1
			and int(fourth_resolution.get("priority", 0)) == -1
		)

	TestLogger.write_line(
		"Higher priority actions resolve before lower priority actions: "
		+ ("PASS" if priority_resolution_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. EQUAL PRIORITY USES ADMISSION ORDER AS THE TIE-BREAKER
	# ------------------------------------------------------------

	var equal_priority_tie_pass: bool = false
	if resolution_preview.size() >= 2:
		var first_equal: Dictionary = resolution_preview[0] as Dictionary
		var second_equal: Dictionary = resolution_preview[1] as Dictionary
		equal_priority_tie_pass = (
			str(first_equal.get("action_type", "")) == "step16_4_admission_b"
			and str(second_equal.get("action_type", "")) == "step16_4_admission_c"
			and int(first_equal.get("admission_order", -1))
			< int(second_equal.get("admission_order", -1))
		)

	TestLogger.write_line(
		"Equal-priority actions resolve by deterministic admission order: "
		+ ("PASS" if equal_priority_tie_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. RESERVATIONS REMAIN INTACT BEFORE MONTHLY RESOLUTION
	# ------------------------------------------------------------

	var reservation_state_pass: bool = (
		manager.get_reservation_count() == 4
		and manager.has_action_reservation(action_a)
		and manager.has_action_reservation(action_b)
		and manager.has_action_reservation(action_c)
		and manager.has_action_reservation(action_d)
	)

	TestLogger.write_line(
		"Resolution ordering does not mutate committed reservation state: "
		+ ("PASS" if reservation_state_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. MONTHLY COMPLETION ORDER MATCHES RESOLUTION ORDER
	# ------------------------------------------------------------

	isolated_simulation.tick_month()

	var outcome_history: Array = manager.get_outcome_history()
	var completion_order_pass: bool = false

	if outcome_history.size() == 4:
		var outcome_a: Dictionary = outcome_history[0] as Dictionary
		var outcome_b: Dictionary = outcome_history[1] as Dictionary
		var outcome_c: Dictionary = outcome_history[2] as Dictionary
		var outcome_d: Dictionary = outcome_history[3] as Dictionary

		completion_order_pass = (
			str(outcome_a.get("type", "")) == "step16_4_admission_b"
			and str(outcome_b.get("type", "")) == "step16_4_admission_c"
			and str(outcome_c.get("type", "")) == "step16_4_admission_a"
			and str(outcome_d.get("type", "")) == "step16_4_admission_d"
			and action_b.state == SimAction.STATE_COMPLETED
			and action_c.state == SimAction.STATE_COMPLETED
			and action_a.state == SimAction.STATE_COMPLETED
			and action_d.state == SimAction.STATE_COMPLETED
			and manager.get_pending_count() == 0
			and manager.get_reservation_count() == 0
		)

	TestLogger.write_line(
		"Completion and outcome ordering follows deterministic resolution order: "
		+ ("PASS" if completion_order_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 6. RESERVATION CONFLICT IS NOT RETROACTIVELY OVERRIDDEN BY PRIORITY
	# ------------------------------------------------------------

	var conflict_fixture: Dictionary = _create_fixture()
	var conflict_simulation: SimulationEngine = conflict_fixture["simulation"] as SimulationEngine
	var conflict_actor: SimEntity = conflict_fixture["actor"] as SimEntity
	var conflict_target_a: SimEntity = conflict_fixture["target_a"] as SimEntity
	var conflict_target_b: SimEntity = conflict_fixture["target_b"] as SimEntity
	var conflict_manager: ActionManager = conflict_fixture["manager"] as ActionManager

	var lower_priority_first: SimAction = _new_action(
		conflict_actor,
		conflict_target_a,
		"step16_4_conflict_low_first",
		1
	)
	lower_priority_first.resource_requirements = {"steel": 30.0}

	var higher_priority_second: SimAction = _new_action(
		conflict_actor,
		conflict_target_b,
		"step16_4_conflict_high_second",
		10
	)
	higher_priority_second.resource_requirements = {"steel": 25.0}

	var low_result: bool = conflict_simulation.add_action(lower_priority_first)
	var high_result: bool = conflict_simulation.add_action(higher_priority_second)

	var reservation_conflict_pass: bool = (
		low_result
		and not high_result
		and lower_priority_first.state == SimAction.STATE_QUEUED
		and higher_priority_second.state == SimAction.STATE_FAILED
		and conflict_manager.get_pending_count() == 1
		and conflict_manager.get_reservation_count() == 1
		and conflict_manager.has_action_reservation(lower_priority_first)
		and not conflict_manager.has_action_reservation(higher_priority_second)
	)

	TestLogger.write_line(
		"Existing reservation commitment is not retroactively displaced by later priority: "
		+ ("PASS" if reservation_conflict_pass else "FAIL")
	)

	var overall_pass: bool = (
		admission_order_pass
		and priority_resolution_pass
		and equal_priority_tie_pass
		and reservation_state_pass
		and completion_order_pass
		and reservation_conflict_pass
	)

	TestLogger.write_line(
		"Step 16.4 Deterministic Resolution overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 5

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_4_actor",
		"Step 16.4 Actor",
		"country"
	)

	var target_a: SimEntity = SimEntity.new(
		actor.id + "_a",
		"Step 16.4 Target A",
		"country"
	)
	var target_b: SimEntity = SimEntity.new(
		actor.id + "_b",
		"Step 16.4 Target B",
		"country"
	)
	var target_c: SimEntity = SimEntity.new(
		actor.id + "_c",
		"Step 16.4 Target C",
		"country"
	)
	var target_d: SimEntity = SimEntity.new(
		actor.id + "_d",
		"Step 16.4 Target D",
		"country"
	)

	# Resource state is required for the Step 16.4 reservation-conflict
	# case. The fixture intentionally gives the actor 50 steel so the
	# first 30-unit action is individually affordable while the later
	# 25-unit action must fail against the already-committed reservation.
	var resources: SimComponent = ResourceComponent.new(actor.id)
	resources.set_state(
		"stockpile",
		{
			"steel": 50.0
		}
	)
	actor.add_component(resources)

	test_world.add_entity(actor)
	test_world.add_entity(target_a)
	test_world.add_entity(target_b)
	test_world.add_entity(target_c)
	test_world.add_entity(target_d)

	actor.set_relationship(target_a.id, 0.0)
	actor.set_relationship(target_b.id, 0.0)
	actor.set_relationship(target_c.id, 0.0)
	actor.set_relationship(target_d.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)

	return {
		"world": test_world,
		"simulation": isolated_simulation,
		"actor": actor,
		"target_a": target_a,
		"target_b": target_b,
		"target_c": target_c,
		"target_d": target_d,
		"manager": isolated_simulation.action_manager
	}


static func _new_action(
	actor: SimEntity,
	target: SimEntity,
	action_type: String,
	action_priority: int
) -> SimAction:
	var action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		0.0,
		1
	)
	action.action_type = action_type
	action.priority = action_priority
	return action
