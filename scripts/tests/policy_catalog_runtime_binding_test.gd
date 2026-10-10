class_name PolicyCatalogRuntimeBindingTest
extends RefCounted


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section("PHASE 4.7A — POLICY CATALOG RUNTIME BINDING")
	var passed: bool = true
	if world == null or simulation == null:
		TestLogger.write_line("Live world and simulation are available: FAIL")
		return false

	var catalog: PolicyCatalog = PolicyCatalog.new()
	if not catalog.is_loaded():
		TestLogger.write_line("Policy catalog loads for runtime integration: FAIL | " + catalog.get_load_error())
		return false

	var live_government_count: int = 0
	var live_binding_ok: bool = true
	var live_side_effects_ok: bool = true
	for raw_entity in world.entities.values():
		if not raw_entity is SimEntity:
			continue
		var entity: SimEntity = raw_entity as SimEntity
		var raw_government: Variant = entity.get_component("government")
		if raw_government == null:
			continue
		if not raw_government is GovernmentComponent:
			live_binding_ok = false
			continue
		live_government_count += 1
		var government: GovernmentComponent = raw_government as GovernmentComponent
		for raw_policy_id in catalog.get_policy_ids():
			var policy_id: String = str(raw_policy_id)
			var catalog_definition: Dictionary = catalog.get_policy(policy_id)
			var enabled_value: Variant = catalog_definition.get("enabled", false)
			var runtime_definition: Dictionary = government.get_policy_definition(policy_id)
			if typeof(enabled_value) == TYPE_BOOL and bool(enabled_value):
				if runtime_definition.is_empty():
					live_binding_ok = false
				else:
					var runtime_metadata: Dictionary = runtime_definition.get("metadata", {})
					var binding_metadata: Dictionary = runtime_metadata.get("catalog_binding", {})
					if str(binding_metadata.get("policy_id", "")) != policy_id or str(binding_metadata.get("catalog_id", "")) != catalog.get_catalog_id():
						live_binding_ok = false
			else:
				if not runtime_definition.is_empty():
					live_binding_ok = false

		if not government.get_active_policies().is_empty():
			live_side_effects_ok = false
		if not government.get_pending_policy_activation().is_empty():
			live_side_effects_ok = false
		if not government.get_policy_cost_ledger().is_empty():
			live_side_effects_ok = false
		if not government.get_policy_effect_ledger().is_empty():
			live_side_effects_ok = false
		if not government.get_policy_effect_bindings().is_empty():
			live_side_effects_ok = false

	var live_world_ok: bool = live_government_count > 0 and live_binding_ok
	TestLogger.write_line("Every live government has all enabled catalog definitions: " + ("PASS" if live_world_ok else "FAIL"))
	passed = passed and live_world_ok
	TestLogger.write_line("Startup binding does not activate, charge, or apply effects: " + ("PASS" if live_side_effects_ok else "FAIL"))
	passed = passed and live_side_effects_ok

	var base_world_data: Dictionary = _new_test_world("policy_binding_idempotency")
	var base_world: WorldState = base_world_data["world"] as WorldState
	var base_government: GovernmentComponent = base_world_data["government"] as GovernmentComponent
	var binder: PolicyCatalogRuntimeBinder = PolicyCatalogRuntimeBinder.new()
	var first_result: Dictionary = binder.bind_world(base_world, catalog)
	var first_ok: bool = bool(first_result.get("ok", false)) and int(first_result.get("registered_count", -1)) == catalog.get_policy_count()
	TestLogger.write_line("Synthetic world registers every enabled definition: " + ("PASS" if first_ok else "FAIL | " + str(first_result.get("error", ""))))
	passed = passed and first_ok

	var revision_after_first: int = int(base_government.get_state("policy_definition_revision", 0))
	var second_result: Dictionary = binder.bind_world(base_world, catalog)
	var second_ok: bool = bool(second_result.get("ok", false)) and int(second_result.get("registered_count", -1)) == 0 and int(second_result.get("already_registered_count", -1)) == catalog.get_policy_count() and int(base_government.get_state("policy_definition_revision", 0)) == revision_after_first
	TestLogger.write_line("Repeated binding is idempotent and does not increment revisions: " + ("PASS" if second_ok else "FAIL"))
	passed = passed and second_ok
	var synthetic_no_activation: bool = base_government.get_active_policies().is_empty() and base_government.get_pending_policy_activation().is_empty() and base_government.get_policy_cost_ledger().is_empty() and base_government.get_policy_effect_ledger().is_empty()
	TestLogger.write_line("Synthetic binding leaves activation/cost/effect state unchanged: " + ("PASS" if synthetic_no_activation else "FAIL"))
	passed = passed and synthetic_no_activation

	var disabled_catalog: PolicyCatalog = _clone_catalog(catalog)
	var disabled_definition: Dictionary = disabled_catalog.get_policy("revenue_mobilization")
	disabled_definition["enabled"] = false
	disabled_catalog.policies["revenue_mobilization"] = disabled_definition
	var disabled_world_data: Dictionary = _new_test_world("policy_binding_disabled")
	var disabled_world: WorldState = disabled_world_data["world"] as WorldState
	var disabled_government: GovernmentComponent = disabled_world_data["government"] as GovernmentComponent
	var disabled_result: Dictionary = binder.bind_world(disabled_world, disabled_catalog)
	var disabled_ok: bool = bool(disabled_result.get("ok", false)) and int(disabled_result.get("registered_count", -1)) == catalog.get_policy_count() - 1 and not disabled_government.has_policy_definition("revenue_mobilization") and int(disabled_result.get("disabled_count", -1)) == 1
	TestLogger.write_line("Disabled catalog entries are validated but not registered: " + ("PASS" if disabled_ok else "FAIL | " + str(disabled_result.get("error", ""))))
	passed = passed and disabled_ok

	var incompatible_catalog: PolicyCatalog = _clone_catalog(catalog)
	incompatible_catalog.semantic_contract["activation_semantics"] = "phase_4_6b_catalog_content_only; loading_never_registers_or_activates_a_policy"
	var incompatible_world_data: Dictionary = _new_test_world("policy_binding_bad_contract")
	var incompatible_world: WorldState = incompatible_world_data["world"] as WorldState
	var incompatible_government: GovernmentComponent = incompatible_world_data["government"] as GovernmentComponent
	var incompatible_result: Dictionary = binder.bind_world(incompatible_world, incompatible_catalog)
	var incompatible_ok: bool = not bool(incompatible_result.get("ok", true)) and incompatible_government.get_policy_definitions().is_empty()
	TestLogger.write_line("Incompatible catalog contract is rejected before mutation: " + ("PASS" if incompatible_ok else "FAIL"))
	passed = passed and incompatible_ok

	var conflict_world: WorldState = WorldState.new(SimulationConfig.create_default())
	var conflict_first: GovernmentComponent = _add_test_country(conflict_world, "policy_binding_conflict_a")
	var conflict_second: GovernmentComponent = _add_test_country(conflict_world, "policy_binding_conflict_b")
	var conflicting_definition: GovernmentPolicyDefinition = GovernmentPolicyDefinition.new(
		"revenue_mobilization",
		"economic",
		"tax_rate",
		0.99,
		{"treasury": 25.0},
		12,
		{"economy.tax_revenue_rate": 0.99},
		{"implementation_capacity_enabled": true}
	)
	var conflict_seeded: bool = conflict_first.define_policy(conflicting_definition)
	var conflict_result: Dictionary = binder.bind_world(conflict_world, catalog)
	var conflict_ok: bool = conflict_seeded and not bool(conflict_result.get("ok", true)) and conflict_first.get_policy_definitions().size() == 1 and conflict_second.get_policy_definitions().is_empty()
	TestLogger.write_line("Definition conflicts reject the full batch without partial registration: " + ("PASS" if conflict_ok else "FAIL"))
	passed = passed and conflict_ok

	TestLogger.write_line("PolicyCatalogRuntimeBindingTest: " + ("PASS" if passed else "FAIL"))
	return passed


static func _clone_catalog(source: PolicyCatalog) -> PolicyCatalog:
	var clone: PolicyCatalog = PolicyCatalog.new()
	clone.catalog_id = source.get_catalog_id()
	clone.catalog_version = source.get_catalog_version()
	clone.semantic_contract = source.get_semantic_contract()
	clone.load_error = ""
	clone.policies = {}
	for raw_policy_id in source.get_policy_ids():
		var policy_id: String = str(raw_policy_id)
		clone.policies[policy_id] = source.get_policy(policy_id)
	return clone


static func _new_test_world(country_id: String) -> Dictionary:
	var world: WorldState = WorldState.new(SimulationConfig.create_default())
	var government: GovernmentComponent = _add_test_country(world, country_id)
	return {"world": world, "government": government}


static func _add_test_country(world: WorldState, country_id: String) -> GovernmentComponent:
	var entity: SimEntity = SimEntity.new(country_id, country_id, "country")
	var government: GovernmentComponent = GovernmentComponent.new(country_id)
	entity.add_component(government)
	entity.add_component(EconomyComponent.new(country_id))
	world.add_entity(entity)
	return government
