class_name ProductionProcessCatalogSemanticTest
extends RefCounted


static func run() -> bool:

	var catalog := ProductionProcessCatalog.new()
	var process_ids: Array = catalog.get_process_ids()

	var passed := true

	if process_ids.is_empty():
		print("Catalog semantic validation: FAIL | no processes")
		return false

	for process_id in process_ids:

		var id := str(process_id)
		var definition: Dictionary = catalog.get_process(id)

		# ---------------------------------
		# Dictionary fields
		# ---------------------------------

		var dictionary_fields: Array = [
			"inputs",
			"outputs",
			"byproducts",
			"technology_requirements",
			"capability_requirements",
			"infrastructure_requirements",
			"labor_skill_requirement",
			"equipment_requirement",
			"energy_requirement",
			"maintenance_requirement",
			"seasonality",
			"waste",
			"displacement"
		]

		for field_name in dictionary_fields:
			if typeof(definition.get(field_name)) != TYPE_DICTIONARY:
				print(
					"Semantic type error: "
					+ id
					+ " → "
					+ field_name
					+ ": FAIL"
				)
				passed = false

		# ---------------------------------
		# Numeric fields
		# ---------------------------------

		var numeric_fields: Array = [
			"labor_requirement",
			"capital_requirement",
			"operating_cost",
			"transition_cost",
			"efficiency",
			"duration",
			"reliability",
			"land_requirement",
			"obsolescence",
			"power_requirement"
		]

		for field_name in numeric_fields:
			var value = definition.get(field_name)

			if (
				typeof(value) != TYPE_INT
				and typeof(value) != TYPE_FLOAT
			):
				print(
					"Semantic numeric type error: "
					+ id
					+ " → "
					+ field_name
					+ ": FAIL"
				)
				passed = false

		var power_requirement: float = float(
			definition.get("power_requirement", -1.0)
		)

		if power_requirement < 0.0:
			print(
				"Power requirement must be >= 0: "
				+ id
				+ ": FAIL"
			)
			passed = false

		# ---------------------------------
		# At least one output
		# ---------------------------------

		var outputs: Dictionary = definition.get(
			"outputs",
			{}
		)

		if outputs.is_empty():
			print(
				"Process must have at least one output: "
				+ id
				+ ": FAIL"
			)
			passed = false

		# ---------------------------------
		# Efficiency
		# ---------------------------------

		var efficiency: float = float(
			definition.get("efficiency", -1.0)
		)

		if efficiency < 0.0:
			print(
				"Efficiency must be >= 0: "
				+ id
				+ ": FAIL"
			)
			passed = false

		# ---------------------------------
		# Duration
		# ---------------------------------

		var duration: float = float(
			definition.get("duration", 0.0)
		)

		if duration <= 0.0:
			print(
				"Duration must be > 0: "
				+ id
				+ ": FAIL"
			)
			passed = false

		# ---------------------------------
		# Reliability
		# ---------------------------------

		var reliability: float = float(
			definition.get("reliability", -1.0)
		)

		if reliability < 0.0 or reliability > 1.0:
			print(
				"Reliability must be between 0 and 1: "
				+ id
				+ ": FAIL"
			)
			passed = false

		# ---------------------------------
		# Availability dates
		# ---------------------------------

		if not definition.has("available_from"):
			print(
				"Missing available_from: "
				+ id
				+ ": FAIL"
			)
			passed = false
		else:
			var available_from = definition["available_from"]

			if (
				typeof(available_from) != TYPE_INT
				and typeof(available_from) != TYPE_FLOAT
			):
				print(
					"available_from must be numeric: "
					+ id
					+ ": FAIL"
				)
				passed = false

		if definition.has("available_until"):
			var available_until = definition["available_until"]

			if available_until != null:

				if (
					typeof(available_until) != TYPE_INT
					and typeof(available_until) != TYPE_FLOAT
				):
					print(
						"available_until must be numeric or null: "
						+ id
						+ ": FAIL"
					)
					passed = false

				else:
					var from_year := int(
						definition.get(
							"available_from",
							0
						)
					)

					var until_year := int(
						available_until
					)

					if until_year < from_year:
						print(
							"available_until before available_from: "
							+ id
							+ ": FAIL"
						)
						passed = false

	if passed:
		print(
			"All catalog semantic checks: PASS"
		)

	print(
		"ProductionProcessCatalogSemanticTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
