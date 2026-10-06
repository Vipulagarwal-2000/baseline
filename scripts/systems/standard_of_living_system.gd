class_name StandardOfLivingSystem
extends SimulationSystem


# ============================================================
# POPULATION — STEP 9.1
# STANDARD OF LIVING
# ============================================================
#
# Aggregate living-conditions index only.
#
# Authoritative inputs are existing state owned by:
# - EconomyComponent
# - PopulationComponent / LaborSystem
# - ResourceComponent
# - GovernmentComponent
#
# No individual citizens are simulated.
# No new resource, income, price, labor, or public-service model
# is introduced here.
#
# MVP formula:
#
# income score
# + food availability
# + essential-goods availability
# + employment
# + public-service capacity
# - price pressure
# ------------------------------------------------------------
# / 5.0
#
# Every input is normalized to 0..1 before aggregation.
# The final index is clamped to 0..1.
# ============================================================


const EPSILON: float = 0.000001
const DEFAULT_NEUTRAL_AVAILABILITY: float = 1.0
const SCORE_DIVISOR: float = 5.0


func _init() -> void:
	super("standard_of_living_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"StandardOfLivingSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(entity)


func _process_entity(
	entity
) -> void:

	var population = entity.get_component(
		"population"
	)

	if population == null:
		return

	var economy = entity.get_component(
		"economy"
	)

	var resources = entity.get_component(
		"resources"
	)

	var government = entity.get_component(
		"government"
	)

	var income_score := _resolve_income_score(
		economy
	)

	var food_availability := _resolve_food_availability(
		resources
	)

	var essential_goods_availability := _resolve_essential_goods_availability(
		resources,
		food_availability
	)

	var employment_score := _resolve_employment_score(
		population,
		economy
	)

	var public_service_score := _resolve_public_service_score(
		government
	)

	var price_pressure := _resolve_price_pressure(
		economy
	)

	var raw_index := (
		income_score
		+ food_availability
		+ essential_goods_availability
		+ employment_score
		+ public_service_score
		- price_pressure
	) / SCORE_DIVISOR

	var standard_of_living_index := clampf(
		raw_index,
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"income_score": income_score,
		"food_availability": food_availability,
		"essential_goods_availability": essential_goods_availability,
		"employment_score": employment_score,
		"public_service_score": public_service_score,
		"price_pressure": price_pressure,
		"raw_index": raw_index,
		"standard_of_living_index": standard_of_living_index
	}

	var current_index := float(
		population.get_state(
			"standard_of_living_index",
			0.0
		)
	)

	var current_income := float(
		population.get_state(
			"standard_of_living_income_score",
			0.0
		)
	)

	var current_food := float(
		population.get_state(
			"standard_of_living_food_availability",
			0.0
		)
	)

	var current_essential := float(
		population.get_state(
			"standard_of_living_essential_goods_availability",
			0.0
		)
	)

	var current_employment := float(
		population.get_state(
			"standard_of_living_employment_score",
			0.0
		)
	)

	var current_public_services := float(
		population.get_state(
			"standard_of_living_public_service_score",
			0.0
		)
	)

	var current_price_pressure := float(
		population.get_state(
			"standard_of_living_price_pressure",
			0.0
		)
	)

	var unchanged: bool = (
		is_equal_approx(
			current_index,
			standard_of_living_index
		)
		and is_equal_approx(
			current_income,
			income_score
		)
		and is_equal_approx(
			current_food,
			food_availability
		)
		and is_equal_approx(
			current_essential,
			essential_goods_availability
		)
		and is_equal_approx(
			current_employment,
			employment_score
		)
		and is_equal_approx(
			current_public_services,
			public_service_score
		)
		and is_equal_approx(
			current_price_pressure,
			price_pressure
		)
	)

	if unchanged:

		population.set_state(
			"standard_of_living_ledger",
			ledger
		)

		population.set_state(
			"standard_of_living_last_result",
			{
				"action": "no_change",
				"revision": int(
					population.get_state(
						"standard_of_living_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)

		return

	var revision := int(
		population.get_state(
			"standard_of_living_revision",
			0
		)
	) + 1

	population.set_state(
		"standard_of_living_income_score",
		income_score
	)

	population.set_state(
		"standard_of_living_food_availability",
		food_availability
	)

	population.set_state(
		"standard_of_living_essential_goods_availability",
		essential_goods_availability
	)

	population.set_state(
		"standard_of_living_employment_score",
		employment_score
	)

	population.set_state(
		"standard_of_living_public_service_score",
		public_service_score
	)

	population.set_state(
		"standard_of_living_price_pressure",
		price_pressure
	)

	population.set_state(
		"standard_of_living_index",
		standard_of_living_index
	)

	population.set_state(
		"standard_of_living_revision",
		revision
	)

	population.set_state(
		"standard_of_living_ledger",
		ledger
	)

	population.set_state(
		"standard_of_living_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)


func _resolve_income_score(
	economy
) -> float:

	if economy == null:
		return DEFAULT_NEUTRAL_AVAILABILITY

	var coverage := maxf(
		float(
			economy.get_state(
				"income_coverage_ratio",
				0.0
			)
		),
		0.0
	)

	if coverage > EPSILON:
		return clampf(
			coverage,
			0.0,
			1.0
		)

	var purchasing_power_index := maxf(
		float(
			economy.get_state(
				"purchasing_power_index",
				1.0
			)
		),
		0.0
	)

	return clampf(
		purchasing_power_index,
		0.0,
		1.0
	)


func _resolve_food_availability(
	resources
) -> float:

	var population_demand := _get_population_resource_demand(
		resources
	)

	if population_demand.is_empty():
		return DEFAULT_NEUTRAL_AVAILABILITY

	var fulfillment := _get_population_fulfillment(
		resources
	)

	if not population_demand.has("food"):
		return _resolve_weighted_population_fulfillment(
			resources,
			population_demand,
			fulfillment
		)

	var food_claim := maxf(
		float(
			population_demand.get(
				"food",
				0.0
			)
		),
		0.0
	)

	return clampf(
		_resolve_population_resource_fulfillment(
			resources,
			"food",
			food_claim,
			fulfillment
		),
		0.0,
		1.0
	)


func _resolve_essential_goods_availability(
	resources,
	food_availability: float
) -> float:

	var population_demand := _get_population_resource_demand(
		resources
	)

	if population_demand.is_empty():
		return DEFAULT_NEUTRAL_AVAILABILITY

	var fulfillment := _get_population_fulfillment(
		resources
	)

	var weighted_sum := 0.0
	var total_weight := 0.0

	for resource_id_value in population_demand.keys():

		var resource_id := str(
			resource_id_value
		)

		if resource_id == "food":
			continue

		var claim := maxf(
			float(
				population_demand.get(
					resource_id_value,
					0.0
				)
			),
			0.0
		)

		if claim <= EPSILON:
			continue

		var ratio := _resolve_population_resource_fulfillment(
			resources,
			resource_id,
			claim,
			fulfillment
		)

		weighted_sum += (
			ratio
			* claim
		)

		total_weight += claim

	if total_weight <= EPSILON:
		return clampf(
			food_availability,
			0.0,
			1.0
		)

	return clampf(
		weighted_sum / total_weight,
		0.0,
		1.0
	)


func _resolve_weighted_population_fulfillment(
	resources,
	population_demand: Dictionary,
	fulfillment: Dictionary
) -> float:

	var weighted_sum := 0.0
	var total_weight := 0.0

	for resource_id_value in population_demand.keys():

		var resource_id := str(
			resource_id_value
		)

		var claim := maxf(
			float(
				population_demand.get(
					resource_id_value,
					0.0
				)
			),
			0.0
		)

		if claim <= EPSILON:
			continue

		var ratio := _resolve_population_resource_fulfillment(
			resources,
			resource_id,
			claim,
			fulfillment
		)

		weighted_sum += (
			ratio
			* claim
		)

		total_weight += claim

	if total_weight <= EPSILON:
		return DEFAULT_NEUTRAL_AVAILABILITY

	return clampf(
		weighted_sum / total_weight,
		0.0,
		1.0
	)


func _resolve_population_resource_fulfillment(
	resources,
	resource_id: String,
	claim: float,
	fulfillment: Dictionary
) -> float:

	var resource_map_value: Variant = fulfillment.get(
		resource_id,
		{}
	)

	if typeof(resource_map_value) == TYPE_DICTIONARY:

		var population_value = resource_map_value.get(
			"population",
			null
		)

		if (
			population_value is int
			or population_value is float
		):
			return clampf(
				float(population_value),
				0.0,
				1.0
			)

	var actual_consumption := _get_actual_population_consumption(
		resources,
		resource_id
	)

	if claim > EPSILON:
		return clampf(
			actual_consumption / claim,
			0.0,
			1.0
		)

	return DEFAULT_NEUTRAL_AVAILABILITY


func _resolve_employment_score(
	population,
	economy
) -> float:

	var labor_state_value: Variant = population.get_state(
		"labor_state",
		{}
	)

	if typeof(labor_state_value) == TYPE_DICTIONARY:

		var labor_state: Dictionary = (
			labor_state_value
		)

		var labor_force := maxf(
			float(
				labor_state.get(
					"labor_force",
					0.0
				)
			),
			0.0
		)

		if labor_force > EPSILON:

			var employed := maxf(
				float(
					labor_state.get(
						"employed_labor",
						0.0
					)
				),
				0.0
			)

			return clampf(
				employed / labor_force,
				0.0,
				1.0
			)

	if economy != null:

		var unemployment_raw := float(
			economy.get_state(
				"unemployment",
				0.0
			)
		)

		if unemployment_raw > 1.0:
			unemployment_raw /= 100.0

		return clampf(
			1.0 - unemployment_raw,
			0.0,
			1.0
		)

	return DEFAULT_NEUTRAL_AVAILABILITY


func _resolve_public_service_score(
	government
) -> float:

	if government == null:
		return 0.0

	return clampf(
		float(
			government.get_state(
				"public_service_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)


func _resolve_price_pressure(
	economy
) -> float:

	if economy == null:
		return 0.0

	var price_index := maxf(
		float(
			economy.get_state(
				"consumption_price_index",
				1.0
			)
		),
		0.0
	)

	return clampf(
		price_index - 1.0,
		0.0,
		1.0
	)


func _get_population_resource_demand(
	resources
) -> Dictionary:

	if resources == null:
		return {}

	var value = resources.get_state(
		"population_resource_demand",
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value


func _get_population_fulfillment(
	resources
) -> Dictionary:

	if resources == null:
		return {}

	var value = resources.get_state(
		"priority_allocation_fulfillment_ratio_by_category",
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value


func _get_actual_population_consumption(
	resources,
	resource_id: String
) -> float:

	if resources == null:
		return 0.0

	var value = resources.get_state(
		"actual_consumption",
		{}
	)

	if typeof(value) != TYPE_DICTIONARY:
		return 0.0

	return maxf(
		float(
			value.get(
				resource_id,
				0.0
			)
		),
		0.0
	)
