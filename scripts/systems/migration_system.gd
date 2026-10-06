class_name MigrationSystem
extends SimulationSystem


func _init():
	super("migration_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"MigrationSystem: World is null."
		)
		return


	# ========================================================
	# CALCULATE WORLD AVERAGE GDP PER CAPITA
	# ========================================================

	var total_gdp_per_capita = 0.0
	var economy_count = 0


	for entity in world.entities.values():

		var economy = entity.get_component(
			"economy"
		)

		if economy == null:
			continue

		var gdp_per_capita = float(
			economy.get_state(
				"gdp_per_capita",
				0.0
			)
		)

		if gdp_per_capita <= 0.0:
			continue

		total_gdp_per_capita += gdp_per_capita
		economy_count += 1


	var world_average_gdp_per_capita = 0.0


	if economy_count > 0:

		world_average_gdp_per_capita = (
			total_gdp_per_capita
			/ float(economy_count)
		)


	# ========================================================
	# PROCESS COUNTRIES
	# ========================================================

	for entity in world.entities.values():

		var population = entity.get_component(
			"population"
		)

		if population == null:
			continue


		var economy = entity.get_component(
			"economy"
		)

		if economy == null:
			continue


		# ====================================================
		# BASE MIGRATION
		# ====================================================

		var base_immigration = float(
			population.get_state(
				"base_immigration",
				0.0
			)
		)

		var base_emigration = float(
			population.get_state(
				"base_emigration",
				0.0
			)
		)


		# ====================================================
		# MIGRATION POLICY
		# ====================================================

		var migration_policy = float(
			population.get_state(
				"migration_policy",
				1.0
			)
		)

		migration_policy = max(
			0.0,
			migration_policy
		)


		# ====================================================
		# UNEMPLOYMENT
		# ====================================================

		var unemployment = float(
			economy.get_state(
				"unemployment",
				0.0
			)
		)

		var unemployment_pressure = (
			unemployment - 5.0
		)


		# ====================================================
		# ECONOMIC MIGRATION EFFECT
		# ====================================================

		var economic_immigration_modifier = (
			1.0
			- unemployment_pressure * 0.02
		)

		var economic_emigration_modifier = (
			1.0
			+ unemployment_pressure * 0.02
		)


		economic_immigration_modifier = max(
			0.0,
			economic_immigration_modifier
		)

		economic_emigration_modifier = max(
			0.0,
			economic_emigration_modifier
		)


		# ====================================================
		# GDP PER CAPITA
		# ====================================================

		var country_gdp_per_capita = float(
			economy.get_state(
				"gdp_per_capita",
				0.0
			)
		)


		# ====================================================
		# ECONOMIC ATTRACTIVENESS
		# ====================================================

		var economic_attractiveness = 1.0


		if world_average_gdp_per_capita > 0.0:

			economic_attractiveness = (
				country_gdp_per_capita
				/ world_average_gdp_per_capita
			)


		economic_attractiveness = clamp(
			economic_attractiveness,
			0.25,
			4.0
		)


		# ====================================================
		# MIGRATION ATTRACTIVENESS EFFECT
		# ====================================================

		var attractiveness_immigration_modifier = (
			0.5
			+ economic_attractiveness * 0.5
		)

		var attractiveness_emigration_modifier = (
			1.5
			- economic_attractiveness * 0.5
		)


		attractiveness_immigration_modifier = clamp(
			attractiveness_immigration_modifier,
			0.25,
			2.0
		)

		attractiveness_emigration_modifier = clamp(
			attractiveness_emigration_modifier,
			0.25,
			2.0
		)


		# ====================================================
		# POTENTIAL MIGRATION
		# ====================================================

		var potential_immigration = (
			base_immigration
			* economic_immigration_modifier
			* attractiveness_immigration_modifier
			* migration_policy
		)

		var potential_emigration = (
			base_emigration
			* economic_emigration_modifier
			* attractiveness_emigration_modifier
		)


		# ====================================================
		# MIGRATION CAPACITY
		# ====================================================

		var migration_capacity = float(
			population.get_state(
				"migration_capacity",
				0.0
			)
		)

		migration_capacity = max(
			0.0,
			migration_capacity
		)


		var actual_immigration = min(
			potential_immigration,
			migration_capacity
		)


		# ====================================================
		# CAPACITY USAGE
		# ====================================================

		var capacity_used = 0.0


		if migration_capacity > 0.0:

			capacity_used = (
				actual_immigration
				/ migration_capacity
			)


		# ====================================================
		# ACTUAL EMIGRATION
		# ====================================================

		var actual_emigration = (
			potential_emigration
		)


		# ====================================================
		# NET MIGRATION
		# ====================================================

		var net_migration = (
			actual_immigration
			- actual_emigration
		)


		# ====================================================
		# SAVE RESULTS
		# ====================================================

		population.set_state(
			"immigration",
			actual_immigration
		)

		population.set_state(
			"emigration",
			actual_emigration
		)

		population.set_state(
			"net_migration",
			net_migration
		)

		population.set_state(
			"migration_pressure",
			unemployment_pressure
		)

		population.set_state(
			"migration_capacity_used",
			capacity_used
		)

		population.set_state(
			"economic_attractiveness",
			economic_attractiveness
		)

		population.set_state(
			"world_average_gdp_per_capita",
			world_average_gdp_per_capita
		)
