class_name MilitaryPortNavalLogisticsSystem
extends SimulationSystem


# STEP 13.4 — PORTS → NAVAL LOGISTICS
#
# Derived bridge:
#   InfrastructureComponent.ports
#   + localized RegionalTransportNode.port_factor
#       ↓
#   naval_logistics_modifier
#       ↓
#   MilitarySystem
#
# No naval units, fleet simulation, trade execution, or second port system.
# InfrastructureComponent remains country-authoritative.

func _init() -> void:
	super("military_port_naval_logistics_system")


func process_month(world: WorldState) -> void:
	if world == null:
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var military: MilitaryComponent = entity.get_component("military")
		if military == null:
			continue

		var infrastructure: InfrastructureComponent = (
			entity.get_component("infrastructure")
		)

		var country_id: String = str(entity.id)

		var country_port_factor: float = 1.0

		if infrastructure != null:
			country_port_factor = clampf(
				float(
					infrastructure.get_state(
						"ports",
						1.0
					)
				),
				0.0,
				1.0
			)

		var regional_port_factor: float = 1.0
		var weight_total: float = 0.0
		var weighted_ports: float = 0.0

		for node_value in world.regional_transport_nodes.values():
			var node: RegionalTransportNode = (
				node_value as RegionalTransportNode
			)

			if node == null:
				continue

			if node.structural_country_id != country_id:
				continue

			var weight: float = maxf(
				node.population_weight,
				0.0
			)

			if weight <= 0.0:
				weight = 1.0

			weighted_ports += (
				clampf(node.port_factor, 0.0, 1.0)
				* weight
			)
			weight_total += weight

		if weight_total > 0.0:
			regional_port_factor = clampf(
				weighted_ports / weight_total,
				0.0,
				1.0
			)

		var port_capacity_factor: float = clampf(
			country_port_factor * 0.80
			+ regional_port_factor * 0.20,
			0.0,
			1.0
		)

		# Strategic support abstraction:
		# full ports = 1.0, zero port capacity = 0.50.
		var naval_logistics_modifier: float = clampf(
			0.50 + port_capacity_factor * 0.50,
			0.0,
			1.0
		)

		military.set_state(
			"naval_logistics_modifier",
			naval_logistics_modifier
		)

		military.set_state(
			"naval_logistics_constraint",
			1.0 - naval_logistics_modifier
		)

		military.set_state(
			"naval_port_capacity_factor",
			port_capacity_factor
		)

		military.set_state(
			"naval_country_port_factor",
			country_port_factor
		)

		military.set_state(
			"naval_regional_port_factor",
			regional_port_factor
		)

		military.set_state(
			"naval_logistics_source",
			"InfrastructureComponent.ports + RegionalTransportNode.port_factor"
		)
