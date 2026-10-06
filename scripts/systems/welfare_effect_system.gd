class_name WelfareEffectSystem
extends SimulationSystem


# ============================================================
# POPULATION — STEP 9.2
# WELFARE EFFECT
# ============================================================
#
# Converts the already-derived Standard of Living index into
# two aggregate welfare signals:
#
#   standard of living
#          ↓
#   welfare effect (signed)
#   welfare pressure (hardship)
#
# This is intentionally a bridge layer only.
#
# It does NOT:
# - modify the StandardOfLiving index
# - modify government approval
# - modify political pressure
# - modify population growth
# - simulate individual citizens
#
# Those downstream consequences belong to later Step 9 stages.
#
# Neutral reference:
#   standard_of_living_index = 0.50
#
# Derived signals:
#   welfare_effect   = living_index - 0.50
#                      bounded to [-0.50, +0.50]
#
#   welfare_pressure  = 1.0 - living_index
#                      bounded to [0.0, 1.0]
#
# The system is deterministic and idempotent.
# ============================================================


const EPSILON: float = 0.000001
const NEUTRAL_STANDARD_OF_LIVING: float = 0.5


func _init() -> void:
	super("welfare_effect_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"WelfareEffectSystem: World is null."
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

	var standard_of_living_variant: Variant = (
		population.get_state(
			"standard_of_living_index",
			NEUTRAL_STANDARD_OF_LIVING
		)
	)

	var standard_of_living: float = NEUTRAL_STANDARD_OF_LIVING

	if (
		standard_of_living_variant is int
		or standard_of_living_variant is float
	):
		standard_of_living = clampf(
			float(standard_of_living_variant),
			0.0,
			1.0
		)

	var welfare_effect: float = clampf(
		standard_of_living
			- NEUTRAL_STANDARD_OF_LIVING,
		-NEUTRAL_STANDARD_OF_LIVING,
		NEUTRAL_STANDARD_OF_LIVING
	)

	var welfare_pressure: float = clampf(
		1.0 - standard_of_living,
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"standard_of_living_index": standard_of_living,
		"neutral_standard_of_living": NEUTRAL_STANDARD_OF_LIVING,
		"welfare_effect": welfare_effect,
		"welfare_pressure": welfare_pressure
	}

	var current_effect: float = float(
		population.get_state(
			"welfare_effect",
			0.0
		)
	)

	var current_pressure: float = float(
		population.get_state(
			"welfare_pressure",
			0.0
		)
	)

	var unchanged: bool = (
		is_equal_approx(
			current_effect,
			welfare_effect
		)
		and is_equal_approx(
			current_pressure,
			welfare_pressure
		)
	)

	if unchanged:

		population.set_state(
			"welfare_ledger",
			ledger
		)

		population.set_state(
			"welfare_last_result",
			{
				"action": "no_change",
				"revision": int(
					population.get_state(
						"welfare_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)

		return

	var revision: int = int(
		population.get_state(
			"welfare_revision",
			0
		)
	) + 1

	population.set_state(
		"welfare_effect",
		welfare_effect
	)

	population.set_state(
		"welfare_pressure",
		welfare_pressure
	)

	population.set_state(
		"welfare_revision",
		revision
	)

	population.set_state(
		"welfare_ledger",
		ledger
	)

	population.set_state(
		"welfare_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)
