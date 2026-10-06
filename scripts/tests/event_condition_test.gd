class_name EventConditionTest
extends RefCounted


static func run() -> bool:

	var test_passed := true

	TestLogger.section(
		"EventCondition — E4.4"
	)

	# ============================================================
	# CREATE LEAF CONDITION
	# ============================================================

	var condition := EventCondition.new(
		"government.stability",
		"<",
		0.50
	)

	if condition.path != "government.stability":
		TestLogger.write_line(
			"FAIL: EventCondition path"
		)
		test_passed = false

	if condition.operator != "<":
		TestLogger.write_line(
			"FAIL: EventCondition operator"
		)
		test_passed = false

	if condition.value != 0.50:
		TestLogger.write_line(
			"FAIL: EventCondition value"
		)
		test_passed = false

	# ============================================================
	# DEFAULT VALUES
	# ============================================================

	var default_condition := EventCondition.new()

	if default_condition.path != "":
		TestLogger.write_line(
			"FAIL: Default condition path"
		)
		test_passed = false

	if default_condition.operator != "==":
		TestLogger.write_line(
			"FAIL: Default condition operator"
		)
		test_passed = false

	if default_condition.value != null:
		TestLogger.write_line(
			"FAIL: Default condition value"
		)
		test_passed = false

	if default_condition.is_logical_condition():
		TestLogger.write_line(
			"FAIL: Default condition should be a leaf"
		)
		test_passed = false

	# ============================================================
	# SUPPORTED COMPARISON OPERATORS
	# ============================================================

	var supported_operators := (
		EventCondition.get_supported_operators()
	)

	if supported_operators.size() != 6:
		TestLogger.write_line(
			"FAIL: Expected 6 supported comparison operators"
		)
		test_passed = false

	for supported_operator in supported_operators:
		if not EventCondition.is_supported_operator(
			supported_operator
		):
			TestLogger.write_line(
				"FAIL: Supported comparison operator rejected: "
				+ supported_operator
			)
			test_passed = false

	# ============================================================
	# UNSUPPORTED COMPARISON OPERATORS
	# ============================================================

	if EventCondition.is_supported_operator("="):
		TestLogger.write_line(
			"FAIL: Unsupported = operator accepted"
		)
		test_passed = false

	if EventCondition.is_supported_operator("contains"):
		TestLogger.write_line(
			"FAIL: Unsupported contains operator accepted"
		)
		test_passed = false

	# ============================================================
	# SUPPORTED LOGICAL OPERATORS
	# ============================================================

	var logical_operators := (
		EventCondition.get_supported_logical_operators()
	)

	if logical_operators.size() != 3:
		TestLogger.write_line(
			"FAIL: Expected 3 supported logical operators"
		)
		test_passed = false

	if not EventCondition.is_supported_logical_operator(
		EventCondition.LOGICAL_AND
	):
		TestLogger.write_line(
			"FAIL: AND logical operator"
		)
		test_passed = false

	if not EventCondition.is_supported_logical_operator(
		EventCondition.LOGICAL_OR
	):
		TestLogger.write_line(
			"FAIL: OR logical operator"
		)
		test_passed = false

	if not EventCondition.is_supported_logical_operator(
		EventCondition.LOGICAL_NOT
	):
		TestLogger.write_line(
			"FAIL: NOT logical operator"
		)
		test_passed = false

	if EventCondition.is_supported_logical_operator(
		"XOR"
	):
		TestLogger.write_line(
			"FAIL: Unsupported XOR logical operator accepted"
		)
		test_passed = false

	# ============================================================
	# LOGICAL CONDITION CONSTRUCTION
	# ============================================================

	var left := EventCondition.new(
		"left.value",
		">",
		0
	)

	var right := EventCondition.new(
		"right.value",
		"==",
		1
	)

	var and_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[left, right]
	)

	if not and_condition.is_logical_condition():
		TestLogger.write_line(
			"FAIL: AND condition not marked logical"
		)
		test_passed = false

	if and_condition.logical_operator != EventCondition.LOGICAL_AND:
		TestLogger.write_line(
			"FAIL: AND logical operator not stored"
		)
		test_passed = false

	if and_condition.conditions.size() != 2:
		TestLogger.write_line(
			"FAIL: AND child count"
		)
		test_passed = false

	if not and_condition.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: Valid AND structure rejected"
		)
		test_passed = false

	# ============================================================
	# NESTED LOGICAL CONDITION
	# ============================================================

	var not_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[right]
	)

	var nested_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[and_condition, not_condition]
	)

	if not nested_condition.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: Valid nested logical structure rejected"
		)
		test_passed = false

	# ============================================================
	# INVALID LOGICAL STRUCTURES
	# ============================================================

	var invalid_operator := EventCondition.create_logical(
		"XOR",
		[left, right]
	)

	if invalid_operator.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: Invalid logical operator accepted"
		)
		test_passed = false

	var empty_and := EventCondition.create_logical(
		EventCondition.LOGICAL_AND,
		[]
	)

	if empty_and.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: Empty AND structure accepted"
		)
		test_passed = false

	var empty_or := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[]
	)

	if empty_or.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: Empty OR structure accepted"
		)
		test_passed = false

	var invalid_not := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[left, right]
	)

	if invalid_not.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: NOT with two children accepted"
		)
		test_passed = false

	var null_child := EventCondition.create_logical(
		EventCondition.LOGICAL_NOT,
		[null]
	)

	if null_child.is_valid_logical_structure():
		TestLogger.write_line(
			"FAIL: NULL logical child accepted"
		)
		test_passed = false

	# ============================================================
	# RESULT
	# ============================================================

	if test_passed:
		TestLogger.write_line(
			"EventCondition E4.4 test: PASS"
		)
	else:
		TestLogger.write_line(
			"EventCondition E4.4 test: FAIL"
		)

	return test_passed
