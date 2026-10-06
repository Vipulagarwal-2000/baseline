class_name EventConditionValidationTest
extends RefCounted


static func run() -> bool:

	TestLogger.section(
		"EventCondition — E4.5 Complete Validation"
	)

	var passed := true

	# ============================================================
	# VALID SIMPLE COMPARISON
	# ============================================================

	var simple_condition := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_GREATER_EQUAL,
		10
	)

	if not simple_condition.is_valid():
		TestLogger.write_line(
			"FAIL: Valid simple comparison rejected"
		)
		passed = false

	if not EventConditionEvaluator.evaluate(
		simple_condition,
		10
	):
		TestLogger.write_line(
			"FAIL: Valid simple comparison did not evaluate"
		)
		passed = false

	# ============================================================
	# VALID LOGICAL COMPOSITION
	# ============================================================

	var left := EventCondition.new(
		"left.value",
		EventCondition.OPERATOR_GREATER,
		0
	)

	var right := EventCondition.new(
		"right.value",
		EventCondition.OPERATOR_LESS_EQUAL,
		10
	)

	var and_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left, right]
	)

	if not and_condition.is_valid():
		TestLogger.write_line(
			"FAIL: Valid AND composition rejected"
		)
		passed = false

	# ============================================================
	# VALID NESTED CONDITION
	# ============================================================

	var below_limit := EventCondition.new(
		"limit.value",
		EventCondition.OPERATOR_LESS,
		100
	)

	var nested_not := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[below_limit]
	)

	var nested_root := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[and_condition, nested_not]
	)

	if not nested_root.is_valid():
		TestLogger.write_line(
			"FAIL: Valid nested condition rejected"
		)
		passed = false

	# ============================================================
	# MALFORMED LEAF CONDITIONS
	# ============================================================

	var empty_path_condition := EventCondition.new(
		"",
		EventCondition.OPERATOR_EQUAL,
		10
	)

	if empty_path_condition.is_valid():
		TestLogger.write_line(
			"FAIL: Empty-path leaf accepted"
		)
		passed = false

	var unsupported_operator_condition := EventCondition.new(
		"test.value",
		"contains",
		10
	)

	if unsupported_operator_condition.is_valid():
		TestLogger.write_line(
			"FAIL: Unsupported comparison operator accepted"
		)
		passed = false

	var leaf_with_child_array := EventCondition.new(
		"test.value",
		EventCondition.OPERATOR_EQUAL,
		10
	)
	leaf_with_child_array.conditions = [left]

	if leaf_with_child_array.is_valid():
		TestLogger.write_line(
			"FAIL: Leaf with child conditions accepted"
		)
		passed = false

	# ============================================================
	# MALFORMED LOGICAL CONDITIONS
	# ============================================================

	var unsupported_logical_operator := EventCondition.create_logical(
		"XOR",
		[left, right]
	)

	if unsupported_logical_operator.is_valid():
		TestLogger.write_line(
			"FAIL: Unsupported logical operator accepted"
		)
		passed = false

	var empty_and := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[]
	)

	if empty_and.is_valid():
		TestLogger.write_line(
			"FAIL: Empty AND accepted"
		)
		passed = false

	var empty_or := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[]
	)

	if empty_or.is_valid():
		TestLogger.write_line(
			"FAIL: Empty OR accepted"
		)
		passed = false

	var invalid_not_zero := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[]
	)

	if invalid_not_zero.is_valid():
		TestLogger.write_line(
			"FAIL: NOT with zero children accepted"
		)
		passed = false

	var invalid_not_two := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[left, right]
	)

	if invalid_not_two.is_valid():
		TestLogger.write_line(
			"FAIL: NOT with two children accepted"
		)
		passed = false

	var null_child := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left, null]
	)

	if null_child.is_valid():
		TestLogger.write_line(
			"FAIL: Logical condition with null child accepted"
		)
		passed = false

	var non_condition_child := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left, "not a condition"]
	)

	if non_condition_child.is_valid():
		TestLogger.write_line(
			"FAIL: Logical condition with non-condition child accepted"
		)
		passed = false

	# ============================================================
	# MALFORMED MIXED NODE
	# ============================================================

	var mixed_node := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left]
	)
	mixed_node.path = "unexpected.path"

	if mixed_node.is_valid():
		TestLogger.write_line(
			"FAIL: Mixed logical/leaf payload accepted"
		)
		passed = false

	# ============================================================
	# CYCLIC CONDITION GRAPH
	# ============================================================

	var cyclic_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[]
	)
	cyclic_condition.conditions = [cyclic_condition]

	if cyclic_condition.is_valid():
		TestLogger.write_line(
			"FAIL: Cyclic condition graph accepted"
		)
		passed = false

	# ============================================================
	# EVALUATOR MUST REJECT MALFORMED CONDITIONS
	# ============================================================

	if EventConditionEvaluator.evaluate(
		unsupported_operator_condition,
		10
	):
		TestLogger.write_line(
			"FAIL: Evaluator accepted malformed leaf condition"
		)
		passed = false

	if EventConditionEvaluator.evaluate(
		empty_and,
		[]
	):
		TestLogger.write_line(
			"FAIL: Evaluator accepted malformed logical condition"
		)
		passed = false

	TestLogger.write_line(
		"EventCondition E4.5 validation test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
