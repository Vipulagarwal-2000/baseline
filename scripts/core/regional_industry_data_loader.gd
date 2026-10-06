class_name RegionalIndustryDataLoader
extends RefCounted


func load_industry_file(file_path: String) -> Dictionary:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return {}
	return parsed


func load_all_industry_profiles(directory_path: String) -> Array:
	var profiles: Array = []
	if directory_path.is_empty():
		return profiles
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return profiles
	directory.list_dir_begin()
	while true:
		var file_name: String = directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not file_name.ends_with("_industry.json"):
			continue
		var definition: Dictionary = load_industry_file(directory_path + "/" + file_name)
		if definition.is_empty():
			directory.list_dir_end()
			return []
		profiles.append(definition)
	directory.list_dir_end()
	profiles.sort_custom(func(a, b): return str(a.get("country_id", "")) < str(b.get("country_id", "")))
	return profiles


func validate_industry_profile(definition: Dictionary) -> bool:
	var country_id: String = str(definition.get("country_id", ""))
	var profiles_value: Variant = definition.get("profiles", null)
	if country_id.is_empty() or not profiles_value is Array or (profiles_value as Array).is_empty():
		return false
	var seen: Dictionary = {}
	for profile_value in profiles_value as Array:
		if not profile_value is Dictionary:
			return false
		var profile: Dictionary = profile_value
		var region_id: String = str(profile.get("region_id", ""))
		if region_id.is_empty() or seen.has(region_id):
			return false
		seen[region_id] = true
		var shares_value: Variant = profile.get("capacity_share_by_process", null)
		if not shares_value is Dictionary:
			return false
		for share_value in (shares_value as Dictionary).values():
			var share: float = float(share_value)
			if share < 0.0 or share > 1.0:
				return false
	return true
