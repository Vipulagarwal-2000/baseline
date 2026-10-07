class_name CatalogLoaderOwnershipReferentialIntegrityTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("Catalog/Loader Ownership Referential Integrity — Phase 3.8")

	var registry := CatalogLoaderOwnershipRegistry.new()
	var passed := true

	var canonical_ok := registry.get_canonical_domain_mismatches().is_empty()
	TestLogger.write_line(
		"Every canonical domain has catalog/loader ownership metadata: "
		+ ("PASS" if canonical_ok else "FAIL")
	)
	passed = passed and canonical_ok

	var schema_ok := registry.get_schema_mismatches().is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership source contracts agree with canonical schemas: "
		+ ("PASS" if schema_ok else "FAIL")
	)
	passed = passed and schema_ok

	var ownership_ok := registry.get_ownership_status_mismatches().is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership status agrees with domain ownership: "
		+ ("PASS" if ownership_ok else "FAIL")
	)
	passed = passed and ownership_ok

	var invalid_records := registry.get_invalid_records()
	var internal_ok := invalid_records.is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership records remain internally valid: "
		+ ("PASS" if internal_ok else "FAIL")
	)
	passed = passed and internal_ok

	var missing_paths := registry.get_missing_source_paths()
	var sources_ok := missing_paths.is_empty()
	TestLogger.write_line(
		"Catalog/loader ownership declared paths exist: "
		+ ("PASS" if sources_ok else "FAIL")
	)
	passed = passed and sources_ok

	var reserved_ok := true
	for record in registry.get_records():
		if typeof(record) != TYPE_DICTIONARY:
			reserved_ok = false
			continue
		if str(record.get("ownership_status", "")) != "reserved_unmodeled":
			continue
		if str(record.get("ownership_mode", "")) != "reserved_identity_only":
			reserved_ok = false
		if str(record.get("loader_mode", "")) != "reserved_identity_only":
			reserved_ok = false
		var reserved_source_paths = record.get("source_paths", [])
		if typeof(reserved_source_paths) != TYPE_ARRAY:
			reserved_ok = false
		elif not reserved_source_paths.is_empty():
			reserved_ok = false
		if not str(record.get("loader_path", "")).is_empty():
			reserved_ok = false

	TestLogger.write_line(
		"Reserved domains remain identity-only: "
		+ ("PASS" if reserved_ok else "FAIL")
	)
	passed = passed and reserved_ok

	var generic_manager_ok := true
	for record in registry.get_records():
		if typeof(record) != TYPE_DICTIONARY:
			generic_manager_ok = false
			continue
		var loader_contract := str(record.get("loader_contract", "")).to_lower()
		if loader_contract.contains("datamanager"):
			generic_manager_ok = false

	TestLogger.write_line(
		"No generic DataManager is used as catalog/loader authority: "
		+ ("PASS" if generic_manager_ok else "FAIL")
	)
	passed = passed and generic_manager_ok

	return passed
