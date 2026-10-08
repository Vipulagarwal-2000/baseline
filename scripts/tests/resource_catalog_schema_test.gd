class_name ResourceCatalogSchemaTest
extends RefCounted


static func run() -> bool:
	var catalog := ResourceCatalog.new()
	var passed := true

	if catalog.get_resource_ids().is_empty():
		print("Resource catalog contains resources: FAIL")
		return false

	print("Resource catalog contains resources: PASS")

	var required_fields: Array = [
		"name",
		"semantic_class",
		"quantity_type",
		"unit",
		"canonical_unit",
		"unit_status",
		"unit_scale",
		"flow_unit",
		"price_unit",
		"stockpile_semantics",
		"reserve_semantics",
		"roles",
		"allowed_roles",
		"provenance",
		"definition_version",
		"can_be_produced",
		"can_be_consumed",
		"can_be_stockpiled",
		"can_have_reserves"
	]

	for resource_id in catalog.get_resource_ids():
		var definition := catalog.get_resource(resource_id)

		for field_name in required_fields:
			if not definition.has(field_name):
				print(
					"Resource catalog field missing: "
					+ resource_id
					+ " -> "
					+ field_name
					+ ": FAIL"
				)
				passed = false

		if definition.get("unit_status", "") == "unresolved":
			if str(definition.get("unit", "")).strip_edges() == "":
				print(
					"Unresolved resource unit must be explicit: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

		if str(definition.get("quantity_type", "")).strip_edges() == "":
			print(
				"Resource quantity type must be explicit: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		if str(definition.get("canonical_unit", "")).strip_edges() == "":
			print(
				"Resource canonical unit must be explicit: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		if definition.get("canonical_unit", "") != definition.get("unit", ""):
			print(
				"Canonical unit must match declared unit until unit conversion is explicitly modeled: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		if definition.get("unit_scale", 0) != null:
			var unit_scale = definition.get("unit_scale")
			if typeof(unit_scale) not in [TYPE_INT, TYPE_FLOAT] \
			or float(unit_scale) <= 0.0:
				print(
					"Resolved resource unit scale must be positive: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

		if str(definition.get("flow_unit", "")).strip_edges() == "":
			print(
				"Resource flow unit must be explicit: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		if str(definition.get("price_unit", "")).strip_edges() == "":
			print(
				"Resource price unit must be explicit: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		var provenance = definition.get("provenance", {})
		if typeof(provenance) != TYPE_DICTIONARY:
			print(
				"Resource provenance must be an object: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false
		else:
			for provenance_field in ["status", "confidence"]:
				if str(provenance.get(provenance_field, "")).strip_edges() == "":
					print(
						"Resource provenance field missing: "
						+ resource_id
						+ " -> "
						+ provenance_field
						+ ": FAIL"
					)
					passed = false

		if typeof(definition.get("definition_version")) \
		not in [TYPE_INT, TYPE_FLOAT] \
		or int(definition.get("definition_version", 0)) < 1:
			print(
				"Resource definition version must be positive: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		var roles = definition.get("roles", [])
		if typeof(roles) != TYPE_ARRAY or roles.is_empty():
			print(
				"Resource roles must be non-empty: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		var allowed_roles = definition.get("allowed_roles", [])
		if typeof(allowed_roles) != TYPE_ARRAY or allowed_roles.is_empty():
			print(
				"Resource allowed_roles must be non-empty: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false
		elif allowed_roles != roles:
			print(
				"Resource allowed_roles must match roles until role expansion "
				+ "is explicitly modeled: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

	if passed:
		print("All resource catalog schema checks: PASS")

	print(
		"ResourceCatalogSchemaTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
