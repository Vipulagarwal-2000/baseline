class_name ResearchComponent
extends SimComponent


func _init(owner: String = ""):

	super(
		"research",
		owner
	)

	state = {

		# ====================================================
		# RESEARCH CAPACITY
		# ====================================================

		"research_capacity": 0.0,
		"research_funding": 0.0,
		"researchers": 0.0,
		"research_institutions": 0.0,

		# ====================================================
		# RESEARCH ACTIVITY
		# ====================================================

		"research_efficiency": 1.0,
		"research_output": 0.0,

		# ====================================================
		# TECHNOLOGY
		# ====================================================

		"technology_level": 0.0,

		# ====================================================
		# ACTIVE RESEARCH
		# ====================================================

		"active_projects": {},

		# ====================================================
		# COMPLETED RESEARCH
		# ====================================================

		"completed_projects": {},

		# ====================================================
		# TECHNOLOGY CAPABILITIES
		# ====================================================

		"technologies": {},
		"capabilities": {},

		# ====================================================
		# RESEARCH PROGRESS
		# ====================================================

		"research_progress": {}
	}


# ============================================================
# PROJECT MANAGEMENT
# ============================================================

func add_project(
	project: ResearchProject
) -> bool:

	if project == null:

		push_error(
			"ResearchComponent: Cannot add null project."
		)

		return false


	if project.id.strip_edges() == "":

		push_error(
			"ResearchComponent: Project id cannot be empty."
		)

		return false


	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		active_projects = {}


	if active_projects.has(
		project.id
	):

		push_error(
			"ResearchComponent: Project already exists: "
			+ project.id
		)

		return false


	active_projects[
		project.id
	] = project


	set_state(
		"active_projects",
		active_projects
	)

	return true


func get_project(
	project_id: String
):

	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		return null


	return active_projects.get(
		project_id,
		null
	)


func has_project(
	project_id: String
) -> bool:

	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		return false


	return active_projects.has(
		project_id
	)


func remove_project(
	project_id: String
) -> void:

	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		active_projects = {}


	active_projects.erase(
		project_id
	)


	set_state(
		"active_projects",
		active_projects
	)


func get_active_project_count() -> int:

	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		return 0


	return active_projects.size()


# ============================================================
# COMPLETE PROJECT
# ============================================================

func complete_project(
	project_id: String,
	project: ResearchProject
) -> bool:

	if project == null:

		return false


	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(active_projects) != TYPE_DICTIONARY:

		return false


	if not active_projects.has(
		project_id
	):

		return false


	active_projects.erase(
		project_id
	)


	set_state(
		"active_projects",
		active_projects
	)


	var completed_projects = get_state(
		"completed_projects",
		{}
	)


	if typeof(completed_projects) != TYPE_DICTIONARY:

		completed_projects = {}


	completed_projects[
		project_id
	] = project


	set_state(
		"completed_projects",
		completed_projects
	)

	return true


# ============================================================
# TECHNOLOGY ELIGIBILITY
# ============================================================

func can_start_research(
	technology: TechnologyData,
	current_year: int
) -> bool:

	if technology == null:

		return false


	# --------------------------------------------------------
	# Already researched?
	# --------------------------------------------------------

	var completed_technologies = get_state(
		"technologies",
		{}
	)


	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		completed_technologies = {}


	if completed_technologies.has(
		technology.id
	):

		if bool(
			completed_technologies[
				technology.id
			]
		):

			return false


	# --------------------------------------------------------
	# Already being researched?
	# --------------------------------------------------------

	var active_projects = get_state(
		"active_projects",
		{}
	)


	if typeof(
		active_projects
	) == TYPE_DICTIONARY:

		var project_id = (
			_get_project_id_for_technology(
				technology.id
			)
		)


		if active_projects.has(
			project_id
		):

			return false


	# --------------------------------------------------------
	# Technology rules
	# --------------------------------------------------------

	var technology_level = float(
		get_state(
			"technology_level",
			0.0
		)
	)


	return technology.can_be_researched(
		technology_level,
		completed_technologies,
		current_year
	)


# ============================================================
# START RESEARCH
# ============================================================

func start_research(
	technology: TechnologyData,
	current_year: int,
	date: Dictionary,
	priority: float = 1.0
) -> ResearchProject:

	if technology == null:

		push_error(
			"ResearchComponent: Cannot start null technology."
		)

		return null


	# --------------------------------------------------------
	# Validate date
	# --------------------------------------------------------

	if date == null:

		push_error(
			"ResearchComponent: Research start date is null."
		)

		return null


	# --------------------------------------------------------
	# Validate eligibility
	# --------------------------------------------------------

	if not can_start_research(
		technology,
		current_year
	):

		return null


	# --------------------------------------------------------
	# Create deterministic project ID
	# --------------------------------------------------------

	var project_id = (
		_get_project_id_for_technology(
			technology.id
		)
	)


	# --------------------------------------------------------
	# Create project
	# --------------------------------------------------------

	var project = ResearchProject.new(
		project_id,
		technology.id,
		owner_id
	)


	project.research_cost = max(
		0.0,
		float(
			technology.research_cost
		)
	)


	project.duration_months = max(
		0,
		int(
			technology.research_duration_months
		)
	)


	project.priority = max(
		0.0,
		priority
	)


	# --------------------------------------------------------
	# Start project
	# --------------------------------------------------------

	var started = project.start(
		date
	)


	if not started:

		push_error(
			"ResearchComponent: Failed to start project: "
			+ project_id
		)

		return null


	# --------------------------------------------------------
	# Register project
	# --------------------------------------------------------

	if not add_project(
		project
	):

		return null


	return project


# ============================================================
# PROJECT ID
# ============================================================

func _get_project_id_for_technology(
	technology_id: String
) -> String:

	return (
		"research_"
		+ technology_id
	)


# ============================================================
# MISSING PREREQUISITES
# ============================================================

func get_missing_prerequisites(
	technology: TechnologyData
) -> Array:

	var missing: Array = []


	if technology == null:

		return missing


	var completed_technologies = get_state(
		"technologies",
		{}
	)


	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		completed_technologies = {}


	for prerequisite_id in (
		technology.prerequisites
	):

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


# ============================================================
# AVAILABLE TECHNOLOGIES
# ============================================================

func get_available_technologies(
	technology_manager: TechnologyManager,
	current_year: int
) -> Array:

	var available: Array = []


	if technology_manager == null:

		return available


	var technology_level = float(
		get_state(
			"technology_level",
			0.0
		)
	)


	var completed_technologies = get_state(
		"technologies",
		{}
	)


	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		completed_technologies = {}


	var manager_available = (
		technology_manager.get_available_technologies(
			technology_level,
			completed_technologies,
			current_year
		)
	)


	for technology in manager_available:

		if technology == null:

			continue


		var project_id = (
			_get_project_id_for_technology(
				technology.id
			)
		)


		var active_projects = get_state(
			"active_projects",
			{}
		)


		if typeof(
			active_projects
		) == TYPE_DICTIONARY:

			if active_projects.has(
				project_id
			):

				continue


		available.append(
			technology
		)


	return available


# ============================================================
# RESEARCH CAPABILITIES
# ============================================================

func has_research_capability(
	capability_id: String
) -> bool:

	var research_capabilities = get_state(
		"capabilities",
		{}
)


	if typeof(
		research_capabilities
	) != TYPE_DICTIONARY:

		return false


	return bool(
		research_capabilities.get(
			capability_id,
			false
		)
	)


func add_research_capability(
	capability_id: String
) -> void:

	if capability_id.is_empty():

		return


	var research_capabilities = get_state(
		"capabilities",
		{}
)


	if typeof(
		research_capabilities
	) != TYPE_DICTIONARY:

		research_capabilities = {}


	research_capabilities[
		capability_id
	] = true


	set_state(
		"capabilities",
		research_capabilities
	)


func get_research_capabilities() -> Dictionary:

	var research_capabilities = get_state(
		"capabilities",
		{}
	)

	if typeof(
		research_capabilities
	) != TYPE_DICTIONARY:

		return {}

	return research_capabilities
