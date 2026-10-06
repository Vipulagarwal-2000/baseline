class_name InfrastructureRecoverySystem
extends SimulationSystem


const INFRASTRUCTURE_TYPES: Array[String] = [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


func _init() -> void:
	super("infrastructure_recovery_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("InfrastructureRecoverySystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue
		_process_entity(entity)


func get_recovered_damage(
	entity,
	infrastructure_type: String
) -> float:
	if entity == null or not INFRASTRUCTURE_TYPES.has(infrastructure_type):
		return 0.0

	var infrastructure = entity.get_component("infrastructure")
	if infrastructure == null:
		return 0.0

	var projects_value: Variant = infrastructure.get_state(
		"reconstruction_projects",
		[]
	)

	if typeof(projects_value) != TYPE_ARRAY:
		return 0.0

	var recovered: float = 0.0

	for project_value in projects_value:
		if typeof(project_value) != TYPE_DICTIONARY:
			continue

		var project: Dictionary = project_value
		if str(project.get("infrastructure_type", "")) != infrastructure_type:
			continue

		recovered += maxf(
			float(project.get("applied_damage_reduction", 0.0)),
			0.0
		)

	return clampf(recovered, 0.0, 1.0)


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

	var damage_value: Variant = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)

	var damage_state: Dictionary = {}
	if typeof(damage_value) == TYPE_DICTIONARY:
		damage_state = damage_value.duplicate(true)

	var projects: Array = (projects_value as Array).duplicate(true)
	var changed: bool = false

	for project_value in projects:
		if typeof(project_value) != TYPE_DICTIONARY:
			continue

		var project: Dictionary = project_value
		var status: String = str(project.get("status", ""))

		if status != "active" and status != "funded_ready_for_recovery":
			continue

		var infrastructure_type: String = str(
			project.get("infrastructure_type", "")
		)

		if not INFRASTRUCTURE_TYPES.has(infrastructure_type):
			continue

		var committed_reduction: float = clampf(
			float(project.get("committed_damage_reduction", 0.0)),
			0.0,
			1.0
		)

		if committed_reduction <= 0.0:
			project["status"] = "recovered"
			project["recovery_completed"] = true
			changed = true
			continue

		var progress: float = clampf(
			float(project.get("progress", 0.0)),
			0.0,
			1.0
		)

		var previous_applied: float = clampf(
			float(project.get("applied_damage_reduction", 0.0)),
			0.0,
			committed_reduction
		)

		var target_applied: float = minf(
			committed_reduction * progress,
			committed_reduction
		)

		var incremental_recovery: float = maxf(
			target_applied - previous_applied,
			0.0
		)

		var current_damage: float = clampf(
			float(damage_state.get(infrastructure_type, 0.0)),
			0.0,
			1.0
		)

		var actual_recovery: float = minf(
			incremental_recovery,
			current_damage
		)

		if actual_recovery > 0.0:
			damage_state[infrastructure_type] = clampf(
				current_damage - actual_recovery,
				0.0,
				1.0
			)

			project["applied_damage_reduction"] = minf(
				previous_applied + actual_recovery,
				committed_reduction
			)
			changed = true

		if progress >= 1.0:
			project["status"] = "recovered"
			project["recovery_completed"] = true
			project["recovery_completed_months"] = int(
				project.get("months_elapsed", 0)
			)
			changed = true

	if not changed:
		return

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		damage_state[infrastructure_type] = clampf(
			float(damage_state.get(infrastructure_type, 0.0)),
			0.0,
			1.0
		)

	infrastructure.set_state(
		"infrastructure_damage",
		damage_state
	)

	infrastructure.set_state(
		"infrastructure_damage_total",
		_calculate_total_damage(damage_state)
	)

	infrastructure.set_state(
		"reconstruction_projects",
		projects
	)


func _calculate_total_damage(damage_state: Dictionary) -> float:
	var total: float = 0.0

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		total += clampf(
			float(damage_state.get(infrastructure_type, 0.0)),
			0.0,
			1.0
		)

	return clampf(
		total / float(INFRASTRUCTURE_TYPES.size()),
		0.0,
		1.0
	)
