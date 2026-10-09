class_name PolicyCatalogSemanticTest
extends RefCounted


static func run() -> bool:
	var catalog: PolicyCatalog = PolicyCatalog.new()
	var registry: CanonicalIdRegistry = CanonicalIdRegistry.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Policy catalog is available for semantic validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry is available for policy semantic validation: FAIL | "
			+ registry.get_load_error()
		)
		return false

	var domain_status: String = registry.get_domain_status("policy")
	var reserved_status_ok: bool = domain_status == "reserved_unmodeled"
	TestLogger.write_line(
		"Policy canonical domain remains reserved in Phase 4.6A: "
		+ ("PASS" if reserved_status_ok else "FAIL")
		+ " | status="
		+ domain_status
	)
	passed = passed and reserved_status_ok

	var canonical_ids: Array = registry.get_domain_ids("policy")
	var canonical_ids_empty: bool = canonical_ids.is_empty()
	TestLogger.write_line(
		"No canonical policy IDs are introduced by the foundation: "
		+ ("PASS" if canonical_ids_empty else "FAIL")
	)
	passed = passed and canonical_ids_empty

	var catalog_ids: Array = catalog.get_policy_ids()
	var content_absent: bool = (
		catalog_ids.is_empty()
		and catalog.get_policy_count() == 0
	)
	TestLogger.write_line(
		"No named policy content is introduced by Phase 4.6A: "
		+ ("PASS" if content_absent else "FAIL")
	)
	passed = passed and content_absent

	var activation_contract: String = str(
		catalog.get_semantic_contract().get(
			"activation_semantics",
			""
		)
	)
	var activation_boundary_ok: bool = (
		activation_contract
		== "phase_4_6a_catalog_foundation_only; loading_never_activates_a_policy"
	)
	TestLogger.write_line(
		"Catalog loading has no policy activation authority: "
		+ ("PASS" if activation_boundary_ok else "FAIL")
	)
	passed = passed and activation_boundary_ok

	var runtime_boundary: String = str(
		catalog.get_semantic_contract().get(
			"runtime_state_semantics",
			""
		)
	)
	var runtime_boundary_ok: bool = (
		runtime_boundary
		== "GovernmentComponent_and_existing_policy_systems_remain_mutable_runtime_authority"
	)
	TestLogger.write_line(
		"Existing policy runtime remains the state authority: "
		+ ("PASS" if runtime_boundary_ok else "FAIL")
	)
	passed = passed and runtime_boundary_ok

	TestLogger.write_line(
		"PolicyCatalogSemanticTest: "
		+ ("PASS" if passed else "FAIL")
	)
	return passed
