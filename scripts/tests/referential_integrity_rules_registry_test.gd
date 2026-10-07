class_name ReferentialIntegrityRulesRegistryTest
extends RefCounted


static func run() -> bool:
	var registry := ReferentialIntegrityRulesRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Referential integrity rules registry loads: FAIL | "
			+ registry.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Referential integrity rules registry loads: PASS"
	)

	if registry.get_version() <= 0:
		TestLogger.write_line(
			"Referential integrity rules registry version: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Referential integrity rules registry version: PASS"
		)

	if registry.get_registry_id().strip_edges().is_empty():
		TestLogger.write_line(
			"Referential integrity rules registry identifier: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Referential integrity rules registry identifier: PASS"
		)

	var invalid_rules := registry.get_invalid_rules()

	if invalid_rules.is_empty():
		TestLogger.write_line(
			"Referential integrity rule definitions: PASS"
		)
	else:
		TestLogger.write_line(
			"Referential integrity rule definitions: FAIL | "
			+ ", ".join(invalid_rules)
		)
		passed = false

	var missing_sources := registry.get_missing_source_paths()

	if missing_sources.is_empty():
		TestLogger.write_line(
			"Referential integrity source paths exist: PASS"
		)
	else:
		TestLogger.write_line(
			"Referential integrity source paths exist: FAIL | "
			+ ", ".join(missing_sources)
		)
		passed = false

	if registry.get_rule_count() <= 0:
		TestLogger.write_line(
			"Referential integrity registry contains rules: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Referential integrity registry contains rules: PASS | count="
			+ str(registry.get_rule_count())
		)

	TestLogger.write_line(
		"ReferentialIntegrityRulesRegistryTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
