class_name EventConditionEvaluatorTest
extends RefCounted

static func run() -> bool:
	var passed := true

	TestLogger.section(
		"EventConditionEvaluator — E4.4"
	)

	# ============================================================
	# E4.3 LEAF COMPARISON REGRESSION
	# ============================================================

	var equal_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_EQUAL,
		10
	)
	if not EventConditionEvaluator.evaluate(equal_condition, 10):
		passed = false
	if EventConditionEvaluator.evaluate(equal_condition, 11):
		passed = false

	var not_equal_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_NOT_EQUAL,
		10
	)
	if not EventConditionEvaluator.evaluate(not_equal_condition, 11):
		passed = false
	if EventConditionEvaluator.evaluate(not_equal_condition, 10):
		passed = false

	var greater_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_GREATER,
		10
	)
	if not EventConditionEvaluator.evaluate(greater_condition, 11):
		passed = false
	if EventConditionEvaluator.evaluate(greater_condition, 10):
		passed = false

	var greater_equal_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_GREATER_EQUAL,
		10
	)
	if not EventConditionEvaluator.evaluate(greater_equal_condition, 10):
		passed = false
	if not EventConditionEvaluator.evaluate(greater_equal_condition, 11):
		passed = false
	if EventConditionEvaluator.evaluate(greater_equal_condition, 9):
		passed = false

	var less_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_LESS,
		10
	)
	if not EventConditionEvaluator.evaluate(less_condition, 9):
		passed = false
	if EventConditionEvaluator.evaluate(less_condition, 10):
		passed = false

	var less_equal_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_LESS_EQUAL,
		10
	)
	if not EventConditionEvaluator.evaluate(less_equal_condition, 10):
		passed = false
	if not EventConditionEvaluator.evaluate(less_equal_condition, 9):
		passed = false
	if EventConditionEvaluator.evaluate(less_equal_condition, 11):
		passed = false

	var invalid_condition := EventCondition.new(
		"test.value",
		"contains",
		10
	)
	if EventConditionEvaluator.evaluate(invalid_condition, 10):
		passed = false

	if EventConditionEvaluator.evaluate(null, 10):
		passed = false

	# ============================================================
	# E4.4 AND TRUTH TABLE
	# ============================================================

	if not EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[true, true]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[true, false]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[false, true]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[false, false]
	):
		passed = false

	# ============================================================
	# E4.4 OR TRUTH TABLE
	# ============================================================

	if not EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_OR,
		[true, true]
	):
		passed = false

	if not EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_OR,
		[true, false]
	):
		passed = false

	if not EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_OR,
		[false, true]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_OR,
		[false, false]
	):
		passed = false

	# ============================================================
	# E4.4 NOT TRUTH TABLE
	# ============================================================

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_NOT,
		[true]
	):
		passed = false

	if not EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_NOT,
		[false]
	):
		passed = false

	# ============================================================
	# E4.4 INVALID LOGICAL INPUTS
	# ============================================================

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_OR,
		[]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_NOT,
		[true, false]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		"XOR",
		[true, false]
	):
		passed = false

	if EventConditionEvaluator.evaluate_logical(
		EventCondition.LOGICAL_AND,
		[true, 1]
	):
		passed = false

	# ============================================================
	# E4.4 COMPOSITE CONDITION EVALUATION
	# ============================================================

	var left := EventCondition.new(
		"left.value",
		EventCondition.OPERATOR_GREATER,
		0
	)

	var right := EventCondition.new(
		"right.value",
		EventCondition.OPERATOR_EQUAL,
		10
	)

	var and_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left, right]
	)

	if not EventConditionEvaluator.evaluate(
		and_condition,
		[5, 10]
	):
		passed = false

	if EventConditionEvaluator.evaluate(
		and_condition,
		[5, 9]
	):
		passed = false

	# ============================================================
	# E4.4 NESTED LOGICAL EXPRESSION
	# Expression: (A AND B) OR NOT(C)
	# ============================================================

	var a := EventCondition.new(
		"a",
		EventCondition.OPERATOR_GREATER,
		0
	)

	var b := EventCondition.new(
		"b",
		EventCondition.OPERATOR_GREATER_EQUAL,
		10
	)

	var c := EventCondition.new(
		"c",
		EventCondition.OPERATOR_EQUAL,
		1
	)

	var nested_and := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[a, b]
	)

	var nested_not := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[c]
	)

	var nested_expression := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[nested_and, nested_not]
	)

	if not EventConditionEvaluator.evaluate(
		nested_expression,
		[[5, 10], [0]]
	):
		passed = false

	if EventConditionEvaluator.evaluate(
		nested_expression,
		[[5, 9], [1]]
	):
		passed = false

	# ============================================================
	# E4.4 INVALID COMPOSITE EVALUATION
	# ============================================================

	var invalid_empty_and := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[]
	)

	if EventConditionEvaluator.evaluate(
		invalid_empty_and,
		[]
	):
		passed = false

	if EventConditionEvaluator.evaluate(
		and_condition,
		[5]
	):
		passed = false

	if EventConditionEvaluator.evaluate(
		and_condition,
		5
	):
		passed = false

	var invalid_not := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[left, right]
	)

	if EventConditionEvaluator.evaluate(
		invalid_not,
		[5, 10]
	):
		passed = false

	var null_child := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[null]
	)

	if EventConditionEvaluator.evaluate(
		null_child,
		[true]
	):
		passed = false

	TestLogger.write_line(
		"EventConditionEvaluator E4.4 test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
