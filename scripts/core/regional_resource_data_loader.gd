class_name RegionalResourceDataLoader
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.5
# REGIONAL RESOURCE DATA LOADER
# ============================================================
#
# The regional JSON files are simulation-calibration profiles.
# They never replace country ResourceComponent state.
# ============================================================


func load_resource_profile(file_path: String) -> Dictionary:
	if file_path.is_empty():
		return {}

	if not FileAccess.file_exists(file_path):
		push_error(
			"RegionalResourceDataLoader: File not found: " + file_path
		)
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(
			"RegionalResourceDataLoader: Invalid JSON object: " + file_path
		)
		return {}

	var definition: Dictionary = parsed
	if not validate_resource_profile(definition):
		push_error(
			"RegionalResourceDataLoader: Invalid resource profile: " + file_path
		)
		return {}

	return definition


func load_all_resource_profiles(directory_path: String) -> Array:
	var profiles: Array = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error(
			"RegionalResourceDataLoader: Cannot open directory: "
			+ directory_path
		)
		return profiles

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()

	for file_name in file_names:
		if not file_name.ends_with("_resources.json"):
			continue

		var definition: Dictionary = load_resource_profile(
			directory_path + "/" + file_name
		)
		if not definition.is_empty():
			profiles.append(definition)

	return profiles


func validate_resource_profile(definition: Dictionary) -> bool:
	if definition.is_empty():
		return false

	var country_id: String = str(definition.get("country_id", ""))
	if country_id.is_empty():
		return false

	if str(definition.get("profile_type", "")) != "simulation_calibration":
		return false

	if str(definition.get("resource_localization_level", "")) != "parent_region":
		return false

	var province_resources: Variant = definition.get("province_resources", null)
	if typeof(province_resources) != TYPE_DICTIONARY:
		return false

	var province_resources_dict: Dictionary = province_resources
	if bool(province_resources_dict.get("enabled", true)):
		return false

	var profiles_value: Variant = definition.get("profiles", null)
	if not profiles_value is Array or profiles_value.is_empty():
		return false

	var profiles: Array = profiles_value
	var region_ids: Dictionary = {}
	var stockpile_share_total: float = 0.0
	var production_totals: Dictionary = {}
	var reserve_totals: Dictionary = {}

	for value in profiles:
		if not value is Dictionary:
			return false

		var profile: Dictionary = value
		var region_id: String = str(profile.get("region_id", ""))
		if region_id.is_empty() or region_ids.has(region_id):
			return false
		region_ids[region_id] = true

		var stockpile_share: float = float(
			profile.get("stockpile_share", -1.0)
		)
		if stockpile_share < 0.0 or stockpile_share > 1.0:
			return false
		stockpile_share_total += stockpile_share

		var production_share_value: Variant = profile.get(
			"production_share",
			null
		)
		var reserve_share_value: Variant = profile.get(
			"reserve_share",
			null
		)
		var accessibility_value: Variant = profile.get(
			"resource_accessibility",
			null
		)
		var dependency_value: Variant = profile.get(
			"local_import_dependency",
			null
		)

		if not production_share_value is Dictionary:
			return false
		if not reserve_share_value is Dictionary:
			return false
		if not accessibility_value is Dictionary:
			return false
		if not dependency_value is Dictionary:
			return false

		var production_share: Dictionary = production_share_value
		var reserve_share: Dictionary = reserve_share_value
		var accessibility: Dictionary = accessibility_value
		var dependency: Dictionary = dependency_value

		for resource_name in production_share.keys():
			var share: float = float(production_share[resource_name])
			if share < 0.0 or share > 1.0:
				return false
			var resource_key: String = str(resource_name)
			production_totals[resource_key] = float(
				production_totals.get(resource_key, 0.0)
			) + share

		for resource_name in reserve_share.keys():
			var share: float = float(reserve_share[resource_name])
			if share < 0.0 or share > 1.0:
				return false
			var resource_key: String = str(resource_name)
			reserve_totals[resource_key] = float(
				reserve_totals.get(resource_key, 0.0)
			) + share

		for factor_value in accessibility.values():
			var factor: float = float(factor_value)
			if factor < 0.0 or factor > 1.0:
				return false

		for factor_value in dependency.values():
			var factor: float = float(factor_value)
			if factor < 0.0 or factor > 1.0:
				return false

	if not is_equal_approx(stockpile_share_total, 1.0):
		return false

	for total_value in production_totals.values():
		if not is_equal_approx(float(total_value), 1.0):
			return false

	for total_value in reserve_totals.values():
		if not is_equal_approx(float(total_value), 1.0):
			return false

	return true
