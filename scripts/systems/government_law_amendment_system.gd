class_name GovernmentLawAmendmentSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.8
# BASIC LAW / AMENDMENT
# ============================================================
# A minimal state transition: an explicitly approved amendment changes
# one provision of the current law and increments the law version.
# This deliberately excludes parliament, parties, elections,
# constitutional procedure, courts and a separate legal simulator.
# ============================================================

func _init() -> void:
	super("government_law_amendment_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component("government")

		if government == null:
			continue

		_process_country(government)


func _process_country(government) -> void:

	var pending_value = government.get_state(
		"pending_law_amendment",
		{}
	)

	if not pending_value is Dictionary or pending_value.is_empty():
		_record_result(
			government,
			"no_change",
			[],
			{}
		)
		return

	var amendment: Dictionary = pending_value
	var current_value = government.get_state(
		"current_law_state",
		{}
	)

	if not current_value is Dictionary or current_value.is_empty():
		_reject(government, amendment, "invalid_current_law_state")
		return

	var current_law: Dictionary = current_value

	var amendment_id: String = str(amendment.get("amendment_id", "")).strip_edges()
	var current_law_id: String = str(current_law.get("law_id", "")).strip_edges()
	var requested_law_id: String = str(amendment.get("law_id", "")).strip_edges()
	var provision: String = str(amendment.get("provision", "")).strip_edges()

	if amendment_id.is_empty():
		_reject(government, amendment, "missing_amendment_id")
		return

	if current_law_id.is_empty() or requested_law_id != current_law_id:
		_reject(government, amendment, "law_id_mismatch")
		return

	if provision.is_empty():
		_reject(government, amendment, "missing_provision")
		return

	if not amendment.has("new_value"):
		_reject(government, amendment, "missing_new_value")
		return

	if amendment.get("approved", false) != true:
		_reject(government, amendment, "amendment_not_approved")
		return

	if amendment.has("expected_version"):
		var expected_version_value = amendment.get("expected_version")

		if not (expected_version_value is int or expected_version_value is float):
			_reject(government, amendment, "invalid_expected_version")
			return

		var current_version: int = int(current_law.get("version", 0))

		if int(expected_version_value) != current_version:
			_reject(government, amendment, "stale_law_version")
			return

	var provisions_value = current_law.get("provisions", {})

	if not provisions_value is Dictionary:
		_reject(government, amendment, "invalid_law_provisions")
		return

	var provisions: Dictionary = provisions_value.duplicate(true)
	var previous_value = provisions.get(provision, null)
	var new_value = amendment.get("new_value")

	if provisions.has(provision) and previous_value == new_value:
		government.clear_pending_law_amendment()
		_record_result(
			government,
			"no_change",
			[],
			{
				"amendment_id": amendment_id,
				"law_id": current_law_id,
				"provision": provision,
				"previous_value": previous_value,
				"new_value": new_value,
				"version": int(current_law.get("version", 0))
			}
		)
		return

	var next_law: Dictionary = current_law.duplicate(true)
	provisions[provision] = new_value
	next_law["provisions"] = provisions
	next_law["version"] = int(current_law.get("version", 0)) + 1
	next_law["status"] = "active"
	next_law["last_amendment_id"] = amendment_id

	government.set_state(
		"current_law_state",
		next_law
	)

	var revision: int = int(
		government.get_state(
			"law_amendment_revision",
			0
		)
	) + 1

	government.set_state(
		"law_amendment_revision",
		revision
	)

	var ledger_value = government.get_state(
		"law_amendment_ledger",
		{}
	)
	var ledger: Dictionary = {}

	if ledger_value is Dictionary:
		ledger = ledger_value

	ledger[str(revision)] = {
		"action": "amended",
		"revision": revision,
		"amendment_id": amendment_id,
		"law_id": current_law_id,
		"provision": provision,
		"previous_value": previous_value,
		"new_value": new_value,
		"previous_version": int(current_law.get("version", 0)),
		"new_version": int(next_law.get("version", 0))
	}

	government.set_state(
		"law_amendment_ledger",
		ledger
	)

	government.clear_pending_law_amendment()

	_record_result(
		government,
		"amended",
		[],
		ledger[str(revision)].duplicate(true)
	)


func _reject(
	government,
	amendment: Dictionary,
	reason: String
	) -> void:

	var amendment_id: String = str(amendment.get("amendment_id", "")).strip_edges()

	government.clear_pending_law_amendment()

	_record_result(
		government,
		"rejected",
		[reason],
		{
			"amendment_id": amendment_id,
			"reason": reason
		}
	)


func _record_result(
	government,
	action: String,
	errors: Array,
	result_data: Dictionary
	) -> void:

	government.set_state(
		"law_amendment_last_result",
		{
			"action": action,
			"errors": errors.duplicate(),
			"data": result_data.duplicate(true)
		}
	)
