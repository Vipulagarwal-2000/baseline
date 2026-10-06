class_name PurchasingPowerSystem
extends SimulationSystem


const DEFAULT_PRICE_INDEX: float = 1.0
const EPSILON: float = 0.000001


func _init() -> void:
	super("purchasing_power_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("PurchasingPowerSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var economy = entity.get_component("economy")
		var resources = entity.get_component("resources")

		if economy == null:
			continue

		_process_entity_purchasing_power(
			economy,
			resources
		)


func _process_entity_purchasing_power(
	economy,
	resources
) -> void:

	var labor_income: float = maxf(
		float(
			economy.get_state(
				"labor_income",
				0.0
			)
		),
		0.0
	)

	var average_wage: float = maxf(
		float(
			economy.get_state(
				"average_wage",
				0.0
			)
		),
		0.0
	)

	var employed_labor_units: float = maxf(
		float(
			economy.get_state(
				"employed_labor_units",
				0.0
			)
		),
		0.0
	)

	var current_price: Dictionary = {}
	var base_price: Dictionary = {}
	var population_consumption: Dictionary = {}

	if resources != null:
		var raw_current_price = resources.get_state(
			"current_price",
			{}
		)
		var raw_base_price = resources.get_state(
			"base_price",
			{}
		)
		var raw_consumption = resources.get_state(
			"consumption_by_category",
			{}
		)

		if typeof(raw_current_price) == TYPE_DICTIONARY:
			current_price = raw_current_price

		if typeof(raw_base_price) == TYPE_DICTIONARY:
			base_price = raw_base_price

		if typeof(raw_consumption) == TYPE_DICTIONARY:
			var population_value = raw_consumption.get(
				"population",
				{}
			)
			if typeof(population_value) == TYPE_DICTIONARY:
				population_consumption = population_value

	var current_basket_cost: float = 0.0
	var base_basket_cost: float = 0.0
	var basket_ledger: Dictionary = {}

	var resource_names: Dictionary = {}
	for resource_name_value in population_consumption.keys():
		resource_names[str(resource_name_value)] = true
	for resource_name_value in current_price.keys():
		resource_names[str(resource_name_value)] = true
	for resource_name_value in base_price.keys():
		resource_names[str(resource_name_value)] = true

	for resource_name_value in resource_names.keys():

		var resource_name: String = str(resource_name_value)

		var quantity: float = maxf(
			float(
				population_consumption.get(
					resource_name,
					0.0
				)
			),
			0.0
		)

		var current_unit_price: float = maxf(
			float(
				current_price.get(
					resource_name,
					base_price.get(
						resource_name,
						1.0
					)
				)
			),
			0.0
		)

		var base_unit_price: float = maxf(
			float(
				base_price.get(
					resource_name,
					current_unit_price if current_unit_price > 0.0 else 1.0
				)
			),
			0.0
		)

		var current_cost: float = quantity * current_unit_price
		var base_cost: float = quantity * base_unit_price

		current_basket_cost += current_cost
		base_basket_cost += base_cost

		basket_ledger[resource_name] = {
			"quantity": quantity,
			"current_unit_price": current_unit_price,
			"base_unit_price": base_unit_price,
			"current_cost": current_cost,
			"base_cost": base_cost
		}

	var price_index: float = DEFAULT_PRICE_INDEX
	if base_basket_cost > EPSILON:
		price_index = maxf(
			current_basket_cost / base_basket_cost,
			0.0
		)

	var real_labor_income: float = labor_income
	var real_average_wage: float = average_wage

	if price_index > EPSILON:
		real_labor_income = labor_income / price_index
		real_average_wage = average_wage / price_index

	var purchasing_power: float = maxf(
		real_average_wage,
		0.0
	)

	var purchasing_power_index: float = 1.0
	if average_wage > EPSILON:
		purchasing_power_index = purchasing_power / average_wage
	else:
		purchasing_power_index = 0.0

	var income_coverage_ratio: float = 0.0
	if current_basket_cost > EPSILON:
		income_coverage_ratio = labor_income / current_basket_cost

	var ledger: Dictionary = {
		"labor_income": labor_income,
		"average_wage": average_wage,
		"employed_labor_units": employed_labor_units,
		"population_consumption_cost": current_basket_cost,
		"base_population_consumption_cost": base_basket_cost,
		"price_index": price_index,
		"real_labor_income": real_labor_income,
		"real_average_wage": real_average_wage,
		"purchasing_power": purchasing_power,
		"purchasing_power_index": purchasing_power_index,
		"income_coverage_ratio": income_coverage_ratio,
		"basket": basket_ledger
	}

	economy.set_state(
		"population_consumption_cost",
		current_basket_cost
	)
	economy.set_state(
		"base_population_consumption_cost",
		base_basket_cost
	)
	economy.set_state(
		"consumption_price_index",
		price_index
	)
	economy.set_state(
		"real_labor_income",
		real_labor_income
	)
	economy.set_state(
		"real_average_wage",
		real_average_wage
	)
	economy.set_state(
		"purchasing_power",
		purchasing_power
	)
	economy.set_state(
		"purchasing_power_index",
		purchasing_power_index
	)
	economy.set_state(
		"income_coverage_ratio",
		income_coverage_ratio
	)
	economy.set_state(
		"purchasing_power_ledger",
		ledger
	)
