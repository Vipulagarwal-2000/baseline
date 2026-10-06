class_name InfrastructureMaintenanceSystemTest
extends RefCounted


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	if world == null or simulation == null:
		return false

	var maintenance_system = simulation.get_system(
		"infrastructure_maintenance_system"
	)

	passed = _check(
		maintenance_system != null,
		"Infrastructure Maintenance System registered"
	) and passed

	if maintenance_system == null:
		return false

	passed = _check(
		maintenance_system is InfrastructureMaintenanceSystem,
		"Infrastructure Maintenance System type"
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

	var original_state := {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		original_state[infrastructure_type] = infrastructure.get_state(
			infrastructure_type,
			0.0
		)

	var original_condition = infrastructure.get_state(
		"infrastructure_condition",
		{}
	)

	var original_effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var original_maintenance_budget = economy.get_state(
		"infrastructure_maintenance_budget",
		0.0
	)

	var original_budget_enabled = economy.get_state(
		"infrastructure_maintenance_budget_enabled",
		false
	)

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		infrastructure.set_state(
			infrastructure_type,
			0.5
		)

	economy.set_state(
		"infrastructure_maintenance_budget_enabled",
		true
	)

	economy.set_state(
		"infrastructure_maintenance_budget",
		0.0
	)

	maintenance_system.process_month(
		world
	)

	var degraded_condition = maintenance_system.get_condition(
		india,
		"transport"
	)

	passed = _check(
		is_equal_approx(
			degraded_condition,
			0.98
		),
		"Zero maintenance causes controlled degradation"
	) and passed

	var degraded_effective_capacity = float(
		infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		).get(
			"transport",
			-1.0
		)
	)

	passed = _check(
		is_equal_approx(
			degraded_effective_capacity,
			0.49
		),
		"Degraded condition reduces effective infrastructure capacity"
	) and passed

	var requirement_total = maintenance_system.get_maintenance_requirement(
		india
	)

	passed = _check(
		is_equal_approx(
			requirement_total,
			3.5
		),
		"Maintenance requirement scales with infrastructure capacity"
	) and passed

	economy.set_state(
		"infrastructure_maintenance_budget",
		requirement_total
	)

	maintenance_system.process_month(
		world
	)

	var stabilized_condition = maintenance_system.get_condition(
		india,
		"transport"
	)

	passed = _check(
		is_equal_approx(
			stabilized_condition,
			0.98
		),
		"Adequate maintenance stabilizes condition"
	) and passed

	economy.set_state(
		"infrastructure_maintenance_budget",
		requirement_total * 2.0
	)

	maintenance_system.process_month(
		world
	)

	var repaired_condition = maintenance_system.get_condition(
		india,
		"transport"
	)

	passed = _check(
		is_equal_approx(
			repaired_condition,
			1.0
		),
		"Excess maintenance spending repairs degraded condition"
	) and passed

	passed = _check(
		infrastructure.get_state(
			"maintenance_spending_total",
			-1.0
		) > 0.0,
		"Maintenance spending is recorded"
	) and passed

	passed = _check(
		infrastructure.get_state(
			"maintenance_shortfall_total",
			-1.0
		) == 0.0,
		"Adequate maintenance leaves no shortfall"
	) and passed

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		infrastructure.set_state(
			infrastructure_type,
			original_state[infrastructure_type]
		)

	infrastructure.set_state(
		"infrastructure_condition",
		original_condition
	)

	infrastructure.set_state(
		"effective_infrastructure_capacity",
		original_effective_capacity
	)

	economy.set_state(
		"infrastructure_maintenance_budget",
		original_maintenance_budget
	)

	economy.set_state(
		"infrastructure_maintenance_budget_enabled",
		original_budget_enabled
	)

	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:

	print(
		"Infrastructure Maintenance System ",
		label,
		": ",
		"PASS" if condition else "FAIL"
	)

	return condition
