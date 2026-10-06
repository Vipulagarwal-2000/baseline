class_name Step18_5CampaignEvidenceAcceptanceTest
extends RefCounted


# ============================================================
# STEP 18.5 — CAMPAIGN EVIDENCE / ACCEPTANCE TEST
# ============================================================
#
# Acceptance layer for CampaignEvidenceArtifactBuilder.
#
# This file consumes:
#   - the SAME campaign_result produced by Step 18.2;
#   - the SAME Step 18.4 acceptance report derived from that result.
#
# It does NOT:
#   - execute a campaign;
#   - call SimulationEngine.tick_month();
#   - create a second engine;
#   - mutate WorldState;
#   - mutate SimulationEngine.
#
# Step 18.5 proves that the completed campaign has an auditable evidence
# artifact sufficient to support campaign acceptance.
# ============================================================


const DEFAULT_MONTHS: int = 60


static func run(
	campaign_result: Dictionary,
	step18_4_report: Dictionary,
	expected_months: int = DEFAULT_MONTHS
) -> Dictionary:
	TestLogger.section(
		"CAMPAIGN EVIDENCE / ACCEPTANCE — STEP 18.5"
	)

	var evidence: Dictionary = CampaignEvidenceArtifactBuilder.build(
		campaign_result,
		step18_4_report,
		expected_months
	)

	var acceptance: Dictionary = evidence.get("acceptance", {})

	var campaign_available_pass: bool = not campaign_result.is_empty()
	TestLogger.write_line(
		"18.5 campaign result available: "
		+ ("PASS" if campaign_available_pass else "FAIL")
	)

	var artifact_ready_pass: bool = (
		str(evidence.get("status", ""))
		== CampaignEvidenceArtifactBuilder.STATUS_READY
	)
	TestLogger.write_line(
		"18.5 evidence artifact ready: "
		+ ("PASS" if artifact_ready_pass else "FAIL")
	)

	var campaign_boundary_pass: bool = bool(
		acceptance.get("campaign_boundary_pass", false)
	)
	TestLogger.write_line(
		"18.5 campaign boundary evidence: "
		+ ("PASS" if campaign_boundary_pass else "FAIL")
	)

	var monthly_coverage_pass: bool = bool(
		acceptance.get("monthly_coverage_pass", false)
	)
	TestLogger.write_line(
		"18.5 monthly evidence coverage: "
		+ ("PASS" if monthly_coverage_pass else "FAIL")
	)

	var step18_3_pass: bool = bool(
		acceptance.get("step18_3_pass", false)
	)
	TestLogger.write_line(
		"18.5 Step 18.3 evidence completeness: "
		+ ("PASS" if step18_3_pass else "FAIL")
	)

	var step18_4_pass: bool = bool(
		acceptance.get("step18_4_pass", false)
	)
	TestLogger.write_line(
		"18.5 Step 18.4 acceptance linkage: "
		+ ("PASS" if step18_4_pass else "FAIL")
	)

	var step18_4_healthy_pass: bool = bool(
		acceptance.get("step18_4_healthy_pass", false)
	)
	TestLogger.write_line(
		"18.5 healthy campaign evidence: "
		+ ("PASS" if step18_4_healthy_pass else "FAIL")
	)

	var audit_complete_pass: bool = bool(
		acceptance.get("audit_complete_pass", false)
	)
	TestLogger.write_line(
		"18.5 audit metadata complete: "
		+ ("PASS" if audit_complete_pass else "FAIL")
	)

	var fingerprint_pass: bool = not str(
		evidence.get("evidence_fingerprint", "")
	).is_empty()
	TestLogger.write_line(
		"18.5 evidence fingerprint present: "
		+ ("PASS" if fingerprint_pass else "FAIL")
	)

	var deterministic_pass: bool = _validate_determinism(
		campaign_result,
		step18_4_report,
		expected_months,
		evidence
	)
	TestLogger.write_line(
		"18.5 evidence artifact is deterministic: "
		+ ("PASS" if deterministic_pass else "FAIL")
	)

	var synthetic_negative_pass: bool = _run_synthetic_negative_test()
	TestLogger.write_line(
		"18.5 rejects incomplete synthetic campaign evidence: "
		+ ("PASS" if synthetic_negative_pass else "FAIL")
	)

	var synthetic_failure_representation_pass: bool = (
		_run_synthetic_failure_representation_test()
	)
	TestLogger.write_line(
		"18.5 preserves synthetic localized-failure evidence: "
		+ (
			"PASS"
			if synthetic_failure_representation_pass
			else "FAIL"
		)
	)

	var overall_pass: bool = (
		campaign_available_pass
		and artifact_ready_pass
		and campaign_boundary_pass
		and monthly_coverage_pass
		and step18_3_pass
		and step18_4_pass
		and step18_4_healthy_pass
		and audit_complete_pass
		and fingerprint_pass
		and deterministic_pass
		and synthetic_negative_pass
		and synthetic_failure_representation_pass
		and bool(acceptance.get("pass", false))
	)

	TestLogger.write_line(
		"18.5 Campaign Evidence / Acceptance overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)
	TestLogger.write_line(
		"Step 18.5 Campaign Evidence / Acceptance test: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	var summary: Dictionary = evidence.get("summary", {})
	TestLogger.write_line(
		"18.5 evidence status: "
		+ str(summary.get("status", ""))
	)
	TestLogger.write_line(
		"18.5 campaign months evidenced: "
		+ str(summary.get("campaign_months", 0))
	)
	TestLogger.write_line(
		"18.5 start date: "
		+ str(summary.get("start_date", {}))
	)
	TestLogger.write_line(
		"18.5 end date: "
		+ str(summary.get("end_date", {}))
	)
	TestLogger.write_line(
		"18.5 Step 18.4 status: "
		+ str(summary.get("step18_4_status", ""))
	)
	TestLogger.write_line(
		"18.5 evidence fingerprint: "
		+ str(evidence.get("evidence_fingerprint", ""))
	)

	return {
		"passed": overall_pass,
		"evidence": evidence,
		"synthetic_negative_test_pass": synthetic_negative_pass,
		"synthetic_failure_representation_pass": synthetic_failure_representation_pass
	}


# ============================================================
# DETERMINISM
# ============================================================

static func _validate_determinism(
	campaign_result: Dictionary,
	step18_4_report: Dictionary,
	expected_months: int,
	first_evidence: Dictionary
) -> bool:
	var second_evidence: Dictionary = CampaignEvidenceArtifactBuilder.build(
		campaign_result,
		step18_4_report,
		expected_months
	)
	return first_evidence == second_evidence


# ============================================================
# NEGATIVE INPUT REGRESSION
# ============================================================
#
# Validates that Step 18.5 does not quietly accept an incomplete campaign
# evidence source.
# ============================================================

static func _run_synthetic_negative_test() -> bool:
	var incomplete_campaign: Dictionary = {
		"overall_pass": true,
		"requested_months": 3,
		"completed_months": 2,
		"start_date": {"year": 1950, "month": 1, "day": 1},
		"end_date": {"year": 1950, "month": 3, "day": 1},
		"start_elapsed_months": 0,
		"end_elapsed_months": 2,
		"start_snapshot_count": 0,
		"end_snapshot_count": 2,
		"system_count": 5,
		"duration_ms": 1,
		"telemetry": []
	}

	var step18_4_report: Dictionary = {
		"passed": false,
		"analysis": {
			"status": "INVALID_INPUT",
			"first_failure_month": -1,
			"failure_count": 0,
			"sequence_failure_count": 0,
			"observation_gap_count": 1
		}
	}

	var evidence: Dictionary = CampaignEvidenceArtifactBuilder.build(
		incomplete_campaign,
		step18_4_report,
		3
	)
	var acceptance: Dictionary = evidence.get("acceptance", {})

	return (
		not bool(acceptance.get("campaign_boundary_pass", false))
		and not bool(acceptance.get("monthly_coverage_pass", false))
		and not bool(acceptance.get("step18_3_pass", false))
		and not bool(acceptance.get("step18_4_pass", false))
		and not bool(acceptance.get("pass", false))
	)


# ============================================================
# FAILURE EVIDENCE REPRESENTATION REGRESSION
# ============================================================
#
# Step 18.5 must preserve a failure artifact faithfully when Step 18.4
# reports a localized failure. This does not make the failure acceptable;
# it proves the evidence format does not erase diagnostic information.
# ============================================================

static func _run_synthetic_failure_representation_test() -> bool:
	var campaign: Dictionary = _make_synthetic_campaign(3)
	var step18_4_report: Dictionary = {
		"passed": false,
		"analysis": {
			"status": "FAILURE_LOCALIZED",
			"first_failure_month": 2,
			"failure_stage": "domain",
			"failure_invariant": "world_numeric_values_finite",
			"failure_path": "world_telemetry.current_date",
			"failure_reason": "Synthetic failure.",
			"failure_fingerprint": "FAILURE_LOCALIZED|domain|world_numeric_values_finite|world_telemetry.current_date|Synthetic failure.",
			"sequence_failure_count": 0,
			"observation_gap_count": 0,
			"failure_count": 1
		}
	}

	var evidence: Dictionary = CampaignEvidenceArtifactBuilder.build(
		campaign,
		step18_4_report,
		3
	)
	var failure_evidence: Dictionary = evidence.get("step18_4_evidence", {})

	var failure_acceptance: Dictionary = evidence.get("acceptance", {})

	return (
		str(failure_evidence.get("analysis_status", "")) == "FAILURE_LOCALIZED"
		and int(failure_evidence.get("first_failure_month", -1)) == 2
		and str(failure_evidence.get("failure_invariant", ""))
			== "world_numeric_values_finite"
		and not str(failure_evidence.get("failure_fingerprint", "")).is_empty()
		and not bool(failure_acceptance.get("pass", false))
	)


static func _make_synthetic_campaign(month_count: int) -> Dictionary:
	var telemetry: Array = []

	# Derive the end date independently from the loop-local monthly variables.
	# This avoids leaking loop scope and keeps the synthetic campaign boundary
	# correct for both the 3-month regression and the 60-month shape.
	var end_month_number: int = month_count + 1
	var end_year: int = 1950 + int((end_month_number - 1) / 12)
	var end_month: int = ((end_month_number - 1) % 12) + 1

	for index in range(month_count):
		var month_number: int = index + 1
		var after_month_number: int = month_number + 1
		var after_year: int = 1950 + int((after_month_number - 1) / 12)
		var after_month: int = ((after_month_number - 1) % 12) + 1
		var before_month_number: int = month_number
		var before_year: int = 1950 + int((before_month_number - 1) / 12)
		var before_month: int = ((before_month_number - 1) % 12) + 1
		var observer: Dictionary = {
			"invariant_pass": true,
			"failure_stage": "",
			"failure_reason": "",
			"structural_failures": [],
			"domain_failures": []
		}

		telemetry.append({
			"campaign_month": month_number,
			"before_date": {
				"year": before_year,
				"month": before_month,
				"day": 1
			},
			"after_date": {
				"year": after_year,
				"month": after_month,
				"day": 1
			},
			"before_elapsed_months": index,
			"after_elapsed_months": month_number,
			"date_advanced_one_month": true,
			"before_snapshot_count": index,
			"after_snapshot_count": month_number,
			"snapshot_added": true,
			"snapshot_date_present": true,
			"entity_count_before": 3,
			"entity_count_after": 3,
			"entity_count_positive": true,
			"pending_actions_before": 0,
			"pending_actions_after": 0,
			"system_count": 5,
			"system_count_after": 5,
			"system_count_stable": true,
			"engine_ready_after_tick": true,
			"tick_duration_ms": 1,
			"structural_pass": true,
			"step18_3_telemetry": observer
		})

	return {
		"overall_pass": true,
		"requested_months": month_count,
		"completed_months": month_count,
		"start_date": {"year": 1950, "month": 1, "day": 1},
		"end_date": {
			"year": end_year,
			"month": end_month,
			"day": 1
		},
		"start_elapsed_months": 0,
		"end_elapsed_months": month_count,
		"start_snapshot_count": 0,
		"end_snapshot_count": month_count,
		"system_count": 5,
		"duration_ms": month_count,
		"telemetry": telemetry
	}
