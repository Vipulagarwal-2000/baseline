class_name CampaignHarness
extends RefCounted


# ============================================================
# STEP 18.1 / 18.2 MONTHLY CAMPAIGN HARNESS
# ============================================================
#
# Execution infrastructure only.
#
# The harness owns exactly one responsibility:
#   call the existing SimulationEngine.tick_month() repeatedly and record
#   the authoritative monthly boundary produced by that tick.
#
# Optional observers receive ONE argument only:
#   the complete monthly harness result Dictionary.
#
# This deliberately avoids a long positional callback signature. The prior
# Step 18.3 failure had an integration boundary where the observer's callable
# contract could differ from the harness call. A single Dictionary contract
# removes that failure mode.
# ============================================================


const DEFAULT_MONTHS: int = 60


# ============================================================
# PUBLIC ENTRY POINT
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine,
	months: int = DEFAULT_MONTHS,
	monthly_observer: Callable = Callable()
) -> Dictionary:
	var report: Dictionary = {
		"overall_pass": false,
		"requested_months": max(0, months),
		"completed_months": 0,
		"start_date": {},
		"end_date": {},
		"start_elapsed_months": 0,
		"end_elapsed_months": 0,
		"start_snapshot_count": 0,
		"end_snapshot_count": 0,
		"system_count": 0,
		"telemetry": [],
		"failure_month": -1,
		"failure_stage": "",
		"failure_reason": "",
		"warnings": [],
		"duration_ms": 0,
		"monthly_observer_enabled": monthly_observer.is_valid()
	}

	if world == null:
		report["failure_stage"] = "initialization"
		report["failure_reason"] = "WorldState is null."
		return report

	if simulation == null:
		report["failure_stage"] = "initialization"
		report["failure_reason"] = "SimulationEngine is null."
		return report

	if not simulation.is_ready():
		report["failure_stage"] = "initialization"
		report["failure_reason"] = "SimulationEngine is not ready."
		return report

	if months < 0:
		report["failure_stage"] = "initialization"
		report["failure_reason"] = "Requested month count cannot be negative."
		return report

	var expected_system_count: int = simulation.get_system_count()
	var start_snapshot_count: int = simulation.get_snapshot_count()
	var start_date: Dictionary = world.current_date.duplicate(true)
	var start_elapsed_months: int = world.get_elapsed_months()

	report["system_count"] = expected_system_count
	report["start_snapshot_count"] = start_snapshot_count
	report["start_date"] = start_date.duplicate(true)
	report["start_elapsed_months"] = start_elapsed_months

	var started_at_ms: int = Time.get_ticks_msec()

	if months == 0:
		report["end_date"] = world.current_date.duplicate(true)
		report["end_elapsed_months"] = world.get_elapsed_months()
		report["end_snapshot_count"] = simulation.get_snapshot_count()
		report["overall_pass"] = true
		report["duration_ms"] = Time.get_ticks_msec() - started_at_ms
		return report

	for month_index in range(months):
		var month_result: Dictionary = _run_one_month(
			world,
			simulation,
			month_index + 1,
			expected_system_count,
			monthly_observer
		)

		(report["telemetry"] as Array).append(month_result)

		if not bool(month_result.get("structural_pass", false)):
			report["failure_month"] = month_index + 1
			report["failure_stage"] = str(
				month_result.get("failure_stage", "monthly_execution")
			)
			report["failure_reason"] = str(
				month_result.get("failure_reason", "Unknown monthly failure.")
			)
			break

		report["completed_months"] = month_index + 1

	report["end_date"] = world.current_date.duplicate(true)
	report["end_elapsed_months"] = world.get_elapsed_months()
	report["end_snapshot_count"] = simulation.get_snapshot_count()
	report["duration_ms"] = Time.get_ticks_msec() - started_at_ms

	report["overall_pass"] = (
		report["completed_months"] == months
		and str(report["failure_reason"]).is_empty()
	)

	return report


# ============================================================
# SINGLE MONTH
# ============================================================

static func _run_one_month(
	world: WorldState,
	simulation: SimulationEngine,
	month_number: int,
	expected_system_count: int,
	monthly_observer: Callable = Callable()
) -> Dictionary:
	var before_date: Dictionary = world.current_date.duplicate(true)
	var before_elapsed_months: int = world.get_elapsed_months()
	var before_snapshot_count: int = simulation.get_snapshot_count()
	var before_entity_count: int = world.get_entity_count()
	var before_pending_actions: int = simulation.get_pending_action_count()
	var tick_started_at_ms: int = Time.get_ticks_msec()

	var telemetry: Dictionary = {
		"campaign_month": month_number,
		"before_date": before_date,
		"after_date": {},
		"before_elapsed_months": before_elapsed_months,
		"after_elapsed_months": 0,
		"date_advanced_one_month": false,
		"before_snapshot_count": before_snapshot_count,
		"after_snapshot_count": 0,
		"snapshot_added": false,
		"snapshot_date_present": false,
		"snapshot_date": {},
		"entity_count_before": before_entity_count,
		"entity_count_after": 0,
		"entity_count_positive": false,
		"pending_actions_before": before_pending_actions,
		"pending_actions_after": 0,
		"system_count": expected_system_count,
		"system_count_after": 0,
		"system_count_stable": false,
		"engine_ready_after_tick": false,
		"tick_duration_ms": 0,
		"structural_pass": false,
		"failure_stage": "",
		"failure_reason": "",
		"step18_3_telemetry": {}
	}

	if not simulation.is_ready():
		telemetry["failure_stage"] = "pre_tick"
		telemetry["failure_reason"] = (
			"SimulationEngine became unavailable before monthly tick."
		)
		return telemetry

	# ------------------------------------------------------------
	# AUTHORITATIVE MONTHLY EXECUTION
	# ------------------------------------------------------------

	simulation.tick_month()

	telemetry["tick_duration_ms"] = (
		Time.get_ticks_msec() - tick_started_at_ms
	)

	# ------------------------------------------------------------
	# AUTHORITATIVE POST-TICK OBSERVATION
	# ------------------------------------------------------------

	var after_date: Dictionary = world.current_date.duplicate(true)
	var after_elapsed_months: int = world.get_elapsed_months()
	var after_snapshot_count: int = simulation.get_snapshot_count()
	var after_entity_count: int = world.get_entity_count()
	var after_pending_actions: int = simulation.get_pending_action_count()
	var after_system_count: int = simulation.get_system_count()
	var latest_snapshot: WorldSnapshot = simulation.get_latest_snapshot()

	telemetry["after_date"] = after_date
	telemetry["after_elapsed_months"] = after_elapsed_months
	telemetry["after_snapshot_count"] = after_snapshot_count
	telemetry["entity_count_after"] = after_entity_count
	telemetry["pending_actions_after"] = after_pending_actions
	telemetry["system_count_after"] = after_system_count
	telemetry["engine_ready_after_tick"] = simulation.is_ready()

	telemetry["date_advanced_one_month"] = (
		after_elapsed_months == before_elapsed_months + 1
	)
	telemetry["snapshot_added"] = (
		after_snapshot_count == before_snapshot_count + 1
	)
	telemetry["entity_count_positive"] = after_entity_count > 0
	telemetry["system_count_stable"] = (
		after_system_count == expected_system_count
	)

	if latest_snapshot != null:
		telemetry["snapshot_date"] = latest_snapshot.date.duplicate(true)
		telemetry["snapshot_date_present"] = _valid_snapshot_date(
			latest_snapshot.date
		)

	# ------------------------------------------------------------
	# OPTIONAL OBSERVER
	# ------------------------------------------------------------
	# The observer receives ONE canonical Dictionary. This is the same object
	# family used by Step 18.2 to validate the monthly boundary.

	if monthly_observer.is_valid():
		var observer_context: Dictionary = {
			"world": world,
			"simulation": simulation,
			"monthly_result": telemetry.duplicate(true)
		}
		var observer_result: Variant = monthly_observer.call(observer_context)

		if observer_result is Dictionary:
			telemetry["step18_3_telemetry"] = observer_result
		else:
			telemetry["step18_3_telemetry"] = {
				"schema": "step18_3_observer_error",
				"campaign_month": month_number,
				"invariant_pass": false,
				"failure_stage": "observer_contract",
				"failure_reason": (
					"Monthly observer did not return a Dictionary."
				)
			}
	else:
		# Step 18.3 is optional. An invalid observer is therefore recorded as
		# absent rather than turning the Step 18.2 harness itself into a failure.
		telemetry["step18_3_telemetry"] = {}

	# ------------------------------------------------------------
	# STEP 18.1 / 18.2 STRUCTURAL ACCEPTANCE
	# ------------------------------------------------------------

	var structural_pass: bool = (
		bool(telemetry["engine_ready_after_tick"])
		and bool(telemetry["date_advanced_one_month"])
		and bool(telemetry["snapshot_added"])
		and bool(telemetry["entity_count_positive"])
		and bool(telemetry["system_count_stable"])
	)
	telemetry["structural_pass"] = structural_pass

	if not structural_pass:
		if not bool(telemetry["engine_ready_after_tick"]):
			telemetry["failure_stage"] = "post_tick_engine"
			telemetry["failure_reason"] = (
				"SimulationEngine is not ready after monthly tick."
			)
		elif not bool(telemetry["date_advanced_one_month"]):
			telemetry["failure_stage"] = "date_advance"
			telemetry["failure_reason"] = (
				"World elapsed month counter did not advance by exactly one month."
			)
		elif not bool(telemetry["snapshot_added"]):
			telemetry["failure_stage"] = "snapshot"
			telemetry["failure_reason"] = (
				"Monthly tick did not produce exactly one additional snapshot."
			)
		elif not bool(telemetry["entity_count_positive"]):
			telemetry["failure_stage"] = "world_state"
			telemetry["failure_reason"] = (
				"World contains no entities after monthly tick."
			)
		elif not bool(telemetry["system_count_stable"]):
			telemetry["failure_stage"] = "system_registry"
			telemetry["failure_reason"] = (
				"Registered system count changed during campaign tick."
			)

	return telemetry


static func _valid_snapshot_date(value: Variant) -> bool:
	if not value is Dictionary:
		return false

	var date: Dictionary = value
	return (
		date.has("year")
		and date.has("month")
		and date.has("day")
	)
