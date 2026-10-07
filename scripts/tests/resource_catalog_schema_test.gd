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
		"unit",
		"unit_status",
		"roles",
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

		var roles = definition.get("roles", [])
		if typeof(roles) != TYPE_ARRAY or roles.is_empty():
			print(
                "Resource roles must be non-empty: "
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
