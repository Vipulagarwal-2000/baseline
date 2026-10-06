class_name GovernmentTransitionTest
extends RefCounted


# ============================================================
# GOVERNMENT — STEP 8.10 TEST
# ============================================================
# Validates the limited government-state transition only:
# - registered transition system
# - initial government type state
# - proposal remains pending
# - unapproved transition does not mutate government_type
# - approved transition changes government_type
# - repeated processing is idempotent
# - replacement transition changes type deterministically
# - stale/current-type mismatch is rejected without mutation
# - transition audit state is explicit
# - WorldSnapshot representation and deep-copy isolation
# - government state restoration
# - three-country structural integrity
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
	) -> bool:

	TestLogger.section(
        "GOVERNMENT SIMPLIFIED TRANSITION TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var transition_system_instance = simulation.get_system(
        "government_transition_system"
	)

	var transition_system_ok: bool = (
		transition_system_instance != null
		and transition_system_instance is GovernmentTransitionSystem
	)

	TestLogger.write_line(
        "Registered GovernmentTransitionSystem available: "
		+ ("PASS" if transition_system_ok else "FAIL")
	)
	all_passed = all_passed and transition_system_ok

	if not transition_system_ok:
		return false

	var transition_system: GovernmentTransitionSystem = (
		transition_system_instance as GovernmentTransitionSystem
	)

	var india = world.get_entity("india")
	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false
	TestLogger.write_line("India available: PASS")

	var government = india.get_component("government")
	var government_ok: bool = government != null
	TestLogger.write_line(
        "India government component available: "
		+ ("PASS" if government_ok else "FAIL")
	)
	all_passed = all_passed and government_ok
	if not government_ok:
		return false

	var original_government_state: Dictionary = government.state.duplicate(true)

	government.state = original_government_state.duplicate(true)
	government.set_state(
		"government_type",
        "default"
	)
	government.clear_pending_government_transition()

	var initial_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)

	var initial_type_ok: bool = initial_type == "default"
	TestLogger.write_line(
        "Initial government type is explicit: "
		+ ("PASS" if initial_type_ok else "FAIL")
	)
	all_passed = all_passed and initial_type_ok

	var proposal_ok: bool = government.propose_government_transition(
		"transition_8_10_test_1",
		"reformed",
        "default"
	)

	TestLogger.write_line(
        "Government transition proposal is accepted: "
		+ ("PASS" if proposal_ok else "FAIL")
	)
	all_passed = all_passed and proposal_ok

	var pending_before_approval: Dictionary = government.get_pending_government_transition()
	var pending_ok: bool = (
		pending_before_approval.get("transition_id", "") == "transition_8_10_test_1"
		and pending_before_approval.get("approved", false) == false
		and pending_before_approval.get("to_type", "") == "reformed"
	)
	TestLogger.write_line(
        "Unapproved transition remains pending: "
		+ ("PASS" if pending_ok else "FAIL")
	)
	all_passed = all_passed and pending_ok

	transition_system.process_month(world)

	var unchanged_unapproved_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)
	var unapproved_blocked_ok: bool = (
		unchanged_unapproved_type == "default"
		and not government.get_pending_government_transition().is_empty()
	)
	TestLogger.write_line(
        "Unapproved transition does not change government type: "
		+ ("PASS" if unapproved_blocked_ok else "FAIL")
	)
	all_passed = all_passed and unapproved_blocked_ok

	var approval_ok: bool = government.approve_pending_government_transition(
        "transition_8_10_test_1"
	)
	TestLogger.write_line(
        "Pending government transition can be approved explicitly: "
		+ ("PASS" if approval_ok else "FAIL")
	)
	all_passed = all_passed and approval_ok

	transition_system.process_month(world)

	var transitioned_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)
	var transitioned_ok: bool = transitioned_type == "reformed"
	TestLogger.write_line(
        "Approved transition changes government type: "
		+ ("PASS" if transitioned_ok else "FAIL")
	)
	all_passed = all_passed and transitioned_ok

	var pending_after_transition_ok: bool = (
		government.get_pending_government_transition().is_empty()
	)
	TestLogger.write_line(
        "Completed transition clears pending state: "
		+ ("PASS" if pending_after_transition_ok else "FAIL")
	)
	all_passed = all_passed and pending_after_transition_ok

	var revision_after_transition: int = int(
		government.get_state(
			"government_transition_revision",
			0
		)
	)

	transition_system.process_month(world)

	var repeated_revision: int = int(
		government.get_state(
			"government_transition_revision",
			0
		)
	)
	var repeated_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)

	var idempotent_ok: bool = (
		repeated_revision == revision_after_transition
		and repeated_type == "reformed"
	)
	TestLogger.write_line(
        "Repeated transition processing is idempotent: "
		+ ("PASS" if idempotent_ok else "FAIL")
	)
	all_passed = all_passed and idempotent_ok

	var replacement_proposal_ok: bool = government.propose_government_transition(
		"transition_8_10_test_2",
		"centralized",
        "reformed"
	)
	var replacement_approval_ok: bool = (
		replacement_proposal_ok
		and government.approve_pending_government_transition(
            "transition_8_10_test_2"
		)
	)

	transition_system.process_month(world)

	var replacement_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)
	var replacement_ok: bool = (
		replacement_proposal_ok
		and replacement_approval_ok
		and replacement_type == "centralized"
	)
	TestLogger.write_line(
        "Replacing transition changes government type deterministically: "
		+ ("PASS" if replacement_ok else "FAIL")
	)
	all_passed = all_passed and replacement_ok

	var stale_proposal_ok: bool = government.propose_government_transition(
		"transition_8_10_stale",
        "constitutional"
	)
	var stale_approval_ok: bool = (
		stale_proposal_ok
		and government.approve_pending_government_transition(
            "transition_8_10_stale"
		)
	)

	var before_stale_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)
	government.set_state(
		"government_type",
        "externally_changed"
	)
	transition_system.process_month(world)
	var after_stale_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)

	var stale_rejected: Dictionary = government.get_government_transition_last_result()
	var stale_error_ok: bool = false
	if stale_rejected is Dictionary:
		var stale_errors = stale_rejected.get("errors", [])
		if stale_errors is Array:
			stale_error_ok = stale_errors.has("current_type_mismatch")

	var stale_ok: bool = (
		stale_proposal_ok
		and stale_approval_ok
		and before_stale_type == "centralized"
		and after_stale_type == "externally_changed"
		and stale_error_ok
		and not government.get_pending_government_transition().is_empty()
	)
	TestLogger.write_line(
        "Stale current-type transition is rejected without mutation: "
		+ ("PASS" if stale_ok else "FAIL")
	)
	all_passed = all_passed and stale_ok

	government.clear_pending_government_transition()
	government.set_state(
		"government_type",
        "centralized"
	)

	var revision: int = int(
		government.get_state(
			"government_transition_revision",
			0
		)
	)
	var ledger = government.get_government_transition_ledger()
	var result = government.get_government_transition_last_result()
	var audit_ok: bool = (
		revision >= 2
		and ledger is Dictionary
		and result is Dictionary
		and result.has("action")
	)
	TestLogger.write_line(
        "Government transition ledger and last-result state are explicit: "
		+ ("PASS" if audit_ok else "FAIL")
	)
	all_passed = all_passed and audit_ok

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get("india", {})
	var snapshot_components = entity_snapshot.get("components", {})
	var snapshot_government = snapshot_components.get("government", {})
	var snapshot_state = snapshot_government.get("state", {})

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("government_type")
		and snapshot_state.has("pending_government_transition")
		and snapshot_state.has("government_transition_ledger")
	)
	TestLogger.write_line(
        "WorldSnapshot preserves government transition state: "
		+ ("PASS" if snapshot_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_ok

	var live_type: String = str(
		government.get_state(
			"government_type",
            ""
		)
	)
	var snapshot_type_before: String = str(
		snapshot_state.get(
			"government_type",
            ""
		)
	) if snapshot_state is Dictionary else ""

	if snapshot_state is Dictionary:
		snapshot_state["government_type"] = "mutated_snapshot_type"

	var snapshot_isolated_ok: bool = (
		live_type == "centralized"
		and snapshot_type_before == "centralized"
		and str(
			government.get_state(
				"government_type",
                ""
			)
		) == live_type
	)
	TestLogger.write_line(
        "WorldSnapshot government transition state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated_ok

	government.state = original_government_state

	var restored_ok: bool = government.state == original_government_state
	TestLogger.write_line(
        "Step 8.10 government state restoration: "
		+ ("PASS" if restored_ok else "FAIL")
	)
	all_passed = all_passed and restored_ok

	var countries_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null:
			countries_ok = false
			break
		if entity.get_component("government") == null:
			countries_ok = false
			break

	TestLogger.write_line(
        "Three-country world remains structurally clean: "
		+ ("PASS" if countries_ok else "FAIL")
	)
	all_passed = all_passed and countries_ok

	TestLogger.write_line(
        "Government Simplified Transition 8.10 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
