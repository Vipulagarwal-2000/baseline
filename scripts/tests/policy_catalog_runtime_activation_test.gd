class_name PolicyCatalogRuntimeActivationTest
extends RefCounted


# ============================================================
# PHASE 4.7B — CATALOG-BOUND POLICY EXECUTION INTEGRATION
# ============================================================
# Validates that a policy definition registered from the catalog can be
# explicitly requested, charged by the existing policy cost system, and
# applied by the existing policy effect system.
#
# Startup catalog binding must remain declarative: this test creates its
# own explicit request. It does not introduce a second activation, cost, or
# effects authority, and it does not implement duration expiry.
# ============================================================

const POLICY_ID: String = "revenue_mobilization"
const EXPECTED_COST: float = 25.0
const EXPECTED_TAX_REVENUE_RATE: float = 0.15


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section("PHASE 4.7B POLICY CATALOG RUNTIME ACTIVATION TEST")

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	var india: SimEntity = world.get_entity("india") as SimEntity
	if india == null:
		TestLogger.write_line("India entity available: FAIL")
		return false

	var government: GovernmentComponent = india.get_component("government") as GovernmentComponent
	var economy: EconomyComponent = india.get_component("economy") as EconomyComponent
	var cost_system: GovernmentPolicyCostSystem = simulation.get_system("government_policy_cost_system") as GovernmentPolicyCostSystem
	var effect_system: GovernmentPolicyEffectSystem = simulation.get_system("government_policy_effect_system") as GovernmentPolicyEffectSystem
	var activation_service: PolicyCatalogRuntimeActivationService = PolicyCatalogRuntimeActivationService.new()

	var dependencies_ok: bool = (
		government != null
		and economy != null
		and cost_system != null
		and effect_system != null
	)
	TestLogger.write_line("Government/economy/cost/effect dependencies available: " + ("PASS" if dependencies_ok else "FAIL"))
	if not dependencies_ok:
		return false

	var definition: Dictionary = government.get_policy_definition(POLICY_ID)
	if definition.is_empty():
		TestLogger.write_line("Catalog policy is registered on government: FAIL | missing=" + POLICY_ID)
		return false
	TestLogger.write_line("Catalog policy is registered on government: PASS")

	var definition_metadata: Dictionary = definition.get("metadata", {})
	var binding_metadata: Dictionary = definition_metadata.get("catalog_binding", {})
	var startup_activation_ok: bool = not government.is_policy_active(POLICY_ID)
	TestLogger.write_line("Startup binding left catalog policy inactive: " + ("PASS" if startup_activation_ok else "FAIL"))
	var provenance_ok: bool = (
		str(binding_metadata.get("catalog_id", "")) == "world_simulator_policy_catalog"
		and int(binding_metadata.get("definition_version", 0)) == 1
	)
	TestLogger.write_line("Runtime definition retains catalog binding provenance: " + ("PASS" if provenance_ok else "FAIL"))

	var original_component_states: Array[Dictionary] = []
	for raw_entity in world.entities.values():
		if raw_entity == null or not raw_entity is SimEntity:
			continue
		var entity: SimEntity = raw_entity as SimEntity
		var entity_government: GovernmentComponent = entity.get_component("government") as GovernmentComponent
		var entity_economy: EconomyComponent = entity.get_component("economy") as EconomyComponent
		if entity_government != null:
			original_component_states.append({
				"component": entity_government,
				"state": entity_government.state.duplicate(true)
			})
		if entity_economy != null:
			original_component_states.append({
				"component": entity_economy,
				"state": entity_economy.state.duplicate(true)
			})
		# Prevent the world-wide cost-system pass from consuming a pending
		# request left by an unrelated test. Full state is restored below.
		if entity_government != null:
			entity_government.set_state("pending_policy_activation", {})

	var all_passed: bool = provenance_ok and startup_activation_ok

	# The gateway must refuse otherwise-valid definitions not originating in
	# the catalog binder. This synthetic definition is removed by full-state
	# restoration at the end of the test.
	var non_catalog_policy_id: String = "policy_catalog_gateway_non_catalog_47b"
	var non_catalog_policy: GovernmentPolicyDefinition = GovernmentPolicyDefinition.new(
		non_catalog_policy_id,
		"test",
		"gateway_guard",
		0.1,
		{},
		12,
		{},
		{"implementation_capacity_enabled": true}
	)
	var synthetic_policy_registered: bool = government.define_policy(non_catalog_policy)
	var non_catalog_request: Dictionary = activation_service.request_policy_activation(india, non_catalog_policy_id)
	all_passed = _assert(
		synthetic_policy_registered and not bool(non_catalog_request.get("ok", false))
		and str(non_catalog_request.get("reason", "")) == "policy_is_not_catalog_bound",
		"Gateway rejects a valid runtime definition without catalog-binding provenance",
		all_passed
	)

	# Isolate this integration test from previous domain tests while retaining
	# the catalog-bound definition registered by startup.
	government.set_state("active_policies", {})
	government.set_state("pending_policy_activation", {})
	government.set_state("policy_cost_ledger", {})
	government.set_state("policy_cost_last_result", {})
	government.set_state("policy_effect_ledger", {})
	government.set_state("policy_effect_last_result", {})
	government.set_state("policy_effect_bindings", {})
	economy.set_state("treasury", 100.0)
	economy.set_state("tax_revenue_rate", 0.0)

	all_passed = _assert(
		government.get_active_policies().is_empty(),
		"Controlled activation fixture starts with no active policies",
		all_passed
	)

	var request_result: Dictionary = activation_service.request_policy_activation(india, POLICY_ID)
	var request_accepted: bool = bool(request_result.get("ok", false))
	all_passed = _assert(
		request_accepted and str(request_result.get("catalog_id", "")) == "world_simulator_policy_catalog",
		"Explicit activation gateway accepts a canonical catalog-bound policy",
		all_passed
	)
	all_passed = _assert(
		request_accepted
		and not government.is_policy_active(POLICY_ID)
		and is_equal_approx(float(economy.get_state("treasury", -1.0)), 100.0),
		"Activation gateway only queues the request; it does not charge or activate",
		all_passed
	)

	if request_accepted:
		cost_system.process_month(world)

	var treasury_after_activation: float = float(economy.get_state("treasury", -1.0))
	all_passed = _assert(
		government.is_policy_active(POLICY_ID)
		and is_equal_approx(treasury_after_activation, 100.0 - EXPECTED_COST),
		"Existing cost authority activates policy and charges treasury once",
		all_passed
	)

	effect_system.process_month(world)
	var applied_tax_revenue_rate: float = float(economy.get_state("tax_revenue_rate", -1.0))
	all_passed = _assert(
		is_equal_approx(applied_tax_revenue_rate, EXPECTED_TAX_REVENUE_RATE),
		"Existing effect authority applies the catalog policy effect",
		all_passed
	)

	var repeat_request_result: Dictionary = activation_service.request_policy_activation(india, POLICY_ID)
	var repeat_request_accepted: bool = bool(repeat_request_result.get("ok", false))
	if repeat_request_accepted:
		cost_system.process_month(world)
	var treasury_after_repeat: float = float(economy.get_state("treasury", -1.0))
	all_passed = _assert(
		repeat_request_accepted
		and is_equal_approx(treasury_after_repeat, treasury_after_activation),
		"Repeating an active catalog policy request is idempotent and free",
		all_passed
	)

	# Preserve every government's and economy's state because the existing
	# cost/effect systems iterate over the whole world.
	for component_snapshot in original_component_states:
		var component: Variant = component_snapshot.get("component", null)
		if component != null:
			component.state = (component_snapshot.get("state", {}) as Dictionary).duplicate(true)

	TestLogger.write_line("Phase 4.7B Policy Catalog Runtime Activation overall: " + ("PASS" if all_passed else "FAIL"))
	return all_passed


static func _assert(condition: bool, label: String, current: bool) -> bool:
	if condition:
		TestLogger.write_line(label + ": PASS")
		return current
	TestLogger.write_line(label + ": FAIL")
	return false
