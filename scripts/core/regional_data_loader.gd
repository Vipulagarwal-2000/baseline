class_name RegionalDataLoader
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.1
# REGIONAL DEFINITION DATA LOADER
# ============================================================
#
# Keeps WorldLoader country-focused. This loader owns only the
# data-definition layer for regional/province structure.
# ============================================================


func load_region_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error(
			"RegionalDataLoader: Region definition file not found: "
			+ file_path
		)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error(
			"RegionalDataLoader: Could not open region file: "
			+ file_path
		)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error(
			"RegionalDataLoader: Invalid JSON in "
			+ file_path
		)
		return {}

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error(
			"RegionalDataLoader: Root must be a dictionary: "
			+ file_path
		)
		return {}

	if not _validate_definition_document(data, file_path):
		return {}

	return data


func load_all_regions(directory_path: String) -> Array:
	var results: Array = []

	var directory = DirAccess.open(directory_path)
	if directory == null:
		push_error(
			"RegionalDataLoader: Could not open directory: "
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

		if entry.to_lower().ends_with(".json"):
			files.append(entry)

	directory.list_dir_end()
	files.sort()

	for file_name in files:
		var data = load_region_file(
			directory_path.path_join(file_name)
		)

		if data.is_empty():
			push_error(
				"RegionalDataLoader: Failed to load "
				+ file_name
			)
			return []

		results.append(data)

	return results


func _validate_definition_document(
	data: Dictionary,
	file_path: String
) -> bool:
	var country_id = str(data.get("country_id", ""))
	if country_id.is_empty():
		push_error(
			"RegionalDataLoader: Missing country_id in "
			+ file_path
		)
		return false

	var regions = data.get("regions", null)
	if typeof(regions) != TYPE_ARRAY or regions.is_empty():
		push_error(
			"RegionalDataLoader: regions must be a non-empty array in "
			+ file_path
		)
		return false

	var region_ids: Dictionary = {}

	for region_value in regions:
		if typeof(region_value) != TYPE_DICTIONARY:
			push_error(
				"RegionalDataLoader: Region entry is not a dictionary in "
				+ file_path
			)
			return false

		var region: Dictionary = region_value
		var region_id = str(region.get("id", ""))
		var region_name = str(region.get("name", ""))
		var provinces = region.get("provinces", null)

		if region_id.is_empty() or region_name.is_empty():
			push_error(
				"RegionalDataLoader: Region id/name missing in "
				+ file_path
			)
			return false

		if region_ids.has(region_id):
			push_error(
				"RegionalDataLoader: Duplicate region id "
				+ region_id
			)
			return false

		region_ids[region_id] = true

		if typeof(provinces) != TYPE_ARRAY or provinces.is_empty():
			push_error(
				"RegionalDataLoader: Region "
				+ region_id
				+ " has no provinces in "
				+ file_path
			)
			return false

		var province_ids: Dictionary = {}
		for province_value in provinces:
			if typeof(province_value) != TYPE_DICTIONARY:
				push_error(
					"RegionalDataLoader: Province entry is not a dictionary in "
					+ file_path
				)
				return false

			var province: Dictionary = province_value
			var province_id = str(province.get("id", ""))
			var province_name = str(province.get("name", ""))

			if province_id.is_empty() or province_name.is_empty():
				push_error(
					"RegionalDataLoader: Province id/name missing in "
					+ file_path
				)
				return false

			if province_ids.has(province_id):
				push_error(
					"RegionalDataLoader: Duplicate province id "
					+ province_id
				)
				return false

			province_ids[province_id] = true

	return true
