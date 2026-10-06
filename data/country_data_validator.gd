class_name CountryDataValidator
extends RefCounted


func validate_country_data(data: Dictionary) -> bool:

	# ========================================================
	# REQUIRED COUNTRY DATA
	# ========================================================

	if not data.has("id"):
		push_error("CountryDataValidator: Missing 'id'.")
		return false

	if not data.has("name"):
		push_error("CountryDataValidator: Missing 'name'.")
		return false

	if not data.has("country_code"):
		push_error("CountryDataValidator: Missing 'country_code'.")
		return false

	if str(data["id"]).strip_edges() == "":
		push_error("CountryDataValidator: Country id is empty.")
		return false

	if str(data["name"]).strip_edges() == "":
		push_error("CountryDataValidator: Country name is empty.")
		return false

	if str(data["country_code"]).strip_edges() == "":
		push_error("CountryDataValidator: Country code is empty.")
		return false


	# ========================================================
	# POPULATION
	# ========================================================

	if data.has("population"):

		if typeof(data["population"]) != TYPE_DICTIONARY:
			push_error(
				"CountryDataValidator: 'population' must be an object."
			)
			return false

		var population = data["population"]

		if population.has("population"):
			if not _is_non_negative_number(
				population["population"]
			):
				push_error(
					"CountryDataValidator: Invalid population."
				)
				return false

		if population.has("birth_rate"):
			if not _is_non_negative_number(
				population["birth_rate"]
			):
				push_error(
					"CountryDataValidator: Invalid birth_rate."
				)
				return false

		if population.has("death_rate"):
			if not _is_non_negative_number(
				population["death_rate"]
			):
				push_error(
					"CountryDataValidator: Invalid death_rate."
				)
				return false

		if population.has("urbanization"):
			if not _is_between(
				population["urbanization"],
				0.0,
				100.0
			):
				push_error(
					"CountryDataValidator: Urbanization must be between 0 and 100."
				)
				return false

		if population.has("migration_capacity"):
			if not _is_non_negative_number(
				population["migration_capacity"]
			):
				push_error(
					"CountryDataValidator: Invalid migration_capacity."
				)
				return false

		if population.has("migration_policy"):
			if not _is_non_negative_number(
				population["migration_policy"]
			):
				push_error(
					"CountryDataValidator: Invalid migration_policy."
				)
				return false


	# ========================================================
	# ECONOMY
	# ========================================================

	if data.has("economy"):

		if typeof(data["economy"]) != TYPE_DICTIONARY:
			push_error(
				"CountryDataValidator: 'economy' must be an object."
			)
			return false

		var economy = data["economy"]

		if economy.has("gdp"):
			if not _is_non_negative_number(
				economy["gdp"]
			):
				push_error(
					"CountryDataValidator: Invalid GDP."
				)
				return false

		if economy.has("growth_rate"):
			if not _is_number(
				economy["growth_rate"]
			):
				push_error(
					"CountryDataValidator: Invalid growth_rate."
				)
				return false

		if economy.has("inflation"):
			if not _is_number(
				economy["inflation"]
			):
				push_error(
					"CountryDataValidator: Invalid inflation."
				)
				return false

		if economy.has("unemployment"):
			if not _is_between(
				economy["unemployment"],
				0.0,
				100.0
			):
				push_error(
					"CountryDataValidator: Unemployment must be between 0 and 100."
				)
				return false
	
	# ========================================================
	# RESEARCH
	# ========================================================

	if data.has("research"):

		if typeof(data["research"]) != TYPE_DICTIONARY:
			push_error(
				"CountryDataValidator: 'research' must be an object."
			)
			return false

		var research = data["research"]

		if research.has("research_capacity"):
			if not _is_non_negative_number(
				research["research_capacity"]
			):
				push_error(
					"CountryDataValidator: Invalid research_capacity."
				)
				return false

		if research.has("research_funding"):
			if not _is_non_negative_number(
				research["research_funding"]
			):
				push_error(
					"CountryDataValidator: Invalid research_funding."
				)
				return false

		if research.has("researchers"):
			if not _is_non_negative_number(
				research["researchers"]
			):
				push_error(
					"CountryDataValidator: Invalid researchers."
				)
				return false

		if research.has("research_institutions"):
			if not _is_non_negative_number(
				research["research_institutions"]
			):
				push_error(
					"CountryDataValidator: Invalid research_institutions."
				)
				return false

		if research.has("research_efficiency"):
			if not _is_non_negative_number(
				research["research_efficiency"]
			):
				push_error(
					"CountryDataValidator: Invalid research_efficiency."
				)
				return false

		if research.has("technology_level"):
			if not _is_non_negative_number(
				research["technology_level"]
			):
				push_error(
					"CountryDataValidator: Invalid technology_level."
				)
				return false

		if research.has("technologies"):

			if typeof(research["technologies"]) != TYPE_DICTIONARY:
				push_error(
					"CountryDataValidator: 'technologies' must be an object."
				)
				return false

			for technology_id in research["technologies"].keys():

				var technology_value = research["technologies"][technology_id]

				if not _is_non_negative_number(
					technology_value
				):
					push_error(
						"CountryDataValidator: Invalid technology value for "
						+ str(technology_id)
					)
					return false
	
	
	
	
	

	# ========================================================
	# RESOURCES
	# ========================================================

	if data.has("resources"):

		if typeof(data["resources"]) != TYPE_DICTIONARY:
			push_error(
				"CountryDataValidator: 'resources' must be an object."
			)
			return false

		var resources = data["resources"]

		var resource_sections = [
			"production",
			"consumption",
			"reserves",
			"stockpile",
			"imports",
			"exports"
		]

		for section_name in resource_sections:

			if not resources.has(section_name):
				continue

			var section = resources[section_name]

			if typeof(section) != TYPE_DICTIONARY:
				push_error(
					"CountryDataValidator: Resource section '"
					+ section_name
					+ "' must be an object."
				)
				return false

			for resource_name in section.keys():

				var resource_value = section[resource_name]

				if not _is_non_negative_number(
					resource_value
				):
					push_error(
						"CountryDataValidator: Invalid resource value for "
						+ section_name
						+ " → "
						+ str(resource_name)
					)
					return false


	# ========================================================
	# RELATIONSHIPS
	# ========================================================

	if data.has("relationships"):

		if typeof(data["relationships"]) != TYPE_DICTIONARY:
			push_error(
				"CountryDataValidator: 'relationships' must be an object."
			)
			return false

		var relationships = data["relationships"]

		for target_id in relationships.keys():

			var relationship_value = relationships[target_id]

			if not _is_number(
				relationship_value
			):
				push_error(
					"CountryDataValidator: Invalid relationship value for "
					+ str(target_id)
				)
				return false

			if (
				relationship_value < -100.0
				or relationship_value > 100.0
			):
				push_error(
					"CountryDataValidator: Relationship value must be between -100 and 100."
				)
				return false


	# ========================================================
	# VALIDATION SUCCESS
	# ========================================================

	return true


func _is_number(value) -> bool:

	return (
		typeof(value) == TYPE_INT
		or typeof(value) == TYPE_FLOAT
	)


func _is_non_negative_number(value) -> bool:

	if not _is_number(value):
		return false

	return float(value) >= 0.0


func _is_between(
	value,
	minimum: float,
	maximum: float
) -> bool:

	if not _is_number(value):
		return false

	var numeric_value = float(value)

	return (
		numeric_value >= minimum
		and numeric_value <= maximum
	)
