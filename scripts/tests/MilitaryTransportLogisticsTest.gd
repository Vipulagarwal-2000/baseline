class_name MilitaryTransportLogisticsTest
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


static func _in_range(
	value: float
) -> bool:
	return value >= -0.000001 and value <= 1.000001


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["============================================================"])
	_out(["STEP 13.3 — TRANSPORT → MILITARY LOGISTICS TEST"])
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
		"military_transport_logistics_system"
	)

	var bridge_ok: bool = (
		bridge_instance != null
		and bridge_instance is MilitaryTransportLogisticsSystem
	)

	_log_result(
		"Registered MilitaryTransportLogisticsSystem available",
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

	var bridge: MilitaryTransportLogisticsSystem = (
		bridge_instance as MilitaryTransportLogisticsSystem
	)

	var military_system: MilitarySystem = (
		military_system_instance as MilitarySystem
	)

	var passed: bool = true

	# ------------------------------------------------------------
	# CASE 1 — BASELINE TRANSPORT SUPPORT
	# ------------------------------------------------------------
	bridge.process_month(world)

	var baseline_modifier: float = float(
		military.get_state(
			"transport_logistics_modifier",
			-1.0
		)
	)

	var baseline_network_factor: float = float(
		military.get_state(
			"transport_network_factor",
			-1.0
		)
	)

	var baseline_route_factor: float = float(
		military.get_state(
			"transport_route_factor",
			-1.0
		)
	)

	_log_result(
		"Baseline transport logistics modifier is bounded",
		_in_range(baseline_modifier)
	)

	_log_result(
		"Baseline regional network factor is bounded",
		_in_range(baseline_network_factor)
	)

	_log_result(
		"Baseline regional route factor is bounded",
		_in_range(baseline_route_factor)
	)

	if not _in_range(baseline_modifier):
		passed = false

	if not _in_range(baseline_network_factor):
		passed = false

	if not _in_range(baseline_route_factor):
		passed = false

	# ------------------------------------------------------------
	# CASE 2 — COUNTRY TRANSPORT INFRASTRUCTURE DETERIORATES
	# ------------------------------------------------------------
	infrastructure.set_state(
		"transport",
		0.20
	)

	infrastructure.set_state(
		"roads",
		0.20
	)

	infrastructure.set_state(
		"railways",
		0.20
	)

	military.state = original_military_state.duplicate(true)

	bridge.process_month(world)

	var constrained_modifier: float = float(
		military.get_state(
			"transport_logistics_modifier",
			-1.0
		)
	)

	var constrained_infrastructure_factor: float = float(
		military.get_state(
			"transport_infrastructure_factor",
			-1.0
		)
	)

	_log_result(
		"Reduced transport infrastructure lowers infrastructure factor",
		constrained_infrastructure_factor < 1.0
	)

	_log_result(
		"Reduced transport infrastructure constrains military logistics",
		constrained_modifier < baseline_modifier
	)

	if constrained_infrastructure_factor >= 1.0:
		passed = false

	if constrained_modifier >= baseline_modifier:
		passed = false

	# ------------------------------------------------------------
	# CASE 3 — REGIONAL ROUTE DISRUPTION
	# ------------------------------------------------------------
	infrastructure.state = (
		original_infrastructure_state.duplicate(true)
	)

	military.state = original_military_state.duplicate(true)

	var test_route: RegionalTransportRoute = null

	for route_value in world.regional_transport_routes.values():
		var candidate: RegionalTransportRoute = (
			route_value as RegionalTransportRoute
		)

		if candidate == null:
			continue

		if candidate.structural_country_id != india.id:
			continue

		test_route = candidate
		break

	var route_fixture_available: bool = (
		test_route != null
	)

	_log_result(
		"India regional transport route fixture available",
		route_fixture_available
	)

	if not route_fixture_available:
		passed = false
	else:
		var original_route_state: Dictionary = (
			test_route.to_snapshot_dict()
		)

		var from_node: RegionalTransportNode = (
			world.get_regional_transport_node(
				test_route.from_region_id
			)
		)

		var to_node: RegionalTransportNode = (
			world.get_regional_transport_node(
				test_route.to_region_id
			)
		)

		var route_restricted: bool = test_route.apply_route_restriction(
			0.0,
			"step13_3_test"
		)

		test_route.recalculate_effective_capacity(
			from_node,
			to_node
		)

		var route_mutation_ok: bool = (
			route_restricted
			and test_route.effective_capacity
				<= test_route.base_capacity * 0.000001
		)

		_log_result(
			"Regional route restriction creates a physical capacity constraint",
			route_mutation_ok
		)

		if not route_mutation_ok:
			passed = false

		bridge.process_month(world)

		var disrupted_network_factor: float = float(
			military.get_state(
				"transport_network_factor",
				-1.0
			)
		)

		var disrupted_modifier: float = float(
			military.get_state(
				"transport_logistics_modifier",
				-1.0
			)
		)

		_log_result(
			"Regional route disruption lowers network factor",
			disrupted_network_factor < baseline_network_factor
		)

		_log_result(
			"Regional route disruption constrains military logistics",
			disrupted_modifier < baseline_modifier
		)

		if disrupted_network_factor >= baseline_network_factor:
			passed = false

		if disrupted_modifier >= baseline_modifier:
			passed = false

		# Restore route exactly.
		test_route.condition = float(
			original_route_state.get(
				"condition",
				1.0
			)
		)

		test_route.blocked = bool(
			original_route_state.get(
				"blocked",
				false
			)
		)

		test_route.restriction_active = bool(
			original_route_state.get(
				"restriction_active",
				false
			)
		)

		test_route.restriction_factor = float(
			original_route_state.get(
				"restriction_factor",
				1.0
			)
		)

		test_route.restriction_reason = str(
			original_route_state.get(
				"restriction_reason",
				""
			)
		)

		test_route.recalculate_effective_capacity(
			from_node,
			to_node
		)

		var route_restoration_ok: bool = (
			is_equal_approx(
				test_route.effective_capacity,
				float(
					original_route_state.get(
						"effective_capacity",
						test_route.effective_capacity
					)
				)
			)
			and test_route.blocked == bool(
				original_route_state.get(
					"blocked",
					false
				)
			)
			and test_route.restriction_active == bool(
				original_route_state.get(
					"restriction_active",
					false
				)
			)
		)

		_log_result(
			"Regional route fixture restores exactly",
			route_restoration_ok
		)

		if not route_restoration_ok:
			passed = false

	# ------------------------------------------------------------
	# CASE 4 — MILITARYSYSTEM CONSUMES THE TRANSPORT MODIFIER
	# ------------------------------------------------------------
	infrastructure.state = (
		original_infrastructure_state.duplicate(true)
	)

	military.state = original_military_state.duplicate(true)

	bridge.process_month(world)
	military_system.process_month(world)

	var baseline_logistics: float = float(
		military.get_state(
			"logistics_capacity",
			-1.0
		)
	)

	military.state = original_military_state.duplicate(true)

	infrastructure.set_state(
		"transport",
		0.20
	)

	infrastructure.set_state(
		"roads",
		0.20
	)

	infrastructure.set_state(
		"railways",
		0.20
	)

	bridge.process_month(world)
	military_system.process_month(world)

	var constrained_logistics: float = float(
		military.get_state(
			"logistics_capacity",
			-1.0
		)
	)

	_log_result(
		"Baseline MilitarySystem logistics remains bounded",
		_in_range(baseline_logistics)
	)

	_log_result(
		"Transport-constrained MilitarySystem logistics remains bounded",
		_in_range(constrained_logistics)
	)

	_log_result(
		"Transport constraint is causally visible in MilitarySystem logistics",
		constrained_logistics < baseline_logistics
	)

	if not _in_range(baseline_logistics):
		passed = false

	if not _in_range(constrained_logistics):
		passed = false

	if constrained_logistics >= baseline_logistics:
		passed = false

	# ------------------------------------------------------------
	# AUTHORITY PROTECTION
	# ------------------------------------------------------------
	# The bridge only reads infrastructure and regional transport state.
	# It must not mutate the infrastructure component.
	var current_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	# At this point the intentional constrained infrastructure fixture
	# is still applied, so compare against that explicit expected subset.
	var authority_protection_ok: bool = (
		is_equal_approx(
			float(
				current_infrastructure_state.get(
					"transport",
					-1.0
				)
			),
			0.20
		)
		and is_equal_approx(
			float(
				current_infrastructure_state.get(
					"roads",
					-1.0
				)
			),
			0.20
		)
		and is_equal_approx(
			float(
				current_infrastructure_state.get(
					"railways",
					-1.0
				)
			),
			0.20
		)
	)

	_log_result(
		"13.3 bridge does not rewrite infrastructure source state",
		authority_protection_ok
	)

	if not authority_protection_ok:
		passed = false

	# ------------------------------------------------------------
	# EXACT FIXTURE RESTORATION
	# ------------------------------------------------------------
	infrastructure.state = (
		original_infrastructure_state.duplicate(true)
	)

	military.state = (
		original_military_state.duplicate(true)
	)

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and military.state == original_military_state
	)

	_log_result(
		"Step 13.3 fixture restoration",
		restoration_ok
	)

	if not restoration_ok:
		passed = false

	_out([""])
	_out([
		"Step 13.3 transport → logistics overall: ",
		"PASS" if passed else "FAIL"
	])

	return passed
