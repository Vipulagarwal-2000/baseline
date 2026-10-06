class_name RegionalTransportSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.8
# REGIONAL TRANSPORT SYSTEM
# ============================================================
#
# Static parent-region graph/network layer.
# Priority 94 follows Step 12.7 industry at 93.
#
# This system does NOT execute trade, move resources, alter stocks,
# or replace existing country-level transport infrastructure logic.
# It exposes regional route capacity/cost/restriction state that later
# systems can consume.
# ============================================================


const WORLD_UPDATE_PRIORITY: int = 94


func _init() -> void:
	super("regional_transport_system")


func process_month(
	world: WorldState
) -> void:
	# Step 12.8 is intentionally inert during monthly processing.
	# Graph execution/route flow belongs to later systems.
	if world == null:
		return


func initialize_world(
	world: WorldState,
	country_profiles: Dictionary
) -> bool:
	if world == null:
		return false
	if country_profiles.is_empty():
		return false

	if world.get_regional_transport_node_count() > 0:
		push_error(
			"RegionalTransportSystem: Transport graph already initialized."
		)
		return false

	if not _validate_profile_coverage(world, country_profiles):
		return false

	for country_id_value in country_profiles.keys():
		var country_id: String = str(country_id_value)
		var profile_value: Variant = country_profiles.get(country_id, null)
		if not profile_value is Dictionary:
			return false
		var profile: Dictionary = profile_value

		var country_entity = world.get_entity(country_id)
		if country_entity == null:
			return false

		var infrastructure_component = country_entity.get_component("infrastructure")
		if infrastructure_component == null:
			return false

		var nodes_value: Variant = profile.get("nodes", null)
		var routes_value: Variant = profile.get("routes", null)
		if not nodes_value is Array or not routes_value is Array:
			return false

		var nodes: Array = nodes_value
		var routes: Array = routes_value

		var node_profiles: Dictionary = {}
		for node_value in nodes:
			var node_profile: Dictionary = node_value
			var region_id: String = str(node_profile.get("region_id", ""))
			node_profiles[region_id] = node_profile

		for region_id_value in node_profiles.keys():
			var region_id: String = str(region_id_value)
			var node_profile_value: Variant = node_profiles.get(region_id, null)
			if not node_profile_value is Dictionary:
				return false
			var node_profile: Dictionary = node_profile_value

			var region = world.get_region(region_id) as Region
			if region == null:
				return false
			if not region.is_region():
				return false
			if region.country_id != country_id:
				return false

			var infrastructure_state = world.get_regional_infrastructure(region_id)
			if infrastructure_state == null:
				return false

			var node := RegionalTransportNode.new(
				region_id,
				country_id
			)

			var population_weight: float = float(
				infrastructure_state.aggregation_weight
			)
			if population_weight <= 0.0:
				population_weight = 0.0

			var initialized := node.apply_localization(
				infrastructure_state.to_snapshot_dict(),
				population_weight,
				float(node_profile["base_capacity"]),
				float(node_profile["transport_cost"]),
				float(node_profile["condition"]),
				bool(node_profile.get("blocked", false))
			)
			if not initialized:
				return false

			if not world.add_regional_transport_node(node):
				return false

		for route_value in routes:
			var route_profile: Dictionary = route_value
			var from_region_id: String = str(route_profile.get("from_region_id", ""))
			var to_region_id: String = str(route_profile.get("to_region_id", ""))

			var from_node: RegionalTransportNode = world.get_regional_transport_node(from_region_id)
			var to_node: RegionalTransportNode = world.get_regional_transport_node(to_region_id)
			if from_node == null or to_node == null:
				return false
			if from_node.structural_country_id != country_id:
				continue
			if to_node.structural_country_id != country_id:
				return false

			var route := RegionalTransportRoute.new(
				str(route_profile["route_id"]),
				country_id,
				from_region_id,
				to_region_id
			)

			if not route.apply_profile(
				float(route_profile["base_capacity"]),
				float(route_profile["transport_cost"]),
				float(route_profile["condition"]),
				bool(route_profile.get("blocked", false)),
				str(route_profile.get("route_type", "domestic"))
			):
				return false

			route.recalculate_effective_capacity(
				from_node,
				to_node
			)

			if not world.add_regional_transport_route(route):
				return false

	return validate_world(world)


func validate_world(
	world: WorldState
) -> bool:
	if world == null:
		return false

	for region_id_value in world.regions.keys():
		var region_id: String = str(region_id_value)
		var region := world.get_region(region_id) as Region
		if region == null:
			continue

		var node: RegionalTransportNode = world.get_regional_transport_node(region_id)
		if region.is_region():
			if node == null:
				return false
			if node.structural_country_id != region.country_id:
				return false
		else:
			if node != null:
				return false

	for route_id_value in world.regional_transport_routes.keys():
		var route_id: String = str(route_id_value)
		var route: RegionalTransportRoute = world.get_regional_transport_route(route_id)
		if route == null or not route.is_valid():
			return false

		var from_node: RegionalTransportNode = world.get_regional_transport_node(route.from_region_id)
		var to_node: RegionalTransportNode = world.get_regional_transport_node(route.to_region_id)
		if from_node == null or to_node == null:
			return false
		if from_node.structural_country_id != route.structural_country_id:
			return false
		if to_node.structural_country_id != route.structural_country_id:
			return false

		route.recalculate_effective_capacity(
			from_node,
			to_node
		)
		if route.effective_capacity < 0.0:
			return false
		if route.effective_capacity > route.base_capacity + 0.000001:
			return false

	return _validate_country_connectivity(world)


func snapshot_world(
	world: WorldState
) -> Dictionary:
	var snapshot: Dictionary = {
		"nodes": {},
		"routes": {}
	}
	if world == null:
		return snapshot

	for region_id_value in world.regional_transport_nodes.keys():
		var region_id: String = str(region_id_value)
		var node: RegionalTransportNode = world.get_regional_transport_node(region_id)
		if node != null:
			snapshot["nodes"][region_id] = node.to_snapshot_dict()

	for route_id_value in world.regional_transport_routes.keys():
		var route_id: String = str(route_id_value)
		var route: RegionalTransportRoute = world.get_regional_transport_route(route_id)
		if route != null:
			snapshot["routes"][route_id] = route.to_snapshot_dict()

	return snapshot


func _validate_profile_coverage(
	world: WorldState,
	country_profiles: Dictionary
) -> bool:
	for country_id in ["china", "india", "usa"]:
		if not country_profiles.has(country_id):
			return false
		var profile_value: Variant = country_profiles[country_id]
		if not profile_value is Dictionary:
			return false
		var profile: Dictionary = profile_value
		if not RegionalTransportDataLoader.new().validate_transport_profile(profile):
			return false

		var expected_parent_count: int = 0
		for region_value in world.regions.values():
			var region := region_value as Region
			if region != null and region.is_region() and region.country_id == country_id:
				expected_parent_count += 1

		var nodes_value: Variant = profile.get("nodes", null)
		if not nodes_value is Array:
			return false
		var nodes: Array = nodes_value
		if nodes.size() != expected_parent_count:
			return false

	return true


func _validate_country_connectivity(
	world: WorldState
) -> bool:
	for country_id in ["china", "india", "usa"]:
		var country_regions: Array[String] = []
		for region_value in world.regions.values():
			var region := region_value as Region
			if region != null and region.is_region() and region.country_id == country_id:
				country_regions.append(region.id)

		if country_regions.is_empty():
			return false

		var visited: Dictionary = {}
		var queue: Array[String] = [country_regions[0]]
		while not queue.is_empty():
			var current: String = queue.pop_front()
			if visited.has(current):
				continue
			visited[current] = true

			for route_value in world.regional_transport_routes.values():
				var route := route_value as RegionalTransportRoute
				if route == null or route.structural_country_id != country_id:
					continue
				var other: String = route.get_other_endpoint(current)
				if not other.is_empty() and not visited.has(other):
					queue.append(other)

		if visited.size() != country_regions.size():
			return false

	return true
