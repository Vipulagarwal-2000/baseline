class_name Step18_3CampaignInvariantTelemetryTest
extends RefCounted


# ============================================================
# STEP 18.3 — CAMPAIGN INVARIANT / TELEMETRY
# ============================================================
#
# This file is the SINGLE authoritative Step 18.3 class.
#
# IMPORTANT:
#   Keep only ONE project file with class_name
#   Step18_3CampaignInvariantTelemetryTest.
#
# Do NOT keep a second copy named Step18_3CampaignInvariantTelemetryTest.gd
# beside this file. The prior Run 648 symptom is consistent with the
# observer boundary resolving incorrectly while the harness itself remained
# healthy.
#
# Step 18.3 observes the monthly Dictionary already produced by CampaignHarness.
# It does not execute ticks, advance time, or mutate the world.
# ============================================================


const REQUIRED_COUNTRIES: Array[String] = [
	"china",
	"india",
	"usa"
]

const COUNTRY_COMPONENT_IDS: Array[String] = [
	"population",
	"economy",
	"government",
	"resources",
	"research",
	"technology_adoption",
	"technology",
	"military",
	"industry",
	"infrastructure"
]


# ============================================================
# OBSERVER FACTORY
# ============================================================
#
# The callable takes exactly ONE argument: an observation context Dictionary
# containing WorldState, SimulationEngine, and the already-populated monthly
# harness result. The factory itself takes no arguments so the call site remains
# compatible with the normal RunAllTests integration.
# ============================================================

static func create_monthly_observer() -> Callable:
	return func(observer_context: Dictionary) -> Dictionary:
		var world: WorldState = observer_context.get("world") as WorldState
		var simulation: SimulationEngine = observer_context.get("simulation") as SimulationEngine
		var harness_monthly_result_variant: Variant = observer_context.get(
			"monthly_result",
			{}
		)

		if world == null or simulation == null:
			return {
				"schema": "step18_3_observer_error",
				"campaign_month": 0,
				"invariant_pass": false,
				"failure_stage": "observer_context",
				"failure_reason": "Step 18.3 observer context did not contain WorldState and SimulationEngine."
			}

		if not harness_monthly_result_variant is Dictionary:
			return {
				"schema": "step18_3_observer_error",
				"campaign_month": 0,
				"invariant_pass": false,
				"failure_stage": "observer_context",
				"failure_reason": "Step 18.3 observer context did not contain a monthly Dictionary."
			}

		return Step18_3CampaignInvariantTelemetryTest.collect_monthly_telemetry(
			world,
			simulation,
			harness_monthly_result_variant as Dictionary
		)


# ============================================================
# CAMPAIGN RESULT VALIDATION
# ============================================================

static func validate_campaign_result(
	campaign_result: Dictionary,
	expected_months: int = 60
) -> bool:
	TestLogger.section(
		"CAMPAIGN INVARIANT / TELEMETRY COLLECTION — STEP 18.3"
	)

	if campaign_result.is_empty():
		TestLogger.write_line("18.3 campaign result available: FAIL")
		TestLogger.write_line(
			"18.3 first failure: stage=campaign_result | reason=CampaignHarness returned an empty result."
		)
		return false

	TestLogger.write_line("18.3 campaign result available: PASS")

	var telemetry_value: Variant = campaign_result.get("telemetry", [])
	if not telemetry_value is Array:
		TestLogger.write_line("18.3 campaign telemetry container: FAIL")
		TestLogger.write_line(
			"18.3 first failure: stage=telemetry_container | reason=Campaign telemetry is not an Array."
		)
		return false

	var telemetry: Array = telemetry_value
	var requested_months: int = int(
		campaign_result.get("requested_months", expected_months)
	)
	var completed_months: int = int(
		campaign_result.get("completed_months", 0)
	)
	var harness_pass: bool = bool(
		campaign_result.get("overall_pass", false)
	)

	var campaign_length_pass: bool = (
		requested_months == expected_months
		and completed_months == expected_months
		and telemetry.size() == expected_months
	)

	TestLogger.write_line(
		"18.3 requested/completed telemetry month count: "
		+ ("PASS" if campaign_length_pass else "FAIL")
		+ " | requested=" + str(requested_months)
		+ " | completed=" + str(completed_months)
		+ " | telemetry=" + str(telemetry.size())
	)

	var overall_pass: bool = (
		harness_pass
		and campaign_length_pass
	)
	var first_failure_month: int = -1
	var first_failure_stage: String = ""
	var first_failure_reason: String = ""

	for telemetry_variant in telemetry:
		if not telemetry_variant is Dictionary:
			overall_pass = false
			if first_failure_month == -1:
				first_failure_month = 0
				first_failure_stage = "telemetry_container"
				first_failure_reason = (
					"Monthly harness telemetry entry is not a Dictionary."
				)
			continue

		var month_data: Dictionary = telemetry_variant
		var month_number: int = int(month_data.get("campaign_month", 0))
		var observer_value: Variant = month_data.get(
			"step18_3_telemetry",
			null
		)

		if not observer_value is Dictionary:
			overall_pass = false
			if first_failure_month == -1:
				first_failure_month = month_number
				first_failure_stage = "observer_contract"
				first_failure_reason = (
					"Step 18.3 observer did not return a Dictionary."
				)
			continue

		var month_telemetry: Dictionary = observer_value
		var invariant_pass: bool = bool(
			month_telemetry.get("invariant_pass", false)
		)

		if not invariant_pass:
			overall_pass = false
			if first_failure_month == -1:
				first_failure_month = month_number
				first_failure_stage = str(
					month_telemetry.get("failure_stage", "invariant")
				)
				first_failure_reason = str(
					month_telemetry.get(
						"failure_reason",
						"Step 18.3 invariant failure."
					)
				)

		TestLogger.write_line(
			"18.3 month " + str(month_number)
			+ " invariant status: "
			+ ("PASS" if invariant_pass else "FAIL")
			+ " | date="
			+ str(month_telemetry.get("after_date", {}))
			+ " | source="
			+ str(month_telemetry.get("observation_source", ""))
		)

		if not invariant_pass:
			TestLogger.write_line(
				"18.3 month " + str(month_number)
				+ " failure stage="
				+ str(month_telemetry.get("failure_stage", ""))
				+ " | reason="
				+ str(month_telemetry.get("failure_reason", ""))
				+ " | first_invariant="
				+ str(month_telemetry.get("first_failed_invariant", ""))
			)
			TestLogger.write_line(
				"18.3 month " + str(month_number)
				+ " structural_failures="
				+ str(month_telemetry.get("structural_failures", []))
				+ " | domain_failures="
				+ str(month_telemetry.get("domain_failures", []))
			)

	if not overall_pass:
		if first_failure_month == -1:
			first_failure_month = int(
				campaign_result.get("failure_month", -1)
			)
		if first_failure_stage.is_empty():
			first_failure_stage = str(
				campaign_result.get("failure_stage", "campaign")
			)
		if first_failure_reason.is_empty():
			first_failure_reason = str(
				campaign_result.get(
					"failure_reason",
					"Campaign or Step 18.3 validation failed."
				)
			)

		TestLogger.write_line(
			"18.3 first failing month: "
			+ str(first_failure_month)
			+ " | stage=" + first_failure_stage
			+ " | reason=" + first_failure_reason
		)

	TestLogger.write_line(
		"18.3 Campaign Invariant / Telemetry overall: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	return overall_pass


# ============================================================
# MONTHLY COLLECTION
# ============================================================

static func collect_monthly_telemetry(
	world: WorldState,
	simulation: SimulationEngine,
	harness_monthly_result: Dictionary
) -> Dictionary:
	var month_number: int = int(
		harness_monthly_result.get("campaign_month", 0)
	)

	var telemetry: Dictionary = {
		"schema": "step18_3_v3",
		"campaign_month": month_number,
		"before_date": harness_monthly_result.get(
			"before_date", {}
		).duplicate(true),
		"after_date": harness_monthly_result.get(
			"after_date", {}
		).duplicate(true),
		"before_elapsed_months": int(
			harness_monthly_result.get("before_elapsed_months", 0)
		),
		"after_elapsed_months": int(
			harness_monthly_result.get("after_elapsed_months", 0)
		),
		"before_snapshot_count": int(
			harness_monthly_result.get("before_snapshot_count", 0)
		),
		"after_snapshot_count": int(
			harness_monthly_result.get("after_snapshot_count", 0)
		),
		"snapshot_date": harness_monthly_result.get(
			"snapshot_date", {}
		).duplicate(true),
		"snapshot_date_present": bool(
			harness_monthly_result.get("snapshot_date_present", false)
		),
		"entity_count_before": int(
			harness_monthly_result.get("entity_count_before", 0)
		),
		"entity_count_after": int(
			harness_monthly_result.get("entity_count_after", 0)
		),
		"system_count_after": int(
			harness_monthly_result.get("system_count_after", 0)
		),
		"expected_system_count": int(
			harness_monthly_result.get("system_count", 0)
		),
		"pending_actions_after": int(
			harness_monthly_result.get("pending_actions_after", 0)
		),
		"engine_ready_after_tick": bool(
			harness_monthly_result.get("engine_ready_after_tick", false)
		),
		"observation_source": "campaign_harness_monthly_result",
		"structural_invariants": {},
		"domain_invariants": {},
		"structural_failures": [],
		"domain_failures": [],
		"country_telemetry": {},
		"world_telemetry": {},
		"invariant_pass": false,
		"failure_stage": "",
		"failure_reason": "",
		"first_failed_invariant": ""
	}

	if world == null:
		telemetry["failure_stage"] = "input_world"
		telemetry["failure_reason"] = "WorldState is null."
		return telemetry

	if simulation == null:
		telemetry["failure_stage"] = "input_simulation"
		telemetry["failure_reason"] = "SimulationEngine is null."
		return telemetry

	if harness_monthly_result.is_empty():
		telemetry["failure_stage"] = "harness_observation"
		telemetry["failure_reason"] = (
			"CampaignHarness did not provide a monthly post-tick result."
		)
		return telemetry

	# Structural data comes only from the authoritative harness result.
	telemetry["structural_invariants"] = (
		_validate_structural_invariants(harness_monthly_result)
	)

	# Domain telemetry reads the already-completed live state. These reads are
	# observational only; no domain values are written here.
	telemetry["country_telemetry"] = _capture_country_telemetry(world)
	telemetry["world_telemetry"] = _capture_world_telemetry(
		world,
		simulation
	)

	var country_numeric_scan: Dictionary = _validate_recursive_numeric_state(
		telemetry["country_telemetry"]
	)
	var world_numeric_scan: Dictionary = _validate_recursive_numeric_state(
		telemetry["world_telemetry"]
	)

	var required_countries_pass: bool = _required_countries_present(world)
	var relationship_pass: bool = _relationships_finite(world)

	telemetry["domain_invariants"] = {
		"required_countries_present": required_countries_pass,
		"country_numeric_values_finite": bool(
			country_numeric_scan.get("passed", false)
		),
		"world_numeric_values_finite": bool(
			world_numeric_scan.get("passed", false)
		),
		"relationship_values_finite": relationship_pass
	}

	telemetry["country_numeric_failure_path"] = str(
		country_numeric_scan.get("failure_path", "")
	)
	telemetry["world_numeric_failure_path"] = str(
		world_numeric_scan.get("failure_path", "")
	)

	var structural_failures: Array[String] = _collect_false_keys(
		telemetry["structural_invariants"]
	)
	var domain_failures: Array[String] = _collect_false_keys(
		telemetry["domain_invariants"]
	)

	telemetry["structural_failures"] = structural_failures
	telemetry["domain_failures"] = domain_failures
	telemetry["invariant_pass"] = (
		structural_failures.is_empty()
		and domain_failures.is_empty()
	)

	if not bool(telemetry["invariant_pass"]):
		if not structural_failures.is_empty():
			telemetry["failure_stage"] = "structural"
			telemetry["first_failed_invariant"] = str(
				structural_failures[0]
			)
			telemetry["failure_reason"] = _describe_failure(
				"structural",
				str(structural_failures[0]),
				harness_monthly_result
			)
		elif not domain_failures.is_empty():
			telemetry["failure_stage"] = "domain"
			telemetry["first_failed_invariant"] = str(
				domain_failures[0]
			)
			telemetry["failure_reason"] = _describe_failure(
				"domain",
				str(domain_failures[0]),
				telemetry
			)

	return telemetry


# ============================================================
# STRUCTURAL INVARIANTS
# ============================================================

static func _validate_structural_invariants(
	harness_monthly_result: Dictionary
) -> Dictionary:
	return {
		"engine_ready": bool(
			harness_monthly_result.get("engine_ready_after_tick", false)
		),
		"date_advanced_exactly_one_month": bool(
			harness_monthly_result.get("date_advanced_one_month", false)
		),
		"snapshot_added_exactly_once": bool(
			harness_monthly_result.get("snapshot_added", false)
		),
		"entity_count_positive": bool(
			harness_monthly_result.get("entity_count_positive", false)
		),
		"entity_count_stable": int(
			harness_monthly_result.get("entity_count_after", 0)
		) == int(
			harness_monthly_result.get("entity_count_before", 0)
		),
		"system_count_stable": bool(
			harness_monthly_result.get("system_count_stable", false)
		),
		"pending_action_count_non_negative": int(
			harness_monthly_result.get("pending_actions_after", -1)
		) >= 0,
		"snapshot_date_valid": bool(
			harness_monthly_result.get("snapshot_date_present", false)
		),
		"after_date_present": _valid_date_dictionary(
			harness_monthly_result.get("after_date", {})
		)
	}


# ============================================================
# DOMAIN TELEMETRY
# ============================================================

static func _capture_country_telemetry(world: WorldState) -> Dictionary:
	var result: Dictionary = {}
	if world == null:
		return result

	for country_id in REQUIRED_COUNTRIES:
		var entity: SimEntity = world.get_entity(country_id) as SimEntity
		if entity == null:
			result[country_id] = {"present": false}
			continue

		var country_state: Dictionary = {
			"present": true,
			"entity_type": entity.entity_type,
			"relationships": entity.relationships.duplicate(true),
			"sim_metadata": entity.get_all_sim_metadata().duplicate(true),
			"components": {}
		}

		for component_id in COUNTRY_COMPONENT_IDS:
			var component = entity.get_component(component_id)
			if component == null:
				continue

			var component_state: Dictionary = {}
			var raw_state: Variant = component.state
			if raw_state is Dictionary:
				component_state = raw_state.duplicate(true)

			country_state["components"][component_id] = component_state

		result[country_id] = country_state

	return result


static func _capture_world_telemetry(
	world: WorldState,
	simulation: SimulationEngine
) -> Dictionary:
	var result: Dictionary = {}
	if world == null or simulation == null:
		return result

	result["current_date"] = world.current_date.duplicate(true)
	result["elapsed_months"] = world.get_elapsed_months()
	result["entity_count"] = world.get_entity_count()
	result["system_count"] = simulation.get_system_count()
	result["pending_action_count"] = simulation.get_pending_action_count()
	result["snapshot_count"] = simulation.get_snapshot_count()
	result["trade_agreement_count"] = world.get_trade_agreement_count()
	result["trade_route_count"] = world.get_trade_route_count()
	result["trade_transaction_count"] = world.get_trade_transaction_count()
	result["active_event_count"] = world.active_events.size()
	result["completed_event_count"] = world.completed_events.size()
	result["active_conflict_count"] = world.active_conflicts.size()
	result["completed_conflict_count"] = world.completed_conflicts.size()

	return result


# ============================================================
# VALIDATION HELPERS
# ============================================================

static func _required_countries_present(world: WorldState) -> bool:
	if world == null:
		return false

	for country_id in REQUIRED_COUNTRIES:
		if world.get_entity(country_id) == null:
			return false

	return true


static func _relationships_finite(world: WorldState) -> bool:
	if world == null:
		return false

	for country_id in REQUIRED_COUNTRIES:
		var entity: SimEntity = world.get_entity(country_id) as SimEntity
		if entity == null:
			return false

		var scan: Dictionary = _validate_recursive_numeric_state(
			entity_relationships(entity)
		)
		if not bool(scan.get("passed", false)):
			return false

	return true


static func entity_relationships(entity: SimEntity) -> Dictionary:
	if entity == null:
		return {}
	return entity.relationships


static func _validate_recursive_numeric_state(value: Variant, path: String = "root") -> Dictionary:
	if value is Dictionary:
		var dictionary_value: Dictionary = value
		for key in dictionary_value.keys():
			var child: Dictionary = _validate_recursive_numeric_state(
				dictionary_value[key],
				path + "." + str(key)
			)
			if not bool(child.get("passed", false)):
				return child
		return {"passed": true, "failure_path": ""}

	if value is Array:
		var array_value: Array = value
		for index in range(array_value.size()):
			var child_array: Dictionary = _validate_recursive_numeric_state(
				array_value[index],
				path + "[" + str(index) + "]"
			)
			if not bool(child_array.get("passed", false)):
				return child_array
		return {"passed": true, "failure_path": ""}

	if value is float:
		if not is_finite(float(value)):
			return {
				"passed": false,
				"failure_path": path
			}
		return {"passed": true, "failure_path": ""}

	return {"passed": true, "failure_path": ""}


static func _collect_false_keys(values: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	for key in values.keys():
		var value: Variant = values[key]
		if value is bool and not bool(value):
			failures.append(str(key))
	return failures


static func _describe_failure(
	stage: String,
	invariant: String,
	context: Dictionary
) -> String:
	if stage == "structural":
		if invariant == "engine_ready":
			return "SimulationEngine is not ready after the monthly tick."
		if invariant == "date_advanced_exactly_one_month":
			return (
				"Elapsed month count did not advance by exactly one month."
			)
		if invariant == "snapshot_added_exactly_once":
			return "Snapshot count did not increase by exactly one."
		if invariant == "entity_count_positive":
			return "World entity count became non-positive."
		if invariant == "entity_count_stable":
			return "World entity count changed during the campaign month."
		if invariant == "system_count_stable":
			return "Registered system count changed during the campaign month."
		if invariant == "pending_action_count_non_negative":
			return "Pending action count became negative."
		if invariant == "snapshot_date_valid":
			return "Latest snapshot did not contain a valid date."
		if invariant == "after_date_present":
			return "Post-tick world date is missing or incomplete."

	if stage == "domain":
		if invariant == "required_countries_present":
			return "China, India, or USA is missing from the post-tick world."
		if invariant == "country_numeric_values_finite":
			return (
				"A non-finite numeric value exists in country telemetry at path: "
				+ str(context.get("country_numeric_failure_path", ""))
			)
		if invariant == "world_numeric_values_finite":
			return (
				"A non-finite numeric value exists in world telemetry at path: "
				+ str(context.get("world_numeric_failure_path", ""))
			)
		if invariant == "relationship_values_finite":
			return "A required country relationship value is non-finite."

	return "Step 18.3 invariant failed: " + stage + "." + invariant


static func _valid_date_dictionary(value: Variant) -> bool:
	if not value is Dictionary:
		return false

	var date: Dictionary = value
	return (
		date.has("year")
		and date.has("month")
		and date.has("day")
	)
