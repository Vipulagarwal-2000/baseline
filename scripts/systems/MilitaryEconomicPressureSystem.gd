class_name MilitaryEconomicPressureSystem
extends SimulationSystem


# ================================================================
# STEP 13.7 — MILITARY STATE → ECONOMIC PRESSURE
# ================================================================
#
# Derived bridge only.
#
# Authority remains:
#   MilitaryComponent
#       -> authoritative military spending / pressure / war-exhaustion state
#   EconomyComponent
#       -> authoritative country-level economic-pressure state
#
# This system translates the existing strategic military burden into an
# explicit economic-pressure contribution. It does not recalculate GDP,
# inflation, unemployment, treasury, debt, or military state.
#
# Resource-shortage economic pressure is already produced by EconomySystem.
# To avoid double-counting, the existing economic pressure is preserved
# whenever it is already higher than the military-derived pressure.
#
# Strategic abstraction only. No tactical combat or unit-level cost model.
# ================================================================


const MILITARY_SPENDING_WEIGHT: float = 0.45
const MILITARY_PRESSURE_WEIGHT: float = 0.25
const WAR_EXHAUSTION_WEIGHT: float = 0.20
const WAR_STATE_WEIGHT: float = 0.10

# Military pressure is an input to, rather than a replacement for,
# existing economic pressure. This coefficient keeps the bridge bounded
# and prevents the military signal from dominating the economy model.
const MILITARY_ECONOMIC_PRESSURE_FACTOR: float = 0.60


func _init() -> void:
	super("military_economic_pressure_system")


func process_month(world: WorldState) -> void:
	if world == null:
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var military: MilitaryComponent = entity.get_component(
			"military"
		)
		var economy: EconomyComponent = entity.get_component(
			"economy"
		)

		if military == null or economy == null:
			continue

		_update_entity(
			military,
			economy
		)


func _update_entity(
	military: MilitaryComponent,
	economy: EconomyComponent
) -> void:

	var military_spending: float = clampf(
		float(
			military.get_state(
				"military_spending",
				0.30
			)
		),
		0.0,
		1.0
	)

	var military_pressure: float = clampf(
		float(
			military.get_state(
				"military_pressure",
				0.20
			)
		),
		0.0,
		1.0
	)

	var war_exhaustion: float = clampf(
		float(
			military.get_state(
				"war_exhaustion",
				0.0
			)
		),
		0.0,
		1.0
	)

	var at_war: bool = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	var war_state_factor: float = (
		1.0
		if at_war
		else 0.0
	)

	var military_burden: float = clampf(
		military_spending * MILITARY_SPENDING_WEIGHT
		+ military_pressure * MILITARY_PRESSURE_WEIGHT
		+ war_exhaustion * WAR_EXHAUSTION_WEIGHT
		+ war_state_factor * WAR_STATE_WEIGHT,
		0.0,
		1.0
	)

	var military_economic_pressure: float = clampf(
		military_burden * MILITARY_ECONOMIC_PRESSURE_FACTOR,
		0.0,
		1.0
	)

	var existing_economic_pressure: float = clampf(
		float(
			economy.get_state(
				"economic_pressure",
				0.0
			)
		),
		0.0,
		1.0
	)

	# Preserve stronger pre-existing economic pressure. The military bridge
	# adds a competing causal source without summing independent pressure
	# percentages and thereby inflating the normalized state.
	var combined_economic_pressure: float = clampf(
		maxf(
			existing_economic_pressure,
			military_economic_pressure
		),
		0.0,
		1.0
	)

	military.set_state(
		"military_economic_burden",
		military_burden
	)

	military.set_state(
		"military_economic_pressure",
		military_economic_pressure
	)

	military.set_state(
		"military_economic_pressure_source",
		"MilitaryEconomicPressureSystem"
	)

	economy.set_state(
		"military_economic_pressure",
		military_economic_pressure
	)

	economy.set_state(
		"military_economic_burden",
		military_burden
	)

	economy.set_state(
		"economic_pressure_without_military",
		existing_economic_pressure
	)

	economy.set_state(
		"economic_pressure",
		combined_economic_pressure
	)

	economy.set_state(
		"military_economic_pressure_source",
		"MilitaryEconomicPressureSystem"
	)
