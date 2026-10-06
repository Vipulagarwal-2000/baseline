class_name EventSimulationIntegrationTest
extends RefCounted


# ============================================================
# E13 — LIVE SIMULATION INTEGRATION TEST
# ============================================================
#
# Acceptance:
# - registered E13 system exists
# - event is processed from the real SimulationEngine EVENTS phase
# - condition is evaluated against the live WorldState
# - eligible event executes through EventExecutor
# - authoritative world state changes
# - EventResult is produced
# - result reaches the E12 history bridge
# - repeatability prevents a second execution
# - a blocked event leaves state unchanged
# - monthly simulation remains healthy
#
# IMPORTANT FIX FROM RUN 627:
#
# The previous fixture used `government.stability`. That field is a
# live production state updated by GovernmentSystem during WORLD_UPDATE,
# before the EVENTS phase. A full SimulationEngine.tick_month() therefore
# legitimately changed the value before E13 evaluated it, making the old
# 0.40 -> 0.50 assertions invalid.
#
# This test now uses a dedicated E13-only state key on the real
# GovernmentComponent. The state still travels through the live
# component/path resolver, EventTriggerEvaluator, EventExecutor,
# EventEffectExecutor and E12 bridge, but no production system owns or
# mutates the fixture key.
# ============================================================


class TestHistorySink:
	extends RefCounted

	var entries: Array = []

	func record_event_result(
		entry: Dictionary
	) -> bool:
		entries.append(entry.duplicate(true))
		return true

	func get_entries() -> Array:
		return entries.duplicate(true)


static func _log_diagnostic(
	label: String,
	value
) -> void:
	TestLogger.write_line(
		"E13 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"EventSimulationIntegration — E13"
	)

	var test_passed: bool = true

	var available_pass: bool = (
		world != null
		and simulation != null
		and simulation.system_manager != null
	)

	TestLogger.write_line(
		"E13 world / simulation boundary available: "
		+ ("PASS" if available_pass else "FAIL")
	)

	if not available_pass:
		return false


	# ------------------------------------------------------------
	# LIVE FIXTURE
	# ------------------------------------------------------------

	var india: SimEntity = (
		world.get_entity("india")
		as SimEntity
	)

	var government: GovernmentComponent = null

	if india != null:
		government = (
			india.get_component("government")
			as GovernmentComponent
		)

	var fixture_pass: bool = (
		india != null
		and government != null
	)

	TestLogger.write_line(
		"E13 live country / government fixture available: "
		+ ("PASS" if fixture_pass else "FAIL")
	)

	if not fixture_pass:
		return false


	var integration: EventSimulationIntegrationSystem = (
		simulation.get_system(
			"event_simulation_integration"
		) as EventSimulationIntegrationSystem
	)

	var integration_pass: bool = (
		integration != null
	)

	TestLogger.write_line(
		"E13 integration system is registered: "
		+ ("PASS" if integration_pass else "FAIL")
	)

	if not integration_pass:
		return false


	# ------------------------------------------------------------
	# EXACT FIXTURE SNAPSHOT
	# ------------------------------------------------------------
	# Preserve the complete real component state rather than restoring
	# only one field. This guarantees the E13-only key disappears and
	# downstream tests see the exact original government state.

	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)

	var original_date: Dictionary = (
		world.current_date.duplicate(true)
	)

	var original_repeatability_state: Dictionary = (
		integration.get_repeatability_controller().snapshot_state()
	)

	var original_history_sink: Object = (
		integration.get_history_sink()
	)

	integration.clear_registrations()
	integration.get_repeatability_controller().clear_all()

	var history_sink: TestHistorySink = (
		TestHistorySink.new()
	)

	integration.set_history_sink(
		history_sink
	)

	# ------------------------------------------------------------
	# E13-ONLY LIVE COMPONENT STATE
	# ------------------------------------------------------------
	# No existing production system reads/writes this key.
	const TEST_STATE_KEY: String = "e13_test_value"
	const TEST_PATH: String = "government.e13_test_value"

	government.set_state(
		TEST_STATE_KEY,
		0.40
	)

	# ------------------------------------------------------------
	# ELIGIBLE EVENT
	# ------------------------------------------------------------

	var event_definition: EventDefinition = (
		EventDefinition.new(
			"e13_test_live_event",
			"E13 Test Live Event",
			"Synthetic monthly simulation event.",
			"political",
			"country"
		)
	)

	var event_condition: EventCondition = (
		EventCondition.new(
			TEST_PATH,
			EventCondition.OPERATOR_LESS,
			0.50
		)
	)

	var event_effect: EventEffect = (
		EventEffect.new(
			TEST_PATH,
			EventEffect.OPERATION_ADD,
			0.10
		)
	)

	var policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.one_time()
	)

	var registration_pass: bool = (
		integration.register_event(
			event_definition,
			[event_condition],
			[event_effect],
			["india"],
			policy
		)
		and integration.get_registration_count() == 1
	)

	TestLogger.write_line(
		"E13 synthetic event registration: "
		+ ("PASS" if registration_pass else "FAIL")
	)

	if not registration_pass:
		test_passed = false


	# ------------------------------------------------------------
	# MONTH N — ELIGIBLE EVENT EXECUTES THROUGH EVENTS PHASE
	# ------------------------------------------------------------

	government.set_state(
		TEST_STATE_KEY,
		0.40
	)

	var before_tick_date: String = world.get_date_string()

	simulation.tick_month()

	var after_first_tick_value: float = float(
		government.get_state(
			TEST_STATE_KEY,
			0.0
		)
	)

	var results_after_first_tick: Array = (
		integration.get_last_results()
	)

	var history_after_first_tick: Array = (
		history_sink.get_entries()
	)

	var first_execution_pass: bool = (
		is_equal_approx(
			after_first_tick_value,
			0.50
		)
		and results_after_first_tick.size() == 1
		and history_after_first_tick.size() == 1
		and history_after_first_tick[0].get(
			"event_id",
			""
		) == "e13_test_live_event"
		and history_after_first_tick[0].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
	)

	if not first_execution_pass:
		_log_diagnostic(
			"first_value",
			after_first_tick_value
		)
		_log_diagnostic(
			"first_results_count",
			results_after_first_tick.size()
		)
		_log_diagnostic(
			"first_history_count",
			history_after_first_tick.size()
		)
		if not history_after_first_tick.is_empty():
			_log_diagnostic(
				"first_history_entry",
				history_after_first_tick[0]
			)

	TestLogger.write_line(
		"E13 eligible event executes during the real monthly EVENTS phase: "
		+ ("PASS" if first_execution_pass else "FAIL")
	)

	if not first_execution_pass:
		test_passed = false


	# ------------------------------------------------------------
	# MONTH N+1 — ONE-TIME RESTRICTION
	# ------------------------------------------------------------

	simulation.tick_month()

	var second_tick_value: float = float(
		government.get_state(
			TEST_STATE_KEY,
			0.0
		)
	)

	var history_after_second_tick: Array = (
		history_sink.get_entries()
	)

	var repeatability_pass: bool = (
		is_equal_approx(
			second_tick_value,
			0.50
		)
		and history_after_second_tick.size() == 1
		and history_after_second_tick[0].get(
			"event_id",
			""
		) == "e13_test_live_event"
	)

	if not repeatability_pass:
		_log_diagnostic(
			"second_value",
			second_tick_value
		)
		_log_diagnostic(
			"second_history_count",
			history_after_second_tick.size()
		)

	TestLogger.write_line(
		"E13 one-time event does not execute again on the next month: "
		+ ("PASS" if repeatability_pass else "FAIL")
	)

	if not repeatability_pass:
		test_passed = false


	# ------------------------------------------------------------
	# BLOCKED EVENT
	# ------------------------------------------------------------

	integration.clear_registrations()

	var blocked_definition: EventDefinition = (
		EventDefinition.new(
			"e13_blocked_live_event",
			"E13 Blocked Live Event",
			"Synthetic blocked event.",
			"political",
			"country"
		)
	)

	var blocked_condition: EventCondition = (
		EventCondition.new(
			TEST_PATH,
			EventCondition.OPERATOR_LESS,
			0.10
		)
	)

	var blocked_effect: EventEffect = (
		EventEffect.new(
			TEST_PATH,
			EventEffect.OPERATION_ADD,
			0.20
		)
	)

	var blocked_registration_pass: bool = (
		integration.register_event(
			blocked_definition,
			[blocked_condition],
			[blocked_effect],
			["india"],
			EventRepeatabilityPolicy.repeatable()
		)
	)

	if not blocked_registration_pass:
		test_passed = false

	integration.set_history_sink(
		history_sink
	)

	# Keep the live fixture at the post-event value. The real
	# GovernmentSystem does not own TEST_STATE_KEY, so this remains stable
	# through WORLD_UPDATE and reaches EVENTS unchanged.
	government.set_state(
		TEST_STATE_KEY,
		0.50
	)

	simulation.tick_month()

	var blocked_value: float = float(
		government.get_state(
			TEST_STATE_KEY,
			0.0
		)
	)

	var history_after_blocked: Array = (
		history_sink.get_entries()
	)

	var blocked_pass: bool = (
		is_equal_approx(
			blocked_value,
			0.50
		)
		and history_after_blocked.size() == 2
		and history_after_blocked[1].get(
			"event_id",
			""
		) == "e13_blocked_live_event"
		and history_after_blocked[1].get(
			"status",
			""
		) == EventResult.STATUS_BLOCKED
		and not bool(
			history_after_blocked[1].get(
				"effects_executed",
				true
			)
		)
	)

	if not blocked_pass:
		_log_diagnostic(
			"blocked_value",
			blocked_value
		)
		_log_diagnostic(
			"blocked_history_count",
			history_after_blocked.size()
		)
		if history_after_blocked.size() > 1:
			_log_diagnostic(
				"blocked_history_entry",
				history_after_blocked[1]
			)

	TestLogger.write_line(
		"E13 blocked event leaves state unchanged and records blocked result: "
		+ ("PASS" if blocked_pass else "FAIL")
	)

	if not blocked_pass:
		test_passed = false


	# ------------------------------------------------------------
	# MONTHLY HEALTH / DATE ADVANCE
	# ------------------------------------------------------------

	var date_advanced_pass: bool = (
		world.get_date_string() != before_tick_date
	)

	TestLogger.write_line(
		"E13 monthly integration preserves normal date advancement: "
		+ ("PASS" if date_advanced_pass else "FAIL")
	)

	if not date_advanced_pass:
		test_passed = false


	# ------------------------------------------------------------
	# EXACT RESTORATION
	# ------------------------------------------------------------

	government.state = original_government_state.duplicate(true)
	world.current_date = original_date.duplicate(true)

	integration.clear_registrations()
	integration.get_repeatability_controller().restore_state(
		original_repeatability_state
	)
	integration.set_history_sink(
		original_history_sink
	)

	var restoration_pass: bool = (
		government.state == original_government_state
		and world.current_date == original_date
		and integration.get_registration_count() == 0
		and integration.get_history_sink() == original_history_sink
		and integration.get_repeatability_controller().snapshot_state()
			== original_repeatability_state
	)

	TestLogger.write_line(
		"E13 fixture restores world and event registration state: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	if not restoration_pass:
		test_passed = false


	TestLogger.write_line(
		"E13 Simulation Integration test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
