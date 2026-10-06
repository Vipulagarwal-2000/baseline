class_name Step18_1CampaignHarnessTest
extends RefCounted


# ============================================================
# STEP 18.1 — CAMPAIGN HARNESS TEST
# ============================================================
#
# This test wrapper deliberately is NOT added to RunAllTests yet.
# Campaign execution advances the real WorldState and therefore needs
# a dedicated/fresh campaign simulation context rather than the shared
# mutation-sensitive active-suite fixture.
#
# Use:
#
#     Step18_1CampaignHarnessTest.run(world, simulation, 1)
#
# for a one-month smoke test, or a larger month count when intentionally
# running a campaign context.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine,
	months: int = 1
) -> bool:

	TestLogger.section(
		"CAMPAIGN HARNESS — STEP 18.1"
	)

	if world == null:
		TestLogger.write_line(
			"18.1 world available: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"18.1 simulation available: FAIL"
		)
		return false

	var harness_result: Dictionary = CampaignHarness.run(
		world,
		simulation,
		months
	)

	var requested_months: int = int(
		harness_result.get("requested_months", months)
	)
	var completed_months: int = int(
		harness_result.get("completed_months", 0)
	)
	var overall_pass: bool = bool(
		harness_result.get("overall_pass", false)
	)

	TestLogger.write_line(
		"18.1 requested months: "
		+ str(requested_months)
	)

	TestLogger.write_line(
		"18.1 completed months: "
		+ str(completed_months)
	)

	TestLogger.write_line(
		"18.1 campaign harness execution: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	var telemetry: Array = harness_result.get("telemetry", [])

	for telemetry_variant in telemetry:
		if not telemetry_variant is Dictionary:
			continue

		var month_data: Dictionary = telemetry_variant
		var month_number: int = int(
			month_data.get("campaign_month", 0)
		)

		TestLogger.write_line(
			"18.1 month "
			+ str(month_number)
			+ " structural pipeline: "
			+ (
				"PASS"
				if bool(month_data.get("structural_pass", false))
				else "FAIL"
			)
		)

		TestLogger.write_line(
			"18.1 month "
			+ str(month_number)
			+ " date "
			+ str(month_data.get("before_date", {}))
			+ " -> "
			+ str(month_data.get("after_date", {}))
		)

		TestLogger.write_line(
			"18.1 month "
			+ str(month_number)
			+ " snapshot added: "
			+ (
				"PASS"
				if bool(month_data.get("snapshot_added", false))
				else "FAIL"
			)
		)

		TestLogger.write_line(
			"18.1 month "
			+ str(month_number)
			+ " snapshot date present: "
			+ (
				"YES"
				if bool(month_data.get("snapshot_date_present", false))
				else "NO"
			)
		)

	var warnings: Array = harness_result.get("warnings", [])
	if not warnings.is_empty():
		TestLogger.write_line(
			"18.1 warnings: "
			+ str(warnings.size())
		)

		for warning_variant in warnings:
			TestLogger.write_line(
				"18.1 warning: "
				+ str(warning_variant)
			)

	var failure_reason: String = str(
		harness_result.get("failure_reason", "")
	)

	if not failure_reason.is_empty():
		TestLogger.write_line(
			"18.1 first failure: month="
			+ str(harness_result.get("failure_month", -1))
			+ " stage="
			+ str(harness_result.get("failure_stage", ""))
			+ " reason="
			+ failure_reason
		)

	TestLogger.write_line(
		"18.1 Campaign Harness overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass
