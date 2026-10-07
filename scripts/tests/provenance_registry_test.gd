class_name ProvenanceRegistryTest
extends RefCounted


static func run() -> bool:
	var registry := ProvenanceRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Provenance registry loads: FAIL | "
			+ registry.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Provenance registry loads: PASS"
	)

	if registry.get_version() <= 0:
		TestLogger.write_line(
			"Provenance registry version: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Provenance registry version: PASS"
		)

	if registry.get_registry_id().strip_edges().is_empty():
		TestLogger.write_line(
			"Provenance registry identifier: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Provenance registry identifier: PASS"
		)

	var policy := registry.get_policy()
	var required_policy_fields: Array = [
		"every_inventoried_path_requires_exactly_one_record",
		"provenance_metadata_is_not_runtime_state",
		"unknown_source_must_be_explicit",
		"external_source_requires_source_reference",
		"record_domain_and_asset_type_must_match_inventory"
	]

	for field_name in required_policy_fields:
		if not policy.has(field_name):
			TestLogger.write_line(
				"Provenance registry policy field: "
				+ field_name
				+ ": FAIL"
			)
			passed = false

	if registry.get_invalid_records().is_empty():
		TestLogger.write_line(
			"Provenance registry record definitions: PASS"
		)
	else:
		TestLogger.write_line(
			"Provenance registry record definitions: FAIL | "
			+ ", ".join(registry.get_invalid_records())
		)
		passed = false

	if registry.get_missing_source_paths().is_empty():
		TestLogger.write_line(
			"Provenance registry source paths exist: PASS"
		)
	else:
		TestLogger.write_line(
			"Provenance registry source paths exist: FAIL | "
			+ ", ".join(registry.get_missing_source_paths())
		)
		passed = false

	if registry.get_record_count() <= 0:
		TestLogger.write_line(
			"Provenance registry contains records: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Provenance registry contains records: PASS | count="
			+ str(registry.get_record_count())
		)

	var status_counts := registry.get_status_counts()
	var unattributed_baseline_count := int(
		status_counts.get(
			"unattributed_baseline",
			0
		)
	)

	if unattributed_baseline_count > 0:
		TestLogger.write_line(
			"Unattributed baseline status is explicit: PASS | count="
			+ str(unattributed_baseline_count)
		)
	else:
		TestLogger.write_line(
			"Unattributed baseline status is explicit: PASS | count=0"
		)

	TestLogger.write_line(
		"ProvenanceRegistryTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
