class_name MilitaryResourceReadinessTest
extends RefCounted


static func _out(values: Array) -> void:
	var message := ""
	for value in values:
		message += str(value)
	TestLogger.write_line(message)


static func _log_result(
	label: String,
	passed: bool
) -> void:
	_out([
		label,
		": ",
		"PASS" if passed else "FAIL"
	])


static func _approx_equal(
	actual: float,
	expected: float
) -> bool:
	return is_equal_approx(actual, expected)


static func _in_range(value: float) -> bool:
	return value >= -0.000001 and value <= 1.000001


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["============================================================"])
	_out(["STEP 13.2 — RESOURCES → MILITARY READINESS TEST"])
	_out(["============================================================"])

	if world == null:
		_out(["World available: FAIL"])
		return false

	_out(["World available: PASS"])

	if simulation == null:
		_out(["Simulation available: FAIL"])
		return false

	_out(["Simulation available: PASS"])

	var bridge_instance: SimulationSystem = simulation.get_system(
		"military_resource_readiness_system"
	)

	var bridge_ok: bool = (
		bridge_instance != null
		and bridge_instance is MilitaryResourceReadinessSystem
	)

	_log_result(
		"Registered MilitaryResourceReadinessSystem available",
		bridge_ok
	)

	if not bridge_ok:
		return false

	var military_system_instance: SimulationSystem = simulation.get_system(
		"military_system"
	)

	var military_system_ok: bool = (
		military_system_instance != null
		and military_system_instance is MilitarySystem
	)

	_log_result(
		"Registered MilitarySystem available",
		military_system_ok
	)

	if not military_system_ok:
		return false

	var india: SimEntity = world.get_entity("india")

	if india == null:
		_out(["India available: FAIL"])
		return false

	_out(["India available: PASS"])

	var resources: ResourceComponent = india.get_component("resources")
	var military: MilitaryComponent = india.get_component("military")

	var components_ok: bool = (
		resources != null
		and military != null
	)

	_log_result(
		"India resource and military components available",
		components_ok
	)

	if not components_ok:
		return false

	var original_resource_modifier_map: Dictionary = resources.get_state(
		"military_resource_modifier_by_resource",
		{}
	).duplicate(true)

	var original_resource_modifier: float = float(resources.get_state(
		"military_resource_modifier",
		1.0
	))

	var original_military_state: Dictionary = military.state.duplicate(true)

	var passed: bool = true

	# ------------------------------------------------------------
	# CASE 1 — NO STRATEGIC RESOURCE SHORTAGE
	# ------------------------------------------------------------
	resources.set_state(
		"military_resource_modifier_by_resource",
		{
			"coal": 1.0,
			"iron": 1.0,
			"oil": 1.0
		}
	)

	resources.set_state(
		"military_resource_modifier",
		1.0
	)

	var bridge: MilitaryResourceReadinessSystem = (
		bridge_instance as MilitaryResourceReadinessSystem
	)

	bridge.process_month(world)

	var baseline_modifier: float = float(
		military.get_state(
			"resource_readiness_modifier",
			-1.0
		)
	)

	var baseline_constraint: float = float(
		military.get_state(
			"resource_readiness_constraint",
			-1.0
		)
	)

	var baseline_active: bool = bool(
		military.get_state(
			"resource_military_constraint_active",
			true
		)
	)

	_log_result(
		"No-shortage readiness modifier remains neutral",
		_approx_equal(baseline_modifier, 1.0)
	)

	_log_result(
		"No-shortage readiness constraint is zero",
		_approx_equal(baseline_constraint, 0.0)
	)

	_log_result(
		"No-shortage military resource constraint remains inactive",
		not baseline_active
	)

	if not _approx_equal(baseline_modifier, 1.0):
		passed = false
	if not _approx_equal(baseline_constraint, 0.0):
		passed = false
	if baseline_active:
		passed = false

	# ------------------------------------------------------------
	# CASE 2 — COAL SHORTAGE IS LIMITING
	# ------------------------------------------------------------
	resources.set_state(
		"military_resource_modifier_by_resource",
		{
			"coal": 0.70,
			"iron": 1.0,
			"oil": 1.0
		}
	)

	resources.set_state(
		"military_resource_modifier",
		0.70
	)

	military.state = original_military_state.duplicate(true)
	bridge.process_month(world)

	var constrained_modifier: float = float(
		military.get_state(
			"resource_readiness_modifier",
			-1.0
		)
	)

	var constrained_readiness_factor: float = float(
		military.get_state(
			"resource_readiness_constraint",
			-1.0
		)
	)

	var constrained_resources_value: Variant = military.get_state(
		"resource_readiness_constrained_resources",
		[]
	)

	var constrained_resources: Array = []

	if typeof(constrained_resources_value) == TYPE_ARRAY:
		constrained_resources = constrained_resources_value

	_log_result(
		"Strategic-resource shortage produces bounded readiness modifier",
		_in_range(constrained_modifier)
	)

	_log_result(
		"Most limiting strategic resource controls readiness modifier",
		_approx_equal(constrained_modifier, 0.70)
	)

	_log_result(
		"Readiness constraint equals the missing modifier",
		_approx_equal(constrained_readiness_factor, 0.30)
	)

	_log_result(
		"Coal is explicitly visible as the constrained resource",
		constrained_resources.has("coal")
	)

	if not _in_range(constrained_modifier):
		passed = false
	if not _approx_equal(constrained_modifier, 0.70):
		passed = false
	if not _approx_equal(constrained_readiness_factor, 0.30):
		passed = false
	if not constrained_resources.has("coal"):
		passed = false

	# ------------------------------------------------------------
	# CASE 3 — CAUSAL RESPONSE THROUGH MILITARYSYSTEM
	# ------------------------------------------------------------
	var military_system: MilitarySystem = (
		military_system_instance as MilitarySystem
	)

	military.state = original_military_state.duplicate(true)

	resources.set_state(
		"military_resource_modifier_by_resource",
		{
			"coal": 1.0,
			"iron": 1.0,
			"oil": 1.0
		}
	)
	resources.set_state(
		"military_resource_modifier",
		1.0
	)

	bridge.process_month(world)
	military_system.process_month(world)

	var neutral_readiness: float = float(
		military.get_state(
			"readiness",
			-1.0
		)
	)

	military.state = original_military_state.duplicate(true)

	resources.set_state(
		"military_resource_modifier_by_resource",
		{
			"coal": 0.70,
			"iron": 1.0,
			"oil": 1.0
		}
	)
	resources.set_state(
		"military_resource_modifier",
		0.70
	)

	bridge.process_month(world)
	military_system.process_month(world)

	var shortage_readiness: float = float(
		military.get_state(
			"readiness",
			-1.0
		)
	)

	_log_result(
		"No-shortage readiness remains bounded",
		_in_range(neutral_readiness)
	)

	_log_result(
		"Shortage readiness remains bounded",
		_in_range(shortage_readiness)
	)

	_log_result(
		"Resource shortage reduces readiness",
		shortage_readiness < neutral_readiness
	)

	if not _in_range(neutral_readiness):
		passed = false
	if not _in_range(shortage_readiness):
		passed = false
	if shortage_readiness >= neutral_readiness:
		passed = false

	# ------------------------------------------------------------
	# RESOURCE AUTHORITY PROTECTION
	# ------------------------------------------------------------
	var resource_map_after: Dictionary = resources.get_state(
		"military_resource_modifier_by_resource",
		{}
	)

	var resource_map_unchanged: bool = (
		resource_map_after == {
			"coal": 0.70,
			"iron": 1.0,
			"oil": 1.0
		}
	)

	_log_result(
		"13.2 bridge does not rewrite ResourceSystem source state",
		resource_map_unchanged
	)

	if not resource_map_unchanged:
		passed = false

	# ------------------------------------------------------------
	# EXACT RESTORATION
	# ------------------------------------------------------------
	resources.set_state(
		"military_resource_modifier_by_resource",
		original_resource_modifier_map
	)

	resources.set_state(
		"military_resource_modifier",
		original_resource_modifier
	)

	military.state = original_military_state.duplicate(true)

	var restoration_ok: bool = (
		resources.get_state(
			"military_resource_modifier_by_resource",
			{}
		) == original_resource_modifier_map
		and is_equal_approx(
			float(
				resources.get_state(
					"military_resource_modifier",
					-1.0
				)
			),
			float(original_resource_modifier)
		)
		and military.state == original_military_state
	)

	_log_result(
		"Step 13.2 fixture restoration",
		restoration_ok
	)

	if not restoration_ok:
		passed = false

	_out([""])
	_out([
		"Step 13.2 resources → readiness overall: ",
		"PASS" if passed else "FAIL"
	])

	return passed
