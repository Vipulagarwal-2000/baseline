class_name PolicyCatalogRuntimeActivationService
extends RefCounted


const EXPECTED_CATALOG_ID: String = "world_simulator_policy_catalog"


# ============================================================
# PHASE 4.7B — EXPLICIT CATALOG POLICY ACTIVATION GATEWAY
# ============================================================
# This service is a narrow adapter, not a second policy runtime.
# It only accepts definitions previously bound from the canonical policy
# catalog, then queues the request through GovernmentComponent. The existing
# GovernmentPolicyCostSystem remains responsible for affordability, charging,
# and activation; GovernmentPolicyEffectSystem remains responsible for effects.
# ============================================================

func request_policy_activation(
	entity: SimEntity,
	policy_id_value: String
) -> Dictionary:
	var policy_id: String = policy_id_value.strip_edges()
	var result: Dictionary = {
		"ok": false,
		"policy_id": policy_id,
		"catalog_id": "",
		"reason": ""
	}

	if entity == null:
		result["reason"] = "missing_entity"
		return result
	if policy_id.is_empty():
		result["reason"] = "missing_policy_id"
		return result

	var government: GovernmentComponent = entity.get_component("government") as GovernmentComponent
	if government == null:
		result["reason"] = "missing_government_component"
		return result

	var definition: Dictionary = government.get_policy_definition(policy_id)
	if definition.is_empty():
		result["reason"] = "policy_not_registered"
		return result

	var raw_metadata: Variant = definition.get("metadata", {})
	if typeof(raw_metadata) != TYPE_DICTIONARY:
		result["reason"] = "invalid_policy_metadata"
		return result
	var metadata: Dictionary = raw_metadata as Dictionary
	var raw_binding: Variant = metadata.get("catalog_binding", {})
	if typeof(raw_binding) != TYPE_DICTIONARY:
		result["reason"] = "policy_is_not_catalog_bound"
		return result
	var binding: Dictionary = raw_binding as Dictionary
	if binding.is_empty():
		result["reason"] = "policy_is_not_catalog_bound"
		return result

	var bound_catalog_id: String = str(binding.get("catalog_id", ""))
	var bound_policy_id: String = str(binding.get("policy_id", ""))
	var catalog_version: int = int(binding.get("catalog_version", 0))
	var definition_version: int = int(binding.get("definition_version", 0))
	if bound_catalog_id != EXPECTED_CATALOG_ID:
		result["reason"] = "unexpected_catalog_id"
		return result
	if bound_policy_id != policy_id:
		result["reason"] = "catalog_policy_identity_mismatch"
		return result
	if catalog_version < 3 or definition_version < 1:
		result["reason"] = "invalid_catalog_binding_version"
		return result

	# The wrapper queues an explicit request and does not mutate activation,
	# treasury, or effects itself.
	if not government.request_policy_activation(policy_id):
		result["reason"] = "activation_request_rejected"
		return result

	result["ok"] = true
	result["catalog_id"] = bound_catalog_id
	result["reason"] = "queued_for_existing_policy_cost_system"
	return result
