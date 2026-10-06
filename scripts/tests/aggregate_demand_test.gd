class_name AggregateDemandTest
extends RefCounted


static func _approx_equal(
	actual: float,
	expected: float
) -> bool:
	return is_equal_approx(
		actual,
		expected
	)


static func _log_result(
	label: String,
	passed: bool
) -> void:

	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation
) -> bool:

	var all_passed := true

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation available: PASS"
	)

	var aggregate_demand_system = simulation.get_system(
		"aggregate_demand_system"
	)

	var registered_system_passed := (
		aggregate_demand_system != null
		and aggregate_demand_system is AggregateDemandSystem
	)

	_log_result(
		"Registered AggregateDemandSystem available",
		registered_system_passed
	)

	all_passed = all_passed and registered_system_passed

	if not registered_system_passed:
		return false

	# Isolated fixture so the active three-country world remains unchanged.
	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_3_aggregate_demand_test",
		"Step 5.3 Aggregate Demand Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)

	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# ------------------------------------------------------------
	# Controlled category inputs.
	# ------------------------------------------------------------
	resources.set_state(
		"population_resource_demand",
		{
			"food": 100.0,
			"iron": 5.0
		}
	)

	resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0
		}
	)

	resources.set_state(
		"government_resource_demand",
		{
			"steel": 3.0
		}
	)

	resources.set_state(
		"military_resource_demand",
		{
			"iron": 7.0,
			"oil": 15.0
		}
	)

	resources.set_state(
		"exports",
		{
			"iron": 10.0,
			"oil": 4.0
		}
	)

	aggregate_demand_system.process_month(
		world
	)

	var aggregate_demand: Dictionary = resources.get_state(
		"aggregate_demand",
		{}
	)

	var category_totals: Dictionary = resources.get_state(
		"aggregate_demand_total_by_category",
		{}
	)

	var ledger: Dictionary = resources.get_state(
		"aggregate_demand_ledger",
		{}
	)

	# ------------------------------------------------------------
	# Category preservation and aggregation.
	# ------------------------------------------------------------
	var category_values_passed := (
		_approx_equal(
			float(category_totals.get("population", -1.0)),
			105.0
		)
		and _approx_equal(
			float(category_totals.get("industry", -1.0)),
			20.0
		)
		and _approx_equal(
			float(category_totals.get("government", -1.0)),
			3.0
		)
		and _approx_equal(
			float(category_totals.get("military", -1.0)),
			22.0
		)
		and _approx_equal(
			float(category_totals.get("exports", -1.0)),
			14.0
		)
	)

	_log_result(
		"Five demand categories remain separately accounted",
		category_values_passed
	)
	all_passed = all_passed and category_values_passed

	var resource_aggregation_passed := (
		_approx_equal(float(aggregate_demand.get("food", -1.0)), 100.0)
		and _approx_equal(float(aggregate_demand.get("iron", -1.0)), 42.0)
		and _approx_equal(float(aggregate_demand.get("steel", -1.0)), 3.0)
		and _approx_equal(float(aggregate_demand.get("oil", -1.0)), 19.0)
	)

	_log_result(
		"Resource-level aggregate demand sums category demand",
		resource_aggregation_passed
	)
	all_passed = all_passed and resource_aggregation_passed

	var aggregate_total_passed := _approx_equal(
		float(
			resources.get_state(
				"aggregate_demand_total",
				-1.0
			)
		),
		164.0
	)

	_log_result(
		"Aggregate demand total equals all resource/category demand",
		aggregate_total_passed
	)
	all_passed = all_passed and aggregate_total_passed

	var reconciliation_passed := true

	for resource_name in ledger.keys():
		var resource_ledger: Dictionary = ledger[resource_name]
		reconciliation_passed = (
			reconciliation_passed
			and _approx_equal(
				float(resource_ledger.get("reconciliation_error", 999.0)),
				0.0
			)
		)

	_log_result(
		"Aggregate demand reconciliation closes exactly",
		reconciliation_passed
	)
	all_passed = all_passed and reconciliation_passed

	# ------------------------------------------------------------
	# Negative demand is ignored rather than becoming physical demand.
	# ------------------------------------------------------------
	resources.set_state(
		"population_resource_demand",
		{
			"food": -20.0,
			"water": 5.0
		}
	)

	aggregate_demand_system.process_month(
		world
	)

	aggregate_demand = resources.get_state(
		"aggregate_demand",
		{}
	)

	var negative_clamp_passed := (
		not aggregate_demand.has("food")
		and _approx_equal(
			float(aggregate_demand.get("water", -1.0)),
			5.0
		)
	)

	_log_result(
		"Negative demand is clamped without creating demand",
		negative_clamp_passed
	)
	all_passed = all_passed and negative_clamp_passed

	# ------------------------------------------------------------
	# Clearing category inputs clears stale aggregate demand.
	# ------------------------------------------------------------
	resources.set_state(
		"population_resource_demand",
		{}
	)

	resources.set_state(
		"production_process_demand",
		{}
	)

	resources.set_state(
		"government_resource_demand",
		{}
	)

	resources.set_state(
		"military_resource_demand",
		{}
	)

	resources.set_state(
		"exports",
		{}
	)

	aggregate_demand_system.process_month(
		world
	)

	aggregate_demand = resources.get_state(
		"aggregate_demand",
		{}
	)

	var stale_state_cleared_passed := (
		aggregate_demand.is_empty()
		and _approx_equal(
			float(
				resources.get_state(
					"aggregate_demand_total",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Aggregate demand does not retain stale previous-month values",
		stale_state_cleared_passed
	)
	all_passed = all_passed and stale_state_cleared_passed

	world.entities.clear()

	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	var restored := (
		world.has_entity("step_5_3_aggregate_demand_test") == false
		and world.entities.size() == original_entities.size()
	)

	_log_result(
		"Step 5.3 fixture state restored",
		restored
	)
	all_passed = all_passed and restored

	TestLogger.write_line(
		"Aggregate Demand 5.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
