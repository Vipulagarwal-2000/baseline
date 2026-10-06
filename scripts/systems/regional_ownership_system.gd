class_name RegionalOwnershipSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.2
# REGIONAL OWNERSHIP / CONTROL SYSTEM
# ============================================================
#
# Step 12.1 owns the immutable-ish geographic hierarchy.
# Step 12.2 adds explicit ownership and control state without
# rewriting Region.country_id or converting regions into entities.
#
# Initial 1950 state:
#   owner_country_id      = Region.country_id
#   controller_country_id = Region.country_id
#   ownership_status      = sovereign
#   occupation_status     = none
#   claim_ids             = []
#
# Monthly processing is intentionally inert. Ownership changes are
# explicit state transitions. Later conflict/military systems may call
# this API when those systems are implemented.
# ============================================================


func _init() -> void:
	super("regional_ownership_system")


func process_month(world: WorldState) -> void:
	# Ownership is event/action driven in this step. There is no
	# automatic monthly ownership transition.
	if world == null:
		return


# ============================================================
# INITIALIZATION
# ============================================================

func initialize_world(world: WorldState) -> bool:
	if world == null:
		return false

	if world.get_region_count() <= 0:
		return false

	# Like the Step 12.1 regional bootstrap, ownership initialization
	# is a one-time operation. Re-running it must not duplicate or reset
	# existing ownership state.
	if world.get_regional_ownership_count() > 0:
		return false

	for region_id in _sorted_region_ids(world):
		var region := world.get_region(region_id) as Region
		if region == null:
			return false

		var owner_country_id := region.country_id
		if not _is_core_country(world, owner_country_id):
			return false

		var ownership_state := RegionalOwnershipState.new(
			region.id,
			owner_country_id,
			owner_country_id,
			RegionalOwnershipState.OWNERSHIP_SOVEREIGN,
			RegionalOwnershipState.OCCUPATION_NONE
		)

		if not world.add_regional_ownership(ownership_state):
			return false

	return validate_world(world)


func initialize_region(
	world: WorldState,
	region_id: String
) -> bool:
	# Supports future manual Region creation without rebuilding the whole
	# ownership registry.
	if world == null or region_id.is_empty():
		return false

	if world.has_regional_ownership(region_id):
		return false

	var region := world.get_region(region_id) as Region
	if region == null:
		return false

	if not _is_core_country(world, region.country_id):
		return false

	var ownership_state := RegionalOwnershipState.new(
		region.id,
		region.country_id,
		region.country_id,
		RegionalOwnershipState.OWNERSHIP_SOVEREIGN,
		RegionalOwnershipState.OCCUPATION_NONE
	)

	return world.add_regional_ownership(ownership_state)


# ============================================================
# QUERIES
# ============================================================

func get_ownership_state(
	world: WorldState,
	region_id: String
) -> RegionalOwnershipState:
	if world == null:
		return null

	return world.get_regional_ownership(region_id) as RegionalOwnershipState


func get_owner_country_id(
	world: WorldState,
	region_id: String
) -> String:
	var state := get_ownership_state(world, region_id)
	if state == null:
		return ""

	return state.owner_country_id


func get_controller_country_id(
	world: WorldState,
	region_id: String
) -> String:
	var state := get_ownership_state(world, region_id)
	if state == null:
		return ""

	return state.controller_country_id


func get_claim_ids(
	world: WorldState,
	region_id: String
) -> Array[String]:
	var state := get_ownership_state(world, region_id)
	if state == null:
		return []

	return state.get_claim_ids()


# ============================================================
# EXPLICIT OWNERSHIP MUTATION API
# ============================================================

func set_owner(
	world: WorldState,
	region_id: String,
	owner_country_id: String,
	ownership_status: String = RegionalOwnershipState.OWNERSHIP_TRANSFERRED
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if not _is_core_country(world, owner_country_id):
		return false

	if not _is_valid_ownership_status(ownership_status):
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	state.owner_country_id = owner_country_id
	state.ownership_status = ownership_status
	return true


func set_controller(
	world: WorldState,
	region_id: String,
	controller_country_id: String
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if not _is_core_country(world, controller_country_id):
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	state.controller_country_id = controller_country_id
	return true


func set_ownership_status(
	world: WorldState,
	region_id: String,
	ownership_status: String
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if not _is_valid_ownership_status(ownership_status):
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	state.ownership_status = ownership_status
	return true


func set_occupation_status(
	world: WorldState,
	region_id: String,
	occupation_status: String
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if not _is_valid_occupation_status(occupation_status):
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	state.occupation_status = occupation_status
	return true


func add_claim(
	world: WorldState,
	region_id: String,
	claiming_country_id: String
) -> bool:
	if world == null or region_id.is_empty():
		return false

	if not _is_core_country(world, claiming_country_id):
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	# A sovereign owner does not need to claim its own region. This keeps
	# claim_ids semantically reserved for additional claimants.
	if state.owner_country_id == claiming_country_id:
		return false

	return state.add_claim(claiming_country_id)


func remove_claim(
	world: WorldState,
	region_id: String,
	claiming_country_id: String
) -> bool:
	if world == null or region_id.is_empty():
		return false

	var state := get_ownership_state(world, region_id)
	if state == null:
		return false

	return state.remove_claim(claiming_country_id)


# ============================================================
# VALIDATION
# ============================================================

func validate_world(world: WorldState) -> bool:
	if world == null:
		return false

	if world.get_regional_ownership_count() != world.get_region_count():
		return false

	for region_id in _sorted_region_ids(world):
		var region := world.get_region(region_id) as Region
		var state := world.get_regional_ownership(region_id) as RegionalOwnershipState

		if region == null or state == null:
			return false

		if state.region_id != region.id:
			return false

		if not _is_core_country(world, state.owner_country_id):
			return false

		if not _is_core_country(world, state.controller_country_id):
			return false

		if not _is_valid_ownership_status(state.ownership_status):
			return false

		if not _is_valid_occupation_status(state.occupation_status):
			return false

		var seen_claims: Dictionary = {}
		for claim_id in state.claim_ids:
			if seen_claims.has(claim_id):
				return false

			if not _is_core_country(world, claim_id):
				return false

			if claim_id == state.owner_country_id:
				return false

			seen_claims[claim_id] = true

	return true


func snapshot_world(world: WorldState) -> Dictionary:
	var snapshot: Dictionary = {}
	if world == null:
		return snapshot

	for region_id in _sorted_region_ids(world):
		var state := get_ownership_state(world, region_id)
		if state == null:
			continue

		snapshot[region_id] = state.to_snapshot_dict()

	return snapshot


# ============================================================
# PRIVATE HELPERS
# ============================================================

func _is_core_country(
	world: WorldState,
	country_id: String
) -> bool:
	if world == null or country_id.is_empty():
		return false

	var country = world.get_entity(country_id)
	return (
		country != null
		and str(country.entity_type) == "country"
	)


func _is_valid_ownership_status(value: String) -> bool:
	return value in [
		RegionalOwnershipState.OWNERSHIP_SOVEREIGN,
		RegionalOwnershipState.OWNERSHIP_DISPUTED,
		RegionalOwnershipState.OWNERSHIP_TRANSFERRED
	]


func _is_valid_occupation_status(value: String) -> bool:
	return value in [
		RegionalOwnershipState.OCCUPATION_NONE,
		RegionalOwnershipState.OCCUPATION_OCCUPIED
	]


func _sorted_region_ids(world: WorldState) -> Array[String]:
	var ids: Array[String] = []
	if world == null:
		return ids

	for key in world.regions.keys():
		ids.append(str(key))

	ids.sort()
	return ids
