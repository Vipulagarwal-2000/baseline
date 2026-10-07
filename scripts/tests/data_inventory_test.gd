class_name DataInventoryTest
extends RefCounted


static func run() -> bool:
	var inventory := DataInventory.new()
	var passed := true

	if not inventory.is_loaded():
		TestLogger.write_line(
			"Data inventory loads: FAIL | "
			+ inventory.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Data inventory loads: PASS"
	)

	var metadata := inventory.get_metadata()

	var required_metadata_fields: Array = [
		"version",
		"inventory_id",
		"inventory_scope",
		"coverage",
		"entries",
		"expected_families"
	]

	for field_name in required_metadata_fields:

		if not metadata.has(field_name):
			TestLogger.write_line(
				"Data inventory metadata field missing: "
				+ field_name
				+ ": FAIL"
			)
			passed = false

	var invalid_entries := (
		inventory.get_invalid_entries()
	)

	if invalid_entries.is_empty():
		TestLogger.write_line(
			"Data inventory entry schema: PASS"
		)
	else:
		TestLogger.write_line(
			"Data inventory entry schema: FAIL | "
			+ ", ".join(invalid_entries)
		)
		passed = false

	var duplicate_paths := (
		inventory.get_duplicate_inventory_paths()
	)

	if duplicate_paths.is_empty():
		TestLogger.write_line(
			"Data inventory duplicate paths: PASS"
		)
	else:
		TestLogger.write_line(
			"Data inventory duplicate paths: FAIL | "
			+ ", ".join(duplicate_paths)
		)
		passed = false

	var missing_paths := (
		inventory.get_missing_inventory_paths()
	)

	if missing_paths.is_empty():
		TestLogger.write_line(
			"All inventoried data files exist: PASS"
		)
	else:
		TestLogger.write_line(
			"All inventoried data files exist: FAIL | "
			+ ", ".join(missing_paths)
		)
		passed = false

	var untracked_paths := (
		inventory.get_untracked_data_files()
	)

	if untracked_paths.is_empty():
		TestLogger.write_line(
			"All data-directory files are inventoried: PASS"
		)
	else:
		TestLogger.write_line(
			"All data-directory files are inventoried: FAIL | "
			+ ", ".join(untracked_paths)
		)
		passed = false

	var entry_count := inventory.get_entry_count()

	if entry_count <= 0:
		TestLogger.write_line(
			"Data inventory contains entries: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Data inventory contains entries: PASS | count="
			+ str(entry_count)
		)

	var coverage = metadata.get(
		"coverage",
		{}
	)

	if typeof(coverage) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Data inventory coverage metadata: FAIL"
		)
		passed = false
	else:
		var declared_count := int(
			coverage.get(
				"entry_count",
				-1
			)
		)

		if declared_count != entry_count:
			TestLogger.write_line(
				"Data inventory declared entry count matches: FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Data inventory declared entry count matches: PASS"
			)

	TestLogger.write_line(
		"DataInventoryTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
