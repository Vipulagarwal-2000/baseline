class_name GoalSystem
extends SimulationSystem


func _init():

	super(
		"goal_system"
	)


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"GoalSystem: World is null."
		)

		return


	for entity in world.entities.values():

		if entity == null:

			continue

		_update_dynamic_goal_priorities(
			entity
		)

		_process_entity_goals(
			entity
		)


# ============================================================
# DYNAMIC GOAL PRIORITIES
# ============================================================

func _update_dynamic_goal_priorities(
	entity
) -> void:

	if entity == null:

		return


	var dynamic_priorities: Dictionary = {}


	var strategy_signal = entity.get_sim_metadata(
		"military_strategy_signal",
		{}
	)


	if typeof(strategy_signal) != TYPE_DICTIONARY:

		strategy_signal = {}


	var military_priority_signal = clamp(
		float(
			strategy_signal.get(
				"military_priority_signal",
				0.0
			)
		),
		0.0,
		1.0
	)


	var defensive_need = clamp(
		float(
			strategy_signal.get(
				"defensive_need",
				0.0
			)
		),
		0.0,
		1.0
	)


	var projection_opportunity = clamp(
		float(
			strategy_signal.get(
				"projection_opportunity",
				0.0
			)
		),
		0.0,
		1.0
	)


	var strain_signal = clamp(
		float(
			strategy_signal.get(
				"strain_signal",
				0.0
			)
		),
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# MILITARY GOAL PRESSURE
	#
	# Current military conditions influence how important
	# an existing military goal becomes.
	#
	# This does NOT modify goal.priority itself.
	# --------------------------------------------------------

	var military_goal_signal = (
		military_priority_signal * 0.45
		+ defensive_need * 0.30
		+ projection_opportunity * 0.10
		+ strain_signal * 0.15
	)


	military_goal_signal = clamp(
		military_goal_signal,
		0.0,
		1.0
	)


	# --------------------------------------------------------
	# APPLY ONLY TO EXISTING MILITARY GOALS
	# --------------------------------------------------------

	for goal in entity.goals:

		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if goal.goal_type != "military":

			continue


		if not goal.is_active():

			continue


		if goal.is_completed():

			continue


		# Keep the dynamic contribution deliberately modest.
		#
		# Maximum modifier = 0.25
		#
		# This means military conditions influence goals
		# without completely overriding the underlying goal.
		var dynamic_modifier = (
			military_goal_signal * 0.25
		)


		dynamic_priorities[goal.id] = clamp(
			dynamic_modifier,
			0.0,
			0.25
		)


	entity.set_sim_metadata(
		"goal_dynamic_priorities",
		dynamic_priorities
	)


# ============================================================
# GET EFFECTIVE GOAL PRIORITY
# ============================================================

func get_effective_goal_priority(
	entity,
	goal: SimGoal
) -> float:

	if entity == null:

		return 0.0


	if goal == null:

		return 0.0


	var base_priority = clamp(
		goal.priority,
		0.0,
		1.0
	)


	var dynamic_priorities = entity.get_sim_metadata(
		"goal_dynamic_priorities",
		{}
	)


	if typeof(dynamic_priorities) != TYPE_DICTIONARY:

		return base_priority


	var dynamic_modifier = clamp(
		float(
			dynamic_priorities.get(
				goal.id,
				0.0
			)
		),
		0.0,
		0.25
	)


	return clamp(
		base_priority + dynamic_modifier,
		0.0,
		1.0
	)


# ============================================================
# GET DYNAMIC GOAL MODIFIER
# ============================================================

func get_dynamic_goal_modifier(
	entity,
	goal: SimGoal
) -> float:

	if entity == null:

		return 0.0


	if goal == null:

		return 0.0


	var dynamic_priorities = entity.get_sim_metadata(
		"goal_dynamic_priorities",
		{}
	)


	if typeof(dynamic_priorities) != TYPE_DICTIONARY:

		return 0.0


	return clamp(
		float(
			dynamic_priorities.get(
				goal.id,
				0.0
			)
		),
		0.0,
		0.25
	)


# ============================================================
# PROCESS ENTITY GOALS
# ============================================================

func _process_entity_goals(
	entity
) -> void:

	if entity == null:

		return


	if entity.goals.is_empty():

		return


	for goal in entity.goals:

		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if not goal.is_active():

			continue


		if goal.is_completed():

			continue


		# ----------------------------------------------------
		# Goals are not automatically advanced here.
		#
		# Other simulation systems will change progress.
		# ----------------------------------------------------

		goal.check_completion()


# ============================================================
# ADD GOAL
# ============================================================

func add_goal(
	entity,
	goal: SimGoal
) -> bool:

	if entity == null:

		return false


	if goal == null:

		return false


	if goal.id.is_empty():

		return false


	for existing_goal in entity.goals:

		if existing_goal == null:

			continue


		if not existing_goal is SimGoal:

			continue


		if existing_goal.id == goal.id:

			return false


	entity.goals.append(
		goal
	)


	return true


# ============================================================
# REMOVE GOAL
# ============================================================

func remove_goal(
	entity,
	goal_id: String
) -> bool:

	if entity == null:

		return false


	for index in range(
		entity.goals.size()
	):

		var goal = entity.goals[
			index
		]


		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if goal.id == goal_id:

			entity.goals.remove_at(
				index
			)

			return true


	return false


# ============================================================
# GET GOAL
# ============================================================

func get_goal(
	entity,
	goal_id: String
):

	if entity == null:

		return null


	for goal in entity.goals:

		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if goal.id == goal_id:

			return goal


	return null


# ============================================================
# GET ACTIVE GOALS
# ============================================================

func get_active_goals(
	entity
) -> Array:

	var result: Array = []


	if entity == null:

		return result


	for goal in entity.goals:

		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if not goal.is_active():

			continue


		if goal.is_completed():

			continue


		result.append(
			goal
		)


	return result


# ============================================================
# GET HIGHEST PRIORITY GOAL
# ============================================================

func get_highest_priority_goal(
	entity
):

	var active_goals = (
		get_active_goals(
			entity
		)
	)


	if active_goals.is_empty():

		return null


	var highest_priority_goal = (
		active_goals[0]
	)


	for goal in active_goals:

		var effective_priority = (
			get_effective_goal_priority(
				entity,
				goal
			)
		)


		var highest_priority = (
			get_effective_goal_priority(
				entity,
				highest_priority_goal
			)
		)


		if effective_priority > highest_priority:

			highest_priority_goal = goal


	return highest_priority_goal
