class_name PriorityClassAllocationSystem
extends SimulationSystem


# ============================================================
# STEP 7.2 — BASIC PRIORITY CLASSES
# ============================================================
#
# This is a derived priority-aware allocation layer on top of
# Step 5.10 / Step 7.1.
#
# Step 5.10 remains authoritative for:
# - physical supply
# - accessibility
# - export reservation
# - baseline proportional allocation
#
# Step 7.2 derives a second, explicit allocation outcome using
# configurable priority classes. It does NOT rewrite the baseline
# allocation states and does NOT create a second inventory.
#
# Default conceptual order follows the MVP roadmap:
# essential consumption
# -> critical production
# -> government
# -> military
# -> exports
# -> discretionary use
#
# The configuration is data-driven. Current domestic categories are
# mapped to the first four classes. Exports are already physically
# reserved upstream by Step 5.10 and therefore are not drawn again
# from domestic_accessible_supply here.
#
# Categories sharing a priority class are allocated proportionally
# within that class. Unmapped domestic categories fall back to the
# configurable discretionary_use class.
# ============================================================


const DEFAULT_CONFIG_PATH := (
	"res://data/resource_allocation_priority_classes.json"
)

const EPSILON := 0.0000001


var priority_order: Array = []
var category_to_priority_class: Dictionary = {}
var fallback_priority_class: String = "discretionary_use"


func _init(
	priority_configuration: Dictionary = {}
) -> void:

	super("priority_class_allocation_system")

	if priority_configuration.is_empty():
		_load_default_configuration()
	else:
		if not set_priority_configuration(
			priority_configuration
		):
			push_error(
				"PriorityClassAllocationSystem: Invalid provided configuration."
			)
			priority_order = []
			category_to_priority_class = {}


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"PriorityClassAllocationSystem: World is null."
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

		_process_resources(resources)


func get_priority_configuration() -> Dictionary:

	return {
		"priority_order": priority_order.duplicate(
			true
		),
		"category_to_priority_class": (
			category_to_priority_class.duplicate(
				true
			)
		),
		"unmapped_category_fallback": fallback_priority_class
	}


func get_priority_order() -> Array:

	return priority_order.duplicate(
		true
	)


func get_priority_class_for_category(
	category: String
) -> String:

	if category_to_priority_class.has(category):
		return str(
			category_to_priority_class[category]
		)

	return fallback_priority_class


func set_priority_configuration(
	configuration: Dictionary
) -> bool:

	var order_value = configuration.get(
		"priority_order",
		[]
	)

	var mapping_value = configuration.get(
		"category_to_priority_class",
		{}
	)

	var fallback_value := str(
		configuration.get(
			"unmapped_category_fallback",
			"discretionary_use"
		)
	)

	if typeof(order_value) != TYPE_ARRAY:
		return false

	if typeof(mapping_value) != TYPE_DICTIONARY:
		return false

	var validated_order: Array = []

	for class_value in order_value:

		var priority_class := str(
			class_value
		)

		if priority_class.is_empty():
			return false

		if validated_order.has(
			priority_class
		):
			return false

		validated_order.append(
			priority_class
		)

	if validated_order.is_empty():
		return false

	if fallback_value.is_empty():
		return false

	if not validated_order.has(
		fallback_value
	):
		return false

	var validated_mapping: Dictionary = {}

	for category_value in mapping_value.keys():

		var category := str(
			category_value
		)

		var priority_class := str(
			mapping_value[category_value]
		)

		if category.is_empty():
			return false

		if not validated_order.has(
			priority_class
		):
			return false

		validated_mapping[category] = priority_class

	priority_order = validated_order
	category_to_priority_class = validated_mapping
	fallback_priority_class = fallback_value

	return true


func _load_default_configuration() -> void:

	priority_order = []
	category_to_priority_class = {}
	fallback_priority_class = "discretionary_use"

	if not FileAccess.file_exists(
		DEFAULT_CONFIG_PATH
	):
		push_error(
			"PriorityClassAllocationSystem: Priority configuration missing: "
			+ DEFAULT_CONFIG_PATH
		)
		return

	var file := FileAccess.open(
		DEFAULT_CONFIG_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"PriorityClassAllocationSystem: Could not open priority configuration."
		)
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(
			"PriorityClassAllocationSystem: Priority configuration root must be a dictionary."
		)
		return

	if not set_priority_configuration(parsed):
		push_error(
			"PriorityClassAllocationSystem: Priority configuration failed validation."
		)


func _process_resources(
	resources: ResourceComponent
) -> void:

	var accessible_value = resources.get_state(
		"domestic_accessible_supply",
		{}
	)

	var demand_value = resources.get_state(
		"aggregate_demand_by_category",
		{}
	)

	var accessible: Dictionary = {}
	var demand_by_category: Dictionary = {}

	if typeof(accessible_value) == TYPE_DICTIONARY:
		accessible = accessible_value

	if typeof(demand_value) == TYPE_DICTIONARY:
		demand_by_category = demand_value

	var resource_names: Dictionary = {}

	_collect_keys(
		resource_names,
		accessible
	)

	_collect_nested_resource_keys(
		resource_names,
		demand_by_category
	)

	var priority_class_by_category: Dictionary = (
		category_to_priority_class.duplicate(
			true
		)
	)

	var claims_by_class: Dictionary = {}
	var allocated_by_class: Dictionary = {}
	var unmet_by_class: Dictionary = {}
	var allocated_by_category: Dictionary = {}
	var unmet_by_category: Dictionary = {}
	var fulfillment_by_category: Dictionary = {}
	var shortfall_by_category: Dictionary = {}
	var remaining_supply: Dictionary = {}
	var exhausted: Dictionary = {}
	var ledger: Dictionary = {}
	var reconciliation_errors: Dictionary = {}

	for resource_name_value in resource_names.keys():

		var resource_id := str(
			resource_name_value
		)

		var accessible_supply := maxf(
			0.0,
			float(
				accessible.get(
					resource_id,
					0.0
				)
			)
		)

		var class_claims: Dictionary = {}

		for category_value in demand_by_category.keys():

			var category := str(
				category_value
			)

			# Exports are already physically reserved outside the
			# domestic pool by Step 5.10.
			if category == "exports":
				continue

			var raw_category_claim = demand_by_category.get(
				category,
				{}
			)

			if typeof(raw_category_claim) != TYPE_DICTIONARY:
				continue

			var requested := maxf(
				0.0,
				float(
					raw_category_claim.get(
						resource_id,
						0.0
					)
				)
			)

			var priority_class := get_priority_class_for_category(
				category
			)

			priority_class_by_category[category] = (
				priority_class
			)

			if not class_claims.has(
				priority_class
			):
				class_claims[priority_class] = {}

			var category_map: Dictionary = class_claims[
				priority_class
			]

			category_map[category] = requested
			class_claims[priority_class] = category_map

		var resource_allocated_by_category: Dictionary = {}
		var resource_unmet_by_category: Dictionary = {}
		var resource_fulfillment: Dictionary = {}
		var resource_shortfall: Dictionary = {}
		var resource_class_claims: Dictionary = {}
		var resource_class_allocated: Dictionary = {}
		var resource_class_unmet: Dictionary = {}
		var resource_ledger: Dictionary = {}

		var remaining := accessible_supply

		for priority_index in range(
			priority_order.size()
		):

			var priority_class := str(
				priority_order[priority_index]
			)

			var category_map: Dictionary = class_claims.get(
				priority_class,
				{}
			)

			var category_names: Array = category_map.keys()
			category_names.sort()

			var class_claim_total := 0.0

			for category in category_names:
				class_claim_total += maxf(
					0.0,
					float(
						category_map.get(
							category,
							0.0
						)
					)
				)

			var class_allocated_total := minf(
				remaining,
				class_claim_total
			)

			var class_unmet_total := maxf(
				0.0,
				class_claim_total
				- class_allocated_total
			)

			resource_class_claims[priority_class] = (
				class_claim_total
			)
			resource_class_allocated[priority_class] = (
				class_allocated_total
			)
			resource_class_unmet[priority_class] = (
				class_unmet_total
			)

			var category_allocated_so_far := 0.0

			for category_index in range(
				category_names.size()
			):

				var category := str(
					category_names[category_index]
				)

				var requested := maxf(
					0.0,
					float(
						category_map.get(
							category,
							0.0
						)
					)
				)

				var category_allocated := 0.0

				if class_claim_total > EPSILON:

					if category_index == category_names.size() - 1:

						category_allocated = maxf(
							0.0,
							class_allocated_total
							- category_allocated_so_far
						)

					else:

						category_allocated = (
							class_allocated_total
							* requested
							/ class_claim_total
						)

				category_allocated = minf(
					category_allocated,
					requested
				)

				category_allocated_so_far += (
					category_allocated
				)

				var category_unmet := maxf(
					0.0,
					requested
					- category_allocated
				)

				resource_allocated_by_category[
					category
				] = category_allocated

				resource_unmet_by_category[
					category
				] = category_unmet

				var fulfillment := 1.0

				if requested > EPSILON:

					fulfillment = clampf(
						category_allocated
						/ requested,
						0.0,
						1.0
					)

				var shortfall := 0.0

				if requested > EPSILON:

					shortfall = clampf(
						category_unmet
						/ requested,
						0.0,
						1.0
					)

				resource_fulfillment[
					category
				] = fulfillment

				resource_shortfall[
					category
				] = shortfall

			remaining = maxf(
				0.0,
				remaining
				- class_allocated_total
			)

			resource_ledger[priority_class] = {
				"priority_rank": priority_index + 1,
				"claim_total": class_claim_total,
				"allocated_total": class_allocated_total,
				"unmet_total": class_unmet_total,
				"remaining_supply_after_class": remaining,
				"exhausted": (
					class_claim_total > EPSILON
					and remaining <= EPSILON
					and class_unmet_total > EPSILON
				)
			}

		var total_claim := 0.0

		for priority_class in resource_class_claims.keys():
			total_claim += float(
				resource_class_claims[
					priority_class
				]
			)

		var total_allocated := 0.0

		for category in resource_allocated_by_category.keys():
			total_allocated += float(
				resource_allocated_by_category[
					category
				]
			)

		var total_unmet := 0.0

		for category in resource_unmet_by_category.keys():
			total_unmet += float(
				resource_unmet_by_category[
					category
				]
			)

		var reconciliation_error := maxf(
			absf(
				total_claim
				- total_allocated
				- total_unmet
			),
			absf(
				accessible_supply
				- total_allocated
				- remaining
			)
		)

		claims_by_class[resource_id] = resource_class_claims
		allocated_by_class[resource_id] = resource_class_allocated
		unmet_by_class[resource_id] = resource_class_unmet
		allocated_by_category[resource_id] = resource_allocated_by_category
		unmet_by_category[resource_id] = resource_unmet_by_category
		fulfillment_by_category[resource_id] = resource_fulfillment
		shortfall_by_category[resource_id] = resource_shortfall
		remaining_supply[resource_id] = remaining
		exhausted[resource_id] = (
			total_claim > EPSILON
			and total_allocated >= accessible_supply - EPSILON
			and total_unmet > EPSILON
		)
		reconciliation_errors[resource_id] = (
			reconciliation_error
		)

		resource_ledger["accessible_supply"] = (
			accessible_supply
		)
		resource_ledger["total_claim"] = total_claim
		resource_ledger["total_allocated"] = total_allocated
		resource_ledger["total_unmet"] = total_unmet
		resource_ledger["remaining_supply"] = remaining
		resource_ledger["reconciliation_error"] = (
			reconciliation_error
		)

		ledger[resource_id] = resource_ledger

	resources.set_state(
		"priority_class_order",
		priority_order.duplicate(
			true
		)
	)
	resources.set_state(
		"priority_class_by_category",
		priority_class_by_category
	)
	resources.set_state(
		"priority_claim_by_class",
		claims_by_class
	)
	resources.set_state(
		"priority_allocated_supply_by_class",
		allocated_by_class
	)
	resources.set_state(
		"priority_unmet_by_class",
		unmet_by_class
	)
	resources.set_state(
		"priority_allocated_supply_by_category",
		allocated_by_category
	)
	resources.set_state(
		"priority_allocation_unmet_by_category",
		unmet_by_category
	)
	resources.set_state(
		"priority_allocation_fulfillment_ratio_by_category",
		fulfillment_by_category
	)
	resources.set_state(
		"priority_allocation_shortfall_ratio_by_category",
		shortfall_by_category
	)
	resources.set_state(
		"priority_allocation_remaining_supply",
		remaining_supply
	)
	resources.set_state(
		"priority_allocation_exhausted",
		exhausted
	)
	resources.set_state(
		"priority_allocation_ledger",
		ledger
	)
	resources.set_state(
		"priority_allocation_reconciliation_error",
		reconciliation_errors
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[
			str(resource_name)
		] = true


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

			resource_names[
				str(resource_name)
			] = true
