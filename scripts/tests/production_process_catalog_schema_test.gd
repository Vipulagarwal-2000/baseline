class_name ProductionProcessCatalogSchemaTest
extends RefCounted


static func run() -> bool:

	var catalog := ProductionProcessCatalog.new()

	var required_fields: Array = [
		"inputs",
		"outputs",
		"byproducts",
		"technology_requirements",
		"capability_requirements",
		"infrastructure_requirements",
		"labor_requirement",
		"labor_skill_requirement",
		"capital_requirement",
		"equipment_requirement",
		"energy_requirement",
		"power_requirement",
		"land_requirement",
		"maintenance_requirement",
		"operating_cost",
		"transition_cost",
		"efficiency",
		"duration",
		"reliability",
		"seasonality",
		"waste",
		"displacement",
		"obsolescence",
		"production_stage"
	]

	var process_ids: Array = (
		catalog.get_process_ids()
	)

	var passed := true

	if process_ids.is_empty():
		print(
			"Catalog contains processes: FAIL"
		)
		return false

	print(
		"Catalog contains processes: PASS"
	)

	for process_id in process_ids:

		var definition: Dictionary = (
			catalog.get_process(
				str(process_id)
			)
		)

		if definition.is_empty():
			print(
				"Catalog definition "
				+ str(process_id)
				+ ": FAIL"
			)
			passed = false
			continue

		for field_name in required_fields:

			if not definition.has(field_name):

				print(
					"Catalog field missing: "
					+ str(process_id)
					+ " → "
					+ field_name
					+ ": FAIL"
				)

				passed = false


		if definition.has("power_requirement"):
			var power_requirement = definition.get("power_requirement")
			var power_type := typeof(power_requirement)
			if power_type != TYPE_INT and power_type != TYPE_FLOAT:
				print(
					"Catalog power_requirement type: "
					+ str(process_id)
					+ " → FAIL | expected numeric"
				)
				passed = false
			elif float(power_requirement) < 0.0:
				print(
					"Catalog power_requirement value: "
					+ str(process_id)
					+ " → FAIL | value="
					+ str(power_requirement)
				)
				passed = false

		if not definition.has("production_stage"):
			continue

		var production_stage = definition.get(
			"production_stage"
		)

		var stage_type := typeof(
			production_stage
		)

		if (
			stage_type != TYPE_INT
			and stage_type != TYPE_FLOAT
		):

			print(
				"Catalog production_stage type: "
				+ str(process_id)
				+ " → FAIL | expected numeric"
			)

			passed = false

		elif float(production_stage) < 0.0:

			print(
				"Catalog production_stage value: "
				+ str(process_id)
				+ " → FAIL | value="
				+ str(production_stage)
			)

			passed = false

	if passed:
		print(
			"All catalog schema fields: PASS"
		)

	print(
		"ProductionProcessCatalogSchemaTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
