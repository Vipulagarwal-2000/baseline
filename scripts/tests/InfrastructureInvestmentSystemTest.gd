class_name InfrastructureInvestmentSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	if world == null or simulation == null:
		return false

	var investment_system = simulation.get_system(
		"infrastructure_investment_system"
	)

	passed = _check(
		investment_system != null,
		"Infrastructure Investment System registered"
	) and passed

	if investment_system == null:
		return false

	passed = _check(
		investment_system is InfrastructureInvestmentSystem,
		"Infrastructure Investment System type"
	) and passed

	var india = world.get_entity(
		"india"
	)

	passed = _check(
		india != null,
		"India available"
	) and passed

	if india == null:
		return false

	var economy = india.get_component(
		"economy"
	)

	passed = _check(
		economy != null,
		"India EconomyComponent"
	) and passed

	if economy == null:
		return false

	var original_investment: float = float(
		economy.get_state(
			"investment",
			0.0
		)
	)

	var original_rate: float = float(
		economy.get_state(
			"infrastructure_investment_rate",
			0.25
		)
	)

	var original_budget: float = float(
		economy.get_state(
			"infrastructure_investment_budget",
			0.0
		)
	)

	var original_monthly_allocation: float = float(
		economy.get_state(
			"infrastructure_investment_this_month",
			0.0
		)
	)

	economy.set_state(
		"investment",
		100.0
	)

	economy.set_state(
		"infrastructure_investment_rate",
		0.25
	)

	economy.set_state(
		"infrastructure_investment_budget",
		0.0
	)

	investment_system.process_month(
		world
	)

	passed = _check(
		is_equal_approx(
			investment_system.get_monthly_allocation(
				india
			),
			25.0
		),
		"25% investment allocation produces monthly infrastructure budget = 25"
	) and passed

	passed = _check(
		is_equal_approx(
			investment_system.get_investment_budget(
				india
			),
			25.0
		),
		"Infrastructure investment budget accumulates = 25"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				economy.get_state(
					"investment",
					-1.0
				)
			),
			100.0
		),
		"Investment flow remains unchanged by allocation"
	) and passed

	economy.set_state(
		"investment",
		0.0
	)

	investment_system.process_month(
		world
	)

	passed = _check(
		is_equal_approx(
			investment_system.get_monthly_allocation(
				india
			),
			0.0
		),
		"Zero investment produces zero monthly infrastructure allocation"
	) and passed

	passed = _check(
		is_equal_approx(
			investment_system.get_investment_budget(
				india
			),
			25.0
		),
		"Existing infrastructure investment budget is preserved"
	) and passed

	economy.set_state(
		"investment",
		original_investment
	)

	economy.set_state(
		"investment",
		original_investment
	)

	economy.set_state(
		"infrastructure_investment_rate",
		original_rate
	)

	economy.set_state(
		"infrastructure_investment_budget",
		original_budget
	)

	economy.set_state(
		"infrastructure_investment_this_month",
		original_monthly_allocation
	)

	return passed

static func _check(
	condition: bool,
	label: String
) -> bool:

	print(
		"Infrastructure Investment System ",
		label,
		": ",
		"PASS" if condition else "FAIL"
	)

	return condition
