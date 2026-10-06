class_name ExternalEventRelevanceFilterTest
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.5
# EXTERNAL EVENT RELEVANCE FILTER TEST
# ============================================================
#
# Validates:
#   external event exists
#       -> relevance filtering
#       -> relevant core targets remain
#       -> irrelevant targets are omitted
#       -> irrelevant detail is not materialized
#       -> Step 10.3 consumes only the filtered targets
#       -> idempotence / snapshot visibility remain intact
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"EXTERNAL EVENT RELEVANCE FILTER 10.5 TEST"
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

	var filter_system = simulation.get_system(
		"external_event_relevance_filter"
	)

	var causality_system = simulation.get_system(
		"external_event_causality"
	)

	all_passed = _assert(
		filter_system != null,
		"Registered relevance filter system available",
		all_passed
	)

	all_passed = _assert(
		causality_system != null,
		"Registered external causality system available",
		all_passed
	)

	if filter_system == null or causality_system == null:
		return false

	var india = world.get_entity("india")
	var china = world.get_entity("china")
	var usa = world.get_entity("usa")

	all_passed = _assert(
		india != null and china != null and usa != null,
		"All three core-country targets available",
		all_passed
	)

	if india == null or china == null or usa == null:
		return false

	var actor_id := "external_relevance_test_actor"
	var actor := ExternalWorldActor.new(
		actor_id,
		"External Relevance Test Actor"
	)

	world.add_entity(actor)

	var original_india_component = india.get_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)
	var original_usa_component = usa.get_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)
	var original_china_component = china.get_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)

	var original_india_state: Dictionary = {}
	var original_usa_state: Dictionary = {}
	var original_china_state: Dictionary = {}

	if original_india_component is ExternalEventImpactComponent:
		original_india_state = original_india_component.state.duplicate(true)

	if original_usa_component is ExternalEventImpactComponent:
		original_usa_state = original_usa_component.state.duplicate(true)

	if original_china_component is ExternalEventImpactComponent:
		original_china_state = original_china_component.state.duplicate(true)

	var original_active_events: Array = world.active_events.duplicate(true)
	var original_completed_events: Array = world.completed_events.duplicate(true)

	var event_id := "external_relevance_mixed_10_5"

	var target_impacts: Dictionary = {
		"india": {
			"relevant": true,
			"relevance_score": 0.90,
			"relevance_threshold": 0.50,
			"resource": {
				"resource_id": "oil",
				"blocked_quantity": 30.0,
				"severity": 0.60
			},
			"trade": {
				"resource_id": "oil",
				"capacity_reduction": 30.0
			},
			"strategic": {
				"key": "external_pressure",
				"value": 0.60
			},
			"irrelevant_external_domestic_detail": {
				"gdp": 999999.0,
				"population": 999999999.0
			}
		},
		"china": {
			"relevant": false,
			"relevance_score": 0.10,
			"relevance_threshold": 0.50,
			"resource": {
				"resource_id": "oil",
				"blocked_quantity": 80.0,
				"severity": 0.90
			},
			"strategic": {
				"key": "irrelevant_external_pressure",
				"value": 0.90
			}
		},
		"usa": {
			"relevant": true,
			"relevance_score": 0.75,
			"relevance_threshold": 0.50,
			"strategic": {
				"key": "external_pressure",
				"value": 0.25
			},
			"unrelated_detail": "should_not_materialize"
		}
	}

	all_passed = _assert(
		causality_system.queue_external_event(
			world,
			actor_id,
			event_id,
			"External Mixed Relevance Event",
			"international",
			"Synthetic external event for Step 10.5.",
			target_impacts,
			10
		),
		"External mixed-relevance event queued",
		all_passed
	)

	# Filter before Step 10.3 materialization.
	filter_system.process_month(world)

	var pending = actor.get_event_state(
		ExternalEventCausalitySystem.PENDING_EVENT_KEY,
		{}
	)

	all_passed = _assert(
		pending is Dictionary and pending.has(event_id),
		"Filtered event remains queued for causality",
		all_passed
	)

	var filtered_packet: Dictionary = {}

	if pending is Dictionary:
		filtered_packet = pending.get(event_id, {})

	var filtered_targets = filtered_packet.get(
		"target_ids",
		[]
	)

	all_passed = _assert(
		filtered_targets == ["india", "usa"],
		"Relevant core-country targets remain after filtering",
		all_passed
	)

	var filtered_impacts = filtered_packet.get(
		"target_impacts",
		{}
	)

	all_passed = _assert(
		filtered_impacts is Dictionary and not filtered_impacts.has("china"),
		"Irrelevant core-country target is omitted",
		all_passed
	)

	var india_filtered_impact = filtered_impacts.get(
		"india",
		{}
	)

	all_passed = _assert(
		india_filtered_impact is Dictionary
		and india_filtered_impact.has("resource")
		and india_filtered_impact.has("trade")
		and india_filtered_impact.has("strategic")
		and not india_filtered_impact.has("irrelevant_external_domestic_detail"),
		"Irrelevant external detail is stripped before materialization",
		all_passed
	)

	var relevance_state = actor.get_event_state(
		ExternalEventRelevanceFilterSystem.FILTER_STATE_KEY,
		{}
	)

	all_passed = _assert(
		relevance_state is Dictionary
		and relevance_state.get("last_filtered_target_ids", []) == ["china"],
		"Relevance decision state is explicit",
		all_passed
	)

	# Repeat filtering on the same queued event; it must not create a
	# second relevance decision or mutate the filtered packet further.
	var filtered_before_repeat = filtered_packet.duplicate(true)
	filter_system.process_month(world)

	var filtered_after_repeat = actor.get_event_state(
		ExternalEventCausalitySystem.PENDING_EVENT_KEY,
		{}
	).get(event_id, {})

	all_passed = _assert(
		filtered_after_repeat == filtered_before_repeat,
		"Repeated relevance filtering is idempotent",
		all_passed
	)

	# Now allow Step 10.3 to materialize the filtered consequence.
	causality_system.process_month(world)

	var india_impact = causality_system.get_impact_component(india)
	var usa_impact = causality_system.get_impact_component(usa)
	var china_impact = causality_system.get_impact_component(china)

	all_passed = _assert(
		india_impact != null,
		"Relevant India consequence materializes",
		all_passed
	)

	all_passed = _assert(
		usa_impact != null,
		"Relevant USA consequence materializes",
		all_passed
	)

	all_passed = _assert(
		china_impact == null
		or not china_impact.is_event_applied(event_id),
		"Irrelevant China consequence does not materialize",
		all_passed
	)

	if india_impact != null:
		var india_ledger: Array = india_impact.get_state(
			"event_ledger",
			[]
		)
		var india_last: Dictionary = {}
		if not india_ledger.is_empty():
			india_last = india_ledger[india_ledger.size() - 1]

		var materialized_india_impact = india_last.get(
			"impact",
			{}
		)

		all_passed = _assert(
			materialized_india_impact is Dictionary
			and not materialized_india_impact.has("irrelevant_external_domestic_detail"),
			"Irrelevant detail remains absent from materialized India state",
			all_passed
		)

	# ----------------------------------------------------------
	# ALL-IRRELEVANT EVENT
	# ----------------------------------------------------------

	var suppressed_event_id := "external_relevance_suppressed_10_5"

	var suppressed_targets: Dictionary = {
		"china": {
			"relevant": false,
			"relevance_score": 0.05,
			"relevance_threshold": 0.50,
			"resource": {
				"resource_id": "oil",
				"blocked_quantity": 100.0,
				"severity": 1.0
			}
		}
	}

	all_passed = _assert(
		causality_system.queue_external_event(
			world,
			actor_id,
			suppressed_event_id,
			"Suppressed External Event",
			"international",
			"Synthetic irrelevant-only event.",
			suppressed_targets,
			1
		),
		"Irrelevant-only external event queued",
		all_passed
	)

	filter_system.process_month(world)

	var suppressed_pending = actor.get_event_state(
		ExternalEventCausalitySystem.PENDING_EVENT_KEY,
		{}
	)

	var suppressed_events = actor.get_event_state(
		ExternalEventRelevanceFilterSystem.SUPPRESSED_EVENT_KEY,
		{}
	)

	all_passed = _assert(
		suppressed_pending is Dictionary
		and not suppressed_pending.has(suppressed_event_id),
		"Irrelevant-only event is removed from materialization queue",
		all_passed
	)

	all_passed = _assert(
		suppressed_events is Dictionary
		and suppressed_events.has(suppressed_event_id),
		"Suppressed event remains persistently visible to the external actor",
		all_passed
	)

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var actor_snapshot = snapshot.entities.get(actor_id, {})
	var actor_snapshot_components = actor_snapshot.get(
		"components",
		{}
	)
	var actor_snapshot_component = actor_snapshot_components.get(
		ExternalWorldActor.COMPONENT_TYPE,
		{}
	)
	var actor_snapshot_state = actor_snapshot_component.get(
		"state",
		{}
	)
	var snapshot_event_state = actor_snapshot_state.get(
		"event_state",
		{}
	)

	all_passed = _assert(
		snapshot_event_state.get(
			ExternalEventRelevanceFilterSystem.FILTERED_EVENT_KEY,
			{}
		).has(event_id),
		"Snapshot preserves relevance-filter decision state",
		all_passed
	)

	# Deep-copy isolation.
	if actor_snapshot_state is Dictionary:
		var live_relevance = actor.get_event_state(
			ExternalEventRelevanceFilterSystem.FILTER_STATE_KEY,
			{}
		)
		var snapshot_relevance = snapshot_event_state.get(
			ExternalEventRelevanceFilterSystem.FILTER_STATE_KEY,
			{}
		)

		if live_relevance is Dictionary and snapshot_relevance is Dictionary:
			live_relevance["isolation_test"] = true
			actor.set_event_state(
			ExternalEventRelevanceFilterSystem.FILTER_STATE_KEY,
			live_relevance
			)

		all_passed = _assert(
			not bool(
				snapshot_relevance.get(
					"isolation_test",
					false
				)
			),
			"Snapshot relevance state is deep-copy isolated",
			all_passed
		)

	# Restore fixture state.
	if original_india_component is ExternalEventImpactComponent:
		original_india_component.state = original_india_state.duplicate(true)

	if original_usa_component is ExternalEventImpactComponent:
		original_usa_component.state = original_usa_state.duplicate(true)

	if original_china_component is ExternalEventImpactComponent:
		original_china_component.state = original_china_state.duplicate(true)

	india.remove_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)
	usa.remove_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)
	china.remove_component(
		ExternalEventCausalitySystem.IMPACT_COMPONENT_TYPE
	)

	if original_india_component is ExternalEventImpactComponent:
		india.add_component(original_india_component)

	if original_usa_component is ExternalEventImpactComponent:
		usa.add_component(original_usa_component)

	if original_china_component is ExternalEventImpactComponent:
		china.add_component(original_china_component)

	world.active_events = original_active_events
	world.completed_events = original_completed_events
	world.remove_entity(actor_id)

	TestLogger.write_line(
		"External Event Relevance Filter 10.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _assert(
	condition: bool,
	label: String,
	current_result: bool
) -> bool:
	TestLogger.write_line(
		label + ": " + ("PASS" if condition else "FAIL")
	)
	return current_result and condition
