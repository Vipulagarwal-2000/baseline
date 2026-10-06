class_name EventTriggerEvaluatorTest
extends RefCounted


# ============================================================
# E5 — EVENT TRIGGER EVALUATION TEST
# ============================================================
#
# Scope:
#   Verify that EventTriggerEvaluator can answer whether an event is
#   eligible from authoritative component state without executing,
#   mutating, recording, or advancing anything.
#
# Required acceptance cases:
#   - eligible event
#   - blocked event
#   - condition boundary
#   - multiple conditions
#   - no-world-mutation proof
#
# The fixture is synthetic and isolated from historical event content.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"Event Trigger Evaluation — E5"
	)

	var test_passed := true

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)
	TestLogger.write_line(
		"Simulation available: PASS"
	)

	var fixture := _create_fixture()
	var test_world: WorldState = fixture.get("world") as WorldState
	var target: SimEntity = fixture.get("target") as SimEntity
	var definition: EventDefinition = fixture.get("definition") as EventDefinition

	var fixture_available := (
		test_world != null
		and target != null
		and definition != null
	)

	TestLogger.write_line(
		"E5 trigger fixture available: "
		+ ("PASS" if fixture_available else "FAIL")
	)

	if not fixture_available:
		return false

	# ------------------------------------------------------------
	# 1. ELIGIBLE EVENT
	# ------------------------------------------------------------

	var stability_condition := EventCondition.new(
		"government.stability",
		"<",
		0.50
	)

	# The fixture starts at 0.70; make the eligible case explicit
	# through authoritative component state before evaluating.
	var government = target.get_component("government")
	government.set_state("stability", 0.40)

	var eligible_result := EventTriggerEvaluator.evaluate(
		definition,
		stability_condition,
		test_world,
		target.id
	)

	var eligible_pass := eligible_result

	TestLogger.write_line(
		"Eligible event condition evaluates true: "
		+ ("PASS" if eligible_pass else "FAIL")
	)

	if not eligible_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 2. BLOCKED EVENT
	# ------------------------------------------------------------

	government.set_state("stability", 0.70)

	var blocked_result := EventTriggerEvaluator.evaluate(
		definition,
		stability_condition,
		test_world,
		target.id
	)

	var blocked_pass := not blocked_result

	TestLogger.write_line(
		"Blocked event condition evaluates false: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	if not blocked_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 3. CONDITION BOUNDARY
	# ------------------------------------------------------------

	government.set_state("stability", 0.50)

	var boundary_result := EventTriggerEvaluator.evaluate(
		definition,
		stability_condition,
		test_world,
		target.id
	)

	var boundary_pass := not boundary_result

	TestLogger.write_line(
		"Strict comparison boundary 0.50 < 0.50 is false: "
		+ ("PASS" if boundary_pass else "FAIL")
	)

	if not boundary_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 4. MULTIPLE CONDITIONS — IMPLICIT AND
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.60)

	var combined_conditions: Array = [
		EventCondition.new(
			"government.stability",
			"<",
			0.50
		),
		EventCondition.new(
			"government.approval",
			">=",
			0.60
		)
	]

	var multiple_true := EventTriggerEvaluator.evaluate_conditions(
		definition,
		combined_conditions,
		test_world,
		target.id
	)

	var multiple_true_pass := multiple_true

	TestLogger.write_line(
		"Multiple conditions all true → eligible: "
		+ ("PASS" if multiple_true_pass else "FAIL")
	)

	if not multiple_true_pass:
		test_passed = false

	government.set_state("approval", 0.59)

	var multiple_blocked := EventTriggerEvaluator.evaluate_conditions(
		definition,
		combined_conditions,
		test_world,
		target.id
	)

	var multiple_blocked_pass := not multiple_blocked

	TestLogger.write_line(
		"Multiple conditions with one false → blocked: "
		+ ("PASS" if multiple_blocked_pass else "FAIL")
	)

	if not multiple_blocked_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 5. NESTED LOGICAL CONDITION
	# ------------------------------------------------------------

	government.set_state("stability", 0.40)
	government.set_state("approval", 0.59)

	var nested_condition := EventCondition.create_logical(
		EventCondition.LOGICAL_OR,
		[
			EventCondition.new(
				"government.stability",
				"<",
				0.50
			),
			EventCondition.create_logical(
				EventCondition.LOGICAL_AND,
				[
					EventCondition.new(
						"government.approval",
						">=",
						0.60
					),
					EventCondition.new(
						"government.stability",
						">",
						0.30
					)
				]
			)
		]
	)

	var nested_result := EventTriggerEvaluator.evaluate(
		definition,
		nested_condition,
		test_world,
		target.id
	)

	var nested_pass := nested_result

	TestLogger.write_line(
		"Nested logical condition resolves against world state: "
		+ ("PASS" if nested_pass else "FAIL")
	)

	if not nested_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 6. INVALID / MISSING PATH SAFETY
	# ------------------------------------------------------------

	var invalid_path_condition := EventCondition.new(
		"government.missing_state",
		"==",
		true
	)

	var invalid_path_result := EventTriggerEvaluator.evaluate(
		definition,
		invalid_path_condition,
		test_world,
		target.id
	)

	var invalid_path_pass := not invalid_path_result

	TestLogger.write_line(
		"Missing state path blocks evaluation safely: "
		+ ("PASS" if invalid_path_pass else "FAIL")
	)

	if not invalid_path_pass:
		test_passed = false

	# ------------------------------------------------------------
	# 7. NO-WORLD-MUTATION PROOF
	# ------------------------------------------------------------

	var state_before: Dictionary = (
		government.state.duplicate(true)
	)
	var entity_count_before: int = test_world.entities.size()
	var target_id_before: String = target.id

	EventTriggerEvaluator.evaluate(
		definition,
		stability_condition,
		test_world,
		target.id
	)

	var state_after: Dictionary = (
		government.state.duplicate(true)
	)

	var no_mutation_pass := (
		state_before == state_after
		and entity_count_before == test_world.entities.size()
		and target_id_before == target.id
	)

	TestLogger.write_line(
		"Trigger evaluation leaves world state unchanged: "
		+ ("PASS" if no_mutation_pass else "FAIL")
	)

	if not no_mutation_pass:
		test_passed = false

	TestLogger.write_line(
		"E5 Event Trigger Evaluation test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed


# ============================================================
# SYNTHETIC FIXTURE
# ============================================================

static func _create_fixture() -> Dictionary:

	var config: SimulationConfig = SimulationConfig.create_default()
	var test_world: WorldState = WorldState.new(config)

	var target: SimEntity = SimEntity.new(
		"e5_trigger_test_country",
		"E5 Trigger Test Country",
		"country"
	)

	var government := GovernmentComponent.new(target.id)
	target.add_component(government)
	test_world.add_entity(target)

	var definition := EventDefinition.new()
	definition.id = "e5_trigger_test_event"
	definition.name = "E5 Trigger Test Event"
	definition.description = "Synthetic E5 trigger evaluation event."
	definition.category = "political"
	definition.scope = "country"

	return {
		"world": test_world,
		"target": target,
		"definition": definition
	}
