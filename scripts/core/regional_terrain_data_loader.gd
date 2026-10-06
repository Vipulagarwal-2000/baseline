class_name RegionalTerrainDataLoader
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.3
# REGIONAL TERRAIN PROFILE DATA LOADER
# ============================================================
#
# Kept separate from WorldLoader and RegionalDataLoader so the terrain
# catalog can evolve independently of country and hierarchy loading.
# ============================================================


func load_terrain_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error(
            "RegionalTerrainDataLoader: Terrain profile file not found: "
			+ file_path
		)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error(
            "RegionalTerrainDataLoader: Could not open terrain profile file: "
			+ file_path
		)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error(
            "RegionalTerrainDataLoader: Invalid JSON in "
			+ file_path
		)
		return {}

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error(
            "RegionalTerrainDataLoader: Root must be a dictionary: "
			+ file_path
		)
		return {}

	if not _validate_document(data, file_path):
		return {}

	return data


func load_all_terrain_profiles(directory_path: String) -> Array:
	var results: Array = []

	var directory = DirAccess.open(directory_path)
	if directory == null:
		push_error(
            "RegionalTerrainDataLoader: Could not open terrain directory: "
			+ directory_path
		)
		return results

	var files: Array[String] = []
	directory.list_dir_begin()

	while true:
		var entry = directory.get_next()
		if entry.is_empty():
			break

		if directory.current_is_dir():
			continue

		if entry.to_lower().ends_with("_terrain.json"):
			files.append(entry)

	directory.list_dir_end()
	files.sort()

	for file_name in files:
		var data = load_terrain_file(
			directory_path.path_join(file_name)
		)

		if data.is_empty():
			push_error(
                "RegionalTerrainDataLoader: Failed to load "
				+ file_name
			)
			return []

		results.append(data)

	return results


func _validate_document(
	data: Dictionary,
	file_path: String
) -> bool:
	var country_id := str(data.get("country_id", ""))
	if country_id.is_empty():
		push_error(
            "RegionalTerrainDataLoader: Missing country_id in "
			+ file_path
		)
		return false

	var profiles = data.get("profiles", null)
	if typeof(profiles) != TYPE_ARRAY or profiles.is_empty():
		push_error(
            "RegionalTerrainDataLoader: profiles must be a non-empty array in "
			+ file_path
		)
		return false

	var profile_ids: Dictionary = {}
	for profile_value in profiles:
		if typeof(profile_value) != TYPE_DICTIONARY:
			push_error(
                "RegionalTerrainDataLoader: Profile entry is not a dictionary in "
				+ file_path
			)
			return false

		var profile: Dictionary = profile_value
		var region_id := str(profile.get("region_id", ""))
		if region_id.is_empty():
			push_error(
                "RegionalTerrainDataLoader: Missing region_id in "
				+ file_path
			)
			return false

		if profile_ids.has(region_id):
			push_error(
                "RegionalTerrainDataLoader: Duplicate region_id "
				+ region_id
			)
			return false

		profile_ids[region_id] = true

		var terrain = profile.get("terrain", null)
		if not _validate_terrain_dictionary(terrain, region_id, file_path):
			return false

	return true


func _validate_terrain_dictionary(
	terrain,
	region_id: String,
	file_path: String
) -> bool:
	if typeof(terrain) != TYPE_DICTIONARY:
		push_error(
            "RegionalTerrainDataLoader: terrain must be a dictionary for "
			+ region_id
			+ " in "
			+ file_path
		)
		return false

	var required_keys := [
		"mountains",
		"plateaus",
		"deserts",
		"plains",
		"coastal_lowlands",
		"major_rivers",
        "coastal_access"
	]

	for key in required_keys:
		if not terrain.has(key):
			push_error(
                "RegionalTerrainDataLoader: Missing terrain key "
				+ key
				+ " for "
				+ region_id
			)
			return false

		if key != "coastal_access":
			var value := float(terrain[key])
			if not is_finite(value) or value < 0.0 or value > 1.0:
				push_error(
                    "RegionalTerrainDataLoader: Invalid terrain factor "
					+ key
					+ " for "
					+ region_id
				)
				return false

	return typeof(terrain["coastal_access"]) == TYPE_BOOL
