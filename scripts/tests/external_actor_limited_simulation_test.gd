class_name ExternalActorLimitedSimulationTest
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.4
# EXTERNAL ACTOR LIMITED SIMULATION TEST
# ============================================================
#
# Validates that external actors advance only explicitly-declared,
# event-relevant state and do not receive a full country simulation.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"EXTERNAL ACTOR LIMITED SIMULATION 10.4 TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World supplied: FAIL")
		return false

	TestLogger.write_line("World supplied: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation supplied: FAIL")
		return false

	TestLogger.write_line("Simulation supplied: PASS")

	var actor_a_id := "external_limited_test_actor_a"
	var actor_b_id := "external_limited_test_actor_b"

	var actor_a := ExternalWorldActor.new(
		actor_a_id,
		"External Limited Actor A"
	)
	var actor_b := ExternalWorldActor.new(
		actor_b_id,
		"External Limited Actor B"
	)

	actor_a.set_resource_status(
		"oil",
		{
			"availability": 0.80,
			"unrelated_detail": {
				"ignored": true
			}
		}
	)
	actor_a.set_trade_capacity("oil", 100.0)
	actor_a.set_strategic_status("regional_tension", 0.20)

	actor_b.set_resource_status(
		"oil",
		{
			"availability": 0.60
			}
	)
	actor_b.set_trade_capacity("oil", 80.0)
	actor_b.set_strategic_status("regional_tension", 0.10)

	world.add_entity(actor_a)
	world.add_entity(actor_b)

	var system := ExternalActorLimitedSimulationSystem.new()

	all_passed = _assert(
		system != null,
		"Limited simulation system construction",
		all_passed
	)

	all_passed = _assert(
		actor_a.is_lightweight_representation()
		and actor_b.is_lightweight_representation(),
		"External actors remain lightweight",
		all_passed
	)

	# ----------------------------------------------------------
	# EXPLICIT LIMITED RULES ONLY
	# ----------------------------------------------------------

	var rules_a: Dictionary = {
		"resource_rules": {
			"oil": {
				"availability_delta": -0.10,
				"minimum": 0.0,
				"maximum": 1.0
			}
		},
		"trade_rules": {
			"oil": {
				"capacity_delta": -20.0,
				"minimum": 0.0,
				"maximum": 100.0
			}
		},
		"strategic_rules": {
			"regional_tension": {
				"delta": 0.10,
				"minimum": 0.0,
				"maximum": 1.0
			}
		},
		"event_rules": {
			"oil_disruption": {
				"remaining_months": 2.0,
				"decrement_per_month": 1.0,
				"active": true
			}
		}
	}

	var rules_b: Dictionary = {
		"resource_rules": {
			"oil": {
				"availability_delta": -0.05,
				"minimum": 0.0,
				"maximum": 1.0
			}
		},
		"trade_rules": {
			"oil": {
				"capacity_delta": -10.0,
				"minimum": 0.0,
				"maximum": 80.0
			}
		},
		"strategic_rules": {
			"regional_tension": {
				"delta": 0.05,
				"minimum": 0.0,
				"maximum": 1.0
			}
		},
		"event_rules": {}
	}

	all_passed = _assert(
		system.configure_limited_simulation(actor_a, rules_a),
		"Actor A accepts explicit limited-state rules",
		all_passed
	)

	all_passed = _assert(
		system.configure_limited_simulation(actor_b, rules_b),
		"Actor B accepts explicit limited-state rules",
		all_passed
	)

	# ----------------------------------------------------------
	# FIRST LIMITED TICK
	# ----------------------------------------------------------

	var original_date := world.current_date.duplicate(true)

	system.process_month(world)

	var actor_a_oil = actor_a.get_resource_status("oil", {})
	var actor_a_oil_availability = float(
		actor_a_oil.get("availability", -1.0)
	)

	all_passed = _assert(
		is_equal_approx(actor_a_oil_availability, 0.70),
		"Limited resource state advances deterministically",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			actor_a.get_trade_capacity("oil", -1.0),
			80.0
		),
		"Limited trade capacity advances deterministically",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			float(
				actor_a.get_strategic_status(
					"regional_tension",
					-1.0
				)
			),
			0.30
		),
		"Limited strategic state advances deterministically",
		all_passed
	)

	var oil_event_state = actor_a.get_event_state(
		"oil_disruption",
		{}
	)

	var oil_event_limited = oil_event_state.get(
		"limited_simulation",
		{}
	)

	all_passed = _assert(
		is_equal_approx(
			float(
				oil_event_limited.get(
					"remaining_months",
					-1.0
				)
			),
			1.0
		),
		"Limited event timer advances deterministically",
		all_passed
	)

	# ----------------------------------------------------------
	# SAME-DATE IDEMPOTENCE
	# ----------------------------------------------------------

	var state_before_repeat := actor_a.get_external_actor_component().state.duplicate(true)

	system.process_month(world)

	var state_after_repeat := actor_a.get_external_actor_component().state.duplicate(true)

	all_passed = _assert(
		state_before_repeat == state_after_repeat,
		"Repeated same-date limited processing is idempotent",
		all_passed
	)

	# ----------------------------------------------------------
	# NEXT DATE
	# ----------------------------------------------------------

	world.current_date["month"] = int(world.current_date.get("month", 1)) + 1

	if int(world.current_date["month"]) > 12:
		world.current_date["month"] = 1
		world.current_date["year"] = int(world.current_date.get("year", 1950)) + 1

	system.process_month(world)

	oil_event_state = actor_a.get_event_state(
		"oil_disruption",
		{}
	)
	oil_event_limited = oil_event_state.get(
		"limited_simulation",
		{}
	)

	all_passed = _assert(
		float(
			oil_event_limited.get(
				"remaining_months",
				-1.0
			)
		) == 0.0
		and not bool(
			oil_event_limited.get(
			"active",
			true
		)
		),
		"Finite external event state expires at its declared duration",
		all_passed
	)

	# ----------------------------------------------------------
	# ACTOR INDEPENDENCE
	# ----------------------------------------------------------

	all_passed = _assert(
		is_equal_approx(
			float(
				actor_b.get_resource_status("oil", {}).get(
					"availability",
					-1.0
				)
			),
			0.50
		),
		"Independent external actors maintain separate limited state",
		all_passed
	)

	# ----------------------------------------------------------
	# NO DOMESTIC COUNTRY SIMULATION
	# ----------------------------------------------------------

	var forbidden_components: Array[String] = [
		"population",
		"economy",
		"government",
		"resources",
		"research",
		"technology_adoption",
		"industry",
		"infrastructure",
		"military",
		"geography",
		"production_process"
	]

	var no_domestic_clone := true

	for component_name in forbidden_components:
		if actor_a.has_component(component_name):
			no_domestic_clone = false
		if actor_b.has_component(component_name):
			no_domestic_clone = false

	all_passed = _assert(
		no_domestic_clone,
		"Limited simulation does not create domestic country components",
		all_passed
	)

	# ----------------------------------------------------------
	# CORE COUNTRY STATE UNTOUCHED
	# ----------------------------------------------------------

	var india = world.get_entity("india")
	var india_before = {}

	if india != null:
		var india_economy = india.get_component("economy")
		if india_economy != null:
			india_before = india_economy.state.duplicate(true)

	system.process_month(world)

	var core_state_unchanged := true

	if india != null:
		var india_economy_after = india.get_component("economy")
		if india_economy_after != null:
			core_state_unchanged = (
				india_before == india_economy_after.state
			)

	all_passed = _assert(
		core_state_unchanged,
		"Limited external simulation does not mutate core-country domestic state",
		all_passed
	)

	# ----------------------------------------------------------
	# SNAPSHOT VISIBILITY
	# ----------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var actor_snapshot = snapshot.entities.get(
		actor_a_id,
		{}
	)

	var actor_components = actor_snapshot.get(
		"components",
		{}
	)

	var actor_component_snapshot = actor_components.get(
		"external_world_actor",
		{}
	)

	var snapshot_state = actor_component_snapshot.get(
		"state",
		{}
	)

	var snapshot_event_state = snapshot_state.get(
		"event_state",
		{}
	)

	all_passed = _assert(
		typeof(
			snapshot_event_state.get(
				"limited_simulation",
				{}
			)
		) == TYPE_DICTIONARY,
		"Snapshot preserves limited external simulation state",
		all_passed
	)

	var snapshot_copy = snapshot_state.duplicate(true)

	var live_limited = actor_a.get_event_state(
		ExternalActorLimitedSimulationSystem.LIMITED_SIMULATION_KEY,
		{}
	)

	live_limited["probe"] = "live_only"
	actor_a.set_event_state(
		ExternalActorLimitedSimulationSystem.LIMITED_SIMULATION_KEY,
		live_limited
	)

	all_passed = _assert(
		not str(
			snapshot_copy.get("event_state", {}).get(
				ExternalActorLimitedSimulationSystem.LIMITED_SIMULATION_KEY,
				{}
			).get(
					"probe",
					""
			)
		) == "live_only",
		"Snapshot limited state is deep-copy isolated",
		all_passed
	)

	# ----------------------------------------------------------
	# RESTORE FIXTURE
	# ----------------------------------------------------------

	world.current_date = original_date
	world.remove_entity(actor_a_id)
	world.remove_entity(actor_b_id)

	TestLogger.write_line(
		"External Actor Limited Simulation 10.4 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _assert(
	condition: bool,
	label: String,
	current: bool
) -> bool:
	if condition:
		TestLogger.write_line(label + ": PASS")
		return current

	TestLogger.write_line(label + ": FAIL")
	return false
