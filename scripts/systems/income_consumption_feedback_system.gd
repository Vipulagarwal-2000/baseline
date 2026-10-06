class_name IncomeConsumptionFeedbackSystem
extends SimulationSystem


# ============================================================
# POPULATION — STEP 9.3
# INCOME -> PURCHASING POWER -> CONSUMPTION FEEDBACK
# ============================================================
#
# This is a small reverse-loop bridge over the already verified
# income/wage and purchasing-power systems.
#
# Existing upstream chain:
# production -> labor income -> purchasing power
#
# This system derives a bounded population-consumption factor from:
# - income_coverage_ratio
# - purchasing_power_index
#
# The factor is written to EconomyComponent and consumed by the
# next AggregateDemandSystem cycle. It never creates demand above
# the existing baseline population demand.
#
# Bounded MVP rule:
#
# consumption factor = min(
#     clamp(income coverage ratio, 0..1),
#     clamp(purchasing-power index, 0..1)
# )
#
# When no population consumption basket exists, the factor remains
# neutral at 1.0 rather than inventing a new affordability penalty.
# ============================================================


const EPSILON: float = 0.000001
const DEFAULT_NEUTRAL_FACTOR: float = 1.0


func _init() -> void:
	super("income_consumption_feedback_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"IncomeConsumptionFeedbackSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var economy = entity.get_component(
			"economy"
		)

		if economy == null:
			continue

		_process_entity(
			economy
		)


func _process_entity(
	economy
) -> void:

	var population_consumption_cost := maxf(
		float(
			economy.get_state(
				"population_consumption_cost",
				0.0
			)
		),
		0.0
	)

	var income_coverage_ratio := clampf(
		maxf(
			float(
				economy.get_state(
					"income_coverage_ratio",
					1.0
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var purchasing_power_index := clampf(
		maxf(
			float(
				economy.get_state(
					"purchasing_power_index",
					1.0
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var consumption_factor := DEFAULT_NEUTRAL_FACTOR

	if population_consumption_cost > EPSILON:
		consumption_factor = minf(
			income_coverage_ratio,
			purchasing_power_index
		)

	consumption_factor = clampf(
		consumption_factor,
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"population_consumption_cost": population_consumption_cost,
		"income_coverage_ratio": income_coverage_ratio,
		"purchasing_power_index": purchasing_power_index,
		"consumption_demand_factor": consumption_factor,
		"neutral_without_consumption_basket": population_consumption_cost <= EPSILON
	}

	var current_factor := clampf(
		float(
			economy.get_state(
				"population_consumption_demand_factor",
				DEFAULT_NEUTRAL_FACTOR
			)
		),
		0.0,
		1.0
	)

	var unchanged := is_equal_approx(
		current_factor,
		consumption_factor
	)

	if unchanged:
		economy.set_state(
			"population_consumption_feedback_ledger",
			ledger
		)

		economy.set_state(
			"population_consumption_feedback_last_result",
			{
				"action": "no_change",
				"revision": int(
					economy.get_state(
						"population_consumption_feedback_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)
		return

	var revision := int(
		economy.get_state(
			"population_consumption_feedback_revision",
			0
		)
	) + 1

	economy.set_state(
		"population_consumption_demand_factor",
		consumption_factor
	)

	economy.set_state(
		"population_consumption_feedback_revision",
		revision
	)

	economy.set_state(
		"population_consumption_feedback_ledger",
		ledger
	)

	economy.set_state(
		"population_consumption_feedback_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)
