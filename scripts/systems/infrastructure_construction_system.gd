class_name InfrastructureConstructionSystem
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
	super("infrastructure_construction_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"InfrastructureConstructionSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(
			entity
		)


func create_project(
	entity,
	infrastructure_type: String,
	capacity_gain: float,
	money_cost: float,
	industrial_capacity_cost: float,
	construction_months: int
) -> Dictionary:

	if entity == null:
		return {}

	if not INFRASTRUCTURE_TYPES.has(
		infrastructure_type
	):
		return {}

	if capacity_gain <= 0.0:
		return {}

	if money_cost < 0.0:
		return {}

	if industrial_capacity_cost < 0.0:
		return {}

	if construction_months <= 0:
		return {}

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	var economy = entity.get_component(
		"economy"
	)

	if infrastructure == null or economy == null:
		return {}

	var current_capacity: float = clampf(
		float(
			infrastructure.get_state(
				infrastructure_type,
				0.0
			)
		),
		0.0,
		1.0
	)

	if current_capacity >= 1.0:
		return {}

	var treasury: float = maxf(
		float(
			economy.get_state(
				"treasury",
				0.0
			)
		),
		0.0
	)

	var infrastructure_investment_budget: float = maxf(
		float(
			economy.get_state(
				"infrastructure_investment_budget",
				0.0
			)
		),
		0.0
	)

	var unallocated_capacity: float = maxf(
		float(
			economy.get_state(
				"unallocated_industrial_capacity",
				0.0
			)
		),
		0.0
	)

	var investment_funded: float = minf(
		money_cost,
		infrastructure_investment_budget
	)

	var remaining_money_cost: float = maxf(
		money_cost - investment_funded,
		0.0
	)

	if treasury < remaining_money_cost:
		return {}

	if unallocated_capacity < industrial_capacity_cost:
		return {}

	var projects_value: Variant = infrastructure.get_state(
		"construction_projects",
		[]
	)

	var projects: Array = []

	if typeof(projects_value) == TYPE_ARRAY:
		projects = projects_value

	var project_index: int = projects.size() + 1
	var project_id: String = (
		str(entity.id)
		+ "_infra_"
		+ infrastructure_type
		+ "_"
		+ str(project_index)
	)

	var treasury_funded: float = remaining_money_cost
	var funding_source: String = "treasury"

	if investment_funded > 0.0 and treasury_funded > 0.0:
		funding_source = "mixed"
	elif investment_funded > 0.0:
		funding_source = "infrastructure_investment"

	var project: Dictionary = {
		"project_id": project_id,
		"infrastructure_type": infrastructure_type,
		"capacity_gain": capacity_gain,
		"money_cost": money_cost,
		"industrial_capacity_cost": industrial_capacity_cost,
		"construction_months": construction_months,
		"months_elapsed": 0,
		"progress": 0.0,
		"status": "active",
		"applied_capacity_gain": 0.0,
		"investment_funded": investment_funded,
		"treasury_funded": treasury_funded,
		"funding_source": funding_source
	}

	projects.append(
		project
	)

	economy.set_state(
		"infrastructure_investment_budget",
		infrastructure_investment_budget - investment_funded
	)

	economy.set_state(
		"treasury",
		treasury - treasury_funded
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		unallocated_capacity - industrial_capacity_cost
	)

	infrastructure.set_state(
		"construction_projects",
		projects
	)

	return project


func get_projects(
	entity
) -> Array:

	if entity == null:
		return []

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return []

	var projects_value: Variant = infrastructure.get_state(
		"construction_projects",
		[]
	)

	if typeof(projects_value) != TYPE_ARRAY:
		return []

	var projects: Array = projects_value as Array
	return projects


func _process_entity(
	entity
) -> void:

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return

	var projects_value: Variant = infrastructure.get_state(
		"construction_projects",
		[]
	)

	if typeof(projects_value) != TYPE_ARRAY:
		return

	var projects: Array = projects_value as Array

	for project in projects:

		if typeof(project) != TYPE_DICTIONARY:
			continue

		if str(
			project.get(
				"status",
				""
			)
		) != "active":
			continue

		var construction_months: int = max(
			int(
				project.get(
					"construction_months",
					1
				)
			),
			1
		)

		var months_elapsed: int = max(
			int(
				project.get(
					"months_elapsed",
					0
				)
			),
			0
		)

		months_elapsed += 1

		var progress: float = clampf(
			float(months_elapsed)
			/ float(construction_months),
			0.0,
			1.0
		)

		project[
			"months_elapsed"
		] = months_elapsed

		project[
			"progress"
		] = progress

		if months_elapsed < construction_months:
			continue

		var infrastructure_type: String = str(
			project.get(
				"infrastructure_type",
				""
			)
		)

		var requested_capacity_gain: float = maxf(
			float(
				project.get(
					"capacity_gain",
					0.0
				)
			),
			0.0
		)

		var current_capacity: float = clampf(
			float(
			infrastructure.get_state(
				infrastructure_type,
				0.0
			)
		),
			0.0,
			1.0
		)

		var actual_capacity_gain: float = minf(
			requested_capacity_gain,
			1.0 - current_capacity
		)

		infrastructure.set_state(
			infrastructure_type,
			current_capacity + actual_capacity_gain
		)

		project[
			"applied_capacity_gain"
		] = actual_capacity_gain

		project[
			"status"
		] = "completed"
