class_name AggregateConsumptionSystem
extends SimulationSystem


const DOMESTIC_CATEGORIES: Array[String] = [
	"population",
	"industry",
	"government",
	"military"
]


func _init():
	super("aggregate_consumption_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("AggregateConsumptionSystem: World is null.")
		return

	for entity in world.entities.values():

		var resources = entity.get_component(
			"resources"
		)

		if resources == null:
			continue

		_process_entity_consumption(
			resources
		)


func _process_entity_consumption(
	resources: ResourceComponent
) -> void:

	var demand_by_category_value = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)

	var demand_by_category: Dictionary = {}

	if typeof(demand_by_category_value) == TYPE_DICTIONARY:
		demand_by_category = demand_by_category_value


	# Step 7.4 consequence state uses the same authoritative orientation as
	# Step 7.2: resource -> category -> quantity/ratio.
	var allocated_by_resource_value = resources.get_state(
		"allocation_consequence_allocated_by_category",
		{}
	)

	var unmet_by_resource_value = resources.get_state(
		"allocation_consequence_unmet_by_category",
		{}
	)

	var fulfillment_by_resource_value = resources.get_state(
		"allocation_consequence_fulfillment_ratio_by_category",
		{}
	)

	var allocated_by_resource: Dictionary = {}
	var unmet_by_resource: Dictionary = {}
	var fulfillment_by_resource: Dictionary = {}

	if typeof(allocated_by_resource_value) == TYPE_DICTIONARY:
		allocated_by_resource = allocated_by_resource_value

	if typeof(unmet_by_resource_value) == TYPE_DICTIONARY:
		unmet_by_resource = unmet_by_resource_value

	if typeof(fulfillment_by_resource_value) == TYPE_DICTIONARY:
		fulfillment_by_resource = fulfillment_by_resource_value

	var allocation_active: bool = (
		not allocated_by_resource.is_empty()
		or
		not unmet_by_resource.is_empty()
		or
		not fulfillment_by_resource.is_empty()
	)

	# Preserve the verified Step 5.4 behavior exactly until a real Step 7.4
	# allocation consequence exists. This prevents the new downstream layer
	# from changing the semantics of the earlier aggregate-consumption gate.
	if not allocation_active:
		_process_baseline_consumption(
			resources,
			demand_by_category
		)
		return

	# Step 5.4 remains aggregate-only, but Step 7.4 gives it a causal
	# downstream input from the prior monthly allocation:
	#
	# prior allocation
	#      ↓
	# current consumption request
	#      ↓
	# next ResourceSystem physical settlement
	#
	# When no allocation consequence exists yet, the original Step 5.4
	# behavior remains unchanged and gross demand becomes consumption.
	var consumption_by_category: Dictionary = {}
	var consumption_total_by_category: Dictionary = {}
	var actual_consumption: Dictionary = {}
	var reconciliation_error: Dictionary = {}
	var consumption_ledger: Dictionary = {}

	var consumption_total := 0.0

	for category in DOMESTIC_CATEGORIES:

		consumption_by_category[category] = {}
		consumption_total_by_category[category] = 0.0

	var resource_names: Dictionary = {}

	for category in DOMESTIC_CATEGORIES:

		var demand_value = demand_by_category.get(
			category,
			{}
		)

		if typeof(demand_value) != TYPE_DICTIONARY:
			continue

		for resource_name in demand_value.keys():
			resource_names[str(resource_name)] = true

	if allocation_active:

		for resource_name in allocated_by_resource.keys():
			resource_names[str(resource_name)] = true

		for resource_name in unmet_by_resource.keys():
			resource_names[str(resource_name)] = true


	for resource_name_value in resource_names.keys():

		var resource_id := str(
			resource_name_value
		)

		var resource_allocated_value = (
			allocated_by_resource.get(
				resource_id,
				{}
			)
		)

		var resource_unmet_value = (
			unmet_by_resource.get(
				resource_id,
				{}
			)
		)

		var resource_fulfillment_value = (
			fulfillment_by_resource.get(
				resource_id,
				{}
			)
		)

		var resource_allocated: Dictionary = {}
		var resource_unmet: Dictionary = {}
		var resource_fulfillment: Dictionary = {}

		if typeof(resource_allocated_value) == TYPE_DICTIONARY:
			resource_allocated = resource_allocated_value

		if typeof(resource_unmet_value) == TYPE_DICTIONARY:
			resource_unmet = resource_unmet_value

		if typeof(resource_fulfillment_value) == TYPE_DICTIONARY:
			resource_fulfillment = resource_fulfillment_value

		var resource_ledger: Dictionary = {
			"categories": {},
			"gross_demand_total": 0.0,
			"allocated_consumption_total": 0.0,
			"unmet_consumption_total": 0.0,
			"reconciliation_error": 0.0
		}

		for category in DOMESTIC_CATEGORIES:

			var category_demand_value = demand_by_category.get(
				category,
				{}
			)

			var category_demand: Dictionary = {}

			if typeof(category_demand_value) == TYPE_DICTIONARY:
				category_demand = category_demand_value

			var gross_demand: float = maxf(
				float(
					category_demand.get(
						resource_id,
						0.0
					)
				),
				0.0
			)

			var allocated_quantity := gross_demand
			var unmet_quantity := 0.0
			var fulfillment_ratio := 1.0

			if allocation_active:

				allocated_quantity = maxf(
					float(
						resource_allocated.get(
							category,
							0.0
						)
					),
					0.0
				)

				unmet_quantity = maxf(
					float(
						resource_unmet.get(
							category,
							maxf(
								gross_demand
								- allocated_quantity,
								0.0
							)
						)
					),
					0.0
				)

				if resource_fulfillment.has(category):

					fulfillment_ratio = clampf(
						float(
							resource_fulfillment.get(
								category,
								1.0
							)
						),
						0.0,
						1.0
					)

				elif gross_demand > 0.0:

					fulfillment_ratio = clampf(
						allocated_quantity / gross_demand,
						0.0,
						1.0
					)

				else:

					fulfillment_ratio = 1.0

				allocated_quantity = min(
					allocated_quantity,
					gross_demand
				)

				unmet_quantity = maxf(
					0.0,
					gross_demand
					- allocated_quantity
				)

			if allocated_quantity > 0.0:

				consumption_by_category[category][resource_id] = (
					allocated_quantity
				)

			consumption_total_by_category[category] = (
				float(
					consumption_total_by_category.get(
						category,
						0.0
					)
				)
				+ allocated_quantity
			)

			if not actual_consumption.has(resource_id):
				actual_consumption[resource_id] = 0.0

			actual_consumption[resource_id] = (
				float(
					actual_consumption[resource_id]
				)
				+ allocated_quantity
			)

			consumption_total += allocated_quantity

			resource_ledger["categories"][category] = {
				"gross_demand": gross_demand,
				"allocated_consumption": allocated_quantity,
				"unmet_consumption": unmet_quantity,
				"fulfillment_ratio": fulfillment_ratio
			}

			resource_ledger["gross_demand_total"] = (
				float(
					resource_ledger["gross_demand_total"]
				)
				+ gross_demand
			)

			resource_ledger["allocated_consumption_total"] = (
				float(
					resource_ledger["allocated_consumption_total"]
				)
				+ allocated_quantity
			)

			resource_ledger["unmet_consumption_total"] = (
				float(
					resource_ledger["unmet_consumption_total"]
				)
				+ unmet_quantity
			)

		resource_ledger["reconciliation_error"] = (
			float(resource_ledger["gross_demand_total"])
			- float(resource_ledger["allocated_consumption_total"])
			- float(resource_ledger["unmet_consumption_total"])
		)

		reconciliation_error[resource_id] = (
			resource_ledger["reconciliation_error"]
		)

		consumption_ledger[resource_id] = resource_ledger

	resources.set_state(
		"consumption_by_category",
		consumption_by_category
	)

	resources.set_state(
		"consumption_total_by_category",
		consumption_total_by_category
	)

	resources.set_state(
		"actual_consumption",
		actual_consumption
	)

	resources.set_state(
		"actual_consumption_total",
		consumption_total
	)

	resources.set_state(
		"consumption_reconciliation_error",
		reconciliation_error
	)

	resources.set_state(
		"consumption_ledger",
		consumption_ledger
	)

	# Keep the existing ResourceSystem input field as the authoritative
	# domestic-consumption request for the next monthly physical settlement.
	resources.set_state(
		"consumption",
		actual_consumption
	)

# ============================================================
# VERIFIED STEP 5.4 BASELINE PATH
# ============================================================
# This is intentionally kept equivalent to the pre-7.4 implementation.
# Step 7.4 only takes control once allocation consequence state is present.
func _process_baseline_consumption(
	resources: ResourceComponent,
	demand_by_category: Dictionary
) -> void:

	var domestic_categories: Array[String] = [
		"population",
		"industry",
		"government",
		"military"
	]

	var consumption_by_category: Dictionary = {}
	var consumption_total_by_category: Dictionary = {}
	var actual_consumption: Dictionary = {}
	var reconciliation_error: Dictionary = {}
	var consumption_ledger: Dictionary = {}

	var consumption_total := 0.0

	for category in domestic_categories:
		consumption_by_category[category] = {}
		consumption_total_by_category[category] = 0.0

	for category in domestic_categories:

		var category_value = demand_by_category.get(
			category,
			{}
		)

		var category_demand: Dictionary = {}

		if typeof(category_value) == TYPE_DICTIONARY:
			category_demand = category_value
		else:
			category_demand = {}

		for resource_name in category_demand.keys():

			var resource_id := str(resource_name)

			var requested: float = maxf(
				0.0,
				float(
					category_demand.get(
						resource_id,
						0.0
					)
				)
			)

			if requested <= 0.0:
				continue

			consumption_by_category[category][resource_id] = requested

			var current_total: float = float(
				consumption_total_by_category.get(
					category,
					0.0
				)
			)

			consumption_total_by_category[category] = (
				current_total
				+ requested
			)

			if not actual_consumption.has(resource_id):
				actual_consumption[resource_id] = 0.0

			actual_consumption[resource_id] = (
				float(actual_consumption[resource_id])
				+ requested
			)

			consumption_total += requested

	# At Step 5.4 there is deliberately no scarcity allocation yet.
	# Requested domestic demand becomes current-cycle requested consumption.
	var previous_consumption_value = resources.get_state(
		"consumption",
		{}
	)
	var previous_consumption: Dictionary = {}

	if typeof(previous_consumption_value) == TYPE_DICTIONARY:
		previous_consumption = previous_consumption_value

	for resource_name in actual_consumption.keys():

		var resource_id := str(resource_name)

		var resolved_value: float = float(
			actual_consumption.get(
				resource_id,
				0.0
			)
		)

		var previous_value: float = maxf(
			0.0,
			float(
				previous_consumption.get(
					resource_id,
					0.0
				)
			)
		)

		reconciliation_error[resource_id] = (
			resolved_value
			- float(
				actual_consumption.get(
					resource_id,
					0.0
				)
			)
		)

		consumption_ledger[resource_id] = {
			"population": maxf(
				0.0,
				float(
					consumption_by_category["population"].get(
						resource_id,
						0.0
					)
				)
			),
			"industry": maxf(
				0.0,
				float(
					consumption_by_category["industry"].get(
						resource_id,
						0.0
					)
				)
			),
			"government": maxf(
				0.0,
				float(
					consumption_by_category["government"].get(
						resource_id,
						0.0
					)
				)
			),
			"military": maxf(
				0.0,
				float(
					consumption_by_category["military"].get(
						resource_id,
						0.0
					)
				)
			),
			"previous_consumption": previous_value,
			"actual_consumption": resolved_value,
			"unmet_consumption": 0.0,
			"reconciliation_error": reconciliation_error[resource_id]
		}

	resources.set_state(
		"consumption_by_category",
		consumption_by_category
	)

	resources.set_state(
		"consumption_total_by_category",
		consumption_total_by_category
	)

	resources.set_state(
		"actual_consumption",
		actual_consumption
	)

	resources.set_state(
		"actual_consumption_total",
		consumption_total
	)

	resources.set_state(
		"consumption_reconciliation_error",
		reconciliation_error
	)

	resources.set_state(
		"consumption_ledger",
		consumption_ledger
	)

	resources.set_state(
		"consumption",
		actual_consumption
	)
