class_name ActionDurationProgressTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.7 — DURATION / MONTHLY PROGRESS TEST"
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
		"step15_7_actor",
		"Step 15.7 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_7_target",
		"Step 15.7 Target",
		"country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	var economy: SimComponent = EconomyComponent.new(actor.id)
	var industry: SimComponent = IndustryComponent.new(actor.id)
	var infrastructure: SimComponent = InfrastructureComponent.new(actor.id)

	resources.set_state("stockpile", {"steel": 100.0})
	economy.set_state("treasury", 1000.0)
	economy.set_state("investment_capacity", 20.0)
	industry.set_state("industrial_capacity", 50.0)
	infrastructure.set_state("administrative_capacity", 10.0)

	actor.add_component(resources)
	actor.add_component(economy)
	actor.add_component(industry)
	actor.add_component(infrastructure)
	actor.set_sim_metadata(
		"capabilities",
		{
			"administrative": 2.0
		}
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)
	actor.set_relationship(target.id, 0.0)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)
	var manager: ActionManager = isolated_simulation.action_manager
	var manager_available: bool = manager != null

	TestLogger.write_line(
		"ActionManager available: "
		+ ("PASS" if manager_available else "FAIL")
	)
	if manager == null:
		return false

	# ------------------------------------------------------------
	# 1. THREE-MONTH ACTION — INITIAL CONTRACT
	# ------------------------------------------------------------
	var multi_month_action: SimAction = SimAction.new(
		"step15_7_multi_month",
		actor.id,
		target.id,
		0.0,
		3
	)

	var add_result: bool = isolated_simulation.add_action(multi_month_action)
	var initial_pass: bool = (
		add_result
		and multi_month_action.state == SimAction.STATE_QUEUED
		and multi_month_action.duration_months == 3
		and multi_month_action.total_duration_months == 3
		and is_equal_approx(multi_month_action.progress, 0.0)
	)

	TestLogger.write_line(
		"Queued action starts at zero progress with full duration: "
		+ ("PASS" if initial_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. MONTH 1 — 1/3 PROGRESS
	# ------------------------------------------------------------
	isolated_simulation.tick_month()
	var month_1_progress: bool = (
		multi_month_action.state == SimAction.STATE_ACTIVE
		and multi_month_action.duration_months == 2
		and is_equal_approx(multi_month_action.progress, 1.0 / 3.0)
		and manager.get_pending_count() == 1
	)

	TestLogger.write_line(
		"Month 1 advances action to 1/3 progress: "
		+ ("PASS" if month_1_progress else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. MONTH 2 — 2/3 PROGRESS
	# ------------------------------------------------------------
	isolated_simulation.tick_month()
	var month_2_progress: bool = (
		multi_month_action.state == SimAction.STATE_ACTIVE
		and multi_month_action.duration_months == 1
		and is_equal_approx(multi_month_action.progress, 2.0 / 3.0)
		and multi_month_action.progress > 1.0 / 3.0
		and manager.get_pending_count() == 1
	)

	TestLogger.write_line(
		"Month 2 advances action to 2/3 progress: "
		+ ("PASS" if month_2_progress else "FAIL")
	)

	# ------------------------------------------------------------
	# 4. MONTH 3 — COMPLETION / 100%
	# ------------------------------------------------------------
	isolated_simulation.tick_month()
	var completion_progress: bool = (
		multi_month_action.state == SimAction.STATE_COMPLETED
		and multi_month_action.duration_months == 0
		and multi_month_action.total_duration_months == 3
		and is_equal_approx(multi_month_action.progress, 1.0)
		and manager.get_pending_count() == 0
		and manager.get_reservation_count() == 0
	)

	TestLogger.write_line(
		"Month 3 reaches 100% progress and completion: "
		+ ("PASS" if completion_progress else "FAIL")
	)

	# ------------------------------------------------------------
	# 5. ONE-MONTH ACTION COMPLETES IN ONE TICK
	# ------------------------------------------------------------
	var one_month_action: SimAction = SimAction.new(
		"step15_7_one_month",
		actor.id,
		"",
		0.0,
		1
	)

	var one_month_add: bool = isolated_simulation.add_action(one_month_action)
	var one_month_initial: bool = (
		one_month_add
		and is_equal_approx(one_month_action.progress, 0.0)
		and one_month_action.duration_months == 1
	)

	isolated_simulation.tick_month()
	var one_month_completion: bool = (
	one_month_action.state == SimAction.STATE_COMPLETED
		and one_month_action.duration_months == 0
		and is_equal_approx(one_month_action.progress, 1.0)
		and manager.get_pending_count() == 0
		and manager.get_reservation_count() == 0
	)

	var one_month_pass: bool = (
		one_month_initial
		and one_month_completion
	)

	TestLogger.write_line(
		"One-month action completes in one monthly tick at 100%: "
		+ ("PASS" if one_month_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 6. PROGRESS CLAMP / MONOTONICITY
	# ------------------------------------------------------------
	var progress_bounds_pass: bool = (
		multi_month_action.progress >= 0.0
		and multi_month_action.progress <= 1.0
		and one_month_action.progress >= 0.0
		and one_month_action.progress <= 1.0
	)

	TestLogger.write_line(
		"Action progress remains clamped to 0.0..1.0: "
		+ ("PASS" if progress_bounds_pass else "FAIL")
	)

	var passed: bool = (
		manager_available
		and initial_pass
		and month_1_progress
		and month_2_progress
		and completion_progress
		and one_month_pass
		and progress_bounds_pass
	)

	TestLogger.write_line(
		"Step 15.7 Duration / Monthly Progress test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
