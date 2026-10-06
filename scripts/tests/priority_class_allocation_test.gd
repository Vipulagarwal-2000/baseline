class_name PriorityClassAllocationTest
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
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)


static func _get_resource_map(
	resources: ResourceComponent,
	state_name: String
) -> Dictionary:
	var value = resources.get_state(
		state_name,
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"BASIC PRIORITY CLASSES TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var system = simulation.get_system(
		"priority_class_allocation_system"
	)

	var system_ok: bool = (
		system != null
		and system is PriorityClassAllocationSystem
	)

	_log_result(
		"Registered PriorityClassAllocationSystem available",
		system_ok
	)

	if not system_ok:
		return false

	var priority_system: PriorityClassAllocationSystem = (
		system as PriorityClassAllocationSystem
	)

	var default_order: Array = (
		priority_system.get_priority_order()
	)

	var default_config_ok: bool = (
		default_order == [
			"essential_consumption",
			"critical_production",
			"government",
			"military",
			"exports",
			"discretionary_use"
		]
		and priority_system.get_priority_class_for_category(
			"population"
		) == "essential_consumption"
		and priority_system.get_priority_class_for_category(
			"industry"
		) == "critical_production"
		and priority_system.get_priority_class_for_category(
			"government"
		) == "government"
		and priority_system.get_priority_class_for_category(
			"military"
		) == "military"
		and priority_system.get_priority_class_for_category(
			"exports"
		) == "exports"
	)

	_log_result(
		"Default priority configuration is loaded and mapped",
		default_config_ok
	)

	var original_entities: Dictionary = (
		world.entities.duplicate()
	)

	var test_entity := SimEntity.new(
		"step_7_2_priority_classes_test",
		"Step 7.2 Priority Classes Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)

	test_entity.add_component(
		resources
	)

	world.entities.clear()
	world.add_entity(
		test_entity
	)

	# ------------------------------------------------------------
	# Case 1 — scarce supply follows the configured priority order.
	#
	# 100 accessible units.
	# population      30 -> essential consumption
	# industry        60 -> critical production
	# government      10 -> government
	# military        15 -> military
	# exports          5 -> reserved upstream / excluded here
	#
	# Domestic claims = 115.
	# Expected priority allocation:
	# population 30
	# industry   60
	# government 10
	# military    0
	# ------------------------------------------------------------
	resources.set_state(
		"domestic_accessible_supply",
		{
			"coal": 100.0
		}
	)

	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {
				"coal": 30.0
			},
			"industry": {
				"coal": 60.0
			},
			"government": {
				"coal": 10.0
			},
			"military": {
				"coal": 15.0
			},
			"exports": {
				"coal": 5.0
			}
		}
	)

	var original_accessible: Dictionary = (
		resources.get_state(
			"domestic_accessible_supply",
			{}
		).duplicate(true)
	)

	var original_demand: Dictionary = (
		resources.get_state(
			"aggregate_demand_by_category",
			{}
		).duplicate(true)
	)

	priority_system.process_month(
		world
	)

	var allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_category"
		)
	)

	var unmet: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_unmet_by_category"
		)
	)

	var class_allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_class"
		)
	)

	var class_unmet: Dictionary = (
		_get_resource_map(
			resources,
			"priority_unmet_by_class"
		)
	)

	var priority_ledger: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_ledger"
		)
	)

	var scarce_ok: bool = (
		_approx_equal(
			float(
				allocated.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			30.0
		)
		and _approx_equal(
			float(
				allocated.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			60.0
		)
		and _approx_equal(
			float(
				allocated.get(
					"coal",
					{}
				).get(
					"government",
					-1.0
				)
			),
			10.0
		)
		and _approx_equal(
			float(
				allocated.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				unmet.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			15.0
		)
		and _approx_equal(
			float(
				class_allocated.get(
					"coal",
					{}
				).get(
					"essential_consumption",
					-1.0
				)
			),
			30.0
		)
		and _approx_equal(
			float(
				class_allocated.get(
					"coal",
					{}
				).get(
					"critical_production",
					-1.0
				)
			),
			60.0
		)
		and _approx_equal(
			float(
				class_allocated.get(
					"coal",
					{}
				).get(
					"government",
					-1.0
				)
			),
			10.0
		)
		and _approx_equal(
			float(
				class_allocated.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				class_unmet.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			15.0
		)
		and _approx_equal(
			float(
				priority_ledger.get(
					"coal",
					{}
				).get(
					"reconciliation_error",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Scarce supply is allocated by priority class",
		scarce_ok
	)

	# Exports are represented in the configured order but are not drawn
	# from domestic_accessible_supply because Step 5.10 has already
	# reserved them upstream.
	var priority_category_map: Dictionary = (
		_get_resource_map(
			resources,
			"priority_class_by_category"
		)
	)

	var export_claim_by_class: float = float(
		_get_resource_map(
			resources,
			"priority_claim_by_class"
		).get(
			"coal",
			{}
		).get(
			"exports",
			0.0
		)
	)

	var export_class_allocated: float = float(
		class_allocated.get(
			"coal",
			{}
		).get(
			"exports",
			0.0
		)
	)

	var export_boundary_ok: bool = (
		priority_category_map.get("exports", "") == "exports"
		and _approx_equal(
			export_claim_by_class,
			0.0
		)
		and _approx_equal(
			export_class_allocated,
			0.0
		)
	)

	_log_result(
		"Export demand remains outside the domestic priority pool",
		export_boundary_ok
	)

	# Upstream physical states must remain untouched.
	var upstream_unchanged_ok: bool = (
		_get_resource_map(
			resources,
			"domestic_accessible_supply"
		) == original_accessible
		and _get_resource_map(
			resources,
			"aggregate_demand_by_category"
		) == original_demand
	)

	_log_result(
		"Priority allocation does not mutate upstream supply or demand",
		upstream_unchanged_ok
	)

	# ------------------------------------------------------------
	# Case 2 — non-scarce supply satisfies every domestic claim.
	# ------------------------------------------------------------
	resources.set_state(
		"domestic_accessible_supply",
		{
			"coal": 150.0
		}
	)

	priority_system.process_month(
		world
	)

	var non_scarce_allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_category"
		)
	)

	var non_scarce_unmet: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_unmet_by_category"
		)
	)

	var non_scarce_remaining: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_remaining_supply"
		)
	)

	var non_scarce_ok: bool = (
		_approx_equal(
			float(
				non_scarce_allocated.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			30.0
		)
		and _approx_equal(
			float(
				non_scarce_allocated.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			60.0
		)
		and _approx_equal(
			float(
				non_scarce_allocated.get(
					"coal",
					{}
				).get(
					"government",
					-1.0
				)
			),
			10.0
		)
		and _approx_equal(
			float(
				non_scarce_allocated.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			15.0
		)
		and _approx_equal(
			float(
				non_scarce_unmet.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				non_scarce_remaining.get(
					"coal",
					-1.0
				)
			),
			35.0
		)
	)

	_log_result(
		"Non-scarce supply fully satisfies domestic priority claims",
		non_scarce_ok
	)

	# ------------------------------------------------------------
	# Case 3 — reordering the configuration changes only the priority
	# outcome, not the underlying demand/supply inputs.
	# ------------------------------------------------------------
	var reordered_config: Dictionary = {
		"priority_order": [
			"military",
			"government",
			"essential_consumption",
			"critical_production",
			"exports",
			"discretionary_use"
		],
		"category_to_priority_class": {
			"population": "essential_consumption",
			"industry": "critical_production",
			"government": "government",
			"military": "military",
			"exports": "exports"
		},
		"unmapped_category_fallback": "discretionary_use"
	}

	var reordered_system := PriorityClassAllocationSystem.new(
		reordered_config
	)

	var reorder_config_ok: bool = (
		reordered_system.get_priority_order()
		== reordered_config["priority_order"]
		and reordered_system.get_priority_class_for_category(
			"military"
		) == "military"
	)

	_log_result(
		"Priority class order is externally configurable",
		reorder_config_ok
	)

	resources.set_state(
		"domestic_accessible_supply",
		{
			"coal": 100.0
		}
	)

	reordered_system.process_month(
		world
	)

	var reordered_allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_category"
		)
	)

	var reordered_unmet: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_unmet_by_category"
		)
	)

	var reordered_ok: bool = (
		_approx_equal(
			float(
				reordered_allocated.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			15.0
		)
		and _approx_equal(
			float(
				reordered_allocated.get(
					"coal",
					{}
				).get(
					"government",
					-1.0
				)
			),
			10.0
		)
		and _approx_equal(
			float(
				reordered_allocated.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			30.0
		)
		and _approx_equal(
			float(
				reordered_allocated.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			45.0
		)
		and _approx_equal(
			float(
				reordered_unmet.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			15.0
		)
	)

	_log_result(
		"Changing priority order changes the allocation outcome deterministically",
		reordered_ok
	)

	# ------------------------------------------------------------
	# Case 4 — categories sharing one class split that class
	# proportionally rather than gaining a hidden secondary priority.
	# ------------------------------------------------------------
	var shared_class_config: Dictionary = {
		"priority_order": [
			"essential_consumption",
			"government",
			"military",
			"exports",
			"discretionary_use"
		],
		"category_to_priority_class": {
			"population": "essential_consumption",
			"industry": "essential_consumption",
			"government": "government",
			"military": "military",
			"exports": "exports"
		},
		"unmapped_category_fallback": "discretionary_use"
	}

	var shared_class_system := PriorityClassAllocationSystem.new(
		shared_class_config
	)

	resources.set_state(
		"domestic_accessible_supply",
		{
			"coal": 25.0
		}
	)

	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {
				"coal": 20.0
			},
			"industry": {
				"coal": 10.0
			},
			"government": {
				"coal": 10.0
			},
			"military": {
				"coal": 5.0
			},
			"exports": {
				"coal": 0.0
			}
		}
	)

	shared_class_system.process_month(
		world
	)

	var shared_allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_category"
		)
	)

	var shared_ok: bool = (
		_approx_equal(
			float(
				shared_allocated.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			(20.0 / 30.0) * 25.0
		)
		and _approx_equal(
			float(
				shared_allocated.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			(10.0 / 30.0) * 25.0
		)
		and _approx_equal(
			float(
				shared_allocated.get(
					"coal",
					{}
				).get(
					"government",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				shared_allocated.get(
					"coal",
					{}
				).get(
					"military",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Categories sharing a priority class split proportionally",
		shared_ok
	)

	# ------------------------------------------------------------
	# Case 5 — zero accessible supply.
	# ------------------------------------------------------------
	resources.set_state(
		"domestic_accessible_supply",
		{
			"coal": 0.0
		}
	)

	shared_class_system.process_month(
		world
	)

	var zero_allocated: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocated_supply_by_category"
		)
	)

	var zero_unmet: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_unmet_by_category"
		)
	)

	var zero_ok: bool = (
		_approx_equal(
			float(
				zero_allocated.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				zero_unmet.get(
					"coal",
					{}
				).get(
					"population",
					-1.0
				)
			),
			20.0
		)
		and _approx_equal(
			float(
				zero_unmet.get(
					"coal",
					{}
				).get(
					"industry",
					-1.0
				)
			),
			10.0
		)
	)

	_log_result(
		"Zero accessible supply creates complete priority shortfalls safely",
		zero_ok
	)

	# ------------------------------------------------------------
	# Idempotence.
	# ------------------------------------------------------------
	var ledger_before_repeat: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_ledger"
		).duplicate(true)
	)

	shared_class_system.process_month(
		world
	)

	var ledger_after_repeat: Dictionary = (
		_get_resource_map(
			resources,
			"priority_allocation_ledger"
		).duplicate(true)
	)

	var idempotent_ok: bool = (
		ledger_before_repeat == ledger_after_repeat
		and _approx_equal(
			float(
				_get_resource_map(
					resources,
					"priority_allocation_reconciliation_error"
				).get(
					"coal",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Repeated priority allocation processing is deterministic and idempotent",
		idempotent_ok
	)

	# ------------------------------------------------------------
	# Stale-state clearing.
	# ------------------------------------------------------------
	resources.set_state(
		"domestic_accessible_supply",
		{}
	)

	resources.set_state(
		"aggregate_demand_by_category",
		{}
	)

	priority_system.process_month(
		world
	)

	var stale_ok: bool = (
		resources.get_state(
			"priority_claim_by_class",
			{}
		).is_empty()
		and resources.get_state(
			"priority_allocated_supply_by_category",
			{}
		).is_empty()
		and resources.get_state(
			"priority_allocation_ledger",
			{}
		).is_empty()
	)

	_log_result(
		"Priority allocation state clears when upstream inputs clear",
		stale_ok
	)

	# ------------------------------------------------------------
	# Snapshot representation.
	# ------------------------------------------------------------
	var world_snapshot := WorldSnapshot.new()

	world_snapshot.capture(
		world
	)

	var entity_snapshot: Dictionary = world_snapshot.entities.get(
		test_entity.id,
		{}
	)

	var component_snapshots: Dictionary = (
		entity_snapshot.get(
			"components",
			{}
		)
	)

	var resource_snapshot: Dictionary = (
		component_snapshots.get(
			"resources",
			{}
		)
	)

	var resource_state_snapshot: Dictionary = (
		resource_snapshot.get(
			"state",
			{}
		)
	)

	var snapshot_ok: bool = (
		entity_snapshot.has("components")
		and resource_state_snapshot.has(
			"priority_class_order"
		)
		and resource_state_snapshot.has(
			"priority_allocation_ledger"
		)
	)

	_log_result(
		"Priority allocation state remains represented in world snapshot state",
		snapshot_ok
	)

	world.entities.clear()

	for entity_id in original_entities.keys():
		world.entities[entity_id] = (
			original_entities[entity_id]
		)

	var all_passed: bool = (
		system_ok
		and default_config_ok
		and scarce_ok
		and export_boundary_ok
		and upstream_unchanged_ok
		and non_scarce_ok
		and reorder_config_ok
		and reordered_ok
		and shared_ok
		and zero_ok
		and idempotent_ok
		and stale_ok
		and snapshot_ok
	)

	TestLogger.write_line(
		"Basic Priority Classes 7.2 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
