class_name MilitaryResourceDemandSystem
extends SimulationSystem


# ================================================================
# STEP 13.6 — MILITARY DEMAND → RESOURCE CONSUMPTION
# ================================================================
#
# Derived bridge only.
#
# Authority remains:
#   MilitaryComponent
#       -> military activity / spending / force structure
#   ResourceComponent
#       -> authoritative resource demand / consumption ledger
#   AggregateDemandSystem
#       -> aggregate demand reconciliation
#   AggregateConsumptionSystem
#       -> domestic consumption request
#   ResourceSystem
#       -> physical monthly resource settlement
#
# This system does not directly subtract stockpile, reserves, or
# consumption. It creates the already-established
# ResourceComponent.military_resource_demand input so the existing
# resource demand/consumption pipeline carries the consequence.
#
# Strategic abstraction only. No unit-level ammunition, fuel, vehicles,
# formations, tactical supply chains, or battlefield logistics are added.
# ================================================================


const RESOURCE_DEMAND_COEFFICIENTS: Dictionary = {
	"coal": 4.0,
	"iron": 3.0,
	"oil": 5.0
}

const PEACETIME_WAR_MULTIPLIER: float = 1.0
const WAR_ACTIVITY_MULTIPLIER: float = 1.50


func _init() -> void:
	super("military_resource_demand_system")


func process_month(world: WorldState) -> void:
	if world == null:
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var military: MilitaryComponent = entity.get_component(
			"military"
		)
		var resources: ResourceComponent = entity.get_component(
			"resources"
		)

		if military == null or resources == null:
			continue

		_update_entity(
			military,
			resources
		)


func _update_entity(
	military: MilitaryComponent,
	resources: ResourceComponent
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

	var army_strength: float = clampf(
		float(
			military.get_state(
				"army_strength",
				0.50
			)
		),
		0.0,
		1.0
	)

	var naval_strength: float = clampf(
		float(
			military.get_state(
				"naval_strength",
				0.30
			)
		),
		0.0,
		1.0
	)

	var air_strength: float = clampf(
		float(
			military.get_state(
				"air_strength",
				0.20
			)
		),
		0.0,
		1.0
	)

	var logistics_capacity: float = clampf(
		float(
			military.get_state(
				"logistics_capacity",
				0.50
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

	# Aggregate strategic military activity signal.
	# Spending provides the main budgetary driver; force structure and
	# logistics provide bounded operational support demand.
	var force_index: float = (
		army_strength
		+ naval_strength
		+ air_strength
	) / 3.0

	var activity_index: float = clampf(
		0.55 * military_spending
		+ 0.25 * force_index
		+ 0.20 * logistics_capacity,
		0.0,
		1.0
	)

	var war_multiplier: float = (
		WAR_ACTIVITY_MULTIPLIER
		if at_war
		else PEACETIME_WAR_MULTIPLIER
	)

	var effective_activity: float = clampf(
		activity_index * war_multiplier,
		0.0,
		1.50
	)

	var demand_by_resource: Dictionary = {}
	var total_demand: float = 0.0

	for resource_id in RESOURCE_DEMAND_COEFFICIENTS.keys():
		var coefficient: float = maxf(
			0.0,
			float(RESOURCE_DEMAND_COEFFICIENTS[resource_id])
		)

		var demand: float = maxf(
			0.0,
			coefficient * effective_activity
		)

		demand_by_resource[str(resource_id)] = demand
		total_demand += demand

	# ------------------------------------------------------------
	# Military diagnostics
	# ------------------------------------------------------------
	military.set_state(
		"resource_demand_activity_index",
		effective_activity
	)
	military.set_state(
		"resource_demand_war_multiplier",
		war_multiplier
	)
	military.set_state(
		"resource_demand_total",
		total_demand
	)
	military.set_state(
		"resource_demand_by_resource",
		demand_by_resource
	)
	military.set_state(
		"resource_demand_source",
		"MilitaryResourceDemandSystem"
	)

	# ------------------------------------------------------------
	# Existing ResourceComponent demand authority
	# ------------------------------------------------------------
	# This is a demand signal only. AggregateDemandSystem and
	# AggregateConsumptionSystem remain responsible for turning it into
	# aggregate demand and domestic consumption; ResourceSystem remains
	# responsible for the physical stock/reserve settlement.
	resources.set_state(
		"military_resource_demand",
		demand_by_resource
	)
