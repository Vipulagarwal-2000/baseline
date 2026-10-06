class_name ResearchTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func run(world: WorldState) -> void:

	_out([""])
	_out(["================================"])
	_out(["RESEARCH SYSTEM TEST"])
	_out(["================================"])

	if world == null:

		_out(["ERROR: World is null."])
		return

	var india = world.get_entity("india")

	if india == null:

		_out(["ERROR: India not found."])
		return

	var research = india.get_component(
		"research"
	)

	if research == null:

		_out(["ERROR: India research component missing."])
		return

	_out([
		"Research capacity: ",
		research.get_state(
			"research_capacity",
			0.0
		)
	])

	_out([
		"Research funding: ",
		research.get_state(
			"research_funding",
			0.0
		)
	])

	_out([
		"Researchers: ",
		research.get_state(
			"researchers",
			0.0
		)
	])

	_out([
		"Research institutions: ",
		research.get_state(
			"research_institutions",
			0.0
		)
	])

	_out([
		"Research efficiency: ",
		research.get_state(
			"research_efficiency",
			0.0
		)
	])

	_out([
		"Research output: ",
		research.get_state(
			"research_output",
			0.0
		)
	])

	_out([
		"Technology level: ",
		research.get_state(
			"technology_level",
			0.0
		)
	])

	_out([
		"Completed technologies: ",
		research.get_state(
			"technologies",
			{}
		)
	])

	_out([
		"Active projects: ",
		research.get_active_project_count()
	])

	_out([
		"Completed projects: ",
		research.get_state(
			"completed_projects",
			{}
		).size()
	])

	_out([
		"Unlocked capabilities: ",
		research.get_state(
			"capabilities",
			{}
		)
	])

	_out([
		"Research history entries: ",
		research.history.size()
	])
