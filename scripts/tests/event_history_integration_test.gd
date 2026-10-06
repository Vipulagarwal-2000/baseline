class_name EventHistoryIntegrationTest
extends RefCounted


# ============================================================
# E12 — HISTORY INTEGRATION TEST
# ============================================================
#
# Required E12 checks:
# - executed event produces an EventResult
# - result is transformed into a history entry
# - result reaches a history sink through the explicit bridge
# - history entry is stored
# - blocked and failed executions remain distinguishable
#
# IMPORTANT:
# The current concrete project HistorySystem source was not
# available in the development handoff. Therefore this test uses
# a minimal in-memory history sink implementing the explicit E12
# bridge contract. It does NOT claim concrete HistorySystem
# runtime integration until that source is inspected and connected.
# ============================================================


class TestHistorySink:
	extends RefCounted

	var entries: Array = []

	func record_event_result(
		entry: Dictionary
	) -> bool:
		entries.append(entry.duplicate(true))
		return true

	func get_entries() -> Array:
		return entries.duplicate(true)


static func run() -> bool:
	TestLogger.section(
		"EventHistoryBridge — E12 History Integration"
	)

	var test_passed: bool = true


	# ------------------------------------------------------------
	# EXECUTED RESULT
	# ------------------------------------------------------------

	var executed_result: EventResult = EventResult.new(
		"test_stability_event",
		"india"
	)

	executed_result.status = EventResult.STATUS_EXECUTED
	executed_result.eligible = true
	executed_result.effects_executed = true
	executed_result.set_applied_effects(
		[
			{
				"path": "government.stability",
				"operation": "add",
				"value": 0.10,
			}
		]
	)
	executed_result.set_selected_choice("")
	executed_result.set_context(
		12,
		"1951-01",
		"event_framework_test"
	)

	var result_exists_pass: bool = (
		executed_result != null
		and executed_result.is_successful()
	)

	TestLogger.write_line(
		"Executed event produces EventResult: "
		+ ("PASS" if result_exists_pass else "FAIL")
	)

	if not result_exists_pass:
		test_passed = false


	# ------------------------------------------------------------
	# HISTORY PAYLOAD
	# ------------------------------------------------------------

	var history_entry: Dictionary = (
		EventHistoryBridge.build_history_entry(
			executed_result
		)
	)

	var payload_pass: bool = (
		history_entry.get("event_id", "")
			== "test_stability_event"
		and history_entry.get("status", "")
			== EventResult.STATUS_EXECUTED
		and history_entry.get("target", "")
			== "india"
		and bool(history_entry.get("eligible", false))
		and bool(
			history_entry.get(
				"effects_executed",
				false
			)
		)
		and history_entry.get("date", "")
			== "1951-01"
		and int(history_entry.get("tick", -1))
			== 12
		and history_entry.get("source", "")
			== "event_framework_test"
		and typeof(history_entry.get("effects", []))
			== TYPE_ARRAY
	)

	TestLogger.write_line(
		"EventResult produces a complete history payload: "
		+ ("PASS" if payload_pass else "FAIL")
	)

	if not payload_pass:
		test_passed = false


	# ------------------------------------------------------------
	# RESULT → HISTORY SINK
	# ------------------------------------------------------------

	var history_sink: TestHistorySink = (
		TestHistorySink.new()
	)

	var bridge_available_pass: bool = (
		EventHistoryBridge.can_record(
			history_sink
		)
	)

	var record_pass: bool = (
		EventHistoryBridge.record_result(
			history_sink,
			executed_result
		)
	)

	var stored_entries: Array = (
		history_sink.get_entries()
	)

	var stored_pass: bool = (
		stored_entries.size() == 1
		and stored_entries[0].get("event_id", "")
			== "test_stability_event"
		and stored_entries[0].get("target", "")
			== "india"
		and stored_entries[0].get("status", "")
			== EventResult.STATUS_EXECUTED
	)

	var history_reach_pass: bool = (
		bridge_available_pass
		and record_pass
		and stored_pass
	)

	TestLogger.write_line(
		"EventResult reaches and is stored by history sink: "
		+ ("PASS" if history_reach_pass else "FAIL")
	)

	if not history_reach_pass:
		test_passed = false


	# ------------------------------------------------------------
	# BLOCKED RESULT
	# ------------------------------------------------------------

	var blocked_result: EventResult = EventResult.new(
		"test_stability_event",
		"india"
	)

	blocked_result.status = EventResult.STATUS_BLOCKED
	blocked_result.eligible = false
	blocked_result.effects_executed = false
	blocked_result.failure_reason = "conditions_not_met"
	blocked_result.set_context(
		13,
		"1951-02"
	)

	var blocked_entry: Dictionary = (
		EventHistoryBridge.build_history_entry(
			blocked_result
		)
	)

	var blocked_pass: bool = (
		blocked_entry.get("status", "")
			== EventResult.STATUS_BLOCKED
		and not bool(
			blocked_entry.get(
				"eligible",
				true
			)
		)
		and not bool(
			blocked_entry.get(
				"effects_executed",
				true
			)
		)
		and blocked_entry.get(
			"failure_reason",
			""
		) == "conditions_not_met"
	)

	TestLogger.write_line(
		"Blocked execution remains distinguishable in history: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	if not blocked_pass:
		test_passed = false


	# ------------------------------------------------------------
	# FAILED RESULT
	# ------------------------------------------------------------

	var failed_result: EventResult = EventResult.new(
		"test_stability_event",
		"india"
	)

	failed_result.status = EventResult.STATUS_FAILED
	failed_result.eligible = true
	failed_result.effects_executed = false
	failed_result.failure_reason = (
		"effect_execution_failed"
	)
	failed_result.set_context(
		14,
		"1951-03"
	)

	var failed_entry: Dictionary = (
		EventHistoryBridge.build_history_entry(
			failed_result
		)
	)

	var failed_pass: bool = (
		failed_entry.get("status", "")
			== EventResult.STATUS_FAILED
		and bool(
			failed_entry.get(
				"eligible",
				false
			)
		)
		and not bool(
			failed_entry.get(
				"effects_executed",
				true
			)
		)
		and failed_entry.get(
			"failure_reason",
			""
		) == "effect_execution_failed"
	)

	TestLogger.write_line(
		"Failed execution remains distinguishable in history: "
		+ ("PASS" if failed_pass else "FAIL")
	)

	if not failed_pass:
		test_passed = false


	# ------------------------------------------------------------
	# HISTORY PAYLOAD IS DEEP-COPY ISOLATED
	# ------------------------------------------------------------

	var isolated_entry: Dictionary = (
		EventHistoryBridge.build_history_entry(
			executed_result
		)
	)

	var isolated_effects = isolated_entry.get(
		"effects",
		[]
	)

	if typeof(isolated_effects) == TYPE_ARRAY:
		isolated_effects.append(
			{
				"path": "tampered",
			}
		)

	var source_effect_count: int = (
		executed_result.applied_effects.size()
	)

	var isolation_pass: bool = (
		source_effect_count == 1
		and executed_result.applied_effects[0].get(
			"path",
			""
		) == "government.stability"
	)

	TestLogger.write_line(
		"History payload is deep-copy isolated from EventResult: "
		+ ("PASS" if isolation_pass else "FAIL")
	)

	if not isolation_pass:
		test_passed = false


	# ------------------------------------------------------------
	# STATUS CLASSIFICATION
	# ------------------------------------------------------------

	var classification_pass: bool = (
		EventHistoryBridge.classify_status(
			executed_result
		) == "executed"
		and EventHistoryBridge.classify_status(
			blocked_result
		) == "blocked"
		and EventHistoryBridge.classify_status(
			failed_result
		) == "failed"
	)

	TestLogger.write_line(
		"History bridge classifies EventResult statuses correctly: "
		+ (
			"PASS"
			if classification_pass
			else "FAIL"
		)
	)

	if not classification_pass:
		test_passed = false


	TestLogger.write_line(
		"E12 History Integration test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
