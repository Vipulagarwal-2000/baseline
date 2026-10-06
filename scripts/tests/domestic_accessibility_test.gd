class_name DomesticAccessibilityTest
extends RefCounted


const EPSILON: float = 0.000001


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


static func _get_dictionary(
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


static func _max_reconciliation_error(
	errors: Dictionary
) -> float:

	var maximum := 0.0

	for value in errors.values():
		maximum = maxf(
			maximum,
			absf(float(value))
		)

	return maximum


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"DOMESTIC ACCESSIBILITY TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var accessibility_system_instance = simulation.get_system(
		"domestic_accessibility_system"
	)

	var system_ok: bool = (
		accessibility_system_instance != null
		and accessibility_system_instance is DomesticAccessibilitySystem
	)

	_log_result(
		"Registered DomesticAccessibilitySystem available",
		system_ok
	)

	if not system_ok:
		return false

	var accessibility_system: DomesticAccessibilitySystem = (
		accessibility_system_instance as DomesticAccessibilitySystem
	)

	var distribution_system_instance = simulation.get_system(
		"resource_allocation_distribution_system"
	)

	var distribution_ok: bool = (
		distribution_system_instance != null
		and distribution_system_instance is ResourceAllocationDistributionSystem
	)

	_log_result(
		"Registered Step 5.10 distribution system available",
		distribution_ok
	)

	if not distribution_ok:
		return false

	var distribution_system: ResourceAllocationDistributionSystem = (
		distribution_system_instance as ResourceAllocationDistributionSystem
	)

	var priority_system_instance = simulation.get_system(
		"priority_class_allocation_system"
	)

	var priority_ok: bool = (
		priority_system_instance != null
		and priority_system_instance is PriorityClassAllocationSystem
	)

	_log_result(
		"Registered PriorityClassAllocationSystem available",
		priority_ok
	)

	if not priority_ok:
		return false

	var priority_system: PriorityClassAllocationSystem = (
		priority_system_instance as PriorityClassAllocationSystem
	)

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_7_3_domestic_accessibility_test",
		"Step 7.3 Domestic Accessibility Test",
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

	# Controlled physical state:
	# resolved supply = 100
	# exports reserved = 20
	# physical domestic supply = 80
	# accessibility = 0.75
	# accessible domestic supply = 60
	# access loss = 20
	resources.set_state(
		"resolved_supply",
		{"coal": 100.0}
	)
	resources.set_state(
		"exports",
		{"coal": 20.0}
	)
	resources.set_state(
		"stockpile",
		{"coal": 250.0}
	)
	resources.set_state(
		"accessibility",
		{"coal": 0.75}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {"coal": 20.0},
			"industry": {"coal": 30.0},
			"government": {"coal": 10.0},
			"military": {"coal": 10.0},
			"exports": {"coal": 20.0}
		}
	)

	var original_resolved_supply: Dictionary = (
		resources.get_state(
			"resolved_supply",
			{}
		).duplicate(true)
	)
	var original_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)
	var original_exports: Dictionary = (
		resources.get_state(
			"exports",
			{}
		).duplicate(true)
	)

	# ------------------------------------------------------------
	# Case 1 — resolve the existing Step 5.10 physical/accessibility
	# result and expose it through the explicit 7.3 state.
	# ------------------------------------------------------------
	distribution_system.process_month(
		world
	)
	accessibility_system.process_month(
		world
	)

	var physical_domestic: Dictionary = _get_dictionary(
		resources,
		"domestic_physical_supply"
	)
	var accessibility_factor: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_factor"
	)
	var accessibility_ledger: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_ledger"
	)
	var reconciliation_errors: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_reconciliation_error"
	)

	var authoritative_inputs_ok: bool = (
		_approx_equal(
			float(
				physical_domestic.get(
					"coal",
					-1.0
				)
			),
			80.0
		)
		and _approx_equal(
			float(
				accessibility_factor.get(
					"coal",
					-1.0
				)
			),
			0.75
		)
		and accessibility_ledger.get(
			"coal",
			{}
		).get(
			"source",
			""
		) == "step_5_10_resource_allocation_distribution"
	)

	_log_result(
		"Authoritative accessibility inputs discovered",
		authoritative_inputs_ok
	)

	var accessible_supply: float = float(
		_get_dictionary(
			resources,
			"domestic_accessible_supply"
		).get(
			"coal",
			-1.0
		)
	)
	var access_loss: float = float(
		_get_dictionary(
			resources,
			"distribution_access_loss"
		).get(
			"coal",
			-1.0
		)
	)

	var accessible_resolution_ok: bool = (
		_approx_equal(
			accessible_supply,
			60.0
		)
		and _approx_equal(
			access_loss,
			20.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"domestic_accessibility_total_physical",
					-1.0
				)
			),
			80.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"domestic_accessibility_total_accessible",
					-1.0
				)
			),
			60.0
		)
	)

	_log_result(
		"Country-level accessible supply resolves correctly",
		accessible_resolution_ok
	)

	var reconciliation_ok: bool = (
		_approx_equal(
			80.0,
			accessible_supply + access_loss
		)
		and _approx_equal(
			_max_reconciliation_error(
				reconciliation_errors
			),
			0.0
		)
		and _approx_equal(
			float(
				accessibility_ledger.get(
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
		"Access loss reconciles with physical domestic supply",
		reconciliation_ok
	)

	# ------------------------------------------------------------
	# Case 2 — lower accessibility. The upstream physical supply must
	# remain unchanged while accessible quantity falls deterministically.
	# ------------------------------------------------------------
	resources.set_state(
		"accessibility",
		{"coal": 0.50}
	)

	distribution_system.process_month(
		world
	)
	accessibility_system.process_month(
		world
	)

	var reduced_accessible: float = float(
		_get_dictionary(
			resources,
			"domestic_accessible_supply"
		).get(
			"coal",
			-1.0
		)
	)
	var reduced_loss: float = float(
		_get_dictionary(
			resources,
			"distribution_access_loss"
		).get(
			"coal",
			-1.0
		)
	)

	var reduced_accessibility_ok: bool = (
		_approx_equal(
			reduced_accessible,
			40.0
		)
		and _approx_equal(
			reduced_loss,
			40.0
		)
		and _approx_equal(
			float(
				_get_dictionary(
					resources,
					"domestic_physical_supply"
				).get(
					"coal",
					-1.0
				)
			),
			80.0
		)
	)

	_log_result(
		"Reduced accessibility reduces accessible supply deterministically",
		reduced_accessibility_ok
	)

	var upstream_immutable_ok: bool = (
		_get_dictionary(
			resources,
			"resolved_supply"
		) == original_resolved_supply
		and _get_dictionary(
			resources,
			"stockpile"
		) == original_stockpile
		and _get_dictionary(
			resources,
			"exports"
		) == original_exports
	)

	_log_result(
		"Upstream physical supply / stockpile is not mutated",
		upstream_immutable_ok
	)

	# ------------------------------------------------------------
	# Case 3 — the existing priority overlay must consume the resolved
	# accessible pool, not the raw physical supply.
	# ------------------------------------------------------------
	priority_system.process_month(
		world
	)

	var priority_allocated: Dictionary = _get_dictionary(
		resources,
		"priority_allocated_supply_by_category"
	)
	var priority_total: float = 0.0
	var coal_priority: Dictionary = priority_allocated.get(
		"coal",
		{}
	)
	for value in coal_priority.values():
		priority_total += float(value)

	var priority_interaction_ok: bool = (
		_approx_equal(
			priority_total,
			40.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"priority_allocation_remaining_supply",
					{}
				).get(
					"coal",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Priority allocation consumes resolved accessible supply",
		priority_interaction_ok
	)

	# ------------------------------------------------------------
	# Case 4 — repeated 7.3 processing is deterministic and idempotent.
	# ------------------------------------------------------------
	var before_repeat_physical: Dictionary = _get_dictionary(
		resources,
		"domestic_physical_supply"
	).duplicate(true)
	var before_repeat_factor: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_factor"
	).duplicate(true)
	var before_repeat_ledger: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_ledger"
	).duplicate(true)

	accessibility_system.process_month(
		world
	)

	var after_repeat_physical: Dictionary = _get_dictionary(
		resources,
		"domestic_physical_supply"
	)
	var after_repeat_factor: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_factor"
	)
	var after_repeat_ledger: Dictionary = _get_dictionary(
		resources,
		"domestic_accessibility_ledger"
	)

	var idempotence_ok: bool = (
		after_repeat_physical == before_repeat_physical
		and after_repeat_factor == before_repeat_factor
		and after_repeat_ledger == before_repeat_ledger
	)

	_log_result(
		"Repeated processing is deterministic and idempotent",
		idempotence_ok
	)

	# ------------------------------------------------------------
	# Case 5 — clear upstream physical/access state, run the registered
	# Step 5.10 system, then 7.3. All derived accessibility state must clear.
	# ------------------------------------------------------------
	resources.set_state(
		"resolved_supply",
		{}
	)
	resources.set_state(
		"exports",
		{}
	)
	resources.set_state(
		"accessibility",
		{}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{}
	)

	distribution_system.process_month(
		world
	)
	accessibility_system.process_month(
		world
	)

	var stale_cleared_ok: bool = (
		_get_dictionary(
			resources,
			"domestic_physical_supply"
		).is_empty()
		and _get_dictionary(
			resources,
			"domestic_accessibility_factor"
		).is_empty()
		and _get_dictionary(
			resources,
			"domestic_accessibility_reconciliation_error"
		).is_empty()
		and _get_dictionary(
			resources,
			"domestic_accessibility_ledger"
		).is_empty()
		and _approx_equal(
			float(
				resources.get_state(
					"domestic_accessibility_total_physical",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"domestic_accessibility_total_accessible",
					-1.0
				)
			),
			0.0
		)
		and _approx_equal(
			float(
				resources.get_state(
					"domestic_accessibility_total_loss",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Cleared upstream inputs clear stale accessibility state",
		stale_cleared_ok
	)

	# ------------------------------------------------------------
	# Case 6 — ResourceComponent state is automatically snapshot-visible.
	# Rebuild the controlled fixture first so the snapshot contains a live
	# 7.3 result.
	# ------------------------------------------------------------
	resources.set_state(
		"resolved_supply",
		{"coal": 100.0}
	)
	resources.set_state(
		"exports",
		{"coal": 20.0}
	)
	resources.set_state(
		"accessibility",
		{"coal": 0.50}
	)
	resources.set_state(
		"stockpile",
		{"coal": 250.0}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {"coal": 20.0},
			"industry": {"coal": 30.0},
			"government": {"coal": 10.0},
			"military": {"coal": 10.0},
			"exports": {"coal": 20.0}
		}
	)

	distribution_system.process_month(
		world
	)
	accessibility_system.process_month(
		world
	)

	var world_snapshot := WorldSnapshot.new()
	world_snapshot.capture(
		world
	)

	var entity_snapshot: Dictionary = world_snapshot.entities.get(
		test_entity.id,
		{}
	)
	var component_snapshots: Dictionary = entity_snapshot.get(
		"components",
		{}
	)
	var resource_snapshot: Dictionary = component_snapshots.get(
		"resources",
		{}
	)
	var resource_state_snapshot: Dictionary = resource_snapshot.get(
		"state",
		{}
	)

	var snapshot_ok: bool = (
		resource_state_snapshot.has(
			"domestic_physical_supply"
		)
		and resource_state_snapshot.has(
			"domestic_accessibility_factor"
		)
		and resource_state_snapshot.has(
			"domestic_accessibility_ledger"
		)
		and _approx_equal(
			float(
				resource_state_snapshot.get(
					"domestic_accessibility_total_accessible",
					-1.0
				)
			),
			40.0
		)
	)

	_log_result(
		"Accessibility state remains represented in world snapshot state",
		snapshot_ok
	)

	# ------------------------------------------------------------
	# Case 7 — validate the registered 7.3 system against the real
	# three-country validation world after restoring the test fixture.
	# ------------------------------------------------------------
	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	var three_country_world_ok: bool = (
		world.entities.size() == 3
	)

	var processed_resource_entities := 0
	var three_country_errors_ok := true

	if three_country_world_ok:
		accessibility_system.process_month(
			world
		)

		for entity in world.entities.values():
			if entity == null:
				continue

			var country_resources = entity.get_component(
				"resources"
			)

			if country_resources == null:
				continue

			processed_resource_entities += 1

			var errors: Dictionary = _get_dictionary(
				country_resources,
				"domestic_accessibility_reconciliation_error"
			)

			if _max_reconciliation_error(errors) > EPSILON:
				three_country_errors_ok = false

	three_country_world_ok = (
		three_country_world_ok
		and processed_resource_entities == 3
		and three_country_errors_ok
	)

	_log_result(
		"Three-country world validation remains clean",
		three_country_world_ok
	)

	var all_passed: bool = (
		system_ok
		and distribution_ok
		and priority_ok
		and authoritative_inputs_ok
		and accessible_resolution_ok
		and reconciliation_ok
		and reduced_accessibility_ok
		and upstream_immutable_ok
		and priority_interaction_ok
		and idempotence_ok
		and stale_cleared_ok
		and snapshot_ok
		and three_country_world_ok
	)

	TestLogger.write_line(
		"Domestic Accessibility 7.3 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
