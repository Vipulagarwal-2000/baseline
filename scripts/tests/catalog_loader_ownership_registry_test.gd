class_name CatalogLoaderOwnershipRegistryTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("Catalog/Loader Ownership Registry — Phase 3.8")

	var registry := CatalogLoaderOwnershipRegistry.new()
	var passed := true

	var loaded := registry.is_loaded()
	TestLogger.write_line(
		"Catalog/loader ownership registry loads: "
		+ ("PASS" if loaded else "FAIL")
	)
	passed = passed and loaded

	var version_ok := registry.get_version() == 1
	TestLogger.write_line(
		"Catalog/loader ownership registry version: "
		+ ("PASS" if version_ok else "FAIL")
	)
	passed = passed and version_ok

	var id_ok := registry.get_registry_id() == "world_simulator_catalog_loader_ownership"
	TestLogger.write_line(
		"Catalog/loader ownership registry identifier: "
		+ ("PASS" if id_ok else "FAIL")
	)
	passed = passed and id_ok

	var policy := registry.get_policy()
	var policy_ok :bool= (
		policy.get("every_canonical_domain_requires_exactly_one_record", false)
		and policy.get("domain_and_schema_status_must_agree", false)
		and policy.get("generic_data_manager_is_forbidden", false)
	)
	TestLogger.write_line(
		"Catalog/loader ownership policy metadata: "
		+ ("PASS" if policy_ok else "FAIL")
	)
	passed = passed and policy_ok

	var invalid_records := registry.get_invalid_records()
	var definitions_ok := invalid_records.is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership record definitions: "
		+ ("PASS" if definitions_ok else "FAIL")
	)
	if not definitions_ok:
		for error_text in invalid_records:
			TestLogger.write_line("  INVALID: " + str(error_text))
	passed = passed and definitions_ok

	var expected_count_ok := registry.get_record_count() == 17
	TestLogger.write_line(
		"Catalog/loader ownership registry contains records: "
		+ ("PASS" if expected_count_ok else "FAIL")
		+ " | count=" + str(registry.get_record_count())
	)
	passed = passed and expected_count_ok

	var canonical_domain_ok := registry.get_canonical_domain_mismatches().is_empty()
	TestLogger.write_line(
		"All canonical domains have exactly one ownership record: "
		+ ("PASS" if canonical_domain_ok else "FAIL")
	)
	passed = passed and canonical_domain_ok

	var schema_ok := registry.get_schema_mismatches().is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership agrees with canonical schemas: "
		+ ("PASS" if schema_ok else "FAIL")
	)
	passed = passed and schema_ok

	var ownership_ok := registry.get_ownership_status_mismatches().is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership agrees with domain ownership: "
		+ ("PASS" if ownership_ok else "FAIL")
	)
	passed = passed and ownership_ok

	TestLogger.write_line(
		"Catalog/loader ownership source paths exist: "
		+ ("PASS" if registry.get_missing_source_paths().is_empty() else "FAIL")
	)
	passed = passed and registry.get_missing_source_paths().is_empty()

	return passed
