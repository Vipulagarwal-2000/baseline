class_name ProvenanceReferentialIntegrityTest
extends RefCounted


static func run() -> bool:
	var registry := ProvenanceRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Provenance registry available for inventory cross-check: FAIL"
		)
		return false

	TestLogger.write_line(
		"Provenance registry available for inventory cross-check: PASS"
	)

	var missing_inventory_paths := registry.get_missing_inventory_paths()

	if missing_inventory_paths.is_empty():
		TestLogger.write_line(
			"Every inventoried data path has provenance: PASS"
		)
	else:
		TestLogger.write_line(
			"Every inventoried data path has provenance: FAIL | "
			+ ", ".join(missing_inventory_paths)
		)
		passed = false

	var extra_provenance_paths := registry.get_extra_provenance_paths()

	if extra_provenance_paths.is_empty():
		TestLogger.write_line(
			"Every provenance path belongs to the inventory: PASS"
		)
	else:
		TestLogger.write_line(
			"Every provenance path belongs to the inventory: FAIL | "
			+ ", ".join(extra_provenance_paths)
		)
		passed = false

	var metadata_mismatches := registry.get_inventory_metadata_mismatches()

	if metadata_mismatches.is_empty():
		TestLogger.write_line(
			"Provenance domain / asset type agrees with inventory: PASS"
		)
	else:
		TestLogger.write_line(
			"Provenance domain / asset type agrees with inventory: FAIL | "
			+ ", ".join(metadata_mismatches)
		)
		passed = false

	var invalid_records := registry.get_invalid_records()

	if invalid_records.is_empty():
		TestLogger.write_line(
			"Provenance records remain internally valid: PASS"
		)
	else:
		TestLogger.write_line(
			"Provenance records remain internally valid: FAIL | "
			+ ", ".join(invalid_records)
		)
		passed = false

	var record_count := registry.get_record_count()
	var missing_count := missing_inventory_paths.size()
	var extra_count := extra_provenance_paths.size()

	TestLogger.write_line(
		"Provenance coverage: "
		+ (
			"PASS"
			if (
				passed
				and missing_count == 0
				and extra_count == 0
			)
			else "FAIL"
		)
		+ " | records="
		+ str(record_count)
		+ " missing="
		+ str(missing_count)
		+ " extra="
		+ str(extra_count)
	)

	TestLogger.write_line(
		"ProvenanceReferentialIntegrityTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
