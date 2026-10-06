class_name TechnologyManager
extends RefCounted


var library: TechnologyLibrary


func _init(
	technology_library: TechnologyLibrary = null
):

	if technology_library == null:

		library = DefaultTechnologies.create_library()

	else:

		library = technology_library


func get_technology(
	technology_id: String
) -> TechnologyData:

	if library == null:
		return null

	return library.get_technology(
		technology_id
	)


func has_technology(
	technology_id: String
) -> bool:

	if library == null:
		return false

	return library.has_technology(
		technology_id
	)


func get_all_technologies() -> Array:

	if library == null:
		return []

	return library.get_all_technologies()


func get_technology_count() -> int:

	if library == null:
		return 0

	return library.get_technology_count()


func add_technology(
	technology: TechnologyData
) -> bool:

	if library == null:
		return false

	return library.add_technology(
		technology
	)


func remove_technology(
	technology_id: String
) -> void:

	if library == null:
		return

	library.remove_technology(
		technology_id
	)


func can_be_researched(
	technology_id: String,
	technology_level: float,
	completed_technologies: Dictionary,
	current_year: int
) -> bool:

	var technology = get_technology(
		technology_id
	)

	if technology == null:
		return false

	return technology.can_be_researched(
		technology_level,
		completed_technologies,
		current_year
	)


func get_missing_prerequisites(
	technology_id: String,
	completed_technologies: Dictionary
) -> Array:

	var missing: Array = []

	var technology = get_technology(
		technology_id
	)

	if technology == null:
		return missing

	for prerequisite_id in technology.prerequisites:

		if not completed_technologies.has(
			prerequisite_id
		):

			missing.append(
				prerequisite_id
			)

		elif not bool(
			completed_technologies[
				prerequisite_id
			]
		):

			missing.append(
				prerequisite_id
			)

	return missing
	
	
func get_available_technologies(
	technology_level: float,
	completed_technologies: Dictionary,
	current_year: int
) -> Array:

	var available: Array = []

	if library == null:
		return available

	for technology in library.get_all_technologies():

		if technology == null:
			continue

		# A completed technology is no longer available
		# as a new research option.
		if completed_technologies.has(technology.id):

			if bool(completed_technologies[technology.id]):
				continue

		if technology.can_be_researched(
			technology_level,
			completed_technologies,
			current_year
		):

			available.append(
				technology
			)

	return available
