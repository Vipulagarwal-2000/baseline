class_name MilitaryPowerInfrastructureTest
extends RefCounted


static func _out(values: Array) -> void:
	var message: String = ""
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


static func _bounded(value: float) -> bool:
	return value >= -0.000001 and value <= 1.000001


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["============================================================"])
	_out(["STEP 13.5 — POWER → MILITARY INFRASTRUCTURE TEST"])
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
		"military_power_infrastructure_system"
	)

	var bridge_ok: bool = (
		bridge_instance != null
		and bridge_instance is MilitaryPowerInfrastructureSystem
	)

	_log_result(
		"Registered MilitaryPowerInfrastructureSystem available",
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

	var infrastructure: InfrastructureComponent = (
		india.get_component("infrastructure")
	)
	var military: MilitaryComponent = (
		india.get_component("military")
	)

	var components_ok: bool = (
		infrastructure != null
		and military != null
	)

	_log_result(
		"India infrastructure and military components available",
		components_ok
	)

	if not components_ok:
		return false

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)
	var original_military_state: Dictionary = (
		military.state.duplicate(true)
	)

	var bridge: MilitaryPowerInfrastructureSystem = (
		bridge_instance as MilitaryPowerInfrastructureSystem
	)
	var military_system: MilitarySystem = (
		military_system_instance as MilitarySystem
	)

	var passed: bool = true

	# ------------------------------------------------------------
	# CASE 1 — BASELINE POWER SUPPORT
	# ------------------------------------------------------------
	bridge.process_month(world)

	var baseline_modifier: float = float(
		military.get_state(
			"military_infrastructure_modifier",
			-1.0
		)
	)

	var baseline_power_factor: float = float(
		military.get_state(
			"military_infrastructure_power_factor",
			-1.0
		)
	)

	_log_result(
		"Baseline military-infrastructure modifier is bounded",
		_bounded(baseline_modifier)
	)

	_log_result(
		"Baseline power factor is bounded",
		_bounded(baseline_power_factor)
	)

	if not _bounded(baseline_modifier):
		passed = false
	if not _bounded(baseline_power_factor):
		passed = false

	# ------------------------------------------------------------
	# CASE 2 — POWER AVAILABILITY REDUCTION
	# ------------------------------------------------------------
	military.state = original_military_state.duplicate(true)
	infrastructure.set_state(
		"power",
		0.20
	)

	bridge.process_month(world)

	var constrained_modifier: float = float(
		military.get_state(
			"military_infrastructure_modifier",
			-1.0
		)
	)

	var constrained_power_factor: float = float(
		military.get_state(
			"military_infrastructure_power_factor",
			-1.0
		)
	)

	_log_result(
		"Reduced power lowers military-infrastructure support",
		constrained_modifier < baseline_modifier
	)

	_log_result(
		"Reduced power factor remains bounded",
		_bounded(constrained_power_factor)
	)

	_log_result(
		"Reduced military-infrastructure modifier remains bounded",
		_bounded(constrained_modifier)
	)

	if constrained_modifier >= baseline_modifier:
		passed = false
	if not _bounded(constrained_power_factor):
		passed = false
	if not _bounded(constrained_modifier):
		passed = false

	# ------------------------------------------------------------
	# CASE 3 — MILITARYSYSTEM CONSUMES POWER CONSTRAINT
	# ------------------------------------------------------------
	infrastructure.state = original_infrastructure_state.duplicate(true)
	military.state = original_military_state.duplicate(true)

	bridge.process_month(world)
	military_system.process_month(world)

	var baseline_readiness: float = float(
		military.get_state(
			"readiness",
			-1.0
		)
	)

	var baseline_effective_command: float = float(
		military.get_state(
			"effective_command_capacity",
			-1.0
		)
	)

	military.state = original_military_state.duplicate(true)
	infrastructure.set_state(
		"power",
		0.20
	)

	bridge.process_month(world)

	var raw_command_after_bridge: float = float(
		military.get_state(
			"command_capacity",
			-1.0
		)
	)

	var bridge_preserves_raw_command: bool = is_equal_approx(
		raw_command_after_bridge,
		float(
			original_military_state.get(
				"command_capacity",
				raw_command_after_bridge
			)
		)
	)

	_log_result(
		"Power bridge preserves raw command capacity before MilitarySystem recalculation",
		bridge_preserves_raw_command
	)

	if not bridge_preserves_raw_command:
		passed = false

	military_system.process_month(world)

	var constrained_readiness: float = float(
		military.get_state(
			"readiness",
			-1.0
		)
	)

	var constrained_effective_command: float = float(
		military.get_state(
			"effective_command_capacity",
			-1.0
		)
	)

	_log_result(
		"Baseline effective command capacity is bounded",
		_bounded(baseline_effective_command)
	)

	_log_result(
		"Power-constrained effective command capacity is bounded",
		_bounded(constrained_effective_command)
	)

	_log_result(
		"Reduced power lowers effective command capacity",
		constrained_effective_command < baseline_effective_command
	)

	_log_result(
		"Reduced power lowers military readiness",
		constrained_readiness < baseline_readiness
	)

	if not _bounded(baseline_effective_command):
		passed = false
	if not _bounded(constrained_effective_command):
		passed = false
	if constrained_effective_command >= baseline_effective_command:
		passed = false
	if constrained_readiness >= baseline_readiness:
		passed = false
	# ------------------------------------------------------------
	# AUTHORITY PROTECTION
	# ------------------------------------------------------------
	var source_power: float = float(
		infrastructure.get_state(
			"power",
			-1.0
		)
	)

	var source_state_ok: bool = is_equal_approx(
		source_power,
		0.20
	)

	_log_result(
		"13.5 bridge does not rewrite power infrastructure source state",
		source_state_ok
	)

	if not source_state_ok:
		passed = false

	# ------------------------------------------------------------
	# EXACT FIXTURE RESTORATION
	# ------------------------------------------------------------
	infrastructure.state = original_infrastructure_state.duplicate(true)
	military.state = original_military_state.duplicate(true)

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and military.state == original_military_state
	)

	_log_result(
		"Step 13.5 fixture restoration",
		restoration_ok
	)

	if not restoration_ok:
		passed = false

	_out([""])
	_out([
		"Step 13.5 power → military infrastructure overall: ",
		"PASS" if passed else "FAIL"
	])

	return passed
