class_name Step17_7SnapshotPersistenceBoundaryTest
extends RefCounted


# ============================================================
# STEP 17.7 — SNAPSHOT / PERSISTENCE BOUNDARY
# ============================================================
#
# Acceptance boundary:
#
#     authoritative executable state
#              ↓
#        WorldSnapshot capture
#              ↓
#     immutable/deep-copy snapshot data
#              ↓
#       live state divergence
#              ↓
#     executable action-state restore
#
# This step deliberately stays within the snapshot contract that already
# exists in SimulationEngine / WorldSnapshot / ActionManager.
#
# It does NOT claim that WorldSnapshot is the final campaign save format.
# It does NOT invent a generic WorldState restore engine.
# It proves that the current snapshot boundary can safely capture the
# integrated executable/domain state required by Step 17 and restore the
# transient executable action state without creating a second authority.
# ============================================================


static func _log_diagnostic(
	label: String,
	value
) -> void:
	TestLogger.write_line(
		"17.7 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


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


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"SNAPSHOT / PERSISTENCE BOUNDARY — STEP 17.7"
	)

	if world == null:
		TestLogger.write_line(
			"17.7 world available: FAIL"
		)
		return false

	if simulation == null or simulation.system_manager == null:
		TestLogger.write_line(
			"17.7 simulation boundary available: FAIL"
		)
		return false

	var snapshot_manager_available: bool = (
		simulation.snapshot_manager != null
		and simulation.get_snapshot_count() >= 0
	)

	TestLogger.write_line(
		"17.7 snapshot / persistence boundary available: "
		+ ("PASS" if snapshot_manager_available else "FAIL")
	)

	if not snapshot_manager_available:
		return false

	var actor: SimEntity = world.get_entity("india") as SimEntity
	var target: SimEntity = world.get_entity("usa") as SimEntity
	var government: GovernmentComponent = null
	if actor != null:
		government = actor.get_component("government") as GovernmentComponent

	var fixture_available: bool = (
		actor != null
		and target != null
		and government != null
		and simulation.action_manager != null
	)

	TestLogger.write_line(
		"17.7 India / USA / Government / ActionManager fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	# ------------------------------------------------------------
	# PRESERVE LIVE FIXTURE
	# ------------------------------------------------------------

	var original_action_state: Dictionary = (
		simulation.action_manager.capture_snapshot_state()
	)
	var original_government_states: Dictionary = {}
	var original_relationship_states: Dictionary = {}
	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var entity: SimEntity = entity_variant as SimEntity
		if entity == null:
			continue

		original_relationship_states[entity.id] = (
			entity.relationships.duplicate(true)
		)

		var entity_government: GovernmentComponent = (
			entity.get_component("government")
			as GovernmentComponent
		)
		if entity_government != null:
			original_government_states[entity.id] = (
				entity_government.state.duplicate(true)
			)

	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_snapshot_count: int = simulation.get_snapshot_count()

	# ------------------------------------------------------------
	# VERIFY LIVE DATE IS AVAILABLE BEFORE SNAPSHOT CAPTURE
	# ------------------------------------------------------------

	var live_date_pass: bool = (
		world.current_date is Dictionary
		and not world.current_date.is_empty()
		and world.current_date.has("year")
		and world.current_date.has("month")
		and world.current_date.has("day")
	)

	TestLogger.write_line(
		"17.7 live world date available before snapshot capture: "
		+ ("PASS" if live_date_pass else "FAIL")
	)

	if not live_date_pass:
		_log_diagnostic("live_world_date", world.current_date)
		return false

	# ------------------------------------------------------------
	# CREATE A REAL EXECUTABLE ACTION
	# ------------------------------------------------------------

	var player_option: DecisionOption = DecisionOption.new(
		"step17_7_snapshot_action",
		"Step 17.7 Snapshot Boundary Action",
		"diplomatic_outreach"
	)
	player_option.actor_id = actor.id
	player_option.target_id = target.id
	player_option.base_score = 1.0
	player_option.metadata = {
		"risk": 0.10,
		"uncertainty": 0.05,
		"action": {
			"value": 8.0,
			"duration_months": 2
		}
	}

	var issuance_result: Dictionary = simulation.issue_player_action(
		actor.id,
		player_option
	)

	var issued: bool = bool(issuance_result.get("success", false))
	TestLogger.write_line(
		"17.7 real executable action admitted: "
		+ ("PASS" if issued else "FAIL")
	)

	if not issued:
		_log_diagnostic("issuance_result", issuance_result)
		return false

	var action: SimAction = issuance_result.get("action", null) as SimAction
	var action_contract_pass: bool = (
		action != null
		and action.total_duration_months == 2
		and action.duration_months == 2
		and action.state == SimAction.STATE_QUEUED
	)

	TestLogger.write_line(
		"17.7 two-month action contract available: "
		+ ("PASS" if action_contract_pass else "FAIL")
	)

	if not action_contract_pass:
		_log_diagnostic("action", action)
		return false

	# ------------------------------------------------------------
	# ENTER ONLY THE AUTHORITATIVE ACTIONS PHASE
	# ------------------------------------------------------------
	#
	# A direct ACTIONS-phase call is used here instead of a complete
	# monthly tick so that Step 17.7 tests snapshot persistence without
	# introducing unrelated WORLD_UPDATE / EVENTS / DECISIONS mutations.
	# The ActionManager remains the registered ACTIONS authority.
	# ------------------------------------------------------------

	simulation.system_manager.process_phase(
		world,
		SimulationPhase.ACTIONS
	)

	var active_action_pass: bool = (
		action.state == SimAction.STATE_ACTIVE
		and is_equal_approx(action.progress, 0.5)
		and action.duration_months == 1
	)

	TestLogger.write_line(
		"17.7 authoritative ACTIONS phase creates restorable active state: "
		+ ("PASS" if active_action_pass else "FAIL")
	)

	if not active_action_pass:
		_log_diagnostic("live_action_state", action.state)
		_log_diagnostic("live_action_progress", action.progress)
		_log_diagnostic("live_action_remaining", action.duration_months)

	# ------------------------------------------------------------
	# CAPTURE SNAPSHOT
	# ------------------------------------------------------------

	var snapshot_count_before_capture: int = simulation.get_snapshot_count()
	simulation.capture_snapshot()
	var snapshot_count_after_capture: int = simulation.get_snapshot_count()
	var latest_snapshot: WorldSnapshot = simulation.get_latest_snapshot()

	var capture_pass: bool = (
		latest_snapshot != null
		and snapshot_count_after_capture == snapshot_count_before_capture + 1
		and snapshot_count_after_capture >= original_snapshot_count
	)

	TestLogger.write_line(
		"17.7 live snapshot captures exactly one new snapshot: "
		+ ("PASS" if capture_pass else "FAIL")
	)

	if not capture_pass:
		_log_diagnostic("snapshot_count_before", snapshot_count_before_capture)
		_log_diagnostic("snapshot_count_after", snapshot_count_after_capture)
		return false

	# ------------------------------------------------------------
	# VERIFY SNAPSHOT DATE CAPTURE
	# ------------------------------------------------------------

	var snapshot_date_pass: bool = (
		latest_snapshot != null
		and latest_snapshot.date is Dictionary
		and not latest_snapshot.date.is_empty()
		and latest_snapshot.date == world.current_date
	)

	TestLogger.write_line(
		"17.7 snapshot captures authoritative date: "
		+ ("PASS" if snapshot_date_pass else "FAIL")
	)

	if not snapshot_date_pass:
		_log_diagnostic("snapshot_date", latest_snapshot.date if latest_snapshot != null else {})
		_log_diagnostic("live_world_date", world.current_date)
		return false

	# ------------------------------------------------------------
	# VERIFY ACTION STATE CAPTURE
	# ------------------------------------------------------------

	var captured_action_state: Dictionary = (
		simulation.get_action_snapshot_state(-1)
	)
	var captured_action: Dictionary = _find_snapshot_action(
		captured_action_state,
		actor.id,
		target.id
	)

	var action_capture_pass: bool = (
		not captured_action.is_empty()
		and str(captured_action.get("state", "")) == SimAction.STATE_ACTIVE
		and is_equal_approx(
			float(captured_action.get("progress", -1.0)),
			0.5
		)
		and int(captured_action.get("duration_months", -1)) == 1
	)

	TestLogger.write_line(
		"17.7 snapshot captures active action progress/status/residual duration: "
		+ ("PASS" if action_capture_pass else "FAIL")
	)

	if not action_capture_pass:
		_log_diagnostic("captured_action", captured_action)

	# ------------------------------------------------------------
	# VERIFY DOMAIN STATE CAPTURE
	# ------------------------------------------------------------

	var snapshot_entity: Dictionary = latest_snapshot.entities.get(
		actor.id,
		{}
	)	
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
	var government_capture_pass: bool = (
		snapshot_government_state == government.state
	)

	var relationship_capture_pass: bool = (
		snapshot_entity.get("relationships", {})
		== actor.relationships
	)

	TestLogger.write_line(
		"17.7 snapshot captures authoritative government state: "
		+ ("PASS" if government_capture_pass else "FAIL")
	)
	TestLogger.write_line(
		"17.7 snapshot captures authoritative relationship state: "
		+ ("PASS" if relationship_capture_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# VERIFY SNAPSHOT DEEP-COPY ISOLATION
	# ------------------------------------------------------------

	var snapshot_action_probe: Dictionary = (
		latest_snapshot.get_action_snapshot_state()
	)
	var probe_action: Dictionary = _find_snapshot_action(
		snapshot_action_probe,
		actor.id,
		target.id
	)	
	if not probe_action.is_empty():
		probe_action["progress"] = 0.99
		probe_action["failure_reason"] = "mutated_probe"

	var stored_action_state_after_probe: Dictionary = (
		latest_snapshot.get_action_snapshot_state()
	)
	var stored_action_after_probe: Dictionary = _find_snapshot_action(
		stored_action_state_after_probe,
		actor.id,
		target.id
	)

	var action_deep_copy_pass: bool = (
		is_equal_approx(
			float(stored_action_after_probe.get("progress", -1.0)),
			0.5
		)
		and str(stored_action_after_probe.get("failure_reason", "")) != "mutated_probe"
	)

	TestLogger.write_line(
		"17.7 action snapshot payload is deep-copy isolated: "
		+ ("PASS" if action_deep_copy_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# VERIFY LIVE DIVERGENCE WITHOUT DESTROYING SNAPSHOT
	# ------------------------------------------------------------

	var original_live_pressure: float = float(
		government.get_state("political_pressure", 0.0)
	)
	government.set_state(
		"political_pressure",
		original_live_pressure + 0.25
	)

	actor.change_relationship_dimension(
		target.id,
		"diplomatic",
		0.75
	)

	if action != null:
		action.progress = 0.95
		action.duration_months = 0

	var snapshot_survives_live_mutation_pass: bool = (
		latest_snapshot.entities[actor.id]["components"]["government"]["state"]
		== snapshot_government_state
		and latest_snapshot.entities[actor.id]["relationships"]
		== snapshot_entity["relationships"]
		and is_equal_approx(
			float(
				_find_snapshot_action(
					latest_snapshot.get_action_snapshot_state(),
					actor.id,
					target.id
				).get("progress", -1.0)
			),
			0.5
		)
	)

	TestLogger.write_line(
		"17.7 captured snapshot remains stable after live-state divergence: "
		+ ("PASS" if snapshot_survives_live_mutation_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# RESTORE TRANSIENT EXECUTABLE STATE FROM SNAPSHOT
	# ------------------------------------------------------------

	var restored: bool = simulation.restore_action_snapshot_state(-1)
	var restored_action_state: Dictionary = (
		simulation.action_manager.capture_snapshot_state()
	)

	var restored_action_normalized: Dictionary = (
		_normalize_action_snapshot(restored_action_state)
	)
	var captured_action_normalized: Dictionary = (
		_normalize_action_snapshot(captured_action_state)
	)

	var executable_restore_pass: bool = (
		restored
		and restored_action_normalized == captured_action_normalized
	)

	TestLogger.write_line(
		"17.7 executable action state restores from captured snapshot: "
		+ ("PASS" if executable_restore_pass else "FAIL")
	)

	if not executable_restore_pass:
		_log_diagnostic("restored", restored)
		_log_diagnostic("restored_action_state", restored_action_state)
		_log_diagnostic("expected_action_state", captured_action_state)

	# ------------------------------------------------------------
	# RESTORE ORIGINAL FIXTURE
	# ------------------------------------------------------------

	simulation.action_manager.restore_snapshot_state(
		original_action_state,
		world
	)

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue
		var restore_entity: SimEntity = entity_variant as SimEntity
		if restore_entity == null:
			continue

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

	var normalized_current_action_state: Dictionary = (
		_normalize_action_snapshot(
			simulation.action_manager.capture_snapshot_state()
		)
	)
	var normalized_original_action_state: Dictionary = (
		_normalize_action_snapshot(original_action_state)
	)

	var restoration_pass: bool = (
		normalized_current_action_state == normalized_original_action_state
		and world.current_date == original_date
	)

	for entity_id in original_government_states.keys():
		var check_entity: SimEntity = world.get_entity(
			str(entity_id)
		) as SimEntity
		if check_entity == null:
			restoration_pass = false
			continue

		var check_government: GovernmentComponent = (
			check_entity.get_component("government")
			as GovernmentComponent
		)
		if check_government == null:
			restoration_pass = false
			continue

		if check_government.state != original_government_states[entity_id]:
			restoration_pass = false

	for entity_id in original_relationship_states.keys():
		var check_relationship_entity: SimEntity = world.get_entity(
			str(entity_id)
		) as SimEntity
		if check_relationship_entity == null:
			restoration_pass = false
			continue

		if check_relationship_entity.relationships != original_relationship_states[entity_id]:
			restoration_pass = false

	TestLogger.write_line(
		"17.7 fixture restores action/domain/date state: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	var test_passed: bool = (
		snapshot_manager_available
		and fixture_available
		and issued
		and action_contract_pass
		and active_action_pass
		and capture_pass
		and action_capture_pass
		and government_capture_pass
		and relationship_capture_pass
		and action_deep_copy_pass
		and snapshot_survives_live_mutation_pass
		and executable_restore_pass
		and restoration_pass
	)

	TestLogger.write_line(
		"Step 17.7 Snapshot / Persistence Boundary test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
