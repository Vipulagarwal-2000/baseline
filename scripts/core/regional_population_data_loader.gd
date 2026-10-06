class_name RegionalPopulationDataLoader
extends RefCounted


func load_population_file(
	file_path: String
) -> Dictionary:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var raw_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed


func load_all_population_profiles(
	directory_path: String
) -> Array:
	var profiles: Array = []

	if directory_path.is_empty():
		return profiles

	var directory := DirAccess.open(directory_path)
	if directory == null:
		return profiles

	directory.list_dir_begin()

	while true:
		var file_name := directory.get_next()
		if file_name.is_empty():
			break

		if directory.current_is_dir():
			continue

		if not file_name.ends_with("_population.json"):
			continue

		var definition := load_population_file(
			directory_path + "/" + file_name
		)

		if definition.is_empty():
			directory.list_dir_end()
			return []

		profiles.append(definition)

	directory.list_dir_end()

	profiles.sort_custom(
		func(a, b):
			return str(a.get("country_id", "")) < str(b.get("country_id", ""))
	)

	return profiles


func validate_population_profile(
	definition: Dictionary
) -> bool:
	var country_id := str(definition.get("country_id", ""))
	var profiles = definition.get("profiles", null)

	if country_id.is_empty() or typeof(profiles) != TYPE_ARRAY:
		return false
	if profiles.is_empty():
		return false

	var seen: Dictionary = {}
	var share_total := 0.0

	for profile_value in profiles:
		if typeof(profile_value) != TYPE_DICTIONARY:
			return false

		var profile: Dictionary = profile_value
		var region_id := str(profile.get("region_id", ""))
		var share := float(profile.get("population_share", -1.0))
		var urbanization := float(profile.get("urbanization", -1.0))

		if region_id.is_empty() or seen.has(region_id):
			return false
		if share < 0.0 or share > 1.0 or urbanization < 0.0:
			return false

		seen[region_id] = true
		share_total += share

	return is_equal_approx(share_total, 1.0)
