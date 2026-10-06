class_name InfrastructureCapacityLossTest
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

	TestLogger.section(
		"INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.2"
	)

	if world == null:
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)
		return false

	var infrastructure_system_instance: SimulationSystem = simulation.get_system(
		"infrastructure_system"
	)

	var damage_system_instance: SimulationSystem = simulation.get_system(
		"infrastructure_damage_system"
	)

	var infrastructure_system_ok: bool = (
		infrastructure_system_instance != null
		and infrastructure_system_instance is InfrastructureSystem
	)

	var damage_system_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
	)

	TestLogger.write_line(
		"Registered InfrastructureSystem available: "
		+ ("PASS" if infrastructure_system_ok else "FAIL")
	)

	TestLogger.write_line(
		"Registered InfrastructureDamageSystem available: "
		+ ("PASS" if damage_system_ok else "FAIL")
	)

	if not infrastructure_system_ok or not damage_system_ok:
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)
		return false

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)
		return false

	TestLogger.write_line("India available: PASS")

	var infrastructure: InfrastructureComponent = india.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		TestLogger.write_line(
			"India InfrastructureComponent available: FAIL"
		)
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)
		return false

	TestLogger.write_line(
		"India InfrastructureComponent available: PASS"
	)

	var resources = india.get_component("resources")

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	var original_resource_state: Dictionary = {}
	if resources != null:
		original_resource_state = resources.state.duplicate(true)

	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()
	var original_active_conflicts: Array = world.active_conflicts.duplicate()
	var original_completed_conflicts: Array = world.completed_conflicts.duplicate()

	var damage_system: InfrastructureDamageSystem = (
		damage_system_instance as InfrastructureDamageSystem
	)

	var infrastructure_system: InfrastructureSystem = (
		infrastructure_system_instance as InfrastructureSystem
	)

	var raw_baseline: Dictionary = {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		raw_baseline[infrastructure_type] = clampf(
			float(
				infrastructure.get_state(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

	var original_total_capacity: float = clampf(
		float(
			infrastructure.get_state(
				"total_capacity",
				0.0
			)
		),
		0.0,
		1.0
	)

	# Deliberately inject a stale bridge key. Step 14.2 owns derived
	# infrastructure-capacity synchronization and must rebuild, rather than
	# preserve, obsolete keys.
	var original_infrastructure_capacity = resources.get_state(
		"infrastructure_capacity",
		{}
	) if resources != null else {}

	if resources != null:
		resources.set_state(
			"infrastructure_capacity",
			{
				"stale_step14_2_fixture": 0.123
			}
		)

	var passed := true

	# ------------------------------------------------------------
	# DETERMINISTIC CAPACITY BASELINE
	# ------------------------------------------------------------
	# The test isolates 14.2 from any previously generated maintenance
	# result. Condition = 1.0 means effective baseline = raw baseline.
	var baseline_conditions: Dictionary = {}
	for infrastructure_type in INFRASTRUCTURE_TYPES:
		baseline_conditions[infrastructure_type] = 1.0

	infrastructure.set_state(
		"infrastructure_condition",
		baseline_conditions
	)

	infrastructure.set_state(
		"effective_infrastructure_capacity",
		{}
	)

	var fixture_event := SimulationEvent.new(
		"step14_2_fixture_event",
		"Step 14.2 Infrastructure Capacity Fixture",
		"infrastructure_damage"
	)

	fixture_event.add_target("india")
	fixture_event.activate()
	world.add_active_event(fixture_event)

	# ------------------------------------------------------------
	# DAMAGE -> CAPACITY LOSS
	# ------------------------------------------------------------
	var damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.25,
		fixture_event,
		"damage_event_14_2_001",
		"controlled_capacity_loss_fixture"
	)

	TestLogger.write_line(
		"Step 14.1 damage state exists for Step 14.2 fixture: "
		+ ("PASS" if damage_created else "FAIL")
	)
	passed = passed and damage_created

	infrastructure_system.process_month(world)

	var raw_transport: float = float(
		raw_baseline.get("transport", 0.0)
	)

	var effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var effective_transport: float = -1.0
	if typeof(effective_capacity) == TYPE_DICTIONARY:
		effective_transport = float(
			effective_capacity.get(
				"transport",
				-1.0
			)
		)

	var expected_transport: float = clampf(
		raw_transport * 0.75,
		0.0,
		1.0
	)

	var transport_reduced_correctly: bool = is_equal_approx(
		effective_transport,
		expected_transport
	)

	TestLogger.write_line(
		"Damage reduces effective transport capacity by recorded damage fraction: "
		+ ("PASS" if transport_reduced_correctly else "FAIL")
	)

	passed = passed and transport_reduced_correctly

	# ------------------------------------------------------------
	# RAW CAPACITY MUST REMAIN UNCHANGED
	# ------------------------------------------------------------
	var raw_capacity_preserved: bool = true

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		var current_raw: float = float(
			infrastructure.get_state(
				infrastructure_type,
				0.0
			)
		)

		if not is_equal_approx(
			current_raw,
			float(raw_baseline[infrastructure_type])
		):
			raw_capacity_preserved = false

	TestLogger.write_line(
		"Raw infrastructure values remain unchanged after damage translation: "
		+ ("PASS" if raw_capacity_preserved else "FAIL")
	)

	passed = passed and raw_capacity_preserved

	# ------------------------------------------------------------
	# NON-DAMAGED TYPES MUST REMAIN AT THEIR BASELINE
	# ------------------------------------------------------------
	var unaffected_types_preserved: bool = true

	if typeof(effective_capacity) == TYPE_DICTIONARY:
		for infrastructure_type in INFRASTRUCTURE_TYPES:
			if infrastructure_type == "transport":
				continue

			var current_effective: float = float(
				effective_capacity.get(
					infrastructure_type,
					-1.0
				)
			)

			var expected_effective: float = float(
				raw_baseline[infrastructure_type]
			)

			if not is_equal_approx(
				current_effective,
				expected_effective
			):
				unaffected_types_preserved = false

	TestLogger.write_line(
		"Undamaged infrastructure types retain effective baseline capacity: "
		+ ("PASS" if unaffected_types_preserved else "FAIL")
	)

	passed = passed and unaffected_types_preserved

	# ------------------------------------------------------------
	# TOTAL CAPACITY MUST RECOMPUTE FROM EFFECTIVE VALUES
	# ------------------------------------------------------------
	var expected_total_capacity: float = 0.0

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		var component_effective: float = float(
			raw_baseline[infrastructure_type]
		)

		if infrastructure_type == "transport":
			component_effective *= 0.75

		expected_total_capacity += component_effective

	expected_total_capacity /= float(INFRASTRUCTURE_TYPES.size())
	expected_total_capacity = clampf(
		expected_total_capacity,
		0.0,
		1.0
	)

	var current_total_capacity: float = float(
		infrastructure.get_state(
			"total_capacity",
			-1.0
		)
	)

	var total_capacity_recomputed: bool = is_equal_approx(
		current_total_capacity,
		expected_total_capacity
	)

	TestLogger.write_line(
		"total_capacity reflects effective damaged infrastructure: "
		+ ("PASS" if total_capacity_recomputed else "FAIL")
	)

	passed = passed and total_capacity_recomputed

	# ------------------------------------------------------------
	# RESOURCE CAPACITY BRIDGE
	# ------------------------------------------------------------
	var resource_bridge_correct: bool = true

	if resources != null:
		var resource_infrastructure_capacity = resources.get_state(
			"infrastructure_capacity",
			{}
		)

		if typeof(resource_infrastructure_capacity) != TYPE_DICTIONARY:
			resource_bridge_correct = false
		else:
			# All currently represented resources must receive the current total
			# capacity, and the deliberately injected stale key must disappear.
			var expected_resource_names: Dictionary = {}

			for state_name in [
				"production",
				"consumption",
				"reserves",
				"stockpile",
				"imports",
				"exports"
			]:
				var state_value = resources.get_state(
					state_name,
					{}
				)

				if typeof(state_value) != TYPE_DICTIONARY:
					continue

				for resource_name in state_value.keys():
					expected_resource_names[resource_name] = true

			if resource_infrastructure_capacity.has(
				"stale_step14_2_fixture"
			):
				resource_bridge_correct = false

			for resource_name in expected_resource_names.keys():
				if not resource_infrastructure_capacity.has(resource_name):
					resource_bridge_correct = false
					continue

				var bridged_value: float = float(
					resource_infrastructure_capacity[resource_name]
				)

				if not is_equal_approx(
					bridged_value,
					expected_total_capacity
				):
					resource_bridge_correct = false

	TestLogger.write_line(
		"Resource infrastructure-capacity bridge rebuilds cleanly from current resource state: "
		+ ("PASS" if resource_bridge_correct else "FAIL")
	)

	passed = passed and resource_bridge_correct

	# ------------------------------------------------------------
	# IDEMPOTENCE OF DERIVATION
	# ------------------------------------------------------------
	infrastructure_system.process_month(world)

	var repeated_effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var repeated_transport: float = float(
		repeated_effective_capacity.get(
			"transport",
			-1.0
		)
	) if typeof(repeated_effective_capacity) == TYPE_DICTIONARY else -1.0

	var repeated_total: float = float(
		infrastructure.get_state(
			"total_capacity",
			-1.0
		)
	)

	var derivation_idempotent: bool = (
		is_equal_approx(
			repeated_transport,
			expected_transport
		)
		and is_equal_approx(
			repeated_total,
			expected_total_capacity
		)
	)

	TestLogger.write_line(
		"Repeated infrastructure recalculation does not compound the same damage: "
		+ ("PASS" if derivation_idempotent else "FAIL")
	)

	passed = passed and derivation_idempotent

	# ------------------------------------------------------------
	# ADDITIONAL DAMAGE ACCUMULATION
	# ------------------------------------------------------------
	var second_damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.50,
		fixture_event,
		"damage_event_14_2_002",
		"controlled_capacity_loss_fixture_2"
	)

	TestLogger.write_line(
		"Second attributable damage application is accepted: "
		+ ("PASS" if second_damage_created else "FAIL")
	)

	passed = passed and second_damage_created

	infrastructure_system.process_month(world)

	var cumulative_damage: float = damage_system.get_damage(
		india,
		"transport"
	)

	var cumulative_damage_correct: bool = is_equal_approx(
		cumulative_damage,
		0.75
	)

	TestLogger.write_line(
		"Cumulative transport damage reaches 0.75 without exceeding bounds: "
		+ ("PASS" if cumulative_damage_correct else "FAIL")
	)

	passed = passed and cumulative_damage_correct

	var cumulative_effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var cumulative_transport_effective: float = float(
		cumulative_effective_capacity.get(
			"transport",
			-1.0
		)
	) if typeof(cumulative_effective_capacity) == TYPE_DICTIONARY else -1.0

	var expected_cumulative_transport: float = clampf(
		raw_transport * 0.25,
		0.0,
		1.0
	)

	var cumulative_capacity_correct: bool = is_equal_approx(
		cumulative_transport_effective,
		expected_cumulative_transport
	)

	TestLogger.write_line(
		"Additional damage further reduces effective transport capacity: "
		+ ("PASS" if cumulative_capacity_correct else "FAIL")
	)

	passed = passed and cumulative_capacity_correct

	# ------------------------------------------------------------
	# SATURATION AT FULL DAMAGE
	# ------------------------------------------------------------
	var full_damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.25,
		fixture_event,
		"damage_event_14_2_003",
		"controlled_capacity_loss_fixture_3"
	)

	TestLogger.write_line(
		"Final damage application reaches the bounded 1.0 ceiling: "
		+ ("PASS" if full_damage_created else "FAIL")
	)

	passed = passed and full_damage_created

	infrastructure_system.process_month(world)

	var final_damage: float = damage_system.get_damage(
		india,
		"transport"
	)

	var final_effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var final_transport_effective: float = float(
		final_effective_capacity.get(
			"transport",
			-1.0
		)
	) if typeof(final_effective_capacity) == TYPE_DICTIONARY else -1.0

	var saturation_correct: bool = (
		is_equal_approx(final_damage, 1.0)
		and is_equal_approx(final_transport_effective, 0.0)
	)

	TestLogger.write_line(
		"Full damage yields zero effective capacity without changing raw capacity: "
		+ ("PASS" if saturation_correct else "FAIL")
	)

	passed = passed and saturation_correct

	# ------------------------------------------------------------
	# RESTORATION
	# ------------------------------------------------------------
	infrastructure.state = original_infrastructure_state.duplicate(true)

	if resources != null:
		resources.state = original_resource_state.duplicate(true)

	world.active_events = original_active_events.duplicate()
	world.completed_events = original_completed_events.duplicate()
	world.active_conflicts = original_active_conflicts.duplicate()
	world.completed_conflicts = original_completed_conflicts.duplicate()

	var restoration_ok: bool = (
		infrastructure.state == original_infrastructure_state
		and (
			resources == null
			or resources.state == original_resource_state
		)
		and float(
			infrastructure.get_state(
				"total_capacity",
				-1.0
			)
		) == float(
			original_infrastructure_state.get(
				"total_capacity",
				original_total_capacity
			)
		)
	)

	TestLogger.write_line(
		"Step 14.2 fixture restoration: "
		+ ("PASS" if restoration_ok else "FAIL")
	)

	passed = passed and restoration_ok

	TestLogger.write_line(
		"Step 14.2 capacity loss overall: "
		+ ("PASS" if passed else "FAIL")
	)

	if passed:
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: PASS"
		)
	else:
		TestLogger.write_line(
			"Infrastructure Capacity Loss 14.2 test: FAIL"
		)

	return passed
