class_name RegionalInfrastructureDataLoader
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.6
# REGIONAL INFRASTRUCTURE DATA LOADER
# ============================================================


func load_infrastructure_profile(file_path: String) -> Dictionary:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var definition: Dictionary = parsed
	if not validate_infrastructure_profile(definition):
		return {}

	return definition


func load_all_infrastructure_profiles(directory_path: String) -> Array:
	var profiles: Array = []
	if directory_path.is_empty():
		return profiles

	var directory := DirAccess.open(directory_path)
	if directory == null:
		return profiles

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()

	for file_name in file_names:
		if not file_name.ends_with("_infrastructure.json"):
			continue

		var definition: Dictionary = load_infrastructure_profile(
			directory_path + "/" + file_name
		)
		if definition.is_empty():
			return []
		profiles.append(definition)

	return profiles


func validate_infrastructure_profile(definition: Dictionary) -> bool:
	if definition.is_empty():
		return false

	var country_id: String = str(definition.get("country_id", ""))
	if country_id.is_empty():
		return false

	if str(definition.get("profile_type", "")) != "simulation_calibration":
		return false

	if str(definition.get("infrastructure_localization_level", "")) != "parent_region":
		return false

	var province_infrastructure_value: Variant = definition.get(
		"province_infrastructure",
		null
	)
	if not province_infrastructure_value is Dictionary:
		return false

	var province_infrastructure: Dictionary = province_infrastructure_value
	if bool(province_infrastructure.get("enabled", true)):
		return false

	var profiles_value: Variant = definition.get("profiles", null)
	if not profiles_value is Array:
		return false
	if (profiles_value as Array).is_empty():
		return false

	var seen: Dictionary = {}
	var weight_total: float = 0.0
	var required_keys: Array = [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
        "storage"
	]

	for profile_value in profiles_value as Array:
		if not profile_value is Dictionary:
			return false

		var profile: Dictionary = profile_value
		var region_id: String = str(profile.get("region_id", ""))
		if region_id.is_empty() or seen.has(region_id):
			return false
		seen[region_id] = true

		var weight: float = float(profile.get("aggregation_weight", -1.0))
		if weight < 0.0 or weight > 1.0:
			return false
		weight_total += weight

		var infrastructure_value: Variant = profile.get("infrastructure", null)
		if not infrastructure_value is Dictionary:
			return false

		var infrastructure: Dictionary = infrastructure_value
		for key in required_keys:
			var value: Variant = infrastructure.get(key, null)
			if value == null:
				return false
			var numeric_type: int = typeof(value)
			if numeric_type != TYPE_FLOAT and numeric_type != TYPE_INT:
				return false
			var numeric_value: float = float(value)
			if numeric_value < 0.0 or numeric_value > 1.0:
				return false

	return is_equal_approx(weight_total, 1.0)
