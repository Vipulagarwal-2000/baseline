class_name ExternalWorldActorTest
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.2
# EXTERNAL ACTOR REPRESENTATION TEST
# ============================================================
#
# This test validates only the Step 10.2 representation contract.
# It does not implement external event causality, relevance
# filtering, or a monthly external simulation system.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"EXTERNAL WORLD ACTOR 10.2 TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line(
			"World supplied: FAIL"
		)
		return false

	TestLogger.write_line(
		"World supplied: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation supplied: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation supplied: PASS"
	)

	var actor := ExternalWorldActor.new(
		"external_test_actor",
		"External Test Actor"
	)

	all_passed = _assert(
		actor != null,
		"External actor construction",
		all_passed
	)

	if actor == null:
		return false

	all_passed = _assert(
		actor.id == "external_test_actor"
		and actor.name == "External Test Actor",
		"Actor identity",
		all_passed
	)

	all_passed = _assert(
		actor.entity_type == ExternalWorldActor.ENTITY_TYPE,
		"External actor entity type",
		all_passed
	)

	all_passed = _assert(
		actor.get_external_actor_component() != null,
		"External actor component exists",
		all_passed
	)

	all_passed = _assert(
		actor.is_lightweight_representation(),
		"External actor remains lightweight",
		all_passed
	)

	# ----------------------------------------------------------
	# Required Step 10.2 state.
	# ----------------------------------------------------------

	actor.set_resource_status(
		"oil",
		{
			"availability": 0.75,
			"disruption": 0.10
		}
	)

	actor.set_strategic_status(
		"regional_tension",
		0.40
	)

	actor.set_trade_capacity(
		"oil",
		120.0
	)

	actor.set_event_state(
		"oil_disruption",
		{
			"active": true,
			"severity": 0.60
		}
	)

	actor.set_relationship(
		"india",
		35.0
	)

	all_passed = _assert(
		float(
			actor.get_resource_status("oil", {}).get(
				"availability",
				-1.0
			)
		) == 0.75,
		"Relevant resource state",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			float(
				actor.get_strategic_status(
					"regional_tension",
					-1.0
				)
			),
			0.40
		),
		"Relevant strategic state",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			actor.get_trade_capacity(
				"oil",
				-1.0
			),
			120.0
		),
		"Relevant trade capacity",
		all_passed
	)

	all_passed = _assert(
		bool(
			actor.get_event_state(
				"oil_disruption",
				{}
			).get("active", false)
		),
		"Relevant event state",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			actor.get_relationship(
				"india",
				-1.0
			),
			35.0
		),
		"Relevant relationship state",
		all_passed
	)

	all_passed = _assert(
		not CoreCountryRegistry.is_core_country(actor.id),
		"External actor remains outside core-country registry",
		all_passed
	)

	# ----------------------------------------------------------
	# Runtime world authority.
	# ----------------------------------------------------------

	world.add_entity(actor)

	all_passed = _assert(
		world.get_entity(actor.id) == actor,
		"External actor is stored in authoritative WorldState",
		all_passed
	)

	# ----------------------------------------------------------
	# Snapshot visibility.
	# ----------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var actor_snapshot: Dictionary = snapshot.entities.get(
		actor.id,
		{}
	)

	all_passed = _assert(
		not actor_snapshot.is_empty(),
		"External actor is visible in WorldSnapshot",
		all_passed
	)

	all_passed = _assert(
		str(
			actor_snapshot.get(
				"entity_type",
				""
			)
		) == ExternalWorldActor.ENTITY_TYPE,
		"Snapshot preserves external actor type",
		all_passed
	)

	var component_snapshots: Dictionary = actor_snapshot.get(
		"components",
		{}
	)

	var component_snapshot: Dictionary = component_snapshots.get(
		ExternalWorldActor.COMPONENT_TYPE,
		{}
	)

	all_passed = _assert(
		component_snapshot.has("state"),
		"Snapshot preserves external actor component state",
		all_passed
	)

	all_passed = _assert(
		component_snapshot.get("state", {}).has("resource_status")
		and component_snapshot.get("state", {}).has("strategic_status")
		and component_snapshot.get("state", {}).has("trade_capacity")
		and component_snapshot.get("state", {}).has("event_state"),
		"Snapshot preserves all Step 10.2 state groups",
		all_passed
	)

	all_passed = _assert(
		float(actor_snapshot.get("relationships", {}).get("india", {}).get("overall", -1.0)) == 35.0,
		"Snapshot preserves relevant relationship state",
		all_passed
	)

	# ----------------------------------------------------------
	# Snapshot determinism and deep-copy isolation.
	# ----------------------------------------------------------

	var second_snapshot := WorldSnapshot.new()
	second_snapshot.capture(world)

	all_passed = _assert(
		second_snapshot.entities.get(actor.id, {}) == actor_snapshot,
		"Repeated snapshot of unchanged actor is deterministic",
		all_passed
	)

	actor.set_trade_capacity(
		"oil",
		5.0
	)
	actor.set_relationship(
		"india",
		10.0
	)

	all_passed = _assert(
		is_equal_approx(
			float(
				component_snapshot["state"]["trade_capacity"]["oil"]
			),
			120.0
		),
		"Snapshot trade state is isolated from live mutation",
		all_passed
	)

	all_passed = _assert(
		float(actor_snapshot["relationships"]["india"].get("overall", -1.0)) == 35.0,
		"Snapshot relationship state is isolated from live mutation",
		all_passed
	)

	# ----------------------------------------------------------
	# Snapshot restoration of the external component state.
	# ----------------------------------------------------------

	var restored := ExternalWorldActor.new(
		"external_restored_actor",
		"External Restored Actor"
	)

	var restored_component = (
		restored.get_external_actor_component()
	)

	var restore_ok: bool = restored_component != null

	if restore_ok:
		restore_ok = restored_component.apply_snapshot_state(
		component_snapshot
		)

	if restore_ok:
		restored.relationships = (
		actor_snapshot.get(
			"relationships",
			{}
		).duplicate(true)
		)

	all_passed = _assert(
		restore_ok,
		"External actor component can restore from its snapshot state",
		all_passed
		)

	if restore_ok:
		all_passed = _assert(
			is_equal_approx(
				restored.get_trade_capacity(
					"oil",
					-1.0
				),
				120.0
			),
			"Restored trade capacity",
			all_passed
		)

		all_passed = _assert(
			is_equal_approx(
				restored.get_relationship(
					"india",
					-1.0
				),
				35.0
			),
			"Restored relationship state",
			all_passed
		)

	# ----------------------------------------------------------
	# No accidental core-country simulation stack.
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

	var no_country_stack: bool = true

	for component_name in forbidden_components:
		if actor.get_component(component_name) != null:
			no_country_stack = false
			break

	all_passed = _assert(
		no_country_stack,
		"External actor does not clone core-country simulation components",
		all_passed
	)

	world.remove_entity(actor.id)

	TestLogger.write_line(
		"External World Actor 10.2 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _assert(
	condition: bool,
	label: String,
	current_result: bool
) -> bool:

	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if condition else "FAIL")
	)

	return current_result and condition
