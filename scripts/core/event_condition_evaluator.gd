class_name EventConditionEvaluator
extends RefCounted


# ============================================================
# PUBLIC EVALUATION ENTRY POINT
# ============================================================

static func evaluate(
	condition: EventCondition,
	actual_value
) -> bool:

	if condition == null:
		return false

	# E4.5 makes the condition tree contract explicit before any
	# comparison or logical evaluation occurs.
	if not condition.is_valid():
		return false

	if condition.is_logical_condition():
		return _evaluate_logical_condition(
			condition,
			actual_value
		)

	return _evaluate_leaf_condition(
		condition,
		actual_value
	)


# ============================================================
# LOGICAL TRUTH-TABLE EVALUATION
# ============================================================

static func evaluate_logical(
	logical_operator: String,
	results: Array
) -> bool:

	if not EventCondition.is_supported_logical_operator(
		logical_operator
	):
		return false

	if results.is_empty():
		return false

	for result in results:
		if typeof(result) != TYPE_BOOL:
			return false

	match logical_operator:
		EventCondition.LOGICAL_AND:
			for result in results:
				if not result:
					return false
			return true

		EventCondition.LOGICAL_OR:
			for result in results:
				if result:
					return true
			return false

		EventCondition.LOGICAL_NOT:
			if results.size() != 1:
				return false
			return not results[0]

	return false


# ============================================================
# COMPOSITE CONDITION EVALUATION
# ============================================================

# For a logical condition, actual_value mirrors the condition tree:
# - leaf condition -> scalar actual value
# - logical condition -> Array of child actual values
#
# Example:
#   AND(A, NOT(B))
#   actual_value = [actual_A, [actual_B]]
#
# This keeps path resolution outside the condition evaluator.
static func _evaluate_logical_condition(
	condition: EventCondition,
	actual_value
) -> bool:

	if not condition.is_valid():
		return false

	if typeof(actual_value) != TYPE_ARRAY:
		return false

	if actual_value.size() != condition.conditions.size():
		return false

	var child_results: Array = []

	for index in range(condition.conditions.size()):
		var child_condition = condition.conditions[index]
		var child_actual_value = actual_value[index]

		var child_result := evaluate(
			child_condition,
			child_actual_value
		)

		child_results.append(child_result)

	return evaluate_logical(
		condition.logical_operator,
		child_results
	)


# ============================================================
# LEAF CONDITION EVALUATION
# ============================================================

static func _evaluate_leaf_condition(
	condition: EventCondition,
	actual_value
) -> bool:

	if not condition.is_valid():
		return false

	match condition.operator:
		EventCondition.OPERATOR_EQUAL:
			return actual_value == condition.value

		EventCondition.OPERATOR_NOT_EQUAL:
			return actual_value != condition.value

		EventCondition.OPERATOR_GREATER:
			return actual_value > condition.value

		EventCondition.OPERATOR_GREATER_EQUAL:
			return actual_value >= condition.value

		EventCondition.OPERATOR_LESS:
			return actual_value < condition.value

		EventCondition.OPERATOR_LESS_EQUAL:
			return actual_value <= condition.value

	return false
