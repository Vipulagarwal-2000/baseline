class_name LaborSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	if world == null or simulation == null:
		return false

	var labor_system = simulation.get_system(
		"labor_system"
	)

	passed = _check(
		labor_system != null,
		"Labor System registered"
	) and passed

	if labor_system == null:
		return false

	passed = _check(
		labor_system is LaborSystem,
		"Labor System type"
	) and passed

	var india = world.get_entity(
		"india"
	)

	passed = _check(
		india != null,
		"India available"
	) and passed

	if india == null:
		return false

	var population = india.get_component(
		"population"
	)

	var economy = india.get_component(
		"economy"
	)

	passed = _check(
		population != null,
		"India PopulationComponent"
	) and passed

	passed = _check(
		economy != null,
		"India EconomyComponent"
	) and passed

	if population == null or economy == null:
		return false

	var original_population = population.get_state(
		"population",
		0.0
	)

	var original_working_age_share = population.get_state(
		"working_age_share",
		0.60
	)

	var original_participation_rate = population.get_state(
		"labor_force_participation_rate",
		0.65
	)

	var original_skilled_share = population.get_state(
		"skilled_labor_share",
		0.20
	)

	var original_productivity = population.get_state(
		"labor_productivity",
		1.0
	)

	var original_unemployment = economy.get_state(
		"unemployment",
		0.0
	)

	var original_labor_state = population.get_state(
		"labor_state",
		{}
	)

	population.set_state(
		"population",
		1000.0
	)

	population.set_state(
		"working_age_share",
		0.60
	)

	population.set_state(
		"labor_force_participation_rate",
		0.65
	)

	population.set_state(
		"skilled_labor_share",
		0.20
	)

	population.set_state(
		"labor_productivity",
		1.0
	)

	economy.set_state(
		"unemployment",
		0.10
	)

	labor_system.process_month(
		world
	)

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"working_age_population",
					-1.0
				)
			),
			600.0
		),
		"Working-age population = 600"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"labor_force",
					-1.0
				)
			),
			390.0
		),
		"Labor force = 390"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"unemployed_labor",
					-1.0
				)
			),
			39.0
		),
		"Unemployed labor = 39"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"employed_labor",
					-1.0
				)
			),
			351.0
		),
		"Employed labor = 351"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"skilled_labor",
					-1.0
				)
			),
			70.2
		),
		"Skilled labor = 70.2"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				population.get_state(
					"unskilled_labor",
					-1.0
				)
			),
			280.8
		),
		"Unskilled labor = 280.8"
	) and passed

	passed = _check(
		is_equal_approx(
			labor_system.get_effective_labor_capacity(
				india
			),
			351.0
		),
		"Effective labor capacity = employed labor at productivity 1"
	) and passed

	passed = _check(
		is_equal_approx(
			labor_system.get_effective_skilled_labor_capacity(
				india
			),
			70.2
		),
		"Effective skilled labor capacity = skilled labor at productivity 1"
	) and passed

	population.set_state(
		"labor_productivity",
		0.80
	)

	labor_system.process_month(
		world
	)

	passed = _check(
		is_equal_approx(
			labor_system.get_effective_labor_capacity(
				india
			),
			280.8
		),
		"Labor productivity scales effective labor capacity"
	) and passed

	population.set_state(
		"population",
		original_population
	)

	population.set_state(
		"working_age_share",
		original_working_age_share
	)

	population.set_state(
		"labor_force_participation_rate",
		original_participation_rate
	)

	population.set_state(
		"skilled_labor_share",
		original_skilled_share
	)

	population.set_state(
		"labor_productivity",
		original_productivity
	)

	population.set_state(
		"labor_state",
		original_labor_state
	)

	economy.set_state(
		"unemployment",
		original_unemployment
	)

	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:

	print(
		"Labor System ",
		label,
		": ",
		"PASS" if condition else "FAIL"
	)

	return condition
