class_name TestLogger
extends RefCounted


# ============================================================
# TEST LOGGER
# ============================================================
#
# Backwards-compatible logger with two operating modes:
#
# 1. LEGACY MODE
#    TestLogger.start()
#    -> preserves the existing test_run_###.txt behaviour.
#
# 2. SCOPED MODE
#    TestLogger.start_scope(runner_id, display_name)
#    -> captures runner output in memory for the new runner/result
#       architecture. It does not create a legacy report file.
#
# Existing tests do not need to change yet.
# ============================================================


static var current: TestLogger = null


const MODE_LEGACY := "legacy"
const MODE_SCOPED := "scoped"


var mode: String = MODE_LEGACY

# Parent logger used when a scoped runner is embedded inside the master
# suite. The parent remains open and becomes current again when the child
# scope finishes.
var parent_logger: TestLogger = null

var report_path: String = ""
var file: FileAccess = null
var run_id: int = 0

var scope_id: String = ""
var scope_display_name: String = ""

var messages: Array[String] = []
var metadata: Dictionary = {}

var started_at_msec: int = 0
var finished_at_msec: int = 0
var duration_msec: int = 0


# ============================================================
# LEGACY API — PRESERVED
# ============================================================


static func start() -> TestLogger:

	if current != null:
		current.close()

	current = TestLogger.new(
		true
	)

	return current


static func write_line(
	message: Variant = ""
) -> void:

	if current == null:

		print(
			message
		)

		return

	current._write_line(
		str(message)
	)


static func section(
	title: String
) -> void:

	write_line("")
	write_line("================================")
	write_line(title)
	write_line("================================")


static func finish() -> void:

	if current == null:
		return

	var finished_logger := current
	var parent := finished_logger.parent_logger

	finished_logger.close()

	if (
		finished_logger.mode == MODE_SCOPED
		and parent != null
	):

		_forward_messages_to_parent(
			finished_logger
		)

		current = parent

	else:

		current = null


# ============================================================
# NEW SCOPED API
# ============================================================


static func start_scope(
	p_runner_id: String,
	p_display_name: String = ""
) -> TestLogger:

	var parent := current

	var scoped_logger := TestLogger.new(
		false
	)

	scoped_logger.mode = MODE_SCOPED
	scoped_logger.parent_logger = parent
	scoped_logger.scope_id = p_runner_id
	scoped_logger.scope_display_name = (
		p_display_name
		if not p_display_name.is_empty()
		else p_runner_id
	)
	scoped_logger.started_at_msec = Time.get_ticks_msec()

	current = scoped_logger

	return scoped_logger


static func finish_scope(
	result_status: String = ""
) -> TestRunResult:

	if current == null:
		return null

	var logger := current
	var parent := logger.parent_logger

	logger.close()

	var result := logger.build_result(
		result_status
	)

	if (
		logger.mode == MODE_SCOPED
		and parent != null
	):

		_forward_messages_to_parent(
			logger
		)

		current = parent

	else:

		current = null

	return result


static func has_active_scope() -> bool:

	return (
		current != null
		and current.mode == MODE_SCOPED
	)


static func current_scope_id() -> String:

	if not has_active_scope():
		return ""

	return current.scope_id


static func add_metadata(
	key: String,
	value: Variant
) -> void:

	if current == null:
		return

	current.metadata[key] = value


static func record_test(
	test_name: String,
	passed: bool,
	message: String = ""
) -> void:

	if current == null:
		return

	current._record_test(
		test_name,
		passed,
		message
	)


# ============================================================
# INITIALIZATION
# ============================================================


func _init(
	p_use_legacy_file_output: bool = true
):

	mode = (
		MODE_LEGACY
		if p_use_legacy_file_output
		else MODE_SCOPED
	)

	started_at_msec = Time.get_ticks_msec()

	if mode == MODE_LEGACY:
		_start_new_report()


# ============================================================
# MESSAGE / TEST CAPTURE
# ============================================================


func _write_line(
	message: String
) -> void:

	print(
		message
	)

	messages.append(
		message
	)

	if file != null:

		file.store_line(
			message
		)

		file.flush()


func _record_test(
	test_name: String,
	passed: bool,
	message: String = ""
) -> void:

	var status := (
		"PASS"
		if passed
		else "FAIL"
	)

	var result_line := (
		"  "
		+ test_name
		+ ": "
		+ status
	)

	_write_line(
		result_line
	)

	if not message.is_empty():

		_write_line(
			message
		)


func build_result(
	result_status: String = ""
) -> TestRunResult:

	var result := TestRunResult.new(
		scope_id,
		scope_display_name
	)

	for message in messages:

		result.add_message(
			message
		)

	result.set_metadata(
		"logger_mode",
		mode
	)

	result.set_metadata(
		"report_path",
		report_path
	)

	result.started_at_msec = started_at_msec
	result.finished_at_msec = finished_at_msec
	result.duration_msec = duration_msec

	if not result_status.is_empty():

		result.status = result_status

	return result


# ============================================================
# LEGACY REPORT OUTPUT
# ============================================================


func _start_new_report() -> void:

	var directory := "res://test_results"

	DirAccess.make_dir_recursive_absolute(
		directory
	)

	var run_number := _get_next_run_number()

	run_id = run_number

	report_path = (
		directory
		+ "/test_run_%03d.txt"
		% run_number
	)

	file = FileAccess.open(
		report_path,
		FileAccess.WRITE
	)

	if file == null:

		print(
			"TEST LOGGER ERROR: Could not create report: ",
			report_path
		)

		return

	file.store_line(
		"SIMULATOR TEST REPORT"
	)

	file.store_line(
		"================================"
	)

	file.store_line(
		"Test Run: %03d" % run_number
	)

	file.store_line(
		"================================"
	)

	file.store_line("")


func _get_next_run_number() -> int:

	var directory := DirAccess.open(
		"res://test_results"
	)

	if directory == null:
		return 1

	var highest_number := 0

	directory.list_dir_begin()

	var filename := directory.get_next()

	while filename != "":

		if not directory.current_is_dir():

			if (
				filename.begins_with(
					"test_run_"
				)
				and filename.ends_with(
					".txt"
				)
			):

				var number_text := (
					filename
					.trim_prefix(
						"test_run_"
					)
					.trim_suffix(
						".txt"
					)
				)

				if number_text.is_valid_int():

					highest_number = max(
						highest_number,
						int(number_text)
					)

		filename = directory.get_next()

	directory.list_dir_end()

	return highest_number + 1



static func _forward_messages_to_parent(
	logger: TestLogger
) -> void:

	if logger == null:
		return

	var parent := logger.parent_logger

	if parent == null:
		return

	for message in logger.messages:

		parent._capture_child_message(
			message
	)


func _capture_child_message(
	message: String
) -> void:

	messages.append(
		message
	)

	if file != null:

		file.store_line(
			message
		)

		file.flush()

# ============================================================
# LIFECYCLE
# ============================================================


func close() -> void:

	finished_at_msec = Time.get_ticks_msec()

	duration_msec = max(
		0,
		finished_at_msec - started_at_msec
	)

	if file != null:

		file.flush()
		file.close()

		file = null


func get_report_path() -> String:

	return report_path


func get_run_id() -> int:

	return run_id


func get_messages() -> Array[String]:

	return messages.duplicate()


func get_scope_id() -> String:

	return scope_id


func get_scope_display_name() -> String:

	return scope_display_name


func get_duration_msec() -> int:

	return duration_msec
