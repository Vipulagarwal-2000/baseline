class_name SimEntity
extends RefCounted


var id: String
var name: String
var entity_type: String

var components: Dictionary = {}
var relationships: Dictionary = {}
var goals: Array = []
var memory: Array = []
var modifiers: Array = []

# Simulation-specific metadata.
# We use our own names because Object already provides
# native metadata methods such as get_meta() and set_meta().
var simulation_metadata: Dictionary = {}


func _init(
	entity_id: String,
	entity_name: String,
	type: String
):
	id = entity_id
	name = entity_name
	entity_type = type


# ============================================================
# COMPONENTS
# ============================================================

func add_component(component: SimComponent) -> void:
	if component == null:
		push_error("Cannot add a null component.")
		return

	component.owner_id = id
	components[component.component_type] = component


func get_component(component_type: String):
	return components.get(
		component_type,
		null
	)


func has_component(component_type: String) -> bool:
	return components.has(component_type)


func remove_component(component_type: String) -> void:
	components.erase(component_type)


# ============================================================
# RELATIONSHIPS
# ============================================================

func set_relationship(
	target_id: String,
	value: float
) -> void:

	var relationship = _get_or_create_relationship(
		target_id
	)

	relationship["overall"] = clamp(
		value,
		-100.0,
		100.0
	)

	relationships[target_id] = relationship


func get_relationship(
	target_id: String,
	default_value: float = 0.0
) -> float:

	if not relationships.has(target_id):
		return default_value

	var relationship = relationships[target_id]

	if typeof(relationship) == TYPE_INT:
		return float(relationship)

	if typeof(relationship) == TYPE_FLOAT:
		return float(relationship)

	if typeof(relationship) != TYPE_DICTIONARY:
		return default_value

	return float(
		relationship.get(
			"overall",
			default_value
		)
	)


func change_relationship(
	target_id: String,
	change: float
) -> void:

	var current_value = get_relationship(
		target_id,
		0.0
	)

	set_relationship(
		target_id,
		current_value + change
	)


func set_relationship_dimension(
	target_id: String,
	dimension: String,
	value: float
) -> void:

	if dimension.is_empty():
		return

	var relationship = _get_or_create_relationship(
		target_id
	)

	relationship[dimension] = clamp(
		value,
		-100.0,
		100.0
	)

	_update_overall_relationship(
		relationship
	)

	relationships[target_id] = relationship


func get_relationship_dimension(
	target_id: String,
	dimension: String,
	default_value: float = 0.0
) -> float:

	if not relationships.has(target_id):
		return default_value

	var relationship = relationships[target_id]

	if typeof(relationship) != TYPE_DICTIONARY:
		return default_value

	return float(
		relationship.get(
			dimension,
			default_value
		)
	)


func change_relationship_dimension(
	target_id: String,
	dimension: String,
	change: float
) -> void:

	var current_value = get_relationship_dimension(
		target_id,
		dimension,
		0.0
	)

	set_relationship_dimension(
		target_id,
		dimension,
		current_value + change
	)


func get_relationship_data(
	target_id: String
) -> Dictionary:

	if not relationships.has(target_id):
		return {}

	var relationship = relationships[target_id]

	if typeof(relationship) == TYPE_DICTIONARY:
		return relationship

	if typeof(relationship) == TYPE_INT:
		return {
			"overall": float(relationship)
		}

	if typeof(relationship) == TYPE_FLOAT:
		return {
			"overall": float(relationship)
		}

	return {}


func get_all_relationships() -> Dictionary:
	return relationships


func _get_or_create_relationship(
	target_id: String
) -> Dictionary:

	if relationships.has(target_id):

		var existing = relationships[target_id]

		if typeof(existing) == TYPE_DICTIONARY:
			return existing

		if typeof(existing) == TYPE_INT:
			return {
				"overall": float(existing)
			}

		if typeof(existing) == TYPE_FLOAT:
			return {
				"overall": float(existing)
			}

	return {
		"overall": 0.0,
		"diplomatic": 0.0,
		"economic": 0.0,
		"military": 0.0,
		"trade": 0.0,
		"political": 0.0,
		"cultural": 0.0,
		"trust": 0.0,
		"hostility": 0.0
	}


func _update_overall_relationship(
	relationship: Dictionary
) -> void:

	var dimensions = [
		"diplomatic",
		"economic",
		"military",
		"trade",
		"political",
		"cultural",
		"trust",
		"hostility"
	]

	var total = 0.0
	var count = 0

	for dimension in dimensions:

		if not relationship.has(dimension):
			continue

		total += float(
			relationship[dimension]
	)

		count += 1

	if count <= 0:
		return

	var average = (
		total /
		float(count)
	)

	relationship["overall"] = clamp(
		average,
		-100.0,
		100.0
	)


# ============================================================
# MEMORY
# ============================================================

func add_memory(entry: Dictionary) -> void:

	if entry.is_empty():
		return

	memory.append(
		entry.duplicate(true)
	)


func get_memory() -> Array:
	return memory


func get_memory_count() -> int:
	return memory.size()


func get_recent_memory(
	count: int = 10
) -> Array:

	if memory.is_empty():
		return []

	var start_index = max(
		0,
		memory.size() - count
	)

	var recent: Array = []

	for index in range(
		start_index,
		memory.size()
	):

		recent.append(
			memory[index]
		)

	return recent


func get_memory_by_type(
	memory_type: String
) -> Array:

	var result: Array = []

	for entry in memory:

		if typeof(entry) != TYPE_DICTIONARY:
			continue

		if str(
			entry.get(
				"type",
				""
			)
		) == memory_type:

			result.append(entry)

	return result


func clear_memory() -> void:
	memory.clear()


# ============================================================
# SIMULATION METADATA
# ============================================================

func set_sim_metadata(
	key: String,
	value
) -> void:

	if key.is_empty():
		return

	simulation_metadata[key] = value


func get_sim_metadata(
	key: String,
	default_value = null
):

	if key.is_empty():
		return default_value

	return simulation_metadata.get(
		key,
		default_value
	)


func has_sim_metadata(
	key: String
) -> bool:

	if key.is_empty():
		return false

	return simulation_metadata.has(key)


func remove_sim_metadata(
	key: String
) -> void:

	if key.is_empty():
		return

	simulation_metadata.erase(key)


func clear_sim_metadata() -> void:
	simulation_metadata.clear()


func get_all_sim_metadata() -> Dictionary:
	return simulation_metadata
