class_name InfrastructureMaintenanceSystem
extends SimulationSystem


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]

const DEFAULT_MAINTENANCE_COST_RATE := 1.0
const DEFAULT_DEGRADATION_RATE := 0.02
const DEFAULT_REPAIR_RATE := 0.05


func _init() -> void:
	super("infrastructure_maintenance_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"InfrastructureMaintenanceSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(
			entity
		)


func get_condition(
	entity,
	infrastructure_type: String
) -> float:

	if entity == null or not INFRASTRUCTURE_TYPES.has(
		infrastructure_type
	):
		return 0.0

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return 0.0

	var conditions = infrastructure.get_state(
		"infrastructure_condition",
		{}
	)

	if typeof(conditions) != TYPE_DICTIONARY:
		return 0.0

	return clampf(
		float(
			conditions.get(
				infrastructure_type,
				0.0
			)
		),
		0.0,
		1.0
	)


func get_maintenance_requirement(
	entity
) -> float:

	if entity == null:
		return 0.0

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return 0.0

	return maxf(
		float(
			infrastructure.get_state(
				"maintenance_requirement_total",
				0.0
			)
		),
		0.0
	)


func get_process_maintenance_capacity(
	entity,
	maintenance_type: String = "machinery"
) -> float:

	if entity == null:
		return 0.0

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return 0.0

	var process_maintenance_capacity = infrastructure.get_state(
		"process_maintenance_capacity",
		{}
	)

	if typeof(process_maintenance_capacity) != TYPE_DICTIONARY:
		return 0.0

	return clampf(
		float(
			process_maintenance_capacity.get(
				maintenance_type,
				0.0
			)
		),
		0.0,
		1.0
	)


func _process_entity(
	entity
) -> void:

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	var economy = entity.get_component(
		"economy"
	)

	if infrastructure == null or economy == null:
		return

	var conditions = infrastructure.get_state(
		"infrastructure_condition",
		{}
	)

	if typeof(conditions) != TYPE_DICTIONARY:
		conditions = {}

	var effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	if typeof(effective_capacity) != TYPE_DICTIONARY:
		effective_capacity = {}

	var maintenance_requirements = {}
	var maintenance_spending = {}
	var maintenance_shortfall = {}
	var repair_spending = {}
	var funding_ratios = {}

	var total_requirement: float = 0.0

	for infrastructure_type in INFRASTRUCTURE_TYPES:

		var base_capacity = clampf(
			float(
				infrastructure.get_state(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

		var requirement = (
			base_capacity
			* DEFAULT_MAINTENANCE_COST_RATE
		)

		maintenance_requirements[
			infrastructure_type
		] = requirement

		total_requirement += requirement

	if total_requirement <= 0.0:
		infrastructure.set_state(
			"maintenance_requirement_total",
			0.0
		)
		infrastructure.set_state(
			"process_maintenance_capacity",
			{
				"machinery": 0.0
			}
		)
		return

	var budget_enabled = bool(
		economy.get_state(
			"infrastructure_maintenance_budget_enabled",
			false
		)
	)

	var maintenance_budget: float

	if budget_enabled:
		maintenance_budget = maxf(
			float(
				economy.get_state(
					"infrastructure_maintenance_budget",
					0.0
				)
			),
			0.0
		)
	else:
		# Until the economy explicitly controls maintenance funding, assume
		# adequate maintenance so existing worlds do not silently decay.
		maintenance_budget = total_requirement

	var total_spending: float = 0.0
	var total_shortfall: float = 0.0
	var total_repair: float = 0.0

	for infrastructure_type in INFRASTRUCTURE_TYPES:

		var base_capacity = clampf(
			float(
				infrastructure.get_state(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

		var requirement = float(
			maintenance_requirements[
				infrastructure_type
			]
		)

		var allocation = (
			maintenance_budget
			* requirement
			/ total_requirement
		)

		var spending = minf(
			allocation,
			requirement
		)

		var shortfall = maxf(
			requirement - spending,
			0.0
		)

		var repair = maxf(
			allocation - requirement,
			0.0
		)

		var funding_ratio = clampf(
			spending / requirement
			if requirement > 0.0
			else 1.0,
			0.0,
			1.0
		)

		var condition = clampf(
			float(
				conditions.get(
					infrastructure_type,
					1.0
				)
			),
			0.0,
			1.0
		)

		if shortfall > 0.0:
			condition -= (
				1.0 - funding_ratio
			) * DEFAULT_DEGRADATION_RATE

		if repair > 0.0:
			var repair_ratio = repair / requirement
			condition += (
				repair_ratio * DEFAULT_REPAIR_RATE
			)

		condition = clampf(
			condition,
			0.0,
			1.0
		)

		conditions[
			infrastructure_type
		] = condition

		effective_capacity[
			infrastructure_type
		] = clampf(
			base_capacity * condition,
			0.0,
			1.0
		)

		maintenance_spending[
			infrastructure_type
		] = spending

		maintenance_shortfall[
			infrastructure_type
		] = shortfall

		repair_spending[
			infrastructure_type
		] = repair

		funding_ratios[
			infrastructure_type
		] = funding_ratio

		total_spending += spending
		total_shortfall += shortfall
		total_repair += repair

	infrastructure.set_state(
		"infrastructure_condition",
		conditions
	)

	infrastructure.set_state(
		"effective_infrastructure_capacity",
		effective_capacity
	)

	infrastructure.set_state(
		"maintenance_requirement",
		maintenance_requirements
	)

	infrastructure.set_state(
		"maintenance_requirement_total",
		total_requirement
	)

	infrastructure.set_state(
		"maintenance_spending",
		maintenance_spending
	)

	infrastructure.set_state(
		"maintenance_spending_total",
		total_spending
	)

	infrastructure.set_state(
		"maintenance_shortfall",
		maintenance_shortfall
	)

	infrastructure.set_state(
		"maintenance_shortfall_total",
		total_shortfall
	)

	infrastructure.set_state(
		"repair_spending",
		repair_spending
	)

	infrastructure.set_state(
		"repair_spending_total",
		total_repair
	)

	infrastructure.set_state(
		"maintenance_funding_ratio",
		funding_ratios
	)

	infrastructure.set_state(
		"maintenance_budget_this_month",
		maintenance_budget
	)


	# Production maintenance bridge. This is a normalized available
	# maintenance-capacity factor for industrial process maintenance.
	var industrial_effective_capacity = clampf(
		float(
			effective_capacity.get(
				"industrial",
				0.0
			)
		),
		0.0,
		1.0
	)

	var industrial_funding_ratio = clampf(
		float(
			funding_ratios.get(
				"industrial",
				0.0
			)
		),
		0.0,
		1.0
	)

	infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": clampf(
				industrial_effective_capacity
				* industrial_funding_ratio,
				0.0,
				1.0
			)
		}
	)
