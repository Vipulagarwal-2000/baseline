class_name ConcurrentActionAdmissionTest
extends RefCounted


# ============================================================
# STEP 16.2 — CONCURRENT ACTION ADMISSION TEST
# ============================================================
#
# Step 16.1 established the bounded execution-slot contract.
# Step 16.2 proves the next semantic boundary:
#
#   multiple compatible actions may be admitted into the same
#   actor's execution queue before the next monthly processing pass.
#
# This test deliberately gives the fixture a capacity of five so
# the test exercises concurrent admission rather than the Step 16.1
# slot ceiling of three.
#
# No second admission authority is introduced. The existing
# SimulationEngine -> ActionManager -> add_action() path remains the
# authoritative admission boundary.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 16.2 — CONCURRENT ACTION ADMISSION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	# ------------------------------------------------------------
	# CONTROLLED FIXTURE
	# ------------------------------------------------------------

	var config: SimulationConfig = SimulationConfig.create_default()
	config.max_concurrent_actions_per_actor = 5

	var test_world: WorldState = WorldState.new(config)

	var actor: SimEntity = SimEntity.new(
		"step16_2_actor",
		"Step 16.2 Actor",
		"country"
	)

	test_world.add_entity(actor)

	var targets: Array[SimEntity] = []

	for index in range(4):
		var target: SimEntity = SimEntity.new(
			"step16_2_target_" + str(index + 1),
			"Step 16.2 Target " + str(index + 1),
			"country"
		)
		test_world.add_entity(target)
		actor.set_relationship(target.id, 0.0)
		targets.append(target)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(
		test_world
	)

	var manager: ActionManager = isolated_simulation.action_manager

	if manager == null:
		TestLogger.write_line("ActionManager available: FAIL")
		return false

	TestLogger.write_line("ActionManager available: PASS")

	var configured_capacity: int = manager.get_action_capacity_limit(
		test_world,
		actor.id
	)

	var capacity_fixture_pass: bool = configured_capacity == 5
	TestLogger.write_line(
		"Fixture capacity is above the Step 16.1 default ceiling: "
		+ ("PASS" if capacity_fixture_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 1. SINGLE ACTION BASELINE
	# ------------------------------------------------------------

	var first_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		targets[0].id,
		1.0,
		2
	)

	var first_result: bool = isolated_simulation.add_action(first_action)

	var first_admission_pass: bool = (
		first_result
		and first_action.state == SimAction.STATE_QUEUED
		and manager.get_pending_count() == 1
		and manager.get_concurrent_action_count(actor.id) == 1
	)

	TestLogger.write_line(
		"One compatible action is admitted through the normal action path: "
		+ ("PASS" if first_admission_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. ADD MULTIPLE COMPATIBLE ACTIONS BEFORE MONTHLY PROCESSING
	# ------------------------------------------------------------

	var second_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		targets[1].id,
		1.0,
		2
	)

	var third_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		targets[2].id,
		1.0,
		2
	)

	var second_result: bool = isolated_simulation.add_action(second_action)
	var third_result: bool = isolated_simulation.add_action(third_action)

	var concurrent_admission_pass: bool = (
		second_result
		and third_result
		and second_action.state == SimAction.STATE_QUEUED
		and third_action.state == SimAction.STATE_QUEUED
		and manager.get_pending_count() == 3
		and manager.get_concurrent_action_count(actor.id) == 3
	)

	TestLogger.write_line(
		"Multiple compatible actions enter the same monthly queue before processing: "
		+ ("PASS" if concurrent_admission_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. ALL ACTIONS SHARE THE SAME ADMISSION MONTH
	# ------------------------------------------------------------

	var same_start_date_pass: bool = (
		first_action.start_date == second_action.start_date
		and second_action.start_date == third_action.start_date
		and not first_action.start_date.strip_edges().is_empty()
	)

	TestLogger.write_line(
		"Concurrent admissions receive the same authoritative start month: "
		+ ("PASS" if same_start_date_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. ONE MONTH PROCESSES ALL ADMITTED ACTIONS
	# ------------------------------------------------------------

	manager.process_month(test_world)

	var all_active_after_first_month: bool = (
		first_action.state == SimAction.STATE_ACTIVE
		and second_action.state == SimAction.STATE_ACTIVE
		and third_action.state == SimAction.STATE_ACTIVE
	)

	var equal_progress_after_first_month: bool = (
		is_equal_approx(first_action.progress, 0.5)
		and is_equal_approx(second_action.progress, 0.5)
		and is_equal_approx(third_action.progress, 0.5)
	)

	var all_remain_admitted_pass: bool = (
		manager.get_pending_count() == 3
		and manager.get_concurrent_action_count(actor.id) == 3
	)

	TestLogger.write_line(
		"All concurrently admitted actions enter active execution in the same monthly pass: "
		+ ("PASS" if all_active_after_first_month else "FAIL")
	)

	TestLogger.write_line(
		"Concurrent actions advance independently to equal first-month progress: "
		+ ("PASS" if equal_progress_after_first_month else "FAIL")
	)

	TestLogger.write_line(
		"All compatible actions remain admitted after the first monthly pass: "
		+ ("PASS" if all_remain_admitted_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. ADMISSION IS NOT SERIALIZED BY ONE-ACTION-ONLY LOGIC
	# ------------------------------------------------------------

	var serialization_bypass_pass: bool = (
		manager.get_concurrent_action_count(actor.id) == 3
		and first_action.duration_months == 1
		and second_action.duration_months == 1
		and third_action.duration_months == 1
	)

	TestLogger.write_line(
		"Concurrent execution is not reduced to one-action-per-month serialization: "
		+ ("PASS" if serialization_bypass_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# FINAL
	# ------------------------------------------------------------

	var overall_pass: bool = (
		capacity_fixture_pass
		and first_admission_pass
		and concurrent_admission_pass
		and same_start_date_pass
		and all_active_after_first_month
		and equal_progress_after_first_month
		and all_remain_admitted_pass
		and serialization_bypass_pass
	)

	TestLogger.write_line(
		"Step 16.2 Concurrent Admission overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass
