class_name SupplyDemandResolutionSystem
extends SimulationSystem


func _init():
	super("supply_demand_resolution_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("SupplyDemandResolutionSystem: World is null.")
		return

	for entity in world.entities.values():

		var resources = entity.get_component(
			"resources"
		)

		if resources == null:
			continue

		_process_entity_resolution(
			resources
		)


func _process_entity_resolution(
	resources: ResourceComponent
) -> void:

	var available_supply_value = resources.get_state(
		"available_supply",
		{}
	)

	var actual_consumption_value = resources.get_state(
		"actual_consumption",
		{}
	)

	var exports_value = resources.get_state(
		"exports",
		{}
	)

	var aggregate_demand_value = resources.get_state(
		"aggregate_demand",
		{}
	)

	var available_supply: Dictionary = {}
	var actual_consumption: Dictionary = {}
	var exports: Dictionary = {}
	var aggregate_demand: Dictionary = {}

	if typeof(available_supply_value) == TYPE_DICTIONARY:
		available_supply = available_supply_value

	if typeof(actual_consumption_value) == TYPE_DICTIONARY:
		actual_consumption = actual_consumption_value

	if typeof(exports_value) == TYPE_DICTIONARY:
		exports = exports_value

	if typeof(aggregate_demand_value) == TYPE_DICTIONARY:
		aggregate_demand = aggregate_demand_value

	var resource_names: Dictionary = {}
	_collect_keys(resource_names, available_supply)
	_collect_keys(resource_names, actual_consumption)
	_collect_keys(resource_names, exports)
	_collect_keys(resource_names, aggregate_demand)

	var resolved_supply: Dictionary = {}
	var resolved_demand: Dictionary = {}
	var resolved_fulfilled: Dictionary = {}
	var resolved_unmet: Dictionary = {}
	var resolved_surplus: Dictionary = {}
	var resolved_shortage_ratio: Dictionary = {}
	var reconciliation_error: Dictionary = {}
	var supply_demand_ledger: Dictionary = {}

	var total_supply := 0.0
	var total_demand := 0.0
	var total_fulfilled := 0.0
	var total_unmet := 0.0
	var total_surplus := 0.0

	for resource_name in resource_names.keys():

		var resource_id := str(resource_name)

		var supply: float = maxf(
			0.0,
			float(
				available_supply.get(
					resource_id,
					0.0
				)
			)
		)

		var domestic_demand: float = maxf(
			0.0,
			float(
				actual_consumption.get(
					resource_id,
					0.0
				)
			)
		)

		# TradeSystem has already resolved physical export quantity before
		# ResourceSystem. This layer therefore reads the existing exports
		# state and does not reapply port / route constraints.
		var export_demand: float = maxf(
			0.0,
			float(
				exports.get(
					resource_id,
					0.0
				)
			)
		)

		var demand: float = domestic_demand + export_demand
		var fulfilled: float = minf(
			supply,
			demand
		)
		var unmet: float = maxf(
			demand - fulfilled,
			0.0
		)
		var surplus: float = maxf(
			supply - demand,
			0.0
		)

		var shortage_ratio := 0.0
		if demand > 0.0:
			shortage_ratio = (
				(unmet / demand) * 100.0
			)

		shortage_ratio = clampf(
			shortage_ratio,
			0.0,
			100.0
		)

		var supply_error: float = (
			supply
			- fulfilled
			- surplus
		)

		var demand_error: float = (
			demand
			- fulfilled
			- unmet
		)

		# aggregate_demand is the Step 5.3 declared demand signal. The
		# current resolution uses Step 5.4 domestic consumption plus the
		# physically scheduled exports. This diagnostic identifies any
		# mismatch without changing either source state.
		var declared_demand: float = maxf(
			0.0,
			float(
				aggregate_demand.get(
					resource_id,
					0.0
				)
			)
		)

		var declared_demand_error: float = (
			declared_demand
			- demand
		)

		resolved_supply[resource_id] = supply
		resolved_demand[resource_id] = demand
		resolved_fulfilled[resource_id] = fulfilled
		resolved_unmet[resource_id] = unmet
		resolved_surplus[resource_id] = surplus
		resolved_shortage_ratio[resource_id] = shortage_ratio
		reconciliation_error[resource_id] = maxf(
			absf(supply_error),
			absf(demand_error)
		)

		supply_demand_ledger[resource_id] = {
			"available_supply": supply,
			"domestic_demand": domestic_demand,
			"export_demand": export_demand,
			"resolved_demand": demand,
			"declared_aggregate_demand": declared_demand,
			"declared_demand_error": declared_demand_error,
			"fulfilled_demand": fulfilled,
			"unmet_demand": unmet,
			"surplus": surplus,
			"shortage_ratio": shortage_ratio,
			"supply_reconciliation_error": supply_error,
			"demand_reconciliation_error": demand_error,
			"reconciliation_error": reconciliation_error[resource_id]
		}

		total_supply += supply
		total_demand += demand
		total_fulfilled += fulfilled
		total_unmet += unmet
		total_surplus += surplus

	resources.set_state(
		"resolved_supply",
		resolved_supply
	)
	resources.set_state(
		"resolved_demand",
		resolved_demand
	)
	resources.set_state(
		"resolved_fulfilled_demand",
		resolved_fulfilled
	)
	resources.set_state(
		"resolved_unmet_demand",
		resolved_unmet
	)
	resources.set_state(
		"resolved_surplus",
		resolved_surplus
	)
	resources.set_state(
		"resolved_shortage_ratio",
		resolved_shortage_ratio
	)
	resources.set_state(
		"supply_demand_reconciliation_error",
		reconciliation_error
	)
	resources.set_state(
		"supply_demand_ledger",
		supply_demand_ledger
	)
	resources.set_state(
		"supply_demand_total_supply",
		total_supply
	)
	resources.set_state(
		"supply_demand_total_demand",
		total_demand
	)
	resources.set_state(
		"supply_demand_total_fulfilled",
		total_fulfilled
	)
	resources.set_state(
		"supply_demand_total_unmet",
		total_unmet
	)
	resources.set_state(
		"supply_demand_total_surplus",
		total_surplus
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[str(resource_name)] = true
