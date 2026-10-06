class_name InfrastructureReconstructionInvestmentSystem
extends SimulationSystem


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


func _init() -> void:
	super("infrastructure_reconstruction_investment_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("InfrastructureReconstructionInvestmentSystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue
		_process_entity(entity)


func get_projects(entity) -> Array:
	if entity == null:
		return []

	var infrastructure = entity.get_component("infrastructure")
	if infrastructure == null:
		return []

	var projects_value: Variant = infrastructure.get_state(
		"reconstruction_projects",
		[]
	)

	if typeof(projects_value) != TYPE_ARRAY:
		return []

	return (projects_value as Array)


func get_committed_investment(entity) -> float:
	if entity == null:
		return 0.0

	var infrastructure = entity.get_component("infrastructure")
	if infrastructure == null:
		return 0.0

	var projects: Array = get_projects(entity)
	var committed: float = 0.0

	for project in projects:
		if typeof(project) != TYPE_DICTIONARY:
			continue
		if str(project.get("status", "")) != "active":
			continue
		committed += maxf(
			float(project.get("investment_funded", 0.0)),
			0.0
		)

	return committed


func create_reconstruction_project(
	entity,
	infrastructure_type: String,
	damage_reduction: float,
	investment_cost: float,
	reconstruction_months: int
) -> Dictionary:
	if entity == null:
		return {}

	if not INFRASTRUCTURE_TYPES.has(infrastructure_type):
		return {}

	if damage_reduction <= 0.0:
		return {}

	if investment_cost <= 0.0:
		return {}

	if reconstruction_months <= 0:
		return {}

	var infrastructure = entity.get_component("infrastructure")
	var economy = entity.get_component("economy")

	if infrastructure == null or economy == null:
		return {}

	var damage_state: Variant = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)

	if typeof(damage_state) != TYPE_DICTIONARY:
		return {}

	var current_damage: float = clampf(
		float(damage_state.get(infrastructure_type, 0.0)),
		0.0,
		1.0
	)

	if current_damage <= 0.0:
		return {}

	var requested_repair: float = minf(
		damage_reduction,
		current_damage
	)

	if requested_repair <= 0.0:
		return {}

	# Existing InfrastructureInvestmentSystem is the sole owner of
	# creating this budget. Reconstruction only consumes that budget.
	var investment_budget: float = maxf(
		float(
			economy.get_state(
				"infrastructure_investment_budget",
				0.0
			)
		),
		0.0
	)

	if investment_budget < investment_cost:
		return {}

	var projects: Array = get_projects(entity).duplicate(true)
	var project_index: int = projects.size() + 1
	var project_id: String = (
		str(entity.id)
		+ "_reconstruction_"
		+ infrastructure_type
		+ "_"
		+ str(project_index)
	)

	var project: Dictionary = {
		"project_id": project_id,
		"infrastructure_type": infrastructure_type,
		"requested_damage_reduction": damage_reduction,
		"committed_damage_reduction": requested_repair,
		"investment_cost": investment_cost,
		"investment_funded": investment_cost,
		"reconstruction_months": reconstruction_months,
		"months_elapsed": 0,
		"progress": 0.0,
		"status": "active",
		"applied_damage_reduction": 0.0,
		"funding_source": "infrastructure_investment"
	}

	projects.append(project)

	economy.set_state(
		"infrastructure_investment_budget",
		investment_budget - investment_cost
	)

	infrastructure.set_state(
		"reconstruction_projects",
		projects
	)

	return project


func _process_entity(entity) -> void:
	var infrastructure = entity.get_component("infrastructure")
	if infrastructure == null:
		return

	var projects_value: Variant = infrastructure.get_state(
		"reconstruction_projects",
		[]
	)

	if typeof(projects_value) != TYPE_ARRAY:
		return

	var projects: Array = projects_value as Array

	for project in projects:
		if typeof(project) != TYPE_DICTIONARY:
			continue

		if str(project.get("status", "")) != "active":
			continue

		var reconstruction_months: int = max(
			int(project.get("reconstruction_months", 1)),
			1
		)
		var months_elapsed: int = max(
			int(project.get("months_elapsed", 0)),
			0
		)

		months_elapsed += 1

		project["months_elapsed"] = months_elapsed
		project["progress"] = clampf(
			float(months_elapsed) / float(reconstruction_months),
			0.0,
			1.0
		)

		# Step 14.5 commits reconstruction investment and tracks project
		# progress. It does not yet modify damage or effective capacity;
		# that recovery consequence belongs to Step 14.6.
		if months_elapsed >= reconstruction_months:
			project["status"] = "funded_ready_for_recovery"

	infrastructure.set_state(
		"reconstruction_projects",
		projects
	)
