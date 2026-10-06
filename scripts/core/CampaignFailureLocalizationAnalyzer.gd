class_name CampaignFailureLocalizationAnalyzer
extends RefCounted


# ============================================================
# STEP 18.4 — CAMPAIGN FAILURE LOCALIZATION / REGRESSION ANALYSIS
# ============================================================
#
# Pure analysis layer.
#
# Responsibilities:
#   1. Consume the campaign result already produced by CampaignHarness.
#   2. Consume Step 18.3 monthly invariant telemetry embedded in that result.
#   3. Identify the first failing month and exact failing boundary.
#   4. Preserve adjacent-month context for regression analysis.
#   5. Produce a deterministic regression fingerprint.
#   6. Never execute ticks, mutate WorldState, mutate SimulationEngine, or
#      create a second campaign run.
#
# Step 18.4 therefore sits strictly after Step 18.2/18.3:
#
#   real simulation
#        -> CampaignHarness
#        -> Step 18.3 telemetry
#        -> THIS ANALYZER
# ============================================================


const STATUS_HEALTHY: String = "HEALTHY"
const STATUS_FAILURE_LOCALIZED: String = "FAILURE_LOCALIZED"
const STATUS_OBSERVATION_GAP: String = "OBSERVATION_GAP"
const STATUS_INVALID_INPUT: String = "INVALID_INPUT"


# ============================================================
# PUBLIC API
# ============================================================

static func analyze_campaign_result(
	campaign_result: Dictionary,
	expected_months: int = 60
) -> Dictionary:
	var report: Dictionary = _empty_report(expected_months)

	if campaign_result.is_empty():
		report["status"] = STATUS_INVALID_INPUT
		report["failure_stage"] = "campaign_result"
		report["failure_reason"] = "Campaign result is empty."
		return report

	var telemetry_variant: Variant = campaign_result.get("telemetry", [])
	if not telemetry_variant is Array:
		report["status"] = STATUS_INVALID_INPUT
		report["failure_stage"] = "telemetry_container"
		report["failure_reason"] = "Campaign telemetry is not an Array."
		return report

	var telemetry: Array = telemetry_variant
	report["requested_months"] = int(
		campaign_result.get("requested_months", expected_months)
	)
	report["completed_months"] = int(
		campaign_result.get("completed_months", 0)
	)
	report["telemetry_months"] = telemetry.size()
	report["harness_overall_pass"] = bool(
		campaign_result.get("overall_pass", false)
	)

	var sequence_failures: Array = []
	var observation_gaps: Array = []
	var failure_records: Array = []
	var monthly_reports: Array = []

	var previous_valid_date: Dictionary = {}
	var previous_month_number: int = 0

	for index in range(telemetry.size()):
		var month_value: Variant = telemetry[index]
		if not month_value is Dictionary:
			sequence_failures.append(
				"telemetry[" + str(index) + "] is not a Dictionary"
			)
			continue

		var month_data: Dictionary = month_value
		var monthly_report: Dictionary = _analyze_month(
			month_data,
			previous_month_number,
			previous_valid_date
		)
		monthly_reports.append(monthly_report)

		previous_month_number = int(monthly_report.get("month", previous_month_number))
		var observed_date: Variant = monthly_report.get("after_date", {})
		if _valid_date_dictionary(observed_date):
			previous_valid_date = (observed_date as Dictionary).duplicate(true)

		var sequence_failure: String = str(
			monthly_report.get("sequence_failure", "")
		)
		if not sequence_failure.is_empty():
			sequence_failures.append(sequence_failure)

		var observation_gap: String = str(
			monthly_report.get("observation_gap", "")
		)
		if not observation_gap.is_empty():
			observation_gaps.append(observation_gap)

		if not bool(monthly_report.get("healthy", false)):
			failure_records.append(monthly_report)

	report["monthly_reports"] = monthly_reports
	report["sequence_failures"] = sequence_failures
	report["observation_gaps"] = observation_gaps
	report["failure_records"] = failure_records
	report["sequence_failure_count"] = sequence_failures.size()
	report["observation_gap_count"] = observation_gaps.size()
	report["failure_count"] = failure_records.size()

	if not monthly_reports.is_empty():
		var first_month_report: Dictionary = monthly_reports[0]
		var last_month_report: Dictionary = monthly_reports[monthly_reports.size() - 1]
		var first_month_number: int = int(first_month_report.get("month", -1))
		var last_month_number: int = int(last_month_report.get("month", -1))

		if first_month_number != 1:
			sequence_failures.append(
				"Campaign telemetry must begin at month 1; actual="
				+ str(first_month_number)
			)

		if last_month_number != expected_months:
			sequence_failures.append(
				"Campaign telemetry must end at expected month "
				+ str(expected_months)
				+ "; actual="
				+ str(last_month_number)
			)

		report["sequence_failures"] = sequence_failures
		report["sequence_failure_count"] = sequence_failures.size()

	var expected_length_pass: bool = (
		report["requested_months"] == expected_months
		and report["completed_months"] == expected_months
		and report["telemetry_months"] == expected_months
	)
	report["expected_campaign_length_pass"] = expected_length_pass

	var first_failure: Dictionary = {}
	if not failure_records.is_empty():
		first_failure = failure_records[0]

	if not expected_length_pass:
		report["status"] = STATUS_INVALID_INPUT
		report["failure_stage"] = "campaign_boundary"
		report["failure_reason"] = (
			"Campaign length / completion / telemetry count does not match the expected month count."
		)
	elif not observation_gaps.is_empty():
		report["status"] = STATUS_OBSERVATION_GAP
		report["failure_stage"] = "observation"
		report["failure_reason"] = observation_gaps[0]
	elif not sequence_failures.is_empty():
		report["status"] = STATUS_FAILURE_LOCALIZED
		report["failure_stage"] = "sequence"
		report["failure_reason"] = sequence_failures[0]
	elif not first_failure.is_empty():
		report["status"] = STATUS_FAILURE_LOCALIZED
		report["first_failure_month"] = int(
			first_failure.get("month", -1)
		)
		report["failure_stage"] = str(
			first_failure.get("failure_stage", "")
		)
		report["failure_invariant"] = str(
			first_failure.get("failure_invariant", "")
		)
		report["failure_reason"] = str(
			first_failure.get("failure_reason", "")
		)
		report["failure_path"] = str(
			first_failure.get("failure_path", "")
		)
	else:
		report["status"] = STATUS_HEALTHY
		report["failure_stage"] = ""
		report["failure_reason"] = ""

	if first_failure.is_empty():
		report["first_failure_month"] = -1

	report["failure_fingerprint"] = _build_failure_fingerprint(
		report
	)
	report["repeated_failure_fingerprints"] = _count_failure_fingerprints(
		failure_records
	)
	report["transition_context"] = _build_transition_context(
		monthly_reports,
		int(report.get("first_failure_month", -1))
	)

	return report


# ============================================================
# MONTH ANALYSIS
# ============================================================

static func _analyze_month(
	month_data: Dictionary,
	previous_month_number: int,
	previous_date: Dictionary
) -> Dictionary:
	var month_number: int = int(month_data.get("campaign_month", -1))
	var after_date_variant: Variant = month_data.get("after_date", {})
	var after_date: Dictionary = (
		after_date_variant as Dictionary
		if after_date_variant is Dictionary
		else {}
	)

	var result: Dictionary = {
		"month": month_number,
		"after_date": after_date.duplicate(true),
		"healthy": true,
		"harness_structural_pass": bool(
			month_data.get("structural_pass", false)
		),
		"step18_3_present": false,
		"step18_3_pass": false,
		"failure_stage": "",
		"failure_invariant": "",
		"failure_reason": "",
		"failure_path": "",
		"sequence_failure": "",
		"observation_gap": "",
		"tick_duration_ms": int(month_data.get("tick_duration_ms", 0)),
		"harness_failure_stage": str(
			month_data.get("failure_stage", "")
		),
		"harness_failure_reason": str(
			month_data.get("failure_reason", "")
		)
	}

	if month_number <= 0:
		result["healthy"] = false
		result["sequence_failure"] = (
			"Invalid campaign month number: " + str(month_number)
		)
		return result

	if previous_month_number > 0 and month_number != previous_month_number + 1:
		result["healthy"] = false
		result["sequence_failure"] = (
			"Campaign month sequence discontinuity: previous="
			+ str(previous_month_number)
			+ " current="
			+ str(month_number)
		)

	if not _valid_date_dictionary(after_date):
		result["healthy"] = false
		result["observation_gap"] = (
			"Month " + str(month_number) + " has no valid post-tick date."
		)
	elif not previous_date.is_empty():
		var expected_date: Dictionary = _add_one_month(previous_date)
		if after_date != expected_date:
			result["healthy"] = false
			result["sequence_failure"] = (
				"Date sequence discontinuity at month "
				+ str(month_number)
				+ ": expected="
				+ str(expected_date)
				+ " actual="
				+ str(after_date)
			)

	if not result["harness_structural_pass"]:
		result["healthy"] = false
		result["failure_stage"] = str(
			month_data.get("failure_stage", "harness_structural")
		)
		result["failure_reason"] = str(
			month_data.get(
				"failure_reason",
				"CampaignHarness structural boundary failed."
			)
		)

	var step18_3_variant: Variant = month_data.get(
		"step18_3_telemetry",
		{}
	)
	if not step18_3_variant is Dictionary:
		result["healthy"] = false
		result["observation_gap"] = (
			"Month " + str(month_number) + " Step 18.3 telemetry is not a Dictionary."
		)
		return result

	var step18_3: Dictionary = step18_3_variant
	result["step18_3_present"] = not step18_3.is_empty()

	if step18_3.is_empty():
		result["healthy"] = false
		result["observation_gap"] = (
			"Month " + str(month_number) + " has empty Step 18.3 telemetry."
		)
		return result

	var invariant_pass: bool = bool(
		step18_3.get("invariant_pass", false)
	)
	result["step18_3_pass"] = invariant_pass

	if not invariant_pass:
		result["healthy"] = false
		result["failure_stage"] = str(
			step18_3.get("failure_stage", "invariant")
		)
		result["failure_invariant"] = str(
			step18_3.get("first_failed_invariant", "")
		)
		result["failure_reason"] = str(
			step18_3.get("failure_reason", "Step 18.3 invariant failure.")
		)

		if result["failure_invariant"].is_empty():
			var failures: Variant = (
				step18_3.get("structural_failures", [])
			)
			if failures is Array and not failures.is_empty():
				result["failure_invariant"] = str(failures[0])
			else:
				failures = step18_3.get("domain_failures", [])
				if failures is Array and not failures.is_empty():
					result["failure_invariant"] = str(failures[0])

		if result["failure_invariant"] == "country_numeric_values_finite":
			result["failure_path"] = str(
				step18_3.get("country_numeric_failure_path", "")
			)
		elif result["failure_invariant"] == "world_numeric_values_finite":
			result["failure_path"] = str(
				step18_3.get("world_numeric_failure_path", "")
			)

	return result


# ============================================================
# REGRESSION / FINGERPRINTING
# ============================================================

static func _build_failure_fingerprint(report: Dictionary) -> String:
	if str(report.get("status", "")) == STATUS_HEALTHY:
		return ""

	return "|".join([
		str(report.get("status", "")),
		str(report.get("failure_stage", "")),
		str(report.get("failure_invariant", "")),
		str(report.get("failure_path", "")),
		str(report.get("failure_reason", ""))
	])


static func _count_failure_fingerprints(failure_records: Array) -> Dictionary:
	var counts: Dictionary = {}

	for failure_record_variant in failure_records:
		if not failure_record_variant is Dictionary:
			continue

		var failure_record: Dictionary = failure_record_variant
		var fingerprint: String = "|".join([
			str(failure_record.get("failure_stage", "")),
			str(failure_record.get("failure_invariant", "")),
			str(failure_record.get("failure_path", "")),
			str(failure_record.get("failure_reason", ""))
		])

		if fingerprint.is_empty():
			continue

		counts[fingerprint] = int(counts.get(fingerprint, 0)) + 1

	return counts


static func _build_transition_context(
	monthly_reports: Array,
	first_failure_month: int
) -> Dictionary:
	if first_failure_month <= 0:
		return {
			"previous": {},
			"current": {},
			"next": {}
		}

	var previous: Dictionary = {}
	var current: Dictionary = {}
	var next: Dictionary = {}

	for report_variant in monthly_reports:
		if not report_variant is Dictionary:
			continue

		var monthly_report: Dictionary = report_variant
		var month_number: int = int(monthly_report.get("month", -1))

		if month_number == first_failure_month - 1:
			previous = monthly_report
		elif month_number == first_failure_month:
			current = monthly_report
		elif month_number == first_failure_month + 1:
			next = monthly_report

	return {
		"previous": previous,
		"current": current,
		"next": next
	}


# ============================================================
# REPORT SHAPE
# ============================================================

static func _empty_report(expected_months: int) -> Dictionary:
	return {
		"schema": "step18_4_campaign_failure_localization_v1",
		"expected_months": expected_months,
		"requested_months": 0,
		"completed_months": 0,
		"telemetry_months": 0,
		"harness_overall_pass": false,
		"expected_campaign_length_pass": false,
		"status": STATUS_INVALID_INPUT,
		"first_failure_month": -1,
		"failure_stage": "",
		"failure_invariant": "",
		"failure_reason": "",
		"failure_path": "",
		"failure_fingerprint": "",
		"sequence_failure_count": 0,
		"observation_gap_count": 0,
		"failure_count": 0,
		"monthly_reports": [],
		"failure_records": [],
		"sequence_failures": [],
		"observation_gaps": [],
		"repeated_failure_fingerprints": {},
		"transition_context": {
			"previous": {},
			"current": {},
			"next": {}
		}
	}


# ============================================================
# DATE HELPERS
# ============================================================

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


static func _valid_date_dictionary(value: Variant) -> bool:
	if not value is Dictionary:
		return false

	var date: Dictionary = value
	var year: int = int(date.get("year", 0))
	var month: int = int(date.get("month", 0))
	var day: int = int(date.get("day", 0))

	return (
		year > 0
		and month >= 1
		and month <= 12
		and day >= 1
		and day <= 31
	)
