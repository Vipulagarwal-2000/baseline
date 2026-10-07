class_name CanonicalSchemaRegistryTest
extends RefCounted


static func run() -> bool:
	var registry := CanonicalSchemaRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical schema registry loads: FAIL | "
			+ registry.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Canonical schema registry loads: PASS"
	)

	if registry.get_version() <= 0:
		TestLogger.write_line(
			"Canonical schema registry version: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Canonical schema registry version: PASS"
		)

	if registry.get_schema_registry_id().strip_edges().is_empty():
		TestLogger.write_line(
			"Canonical schema registry identifier: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Canonical schema registry identifier: PASS"
		)

	var policy := registry.get_policy()

	for policy_field in [
		"stable_schema_identity",
		"identity_field_is_explicit",
		"runtime_state_is_not_definition_authority",
		"reserved_domains_may_define_identity_only",
		"field_semantic_type_is_required",
		"source_paths_are_descriptive_not_runtime_state"
	]:
		if not bool(
			policy.get(
				policy_field,
				false
			)
		):
			TestLogger.write_line(
				"Canonical schema policy: "
				+ policy_field
				+ ": FAIL"
			)
			passed = false
		else:
			TestLogger.write_line(
				"Canonical schema policy: "
				+ policy_field
				+ ": PASS"
			)

	var invalid_schema_entries := (
		registry.get_invalid_schema_entries()
	)

	if invalid_schema_entries.is_empty():
		TestLogger.write_line(
			"Canonical schema entry structure: PASS"
		)
	else:
		TestLogger.write_line(
			"Canonical schema entry structure: FAIL | "
			+ ", ".join(invalid_schema_entries)
		)
		passed = false

	var invalid_fields := (
		registry.get_invalid_field_definitions()
	)

	if invalid_fields.is_empty():
		TestLogger.write_line(
			"Canonical schema field definitions: PASS"
		)
	else:
		TestLogger.write_line(
			"Canonical schema field definitions: FAIL | "
			+ ", ".join(invalid_fields)
		)
		passed = false

	if registry.get_domain_ids().is_empty():
		TestLogger.write_line(
			"Canonical schema registry contains domains: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Canonical schema registry contains domains: PASS | count="
			+ str(registry.get_domain_ids().size())
		)

	var missing_sources := (
		registry.get_missing_source_paths()
	)

	if missing_sources.is_empty():
		TestLogger.write_line(
			"Canonical schema source paths exist: PASS"
		)
	else:
		TestLogger.write_line(
			"Canonical schema source paths exist: FAIL | "
			+ ", ".join(missing_sources)
		)
		passed = false

	for domain_id in registry.get_domain_ids():
		var definition := registry.get_domain_schema(domain_id)
		TestLogger.write_line(
			"Canonical schema domain: "
			+ domain_id
			+ ": "
			+ str(
				definition.get(
					"schema_status",
					""
				)
			)
		)

	TestLogger.write_line(
		"CanonicalSchemaRegistryTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
