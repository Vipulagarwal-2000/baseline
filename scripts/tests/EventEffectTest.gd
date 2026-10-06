class_name EventEffectTest
extends RefCounted


static func run() -> bool:
	TestLogger.section(
		"EventEffect — E6 Effect Model"
	)

	var all_passed := true


	# ============================================================
	# CONSTRUCTION
	# ============================================================

	var effect := EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var construction_passed := (
		effect != null
		and effect.path == "government.stability"
		and effect.operation == EventEffect.OPERATION_ADD
		and is_equal_approx(effect.value, 0.10)
	)

	TestLogger.write_line(
		"Effect construction and field storage: "
		+ ("PASS" if construction_passed else "FAIL")
	)

	all_passed = all_passed and construction_passed


	# ============================================================
	# SUPPORTED OPERATIONS
	# ============================================================

	var operations_passed := (
		EventEffect.is_supported_operation(EventEffect.OPERATION_SET)
		and EventEffect.is_supported_operation(EventEffect.OPERATION_ADD)
		and EventEffect.is_supported_operation(EventEffect.OPERATION_SUBTRACT)
		and EventEffect.is_supported_operation(EventEffect.OPERATION_MULTIPLY)
		and EventEffect.get_supported_operations().size() == 4
	)

	TestLogger.write_line(
		"Supported operation validation: "
		+ ("PASS" if operations_passed else "FAIL")
	)

	all_passed = all_passed and operations_passed


	# ============================================================
	# VALID EFFECTS
	# ============================================================

	var set_effect := EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_SET,
		0.50
	)

	var add_effect := EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var subtract_effect := EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_SUBTRACT,
		0.10
	)

	var multiply_effect := EventEffect.new(
		"economy.tax_rate",
		EventEffect.OPERATION_MULTIPLY,
		0.90
	)

	var valid_effects_passed := (
		set_effect.is_valid()
		and add_effect.is_valid()
		and subtract_effect.is_valid()
		and multiply_effect.is_valid()
	)

	TestLogger.write_line(
		"Valid effect structures: "
		+ ("PASS" if valid_effects_passed else "FAIL")
	)

	all_passed = all_passed and valid_effects_passed


	# ============================================================
	# INVALID OPERATION
	# ============================================================

	var invalid_operation := EventEffect.new(
		"government.stability",
		"divide",
		2.0
	)

	var invalid_operation_passed := (
		not invalid_operation.is_valid()
		and not EventEffect.is_supported_operation("divide")
	)

	TestLogger.write_line(
		"Invalid operation rejection: "
		+ ("PASS" if invalid_operation_passed else "FAIL")
	)

	all_passed = all_passed and invalid_operation_passed


	# ============================================================
	# INVALID PATH
	# ============================================================

	var invalid_path := EventEffect.new(
		"",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var invalid_path_passed := not invalid_path.is_valid()

	TestLogger.write_line(
		"Empty path rejection: "
		+ ("PASS" if invalid_path_passed else "FAIL")
	)

	all_passed = all_passed and invalid_path_passed


	# ============================================================
	# INVALID NUMERIC OPERAND
	# ============================================================

	var invalid_numeric := EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		"0.10"
	)

	var invalid_numeric_passed := not invalid_numeric.is_valid()

	TestLogger.write_line(
		"Invalid arithmetic operand rejection: "
		+ ("PASS" if invalid_numeric_passed else "FAIL")
	)

	all_passed = all_passed and invalid_numeric_passed


	# ============================================================
	# E6 MUST NOT EXECUTE / MUTATE WORLD
	# ============================================================

	# EventEffect is deliberately only a data object.
	# No WorldState or SimulationEngine is accepted by this API.
	var data_only_passed := (
		effect.get_property_list().size() > 0
		and not effect.get_property_list().any(
			func(property): return property.name == "world"
		)
	)

	TestLogger.write_line(
		"Effect model remains declarative with no world execution: "
		+ ("PASS" if data_only_passed else "FAIL")
	)

	all_passed = all_passed and data_only_passed


	TestLogger.write_line(
		"E6 Effect Model test: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
