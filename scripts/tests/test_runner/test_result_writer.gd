class_name TestResultWriter
extends RefCounted


# ============================================================
# TEST RESULT WRITER
# ============================================================
#
# Persists one completed TestSuiteResult as a self-contained evidence
# package.
#
# The diagnostic summary is the authoritative compact human-facing verdict.
# Detailed runner files remain available as evidence.
# ============================================================


const RESULTS_ROOT := "res://test_results"
const LATEST_ROOT := RESULTS_ROOT + "/latest"
const ARCHIVE_ROOT := RESULTS_ROOT + "/archive"


static func write_suite_result(
	suite_result: TestSuiteResult
) -> Dictionary:

	if suite_result == null:
		return {
			"passed": false,
			"error": "suite_result is null"
		}

	var run_id: int = suite_result.run_id

	if run_id <= 0:
		run_id = _get_next_run_id()
		suite_result.run_id = run_id

	_prepare_directories()
	_clear_latest_directory()

	var archive_root := (
		ARCHIVE_ROOT
		+ "/run_%03d"
		% run_id
	)

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(archive_root)
	)

	var written_files: Array[String] = []

	var diagnostic_text := TestDiagnosticSummary.build_text(
		suite_result
	)

	var diagnostic_json := JSON.stringify(
		TestDiagnosticSummary.build_dictionary(
			suite_result
		),
		"\t"
	)

	var master_text := _build_master_result(
		suite_result
	)

	var diagnostic_archive_path := archive_root + "/diagnostic_summary.txt"
	var diagnostic_latest_path := LATEST_ROOT + "/diagnostic_summary.txt"

	if _write_text(diagnostic_archive_path, diagnostic_text):
		written_files.append(diagnostic_archive_path)

	if _write_text(diagnostic_latest_path, diagnostic_text):
		written_files.append(diagnostic_latest_path)

	var diagnostic_json_archive_path := archive_root + "/diagnostic_summary.json"
	var diagnostic_json_latest_path := LATEST_ROOT + "/diagnostic_summary.json"

	if _write_text(diagnostic_json_archive_path, diagnostic_json):
		written_files.append(diagnostic_json_archive_path)

	if _write_text(diagnostic_json_latest_path, diagnostic_json):
		written_files.append(diagnostic_json_latest_path)

	var master_archive_path := archive_root + "/master_result.txt"
	var master_latest_path := LATEST_ROOT + "/master_result.txt"

	if _write_text(master_archive_path, master_text):
		written_files.append(master_archive_path)

	if _write_text(master_latest_path, master_text):
		written_files.append(master_latest_path)

	var metadata_text := JSON.stringify(
		suite_result.to_dictionary(),
		"\t"
	)

	var metadata_archive_path := archive_root + "/run_metadata.json"
	var metadata_latest_path := LATEST_ROOT + "/run_metadata.json"

	if _write_text(metadata_archive_path, metadata_text):
		written_files.append(metadata_archive_path)

	if _write_text(metadata_latest_path, metadata_text):
		written_files.append(metadata_latest_path)

	for runner_result in suite_result.runner_results:

		if runner_result == null:
			continue

		var filename := (
			_sanitize_identifier(
				runner_result.runner_id
			)
			+ "_result.txt"
		)

		var runner_text := _build_runner_result(
			runner_result
		)

		var runner_archive_path := (
			archive_root
			+ "/"
			+ filename
		)

		var runner_latest_path := (
			LATEST_ROOT
			+ "/"
			+ filename
		)

		if _write_text(runner_archive_path, runner_text):
			written_files.append(runner_archive_path)

		if _write_text(runner_latest_path, runner_text):
			written_files.append(runner_latest_path)

	var expected_file_count: int = (
		2  # diagnostic txt + diagnostic json
		+ 2  # master txt
		+ 2  # run metadata json
		+ (suite_result.runner_count() * 2)  # per-runner archive/latest
	)

	var write_passed: bool = (
		written_files.size() == expected_file_count
	)

	return {
		"passed": write_passed,
		"run_id": run_id,
		"archive_path": archive_root,
		"latest_path": LATEST_ROOT,
		"files": written_files,
		"expected_file_count": expected_file_count
	}


static func _prepare_directories() -> void:

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(RESULTS_ROOT)
	)

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(LATEST_ROOT)
	)

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(ARCHIVE_ROOT)
	)


static func _clear_latest_directory() -> void:

	var directory := DirAccess.open(
		LATEST_ROOT
	)

	if directory == null:
		return

	directory.list_dir_begin()

	var filename := directory.get_next()

	while filename != "":

		if not directory.current_is_dir():

			var file_path := (
				LATEST_ROOT
				+ "/"
				+ filename
			)

			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(file_path)
			)

		filename = directory.get_next()

	directory.list_dir_end()


static func _get_next_run_id() -> int:

	_prepare_directories()

	var highest_number := 0

	var archive_directory := DirAccess.open(
		ARCHIVE_ROOT
	)

	if archive_directory != null:

		archive_directory.list_dir_begin()

		var filename := archive_directory.get_next()

		while filename != "":

			if archive_directory.current_is_dir():

				if filename.begins_with("run_"):

					var number_text := (
						filename
						.trim_prefix("run_")
					)

					if number_text.is_valid_int():
						highest_number = max(
							highest_number,
							int(number_text)
						)

			filename = archive_directory.get_next()

		archive_directory.list_dir_end()

	var legacy_directory := DirAccess.open(
		RESULTS_ROOT
	)

	if legacy_directory != null:

		legacy_directory.list_dir_begin()

		var legacy_filename := legacy_directory.get_next()

		while legacy_filename != "":

			if not legacy_directory.current_is_dir():

				if (
					legacy_filename.begins_with("test_run_")
					and legacy_filename.ends_with(".txt")
				):

					var legacy_number_text := (
						legacy_filename
						.trim_prefix("test_run_")
						.trim_suffix(".txt")
					)

					if legacy_number_text.is_valid_int():
						highest_number = max(
							highest_number,
							int(legacy_number_text)
						)

			legacy_filename = legacy_directory.get_next()

		legacy_directory.list_dir_end()

	return highest_number + 1


static func _build_master_result(
	suite_result: TestSuiteResult
) -> String:

	var lines: Array[String] = []

	lines.append(
		"WORLD SIMULATOR TEST REPORT"
	)
	lines.append(
		"================================"
	)
	lines.append(
		"Test Run: %03d" % suite_result.run_id
	)
	lines.append(
		"Overall: " + suite_result.status
	)

	var validation_scope := str(
		suite_result.metadata.get(
			"validation_scope",
			"full_suite"
		)
	)

	lines.append(
		"Validation Scope: " + validation_scope
	)

	var migration_complete := bool(
		suite_result.metadata.get(
			"migration_complete",
			true
		)
	)

	lines.append(
		"Runner Migration Complete: "
		+ ("YES" if migration_complete else "NO")
	)

	lines.append(
		"================================"
	)
	lines.append("")
	lines.append(
		"Diagnostic Summary: diagnostic_summary.txt"
	)
	lines.append(
		"Runner Count: "
		+ str(suite_result.runner_count())
	)
	lines.append(
		"Failed Runners: "
		+ str(suite_result.failed_runner_count())
	)
	lines.append(
		"Total Tests: "
		+ str(suite_result.total_tests_run())
	)
	lines.append(
		"Total Failures/Errors: "
		+ str(suite_result.total_tests_failed())
	)
	lines.append(
		"Duration (ms): "
		+ str(suite_result.duration_msec)
	)
	lines.append("")

	lines.append(
		"RUNNER RESULTS"
	)
	lines.append(
		"--------------------------------"
	)

	for runner_result in suite_result.runner_results:

		if runner_result == null:
			lines.append(
				"INVALID RUNNER RESULT: FAIL"
			)
			continue

		lines.append(
			runner_result.summary_line()
		)

	lines.append("")
	lines.append(
		suite_result.summary_line()
	)

	return "\n".join(lines)


static func _build_runner_result(
	runner_result: TestRunResult
) -> String:

	var lines: Array[String] = []

	lines.append(
		"WORLD SIMULATOR RUNNER SUMMARY"
	)
	lines.append(
		"================================"
	)
	lines.append(
		"Runner: " + runner_result.display_name
	)
	lines.append(
		"Runner ID: " + runner_result.runner_id
	)
	lines.append(
		"Status: " + runner_result.status
	)
	lines.append(
		"================================"
	)
	lines.append("")

	lines.append(
		"Tests Run: "
		+ str(runner_result.tests_run)
	)
	lines.append(
		"Tests Passed: "
		+ str(runner_result.tests_passed)
	)
	lines.append(
		"Tests Failed: "
		+ str(runner_result.tests_failed)
	)
	lines.append(
		"Tests Errored: "
		+ str(runner_result.tests_errored)
	)
	lines.append(
		"Diagnostics: "
		+ str(runner_result.diagnostics.size())
	)
	lines.append(
		"Duration (ms): "
		+ str(runner_result.duration_msec)
	)

	if runner_result.passed():

		lines.append("")
		lines.append(
			"RESULT: PASS"
		)
		lines.append(
			"No failure diagnostics recorded."
		)

		return "\n".join(lines)

	lines.append("")
	lines.append(
		"FAILURE DIAGNOSTICS"
	)
	lines.append(
		"--------------------------------"
	)

	var failure_diagnostics := (
		runner_result.failed_diagnostics()
	)

	if failure_diagnostics.is_empty():

		lines.append(
			"No structured failure diagnostics recorded."
		)

	else:

		var index := 1

		for diagnostic in failure_diagnostics:

			if diagnostic == null:
				continue

			lines.append(
				str(index)
				+ ". "
				+ diagnostic.summary_line()
			)

			lines.append(
				"   Message: "
				+ diagnostic.message
			)

			if not diagnostic.action.is_empty():

				lines.append(
					"   Action: "
					+ diagnostic.action
				)

			index += 1

	lines.append("")
	lines.append(
		"RESULT: FAIL"
	)

	return "\n".join(lines)


static func _write_text(
	path: String,
	content: String
) -> bool:

	var file := FileAccess.open(
		path,
		FileAccess.WRITE
	)

	if file == null:
		return false

	file.store_string(
		content
	)

	file.flush()
	file.close()

	return true


static func _sanitize_identifier(
	value: String
) -> String:

	var output := ""

	for character in value:

		if (
			character >= "a"
			and character <= "z"
		) or (
			character >= "A"
			and character <= "Z"
		) or (
			character >= "0"
			and character <= "9"
		) or character == "_":

			output += character
		else:
			output += "_"

	if output.is_empty():
		return "runner"

	return output
