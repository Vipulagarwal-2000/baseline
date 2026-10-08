class_name ProductionProcessCatalogRuntimeIntegrationTest
extends RefCounted


const REQUIRED_PROCESS_IDS: Array[String] = [
	"steel_basic",
	"coal_mining",
	"iron_ore_mining",
	"advanced_steel_production",
	"machinery_basic"
]

const REQUIRED_MAP_FIELDS: Array[String] = [
	"technology_requirements",
	"capability_requirements",
	"infrastructure_requirements",
	"infrastructure_usage",
	"inputs",
	"outputs",
	"byproducts",
	"labor_skill_requirement",
	"equipment_requirement",
	"energy_requirement",
	"maintenance_requirement",
	"seasonality",
	"waste",
	"displacement"
]

static var _last_failure_reason: String = ""


static func get_failure_reason() -> String:
	if _last_failure_reason.is_empty():
		return "No additional diagnostic recorded."
	return _last_failure_reason


static func _record_failure(reason: String) -> void:
	if reason.is_empty():
		return

	if _last_failure_reason.is_empty():
		_last_failure_reason = reason
	else:
		_last_failure_reason += " | " + reason


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_last_failure_reason = ""

	TestLogger.section(
		"PRODUCTION PROCESS CATALOG ↔ RUNTIME INTEGRATION TEST"
	)

	var passed: bool = true

	if world == null or simulation == null:
		_record_failure("World or Simulation is null.")
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var production_system = simulation.get_system(
		"production_process_system"
	)

	var system_ok: bool = (
		production_system != null
		and production_system is ProductionProcessSystem
	)

	TestLogger.write_line(
		"Registered ProductionProcessSystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)

	passed = passed and system_ok

	if not system_ok:
		_record_failure(
			"Registered ProductionProcessSystem is missing or has an unexpected type."
		)
		return false

	var runtime_catalog = production_system.catalog

	var runtime_catalog_ok: bool = (
		runtime_catalog != null
		and runtime_catalog is ProductionProcessCatalog
	)

	TestLogger.write_line(
		"ProductionProcessSystem exposes its authoritative catalog: "
		+ ("PASS" if runtime_catalog_ok else "FAIL")
	)

	passed = passed and runtime_catalog_ok

	if not runtime_catalog_ok:
		_record_failure(
			"ProductionProcessSystem.catalog is missing or has an unexpected type."
		)
		return false

	var source_catalog: ProductionProcessCatalog = (
		ProductionProcessCatalog.new()
	)

	var source_ids: Array = source_catalog.get_process_ids()
	var runtime_ids: Array = runtime_catalog.get_process_ids()

	source_ids.sort()
	runtime_ids.sort()

	var process_id_sets_match: bool = (
		source_ids == runtime_ids
	)

	TestLogger.write_line(
		"Runtime process IDs match catalog-loader IDs: "
		+ ("PASS" if process_id_sets_match else "FAIL")
	)

	if not process_id_sets_match:
		_record_failure(
			"Process ID set mismatch. Source="
			+ str(source_ids)
			+ " Runtime="
			+ str(runtime_ids)
		)

	passed = passed and process_id_sets_match

	var required_ids_present: bool = true
	var missing_required_ids: Array[String] = []

	for process_id in REQUIRED_PROCESS_IDS:
		var present: bool = (
			source_catalog.has_process(process_id)
			and runtime_catalog.has_process(process_id)
		)

		required_ids_present = (
			required_ids_present
			and present
		)

		if not present:
			missing_required_ids.append(process_id)
			TestLogger.write_line(
				"Required process resolves in source/runtime catalogs | "
				+ process_id
				+ ": FAIL"
			)

	TestLogger.write_line(
		"Required authoritative process IDs resolve in both catalogs: "
		+ ("PASS" if required_ids_present else "FAIL")
	)

	if not required_ids_present:
		_record_failure(
			"Required process IDs missing: "
			+ str(missing_required_ids)
		)

	passed = passed and required_ids_present

	var definition_parity: bool = true

	for process_id in source_ids:
		var source_definition: Dictionary = (
			source_catalog.get_process(process_id)
		)

		var runtime_definition: Dictionary = (
			runtime_catalog.get_process(process_id)
		)

		var same_definition: bool = (
			source_definition == runtime_definition
		)

		definition_parity = (
			definition_parity
			and same_definition
		)

		if not same_definition:
			var mismatched_fields: Array[String] = []

			var all_keys: Dictionary = {}
			for key in source_definition.keys():
				all_keys[str(key)] = true
			for key in runtime_definition.keys():
				all_keys[str(key)] = true

			for key_value in all_keys.keys():
				var key: String = str(key_value)
				var source_has: bool = source_definition.has(key)
				var runtime_has: bool = runtime_definition.has(key)

				if source_has != runtime_has:
					mismatched_fields.append(
						key + "(presence)"
					)
					continue

				if source_has:
					var source_value: Variant = source_definition.get(
						key,
						null
					)
					var runtime_value: Variant = runtime_definition.get(
						key,
						null
					)

					if source_value != runtime_value:
						mismatched_fields.append(
							key
							+ "(source="
							+ str(source_value)
							+ ",runtime="
							+ str(runtime_value)
							+ ")"
						)

			TestLogger.write_line(
				"Runtime definition matches authoritative catalog | "
				+ process_id
				+ ": FAIL"
			)

			_record_failure(
				"Definition mismatch for "
				+ process_id
				+ " fields="
				+ str(mismatched_fields)
			)

	TestLogger.write_line(
		"Runtime process definitions match catalog definitions: "
		+ ("PASS" if definition_parity else "FAIL")
	)

	passed = passed and definition_parity

	var semantic_shape_ok: bool = true

	for process_id in source_ids:
		var definition: Dictionary = (
			source_catalog.get_process(process_id)
		)

		var identity_ok: bool = (
			not str(
				definition.get("name", "")
			).is_empty()
			and not str(
				definition.get("category", "")
			).is_empty()
		)

		var stage_value: Variant = definition.get(
			"production_stage",
			null
		)
		var stage_ok: bool = (
			typeof(stage_value) == TYPE_INT
			or typeof(stage_value) == TYPE_FLOAT
		)

		var available_from_value: Variant = definition.get(
			"available_from",
			null
		)
		var availability_ok: bool = (
			typeof(available_from_value) == TYPE_INT
			or typeof(available_from_value) == TYPE_FLOAT
		)

		var available_until_value: Variant = definition.get(
			"available_until",
			null
		)
		var available_until_ok: bool = (
			available_until_value == null
			or typeof(available_until_value) == TYPE_INT
		)

		var efficiency_value: Variant = definition.get(
			"efficiency",
			null
		)
		var efficiency_ok: bool = (
			typeof(efficiency_value) == TYPE_FLOAT
			or typeof(efficiency_value) == TYPE_INT
		)

		var duration_value: Variant = definition.get(
			"duration",
			null
		)
		var duration_ok: bool = (
			typeof(duration_value) == TYPE_FLOAT
			or typeof(duration_value) == TYPE_INT
		)

		var reliability_value: Variant = definition.get(
			"reliability",
			null
		)
		var reliability_ok: bool = (
			typeof(reliability_value) == TYPE_FLOAT
			or typeof(reliability_value) == TYPE_INT
		)

		var map_fields_ok: bool = true

		for field_name in REQUIRED_MAP_FIELDS:
			var field_value: Variant = definition.get(
				field_name,
				null
			)

			if typeof(field_value) != TYPE_DICTIONARY:
				map_fields_ok = false

				TestLogger.write_line(
					"Production process map field is Dictionary | "
					+ process_id
					+ " -> "
					+ field_name
					+ ": FAIL"
				)

				_record_failure(
					"Invalid map field type for "
					+ process_id
					+ " -> "
					+ field_name
					+ " actual_type="
					+ str(typeof(field_value))
				)

		var process_ok: bool = (
			identity_ok
			and stage_ok
			and availability_ok
			and available_until_ok
			and efficiency_ok
			and duration_ok
			and reliability_ok
			and map_fields_ok
		)

		if not identity_ok:
			_record_failure(
				"Identity fields invalid for " + process_id
			)

		if not stage_ok:
			_record_failure(
				"production_stage must be numeric for "
				+ process_id
				+ " actual_type="
				+ str(typeof(stage_value))
			)

		if not availability_ok:
			_record_failure(
				"available_from must be numeric for "
				+ process_id
				+ " actual_type="
				+ str(typeof(available_from_value))
			)

		if not available_until_ok:
			_record_failure(
				"available_until type invalid for "
				+ process_id
				+ " actual_type="
				+ str(typeof(available_until_value))
			)

		if not efficiency_ok:
			_record_failure(
				"efficiency type invalid for "
				+ process_id
				+ " actual_type="
				+ str(typeof(efficiency_value))
			)

		if not duration_ok:
			_record_failure(
				"duration type invalid for "
				+ process_id
				+ " actual_type="
				+ str(typeof(duration_value))
			)

		if not reliability_ok:
			_record_failure(
				"reliability type invalid for "
				+ process_id
				+ " actual_type="
				+ str(typeof(reliability_value))
			)

		semantic_shape_ok = (
			semantic_shape_ok
			and process_ok
		)

	TestLogger.write_line(
		"Loaded production process definitions have normalized runtime shape: "
		+ ("PASS" if semantic_shape_ok else "FAIL")
	)

	passed = passed and semantic_shape_ok

	var source_1950: Array = (
		source_catalog.get_available_process_ids(1950)
	)
	var runtime_1950: Array = (
		runtime_catalog.get_available_process_ids(1950)
	)

	var availability_1950_match: bool = (
		source_1950 == runtime_1950
	)

	TestLogger.write_line(
		"1950 availability resolution matches runtime/source catalogs: "
		+ ("PASS" if availability_1950_match else "FAIL")
	)

	if not availability_1950_match:
		_record_failure(
			"1950 availability mismatch. Source="
			+ str(source_1950)
			+ " Runtime="
			+ str(runtime_1950)
		)

	passed = passed and availability_1950_match

	var source_1955: Array = (
		source_catalog.get_available_process_ids(1955)
	)
	var runtime_1955: Array = (
		runtime_catalog.get_available_process_ids(1955)
	)

	var availability_1955_match: bool = (
		source_1955 == runtime_1955
	)

	TestLogger.write_line(
		"1955 availability resolution matches runtime/source catalogs: "
		+ ("PASS" if availability_1955_match else "FAIL")
	)

	if not availability_1955_match:
		_record_failure(
			"1955 availability mismatch. Source="
			+ str(source_1955)
			+ " Runtime="
			+ str(runtime_1955)
		)

	passed = passed and availability_1955_match

	var extraction_definition_ok: bool = true
	var transformation_definition_ok: bool = true

	for process_id in source_ids:
		var definition: Dictionary = (
			source_catalog.get_process(process_id)
		)

		var category: String = str(
			definition.get("category", "")
		)

		var inputs_value: Variant = definition.get(
			"inputs",
			{}
		)

		var outputs_value: Variant = definition.get(
			"outputs",
			{}
		)

		var inputs: Dictionary = (
			inputs_value
			if typeof(inputs_value) == TYPE_DICTIONARY
			else {}
		)

		var outputs: Dictionary = (
			outputs_value
			if typeof(outputs_value) == TYPE_DICTIONARY
			else {}
		)

		if category == "extraction":
			var extraction_ok: bool = (
				inputs.is_empty()
				and not outputs.is_empty()
			)

			extraction_definition_ok = (
				extraction_definition_ok
				and extraction_ok
			)

			if not extraction_ok:
				_record_failure(
					"Extraction boundary invalid for "
					+ process_id
					+ " inputs="
					+ str(inputs)
					+ " outputs="
					+ str(outputs)
				)

				TestLogger.write_line(
					"Extraction process keeps extraction boundary shape | "
					+ process_id
					+ ": FAIL"
				)
		else:
			var transformation_ok: bool = (
				not outputs.is_empty()
			)

			transformation_definition_ok = (
				transformation_definition_ok
				and transformation_ok
			)

			if not transformation_ok:
				_record_failure(
					"Non-extraction process has no executable outputs: "
					+ process_id
				)

				TestLogger.write_line(
					"Non-extraction process has executable outputs | "
					+ process_id
					+ ": FAIL"
				)

	TestLogger.write_line(
		"Extraction process definitions preserve extraction boundary: "
		+ ("PASS" if extraction_definition_ok else "FAIL")
	)

	TestLogger.write_line(
		"Non-extraction definitions preserve transformational output semantics: "
		+ ("PASS" if transformation_definition_ok else "FAIL")
	)

	passed = (
		passed
		and extraction_definition_ok
		and transformation_definition_ok
	)

	if not passed and _last_failure_reason.is_empty():
		_record_failure(
			"Integration validation failed without a more specific diagnostic."
		)

	TestLogger.write_line(
		"Production Process Catalog ↔ runtime integration: "
		+ ("PASS" if passed else "FAIL")
	)

	TestLogger.write_line(
		"ProductionProcessCatalogRuntimeIntegrationTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
