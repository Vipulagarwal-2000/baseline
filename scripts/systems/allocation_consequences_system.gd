class_name AllocationConsequencesSystem
extends SimulationSystem


const DOMESTIC_CATEGORIES: Array[String] = [
	"population",
	"industry",
	"government",
	"military"
]

const EPSILON: float = 0.000001


func _init() -> void:
	super("allocation_consequences_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"AllocationConsequencesSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var resources = entity.get_component(
			"resources"
		)

		if resources == null:
			continue

		_process_entity(
			resources
		)


func _process_entity(
	resources: ResourceComponent
) -> void:

	var allocated_value = resources.get_state(
		"priority_allocated_supply_by_category",
		{}
	)
	var unmet_value = resources.get_state(
		"priority_allocation_unmet_by_category",
		{}
	)
	var fulfillment_value = resources.get_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{}
	)
	var shortfall_value = resources.get_state(
		"priority_allocation_shortfall_ratio_by_category",
		{}
	)
	var remaining_value = resources.get_state(
		"priority_allocation_remaining_supply",
		{}
	)
	var exhausted_value = resources.get_state(
		"priority_allocation_exhausted",
		{}
	)

	var source_active: bool = (
		(
			typeof(allocated_value) == TYPE_DICTIONARY
			and not allocated_value.is_empty()
		)
		or
		(
			typeof(unmet_value) == TYPE_DICTIONARY
			and not unmet_value.is_empty()
		)
		or
		(
			typeof(fulfillment_value) == TYPE_DICTIONARY
			and not fulfillment_value.is_empty()
		)
		or
		(
			typeof(remaining_value) == TYPE_DICTIONARY
			and not remaining_value.is_empty()
		)
	)

	if not source_active:

		_clear_state(
			resources
		)
		return

	var allocated: Dictionary = {}
	var unmet: Dictionary = {}
	var fulfillment: Dictionary = {}
	var shortfall: Dictionary = {}
	var remaining: Dictionary = {}
	var exhausted: Dictionary = {}

	if typeof(allocated_value) == TYPE_DICTIONARY:
		allocated = allocated_value

	if typeof(unmet_value) == TYPE_DICTIONARY:
		unmet = unmet_value

	if typeof(fulfillment_value) == TYPE_DICTIONARY:
		fulfillment = fulfillment_value

	if typeof(shortfall_value) == TYPE_DICTIONARY:
		shortfall = shortfall_value

	if typeof(remaining_value) == TYPE_DICTIONARY:
		remaining = remaining_value

	if typeof(exhausted_value) == TYPE_DICTIONARY:
		exhausted = exhausted_value

	var resource_names: Dictionary = {}

	_collect_keys(resource_names, allocated)
	_collect_keys(resource_names, unmet)
	_collect_keys(resource_names, fulfillment)
	_collect_keys(resource_names, remaining)

	var domestic_accessible_supply_value = resources.get_state(
		"domestic_accessible_supply",
		{}
	)
	var domestic_accessible_supply: Dictionary = {}

	if typeof(domestic_accessible_supply_value) == TYPE_DICTIONARY:
		domestic_accessible_supply = domestic_accessible_supply_value

	var allocated_out: Dictionary = {}
	var unmet_out: Dictionary = {}
	var fulfillment_out: Dictionary = {}
	var shortfall_out: Dictionary = {}
	var remaining_out: Dictionary = {}
	var exhausted_out: Dictionary = {}
	var total_allocated: Dictionary = {}
	var total_unmet: Dictionary = {}
	var reconciliation_errors: Dictionary = {}
	var ledger: Dictionary = {}

	var population_ratio: Dictionary = {}
	var critical_production_ratio: Dictionary = {}
	var government_ratio: Dictionary = {}
	var military_ratio: Dictionary = {}

	for resource_name_value in resource_names.keys():

		var resource_id := str(
			resource_name_value
		)

		var source_allocated_value = allocated.get(
			resource_id,
			{}
		)
		var source_unmet_value = unmet.get(
			resource_id,
			{}
		)
		var source_fulfillment_value = fulfillment.get(
			resource_id,
			{}
		)
		var source_shortfall_value = shortfall.get(
			resource_id,
			{}
		)

		var source_allocated: Dictionary = {}
		var source_unmet: Dictionary = {}
		var source_fulfillment: Dictionary = {}
		var source_shortfall: Dictionary = {}

		if typeof(source_allocated_value) == TYPE_DICTIONARY:
			source_allocated = source_allocated_value

		if typeof(source_unmet_value) == TYPE_DICTIONARY:
			source_unmet = source_unmet_value

		if typeof(source_fulfillment_value) == TYPE_DICTIONARY:
			source_fulfillment = source_fulfillment_value

		if typeof(source_shortfall_value) == TYPE_DICTIONARY:
			source_shortfall = source_shortfall_value

		var resource_allocated: Dictionary = {}
		var resource_unmet: Dictionary = {}
		var resource_fulfillment: Dictionary = {}
		var resource_shortfall: Dictionary = {}

		var total_claim := 0.0
		var total_resource_allocated := 0.0
		var total_resource_unmet := 0.0

		for category in DOMESTIC_CATEGORIES:

			var allocated_quantity := maxf(
				float(
					source_allocated.get(
						category,
						0.0
					)
				),
				0.0
			)

			var unmet_quantity := maxf(
				float(
					source_unmet.get(
						category,
						0.0
					)
				),
				0.0
			)

			var claim := (
				allocated_quantity
				+ unmet_quantity
			)

			var fulfillment_ratio := 1.0
			var shortfall_ratio := 0.0

			if source_fulfillment.has(category):

				fulfillment_ratio = clampf(
					float(
						source_fulfillment.get(
							category,
							1.0
						)
					),
					0.0,
					1.0
				)

			elif claim > EPSILON:

				fulfillment_ratio = clampf(
					allocated_quantity / claim,
					0.0,
					1.0
				)

			if source_shortfall.has(category):

				shortfall_ratio = clampf(
					float(
						source_shortfall.get(
							category,
							0.0
						)
					),
					0.0,
					1.0
				)

			else:

				shortfall_ratio = clampf(
					1.0 - fulfillment_ratio,
					0.0,
					1.0
				)

			if claim > EPSILON:

				resource_allocated[category] = (
					allocated_quantity
				)
				resource_unmet[category] = (
					unmet_quantity
				)
				resource_fulfillment[category] = (
					fulfillment_ratio
				)
				resource_shortfall[category] = (
					shortfall_ratio
				)

				total_claim += claim
				total_resource_allocated += (
					allocated_quantity
				)
				total_resource_unmet += (
					unmet_quantity
				)

		var remaining_supply := maxf(
			float(
				remaining.get(
					resource_id,
					0.0
				)
			),
			0.0
		)

		var accessible_supply := maxf(
			float(
				domestic_accessible_supply.get(
					resource_id,
					total_resource_allocated
					+ remaining_supply
				)
			),
			0.0
		)

		var reconciliation_error := maxf(
			absf(
				total_claim
				- total_resource_allocated
				- total_resource_unmet
			),
			absf(
				accessible_supply
				- total_resource_allocated
				- remaining_supply
			)
		)

		allocated_out[resource_id] = (
			resource_allocated
		)
		unmet_out[resource_id] = (
			resource_unmet
		)
		fulfillment_out[resource_id] = (
			resource_fulfillment
		)
		shortfall_out[resource_id] = (
			resource_shortfall
		)
		remaining_out[resource_id] = (
			remaining_supply
		)
		exhausted_out[resource_id] = bool(
			exhausted.get(
				resource_id,
				false
			)
		)
		total_allocated[resource_id] = (
			total_resource_allocated
		)
		total_unmet[resource_id] = (
			total_resource_unmet
		)
		reconciliation_errors[resource_id] = (
			reconciliation_error
		)

		ledger[resource_id] = {
			"accessible_supply": accessible_supply,
			"total_claim": total_claim,
			"total_allocated": total_resource_allocated,
			"total_unmet": total_resource_unmet,
			"remaining_supply": remaining_supply,
			"reconciliation_error": reconciliation_error
		}

		population_ratio[resource_id] = (
			resource_fulfillment.get(
				"population",
				1.0
			)
		)

		critical_production_ratio[resource_id] = (
			resource_fulfillment.get(
				"industry",
				1.0
			)
		)

		government_ratio[resource_id] = (
			resource_fulfillment.get(
				"government",
				1.0
			)
		)

		military_ratio[resource_id] = (
			resource_fulfillment.get(
				"military",
				1.0
			)
		)

	resources.set_state(
		"allocation_consequence_allocated_by_category",
		allocated_out
	)
	resources.set_state(
		"allocation_consequence_unmet_by_category",
		unmet_out
	)
	resources.set_state(
		"allocation_consequence_fulfillment_ratio_by_category",
		fulfillment_out
	)
	resources.set_state(
		"allocation_consequence_shortfall_ratio_by_category",
		shortfall_out
	)
	resources.set_state(
		"allocation_consequence_remaining_supply",
		remaining_out
	)
	resources.set_state(
		"allocation_consequence_exhausted",
		exhausted_out
	)
	resources.set_state(
		"allocation_consequence_total_allocated",
		total_allocated
	)
	resources.set_state(
		"allocation_consequence_total_unmet",
		total_unmet
	)
	resources.set_state(
		"allocation_consequence_reconciliation_error",
		reconciliation_errors
	)
	resources.set_state(
		"allocation_consequence_ledger",
		ledger
	)

	resources.set_state(
		"population_consumption_allocation_ratio",
		population_ratio
	)
	resources.set_state(
		"critical_production_allocation_ratio",
		critical_production_ratio
	)
	resources.set_state(
		"government_resource_allocation_ratio",
		government_ratio
	)
	resources.set_state(
		"military_resource_allocation_ratio",
		military_ratio
	)


func _clear_state(
	resources: ResourceComponent
) -> void:

	resources.set_state(
		"allocation_consequence_allocated_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_unmet_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_fulfillment_ratio_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_shortfall_ratio_by_category",
		{}
	)
	resources.set_state(
		"allocation_consequence_remaining_supply",
		{}
	)
	resources.set_state(
		"allocation_consequence_exhausted",
		{}
	)
	resources.set_state(
		"allocation_consequence_total_allocated",
		{}
	)
	resources.set_state(
		"allocation_consequence_total_unmet",
		{}
	)
	resources.set_state(
		"allocation_consequence_reconciliation_error",
		{}
	)
	resources.set_state(
		"allocation_consequence_ledger",
		{}
	)
	resources.set_state(
		"population_consumption_allocation_ratio",
		{}
	)
	resources.set_state(
		"critical_production_allocation_ratio",
		{}
	)
	resources.set_state(
		"government_resource_allocation_ratio",
		{}
	)
	resources.set_state(
		"military_resource_allocation_ratio",
		{}
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[
			str(resource_name)
		] = true
