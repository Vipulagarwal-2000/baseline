class_name EventEffect
extends RefCounted


# ============================================================
# E6 — DECLARATIVE EFFECT MODEL
# ============================================================

const OPERATION_SET := "set"
const OPERATION_ADD := "add"
const OPERATION_SUBTRACT := "subtract"
const OPERATION_MULTIPLY := "multiply"

const SUPPORTED_OPERATIONS := [
	OPERATION_SET,
	OPERATION_ADD,
	OPERATION_SUBTRACT,
	OPERATION_MULTIPLY,
]


# ============================================================
# EFFECT DATA
# ============================================================

var path: String = ""
var operation: String = OPERATION_SET
var value = null


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	effect_path: String = "",
	effect_operation: String = OPERATION_SET,
	effect_value = null
):
	path = effect_path
	operation = effect_operation
	value = effect_value


# ============================================================
# OPERATION VALIDATION
# ============================================================

static func is_supported_operation(
	effect_operation: String
) -> bool:
	return effect_operation in SUPPORTED_OPERATIONS


static func get_supported_operations() -> Array[String]:
	return [
		OPERATION_SET,
		OPERATION_ADD,
		OPERATION_SUBTRACT,
		OPERATION_MULTIPLY,
	]


# ============================================================
# E6 VALIDATION
# ============================================================

func is_valid() -> bool:
	if path.strip_edges().is_empty():
		return false

	if not EventEffect.is_supported_operation(operation):
		return false

	# set may accept any declarative value.
	# Arithmetic operations require a numeric operand.
	if operation != OPERATION_SET:
		if typeof(value) not in [
			TYPE_INT,
			TYPE_FLOAT,
		]:
			return false

	return true
