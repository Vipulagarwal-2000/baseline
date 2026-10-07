class_name TestRunResult
extends RefCounted


# ============================================================
# TEST RUN RESULT
# ============================================================

const STATUS_NOT_RUN := "NOT_RUN"
const STATUS_RUNNING := "RUNNING"
const STATUS_PASS := "PASS"
const STATUS_FAIL := "FAIL"
const STATUS_ERROR := "ERROR"

var runner_id: String = ""
var display_name: String = ""

var status: String = STATUS_NOT_RUN

var tests_run: int = 0
var tests_passed: int = 0
var tests_failed: int = 0
var tests_errored: int = 0

var started_at_msec: int = 0
var finished_at_msec: int = 0
var duration_msec: int = 0

var messages: Array[String] = []
var diagnostics: Array[TestDiagnostic] = []

# Compact structured test verdicts. These are retained for in-memory
# diagnostics/UI use but are not serialized into the compact evidence
# package unless a future diagnostic consumer explicitly requests them.
var test_results: Array[Dictionary] = []

var metadata: Dictionary = {}


func _init(
	p_runner_id: String = "",
	p_display_name: String = ""
) -> void:

	runner_id = p_runner_id
	display_name = p_display_name
	started_at_msec = Time.get_ticks_msec()
	status = STATUS_RUNNING


func record_test(
	test_name: String,
	passed: bool,
	message: String = "",
	source_file: String = "",
	diagnostic_message: String = "",
	action: String = ""
) -> void:

	tests_run += 1

	if passed:
		tests_passed += 1
	else:
		tests_failed += 1
		status = STATUS_FAIL

	if not test_name.is_empty():
		test_results.append({
			"name": test_name,
			"status": (
				"PASS"
				if passed
				else "FAIL"
			)
		})

		messages.append(
			_test_line(
				test_name,
				"PASS" if passed else "FAIL"
			)
		)

	if not message.is_empty():
		messages.append(
			message
		)

	if not passed:

		var diagnostic_text := diagnostic_message

		if diagnostic_text.is_empty():
			diagnostic_text = "Test returned FAIL."

		var diagnostic_action := action

		if diagnostic_action.is_empty():
			diagnostic_action = "Inspect the referenced test source file."

		add_diagnostic(
			TestDiagnostic.new(
				TestDiagnostic.CODE_TEST_FAILED,
				TestDiagnostic.SEVERITY_FAIL,
				runner_id,
				display_name,
				test_name,
				source_file,
				diagnostic_text,
				diagnostic_action
			)
		)


func record_error(
	test_name: String,
	message: String,
	source_file: String = "",
	action: String = ""
) -> void:

	tests_run += 1
	tests_errored += 1
	status = STATUS_ERROR

	if not test_name.is_empty():
		test_results.append({
			"name": test_name,
			"status": "ERROR"
		})

		messages.append(
			_test_line(
				test_name,
				"ERROR"
			)
		)

	if not message.is_empty():
		messages.append(
			message
		)

	var diagnostic_action := action

	if diagnostic_action.is_empty():
		diagnostic_action = "Inspect the referenced test source file and runtime error."

	add_diagnostic(
		TestDiagnostic.new(
			TestDiagnostic.CODE_TEST_ERROR,
			TestDiagnostic.SEVERITY_ERROR,
			runner_id,
			display_name,
			test_name,
			source_file,
			message,
			diagnostic_action
		)
	)


func add_diagnostic(
	diagnostic: TestDiagnostic
) -> void:

	if diagnostic == null:
		return

	diagnostics.append(
		diagnostic
	)


func add_message(
	message: String
) -> void:

	if not message.is_empty():
		messages.append(
			message
		)


func add_messages(
	additional_messages: Array[String]
) -> void:

	for message in additional_messages:
		add_message(message)


func set_metadata(
	key: String,
	value: Variant
) -> void:

	metadata[key] = value


func finish() -> void:

	if finished_at_msec != 0:
		return

	finished_at_msec = Time.get_ticks_msec()
	duration_msec = max(
		0,
		finished_at_msec - started_at_msec
	)

	if status == STATUS_ERROR:
		return

	if tests_failed > 0:
		status = STATUS_FAIL
		return

	status = STATUS_PASS


func passed() -> bool:

	return status == STATUS_PASS


func has_failures() -> bool:

	return (
		tests_failed > 0
		or tests_errored > 0
		or status == STATUS_FAIL
		or status == STATUS_ERROR
	)


func failed_diagnostics() -> Array[TestDiagnostic]:

	var result: Array[TestDiagnostic] = []

	for diagnostic in diagnostics:

		if diagnostic != null and diagnostic.is_failure():
			result.append(diagnostic)

	return result


func primary_diagnostic() -> TestDiagnostic:

	for diagnostic in diagnostics:

		if diagnostic != null and diagnostic.is_error():
			return diagnostic

	for diagnostic in diagnostics:

		if diagnostic != null and diagnostic.is_failure():
			return diagnostic

	return null


func summary_line() -> String:

	return (
		display_name
		+ ": "
		+ status
		+ " | tests="
		+ str(tests_run)
		+ " | passed="
		+ str(tests_passed)
		+ " | failed="
		+ str(tests_failed)
		+ " | errors="
		+ str(tests_errored)
	)


func to_dictionary() -> Dictionary:

	var serialized_diagnostics: Array[Dictionary] = []

	for diagnostic in diagnostics:

		if diagnostic != null:
			serialized_diagnostics.append(
				diagnostic.to_dictionary()
			)

	return {
		"runner_id": runner_id,
		"display_name": display_name,
		"status": status,
		"passed": passed(),
		"tests_run": tests_run,
		"tests_passed": tests_passed,
		"tests_failed": tests_failed,
		"tests_errored": tests_errored,
		"started_at_msec": started_at_msec,
		"finished_at_msec": finished_at_msec,
		"duration_msec": duration_msec,
		"diagnostics": serialized_diagnostics,
		"metadata": metadata.duplicate(true)
	}


func compact_test_statuses() -> Array[Dictionary]:

	return test_results.duplicate(true)


func _test_line(
	test_name: String,
	result: String
) -> String:

	return (
		"  "
		+ test_name
		+ ": "
		+ result
	)
