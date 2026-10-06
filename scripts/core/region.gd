class_name Region
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.1
# DATA-DRIVEN REGION / PROVINCE MODEL
# ============================================================
#
# Structural hierarchy only:
#   Country
#      -> Region
#           -> Province
#
# This class deliberately does NOT own localized population,
# resources, infrastructure, industry, terrain simulation,
# transport throughput, or regional economics. Those belong to
# later Step 12 substeps.
#
# The optional source_geography_key links an MVP simulation
# region back to an existing country-level strategic geography
# key without making the country geography component regional.
# ============================================================

const LEVEL_REGION: String = "region"
const LEVEL_PROVINCE: String = "province"


var id: String = ""
var name: String = ""
var level: String = LEVEL_REGION
var country_id: String = ""
var parent_region_id: String = ""

# Existing country geography anchor used only as a structural
# source reference during the regionalization MVP.
var source_geography_key: String = ""

# Child region/province IDs are structural links only.
var child_ids: Array[String] = []

# Non-authoritative descriptive metadata. Later regional systems
# should add authoritative state through their own bounded layers.
var metadata: Dictionary = {}


func _init(
	region_id: String,
	region_name: String,
	region_level: String,
	owner_country_id: String,
	parent_id: String = ""
) -> void:
	id = region_id
	name = region_name
	level = region_level
	country_id = owner_country_id
	parent_region_id = parent_id


func is_region() -> bool:
	return level == LEVEL_REGION


func is_province() -> bool:
	return level == LEVEL_PROVINCE


func is_valid() -> bool:
	if id.is_empty() or name.is_empty() or country_id.is_empty():
		return false

	if is_region():
		return parent_region_id.is_empty()

	if is_province():
		return not parent_region_id.is_empty()

	return false


func add_child_id(child_id: String) -> bool:
	if child_id.is_empty():
		return false

	if child_ids.has(child_id):
		return false

	child_ids.append(child_id)
	return true


func remove_child_id(child_id: String) -> bool:
	if not child_ids.has(child_id):
		return false

	child_ids.erase(child_id)
	return true


func has_child(child_id: String) -> bool:
	return child_ids.has(child_id)


func get_child_ids() -> Array[String]:
	return child_ids.duplicate()


func set_source_geography_key(key: String) -> void:
	source_geography_key = key


func set_metadata(key: String, value) -> void:
	if key.is_empty():
		return

	metadata[key] = value


func get_metadata(key: String, default_value = null):
	return metadata.get(key, default_value)


func to_snapshot_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"level": level,
		"country_id": country_id,
		"parent_region_id": parent_region_id,
		"source_geography_key": source_geography_key,
		"child_ids": child_ids.duplicate(),
		"metadata": metadata.duplicate(true)
	}
