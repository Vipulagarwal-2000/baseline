class_name PolicyCatalogSchemaTest
extends RefCounted


static func _is_numeric(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _is_positive_whole_number(value: Variant) -> bool:
	if not _is_numeric(value):
		return false
	var numeric_value: float = float(value)
	return numeric_value >= 1.0 and is_equal_approx(numeric_value, floor(numeric_value))


static func run() -> bool:
	var catalog: PolicyCatalog = PolicyCatalog.new()
	var passed: bool = true

	if not catalog.is_loaded():
		TestLogger.write_line(
			"Policy catalog loads for schema validation: FAIL | "
			+ catalog.get_load_error()
		)
		return false
	TestLogger.write_line("Policy catalog loads for schema validation: PASS")

	if catalog.get_catalog_version() < 2:
		TestLogger.write_line("Policy catalog content version is at least 2: FAIL")
		passed = false
	else:
		TestLogger.write_line("Policy catalog content version is at least 2: PASS")

	if catalog.get_catalog_id().strip_edges().is_empty():
		TestLogger.write_line("Policy catalog identifier is non-empty: FAIL")
		passed = false
	else:
		TestLogger.write_line("Policy catalog identifier is non-empty: PASS")

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
		"definition_version_semantics",
		"enabled_semantics",
		"spending_allocation_bundle_semantics",
		"effect_ownership_semantics",
		"content_scope_semantics"
	]
	for field_name in required_contract_fields:
		if str(contract.get(field_name, "")).strip_edges().is_empty():
			TestLogger.write_line("Policy catalog semantic contract field is non-empty: " + field_name + ": FAIL")
			passed = false

	var policy_ids: Array = catalog.get_policy_ids()
	if policy_ids.is_empty():
		TestLogger.write_line("Policy catalog contains named definitions: FAIL")
		return false
	TestLogger.write_line("Policy catalog contains named definitions: PASS | count=" + str(policy_ids.size()))

	var required_fields: Array[String] = [
		"id", "name", "description", "category", "target", "value",
		"cost", "duration_months", "effects", "metadata", "enabled",
		"provenance", "definition_version"
	]

	for policy_id_value in policy_ids:
		var policy_id: String = str(policy_id_value)
		var definition: Dictionary = catalog.get_policy(policy_id)
		for field_name in required_fields:
			if not definition.has(field_name):
				TestLogger.write_line("Policy catalog field exists: " + policy_id + " -> " + field_name + ": FAIL")
				passed = false

		if str(definition.get("id", "")) != policy_id:
			TestLogger.write_line("Policy definition id matches catalog key: " + policy_id + ": FAIL")
			passed = false

		for field_name in ["id", "name", "description", "category", "target"]:
			if str(definition.get(field_name, "")).strip_edges().is_empty():
				TestLogger.write_line("Policy definition text field is non-empty: " + policy_id + " -> " + field_name + ": FAIL")
				passed = false

		var value: Variant = definition.get("value", null)
		if not _is_numeric(value) or float(value) < 0.0 or float(value) > 1.0:
			TestLogger.write_line("Policy scalar value is numeric and within 0..1: " + policy_id + ": FAIL")
			passed = false

		var cost_value: Variant = definition.get("cost", null)
		if typeof(cost_value) != TYPE_DICTIONARY:
			TestLogger.write_line("Policy cost is a dictionary: " + policy_id + ": FAIL")
			passed = false
		else:
			var cost: Dictionary = cost_value as Dictionary
			if cost.is_empty():
				TestLogger.write_line("Policy cost declares at least one resource: " + policy_id + ": FAIL")
				passed = false
			for resource_id in cost.keys():
				var amount: Variant = cost[resource_id]
				if not _is_numeric(amount) or float(amount) < 0.0:
					TestLogger.write_line("Policy cost amount is non-negative numeric: " + policy_id + " -> " + str(resource_id) + ": FAIL")
					passed = false

		if not _is_positive_whole_number(definition.get("duration_months", null)):
			TestLogger.write_line("Policy duration is a positive whole number of months: " + policy_id + ": FAIL")
			passed = false

		var effects_value: Variant = definition.get("effects", null)
		if typeof(effects_value) != TYPE_DICTIONARY or (effects_value as Dictionary).is_empty():
			TestLogger.write_line("Policy effects are a non-empty dictionary: " + policy_id + ": FAIL")
			passed = false

		var metadata_value: Variant = definition.get("metadata", null)
		if typeof(metadata_value) != TYPE_DICTIONARY:
			TestLogger.write_line("Policy metadata is a dictionary: " + policy_id + ": FAIL")
			passed = false
		else:
			var metadata: Dictionary = metadata_value as Dictionary
			if typeof(metadata.get("implementation_capacity_enabled", null)) != TYPE_BOOL:
				TestLogger.write_line("Policy implementation-capacity flag is boolean: " + policy_id + ": FAIL")
				passed = false

		if typeof(definition.get("enabled", null)) != TYPE_BOOL:
			TestLogger.write_line("Policy enabled flag is boolean: " + policy_id + ": FAIL")
			passed = false

		var provenance_value: Variant = definition.get("provenance", null)
		if typeof(provenance_value) != TYPE_DICTIONARY:
			TestLogger.write_line("Policy provenance is a dictionary: " + policy_id + ": FAIL")
			passed = false
		else:
			var provenance: Dictionary = provenance_value as Dictionary
			for field_name in ["status", "source_reference", "confidence", "notes"]:
				if str(provenance.get(field_name, "")).strip_edges().is_empty():
					TestLogger.write_line("Policy provenance field is non-empty: " + policy_id + " -> " + field_name + ": FAIL")
					passed = false

		if not _is_positive_whole_number(definition.get("definition_version", null)):
			TestLogger.write_line("Policy definition version is a positive integer: " + policy_id + ": FAIL")
			passed = false

	TestLogger.write_line("Policy catalog entry schema validation: " + ("PASS" if passed else "FAIL"))
	if passed:
		TestLogger.write_line("All policy catalog schema checks: PASS")
	TestLogger.write_line("PolicyCatalogSchemaTest: " + ("PASS" if passed else "FAIL"))
	return passed
