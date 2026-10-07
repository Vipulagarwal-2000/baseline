class_name TestDiagnosticSummary
extends RefCounted


# ============================================================
# TEST DIAGNOSTIC SUMMARY
# ============================================================
#
# Produces the compact authoritative human/machine-facing verdict for a
# completed TestSuiteResult.
#
# PASS is intentionally short.
# FAIL/ERROR is intentionally targeted: only failed runners/tests and their
# structured diagnostics are shown. Individual PASS assertions are omitted.
#
# During runner migration, the summary explicitly reports the validation
# scope. It must never claim that the full suite passed when the structured
# result only represents migrated runners.
# ============================================================


static func build_dictionary(
	suite_result: TestSuiteResult
) -> Dictionary:

	if suite_result == null:
		return {
			"status": TestSuiteResult.STATUS_ERROR,
			"passed": false,
			"run_id": 0,
			"validation_scope": "unknown",
			"migration_complete": false,
			"message": "Test suite result is null.",
			"runner_summaries": [],
			"diagnostics": [],
			"failed_runner_count": 0,
			"total_tests_run": 0,
			"total_tests_failed": 0
		}

	var runner_summaries: Array[Dictionary] = []
	var diagnostics: Array[Dictionary] = []

	for runner_result in suite_result.runner_results:

		if runner_result == null:
			continue

		runner_summaries.append({
			"runner_id": runner_result.runner_id,
			"display_name": runner_result.display_name,
			"status": runner_result.status,
			"tests_run": runner_result.tests_run,
			"tests_failed": runner_result.tests_failed,
			"tests_errored": runner_result.tests_errored
		})

		for diagnostic in runner_result.diagnostics:

			if diagnostic == null:
				continue

			if diagnostic.is_failure():
				diagnostics.append(
					diagnostic.to_dictionary()
				)

	var validation_scope := str(
		suite_result.metadata.get(
			"validation_scope",
			"full_suite"
		)
	)

	var migration_complete := bool(
		suite_result.metadata.get(
			"migration_complete",
			true
		)
	)

	var scope_passed := (
		suite_result.status == TestSuiteResult.STATUS_PASS
	)

	var message := ""

	if scope_passed:

		if migration_complete:
			message = "All active validation passed."
		else:
			message = (
				"All migrated validation passed; "
				+ "full-suite diagnostic remains pending."
			)

	else:

		message = (
			"Validation failed in the current reported scope."
		)

	return {
		"status": (
			TestSuiteResult.STATUS_PASS
			if scope_passed
			else suite_result.status
		),
		"passed": scope_passed,
		"run_id": suite_result.run_id,
		"validation_scope": validation_scope,
		"migration_complete": migration_complete,
		"message": message,
		"runner_summaries": runner_summaries,
		"diagnostics": diagnostics,
		"failed_runner_count": suite_result.failed_runner_count(),
		"total_tests_run": suite_result.total_tests_run(),
		"total_tests_failed": suite_result.total_tests_failed()
	}


static func build_text(
	suite_result: TestSuiteResult
) -> String:

	var summary := build_dictionary(
		suite_result
	)

	var lines: Array[String] = []

	lines.append(
		"WORLD SIMULATOR DIAGNOSTIC SUMMARY"
	)
	lines.append(
		"====================================="
	)
	lines.append(
		"Test Run: " + str(summary.get("run_id", 0)).pad_zeros(3)
	)
	lines.append(
		"OVERALL: " + str(
			summary.get(
				"status",
				TestSuiteResult.STATUS_ERROR
			)
		)
	)
	lines.append(
		"====================================="
	)
	lines.append("")

	var passed := bool(
		summary.get(
			"passed",
			false
		)
	)

	var migration_complete := bool(
		summary.get(
			"migration_complete",
			false
		)
	)

	lines.append(
		"VALIDATION SCOPE: "
		+ str(
			summary.get(
				"validation_scope",
				"unknown"
			)
		)
	)

	lines.append(
		"RUNNER MIGRATION COMPLETE: "
		+ (
			"YES"
			if migration_complete
			else "NO"
		)
	)

	lines.append("")

	if passed:

		lines.append(
			"RUNNER STATUS"
		)
		lines.append(
			"-------------------------------------"
		)

		for runner_summary in summary.get(
			"runner_summaries",
			[]
		):

			lines.append(
				str(
					runner_summary.get(
						"display_name",
						"Runner"
					)
				)
				+ ": "
				+ str(
					runner_summary.get(
						"status",
						""
					)
				)
			)

		lines.append("")
		lines.append(
			"FAILED RUNNERS: "
			+ str(
				summary.get(
					"failed_runner_count",
					0
				)
			)
		)
		lines.append(
			"FAILED TESTS / ERRORS: "
			+ str(
				summary.get(
					"total_tests_failed",
					0
				)
			)
		)
		lines.append("")

		if migration_complete:

			lines.append(
				"DIAGNOSTIC: ALL ACTIVE VALIDATION PASSED"
			)

		else:

			lines.append(
				"DIAGNOSTIC: MIGRATED VALIDATION PASSED"
			)
			lines.append(
				"FULL SUITE DIAGNOSTIC: "
				+ "PENDING REMAINING RUNNER MIGRATION"
			)

		return "\n".join(lines)

	lines.append(
		"RUNNER STATUS"
	)
	lines.append(
		"-------------------------------------"
	)

	for runner_summary in summary.get(
		"runner_summaries",
		[]
	):

		if str(
			runner_summary.get(
				"status",
				""
			)
		) == TestRunResult.STATUS_PASS:

			continue

		lines.append(
			str(
				runner_summary.get(
					"display_name",
					"Runner"
				)
			)
			+ ": "
			+ str(
				runner_summary.get(
					"status",
					""
				)
			)
		)

	lines.append("")
	lines.append(
		"FAILURE DIAGNOSTICS"
	)
	lines.append(
		"-------------------------------------"
	)

	var diagnostics: Array = summary.get(
		"diagnostics",
		[]
	)

	if diagnostics.is_empty():

		lines.append(
			"No structured failure diagnostic was recorded."
		)
		lines.append(
			"Inspect the failed runner's result file for details."
		)

	else:

		var index := 1

		for diagnostic in diagnostics:

			lines.append(
				str(index)
				+ ". "
				+ str(
					diagnostic.get(
						"severity",
						"FAIL"
					)
				)
				+ " | "
				+ str(
					diagnostic.get(
						"code",
						"TEST_FAILED"
					)
				)
			)

			lines.append(
				"Runner: "
				+ str(
					diagnostic.get(
						"runner_name",
						""
					)
				)
			)

			lines.append(
				"Test: "
				+ str(
					diagnostic.get(
						"test_name",
						""
					)
				)
			)

			lines.append(
				"Source: "
				+ str(
					diagnostic.get(
						"source_file",
						"source not specified"
					)
				)
			)

			lines.append(
				"Diagnostic: "
				+ str(
					diagnostic.get(
						"message",
						""
					)
				)
			)

			var action := str(
				diagnostic.get(
					"action",
					""
				)
			)

			if not action.is_empty():

				lines.append(
					"Action: "
					+ action
				)

			lines.append("")

			index += 1

	lines.append(
		"FAILED RUNNERS: "
		+ str(
			summary.get(
				"failed_runner_count",
				0
			)
		)
	)

	lines.append(
		"FAILED TESTS / ERRORS: "
		+ str(
			summary.get(
				"total_tests_failed",
				0
			)
		)
	)

	lines.append("")

	lines.append(
		"DIAGNOSTIC: ACTIVE VALIDATION FAILED"
	)

	return "\n".join(lines)
