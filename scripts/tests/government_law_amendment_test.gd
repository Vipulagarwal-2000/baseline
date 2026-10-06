class_name GovernmentLawAmendmentTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
	) -> bool:

	TestLogger.section(
        "GOVERNMENT BASIC LAW / AMENDMENT TEST"
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

	var law_system_instance = simulation.get_system(
        "government_law_amendment_system"
	)
	var law_system_ok: bool = (
		law_system_instance != null
		and law_system_instance is GovernmentLawAmendmentSystem
	)
	TestLogger.write_line(
        "Registered GovernmentLawAmendmentSystem available: "
		+ ("PASS" if law_system_ok else "FAIL")
	)
	all_passed = all_passed and law_system_ok
	if not law_system_ok:
		return false

	var law_system: GovernmentLawAmendmentSystem = (
		law_system_instance as GovernmentLawAmendmentSystem
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

	var initial_law: Dictionary = government.get_current_law_state()
	var initial_provisions = initial_law.get("provisions", {})
	var initial_law_ok: bool = (
		initial_law is Dictionary
		and str(initial_law.get("law_id", "")).strip_edges() == "mvp_government_law"
		and int(initial_law.get("version", 0)) == 1
		and str(initial_law.get("status", "")) == "active"
		and initial_provisions is Dictionary
	)
	TestLogger.write_line(
        "Initial law state is explicit and valid: "
		+ ("PASS" if initial_law_ok else "FAIL")
	)
	all_passed = all_passed and initial_law_ok

	var amendment = {
		"amendment_id": "law_amendment_8_8_test",
		"law_id": "mvp_government_law",
		"provision": "spending_authority",
		"new_value": "expanded",
		"approved": true,
		"expected_version": 1,
		"reason": "controlled_step_8_8_test"
	}

	var proposal_ok: bool = government.propose_law_amendment(amendment)
	TestLogger.write_line(
        "Approved law amendment proposal is accepted: "
		+ ("PASS" if proposal_ok else "FAIL")
	)
	all_passed = all_passed and proposal_ok

	var pending_before_process: Dictionary = government.get_pending_law_amendment()
	var pending_ok: bool = (
		pending_before_process is Dictionary
		and str(pending_before_process.get("amendment_id", "")) == "law_amendment_8_8_test"
	)
	TestLogger.write_line(
        "Approved amendment remains pending before processing: "
		+ ("PASS" if pending_ok else "FAIL")
	)
	all_passed = all_passed and pending_ok

	law_system.process_month(world)

	var amended_law: Dictionary = government.get_current_law_state()
	var provisions = amended_law.get("provisions", {})
	var applied_ok: bool = (
		int(amended_law.get("version", 0)) == 2
		and str(provisions.get("spending_authority", "")) == "expanded"
		and str(amended_law.get("last_amendment_id", "")) == "law_amendment_8_8_test"
		and government.get_pending_law_amendment().is_empty()
	)
	TestLogger.write_line(
        "Approved amendment transitions the current law state: "
		+ ("PASS" if applied_ok else "FAIL")
	)
	all_passed = all_passed and applied_ok

	var last_result = government.get_law_amendment_last_result()
	var ledger = government.get_law_amendment_ledger()
	var audit_ok: bool = (
		last_result is Dictionary
		and str(last_result.get("action", "")) == "amended"
		and ledger is Dictionary
		and ledger.has("1")
	)
	TestLogger.write_line(
        "Law amendment ledger and last-result state are explicit: "
		+ ("PASS" if audit_ok else "FAIL")
	)
	all_passed = all_passed and audit_ok

	var revision_before_repeat: int = int(
		government.get_state(
			"law_amendment_revision",
			0
		)
	)
	var version_before_repeat: int = int(
		amended_law.get("version", 0)
	)

	law_system.process_month(world)

	var repeated_law: Dictionary = government.get_current_law_state()
	var repeated_provisions = repeated_law.get("provisions", {})
	var idempotent_ok: bool = (
		int(government.get_state("law_amendment_revision", 0)) == revision_before_repeat
		and int(repeated_law.get("version", 0)) == version_before_repeat
		and str(repeated_provisions.get("spending_authority", "")) == "expanded"
	)
	TestLogger.write_line(
        "Repeated law processing is idempotent: "
		+ ("PASS" if idempotent_ok else "FAIL")
	)
	all_passed = all_passed and idempotent_ok

	var replacement_amendment = {
		"amendment_id": "law_amendment_replacement_8_8_test",
		"law_id": "mvp_government_law",
		"provision": "spending_authority",
		"new_value": "constrained",
		"approved": true,
		"expected_version": 2
	}

	var replacement_proposal_ok: bool = government.propose_law_amendment(replacement_amendment)
	law_system.process_month(world)

	var replacement_law: Dictionary = government.get_current_law_state()
	var replacement_provisions = replacement_law.get("provisions", {})
	var replacement_ok: bool = (
		replacement_proposal_ok
		and int(replacement_law.get("version", 0)) == 3
		and str(replacement_provisions.get("spending_authority", "")) == "constrained"
	)
	TestLogger.write_line(
        "Replacing a law provision changes the law state deterministically: "
		+ ("PASS" if replacement_ok else "FAIL")
	)
	all_passed = all_passed and replacement_ok

	var stale_amendment = {
		"amendment_id": "law_amendment_stale_8_8_test",
		"law_id": "mvp_government_law",
		"provision": "taxation_authority",
		"new_value": "restricted",
		"approved": true,
		"expected_version": 1
	}

	var stale_proposal_ok: bool = government.propose_law_amendment(stale_amendment)
	law_system.process_month(world)

	var stale_result = government.get_law_amendment_last_result()
	var stale_law = government.get_current_law_state()
	var stale_provisions = stale_law.get("provisions", {})
	var stale_rejected_ok: bool = (
		stale_proposal_ok
		and str(stale_result.get("action", "")) == "rejected"
		and "stale_law_version" in stale_result.get("errors", [])
		and int(stale_law.get("version", 0)) == 3
		and str(stale_provisions.get("taxation_authority", "")) == "baseline"
	)
	TestLogger.write_line(
        "Stale law version is rejected without mutating the current law: "
		+ ("PASS" if stale_rejected_ok else "FAIL")
	)
	all_passed = all_passed and stale_rejected_ok

	var unapproved_amendment = {
		"amendment_id": "law_amendment_unapproved_8_8_test",
		"law_id": "mvp_government_law",
		"provision": "administrative_authority",
		"new_value": "expanded",
		"approved": false,
		"expected_version": 3
	}

	var unapproved_proposal_ok: bool = government.propose_law_amendment(unapproved_amendment)
	TestLogger.write_line(
        "Unapproved amendment is rejected at proposal stage: "
		+ ("PASS" if not unapproved_proposal_ok else "FAIL")
	)
	all_passed = all_passed and not unapproved_proposal_ok

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get("india", {})
	var snapshot_components = entity_snapshot.get("components", {})
	var snapshot_government = snapshot_components.get("government", {})
	var snapshot_state = snapshot_government.get("state", {})

	var snapshot_has_law_state: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("current_law_state")
		and snapshot_state.has("law_amendment_revision")
		and snapshot_state.has("law_amendment_ledger")
	)
	TestLogger.write_line(
        "WorldSnapshot preserves basic law/amendment state: "
		+ ("PASS" if snapshot_has_law_state else "FAIL")
	)
	all_passed = all_passed and snapshot_has_law_state

	var live_version: int = int(
		government.get_current_law_state().get(
			"version",
			0
		)
	)

	if snapshot_state is Dictionary:
		var snapshot_law_value = snapshot_state.get(
			"current_law_state",
			{}
		)
		if snapshot_law_value is Dictionary:
			snapshot_law_value["version"] = -999

	var snapshot_isolated_ok: bool = (
		int(
			government.get_current_law_state().get(
				"version",
				0
			)
		) == live_version
	)
	TestLogger.write_line(
        "WorldSnapshot law state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated_ok

	government.state = original_government_state

	var restored_ok: bool = (
		government.state == original_government_state
	)
	TestLogger.write_line(
        "Step 8.8 government state restoration: "
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
        "Government Basic Law / Amendment 8.8 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
