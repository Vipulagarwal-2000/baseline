class_name GovernmentTransitionSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.10
# SIMPLIFIED GOVERNMENT TRANSITION
# ============================================================
#
# Small MVP state transition only:
#
# current government type
#        ↓
# approved transition request
#        ↓
# eligibility validation
#        ↓
# new government type
#
# This deliberately does not model parliament, parties, elections,
# constitutions, succession law, coups, revolutions, ministries, or
# other detailed political institutions.
#
# The GovernmentComponent owns the transition request and resulting
# government_type state. This system only validates and applies the
# pending transition.
# ============================================================

func _init() -> void:
	super("government_transition_system")


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


func _process_country(government: GovernmentComponent) -> void:

	var pending: Dictionary = government.get_pending_government_transition()

	if pending.is_empty():
		government.set_state(
			"government_transition_last_result",
			{
				"action": "no_change",
				"errors": [],
				"data": {}
			}
		)
		return

	var errors: Array[String] = []

	var approved: bool = pending.get("approved", false) == true
	if not approved:
		errors.append("transition_not_approved")

	var current_type: String = str(
		government.get_state(
			"government_type",
            "default"
		)
	).strip_edges()

	var requested_from_type: String = str(
		pending.get(
			"from_type",
            ""
		)
	).strip_edges()

	var required_current_type: String = str(
		pending.get(
			"required_current_type",
            ""
		)
	).strip_edges()

	var target_type: String = str(
		pending.get(
			"to_type",
            ""
		)
	).strip_edges()

	if requested_from_type.is_empty():
		errors.append("missing_from_type")
	elif current_type != requested_from_type:
		errors.append("current_type_mismatch")

	if not required_current_type.is_empty() and current_type != required_current_type:
		errors.append("required_current_type_mismatch")

	if target_type.is_empty():
		errors.append("missing_target_type")
	elif target_type == current_type:
		errors.append("target_type_matches_current_type")

	var transition_id: String = str(
		pending.get(
			"transition_id",
            ""
		)
	).strip_edges()

	if transition_id.is_empty():
		errors.append("missing_transition_id")

	if not errors.is_empty():
		_record_result(
			government,
			"rejected",
			errors,
			{
				"transition_id": transition_id,
				"from_type": current_type,
				"to_type": target_type
			}
		)
		return

	government.set_state(
		"government_type",
		target_type
	)

	var revision: int = int(
		government.get_state(
			"government_transition_revision",
			0
		)
	) + 1

	var ledger: Dictionary = government.get_government_transition_ledger()

	var transition_result: Dictionary = {
		"action": "transitioned",
		"revision": revision,
		"transition_id": transition_id,
		"previous_government_type": current_type,
		"new_government_type": target_type
	}

	ledger[str(revision)] = transition_result.duplicate(true)

	government.set_state(
		"government_transition_revision",
		revision
	)

	government.set_state(
		"government_transition_ledger",
		ledger
	)

	government.clear_pending_government_transition()

	government.set_state(
		"government_transition_last_result",
		transition_result.duplicate(true)
	)

func _record_result(
	government: GovernmentComponent,
	action: String,
	errors: Array[String],
	data: Dictionary
) -> void:

	var result: Dictionary = {
		"action": action,
		"errors": errors.duplicate(),
		"data": data.duplicate(true)
	}

	government.set_state(
		"government_transition_last_result",
		result.duplicate(true)
	)
