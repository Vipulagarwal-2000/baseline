class_name WorldState
extends RefCounted


# ============================================================
# CONFIGURATION
# ============================================================

var config: SimulationConfig


# ============================================================
# CURRENT DATE
# ============================================================

var current_date: Dictionary = {}


# ============================================================
# WORLD ENTITIES
# ============================================================

var entities: Dictionary = {}


# ============================================================
# WORLD TRADE AGREEMENTS
# ============================================================

# Durable bilateral trade-agreement state.
# Step 4.1 stores the agreement itself only; it does not execute
# resource movement or route throughput.
var trade_agreements: Dictionary = {}


func add_trade_agreement(
	agreement
) -> bool:

	if agreement == null:
		push_error(
			"WorldState: Cannot add null trade agreement."
		)
		return false

	if not agreement is TradeAgreement:
		push_error(
			"WorldState: Invalid trade agreement type."
		)
		return false

	if not agreement.is_valid():
		push_error(
			"WorldState: Cannot add invalid trade agreement."
		)
		return false

	if trade_agreements.has(agreement.id):
		push_error(
			"WorldState: Trade agreement ID already exists: "
			+ agreement.id
		)
		return false

	trade_agreements[agreement.id] = agreement
	return true


func get_trade_agreement(
	agreement_id: String
):

	return trade_agreements.get(
		agreement_id,
		null
	)


func has_trade_agreement(
	agreement_id: String
) -> bool:

	return trade_agreements.has(
		agreement_id
	)


func remove_trade_agreement(
	agreement_id: String
) -> void:

	trade_agreements.erase(
		agreement_id
	)


func get_trade_agreement_count() -> int:

	return trade_agreements.size()


# ============================================================
# WORLD TRADE ROUTES
# ============================================================

# Durable connection state for existing TradeAgreement objects.
# Step 4.2 stores the route relationship only; it does not
# calculate throughput or move resources.
var trade_routes: Dictionary = {}


func add_trade_route(
	route
) -> bool:

	if route == null:
		push_error(
			"WorldState: Cannot add null trade route."
		)
		return false

	if not route is TradeRoute:
		push_error(
			"WorldState: Invalid trade route type."
		)
		return false

	if not route.is_valid():
		push_error(
			"WorldState: Cannot add invalid trade route."
		)
		return false

	if trade_routes.has(route.id):
		push_error(
			"WorldState: Trade route ID already exists: "
			+ route.id
		)
		return false

	var agreement = get_trade_agreement(
		route.agreement_id
	)

	if agreement == null:
		push_error(
			"WorldState: Trade route references unknown trade agreement: "
			+ route.agreement_id
		)
		return false

	if (
		route.exporter_id != agreement.exporter_id
		or route.importer_id != agreement.importer_id
	):
		push_error(
			"WorldState: Trade route endpoints do not match linked trade agreement."
		)
		return false

	trade_routes[route.id] = route
	return true


func get_trade_route(
	route_id: String
):

	return trade_routes.get(
		route_id,
		null
	)


func has_trade_route(
	route_id: String
) -> bool:

	return trade_routes.has(
		route_id
	)


func remove_trade_route(
	route_id: String
) -> void:

	trade_routes.erase(
		route_id
	)


func get_trade_route_count() -> int:

	return trade_routes.size()



# ============================================================
# WORLD TRADE TRANSACTIONS
# ============================================================

# Monthly executed trade records created by TradeSystem.
# These are durable records of the 4.3 execution layer; they do
# not replace the ResourceSystem's authoritative stockpile state.
var trade_transactions: Dictionary = {}


func add_trade_transaction(
	transaction
) -> bool:

	if transaction == null:
		push_error(
            "WorldState: Cannot add null trade transaction."
		)
		return false

	if not transaction is TradeTransaction:
		push_error(
            "WorldState: Invalid trade transaction type."
		)
		return false

	if not transaction.is_valid():
		push_error(
            "WorldState: Cannot add invalid trade transaction."
		)
		return false

	if trade_transactions.has(transaction.id):
		push_error(
            "WorldState: Trade transaction ID already exists: "
			+ transaction.id
		)
		return false

	if not has_trade_agreement(transaction.agreement_id):
		push_error(
            "WorldState: Trade transaction references unknown trade agreement: "
			+ transaction.agreement_id
		)
		return false

	if not has_trade_route(transaction.route_id):
		push_error(
            "WorldState: Trade transaction references unknown trade route: "
			+ transaction.route_id
		)
		return false

	trade_transactions[transaction.id] = transaction
	return true


func get_trade_transaction(
	transaction_id: String
):

	return trade_transactions.get(
		transaction_id,
		null
	)


func has_trade_transaction(
	transaction_id: String
) -> bool:

	return trade_transactions.has(
		transaction_id
	)


func remove_trade_transaction(
	transaction_id: String
) -> void:

	trade_transactions.erase(
		transaction_id
	)


func get_trade_transaction_count() -> int:

	return trade_transactions.size()


# ============================================================
# WORLD EVENTS
# ============================================================

var active_events: Array = []
var completed_events: Array = []


# ============================================================
# WORLD CONFLICTS
# ============================================================

var active_conflicts: Array = []
var completed_conflicts: Array = []


# ============================================================
# WORLD VARIABLES
# ============================================================

var global_variables: Dictionary = {}

var world_flags: Dictionary = {}

var global_modifiers: Dictionary = {}

var world_metadata: Dictionary = {}


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	simulation_config: SimulationConfig = null
):

	if simulation_config == null:

		config = (
			SimulationConfig.create_default()
		)

	else:

		config = simulation_config


	current_date = {

		"year":
			config.start_year,

		"month":
			config.start_month,

		"day":
			config.start_day
	}


# ============================================================
# ENTITY MANAGEMENT
# ============================================================

func add_entity(
	entity
) -> void:

	if entity == null:

		push_error(
			"WorldState: Cannot add null entity."
		)

		return


	if entity.id.is_empty():

		push_error(
			"WorldState: Cannot add entity with empty ID."
		)

		return


	entities[
		entity.id
	] = entity


func get_entity(
	entity_id: String
):

	return entities.get(
		entity_id,
		null
	)


func remove_entity(
	entity_id: String
) -> void:

	entities.erase(
		entity_id
	)


func has_entity(
	entity_id: String
) -> bool:

	return entities.has(
		entity_id
	)


func get_entity_count() -> int:

	return entities.size()


# ============================================================
# WORLD REGIONS — STEP 12.1
# ============================================================
# Regions are deliberately stored in their own registry. They are
# not fake SimEntity/Country objects and do not compete with
# country-level authority.
var regions: Dictionary = {}


func add_region(
	region
) -> bool:

	if region == null:
		push_error(
			"WorldState: Cannot add null region."
		)
		return false

	if not region is Region:
		push_error(
			"WorldState: Invalid region type."
		)
		return false

	if not region.is_valid():
		push_error(
			"WorldState: Invalid region state."
		)
		return false

	if not has_entity(region.country_id):
		push_error(
			"WorldState: Region references unknown country: "
			+ region.country_id
		)
		return false

	if regions.has(region.id):
		push_error(
			"WorldState: Region ID already exists: "
			+ region.id
		)
		return false

	if entities.has(region.id):
		push_error(
			"WorldState: Region ID collides with entity ID: "
			+ region.id
		)
		return false

	regions[region.id] = region
	return true


func get_region(
	region_id: String
):

	return regions.get(
		region_id,
		null
	)


func has_region(
	region_id: String
) -> bool:

	return regions.has(
		region_id
	)


func remove_region(
	region_id: String
) -> void:

	regions.erase(
		region_id
	)


func get_region_count() -> int:

	return regions.size()


# ============================================================
# REGIONAL OWNERSHIP — STEP 12.2
# ============================================================
# Ownership/control state is stored separately from the structural
# Region registry. This preserves the distinction between geographic
# home (Region.country_id) and current ownership/controller state.
var regional_ownership: Dictionary = {}


func add_regional_ownership(
	ownership_state
) -> bool:

	if ownership_state == null:
		push_error(
			"WorldState: Cannot add null regional ownership state."
		)
		return false

	if not ownership_state is RegionalOwnershipState:
		push_error(
			"WorldState: Invalid regional ownership state type."
		)
		return false

	if not has_region(ownership_state.region_id):
		push_error(
			"WorldState: Ownership state references unknown region: "
			+ ownership_state.region_id
		)
		return false

	if regional_ownership.has(ownership_state.region_id):
		push_error(
			"WorldState: Regional ownership ID already exists: "
			+ ownership_state.region_id
		)
		return false

	regional_ownership[ownership_state.region_id] = ownership_state
	return true


func get_regional_ownership(
	region_id: String
):

	return regional_ownership.get(
		region_id,
		null
	)


func has_regional_ownership(
	region_id: String
) -> bool:

	return regional_ownership.has(
		region_id
	)


func remove_regional_ownership(
	region_id: String
) -> void:

	regional_ownership.erase(
		region_id
	)


func get_regional_ownership_count() -> int:

	return regional_ownership.size()


# ============================================================
# REGIONAL TERRAIN — STEP 12.3
# ============================================================
# Terrain is a bounded regional state registry. It stays separate
# from both the structural Region object and Country geography.
var regional_terrain: Dictionary = {}


func add_regional_terrain(
	terrain_state
) -> bool:

	if terrain_state == null:
		push_error(
			"WorldState: Cannot add null regional terrain state."
		)
		return false

	if not terrain_state is RegionalTerrainState:
		push_error(
			"WorldState: Invalid regional terrain state type."
		)
		return false

	if not terrain_state.is_valid():
		push_error(
			"WorldState: Invalid regional terrain state."
		)
		return false

	if not has_region(terrain_state.region_id):
		push_error(
			"WorldState: Regional terrain references unknown region: "
			+ terrain_state.region_id
		)
		return false

	if regional_terrain.has(terrain_state.region_id):
		push_error(
			"WorldState: Regional terrain ID already exists: "
			+ terrain_state.region_id
		)
		return false

	regional_terrain[terrain_state.region_id] = terrain_state
	return true


func get_regional_terrain(
	region_id: String
):

	return regional_terrain.get(
		region_id,
		null
	)


func has_regional_terrain(
	region_id: String
) -> bool:

	return regional_terrain.has(
		region_id
	)


func remove_regional_terrain(
	region_id: String
) -> void:

	regional_terrain.erase(
		region_id
	)


func get_regional_terrain_count() -> int:

	return regional_terrain.size()


# ============================================================
# REGIONAL POPULATION — STEP 12.4
# ============================================================
# Population localization is kept in a dedicated registry so the
# structural Region object does not become a second demographic authority.
var regional_population: Dictionary = {}


func add_regional_population(
	population_state
) -> bool:

	if population_state == null:
		push_error(
			"WorldState: Cannot add null regional population state."
		)
		return false

	if not population_state is RegionalPopulationState:
		push_error(
			"WorldState: Invalid regional population state type."
		)
		return false

	if not population_state.is_valid():
		push_error(
			"WorldState: Invalid regional population state."
		)
		return false

	var region := get_region(
		population_state.region_id
	) as Region

	if region == null:
		push_error(
			"WorldState: Regional population references unknown region: "
			+ population_state.region_id
		)
		return false

	if not region.is_region():
		push_error(
			"WorldState: Step 12.4 population authority must attach to parent region: "
			+ population_state.region_id
		)
		return false

	if population_state.structural_country_id != region.country_id:
		push_error(
			"WorldState: Regional population country mismatch for region: "
			+ population_state.region_id
		)
		return false

	if regional_population.has(population_state.region_id):
		push_error(
			"WorldState: Regional population ID already exists: "
			+ population_state.region_id
		)
		return false

	regional_population[population_state.region_id] = population_state
	return true


func get_regional_population(
	region_id: String
):

	return regional_population.get(
		region_id,
		null
	)


func has_regional_population(
	region_id: String
) -> bool:

	return regional_population.has(
		region_id
	)


func remove_regional_population(
	region_id: String
) -> void:

	regional_population.erase(
		region_id
	)


func get_regional_population_count() -> int:

	return regional_population.size()


# ============================================================
# REGIONAL RESOURCES — STEP 12.5
# ============================================================
# Resource localization is kept in its own registry so Region does not
# become a duplicate ResourceComponent authority.
var regional_resources: Dictionary = {}


func add_regional_resource(
	resource_state
) -> bool:

	if resource_state == null:
		push_error(
			"WorldState: Cannot add null regional resource state."
		)
		return false

	if not resource_state is RegionalResourceState:
		push_error(
			"WorldState: Invalid regional resource state type."
		)
		return false

	if not resource_state.is_valid():
		push_error(
			"WorldState: Invalid regional resource state."
		)
		return false

	var region := get_region(
		resource_state.region_id
	) as Region

	if region == null:
		push_error(
			"WorldState: Regional resource references unknown region: "
			+ resource_state.region_id
		)
		return false

	if not region.is_region():
		push_error(
			"WorldState: Step 12.5 resource authority must attach to parent region: "
			+ resource_state.region_id
		)
		return false

	if resource_state.structural_country_id != region.country_id:
		push_error(
			"WorldState: Regional resource country mismatch for region: "
			+ resource_state.region_id
		)
		return false

	if regional_resources.has(resource_state.region_id):
		push_error(
			"WorldState: Regional resource ID already exists: "
			+ resource_state.region_id
		)
		return false

	regional_resources[resource_state.region_id] = resource_state
	return true


func get_regional_resource(
	region_id: String
):

	return regional_resources.get(
		region_id,
		null
	)


func has_regional_resource(
	region_id: String
) -> bool:

	return regional_resources.has(
		region_id
	)


func remove_regional_resource(
	region_id: String
) -> void:

	regional_resources.erase(
		region_id
	)


func get_regional_resource_count() -> int:

	return regional_resources.size()


# ============================================================
# REGIONAL INFRASTRUCTURE — STEP 12.6
# ============================================================
# Infrastructure localization is kept in its own registry. The existing
# country InfrastructureComponent remains authoritative until the later
# country aggregation handoff.
var regional_infrastructure: Dictionary = {}


func add_regional_infrastructure(
	infrastructure_state
) -> bool:

	if infrastructure_state == null:
		push_error(
			"WorldState: Cannot add null regional infrastructure state."
		)
		return false

	if not infrastructure_state is RegionalInfrastructureState:
		push_error(
			"WorldState: Invalid regional infrastructure state type."
		)
		return false

	if not infrastructure_state.is_valid():
		push_error(
			"WorldState: Invalid regional infrastructure state."
		)
		return false

	var region: Region = get_region(
		infrastructure_state.region_id
	) as Region
	if region == null:
		push_error(
			"WorldState: Regional infrastructure references unknown region: "
			+ infrastructure_state.region_id
		)
		return false

	if not region.is_region():
		push_error(
			"WorldState: Step 12.6 infrastructure authority must attach to parent region: "
			+ infrastructure_state.region_id
		)
		return false

	if infrastructure_state.structural_country_id != region.country_id:
		push_error(
			"WorldState: Regional infrastructure country mismatch for region: "
			+ infrastructure_state.region_id
		)
		return false

	if regional_infrastructure.has(infrastructure_state.region_id):
		push_error(
			"WorldState: Regional infrastructure ID already exists: "
			+ infrastructure_state.region_id
		)
		return false

	regional_infrastructure[infrastructure_state.region_id] = infrastructure_state
	return true


func get_regional_infrastructure(
	region_id: String
):

	return regional_infrastructure.get(
		region_id,
		null
	)


func has_regional_infrastructure(
	region_id: String
) -> bool:

	return regional_infrastructure.has(
		region_id
	)


func remove_regional_infrastructure(
	region_id: String
) -> void:

	regional_infrastructure.erase(
		region_id
	)


func get_regional_infrastructure_count() -> int:

	return regional_infrastructure.size()


# ============================================================
# REGIONAL INDUSTRY — STEP 12.7
# ============================================================
# Industry localization is kept separate from the structural Region object
# and from the authoritative country IndustryComponent.
var regional_industry: Dictionary = {}


func add_regional_industry(
	industry_state
) -> bool:

	if industry_state == null:
		push_error(
			"WorldState: Cannot add null regional industry state."
		)
		return false

	if not industry_state is RegionalIndustryState:
		push_error(
			"WorldState: Invalid regional industry state type."
		)
		return false

	if not industry_state.is_valid():
		push_error(
			"WorldState: Invalid regional industry state."
		)
		return false

	var region: Region = get_region(
		industry_state.region_id
	) as Region

	if region == null:
		push_error(
			"WorldState: Regional industry references unknown region: "
			+ industry_state.region_id
		)
		return false

	if not region.is_region():
		push_error(
			"WorldState: Step 12.7 industry authority must attach to parent region: "
			+ industry_state.region_id
		)
		return false

	if industry_state.structural_country_id != region.country_id:
		push_error(
			"WorldState: Regional industry country mismatch for region: "
			+ industry_state.region_id
		)
		return false

	if regional_industry.has(industry_state.region_id):
		push_error(
			"WorldState: Regional industry ID already exists: "
			+ industry_state.region_id
		)
		return false

	regional_industry[industry_state.region_id] = industry_state
	return true


func get_regional_industry(
	region_id: String
):

	return regional_industry.get(
		region_id,
		null
	)


func has_regional_industry(
	region_id: String
) -> bool:

	return regional_industry.has(
		region_id
	)


func remove_regional_industry(
	region_id: String
) -> void:

	regional_industry.erase(
		region_id
	)


func get_regional_industry_count() -> int:

	return regional_industry.size()


# ============================================================
# REGIONAL TRANSPORT NODES — STEP 12.8
# ============================================================
# Parent regions are transport nodes. This registry does not replace
# the country infrastructure component or execute resource movement.
var regional_transport_nodes: Dictionary = {}


func add_regional_transport_node(
	node
) -> bool:
	if node == null:
		push_error(
			"WorldState: Cannot add null regional transport node."
		)
		return false

	if not node is RegionalTransportNode:
		push_error(
			"WorldState: Invalid regional transport node type."
		)
		return false

	if not node.is_valid():
		push_error(
			"WorldState: Invalid regional transport node."
		)
		return false

	var region: Region = get_region(
		node.region_id
	) as Region
	if region == null:
		push_error(
			"WorldState: Regional transport node references unknown region: "
			+ node.region_id
		)
		return false

	if not region.is_region():
		push_error(
			"WorldState: Step 12.8 transport node must attach to parent region: "
			+ node.region_id
		)
		return false

	if node.structural_country_id != region.country_id:
		push_error(
			"WorldState: Regional transport node country mismatch: "
			+ node.region_id
		)
		return false

	if regional_transport_nodes.has(node.region_id):
		push_error(
			"WorldState: Regional transport node already exists: "
			+ node.region_id
		)
		return false

	regional_transport_nodes[node.region_id] = node
	return true


func get_regional_transport_node(
	region_id: String
):
	return regional_transport_nodes.get(
		region_id,
		null
	)


func has_regional_transport_node(
	region_id: String
) -> bool:
	return regional_transport_nodes.has(
		region_id
	)


func remove_regional_transport_node(
	region_id: String
) -> void:
	regional_transport_nodes.erase(
		region_id
	)


func get_regional_transport_node_count() -> int:
	return regional_transport_nodes.size()


# ============================================================
# REGIONAL TRANSPORT ROUTES — STEP 12.8
# ============================================================
var regional_transport_routes: Dictionary = {}


func add_regional_transport_route(
	route
) -> bool:
	if route == null:
		push_error(
			"WorldState: Cannot add null regional transport route."
		)
		return false

	if not route is RegionalTransportRoute:
		push_error(
			"WorldState: Invalid regional transport route type."
		)
		return false

	if not route.is_valid():
		push_error(
			"WorldState: Invalid regional transport route."
		)
		return false

	var from_node = get_regional_transport_node(
		route.from_region_id
	)
	var to_node = get_regional_transport_node(
		route.to_region_id
	)
	if from_node == null or to_node == null:
		push_error(
			"WorldState: Regional transport route references unknown endpoint."
		)
		return false

	if from_node.structural_country_id != route.structural_country_id:
		push_error(
			"WorldState: Regional transport route source country mismatch."
		)
		return false
	if to_node.structural_country_id != route.structural_country_id:
		push_error(
			"WorldState: Regional transport route destination country mismatch."
		)
		return false

	if route.from_region_id == route.to_region_id:
		return false

	for existing_value in regional_transport_routes.values():
		var existing_route := existing_value as RegionalTransportRoute
		if existing_route == null:
			continue
		if (
			(
				existing_route.from_region_id == route.from_region_id
				and existing_route.to_region_id == route.to_region_id
			)
			or (
				existing_route.from_region_id == route.to_region_id
				and existing_route.to_region_id == route.from_region_id
			)
		):
			push_error(
				"WorldState: Duplicate regional transport connection."
			)
			return false

	if regional_transport_routes.has(route.route_id):
		push_error(
			"WorldState: Regional transport route already exists: "
			+ route.route_id
		)
		return false

	route.recalculate_effective_capacity(
		from_node,
		to_node
	)
	regional_transport_routes[route.route_id] = route
	return true


func get_regional_transport_route(
	route_id: String
):
	return regional_transport_routes.get(
		route_id,
		null
	)


func has_regional_transport_route(
	route_id: String
) -> bool:
	return regional_transport_routes.has(
		route_id
	)


func remove_regional_transport_route(
	route_id: String
) -> void:
	regional_transport_routes.erase(
		route_id
	)


func get_regional_transport_route_count() -> int:
	return regional_transport_routes.size()


func get_country_region_count(
	country_id: String
) -> int:

	var count := 0

	for value in regions.values():
		var region := value as Region
		if region == null:
			continue

		if region.country_id == country_id and region.is_region():
			count += 1

	return count


func get_country_province_count(
	country_id: String
) -> int:

	var count := 0

	for value in regions.values():
		var region := value as Region
		if region == null:
			continue

		if region.country_id == country_id and region.is_province():
			count += 1

	return count


# ============================================================
# WORLD VARIABLES
# ============================================================

func set_global_variable(
	key: String,
	value
) -> void:

	if key.is_empty():

		return


	global_variables[
		key
	] = value


func get_global_variable(
	key: String,
	default_value = null
):

	return global_variables.get(
		key,
		default_value
	)


func has_global_variable(
	key: String
) -> bool:

	return global_variables.has(
		key
	)


func remove_global_variable(
	key: String
) -> void:

	global_variables.erase(
		key
	)


# ============================================================
# WORLD FLAGS
# ============================================================

func set_world_flag(
	flag_id: String,
	value: bool = true
) -> void:

	if flag_id.is_empty():

		return


	world_flags[
		flag_id
	] = value


func has_world_flag(
	flag_id: String
) -> bool:

	return bool(
		world_flags.get(
			flag_id,
			false
		)
	)


func remove_world_flag(
	flag_id: String
) -> void:

	world_flags.erase(
		flag_id
	)


# ============================================================
# GLOBAL MODIFIERS
# ============================================================

func set_global_modifier(
	modifier_id: String,
	value
) -> void:

	if modifier_id.is_empty():

		return


	global_modifiers[
		modifier_id
	] = value


func get_global_modifier(
	modifier_id: String,
	default_value = null
):

	return global_modifiers.get(
		modifier_id,
		default_value
	)


func has_global_modifier(
	modifier_id: String
) -> bool:

	return global_modifiers.has(
		modifier_id
	)


func remove_global_modifier(
	modifier_id: String
) -> void:

	global_modifiers.erase(
		modifier_id
	)


# ============================================================
# WORLD METADATA
# ============================================================

func set_metadata(
	key: String,
	value
) -> void:

	if key.is_empty():

		return


	world_metadata[
		key
	] = value


func get_metadata(
	key: String,
	default_value = null
):

	return world_metadata.get(
		key,
		default_value
	)


func has_metadata(
	key: String
) -> bool:

	return world_metadata.has(
		key
	)


func remove_metadata(
	key: String
) -> void:

	world_metadata.erase(
		key
	)


# ============================================================
# EVENT MANAGEMENT
# ============================================================

func add_active_event(
	event
) -> void:

	if event == null:

		return


	active_events.append(
		event
	)


func add_completed_event(
	event
) -> void:

	if event == null:

		return


	completed_events.append(
		event
	)


# ============================================================
# CONFLICT MANAGEMENT
# ============================================================

func add_active_conflict(
	conflict
) -> void:

	if conflict == null:

		return


	active_conflicts.append(
		conflict
	)


func add_completed_conflict(
	conflict
) -> void:

	if conflict == null:

		return


	completed_conflicts.append(
		conflict
	)


# ============================================================
# DATE MANAGEMENT
# ============================================================

func advance_month() -> void:

	current_date.month += 1


	if current_date.month > 12:

		current_date.month = 1

		current_date.year += 1


func get_year() -> int:

	return int(
		current_date.year
	)


func get_month() -> int:

	return int(
		current_date.month
	)


func get_day() -> int:

	return int(
		current_date.day
	)


# ============================================================
# ELAPSED TIME
# ============================================================

func get_elapsed_months() -> int:

	var start_total_months = (

		config.start_year * 12

		+ (
			config.start_month - 1
		)

	)


	var current_total_months = (

		get_year() * 12

		+ (
			get_month() - 1
		)

	)


	return (
		current_total_months
		- start_total_months
	)


func get_elapsed_years() -> float:

	return (
		float(
			get_elapsed_months()
		)
		/ 12.0
	)


# ============================================================
# DATE STRING
# ============================================================

func get_date_string() -> String:

	return "%02d/%02d/%04d" % [

		get_day(),

		get_month(),

		get_year()
	]


# ============================================================
# DATE CHECKS
# ============================================================

func is_start_of_year() -> bool:

	return (
		get_month() == 1
		and get_day() == 1
	)


func is_end_of_year() -> bool:

	return (
		get_month() == 12
		and get_day() == 1
	)


func is_month(
	month: int
) -> bool:

	return (
		get_month() == month
	)


func is_year(
	year: int
) -> bool:

	return (
		get_year() == year
	)
