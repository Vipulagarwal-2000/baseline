class_name DecisionOption
extends RefCounted

var id: String = ""
var name: String = ""
var description: String = ""

var actor_id: String = ""
var target_id: String = ""

var action_type: String = ""

var base_score: float = 0.0
var goal_score: float = 0.0
var strategy_score: float = 0.0
var relationship_score: float = 0.0
var economic_score: float = 0.0
var military_score: float = 0.0
var diplomatic_score: float = 0.0
var risk_score: float = 0.0
var uncertainty_score: float = 0.0

var final_score: float = 0.0

var available: bool = true
var blocked_reason: String = ""

var metadata: Dictionary = {}


func _init(
	option_id: String = "",
	option_name: String = "",
	type: String = ""
):
	id = option_id
	name = option_name
	action_type = type


func calculate_final_score() -> float:
	final_score = (
		base_score +
		goal_score +
		strategy_score +
		relationship_score +
		economic_score +
		military_score +
		diplomatic_score +
		risk_score +
		uncertainty_score
	)

	return final_score


func block(reason: String) -> void:
	available = false
	blocked_reason = reason


func is_available() -> bool:
	return available

# ============================================================
# STEP 15.2 — DECISION → EXECUTABLE ACTION CONVERSION
# ============================================================

func to_executable_action(
	start_date_override: String = ""
) -> SimAction:
	"""
	Convert this decision option into the single executable action
	contract used by both player and AI paths.

	The decision option remains a choice/scoring object. Runtime
	lifecycle state is initialized by SimAction itself:
	queued, zero progress, empty failure reason, and isolated
	mutable payload containers.

	Action-specific data may be supplied either:
	1. inside metadata["action"], or
	2. as flat keys in metadata for compatibility.

	Supported action payload keys:
	value
	duration / duration_months
	cost
	resource_requirements
	financial_requirements
	capability_requirements
	capacity_requirements
	start_date
	effects
	completion_result
	"""

	var action_payload: Dictionary = _get_action_payload()

	var action_value: float = _get_action_float(
		action_payload,
		"value",
		0.0
	)

	var action_duration: int = _get_action_int(
		action_payload,
		"duration_months",
		_get_action_int(
			action_payload,
			"duration",
			1
		)
	)

	var executable_action_type: String = _resolve_executable_action_type(
		action_payload
	)

	var action: SimAction = SimAction.new(
		executable_action_type,
		actor_id,
		target_id,
		action_value,
		action_duration
	)

	action.cost = _get_action_float(
		action_payload,
		"cost",
		0.0
	)

	action.resource_requirements = _get_action_dictionary(
		action_payload,
		"resource_requirements"
	)

	action.financial_requirements = _get_action_dictionary(
		action_payload,
		"financial_requirements"
	)

	action.capability_requirements = _get_action_dictionary(
		action_payload,
		"capability_requirements"
	)

	action.capacity_requirements = _get_action_dictionary(
		action_payload,
		"capacity_requirements"
	)

	var resolved_start_date: String = start_date_override

	if resolved_start_date.is_empty():
		resolved_start_date = _get_action_string(
			action_payload,
			"start_date",
			""
		)

	action.start_date = resolved_start_date

	# Decision conversion creates a fresh executable action candidate.
	# Runtime progress/state transitions belong to later Step 15 stages.
	action.state = SimAction.STATE_QUEUED
	action.progress = 0.0
	action.failure_reason = ""

	action.effects = _get_action_dictionary(
		action_payload,
		"effects"
	)

	action.completion_result = _get_action_dictionary(
		action_payload,
		"completion_result"
	)

	return action


func _resolve_executable_action_type(
	action_payload: Dictionary
) -> String:
	# DecisionOption.action_type is used by the decision layer as a
	# category (for example "diplomatic" / "economic"). The executable
	# action layer requires the concrete action kind. A payload override
	# takes precedence; otherwise known canonical option ids provide the
	# concrete executable kind. Unknown options retain their existing
	# action_type for backward compatibility.
	var payload_type: String = str(
		action_payload.get(
			"executable_action_type",
			""
		)
	).strip_edges()

	if not payload_type.is_empty():
		return payload_type

	match id:
		"diplomatic_outreach":
			return "diplomatic_outreach"
		"expand_trade":
			return "expand_trade"
		_: 
			return action_type


func _get_action_payload() -> Dictionary:
	var nested_payload_variant: Variant = metadata.get(
		"action",
		{}
	)

	if typeof(nested_payload_variant) == TYPE_DICTIONARY:
		var nested_payload: Dictionary = nested_payload_variant

		return nested_payload.duplicate(
			true
		)

	return {}


func _get_action_value(
	payload: Dictionary,
	key: String,
	default_value: Variant
) -> Variant:
	if payload.has(key):
		return payload[key]

	return metadata.get(
		key,
		default_value
	)


func _get_action_float(
	payload: Dictionary,
	key: String,
	default_value: float
) -> float:
	var raw_value: Variant = _get_action_value(
		payload,
		key,
		default_value
	)

	return float(raw_value)


func _get_action_int(
	payload: Dictionary,
	key: String,
	default_value: int
) -> int:
	var raw_value: Variant = _get_action_value(
		payload,
		key,
		default_value
	)

	return int(raw_value)


func _get_action_string(
	payload: Dictionary,
	key: String,
	default_value: String
) -> String:
	var raw_value: Variant = _get_action_value(
		payload,
		key,
		default_value
	)

	return str(raw_value)


func _get_action_dictionary(
	payload: Dictionary,
	key: String
) -> Dictionary:
	var raw_value: Variant = _get_action_value(
		payload,
		key,
		{}
	)

	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}

	var dictionary_value: Dictionary = raw_value

	return dictionary_value.duplicate(
		true
	)
