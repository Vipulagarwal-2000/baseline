class_name EconomicPressurePoliticalFeedbackSystem
extends SimulationSystem


# ============================================================
# POPULATION — STEP 9.4
# ECONOMIC PRESSURE -> POLITICAL PRESSURE
# ============================================================
#
# Converts the already-derived aggregate economic/social pressure
# signals into a bounded political-pressure contribution.
#
# Existing inputs:
#   EconomyComponent.economic_pressure
#   PopulationComponent.welfare_pressure
#
# The stronger of those two normalized pressure signals represents
# severe economic/social pressure.
#
# MVP rule:
#
#   social_economic_pressure =
#       max(economic_pressure, welfare_pressure)
#
#   political_pressure_contribution =
#       social_economic_pressure * 0.50
#
#   political_pressure =
#       max(existing political_pressure,
#           political_pressure_contribution)
#
# The contribution therefore raises political pressure when severe
# hardship warrants it, while never erasing pressure already produced
# by other government mechanisms.
#
# This step deliberately does NOT:
# - modify approval
# - modify stability
# - modify legitimacy
# - select or execute policies
# - simulate individual citizens
# - create another economic-pressure model
#
# It owns only its derived audit state. GovernmentComponent remains
# the authoritative owner of the canonical political_pressure field.
#
# The result is deterministic and idempotent for repeated processing
# with unchanged upstream inputs.
# ============================================================


const POLITICAL_PRESSURE_WEIGHT: float = 0.50


func _init() -> void:
	super("economic_pressure_political_feedback_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"EconomicPressurePoliticalFeedbackSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(
			entity
		)


func _process_entity(
	entity
) -> void:

	var economy = entity.get_component(
		"economy"
	)
	var population = entity.get_component(
		"population"
	)
	var government = entity.get_component(
		"government"
	)

	if (
		economy == null
		or population == null
		or government == null
	):
		return

	var economic_pressure: float = clampf(
		float(
			economy.get_state(
				"economic_pressure",
				0.0
			)
		),
		0.0,
		1.0
	)

	var welfare_pressure: float = clampf(
		float(
			population.get_state(
				"welfare_pressure",
				0.0
			)
		),
		0.0,
		1.0
	)

	var social_economic_pressure: float = maxf(
		economic_pressure,
		welfare_pressure
	)

	var political_pressure_contribution: float = clampf(
		social_economic_pressure
			* POLITICAL_PRESSURE_WEIGHT,
		0.0,
		1.0
	)

	var current_political_pressure: float = clampf(
		float(
			government.get_state(
				"political_pressure",
				0.0
			)
		),
		0.0,
		1.0
	)

	# Existing pressure from other political/government mechanisms is
	# preserved. Step 9.4 only adds a hardship-derived floor.
	var resulting_political_pressure: float = clampf(
		maxf(
			current_political_pressure,
			political_pressure_contribution
		),
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"economic_pressure": economic_pressure,
		"welfare_pressure": welfare_pressure,
		"social_economic_pressure": social_economic_pressure,
		"political_pressure_weight": POLITICAL_PRESSURE_WEIGHT,
		"political_pressure_contribution": political_pressure_contribution,
		"existing_political_pressure": current_political_pressure,
		"resulting_political_pressure": resulting_political_pressure
	}

	var current_signal: float = clampf(
		float(
			government.get_state(
				"economic_political_pressure",
				0.0
			)
		),
		0.0,
		1.0
	)

	var unchanged: bool = (
		is_equal_approx(
			current_signal,
			political_pressure_contribution
		)
		and is_equal_approx(
			current_political_pressure,
			resulting_political_pressure
		)
	)

	if unchanged:

		government.set_state(
			"economic_political_pressure_ledger",
			ledger
		)

		government.set_state(
			"economic_political_pressure_last_result",
			{
				"action": "no_change",
				"revision": int(
					government.get_state(
						"economic_political_pressure_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)

		return

	var revision: int = int(
		government.get_state(
			"economic_political_pressure_revision",
			0
		)
	) + 1

	government.set_state(
		"economic_political_pressure",
		political_pressure_contribution
	)

	government.set_state(
		"political_pressure",
		resulting_political_pressure
	)

	government.set_state(
		"economic_political_pressure_revision",
		revision
	)

	government.set_state(
		"economic_political_pressure_ledger",
		ledger
	)

	government.set_state(
		"economic_political_pressure_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)
