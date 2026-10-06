class_name ScarceResourceAllocationSystem
extends SimulationSystem


const EPSILON := 0.0000001


func _init() -> void:
	super("scarce_resource_allocation_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("ScarceResourceAllocationSystem: World is null.")
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var resources = entity.get_component("resources")
		if resources == null:
			continue

		_process_resources(resources)


func _process_resources(resources: ResourceComponent) -> void:
	# 5.10 remains the owner of physical accessibility and baseline
	# proportional allocation. Step 7.1 makes the scarcity outcome
	# explicit and machine-readable without creating a second inventory
	# or a second physical distribution model.
	var accessible_value = resources.get_state(
		"domestic_accessible_supply",
		{}
	)
	var demand_by_category_value = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)
	var allocated_by_category_value = resources.get_state(
		"allocated_supply_by_category",
		{}
	)
	var allocation_total_value = resources.get_state(
		"allocated_supply_total",
		{}
	)
	var unmet_by_category_value = resources.get_state(
		"allocation_unmet_by_category",
		{}
	)

	var accessible: Dictionary = {}
	var demand_by_category: Dictionary = {}
	var allocated_by_category: Dictionary = {}
	var allocation_total: Dictionary = {}
	var unmet_by_category: Dictionary = {}

	if typeof(accessible_value) == TYPE_DICTIONARY:
		accessible = accessible_value

	if typeof(demand_by_category_value) == TYPE_DICTIONARY:
		demand_by_category = demand_by_category_value

	if typeof(allocated_by_category_value) == TYPE_DICTIONARY:
		allocated_by_category = allocated_by_category_value

	if typeof(allocation_total_value) == TYPE_DICTIONARY:
		allocation_total = allocation_total_value

	if typeof(unmet_by_category_value) == TYPE_DICTIONARY:
		unmet_by_category = unmet_by_category_value

	var resource_names: Dictionary = {}
	_collect_keys(resource_names, accessible)
	_collect_nested_resource_keys(resource_names, demand_by_category)
	_collect_nested_resource_keys(resource_names, allocated_by_category)
	_collect_nested_resource_keys(resource_names, unmet_by_category)
	_collect_keys(resource_names, allocation_total)

	var scarcity_active: Dictionary = {}
	var domestic_claims_total: Dictionary = {}
	var fulfillment_by_category: Dictionary = {}
	var shortfall_ratio_by_category: Dictionary = {}
	var allocation_exhausted: Dictionary = {}
	var ledger: Dictionary = {}
	var reconciliation_errors: Dictionary = {}

	for resource_name_value in resource_names.keys():
		var resource_id := str(resource_name_value)

		var accessible_supply := maxf(
			0.0,
			float(accessible.get(resource_id, 0.0))
		)

		var domestic_claims := 0.0
		var category_claims: Dictionary = {}

		for category_value in demand_by_category.keys():
			var category := str(category_value)

			# Exports are already reserved outside the domestic allocation
			# pool by Step 5.10 and are therefore excluded here.
			if category == "exports":
				continue

			var category_values = demand_by_category.get(
				category,
				{}
			)

			if typeof(category_values) != TYPE_DICTIONARY:
				continue

			var requested := maxf(
				0.0,
				float(
					category_values.get(
						resource_id,
						0.0
					)
				)
			)

			category_claims[category] = requested
			domestic_claims += requested

		var allocated_total := maxf(
			0.0,
			float(
				allocation_total.get(
					resource_id,
					0.0
				)
			)
		)

		var scarce := (
			domestic_claims > accessible_supply + EPSILON
		)

		scarcity_active[resource_id] = scarce
		domestic_claims_total[resource_id] = domestic_claims

		# The accessible pool is exhausted when the baseline allocation has
		# no unallocated accessible supply left and there are positive claims.
		var remaining_accessible := maxf(
			0.0,
			accessible_supply - allocated_total
		)

		allocation_exhausted[resource_id] = (
			domestic_claims > EPSILON
			and remaining_accessible <= EPSILON
		)

		var category_fulfillment: Dictionary = {}
		var category_shortfall: Dictionary = {}

		for category in category_claims.keys():
			var requested: float = category_claims[category]

			var allocated := 0.0
			var category_values = allocated_by_category.get(
				category,
				{}
			)

			if typeof(category_values) == TYPE_DICTIONARY:
				allocated = maxf(
					0.0,
					float(
						category_values.get(
							resource_id,
							0.0
						)
					)
				)

			var unmet := maxf(
				0.0,
				requested - allocated
			)

			var fulfillment := 0.0
			if requested > EPSILON:
				fulfillment = clampf(
					allocated / requested,
					0.0,
					1.0
				)
			else:
				fulfillment = 1.0

			var shortfall_ratio := 0.0
			if requested > EPSILON:
				shortfall_ratio = clampf(
					unmet / requested,
					0.0,
					1.0
				)

			category_fulfillment[category] = fulfillment
			category_shortfall[category] = shortfall_ratio

		fulfillment_by_category[resource_id] = (
			category_fulfillment
		)
		shortfall_ratio_by_category[resource_id] = (
			category_shortfall
		)

		# Reconcile the scarce-allocation interpretation:
		# allocated + unmet = claims.
		var demand_reconciliation_error := 0.0

		for category in category_claims.keys():
			var requested: float = category_claims[category]
			var category_allocated := 0.0
			var category_unmet := 0.0

			var allocated_values = allocated_by_category.get(
				category,
				{}
			)
			if typeof(allocated_values) == TYPE_DICTIONARY:
				category_allocated = maxf(
					0.0,
					float(
						allocated_values.get(
							resource_id,
							0.0
						)
					)
				)

			var unmet_values = unmet_by_category.get(
				category,
				{}
			)
			if typeof(unmet_values) == TYPE_DICTIONARY:
				category_unmet = maxf(
					0.0,
					float(
						unmet_values.get(
							resource_id,
							0.0
						)
					)
				)

			demand_reconciliation_error = maxf(
				demand_reconciliation_error,
				absf(
					requested
					- category_allocated
					- category_unmet
				)
			)

		var supply_reconciliation_error := absf(
			accessible_supply
			- allocated_total
			- remaining_accessible
		)

		reconciliation_errors[resource_id] = maxf(
			demand_reconciliation_error,
			supply_reconciliation_error
		)

		ledger[resource_id] = {
			"accessible_supply": accessible_supply,
			"domestic_claims": domestic_claims,
			"allocated_supply": allocated_total,
			"unallocated_accessible_supply": remaining_accessible,
			"scarcity_active": scarce,
			"allocation_exhausted": (
				allocation_exhausted[resource_id]
			),
			"claims_by_category": category_claims,
			"fulfillment_ratio_by_category": (
				category_fulfillment
			),
			"shortfall_ratio_by_category": (
				category_shortfall
			),
			"reconciliation_error": (
				reconciliation_errors[resource_id]
			)
		}

	resources.set_state(
		"scarcity_active",
		scarcity_active
	)
	resources.set_state(
		"domestic_claims_total",
		domestic_claims_total
	)
	resources.set_state(
		"allocation_fulfillment_ratio_by_category",
		fulfillment_by_category
	)
	resources.set_state(
		"allocation_shortfall_ratio_by_category",
		shortfall_ratio_by_category
	)
	resources.set_state(
		"allocation_exhausted",
		allocation_exhausted
	)
	resources.set_state(
		"scarce_resource_allocation_ledger",
		ledger
	)
	resources.set_state(
		"scarce_resource_allocation_reconciliation_error",
		reconciliation_errors
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:
	for resource_name in values.keys():
		resource_names[str(resource_name)] = true


func _collect_nested_resource_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:
	for category_value in values.keys():
		var category_values = values.get(
			category_value,
			{}
		)

		if typeof(category_values) != TYPE_DICTIONARY:
			continue

		for resource_name in category_values.keys():
			resource_names[str(resource_name)] = true
