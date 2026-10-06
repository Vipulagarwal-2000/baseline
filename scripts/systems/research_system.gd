class_name ResearchSystem
extends SimulationSystem


var technology_manager: TechnologyManager


func _init(
	manager: TechnologyManager = null
):

	super(
		"research_system"
	)


	if manager == null:

		technology_manager = (
			TechnologyManager.new()
		)

	else:

		technology_manager = manager


func get_technology_manager() -> TechnologyManager:

	return technology_manager


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"ResearchSystem: World is null."
		)

		return


	for entity in world.entities.values():

		var research = (
			entity.get_component(
				"research"
			)
		)


		if research == null:

			continue


		# ----------------------------------------------------
		# CALCULATE RESEARCH OUTPUT
		# ----------------------------------------------------

		var research_output = (
			_calculate_research_output(
				research
			)
		)


		research.set_state(
			"research_output",
			research_output
		)


		# ----------------------------------------------------
		# UPDATE TECHNOLOGY LEVEL
		# ----------------------------------------------------

		var current_technology_level = float(
			research.get_state(
				"technology_level",
				0.0
			)
		)


		var technology_level_change = (
			research_output
			/ 100.0
		)


		var new_technology_level = (
			current_technology_level
			+ technology_level_change
		)


		research.set_state(
			"technology_level",
			new_technology_level
		)


		# ----------------------------------------------------
		# PROCESS ACTIVE PROJECTS
		# ----------------------------------------------------

		_process_active_projects(
			entity,
			research,
			world
		)


		# ----------------------------------------------------
		# REBUILD CAPABILITIES
		# ----------------------------------------------------

		rebuild_capabilities(
			research
		)


		# ----------------------------------------------------
		# RESEARCH HISTORY
		# ----------------------------------------------------

		research.add_history_entry({

			"year":
				world.get_year(),

			"month":
				world.get_month(),

			"research_output":
				research_output,

			"technology_level":
				new_technology_level,

			"active_projects":
				research.get_active_project_count()
		})


# ============================================================
# RESEARCH OUTPUT
# ============================================================

func _calculate_research_output(
	research: ResearchComponent
) -> float:

	var research_capacity = float(
		research.get_state(
			"research_capacity",
			0.0
		)
	)


	var research_funding = float(
		research.get_state(
			"research_funding",
			0.0
		)
	)


	var researchers = float(
		research.get_state(
			"researchers",
			0.0
		)
	)


	var research_institutions = float(
		research.get_state(
			"research_institutions",
			0.0
		)
	)


	var research_efficiency = float(
		research.get_state(
			"research_efficiency",
			1.0
		)
	)


	research_capacity = max(
		0.0,
		research_capacity
	)

	research_funding = max(
		0.0,
		research_funding
	)

	researchers = max(
		0.0,
		researchers
	)

	research_institutions = max(
		0.0,
		research_institutions
	)

	research_efficiency = max(
		0.0,
		research_efficiency
	)


	var funding_multiplier = min(
		research_funding / 10.0,
		2.0
	)


	var researcher_multiplier = min(
		researchers / 10.0,
		2.0
	)


	var institution_multiplier = min(
		research_institutions / 10.0,
		2.0
	)


	var output = (
		research_capacity
		* funding_multiplier
		* researcher_multiplier
		* institution_multiplier
		* research_efficiency
	)


	return max(
		0.0,
		output
	)


# ============================================================
# ACTIVE RESEARCH PROJECTS
# ============================================================

func _process_active_projects(
	entity,
	research: ResearchComponent,
	world: WorldState
) -> void:

	var active_projects = (
		research.get_state(
			"active_projects",
			{}
		)
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		return


	if active_projects.is_empty():

		return


	var research_output = float(
		research.get_state(
			"research_output",
			0.0
		)
	)


	if research_output <= 0.0:

		return


	var project_ids = (
		active_projects.keys()
	)


	var active_project_count = (
		project_ids.size()
	)


	if active_project_count <= 0:

		return


	var project_output = (
		research_output
		/ float(active_project_count)
	)


	for project_id in project_ids:

		var project = (
			research.get_project(
				str(project_id)
			)
		)


		if project == null:

			continue


		if project.completed:

			continue


		# ------------------------------------------------
		# ADD MONTHLY RESEARCH PROGRESS
		# ------------------------------------------------

		project.add_progress(
			project_output
		)


		project.elapsed_months += 1


		# ------------------------------------------------
		# CURRENT SIMULATION DATE
		# ------------------------------------------------

		var completion_date = {

			"year":
				world.get_year(),

			"month":
				world.get_month(),

			"day":
				world.get_day()
		}


		# ------------------------------------------------
		# CHECK COMPLETION
		# ------------------------------------------------

		var project_completed = (
			project.check_completion(
				completion_date
			)
		)


		if project_completed:

			_complete_research_project(
				entity,
				research,
				project,
				world
			)


# ============================================================
# COMPLETE RESEARCH PROJECT
# ============================================================

func _complete_research_project(
	entity,
	research: ResearchComponent,
	project: ResearchProject,
	world: WorldState
) -> void:

	if project == null:

		return


	var technology_id = str(
		project.technology_id
	)


	if technology_id.is_empty():

		return


	var technology = (
		technology_manager.get_technology(
			technology_id
		)
	)


	if technology == null:

		push_error(
			"ResearchSystem: Technology not found: "
			+ technology_id
		)

		return


	# --------------------------------------------------------
	# MARK PROJECT COMPLETE
	# --------------------------------------------------------

	project.completed = true


	project.completion_date = {

		"year":
			world.get_year(),

		"month":
			world.get_month(),

		"day":
			world.get_day()
	}


	# --------------------------------------------------------
	# MOVE PROJECT TO COMPLETED PROJECTS
	# --------------------------------------------------------

	research.complete_project(
		project.id,
		project
	)


	# --------------------------------------------------------
	# MARK TECHNOLOGY AS RESEARCHED
	# --------------------------------------------------------

	var completed_technologies = (
		research.get_state(
			"technologies",
			{}
		)
	)


	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		completed_technologies = {}


	completed_technologies[
		technology_id
	] = 1.0


	research.set_state(
		"technologies",
		completed_technologies
	)


	# --------------------------------------------------------
	# ADD TECHNOLOGY CAPABILITIES
	# --------------------------------------------------------

	for capability_id in technology.capabilities:

		research.add_research_capability(
			str(capability_id)
		)


	# --------------------------------------------------------
	# INITIALIZE TECHNOLOGY ADOPTION
	# --------------------------------------------------------

	var technology_adoption = (
		entity.get_component(
			"technology_adoption"
		)
	)


	if technology_adoption != null:

		if not technology_adoption.has_adoption(
			technology_id
		):

			technology_adoption.set_adoption(
				technology_id,
				0.0
			)


	# --------------------------------------------------------
	# RESEARCH PROGRESS RECORD
	# --------------------------------------------------------

	var research_progress = (
		research.get_state(
			"research_progress",
			{}
		)
	)


	if typeof(
		research_progress
	) != TYPE_DICTIONARY:

		research_progress = {}


	research_progress[
		technology_id
	] = {

		"progress":
			project.progress,

		"research_cost":
			project.research_cost,

		"duration_months":
			project.duration_months,

		"elapsed_months":
			project.elapsed_months,

		"completed":
			true,

		"completion_year":
			world.get_year(),

		"completion_month":
			world.get_month()
	}


	research.set_state(
		"research_progress",
		research_progress
	)


	# --------------------------------------------------------
	# HISTORY
	# --------------------------------------------------------

	research.add_history_entry({

		"year":
			world.get_year(),

		"month":
			world.get_month(),

		"type":
			"technology_completed",

		"technology_id":
			technology_id,

		"technology_name":
			technology.name,

		"research_output":
			research.get_state(
				"research_output",
				0.0
			)
	})


# ============================================================
# REBUILD RESEARCH CAPABILITIES
# ============================================================

func rebuild_capabilities(
	research: ResearchComponent
) -> void:

	if research == null:

		return


	var completed_technologies = (
		research.get_state(
			"technologies",
			{}
		)
	)


	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		return


	for technology_id in (
		completed_technologies.keys()
	):

		if not bool(
			completed_technologies[
				technology_id
			]
		):

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
