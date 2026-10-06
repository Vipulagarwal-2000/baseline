class_name PopulationSystem
extends SimulationSystem


func _init():
	super("population_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"PopulationSystem: World is null."
		)
		return

	for entity in world.entities.values():

		var population = entity.get_component(
			"population"
		)

		if population == null:
			continue


		# ====================================================
		# CURRENT POPULATION
		# ====================================================

		var current_population = float(
			population.get_state(
				"population",
				0.0
			)
		)


		# ====================================================
		# NATURAL GROWTH
		# ====================================================

		var natural_growth_rate = float(
			population.get_state(
				"natural_growth_rate",
				0.0
			)
		)

		var monthly_growth_rate = (
			natural_growth_rate / 12.0
		)

		var natural_population_change = (
			current_population
			* monthly_growth_rate
			/ 1000.0
		)


		# ====================================================
		# MIGRATION
		# ====================================================

		var net_migration = float(
			population.get_state(
				"net_migration",
				0.0
			)
		)


		# ====================================================
		# TOTAL POPULATION CHANGE
		# ====================================================

		var total_population_change = (
			natural_population_change
			+ net_migration
		)

		var new_population = (
			current_population
			+ total_population_change
		)


		# ====================================================
		# UPDATE POPULATION
		# ====================================================

		population.set_state(
			"population",
			new_population
		)


		# ====================================================
		# STORE CALCULATED VALUES
		# ====================================================

		population.set_state(
			"monthly_population_change",
			total_population_change
		)

		population.set_state(
			"natural_population_change",
			natural_population_change
		)
