class_name MilitaryTransportLogisticsSystem
extends SimulationSystem


# ================================================================
# STEP 13.3 — TRANSPORT → LOGISTICS
# ================================================================
#
# Derived bridge only.
#
# Authority remains:
#   InfrastructureComponent
#       -> current country transport / roads / railways capacity
#   RegionalTransportSystem / RegionalTransportNode / Route
#       -> existing regional strategic network capacity/cost/restrictions
#   MilitarySystem
#       -> final military logistics state
#
# This system does not move resources, execute trade, or create a second
# transport network. It only translates already-existing physical
# transport state into an explicit military logistics modifier.
# ================================================================


const DEFAULT_MODIFIER: float = 1.0


func _get_effective_transport_capacity(
	infrastructure: InfrastructureComponent
) -> float:
	if infrastructure == null:
		return DEFAULT_MODIFIER

	var damage_state = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	var has_active_damage := false
	if damage_state is Dictionary:
		for value in damage_state.values():
			if float(value) > 0.0:
				has_active_damage = true
				break

	var condition_state = infrastructure.get_state(
		"infrastructure_condition",
		{}
	)
	var has_non_neutral_condition := false
	if condition_state is Dictionary:
		for value in condition_state.values():
			if absf(float(value) - 1.0) > 0.000001:
				has_non_neutral_condition = true
				break

	if has_active_damage or has_non_neutral_condition:
		var effective_capacity = infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		)
		if (
			effective_capacity is Dictionary
			and effective_capacity.has("transport")
		):
			return clampf(
				float(effective_capacity.get("transport", DEFAULT_MODIFIER)),
				0.0,
				1.0
			)

	return clampf(
		float(
			infrastructure.get_state(
				"transport",
				DEFAULT_MODIFIER
			)
		),
		0.0,
		1.0
	)


func _init() -> void:
	super("military_transport_logistics_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error(
			"MilitaryTransportLogisticsSystem: World is null."
		)
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var military: MilitaryComponent = entity.get_component(
			"military"
		)
		if military == null:
			continue

		var infrastructure: InfrastructureComponent = entity.get_component(
			"infrastructure"
		)

		_update_entity(
			world,
			entity.id,
			military,
			infrastructure
		)


func _update_entity(
	world: WorldState,
	country_id: String,
	military: MilitaryComponent,
	infrastructure: InfrastructureComponent
) -> void:

	var infrastructure_factor: float = 1.0

	if infrastructure != null:
		var transport: float = _get_effective_transport_capacity(
			infrastructure
		)

		var roads: float = clampf(
			float(
				infrastructure.get_state(
					"roads",
					1.0
				)
			),
			0.0,
			1.0
		)

		var railways: float = clampf(
			float(
				infrastructure.get_state(
					"railways",
					1.0
				)
			),
			0.0,
			1.0
		)

		infrastructure_factor = clampf(
			transport * 0.45
			+ roads * 0.30
			+ railways * 0.25,
			0.0,
			1.0
		)

	# ------------------------------------------------------------
	# Existing regional transport graph
	#
	# Nodes and routes remain read-only inputs here. A node/route
	# capacity ratio is measured against its existing base capacity.
	# ------------------------------------------------------------

	var node_factor: float = 1.0
	var route_factor: float = 1.0
	var cost_factor: float = 1.0

	var node_weight_total: float = 0.0
	var node_weighted_capacity: float = 0.0

	if world.has_method("get_regional_transport_node_count"):
		for node_value in world.regional_transport_nodes.values():
			var node: RegionalTransportNode = (
				node_value as RegionalTransportNode
			)

			if node == null:
				continue

			if node.structural_country_id != country_id:
				continue

			if node.base_capacity <= 0.0:
				continue

			var node_ratio: float = clampf(
				node.effective_capacity
				/ node.base_capacity,
				0.0,
				1.0
			)

			var weight: float = maxf(
				node.population_weight,
				0.0
			)

			if weight <= 0.0:
				weight = 1.0

			node_weighted_capacity += (
				node_ratio * weight
			)

			node_weight_total += weight

	if node_weight_total > 0.0:
		node_factor = clampf(
			node_weighted_capacity
			/ node_weight_total,
			0.0,
			1.0
		)

	var route_weight_total: float = 0.0
	var route_weighted_capacity: float = 0.0
	var route_weighted_cost: float = 0.0

	if world.has_method("get_regional_transport_route_count"):
		for route_value in world.regional_transport_routes.values():
			var route: RegionalTransportRoute = (
				route_value as RegionalTransportRoute
			)

			if route == null:
				continue

			if route.structural_country_id != country_id:
				continue

			if route.base_capacity <= 0.0:
				continue

			var route_ratio: float = clampf(
				route.effective_capacity
				/ route.base_capacity,
				0.0,
				1.0
			)

			var weight: float = maxf(
				route.base_capacity,
				0.000001
			)

			route_weighted_capacity += (
				route_ratio * weight
			)

			route_weighted_cost += (
				clampf(
					route.transport_cost,
					0.0,
					1000000.0
				)
				* weight
			)

			route_weight_total += weight

	if route_weight_total > 0.0:
		route_factor = clampf(
			route_weighted_capacity
			/ route_weight_total,
			0.0,
			1.0
		)

		var average_cost: float = (
			route_weighted_cost
			/ route_weight_total
		)

		cost_factor = clampf(
			1.0 / maxf(
				1.0,
				average_cost
			),
			0.50,
			1.0
		)

	# If no regional graph exists for the country, keep the network
	# contribution neutral. Country infrastructure remains sufficient
	# to provide the 13.3 strategic abstraction.
	var regional_network_factor: float = clampf(
		node_factor * 0.45
		+ route_factor * 0.45
		+ cost_factor * 0.10,
		0.0,
		1.0
	)

	var combined_transport_factor: float = clampf(
		infrastructure_factor * 0.70
		+ regional_network_factor * 0.30,
		0.0,
		1.0
	)

	# Bounded strategic abstraction:
	# full transport support preserves existing military logistics;
	# degraded transport reduces it, but a transport disruption does
	# not erase all logistics capability.
	var logistics_modifier: float = clampf(
		0.60
		+ combined_transport_factor * 0.40,
		0.0,
		1.0
	)

	military.set_state(
		"transport_logistics_modifier",
		logistics_modifier
	)

	military.set_state(
		"transport_logistics_constraint",
		1.0 - logistics_modifier
	)

	military.set_state(
		"transport_infrastructure_factor",
		infrastructure_factor
	)

	military.set_state(
		"transport_node_factor",
		node_factor
	)

	military.set_state(
		"transport_route_factor",
		route_factor
	)

	military.set_state(
		"transport_cost_factor",
		cost_factor
	)

	military.set_state(
		"transport_network_factor",
		regional_network_factor
	)

	military.set_state(
		"transport_logistics_source",
		"InfrastructureComponent.effective_transport + RegionalTransportSystem"
	)
