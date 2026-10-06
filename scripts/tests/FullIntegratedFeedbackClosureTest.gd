class_name Step17_6FullIntegratedFeedbackClosureTest
extends RefCounted


# ============================================================
# STEP 17.6 — FULL INTEGRATED FEEDBACK CLOSURE
# ============================================================
#
# Acceptance boundary:
#
#     player action
#          ↓
#     authoritative ActionManager
#          ↓
#     multi-month ACTIONS execution
#          ↓
#     authoritative diplomatic state
#
#     event in the same live monthly simulation
#          ↓
#     authoritative government state
#          ↓
#     next-month GovernmentSystem observation
#
#     both consequences
#          ↓
#     DECISIONS phase
#          ↓
#     decision evaluation sees the changed environment
#
# This test deliberately composes already-proven authorities. It does
# NOT introduce another action engine, event engine, feedback engine,
# or domain ledger.
#
# E13 is already responsible for entering the real EVENTS phase. The
# purpose of 17.6 is therefore broader causal closure: one real monthly
# sequence must carry independent player-action and event consequences
# through later authoritative systems and into the next decision state.
# ============================================================


class TestHistorySink:
	extends RefCounted

	var entries: Array = []

	func record_event_result(
		entry: Dictionary
	) -> bool:
		entries.append(
			entry.duplicate(true)
		)
		return true

	func get_entries() -> Array:
		return entries.duplicate(true)


static func _log_diagnostic(
	label: String,
	value
) -> void:
	TestLogger.write_line(
		"17.6 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


static func _get_actor_action_issued_this_tick(
	simulation: SimulationEngine,
	actor_id: String,
	current_date: String
) -> SimAction:
	if simulation == null or simulation.action_manager == null:
		return null

	for action_variant in simulation.action_manager.get_pending_actions():
		if action_variant == null:
			continue

		var candidate: SimAction = action_variant as SimAction
		if candidate == null:
			continue

		if candidate.actor_id != actor_id:
			continue

		if candidate.start_date != current_date:
			continue

		if (
			candidate.state == SimAction.STATE_QUEUED
			or candidate.state == SimAction.STATE_ACTIVE
		):
			return candidate

	return null


static func _normalize_action_snapshot(
	snapshot: Dictionary
) -> Dictionary:
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
			var reservation_value: Variant = reservation_entry.get("reservation", {})
			if reservation_value is Dictionary:
				var normalized_reservation: Dictionary = reservation_value.duplicate(true)
				normalized_reservation.erase("action_instance_id")
				reservation_entry["reservation"] = normalized_reservation
			normalized["reservations"].append(reservation_entry)

	return normalized


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"FULL INTEGRATED FEEDBACK CLOSURE — STEP 17.6"
	)

	if world == null:
		TestLogger.write_line(
			"17.6 world available: FAIL"
		)
		return false

	if simulation == null or simulation.system_manager == null:
		TestLogger.write_line(
			"17.6 simulation boundary available: FAIL"
		)
		return false

	TestLogger.write_line(
		"17.6 world / simulation boundary available: PASS"
	)

	var integration: EventSimulationIntegrationSystem = (
		simulation.get_system(
			"event_simulation_integration"
		) as EventSimulationIntegrationSystem
	)
	var decision_system = simulation.get_system(
		"decision_system"
	)
	var ai_decision_system = simulation.get_system(
		"ai_decision_system"
	)
	var government_system = simulation.get_system(
		"government_system"
	)

	var systems_available: bool = (
		integration != null
		and decision_system is DecisionSystem
		and ai_decision_system is AIDecisionSystem
		and government_system is GovernmentSystem
		and simulation.action_manager != null
	)

	TestLogger.write_line(
		"17.6 authoritative action / event / government / decision systems available: "
		+ ("PASS" if systems_available else "FAIL")
	)

	if not systems_available:
		return false

	var actor: SimEntity = world.get_entity("india") as SimEntity
	var target: SimEntity = world.get_entity("usa") as SimEntity

	var government: GovernmentComponent = null
	if actor != null:
		government = actor.get_component(
			"government"
		) as GovernmentComponent

	var fixture_available: bool = (
		actor != null
		and target != null
		and government != null
	)

	TestLogger.write_line(
		"17.6 India / USA / Government fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	# ------------------------------------------------------------
	# FIXTURE SAFETY
	# ------------------------------------------------------------

	var initial_registration_count: int = (
		integration.get_registration_count()
	)

	var registration_fixture_pass: bool = (
		initial_registration_count == 0
	)

	TestLogger.write_line(
		"17.6 event registration fixture is isolated: "
		+ ("PASS" if registration_fixture_pass else "FAIL")
	)

	if not registration_fixture_pass:
		_log_diagnostic(
			"unexpected_registration_count",
			initial_registration_count
		)
		return false

	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)
	var original_relationships: Dictionary = (
		actor.relationships.duplicate(true)
	)
	var original_date: Dictionary = (
		world.current_date.duplicate(true)
	)
	var original_sim_metadata: Dictionary = {}
	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var metadata_entity: SimEntity = entity_variant as SimEntity
		if metadata_entity == null:
			continue
		original_sim_metadata[metadata_entity.id] = (
			metadata_entity.get_all_sim_metadata().duplicate(true)
		)
	var original_government_states: Dictionary = {}
	var original_relationship_states: Dictionary = {}
	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var state_entity: SimEntity = entity_variant as SimEntity
		if state_entity == null:
			continue
		if state_entity.entity_type != "country":
			continue

		original_relationship_states[state_entity.id] = (
			state_entity.relationships.duplicate(true)
		)

		var state_government: GovernmentComponent = (
			state_entity.get_component("government")
			as GovernmentComponent
		)
		if state_government != null:
			original_government_states[state_entity.id] = (
			state_government.state.duplicate(true)
		)

	var original_action_state: Dictionary = (
		simulation.action_manager.capture_snapshot_state()
	)
	var original_repeatability_state: Dictionary = (
		integration.get_repeatability_controller().snapshot_state()
	)
	var original_history_sink: Object = (
		integration.get_history_sink()
	)

	integration.clear_registrations()
	integration.get_repeatability_controller().clear_all()

	var history_sink: TestHistorySink = TestHistorySink.new()
	integration.set_history_sink(history_sink)

	var test_passed: bool = true

	# ------------------------------------------------------------
	# BASELINE DECISION CONTEXT
	# ------------------------------------------------------------

	const EVENT_ID: String = "step17_6_integrated_government_event"
	const TARGET_ID: String = "india"
	const EVENT_PRESSURE: float = 0.75
	const EVENT_PATH: String = "government.political_pressure"

	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_before: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var decision_baseline: DecisionOption = DecisionOption.new(
		"step17_6_baseline_evaluation",
		"Step 17.6 Baseline Diplomatic Evaluation",
		"diplomatic_outreach"
	)
	decision_baseline.actor_id = actor.id
	decision_baseline.target_id = target.id
	decision_baseline.base_score = 1.0
	decision_baseline.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05
	}

	var baseline_score: float = decision_system.evaluate_option(
		world,
		actor,
		decision_baseline
	)
	var baseline_relationship_score: float = (
		decision_baseline.relationship_score
	)

	var baseline_pass: bool = (
		is_finite(baseline_score)
		and is_finite(baseline_relationship_score)
	)

	TestLogger.write_line(
		"17.6 baseline decision context is evaluable: "
		+ ("PASS" if baseline_pass else "FAIL")
	)

	if not baseline_pass:
		_log_diagnostic("baseline_score", baseline_score)
		_log_diagnostic(
			"baseline_relationship_score",
			baseline_relationship_score
		)
		test_passed = false

	# ------------------------------------------------------------
	# REGISTER EVENT CONSEQUENCE
	# ------------------------------------------------------------

	var definition: EventDefinition = EventDefinition.new(
		EVENT_ID,
		"Step 17.6 Integrated Government Event",
		"Synthetic event used to close the event-to-domain-to-decision loop.",
		"political",
		"country"
	)

	var condition: EventCondition = EventCondition.new(
		EVENT_PATH,
		EventCondition.OPERATOR_LESS,
		1.10
	)

	var effect: EventEffect = EventEffect.new(
		EVENT_PATH,
		EventEffect.OPERATION_SET,
		EVENT_PRESSURE
	)

	var registration_pass: bool = integration.register_event(
		definition,
		[condition],
		[effect],
		[TARGET_ID],
		EventRepeatabilityPolicy.one_time()
	)

	TestLogger.write_line(
		"17.6 integrated event registration: "
		+ ("PASS" if registration_pass else "FAIL")
	)

	if not registration_pass:
		test_passed = false

	# ------------------------------------------------------------
	# CREATE REAL PLAYER ACTION
	# ------------------------------------------------------------

	var player_option: DecisionOption = DecisionOption.new(
		"step17_6_integrated_player_action",
		"Step 17.6 Integrated Diplomatic Outreach",
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

	var player_action_issued: bool = bool(
		issuance_result.get("success", false)
	)

	TestLogger.write_line(
		"17.6 real player action admitted: "
		+ ("PASS" if player_action_issued else "FAIL")
	)

	if not player_action_issued:
		_log_diagnostic(
			"player_action_issuance",
			issuance_result
		)
		test_passed = false

	var action: SimAction = (
		issuance_result.get("action", null)
		as SimAction
	)

	var action_contract_pass: bool = (
		action != null
		and action.total_duration_months == 2
		and action.duration_months == 2
		and action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"17.6 player action preserves two-month executable contract: "
		+ ("PASS" if action_contract_pass else "FAIL")
	)

	if not action_contract_pass:
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N + 1
	# ------------------------------------------------------------
	# WORLD_UPDATE runs first, ACTIONS resolves the admitted player
	# action, EVENTS executes the synthetic event, and DECISIONS evaluates
	# the resulting world later in the same monthly pass.

	var elapsed_before: int = world.get_elapsed_months()
	var date_before: String = world.get_date_string()

	simulation.tick_month()

	var elapsed_n_plus_one: int = world.get_elapsed_months()
	var action_month_1_active: bool = (
		action != null
		and action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(action.progress, 0.5)
		and action.duration_months == 1
	)

	var event_history_after_month_1: Array = (
		history_sink.get_entries()
	)
	var pressure_after_event: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var month_1_boundary_pass: bool = (
		elapsed_n_plus_one == elapsed_before + 1
		and world.get_date_string() != date_before
		and action_month_1_active
		and is_equal_approx(
			pressure_after_event,
			EVENT_PRESSURE
		)
		and event_history_after_month_1.size() == 1
		and event_history_after_month_1[0].get(
			"event_id",
			""
		) == EVENT_ID
		and event_history_after_month_1[0].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
	)

	TestLogger.write_line(
		"17.6 Month N+1 carries action progress and event consequence together: "
		+ ("PASS" if month_1_boundary_pass else "FAIL")
	)

	if not month_1_boundary_pass:
		_log_diagnostic("action_month_1_state", action)
		_log_diagnostic(
			"pressure_after_event",
			pressure_after_event
		)
		_log_diagnostic(
			"event_history_after_month_1",
			event_history_after_month_1
		)
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N + 2
	# ------------------------------------------------------------
	# The event consequence now reaches GovernmentSystem during
	# WORLD_UPDATE. The player action completes in ACTIONS. DECISIONS then
	# evaluates a fresh option against the changed authoritative world.

	var month_1_relationship: float = actor.get_relationship(
		target.id,
		0.0
	)

	simulation.tick_month()

	var elapsed_n_plus_two: int = world.get_elapsed_months()
	var consumed_previous_pressure: float = float(
		government.get_state(
			"previous_pressure",
			-1.0
		)
	)
	var relationship_after: float = actor.get_relationship(
		target.id,
		0.0
	)
	var diplomatic_after: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var decision_after: DecisionOption = DecisionOption.new(
		"step17_6_post_consequence_evaluation",
		"Step 17.6 Post-Consequence Diplomatic Evaluation",
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

	var live_selected_decision: DecisionOption = (
		ai_decision_system.get_selected_decision(actor)
		as DecisionOption
	)
	var live_decision_options: Variant = actor.get_sim_metadata(
		"decision_options",
		[]
	)

	# AIDecisionSystem stores the selected decision during the registered
	# DECISIONS phase, then SimulationEngine.process_ai_action_issuance()
	# converts that selection through the canonical ActionManager path and
	# clears the transient selected_decision metadata after successful
	# admission. Therefore a null selected_decision after tick_month() is
	# expected when the AI action was actually issued.
	#
	# Important authority rule:
	# DecisionSystem stores the generated option array directly on the
	# actor's `decision_options` metadata. Because this metadata is read
	# from the actor itself, the test must not re-filter those options by
	# DecisionOption.actor_id. Doing so duplicates authority and can reject
	# a valid live option set when an option object has an incomplete actor
	# field even though the real DECISIONS/AIDecision path successfully used
	# it.
	#
	# Durable evidence for the real DECISIONS phase is therefore:
	#   1. the actor's live option set is non-empty;
	#   2. at least one live option has finite evaluated scores;
	#   3. the real AI issuance path admitted an action for this actor/date;
	#   4. the issued action target belongs to the live option set;
	#   5. the same known decision contract evaluates differently after the
	#      integrated event/government consequence.
	var live_decision_option_count: int = 0
	var live_valid_decision_option_count: int = 0
	var live_option_target_ids: Array = []
	if live_decision_options is Array:
		for option_variant in (live_decision_options as Array):
			if option_variant == null:
				continue
			if not option_variant is DecisionOption:
				continue

			var live_option: DecisionOption = option_variant as DecisionOption
			live_decision_option_count += 1

			if not is_finite(live_option.final_score):
				continue

			if not is_finite(live_option.relationship_score):
				continue

			live_valid_decision_option_count += 1
			live_option_target_ids.append(live_option.target_id)

	var actor_ai_action: SimAction = _get_actor_action_issued_this_tick(
		simulation,
		actor.id,
		world.get_date_string()
	)

	var actor_ai_action_issued: bool = actor_ai_action != null

	var issued_action_matches_live_option: bool = false
	if actor_ai_action != null:
		for live_target_id_variant in live_option_target_ids:
			if str(live_target_id_variant) == actor_ai_action.target_id:
				issued_action_matches_live_option = true
				break

	var live_decision_phase_pass: bool = (
		live_decision_options is Array
		and live_decision_option_count > 0
		and live_valid_decision_option_count > 0
		and actor_ai_action_issued
		and issued_action_matches_live_option
	)

	var player_terminal_pass: bool = (
		action != null
		and action.state == SimAction.STATE_COMPLETED
		and is_equal_approx(
			actor.get_relationship_dimension(
				target.id,
				"diplomatic",
				0.0
			),
			diplomatic_after
		)
		and not is_equal_approx(
			diplomatic_after,
			diplomatic_before
		)
	)

	var government_handoff_pass: bool = is_equal_approx(
		consumed_previous_pressure,
		EVENT_PRESSURE
	)

	var decision_context_changed_pass: bool = (
		is_finite(after_score)
		and is_finite(after_relationship_score)
		and not is_equal_approx(
			after_relationship_score,
			baseline_relationship_score
		)
	)

	var integrated_month_2_pass: bool = (
		elapsed_n_plus_two == elapsed_n_plus_one + 1
		and player_terminal_pass
		and government_handoff_pass
		and decision_context_changed_pass
		and live_decision_phase_pass
	)

	TestLogger.write_line(
		"17.6 Month N+2 completes the player action through ACTIONS: "
		+ ("PASS" if player_terminal_pass else "FAIL")
	)

	TestLogger.write_line(
		"17.6 Month N+2 GovernmentSystem consumes the prior event consequence: "
		+ ("PASS" if government_handoff_pass else "FAIL")
	)

	TestLogger.write_line(
		"17.6 Month N+2 DECISIONS sees the changed integrated environment: "
		+ ("PASS" if decision_context_changed_pass else "FAIL")
	)

	TestLogger.write_line(
		"17.6 real DECISIONS phase produced a fresh decision and AI action: "
		+ ("PASS" if live_decision_phase_pass else "FAIL")
	)

	TestLogger.write_line(
		"17.6 two-month integrated causal closure remains intact: "
		+ ("PASS" if integrated_month_2_pass else "FAIL")
	)

	if not integrated_month_2_pass:
		_log_diagnostic(
			"live_decision_option_count",
			live_decision_option_count
		)
		_log_diagnostic(
			"live_valid_decision_option_count",
			live_valid_decision_option_count
		)
		_log_diagnostic(
			"live_option_target_ids",
			live_option_target_ids
		)
		_log_diagnostic(
			"actor_ai_action_issued",
			actor_ai_action_issued
		)
		_log_diagnostic(
			"issued_action_matches_live_option",
			issued_action_matches_live_option
		)
		_log_diagnostic(
			"actor_ai_action",
			actor_ai_action
		)
		_log_diagnostic("relationship_before", relationship_before)
		_log_diagnostic("month_1_relationship", month_1_relationship)
		_log_diagnostic("relationship_after", relationship_after)
		_log_diagnostic("diplomatic_before", diplomatic_before)
		_log_diagnostic("diplomatic_after", diplomatic_after)
		_log_diagnostic(
			"consumed_previous_pressure",
			consumed_previous_pressure
		)
		_log_diagnostic("baseline_score", baseline_score)
		_log_diagnostic("after_score", after_score)
		_log_diagnostic(
			"baseline_relationship_score",
			baseline_relationship_score
		)
		_log_diagnostic(
			"after_relationship_score",
			after_relationship_score
		)
		_log_diagnostic(
			"live_selected_decision",
			live_selected_decision
		)
		_log_diagnostic(
			"live_decision_options",
			live_decision_options
		)
		test_passed = false

	# ------------------------------------------------------------
	# ONE-TIME EVENT / HISTORY INVARIANT
	# ------------------------------------------------------------

	var event_history_after_month_2: Array = (
		history_sink.get_entries()
	)
	var one_time_history_pass: bool = (
		event_history_after_month_2.size() == 1
		and event_history_after_month_2[0].get(
			"event_id",
			""
		) == EVENT_ID
	)

	TestLogger.write_line(
		"17.6 event executes once across the integrated two-month closure: "
		+ ("PASS" if one_time_history_pass else "FAIL")
	)

	if not one_time_history_pass:
		test_passed = false

	# ------------------------------------------------------------
	# RESTORATION
	# ------------------------------------------------------------

	var action_restore_initial_pass: bool = (
		simulation.action_manager.restore_snapshot_state(
			original_action_state,
			world
		)
	)

	# Restore every country touched indirectly by the real monthly systems,
	# not only the India event target. GovernmentSystem and DECISIONS are
	# world-wide phases, so the fixture boundary must be world-wide too.
	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var restore_entity: SimEntity = entity_variant as SimEntity
		if restore_entity == null:
			continue

		var restored_metadata: Variant = original_sim_metadata.get(
			restore_entity.id,
			{}
		)
		restore_entity.clear_sim_metadata()
		if restored_metadata is Dictionary:
			for metadata_key in restored_metadata.keys():
				var metadata_value: Variant = restored_metadata[metadata_key]
				# Restore the original metadata object references rather than
				# deep-copying RefCounted decision/trajectory objects. This keeps
				# cross-system metadata identity intact after the fixture closes.
				restore_entity.set_sim_metadata(
					str(metadata_key),
					metadata_value
				)

		if original_relationship_states.has(restore_entity.id):
			restore_entity.relationships = (
				original_relationship_states[restore_entity.id].duplicate(true)
			)

		var restore_government: GovernmentComponent = (
			restore_entity.get_component("government")
			as GovernmentComponent
		)
		if (
			restore_government != null
			and original_government_states.has(restore_entity.id)
		):
			restore_government.state = (
				original_government_states[restore_entity.id].duplicate(true)
			)

	world.current_date = original_date.duplicate(true)

	integration.clear_registrations()
	integration.get_repeatability_controller().restore_state(
		original_repeatability_state
	)
	integration.set_history_sink(
		original_history_sink
	)

	var normalized_current_action_state: Dictionary = (
		_normalize_action_snapshot(
			simulation.action_manager.capture_snapshot_state()
		)
	)
	var normalized_original_action_state: Dictionary = (
		_normalize_action_snapshot(original_action_state)
	)

	var action_state_restored: bool = (
		normalized_current_action_state
		== normalized_original_action_state
	)

	var government_states_restored: bool = true
	var relationship_states_restored: bool = true

	for entity_id in original_government_states.keys():
		var check_entity: SimEntity = world.get_entity(
			str(entity_id)
		) as SimEntity
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

	for entity_id in original_relationship_states.keys():
		var relationship_entity: SimEntity = world.get_entity(
			str(entity_id)
		) as SimEntity
		if relationship_entity == null:
			relationship_states_restored = false
			continue

		if relationship_entity.relationships != original_relationship_states[entity_id]:
			relationship_states_restored = false

	var action_restore_pass: bool = (
		action_restore_initial_pass and action_state_restored
	)
	var registration_restored: bool = (
		integration.get_registration_count() == initial_registration_count
	)
	var history_sink_restored: bool = (
		integration.get_history_sink() == original_history_sink
	)
	var repeatability_restored: bool = (
		integration.get_repeatability_controller().snapshot_state()
		== original_repeatability_state
	)
	var date_restored: bool = (world.current_date == original_date)

	var restoration_pass: bool = (
		action_restore_pass
		and government_states_restored
		and relationship_states_restored
		and date_restored
		and registration_restored
		and history_sink_restored
		and repeatability_restored
	)

	_log_diagnostic("restoration_action_state", action_restore_pass)
	_log_diagnostic("restoration_government_states", government_states_restored)
	_log_diagnostic("restoration_relationship_states", relationship_states_restored)
	_log_diagnostic("restoration_date", date_restored)
	_log_diagnostic("restoration_event_registration", registration_restored)
	_log_diagnostic("restoration_history_sink", history_sink_restored)
	_log_diagnostic("restoration_repeatability", repeatability_restored)

	TestLogger.write_line(
		"17.6 action/domain/event fixture restoration: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	if not restoration_pass:
		test_passed = false

	TestLogger.write_line(
		"Step 17.6 Full Integrated Feedback Closure test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
