class_name ResourceCatalogProductionSemanticsTest
extends RefCounted


static func run() -> bool:
	var resource_catalog := ResourceCatalog.new()
	var production_catalog := ProductionProcessCatalog.new()
	var passed := true

	var resource_ids: Array = resource_catalog.get_resource_ids()
	var process_ids: Array = production_catalog.get_process_ids()

	if resource_ids.is_empty():
		print("Resource catalog has resources: FAIL")
		return false

	if process_ids.is_empty():
		print("Production process catalog has processes: FAIL")
		return false

	print("Resource catalog has resources: PASS")
	print("Production process catalog has processes: PASS")

	# ------------------------------------------------------------
	# 1. Resource semantic classification must exist.
	# ------------------------------------------------------------

	var semantic_class_counts: Dictionary = {}
	var referenced_resources: Dictionary = {}
	var referenced_by_process: Dictionary = {}

	for resource_id_value in resource_ids:
		var resource_id := str(resource_id_value)
		var definition := resource_catalog.get_resource(resource_id)

		var semantic_class := str(
			definition.get(
				"semantic_class",
				""
			)
		).strip_edges()

		if semantic_class.is_empty():
			print(
				"Resource semantic_class missing: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false
		else:
			semantic_class_counts[semantic_class] = (
				int(
					semantic_class_counts.get(
						semantic_class,
						0
					)
				)
				+ 1
			)

		var roles = definition.get("roles", [])
		var allowed_roles = definition.get("allowed_roles", [])

		if typeof(roles) != TYPE_ARRAY or roles.is_empty():
			print(
				"Resource roles missing: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false
		elif typeof(allowed_roles) != TYPE_ARRAY or allowed_roles.is_empty():
			print(
				"Resource allowed_roles missing: "
				+ resource_id
				+ ": FAIL"
			)
			passed = false

		# can_be_produced is a capability flag, not a requirement that
		# the resource carry a generic "production" role. Raw resources
		# such as coal, oil, and natural gas can be produced through the
		# ResourceSystem extraction boundary while their catalog roles
		# remain focused on consumption, storage, reserve, and trade semantics.
		#
		# The consistency rule works in the opposite direction:
		# an explicit production role requires can_be_produced=true.
		if _has_any_role(
			roles,
			["production", "production_output"]
		):
			if not bool(definition.get("can_be_produced", false)):
				print(
					"Production role requires can_be_produced: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

		if bool(definition.get("can_be_consumed", false)):
			# A resource may be consumed by population, production, energy,
			# maintenance, or another explicitly modeled domain. Do not force
			# a single consumption-role name here.
			if not _has_any_role(
				roles,
				[
					"consumption",
					"production_input",
					"energy_input",
					"maintenance_input"
				]
			):
				print(
					"Consumable resource lacks a consumption-capable role: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

		if bool(definition.get("can_be_stockpiled", false)):
			if not _has_any_role(
				roles,
				["stockpile"]
			):
				print(
					"Stockpilable resource lacks stockpile role: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

		if bool(definition.get("can_have_reserves", false)):
			if not _has_any_role(
				roles,
				["reserve"]
			):
				print(
					"Reservable resource lacks reserve role: "
					+ resource_id
					+ ": FAIL"
				)
				passed = false

	# ------------------------------------------------------------
	# 2. Every production resource edge must resolve to the resource
	#    catalog and agree with the resource semantic contract.
	# ------------------------------------------------------------

	var process_reference_fields: Array = [
		"inputs",
		"outputs",
		"byproducts",
		"energy_requirement",
		"maintenance_requirement",
		"waste"
	]

	for process_id_value in process_ids:
		var process_id := str(process_id_value)
		var process_definition := production_catalog.get_process(process_id)
		var category := str(
			process_definition.get(
				"category",
				""
			)
		).strip_edges().to_lower()

		for field_name in process_reference_fields:
			var references = process_definition.get(
				field_name,
				{}
			)

			if typeof(references) != TYPE_DICTIONARY:
				continue

			for resource_key in references.keys():
				var resource_id := str(resource_key)
				referenced_resources[resource_id] = true
				if not referenced_by_process.has(resource_id):
					referenced_by_process[resource_id] = []
				referenced_by_process[resource_id].append(
					process_id + ":" + field_name
				)

				if not resource_catalog.has_resource(resource_id):
					print(
						"Unknown resource reference: "
						+ process_id
						+ " -> "
						+ field_name
						+ " -> "
						+ resource_id
						+ ": FAIL"
					)
					passed = false
					continue

				var resource_definition := resource_catalog.get_resource(
					resource_id
				)
				var roles = resource_definition.get(
					"roles",
					[]
				)

				match field_name:
					"inputs":
						if not bool(resource_definition.get("can_be_consumed", false)):
							print(
								"Production input is not consumable: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

						if not _has_any_role(
							roles,
							["production_input"]
						):
							print(
								"Production input lacks production_input role: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

						# ProductionProcessSystem currently consumes process inputs
						# from ResourceComponent stockpile state. A resource that
						# cannot be stockpiled therefore cannot safely be connected
						# here until the runtime contract explicitly supports flow-only
						# process inputs.
						if not bool(resource_definition.get("can_be_stockpiled", false)):
							print(
								"Non-stockpilable resource cannot currently be a production input: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

					"outputs", "byproducts", "waste":
						if not bool(resource_definition.get("can_be_produced", false)):
							print(
								"Production output is not producible: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

						# Extraction is a separate runtime boundary owned by
						# ResourceSystem. Extraction outputs therefore do not need
						# the manufactured-process production role.
						if category != "extraction":
							if not _has_any_role(
								roles,
								["production_output", "production"]
							):
								print(
									"Production output lacks production role: "
									+ _edge_label(process_id, field_name, resource_id)
									+ ": FAIL"
								)
								passed = false

						if not bool(resource_definition.get("can_be_stockpiled", false)):
							print(
								"Non-stockpilable resource cannot currently be a process output: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

					"energy_requirement":
						if not bool(resource_definition.get("can_be_consumed", false)):
							print(
								"Energy resource is not consumable: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

						if not _has_any_role(
							roles,
							["energy_input"]
						):
							print(
								"Energy resource lacks energy_input role: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

					"maintenance_requirement":
						if not bool(resource_definition.get("can_be_consumed", false)):
							print(
								"Maintenance resource is not consumable: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

						if not _has_any_role(
							roles,
							["maintenance_input"]
						):
							print(
								"Maintenance resource lacks maintenance_input role: "
								+ _edge_label(process_id, field_name, resource_id)
								+ ": FAIL"
							)
							passed = false

		# Extraction is a semantic boundary in the live runtime. Keep the
		# 4.1C contract narrow: extraction processes must produce resources,
		# while the actual extraction quantity remains ResourceSystem-owned.
		if category == "extraction":
			var outputs = process_definition.get("outputs", {})
			if typeof(outputs) != TYPE_DICTIONARY or outputs.is_empty():
				print(
					"Extraction process must define at least one output resource: "
					+ process_id
					+ ": FAIL"
				)
				passed = false

	# ------------------------------------------------------------
	# 3. Report connected vs catalog-only resource semantics.
	#    Unreferenced resources are readiness states, not failures.
	# ------------------------------------------------------------

	var connected_count := 0
	var unreferenced_count := 0

	for resource_id_value in resource_ids:
		var resource_id := str(resource_id_value)
		if referenced_resources.has(resource_id):
			connected_count += 1
		else:
			unreferenced_count += 1
			print(
				"Resource semantic readiness: "
				+ resource_id
				+ " -> defined / canonically identified / semantically valid / not yet referenced by production"
			)

	print(
		"Resource semantic classes: "
		+ str(semantic_class_counts)
	)

	print(
		"Production-connected resources: "
		+ str(connected_count)
		+ " | catalog-only resources: "
		+ str(unreferenced_count)
	)

	# ------------------------------------------------------------
	# Result
	# ------------------------------------------------------------

	if passed:
		print(
			"Resource ↔ Production semantic causal readiness: PASS"
		)

	print(
		"ResourceCatalogProductionSemanticsTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _has_any_role(
	roles: Array,
	candidates: Array
) -> bool:
	for role in candidates:
		if roles.has(role):
			return true
	return false


static func _edge_label(
	process_id: String,
	field_name: String,
	resource_id: String
) -> String:
	return (
		process_id
		+ " -> "
		+ field_name
		+ " -> "
		+ resource_id
	)
