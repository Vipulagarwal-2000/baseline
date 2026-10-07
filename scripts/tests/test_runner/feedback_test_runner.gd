class_name FeedbackTestRunner
extends RefCounted


# ============================================================
# FEEDBACK TEST RUNNER
# ============================================================
#
# Step 10 — Step 17 feedback validation.
#
# Scope:
#   Step 17.1 — Player Feedback
#   Step 17.2 — AI Feedback
#   Step 17.3 — Cross-Domain Feedback
#   Step 17.4 — Multi-Month Closure
#   Step 17.5 — Event-Driven Feedback
#   Step 17.6 — Full Integrated Feedback Closure
#   Step 17.7 — Snapshot / Persistence Boundary
#   Step 17.8 — Full Dynamic Feedback Acceptance
#
# The runner uses the existing authoritative WorldState + SimulationEngine
# and does not create a second feedback or causal model.
#
# The master RunAllTests path is integrated in the same step, so the legacy
# Step 17 calls are removed after being transferred here.
# ============================================================


const RUNNER_ID := "feedback"
const DISPLAY_NAME := "Feedback Test Runner"
const EXPECTED_TEST_COUNT := 8


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
        "FEEDBACK TEST RUNNER"
	)

	TestLogger.write_line(
        "Step 17 dynamic feedback validation"
	)

	TestLogger.section(
		"[DOMAIN] STEP 17 FEEDBACK"
	)

	_record(
		result,
		"Step 17.1 Player Feedback",
		PlayerFeedbackTest.run(world, simulation),
		"res://scripts/tests/player_feedback_test.gd",
		"Step 17.1 Player Feedback validation returned FAIL.",
        "Inspect player feedback outcome propagation and the authoritative player action path."
	)

	_record(
		result,
		"Step 17.2 AI Feedback",
		AIFeedbackStep17_2Test.run(world, simulation),
		"res://scripts/tests/AIFeedbackStep17_2test.gd",
		"Step 17.2 AI Feedback validation returned FAIL.",
        "Inspect AI action outcome feedback, memory, and decision trajectory integration."
	)

	_record(
		result,
		"Step 17.3 Cross-Domain Feedback",
		Step17_3CrossDomainFeedbackTest.run(world, simulation),
		"res://scripts/tests/CrossDomainFeedbackTest.gd",
		"Step 17.3 Cross-Domain Feedback validation returned FAIL.",
        "Inspect cross-domain consequence propagation and shared authoritative state consumption."
	)

	_record(
		result,
		"Step 17.4 Multi-Month Closure",
		Step17_4MultiMonthClosureTest.run(world, simulation),
		"res://scripts/tests/MultiMonthClosureTest.gd",
		"Step 17.4 Multi-Month Closure validation returned FAIL.",
        "Inspect monthly feedback persistence, date advancement, and downstream decision effects."
	)

	_record(
		result,
		"Step 17.5 Event-Driven Feedback",
		Step17_5EventDrivenFeedbackTest.run(world, simulation),
		"res://scripts/tests/EventDrivenFeedbackTest.gd",
		"Step 17.5 Event-Driven Feedback validation returned FAIL.",
        "Inspect event eligibility, execution, consequence propagation, and one-time event behavior."
	)

	_record(
		result,
		"Step 17.6 Full Integrated Feedback Closure",
		Step17_6FullIntegratedFeedbackClosureTest.run(world, simulation),
		"res://scripts/tests/FullIntegratedFeedbackClosureTest.gd",
		"Step 17.6 Full Integrated Feedback Closure validation returned FAIL.",
        "Inspect the connected event → domain → action → relationship → decision feedback chain."
	)

	_record(
		result,
		"Step 17.7 Snapshot / Persistence Boundary",
		Step17_7SnapshotPersistenceBoundaryTest.run(world, simulation),
		"res://scripts/tests/SnapshotPersistenceBoundaryTest.gd",
		"Step 17.7 Snapshot / Persistence Boundary validation returned FAIL.",
        "Inspect snapshot capture, deep-copy isolation, executable state restoration, and fixture recovery."
	)

	_record(
		result,
		"Step 17.8 Full Dynamic Feedback Acceptance",
		Step17_8Step17AcceptanceTest.run(world, simulation),
		"res://scripts/tests/AcceptanceTest.gd",
		"Step 17.8 Full Dynamic Feedback Acceptance validation returned FAIL.",
        "Inspect the complete bounded Step 17 feedback chain and final acceptance boundary."
	)

	result.set_metadata(
		"scope",
        "Step 17.1–17.8 dynamic feedback"
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
