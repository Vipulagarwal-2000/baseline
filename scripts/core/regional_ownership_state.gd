class_name RegionalOwnershipState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.2
# EXPLICIT REGIONAL OWNERSHIP / CONTROL STATE
# ============================================================
#
# Structural Region.country_id remains the geographic home used by
# Step 12.1. This object deliberately separates ownership/control
# state so later territorial transfers do not require rewriting the
# Country -> Region -> Province hierarchy.
#
# Required authoritative state:
#   owner_country_id
#   controller_country_id
#   ownership_status
#   occupation_status
#   claim_ids
# ============================================================

const OWNERSHIP_SOVEREIGN: String = "sovereign"
const OWNERSHIP_DISPUTED: String = "disputed"
const OWNERSHIP_TRANSFERRED: String = "transferred"

const OCCUPATION_NONE: String = "none"
const OCCUPATION_OCCUPIED: String = "occupied"


var region_id: String = ""
var owner_country_id: String = ""
var controller_country_id: String = ""
var ownership_status: String = OWNERSHIP_SOVEREIGN
var occupation_status: String = OCCUPATION_NONE
var claim_ids: Array[String] = []


func _init(
	ownership_region_id: String,
	initial_owner_country_id: String,
	initial_controller_country_id: String = "",
	initial_ownership_status: String = OWNERSHIP_SOVEREIGN,
	initial_occupation_status: String = OCCUPATION_NONE
) -> void:
	region_id = ownership_region_id
	owner_country_id = initial_owner_country_id
	controller_country_id = (
		initial_controller_country_id
		if not initial_controller_country_id.is_empty()
		else initial_owner_country_id
	)
	ownership_status = initial_ownership_status
	occupation_status = initial_occupation_status


func add_claim(claiming_country_id: String) -> bool:
	if claiming_country_id.is_empty():
		return false

	if claim_ids.has(claiming_country_id):
		return false

	claim_ids.append(claiming_country_id)
	return true


func remove_claim(claiming_country_id: String) -> bool:
	if not claim_ids.has(claiming_country_id):
		return false

	claim_ids.erase(claiming_country_id)
	return true


func has_claim(claiming_country_id: String) -> bool:
	return claim_ids.has(claiming_country_id)


func clear_claims() -> void:
	claim_ids.clear()


func get_claim_ids() -> Array[String]:
	return claim_ids.duplicate()


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"owner_country_id": owner_country_id,
		"controller_country_id": controller_country_id,
		"ownership_status": ownership_status,
		"occupation_status": occupation_status,
		"claim_ids": claim_ids.duplicate()
	}
