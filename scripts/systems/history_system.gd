class_name HistorySystem
extends SimulationSystem


func _init():

	super(
		"history_system"
	)


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"HistorySystem: World is null."
		)

		return


	_record_world_tick(
		world
	)


# ============================================================
# RECORD WORLD TICK
# ============================================================

func _record_world_tick(
	world: WorldState
) -> void:

	var entry = {

		"type":
			"simulation_tick",

		"year":
			world.get_year(),

		"month":
			world.get_month(),

		"day":
			world.get_day(),

		"elapsed_months":
			world.get_elapsed_months()
	}


	_record_world_history(
		world,
		entry
	)


# ============================================================
# RECORD WORLD HISTORY
# ============================================================

func _record_world_history(
	world: WorldState,
	entry: Dictionary
) -> void:

	var history = (
		world.get_metadata(
			"history",
			[]
		)
	)


	if typeof(
		history
	) != TYPE_ARRAY:

		history = []


	history.append(
		entry
	)


	world.set_metadata(
		"history",
		history
	)


# ============================================================
# RECORD ENTITY EVENT
# ============================================================

func record_entity_event(
	world: WorldState,
	entity_id: String,
	event_type: String,
	data: Dictionary = {}
) -> void:

	if world == null:

		return


	var entity = (
		world.get_entity(
			entity_id
		)
	)


	if entity == null:

		return


	var entry = {

		"type":
			event_type,

		"entity_id":
			entity_id,

		"year":
			world.get_year(),

		"month":
			world.get_month(),

		"day":
			world.get_day(),

		"data":
			data.duplicate(true)
	}


	entity.add_memory(
		entry
	)


# ============================================================
# RECORD WORLD EVENT
# ============================================================

func record_world_event(
	world: WorldState,
	event_type: String,
	data: Dictionary = {}
) -> void:

	if world == null:

		return


	var entry = {

		"type":
			event_type,

		"year":
			world.get_year(),

		"month":
			world.get_month(),

		"day":
			world.get_day(),

		"data":
			data.duplicate(true)
	}


	_record_world_history(
		world,
		entry
	)


# ============================================================
# GET WORLD HISTORY
# ============================================================

func get_world_history(
	world: WorldState
) -> Array:

	if world == null:

		return []


	var history = (
		world.get_metadata(
			"history",
			[]
		)
	)


	if typeof(
		history
	) != TYPE_ARRAY:

		return []


	return history


# ============================================================
# GET ENTITY HISTORY
# ============================================================

func get_entity_history(
	world: WorldState,
	entity_id: String
) -> Array:

	if world == null:

		return []


	var entity = (
		world.get_entity(
			entity_id
		)
	)


	if entity == null:

		return []


	return entity.memory


# ============================================================
# GET RECENT WORLD HISTORY
# ============================================================

func get_recent_world_history(
	world: WorldState,
	count: int = 10
) -> Array:

	var history = (
		get_world_history(
			world
		)
	)


	if history.is_empty():

		return []


	var start_index = max(
		0,
		history.size() - count
	)


	var recent: Array = []


	for index in range(
		start_index,
		history.size()
	):

		recent.append(
			history[index]
		)


	return recent


# ============================================================
# GET RECENT ENTITY HISTORY
# ============================================================

func get_recent_entity_history(
	world: WorldState,
	entity_id: String,
	count: int = 10
) -> Array:

	var history = (
		get_entity_history(
			world,
			entity_id
		)
	)


	if history.is_empty():

		return []


	var start_index = max(
		0,
		history.size() - count
	)


	var recent: Array = []


	for index in range(
		start_index,
		history.size()
	):

		recent.append(
			history[index]
		)


	return recent
