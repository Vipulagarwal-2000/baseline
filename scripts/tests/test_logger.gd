class_name TestLogger
extends RefCounted


static var current: TestLogger = null

var report_path: String = ""
var file: FileAccess = null


static func start() -> TestLogger:

	if current != null:
		current.close()

	current = TestLogger.new()

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

	current.close()
	current = null


func _init():

	_start_new_report()


func _start_new_report() -> void:

	var directory = "res://test_results"

	DirAccess.make_dir_recursive_absolute(
		directory
	)

	var run_number = _get_next_run_number()

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

	var directory = DirAccess.open(
		"res://test_results"
	)

	if directory == null:
		return 1

	var highest_number = 0

	directory.list_dir_begin()

	var filename = directory.get_next()

	while filename != "":

		if not directory.current_is_dir():

			if filename.begins_with(
				"test_run_"
			) and filename.ends_with(
				".txt"
			):

				var number_text = filename.trim_prefix(
					"test_run_"
				).trim_suffix(
					".txt"
				)

				if number_text.is_valid_int():

					highest_number = max(
						highest_number,
						int(number_text)
					)

		filename = directory.get_next()

	directory.list_dir_end()

	return highest_number + 1


func _write_line(
	message: String
) -> void:

	print(
		message
	)

	if file != null:

		file.store_line(
			message
		)

		file.flush()


func close() -> void:

	if file != null:

		file.flush()
		file.close()

		file = null


func get_report_path() -> String:

	return report_path
