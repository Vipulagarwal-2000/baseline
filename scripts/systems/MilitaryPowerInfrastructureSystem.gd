class_name MilitaryPowerInfrastructureSystem
extends SimulationSystem


# ================================================================
# STEP 13.5 — POWER → MILITARY INFRASTRUCTURE
# ================================================================
#
# Derived bridge only.
#
# Authority remains:
#   InfrastructureComponent.power
#       -> country-authoritative power infrastructure availability
#   MilitarySystem
#       -> final military readiness/capability calculation
#
# This system does not create a second power grid, energy market, or
# tactical military infrastructure model. It translates existing power
# availability into strategic military-infrastructure support.
# ================================================================


func _init() -> void:
	super("military_power_infrastructure_system")


func process_month(world: WorldState) -> void:
	if world == null:
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
			infrastructure,
			military
		)


func _update_entity(
	infrastructure: InfrastructureComponent,
	military: MilitaryComponent
) -> void:

	var power_availability: float = 1.0

	if infrastructure != null:
		power_availability = clampf(
			float(
				infrastructure.get_state(
					"power",
					1.0
				)
			),
			0.0,
			1.0
		)

	# Strategic abstraction:
	# full power support = 1.0
	# zero power availability = 0.50
	#
	# This represents emergency/backup support rather than deleting
	# the country's military infrastructure altogether.
	var military_infrastructure_modifier: float = clampf(
		0.50
		+ power_availability * 0.50,
		0.0,
		1.0
	)

	var military_infrastructure_constraint: float = (
		1.0 - military_infrastructure_modifier
	)

	military.set_state(
		"military_infrastructure_modifier",
		military_infrastructure_modifier
	)

	military.set_state(
		"military_infrastructure_constraint",
		military_infrastructure_constraint
	)

	military.set_state(
		"military_infrastructure_power_factor",
		power_availability
	)

	military.set_state(
		"military_infrastructure_source",
		"InfrastructureComponent.power"
	)
