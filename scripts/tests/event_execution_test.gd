class_name EventExecutionTest
extends RefCounted


# ============================================================
# E8 — EVENT EXECUTION TEST
# ============================================================
#
# Synthetic event:
#   government.stability < 0.50
#       ↓
#   government.stability += 0.10
#
# Required proof:
#   0.40 → eligible → 0.50
#   0.70 → blocked  → 0.70
#
# Also verifies:
# - EventResult is produced
# - blocked events do not execute effects
# - failed effect execution is represented as failed
# - unrelated state is preserved
# ============================================================


static func run() -> bool:
	TestLogger.section(
		"EventExecutor — E8 Event Execution"
	)

	var test_passed: bool = true

	var fixture: Dictionary = _create_fixture()
	var world: WorldState = fixture.get("world") as WorldState
	var target: SimEntity = fixture.get("target") as SimEntity

	var fixture_available: bool = (
		world != null
		and target != null
		and target.get_component("government") != null
	)

	TestLogger.write_line(
		"E8 execution fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	var government: GovernmentComponent = target.get_component("government")

	# ------------------------------------------------------------
	# SYNTHETIC EVENT DEFINITION
	# ------------------------------------------------------------

	var definition: EventDefinition = EventDefinition.new(
		"test_stability_event",
		"Test Stability Event",
		"Synthetic E8 event execution test.",
		"political",
		"country"
	)

	var definition_pass: bool = (
		not definition.id.strip_edges().is_empty()
		and not definition.name.strip_edges().is_empty()
		and not definition.category.strip_edges().is_empty()
		and not definition.scope.strip_edges().is_empty()
	)

	TestLogger.write_line(
		"Synthetic EventDefinition satisfies E2/E3 identity contract: "
		+ ("PASS" if definition_pass else "FAIL")
	)

	if not definition_pass:
		test_passed = false

	var stability_condition: EventCondition = EventCondition.new(
		"government.stability",
		EventCondition.OPERATOR_LESS,
		0.50
	)

	var stability_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var conditions: Array = [stability_condition]
	var effects: Array = [stability_effect]

	# ------------------------------------------------------------
	# TEST A — ELIGIBLE EVENT
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)

	var approval_before_a: float = float(
		government.get_state("approval")
	)

	var eligible_result: EventResult = EventExecutor.execute(
		definition,
		conditions,
		effects,
		world,
		target.id
	)

	var eligible_pass: bool = (
		eligible_result != null
		and eligible_result.status == EventResult.STATUS_EXECUTED
		and eligible_result.eligible
		and eligible_result.effects_executed
		and is_equal_approx(
			float(government.get_state("stability")),
			0.50
		)
		and is_equal_approx(
			float(government.get_state("approval")),
			approval_before_a
		)
	)

	TestLogger.write_line(
		"Eligible event executes 0.40 → 0.50: "
		+ ("PASS" if eligible_pass else "FAIL")
	)

	if not eligible_pass:
		test_passed = false

	# ------------------------------------------------------------
	# TEST B — BLOCKED EVENT
	# ------------------------------------------------------------

	government.set_state("stability", 0.70)

	var approval_before_b: float = float(
		government.get_state("approval")
	)

	var blocked_result: EventResult = EventExecutor.execute(
		definition,
		conditions,
		effects,
		world,
		target.id
	)

	var blocked_pass: bool = (
		blocked_result != null
		and blocked_result.status == EventResult.STATUS_BLOCKED
		and not blocked_result.eligible
		and not blocked_result.effects_executed
		and is_equal_approx(
			float(government.get_state("stability")),
			0.70
		)
		and is_equal_approx(
			float(government.get_state("approval")),
			approval_before_b
		)
	)

	TestLogger.write_line(
		"Blocked event preserves 0.70: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	if not blocked_pass:
		test_passed = false

	# ------------------------------------------------------------
	# TEST C — EVENT RESULT IDENTITY
	# ------------------------------------------------------------

	var result_identity_pass: bool = (
		eligible_result.event_id == "test_stability_event"
		and eligible_result.target_id == target.id
		and blocked_result.event_id == "test_stability_event"
		and blocked_result.target_id == target.id
	)

	TestLogger.write_line(
		"EventResult carries event and target identity: "
		+ ("PASS" if result_identity_pass else "FAIL")
	)

	if not result_identity_pass:
		test_passed = false

	# ------------------------------------------------------------
	# TEST D — EFFECT FAILURE DOES NOT CLAIM EXECUTION
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)

	var invalid_effect: EventEffect = EventEffect.new(
		"government.missing_state",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var failed_result: EventResult = EventExecutor.execute(
		definition,
		conditions,
		[invalid_effect],
		world,
		target.id
	)

	var failure_pass: bool = (
		failed_result != null
		and failed_result.status == EventResult.STATUS_FAILED
		and failed_result.eligible
		and not failed_result.effects_executed
		and failed_result.failure_reason == "effect_execution_failed"
		and is_equal_approx(
			float(government.get_state("stability")),
			0.40
		)
	)

	TestLogger.write_line(
		"Eligible event reports effect failure without false success: "
		+ ("PASS" if failure_pass else "FAIL")
	)

	if not failure_pass:
		test_passed = false

	TestLogger.write_line(
		"E8 Event Execution test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	var world: WorldState = WorldState.new(config)

	var target: SimEntity = SimEntity.new(
		"e8_event_execution_test_country",
		"E8 Event Execution Test Country",
		"country"
	)

	var government: GovernmentComponent = GovernmentComponent.new(
		target.id
	)

	target.add_component(government)
	world.add_entity(target)

	return {
		"world": world,
		"target": target,
	}
