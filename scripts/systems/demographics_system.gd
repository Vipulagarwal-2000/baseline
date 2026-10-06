class_name DemographicsSystem
extends SimulationSystem


func _init():
	super("demographics_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"DemographicsSystem: World is null."
		)
		return

	for entity in world.entities.values():

		var population = entity.get_component(
			"population"
		)

		if population == null:
			continue

		var birth_rate = float(
			population.get_state(
				"birth_rate",
				0.0
			)
		)

		var death_rate = float(
			population.get_state(
				"death_rate",
				0.0
			)
		)

		var natural_growth_rate = (
			birth_rate - death_rate
		)

		population.set_state(
			"natural_growth_rate",
			natural_growth_rate
		)
