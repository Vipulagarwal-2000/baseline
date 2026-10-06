class_name DecisionTrajectorySystem
extends SimulationSystem


func _init():
	super("decision_trajectory_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("DecisionTrajectorySystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity_trajectories(entity)


func _process_entity_trajectories(entity) -> void:

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		trajectories = []

	for trajectory in trajectories:

		if trajectory == null:
			continue

		if not trajectory is DecisionTrajectory:
			continue

		if not trajectory.is_active():
			continue

		# Environmental and external changes will be
		# applied by other systems.
		#
		# This system currently maintains the trajectory
		# collection and its active state.


func add_trajectory(
	entity,
	trajectory: DecisionTrajectory
) -> bool:

	if entity == null:
		return false

	if trajectory == null:
		return false

	if trajectory.id.is_empty():
		return false

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		trajectories = []

	for existing in trajectories:

		if existing == null:
			continue

		if not existing is DecisionTrajectory:
			continue

		if existing.id == trajectory.id:
			return false

	trajectories.append(
		trajectory
	)

	entity.set_sim_metadata(
		"decision_trajectories",
		trajectories
	)

	return true


func get_trajectory(
	entity,
	trajectory_id: String
):

	if entity == null:
		return null

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		return null

	for trajectory in trajectories:

		if trajectory == null:
			continue

		if not trajectory is DecisionTrajectory:
			continue

		if trajectory.id == trajectory_id:
			return trajectory

	return null


func get_active_trajectories(
	entity
) -> Array:

	var result: Array = []

	if entity == null:
		return result

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		return result

	for trajectory in trajectories:

		if trajectory == null:
			continue

		if not trajectory is DecisionTrajectory:
			continue

		if not trajectory.is_active():
			continue

		if trajectory.is_resolved():
			continue

		result.append(
			trajectory
		)

	return result


func change_trajectory(
	entity,
	trajectory_id: String,
	change: float,
	source: String = "external"
) -> bool:

	var trajectory = get_trajectory(
		entity,
		trajectory_id
	)

	if trajectory == null:
		return false

	match source:

		"player":
			trajectory.add_player_contribution(
				change
			)

		"ai":
			trajectory.add_ai_contribution(
				change
			)

		"environment":
			trajectory.add_environmental_contribution(
				change
			)

		"external_actor":
			trajectory.add_external_actor_contribution(
				change
			)

		_:
			trajectory.change_value(
				change
			)

	return true

# ============================================================
# STEP 15.13 — ACTION OUTCOME FEEDBACK
# ============================================================

func record_action_outcome_feedback(
	world: WorldState,
	outcome: Dictionary
) -> int:
	if world == null:
		return 0

	if outcome.is_empty():
		return 0

	var actor_id: String = str(
		outcome.get(
			"actor",
			""
		)
	)

	if actor_id.is_empty():
		return 0

	var entity = world.get_entity(
		actor_id
	)

	if entity == null:
		return 0

	var target_id: String = str(
		outcome.get(
			"target",
			""
		)
	)

	var action_type: String = str(
		outcome.get(
			"type",
			""
		)
	)

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		return 0

	var recorded_count: int = 0

	for trajectory_variant in trajectories:
		if trajectory_variant == null:
			continue

		if not trajectory_variant is DecisionTrajectory:
			continue

		var trajectory: DecisionTrajectory = trajectory_variant

		if not trajectory.actor_id.is_empty():
			if trajectory.actor_id != actor_id:
				continue

		if not trajectory.target_id.is_empty():
			if trajectory.target_id != target_id:
				continue

		if not trajectory.situation_type.is_empty():
			var normalized_action_type: String = _normalize_action_category(action_type)
			if trajectory.situation_type != action_type and trajectory.situation_type != normalized_action_type:
				continue

		if trajectory.record_action_outcome_feedback(
			outcome
		):
			recorded_count += 1

	return recorded_count


func get_action_outcome_feedback(
	entity
) -> Array:
	if entity == null:
		return []

	var trajectories = entity.get_sim_metadata(
		"decision_trajectories",
		[]
	)

	if typeof(trajectories) != TYPE_ARRAY:
		return []

	var result: Array = []

	for trajectory_variant in trajectories:
		if trajectory_variant == null:
			continue

		if not trajectory_variant is DecisionTrajectory:
			continue

		var trajectory: DecisionTrajectory = trajectory_variant
		var feedback: Array = trajectory.get_action_outcome_feedback()

		for feedback_variant in feedback:
			if typeof(feedback_variant) != TYPE_DICTIONARY:
				continue

			result.append(
				feedback_variant.duplicate(true)
			)

	return result



func _normalize_action_category(action_type: String) -> String:
	match action_type:
		"diplomatic_outreach":
			return "diplomatic"
		"expand_trade":
			return "economic"
		_:
			return action_type
