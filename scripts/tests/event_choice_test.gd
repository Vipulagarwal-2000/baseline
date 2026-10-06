class_name EventChoiceTest
extends RefCounted


# ============================================================
# E9 — CHOICES TEST
# ============================================================
#
# Required acceptance:
# - choice creation
# - choice conditions
# - selected choice effect
# - unselected choice effect absent
# - blocked choice
# - multiple choices
#
# Synthetic branches:
#
# Choice A:
#   government.stability += 0.10
#
# Choice B:
#   government.approval += 0.20
#
# The selected branch alone may execute.
# ============================================================


static func run() -> bool:
	TestLogger.section(
		"EventChoiceExecutor — E9 Choices"
	)

	var test_passed: bool = true

	var fixture: Dictionary = _create_fixture()
	var world: WorldState = fixture.get("world") as WorldState
	var target: SimEntity = fixture.get("target") as SimEntity
	var definition: EventDefinition = (
		fixture.get("definition") as EventDefinition
	)

	var fixture_available: bool = (
		world != null
		and target != null
		and definition != null
		and target.get_component("government") != null
	)

	TestLogger.write_line(
		"E9 choice execution fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	var government: GovernmentComponent = (
		target.get_component("government")
	)

	# ------------------------------------------------------------
	# CHOICE CREATION
	# ------------------------------------------------------------

	var choice_a_condition: EventCondition = EventCondition.new(
		"government.stability",
		EventCondition.OPERATOR_LESS,
		0.50
	)

	var choice_a_effect: EventEffect = EventEffect.new(
		"government.stability",
		EventEffect.OPERATION_ADD,
		0.10
	)

	var choice_b_condition: EventCondition = EventCondition.new(
		"government.approval",
		EventCondition.OPERATOR_GREATER_EQUAL,
		0.50
	)

	var choice_b_effect: EventEffect = EventEffect.new(
		"government.approval",
		EventEffect.OPERATION_ADD,
		0.20
	)

	var choice_a: EventChoice = EventChoice.new(
		"choice_a",
		"Stabilize",
		"Increase stability.",
		[choice_a_condition],
		[choice_a_effect]
	)

	var choice_b: EventChoice = EventChoice.new(
		"choice_b",
		"Approve",
		"Increase approval.",
		[choice_b_condition],
		[choice_b_effect]
	)

	var choice_creation_pass: bool = (
		choice_a.is_valid()
		and choice_b.is_valid()
		and choice_a.id == "choice_a"
		and choice_b.id == "choice_b"
	)

	TestLogger.write_line(
		"Choice creation and validation: "
		+ ("PASS" if choice_creation_pass else "FAIL")
	)

	if not choice_creation_pass:
		test_passed = false

	var choices: Array = [
		choice_a,
		choice_b,
	]

	# ------------------------------------------------------------
	# SELECT CHOICE A
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)

	var approval_before_a: float = float(
		government.get_state("approval")
	)

	var choice_a_result: EventChoiceResult = (
		EventChoiceExecutor.execute_selected_choice(
			definition,
			choices,
			"choice_a",
			world,
			target.id
		)
	)

	var choice_a_pass: bool = (
		choice_a_result != null
		and choice_a_result.status
			== EventChoiceResult.STATUS_EXECUTED
		and choice_a_result.eligible
		and choice_a_result.effects_executed
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
		"Selected choice A executes its effect: "
		+ ("PASS" if choice_a_pass else "FAIL")
	)

	if not choice_a_pass:
		test_passed = false

	# ------------------------------------------------------------
	# UNSELECTED CHOICE B REMAINS ABSENT
	# ------------------------------------------------------------

	var unselected_b_pass: bool = is_equal_approx(
		float(government.get_state("approval")),
		approval_before_a
	)

	TestLogger.write_line(
		"Unselected choice B effect remains unapplied: "
		+ ("PASS" if unselected_b_pass else "FAIL")
	)

	if not unselected_b_pass:
		test_passed = false

	# ------------------------------------------------------------
	# SELECT CHOICE B
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)

	var stability_before_b: float = float(
		government.get_state("stability")
	)

	var choice_b_result: EventChoiceResult = (
		EventChoiceExecutor.execute_selected_choice(
			definition,
			choices,
			"choice_b",
			world,
			target.id
		)
	)

	var choice_b_pass: bool = (
		choice_b_result != null
		and choice_b_result.status
			== EventChoiceResult.STATUS_EXECUTED
		and choice_b_result.eligible
		and choice_b_result.effects_executed
		and is_equal_approx(
			float(government.get_state("approval")),
			0.80
		)
		and is_equal_approx(
			float(government.get_state("stability")),
			stability_before_b
		)
	)

	TestLogger.write_line(
		"Selected choice B executes only its effect: "
		+ ("PASS" if choice_b_pass else "FAIL")
	)

	if not choice_b_pass:
		test_passed = false

	# ------------------------------------------------------------
	# BLOCKED CHOICE
	# ------------------------------------------------------------

	government.set_state("stability", 0.70)
	government.set_state("approval", 0.60)

	var stability_before_blocked: float = float(
		government.get_state("stability")
	)
	var approval_before_blocked: float = float(
		government.get_state("approval")
	)

	var blocked_result: EventChoiceResult = (
		EventChoiceExecutor.execute_selected_choice(
			definition,
			choices,
			"choice_a",
			world,
			target.id
		)
	)

	var blocked_pass: bool = (
		blocked_result != null
		and blocked_result.status
			== EventChoiceResult.STATUS_BLOCKED
		and not blocked_result.eligible
		and not blocked_result.effects_executed
		and is_equal_approx(
			float(government.get_state("stability")),
			stability_before_blocked
		)
		and is_equal_approx(
			float(government.get_state("approval")),
			approval_before_blocked
		)
	)

	TestLogger.write_line(
		"Blocked choice executes no effect: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	if not blocked_pass:
		test_passed = false

	# ------------------------------------------------------------
	# INVALID / MISSING CHOICE
	# ------------------------------------------------------------

	var missing_result: EventChoiceResult = (
		EventChoiceExecutor.execute_selected_choice(
			definition,
			choices,
			"missing_choice",
			world,
			target.id
		)
	)

	var missing_pass: bool = (
		missing_result != null
		and missing_result.status
			== EventChoiceResult.STATUS_REJECTED
		and not missing_result.effects_executed
	)

	TestLogger.write_line(
		"Missing selected choice is rejected safely: "
		+ ("PASS" if missing_pass else "FAIL")
	)

	if not missing_pass:
		test_passed = false

	# ------------------------------------------------------------
	# MULTIPLE CHOICES REMAIN ISOLATED
	# ------------------------------------------------------------

	var multiple_isolation_pass: bool = (
		choice_a.id != choice_b.id
		and choice_a.effects != choice_b.effects
		and choice_a.conditions != choice_b.conditions
	)

	TestLogger.write_line(
		"Multiple choices remain branch-isolated: "
		+ ("PASS" if multiple_isolation_pass else "FAIL")
	)

	if not multiple_isolation_pass:
		test_passed = false

	TestLogger.write_line(
		"E9 Choices test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed


static func _create_fixture() -> Dictionary:
	var config: SimulationConfig = SimulationConfig.create_default()
	var world: WorldState = WorldState.new(config)

	var target: SimEntity = SimEntity.new(
		"e9_choice_test_country",
		"E9 Choice Test Country",
		"country"
	)

	var government: GovernmentComponent = GovernmentComponent.new(
		target.id
	)

	target.add_component(government)
	world.add_entity(target)

	var definition: EventDefinition = EventDefinition.new(
		"test_choice_event",
		"Test Choice Event",
		"Synthetic E9 choice test event.",
		"political",
		"country"
	)

	return {
		"world": world,
		"target": target,
		"definition": definition,
	}
