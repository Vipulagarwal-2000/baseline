class_name WorldStateValidationTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func run(world: WorldState) -> bool:

	_out([""])
	_out(["================================"])
	_out(["WORLD STATE VALIDATION"])
	_out(["================================"])
	_out([""])

	if world == null:

		_out(["World state is null."])
		_out(["Overall: FAIL"])

		return false


	var countries_checked := 0
	var countries_passed := 0
	var countries_failed := 0


	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue


		countries_checked += 1


		_out(["Country: ", entity.name])
		_out(["ID: ", entity.id])


		# ====================================================
		# POPULATION
		# ====================================================

		var population = entity.get_component(
			"population"
		)

		var population_pass := population != null

		_out([
			"  population: ",
			"PASS" if population_pass else "MISSING"
		])


		# ====================================================
		# ECONOMY
		# ====================================================

		var economy = entity.get_component(
			"economy"
		)

		var economy_pass := economy != null

		_out([
			"  economy: ",
			"PASS" if economy_pass else "MISSING"
		])


		# ====================================================
		# GOVERNMENT
		# ====================================================

		var government = entity.get_component(
			"government"
		)

		var government_pass := government != null

		_out([
			"  government: ",
			"PASS" if government_pass else "MISSING"
		])


		# ====================================================
		# RESOURCES
		# ====================================================

		var resources = entity.get_component(
			"resources"
		)

		var resources_pass := resources != null

		_out([
			"  resources: ",
			"PASS" if resources_pass else "MISSING"
		])


		# ====================================================
		# RESEARCH
		# ====================================================

		var research = entity.get_component(
			"research"
		)

		var research_pass := research != null

		_out([
			"  research: ",
			"PASS" if research_pass else "MISSING"
		])


		# ====================================================
		# TECHNOLOGY ADOPTION
		# ====================================================

		var technology_adoption = entity.get_component(
			"technology_adoption"
		)

		var technology_adoption_pass := (
			technology_adoption != null
		)

		_out([
			"  technology_adoption: ",
			"PASS"
			if technology_adoption_pass
			else "MISSING"
		])


		# ====================================================
		# COUNTRY VALIDATION
		# ====================================================

		var country_passed := (
			population_pass
			and economy_pass
			and government_pass
			and resources_pass
			and research_pass
			and technology_adoption_pass
		)


		_out([
			"  Country validation: ",
			"PASS" if country_passed else "FAIL"
		])

		_out([""])


		if country_passed:

			countries_passed += 1

		else:

			countries_failed += 1


	# ========================================================
	# FINAL RESULT
	# ========================================================

	var overall_passed := (
		countries_checked > 0
		and countries_failed == 0
	)


	_out(["================================"])
	_out(["WORLD STATE VALIDATION RESULT"])
	_out(["================================"])


	_out([
		"Countries checked: ",
		countries_checked
	])

	_out([
		"Countries passed: ",
		countries_passed
	])

	_out([
		"Countries failed: ",
		countries_failed
	])

	_out([
		"Overall: ",
		"PASS" if overall_passed else "FAIL"
	])

	_out(["World state validation complete."])


	return overall_passed
