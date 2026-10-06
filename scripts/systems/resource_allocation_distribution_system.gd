class_name ResourceAllocationDistributionSystem
extends SimulationSystem


const DEFAULT_ACCESSIBILITY: float = 1.0
const EPSILON: float = 0.000001


func _init() -> void:
	super("resource_allocation_distribution_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("ResourceAllocationDistributionSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var resources = entity.get_component("resources")

		if resources == null:
			continue

		_process_entity_allocation(resources)


func _process_entity_allocation(resources: ResourceComponent) -> void:

	var resolved_supply_value = resources.get_state(
		"resolved_supply",
		{}
	)
	var exports_value = resources.get_state(
		"exports",
		{}
	)
	var demand_by_category_value = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)
	var accessibility_value = resources.get_state(
		"accessibility",
		{}
	)

	var resolved_supply: Dictionary = {}
	var exports: Dictionary = {}
	var demand_by_category: Dictionary = {}
	var accessibility: Dictionary = {}

	if typeof(resolved_supply_value) == TYPE_DICTIONARY:
		resolved_supply = resolved_supply_value

	if typeof(exports_value) == TYPE_DICTIONARY:
		exports = exports_value

	if typeof(demand_by_category_value) == TYPE_DICTIONARY:
		demand_by_category = demand_by_category_value

	if typeof(accessibility_value) == TYPE_DICTIONARY:
		accessibility = accessibility_value

	var domestic_categories: Array[String] = [
		"population",
		"industry",
		"government",
		"military"
	]

	var resource_names: Dictionary = {}
	_collect_keys(resource_names, resolved_supply)
	_collect_keys(resource_names, exports)
	_collect_keys(resource_names, accessibility)

	for category in domestic_categories:
		var category_value = demand_by_category.get(category, {})
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		_collect_keys(resource_names, category_value)

	var domestic_accessible_supply: Dictionary = {}
	var distribution_access_loss: Dictionary = {}
	var allocated_supply_by_category: Dictionary = {}
	var allocated_supply_total: Dictionary = {}
	var allocation_unmet_by_category: Dictionary = {}
	var unallocated_accessible_supply: Dictionary = {}
	var allocation_reconciliation_error: Dictionary = {}
	var distribution_ledger: Dictionary = {}

	var total_accessible_supply := 0.0
	var total_allocated := 0.0
	var total_unmet := 0.0

	for category in domestic_categories:
		allocated_supply_by_category[category] = {}
		allocation_unmet_by_category[category] = {}

	for resource_name_value in resource_names.keys():

		var resource_id: String = str(resource_name_value)

		var supply: float = maxf(
			float(resolved_supply.get(resource_id, 0.0)),
			0.0
		)

		# Trade exports are already physically resolved upstream. Reserve the
		# existing export quantity before distributing domestic supply so that
		# domestic categories cannot claim the same units a second time.
		var export_quantity: float = maxf(
			float(exports.get(resource_id, 0.0)),
			0.0
		)
		export_quantity = minf(export_quantity, supply)

		var supply_after_exports: float = maxf(
			supply - export_quantity,
			0.0
		)

		# Accessibility is an existing ResourceSystem / infrastructure-derived
		# state. This system consumes it rather than constructing another
		# transport model.
		var access_factor: float = clampf(
			float(
				accessibility.get(
					resource_id,
					DEFAULT_ACCESSIBILITY
				)
			),
			0.0,
			1.0
		)

		var accessible_supply: float = (
			supply_after_exports * access_factor
		)
		var distribution_loss: float = maxf(
			supply_after_exports - accessible_supply,
			0.0
		)

		var requested_by_category: Dictionary = {}
		var domestic_demand: float = 0.0

		for category in domestic_categories:
			var category_value = demand_by_category.get(category, {})
			var category_demand: float = 0.0

			if typeof(category_value) == TYPE_DICTIONARY:
				category_demand = maxf(
					float(category_value.get(resource_id, 0.0)),
					0.0
				)

			requested_by_category[category] = category_demand
			domestic_demand += category_demand

		var allocated_total: float = minf(
			accessible_supply,
			domestic_demand
		)
		var remaining_supply: float = maxf(
			accessible_supply - allocated_total,
			0.0
		)

		for category in domestic_categories:
			var requested: float = float(
				requested_by_category.get(category, 0.0)
			)
			var allocated: float = 0.0

			if domestic_demand > EPSILON and allocated_total > 0.0:
				allocated = allocated_total * (requested / domestic_demand)

			var unmet: float = maxf(
				requested - allocated,
				0.0
			)

			if allocated > EPSILON:
				allocated_supply_by_category[category][resource_id] = allocated
			elif requested > EPSILON:
				allocated_supply_by_category[category][resource_id] = 0.0

			if unmet > EPSILON:
				allocation_unmet_by_category[category][resource_id] = unmet
			elif requested > EPSILON:
				allocation_unmet_by_category[category][resource_id] = 0.0

			if not allocated_supply_total.has(resource_id):
				allocated_supply_total[resource_id] = 0.0
			allocated_supply_total[resource_id] = (
				float(allocated_supply_total[resource_id]) + allocated
			)

			total_unmet += unmet

		allocated_supply_total[resource_id] = allocated_total
		unallocated_accessible_supply[resource_id] = remaining_supply
		domestic_accessible_supply[resource_id] = accessible_supply
		distribution_access_loss[resource_id] = distribution_loss

		var supply_reconciliation_error: float = (
			supply_after_exports
			- distribution_loss
			- allocated_total
			- remaining_supply
		)
		var demand_reconciliation_error: float = (
			domestic_demand
			- allocated_total
			- maxf(domestic_demand - allocated_total, 0.0)
		)

		allocation_reconciliation_error[resource_id] = maxf(
			absf(supply_reconciliation_error),
			absf(demand_reconciliation_error)
		)

		distribution_ledger[resource_id] = {
			"resolved_supply": supply,
			"export_quantity_reserved": export_quantity,
			"supply_after_exports": supply_after_exports,
			"accessibility": access_factor,
			"accessible_supply": accessible_supply,
			"distribution_loss": distribution_loss,
			"domestic_demand": domestic_demand,
			"allocated_domestic_supply": allocated_total,
			"unallocated_accessible_supply": remaining_supply,
			"requested_by_category": requested_by_category,
			"supply_reconciliation_error": supply_reconciliation_error,
			"demand_reconciliation_error": demand_reconciliation_error,
			"reconciliation_error": allocation_reconciliation_error[resource_id]
		}

		total_accessible_supply += accessible_supply
		total_allocated += allocated_total

	resources.set_state(
		"domestic_accessible_supply",
		domestic_accessible_supply
	)
	resources.set_state(
		"distribution_access_loss",
		distribution_access_loss
	)
	resources.set_state(
		"allocated_supply_by_category",
		allocated_supply_by_category
	)
	resources.set_state(
		"allocated_supply_total",
		allocated_supply_total
	)
	resources.set_state(
		"allocation_unmet_by_category",
		allocation_unmet_by_category
	)
	resources.set_state(
		"unallocated_accessible_supply",
		unallocated_accessible_supply
	)
	resources.set_state(
		"allocation_reconciliation_error",
		allocation_reconciliation_error
	)
	resources.set_state(
		"domestic_distribution_total_accessible",
		total_accessible_supply
	)
	resources.set_state(
		"domestic_distribution_total_allocated",
		total_allocated
	)
	resources.set_state(
		"domestic_distribution_total_unmet",
		total_unmet
	)
	resources.set_state(
		"domestic_distribution_ledger",
		distribution_ledger
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[str(resource_name)] = true
