class_name Step18_2Campaign60MonthValidationTest
extends RefCounted


# ============================================================
# STEP 18.2 — 60-MONTH CAMPAIGN VALIDATION
# ============================================================
#
# Uses the real SimulationEngine through CampaignHarness.
# Step 18.3 is an observer attached to this SAME 60-month execution.
# There is no second campaign loop.
# ============================================================


const DEFAULT_MONTHS: int = 60


static func run(
	world: WorldState,
	simulation: SimulationEngine,
	months: int = DEFAULT_MONTHS
) -> bool:
	return bool(
		run_with_report(
			world,
			simulation,
			months,
			false
		).get("passed", false)
	)


static func run_with_report(
	world: WorldState,
	simulation: SimulationEngine,
	months: int = DEFAULT_MONTHS,
	collect_step18_3: bool = false
) -> Dictionary:
	TestLogger.section("60-MONTH CAMPAIGN VALIDATION — STEP 18.2")

	if world == null:
		TestLogger.write_line("18.2 world available: FAIL")
		return {"passed": false, "campaign_result": {}}

	if simulation == null:
		TestLogger.write_line("18.2 simulation available: FAIL")
		return {"passed": false, "campaign_result": {}}

	if not simulation.is_ready():
		TestLogger.write_line("18.2 simulation ready: FAIL")
		return {"passed": false, "campaign_result": {}}

	var config: SimulationConfig = world.config
	if config == null:
		TestLogger.write_line("18.2 simulation config available: FAIL")
		return {"passed": false, "campaign_result": {}}

	var start_date: Dictionary = world.current_date.duplicate(true)
	var expected_start_date: Dictionary = {
		"year": config.start_year,
		"month": config.start_month,
		"day": config.start_day
	}
	var fresh_start_pass: bool = start_date == expected_start_date

	TestLogger.write_line(
		"18.2 fresh campaign start date: "
		+ ("PASS" if fresh_start_pass else "FAIL")
	)
	TestLogger.write_line("18.2 start date actual: " + str(start_date))
	TestLogger.write_line(
		"18.2 start date expected: " + str(expected_start_date)
	)

	var required_country_pass: bool = _validate_required_countries(world)
	TestLogger.write_line(
		"18.2 China / India / USA campaign set: "
		+ ("PASS" if required_country_pass else "FAIL")
	)

	var initial_entity_count: int = world.get_entity_count()
	var initial_system_count: int = simulation.get_system_count()
	var initial_snapshot_count: int = simulation.get_snapshot_count()
	var initial_elapsed_months: int = world.get_elapsed_months()

	TestLogger.write_line(
		"18.2 initial entity count: " + str(initial_entity_count)
	)
	TestLogger.write_line(
		"18.2 initial system count: " + str(initial_system_count)
	)
	TestLogger.write_line(
		"18.2 initial snapshot count: " + str(initial_snapshot_count)
	)
	TestLogger.write_line(
		"18.2 initial elapsed months: " + str(initial_elapsed_months)
	)

	if not fresh_start_pass or not required_country_pass:
		return {"passed": false, "campaign_result": {}}

	var monthly_observer: Callable = Callable()
	if collect_step18_3:
		monthly_observer = (
			Step18_3CampaignInvariantTelemetryTest
			.create_monthly_observer()
		)

	var observer_ready_pass: bool = (
		(not collect_step18_3)
		or monthly_observer.is_valid()
	)

	TestLogger.write_line(
		"18.2 Step 18.3 observer Callable: "
		+ ("PASS" if observer_ready_pass else "FAIL")
	)

	if not observer_ready_pass:
		return {"passed": false, "campaign_result": {}}

	var campaign_result: Dictionary = CampaignHarness.run(
		world,
		simulation,
		months,
		monthly_observer
	)

	var requested_months: int = int(
		campaign_result.get("requested_months", months)
	)
	var completed_months: int = int(
		campaign_result.get("completed_months", 0)
	)
	var overall_harness_pass: bool = bool(
		campaign_result.get("overall_pass", false)
	)

	TestLogger.write_line("18.2 requested months: " + str(requested_months))
	TestLogger.write_line("18.2 completed months: " + str(completed_months))
	TestLogger.write_line(
		"18.2 CampaignHarness execution: "
		+ ("PASS" if overall_harness_pass else "FAIL")
	)

	var telemetry_value: Variant = campaign_result.get("telemetry", [])
	var telemetry: Array = telemetry_value if telemetry_value is Array else []
	var monthly_pass: bool = (
		telemetry.size() == completed_months
		and completed_months == months
	)

	for telemetry_variant in telemetry:
		if not telemetry_variant is Dictionary:
			monthly_pass = false
			break

		var month_data: Dictionary = telemetry_variant
		var month_number: int = int(month_data.get("campaign_month", 0))
		var month_structural_pass: bool = bool(
			month_data.get("structural_pass", false)
		)
		var month_snapshot_date_pass: bool = bool(
			month_data.get("snapshot_date_present", false)
		)
		var month_date_pass: bool = bool(
			month_data.get("date_advanced_one_month", false)
		)
		var month_entity_pass: bool = (
			int(month_data.get("entity_count_after", 0))
			== initial_entity_count
		)
		var month_system_pass: bool = bool(
			month_data.get("system_count_stable", false)
		)

		var month_pass: bool = (
			month_structural_pass
			and month_snapshot_date_pass
			and month_date_pass
			and month_entity_pass
			and month_system_pass
		)

		if not month_pass:
			monthly_pass = false

		TestLogger.write_line(
			"18.2 month "
			+ str(month_number)
			+ " structural: "
			+ ("PASS" if month_pass else "FAIL")
			+ " | date="
			+ str(month_data.get("after_date", {}))
			+ " | tick_ms="
			+ str(month_data.get("tick_duration_ms", 0))
		)

		if not month_pass:
			TestLogger.write_line(
				"18.2 first failing month: "
				+ str(month_number)
				+ " | structural=" + str(month_structural_pass)
				+ " | date=" + str(month_date_pass)
				+ " | snapshot_date=" + str(month_snapshot_date_pass)
				+ " | entities=" + str(month_entity_pass)
				+ " | systems=" + str(month_system_pass)
			)
			break

	var end_date: Dictionary = world.current_date.duplicate(true)
	var expected_end_date: Dictionary = _add_months_to_date(start_date, months)
	var final_date_pass: bool = end_date == expected_end_date

	var final_elapsed_months: int = world.get_elapsed_months()
	var expected_elapsed_months: int = initial_elapsed_months + months
	var elapsed_pass: bool = final_elapsed_months == expected_elapsed_months

	var final_snapshot_count: int = simulation.get_snapshot_count()
	var expected_snapshot_count: int = initial_snapshot_count + months
	var snapshot_count_pass: bool = final_snapshot_count == expected_snapshot_count

	var final_entity_count: int = world.get_entity_count()
	var final_entity_pass: bool = final_entity_count == initial_entity_count

	var final_system_count: int = simulation.get_system_count()
	var final_system_pass: bool = final_system_count == initial_system_count

	TestLogger.write_line("18.2 final date: " + str(end_date))
	TestLogger.write_line("18.2 expected final date: " + str(expected_end_date))
	TestLogger.write_line(
		"18.2 final date boundary: "
		+ ("PASS" if final_date_pass else "FAIL")
	)
	TestLogger.write_line(
		"18.2 elapsed month boundary: "
		+ ("PASS" if elapsed_pass else "FAIL")
	)
	TestLogger.write_line(
		"18.2 snapshot count boundary: "
		+ ("PASS" if snapshot_count_pass else "FAIL")
	)
	TestLogger.write_line(
		"18.2 final entity count boundary: "
		+ ("PASS" if final_entity_pass else "FAIL")
	)
	TestLogger.write_line(
		"18.2 final system count boundary: "
		+ ("PASS" if final_system_pass else "FAIL")
	)
	TestLogger.write_line(
		"18.2 campaign length is exactly "
		+ str(months)
		+ " months: "
		+ ("PASS" if completed_months == months else "FAIL")
	)
	TestLogger.write_line(
		"18.2 Step 18.3 observer enabled: "
		+ ("PASS" if collect_step18_3 else "NO")
	)

	var overall_pass: bool = (
		fresh_start_pass
		and required_country_pass
		and overall_harness_pass
		and monthly_pass
		and final_date_pass
		and elapsed_pass
		and snapshot_count_pass
		and final_entity_pass
		and final_system_pass
	)

	TestLogger.write_line(
		"18.2 60-Month Campaign Validation overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)
	TestLogger.write_line(
		"Step 18.2 Dedicated 60-Month Campaign test: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return {
		"passed": overall_pass,
		"campaign_result": campaign_result,
		"step18_3_observer_enabled": collect_step18_3
	}


static func _validate_required_countries(world: WorldState) -> bool:
	if world == null:
		return false

	return (
		world.get_entity("china") != null
		and world.get_entity("india") != null
		and world.get_entity("usa") != null
	)


static func _add_months_to_date(
	start_date: Dictionary,
	months: int
) -> Dictionary:
	var start_year: int = int(start_date.get("year", 0))
	var start_month: int = int(start_date.get("month", 1))
	var start_day: int = int(start_date.get("day", 1))

	var absolute_month: int = start_year * 12 + (start_month - 1) + months
	var final_year: int = int(absolute_month / 12)
	var final_month: int = (absolute_month % 12) + 1

	return {
		"year": final_year,
		"month": final_month,
		"day": start_day
	}
