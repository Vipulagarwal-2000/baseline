class_name CampaignTestRunner
extends RefCounted


# ============================================================
# CAMPAIGN TEST RUNNER
# ============================================================
#
# Step 18 campaign validation.
#
# Scope:
#   Step 18.2 — Dedicated 60-Month Campaign
#   Step 18.3 — Campaign Invariant / Telemetry
#   Step 18.4 — Campaign Failure Localization / Regression
#   Step 18.5 — Campaign Evidence / Acceptance
#
# Step 18.2 is the SINGLE campaign execution. Steps 18.3–18.5 consume
# the exact same campaign_result and do not advance the simulation again.
#
# Step 18.1 (Campaign Harness) remains an isolated/manual smoke entry point
# because it intentionally advances the supplied campaign context. It is not
# included here so the runner cannot execute a preliminary campaign and then
# invalidate the fresh-state boundary required by Step 18.2.
# ============================================================


const RUNNER_ID := "campaign"
const DISPLAY_NAME := "Campaign Test Runner"
const EXPECTED_TEST_COUNT := 4
const DEFAULT_MONTHS := 60


static func run(
	campaign_world: WorldState,
	campaign_simulation: SimulationEngine,
	campaign_months: int = DEFAULT_MONTHS
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
        "CAMPAIGN TEST RUNNER"
	)

	TestLogger.write_line(
        "Step 18.2–18.5 campaign validation"
	)

	if campaign_world == null:
		_record(
			result,
			"Step 18.2 Dedicated 60-Month Campaign",
			false,
			"res://scripts/tests/Campaign60MonthValidationTest.gd",
			"Dedicated campaign world was null.",
            "Provide the fresh dedicated campaign WorldState created for Step 18.2."
		)
		_record(
			result,
			"Step 18.3 Campaign Invariant / Telemetry",
			false,
			"res://scripts/tests/CampaignInvariantTelemetryTest.gd",
			"Campaign execution did not produce a report because the campaign world was null.",
            "Provide a valid dedicated campaign context."
		)
		_record(
			result,
			"Step 18.4 Campaign Failure Localization / Regression",
			false,
			"res://scripts/tests/CampaignFailureLocalizationTest.gd",
			"Campaign execution did not produce a report because the campaign world was null.",
            "Provide a valid dedicated campaign context."
		)
		_record(
			result,
			"Step 18.5 Campaign Evidence / Acceptance",
			false,
			"res://scripts/tests/CampaignEvidenceAcceptanceTest.gd",
			"Campaign execution did not produce a report because the campaign world was null.",
            "Provide a valid dedicated campaign context."
		)
	elif campaign_simulation == null:
		_record(
			result,
			"Step 18.2 Dedicated 60-Month Campaign",
			false,
			"res://scripts/tests/Campaign60MonthValidationTest.gd",
			"Dedicated campaign simulation was null.",
            "Provide the fresh dedicated campaign SimulationEngine created for Step 18.2."
		)
		_record(
			result,
			"Step 18.3 Campaign Invariant / Telemetry",
			false,
			"res://scripts/tests/CampaignInvariantTelemetryTest.gd",
			"Campaign execution did not produce a report because the campaign simulation was null.",
            "Provide a valid dedicated campaign context."
		)
		_record(
			result,
			"Step 18.4 Campaign Failure Localization / Regression",
			false,
			"res://scripts/tests/CampaignFailureLocalizationTest.gd",
			"Campaign execution did not produce a report because the campaign simulation was null.",
            "Provide a valid dedicated campaign context."
		)
		_record(
			result,
			"Step 18.5 Campaign Evidence / Acceptance",
			false,
			"res://scripts/tests/CampaignEvidenceAcceptanceTest.gd",
			"Campaign execution did not produce a report because the campaign simulation was null.",
            "Provide a valid dedicated campaign context."
		)
	else:
		var step18_2_report: Dictionary = (
			Step18_2Campaign60MonthValidationTest.run_with_report(
				campaign_world,
				campaign_simulation,
				campaign_months,
				true
			)
		)

		var step18_2_passed: bool = bool(
			step18_2_report.get("passed", false)
		)

		_record(
			result,
			"Step 18.2 Dedicated 60-Month Campaign",
			step18_2_passed,
			"res://scripts/tests/Campaign60MonthValidationTest.gd",
			"Step 18.2 dedicated campaign execution or campaign-boundary validation failed.",
            "Inspect the single 60-month CampaignHarness execution, fresh-start boundary, monthly telemetry, date progression, snapshots, entity count, and system-count stability."
		)

		var step18_3_passed: bool = false

		if not step18_2_report.is_empty():
			var campaign_result: Dictionary = step18_2_report.get(
				"campaign_result",
				{}
			)

			step18_3_passed = (
				Step18_3CampaignInvariantTelemetryTest
				.validate_campaign_result(
					campaign_result,
					campaign_months
				)
			)

		_record(
			result,
			"Step 18.3 Campaign Invariant / Telemetry",
			step18_3_passed,
			"res://scripts/tests/CampaignInvariantTelemetryTest.gd",
			"Step 18.3 campaign invariant / telemetry validation failed.",
            "Inspect monthly observer output, invariant coverage, campaign length, telemetry completeness, and first-failure localization data."
		)

		var step18_4_passed: bool = false
		var step18_4_report: Dictionary = {}

		if not step18_2_report.is_empty():
			var step18_4_campaign_result: Dictionary = (
				step18_2_report.get(
					"campaign_result",
					{}
				)
			)

			step18_4_report = (
				Step18_4CampaignFailureLocalizationTest.run(
					step18_4_campaign_result,
					campaign_months
				)
			)

			step18_4_passed = bool(
				step18_4_report.get(
					"passed",
					false
				)
			)

		_record(
			result,
			"Step 18.4 Campaign Failure Localization / Regression",
			step18_4_passed,
			"res://scripts/tests/CampaignFailureLocalizationTest.gd",
			"Step 18.4 campaign failure localization / regression validation failed.",
            "Inspect campaign result classification, observation gaps, deterministic analysis, first-failure month, invariant, failure path, transition context, and synthetic localization regression."
		)

		var step18_5_passed: bool = false

		if not step18_2_report.is_empty():
			var step18_5_campaign_result: Dictionary = (
				step18_2_report.get(
					"campaign_result",
					{}
				)
			)

			var step18_5_report: Dictionary = (
				Step18_5CampaignEvidenceAcceptanceTest.run(
					step18_5_campaign_result,
					step18_4_report,
					campaign_months
				)
			)

			step18_5_passed = bool(
				step18_5_report.get(
					"passed",
					false
				)
			)

		_record(
			result,
			"Step 18.5 Campaign Evidence / Acceptance",
			step18_5_passed,
			"res://scripts/tests/CampaignEvidenceAcceptanceTest.gd",
			"Step 18.5 campaign evidence / acceptance validation failed.",
            "Inspect campaign boundary evidence, monthly evidence coverage, Step 18.3 linkage, Step 18.4 acceptance linkage, audit metadata, deterministic fingerprinting, and negative-input regressions."
		)

	result.set_metadata(
		"scope",
        "Step 18.2–18.5 campaign execution + acceptance"
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
		"requires_dedicated_campaign_context",
		true
	)

	result.set_metadata(
		"campaign_months",
		campaign_months
	)

	result.set_metadata(
		"single_campaign_execution",
		true
	)

	result.set_metadata(
		"mutation_policy",
        "dedicated_campaign_context"
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
