class_name EventEffectExecutionTest
extends RefCounted


# ============================================================
# E7 — EFFECT EXECUTION TEST
# ============================================================
#
# Scope:
#   Verify that EventEffectExecutor applies validated effects to
#   authoritative component state and rejects invalid execution
#   without partial mutation.
#
# Required acceptance cases from E7:
#   - valid path
#   - invalid path
#   - missing target
#   - invalid numeric operation
#   - correct result
#   - unrelated state unchanged
#   - multiple effects
# ============================================================


static func run() -> bool:

	TestLogger.section(
		"EventEffectExecutor — E7 Effect Execution"
	)

	var test_passed: bool = true

	var fixture: Dictionary = _create_fixture()
	var world: WorldState = fixture.get("world") as WorldState
	var target: SimEntity = fixture.get("target") as SimEntity
	var government = target.get_component("government") if target != null else null

	var fixture_available: bool = (
		world != null
		and target != null
		and government != null
	)

	TestLogger.write_line(
		"E7 execution fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	# ------------------------------------------------------------
	# 1. VALID PATH / ADD
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)

	var add_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var add_pass: bool = EventEffectExecutor.execute(
		add_effect,
		world,
		target.id
	)

	var add_result_pass: bool = (
		add_pass
		and is_equal_approx(
			float(government.get_state("stability")),
			0.50
		)
	)

	TestLogger.write_line(
		"Valid path / add operation executes correctly: "
		+ ("PASS" if add_result_pass else "FAIL")
	)

	if not add_result_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 2. SUBTRACT
	# ------------------------------------------------------------

	government.set_state("stability", 0.50)

	var subtract_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_SUBTRACT,
		0.10
	)

	var subtract_pass: bool = EventEffectExecutor.execute(
		subtract_effect,
		world,
		target.id
	)

	var subtract_result_pass: bool = (
		subtract_pass
		and is_equal_approx(
			float(government.get_state("stability")),
			0.40
		)
	)

	TestLogger.write_line(
		"Subtract operation executes correctly: "
		+ ("PASS" if subtract_result_pass else "FAIL")
	)

	if not subtract_result_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 3. MULTIPLY
	# ------------------------------------------------------------

	government.set_state("approval", 0.60)

	var multiply_effect: EventEffect = EventEffect.new(
		"government.approval",
		EventEffect.OPERATION_MULTIPLY,
		0.50
	)

	var multiply_pass: bool = EventEffectExecutor.execute(
		multiply_effect,
		world,
		target.id
	)

	var multiply_result_pass: bool = (
		multiply_pass
		and is_equal_approx(
			float(government.get_state("approval")),
			0.30
		)
	)

	TestLogger.write_line(
		"Multiply operation executes correctly: "
		+ ("PASS" if multiply_result_pass else "FAIL")
	)

	if not multiply_result_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 4. SET
	# ------------------------------------------------------------

	var set_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_SET,
		0.75
	)

	var set_pass: bool = EventEffectExecutor.execute(
		set_effect,
		world,
		target.id
	)

	var set_result_pass: bool = (
		set_pass
		and is_equal_approx(
			float(government.get_state("stability")),
			0.75
		)
	)

	TestLogger.write_line(
		"Set operation executes correctly: "
		+ ("PASS" if set_result_pass else "FAIL")
	)

	if not set_result_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 5. INVALID PATH
	# ------------------------------------------------------------

	var state_before_invalid_path: Dictionary = (
		government.state.duplicate(true)
	)

	var invalid_path_effect: EventEffect = EventEffect.new(
		"government.missing_state",
		EventEffect.OPERATION_ADD,
		1.0
	)

	var invalid_path_result: bool = EventEffectExecutor.execute(
		invalid_path_effect,
		world,
		target.id
	)

	var invalid_path_pass: bool = (
		not invalid_path_result
		and government.state == state_before_invalid_path
	)

	TestLogger.write_line(
		"Invalid path is rejected without state mutation: "
		+ ("PASS" if invalid_path_pass else "FAIL")
	)

	if not invalid_path_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 6. MISSING TARGET
	# ------------------------------------------------------------

	var state_before_missing_target: Dictionary = (
		government.state.duplicate(true)
	)

	var missing_target_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		1.0
	)

	var missing_target_result: bool = EventEffectExecutor.execute(
		missing_target_effect,
		world,
		"missing_e7_target"
	)

	var missing_target_pass: bool = (
		not missing_target_result
		and government.state == state_before_missing_target
	)

	TestLogger.write_line(
		"Missing target is rejected without state mutation: "
		+ ("PASS" if missing_target_pass else "FAIL")
	)

	if not missing_target_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 7. INVALID NUMERIC OPERATION
	# ------------------------------------------------------------

	government.set_state("government_type", "default")

	var invalid_numeric_effect: EventEffect = EventEffect.new(
		"government.government_type",
		EventEffect.OPERATION_ADD,
		1.0
	)

	var invalid_numeric_result: bool = EventEffectExecutor.execute(
		invalid_numeric_effect,
		world,
		target.id
	)

	var invalid_numeric_pass: bool = (
		not invalid_numeric_result
		and government.get_state("government_type") == "default"
	)

	TestLogger.write_line(
		"Invalid numeric operation is rejected without mutation: "
		+ ("PASS" if invalid_numeric_pass else "FAIL")
	)

	if not invalid_numeric_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 8. UNRELATED STATE UNCHANGED
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)
	government.set_state("political_pressure", 0.30)

	var unrelated_before = government.get_state(
		"political_pressure"
	)

	var unrelated_test_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var unrelated_execution: bool = EventEffectExecutor.execute(
		unrelated_test_effect,
		world,
		target.id
	)

	var unrelated_pass: bool = (
		unrelated_execution
		and is_equal_approx(
			float(government.get_state("stability")),
			0.50
		)
		and is_equal_approx(
			float(government.get_state("political_pressure")),
			float(unrelated_before)
		)
	)

	TestLogger.write_line(
		"Unrelated state remains unchanged: "
		+ ("PASS" if unrelated_pass else "FAIL")
	)

	if not unrelated_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 9. MULTIPLE EFFECTS
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)
	government.set_state("political_pressure", 0.30)

	var multiple_effects: Array = [
		EventEffect.new(
			"government.stability",
			EventEffect.OPERATION_ADD,
			0.10
		),
		EventEffect.new(
			"government.approval",
			EventEffect.OPERATION_SUBTRACT,
			0.10
		),
		EventEffect.new(
			"government.political_pressure",
			EventEffect.OPERATION_MULTIPLY,
			2.0
		),
	]

	var multiple_result: bool = EventEffectExecutor.execute_effects(
		multiple_effects,
		world,
		target.id
	)

	var multiple_pass: bool = (
		multiple_result
		and is_equal_approx(
			float(government.get_state("stability")),
			0.50
		)
		and is_equal_approx(
			float(government.get_state("approval")),
			0.50
		)
		and is_equal_approx(
			float(government.get_state("political_pressure")),
			0.60
		)
	)

	TestLogger.write_line(
		"Multiple effects execute together correctly: "
		+ ("PASS" if multiple_pass else "FAIL")
	)

	if not multiple_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 10. MULTIPLE-EFFECT PREVALIDATION / NO PARTIAL MUTATION
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)

	var prevalidation_before: Dictionary = (
		government.state.duplicate(true)
	)

	var invalid_batch: Array = [
		EventEffect.new(
			"government.stability",
			EventEffect.OPERATION_ADD,
			0.10
		),
		EventEffect.new(
			"government.missing_state",
			EventEffect.OPERATION_SET,
			0.0
		),
	]

	var invalid_batch_result: bool = EventEffectExecutor.execute_effects(
		invalid_batch,
		world,
		target.id
	)

	var invalid_batch_pass: bool = (
		not invalid_batch_result
		and government.state == prevalidation_before
	)

	TestLogger.write_line(
		"Invalid effect batch is rejected without partial mutation: "
		+ ("PASS" if invalid_batch_pass else "FAIL")
	)

	if not invalid_batch_pass:
		test_passed = false


	TestLogger.write_line(
		"E7 Effect Execution test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed


# ============================================================
# SYNTHETIC FIXTURE
# ============================================================

static func _create_fixture() -> Dictionary:

	var config: SimulationConfig = SimulationConfig.create_default()
	var world: WorldState = WorldState.new(config)

	var target: SimEntity = SimEntity.new(
		"e7_effect_test_country",
		"E7 Effect Test Country",
		"country"
	)

	var government: GovernmentComponent = GovernmentComponent.new(target.id)
	target.add_component(government)
	world.add_entity(target)

	return {
		"world": world,
		"target": target,
	}
