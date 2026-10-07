class_name TestSuiteResult
extends RefCounted


# ============================================================
# TEST SUITE RESULT
# ============================================================

const STATUS_NOT_RUN := "NOT_RUN"
const STATUS_RUNNING := "RUNNING"
const STATUS_PASS := "PASS"
const STATUS_FAIL := "FAIL"
const STATUS_ERROR := "ERROR"

var suite_id: String = "world_simulator_active_suite"
var display_name: String = "World Simulator Active Test Suite"

var status: String = STATUS_NOT_RUN
var run_id: int = 0

var started_at_msec: int = 0
var finished_at_msec: int = 0
var duration_msec: int = 0

var runner_results: Array[TestRunResult] = []
var metadata: Dictionary = {}


func _init(
	p_run_id: int = 0
) -> void:

	run_id = p_run_id
	started_at_msec = Time.get_ticks_msec()
	status = STATUS_RUNNING


func add_runner_result(
	result: TestRunResult
) -> void:

	if result == null:
		status = STATUS_ERROR
		return

	runner_results.append(
		result
	)

	if result.status == TestRunResult.STATUS_ERROR:
		status = STATUS_ERROR
	elif result.status == TestRunResult.STATUS_FAIL:
		status = STATUS_FAIL


func set_metadata(
	key: String,
	value: Variant
) -> void:

	metadata[key] = value


func all_diagnostics() -> Array[TestDiagnostic]:

	var result: Array[TestDiagnostic] = []

	for runner_result in runner_results:

		if runner_result == null:
			continue

		for diagnostic in runner_result.diagnostics:

			if diagnostic != null:
				result.append(diagnostic)

	return result


func failed_diagnostics() -> Array[TestDiagnostic]:

	var result: Array[TestDiagnostic] = []

	for diagnostic in all_diagnostics():

		if diagnostic != null and diagnostic.is_failure():
			result.append(diagnostic)

	return result


func primary_diagnostic() -> TestDiagnostic:

	for diagnostic in failed_diagnostics():

		if diagnostic.is_error():
			return diagnostic

	var failures := failed_diagnostics()

	if not failures.is_empty():
		return failures[0]

	return null


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

	for result in runner_results:

		if result == null:
			status = STATUS_ERROR
			return

		if not result.passed():

			if result.status == TestRunResult.STATUS_ERROR:
				status = STATUS_ERROR
			else:
				status = STATUS_FAIL

			return

	status = STATUS_PASS


func passed() -> bool:

	return status == STATUS_PASS


func runner_count() -> int:

	return runner_results.size()


func failed_runner_count() -> int:

	var count := 0

	for result in runner_results:

		if result == null:
			count += 1
			continue

		if not result.passed():
			count += 1

	return count


func total_tests_run() -> int:

	var total := 0

	for result in runner_results:

		if result != null:
			total += result.tests_run

	return total


func total_tests_failed() -> int:

	var total := 0

	for result in runner_results:

		if result != null:
			total += result.tests_failed + result.tests_errored

	return total


func summary_line() -> String:

	return (
		"OVERALL: "
		+ status
		+ " | runners="
		+ str(runner_count())
		+ " | failed_runners="
		+ str(failed_runner_count())
		+ " | tests="
		+ str(total_tests_run())
		+ " | failures="
		+ str(total_tests_failed())
	)


func to_dictionary() -> Dictionary:

	var serialized_runners: Array[Dictionary] = []
	var serialized_diagnostics: Array[Dictionary] = []

	for result in runner_results:

		if result != null:
			serialized_runners.append(
				result.to_dictionary()
			)

	for diagnostic in all_diagnostics():

		if diagnostic != null:
			serialized_diagnostics.append(
				diagnostic.to_dictionary()
			)

	return {
		"suite_id": suite_id,
		"display_name": display_name,
		"status": status,
		"passed": passed(),
		"run_id": run_id,
		"started_at_msec": started_at_msec,
		"finished_at_msec": finished_at_msec,
		"duration_msec": duration_msec,
		"runner_count": runner_count(),
		"failed_runner_count": failed_runner_count(),
		"total_tests_run": total_tests_run(),
		"total_tests_failed": total_tests_failed(),
		"diagnostics": serialized_diagnostics,
		"runner_results": serialized_runners,
		"metadata": metadata.duplicate(true)
	}
