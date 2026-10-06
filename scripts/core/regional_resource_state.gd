class_name RegionalResourceState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.5
# REGIONAL RESOURCE STATE
# ============================================================
#
# Parent regions are the resource-localization authority for this
# step. The country ResourceComponent remains authoritative for the
# country-level resource state from which these regional seeds are
# created.
#
# Province/state children remain structural only in Step 12.5.
# No monthly regional resource-flow simulation occurs here.
# ============================================================


var region_id: String = ""
var structural_country_id: String = ""

# Immutable-at-initialization reference copy of the authoritative
# country resource seed used to build this regional state.
var source_country_resource_state: Dictionary = {}

var production_by_resource: Dictionary = {}
var reserves_by_resource: Dictionary = {}
var stockpile_by_resource: Dictionary = {}
var resource_accessibility: Dictionary = {}
var local_import_dependency: Dictionary = {}

var production_authority: String = "regional_seed"
var reserves_authority: String = "regional_seed"
var stockpile_authority: String = "regional_seed"
var accessibility_authority: String = "regional_calibration"
var import_dependency_authority: String = "regional_calibration"

var province_resource_authority: bool = false


func _init(
	target_region_id: String = "",
	target_country_id: String = ""
) -> void:
	region_id = target_region_id
	structural_country_id = target_country_id


func apply_localization(
	country_resource_state: Dictionary,
	production_share: Dictionary,
	reserve_share: Dictionary,
	stockpile_share: float,
	accessibility: Dictionary,
	import_dependency: Dictionary
) -> bool:
	if country_resource_state.is_empty():
		return false

	if stockpile_share < 0.0 or stockpile_share > 1.0:
		return false

	for key in ["production", "reserves", "stockpile"]:
		if typeof(country_resource_state.get(key, null)) != TYPE_DICTIONARY:
			return false

	source_country_resource_state = country_resource_state.duplicate(true)
	production_by_resource = {}
	reserves_by_resource = {}
	stockpile_by_resource = {}
	resource_accessibility = {}
	local_import_dependency = {}

	var country_production: Dictionary = country_resource_state["production"]
	var country_reserves: Dictionary = country_resource_state["reserves"]
	var country_stockpile: Dictionary = country_resource_state["stockpile"]

	for resource_name in country_production.keys():
		if not production_share.has(resource_name):
			return false

		var production_share_value: float = float(
			production_share[resource_name]
		)
		if production_share_value < 0.0 or production_share_value > 1.0:
			return false

		production_by_resource[resource_name] = maxf(
			float(country_production[resource_name]),
			0.0
		) * production_share_value

		var accessibility_value: float = float(
			accessibility.get(resource_name, 1.0)
		)
		if accessibility_value < 0.0 or accessibility_value > 1.0:
			return false
		resource_accessibility[resource_name] = accessibility_value

		var dependency_value: float = float(
			import_dependency.get(resource_name, 0.0)
		)
		if dependency_value < 0.0 or dependency_value > 1.0:
			return false
		local_import_dependency[resource_name] = dependency_value

	for resource_name in country_reserves.keys():
		var reserve_total: float = maxf(
			float(country_reserves[resource_name]),
			0.0
		)
		if reserve_total <= 0.0:
			continue

		if not reserve_share.has(resource_name):
			return false

		var reserve_share_value: float = float(
			reserve_share[resource_name]
		)
		if reserve_share_value < 0.0 or reserve_share_value > 1.0:
			return false

		reserves_by_resource[resource_name] = (
			reserve_total * reserve_share_value
		)

	for resource_name in country_stockpile.keys():
		var stockpile_total: float = maxf(
			float(country_stockpile[resource_name]),
			0.0
		)
		stockpile_by_resource[resource_name] = (
			stockpile_total * stockpile_share
		)

	production_authority = "regional_seed"
	reserves_authority = "regional_seed"
	stockpile_authority = "regional_seed"
	accessibility_authority = "regional_calibration"
	import_dependency_authority = "regional_calibration"
	province_resource_authority = false

	return is_valid()


func is_valid() -> bool:
	if region_id.is_empty() or structural_country_id.is_empty():
		return false

	if province_resource_authority:
		return false

	if production_authority != "regional_seed":
		return false
	if reserves_authority != "regional_seed":
		return false
	if stockpile_authority != "regional_seed":
		return false
	if accessibility_authority != "regional_calibration":
		return false
	if import_dependency_authority != "regional_calibration":
		return false

	for dictionary in [
		production_by_resource,
		reserves_by_resource,
		stockpile_by_resource,
		resource_accessibility,
		local_import_dependency
	]:
		for key in dictionary.keys():
			if str(key).strip_edges().is_empty():
				return false
			if float(dictionary[key]) < 0.0:
				return false

	for value in resource_accessibility.values():
		if float(value) < 0.0 or float(value) > 1.0:
			return false

	for value in local_import_dependency.values():
		if float(value) < 0.0 or float(value) > 1.0:
			return false

	return true


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_country_resource_state": source_country_resource_state.duplicate(true),
		"production_by_resource": production_by_resource.duplicate(true),
		"reserves_by_resource": reserves_by_resource.duplicate(true),
		"stockpile_by_resource": stockpile_by_resource.duplicate(true),
		"resource_accessibility": resource_accessibility.duplicate(true),
		"local_import_dependency": local_import_dependency.duplicate(true),
		"production_authority": production_authority,
		"reserves_authority": reserves_authority,
		"stockpile_authority": stockpile_authority,
		"accessibility_authority": accessibility_authority,
		"import_dependency_authority": import_dependency_authority,
		"province_resource_authority": province_resource_authority
	}
