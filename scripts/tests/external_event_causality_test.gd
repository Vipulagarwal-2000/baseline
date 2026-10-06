class_name ExternalEventCausalityTest
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.3
# EXTERNAL EVENT CAUSALITY TEST
# ============================================================
#
# Validates the narrow 10.3 contract:
#
# external actor
#   -> event creation
#   -> event enters existing event lifecycle
#   -> one or more core-country targets receive material impact state
#   -> impact is idempotent
#   -> irrelevant / non-core targets are rejected
#   -> actor and country impact state are snapshot-visible
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"EXTERNAL EVENT CAUSALITY 10.3 TEST"
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

	var actor_id := "external_causality_test_actor"
	var event_id := "external_oil_disruption_10_3"

	var actor := ExternalWorldActor.new(
		actor_id,
		"External Oil Actor"
	)

	actor.set_event_state(
		"role",
		"external_resource_supplier"
	)

	world.add_entity(actor)

	var india = world.get_entity("india")
	var china = world.get_entity("china")

	all_passed = _assert(
		india != null,
		"India target available",
		all_passed
	)

	all_passed = _assert(
		china != null,
		"China target available",
		all_passed
	)

	if india == null or china == null:
		world.remove_entity(actor_id)
		return false

	# Preserve target component state for deterministic restoration.
	var original_india_component = india.get_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)
	var original_china_component = china.get_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)

	var original_india_state: Dictionary = {}
	var original_china_state: Dictionary = {}

	if original_india_component is ExternalEventImpactComponent:
		original_india_state = original_india_component.state.duplicate(true)

	if original_china_component is ExternalEventImpactComponent:
		original_china_state = original_china_component.state.duplicate(true)

	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()

	var causality := ExternalEventCausalitySystem.new()

	# ----------------------------------------------------------
	# EXTERNAL EVENT CREATION
	# ----------------------------------------------------------

	var target_impacts: Dictionary = {
		"india": {
			"resource": {
				"resource_id": "oil",
				"blocked_quantity": 40.0,
				"severity": 0.80
			},
			"trade": {
				"resource_id": "oil",
				"capacity_reduction": 40.0
			},
			"strategic": {
				"key": "external_resource_pressure",
				"value": 0.80
			}
		},
		"china": {
			"resource": {
				"resource_id": "oil",
				"blocked_quantity": 25.0,
				"severity": 0.60
			}
		}
	}

	var queued := causality.create_external_event(
		world,
		actor_id,
		event_id,
		"External Oil Disruption",
		"international",
		"External supplier disruption reduces oil access for affected core countries.",
		target_impacts,
		100
	)

	all_passed = _assert(
		queued,
		"External event creation",
		all_passed
	)

	# ----------------------------------------------------------
	# CAUSAL PROPAGATION
	# ----------------------------------------------------------

	causality.process_month(world)

	var india_impact := causality.get_impact_component(india)
	var china_impact := causality.get_impact_component(china)

	all_passed = _assert(
		india_impact != null,
		"External event creates India impact state",
		all_passed
	)

	all_passed = _assert(
		china_impact != null,
		"External event creates China impact state",
		all_passed
	)

	if india_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					india_impact.get_resource_impact(
						"oil",
						{}
					).get("blocked_quantity", -1.0)
				),
				40.0
			),
			"Relevant resource consequence reaches India",
			all_passed
		)

	if china_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					china_impact.get_resource_impact(
						"oil",
						{}
					).get("blocked_quantity", -1.0)
				),
				25.0
			),
			"Relevant resource consequence reaches China",
			all_passed
		)

	if india_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					india_impact.get_trade_impact(
						"oil",
						{}
					).get("capacity_reduction", -1.0)
				),
				40.0
			),
			"Relevant trade consequence reaches India",
			all_passed
		)

	if india_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					india_impact.get_strategic_impact(
						"external_resource_pressure",
						{}
					).get("value", -1.0)
				),
				0.80
			),
			"Relevant strategic consequence reaches India",
			all_passed
		)

	# ----------------------------------------------------------
	# EXISTING EVENT LIFECYCLE
	# ----------------------------------------------------------

	var created_event = _find_event(
		world,
		event_id
	)

	all_passed = _assert(
		created_event != null,
		"External SimulationEvent enters existing world event lifecycle",
		all_passed
	)

	all_passed = _assert(
		created_event != null
		and created_event is SimulationEvent,
		"External causal object is a SimulationEvent",
		all_passed
	)

	# ----------------------------------------------------------
	# IDEMPOTENCE
	# ----------------------------------------------------------

	causality.process_month(world)

	if india_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					india_impact.get_resource_impact(
						"oil",
						{}
					).get("blocked_quantity", -1.0)
				),
				40.0
			),
			"Repeated external event processing is idempotent",
			all_passed
		)

	if china_impact != null:
		all_passed = _assert(
			is_equal_approx(
				float(
					china_impact.get_resource_impact(
						"oil",
						{}
					).get("blocked_quantity", -1.0)
				),
				25.0
			),
			"Repeated processing does not duplicate multi-country impact",
			all_passed
		)

	# ----------------------------------------------------------
	# INVALID / IRRELEVANT TARGET REJECTION
	# ----------------------------------------------------------

	var rejected := causality.create_external_event(
		world,
		actor_id,
		"external_invalid_target_10_3",
		"Invalid Target Event",
		"international",
		"This event should be rejected.",
		{
			"not_a_core_country": {
				"resource": {
					"resource_id": "oil",
					"blocked_quantity": 10.0
				}
			}
		}
	)

	all_passed = _assert(
		not rejected,
		"Non-core target is rejected",
		all_passed
	)

	# ----------------------------------------------------------
	# ACTOR PERSISTENCE STATE
	# ----------------------------------------------------------

	var actor_processed = actor.get_event_state(
		ExternalEventCausalitySystem.PROCESSED_EVENT_KEY,
		{}
	)

	all_passed = _assert(
		typeof(actor_processed) == TYPE_DICTIONARY
		and actor_processed.has(event_id),
		"External actor records processed causal event",
		all_passed
	)

	# ----------------------------------------------------------
	# SNAPSHOT VISIBILITY
	# ----------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var actor_snapshot: Dictionary = snapshot.entities.get(
		actor_id,
		{}
	)

	var india_snapshot: Dictionary = snapshot.entities.get(
		"india",
		{}
	)

	var china_snapshot: Dictionary = snapshot.entities.get(
		"china",
		{}
	)

	var india_components: Dictionary = india_snapshot.get(
		"components",
		{}
	)
	var china_components: Dictionary = china_snapshot.get(
		"components",
		{}
	)

	all_passed = _assert(
		actor_snapshot.get("components", {}).has(
			ExternalWorldActor.COMPONENT_TYPE
		),
		"Snapshot preserves external actor causal event state",
		all_passed
	)

	all_passed = _assert(
		india_components.has(
			ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
		),
		"Snapshot preserves India external-event impact state",
		all_passed
	)

	all_passed = _assert(
		china_components.has(
			ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
		),
		"Snapshot preserves China external-event impact state",
		all_passed
	)

	if india_components.has(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	):
		var india_snapshot_state = india_components[
			ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
		].get("state", {})

		all_passed = _assert(
			india_snapshot_state.get(
				"applied_event_ids",
				[]
			).has(event_id),
			"Snapshot preserves causal idempotence state",
			all_passed
		)

	# ----------------------------------------------------------
	# EVENT LIFECYCLE PROGRESS
	# ----------------------------------------------------------

	var synchronizer := EventSynchronizer.new()
	synchronizer.process_month(world)

	var lifecycle_event = _find_event(
		world,
		event_id
	)

	all_passed = _assert(
		lifecycle_event != null
		and lifecycle_event.state in ["active", "resolving", "completed"],
		"External event progresses through existing EventSynchronizer lifecycle",
		all_passed
	)

	# ----------------------------------------------------------
	# RESULT
	# ----------------------------------------------------------

	TestLogger.section(
		"EXTERNAL EVENT CAUSALITY RESULT"
	)

	TestLogger.write_line(
		"External Event Causality 10.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	# Restore event arrays exactly as they were before this test.
	world.active_events = original_active_events
	world.completed_events = original_completed_events

	# Restore or remove temporary impact components.
	_restore_component(
		india,
		original_india_component,
		original_india_state
	)

	_restore_component(
		china,
		original_china_component,
		original_china_state
	)

	world.remove_entity(actor_id)

	return all_passed


static func _restore_component(
	entity,
	original_component,
	original_state: Dictionary
) -> void:
	if entity == null:
		return

	if original_component is ExternalEventImpactComponent:
		entity.components[
			ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
		] = original_component
		original_component.state = original_state.duplicate(true)
		original_component.baseline_state = original_state.duplicate(true)
	else:
		entity.components.erase(
			ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
		)


static func _find_event(
	world: WorldState,
	event_id: String
):
	if world == null:
		return null

	for event in world.active_events:
		if event == null:
			continue
		if not event is SimulationEvent:
			continue
		if event.id == event_id:
			return event

	for event in world.completed_events:
		if event == null:
			continue
		if not event is SimulationEvent:
			continue
		if event.id == event_id:
			return event

	return null


static func _assert(
	condition: bool,
	label: String,
	current: bool
) -> bool:
	var result := condition and current

	TestLogger.write_line(
		label + ": " + ("PASS" if condition else "FAIL")
	)

	return result
