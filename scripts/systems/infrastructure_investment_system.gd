class_name InfrastructureInvestmentSystem
extends SimulationSystem


const DEFAULT_INFRASTRUCTURE_INVESTMENT_RATE := 0.25


func _init() -> void:
	super("infrastructure_investment_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"InfrastructureInvestmentSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_update_entity(
			entity
		)


func get_investment_budget(
	entity
) -> float:

	if entity == null:
		return 0.0

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		return 0.0

	return maxf(
		float(
			economy.get_state(
				"infrastructure_investment_budget",
				0.0
			)
		),
		0.0
	)


func get_monthly_allocation(
	entity
) -> float:

	if entity == null:
		return 0.0

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		return 0.0

	return maxf(
		float(
			economy.get_state(
				"infrastructure_investment_this_month",
				0.0
			)
		),
		0.0
	)


func _update_entity(
	entity
) -> void:

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		return

	var investment: float = maxf(
		float(
			economy.get_state(
				"investment",
				0.0
			)
		),
		0.0
	)

	var allocation_rate: float = clampf(
		float(
			economy.get_state(
				"infrastructure_investment_rate",
				DEFAULT_INFRASTRUCTURE_INVESTMENT_RATE
			)
		),
		0.0,
		1.0
	)

	var previous_budget: float = maxf(
		float(
			economy.get_state(
				"infrastructure_investment_budget",
				0.0
			)
		),
		0.0
	)

	var monthly_allocation: float = (
		investment
		* allocation_rate
	)

	var new_budget: float = (
		previous_budget
		+ monthly_allocation
	)

	economy.set_state(
		"infrastructure_investment_rate",
		allocation_rate
	)

	economy.set_state(
		"infrastructure_investment_this_month",
		monthly_allocation
	)

	economy.set_state(
		"infrastructure_investment_budget",
		new_budget
	)
