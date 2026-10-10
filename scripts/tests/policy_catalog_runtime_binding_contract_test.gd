class_name PolicyCatalogRuntimeBindingContractTest
extends RefCounted


static func run() -> bool:
	TestLogger.section("PHASE 4.7A — POLICY CATALOG RUNTIME-BINDING CONTRACT")
	var passed: bool = true
	var catalog: PolicyCatalog = PolicyCatalog.new()
	if not catalog.is_loaded():
		TestLogger.write_line("Policy catalog loads for runtime-binding contract: FAIL | " + catalog.get_load_error())
		return false

	var contract: Dictionary = catalog.get_semantic_contract()
	var version_ok: bool = catalog.get_catalog_version() >= PolicyCatalogRuntimeBinder.MINIMUM_CATALOG_VERSION
	TestLogger.write_line("Policy catalog version supports explicit runtime binding: " + ("PASS" if version_ok else "FAIL"))
	passed = passed and version_ok

	var identity_ok: bool = catalog.get_catalog_id() == PolicyCatalogRuntimeBinder.EXPECTED_CATALOG_ID
	TestLogger.write_line("Policy catalog ID matches the runtime binder: " + ("PASS" if identity_ok else "FAIL"))
	passed = passed and identity_ok

	var mapping_ok: bool = str(contract.get("runtime_mapping_semantics", "")) == PolicyCatalogRuntimeBinder.EXPECTED_MAPPING_SEMANTICS
	TestLogger.write_line("Catalog explicitly declares runtime ID mapping: " + ("PASS" if mapping_ok else "FAIL"))
	passed = passed and mapping_ok

	var activation_ok: bool = str(contract.get("activation_semantics", "")) == PolicyCatalogRuntimeBinder.EXPECTED_ACTIVATION_SEMANTICS
	TestLogger.write_line("Catalog declares binding without policy activation: " + ("PASS" if activation_ok else "FAIL"))
	passed = passed and activation_ok

	var binder_path_ok: bool = FileAccess.file_exists("res://scripts/core/policy_catalog_runtime_binder.gd")
	TestLogger.write_line("Dedicated policy runtime binder source exists: " + ("PASS" if binder_path_ok else "FAIL"))
	passed = passed and binder_path_ok

	var id_registry: CanonicalIdRegistry = CanonicalIdRegistry.new()
	var catalog_ids: Array = catalog.get_policy_ids()
	var canonical_ids: Array = id_registry.get_domain_ids("policy")
	catalog_ids.sort()
	canonical_ids.sort()
	var ids_match: bool = id_registry.is_loaded() and id_registry.get_domain_status("policy") == "active" and catalog_ids == canonical_ids
	TestLogger.write_line("Enabled/disabled catalog records retain canonical policy identities: " + ("PASS" if ids_match else "FAIL"))
	passed = passed and ids_match

	TestLogger.write_line("PolicyCatalogRuntimeBindingContractTest: " + ("PASS" if passed else "FAIL"))
	return passed
