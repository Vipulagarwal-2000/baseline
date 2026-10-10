class_name PolicyCatalogRuntimeActivationContractTest
extends RefCounted


# ============================================================
# PHASE 4.7B — ACTIVATION BOUNDARY CONTRACT TEST
# ============================================================
# Ensures catalog loading and runtime binding remain separate from explicit
# policy activation. Runtime activation must continue to use the existing
# GovernmentComponent, GovernmentPolicyCostSystem, and
# GovernmentPolicyEffectSystem authorities.
# ============================================================

static func run() -> bool:
	TestLogger.section("PHASE 4.7B POLICY CATALOG ACTIVATION CONTRACT TEST")
	var all_passed: bool = true
	var catalog: PolicyCatalog = PolicyCatalog.new()

	all_passed = _assert(catalog.is_loaded(), "Policy catalog loads", all_passed)
	if not catalog.is_loaded():
		TestLogger.write_line("Catalog error: " + catalog.get_load_error())
		return false

	all_passed = _assert(
		catalog.get_catalog_id() == "world_simulator_policy_catalog",
		"Canonical catalog identity is preserved",
		all_passed
	)
	all_passed = _assert(
		catalog.get_catalog_version() >= 3,
		"Catalog version declares the runtime-binding contract",
		all_passed
	)

	var contract: Dictionary = catalog.get_semantic_contract()
	all_passed = _assert(
		str(contract.get("runtime_mapping_semantics", "")) == "catalog_id_maps_to_GovernmentPolicyDefinition.policy_id_during_explicit_PolicyCatalogRuntimeBinder_binding",
		"Catalog mapping names the explicit runtime binder boundary",
		all_passed
	)
	all_passed = _assert(
		str(contract.get("activation_semantics", "")) == "phase_4_7a_explicit_runtime_binding; enabled_definitions_are_registered_but_never_activated",
		"Catalog binding contract explicitly forbids automatic activation",
		all_passed
	)
	all_passed = _assert(
		str(contract.get("runtime_state_semantics", "")) == "GovernmentComponent_and_existing_policy_systems_remain_mutable_runtime_authority",
		"Existing government policy systems retain runtime-state authority",
		all_passed
	)

	var required_ids: Array[String] = [
		"revenue_mobilization",
		"investment_stimulation",
		"infrastructure_priority"
	]
	for policy_id in required_ids:
		var definition: Dictionary = catalog.get_policy(policy_id)
		all_passed = _assert(
			not definition.is_empty() and str(definition.get("id", "")) == policy_id,
			"Catalog contains canonical policy definition: " + policy_id,
			all_passed
		)
		if not definition.is_empty():
			all_passed = _assert(
				typeof(definition.get("enabled", null)) == TYPE_BOOL,
				"Catalog enabled flag is explicit: " + policy_id,
				all_passed
			)

	TestLogger.write_line("Phase 4.7B Policy Catalog Activation Contract overall: " + ("PASS" if all_passed else "FAIL"))
	return all_passed


static func _assert(condition: bool, label: String, current: bool) -> bool:
	if condition:
		TestLogger.write_line(label + ": PASS")
		return current
	TestLogger.write_line(label + ": FAIL")
	return false
