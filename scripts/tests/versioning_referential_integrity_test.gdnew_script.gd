class_name VersioningReferentialIntegrityTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("Versioning Referential Integrity — Phase 3.7")

	var registry := VersioningRegistry.new()
	var passed := true

	var missing_inventory := registry.get_missing_inventory_paths()
	var inventory_coverage_ok := missing_inventory.is_empty()
	TestLogger.write_line(
		"Every inventoried data path has version metadata: "
		+ ("PASS" if inventory_coverage_ok else "FAIL")
	)
	passed = passed and inventory_coverage_ok

	var extra_paths := registry.get_extra_versioning_paths()
	var extra_paths_ok := extra_paths.is_empty()
	TestLogger.write_line(
		"Every versioning path belongs to the inventory: "
		+ ("PASS" if extra_paths_ok else "FAIL")
	)
	passed = passed and extra_paths_ok

	var inventory_mismatches := registry.get_inventory_mismatches()
	var inventory_match_ok := inventory_mismatches.is_empty()
	TestLogger.write_line(
		"Versioning domain / asset type agrees with inventory: "
		+ ("PASS" if inventory_match_ok else "FAIL")
	)
	passed = passed and inventory_match_ok

	var provenance_mismatches := registry.get_provenance_baseline_mismatches()
	var provenance_match_ok := provenance_mismatches.is_empty()
	TestLogger.write_line(
		"Versioning baseline reference agrees with provenance: "
		+ ("PASS" if provenance_match_ok else "FAIL")
	)
	passed = passed and provenance_match_ok

	var records_ok := registry.get_invalid_records().is_empty()
	TestLogger.write_line(
		"Versioning records remain internally valid: "
		+ ("PASS" if records_ok else "FAIL")
	)
	passed = passed and records_ok

	var coverage_ok := (
		registry.get_record_count() == 37
		and missing_inventory.is_empty()
		and extra_paths.is_empty()
	)
	TestLogger.write_line(
		"Versioning coverage: "
		+ ("PASS" if coverage_ok else "FAIL")
		+ " | records="
		+ str(registry.get_record_count())
		+ " missing="
		+ str(missing_inventory.size())
		+ " extra="
		+ str(extra_paths.size())
	)
	passed = passed and coverage_ok

	TestLogger.write_line(
		"Step 3.7 Versioning Referential Integrity test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
