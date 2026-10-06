class_name Step19_9EventDrivenScenarioValidationTest
extends RefCounted


# ============================================================
# STEP 19.9 — EVENT-DRIVEN SCENARIO VALIDATION
# ============================================================
#
# Controlled event-driven causal experiment:
#
# authoritative military state
#        ↓
# real EVENTS phase
#        ↓
# EventSimulationIntegrationSystem
#        ↓
# EventTriggerEvaluator
#        ↓
# EventExecutor / EventEffectExecutor
#        ↓
# authoritative government state
#        ↓
# next monthly WORLD_UPDATE
#        ↓
# GovernmentSystem consumes the event consequence
#        ↓
# one-time repeatability prevents duplicate execution
#
# This test deliberately reuses the live E13 event integration boundary.
# It does not introduce an EventSynchronizer execution path, an Event→
# ActionRequest interface, or a second domain engine.
#
# The scenario uses the existing military.at_war state as the trigger
# condition and government.political_pressure as the authoritative event
# effect. Both are existing domain-owned state paths.
#
# The test runs in a fresh live simulation context created through the
# project's main.gd bootstrap so the active regression-suite world is not
# consumed by the event scenario.
# ============================================================

const TARGET_COUNTRY_ID: String = "india"
const EVENT_ID: String = "step19_9_war_shock_event"
const EVENT_TARGET_PRESSURE: float = 0.80
const INITIAL_NON_WAR_STATE: bool = false
const SHOCK_WAR_STATE: bool = true

const MAIN_SCRIPT: Script = preload("res://scripts/main.gd")


class TestHistorySink:
	extends RefCounted

	var entries: Array = []

	func record_event_result(
		entry: Dictionary
	) -> bool:
		entries.append(
			entry.duplicate(true)
		)
		return true

	func get_entries() -> Array:
		return entries.duplicate(true)


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func _log_result(
	label: String,
	passed: bool
) -> void:
	TestLogger.write_line(
		label + ": " + _pass_fail(passed)
	)


static func _log_diagnostic(
	label: String,
	value
) -> void:
	TestLogger.write_line(
		"19.9 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


static func _bootstrap_context() -> Dictionary:
	var bootstrap: Node = MAIN_SCRIPT.new() as Node

	if bootstrap == null:
		return {}

	var context: Variant = bootstrap.call(
		"_create_simulation_context"
	)

	if typeof(context) != TYPE_DICTIONARY:
		return {}

	return context


static func _get_registered_system(
	simulation: SimulationEngine,
	system_name: String
) -> SimulationSystem:
	if simulation == null:
		return null

	return simulation.get_system(system_name) as SimulationSystem


static func _get_component(
	world: WorldState,
	entity_id: String,
	component_name: String
) -> SimComponent:
	if world == null:
		return null

	var entity: SimEntity = (
		world.get_entity(entity_id)
		as SimEntity
	)

	if entity == null:
		return null

	return entity.get_component(component_name) as SimComponent


static func _register_event(
	integration: EventSimulationIntegrationSystem
) -> bool:
	if integration == null:
		return false

	var definition: EventDefinition = EventDefinition.new(
		EVENT_ID,
		"Step 19.9 War Shock Event",
		"Synthetic event used to validate a live event-driven causal scenario.",
		"war",
		"country"
	)

	var condition: EventCondition = EventCondition.new(
		"military.at_war",
		EventCondition.OPERATOR_EQUAL,
		SHOCK_WAR_STATE
	)

	var effect: EventEffect = EventEffect.new(
		"government.political_pressure",
		EventEffect.OPERATION_SET,
		EVENT_TARGET_PRESSURE
	)

	return integration.register_event(
		definition,
		[condition],
		[effect],
		[TARGET_COUNTRY_ID],
		EventRepeatabilityPolicy.one_time()
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"STEP 19.9 — EVENT-DRIVEN SCENARIO VALIDATION"
	)

	var passed: bool = true

	# ------------------------------------------------------------
	# ACTIVE-SUITE FIXTURE SAFETY
	# ------------------------------------------------------------

	var primary_before: WorldSnapshot = WorldSnapshot.new()
	if world != null:
		primary_before.capture(world)

	var primary_boundary_valid: bool = (
		world != null
		and simulation != null
		and primary_before != null
	)

	_log_result(
		"Primary active-suite world is available before 19.9 isolation",
		primary_boundary_valid
	)
	passed = passed and primary_boundary_valid

	if not primary_boundary_valid:
		return false

	# ------------------------------------------------------------
	# FRESH LIVE CONTEXT
	# ------------------------------------------------------------

	var context: Dictionary = _bootstrap_context()
	var scenario_world: WorldState = context.get(
		"world",
		null
	) as WorldState
	var scenario_simulation: SimulationEngine = context.get(
		"simulation",
		null
	) as SimulationEngine

	var context_valid: bool = (
		scenario_world != null
		and scenario_simulation != null
	)

	_log_result(
		"Fresh live simulation context available for 19.9",
		context_valid
	)
	passed = passed and context_valid

	if not context_valid:
		return false

	# ------------------------------------------------------------
	# LIVE SYSTEM AVAILABILITY
	# ------------------------------------------------------------

	var integration: EventSimulationIntegrationSystem = (
		_get_registered_system(
			scenario_simulation,
			"event_simulation_integration"
		)
		as EventSimulationIntegrationSystem
	)

	var government_system: GovernmentSystem = (
		_get_registered_system(
			scenario_simulation,
			"government_system"
		)
		as GovernmentSystem
	)

	var event_system_pass: bool = integration != null
	var government_system_pass: bool = government_system != null

	_log_result(
		"Registered EventSimulationIntegrationSystem exists",
		event_system_pass
	)
	_log_result(
		"Registered GovernmentSystem exists",
		government_system_pass
	)

	passed = passed and event_system_pass and government_system_pass

	if not (event_system_pass and government_system_pass):
		return false

	var india: SimEntity = (
		scenario_world.get_entity(TARGET_COUNTRY_ID)
		as SimEntity
	)

	var military: SimComponent = _get_component(
		scenario_world,
		TARGET_COUNTRY_ID,
		"military"
	)
	var government: SimComponent = _get_component(
		scenario_world,
		TARGET_COUNTRY_ID,
		"government"
	)

	var fixture_pass: bool = (
		india != null
		and military != null
		and government != null
	)

	_log_result(
		"India / military / government fixtures available",
		fixture_pass
	)
	passed = passed and fixture_pass

	if not fixture_pass:
		return false

	# ------------------------------------------------------------
	# EVENT-INTEGRATION FIXTURE SAFETY
	# ------------------------------------------------------------

	var initial_registration_count: int = (
		integration.get_registration_count()
	)

	var registration_fixture_pass: bool = (
		initial_registration_count == 0
	)

	_log_result(
		"19.9 event registration fixture starts empty",
		registration_fixture_pass
	)
	passed = passed and registration_fixture_pass

	if not registration_fixture_pass:
		_log_diagnostic(
			"unexpected_registration_count",
			initial_registration_count
		)
		return false

	var original_military_state: Dictionary = (
		military.state.duplicate(true)
	)
	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)
	var original_date: Dictionary = (
		scenario_world.current_date.duplicate(true)
	)
	var original_repeatability_state: Dictionary = (
		integration.get_repeatability_controller().snapshot_state()
	)
	var original_history_sink: Object = (
		integration.get_history_sink()
	)

	integration.clear_registrations()
	integration.get_repeatability_controller().clear_all()

	var history_sink: TestHistorySink = TestHistorySink.new()
	integration.set_history_sink(history_sink)

	# ------------------------------------------------------------
	# BASELINE / NON-ELIGIBLE MONTH
	# ------------------------------------------------------------

	military.set_state(
		"at_war",
		INITIAL_NON_WAR_STATE
	)

	var baseline_war_state: bool = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	var baseline_trigger_input_pass: bool = (
		baseline_war_state == INITIAL_NON_WAR_STATE
	)

	_log_result(
		"19.9 baseline military trigger state is non-war",
		baseline_trigger_input_pass
	)
	passed = passed and baseline_trigger_input_pass

	var registration_pass: bool = _register_event(integration)

	_log_result(
		"19.9 live E13 event registration succeeds",
		registration_pass
	)
	passed = passed and registration_pass

	if not registration_pass:
		integration.clear_registrations()
		return false

	# E13 records a blocked EventResult when the trigger condition is false.
	# "Dormant" therefore means: no execution/effects, not "no result".
	scenario_simulation.tick_month()

	var baseline_results: Array = integration.get_last_results()
	var baseline_history: Array = history_sink.get_entries()

	var baseline_result: Dictionary = {}
	if not baseline_results.is_empty():
		baseline_result = baseline_results[baseline_results.size() - 1]

	var baseline_history_entry: Dictionary = {}
	if not baseline_history.is_empty():
		baseline_history_entry = baseline_history[baseline_history.size() - 1]

	var dormant_pass: bool = (
		baseline_results.size() == 1
		and baseline_result.get("event_id", "") == EVENT_ID
		and baseline_result.get("status", "") == EventResult.STATUS_BLOCKED
		and not bool(baseline_result.get("eligible", true))
		and not bool(baseline_result.get("effects_executed", true))
		and baseline_history.size() == 1
		and baseline_history_entry.get("event_id", "") == EVENT_ID
		and baseline_history_entry.get("status", "") == EventResult.STATUS_BLOCKED
		and not bool(baseline_history_entry.get("eligible", true))
		and not bool(baseline_history_entry.get("effects_executed", true))
	)

	_log_result(
		"19.9 event remains dormant while trigger condition is false",
		dormant_pass
	)
	passed = passed and dormant_pass

	if not dormant_pass:
		_log_diagnostic(
			"baseline_results",
			baseline_results
		)
		_log_diagnostic(
			"baseline_history",
			baseline_history
		)

	# ------------------------------------------------------------
	# SHOCK MONTH — LIVE EVENTS PHASE
	# ------------------------------------------------------------

	military.set_state(
		"at_war",
		SHOCK_WAR_STATE
	)

	var shock_trigger_state: bool = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	var shock_input_pass: bool = (
		shock_trigger_state == SHOCK_WAR_STATE
	)

	_log_result(
		"19.9 authoritative military shock trigger is enabled",
		shock_input_pass
	)
	passed = passed and shock_input_pass

	var month_n_date: String = scenario_world.get_date_string()

	scenario_simulation.tick_month()

	var shock_government_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)
	var shock_results: Array = integration.get_last_results()
	var shock_history: Array = history_sink.get_entries()

	var shock_result: Dictionary = {}
	if not shock_results.is_empty():
		shock_result = shock_results[shock_results.size() - 1]

	var shock_history_entry: Dictionary = {}
	if not shock_history.is_empty():
		shock_history_entry = shock_history[shock_history.size() - 1]

	var event_execution_pass: bool = (
		is_equal_approx(
			shock_government_pressure,
			EVENT_TARGET_PRESSURE
		)
		and shock_results.size() == 1
		and shock_result.get("event_id", "") == EVENT_ID
		and shock_result.get("status", "") == EventResult.STATUS_EXECUTED
		and bool(shock_result.get("eligible", false))
		and shock_history.size() == 2
		and shock_history_entry.get("event_id", "") == EVENT_ID
		and shock_history_entry.get("status", "") == EventResult.STATUS_EXECUTED
		and bool(shock_history_entry.get("eligible", false))
	)

	_log_result(
		"19.9 event fires in the real EVENTS phase and changes authoritative government state",
		event_execution_pass
	)
	passed = passed and event_execution_pass

	if not event_execution_pass:
		_log_diagnostic(
			"shock_government_pressure",
			shock_government_pressure
		)
		_log_diagnostic(
			"shock_results",
			shock_results
		)
		_log_diagnostic(
			"shock_history",
			shock_history
		)

	# ------------------------------------------------------------
	# NEXT-MONTH DOMAIN CONSUMPTION
	# ------------------------------------------------------------

	var month_n_plus_one_date_before: String = (
		scenario_world.get_date_string()
	)

	scenario_simulation.tick_month()

	var consumed_previous_pressure: float = float(
		government.get_state(
			"previous_pressure",
			-1.0
		)
	)

	var month_n_plus_one_results: Array = (
		integration.get_last_results()
	)
	var month_n_plus_one_history: Array = (
		history_sink.get_entries()
	)

	var downstream_consumption_pass: bool = (
		is_equal_approx(
			consumed_previous_pressure,
			EVENT_TARGET_PRESSURE
		)
		and month_n_plus_one_results.is_empty()
		and month_n_plus_one_history.size() == 2
		and month_n_plus_one_history[month_n_plus_one_history.size() - 1].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
	)

	_log_result(
		"19.9 next-month GovernmentSystem consumes the event consequence",
		downstream_consumption_pass
	)
	passed = passed and downstream_consumption_pass

	if not downstream_consumption_pass:
		_log_diagnostic(
			"consumed_previous_pressure",
			consumed_previous_pressure
		)
		_log_diagnostic(
			"month_n_plus_one_results",
			month_n_plus_one_results
		)
		_log_diagnostic(
			"month_n_plus_one_history",
			month_n_plus_one_history
		)

	# ------------------------------------------------------------
	# REPEATABILITY / TEMPORAL BOUNDARY
	# ------------------------------------------------------------

	var one_time_pass: bool = (
		month_n_plus_one_results.is_empty()
		and month_n_plus_one_history.size() == 2
		and month_n_plus_one_history[month_n_plus_one_history.size() - 1].get(
			"event_id",
			""
		) == EVENT_ID
		and month_n_plus_one_history[month_n_plus_one_history.size() - 1].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
	)

	_log_result(
		"19.9 one-time event does not re-execute on the next month",
		one_time_pass
	)
	passed = passed and one_time_pass

	var date_advanced_pass: bool = (
		scenario_world.get_date_string() != month_n_date
		and scenario_world.get_date_string() != month_n_plus_one_date_before
	)

	_log_result(
		"19.9 normal monthly boundary advances across the scenario",
		date_advanced_pass
	)
	passed = passed and date_advanced_pass

	# ------------------------------------------------------------
	# PRIMARY WORLD REMAINS UNTOUCHED
	# ------------------------------------------------------------

	var primary_after: WorldSnapshot = WorldSnapshot.new()
	primary_after.capture(world)

	var primary_isolation_pass: bool = (
		primary_after.date == primary_before.date
		and primary_after.entities == primary_before.entities
		and primary_after.trade_agreements == primary_before.trade_agreements
		and primary_after.trade_routes == primary_before.trade_routes
		and primary_after.trade_transactions == primary_before.trade_transactions
	)

	_log_result(
		"19.9 isolated event scenario leaves the active-suite world unchanged",
		primary_isolation_pass
	)
	passed = passed and primary_isolation_pass

	# ------------------------------------------------------------
	# LOCAL FIXTURE RESTORATION
	# ------------------------------------------------------------

	military.state = original_military_state.duplicate(true)
	government.state = original_government_state.duplicate(true)
	scenario_world.current_date = original_date.duplicate(true)

	integration.clear_registrations()
	integration.get_repeatability_controller().restore_state(
		original_repeatability_state
	)
	integration.set_history_sink(
		original_history_sink
	)

	var restoration_pass: bool = (
		military.state == original_military_state
		and government.state == original_government_state
		and scenario_world.current_date == original_date
		and integration.get_registration_count() == initial_registration_count
		and integration.get_history_sink() == original_history_sink
		and integration.get_repeatability_controller().snapshot_state()
			== original_repeatability_state
	)

	_log_result(
		"19.9 event integration and local domain fixture restore correctly",
		restoration_pass
	)
	passed = passed and restoration_pass

	TestLogger.write_line(
		"Step 19.9 Event-Driven Scenario Validation test: "
		+ _pass_fail(passed)
	)

	return passed
