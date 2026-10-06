class_name MilitaryPortNavalLogisticsTest
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
	_out(["STEP 13.4 — PORTS → NAVAL LOGISTICS TEST"])
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
		"military_port_naval_logistics_system"
	)

	var bridge_ok: bool = (
		bridge_instance != null
		and bridge_instance is MilitaryPortNavalLogisticsSystem
	)

	_log_result(
		"Registered MilitaryPortNavalLogisticsSystem available",
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

	var bridge: MilitaryPortNavalLogisticsSystem = (
		bridge_instance as MilitaryPortNavalLogisticsSystem
	)
	var military_system: MilitarySystem = (
		military_system_instance as MilitarySystem
	)

	var passed: bool = true

	# 1. Baseline
	bridge.process_month(world)

	var baseline_modifier: float = float(
		military.get_state("naval_logistics_modifier", -1.0)
	)
	var baseline_port_factor: float = float(
		military.get_state("naval_port_capacity_factor", -1.0)
	)

	_log_result(
		"Baseline naval logistics modifier is bounded",
		_bounded(baseline_modifier)
	)
	_log_result(
		"Baseline port capacity factor is bounded",
		_bounded(baseline_port_factor)
	)

	if not _bounded(baseline_modifier):
		passed = false
	if not _bounded(baseline_port_factor):
		passed = false

	# 2. Port reduction
	military.state = original_military_state.duplicate(true)

	infrastructure.set_state("ports", 0.20)

	bridge.process_month(world)

	var constrained_modifier: float = float(
		military.get_state("naval_logistics_modifier", -1.0)
	)
	var constrained_country_port: float = float(
		military.get_state("naval_country_port_factor", -1.0)
	)

	_log_result(
		"Reduced port capacity lowers country port factor",
		constrained_country_port < float(
			original_infrastructure_state.get("ports", 1.0)
		)
	)

	_log_result(
		"Reduced port capacity constrains naval logistics",
		constrained_modifier < baseline_modifier
	)

	if not constrained_country_port < float(
		original_infrastructure_state.get("ports", 1.0)
	):
		passed = false
	if constrained_modifier >= baseline_modifier:
		passed = false

	# 3. MilitarySystem consumes the modifier.
	infrastructure.state = original_infrastructure_state.duplicate(true)
	military.state = original_military_state.duplicate(true)

	bridge.process_month(world)
	military_system.process_month(world)

	var baseline_power: float = float(
		military.get_state("military_power", -1.0)
	)
	var baseline_effective_navy: float = float(
		military.get_state("effective_naval_strength", -1.0)
	)

	military.state = original_military_state.duplicate(true)
	infrastructure.set_state("ports", 0.20)

	bridge.process_month(world)
	military_system.process_month(world)

	var constrained_power: float = float(
		military.get_state("military_power", -1.0)
	)
	var constrained_effective_navy: float = float(
		military.get_state("effective_naval_strength", -1.0)
	)
	var raw_navy: float = float(
		military.get_state("naval_strength", -1.0)
	)

	_log_result(
		"Baseline effective naval strength is bounded",
		_bounded(baseline_effective_navy)
	)
	_log_result(
		"Constrained effective naval strength is bounded",
		_bounded(constrained_effective_navy)
	)
	_log_result(
		"Reduced ports lower effective naval strength",
		constrained_effective_navy < baseline_effective_navy
	)
	_log_result(
		"Reduced ports lower MilitarySystem military power",
		constrained_power < baseline_power
	)
	_log_result(
		"Raw naval strength remains unchanged",
		is_equal_approx(
			raw_navy,
			float(
				original_military_state.get(
					"naval_strength",
					raw_navy
				)
			)
		)
	)

	if not _bounded(baseline_effective_navy):
		passed = false
	if not _bounded(constrained_effective_navy):
		passed = false
	if constrained_effective_navy >= baseline_effective_navy:
		passed = false
	if constrained_power >= baseline_power:
		passed = false
	if not is_equal_approx(
		raw_navy,
		float(
			original_military_state.get(
				"naval_strength",
				raw_navy
			)
		)
	):
		passed = false

	# 4. Source authority protection.
	var source_ports: float = float(
		infrastructure.get_state("ports", -1.0)
	)

	var source_state_ok: bool = is_equal_approx(
		source_ports,
		0.20
	)

	_log_result(
		"13.4 bridge does not rewrite port infrastructure source state",
		source_state_ok
	)

	if not source_state_ok:
		passed = false

	# 5. Restore exact fixtures.
	infrastructure.state = original_infrastructure_state.duplicate(true)
	military.state = original_military_state.duplicate(true)

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and military.state == original_military_state
	)

	_log_result(
		"Step 13.4 fixture restoration",
		restoration_ok
	)

	if not restoration_ok:
		passed = false

	_out([""])
	_out([
		"Step 13.4 ports → naval logistics overall: ",
		"PASS" if passed else "FAIL"
	])

	return passed
