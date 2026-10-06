class_name CampaignEvidenceArtifactBuilder
extends RefCounted


# ============================================================
# STEP 18.5 — CAMPAIGN EVIDENCE ARTIFACT BUILDER
# ============================================================
#
# Pure evidence / aggregation layer.
#
# Responsibilities:
#   1. Consume the SAME campaign_result produced by Step 18.2.
#   2. Consume the Step 18.4 acceptance report already produced for it.
#   3. Build one deterministic, auditable evidence artifact.
#   4. Preserve the monthly campaign boundary without executing anything.
#   5. Expose enough evidence for Step 18.5 acceptance to prove:
#        - campaign length/completion
#        - monthly coverage
#        - date continuity
#        - structural boundary coverage
#        - Step 18.3 observation coverage
#        - Step 18.4 regression state
#        - audit metadata / fingerprint
#
# This class MUST NOT:
#   - execute SimulationEngine.tick_month()
#   - create a new simulation
#   - mutate WorldState
#   - mutate SimulationEngine
#   - fabricate campaign data
# ============================================================


const SCHEMA: String = "step18_5_campaign_evidence_v1"
const STATUS_READY: String = "READY"
const STATUS_INVALID_INPUT: String = "INVALID_INPUT"


# ============================================================
# PUBLIC API
# ============================================================

static func build(
	campaign_result: Dictionary,
	step18_4_report: Dictionary,
	expected_months: int = 60
) -> Dictionary:
	var artifact: Dictionary = _empty_artifact(expected_months)

	if campaign_result.is_empty():
		artifact["status"] = STATUS_INVALID_INPUT
		artifact["failure_reason"] = "Campaign result is empty."
		return artifact

	var telemetry_variant: Variant = campaign_result.get("telemetry", [])
	if not telemetry_variant is Array:
		artifact["status"] = STATUS_INVALID_INPUT
		artifact["failure_reason"] = "Campaign telemetry is not an Array."
		return artifact

	if expected_months < 0:
		artifact["status"] = STATUS_INVALID_INPUT
		artifact["failure_reason"] = "Expected month count cannot be negative."
		return artifact

	var telemetry: Array = telemetry_variant
	var step18_4_analysis: Dictionary = step18_4_report.get(
		"analysis",
		{}
	)
	if not step18_4_analysis is Dictionary:
		step18_4_analysis = {}

	artifact["campaign"] = _build_campaign_boundary(
		campaign_result,
		telemetry,
		expected_months
	)

	artifact["monthly_evidence"] = _build_monthly_evidence(telemetry)
	artifact["monthly_coverage"] = _evaluate_monthly_coverage(
		telemetry,
		expected_months
	)
	artifact["step18_3_evidence"] = _build_step18_3_evidence(
		telemetry,
		expected_months
	)
	artifact["step18_4_evidence"] = _build_step18_4_evidence(
		step18_4_report,
		step18_4_analysis
	)
	artifact["audit"] = _build_audit_metadata(
		campaign_result,
		step18_4_analysis,
		expected_months
	)

	var campaign_boundary: Dictionary = artifact.get("campaign", {})
	var monthly_coverage: Dictionary = artifact.get("monthly_coverage", {})
	var step18_3_evidence: Dictionary = artifact.get("step18_3_evidence", {})
	var step18_4_evidence: Dictionary = artifact.get("step18_4_evidence", {})
	var audit: Dictionary = artifact.get("audit", {})

	var campaign_boundary_pass: bool = _campaign_boundary_pass(
		campaign_boundary,
		expected_months
	)
	var monthly_coverage_pass: bool = bool(
		monthly_coverage.get("pass", false)
	)
	var step18_3_pass: bool = bool(
		step18_3_evidence.get("pass", false)
	)
	var step18_4_pass: bool = bool(
		step18_4_evidence.get("acceptance_pass", false)
	)
	var step18_4_healthy_pass: bool = bool(
		step18_4_evidence.get("healthy_campaign_pass", false)
	)
	var audit_complete_pass: bool = bool(
		audit.get("complete", false)
	)

	artifact["acceptance"] = {
		"campaign_boundary_pass": campaign_boundary_pass,
		"monthly_coverage_pass": monthly_coverage_pass,
		"step18_3_pass": step18_3_pass,
		"step18_4_pass": step18_4_pass,
		"step18_4_healthy_pass": step18_4_healthy_pass,
		"audit_complete_pass": audit_complete_pass,
		"pass": (
			campaign_boundary_pass
			and monthly_coverage_pass
			and step18_3_pass
			and step18_4_pass
			and step18_4_healthy_pass
			and audit_complete_pass
		)
	}

	artifact["status"] = STATUS_READY
	artifact["evidence_fingerprint"] = _build_evidence_fingerprint(
		artifact
	)
	artifact["summary"] = _build_summary(artifact)

	return artifact


# ============================================================
# CAMPAIGN BOUNDARY
# ============================================================

static func _build_campaign_boundary(
	campaign_result: Dictionary,
	telemetry: Array,
	expected_months: int
) -> Dictionary:
	return {
		"requested_months": int(campaign_result.get("requested_months", 0)),
		"completed_months": int(campaign_result.get("completed_months", 0)),
		"telemetry_months": telemetry.size(),
		"expected_months": expected_months,
		"overall_pass": bool(campaign_result.get("overall_pass", false)),
		"start_date": _copy_dictionary(campaign_result.get("start_date", {})),
		"end_date": _copy_dictionary(campaign_result.get("end_date", {})),
		"start_elapsed_months": int(
			campaign_result.get("start_elapsed_months", 0)
		),
		"end_elapsed_months": int(
			campaign_result.get("end_elapsed_months", 0)
		),
		"start_snapshot_count": int(
			campaign_result.get("start_snapshot_count", 0)
		),
		"end_snapshot_count": int(
			campaign_result.get("end_snapshot_count", 0)
		),
		"system_count": int(campaign_result.get("system_count", 0)),
		"failure_month": int(campaign_result.get("failure_month", -1)),
		"failure_stage": str(campaign_result.get("failure_stage", "")),
		"failure_reason": str(campaign_result.get("failure_reason", "")),
		"duration_ms": int(campaign_result.get("duration_ms", 0))
	}


static func _campaign_boundary_pass(
	campaign: Dictionary,
	expected_months: int
) -> bool:
	return (
		int(campaign.get("requested_months", 0)) == expected_months
		and int(campaign.get("completed_months", 0)) == expected_months
		and int(campaign.get("telemetry_months", 0)) == expected_months
		and bool(campaign.get("overall_pass", false))
		and int(campaign.get("end_elapsed_months", 0))
			== int(campaign.get("start_elapsed_months", 0)) + expected_months
		and int(campaign.get("end_snapshot_count", 0))
			== int(campaign.get("start_snapshot_count", 0)) + expected_months
		and int(campaign.get("system_count", 0)) > 0
	)


# ============================================================
# MONTHLY EVIDENCE
# ============================================================

static func _build_monthly_evidence(telemetry: Array) -> Array:
	var evidence: Array = []

	for month_value in telemetry:
		if not month_value is Dictionary:
			evidence.append({
				"valid": false,
				"reason": "Monthly telemetry entry is not a Dictionary."
			})
			continue

		var month_data: Dictionary = month_value
		var step18_3_variant: Variant = month_data.get(
			"step18_3_telemetry",
			{}
		)
		var step18_3: Dictionary = (
			step18_3_variant as Dictionary
			if step18_3_variant is Dictionary
			else {}
		)

		evidence.append({
			"valid": true,
			"month": int(month_data.get("campaign_month", -1)),
			"before_date": _copy_dictionary(month_data.get("before_date", {})),
			"after_date": _copy_dictionary(month_data.get("after_date", {})),
			"before_elapsed_months": int(
				month_data.get("before_elapsed_months", 0)
			),
			"after_elapsed_months": int(
				month_data.get("after_elapsed_months", 0)
			),
			"structural_pass": bool(
				month_data.get("structural_pass", false)
			),
			"date_advanced_one_month": bool(
				month_data.get("date_advanced_one_month", false)
			),
			"snapshot_added": bool(month_data.get("snapshot_added", false)),
			"snapshot_date_present": bool(
				month_data.get("snapshot_date_present", false)
			),
			"entity_count_positive": bool(
				month_data.get("entity_count_positive", false)
			),
			"system_count": int(month_data.get("system_count", 0)),
			"system_count_after": int(
				month_data.get("system_count_after", 0)
			),
			"system_count_stable": bool(
				month_data.get("system_count_stable", false)
			),
			"engine_ready_after_tick": bool(
				month_data.get("engine_ready_after_tick", false)
			),
			"tick_duration_ms": int(
				month_data.get("tick_duration_ms", 0)
			),
			"step18_3_present": not step18_3.is_empty(),
			"step18_3_pass": bool(
				step18_3.get("invariant_pass", false)
			)
		})

	return evidence


static func _evaluate_monthly_coverage(
	telemetry: Array,
	expected_months: int
) -> Dictionary:
	var valid_entry_count: int = 0
	var structural_pass_count: int = 0
	var date_sequence_pass: bool = true
	var previous_date: Dictionary = {}
	var previous_month: int = 0
	var first_month: int = -1
	var last_month: int = -1
	var sequence_failures: Array = []

	for value in telemetry:
		if not value is Dictionary:
			date_sequence_pass = false
			sequence_failures.append("Non-Dictionary monthly evidence entry.")
			continue

		var month_data: Dictionary = value
		valid_entry_count += 1

		var month_number: int = int(month_data.get("campaign_month", -1))
		if first_month == -1:
			first_month = month_number
		last_month = month_number

		if previous_month > 0 and month_number != previous_month + 1:
			date_sequence_pass = false
			sequence_failures.append(
				"Month sequence discontinuity: previous="
				+ str(previous_month)
				+ " current="
				+ str(month_number)
			)

		if not previous_date.is_empty():
			var expected_date: Dictionary = _add_one_month(previous_date)
			var current_date: Dictionary = _copy_dictionary(
				month_data.get("after_date", {})
			)
			if current_date != expected_date:
				date_sequence_pass = false
				sequence_failures.append(
					"Date sequence discontinuity at month "
					+ str(month_number)
				)

		var after_date: Dictionary = _copy_dictionary(
			month_data.get("after_date", {})
		)
		if after_date.is_empty():
			date_sequence_pass = false
			sequence_failures.append(
				"Month " + str(month_number) + " has no post-tick date."
			)
		else:
			previous_date = after_date

		previous_month = month_number
		if bool(month_data.get("structural_pass", false)):
			structural_pass_count += 1

	return {
		"pass": (
			valid_entry_count == expected_months
			and first_month == 1
			and last_month == expected_months
			and structural_pass_count == expected_months
			and date_sequence_pass
		),
		"valid_entry_count": valid_entry_count,
		"structural_pass_count": structural_pass_count,
		"expected_months": expected_months,
		"first_month": first_month,
		"last_month": last_month,
		"date_sequence_pass": date_sequence_pass,
		"sequence_failures": sequence_failures
	}


# ============================================================
# STEP 18.3 EVIDENCE
# ============================================================

static func _build_step18_3_evidence(
	telemetry: Array,
	expected_months: int
) -> Dictionary:
	var telemetry_present_count: int = 0
	var invariant_pass_count: int = 0
	var invariant_failure_count: int = 0

	for value in telemetry:
		if not value is Dictionary:
			continue

		var month_data: Dictionary = value
		var observer_variant: Variant = month_data.get(
			"step18_3_telemetry",
			{}
		)
		if not observer_variant is Dictionary:
			continue

		var observer: Dictionary = observer_variant
		if observer.is_empty():
			continue

		telemetry_present_count += 1
		if bool(observer.get("invariant_pass", false)):
			invariant_pass_count += 1
		else:
			invariant_failure_count += 1

	return {
		"pass": (
			telemetry_present_count == expected_months
			and invariant_pass_count == expected_months
			and invariant_failure_count == 0
		),
		"telemetry_present_count": telemetry_present_count,
		"invariant_pass_count": invariant_pass_count,
		"invariant_failure_count": invariant_failure_count,
		"expected_months": expected_months
	}


# ============================================================
# STEP 18.4 EVIDENCE
# ============================================================

static func _build_step18_4_evidence(
	step18_4_report: Dictionary,
	step18_4_analysis: Dictionary
) -> Dictionary:
	var analysis_status: String = str(
		step18_4_analysis.get("status", "")
	)
	var first_failure_month: int = int(
		step18_4_analysis.get("first_failure_month", -1)
	)
	var sequence_failure_count: int = int(
		step18_4_analysis.get("sequence_failure_count", 0)
	)
	var observation_gap_count: int = int(
		step18_4_analysis.get("observation_gap_count", 0)
	)
	var failure_count: int = int(
		step18_4_analysis.get("failure_count", 0)
	)
	var failure_fingerprint: String = str(
		step18_4_analysis.get("failure_fingerprint", "")
	)
	var healthy_campaign_pass: bool = (
		analysis_status == "HEALTHY"
		and first_failure_month == -1
		and sequence_failure_count == 0
		and observation_gap_count == 0
		and failure_count == 0
		and failure_fingerprint.is_empty()
	)

	return {
		"acceptance_pass": bool(step18_4_report.get("passed", false)),
		"healthy_campaign_pass": healthy_campaign_pass,
		"analysis_status": analysis_status,
		"first_failure_month": first_failure_month,
		"failure_stage": str(
			step18_4_analysis.get("failure_stage", "")
		),
		"failure_invariant": str(
			step18_4_analysis.get("failure_invariant", "")
		),
		"failure_path": str(
			step18_4_analysis.get("failure_path", "")
		),
		"failure_reason": str(
			step18_4_analysis.get("failure_reason", "")
		),
		"failure_fingerprint": failure_fingerprint,
		"sequence_failure_count": sequence_failure_count,
		"observation_gap_count": observation_gap_count,
		"failure_count": failure_count
	}


# ============================================================
# AUDIT METADATA
# ============================================================

static func _build_audit_metadata(
	campaign_result: Dictionary,
	step18_4_analysis: Dictionary,
	expected_months: int
) -> Dictionary:
	var required_fields: Array = [
		"requested_months",
		"completed_months",
		"start_date",
		"end_date",
		"start_elapsed_months",
		"end_elapsed_months",
		"start_snapshot_count",
		"end_snapshot_count",
		"system_count",
		"duration_ms",
		"telemetry"
	]

	var missing_fields: Array = []
	for field_name in required_fields:
		if not campaign_result.has(field_name):
			missing_fields.append(field_name)

	var analysis_fields_present: bool = (
		step18_4_analysis.has("status")
		and step18_4_analysis.has("first_failure_month")
		and step18_4_analysis.has("failure_count")
		and step18_4_analysis.has("sequence_failure_count")
		and step18_4_analysis.has("observation_gap_count")
	)

	return {
		"artifact_schema": SCHEMA,
		"expected_months": expected_months,
		"missing_campaign_fields": missing_fields,
		"step18_4_analysis_fields_present": analysis_fields_present,
		"complete": missing_fields.is_empty() and analysis_fields_present
	}


# ============================================================
# DETERMINISTIC FINGERPRINT
# ============================================================

static func _build_evidence_fingerprint(artifact: Dictionary) -> String:
	var campaign: Dictionary = artifact.get("campaign", {})
	var coverage: Dictionary = artifact.get("monthly_coverage", {})
	var step18_3: Dictionary = artifact.get("step18_3_evidence", {})
	var step18_4: Dictionary = artifact.get("step18_4_evidence", {})

	var start_date: Dictionary = _copy_dictionary(campaign.get("start_date", {}))
	var end_date: Dictionary = _copy_dictionary(campaign.get("end_date", {}))

	return "|".join([
		SCHEMA,
		str(campaign.get("requested_months", 0)),
		str(campaign.get("completed_months", 0)),
		str(start_date.get("year", 0)),
		str(start_date.get("month", 0)),
		str(start_date.get("day", 0)),
		str(end_date.get("year", 0)),
		str(end_date.get("month", 0)),
		str(end_date.get("day", 0)),
		str(campaign.get("start_elapsed_months", 0)),
		str(campaign.get("end_elapsed_months", 0)),
		str(campaign.get("start_snapshot_count", 0)),
		str(campaign.get("end_snapshot_count", 0)),
		str(coverage.get("first_month", -1)),
		str(coverage.get("last_month", -1)),
		str(coverage.get("structural_pass_count", 0)),
		str(step18_3.get("telemetry_present_count", 0)),
		str(step18_3.get("invariant_pass_count", 0)),
		str(step18_4.get("analysis_status", "")),
		str(step18_4.get("first_failure_month", -1)),
		str(step18_4.get("failure_fingerprint", ""))
	])


static func _build_summary(artifact: Dictionary) -> Dictionary:
	var campaign: Dictionary = artifact.get("campaign", {})
	var coverage: Dictionary = artifact.get("monthly_coverage", {})
	var step18_3: Dictionary = artifact.get("step18_3_evidence", {})
	var step18_4: Dictionary = artifact.get("step18_4_evidence", {})
	var acceptance: Dictionary = artifact.get("acceptance", {})

	return {
		"status": str(artifact.get("status", STATUS_INVALID_INPUT)),
		"acceptance_pass": bool(acceptance.get("pass", false)),
		"campaign_months": int(campaign.get("completed_months", 0)),
		"start_date": campaign.get("start_date", {}),
		"end_date": campaign.get("end_date", {}),
		"monthly_coverage_pass": bool(coverage.get("pass", false)),
		"step18_3_pass": bool(step18_3.get("pass", false)),
		"step18_4_status": str(step18_4.get("analysis_status", "")),
		"step18_4_first_failure_month": int(
			step18_4.get("first_failure_month", -1)
		),
		"evidence_fingerprint": str(
			artifact.get("evidence_fingerprint", "")
		)
	}


# ============================================================
# HELPERS
# ============================================================

static func _empty_artifact(expected_months: int) -> Dictionary:
	return {
		"schema": SCHEMA,
		"status": STATUS_INVALID_INPUT,
		"failure_reason": "",
		"expected_months": expected_months,
		"campaign": {},
		"monthly_evidence": [],
		"monthly_coverage": {},
		"step18_3_evidence": {},
		"step18_4_evidence": {},
		"audit": {},
		"acceptance": {
			"campaign_boundary_pass": false,
			"monthly_coverage_pass": false,
			"step18_3_pass": false,
			"step18_4_pass": false,
			"step18_4_healthy_pass": false,
			"audit_complete_pass": false,
			"pass": false
		},
		"evidence_fingerprint": "",
		"summary": {}
	}


static func _copy_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _add_one_month(date: Dictionary) -> Dictionary:
	var result: Dictionary = date.duplicate(true)
	var year: int = int(result.get("year", 0))
	var month: int = int(result.get("month", 0))
	var day: int = int(result.get("day", 1))

	month += 1
	if month > 12:
		month = 1
		year += 1

	result["year"] = year
	result["month"] = month
	result["day"] = day
	return result
