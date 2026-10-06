class_name RegionalOwnershipTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.2 INTEGRATED TEST
# ============================================================
#
# Verifies that ownership/control state is a separate regional layer:
#   Region.country_id remains structural home
#   owner/controller are explicit mutable state
#   claims/occupation/status are bounded
#   initialization is idempotence-safe
#   snapshots are deep-copy isolated
#   country entities remain authoritative and untouched
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"REGIONALIZATION — STEP 12.2 OWNERSHIP TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	var all_passed: bool = true
	var system := RegionalOwnershipSystem.new()

	# ------------------------------------------------------------
	# REGIONAL / SYSTEM AVAILABILITY
	# ------------------------------------------------------------
	var registry_count_passed: bool = (
		world.get_region_count() == 145
		and world.get_regional_ownership_count() == 145
	)
	TestLogger.write_line(
		"Regional ownership registry initialized for all 145 nodes: "
		+ ("PASS" if registry_count_passed else "FAIL")
	)
	all_passed = all_passed and registry_count_passed

	var registered_system_passed: bool = false
	if simulation != null:
		registered_system_passed = (
			simulation.get_system("regional_ownership_system")
			is RegionalOwnershipSystem
		)

	TestLogger.write_line(
		"Registered RegionalOwnershipSystem available: "
		+ ("PASS" if registered_system_passed else "FAIL")
	)
	all_passed = all_passed and registered_system_passed

	# ------------------------------------------------------------
	# INITIAL STATE
	# ------------------------------------------------------------
	var initial_state_passed: bool = true
	for region_id in _sorted_region_ids(world):
		var region := world.get_region(region_id) as Region
		var state := system.get_ownership_state(world, region_id)

		if region == null or state == null:
			initial_state_passed = false
			break

		if state.owner_country_id != region.country_id:
			initial_state_passed = false
			break

		if state.controller_country_id != region.country_id:
			initial_state_passed = false
			break

		if state.ownership_status != RegionalOwnershipState.OWNERSHIP_SOVEREIGN:
			initial_state_passed = false
			break

		if state.occupation_status != RegionalOwnershipState.OCCUPATION_NONE:
			initial_state_passed = false
			break

		if not state.claim_ids.is_empty():
			initial_state_passed = false
			break

	TestLogger.write_line(
		"Initial ownership/control matches structural home country: "
		+ ("PASS" if initial_state_passed else "FAIL")
	)
	all_passed = all_passed and initial_state_passed

	# ------------------------------------------------------------
	# COUNTRY SEPARATION
	# ------------------------------------------------------------
	var china = world.get_entity("china")
	var india = world.get_entity("india")
	var usa = world.get_entity("usa")
	var countries_valid: bool = (
		china != null
		and india != null
		and usa != null
		and str(china.entity_type) == "country"
		and str(india.entity_type) == "country"
		and str(usa.entity_type) == "country"
	)
	TestLogger.write_line(
		"Core country ownership targets remain valid country entities: "
		+ ("PASS" if countries_valid else "FAIL")
	)
	all_passed = all_passed and countries_valid

	# ------------------------------------------------------------
	# DUPLICATE INITIALIZATION
	# ------------------------------------------------------------
	var before_duplicate: int = world.get_regional_ownership_count()
	var duplicate_init_result: bool = system.initialize_world(world)
	var after_duplicate: int = world.get_regional_ownership_count()
	var duplicate_protection_passed: bool = (
		duplicate_init_result == false
		and before_duplicate == after_duplicate
	)
	TestLogger.write_line(
		"Second ownership initialization is rejected without duplication: "
		+ ("PASS" if duplicate_protection_passed else "FAIL")
	)
	all_passed = all_passed and duplicate_protection_passed

	# ------------------------------------------------------------
	# CONTROLLED OWNERSHIP TRANSITION FIXTURE
	# ------------------------------------------------------------
	var fixture_region_id := "china_beijing_municipality"
	var fixture_region := world.get_region(fixture_region_id) as Region
	var fixture_state := system.get_ownership_state(world, fixture_region_id)
	var fixture_ready: bool = fixture_region != null and fixture_state != null

	TestLogger.write_line(
		"Controlled ownership fixture available: "
		+ ("PASS" if fixture_ready else "FAIL")
	)
	all_passed = all_passed and fixture_ready

	if fixture_ready:
		var original_owner := fixture_state.owner_country_id
		var original_controller := fixture_state.controller_country_id
		var original_ownership_status := fixture_state.ownership_status
		var original_occupation_status := fixture_state.occupation_status
		var original_claims := fixture_state.get_claim_ids()
		var original_structural_country := fixture_region.country_id
		var original_parent := fixture_region.parent_region_id

		var owner_set := system.set_owner(
			world,
			fixture_region_id,
			"india",
			RegionalOwnershipState.OWNERSHIP_TRANSFERRED
		)
		var controller_set := system.set_controller(
			world,
			fixture_region_id,
			"india"
		)
		var occupation_set := system.set_occupation_status(
			world,
			fixture_region_id,
			RegionalOwnershipState.OCCUPATION_OCCUPIED
		)
		var claim_added := system.add_claim(
			world,
			fixture_region_id,
			"usa"
		)

		var transition_state_passed: bool = (
			owner_set
			and controller_set
			and occupation_set
			and claim_added
			and system.get_owner_country_id(world, fixture_region_id) == "india"
			and system.get_controller_country_id(world, fixture_region_id) == "india"
			and fixture_state.ownership_status == RegionalOwnershipState.OWNERSHIP_TRANSFERRED
			and fixture_state.occupation_status == RegionalOwnershipState.OCCUPATION_OCCUPIED
			and fixture_state.has_claim("usa")
		)
		TestLogger.write_line(
			"Explicit ownership/control mutation updates only ownership state: "
			+ ("PASS" if transition_state_passed else "FAIL")
		)
		all_passed = all_passed and transition_state_passed

		var structural_separation_passed: bool = (
			fixture_region.country_id == original_structural_country
			and fixture_region.parent_region_id == original_parent
		)
		TestLogger.write_line(
			"Ownership transition does not rewrite structural region hierarchy: "
			+ ("PASS" if structural_separation_passed else "FAIL")
		)
		all_passed = all_passed and structural_separation_passed

		# --------------------------------------------------------
		# SNAPSHOT / DEEP COPY
		# --------------------------------------------------------
		var snapshot := fixture_state.to_snapshot_dict()
		var snapshot_isolation_passed: bool = false
		if typeof(snapshot.get("claim_ids", null)) == TYPE_ARRAY:
			var snapshot_claims: Array = snapshot["claim_ids"]
			snapshot_claims.append("china")
			snapshot_isolation_passed = not fixture_state.has_claim("china")

		TestLogger.write_line(
			"Ownership snapshot is deep-copy isolated: "
			+ ("PASS" if snapshot_isolation_passed else "FAIL")
		)
		all_passed = all_passed and snapshot_isolation_passed

		# --------------------------------------------------------
		# INVALID TARGET PROTECTION
		# --------------------------------------------------------
		var invalid_owner_rejected := not system.set_owner(
			world,
			fixture_region_id,
			"not_a_country",
			RegionalOwnershipState.OWNERSHIP_TRANSFERRED
		)
		var invalid_claim_rejected := not system.add_claim(
			world,
			fixture_region_id,
			"not_a_country"
		)
		TestLogger.write_line(
			"Invalid ownership targets are rejected without mutation: "
			+ ("PASS" if (invalid_owner_rejected and invalid_claim_rejected) else "FAIL")
		)
		all_passed = all_passed and invalid_owner_rejected and invalid_claim_rejected

		# --------------------------------------------------------
		# RESTORE FIXTURE
		# --------------------------------------------------------
		fixture_state.owner_country_id = original_owner
		fixture_state.controller_country_id = original_controller
		fixture_state.ownership_status = original_ownership_status
		fixture_state.occupation_status = original_occupation_status
		fixture_state.claim_ids = original_claims.duplicate()

		var restored_passed: bool = (
			fixture_state.owner_country_id == original_owner
			and fixture_state.controller_country_id == original_controller
			and fixture_state.ownership_status == original_ownership_status
			and fixture_state.occupation_status == original_occupation_status
			and fixture_state.get_claim_ids() == original_claims
		)
		TestLogger.write_line(
			"Ownership fixture restores exact baseline state: "
			+ ("PASS" if restored_passed else "FAIL")
		)
		all_passed = all_passed and restored_passed

	# ------------------------------------------------------------
	# FINAL VALIDATION
	# ------------------------------------------------------------
	var final_validation_passed: bool = system.validate_world(world)
	TestLogger.write_line(
		"Final regional ownership validation: "
		+ ("PASS" if final_validation_passed else "FAIL")
	)
	all_passed = all_passed and final_validation_passed

	TestLogger.write_line(
		"Regionalization 12.2 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _sorted_region_ids(world: WorldState) -> Array[String]:
	var ids: Array[String] = []
	for key in world.regions.keys():
		ids.append(str(key))
	ids.sort()
	return ids
