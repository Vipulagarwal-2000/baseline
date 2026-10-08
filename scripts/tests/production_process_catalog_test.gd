class_name ProductionProcessCatalogTest
extends RefCounted


const EXPANDED_PROCESS_IDS: Array[String] = [
	"natural_gas_extraction",
	"fertilizer_production",
	"cement_production",
	"chemical_production"
]


static func run() -> bool:

	var catalog := ProductionProcessCatalog.new()
	var resource_catalog := ResourceCatalog.new()
	var passed: bool = true

	# ============================================================
	# EXISTING BASELINE PROCESSES
	# ============================================================

	var required_baseline_ids: Array[String] = [
		"steel_basic",
		"coal_mining",
		"iron_ore_mining",
		"advanced_steel_production",
		"machinery_basic"
	]

	for process_id in required_baseline_ids:
		if not catalog.has_process(process_id):
			print("Catalog " + process_id + ": FAIL")
			passed = false
		else:
			print("Catalog " + process_id + ": PASS")

	var steel: Dictionary = catalog.get_process("steel_basic")
	var steel_inputs: Dictionary = steel.get("inputs", {})

	var steel_input_passed: bool = is_equal_approx(
		float(steel_inputs.get("iron", 0.0)),
		2.0
	)

	print(
		"Steel iron input: "
		+ ("PASS" if steel_input_passed else "FAIL")
	)

	if not steel_input_passed:
		passed = false

	var available_1950: Array = catalog.get_available_process_ids(1950)
	var available_1955: Array = catalog.get_available_process_ids(1955)

	var steel_1950_passed: bool = available_1950.has("steel_basic")
	var advanced_steel_1950_blocked: bool = not available_1950.has(
		"advanced_steel_production"
	)
	var advanced_steel_1955_passed: bool = available_1955.has(
		"advanced_steel_production"
	)

	print(
		"1950 steel availability: "
		+ ("PASS" if steel_1950_passed else "FAIL")
	)
	print(
		"1950 advanced steel blocked: "
		+ ("PASS" if advanced_steel_1950_blocked else "FAIL")
	)
	print(
		"1955 advanced steel availability: "
		+ ("PASS" if advanced_steel_1955_passed else "FAIL")
	)

	if not steel_1950_passed:
		passed = false
	if not advanced_steel_1950_blocked:
		passed = false
	if not advanced_steel_1955_passed:
		passed = false

	# ============================================================
	# 4.3B EXPANDED PROCESSES
	# ============================================================
	# These four processes use only the existing production-process
	# execution semantics and the stockpilable resource contract.
	# Electric-power generation is intentionally not introduced here:
	# electric_power is a processed-energy resource and the current
	# ProductionProcessSystem writes process outputs to stockpile.
	# ============================================================

	for process_id in EXPANDED_PROCESS_IDS:

		var exists: bool = catalog.has_process(process_id)
		print(
			"Expanded process exists: "
			+ process_id
			+ ": "
			+ ("PASS" if exists else "FAIL")
		)

		if not exists:
			passed = false
			continue

		var definition: Dictionary = catalog.get_process(process_id)
		var inputs: Dictionary = definition.get("inputs", {})
		var outputs: Dictionary = definition.get("outputs", {})
		var category: String = str(definition.get("category", ""))
		var available_from: int = int(definition.get("available_from", 0))

		var expected_extraction: bool = (
			process_id == "natural_gas_extraction"
		)

		var input_shape_passed: bool = (
			inputs.is_empty()
			if expected_extraction
			else not inputs.is_empty()
		)
		var output_shape_passed: bool = not outputs.is_empty()
		var date_passed: bool = available_from == 1950
		var availability_passed: bool = available_1950.has(process_id)

		print(
			"Expanded input shape: "
			+ process_id
			+ ": "
			+ ("PASS" if input_shape_passed else "FAIL")
		)
		print(
			"Expanded output shape: "
			+ process_id
			+ ": "
			+ ("PASS" if output_shape_passed else "FAIL")
		)
		print(
			"Expanded 1950 availability: "
			+ process_id
			+ ": "
			+ ("PASS" if date_passed and availability_passed else "FAIL")
		)

		if expected_extraction:
			var extraction_shape_passed: bool = (
				category == "extraction"
				and inputs.is_empty()
				and output_shape_passed
			)

			print(
				"Natural-gas extraction boundary: "
				+ ("PASS" if extraction_shape_passed else "FAIL")
			)

			if not extraction_shape_passed:
				passed = false
		else:
			var manufacturing_shape_passed: bool = (
				category != "extraction"
				and not inputs.is_empty()
				and output_shape_passed
			)

			print(
				"Manufacturing process shape: "
				+ process_id
				+ ": "
				+ ("PASS" if manufacturing_shape_passed else "FAIL")
			)

			if not manufacturing_shape_passed:
				passed = false

		if not input_shape_passed:
			passed = false
		if not output_shape_passed:
			passed = false
		if not date_passed:
			passed = false
		if not availability_passed:
			passed = false

		# ------------------------------------------------------------
		# RESOURCE REFERENCE CHECKS
		# ------------------------------------------------------------

		for resource_id_variant in inputs.keys():
			var resource_id: String = str(resource_id_variant)
			var resource_exists: bool = resource_catalog.has_resource(resource_id)

			print(
				"Expanded input resource resolves: "
				+ process_id
				+ " -> "
				+ resource_id
				+ ": "
				+ ("PASS" if resource_exists else "FAIL")
			)

			if not resource_exists:
				passed = false
				continue

			var resource_definition: Dictionary = (
				resource_catalog.get_resource(resource_id)
			)
			var can_be_consumed: bool = bool(
				resource_definition.get("can_be_consumed", false)
			)
			var can_be_stockpiled: bool = bool(
				resource_definition.get("can_be_stockpiled", false)
			)
			var roles_variant: Variant = resource_definition.get(
				"allowed_roles",
				[]
			)
			var roles: Array = []
			if typeof(roles_variant) == TYPE_ARRAY:
				roles = roles_variant

			var input_role_valid: bool = roles.has("production_input")
			var input_semantics_passed: bool = (
				can_be_consumed
				and can_be_stockpiled
				and input_role_valid
			)

			print(
				"Expanded input resource semantics: "
				+ process_id
				+ " -> "
				+ resource_id
				+ ": "
				+ ("PASS" if input_semantics_passed else "FAIL")
			)

			if not input_semantics_passed:
				passed = false

		for resource_id_variant in outputs.keys():
			var resource_id: String = str(resource_id_variant)
			var resource_exists: bool = resource_catalog.has_resource(resource_id)

			print(
				"Expanded output resource resolves: "
				+ process_id
				+ " -> "
				+ resource_id
				+ ": "
				+ ("PASS" if resource_exists else "FAIL")
			)

			if not resource_exists:
				passed = false
				continue

			var resource_definition: Dictionary = (
				resource_catalog.get_resource(resource_id)
			)
			var can_be_produced: bool = bool(
				resource_definition.get("can_be_produced", false)
			)
			var can_be_stockpiled: bool = bool(
				resource_definition.get("can_be_stockpiled", false)
			)
			var roles_variant: Variant = resource_definition.get(
				"allowed_roles",
				[]
			)
			var roles: Array = []
			if typeof(roles_variant) == TYPE_ARRAY:
				roles = roles_variant

			# Extraction outputs are a ResourceSystem-owned boundary.
			# They must be producible and stockpilable, but they do not
			# require a generic production_output role. This matches the
			# 4.1C resource/process semantic contract.
			var output_role_valid: bool = (
				roles.has("production_output")
				if not expected_extraction
				else true
			)

			var output_semantics_passed: bool = (
				can_be_produced
				and can_be_stockpiled
				and output_role_valid
			)

			print(
				"Expanded output resource semantics: "
				+ process_id
				+ " -> "
				+ resource_id
				+ ": "
				+ ("PASS" if output_semantics_passed else "FAIL")
			)

			if not output_semantics_passed:
				passed = false

	# ============================================================
	# PROCESS-SPECIFIC CONTENT CHECKS
	# ============================================================

	var natural_gas_definition: Dictionary = catalog.get_process(
		"natural_gas_extraction"
	)
	var natural_gas_outputs: Dictionary = natural_gas_definition.get(
		"outputs",
		{}
	)
	var natural_gas_output_passed: bool = is_equal_approx(
		float(natural_gas_outputs.get("natural_gas", 0.0)),
		1.0
	)

	print(
		"Natural gas extraction output: "
		+ ("PASS" if natural_gas_output_passed else "FAIL")
	)

	if not natural_gas_output_passed:
		passed = false

	var fertilizer_definition: Dictionary = catalog.get_process(
		"fertilizer_production"
	)
	var fertilizer_inputs: Dictionary = fertilizer_definition.get(
		"inputs",
		{}
	)
	var fertilizer_outputs: Dictionary = fertilizer_definition.get(
		"outputs",
		{}
	)
	var fertilizer_chain_passed: bool = (
		is_equal_approx(
			float(fertilizer_inputs.get("natural_gas", 0.0)),
			1.0
		)
		and is_equal_approx(
			float(fertilizer_outputs.get("fertilizer", 0.0)),
			1.0
		)
	)

	print(
		"Fertilizer natural_gas -> fertilizer chain: "
		+ ("PASS" if fertilizer_chain_passed else "FAIL")
	)

	if not fertilizer_chain_passed:
		passed = false

	var cement_definition: Dictionary = catalog.get_process(
		"cement_production"
	)
	var cement_inputs: Dictionary = cement_definition.get(
		"inputs",
		{}
	)
	var cement_outputs: Dictionary = cement_definition.get(
		"outputs",
		{}
	)
	var cement_chain_passed: bool = (
		is_equal_approx(
			float(cement_inputs.get("coal", 0.0)),
			1.0
		)
		and is_equal_approx(
			float(cement_outputs.get("cement", 0.0)),
			1.0
		)
	)

	print(
		"Cement coal -> cement chain: "
		+ ("PASS" if cement_chain_passed else "FAIL")
	)

	if not cement_chain_passed:
		passed = false

	var chemical_definition: Dictionary = catalog.get_process(
		"chemical_production"
	)
	var chemical_inputs: Dictionary = chemical_definition.get(
		"inputs",
		{}
	)
	var chemical_outputs: Dictionary = chemical_definition.get(
		"outputs",
		{}
	)
	var chemical_chain_passed: bool = (
		is_equal_approx(
			float(chemical_inputs.get("oil", 0.0)),
			1.0
		)
		and is_equal_approx(
			float(chemical_outputs.get("chemicals", 0.0)),
			1.0
		)
	)

	print(
		"Chemical oil -> chemicals chain: "
		+ ("PASS" if chemical_chain_passed else "FAIL")
	)

	if not chemical_chain_passed:
		passed = false

	print(
		"ProductionProcessCatalogTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
