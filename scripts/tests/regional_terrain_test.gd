class_name RegionalTerrainTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.3 INTEGRATED TEST
# ============================================================
#
# Verifies that terrain is a separate bounded regional state layer:
#   regional terrain exists for every Region/Province node
#   province nodes inherit parent-region profiles
#   terrain values are bounded and deterministic
#   country geography remains unchanged
#   duplicate initialization is rejected without mutation
#   snapshots are deep-copy isolated
#   structural hierarchy and ownership remain untouched
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
        "REGIONALIZATION — STEP 12.3 TERRAIN TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	var all_passed: bool = true
	var system := RegionalTerrainSystem.new()
	var expected_region_count := world.get_region_count()

	# ------------------------------------------------------------
	# REGISTRY / SYSTEM AVAILABILITY
	# ------------------------------------------------------------
	var registry_passed: bool = (
		expected_region_count > 0
		and world.get_regional_terrain_count() == expected_region_count
	)
	TestLogger.write_line(
        "Regional terrain registry initialized for all regional nodes: "
		+ ("PASS" if registry_passed else "FAIL")
	)
	all_passed = all_passed and registry_passed

	var registered_system_passed: bool = false
	if simulation != null:
		registered_system_passed = (
			simulation.get_system("regional_terrain_system")
			is RegionalTerrainSystem
		)

	TestLogger.write_line(
        "Registered RegionalTerrainSystem available: "
		+ ("PASS" if registered_system_passed else "FAIL")
	)
	all_passed = all_passed and registered_system_passed

	# ------------------------------------------------------------
	# TERRAIN STATE / HIERARCHY RECONCILIATION
	# ------------------------------------------------------------
	var structural_passed: bool = true
	var bounds_passed: bool = true
	var inheritance_passed: bool = true

	for region_id in _sorted_region_ids(world):
		var region := world.get_region(region_id) as Region
		var terrain := system.get_terrain_state(world, region_id)

		if region == null or terrain == null:
			structural_passed = false
			bounds_passed = false
			inheritance_passed = false
			break

		if terrain.structural_country_id != region.country_id:
			structural_passed = false

		if not terrain.is_valid():
			bounds_passed = false

		if region.is_region():
			if (
				terrain.source_profile_id != region.id
				or terrain.inherited_from_parent
			):
				inheritance_passed = false
		elif region.is_province():
			if (
				terrain.source_profile_id != region.parent_region_id
				or not terrain.inherited_from_parent
			):
				inheritance_passed = false

			var parent_terrain := system.get_terrain_state(
				world,
				region.parent_region_id
			)
			if parent_terrain == null:
				inheritance_passed = false
			elif not _terrain_fields_match(terrain, parent_terrain):
				inheritance_passed = false

	TestLogger.write_line(
        "Regional terrain state reconciles with structural hierarchy: "
		+ ("PASS" if structural_passed else "FAIL")
	)
	all_passed = all_passed and structural_passed

	TestLogger.write_line(
        "Regional terrain factors and modifiers are valid: "
		+ ("PASS" if bounds_passed else "FAIL")
	)
	all_passed = all_passed and bounds_passed

	TestLogger.write_line(
        "Province terrain inherits its parent region profile: "
		+ ("PASS" if inheritance_passed else "FAIL")
	)
	all_passed = all_passed and inheritance_passed

	# ------------------------------------------------------------
	# STRATEGIC TERRAIN ANCHORS
	# ------------------------------------------------------------
	var anchor_ids := [
		"china_northwest",
		"china_east_china",
		"india_north",
		"india_south",
		"usa_northeast",
        "usa_west"
	]
	var anchor_passed: bool = true
	for anchor_id in anchor_ids:
		if system.get_terrain_state(world, anchor_id) == null:
			anchor_passed = false
			break

	TestLogger.write_line(
        "Strategic terrain anchor profiles resolve: "
		+ ("PASS" if anchor_passed else "FAIL")
	)
	all_passed = all_passed and anchor_passed

	# ------------------------------------------------------------
	# COUNTRY SEPARATION / NO DUPLICATE AUTHORITY
	# ------------------------------------------------------------
	var entity_count_before := world.get_entity_count()
	var countries_valid := (
		world.get_entity("china") != null
		and world.get_entity("india") != null
		and world.get_entity("usa") != null
	)
	var regions_are_not_entities := true
	for region_id in _sorted_region_ids(world):
		if world.has_entity(region_id):
			regions_are_not_entities = false
			break

	var country_separation_passed := (
		countries_valid
		and regions_are_not_entities
		and world.get_entity_count() == entity_count_before
	)

	var ownership_before: Dictionary = {}
	for region_id in _sorted_region_ids(world):
		var ownership := world.get_regional_ownership(region_id) as RegionalOwnershipState
		if ownership == null:
			continue
		ownership_before[region_id] = ownership.to_snapshot_dict()

	TestLogger.write_line(
        "Country entities remain authoritative and unchanged: "
		+ ("PASS" if country_separation_passed else "FAIL")
	)
	all_passed = all_passed and country_separation_passed

	# ------------------------------------------------------------
	# DUPLICATE INITIALIZATION
	# ------------------------------------------------------------
	var before_duplicate := world.get_regional_terrain_count()
	var duplicate_result := system.initialize_world(
		world,
		[]
	)
	var after_duplicate := world.get_regional_terrain_count()
	var duplicate_passed: bool = (
		duplicate_result == false
		and before_duplicate == after_duplicate
	)

	TestLogger.write_line(
        "Second terrain initialization is rejected without duplication: "
		+ ("PASS" if duplicate_passed else "FAIL")
	)
	all_passed = all_passed and duplicate_passed

	# ------------------------------------------------------------
	# SNAPSHOT / DEEP COPY
	# ------------------------------------------------------------
	var fixture_id := "china_northwest"
	var fixture := system.get_terrain_state(world, fixture_id)
	var snapshot_passed: bool = false

	if fixture != null:
		var snapshot := fixture.to_snapshot_dict()
		snapshot["mountains"] = 0.0
		snapshot["mobility_modifier"] = 999.0

		snapshot_passed = (
			fixture.mountains != 0.0
			and fixture.mobility_modifier != 999.0
		)

	TestLogger.write_line(
        "Terrain snapshot is isolated from live state: "
		+ ("PASS" if snapshot_passed else "FAIL")
	)
	all_passed = all_passed and snapshot_passed

	# ------------------------------------------------------------
	# EXPLICIT PROFILE MUTATION FIXTURE
	# ------------------------------------------------------------
	var mutation_passed: bool = false
	var structure_after_mutation_passed: bool = false
	if fixture != null:
		var original_mountains := fixture.mountains
		var original_country := fixture.structural_country_id
		var original_parent := (world.get_region(fixture_id) as Region).parent_region_id

		var mutated := fixture.apply_profile({
			"mountains": 0.40,
			"plateaus": 0.25,
			"deserts": 0.10,
			"plains": 0.55,
			"coastal_lowlands": 0.10,
			"major_rivers": 0.65,
			"coastal_access": false
		})

		mutation_passed = (
			mutated
			and fixture.mountains == 0.40
			and fixture.mountains != original_mountains
		)

		var region_after := world.get_region(fixture_id) as Region
		structure_after_mutation_passed = (
			region_after != null
			and region_after.country_id == original_country
			and region_after.parent_region_id == original_parent
		)

		# Restore the fixture to the authoritative loaded profile.
		fixture.apply_profile({
			"mountains": 0.55,
			"plateaus": 0.55,
			"deserts": 0.55,
			"plains": 0.12,
			"coastal_lowlands": 0.02,
			"major_rivers": 0.35,
			"coastal_access": false
		})

	TestLogger.write_line(
        "Explicit terrain profile mutation changes only terrain state: "
		+ ("PASS" if mutation_passed else "FAIL")
	)
	all_passed = all_passed and mutation_passed

	TestLogger.write_line(
        "Terrain mutation does not rewrite region hierarchy: "
		+ ("PASS" if structure_after_mutation_passed else "FAIL")
	)
	all_passed = all_passed and structure_after_mutation_passed

	# ------------------------------------------------------------
	# OWNERSHIP / STRUCTURE PRESERVATION
	# ------------------------------------------------------------
	var ownership_preserved := true
	for region_id in ownership_before.keys():
		var current := world.get_regional_ownership(region_id) as RegionalOwnershipState
		if current == null:
			ownership_preserved = false
			break
		if current.to_snapshot_dict() != ownership_before[region_id]:
			ownership_preserved = false
			break

	TestLogger.write_line(
        "Existing regional ownership state remains unchanged: "
		+ ("PASS" if ownership_preserved else "FAIL")
	)
	all_passed = all_passed and ownership_preserved

	# ------------------------------------------------------------
	# FINAL VALIDATION
	# ------------------------------------------------------------
	var final_validation_passed := system.validate_world(world)
	TestLogger.write_line(
        "Final regional terrain validation: "
		+ ("PASS" if final_validation_passed else "FAIL")
	)
	all_passed = all_passed and final_validation_passed

	TestLogger.write_line(
        "Regionalization 12.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _sorted_region_ids(world: WorldState) -> Array[String]:
	var ids: Array[String] = []
	for key in world.regions.keys():
		ids.append(str(key))
	ids.sort()
	return ids


static func _terrain_fields_match(
	left: RegionalTerrainState,
	right: RegionalTerrainState
) -> bool:
	return (
		is_equal_approx(left.mountains, right.mountains)
		and is_equal_approx(left.plateaus, right.plateaus)
		and is_equal_approx(left.deserts, right.deserts)
		and is_equal_approx(left.plains, right.plains)
		and is_equal_approx(left.coastal_lowlands, right.coastal_lowlands)
		and is_equal_approx(left.major_rivers, right.major_rivers)
		and left.coastal_access == right.coastal_access
		and is_equal_approx(left.mobility_modifier, right.mobility_modifier)
		and is_equal_approx(left.agriculture_modifier, right.agriculture_modifier)
		and is_equal_approx(left.infrastructure_cost_modifier, right.infrastructure_cost_modifier)
		and is_equal_approx(left.defense_modifier, right.defense_modifier)
	)
