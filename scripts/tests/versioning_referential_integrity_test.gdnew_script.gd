class_name VersioningReferentialIntegrityTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("Versioning Referential Integrity — Phase 3.7")

	var registry: VersioningRegistry = VersioningRegistry.new()
	var inventory: DataInventory = DataInventory.new()
	var passed: bool = true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Versioning registry available for referential integrity: FAIL | "
			+ registry.get_load_error()
		)
		return false

	if not inventory.is_loaded():
		TestLogger.write_line(
			"Data inventory available for versioning referential integrity: FAIL | "
			+ inventory.get_load_error()
		)
		return false

	var missing_inventory: Array = (
		registry.get_missing_inventory_paths()
	)

	var inventory_coverage_ok: bool = (
		missing_inventory.is_empty()
	)

	TestLogger.write_line(
		"Every inventoried data path has version metadata: "
		+ (
			"PASS"
			if inventory_coverage_ok
			else "FAIL"
		)
	)

	if not inventory_coverage_ok:
		TestLogger.write_line(
			"  Missing versioning paths: "
			+ ", ".join(missing_inventory)
		)

	passed = passed and inventory_coverage_ok

	var extra_paths: Array = (
		registry.get_extra_versioning_paths()
	)

	var extra_paths_ok: bool = (
		extra_paths.is_empty()
	)

	TestLogger.write_line(
		"Every versioning path belongs to the inventory: "
		+ (
			"PASS"
			if extra_paths_ok
			else "FAIL"
		)
	)

	if not extra_paths_ok:
		TestLogger.write_line(
			"  Extra versioning paths: "
			+ ", ".join(extra_paths)
		)

	passed = passed and extra_paths_ok

	var inventory_mismatches: Array = (
		registry.get_inventory_mismatches()
	)

	var inventory_match_ok: bool = (
		inventory_mismatches.is_empty()
	)

	TestLogger.write_line(
		"Versioning domain / asset type agrees with inventory: "
		+ (
			"PASS"
			if inventory_match_ok
			else "FAIL"
		)
	)

	if not inventory_match_ok:
		TestLogger.write_line(
			"  Inventory mismatches: "
			+ ", ".join(inventory_mismatches)
		)

	passed = passed and inventory_match_ok

	var provenance_mismatches: Array = (
		registry.get_provenance_baseline_mismatches()
	)

	var provenance_match_ok: bool = (
		provenance_mismatches.is_empty()
	)

	TestLogger.write_line(
		"Versioning baseline reference agrees with provenance: "
		+ (
			"PASS"
			if provenance_match_ok
			else "FAIL"
		)
	)

	if not provenance_match_ok:
		TestLogger.write_line(
			"  Provenance baseline mismatches: "
			+ ", ".join(provenance_mismatches)
		)

	passed = passed and provenance_match_ok

	var records_invalid: Array = (
		registry.get_invalid_records()
	)

	var records_ok: bool = records_invalid.is_empty()

	TestLogger.write_line(
		"Versioning records remain internally valid: "
		+ (
			"PASS"
			if records_ok
			else "FAIL"
		)
	)

	if not records_ok:
		TestLogger.write_line(
			"  Invalid records: "
			+ ", ".join(records_invalid)
		)

	passed = passed and records_ok

	# Coverage is derived from the authoritative DataInventory rather
	# than from a historical hard-coded count. The missing/extra checks
	# above still enforce exact path coverage.
	var inventory_count: int = (
		inventory.get_entry_count()
	)

	var versioning_count: int = (
		registry.get_record_count()
	)

	var coverage_ok: bool = (
		versioning_count == inventory_count
		and missing_inventory.is_empty()
		and extra_paths.is_empty()
	)

	TestLogger.write_line(
		"Versioning coverage: "
		+ (
			"PASS"
			if coverage_ok
			else "FAIL"
		)
		+ " | records="
		+ str(versioning_count)
		+ " inventory="
		+ str(inventory_count)
		+ " missing="
		+ str(missing_inventory.size())
		+ " extra="
		+ str(extra_paths.size())
	)

	passed = passed and coverage_ok

	TestLogger.write_line(
		"Step 3.7 Versioning Referential Integrity test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
