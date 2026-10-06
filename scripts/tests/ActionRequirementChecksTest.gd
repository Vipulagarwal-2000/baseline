class_name ActionRequirementChecksTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 15.5 — RESOURCE / FINANCIAL / CAPABILITY / CAPACITY CHECKS TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	var action_manager: ActionManager = simulation.get_system(
		"action_manager"
	) as ActionManager

	if action_manager == null:
		TestLogger.write_line("ActionManager available: FAIL")
		return false

	var test_config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(test_config)
	var actor: SimEntity = SimEntity.new(
		"step15_5_actor",
		"Step 15.5 Actor",
		"country"
	)

	var resources: SimComponent = ResourceComponent.new(actor.id)
	var economy: EconomyComponent = EconomyComponent.new(actor.id)
	var industry: SimComponent = IndustryComponent.new(actor.id)
	var infrastructure: InfrastructureComponent = InfrastructureComponent.new(actor.id)

	resources.set_state("stockpile", {"steel": 50.0})
	economy.set_state("treasury", 1000.0)
	economy.set_state("investment_capacity", 10.0)
	industry.set_state("industrial_capacity", 20.0)
	infrastructure.set_state("administrative_capacity", 5.0)

	actor.add_component(resources)
	actor.add_component(economy)
	actor.add_component(industry)
	actor.add_component(infrastructure)
	actor.set_sim_metadata(
		"capabilities",
		{
			"administrative": 0.5
		}
	)
	test_world.add_entity(actor)

	var isolated_simulation: SimulationEngine = SimulationEngine.new(test_world)
	var isolated_manager: ActionManager = isolated_simulation.action_manager

	if isolated_manager == null:
		TestLogger.write_line("Isolated ActionManager available: FAIL")
		return false

	var valid_action: SimAction = SimAction.new(
		"step15_5_requirement_check",
		actor.id,
		"",
		0.0,
		2
	)
	valid_action.cost = 25.0
	valid_action.resource_requirements = {
		"steel": 10.0
	}
	valid_action.financial_requirements = {
		"treasury": 50.0
	}
	valid_action.capability_requirements = {
		"administrative": 0.2
	}
	valid_action.capacity_requirements = {
		"investment_capacity": 2.0
	}

	var valid_result: bool = isolated_simulation.add_action(valid_action)
	var valid_pass: bool = (
		valid_result
		and valid_action.state == SimAction.STATE_QUEUED
		and valid_action.failure_reason.is_empty()
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"All requirements satisfied → action admitted: "
		+ ("PASS" if valid_pass else "FAIL")
	)

	# Resource failure.
	var resource_fail: SimAction = SimAction.new(
		"step15_5_resource_failure",
		actor.id,
		"",
		0.0,
		2
	)
	resource_fail.resource_requirements = {"steel": 51.0}
	var resource_result: bool = isolated_simulation.add_action(resource_fail)
	var resource_pass: bool = (
		not resource_result
		and resource_fail.state == SimAction.STATE_FAILED
		and resource_fail.failure_reason.find("insufficient resource") >= 0
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Insufficient resource → action rejected: "
		+ ("PASS" if resource_pass else "FAIL")
	)

	# Financial failure.
	var financial_fail: SimAction = SimAction.new(
		"step15_5_financial_failure",
		actor.id,
		"",
		0.0,
		2
	)
	financial_fail.financial_requirements = {"treasury": 1001.0}
	var financial_result: bool = isolated_simulation.add_action(financial_fail)
	var financial_pass: bool = (
		not financial_result
		and financial_fail.state == SimAction.STATE_FAILED
		and financial_fail.failure_reason.find("insufficient financial state") >= 0
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Insufficient financial state → action rejected: "
		+ ("PASS" if financial_pass else "FAIL")
	)

	# Capability failure.
	var capability_fail: SimAction = SimAction.new(
		"step15_5_capability_failure",
		actor.id,
		"",
		0.0,
		2
	)
	capability_fail.capability_requirements = {"administrative": 0.6}
	var capability_result: bool = isolated_simulation.add_action(capability_fail)
	var capability_pass: bool = (
		not capability_result
		and capability_fail.state == SimAction.STATE_FAILED
		and capability_fail.failure_reason.find("insufficient capability") >= 0
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Insufficient capability → action rejected: "
		+ ("PASS" if capability_pass else "FAIL")
	)

	# Capacity failure.
	var capacity_fail: SimAction = SimAction.new(
		"step15_5_capacity_failure",
		actor.id,
		"",
		0.0,
		2
	)
	capacity_fail.capacity_requirements = {"investment_capacity": 11.0}
	var capacity_result: bool = isolated_simulation.add_action(capacity_fail)
	var capacity_pass: bool = (
		not capacity_result
		and capacity_fail.state == SimAction.STATE_FAILED
		and capacity_fail.failure_reason.find("insufficient capacity") >= 0
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Insufficient capacity → action rejected: "
		+ ("PASS" if capacity_pass else "FAIL")
	)

	# Cost-only financial fallback.
	var cost_fail: SimAction = SimAction.new(
		"step15_5_cost_failure",
		actor.id,
		"",
		0.0,
		2
	)
	cost_fail.cost = 1001.0
	var cost_result: bool = isolated_simulation.add_action(cost_fail)
	var cost_pass: bool = (
		not cost_result
		and cost_fail.state == SimAction.STATE_FAILED
		and cost_fail.failure_reason.find("insufficient treasury") >= 0
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Action cost uses authoritative treasury check: "
		+ ("PASS" if cost_pass else "FAIL")
	)

	var passed: bool = (
		valid_pass
		and resource_pass
		and financial_pass
		and capability_pass
		and capacity_pass
		and cost_pass
	)

	TestLogger.write_line(
		"Step 15.5 Resource / Financial / Capability / Capacity Checks test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
