class_name TechnologyAdoptionSystem
extends SimulationSystem


func _init():
	super("technology_adoption_system")


func process_month(world: WorldState) -> void:

	if world == null:

		push_error(
			"TechnologyAdoptionSystem: World is null."
		)

		return


	for entity in world.entities.values():

		var research = entity.get_component(
			"research"
		)

		if research == null:
			continue


		var adoption = entity.get_component(
			"technology_adoption"
		)

		if adoption == null:
			continue


		var completed_technologies = (
			research.get_state(
				"technologies",
				{}
			)
		)

		if typeof(
			completed_technologies
		) != TYPE_DICTIONARY:

			continue


		var deployment_capacity = float(
			adoption.get_state(
				"deployment_capacity",
				0.0
			)
		)

		var deployment_efficiency = float(
			adoption.get_state(
				"deployment_efficiency",
				1.0
			)
		)

		deployment_capacity = max(
			0.0,
			deployment_capacity
		)

		deployment_efficiency = clamp(
			deployment_efficiency,
			0.0,
			1.0
		)


		# Monthly adoption rate.
		#
		# Example:
		# deployment capacity = 10
		# efficiency = 1.0
		#
		# Monthly adoption increase = 0.01
		# or 1 percentage point.

		var monthly_adoption_rate = (
			deployment_capacity
			* deployment_efficiency
			/ 1000.0
		)


		for technology_id in (
			completed_technologies.keys()
		):

			if not bool(
				completed_technologies[
					technology_id
				]
			):

				continue


			var current_adoption = (
				adoption.get_adoption(
					str(technology_id)
				)
			)


			# Already fully adopted.

			if current_adoption >= 1.0:

				continue


			var new_adoption = (
				current_adoption
				+ monthly_adoption_rate
			)

			new_adoption = clamp(
				new_adoption,
				0.0,
				1.0
			)

			adoption.set_adoption(
				str(technology_id),
				new_adoption
			)
