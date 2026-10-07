class_name TestDiagnostic
extends RefCounted


# ============================================================
# TEST DIAGNOSTIC
# ============================================================
#
# Structured, authoritative diagnosis for one test/runner failure.
#
# This is deliberately separate from TestLogger:
#   TestLogger       -> execution text
#   TestDiagnostic  -> structured diagnostic authority
#
# The diagnostic layer should tell a maintainer:
#   - what failed;
#   - where the failing test lives;
#   - what category/severity the failure has;
#   - what should be inspected next.
#
# It must not invent the hidden root cause when the underlying test only
# exposes a boolean failure result.
# ============================================================


const SEVERITY_INFO := "INFO"
const SEVERITY_WARNING := "WARNING"
const SEVERITY_FAIL := "FAIL"
const SEVERITY_ERROR := "ERROR"

const CODE_TEST_FAILED := "TEST_FAILED"
const CODE_TEST_ERROR := "TEST_ERROR"
const CODE_RUNNER_FAILED := "RUNNER_FAILED"
const CODE_RUNNER_ERROR := "RUNNER_ERROR"
const CODE_SUITE_FAILED := "SUITE_FAILED"


var code: String = ""
var severity: String = SEVERITY_INFO

var runner_id: String = ""
var runner_name: String = ""

var test_name: String = ""
var source_file: String = ""

var message: String = ""
var action: String = ""

var metadata: Dictionary = {}


func _init(
	p_code: String = "",
	p_severity: String = SEVERITY_INFO,
	p_runner_id: String = "",
	p_runner_name: String = "",
	p_test_name: String = "",
	p_source_file: String = "",
	p_message: String = "",
	p_action: String = ""
) -> void:

	code = p_code
	severity = p_severity
	runner_id = p_runner_id
	runner_name = p_runner_name
	test_name = p_test_name
	source_file = p_source_file
	message = p_message
	action = p_action


func is_failure() -> bool:

	return (
		severity == SEVERITY_FAIL
		or severity == SEVERITY_ERROR
	)


func is_error() -> bool:

	return severity == SEVERITY_ERROR


func is_warning() -> bool:

	return severity == SEVERITY_WARNING


func set_metadata(
	key: String,
	value: Variant
) -> void:

	metadata[key] = value


func summary_line() -> String:

	var location := source_file

	if location.is_empty():
		location = "source not specified"

	return (
		severity
		+ " | "
		+ code
		+ " | "
		+ runner_name
		+ " | "
		+ test_name
		+ " | "
		+ location
	)


func to_dictionary() -> Dictionary:

	return {
		"code": code,
		"severity": severity,
		"runner_id": runner_id,
		"runner_name": runner_name,
		"test_name": test_name,
		"source_file": source_file,
		"message": message,
		"action": action,
		"metadata": metadata.duplicate(true)
	}
