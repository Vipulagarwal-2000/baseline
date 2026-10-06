class_name Step17_5EventDrivenFeedbackTest
extends RefCounted


# ============================================================
# STEP 17.5 — EVENT-DRIVEN FEEDBACK
# ============================================================
#
# Acceptance boundary:
#
#     live world condition
#          ↓
#     real EVENTS phase
#          ↓
#     EventSimulationIntegrationSystem
#          ↓
#     EventTriggerEvaluator
#          ↓
#     EventExecutor / EventEffectExecutor
#          ↓
#     authoritative government state
#          ↓
#     next monthly WORLD_UPDATE
#          ↓
#     real GovernmentSystem consumes the event consequence
#
# This test deliberately uses an existing authoritative state:
#     government.political_pressure
#
# It does NOT introduce an Event→ActionRequest contract. No canonical
# contract for that boundary currently exists. Events therefore use the
# already-proven E13 effect path for this bounded Step 17.5 closure.
#
# The key proof is temporal:
#     Month N EVENTS changes political_pressure to 0.80.
#     Month N+1 GovernmentSystem must read that exact value and record
#     it into its existing previous_pressure state before recalculating
#     the next pressure value.
#
# This demonstrates that an event consequence survives the EVENTS phase
# and becomes an input to a real authoritative domain system on the next
# monthly cycle.
# ============================================================


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


static func _log_diagnostic(
	label: String,
	value
) -> void:
	TestLogger.write_line(
		"17.5 diagnostic | "
		+ label
		+ "="
		+ str(value)
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"Event-Driven Feedback — STEP 17.5"
	)

	var test_passed: bool = true

	# ------------------------------------------------------------
	# LIVE SIMULATION BOUNDARY
	# ------------------------------------------------------------

	var available_pass: bool = (
		world != null
		and simulation != null
		and simulation.system_manager != null
	)

	TestLogger.write_line(
		"17.5 world / simulation boundary available: "
		+ ("PASS" if available_pass else "FAIL")
	)

	if not available_pass:
		return false

	var integration: EventSimulationIntegrationSystem = (
		simulation.get_system(
			"event_simulation_integration"
		) as EventSimulationIntegrationSystem
	)

	var government_system: GovernmentSystem = (
		simulation.get_system(
			"government_system"
		) as GovernmentSystem
	)

	var integration_pass: bool = integration != null
	var government_system_pass: bool = government_system != null

	TestLogger.write_line(
		"17.5 live event integration system available: "
		+ ("PASS" if integration_pass else "FAIL")
	)

	TestLogger.write_line(
		"17.5 live GovernmentSystem available: "
		+ ("PASS" if government_system_pass else "FAIL")
	)

	if not integration_pass or not government_system_pass:
		return false

	# ------------------------------------------------------------
	# LIVE COUNTRY / GOVERNMENT FIXTURE
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
		"17.5 India / Government fixture available: "
		+ ("PASS" if fixture_pass else "FAIL")
	)

	if not fixture_pass:
		return false

	# ------------------------------------------------------------
	# FIXTURE SAFETY
	# ------------------------------------------------------------
	# The live E13 integration layer is expected to have no authored
	# runtime registrations at this point in the acceptance suite. Do
	# not silently destroy such registrations if another caller has
	# inserted them.

	var initial_registration_count: int = (
		integration.get_registration_count()
	)

	var registration_fixture_pass: bool = (
		initial_registration_count == 0
	)

	TestLogger.write_line(
		"17.5 event registration fixture is isolated: "
		+ ("PASS" if registration_fixture_pass else "FAIL")
	)

	if not registration_fixture_pass:
		_log_diagnostic(
			"unexpected_registration_count",
			initial_registration_count
		)
		return false

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

	var history_sink: TestHistorySink = TestHistorySink.new()
	integration.set_history_sink(history_sink)

	# ------------------------------------------------------------
	# REGISTER SYNTHETIC EVENT
	# ------------------------------------------------------------
	# Condition is deliberately broad enough to remain valid after the
	# real GovernmentSystem processes Month N WORLD_UPDATE. The event
	# then sets an authoritative domain input to a deterministic value.

	const EVENT_ID: String = "step17_5_government_pressure_event"
	const TARGET_ID: String = "india"
	const PRESSURE_TARGET: float = 0.80
	const TEST_PATH: String = "government.political_pressure"

	var definition: EventDefinition = EventDefinition.new(
		EVENT_ID,
		"Step 17.5 Government Pressure Event",
		"Synthetic event used to verify event-driven monthly feedback.",
		"political",
		"country"
	)

	var condition: EventCondition = EventCondition.new(
		TEST_PATH,
		EventCondition.OPERATOR_LESS,
		1.10
	)

	var effect: EventEffect = EventEffect.new(
		TEST_PATH,
		EventEffect.OPERATION_SET,
		PRESSURE_TARGET
	)

	var registration_pass: bool = integration.register_event(
		definition,
		[condition],
		[effect],
		[TARGET_ID],
		EventRepeatabilityPolicy.one_time()
	)

	TestLogger.write_line(
		"17.5 synthetic event registration: "
		+ ("PASS" if registration_pass else "FAIL")
	)

	if not registration_pass:
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N — EVENT EXECUTION
	# ------------------------------------------------------------

	# Establish a bounded pre-event value. GovernmentSystem is allowed to
	# process normally in WORLD_UPDATE; the event remains eligible because
	# the condition is intentionally broader than normal pressure values.
	government.set_state(
		"political_pressure",
		0.20
	)

	var month_n_date: String = world.get_date_string()

	simulation.tick_month()

	var month_n_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var month_n_results: Array = integration.get_last_results()
	var month_n_history: Array = history_sink.get_entries()

	var executed_pass: bool = (
		is_equal_approx(
			month_n_pressure,
			PRESSURE_TARGET
		)
		and month_n_results.size() == 1
		and month_n_history.size() == 1
		and month_n_history[0].get("event_id", "") == EVENT_ID
		and month_n_history[0].get(
			"status",
			""
		) == EventResult.STATUS_EXECUTED
		and bool(
			month_n_history[0].get(
			"eligible",
			false
			)
		)
	)

	if not executed_pass:
		_log_diagnostic(
			"month_n_pressure",
			month_n_pressure
		)
		_log_diagnostic(
			"month_n_results",
			month_n_results
		)
		_log_diagnostic(
			"month_n_history",
			month_n_history
		)

	TestLogger.write_line(
		"17.5 eligible event executes in the real EVENTS phase and changes authoritative state: "
		+ ("PASS" if executed_pass else "FAIL")
	)

	if not executed_pass:
		test_passed = false

	# ------------------------------------------------------------
	# MONTH N → N+1 CAUSAL HANDOFF
	# ------------------------------------------------------------
	# GovernmentSystem runs during WORLD_UPDATE before EVENTS. Therefore,
	# on Month N+1 it should observe exactly the value written by the event
	# during Month N EVENTS and store that consumed value in previous_pressure.

	var month_n_plus_one_date_before: String = world.get_date_string()

	simulation.tick_month()

	var consumed_previous_pressure: float = float(
		government.get_state(
			"previous_pressure",
			-1.0
		)
	)

	var month_n_plus_one_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var month_n_plus_one_stability: float = float(
		government.get_state(
			"stability",
			-1.0
		)
	)

	var persistence_pass: bool = (
		is_equal_approx(
			consumed_previous_pressure,
			PRESSURE_TARGET
		)
		and month_n_plus_one_pressure >= 0.0
		and month_n_plus_one_pressure <= 1.0
		and month_n_plus_one_stability >= 0.0
		and month_n_plus_one_stability <= 1.0
	)

	if not persistence_pass:
		_log_diagnostic(
			"consumed_previous_pressure",
			consumed_previous_pressure
		)
		_log_diagnostic(
			"month_n_plus_one_pressure",
			month_n_plus_one_pressure
		)
		_log_diagnostic(
			"month_n_plus_one_stability",
			month_n_plus_one_stability
		)

	TestLogger.write_line(
		"17.5 next-month GovernmentSystem consumes the event consequence: "
		+ ("PASS" if persistence_pass else "FAIL")
	)

	if not persistence_pass:
		test_passed = false

	# ------------------------------------------------------------
	# REPEATABILITY / NO SECOND EXECUTION
	# ------------------------------------------------------------

	var month_n_plus_one_results: Array = integration.get_last_results()
	var month_n_plus_one_history: Array = history_sink.get_entries()

	var one_time_pass: bool = (
		month_n_plus_one_results.is_empty()
		and month_n_plus_one_history.size() == 1
		and month_n_plus_one_history[0].get(
			"event_id",
			""
		) == EVENT_ID
	)

	TestLogger.write_line(
		"17.5 one-time event does not re-execute on the next month: "
		+ ("PASS" if one_time_pass else "FAIL")
	)

	if not one_time_pass:
		test_passed = false

	# ------------------------------------------------------------
	# DATE / MONTHLY BOUNDARY
	# ------------------------------------------------------------

	var date_advanced_pass: bool = (
		world.get_date_string() != month_n_date
		and world.get_date_string() != month_n_plus_one_date_before
	)

	TestLogger.write_line(
		"17.5 monthly boundary preserves normal date advancement: "
		+ ("PASS" if date_advanced_pass else "FAIL")
	)

	if not date_advanced_pass:
		test_passed = false

	# ------------------------------------------------------------
	# RESTORATION
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
		and integration.get_registration_count() == initial_registration_count
		and integration.get_history_sink() == original_history_sink
		and integration.get_repeatability_controller().snapshot_state()
			== original_repeatability_state
	)

	TestLogger.write_line(
		"17.5 fixture restores government/date/event integration state: "
		+ ("PASS" if restoration_pass else "FAIL")
	)

	if not restoration_pass:
		test_passed = false

	TestLogger.write_line(
		"Step 17.5 Event-Driven Feedback test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
