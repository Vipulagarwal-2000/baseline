class_name IncomeWageFlowSystem
extends SimulationSystem


const DEFAULT_WAGE_RATE: float = 1.0
const DEFAULT_SKILLED_WAGE_PREMIUM: float = 0.50

var catalog: ProductionProcessCatalog


func _init(process_catalog: ProductionProcessCatalog = null) -> void:
	super("income_wage_flow_system")
	catalog = process_catalog


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("IncomeWageFlowSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var economy = entity.get_component("economy")
		var industry = entity.get_component("industry")

		if economy == null:
			continue

		_process_entity_income(economy, industry)


func _process_entity_income(economy, industry) -> void:

	var base_wage_rate: float = maxf(
		float(
			economy.get_state(
				"base_wage_rate",
				DEFAULT_WAGE_RATE
			)
		),
		0.0
	)

	var skilled_wage_premium: float = maxf(
		float(
			economy.get_state(
				"skilled_wage_premium",
				DEFAULT_SKILLED_WAGE_PREMIUM
			)
		),
		0.0
	)

	var process_states: Dictionary = {}
	var production_states: Dictionary = {}

	if industry != null:
		var raw_processes = industry.get_state("processes", {})
		var raw_production = industry.get_state("production_state", {})

		if typeof(raw_processes) == TYPE_DICTIONARY:
			process_states = raw_processes

		if typeof(raw_production) == TYPE_DICTIONARY:
			production_states = raw_production

	var employed_labor_units: float = 0.0
	var skilled_labor_units: float = 0.0
	var unskilled_labor_units: float = 0.0
	var skilled_labor_income: float = 0.0
	var unskilled_labor_income: float = 0.0
	var labor_income_by_process: Dictionary = {}
	var ledger: Dictionary = {}

	for process_id_value in process_states.keys():

		var process_id: String = str(process_id_value)
		var process_instance = process_states.get(process_id_value, {})

		if typeof(process_instance) != TYPE_DICTIONARY:
			continue

		var outcome = production_states.get(process_id, {})
		if typeof(outcome) != TYPE_DICTIONARY:
			outcome = {}

		var actual_production: float = maxf(
			float(
				outcome.get(
					"actual_production",
					0.0
				)
			),
			0.0
		)

		if not bool(process_instance.get("active", false)):
			actual_production = 0.0

		var labor_requirement: float = _resolve_requirement(
			process_instance,
			process_id,
			"labor_requirement"
		)

		var skilled_labor_requirement: float = _resolve_requirement(
			process_instance,
			process_id,
			"labor_skill_requirement"
		)

		var labor_used: float = actual_production * labor_requirement
		var skilled_labor_used: float = (
			actual_production
			* skilled_labor_requirement
		)

		# Skilled labor is part of total labor. If the source data expresses
		# skilled labor as a subset of general labor, cap it at total labor so
		# the aggregate ledger cannot create negative unskilled employment.
		skilled_labor_used = minf(
			maxf(skilled_labor_used, 0.0),
			maxf(labor_used, 0.0)
		)

		var unskilled_labor_used: float = maxf(
			labor_used - skilled_labor_used,
			0.0
		)

		var wage_multiplier: float = (
			1.0
			+ skilled_wage_premium
		)

		var skilled_income: float = (
			skilled_labor_used
			* base_wage_rate
			* wage_multiplier
		)

		var unskilled_income: float = (
			unskilled_labor_used
			* base_wage_rate
		)

		var process_income: float = (
			skilled_income
			+ unskilled_income
		)

		employed_labor_units += maxf(labor_used, 0.0)
		skilled_labor_units += skilled_labor_used
		unskilled_labor_units += unskilled_labor_used
		skilled_labor_income += skilled_income
		unskilled_labor_income += unskilled_income
		labor_income_by_process[process_id] = process_income

		ledger[process_id] = {
			"active": bool(process_instance.get("active", false)),
			"actual_production": actual_production,
			"labor_requirement": labor_requirement,
			"skilled_labor_requirement": skilled_labor_requirement,
			"labor_used": labor_used,
			"skilled_labor_used": skilled_labor_used,
			"unskilled_labor_used": unskilled_labor_used,
			"wage_rate": base_wage_rate,
			"skilled_wage_multiplier": wage_multiplier,
			"skilled_labor_income": skilled_income,
			"unskilled_labor_income": unskilled_income,
			"labor_income": process_income
		}

	var labor_income: float = (
		skilled_labor_income
		+ unskilled_labor_income
	)

	var average_wage: float = 0.0
	if employed_labor_units > 0.0:
		average_wage = labor_income / employed_labor_units

	var reconciliation_error: float = (
		labor_income
		- (
			skilled_labor_income
			+ unskilled_labor_income
		)
	)

	economy.set_state(
		"base_wage_rate",
		base_wage_rate
	)
	economy.set_state(
		"skilled_wage_premium",
		skilled_wage_premium
	)
	economy.set_state(
		"employed_labor_units",
		employed_labor_units
	)
	economy.set_state(
		"skilled_labor_units",
		skilled_labor_units
	)
	economy.set_state(
		"unskilled_labor_units",
		unskilled_labor_units
	)
	economy.set_state(
		"labor_income",
		labor_income
	)
	economy.set_state(
		"skilled_labor_income",
		skilled_labor_income
	)
	economy.set_state(
		"unskilled_labor_income",
		unskilled_labor_income
	)
	economy.set_state(
		"average_wage",
		average_wage
	)
	economy.set_state(
		"labor_income_by_process",
		labor_income_by_process
	)
	economy.set_state(
		"income_wage_ledger",
		ledger
	)
	economy.set_state(
		"income_flow_reconciliation_error",
		reconciliation_error
	)


func _resolve_requirement(
	process_instance: Dictionary,
	process_id: String,
	field_name: String
) -> float:

	var raw_instance_value = process_instance.get(
		field_name,
		null
	)

	if (
		typeof(raw_instance_value) == TYPE_INT
		or typeof(raw_instance_value) == TYPE_FLOAT
	):
		return maxf(float(raw_instance_value), 0.0)

	if catalog != null and catalog.has_process(process_id):
		var definition = catalog.get_process(process_id)
		if typeof(definition) == TYPE_DICTIONARY:
			var raw_definition_value = definition.get(
				field_name,
				0.0
			)
			if (
				typeof(raw_definition_value) == TYPE_INT
				or typeof(raw_definition_value) == TYPE_FLOAT
			):
				return maxf(float(raw_definition_value), 0.0)

	return 0.0
