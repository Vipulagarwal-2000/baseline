class_name Step17_8Step17AcceptanceTest
extends RefCounted


# ============================================================
# STEP 17.8 — FULL DYNAMIC FEEDBACK ACCEPTANCE
# ============================================================
#
# Final Step 17 acceptance boundary.
#
# The test proves one bounded, real monthly causal chain using the
# authoritative systems already verified by 17.1–17.7:
#
#     player action
#          ↓
#     authoritative ActionManager
#          ↓
#     active multi-month action
#
#     same monthly simulation
#          ↓
#     EVENTS phase
#          ↓
#     event effect → GovernmentComponent
#          ↓
#     next WORLD_UPDATE / GovernmentSystem observation
#          ↓
#     DECISIONS phase / changed decision context
#
#     snapshot boundary is crossed while the action is executable
#
# The test is intentionally bounded. It does not create a new feedback
# engine, action engine, event engine, or domain ledger. It composes the
# existing authoritative systems into one end-to-end Step 17 acceptance.
# ============================================================


class TestHistorySink:
	extends RefCounted

	var entries: Array = []

	func record_event_result(entry: Dictionary) -> bool:
		entries.append(entry.duplicate(true))
		return true

	func get_entries() -> Array:
		return entries.duplicate(true)


static func _log_diagnostic(label: String, value) -> void:
	TestLogger.write_line(
		"17.8 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


static func _normalize_action_snapshot(snapshot: Dictionary) -> Dictionary:
	var normalized: Dictionary = {
		"version": snapshot.get("version", 1),
		"pending_actions": [],
		"reservations": []
	}

	var pending_value: Variant = snapshot.get("pending_actions", [])
	if pending_value is Array:
		for action_variant in (pending_value as Array):
			if not action_variant is Dictionary:
				continue
			var action_record: Dictionary = action_variant.duplicate(true)
			action_record.erase("snapshot_action_id")
			normalized["pending_actions"].append(action_record)

	var reservations_value: Variant = snapshot.get("reservations", [])
	if reservations_value is Array:
		for reservation_variant in (reservations_value as Array):
			if not reservation_variant is Dictionary:
				continue
			var reservation_entry: Dictionary = reservation_variant.duplicate(true)
			reservation_entry.erase("source_action_instance_id")
			var reservation_value: Variant = reservation_entry.get(
				"reservation",
				{}
			)
			if reservation_value is Dictionary:
				var normalized_reservation: Dictionary = (
					reservation_value.duplicate(true)
				)
				normalized_reservation.erase("action_instance_id")
				reservation_entry["reservation"] = normalized_reservation
			normalized["reservations"].append(reservation_entry)

	return normalized


static func _find_snapshot_action(
	snapshot_state: Dictionary,
	actor_id: String,
	target_id: String
) -> Dictionary:
	var pending_value: Variant = snapshot_state.get("pending_actions", [])
	if not pending_value is Array:
		return {}

	for action_variant in (pending_value as Array):
		if not action_variant is Dictionary:
			continue
		var action_record: Dictionary = action_variant
		if (
			str(action_record.get("actor_id", "")) == actor_id
			and str(action_record.get("target_id", "")) == target_id
		):
			return action_record.duplicate(true)

	return {}


static func _capture_government_states(world: WorldState) -> Dictionary:
	var result: Dictionary = {}
	if world == null:
		return result

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var entity: SimEntity = entity_variant as SimEntity
		if entity == null:
			continue

		var government: GovernmentComponent = (
			entity.get_component("government")
			as GovernmentComponent
		)
		if government != null:
			result[entity.id] = government.state.duplicate(true)

	return result


static func _capture_relationship_states(world: WorldState) -> Dictionary:
	var result: Dictionary = {}
	if world == null:
		return result

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var entity: SimEntity = entity_variant as SimEntity
		if entity == null:
			continue
		result[entity.id] = entity.relationships.duplicate(true)

	return result


static func _capture_sim_metadata(world: WorldState) -> Dictionary:
	var result: Dictionary = {}
	if world == null:
		return result

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var entity: SimEntity = entity_variant as SimEntity
		if entity == null:
			continue
		result[entity.id] = entity.get_all_sim_metadata().duplicate(true)

	return result


static func _restore_world_fixture(
	world: WorldState,
	original_date: Dictionary,
	original_government_states: Dictionary,
	original_relationship_states: Dictionary,
	original_sim_metadata: Dictionary
) -> bool:
	if world == null:
		return false

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var entity: SimEntity = entity_variant as SimEntity
		if entity == null:
			continue

		if original_sim_metadata.has(entity.id):
			entity.clear_sim_metadata()
			var metadata_value: Variant = original_sim_metadata[entity.id]
			if metadata_value is Dictionary:
				for metadata_key in (metadata_value as Dictionary).keys():
					entity.set_sim_metadata(
						str(metadata_key),
						(metadata_value as Dictionary)[metadata_key]
					)

		if original_relationship_states.has(entity.id):
			entity.relationships = (
				original_relationship_states[entity.id].duplicate(true)
			)

		var government: GovernmentComponent = (
			entity.get_component("government")
			as GovernmentComponent
		)
		if (
			government != null
			and original_government_states.has(entity.id)
		):
			government.state = (
				original_government_states[entity.id].duplicate(true)
			)

	world.current_date = original_date.duplicate(true)
	return true


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"FULL DYNAMIC FEEDBACK ACCEPTANCE — STEP 17.8"
	)

	var test_passed: bool = true

	# ------------------------------------------------------------
	# LIVE AUTHORITIES
	# ------------------------------------------------------------

	var integration: EventSimulationIntegrationSystem = (
		simulation.get_system(
			"event_simulation_integration"
		) as EventSimulationIntegrationSystem
	)
	var decision_system = simulation.get_system("decision_system")
	var government_system = simulation.get_system("government_system")

	var world_simulation_pass: bool = (
		world != null
		and simulation != null
		and simulation.system_manager != null
	)
	TestLogger.write_line(
		"17.8 world / simulation boundary available: "
		+ ("PASS" if world_simulation_pass else "FAIL")
	)
	if not world_simulation_pass:
		return false

	var authorities_pass: bool = (
		integration != null
		and decision_system is DecisionSystem
		and government_system is GovernmentSystem
		and simulation.action_manager != null
		and simulation.snapshot_manager != null
	)
	TestLogger.write_line(
		"17.8 authoritative action / event / government / decision / snapshot systems available: "
		+ ("PASS" if authorities_pass else "FAIL")
	)
	if not authorities_pass:
		return false

	var actor: SimEntity = world.get_entity("india") as SimEntity
	var target: SimEntity = world.get_entity("usa") as SimEntity
	var government: GovernmentComponent = null
	if actor != null:
		government = actor.get_component("government") as GovernmentComponent

	var fixture_pass: bool = (
		actor != null
		and target != null
		and government != null
	)
	TestLogger.write_line(
		"17.8 India / USA / Government fixture available: "
		+ ("PASS" if fixture_pass else "FAIL")
	)
	if not fixture_pass:
		return false

	# ------------------------------------------------------------
	# PRESERVE FULL FIXTURE
	# ------------------------------------------------------------

	var original_action_state: Dictionary = (
		simulation.action_manager.capture_snapshot_state()
	)
	var original_repeatability_state: Dictionary = (
		integration.get_repeatability_controller().snapshot_state()
	)
	var original_history_sink: Object = integration.get_history_sink()
	var original_registration_count: int = (
		integration.get_registration_count()
	)
	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_government_states: Dictionary = (
		_capture_government_states(world)
	)
	var original_relationship_states: Dictionary = (
		_capture_relationship_states(world)
	)
	var original_sim_metadata: Dictionary = (
		_capture_sim_metadata(world)
	)
	var original_snapshot_count: int = simulation.get_snapshot_count()

	integration.clear_registrations()
	integration.get_repeatability_controller().clear_all()

	var history_sink: TestHistorySink = TestHistorySink.new()
	integration.set_history_sink(history_sink)

	var test_event_id: String = "step17_8_final_acceptance_event"
	var event_target_id: String = actor.id
	var event_path: String = "government.political_pressure"
	var event_pressure: float = 0.75

	# ------------------------------------------------------------
	# BASELINE DECISION
	# ------------------------------------------------------------

	var decision_before: DecisionOption = DecisionOption.new(
		"step17_8_baseline_decision",
		"Step 17.8 Baseline Diplomatic Evaluation",
		"diplomatic_outreach"
	)
	decision_before.actor_id = actor.id
	decision_before.target_id = target.id
	decision_before.base_score = 1.0
	decision_before.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var baseline_score: float = decision_system.evaluate_option(
		world,
		actor,
		decision_before
	)
	var baseline_relationship_score: float = (
		decision_before.relationship_score
	)
	var baseline_decision_pass: bool = (
		is_finite(baseline_score)
		and is_finite(baseline_relationship_score)
	)
	TestLogger.write_line(
		"17.8 baseline decision context is evaluable: "
		+ ("PASS" if baseline_decision_pass else "FAIL")
	)
	if not baseline_decision_pass:
		_log_diagnostic("baseline_score", baseline_score)
		_log_diagnostic(
			"baseline_relationship_score",
			baseline_relationship_score
		)
		test_passed = false

	# ------------------------------------------------------------
	# REGISTER REAL EVENT FOR THE LIVE EVENTS PHASE
	# ------------------------------------------------------------

	var definition: EventDefinition = EventDefinition.new(
		test_event_id,
		"Step 17.8 Final Acceptance Event",
		"Synthetic event proving final Step 17 causal closure.",
		"political",
		"country"
	)
	var condition: EventCondition = EventCondition.new(
		event_path,
		EventCondition.OPERATOR_LESS,
		1.10
	)
	var effect: EventEffect = EventEffect.new(
		event_path,
		EventEffect.OPERATION_SET,
		event_pressure
	)

	var event_registered: bool = integration.register_event(
		definition,
		[condition],
		[effect],
		[event_target_id],
		EventRepeatabilityPolicy.one_time()
	)
	TestLogger.write_line(
		"17.8 synthetic event registration: "
		+ ("PASS" if event_registered else "FAIL")
	)
	if not event_registered:
		test_passed = false

	# ------------------------------------------------------------
	# ISSUE REAL PLAYER ACTION
	# ------------------------------------------------------------

	var player_option: DecisionOption = DecisionOption.new(
		"step17_8_final_acceptance_action",
		"Step 17.8 Final Acceptance Diplomatic Outreach",
		"diplomatic_outreach"
	)
	player_option.actor_id = actor.id
	player_option.target_id = target.id
	player_option.base_score = 1.0
	player_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05,
		"action": {
			"value": 12.0,
			"duration_months": 2
		}
	}

	var issuance_result: Dictionary = simulation.issue_player_action(
		actor.id,
		player_option
	)
	var action: SimAction = (
		issuance_result.get("action", null)
		as SimAction
	)
	var player_action_pass: bool = (
		bool(issuance_result.get("success", false))
		and action != null
		and action.total_duration_months == 2
		and action.duration_months == 2
		and action.state == SimAction.STATE_QUEUED
	)
	TestLogger.write_line(
		"17.8 real player action admitted through ActionManager: "
		+ ("PASS" if player_action_pass else "FAIL")
	)
	if not player_action_pass:
		_log_diagnostic("issuance_result", issuance_result)
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N + 1 — ACTION + EVENT IN SAME LIVE MONTH
	# ------------------------------------------------------------

	var date_before_month_1: String = world.get_date_string()
	var elapsed_before_month_1: int = world.get_elapsed_months()

	simulation.tick_month()

	var action_month_1_pass: bool = (
		action != null
		and action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(action.progress, 0.5)
		and action.duration_months == 1
	)
	var pressure_month_1: float = float(
		government.get_state(event_path.replace("government.", ""), -1.0)
	)
	var history_month_1: Array = history_sink.get_entries()
	var month_1_live_pass: bool = (
		world.get_elapsed_months() == elapsed_before_month_1 + 1
		and world.get_date_string() != date_before_month_1
		and action_month_1_pass
		and is_equal_approx(pressure_month_1, event_pressure)
		and history_month_1.size() == 1
		and history_month_1[0].get("event_id", "") == test_event_id
		and history_month_1[0].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
	)
	TestLogger.write_line(
		"17.8 Month N+1 executes action/event causal inputs in the live pipeline: "
		+ ("PASS" if month_1_live_pass else "FAIL")
	)
	if not month_1_live_pass:
		_log_diagnostic("action_month_1", action)
		_log_diagnostic("pressure_month_1", pressure_month_1)
		_log_diagnostic("history_month_1", history_month_1)
		test_passed = false

	# ------------------------------------------------------------
	# SNAPSHOT THE ACTIVE INTEGRATED STATE
	# ------------------------------------------------------------

	var snapshot_count_before: int = simulation.get_snapshot_count()
	simulation.capture_snapshot()
	var snapshot_count_after: int = simulation.get_snapshot_count()
	var latest_snapshot: WorldSnapshot = simulation.get_latest_snapshot()

	var captured_action_state: Dictionary = (
		simulation.get_action_snapshot_state(-1)
	)
	var captured_action: Dictionary = _find_snapshot_action(
		captured_action_state,
		actor.id,
		target.id
	)

	var snapshot_entity: Dictionary = latest_snapshot.entities.get(
		actor.id,
		{}
	) if latest_snapshot != null else {}
	var snapshot_component_map: Variant = snapshot_entity.get(
		"components",
		{}
	)
	var snapshot_government_record: Dictionary = {}
	if snapshot_component_map is Dictionary:
		var government_record: Variant = (
			(snapshot_component_map as Dictionary).get("government", {})
		)
		if government_record is Dictionary:
			snapshot_government_record = government_record

	var snapshot_government_state: Variant = (
		snapshot_government_record.get("state", {})
	)

	var snapshot_capture_pass: bool = (
		latest_snapshot != null
		and snapshot_count_after == snapshot_count_before + 1
		and snapshot_count_after >= original_snapshot_count
		and not captured_action.is_empty()
		and str(captured_action.get("state", "")) == SimAction.STATE_ACTIVE
		and is_equal_approx(
			float(captured_action.get("progress", -1.0)),
			0.5
		)
		and snapshot_government_state == government.state
		and snapshot_entity.get("relationships", {}) == actor.relationships
	)
	TestLogger.write_line(
		"17.8 active action + event consequence are captured at the snapshot boundary: "
		+ ("PASS" if snapshot_capture_pass else "FAIL")
	)
	if not snapshot_capture_pass:
		_log_diagnostic("captured_action", captured_action)
		_log_diagnostic("snapshot_government_state", snapshot_government_state)
		_log_diagnostic("live_government_state", government.state)
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N + 2 — DOWNSTREAM GOVERNMENT + DECISION CONSEQUENCE
	# ------------------------------------------------------------

	var consumed_before_tick: Variant = government.get_state(
		"previous_pressure",
		null
	)
	simulation.tick_month()

	var action_completed_pass: bool = (
		action != null
		and action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(action.progress, 1.0)
	)
	var consumed_pressure: float = float(
		government.get_state("previous_pressure", -1.0)
	)

	var decision_after: DecisionOption = DecisionOption.new(
		"step17_8_post_feedback_decision",
		"Step 17.8 Post-Feedback Diplomatic Evaluation",
		"diplomatic_outreach"
	)
	decision_after.actor_id = actor.id
	decision_after.target_id = target.id
	decision_after.base_score = 1.0
	decision_after.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var after_score: float = decision_system.evaluate_option(
		world,
		actor,
		decision_after
	)
	var after_relationship_score: float = (
		decision_after.relationship_score
	)

	var event_only_once_pass: bool = (
		history_sink.get_entries().size() == 1
		and history_sink.get_entries()[0].get("event_id", "") == test_event_id
	)
	var government_handoff_pass: bool = is_equal_approx(
		consumed_pressure,
		event_pressure
	)
	var decision_context_changed_pass: bool = (
		is_finite(after_score)
		and is_finite(after_relationship_score)
		and not is_equal_approx(
			after_relationship_score,
			baseline_relationship_score
		)
	)
	var downstream_month_pass: bool = (
		world.get_elapsed_months() == elapsed_before_month_1 + 2
		and action_completed_pass
		and government_handoff_pass
		and decision_context_changed_pass
		and event_only_once_pass
	)

	TestLogger.write_line(
		"17.8 Month N+2 completes the player action through ACTIONS: "
		+ ("PASS" if action_completed_pass else "FAIL")
	)
	TestLogger.write_line(
		"17.8 Month N+2 GovernmentSystem consumes the event consequence: "
		+ ("PASS" if government_handoff_pass else "FAIL")
	)
	TestLogger.write_line(
		"17.8 Month N+2 DECISIONS observes the changed environment: "
		+ ("PASS" if decision_context_changed_pass else "FAIL")
	)
	TestLogger.write_line(
		"17.8 one-time event remains non-repeated across the causal chain: "
		+ ("PASS" if event_only_once_pass else "FAIL")
	)
	TestLogger.write_line(
		"17.8 downstream monthly causal closure: "
		+ ("PASS" if downstream_month_pass else "FAIL")
	)

	if not downstream_month_pass:
		_log_diagnostic("consumed_before_tick", consumed_before_tick)
		_log_diagnostic("consumed_pressure", consumed_pressure)
		_log_diagnostic("after_score", after_score)
		_log_diagnostic(
			"after_relationship_score",
			after_relationship_score
		)
		test_passed = false

	# ------------------------------------------------------------
	# PROVE SNAPSHOT REMAINS STABLE AFTER LIVE DIVERGENCE
	# ------------------------------------------------------------

	var captured_action_before_probe: Dictionary = (
		_find_snapshot_action(
			latest_snapshot.get_action_snapshot_state(),
			actor.id,
			target.id
		)
	)

	government.set_state(
		"political_pressure",
		float(government.get_state("political_pressure", 0.0)) + 0.20
	)
	actor.change_relationship_dimension(
		target.id,
		"diplomatic",
		0.50
	)

	var snapshot_stable_after_divergence_pass: bool = (
		latest_snapshot != null
		and latest_snapshot.entities[actor.id]["relationships"]
			== snapshot_entity["relationships"]
		and latest_snapshot.entities[actor.id]["components"]["government"]["state"]
			== snapshot_government_state
		and _find_snapshot_action(
			latest_snapshot.get_action_snapshot_state(),
			actor.id,
			target.id
		).get("progress", -1.0)
			== captured_action_before_probe.get("progress", -2.0)
	)
	TestLogger.write_line(
		"17.8 captured integrated snapshot remains isolated after live divergence: "
		+ ("PASS" if snapshot_stable_after_divergence_pass else "FAIL")
	)
	if not snapshot_stable_after_divergence_pass:
		test_passed = false

	# ------------------------------------------------------------
	# FIXTURE RESTORATION
	# ------------------------------------------------------------

	var action_restore_pass: bool = simulation.action_manager.restore_snapshot_state(
		original_action_state,
		world
	)
	var world_restore_pass: bool = _restore_world_fixture(
		world,
		original_date,
		original_government_states,
		original_relationship_states,
		original_sim_metadata
	)

	integration.clear_registrations()
	integration.get_repeatability_controller().restore_state(
		original_repeatability_state
	)
	integration.set_history_sink(original_history_sink)

	var restored_action_state: Dictionary = (
		_normalize_action_snapshot(
			simulation.action_manager.capture_snapshot_state()
		)
	)
	var normalized_original_action_state: Dictionary = (
		_normalize_action_snapshot(original_action_state)
	)
	var action_state_restored: bool = (
		restored_action_state == normalized_original_action_state
	)
	var registration_restored: bool = (
		integration.get_registration_count() == original_registration_count
	)
	var history_sink_restored: bool = (
		integration.get_history_sink() == original_history_sink
	)
	var repeatability_restored: bool = (
		integration.get_repeatability_controller().snapshot_state()
		== original_repeatability_state
	)
	var date_restored: bool = world.current_date == original_date

	var government_states_restored: bool = true
	for entity_id in original_government_states.keys():
		var check_entity: SimEntity = world.get_entity(str(entity_id)) as SimEntity
		if check_entity == null:
			government_states_restored = false
			continue
		var check_government: GovernmentComponent = (
			check_entity.get_component("government")
			as GovernmentComponent
		)
		if check_government == null:
			government_states_restored = false
			continue
		if check_government.state != original_government_states[entity_id]:
			government_states_restored = false

	var relationship_states_restored: bool = true
	for entity_id in original_relationship_states.keys():
		var check_entity: SimEntity = world.get_entity(str(entity_id)) as SimEntity
		if check_entity == null:
			relationship_states_restored = false
			continue
		if check_entity.relationships != original_relationship_states[entity_id]:
			relationship_states_restored = false

	var restoration_pass: bool = (
		action_restore_pass
		and action_state_restored
		and world_restore_pass
		and government_states_restored
		and relationship_states_restored
		and date_restored
		and registration_restored
		and history_sink_restored
		and repeatability_restored
	)

	TestLogger.write_line(
		"17.8 fixture restoration after full causal chain: "
		+ ("PASS" if restoration_pass else "FAIL")
	)
	if not restoration_pass:
		_log_diagnostic("action_restore_pass", action_restore_pass)
		_log_diagnostic("action_state_restored", action_state_restored)
		_log_diagnostic("world_restore_pass", world_restore_pass)
		_log_diagnostic(
			"government_states_restored",
			government_states_restored
		)
		_log_diagnostic(
			"relationship_states_restored",
			relationship_states_restored
		)
		_log_diagnostic("date_restored", date_restored)
		_log_diagnostic(
			"registration_restored",
			registration_restored
		)
		_log_diagnostic(
			"history_sink_restored",
			history_sink_restored
		)
		_log_diagnostic(
			"repeatability_restored",
			repeatability_restored
		)
		test_passed = false

	TestLogger.write_line(
		"17.8 Full Dynamic Feedback Acceptance overall: "
		+ ("PASS" if test_passed else "FAIL")
	)
	TestLogger.write_line(
		"Step 17.8 Full Dynamic Feedback Acceptance test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
