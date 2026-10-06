class_name EventDefinitionTest
extends RefCounted


static func run() -> bool:

	var test_passed := true

	TestLogger.section(
		"EventDefinition"
	)

	# ============================================================
	# CREATE DEFINITION
	# ============================================================

	var definition := EventDefinition.new(
		"test_stability_event",
		"Test Stability Event",
		"Test event definition.",
		"political",
		"country"
	)

	# ============================================================
	# IDENTITY
	# ============================================================

	if definition.id != "test_stability_event":
		TestLogger.write_line(
			"FAIL: EventDefinition id"
		)
		test_passed = false

	if definition.name != "Test Stability Event":
		TestLogger.write_line(
			"FAIL: EventDefinition name"
		)
		test_passed = false

	if definition.description != "Test event definition.":
		TestLogger.write_line(
			"FAIL: EventDefinition description"
		)
		test_passed = false
		
		
		
	# DEFAULT VALUES
	var default_definition := EventDefinition.new(
		"default_test",
		"Default Test Event"
	)

	if default_definition.description != "":
		TestLogger.write_line(
			"FAIL: Default description"
		)
		test_passed = false

	if default_definition.category != "general":
		TestLogger.write_line(
			"FAIL: Default category"
		)
		test_passed = false

	if default_definition.scope != "country":
		TestLogger.write_line(
			"FAIL: Default scope"
		)
		test_passed = false

	if not default_definition.metadata.is_empty():
		TestLogger.write_line(
			"FAIL: Default metadata should be empty"
		)
		test_passed = false

	# ============================================================
	# CLASSIFICATION
	# ============================================================

	if definition.category != "political":
		TestLogger.write_line(
			"FAIL: EventDefinition category"
		)
		test_passed = false

	if definition.scope != "country":
		TestLogger.write_line(
			"FAIL: EventDefinition scope"
		)
		test_passed = false

	# ============================================================
	# METADATA
	# ============================================================

	definition.set_metadata_value(
		"test_key",
		"test_value"
	)

	if not definition.has_metadata_value(
		"test_key"
	):
		TestLogger.write_line(
			"FAIL: Metadata key was not created"
		)
		test_passed = false

	if definition.get_metadata_value(
		"test_key"
	) != "test_value":
		TestLogger.write_line(
			"FAIL: Metadata value"
		)
		test_passed = false

	# ============================================================
	# DEFAULT METADATA VALUE
	# ============================================================

	if definition.get_metadata_value(
		"missing_key",
		"default_value"
	) != "default_value":
		TestLogger.write_line(
			"FAIL: Metadata default value"
		)
		test_passed = false

	# ============================================================
	# REMOVE METADATA
	# ============================================================

	definition.remove_metadata_value(
		"test_key"
	)

	if definition.has_metadata_value(
		"test_key"
	):
		TestLogger.write_line(
			"FAIL: Metadata key was not removed"
		)
		test_passed = false
		
		
	# ============================================================
	# METADATA ISOLATION
	# ============================================================

	var second_definition := EventDefinition.new(
		"second_test",
		"Second Test Event"
	)

	definition.set_metadata_value(
		"shared_test_key",
		"first_value"
	)

	if second_definition.has_metadata_value(
		"shared_test_key"
	):
		TestLogger.write_line(
			"FAIL: Metadata leaked between definitions"
		)
		test_passed = false

	second_definition.set_metadata_value(
		"shared_test_key",
		"second_value"
	)

	if definition.get_metadata_value(
		"shared_test_key"
	) != "first_value":
		TestLogger.write_line(
			"FAIL: Definition metadata was modified by another definition"
		)
		test_passed = false
		
	# ============================================================
	# EMPTY IDENTITY VALUES
	# ============================================================

	var empty_definition := EventDefinition.new(
		"",
		""
	)

	if empty_definition.id != "":
		TestLogger.write_line(
			"FAIL: Empty id was changed unexpectedly"
		)
		test_passed = false

	if empty_definition.name != "":
		TestLogger.write_line(
			"FAIL: Empty name was changed unexpectedly"
		)
		test_passed = false

	# ============================================================
	# RESULT
	# ============================================================

	if test_passed:
		TestLogger.write_line(
			"EventDefinition test: PASS"
		)
	else:
		TestLogger.write_line(
			"EventDefinition test: FAIL"
		)

	return test_passed
