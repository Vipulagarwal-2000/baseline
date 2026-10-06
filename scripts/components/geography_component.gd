class_name GeographyComponent
extends SimComponent


func _init(
	owner: String = ""
):

	super(
		"geography",
		owner
	)


	state = {

		# ====================================================
		# BASIC GEOGRAPHY
		# ====================================================

		"region": "",

		"subregion": "",

		"latitude": 0.0,

		"longitude": 0.0,

		"land_area": 0.0,


		# ====================================================
		# TERRAIN
		# ====================================================

		"terrain": {},


		# ====================================================
		# MARITIME ACCESS
		# ====================================================

		"coastline": 0.0,

		"maritime_access": false,

		"major_ports": {},


		# ====================================================
		# BORDERS
		# ====================================================

		"neighbors": {},


		# ====================================================
		# STRATEGIC GEOGRAPHY
		# ====================================================

		"strategic_locations": {},

		"strategic_importance": 0.0,


		# ====================================================
		# TRADE GEOGRAPHY
		# ====================================================

		"trade_routes": {},

		"shipping_access": 0.0,


		# ====================================================
		# RESOURCE GEOGRAPHY
		# ====================================================

		"resource_locations": {},


		# ====================================================
		# MILITARY GEOGRAPHY
		# ====================================================

		"military_access": 0.0,

		"military_projection": 0.0
	}


	# ========================================================
	# DEFAULT CAPABILITIES
	# ========================================================

	capabilities = {

		"land_access": true,

		"geographic_position": true
	}


# ============================================================
# REGION
# ============================================================

func set_region(
	region: String,
	subregion: String = ""
) -> void:

	state[
		"region"
	] = region

	state[
		"subregion"
	] = subregion


func get_region() -> String:

	return str(
		state.get(
			"region",
			""
		)
	)


func get_subregion() -> String:

	return str(
		state.get(
			"subregion",
			""
		)
	)


# ============================================================
# COORDINATES
# ============================================================

func set_coordinates(
	latitude: float,
	longitude: float
) -> void:

	state[
		"latitude"
	] = clamp(
		latitude,
		-90.0,
		90.0
	)

	state[
		"longitude"
	] = clamp(
		longitude,
		-180.0,
		180.0
	)


func get_latitude() -> float:

	return float(
		state.get(
			"latitude",
			0.0
		)
	)


func get_longitude() -> float:

	return float(
		state.get(
			"longitude",
			0.0
		)
	)


# ============================================================
# LAND AREA
# ============================================================

func set_land_area(
	area: float
) -> void:

	state[
		"land_area"
	] = max(
		0.0,
		area
	)


func get_land_area() -> float:

	return float(
		state.get(
			"land_area",
			0.0
		)
	)


# ============================================================
# MARITIME ACCESS
# ============================================================

func set_maritime_access(
	available: bool
) -> void:

	state[
		"maritime_access"
	] = available


func has_maritime_access() -> bool:

	return bool(
		state.get(
			"maritime_access",
			false
		)
	)


func set_coastline(
	length: float
) -> void:

	state[
		"coastline"
	] = max(
		0.0,
		length
	)


func get_coastline() -> float:

	return float(
		state.get(
			"coastline",
			0.0
		)
	)


# ============================================================
# NEIGHBORS
# ============================================================

func set_neighbor(
	country_id: String,
	border_strength: float = 1.0
) -> void:

	if country_id.is_empty():

		return


	var neighbors = state.get(
		"neighbors",
		{}
	)


	if typeof(
		neighbors
	) != TYPE_DICTIONARY:

		neighbors = {}


	neighbors[
		country_id
	] = max(
		0.0,
		border_strength
	)


	state[
		"neighbors"
	] = neighbors


func has_neighbor(
	country_id: String
) -> bool:

	var neighbors = state.get(
		"neighbors",
		{}
	)


	if typeof(
		neighbors
	) != TYPE_DICTIONARY:

		return false


	return neighbors.has(
		country_id
	)


func get_neighbors() -> Dictionary:

	var neighbors = state.get(
		"neighbors",
		{}
	)


	if typeof(
		neighbors
	) != TYPE_DICTIONARY:

		return {}


	return neighbors


# ============================================================
# STRATEGIC IMPORTANCE
# ============================================================

func set_strategic_importance(
	value: float
) -> void:

	state[
		"strategic_importance"
	] = clamp(
		value,
		0.0,
		100.0
	)


func get_strategic_importance() -> float:

	return float(
		state.get(
			"strategic_importance",
			0.0
		)
	)


# ============================================================
# SHIPPING ACCESS
# ============================================================

func set_shipping_access(
	value: float
) -> void:

	state[
		"shipping_access"
	] = clamp(
		value,
		0.0,
		100.0
	)


func get_shipping_access() -> float:

	return float(
		state.get(
			"shipping_access",
			0.0
		)
	)


# ============================================================
# MILITARY ACCESS
# ============================================================

func set_military_access(
	value: float
) -> void:

	state[
		"military_access"
	] = clamp(
		value,
		0.0,
		100.0
	)


func get_military_access() -> float:

	return float(
		state.get(
			"military_access",
			0.0
		)
	)


func set_military_projection(
	value: float
) -> void:

	state[
		"military_projection"
	] = clamp(
		value,
		0.0,
		100.0
	)


func get_military_projection() -> float:

	return float(
		state.get(
			"military_projection",
			0.0
		)
	)


# ============================================================
# STRATEGIC LOCATIONS
# ============================================================

func set_strategic_location(
	location_id: String,
	location_data: Dictionary
) -> void:

	if location_id.is_empty():

		return


	var locations = state.get(
		"strategic_locations",
		{}
	)


	if typeof(
		locations
	) != TYPE_DICTIONARY:

		locations = {}


	locations[
		location_id
	] = location_data.duplicate(
		true
	)


	state[
		"strategic_locations"
	] = locations


func get_strategic_locations() -> Dictionary:

	var locations = state.get(
		"strategic_locations",
		{}
	)


	if typeof(
		locations
	) != TYPE_DICTIONARY:

		return {}


	return locations
