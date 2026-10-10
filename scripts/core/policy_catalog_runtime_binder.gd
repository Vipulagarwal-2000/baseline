class_name PolicyCatalogRuntimeBinder
extends RefCounted


const EXPECTED_CATALOG_ID: String = "world_simulator_policy_catalog"
const MINIMUM_CATALOG_VERSION: int = 3
const EXPECTED_MAPPING_SEMANTICS: String = "catalog_id_maps_to_GovernmentPolicyDefinition.policy_id_during_explicit_PolicyCatalogRuntimeBinder_binding"
const EXPECTED_ACTIVATION_SEMANTICS: String = "phase_4_7a_explicit_runtime_binding; enabled_definitions_are_registered_but_never_activated"
const EXPECTED_RUNTIME_STATE_SEMANTICS: String = "GovernmentComponent_and_existing_policy_systems_remain_mutable_runtime_authority"
const TREASURY_RESOURCE: String = "treasury"

const SPENDING_EFFECT_KEYS: Array[String] = [
	"government.spending.infrastructure_share",
	"government.spending.military_share",
	"government.spending.public_services_share",
	"government.spending.administration_share"
]


func bind_world(
	world: WorldState,
	catalog_override: PolicyCatalog = null
) -> Dictionary:
	var result: Dictionary = {
		"ok": false,
		"catalog_id": "",
		"catalog_version": 0,
		"governments_processed": 0,
		"registered_count": 0,
		"already_registered_count": 0,
		"disabled_count": 0,
		"policy_ids": [],
		"error": ""
	}

	if world == null:
		result["error"] = "Policy runtime binding requires a WorldState."
		return result

	var catalog: PolicyCatalog = catalog_override
	if catalog == null:
		catalog = PolicyCatalog.new()

	if not catalog.is_loaded():
		result["error"] = "Policy catalog failed to load: " + catalog.get_load_error()
		return result

	result["catalog_id"] = catalog.get_catalog_id()
	result["catalog_version"] = catalog.get_catalog_version()

	if catalog.get_catalog_id() != EXPECTED_CATALOG_ID:
		result["error"] = "Unexpected policy catalog ID: " + catalog.get_catalog_id()
		return result

	if catalog.get_catalog_version() < MINIMUM_CATALOG_VERSION:
		result["error"] = "Policy catalog version 3 or newer is required for runtime binding."
		return result

	var contract: Dictionary = catalog.get_semantic_contract()
	if str(contract.get("runtime_mapping_semantics", "")) != EXPECTED_MAPPING_SEMANTICS:
		result["error"] = "Policy catalog runtime-mapping contract is missing or incompatible."
		return result
	if str(contract.get("activation_semantics", "")) != EXPECTED_ACTIVATION_SEMANTICS:
		result["error"] = "Policy catalog activation contract is missing or incompatible."
		return result
	if str(contract.get("runtime_state_semantics", "")) != EXPECTED_RUNTIME_STATE_SEMANTICS:
		result["error"] = "Policy catalog runtime-state ownership contract is incompatible."
		return result

	var definition_plan: Dictionary = _build_definition_plan(catalog)
	if not bool(definition_plan.get("ok", false)):
		result["error"] = str(definition_plan.get("error", "Policy definition validation failed."))
		return result

	var runtime_definitions: Dictionary = definition_plan.get("definitions", {})
	var policy_ids: Array = runtime_definitions.keys()
	policy_ids.sort()
	result["disabled_count"] = int(definition_plan.get("disabled_count", 0))
	result["policy_ids"] = policy_ids.duplicate()

	var governments: Array[GovernmentComponent] = []
	var seen_governments: Dictionary = {}
	for raw_entity in world.entities.values():
		if not raw_entity is SimEntity:
			result["error"] = "WorldState contains an entity with an unexpected runtime type."
			return result

		var entity: SimEntity = raw_entity as SimEntity
		var raw_government: Variant = entity.get_component("government")
		if raw_government == null:
			continue
		if not raw_government is GovernmentComponent:
			result["error"] = "Entity " + entity.id + " has an invalid government component."
			return result

		var government: GovernmentComponent = raw_government as GovernmentComponent
		var unique_key: int = government.get_instance_id()
		if seen_governments.has(unique_key):
			continue
		seen_governments[unique_key] = true
		governments.append(government)

	if governments.is_empty():
		result["error"] = "No government components were found; no policies were bound."
		return result

	# Preflight the entire world before changing any component. Existing IDs
	# are accepted only when their runtime payload exactly matches the catalog.
	var missing_by_government: Array[Dictionary] = []
	var already_registered_count: int = 0
	for government in governments:
		var missing_for_government: Dictionary = {}
		for policy_id_value in policy_ids:
			var policy_id: String = str(policy_id_value)
			var desired: Dictionary = runtime_definitions[policy_id]
			var existing: Dictionary = government.get_policy_definition(policy_id)
			if existing.is_empty():
				missing_for_government[policy_id] = desired
				continue
			if existing != desired:
				result["error"] = "Conflicting runtime definition already exists for policy ID: " + policy_id
				return result
			already_registered_count += 1
		missing_by_government.append(missing_for_government)

	# A single commit pass runs only after all governments have passed preflight.
	# The full state copies are a defensive rollback for an unexpected API failure.
	var snapshots: Array[Dictionary] = []
	for government in governments:
		snapshots.append({
			"government": government,
			"state": government.state.duplicate(true)
		})

	var registered_count: int = 0
	for government_index in range(governments.size()):
		var government: GovernmentComponent = governments[government_index]
		var missing_for_government: Dictionary = missing_by_government[government_index]
		var missing_ids: Array = missing_for_government.keys()
		missing_ids.sort()
		for policy_id_value in missing_ids:
			var policy_id: String = str(policy_id_value)
			var policy_data: Dictionary = missing_for_government[policy_id]
			var policy: GovernmentPolicyDefinition = GovernmentPolicyDefinition.from_dict(policy_data)
			if policy == null or not government.define_policy(policy):
				for snapshot in snapshots:
					var snapshot_government: GovernmentComponent = snapshot["government"] as GovernmentComponent
					snapshot_government.state = (snapshot["state"] as Dictionary).duplicate(true)
				result["error"] = "GovernmentComponent rejected policy registration; all touched component state was restored."
				result["registered_count"] = 0
				result["already_registered_count"] = 0
				return result
			registered_count += 1

	result["ok"] = true
	result["governments_processed"] = governments.size()
	result["registered_count"] = registered_count
	result["already_registered_count"] = already_registered_count
	result["error"] = ""
	return result


func _build_definition_plan(catalog: PolicyCatalog) -> Dictionary:
	var output: Dictionary = {
		"ok": false,
		"definitions": {},
		"disabled_count": 0,
		"error": ""
	}
	var source_ids: Array = catalog.get_policy_ids()
	if source_ids.is_empty():
		output["error"] = "Policy catalog contains no definitions."
		return output

	var source_policies: Dictionary = {}
	var target_owners: Dictionary = {}
	var effect_owners: Dictionary = {}
	var enabled_definitions: Dictionary = {}
	var supported_effects: Dictionary = GovernmentPolicyEffectSystem.SUPPORTED_EFFECTS
	var spending_bundle_count: int = 0

	for raw_id in source_ids:
		var policy_id: String = str(raw_id)
		var definition: Dictionary = catalog.get_policy(policy_id)
		if definition.is_empty():
			output["error"] = "Policy catalog entry is missing or malformed: " + policy_id
			return output
		if str(definition.get("id", "")) != policy_id:
			output["error"] = "Policy catalog key and definition ID disagree: " + policy_id
			return output

		for required_text_field in ["name", "description", "category", "target"]:
			if str(definition.get(required_text_field, "")).strip_edges().is_empty():
				output["error"] = "Policy " + policy_id + " has an empty field: " + str(required_text_field)
				return output

		var enabled_value: Variant = definition.get("enabled", null)
		if typeof(enabled_value) != TYPE_BOOL:
			output["error"] = "Policy enabled flag must be boolean: " + policy_id
			return output

		var scalar_value: Variant = definition.get("value", null)
		if not _is_numeric(scalar_value) or float(scalar_value) < 0.0 or float(scalar_value) > 1.0:
			output["error"] = "Policy scalar value is outside the supported 0..1 range: " + policy_id
			return output

		var cost_value: Variant = definition.get("cost", null)
		if typeof(cost_value) != TYPE_DICTIONARY:
			output["error"] = "Policy cost must be a dictionary: " + policy_id
			return output
		var cost: Dictionary = cost_value as Dictionary
		if cost.is_empty():
			output["error"] = "Policy cost must declare at least one resource: " + policy_id
			return output
		for raw_resource_id in cost.keys():
			var amount: Variant = cost[raw_resource_id]
			if str(raw_resource_id) != TREASURY_RESOURCE or not _is_numeric(amount) or float(amount) < 0.0:
				output["error"] = "Policy cost violates the current treasury-only contract: " + policy_id
				return output

		var duration_value: Variant = definition.get("duration_months", null)
		if not _is_positive_integer(duration_value):
			output["error"] = "Policy duration must be a positive whole number: " + policy_id
			return output

		var metadata_value: Variant = definition.get("metadata", null)
		if typeof(metadata_value) != TYPE_DICTIONARY:
			output["error"] = "Policy metadata must be a dictionary: " + policy_id
			return output
		var metadata: Dictionary = (metadata_value as Dictionary).duplicate(true)
		if typeof(metadata.get("implementation_capacity_enabled", null)) != TYPE_BOOL:
			output["error"] = "Policy implementation_capacity_enabled must be boolean: " + policy_id
			return output
		if metadata.has("catalog_binding"):
			output["error"] = "Policy metadata uses the reserved catalog_binding key: " + policy_id
			return output

		var provenance_value: Variant = definition.get("provenance", null)
		if typeof(provenance_value) != TYPE_DICTIONARY:
			output["error"] = "Policy provenance must be a dictionary: " + policy_id
			return output
		var definition_version: Variant = definition.get("definition_version", null)
		if not _is_positive_integer(definition_version):
			output["error"] = "Policy definition_version must be a positive whole number: " + policy_id
			return output

		var effects_value: Variant = definition.get("effects", null)
		if typeof(effects_value) != TYPE_DICTIONARY:
			output["error"] = "Policy effects must be a dictionary: " + policy_id
			return output
		var effects: Dictionary = effects_value as Dictionary
		if effects.is_empty():
			output["error"] = "Policy effects must not be empty: " + policy_id
			return output
		for raw_effect_key in effects.keys():
			var effect_key: String = str(raw_effect_key)
			var effect_value: Variant = effects[raw_effect_key]
			if not supported_effects.has(effect_key):
				output["error"] = "Unsupported policy effect: " + effect_key
				return output
			if not _is_numeric(effect_value) or float(effect_value) < 0.0 or float(effect_value) > 1.0:
				output["error"] = "Policy effect is outside the supported 0..1 range: " + effect_key
				return output
			if effect_owners.has(effect_key):
				output["error"] = "Multiple policy catalog entries own the same effect: " + effect_key
				return output
			effect_owners[effect_key] = policy_id

		var target_key: String = str(definition.get("category", "")).strip_edges() + "::" + str(definition.get("target", "")).strip_edges()
		if target_owners.has(target_key):
			output["error"] = "Multiple catalog policies share a runtime activation target: " + target_key
			return output
		target_owners[target_key] = policy_id

		var has_spending_effect: bool = false
		for spending_key in SPENDING_EFFECT_KEYS:
			if effects.has(spending_key):
				has_spending_effect = true
		if has_spending_effect:
			spending_bundle_count += 1
			if not _has_all_keys(effects, SPENDING_EFFECT_KEYS):
				output["error"] = "Spending-share policy must include all four allocation effects: " + policy_id
				return output
			var spending_total: float = 0.0
			for spending_key in SPENDING_EFFECT_KEYS:
				spending_total += float(effects[spending_key])
			if not is_equal_approx(spending_total, 1.0):
				output["error"] = "Spending-share policy does not sum to 1.0: " + policy_id
				return output

		var runtime_metadata: Dictionary = metadata.duplicate(true)
		runtime_metadata["catalog_binding"] = {
			"catalog_id": catalog.get_catalog_id(),
			"catalog_version": catalog.get_catalog_version(),
			"policy_id": policy_id,
			"name": str(definition.get("name", "")),
			"description": str(definition.get("description", "")),
			"definition_version": int(definition_version),
			"provenance": (provenance_value as Dictionary).duplicate(true)
		}

		var runtime_definition: GovernmentPolicyDefinition = GovernmentPolicyDefinition.new(
			policy_id,
			str(definition.get("category", "")),
			str(definition.get("target", "")),
			float(scalar_value),
			cost.duplicate(true),
			int(duration_value),
			effects.duplicate(true),
			runtime_metadata
		)
		if not runtime_definition.is_valid():
			output["error"] = "Policy could not be represented by GovernmentPolicyDefinition: " + policy_id
			return output
		source_policies[policy_id] = runtime_definition.to_dict()
		if bool(enabled_value):
			enabled_definitions[policy_id] = runtime_definition.to_dict()
		else:
			output["disabled_count"] = int(output["disabled_count"]) + 1

	var declared_effect_keys: Array = effect_owners.keys()
	var supported_effect_keys: Array = supported_effects.keys()
	declared_effect_keys.sort()
	supported_effect_keys.sort()
	if declared_effect_keys != supported_effect_keys:
		output["error"] = "Policy catalog does not cover every supported effect exactly once."
		return output
	if spending_bundle_count != 1:
		output["error"] = "Policy catalog must contain exactly one atomic spending-share bundle."
		return output
	if enabled_definitions.is_empty():
		output["error"] = "Policy catalog has no enabled definitions to bind."
		return output

	output["ok"] = true
	output["definitions"] = enabled_definitions
	output["all_definitions"] = source_policies
	output["error"] = ""
	return output


func _is_numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_positive_integer(value: Variant) -> bool:
	if not _is_numeric(value):
		return false
	var numeric_value: float = float(value)
	return numeric_value >= 1.0 and is_equal_approx(numeric_value, floor(numeric_value))


func _has_all_keys(dictionary: Dictionary, keys: Array[String]) -> bool:
	for key in keys:
		if not dictionary.has(key):
			return false
	return true
