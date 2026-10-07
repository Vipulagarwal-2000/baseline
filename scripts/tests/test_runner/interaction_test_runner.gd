class_name InteractionTestRunner
extends RefCounted


# ============================================================
# INTERACTION TEST RUNNER
# ============================================================
#
# Step 8 — action / concurrency interaction validation.
#
# Scope:
#   Step 15.1–15.15
#   Step 16.1–16.7
#
# This runner intentionally excludes:
#   - Phase 3 data/governance
#   - domain-specific economy/resource/government tests
#   - feedback runner (17.x)
#   - campaign runner (18.x)
#   - causal runner (19.x)
#
# It requires the live WorldState + SimulationEngine because the interaction
# tests validate the authoritative action path.
#
# Existing RunAllTests remains unchanged in this step. The runner is created
# first and will be integrated only after standalone verification.
# ============================================================


const RUNNER_ID := "interaction"
const DISPLAY_NAME := "Interaction Test Runner"

const EXPECTED_TEST_COUNT := 22


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> TestRunResult:

	var result := TestRunResult.new(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.start_scope(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.section(
		"INTERACTION TEST RUNNER"
	)

	TestLogger.write_line(
		"Action and concurrent-action interaction validation"
	)

	TestLogger.section(
		"STEP 15.1–15.15 — ACTION CONTRACT / EXECUTION"
	)
	_record(
		result,
		"Step 15.1 Action Contract",
		ActionContractTest.run(),
		"res://scripts/tests/ActionContractTest.gd",
		"Action contract validation returned FAIL.",
		"Inspect the common executable action contract and its alias/state fields."
	)

	_record(
		result,
		"Step 15.2 Decision → Action Conversion",
		DecisionActionConversionTest.run(world, simulation),
		"res://scripts/tests/DecisionActionConversionTest.gd",
		"Decision-to-action conversion validation returned FAIL.",
		"Inspect the shared DecisionOption → SimAction conversion path."
	)

	_record(
		result,
		"Step 15.3 ACTIONS Phase → ActionManager Execution",
		ActionPhaseExecutionTest.run(world, simulation),
		"res://scripts/tests/ActionPhaseExecutionTest.gd",
		"ACTIONS phase execution validation returned FAIL.",
		"Inspect ActionManager registration, ordering, and monthly action execution."
	)

	_record(
		result,
		"Step 15.4 Action Validation",
		ActionValidationTest.run(world, simulation),
		"res://scripts/tests/ActionValidationTest.gd",
		"Action validation returned FAIL.",
		"Inspect structural validation and explicit rejection reasons."
	)

	_record(
		result,
		"Step 15.5 Action Requirement Checks",
		ActionRequirementChecksTest.run(world, simulation),
		"res://scripts/tests/ActionRequirementChecksTest.gd",
		"Action requirement checks returned FAIL.",
		"Inspect resource, financial, capability, and capacity admission checks."
	)

	_record(
		result,
		"Step 15.6 Reservation / Commitment",
		ActionReservationCommitmentTest.run(world, simulation),
		"res://scripts/tests/ActionReservationCommitmentTest.gd",
		"Reservation/commitment validation returned FAIL.",
		"Inspect reservation admission, contention, commit, and release behavior."
	)

	_record(
		result,
		"Step 15.7 Duration / Monthly Progress",
		ActionDurationProgressTest.run(world, simulation),
		"res://scripts/tests/ActionDurationProgressTest.gd",
		"Action duration/progress validation returned FAIL.",
		"Inspect monthly progress and completion boundaries."
	)

	_record(
		result,
		"Step 15.8 Completion / World-State Change",
		ActionCompletionWorldStateTest.run(world, simulation),
		"res://scripts/tests/ActionCompletionWorldStateTest.gd",
		"Action completion world-state validation returned FAIL.",
		"Inspect authoritative completion effects and queue cleanup."
	)

	_record(
		result,
		"Step 15.9 Failure / Cancellation",
		ActionFailureCancellationTest.run(world, simulation),
		"res://scripts/tests/ActionFailureCancellationTest.gd",
		"Action failure/cancellation validation returned FAIL.",
		"Inspect cancellation, interruption, failure, and terminal-state behavior."
	)

	_record(
		result,
		"Step 15.10 Player / AI Parity",
		ActionPlayerAIParityTest.run(world, simulation),
		"res://scripts/tests/ActionPlayerAIParityTest.gd",
		"Player/AI action parity validation returned FAIL.",
		"Inspect shared player/AI executable action and resolution paths."
	)

	_record(
		result,
		"Step 15.11 Action Outcome / History",
		ActionOutcomeHistoryTest.run(world, simulation),
		"res://scripts/tests/ActionOutcomeHistoryTest.gd",
		"Action outcome/history validation returned FAIL.",
		"Inspect outcome ledger creation, uniqueness, and isolation."
	)

	_record(
		result,
		"Step 15.12 Action Snapshot Safety",
		ActionSnapshotSafetyTest.run(world, simulation),
		"res://scripts/tests/ActionSnapshotSafetyTest.gd",
		"Action snapshot safety validation returned FAIL.",
		"Inspect action snapshot capture, restore, and deep-copy isolation."
	)

	_record(
		result,
		"Step 15.13 AI Feedback",
		ActionAIFeedbackTest.run(world, simulation),
		"res://scripts/tests/ActionAIFeedbackTest.gd",
		"AI action feedback validation returned FAIL.",
		"Inspect completed-action feedback into AI memory and decision trajectory."
	)

	_record(
		result,
		"Step 15.14 Player-Issued Action Pathway",
		PlayerActionIssuanceTest.run(world, simulation),
		"res://scripts/tests/PlayerActionIssuanceTest.gd",
		"Player-issued action pathway validation returned FAIL.",
		"Inspect player issuance through the common ActionManager path."
	)

	_record(
		result,
		"Step 15.15 Action Execution End-to-End",
		ActionExecutionEndToEndTest.run(world, simulation),
		"res://scripts/tests/ActionExecutionEndToEndTest.gd",
		"End-to-end action execution validation returned FAIL.",
		"Inspect the shared player/AI action path through validation, execution, and outcomes."
	)

	TestLogger.section(
		"STEP 16.1–16.7 — CONCURRENT ACTIONS"
	)
	_record(
		result,
		"Step 16.1 Action Capacity",
		ActionCapacityTest.run(world, simulation),
		"res://scripts/tests/ActionCapacityTest.gd",
		"Concurrent action capacity validation returned FAIL.",
		"Inspect actor-level concurrent action capacity and release behavior."
	)

	_record(
		result,
		"Step 16.2 Concurrent Action Admission",
		ConcurrentActionAdmissionTest.run(world, simulation),
		"res://scripts/tests/ConcurrentActionAdmissionTest.gd",
		"Concurrent action admission validation returned FAIL.",
		"Inspect same-month concurrent admission and independent execution."
	)

	_record(
		result,
		"Step 16.3 Action Contention",
		ActionContentionTest.run(world, simulation),
		"res://scripts/tests/ActionContentionTest.gd",
		"Concurrent contention validation returned FAIL.",
		"Inspect resource, budget, capability, and domain-capacity reservations."
	)

	_record(
		result,
		"Step 16.4 Deterministic Action Resolution",
		DeterministicActionResolutionTest.run(world, simulation),
		"res://scripts/tests/DeterministicActionResolutionTest.gd",
		"Deterministic action resolution validation returned FAIL.",
		"Inspect priority ordering, admission order, and reservation stability."
	)

	_record(
		result,
		"Step 16.5 Cancellation / Interruption",
		ConcurrentActionCancellationTest.run(world, simulation),
		"res://scripts/tests/ConcurrentActionCancellationTest.gd",
		"Concurrent cancellation/interruption validation returned FAIL.",
		"Inspect sibling action preservation, reservation release, and terminal state."
	)

	_record(
		result,
		"Step 16.6 Concurrent Snapshot / Load",
		ConcurrentActionSnapshotLoadTest.run(world, simulation),
		"res://scripts/tests/ConcurrentActionSnapshotLoadTest.gd",
		"Concurrent snapshot/load validation returned FAIL.",
		"Inspect executable concurrent action state, ordering, and reservation restoration."
	)

	_record(
		result,
		"Step 16.7 Concurrent Action Regression / Acceptance",
		ConcurrentActionRegressionTest.run(world, simulation),
		"res://scripts/tests/ConcurrentActionRegressionTest.gd",
		"Concurrent action regression/acceptance validation returned FAIL.",
		"Inspect the full concurrent action regression boundary and state restoration."
	)

	result.set_metadata(
		"scope",
		"Step 15 interaction + Step 16 concurrent actions"
	)

	result.set_metadata(
		"tests_expected",
		EXPECTED_TEST_COUNT
	)

	result.set_metadata(
		"requires_world",
		true
	)

	result.set_metadata(
		"requires_simulation",
		true
	)

	result.set_metadata(
		"mutation_policy",
		"controlled_fixture_restore"
	)

	result.set_metadata(
		"detail_source",
		"legacy TestLogger report"
	)

	result.set_metadata(
		"compact_result",
		true
	)

	result.finish()

	TestLogger.write_line("")
	TestLogger.write_line(
		result.summary_line()
	)

	TestLogger.finish()

	return result


static func _record(
	result: TestRunResult,
	test_name: String,
	passed: bool,
	source_file: String,
	diagnostic_message: String,
	action: String
) -> void:

	result.record_test(
		test_name,
		passed,
		"",
		source_file,
		diagnostic_message,
		action
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		test_name
		+ ": "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)
