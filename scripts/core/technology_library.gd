class_name TechnologyLibrary
extends RefCounted


var technologies: Dictionary = {}


func add_technology(
	technology: TechnologyData
) -> bool:

	if technology == null:
		push_error(
			"TechnologyLibrary: Cannot add null technology."
		)
		return false

	if technology.id.strip_edges() == "":
		push_error(
			"TechnologyLibrary: Technology id cannot be empty."
		)
		return false

	if technologies.has(technology.id):
		push_error(
			"TechnologyLibrary: Technology already exists: "
			+ technology.id
		)
		return false

	technologies[technology.id] = technology

	return true


func get_technology(
	technology_id: String
) -> TechnologyData:

	return technologies.get(
		technology_id,
		null
	)


func has_technology(
	technology_id: String
) -> bool:

	return technologies.has(
		technology_id
	)


func remove_technology(
	technology_id: String
) -> void:

	technologies.erase(
		technology_id
	)


func get_technology_count() -> int:

	return technologies.size()


func get_all_technologies() -> Array:

	return technologies.values()


func clear() -> void:

	technologies.clear()
