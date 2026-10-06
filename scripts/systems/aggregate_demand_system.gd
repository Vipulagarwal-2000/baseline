class_name AggregateDemandSystem
extends SimulationSystem


func _init():
	super("aggregate_demand_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("AggregateDemandSystem: World is null.")
		return

	for entity in world.entities.values():

		var resources = entity.get_component(
			"resources"
		)

		if resources == null:
			continue

		_process_entity_demand(
			entity
		)


func _process_entity_demand(
	entity
) -> void:

	var resources = entity.get_component(
		"resources"
	)

	if resources == null:
		return

	var population_demand = _sanitize_demand_map(
		resources.get_state(
			"population_resource_demand",
			{}
		)
	)

	var economy = entity.get_component(
		"economy"
	)

	var population_consumption_factor := 1.0

	if economy != null:
		population_consumption_factor = clampf(
			maxf(
				float(
					economy.get_state(
						"population_consumption_demand_factor",
						1.0
					)
				),
				0.0
			),
			0.0,
			1.0
		)

	var baseline_population_demand := population_demand.duplicate(true)

	if not is_equal_approx(
		population_consumption_factor,
		1.0
	):
		for resource_name in population_demand.keys():
			population_demand[resource_name] = (
				maxf(
					float(
						population_demand[resource_name]
					),
					0.0
				)
				* population_consumption_factor
			)

	var industry_demand = _sanitize_demand_map(
		resources.get_state(
			"production_process_demand",
			{}
		)
	)

	var government_demand = _sanitize_demand_map(
		resources.get_state(
			"government_resource_demand",
			{}
		)
	)

	var military_demand = _sanitize_demand_map(
		resources.get_state(
			"military_resource_demand",
			{}
		)
	)

	# Exports are a demand destination for domestically available
	# resources. ResourceSystem already owns the physical export settlement;
	# Step 5.3 only exposes the export requirement as a demand category.
	var export_demand = _sanitize_demand_map(
		resources.get_state(
			"exports",
			{}
		)
	)

	var category_demands: Dictionary = {
		"population": population_demand,
		"industry": industry_demand,
		"government": government_demand,
		"military": military_demand,
		"exports": export_demand
	}

	var resource_names: Dictionary = {}

	for category in category_demands.keys():

		var category_map: Dictionary = category_demands[category]

		for resource_name in category_map.keys():
			resource_names[str(resource_name)] = true

	var aggregate_demand: Dictionary = {}
	var reconciliation_error: Dictionary = {}
	var ledger: Dictionary = {}
	var category_totals: Dictionary = {}
	var aggregate_total := 0.0

	for category in category_demands.keys():
		category_totals[category] = 0.0

	for resource_name in resource_names.keys():

		var resource_id := str(resource_name)
		var population_value: float = maxf(
			0.0,
			float(
				population_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var industry_value: float = maxf(
			0.0,
			float(
				industry_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var government_value: float = maxf(
			0.0,
			float(
				government_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var military_value: float = maxf(
			0.0,
			float(
				military_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var export_value: float = maxf(
			0.0,
			float(
				export_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var resource_total: float = (
			population_value
			+ industry_value
			+ government_value
			+ military_value
			+ export_value
		)

		var reconstructed_total: float = (
			population_value
			+ industry_value
			+ government_value
			+ military_value
			+ export_value
		)

		aggregate_demand[resource_id] = resource_total

		reconciliation_error[resource_id] = (
			resource_total
			- reconstructed_total
		)

		ledger[resource_id] = {
			"population": population_value,
			"industry": industry_value,
			"government": government_value,
			"military": military_value,
			"exports": export_value,
			"total_demand": resource_total,
			"reconciliation_error": reconciliation_error[resource_id]
		}

		category_totals["population"] += population_value
		category_totals["industry"] += industry_value
		category_totals["government"] += government_value
		category_totals["military"] += military_value
		category_totals["exports"] += export_value

		aggregate_total += resource_total

	resources.set_state(
		"aggregate_demand_by_category",
		category_demands
	)

	resources.set_state(
		"aggregate_demand_total_by_category",
		category_totals
	)

	resources.set_state(
		"aggregate_demand",
		aggregate_demand
	)

	resources.set_state(
		"aggregate_demand_total",
		aggregate_total
	)

	resources.set_state(
		"aggregate_demand_reconciliation_error",
		reconciliation_error
	)

	resources.set_state(
		"aggregate_demand_ledger",
		ledger
	)

	resources.set_state(
		"population_consumption_demand_factor",
		population_consumption_factor
	)

	resources.set_state(
		"population_demand_before_consumption_feedback",
		baseline_population_demand
	)


func _sanitize_demand_map(
	value: Variant
) -> Dictionary:

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	var sanitized: Dictionary = {}

	for resource_name in value.keys():

		var resource_id := str(resource_name)
		var amount := float(value[resource_name])

		if amount <= 0.0:
			continue

		sanitized[resource_id] = amount

	return sanitized
