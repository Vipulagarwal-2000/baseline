class_name EventCondition
extends RefCounted


# ============================================================
# SUPPORTED COMPARISON OPERATORS
# ============================================================

const OPERATOR_EQUAL := "=="
const OPERATOR_NOT_EQUAL := "!="
const OPERATOR_GREATER := ">"
const OPERATOR_GREATER_EQUAL := ">="
const OPERATOR_LESS := "<"
const OPERATOR_LESS_EQUAL := "<="


# ============================================================
# SUPPORTED LOGICAL OPERATORS
# ============================================================

const LOGICAL_AND := "AND"
const LOGICAL_OR := "OR"
const LOGICAL_NOT := "NOT"


# ============================================================
# CONDITION DATA
# ============================================================

# Leaf condition fields. These remain compatible with E4.3.
var path: String = ""
var operator: String = "=="
var value = null

# Composite condition fields introduced for E4.4.
# A logical condition is identified by a non-empty logical_operator.
# The children array contains EventCondition leaves or nested logical conditions.
var logical_operator: String = ""
var conditions: Array = []


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	condition_path: String = "",
	condition_operator: String = "==",
	condition_value = null
):
	path = condition_path
	operator = condition_operator
	value = condition_value


# ============================================================
# LOGICAL CONDITION FACTORY
# ============================================================

static func create_logical(
	condition_logical_operator: String,
	child_conditions: Array = []
) -> EventCondition:

	var condition := EventCondition.new()
	condition.logical_operator = condition_logical_operator
	condition.conditions = child_conditions.duplicate()
	return condition


# ============================================================
# OPERATOR VALIDATION
# ============================================================

static func is_supported_operator(
	condition_operator: String
) -> bool:

	return condition_operator in [
		OPERATOR_EQUAL,
		OPERATOR_NOT_EQUAL,
		OPERATOR_GREATER,
		OPERATOR_GREATER_EQUAL,
		OPERATOR_LESS,
		OPERATOR_LESS_EQUAL
	]


static func get_supported_operators() -> Array[String]:

	return [
		OPERATOR_EQUAL,
		OPERATOR_NOT_EQUAL,
		OPERATOR_GREATER,
		OPERATOR_GREATER_EQUAL,
		OPERATOR_LESS,
		OPERATOR_LESS_EQUAL
	]


# ============================================================
# LOGICAL OPERATOR VALIDATION
# ============================================================

static func is_supported_logical_operator(
	condition_logical_operator: String
) -> bool:

	return condition_logical_operator in [
		LOGICAL_AND,
		LOGICAL_OR,
		LOGICAL_NOT
	]


static func get_supported_logical_operators() -> Array[String]:

	return [
		LOGICAL_AND,
		LOGICAL_OR,
		LOGICAL_NOT
	]


# ============================================================
# CONDITION KIND
# ============================================================

func is_logical_condition() -> bool:
	return not logical_operator.is_empty()


# ============================================================
# E4.4 LOGICAL STRUCTURE VALIDATION
# ============================================================

func is_valid_logical_structure() -> bool:

	if not is_logical_condition():
		return false

	if not EventCondition.is_supported_logical_operator(
		logical_operator
	):
		return false

	match logical_operator:
		LOGICAL_AND, LOGICAL_OR:
			if conditions.is_empty():
				return false

		LOGICAL_NOT:
			if conditions.size() != 1:
				return false

	for child_condition in conditions:
		if child_condition == null:
			return false
		if not (child_condition is EventCondition):
			return false

	return true


# ============================================================
# E4.5 COMPLETE CONDITION VALIDATION
# ============================================================

# Validates the complete condition tree without resolving any world-state
# path and without evaluating an actual runtime value.
#
# Leaf contract:
# - path must be non-empty
# - comparison operator must be supported
# - logical fields must remain unused
#
# Logical contract:
# - logical operator must be supported
# - AND / OR require at least one child
# - NOT requires exactly one child
# - every child must be an EventCondition
# - every child must itself be valid
# - leaf payload must not be mixed into a logical node
#
# A recursion guard rejects cyclic condition graphs deterministically.
func is_valid() -> bool:
	return _validate_condition({})


func _validate_condition(visited: Dictionary) -> bool:

	var condition_id := get_instance_id()

	if visited.has(condition_id):
		return false

	visited[condition_id] = true

	if is_logical_condition():
		var logical_valid := _validate_logical_condition(visited)
		visited.erase(condition_id)
		return logical_valid

	var leaf_valid := _validate_leaf_condition()
	visited.erase(condition_id)
	return leaf_valid


func _validate_leaf_condition() -> bool:

	if path.is_empty():
		return false

	if not EventCondition.is_supported_operator(operator):
		return false

	if not logical_operator.is_empty():
		return false

	if not conditions.is_empty():
		return false

	return true


func _validate_logical_condition(visited: Dictionary) -> bool:

	if not is_valid_logical_structure():
		return false

	# Logical nodes are structural nodes, not leaf comparisons.
	# Reject mixed payload that could make the same node ambiguous.
	if not path.is_empty():
		return false

	if operator != OPERATOR_EQUAL:
		return false

	if value != null:
		return false

	for child_condition in conditions:
		if not child_condition._validate_condition(visited):
			return false

	return true
