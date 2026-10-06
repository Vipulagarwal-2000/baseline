class_name RegionalTransportDataLoader
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.8
# REGIONAL TRANSPORT DATA LOADER
# ============================================================


func load_transport_profile(
	path: String
) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error(
			"RegionalTransportDataLoader: Missing profile: " + path
		)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		push_error(
			"RegionalTransportDataLoader: Invalid JSON: " + path
		)
		return {}

	var profile: Dictionary = parsed
	if not validate_transport_profile(profile):
		push_error(
			"RegionalTransportDataLoader: Invalid transport profile: " + path
		)
		return {}

	return profile


func load_all_transport_profiles(
	directory_path: String
) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error(
			"RegionalTransportDataLoader: Missing directory: " + directory_path
		)
		return result

	directory.list_dir_begin()
	while true:
		var file_name := directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not file_name.ends_with("_transport.json"):
			continue

		var profile: Dictionary = load_transport_profile(
			directory_path.path_join(file_name)
		)
		if profile.is_empty():
			continue

		var country_id: String = str(profile.get("country_id", ""))
		if country_id.is_empty() or result.has(country_id):
			push_error(
				"RegionalTransportDataLoader: Duplicate/invalid country profile: "
				+ country_id
			)
			continue

		result[country_id] = profile

	directory.list_dir_end()
	return result


func validate_transport_profile(
	profile: Dictionary
) -> bool:
	if profile.is_empty():
		return false
	if str(profile.get("profile_type", "")) != "simulation_calibration":
		return false
	if str(profile.get("transport_localization_level", "")) != "parent_region_network":
		return false
	if typeof(profile.get("nodes", null)) != TYPE_ARRAY:
		return false
	if typeof(profile.get("routes", null)) != TYPE_ARRAY:
		return false

	var nodes: Array = profile["nodes"]
	var routes: Array = profile["routes"]
	if nodes.is_empty() or routes.is_empty():
		return false

	var node_ids: Dictionary = {}
	for node_value in nodes:
		if not node_value is Dictionary:
			return false
		var node: Dictionary = node_value
		var region_id: String = str(node.get("region_id", ""))
		if region_id.is_empty() or node_ids.has(region_id):
			return false
		node_ids[region_id] = true

		var base_capacity_value: Variant = node.get("base_capacity", null)
		var cost_value: Variant = node.get("transport_cost", null)
		var condition_value: Variant = node.get("condition", null)
		if base_capacity_value == null or cost_value == null or condition_value == null:
			return false
		if typeof(base_capacity_value) != TYPE_FLOAT and typeof(base_capacity_value) != TYPE_INT:
			return false
		if typeof(cost_value) != TYPE_FLOAT and typeof(cost_value) != TYPE_INT:
			return false
		if typeof(condition_value) != TYPE_FLOAT and typeof(condition_value) != TYPE_INT:
			return false
		if float(base_capacity_value) <= 0.0:
			return false
		if float(cost_value) <= 0.0:
			return false
		if float(condition_value) < 0.0 or float(condition_value) > 1.0:
			return false

	var route_ids: Dictionary = {}
	var undirected_pairs: Dictionary = {}
	for route_value in routes:
		if not route_value is Dictionary:
			return false
		var route: Dictionary = route_value
		var route_id: String = str(route.get("route_id", ""))
		var from_region_id: String = str(route.get("from_region_id", ""))
		var to_region_id: String = str(route.get("to_region_id", ""))
		if route_id.is_empty() or route_ids.has(route_id):
			return false
		if from_region_id.is_empty() or to_region_id.is_empty():
			return false
		if from_region_id == to_region_id:
			return false
		if not node_ids.has(from_region_id) or not node_ids.has(to_region_id):
			return false

		var pair_key: String
		if from_region_id < to_region_id:
			pair_key = from_region_id + "|" + to_region_id
		else:
			pair_key = to_region_id + "|" + from_region_id
		if undirected_pairs.has(pair_key):
			return false
		undirected_pairs[pair_key] = true
		route_ids[route_id] = true

		var base_capacity_value: Variant = route.get("base_capacity", null)
		var cost_value: Variant = route.get("transport_cost", null)
		var condition_value: Variant = route.get("condition", null)
		if base_capacity_value == null or cost_value == null or condition_value == null:
			return false
		if typeof(base_capacity_value) != TYPE_FLOAT and typeof(base_capacity_value) != TYPE_INT:
			return false
		if typeof(cost_value) != TYPE_FLOAT and typeof(cost_value) != TYPE_INT:
			return false
		if typeof(condition_value) != TYPE_FLOAT and typeof(condition_value) != TYPE_INT:
			return false
		if float(base_capacity_value) <= 0.0:
			return false
		if float(cost_value) <= 0.0:
			return false
		if float(condition_value) < 0.0 or float(condition_value) > 1.0:
			return false

	return true
