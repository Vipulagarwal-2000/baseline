class_name BasicPopulationResponseSystem
extends SimulationSystem


# ============================================================
# POPULATION — STEP 9.5
# BASIC POPULATION RESPONSE
# ============================================================
#
# Aggregate response layer only.
#
# Inputs already owned by earlier systems:
# - PopulationComponent.welfare_pressure
# - GovernmentComponent.political_pressure
# - PopulationComponent.labor_force_participation_rate
#
# Outputs are broad response signals only:
# - migration_pressure
# - fertility_rate_modifier
# - mortality_rate_modifier
# - labor_participation_modifier
# - labor_participation_target
#
# This first implementation deliberately DOES NOT mutate:
# - birth_rate
# - death_rate
# - immigration
# - emigration
# - labor_force_participation_rate
#
# Those authoritative demographic/labor values remain owned by their
# existing systems. Step 9.5 therefore produces a deterministic,
# aggregate response state that later systems can consume without
# introducing a second population model.
#
# Implementation assumption where the master does not prescribe exact
# coefficients:
#
# response_pressure = max(welfare_pressure, political_pressure)
#
# fertility modifier    = 1.0 - 0.20 * response pressure
# mortality modifier    = 1.0 + 0.20 * response pressure
# labor modifier        = 1.0 - 0.10 * response pressure
# migration pressure    = response pressure
#
# All outputs are bounded and deterministic.
# ============================================================


const EPSILON: float = 0.000001
const DEFAULT_NEUTRAL_PRESSURE: float = 0.0
const FERTILITY_RESPONSE_COEFFICIENT: float = 0.20
const MORTALITY_RESPONSE_COEFFICIENT: float = 0.20
const LABOR_RESPONSE_COEFFICIENT: float = 0.10


func _init() -> void:
	super("basic_population_response_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"BasicPopulationResponseSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(entity)


func _process_entity(
	entity
) -> void:

	var population = entity.get_component(
		"population"
	)

	if population == null:
		return

	var government = entity.get_component(
		"government"
	)

	var welfare_pressure := clampf(
		maxf(
			float(
				population.get_state(
					"welfare_pressure",
					DEFAULT_NEUTRAL_PRESSURE
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var political_pressure := 0.0

	if government != null:
		political_pressure = clampf(
			maxf(
				float(
					government.get_state(
						"political_pressure",
						0.0
					)
				),
				0.0
			),
			0.0,
			1.0
		)

	var response_pressure := maxf(
		welfare_pressure,
		political_pressure
	)

	response_pressure = clampf(
		response_pressure,
		0.0,
		1.0
	)

	var migration_pressure := response_pressure

	var fertility_rate_modifier := clampf(
		1.0
		- (
			FERTILITY_RESPONSE_COEFFICIENT
			* response_pressure
		),
		0.80,
		1.0
	)

	var mortality_rate_modifier := clampf(
		1.0
		+ (
			MORTALITY_RESPONSE_COEFFICIENT
			* response_pressure
		),
		1.0,
		1.20
	)

	var labor_participation_modifier := clampf(
		1.0
		- (
			LABOR_RESPONSE_COEFFICIENT
			* response_pressure
		),
		0.90,
		1.0
	)

	var base_participation_rate := clampf(
		float(
			population.get_state(
				"labor_force_participation_rate",
				0.65
			)
		),
		0.0,
		1.0
	)

	var labor_participation_target := clampf(
		base_participation_rate
		* labor_participation_modifier,
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"welfare_pressure": welfare_pressure,
		"political_pressure": political_pressure,
		"response_pressure": response_pressure,
		"migration_pressure": migration_pressure,
		"fertility_rate_modifier": fertility_rate_modifier,
		"mortality_rate_modifier": mortality_rate_modifier,
		"labor_participation_modifier": labor_participation_modifier,
		"base_labor_force_participation_rate": base_participation_rate,
		"labor_participation_target": labor_participation_target,
		"coefficients": {
			"fertility": FERTILITY_RESPONSE_COEFFICIENT,
			"mortality": MORTALITY_RESPONSE_COEFFICIENT,
			"labor_participation": LABOR_RESPONSE_COEFFICIENT
		}
	}

	var current_response_pressure := clampf(
		float(
			population.get_state(
				"population_response_pressure",
				DEFAULT_NEUTRAL_PRESSURE
			)
		),
		0.0,
		1.0
	)

	var unchanged := is_equal_approx(
		current_response_pressure,
		response_pressure
	)

	population.set_state(
		"migration_pressure",
		migration_pressure
	)

	population.set_state(
		"fertility_rate_modifier",
		fertility_rate_modifier
	)

	population.set_state(
		"mortality_rate_modifier",
		mortality_rate_modifier
	)

	population.set_state(
		"labor_participation_modifier",
		labor_participation_modifier
	)

	population.set_state(
		"labor_participation_target",
		labor_participation_target
	)

	population.set_state(
		"population_response_pressure",
		response_pressure
	)

	population.set_state(
		"population_response_ledger",
		ledger
	)

	if unchanged:
		population.set_state(
			"population_response_last_result",
			{
				"action": "no_change",
				"revision": int(
					population.get_state(
						"population_response_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)
		return

	var revision := int(
		population.get_state(
			"population_response_revision",
			0
		)
	) + 1

	population.set_state(
		"population_response_revision",
		revision
	)

	population.set_state(
		"population_response_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)
