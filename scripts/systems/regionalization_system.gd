class_name RegionalizationSystem
extends SimulationSystem


# ============================================================
# REGIONALIZATION — STEP 12.1
# DATA-DRIVEN REGION / PROVINCE STRUCTURE SERVICE
# ============================================================
#
# Merges the earlier manual Region API with a new data-driven
# initialization path for the three-country MVP.
#
# Responsibilities in 12.1:
#   - build Country -> Region -> Province structure
#   - keep region state in WorldState.regions
#   - preserve a link to country geography strategic locations
#   - validate hierarchy and cross-country ownership
#   - protect country entities from regional duplication
#
# Explicitly deferred:
#   12.2 ownership state transitions
#   12.3 terrain localization
#   12.4 population localization
#   12.5 resource localization
#   12.6 infrastructure localization
#   12.7 industry localization
#   12.8 regional transport
#   12.9 country aggregation
# ============================================================


func _init() -> void:
	super("regionalization_system")


func process_month(world: WorldState) -> void:
	# Step 12.1 is structural. No monthly regional simulation occurs yet.
	if world == null:
		return


# ============================================================
# DATA-DRIVEN INITIALIZATION
# ============================================================

func initialize_world(
	world: WorldState,
	definitions: Array
) -> bool:
	if world == null:
		return false

	if definitions.is_empty():
		return false

	# Step 12.1 regional definitions are a one-time world bootstrap.
	# Once any region exists, a second bootstrap must be rejected before
	# validation/creation so that a new RegionalizationSystem instance
	# cannot silently rebuild the same structural dataset.
	if world.get_region_count() > 0:
		return false

	if not _validate_definition_set(world, definitions):
		return false

	for definition_value in definitions:
		var definition: Dictionary = definition_value
		var country_id = str(definition.get("country_id", ""))
		var regions: Array = definition.get("regions", [])

		for region_value in regions:
			var region_data: Dictionary = region_value

			var region := Region.new(
				str(region_data.get("id", "")),
				str(region_data.get("name", "")),
				Region.LEVEL_REGION,
				country_id
			)

			region.set_source_geography_key(
				str(region_data.get("strategic_location_key", ""))
			)
			_copy_metadata(
				region,
				region_data.get("metadata", {})
			)

			if not world.add_region(region):
				return false

			for province_value in region_data.get("provinces", []):
				var province_data: Dictionary = province_value

				var province := Region.new(
					str(province_data.get("id", "")),
					str(province_data.get("name", "")),
					Region.LEVEL_PROVINCE,
					country_id,
					region.id
				)

				_copy_metadata(
					province,
					province_data.get("metadata", {})
				)

				if not world.add_region(province):
					return false

				if not region.add_child_id(province.id):
					return false

	return validate_hierarchy(world)


func _validate_definition_set(
	world: WorldState,
	definitions: Array
) -> bool:
	var country_ids: Dictionary = {}
	var global_ids: Dictionary = {}

	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			return false

		var definition: Dictionary = definition_value
		var country_id = str(definition.get("country_id", ""))
		if country_id.is_empty():
			return false

		if country_ids.has(country_id):
			return false
		country_ids[country_id] = true

		var country = world.get_entity(country_id)
		if country == null or str(country.entity_type) != "country":
			return false

		var geography = country.get_component("geography")
		if geography == null:
			return false

		var strategic_locations = geography.state.get(
			"strategic_locations",
			{}
		)

		if typeof(strategic_locations) != TYPE_DICTIONARY:
			return false

		var regions: Array = definition.get("regions", [])
		if regions.is_empty():
			return false

		for region_value in regions:
			if typeof(region_value) != TYPE_DICTIONARY:
				return false

			var region_data: Dictionary = region_value
			var region_id = str(region_data.get("id", ""))
			var region_name = str(region_data.get("name", ""))
			var strategic_key = str(
				region_data.get("strategic_location_key", "")
			)

			if region_id.is_empty() or region_name.is_empty():
				return false

			if global_ids.has(region_id):
				return false

			if world.has_region(region_id) or world.has_entity(region_id):
				return false

			global_ids[region_id] = true

			if not strategic_key.is_empty() and not strategic_locations.has(strategic_key):
				return false

			var provinces: Array = region_data.get("provinces", [])
			if provinces.is_empty():
				return false

			for province_value in provinces:
				if typeof(province_value) != TYPE_DICTIONARY:
					return false

				var province_data: Dictionary = province_value
				var province_id = str(province_data.get("id", ""))
				var province_name = str(province_data.get("name", ""))

				if province_id.is_empty() or province_name.is_empty():
					return false

				if global_ids.has(province_id):
					return false

				if world.has_region(province_id) or world.has_entity(province_id):
					return false

				global_ids[province_id] = true

	return true


func _copy_metadata(node: Region, source_value) -> void:
	if node == null:
		return

	if typeof(source_value) != TYPE_DICTIONARY:
		return

	var source: Dictionary = source_value
	for key in source.keys():
		node.set_metadata(str(key), source[key])


# ============================================================
# LEGACY / MANUAL CREATION API PRESERVED
# ============================================================

func create_region(
	world: WorldState,
	country_id: String,
	region_id: String,
	region_name: String
) -> Region:
	if world == null:
		return null

	if country_id.is_empty() or region_id.is_empty() or region_name.is_empty():
		return null

	var country = world.get_entity(country_id)
	if country == null:
		return null

	if str(country.entity_type) != "country":
		return null

	if world.has_region(region_id) or world.has_entity(region_id):
		return null

	var region := Region.new(
		region_id,
		region_name,
		Region.LEVEL_REGION,
		country_id
	)

	if not world.add_region(region):
		return null

	return region


func create_province(
	world: WorldState,
	region_id: String,
	province_id: String,
	province_name: String
) -> Region:
	if world == null:
		return null

	if region_id.is_empty() or province_id.is_empty() or province_name.is_empty():
		return null

	var parent = world.get_region(region_id)
	if parent == null or not parent.is_region():
		return null

	if world.has_region(province_id) or world.has_entity(province_id):
		return null

	var province := Region.new(
		province_id,
		province_name,
		Region.LEVEL_PROVINCE,
		parent.country_id,
		parent.id
	)

	if not world.add_region(province):
		return null

	if not parent.add_child_id(province.id):
		world.remove_region(province.id)
		return null

	return province


# ============================================================
# QUERIES
# ============================================================

func get_country_regions(
	world: WorldState,
	country_id: String
) -> Array[Region]:
	var result: Array[Region] = []

	if world == null:
		return result

	for value in world.regions.values():
		var region := value as Region
		if region == null:
			continue

		if region.country_id != country_id or not region.is_region():
			continue

		result.append(region)

	return result


func get_country_provinces(
	world: WorldState,
	country_id: String
) -> Array[Region]:
	var result: Array[Region] = []

	if world == null:
		return result

	for value in world.regions.values():
		var region := value as Region
		if region == null:
			continue

		if region.country_id != country_id or not region.is_province():
			continue

		result.append(region)

	return result


func get_region_children(
	world: WorldState,
	region_id: String
) -> Array[Region]:
	var result: Array[Region] = []

	if world == null:
		return result

	var parent = world.get_region(region_id)
	if parent == null:
		return result

	for child_id in parent.child_ids:
		var child = world.get_region(child_id)
		if child != null:
			result.append(child)

	return result


# ============================================================
# VALIDATION
# ============================================================

func validate_hierarchy(world: WorldState) -> bool:
	if world == null:
		return false

	for value in world.regions.values():
		var node := value as Region
		if node == null or not node.is_valid():
			return false

		var country = world.get_entity(node.country_id)
		if country == null or str(country.entity_type) != "country":
			return false

		if node.is_region():
			if not node.parent_region_id.is_empty():
				return false
		else:
			if node.parent_region_id.is_empty():
				return false

			var parent = world.get_region(node.parent_region_id)
			if parent == null or not parent.is_region():
				return false

			if parent.country_id != node.country_id:
				return false

			if not parent.has_child(node.id):
				return false

		for child_id in node.child_ids:
			var child = world.get_region(child_id)
			if child == null or not child.is_province():
				return false

			if child.parent_region_id != node.id:
				return false

			if child.country_id != node.country_id:
				return false

	return true


func validate_country_anchor(
	world: WorldState,
	region: Region
) -> bool:
	if world == null or region == null:
		return false

	if region.source_geography_key.is_empty():
		return true

	var country = world.get_entity(region.country_id)
	if country == null:
		return false

	var geography = country.get_component("geography")
	if geography == null:
		return false

	var strategic_locations = geography.state.get(
		"strategic_locations",
		{}
	)

	if typeof(strategic_locations) != TYPE_DICTIONARY:
		return false

	return strategic_locations.has(region.source_geography_key)


func remove_node(
	world: WorldState,
	region_id: String
) -> bool:
	if world == null:
		return false

	var node = world.get_region(region_id)
	if node == null:
		return false

	if not node.child_ids.is_empty():
		return false

	if not node.parent_region_id.is_empty():
		var parent = world.get_region(node.parent_region_id)
		if parent != null:
			parent.remove_child_id(node.id)

	world.remove_region(node.id)
	return true
