class_name PolicyCatalogSchemaTest
extends RefCounted


static func run() -> bool:
	var catalog: PolicyCatalog = PolicyCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Policy catalog loads: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	TestLogger.write_line("Policy catalog loads: PASS")

	var version_ok: bool = catalog.get_catalog_version() >= 1
	TestLogger.write_line(
		"Policy catalog version is positive: "
		+ ("PASS" if version_ok else "FAIL")
	)
	passed = passed and version_ok

	var catalog_id_ok: bool = (
		catalog.get_catalog_id() == "world_simulator_policy_catalog"
	)
	TestLogger.write_line(
		"Policy catalog identifier is canonical: "
		+ ("PASS" if catalog_id_ok else "FAIL")
	)
	passed = passed and catalog_id_ok

	var contract: Dictionary = catalog.get_semantic_contract()
	var required_contract_fields: Array[String] = [
		"identity_semantics",
		"definition_semantics",
		"runtime_mapping_semantics",
		"target_semantics",
		"cost_semantics",
		"duration_semantics",
		"effect_semantics",
		"activation_semantics",
		"runtime_state_semantics",
		"provenance_semantics",
		"definition_version_semantics"
	]

	for field_name in required_contract_fields:
		var field_value: Variant = contract.get(field_name, null)
		var field_ok: bool = (
			typeof(field_value) == TYPE_STRING
			and not str(field_value).strip_edges().is_empty()
		)
		if not field_ok:
			TestLogger.write_line(
				"Policy catalog semantic contract field is present: "
				+ field_name
				+ ": FAIL"
			)
			passed = false

	var ids: Array = catalog.get_policy_ids()
	var empty_foundation_ok: bool = (
		catalog.get_policy_count() == 0
		and ids.is_empty()
	)
	TestLogger.write_line(
		"Phase 4.6A policy definition map remains empty: "
		+ ("PASS" if empty_foundation_ok else "FAIL")
		+ " | count="
		+ str(catalog.get_policy_count())
	)
	passed = passed and empty_foundation_ok

	var contract_copy: Dictionary = catalog.get_semantic_contract()
	contract_copy["identity_semantics"] = "mutated_test_copy"
	var copy_isolated: bool = (
		str(catalog.get_semantic_contract().get("identity_semantics", ""))
		== "canonical_policy_id"
	)
	TestLogger.write_line(
		"Policy catalog semantic contract returns a deep copy: "
		+ ("PASS" if copy_isolated else "FAIL")
	)
	passed = passed and copy_isolated

	TestLogger.write_line(
		"PolicyCatalogSchemaTest: "
		+ ("PASS" if passed else "FAIL")
	)
	return passed
