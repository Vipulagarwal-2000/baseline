class_name ScarceResourceAllocationTest
extends RefCounted


static func _approx_equal(actual: float, expected: float) -> bool:
	return is_equal_approx(actual, expected)


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"SCARCE RESOURCE ALLOCATION TEST"
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
		"scarce_resource_allocation_system"
	)

	var system_ok: bool = (
		system != null
		and system is ScarceResourceAllocationSystem
	)

	_log_result(
		"Registered ScarceResourceAllocationSystem available",
		system_ok
	)

	if not system_ok:
		return false

	var original_entities: Dictionary = world.entities.duplicate()

	var test_entity := SimEntity.new(
		"step_7_1_scarce_allocation_test",
		"Step 7.1 Scarce Resource Allocation Test",
		"country"
	)

	var resources := ResourceComponent.new(
		test_entity.id
	)
	test_entity.add_component(resources)

	world.entities.clear()
	world.add_entity(test_entity)

	# 100 units accessible, 120 domestic claims:
	# population 30, industry 60, government 10, military 15,
	# with 5 units of external demand reserved outside the domestic pool.
	resources.set_state(
		"domestic_accessible_supply",
		{"coal": 100.0}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{
			"population": {"coal": 30.0},
			"industry": {"coal": 60.0},
			"government": {"coal": 10.0},
			"military": {"coal": 15.0},
			"exports": {"coal": 5.0}
		}
	)
	resources.set_state(
		"allocated_supply_by_category",
		{
			"population": {
				"coal": 26.0869565217391
			},
			"industry": {
				"coal": 52.1739130434783
			},
			"government": {
				"coal": 8.69565217391304
			},
			"military": {
				"coal": 13.0434782608696
			}
		}
	)
	resources.set_state(
		"allocated_supply_total",
		{"coal": 100.0}
	)
	resources.set_state(
		"allocation_unmet_by_category",
		{
			"population": {
				"coal": 3.91304347826087
			},
			"industry": {
				"coal": 7.82608695652174
			},
			"government": {
				"coal": 1.30434782608696
			},
			"military": {
				"coal": 1.95652173913044
			}
		}
	)

	var original_accessible := float(
		resources.get_state(
			"domestic_accessible_supply",
			{}
		).get("coal", -1.0)
	)
	var original_claim := float(
		resources.get_state(
			"aggregate_demand_by_category",
			{}
		).get("industry", {}).get("coal", -1.0)
	)

	(system as ScarceResourceAllocationSystem).process_month(
		world
	)

	var scarcity_state: Dictionary = resources.get_state(
		"scarcity_active",
		{}
	)
	var claims_total: Dictionary = resources.get_state(
		"domestic_claims_total",
		{}
	)
	var fulfillment: Dictionary = resources.get_state(
		"allocation_fulfillment_ratio_by_category",
		{}
	)
	var shortfall: Dictionary = resources.get_state(
		"allocation_shortfall_ratio_by_category",
		{}
	)
	var exhausted: Dictionary = resources.get_state(
		"allocation_exhausted",
		{}
	)

	var scarcity_ok: bool = (
		bool(scarcity_state.get("coal", false))
		and _approx_equal(
			float(claims_total.get("coal", -1.0)),
			115.0
		)
		and bool(exhausted.get("coal", false))
	)

	_log_result(
		"Scarcity is detected from insufficient domestic accessible supply",
		scarcity_ok
	)

	var proportional_baseline_ok: bool = (
		_approx_equal(
			float(
				fulfillment.get("coal", {}).get(
					"population",
					-1.0
				)
			),
			100.0 / 115.0
		)
		and _approx_equal(
			float(
				fulfillment.get("coal", {}).get(
					"industry",
					-1.0
				)
			),
			100.0 / 115.0
		)
		and _approx_equal(
			float(
				fulfillment.get("coal", {}).get(
					"government",
					-1.0
				)
			),
			100.0 / 115.0
		)
		and _approx_equal(
			float(
				fulfillment.get("coal", {}).get(
					"military",
					-1.0
				)
			),
			100.0 / 115.0
		)
	)

	_log_result(
		"Baseline scarce allocation preserves the existing proportional claim rule",
		proportional_baseline_ok
	)

	var shortfall_ok: bool = (
		_approx_equal(
			float(
				shortfall.get("coal", {}).get(
					"population",
					-1.0
				)
			),
			15.0 / 115.0
		)
		and _approx_equal(
			float(
				shortfall.get("coal", {}).get(
					"industry",
					-1.0
				)
			),
			15.0 / 115.0
		)
		and _approx_equal(
			float(
				shortfall.get("coal", {}).get(
					"government",
					-1.0
				)
			),
			15.0 / 115.0
		)
		and _approx_equal(
			float(
				shortfall.get("coal", {}).get(
					"military",
					-1.0
				)
			),
			15.0 / 115.0
		)
	)

	_log_result(
		"Scarce allocation records explicit category shortfall ratios",
		shortfall_ok
	)

	var ledger: Dictionary = resources.get_state(
		"scarce_resource_allocation_ledger",
		{}
	)
	var ledger_coal: Dictionary = ledger.get(
		"coal",
		{}
	)

	var ledger_ok: bool = (
		_approx_equal(
			float(
				ledger_coal.get(
					"accessible_supply",
					-1.0
				)
			),
			100.0
		)
		and _approx_equal(
			float(
				ledger_coal.get(
					"domestic_claims",
					-1.0
				)
			),
			115.0
		)
		and _approx_equal(
			float(
				ledger_coal.get(
					"allocated_supply",
					-1.0
				)
			),
			100.0
		)
		and bool(
			ledger_coal.get(
				"scarcity_active",
				false
			)
		)
		and _approx_equal(
			float(
				ledger_coal.get(
					"reconciliation_error",
					-1.0
				)
			),
			0.0
		)
	)

	_log_result(
		"Scarce allocation ledger reconciles supply and claims",
		ledger_ok
	)

	var upstream_unchanged: bool = (
		_approx_equal(
			float(
				resources.get_state(
					"domestic_accessible_supply",
					{}
				).get("coal", -1.0)
			),
			original_accessible
		)
		and _approx_equal(
			float(
				resources.get_state(
					"aggregate_demand_by_category",
					{}
				).get("industry", {}).get("coal", -1.0)
			),
			original_claim
		)
	)

	_log_result(
		"Scarce allocation does not mutate upstream supply or demand state",
		upstream_unchanged
	)

	# Non-scarce case: 150 accessible against the same 115 claims.
	resources.set_state(
		"domestic_accessible_supply",
		{"coal": 150.0}
	)
	(system as ScarceResourceAllocationSystem).process_month(
		world
	)

	var non_scarce_state: Dictionary = resources.get_state(
		"scarcity_active",
		{}
	)
	var non_scarce_fulfillment: Dictionary = (
		resources.get_state(
			"allocation_fulfillment_ratio_by_category",
			{}
		)
	)
	var non_scarce_ok: bool = (
		not bool(non_scarce_state.get("coal", true))
		and _approx_equal(
			float(
				non_scarce_fulfillment.get("coal", {}).get(
					"industry",
					-1.0
				)
			),
			100.0 / 115.0
		)
	)

	_log_result(
		"Non-scarce classification remains neutral without inventing extra allocation",
		non_scarce_ok
	)

	# Zero supply: every positive claim has full shortfall.
	resources.set_state(
		"domestic_accessible_supply",
		{"coal": 0.0}
	)
	resources.set_state(
		"allocated_supply_by_category",
		{
			"population": {"coal": 0.0},
			"industry": {"coal": 0.0},
			"government": {"coal": 0.0},
			"military": {"coal": 0.0}
		}
	)
	resources.set_state(
		"allocated_supply_total",
		{"coal": 0.0}
	)
	resources.set_state(
		"allocation_unmet_by_category",
		{
			"population": {"coal": 30.0},
			"industry": {"coal": 60.0},
			"government": {"coal": 10.0},
			"military": {"coal": 15.0}
		}
	)
	(system as ScarceResourceAllocationSystem).process_month(
		world
	)

	var zero_fulfillment: Dictionary = resources.get_state(
		"allocation_fulfillment_ratio_by_category",
		{}
	)
	var zero_shortfall: Dictionary = resources.get_state(
		"allocation_shortfall_ratio_by_category",
		{}
	)

	var zero_supply_ok: bool = (
		zero_fulfillment.get("coal", {}).get(
			"population",
			-1.0
		) == 0.0
		and zero_shortfall.get("coal", {}).get(
			"population",
			-1.0
		) == 1.0
		and zero_fulfillment.get("coal", {}).get(
			"industry",
			-1.0
		) == 0.0
		and zero_shortfall.get("coal", {}).get(
			"industry",
			-1.0
		) == 1.0
	)

	_log_result(
		"Zero accessible supply produces complete category shortfall safely",
		zero_supply_ok
	)

	# Idempotence.
	(system as ScarceResourceAllocationSystem).process_month(
		world
	)

	var idempotent_ledger: Dictionary = (
		resources.get_state(
			"scarce_resource_allocation_ledger",
			{}
		)
	)
	var idempotent_ok: bool = (
		idempotent_ledger.get("coal", {}).get(
			"scarcity_active",
			false
		)
		and _approx_equal(
			float(
				resources.get_state(
					"scarce_resource_allocation_reconciliation_error",
					{}
				).get("coal", -1.0)
			),
			0.0
		)
	)

	_log_result(
		"Repeated scarce-allocation processing is deterministic and idempotent",
		idempotent_ok
	)

	# Stale-state clearing.
	resources.set_state(
		"domestic_accessible_supply",
		{}
	)
	resources.set_state(
		"aggregate_demand_by_category",
		{}
	)
	resources.set_state(
		"allocated_supply_by_category",
		{}
	)
	resources.set_state(
		"allocated_supply_total",
		{}
	)
	resources.set_state(
		"allocation_unmet_by_category",
		{}
	)

	(system as ScarceResourceAllocationSystem).process_month(
		world
	)

	var stale_ok: bool = (
		resources.get_state(
			"scarcity_active",
			{}
		).is_empty()
		and resources.get_state(
			"domestic_claims_total",
			{}
		).is_empty()
		and resources.get_state(
			"scarce_resource_allocation_ledger",
			{}
		).is_empty()
	)

	_log_result(
		"Scarce allocation state clears when upstream allocation state clears",
		stale_ok
	)

	# Snapshot representation uses the existing world snapshot architecture.
	# SimEntity does not expose to_snapshot_dict(); WorldSnapshot is the
	# authoritative entity/component snapshot path.
	var world_snapshot := WorldSnapshot.new()
	world_snapshot.capture(world)

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
		entity_snapshot.has("components")
		and resource_state_snapshot.has("scarcity_active")
		and resource_state_snapshot.has("domestic_claims_total")
		and resource_state_snapshot.has("scarce_resource_allocation_ledger")
	)

	_log_result(
		"Scarce allocation state remains represented in world snapshot state",
		snapshot_ok
	)

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]

	var all_passed: bool = (
		system_ok
		and scarcity_ok
		and proportional_baseline_ok
		and shortfall_ok
		and ledger_ok
		and upstream_unchanged
		and non_scarce_ok
		and zero_supply_ok
		and idempotent_ok
		and stale_ok
		and snapshot_ok
	)

	TestLogger.write_line(
		"Scarce Resource Allocation 7.1 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
