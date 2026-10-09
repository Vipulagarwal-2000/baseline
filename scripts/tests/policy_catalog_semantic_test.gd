class_name PolicyCatalogSemanticTest
extends RefCounted


static func _is_numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _has_all_keys(dictionary: Dictionary, keys: Array[String]) -> bool:
	for key in keys:
		if not dictionary.has(key):
			return false
	return true


static func run() -> bool:
	var catalog: PolicyCatalog = PolicyCatalog.new()
	var registry: CanonicalIdRegistry = CanonicalIdRegistry.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line("Policy catalog available for semantic validation: FAIL | " + catalog.get_load_error())
		return false
	if not registry.is_loaded():
		TestLogger.write_line("Canonical ID registry available for policy semantic validation: FAIL | " + registry.get_load_error())
		return false

	var domain_status: String = registry.get_domain_status("policy")
	if domain_status != "active":
		TestLogger.write_line("Policy canonical ID domain is active: FAIL | status=" + domain_status)
		passed = false
	else:
		TestLogger.write_line("Policy canonical ID domain is active: PASS")

	var catalog_ids: Array = catalog.get_policy_ids()
	var canonical_ids: Array = registry.get_domain_ids("policy")
	catalog_ids.sort()
	canonical_ids.sort()
	if catalog_ids != canonical_ids:
		TestLogger.write_line("Canonical policy IDs exactly match catalog IDs: FAIL | catalog=" + str(catalog_ids) + " registry=" + str(canonical_ids))
		passed = false
	else:
		TestLogger.write_line("Canonical policy IDs exactly match catalog IDs: PASS | count=" + str(catalog_ids.size()))

	var contract: Dictionary = catalog.get_semantic_contract()
	var activation_contract_ok: bool = str(contract.get("activation_semantics", "")) == "phase_4_6b_catalog_content_only; loading_never_registers_or_activates_a_policy"
	if not activation_contract_ok:
		TestLogger.write_line("Catalog loading is explicitly non-activating: FAIL")
		passed = false
	else:
		TestLogger.write_line("Catalog loading is explicitly non-activating: PASS")

	var runtime_boundary_ok: bool = str(contract.get("runtime_state_semantics", "")) == "GovernmentComponent_and_existing_policy_systems_remain_mutable_runtime_authority"
	if not runtime_boundary_ok:
		TestLogger.write_line("Existing policy runtime remains state authority: FAIL")
		passed = false
	else:
		TestLogger.write_line("Existing policy runtime remains state authority: PASS")

	var supported_effects: Dictionary = GovernmentPolicyEffectSystem.SUPPORTED_EFFECTS.duplicate(true)
	var effect_owner: Dictionary = {}
	var spending_effect_keys: Array[String] = [
		"government.spending.infrastructure_share",
		"government.spending.military_share",
		"government.spending.public_services_share",
		"government.spending.administration_share"
	]
	var spending_bundle_count: int = 0

	var runtime_target_owners: Dictionary = {}
	for policy_id_value in catalog_ids:
		var policy_id: String = str(policy_id_value)
		var definition: Dictionary = catalog.get_policy(policy_id)
		if not registry.matches_id_format("policy", policy_id) or not registry.has_id("policy", policy_id):
			TestLogger.write_line("Policy ID follows canonical identity rules: " + policy_id + ": FAIL")
			passed = false

		var runtime_target_key: String = str(definition.get("category", "")).strip_edges() + "::" + str(definition.get("target", "")).strip_edges()
		if runtime_target_key.begins_with("::") or runtime_target_key.ends_with("::"):
			TestLogger.write_line("Policy runtime target grouping key is non-empty: " + policy_id + ": FAIL")
			passed = false
		elif runtime_target_owners.has(runtime_target_key):
			TestLogger.write_line("Catalog policy targets are unique for activation replacement: " + runtime_target_key + ": FAIL")
			passed = false
		else:
			runtime_target_owners[runtime_target_key] = policy_id

		var enabled_value: Variant = definition.get("enabled", null)
		if typeof(enabled_value) != TYPE_BOOL or not bool(enabled_value):
			TestLogger.write_line("MVP policy content is enabled for later explicit binding: " + policy_id + ": FAIL")
			passed = false

		var cost_value: Variant = definition.get("cost", null)
		if typeof(cost_value) != TYPE_DICTIONARY:
			TestLogger.write_line("Policy cost follows current treasury-only runtime contract: " + policy_id + ": FAIL")
			passed = false
		else:
			var cost: Dictionary = cost_value as Dictionary
			for resource_id in cost.keys():
				var amount: Variant = cost[resource_id]
				if str(resource_id) != "treasury" or not _is_numeric(amount) or float(amount) < 0.0:
					TestLogger.write_line("Policy cost follows current treasury-only runtime contract: " + policy_id + " -> " + str(resource_id) + ": FAIL")
					passed = false

		var effects_value: Variant = definition.get("effects", null)
		if typeof(effects_value) != TYPE_DICTIONARY:
			TestLogger.write_line("Policy effects are a dictionary: " + policy_id + ": FAIL")
			passed = false
			continue
		var effects: Dictionary = effects_value as Dictionary
		for effect_key_value in effects.keys():
			var effect_key: String = str(effect_key_value)
			var effect_value: Variant = effects[effect_key_value]
			if not supported_effects.has(effect_key):
				TestLogger.write_line("Policy effect exists in existing runtime contract: " + policy_id + " -> " + effect_key + ": FAIL")
				passed = false
				continue
			if not _is_numeric(effect_value) or float(effect_value) < 0.0 or float(effect_value) > 1.0:
				TestLogger.write_line("Policy effect value is within runtime range 0..1: " + policy_id + " -> " + effect_key + ": FAIL")
				passed = false
			if effect_owner.has(effect_key):
				TestLogger.write_line("Each supported effect key has one catalog owner: " + effect_key + ": FAIL")
				passed = false
			else:
				effect_owner[effect_key] = policy_id

		var has_spending_effect: bool = false
		for spending_key in spending_effect_keys:
			if effects.has(spending_key):
				has_spending_effect = true
		if has_spending_effect:
			spending_bundle_count += 1
			if not _has_all_keys(effects, spending_effect_keys):
				TestLogger.write_line("Spending-share policy updates all four allocation categories atomically: " + policy_id + ": FAIL")
				passed = false
			else:
				var spending_total: float = 0.0
				for spending_key in spending_effect_keys:
					spending_total += float(effects[spending_key])
				if not is_equal_approx(spending_total, 1.0):
					TestLogger.write_line("Spending-share bundle sums to exactly 1.0: " + policy_id + " | total=" + str(spending_total) + ": FAIL")
					passed = false
				else:
					TestLogger.write_line("Spending-share bundle sums to exactly 1.0: " + policy_id + ": PASS")

	var declared_effect_keys: Array = effect_owner.keys()
	var supported_effect_keys: Array = supported_effects.keys()
	declared_effect_keys.sort()
	supported_effect_keys.sort()
	if declared_effect_keys != supported_effect_keys:
		TestLogger.write_line("Catalog content covers each currently supported effect exactly once: FAIL | declared=" + str(declared_effect_keys) + " runtime=" + str(supported_effect_keys))
		passed = false
	else:
		TestLogger.write_line("Catalog content covers each currently supported effect exactly once: PASS | count=" + str(declared_effect_keys.size()))

	if spending_bundle_count != 1:
		TestLogger.write_line("Exactly one atomic spending-share bundle is present: FAIL | count=" + str(spending_bundle_count))
		passed = false
	else:
		TestLogger.write_line("Exactly one atomic spending-share bundle is present: PASS")

	if passed:
		TestLogger.write_line("All policy catalog semantic checks: PASS")
	TestLogger.write_line("PolicyCatalogSemanticTest: " + ("PASS" if passed else "FAIL"))
	return passed
