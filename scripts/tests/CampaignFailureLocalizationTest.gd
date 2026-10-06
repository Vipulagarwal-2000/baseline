class_name Step18_4CampaignFailureLocalizationTest
extends RefCounted


# ============================================================
# STEP 18.4 — FAILURE LOCALIZATION / REGRESSION TEST
# ============================================================
#
# Acceptance layer for CampaignFailureLocalizationAnalyzer.
#
# This file does NOT run the campaign. It consumes an already completed
# CampaignHarness result and validates that Step 18.4 can:
#   - accept a healthy 60-month result;
#   - detect missing / malformed observation data;
#   - localize a first failing month;
#   - identify the Step 18.3 invariant behind the failure;
#   - retain previous/current/next month context;
#   - produce a deterministic failure fingerprint;
#   - avoid false failures on the current healthy Run 649 structure.
#
# The synthetic regression case is deliberately local and does not touch any
# live WorldState or SimulationEngine.
# ============================================================


const DEFAULT_MONTHS: int = 60


static func run(
	campaign_result: Dictionary,
	expected_months: int = DEFAULT_MONTHS
) -> Dictionary:
	TestLogger.section(
		"CAMPAIGN FAILURE LOCALIZATION / REGRESSION — STEP 18.4"
	)

	var analysis: Dictionary = CampaignFailureLocalizationAnalyzer.analyze_campaign_result(
		campaign_result,
		expected_months
	)

	var campaign_available_pass: bool = not campaign_result.is_empty()
	TestLogger.write_line(
		"18.4 campaign result available: "
		+ ("PASS" if campaign_available_pass else "FAIL")
	)

	var length_pass: bool = bool(
		analysis.get("expected_campaign_length_pass", false)
	)
	TestLogger.write_line(
		"18.4 campaign length boundary: "
		+ ("PASS" if length_pass else "FAIL")
	)

	var harness_pass: bool = bool(
		analysis.get("harness_overall_pass", false)
	)
	TestLogger.write_line(
		"18.4 harness completed cleanly: "
		+ ("PASS" if harness_pass else "FAIL")
	)

	var observation_gap_free: bool = int(
		analysis.get("observation_gap_count", -1)
	) == 0
	TestLogger.write_line(
		"18.4 observation gaps absent: "
		+ ("PASS" if observation_gap_free else "FAIL")
	)

	var healthy_pass: bool = (
		str(analysis.get("status", "")) == CampaignFailureLocalizationAnalyzer.STATUS_HEALTHY
		and int(analysis.get("failure_count", -1)) == 0
		and int(analysis.get("sequence_failure_count", -1)) == 0
	)
	TestLogger.write_line(
		"18.4 healthy campaign classified as HEALTHY: "
		+ ("PASS" if healthy_pass else "FAIL")
	)

	var first_failure_absent_pass: bool = int(
		analysis.get("first_failure_month", 0)
	) == -1
	TestLogger.write_line(
		"18.4 healthy campaign has no first failure month: "
		+ ("PASS" if first_failure_absent_pass else "FAIL")
	)

	var deterministic_pass: bool = _validate_determinism(
		campaign_result,
		expected_months,
		analysis
	)
	TestLogger.write_line(
		"18.4 analysis is deterministic: "
		+ ("PASS" if deterministic_pass else "FAIL")
	)

	var synthetic_pass: bool = _run_synthetic_localization_test()
	TestLogger.write_line(
		"18.4 synthetic failure localization: "
		+ ("PASS" if synthetic_pass else "FAIL")
	)

	if str(analysis.get("status", "")) != CampaignFailureLocalizationAnalyzer.STATUS_HEALTHY:
		TestLogger.write_line(
			"18.4 localized failure month: "
			+ str(analysis.get("first_failure_month", -1))
		)
		TestLogger.write_line(
			"18.4 localized failure stage: "
			+ str(analysis.get("failure_stage", ""))
		)
		TestLogger.write_line(
			"18.4 localized failure invariant: "
			+ str(analysis.get("failure_invariant", ""))
		)
		TestLogger.write_line(
			"18.4 localized failure path: "
			+ str(analysis.get("failure_path", ""))
		)
		TestLogger.write_line(
			"18.4 localized failure reason: "
			+ str(analysis.get("failure_reason", ""))
		)

	var overall_pass: bool = (
		campaign_available_pass
		and length_pass
		and harness_pass
		and observation_gap_free
		and healthy_pass
		and first_failure_absent_pass
		and deterministic_pass
		and synthetic_pass
	)

	TestLogger.write_line(
		"18.4 Campaign Failure Localization / Regression overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)
	TestLogger.write_line(
		"Step 18.4 Failure Localization / Regression test: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return {
		"passed": overall_pass,
		"analysis": analysis,
		"synthetic_test_pass": synthetic_pass
	}


# ============================================================
# DETERMINISM
# ============================================================

static func _validate_determinism(
	campaign_result: Dictionary,
	expected_months: int,
	first_analysis: Dictionary
) -> bool:
	var second_analysis: Dictionary = (
		CampaignFailureLocalizationAnalyzer.analyze_campaign_result(
			campaign_result,
			expected_months
		)
	)

	return first_analysis == second_analysis


# ============================================================
# SYNTHETIC FIRST-FAILURE REGRESSION
# ============================================================
#
# Constructs only Dictionaries. No domain state is created or mutated.
#
# Expected:
#   month 1 -> healthy
#   month 2 -> domain failure
#   invariant -> world_numeric_values_finite
#   path -> world_telemetry.current_date
#   transition context contains month 1 / 2 / 3
# ============================================================

static func _run_synthetic_localization_test() -> bool:
	var synthetic_campaign: Dictionary = {
		"overall_pass": false,
		"requested_months": 3,
		"completed_months": 3,
		"telemetry": [
			_make_synthetic_month(
				1,
				{"year": 1950, "month": 2, "day": 1},
				true,
				true,
				{}
			),
			_make_synthetic_month(
				2,
				{"year": 1950, "month": 3, "day": 1},
				true,
				false,
				{
					"failure_stage": "domain",
					"first_failed_invariant": "world_numeric_values_finite",
					"failure_reason": "Synthetic non-finite world value.",
					"world_numeric_failure_path": "world_telemetry.current_date",
					"domain_failures": ["world_numeric_values_finite"],
					"structural_failures": []
				}
			),
			_make_synthetic_month(
				3,
				{"year": 1950, "month": 4, "day": 1},
				true,
				true,
				{}
			)
		]
	}

	var analysis: Dictionary = CampaignFailureLocalizationAnalyzer.analyze_campaign_result(
		synthetic_campaign,
		3
	)

	var first_failure_month_pass: bool = int(
		analysis.get("first_failure_month", -1)
	) == 2
	var stage_pass: bool = str(
		analysis.get("failure_stage", "")
	) == "domain"
	var invariant_pass: bool = str(
		analysis.get("failure_invariant", "")
	) == "world_numeric_values_finite"
	var path_pass: bool = str(
		analysis.get("failure_path", "")
	) == "world_telemetry.current_date"
	var context: Dictionary = analysis.get("transition_context", {})
	var previous_pass: bool = int(
		(context.get("previous", {}) as Dictionary).get("month", -1)
	) == 1
	var current_pass: bool = int(
		(context.get("current", {}) as Dictionary).get("month", -1)
	) == 2
	var next_pass: bool = int(
		(context.get("next", {}) as Dictionary).get("month", -1)
	) == 3
	var fingerprint_pass: bool = not str(
		analysis.get("failure_fingerprint", "")
	).is_empty()

	return (
		first_failure_month_pass
		and stage_pass
		and invariant_pass
		and path_pass
		and previous_pass
		and current_pass
		and next_pass
		and fingerprint_pass
	)


static func _make_synthetic_month(
	month_number: int,
	date: Dictionary,
	structural_pass: bool,
	invariant_pass: bool,
	failure_payload: Dictionary
) -> Dictionary:
	var step18_3: Dictionary = {
		"invariant_pass": invariant_pass,
		"failure_stage": str(failure_payload.get("failure_stage", "")),
		"first_failed_invariant": str(
			failure_payload.get("first_failed_invariant", "")
		),
		"failure_reason": str(
			failure_payload.get("failure_reason", "")
		),
		"world_numeric_failure_path": str(
			failure_payload.get("world_numeric_failure_path", "")
		),
		"country_numeric_failure_path": "",
		"structural_failures": failure_payload.get(
			"structural_failures",
			[]
		),
		"domain_failures": failure_payload.get(
			"domain_failures",
			[]
		)
	}

	return {
		"campaign_month": month_number,
		"after_date": date,
		"structural_pass": structural_pass,
		"failure_stage": "" if structural_pass else "synthetic_structural",
		"failure_reason": "" if structural_pass else "Synthetic structural failure.",
		"tick_duration_ms": 1,
		"step18_3_telemetry": step18_3,
		"engine_ready_after_tick": true,
		"date_advanced_one_month": true,
		"snapshot_added": true,
		"entity_count_positive": true,
		"entity_count_before": 3,
		"entity_count_after": 3,
		"system_count_stable": true,
		"pending_actions_after": 0,
		"snapshot_date_present": true
	}
