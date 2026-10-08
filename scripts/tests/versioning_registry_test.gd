class_name VersioningRegistryTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("Versioning Registry — Phase 3.7")

	var registry := VersioningRegistry.new()
	var passed := true

	var loaded_ok := registry.is_loaded()
	TestLogger.write_line(
		"Versioning registry loads: "
		+ ("PASS" if loaded_ok else "FAIL")
	)
	passed = passed and loaded_ok

	var version_ok := registry.get_version() == 1
	TestLogger.write_line(
		"Versioning registry version: "
		+ ("PASS" if version_ok else "FAIL")
	)
	passed = passed and version_ok

	var id_ok := registry.get_registry_id() == "world_simulator_versioning_registry"
	TestLogger.write_line(
		"Versioning registry identifier: "
		+ ("PASS" if id_ok else "FAIL")
	)
	passed = passed and id_ok

	var policy := registry.get_policy()
	var required_policy_fields := [
		"every_inventoried_path_requires_exactly_one_record",
		"versioning_metadata_is_not_runtime_state",
		"baseline_assets_must_explicitly_mark_unversioned_history",
		"controlled_assets_require_semver_label",
		"schema_version_must_be_positive_integer",
		"previous_version_must_be_null_for_initial_control_record",
		"domain_and_asset_type_must_match_inventory",
		"duplicate_paths_are_invalid",
		"effective_date_must_be_iso_date",
		"compatibility_policy_must_be_explicit"
	]
	var policy_ok := true
	for field_name in required_policy_fields:
		if not policy.has(field_name):
			policy_ok = false
	TestLogger.write_line(
		"Versioning registry policy metadata: "
		+ ("PASS" if policy_ok else "FAIL")
	)
	passed = passed and policy_ok

	var records_ok := registry.get_invalid_records().is_empty()
	TestLogger.write_line(
		"Versioning registry record definitions: "
		+ ("PASS" if records_ok else "FAIL")
	)
	passed = passed and records_ok

	var source_paths_ok := registry.get_missing_source_paths().is_empty()
	TestLogger.write_line(
		"Versioning registry source paths exist: "
		+ ("PASS" if source_paths_ok else "FAIL")
	)
	passed = passed and source_paths_ok

	var record_count := registry.get_record_count()
	var count_ok := record_count == 39
	TestLogger.write_line(
		"Versioning registry contains records: "
		+ ("PASS" if count_ok else "FAIL")
		+ " | count="
		+ str(record_count)
	)
	passed = passed and count_ok

	var baseline_count := 0
	var controlled_count := 0
	for record in registry.get_records():
		var status := str(record.get("version_status", ""))
		if status == "baseline_unversioned":
			baseline_count += 1
		elif status == "controlled":
			controlled_count += 1

	var baseline_state_ok := baseline_count == 30
	TestLogger.write_line(
		"Explicit baseline version state is preserved: "
		+ ("PASS" if baseline_state_ok else "FAIL")
		+ " | baseline_unversioned="
		+ str(baseline_count)
	)
	passed = passed and baseline_state_ok

	var controlled_state_ok := controlled_count == 9
	TestLogger.write_line(
		"Controlled version state count: "
		+ ("PASS" if controlled_state_ok else "FAIL")
		+ " | controlled="
		+ str(controlled_count)
	)
	passed = passed and controlled_state_ok

	TestLogger.write_line(
		"Phase 3.7 Versioning Registry test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
