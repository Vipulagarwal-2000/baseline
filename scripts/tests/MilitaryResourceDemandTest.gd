class_name MilitaryResourceDemandTest
extends RefCounted


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(label + ": " + ("PASS" if passed else "FAIL"))


static func _sum_map(values: Dictionary) -> float:
	var total: float = 0.0
	for value in values.values():
		total += float(value)
	return total


static func _approximately_equal_map(a: Dictionary, b: Dictionary) -> bool:
	if a.keys().size() != b.keys().size():
		return false
	for key in a.keys():
		if not b.has(key):
			return false
		if not is_equal_approx(float(a[key]), float(b[key])):
			return false
	return true


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section("STEP 13.6 — MILITARY DEMAND → RESOURCE CONSUMPTION TEST")
	if world == null or simulation == null:
		_log_result("World and Simulation available", false)
		return false
	_log_result("World and Simulation available", true)

	var demand_system: MilitaryResourceDemandSystem = simulation.get_system(
		"military_resource_demand_system"
	) as MilitaryResourceDemandSystem
	var aggregate_demand_system: AggregateDemandSystem = simulation.get_system(
		"aggregate_demand_system"
	) as AggregateDemandSystem
	var aggregate_consumption_system: AggregateConsumptionSystem = simulation.get_system(
		"aggregate_consumption_system"
	) as AggregateConsumptionSystem

	var systems_ok: bool = (
		demand_system != null
		and aggregate_demand_system != null
		and aggregate_consumption_system != null
	)
	_log_result("Registered military demand / aggregate demand / aggregate consumption systems available", systems_ok)
	if not systems_ok:
		return false

	var original_entities: Dictionary = world.entities.duplicate()
	var fixture = SimEntity.new(
		"step_13_6_military_fixture",
		"Step 13.6 Military Demand Fixture",
		"country"
	)
	var military: MilitaryComponent = MilitaryComponent.new(fixture.id)
	var resources: ResourceComponent = ResourceComponent.new(fixture.id)
	fixture.add_component(military)
	fixture.add_component(resources)

	military.set_state("military_spending", 0.50)
	military.set_state("army_strength", 0.60)
	military.set_state("naval_strength", 0.30)
	military.set_state("air_strength", 0.20)
	military.set_state("logistics_capacity", 0.50)
	military.set_state("at_war", false)

	resources.set_state("population_resource_demand", {})
	resources.set_state("production_process_demand", {})
	resources.set_state("government_resource_demand", {})
	resources.set_state("exports", {})
	resources.set_state("consumption", {})
	resources.set_state("actual_consumption", {})
	resources.set_state("aggregate_demand_by_category", {})

	world.entities.clear()
	world.add_entity(fixture)

	var original_snapshot: Dictionary = resources.state.duplicate(true)
	var passed: bool = true

	# ------------------------------------------------------------
	# Demand generation
	# ------------------------------------------------------------
	demand_system.process_month(world)
	var produced_military_demand: Dictionary = resources.get_state(
		"military_resource_demand",
		{}
	).duplicate(true)
	var baseline_total: float = float(military.get_state("resource_demand_total", -1.0))
	var baseline_valid: bool = (
		produced_military_demand.has("coal")
		and produced_military_demand.has("iron")
		and produced_military_demand.has("oil")
		and baseline_total >= 0.0
		and is_equal_approx(baseline_total, _sum_map(produced_military_demand))
	)
	_log_result("Baseline military demand is explicitly generated", baseline_valid)
	passed = passed and baseline_valid

	# Higher spending / war still operate on the same isolated fixture.
	var baseline_oil: float = float(produced_military_demand.get("oil", 0.0))
	military.set_state("military_spending", 0.90)
	demand_system.process_month(world)
	var high_spending_demand: Dictionary = resources.get_state("military_resource_demand", {})
	var spending_increase_passed: bool = (
		float(military.get_state("resource_demand_total", 0.0)) > baseline_total
		and float(high_spending_demand.get("oil", 0.0)) > baseline_oil
	)
	_log_result("Higher military spending increases resource demand", spending_increase_passed)
	passed = passed and spending_increase_passed

	military.set_state("military_spending", 0.50)
	military.set_state("at_war", true)
	demand_system.process_month(world)
	var war_total: float = float(military.get_state("resource_demand_total", 0.0))
	var war_demand: Dictionary = resources.get_state("military_resource_demand", {})
	var war_increase_passed: bool = (
		war_total > baseline_total
		and float(war_demand.get("oil", 0.0)) > baseline_oil
	)
	_log_result("War activity increases resource demand", war_increase_passed)
	passed = passed and war_increase_passed

	# Restore controlled baseline for the bridge test.
	military.set_state("military_spending", 0.80)
	military.set_state("at_war", false)
	resources.set_state("population_resource_demand", {})
	resources.set_state("production_process_demand", {})
	resources.set_state("government_resource_demand", {})
	resources.set_state("exports", {})
	demand_system.process_month(world)
	produced_military_demand = (
		resources.get_state("military_resource_demand", {}).duplicate(true)
	)

	aggregate_demand_system.process_month(world)
	var aggregate_by_category: Dictionary = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)
	var military_category: Dictionary = aggregate_by_category.get("military", {}).duplicate(true)
	var aggregate_demand_passed: bool = _approximately_equal_map(
		military_category,
		produced_military_demand
	)
	_log_result("Military demand enters existing aggregate-demand military category", aggregate_demand_passed)
	passed = passed and aggregate_demand_passed

	aggregate_consumption_system.process_month(world)
	var consumption_by_category: Dictionary = resources.get_state(
		"consumption_by_category",
		{}
	)
	var military_consumption: Dictionary = consumption_by_category.get("military", {}).duplicate(true)
	var actual_consumption: Dictionary = resources.get_state(
		"actual_consumption",
		{}
	).duplicate(true)
	var consumption_ledger: Dictionary = resources.get_state(
		"consumption_ledger",
		{}
	)

	var ledger_military: Dictionary = {}
	for resource_id in produced_military_demand.keys():
		var entry: Variant = consumption_ledger.get(str(resource_id), {})
		if entry is Dictionary:
			ledger_military[str(resource_id)] = float((entry as Dictionary).get("military", 0.0))

	var consumption_passed: bool = (
		_approximately_equal_map(military_consumption, produced_military_demand)
		and _approximately_equal_map(ledger_military, produced_military_demand)
		and _approximately_equal_map(actual_consumption, produced_military_demand)
	)
	_log_result(
		"Military demand becomes domestic resource consumption through existing pipeline",
		consumption_passed
	)
	passed = passed and consumption_passed

	var demand_source_non_destructive: bool = (
		is_equal_approx(float(military.get_state("military_spending", -1.0)), 0.80)
		and not bool(military.get_state("at_war", false))
	)
	_log_result("Demand bridge does not rewrite source military state", demand_source_non_destructive)
	passed = passed and demand_source_non_destructive

	military.state = military.state.duplicate(true)
	resources.state = original_snapshot.duplicate(true)
	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]
	_log_result("Step 13.6 fixture restoration", resources.state == original_snapshot)
	passed = passed and resources.state == original_snapshot

	TestLogger.write_line(
		"Step 13.6 military demand → resource consumption overall: "
		+ ("PASS" if passed else "FAIL")
	)
	return passed
