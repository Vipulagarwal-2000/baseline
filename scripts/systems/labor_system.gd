class_name LaborSystem
extends SimulationSystem


const DEFAULT_WORKING_AGE_SHARE := 0.60
const DEFAULT_LABOR_FORCE_PARTICIPATION_RATE := 0.65
const DEFAULT_SKILLED_LABOR_SHARE := 0.20
const DEFAULT_LABOR_PRODUCTIVITY := 1.0


func _init() -> void:
	super("labor_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"LaborSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_update_entity(
			entity
		)


func get_labor_state(
	entity
) -> Dictionary:

	if entity == null:
		return {}

	var population = entity.get_component(
		"population"
	)

	if population == null:
		return {}

	var state = population.get_state(
		"labor_state",
		{}
	)

	if typeof(state) != TYPE_DICTIONARY:
		return {}

	return state


func get_effective_labor_capacity(
	entity
) -> float:

	var labor_state = get_labor_state(
		entity
	)

	return maxf(
		float(
			labor_state.get(
				"effective_labor_capacity",
				0.0
			)
		),
		0.0
	)


func get_effective_skilled_labor_capacity(
	entity
) -> float:

	var labor_state = get_labor_state(
		entity
	)

	return maxf(
		float(
			labor_state.get(
				"effective_skilled_labor_capacity",
				0.0
			)
		),
		0.0
	)


func _update_entity(
	entity
) -> void:

	var population = entity.get_component(
		"population"
	)

	var economy = entity.get_component(
		"economy"
	)

	if population == null:
		return

	var total_population := maxf(
		float(
			population.get_state(
				"population",
				0.0
			)
		),
		0.0
	)

	var working_age_share := clampf(
		float(
			population.get_state(
				"working_age_share",
				DEFAULT_WORKING_AGE_SHARE
			)
		),
		0.0,
		1.0
	)

	var participation_rate := clampf(
		float(
			population.get_state(
				"labor_force_participation_rate",
				DEFAULT_LABOR_FORCE_PARTICIPATION_RATE
			)
		),
		0.0,
		1.0
	)

	var skilled_share := clampf(
		float(
			population.get_state(
				"skilled_labor_share",
				DEFAULT_SKILLED_LABOR_SHARE
			)
		),
		0.0,
		1.0
	)

	var labor_productivity := maxf(
		float(
			population.get_state(
				"labor_productivity",
				DEFAULT_LABOR_PRODUCTIVITY
			)
		),
		0.0
	)

	var unemployment_rate := 0.0

	if economy != null:
		unemployment_rate = clampf(
			float(
				economy.get_state(
					"unemployment",
					0.0
				)
			),
			0.0,
			1.0
		)

	var working_age_population := (
		total_population
		* working_age_share
	)

	var labor_force := (
		working_age_population
		* participation_rate
	)

	var unemployed_labor := (
		labor_force
		* unemployment_rate
	)

	var employed_labor := maxf(
		labor_force
		- unemployed_labor,
		0.0
	)

	var skilled_labor := (
		employed_labor
		* skilled_share
	)

	var unskilled_labor := maxf(
		employed_labor
		- skilled_labor,
		0.0
	)

	var effective_labor_capacity := (
		employed_labor
		* labor_productivity
	)

	var effective_skilled_labor_capacity := (
		skilled_labor
		* labor_productivity
	)

	population.set_state(
		"working_age_population",
		working_age_population
	)

	population.set_state(
		"labor_force",
		labor_force
	)

	population.set_state(
		"unemployed_labor",
		unemployed_labor
	)

	population.set_state(
		"employed_labor",
		employed_labor
	)

	population.set_state(
		"skilled_labor",
		skilled_labor
	)

	population.set_state(
		"unskilled_labor",
		unskilled_labor
	)

	population.set_state(
		"effective_labor_capacity",
		effective_labor_capacity
	)

	population.set_state(
		"effective_skilled_labor_capacity",
		effective_skilled_labor_capacity
	)

	population.set_state(
		"labor_state",
		{
			"total_population": total_population,
			"working_age_population": working_age_population,
			"labor_force": labor_force,
			"unemployed_labor": unemployed_labor,
			"employed_labor": employed_labor,
			"skilled_labor": skilled_labor,
			"unskilled_labor": unskilled_labor,
			"labor_productivity": labor_productivity,
			"effective_labor_capacity": effective_labor_capacity,
			"effective_skilled_labor_capacity": effective_skilled_labor_capacity,
			"working_age_share": working_age_share,
			"labor_force_participation_rate": participation_rate,
			"skilled_labor_share": skilled_share,
			"unemployment_rate": unemployment_rate
		}
	)
