class_name BasicPriceFormationSystem
extends SimulationSystem


const DEFAULT_BASE_PRICE: float = 1.0
const MIN_PRICE_MODIFIER: float = 0.5
const MAX_PRICE_MODIFIER: float = 2.0


func _init():
	super("basic_price_formation_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("BasicPriceFormationSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var resources = entity.get_component("resources")

		if resources == null:
			continue

		_process_entity_prices(resources)


func _process_entity_prices(resources: ResourceComponent) -> void:

	var base_price_value = resources.get_state("base_price", {})
	var resolved_supply_value = resources.get_state("resolved_supply", {})
	var resolved_demand_value = resources.get_state("resolved_demand", {})
	var resolved_surplus_value = resources.get_state("resolved_surplus", {})
	var resolved_shortage_ratio_value = resources.get_state(
		"resolved_shortage_ratio",
		{}
	)

	var base_price: Dictionary = {}
	var resolved_supply: Dictionary = {}
	var resolved_demand: Dictionary = {}
	var resolved_surplus: Dictionary = {}
	var resolved_shortage_ratio: Dictionary = {}

	if typeof(base_price_value) == TYPE_DICTIONARY:
		base_price = base_price_value

	if typeof(resolved_supply_value) == TYPE_DICTIONARY:
		resolved_supply = resolved_supply_value

	if typeof(resolved_demand_value) == TYPE_DICTIONARY:
		resolved_demand = resolved_demand_value

	if typeof(resolved_surplus_value) == TYPE_DICTIONARY:
		resolved_surplus = resolved_surplus_value

	if typeof(resolved_shortage_ratio_value) == TYPE_DICTIONARY:
		resolved_shortage_ratio = resolved_shortage_ratio_value

	var resource_names: Dictionary = {}
	_collect_keys(resource_names, base_price)
	_collect_keys(resource_names, resolved_supply)
	_collect_keys(resource_names, resolved_demand)
	_collect_keys(resource_names, resolved_surplus)
	_collect_keys(resource_names, resolved_shortage_ratio)

	var scarcity_modifiers: Dictionary = {}
	var surplus_modifiers: Dictionary = {}
	var price_modifiers: Dictionary = {}
	var current_prices: Dictionary = {}
	var price_ledger: Dictionary = {}

	for resource_name_value in resource_names.keys():

		var resource_name: String = str(resource_name_value)

		var base: float = maxf(
			float(base_price.get(resource_name, DEFAULT_BASE_PRICE)),
			0.0
		)

		var supply: float = maxf(
			float(resolved_supply.get(resource_name, 0.0)),
			0.0
		)

		var demand: float = maxf(
			float(resolved_demand.get(resource_name, 0.0)),
			0.0
		)

		var surplus: float = maxf(
			float(resolved_surplus.get(resource_name, 0.0)),
			0.0
		)

		var shortage_ratio: float = clampf(
			float(resolved_shortage_ratio.get(resource_name, 0.0)),
			0.0,
			100.0
		)

		# Step 5.5 already owns the shortage calculation. A 50% shortage
		# therefore creates a 1.5x scarcity multiplier here; a full shortage
		# creates a 2.0x multiplier.
		var scarcity_modifier: float = 1.0 + (shortage_ratio / 100.0)
		scarcity_modifier = clampf(
			scarcity_modifier,
			1.0,
			MAX_PRICE_MODIFIER
		)

		# Surplus is normalized against available supply. This keeps the
		# relief signal bounded and avoids a second market-clearing model.
		var surplus_ratio: float = 0.0
		if supply > 0.0:
			surplus_ratio = clampf(
				surplus / supply,
				0.0,
				1.0
			)

		var surplus_modifier: float = 1.0 - (0.5 * surplus_ratio)
		surplus_modifier = clampf(
			surplus_modifier,
			MIN_PRICE_MODIFIER,
			1.0
		)

		var price_modifier: float = clampf(
			scarcity_modifier * surplus_modifier,
			MIN_PRICE_MODIFIER,
			MAX_PRICE_MODIFIER
		)

		var current_price: float = base * price_modifier

		scarcity_modifiers[resource_name] = scarcity_modifier
		surplus_modifiers[resource_name] = surplus_modifier
		price_modifiers[resource_name] = price_modifier
		current_prices[resource_name] = current_price

		price_ledger[resource_name] = {
			"base_price": base,
			"resolved_supply": supply,
			"resolved_demand": demand,
			"resolved_surplus": surplus,
			"resolved_shortage_ratio": shortage_ratio,
			"surplus_ratio": surplus_ratio,
			"scarcity_modifier": scarcity_modifier,
			"surplus_modifier": surplus_modifier,
			"price_modifier": price_modifier,
			"current_price": current_price
		}

	resources.set_state(
		"scarcity_price_modifier",
		scarcity_modifiers
	)
	resources.set_state(
		"surplus_price_modifier",
		surplus_modifiers
	)
	resources.set_state(
		"price_modifier",
		price_modifiers
	)
	resources.set_state(
		"current_price",
		current_prices
	)
	resources.set_state(
		"price_formation_ledger",
		price_ledger
	)


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[str(resource_name)] = true
