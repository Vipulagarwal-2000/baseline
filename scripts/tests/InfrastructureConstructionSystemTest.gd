class_name InfrastructureConstructionSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	if world == null or simulation == null:
		return false

	var construction_system = simulation.get_system(
		"infrastructure_construction_system"
	)

	passed = _check(
		construction_system != null,
		"Infrastructure Construction System registered"
	) and passed

	if construction_system == null:
		return false

	passed = _check(
		construction_system is InfrastructureConstructionSystem,
		"Infrastructure Construction System type"
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

	var infrastructure = india.get_component(
		"infrastructure"
	)

	var economy = india.get_component(
		"economy"
	)

	passed = _check(
		infrastructure != null,
		"India InfrastructureComponent"
	) and passed

	passed = _check(
		economy != null,
		"India EconomyComponent"
	) and passed

	if infrastructure == null or economy == null:
		return false

	var original_railways: float = float(
		infrastructure.get_state(
			"railways",
			0.0
		)
	)

	var original_treasury: float = float(
		economy.get_state(
			"treasury",
			0.0
		)
	)

	var original_unallocated: float = float(
		economy.get_state(
			"unallocated_industrial_capacity",
			0.0
		)
	)

	var original_investment_budget: float = float(
		economy.get_state(
			"infrastructure_investment_budget",
			0.0
		)
	)

	var original_projects_value: Variant = infrastructure.get_state(
		"construction_projects",
		[]
	)

	var original_projects: Array = []

	if typeof(original_projects_value) == TYPE_ARRAY:
		original_projects = original_projects_value as Array

	# Baseline: no infrastructure investment budget means the project falls back to treasury.
	infrastructure.set_state(
		"construction_projects",
		[]
	)

	economy.set_state(
		"treasury",
		100.0
	)

	economy.set_state(
		"infrastructure_investment_budget",
		0.0
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		10.0
	)

	infrastructure.set_state(
		"railways",
		0.30
	)

	var created_project: Dictionary = (
		construction_system.create_project(
			india,
			"railways",
			0.20,
			40.0,
			2.0,
			3
		)
	)

	passed = _check(
		not created_project.is_empty(),
		"Infrastructure construction project created"
	) and passed

	var projects_after_creation: Array = (
		construction_system.get_projects(
			india
		)
	)

	passed = _check(
		projects_after_creation.size() == 1,
		"Construction project stored"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					-1.0
				)
			),
			60.0
		),
		"Construction money cost reserved from treasury"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				economy.get_state(
					"infrastructure_investment_budget",
					-1.0
				)
			),
			0.0
		),
		"No infrastructure investment budget consumed when budget is empty"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				created_project.get(
					"investment_funded",
					-1.0
				)
			),
			0.0
		),
		"Treasury-only project records zero investment funding"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				created_project.get(
					"treasury_funded",
					-1.0
				)
			),
			40.0
		),
		"Treasury-only project records full treasury funding"
	) and passed

	construction_system.process_month(
		world
	)

	var month_one_projects: Array = (
		construction_system.get_projects(
			india
		)
	)

	var month_one_project: Dictionary = month_one_projects[0]

	passed = _check(
		is_equal_approx(
			float(
				month_one_project.get(
					"progress",
					-1.0
				)
			),
			1.0 / 3.0
		),
		"Construction month 1 progress = 1/3"
	) and passed

	passed = _check(
		str(
			month_one_project.get(
				"status",
				""
			)
		) == "active",
		"Construction remains active after month 1"
	) and passed

	construction_system.process_month(
		world
	)

	var month_two_projects: Array = (
		construction_system.get_projects(
			india
		)
	)

	var month_two_project: Dictionary = month_two_projects[0]

	passed = _check(
		is_equal_approx(
			float(
				month_two_project.get(
					"progress",
					-1.0
				)
			),
			2.0 / 3.0
		),
		"Construction month 2 progress = 2/3"
	) and passed

	passed = _check(
		str(
			month_two_project.get(
				"status",
				""
			)
		) == "active",
		"Construction remains active after month 2"
	) and passed

	construction_system.process_month(
		world
	)

	var completed_projects: Array = (
		construction_system.get_projects(
			india
		)
	)

	var completed_project: Dictionary = completed_projects[0]

	passed = _check(
		is_equal_approx(
			float(
				completed_project.get(
					"progress",
					-1.0
				)
			),
			1.0
		),
		"Construction completion progress = 1.0"
	) and passed

	passed = _check(
		str(
			completed_project.get(
				"status",
				""
			)
		) == "completed",
		"Construction project completed"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				infrastructure.get_state(
					"railways",
					-1.0
				)
			),
			0.50
		),
		"Railways capacity increases on completion"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				completed_project.get(
					"applied_capacity_gain",
					-1.0
				)
			),
			0.20
		),
		"Applied infrastructure capacity gain recorded"
	) and passed

	# Integration: accumulated infrastructure investment budget funds construction before treasury.
	infrastructure.set_state(
		"construction_projects",
		[]
	)

	infrastructure.set_state(
		"railways",
		original_railways
	)

	economy.set_state(
		"treasury",
		0.0
	)

	economy.set_state(
		"infrastructure_investment_budget",
		40.0
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		10.0
	)

	var investment_funded_project: Dictionary = (
		construction_system.create_project(
			india,
			"railways",
			0.10,
			40.0,
			2.0,
			1
		)
	)

	passed = _check(
		not investment_funded_project.is_empty(),
		"Infrastructure investment budget can fund construction"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				economy.get_state(
					"infrastructure_investment_budget",
					-1.0
				)
			),
			0.0
		),
		"Infrastructure investment budget is consumed by construction"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				economy.get_state(
					"treasury",
					-1.0
				)
			),
			0.0
		),
		"Treasury remains unchanged when investment budget fully funds construction"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				investment_funded_project.get(
					"investment_funded",
					-1.0
				)
			),
			40.0
		),
		"Project records infrastructure investment funding"
	) and passed

	passed = _check(
		is_equal_approx(
			float(
				investment_funded_project.get(
					"treasury_funded",
					-1.0
				)
			),
			0.0
		),
		"Investment-funded project records zero treasury funding"
	) and passed

	passed = _check(
		str(
			investment_funded_project.get(
				"funding_source",
				""
			)
		) == "infrastructure_investment",
		"Investment-funded project records funding source"
	) and passed

	infrastructure.set_state(
		"railways",
		original_railways
	)

	economy.set_state(
		"treasury",
		original_treasury
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		original_unallocated
	)

	economy.set_state(
		"infrastructure_investment_budget",
		original_investment_budget
	)

	infrastructure.set_state(
		"construction_projects",
		original_projects
	)

	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:

	print(
		"Infrastructure Construction System ",
		label,
		": ",
		"PASS" if condition else "FAIL"
	)

	return condition
