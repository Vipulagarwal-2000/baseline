class_name RegionalizationTest
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.1 INTEGRATED DATA TEST
# ============================================================
#
# This test verifies the merged path:
#   country JSON -> WorldLoader -> Country
#   region JSON  -> RegionalDataLoader -> Region/Province
#   both coexist without duplicating country authority.
#
# Step 12.1 is structural only. It must NOT localize or mutate
# population, resources, infrastructure, industry, economy, or
# other country-level simulation state.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"REGIONALIZATION — STEP 12.1 INTEGRATED TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	var countries: Array[String] = ["china", "india", "usa"]
	var expected_regions: Dictionary = {
		"china": 6,
		"india": 6,
		"usa": 4
	}
	var expected_provinces: Dictionary = {
		"china": 50,
		"india": 28,
		"usa": 51
	}

	var all_passed: bool = true
	var system := RegionalizationSystem.new()
	var loader := RegionalDataLoader.new()

	# ------------------------------------------------------------
	# COUNTRY AVAILABILITY
	# ------------------------------------------------------------
	for country_id in countries:
		var country = world.get_entity(country_id)
		var passed: bool = (
			country != null
			and str(country.entity_type) == "country"
		)

		TestLogger.write_line(
			country_id.capitalize() + " country available: "
			+ ("PASS" if passed else "FAIL")
		)

		all_passed = all_passed and passed

	# ------------------------------------------------------------
	# DATA-DEFINITION LOADING
	# ------------------------------------------------------------
	var definitions: Array = loader.load_all_regions(
		"res://data/regions"
	)

	var data_count_passed: bool = definitions.size() == 3
	TestLogger.write_line(
		"Three regional definition files loaded: "
		+ ("PASS" if data_count_passed else "FAIL")
	)
	all_passed = all_passed and data_count_passed

	# ------------------------------------------------------------
	# HISTORICAL PROFILE VALIDATION
	# ------------------------------------------------------------
	var historical_profile_passed: bool = _validate_historical_profiles(
		definitions
	)

	TestLogger.write_line(
		"1950-1955 historical regional profiles present: "
		+ ("PASS" if historical_profile_passed else "FAIL")
	)
	all_passed = all_passed and historical_profile_passed

	# ------------------------------------------------------------
	# EXPECTED COUNTRY STRUCTURE
	# ------------------------------------------------------------
	for country_id in countries:
		var region_count: int = world.get_country_region_count(country_id)
		var province_count: int = world.get_country_province_count(country_id)

		var count_passed: bool = (
			region_count == int(expected_regions[country_id])
			and province_count == int(expected_provinces[country_id])
		)

		TestLogger.write_line(
			country_id.capitalize()
			+ " region/province counts ("
			+ str(region_count)
			+ "/"
			+ str(province_count)
			+ "): "
			+ ("PASS" if count_passed else "FAIL")
		)

		all_passed = all_passed and count_passed

	# ------------------------------------------------------------
	# COUNTRY ANCHOR VALIDATION
	# ------------------------------------------------------------
	var anchor_passed: bool = true

	for value in world.regions.values():
		var region := value as Region
		if region == null or not region.is_region():
			continue

		if not system.validate_country_anchor(world, region):
			anchor_passed = false
			break

	TestLogger.write_line(
		"Region strategic-geography anchors resolve: "
		+ ("PASS" if anchor_passed else "FAIL")
	)
	all_passed = all_passed and anchor_passed

	# ------------------------------------------------------------
	# HIERARCHY VALIDATION
	# ------------------------------------------------------------
	var hierarchy_passed: bool = system.validate_hierarchy(world)

	TestLogger.write_line(
		"Country -> region -> province hierarchy: "
		+ ("PASS" if hierarchy_passed else "FAIL")
	)
	all_passed = all_passed and hierarchy_passed

	# ------------------------------------------------------------
	# COUNTRY IS STILL THE AUTHORITATIVE ENTITY
	# ------------------------------------------------------------
	var authority_passed: bool = true

	for country_id in countries:
		var country = world.get_entity(country_id)

		if country == null:
			authority_passed = false
			break

		if str(country.entity_type) != "country":
			authority_passed = false
			break

		if world.get_region(country_id) != null:
			authority_passed = false
			break

	TestLogger.write_line(
		"Countries remain separate from regional registry: "
		+ ("PASS" if authority_passed else "FAIL")
	)
	all_passed = all_passed and authority_passed

	# ------------------------------------------------------------
	# COUNTRY STATE IMMUTABILITY DURING 12.1 STRUCTURE CHECK
	# ------------------------------------------------------------
	var state_before: Dictionary = {}

	for country_id in countries:
		var country = world.get_entity(country_id)
		state_before[country_id] = {
			"population": _component_state_snapshot(country, "population"),
			"economy": _component_state_snapshot(country, "economy"),
			"resources": _component_state_snapshot(country, "resources"),
			"geography": _component_state_snapshot(country, "geography"),
			"infrastructure": _component_state_snapshot(country, "infrastructure"),
			"industry": _component_state_snapshot(country, "industry")
		}

	# 12.1 does not run a monthly state update.
	system.process_month(world)

	var state_after_passed: bool = true

	for country_id in countries:
		var country = world.get_entity(country_id)
		var after: Dictionary = {
			"population": _component_state_snapshot(country, "population"),
			"economy": _component_state_snapshot(country, "economy"),
			"resources": _component_state_snapshot(country, "resources"),
			"geography": _component_state_snapshot(country, "geography"),
			"infrastructure": _component_state_snapshot(country, "infrastructure"),
			"industry": _component_state_snapshot(country, "industry")
		}

		if after != state_before[country_id]:
			state_after_passed = false
			break

	TestLogger.write_line(
		"Step 12.1 leaves country-level simulation state unchanged: "
		+ ("PASS" if state_after_passed else "FAIL")
	)
	all_passed = all_passed and state_after_passed

	# ------------------------------------------------------------
	# IDEMPOTENCE / DUPLICATE PROTECTION
	# ------------------------------------------------------------
	# Regional initialization is a bootstrap operation. Once regional
	# state exists in the world, the same initialization request must be
	# rejected and must not create a second copy of the hierarchy.
	var regions_before_duplicate_load: int = world.get_region_count()

	var duplicate_load_result: bool = system.initialize_world(
		world,
		definitions
	)

	var regions_after_duplicate_load: int = world.get_region_count()

	var duplicate_load_passed: bool = (
		duplicate_load_result == false
	)

	# The registry contains both first-level regions and second-level
	# province/administrative child nodes. Do not hardcode a node count here;
	# the authoritative check is that the count remains exactly unchanged.
	var counts_stable: bool = (
		regions_before_duplicate_load > 0
		and regions_after_duplicate_load == regions_before_duplicate_load
	)

	var idempotence_passed: bool = (
		duplicate_load_passed
		and counts_stable
	)

	TestLogger.write_line(
		"Second regional data load result: "
		+ str(duplicate_load_result)
		+ " | before="
		+ str(regions_before_duplicate_load)
		+ " | after="
		+ str(regions_after_duplicate_load)
	)

	TestLogger.write_line(
		"Second regional data load is rejected without duplication: "
		+ ("PASS" if idempotence_passed else "FAIL")
	)
	all_passed = all_passed and idempotence_passed

	# ------------------------------------------------------------
	# LEGACY MANUAL API PRESERVED
	# ------------------------------------------------------------
	var temp_region_id: String = "test_region_12_1_manual"
	var temp_province_id: String = "test_province_12_1_manual"

	var temp_region = system.create_region(
		world,
		"china",
		temp_region_id,
		"Test Manual Region"
	)

	var temp_province = system.create_province(
		world,
		temp_region_id,
		temp_province_id,
		"Test Manual Province"
	)

	var manual_api_passed: bool = (
		temp_region != null
		and temp_province != null
		and temp_province.parent_region_id == temp_region.id
		and temp_region.has_child(temp_province.id)
	)

	TestLogger.write_line(
		"Legacy manual Region API remains compatible: "
		+ ("PASS" if manual_api_passed else "FAIL")
	)
	all_passed = all_passed and manual_api_passed

	var manual_duplicate_region = system.create_region(
		world,
		"china",
		temp_region_id,
		"Duplicate"
	)

	var manual_duplicate_province = system.create_province(
		world,
		temp_region_id,
		temp_province_id,
		"Duplicate"
	)

	var manual_duplicate_passed: bool = (
		manual_duplicate_region == null
		and manual_duplicate_province == null
	)

	TestLogger.write_line(
		"Manual duplicate IDs rejected: "
		+ ("PASS" if manual_duplicate_passed else "FAIL")
	)
	all_passed = all_passed and manual_duplicate_passed

	# ------------------------------------------------------------
	# SNAPSHOT
	# ------------------------------------------------------------
	var snapshot_passed: bool = false

	if temp_region != null:
		var snapshot: Dictionary = temp_region.to_snapshot_dict()
		snapshot_passed = (
			snapshot.get("id", "") == temp_region_id
			and snapshot.get("level", "") == Region.LEVEL_REGION
			and snapshot.get("country_id", "") == "china"
			and snapshot.get("child_ids", []).size() == 1
		)

	TestLogger.write_line(
		"Region snapshot preserves structural state: "
		+ ("PASS" if snapshot_passed else "FAIL")
	)
	all_passed = all_passed and snapshot_passed

	# ------------------------------------------------------------
	# CLEANUP
	# ------------------------------------------------------------
	var cleanup_province_passed: bool = system.remove_node(
		world,
		temp_province_id
	)

	var cleanup_region_passed: bool = system.remove_node(
		world,
		temp_region_id
	)

	var cleanup_passed: bool = (
		cleanup_province_passed
		and cleanup_region_passed
	)

	TestLogger.write_line(
		"Temporary manual regional fixture removed: "
		+ ("PASS" if cleanup_passed else "FAIL")
	)
	all_passed = all_passed and cleanup_passed

	# ------------------------------------------------------------
	# FINAL
	# ------------------------------------------------------------
	var final_hierarchy: bool = system.validate_hierarchy(world)

	TestLogger.write_line(
		"Final regional hierarchy remains valid: "
		+ ("PASS" if final_hierarchy else "FAIL")
	)
	all_passed = all_passed and final_hierarchy

	TestLogger.write_line(
		"Regionalization 12.1 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _validate_historical_profiles(
	definitions: Array
) -> bool:
	var by_country: Dictionary = {}

	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			return false

		var definition: Dictionary = definition_value
		by_country[str(definition.get("country_id", ""))] = definition

	if not by_country.has("china"):
		return false

	if not by_country.has("india"):
		return false

	if not by_country.has("usa"):
		return false

	var china_definition: Dictionary = by_country["china"]
	var india_definition: Dictionary = by_country["india"]
	var usa_definition: Dictionary = by_country["usa"]

	var china_historical_period: Dictionary = china_definition.get(
		"historical_period",
		{}
	)
	var india_historical_period: Dictionary = india_definition.get(
		"historical_period",
		{}
	)
	var usa_historical_period: Dictionary = usa_definition.get(
		"historical_period",
		{}
	)

	var china_profile_passed: bool = (
		str(china_historical_period.get("baseline", "")) == "1950-01-01"
		and china_definition.get("historical_transition_events", []).size() >= 4
	)

	var india_profile_passed: bool = (
		str(india_historical_period.get("baseline", "")) == "1950-01-26"
		and india_definition.get("historical_transition_events", []).size() == 3
	)

	var usa_profile_passed: bool = (
		str(usa_historical_period.get("baseline", "")) == "1950-04-01"
		and str(usa_definition.get("historical_profile", "")).find("1950") >= 0
	)

	return (
		china_profile_passed
		and india_profile_passed
		and usa_profile_passed
	)


static func _component_state_snapshot(
	country,
	component_type: String
) -> Dictionary:
	if country == null:
		return {}

	var component = country.get_component(component_type)
	if component == null:
		return {}

	return component.state.duplicate(true)
