class_name EventDefinitionLoaderTest
extends RefCounted


static func run() -> bool:

	var test_passed := true

	TestLogger.section(
		"EventDefinitionLoader"
	)

	# ============================================================
	# CREATE LOADER
	# ============================================================

	var loader := EventDefinitionLoader.new()

	# ============================================================
	# LOAD JSON
	# ============================================================

	var loaded := loader.load_from_file(
		"res://data/events/events.json"
	)

	if not loaded:
		TestLogger.write_line(
			"FAIL: Event definitions could not be loaded"
		)
		test_passed = false

	# ============================================================
	# DEFINITION COUNT
	# ============================================================

	if loader.get_definition_count() != 2:
		TestLogger.write_line(
			"FAIL: Expected 2 event definitions"
		)
		test_passed = false

	# ============================================================
	# FIRST DEFINITION
	# ============================================================

	var stability_event := loader.get_definition(
		"test_stability_event"
	)

	if stability_event == null:
		TestLogger.write_line(
			"FAIL: test_stability_event was not found"
		)
		test_passed = false
	else:

		if stability_event.name != "Test Stability Event":
			TestLogger.write_line(
				"FAIL: Stability event name"
			)
			test_passed = false

		if stability_event.category != "political":
			TestLogger.write_line(
				"FAIL: Stability event category"
			)
			test_passed = false

		if stability_event.scope != "country":
			TestLogger.write_line(
				"FAIL: Stability event scope"
			)
			test_passed = false

	# ============================================================
	# SECOND DEFINITION
	# ============================================================

	var resource_event := loader.get_definition(
		"test_resource_event"
	)

	if resource_event == null:
		TestLogger.write_line(
			"FAIL: test_resource_event was not found"
		)
		test_passed = false
	else:

		if resource_event.name != "Test Resource Event":
			TestLogger.write_line(
				"FAIL: Resource event name"
			)
			test_passed = false

		if resource_event.category != "resource":
			TestLogger.write_line(
				"FAIL: Resource event category"
			)
			test_passed = false

		if resource_event.get_metadata_value(
			"test"
		) != true:
			TestLogger.write_line(
				"FAIL: Resource event metadata"
			)
			test_passed = false

	# ============================================================
	# UNKNOWN ID
	# ============================================================

	var missing_event := loader.get_definition(
		"does_not_exist"
	)

	if missing_event != null:
		TestLogger.write_line(
			"FAIL: Unknown event ID should return null"
		)
		test_passed = false

	# ============================================================
	# EMPTY ID
	# ============================================================

	var empty_event := loader.get_definition(
		""
	)

	if empty_event != null:
		TestLogger.write_line(
			"FAIL: Empty event ID should return null"
		)
		test_passed = false

	# ============================================================
	# RESULT
	# ============================================================

	if test_passed:
		TestLogger.write_line(
			"EventDefinitionLoader test: PASS"
		)
	else:
		TestLogger.write_line(
			"EventDefinitionLoader test: FAIL"
		)

	return test_passed
