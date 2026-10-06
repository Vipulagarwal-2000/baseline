class_name WorldLoader
extends RefCounted


var technology_manager: TechnologyManager
var validator: CountryDataValidator


func _init(manager: TechnologyManager = null):
	technology_manager = manager
	validator = CountryDataValidator.new()


# ========================================================
# LOAD COUNTRY
# ========================================================

func load_country(file_path: String) -> Country:

	if not FileAccess.file_exists(file_path):
		push_error(
			"WorldLoader: Country file not found: "
			+ file_path
		)
		return null


	var file = FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"WorldLoader: Could not open country file: "
			+ file_path
		)
		return null


	var json_text = file.get_as_text()
	file.close()


	var json = JSON.new()

	var parse_result = json.parse(
		json_text
	)

	if parse_result != OK:
		push_error(
			"WorldLoader: Invalid JSON in "
			+ file_path
		)
		return null


	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error(
			"WorldLoader: Country data must be a dictionary: "
			+ file_path
		)
		return null


	# ====================================================
	# VALIDATION
	# ====================================================

	var validation_result = (
		validator.validate_country_data(data)
	)

	if not validation_result:
		push_error(
			"WorldLoader: Country validation failed: "
			+ file_path
		)
		return null


	# ====================================================
	# BASIC COUNTRY DATA
	# ====================================================

	var country_id = str(
		data.get("id", "")
	)

	var country_name = str(
		data.get("name", "")
	)

	var country_code = str(
		data.get("country_code", "")
	)

	var country = Country.new(
		country_id,
		country_name,
		country_code
	)


	# ====================================================
	# POPULATION
	# ====================================================

	var population = PopulationComponent.new(
		country.id
	)

	if data.has("population"):

		var population_data = data["population"]

		if typeof(population_data) == TYPE_DICTIONARY:

			for key in population_data.keys():

				population.set_state(
					str(key),
					population_data[key]
				)


	for key in population.state.keys():

		var value = population.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			population.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			population.set_baseline(
				key,
				value
			)


	country.add_component(population)


	# ====================================================
	# ECONOMY
	# ====================================================

	var economy = EconomyComponent.new(
		country.id
	)

	if data.has("economy"):

		var economy_data = data["economy"]

		if typeof(economy_data) == TYPE_DICTIONARY:

			for key in economy_data.keys():

				economy.set_state(
					str(key),
					economy_data[key]
				)


	for key in economy.state.keys():

		var value = economy.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			economy.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			economy.set_baseline(
				key,
				value
			)


	country.add_component(economy)


	# ====================================================
	# GOVERNMENT
	# ====================================================

	var government = GovernmentComponent.new(
		country.id
	)

	if data.has("government"):

		var government_data = data["government"]

		if typeof(government_data) == TYPE_DICTIONARY:

			for key in government_data.keys():

				government.set_state(
					str(key),
					government_data[key]
				)


	for key in government.state.keys():

		var value = government.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			government.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			government.set_baseline(
				key,
				value
			)


	country.add_component(government)


	# ====================================================
	# RESEARCH
	# ====================================================

	var research = ResearchComponent.new(
		country.id
	)

	if data.has("research"):

		var research_data = data["research"]

		if typeof(research_data) == TYPE_DICTIONARY:

			if research_data.has("research_capacity"):
				research.set_state(
					"research_capacity",
					research_data["research_capacity"]
				)

			if research_data.has("research_funding"):
				research.set_state(
					"research_funding",
					research_data["research_funding"]
				)

			if research_data.has("researchers"):
				research.set_state(
					"researchers",
					research_data["researchers"]
				)

			if research_data.has("research_institutions"):
				research.set_state(
					"research_institutions",
					research_data["research_institutions"]
				)

			if research_data.has("research_efficiency"):
				research.set_state(
					"research_efficiency",
					research_data["research_efficiency"]
				)

			if research_data.has("technology_level"):
				research.set_state(
					"technology_level",
					research_data["technology_level"]
				)

			if research_data.has("technologies"):

				if typeof(
					research_data["technologies"]
				) == TYPE_DICTIONARY:

					research.set_state(
						"technologies",
						research_data[
							"technologies"
						].duplicate(true)
					)


			# --------------------------------------------
			# Rebuild research capabilities
			# --------------------------------------------

			var completed_technologies = (
				research.get_state(
					"technologies",
					{}
				)
			)

			if typeof(
				completed_technologies
			) == TYPE_DICTIONARY:

				for technology_id in (
					completed_technologies.keys()
				):

					if not bool(
						completed_technologies[
							technology_id
						]
					):
						continue

					if technology_manager == null:
						continue

					var technology = (
						technology_manager.get_technology(
							str(technology_id)
						)
					)

					if technology == null:
						continue

					for capability_id in (
						technology.capabilities
					):

						research.add_research_capability(
							str(capability_id)
						)


	for key in research.state.keys():

		var value = research.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			research.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			research.set_baseline(
				key,
				value
			)


	country.add_component(research)


	# ====================================================
	# TECHNOLOGY ADOPTION
	# ====================================================

	var technology_adoption = (
		TechnologyAdoptionComponent.new(
			country.id
		)
	)


	var completed_technologies_for_adoption = (
		research.get_state(
			"technologies",
			{}
		)
	)


	if typeof(
		completed_technologies_for_adoption
	) == TYPE_DICTIONARY:

		for technology_id in (
			completed_technologies_for_adoption.keys()
		):

			if not bool(
				completed_technologies_for_adoption[
					technology_id
				]
			):
				continue

			technology_adoption.set_adoption(
				str(technology_id),
				1.0
			)


	var adoption_state = (
		technology_adoption.get_state(
			"adoption",
			{}
		)
	)


	if typeof(adoption_state) == TYPE_DICTIONARY:

		technology_adoption.set_baseline(
			"adoption",
			adoption_state.duplicate(true)
		)


	technology_adoption.set_baseline(
		"deployment_capacity",
		technology_adoption.get_state(
			"deployment_capacity",
			0.0
		)
	)

	technology_adoption.set_baseline(
		"deployment_efficiency",
		technology_adoption.get_state(
			"deployment_efficiency",
			1.0
		)
	)


	country.add_component(
		technology_adoption
	)


	# ====================================================
	# RESOURCES
	# ====================================================

	var resources = ResourceComponent.new(
		country.id
	)

	if data.has("resources"):

		var resource_data = data["resources"]

		if typeof(resource_data) == TYPE_DICTIONARY:

			var resource_sections = [
				"production",
				"consumption",
				"reserves",
				"stockpile",
				"imports",
				"exports"
			]

			for section in resource_sections:

				if not resource_data.has(section):
					continue

				var section_data = (
					resource_data[section]
				)

				if typeof(section_data) != TYPE_DICTIONARY:
					continue

				resources.set_state(
					section,
					section_data.duplicate(true)
				)


	for key in resources.state.keys():

		var value = resources.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			resources.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			resources.set_baseline(
				key,
				value
			)


	country.add_component(resources)


	# ====================================================
	# INDUSTRY
	# ====================================================

	var industry = IndustryComponent.new(
		country.id
	)

	if data.has("industry"):

		var industry_data = data["industry"]

		if typeof(industry_data) == TYPE_DICTIONARY:

			for key in industry_data.keys():

				industry.set_state(
					str(key),
					industry_data[key]
				)


	for key in industry.state.keys():

		var value = industry.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			industry.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			industry.set_baseline(
				key,
				value
			)


	country.add_component(industry)


	# ====================================================
	# GEOGRAPHY
	# ====================================================

	var geography = GeographyComponent.new(
		country.id
	)

	if data.has("geography"):

		var geography_data = data["geography"]

		if typeof(geography_data) == TYPE_DICTIONARY:

			for key in geography_data.keys():

				geography.set_state(
					str(key),
					geography_data[key]
				)


	for key in geography.state.keys():

		var value = geography.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			geography.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			geography.set_baseline(
				key,
				value
			)


	country.add_component(geography)


	# ====================================================
	# MILITARY
	# ====================================================

	var military = MilitaryComponent.new(
		country.id
	)

	if data.has("military"):

		var military_data = data["military"]

		if typeof(military_data) == TYPE_DICTIONARY:

			for key in military_data.keys():

				military.set_state(
					str(key),
					military_data[key]
				)


	for key in military.state.keys():

		var value = military.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			military.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			military.set_baseline(
				key,
				value
			)


	country.add_component(military)


	# ====================================================
	# INFRASTRUCTURE
	# ====================================================

	var infrastructure = InfrastructureComponent.new(
		country.id
	)

	if data.has("infrastructure"):

		var infrastructure_data = data["infrastructure"]

		if typeof(infrastructure_data) == TYPE_DICTIONARY:

			for key in infrastructure_data.keys():

				infrastructure.set_state(
					str(key),
					infrastructure_data[key]
				)


	for key in infrastructure.state.keys():

		var value = infrastructure.get_state(key)

		if typeof(value) == TYPE_DICTIONARY:

			infrastructure.set_baseline(
				key,
				value.duplicate(true)
			)

		else:

			infrastructure.set_baseline(
				key,
				value
			)


	country.add_component(infrastructure)


	# ====================================================
	# RELATIONSHIPS
	# ====================================================

	if data.has("relationships"):

		var relationship_data = (
			data["relationships"]
		)

		if typeof(
			relationship_data
		) == TYPE_DICTIONARY:

			for target_id in (
				relationship_data.keys()
			):

				var relationship_value = (
					relationship_data[target_id]
				)

				if (
					typeof(relationship_value)
					== TYPE_INT
					or
					typeof(relationship_value)
					== TYPE_FLOAT
				):

					country.set_relationship(
						str(target_id),
						float(relationship_value)
					)


	# ====================================================
	# LOADER VERIFICATION
	# ====================================================

	if country.get_component("government") == null:
		push_error(
			"WorldLoader: Government component missing for "
			+ country.id
		)

	if country.get_component("technology_adoption") == null:
		push_error(
			"WorldLoader: Technology adoption component missing for "
			+ country.id
		)

	if country.get_component("geography") == null:
		push_error(
			"WorldLoader: Geography component missing for "
			+ country.id
		)

	if country.get_component("military") == null:
		push_error(
			"WorldLoader: Military component missing for "
			+ country.id
		)

	if country.get_component("industry") == null:
		push_error(
			"WorldLoader: Industry component missing for "
			+ country.id
		)

	if country.get_component("infrastructure") == null:
		push_error(
			"WorldLoader: Infrastructure component missing for "
			+ country.id
		)


	return country


# ========================================================
# LOAD ALL COUNTRIES
# ========================================================

func load_all_countries(
	directory_path: String
) -> Array:

	var countries: Array = []

	var directory = DirAccess.open(
		directory_path
	)

	if directory == null:

		push_error(
			"WorldLoader: Could not open directory: "
			+ directory_path
		)

		return countries


	directory.list_dir_begin()


	while true:

		var file_name = directory.get_next()

		if file_name.is_empty():
			break

		if directory.current_is_dir():
			continue

		if not file_name.ends_with(".json"):
			continue


		var file_path = (
			directory_path
			+ "/"
			+ file_name
		)


		var country = load_country(
			file_path
		)


		if country != null:

			countries.append(
				country
			)


	directory.list_dir_end()


	return countries


# ========================================================
# COMPATIBILITY ALIAS
# ========================================================

func load_countries_from_directory(
	directory_path: String
) -> Array:

	return load_all_countries(
		directory_path
	)
