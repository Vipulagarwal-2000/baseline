class_name RegionalTransportTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.8
# REGIONAL TRANSPORT TEST
# ============================================================


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
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"REGIONALIZATION — STEP 12.8 REGIONAL TRANSPORT TEST"
	)

	var passed := true

	var world_ok := world != null
	_log_result("World available", world_ok)
	passed = passed and world_ok
	if world == null:
		return false

	var simulation_ok := simulation != null
	_log_result("Simulation available", simulation_ok)
	passed = passed and simulation_ok
	if simulation == null:
		return false

	var system = simulation.get_system(
		"regional_transport_system"
	)
	var system_ok := system != null
	_log_result(
		"Registered RegionalTransportSystem available",
		system_ok
	)
	passed = passed and system_ok
	if not system_ok:
		return false

	var transport_system: RegionalTransportSystem = system

	var node_count_ok := (
		world.get_regional_transport_node_count() == 16
	)
	_log_result(
		"Regional transport node registry contains 16 parent nodes",
		node_count_ok
	)
	passed = passed and node_count_ok

	var route_count_ok := (
		world.get_regional_transport_route_count() == 13
	)
	_log_result(
		"Regional transport route registry contains 13 domestic routes",
		route_count_ok
	)
	passed = passed and route_count_ok

	var country_node_counts_ok := (
		_count_country_nodes(world, "china") == 6
		and _count_country_nodes(world, "india") == 6
		and _count_country_nodes(world, "usa") == 4
	)
	_log_result(
		"China/India/USA regional transport node counts = 6/6/4",
		country_node_counts_ok
	)
	passed = passed and country_node_counts_ok

	var country_route_counts_ok := (
		_count_country_routes(world, "china") == 5
		and _count_country_routes(world, "india") == 5
		and _count_country_routes(world, "usa") == 3
	)
	_log_result(
		"China/India/USA regional transport route counts = 5/5/3",
		country_route_counts_ok
	)
	passed = passed and country_route_counts_ok

	var infrastructure_ok := true
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null or entity.get_component("infrastructure") == null:
			infrastructure_ok = false
	_log_result(
		"Country infrastructure components available for transport seeding",
		infrastructure_ok
	)
	passed = passed and infrastructure_ok

	var hierarchy_ok := true
	for region_value in world.regions.values():
		var region := region_value as Region
		if region == null:
			continue
		var node = world.get_regional_transport_node(region.id)
		if region.is_region():
			if node == null or node.structural_country_id != region.country_id:
				hierarchy_ok = false
		else:
			if node != null:
				hierarchy_ok = false
	_log_result(
		"Transport nodes attach only to parent regional hierarchy",
		hierarchy_ok
	)
	passed = passed and hierarchy_ok

	var node_capacity_formula_ok := true
	for node_value in world.regional_transport_nodes.values():
		var node := node_value as RegionalTransportNode
		if node == null:
			node_capacity_formula_ok = false
			continue
		var expected_factor: float = clampf(
			node.transport_factor * 0.40
			+ node.road_factor * 0.30
			+ node.railway_factor * 0.30,
			0.0,
			1.0
		)
		var expected_capacity: float = node.base_capacity * expected_factor * node.condition
		if node.blocked:
			expected_capacity = 0.0
		if not is_equal_approx(node.effective_capacity, expected_capacity):
			node_capacity_formula_ok = false

	_log_result(
		"Regional node capacity deterministically derives from existing infrastructure factors",
		node_capacity_formula_ok
	)
	passed = passed and node_capacity_formula_ok

	var routes_valid_ok := true
	for route_value in world.regional_transport_routes.values():
		var route := route_value as RegionalTransportRoute
		if route == null or not route.is_valid():
			routes_valid_ok = false
			continue

		var from_node: RegionalTransportNode = world.get_regional_transport_node(route.from_region_id)
		var to_node: RegionalTransportNode = world.get_regional_transport_node(route.to_region_id)
		if from_node == null or to_node == null:
			routes_valid_ok = false
			continue
		if from_node.structural_country_id != route.structural_country_id:
			routes_valid_ok = false
		if to_node.structural_country_id != route.structural_country_id:
			routes_valid_ok = false
		if route.effective_capacity < 0.0:
			routes_valid_ok = false
		if route.effective_capacity > route.base_capacity + 0.000001:
			routes_valid_ok = false
		if route.transport_cost <= 0.0:
			routes_valid_ok = false

	_log_result(
		"Regional transport routes validate endpoint, capacity, and cost state",
		routes_valid_ok
	)
	passed = passed and routes_valid_ok

	var connectivity_ok := transport_system.validate_world(world)
	_log_result(
		"Each country's regional transport graph is connected",
		connectivity_ok
	)
	passed = passed and connectivity_ok

	var snapshot: Dictionary = transport_system.snapshot_world(world)
	var snapshot_isolated := true
	if not snapshot.get("nodes", {}).is_empty():
		var first_node_id: String = str(snapshot["nodes"].keys()[0])
		var snap_node: Dictionary = snapshot["nodes"][first_node_id]
		var original_live_capacity: float = float(
			world.get_regional_transport_node(first_node_id).effective_capacity
		)
		snap_node["effective_capacity"] = original_live_capacity + 999.0
		if not is_equal_approx(
			float(world.get_regional_transport_node(first_node_id).effective_capacity),
			original_live_capacity
		):
			snapshot_isolated = false

	_log_result(
		"Regional transport snapshot is isolated from live state",
		snapshot_isolated
	)
	passed = passed and snapshot_isolated

	var hierarchy_before: Dictionary = _capture_hierarchy(world)
	var ownership_before: Dictionary = _capture_simple_registry(world.regional_ownership)
	var terrain_before: Dictionary = _capture_simple_registry(world.regional_terrain)
	var population_before: Dictionary = _capture_simple_registry(world.regional_population)
	var resource_before: Dictionary = _capture_simple_registry(world.regional_resources)
	var industry_before: Dictionary = _capture_simple_registry(world.regional_industry)
	var country_infrastructure_before: Dictionary = _capture_country_infrastructure(world)

	var first_route_id: String = ""
	if not world.regional_transport_routes.is_empty():
		first_route_id = str(world.regional_transport_routes.keys()[0])

	var mutation_ok := false
	if not first_route_id.is_empty():
		var route: RegionalTransportRoute = world.get_regional_transport_route(first_route_id)
		var from_node: RegionalTransportNode = world.get_regional_transport_node(route.from_region_id)
		var to_node: RegionalTransportNode = world.get_regional_transport_node(route.to_region_id)
		var original_effective: float = route.effective_capacity
		var original_condition: float = route.condition

		mutation_ok = route.set_condition(0.5)
		route.recalculate_effective_capacity(from_node, to_node)
		mutation_ok = (
			mutation_ok
			and route.effective_capacity <= original_effective + 0.000001
			and route.effective_capacity < original_effective - 0.000001
		)

		route.set_condition(original_condition)
		route.clear_route_restriction()
		route.recalculate_effective_capacity(from_node, to_node)

	_log_result(
		"Explicit regional transport route mutation changes route state",
		mutation_ok
	)
	passed = passed and mutation_ok

	var hierarchy_after: Dictionary = _capture_hierarchy(world)
	var hierarchy_preserved := hierarchy_before == hierarchy_after
	_log_result(
		"Transport mutation does not rewrite region hierarchy",
		hierarchy_preserved
	)
	passed = passed and hierarchy_preserved

	var monthly_snapshot: Dictionary = transport_system.snapshot_world(world)
	transport_system.process_month(world)
	var monthly_after_snapshot: Dictionary = transport_system.snapshot_world(world)
	var monthly_inert := monthly_snapshot == monthly_after_snapshot
	_log_result(
		"Step 12.8 monthly processing remains inert",
		monthly_inert
	)
	passed = passed and monthly_inert

	var ownership_after: Dictionary = _capture_simple_registry(world.regional_ownership)
	var terrain_after: Dictionary = _capture_simple_registry(world.regional_terrain)
	var population_after: Dictionary = _capture_simple_registry(world.regional_population)
	var resource_after: Dictionary = _capture_simple_registry(world.regional_resources)
	var industry_after: Dictionary = _capture_simple_registry(world.regional_industry)
	var country_infrastructure_after: Dictionary = _capture_country_infrastructure(world)

	var cross_layer_preserved := (
		ownership_before == ownership_after
		and terrain_before == terrain_after
		and population_before == population_after
		and resource_before == resource_after
		and industry_before == industry_after
		and country_infrastructure_before == country_infrastructure_after
	)
	_log_result(
		"Existing regional ownership/terrain/population/resource/industry state remains unchanged",
		cross_layer_preserved
	)
	passed = passed and cross_layer_preserved

	var duplicate_loader := RegionalTransportDataLoader.new()
	var duplicate_profiles: Dictionary = duplicate_loader.load_all_transport_profiles(
		"res://data/regions/transport"
	)
	var duplicate_rejected := not transport_system.initialize_world(
		world,
		duplicate_profiles
	)
	var duplicate_safe := (
		duplicate_rejected
		and world.get_regional_transport_node_count() == 16
		and world.get_regional_transport_route_count() == 13
	)
	_log_result(
		"Second transport initialization is rejected without duplication",
		duplicate_safe
	)
	passed = passed and duplicate_safe

	var fixture_restore_ok := _restore_first_route_and_validate(
		world,
		transport_system,
		first_route_id,
		snapshot
	)
	_log_result(
		"Transport fixture restores exact baseline",
		fixture_restore_ok
	)
	passed = passed and fixture_restore_ok

	var final_validation := transport_system.validate_world(world)
	_log_result(
		"Final regional transport validation",
		final_validation
	)
	passed = passed and final_validation

	TestLogger.write_line(
		"Regionalization 12.8 overall: "
		+ ("PASS" if passed else "FAIL")
	)
	TestLogger.write_line(
		"Regionalization 12.8 test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _count_country_nodes(
	world: WorldState,
	country_id: String
) -> int:
	var count: int = 0
	for node_value in world.regional_transport_nodes.values():
		var node := node_value as RegionalTransportNode
		if node != null and node.structural_country_id == country_id:
			count += 1
	return count


static func _count_country_routes(
	world: WorldState,
	country_id: String
) -> int:
	var count: int = 0
	for route_value in world.regional_transport_routes.values():
		var route := route_value as RegionalTransportRoute
		if route != null and route.structural_country_id == country_id:
			count += 1
	return count


static func _capture_hierarchy(
	world: WorldState
) -> Dictionary:
	var result: Dictionary = {}
	for value in world.regions.values():
		var region := value as Region
		if region == null:
			continue
		result[region.id] = {
			"country_id": region.country_id,
			"parent_region_id": region.parent_region_id,
			"level": region.level,
			"source_geography_key": region.source_geography_key
		}
	return result


static func _capture_simple_registry(
	registry: Dictionary
) -> Dictionary:
	var result: Dictionary = {}
	for key_value in registry.keys():
		var key: String = str(key_value)
		var value = registry[key]
		if value != null and value.has_method("to_snapshot_dict"):
			result[key] = value.to_snapshot_dict()
		else:
			result[key] = str(value)
	return result


static func _capture_country_infrastructure(
	world: WorldState
) -> Dictionary:
	var result: Dictionary = {}
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null:
			result[country_id] = {}
			continue
		var infrastructure = entity.get_component("infrastructure")
		if infrastructure == null:
			result[country_id] = {}
			continue
		result[country_id] = {
			"transport": float(infrastructure.get_state("transport", 0.0)),
			"roads": float(infrastructure.get_state("roads", 0.0)),
			"railways": float(infrastructure.get_state("railways", 0.0)),
			"ports": float(infrastructure.get_state("ports", 0.0))
		}
	return result


static func _restore_first_route_and_validate(
	world: WorldState,
	system: RegionalTransportSystem,
	route_id: String,
	snapshot: Dictionary
) -> bool:
	if route_id.is_empty():
		return false
	if not snapshot.has("routes"):
		return false
	if not snapshot["routes"].has(route_id):
		return false

	var route: RegionalTransportRoute = world.get_regional_transport_route(route_id)
	if route == null:
		return false
	var baseline: Dictionary = snapshot["routes"][route_id]

	route.condition = float(baseline["condition"])
	route.blocked = bool(baseline["blocked"])
	route.restriction_active = bool(baseline["restriction_active"])
	route.restriction_factor = float(baseline["restriction_factor"])
	route.restriction_reason = str(baseline["restriction_reason"])

	var from_node: RegionalTransportNode = world.get_regional_transport_node(route.from_region_id)
	var to_node: RegionalTransportNode = world.get_regional_transport_node(route.to_region_id)
	route.recalculate_effective_capacity(from_node, to_node)

	var restored := route.to_snapshot_dict()
	return restored == baseline and system.validate_world(world)
