class_name EventDefinition
extends RefCounted


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""
var name: String = ""
var description: String = ""


# ============================================================
# CLASSIFICATION
# ============================================================

var category: String = "general"
var scope: String = "country"


# ============================================================
# METADATA
# ============================================================

var metadata: Dictionary = {}


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	event_id: String = "",
	event_name: String = "",
	event_description: String = "",
	event_category: String = "general",
	event_scope: String = "country"
):
	id = event_id
	name = event_name
	description = event_description
	category = event_category
	scope = event_scope


# ============================================================
# METADATA
# ============================================================

func set_metadata_value(
	key: String,
	value
) -> void:

	if key.is_empty():
		return

	metadata[key] = value


func get_metadata_value(
	key: String,
	default_value = null
):

	if key.is_empty():
		return default_value

	return metadata.get(
		key,
		default_value
	)


func has_metadata_value(
	key: String
) -> bool:

	if key.is_empty():
		return false

	return metadata.has(key)


func remove_metadata_value(
	key: String
) -> void:

	if key.is_empty():
		return

	metadata.erase(key)
