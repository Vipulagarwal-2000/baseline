class_name EventHistoryBridge
extends RefCounted


# ============================================================
# E12 — EVENT RESULT → HISTORY BRIDGE
# ============================================================
#
# This is an adapter boundary, not a replacement HistorySystem.
#
# Contract expected from a concrete history sink:
#
#     record_event_result(history_entry: Dictionary) -> bool
#
# The existing project HistorySystem must be inspected before this
# bridge is connected to its concrete implementation.
#
# This keeps E12 from guessing or duplicating an existing history
# authority.
# ============================================================


const HISTORY_RECORD_METHOD: String = "record_event_result"


static func build_history_entry(
	result: EventResult
) -> Dictionary:

	if result == null:
		return {}

	return result.to_history_dict().duplicate(true)


static func can_record(
	history_sink: Object
) -> bool:

	if history_sink == null:
		return false

	return history_sink.has_method(
		HISTORY_RECORD_METHOD
	)


static func record_result(
	history_sink: Object,
	result: EventResult
) -> bool:

	if not can_record(history_sink):
		return false

	if result == null:
		return false

	var entry: Dictionary = build_history_entry(
		result
	)

	if entry.is_empty():
		return false

	var returned = history_sink.call(
		HISTORY_RECORD_METHOD,
		entry
	)

	return bool(returned)


static func classify_status(
	result: EventResult
) -> String:

	if result == null:
		return "invalid"

	if result.is_successful():
		return "executed"

	if result.is_blocked():
		return "blocked"

	if result.is_failed():
		return "failed"

	if result.is_rejected():
		return "rejected"

	return "unknown"
