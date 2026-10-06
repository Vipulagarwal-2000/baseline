class_name AggregateConsumptionTest
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

	var aggregate_consumption_system = simulation.get_system(
		"aggregate_consumption_system"
	)

	var registered_system_passed: bool = (
		aggregate_consumption_system != null
		and aggregate_consumption_system is AggregateConsumptionSystem
	)

	_log_result(
		"Registered AggregateConsumptionSystem available",
		registered_system_passed
	)

	all_passed = all_passed and registered_system_passed

	if not registered_system_passed:
		return false

	# Isolated fixture so the active world remains unchanged.
	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_5_4_aggregate_consumption_test",
		"Step 5.4 Aggregate Consumption Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)

	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# ------------------------------------------------------------
	# Controlled aggregate demand.
	# Exports are intentionally present but must remain outside
	# domestic consumption.
	# ------------------------------------------------------------
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {
				"food": 100.0,
				"iron": 5.0
			},
			"industry": {
				"iron": 20.0,
				"coal": 10.0
			},
			"government": {
				"steel": 3.0
			},
			"military": {
				"iron": 7.0,
				"oil": 15.0
			},
			"exports": {
				"iron": 50.0,
				"oil": 40.0
			}
		}
	)

	resources.set_state(
		"consumption",
		{
			"old_resource": 999.0
		}
	)

	aggregate_consumption_system.process_month(
		world
	)

	var actual_consumption: Dictionary = resources.get_state(
		"actual_consumption",
		{}
	)

	var consumption_by_category: Dictionary = resources.get_state(
		"consumption_by_category",
		{}
	)

	var category_totals: Dictionary = resources.get_state(
		"consumption_total_by_category",
		{}
	)

	var ledger: Dictionary = resources.get_state(
		"consumption_ledger",
		{}
	)

	# ------------------------------------------------------------
	# Domestic categories resolve separately.
	# ------------------------------------------------------------
	var category_separation_passed: bool = (
		_approx_equal(
			float(category_totals.get("population", -1.0)),
			105.0
		)
		and _approx_equal(
			float(category_totals.get("industry", -1.0)),
			30.0
		)
		and _approx_equal(
			float(category_totals.get("government", -1.0)),
			3.0
		)
		and _approx_equal(
			float(category_totals.get("military", -1.0)),
			22.0
		)
		and not consumption_by_category.has("exports")
	)

	_log_result(
		"Domestic consumption categories remain separately accounted",
		category_separation_passed
	)
	all_passed = all_passed and category_separation_passed

	# ------------------------------------------------------------
	# Resource-level domestic consumption.
	# ------------------------------------------------------------
	var resource_consumption_passed: bool = (
		_approx_equal(
			float(actual_consumption.get("food", -1.0)),
			100.0
		)
		and _approx_equal(
			float(actual_consumption.get("iron", -1.0)),
			32.0
		)
		and _approx_equal(
			float(actual_consumption.get("coal", -1.0)),
			10.0
		)
		and _approx_equal(
			float(actual_consumption.get("steel", -1.0)),
			3.0
		)
		and _approx_equal(
			float(actual_consumption.get("oil", -1.0)),
			15.0
		)
		and not actual_consumption.has("export_only_resource")
	)

	_log_result(
		"Resource-level actual consumption sums domestic demand",
		resource_consumption_passed
	)
	all_passed = all_passed and resource_consumption_passed

	# ------------------------------------------------------------
	# Export demand stays outside domestic consumption.
	# ------------------------------------------------------------
	var exports_excluded_passed: bool = (
		_approx_equal(
			float(actual_consumption.get("iron", -1.0)),
			32.0
		)
		and _approx_equal(
			float(actual_consumption.get("oil", -1.0)),
			15.0
		)
	)

	_log_result(
		"Exports remain outside domestic consumption",
		exports_excluded_passed
	)
	all_passed = all_passed and exports_excluded_passed

	# ------------------------------------------------------------
	# Consumption total and reconciliation.
	# ------------------------------------------------------------
	var total_passed := _approx_equal(
		float(
			resources.get_state(
				"actual_consumption_total",
				-1.0
			)
		),
		160.0
	)

	_log_result(
		"Actual consumption total equals domestic category demand",
		total_passed
	)
	all_passed = all_passed and total_passed

	var reconciliation_passed := true

	for resource_name in ledger.keys():
		var resource_ledger: Dictionary = ledger[resource_name]

		reconciliation_passed = (
			reconciliation_passed
			and _approx_equal(
				float(
					resource_ledger.get(
						"reconciliation_error",
						999.0
					)
				),
				0.0
			)
			and _approx_equal(
				float(
					resource_ledger.get(
						"unmet_consumption",
						-1.0
					)
				),
				0.0
			)
		)

	_log_result(
		"Consumption reconciliation closes exactly before supply constraints",
		reconciliation_passed
	)
	all_passed = all_passed and reconciliation_passed

	# ------------------------------------------------------------
	# Negative demand is clamped.
	# ------------------------------------------------------------
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {
				"food": -20.0,
				"water": 5.0
			},
			"industry": {
				"iron": -7.0
			},
			"government": {},
			"military": {},
			"exports": {
				"oil": 30.0
			}
		}
	)

	aggregate_consumption_system.process_month(
		world
	)

	actual_consumption = resources.get_state(
		"actual_consumption",
		{}
	)

	var negative_clamp_passed: bool = (
		not actual_consumption.has("food")
		and not actual_consumption.has("iron")
		and _approx_equal(
			float(
				actual_consumption.get(
					"water",
					-1.0
				)
			),
			5.0
		)
		and not actual_consumption.has("oil")
	)

	_log_result(
		"Negative demand is clamped without creating consumption",
		negative_clamp_passed
	)
	all_passed = all_passed and negative_clamp_passed

	# ------------------------------------------------------------
	# Stale values are cleared when demand is cleared.
	# ------------------------------------------------------------
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {},
			"industry": {},
			"government": {},
			"military": {},
			"exports": {}
		}
	)

	aggregate_consumption_system.process_month(
		world
	)

	actual_consumption = resources.get_state(
		"actual_consumption",
		{}
	)

	var stale_state_cleared_passed: bool = (
		actual_consumption.is_empty()
		and _approx_equal(
			float(
				resources.get_state(
					"actual_consumption_total",
					-1.0
				)
			),
			0.0
		)
		and resources.get_state(
			"consumption",
			{}
		).is_empty()
	)

	_log_result(
		"Actual consumption does not retain stale previous-month values",
		stale_state_cleared_passed
	)
	all_passed = all_passed and stale_state_cleared_passed

	# ------------------------------------------------------------
	# Restore exact world entity dictionary.
	# ------------------------------------------------------------
	world.entities.clear()

	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	_log_result(
		"Step 5.4 fixture state restored",
		true
	)

	TestLogger.write_line(
		"Aggregate Consumption 5.4 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
