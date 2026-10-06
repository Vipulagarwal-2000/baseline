class_name EventSynchronizerTest
extends RefCounted


static func _out(values: Array) -> void:

	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)


static func run(world: WorldState) -> void:

	TestLogger.section(
		"EVENT SYNCHRONIZER TEST"
	)

	if world == null:

		_out([
			"ERROR: World is null."
		])

		return

	var synchronizer = EventSynchronizer.new()

	_out([
		"Synchronizer created: ",
		synchronizer.system_name
	])


	# ============================================================
	# TEST 1 — BASIC EVENT LIFECYCLE
	# ============================================================

	TestLogger.section(
		"BASIC LIFECYCLE TEST"
	)

	var test_event = SimulationEvent.new(
		"test_event_001",
		"Test World Event",
		"general"
	)

	test_event.description = (
		"Basic Event Synchronizer lifecycle test."
	)

	test_event.priority = 10

	_out([
		"Event created: ",
		test_event.id
	])

	_out([
		"Initial state: ",
		test_event.state
	])

	var lifecycle_added = synchronizer.add_event(
		world,
		test_event
	)

	_out([
		"Event added: ",
		lifecycle_added
	])

	synchronizer.process_month(world)

	_out([
		"After first process: ",
		test_event.state
	])

	synchronizer.process_month(world)

	_out([
		"After second process: ",
		test_event.state
	])

	synchronizer.process_month(world)

	_out([
		"After third process: ",
		test_event.state
	])

	_out([
		"Event completed: ",
		test_event.is_completed()
	])

	var lifecycle_found = synchronizer.get_event(
		world,
		"test_event_001"
	)

	_out([
		"Event lookup successful: ",
		lifecycle_found != null
	])

	_out([
		"Active events: ",
		synchronizer.get_active_events(world).size()
	])

	_out([
		"Completed events: ",
		synchronizer.get_completed_events(world).size()
	])

	_out([
		"Event history entries: ",
		test_event.get_history().size()
	])

	var lifecycle_success = (
		lifecycle_added
		and test_event.is_completed()
		and lifecycle_found != null
		and test_event.get_history().size() > 0
	)

	TestLogger.section(
		"BASIC LIFECYCLE RESULT"
	)

	_out([
		"Lifecycle test passed: ",
		lifecycle_success
	])


	# ============================================================
	# TEST 2 — SCHEDULED EVENT
	# ============================================================

	TestLogger.section(
		"SCHEDULED EVENT TEST"
	)

	# IMPORTANT:
	# Do not hard-code a historical month.
	# The test must work regardless of how far main.gd
	# has advanced the shared simulation.

	var current_year = world.get_year()
	var current_month = world.get_month()

	var trigger_year = current_year
	var trigger_month = current_month + 1

	if trigger_month > 12:

		trigger_month = 1
		trigger_year += 1


	var scheduled_event = SimulationEvent.new(
		"scheduled_event_001",
		"Scheduled Test Event",
		"historical"
	)

	scheduled_event.description = (
		"Tests automatic scheduled event triggering."
	)

	scheduled_event.scheduled = true
	scheduled_event.trigger_year = trigger_year
	scheduled_event.trigger_month = trigger_month
	scheduled_event.trigger_day = world.get_day()


	var scheduled_added = synchronizer.add_event(
		world,
		scheduled_event
	)

	_out([
		"Scheduled event added: ",
		scheduled_added
	])

	_out([
		"Current world date: ",
		world.get_date_string()
	])

	_out([
		"Scheduled event date: ",
		"%02d/%02d/%04d" % [
			scheduled_event.trigger_day,
			scheduled_event.trigger_month,
			scheduled_event.trigger_year
		]
	])

	_out([
		"Scheduled event initial state: ",
		scheduled_event.state
	])


	# Process while still before trigger date.

	synchronizer.process_month(
		world
	)

	_out([
		"Before scheduled date: ",
		scheduled_event.state
	])

	var before_date_success = (
		scheduled_event.state == "inactive"
	)


	# Advance exactly one month using the world clock.

	world.advance_month()

	_out([
		"World date advanced to: ",
		world.get_date_string()
	])


	synchronizer.process_month(
		world
	)

	_out([
		"After scheduled date: ",
		scheduled_event.state
	])

	_out([
		"Scheduled event active: ",
		scheduled_event.is_active()
	])

	var scheduled_triggered = (
		scheduled_event.is_active()
		or scheduled_event.is_finished()
	)

	_out([
		"Scheduled event triggered: ",
		scheduled_triggered
	])

	var scheduled_success = (
		scheduled_added
		and before_date_success
		and scheduled_triggered
	)

	TestLogger.section(
		"SCHEDULED EVENT RESULT"
	)

	_out([
		"Scheduled event test passed: ",
		scheduled_success
	])


	# ============================================================
	# TEST 3 — CONDITIONAL EVENT
	# ============================================================

	TestLogger.section(
		"CONDITIONAL EVENT TEST"
	)

	var india = world.get_entity(
		"india"
	)

	if india == null:

		_out([
			"ERROR: India not found."
		])

		_out([
			"Conditional event test passed: false"
		])

		_out([
			"Overall test passed: false"
		])

		return


	var population_component = (
		india.get_component(
			"population"
		)
	)

	if population_component == null:

		_out([
			"ERROR: India population component not found."
		])

		_out([
			"Conditional event test passed: false"
		])

		_out([
			"Overall test passed: false"
		])

		return


	var india_population = float(
		population_component.get_state(
			"population",
			0.0
		)
	)

	_out([
		"India population: ",
		india_population
	])


	# ------------------------------------------------------------
	# CONDITION THAT SHOULD PASS
	# ------------------------------------------------------------

	var population_event = SimulationEvent.new(
		"population_event_001",
		"Population Threshold Event",
		"social"
	)

	population_event.description = (
		"Triggers when India's population reaches "
		+ "the required threshold."
	)

	var passing_threshold = (
		india_population - 1000000.0
	)

	population_event.add_minimum_condition(
		"country",
		"india",
		"population",
		passing_threshold
	)

	var population_event_added = (
		synchronizer.add_event(
			world,
			population_event
		)
	)

	_out([
		"Passing condition threshold: ",
		passing_threshold
	])

	_out([
		"Conditional event added: ",
		population_event_added
	])

	_out([
		"Initial conditional event state: ",
		population_event.state
	])

	synchronizer.process_month(
		world
	)

	_out([
		"After condition evaluation: ",
		population_event.state
	])

	var condition_passed = (
		population_event.state == "active"
	)

	_out([
		"Condition satisfied: ",
		condition_passed
	])


	# ------------------------------------------------------------
	# CONDITION DIAGNOSTIC
	# ------------------------------------------------------------

	TestLogger.section(
		"CONDITION DIAGNOSTIC"
	)

	var passing_diagnostics = (
		synchronizer.get_condition_results(
			world,
			population_event
		)
	)

	for diagnostic in passing_diagnostics:

		_out([
			"Diagnostic: ",
			diagnostic
		])

	var passing_conditions = (
		population_event.get_conditions()
	)

	if not passing_conditions.is_empty():

		var passing_explanation = (
			synchronizer.explain_condition(
				world,
				passing_conditions[0]
			)
		)

		_out([
			"Passing condition explanation: ",
			passing_explanation
		])


	# ------------------------------------------------------------
	# CONDITION THAT SHOULD FAIL
	# ------------------------------------------------------------

	var blocked_event = SimulationEvent.new(
		"population_event_002",
		"Blocked Population Event",
		"social"
	)

	blocked_event.description = (
		"Should remain inactive because the population "
		+ "threshold is too high."
	)

	var failing_threshold = (
		india_population + 100000000.0
	)

	blocked_event.add_minimum_condition(
		"country",
		"india",
		"population",
		failing_threshold
	)

	var blocked_event_added = (
		synchronizer.add_event(
			world,
			blocked_event
		)
	)

	_out([
		"Failing condition threshold: ",
		failing_threshold
	])

	_out([
		"Blocked event added: ",
		blocked_event_added
	])

	_out([
		"Initial blocked event state: ",
		blocked_event.state
	])

	synchronizer.process_month(
		world
	)

	_out([
		"After failed condition evaluation: ",
		blocked_event.state
	])

	var condition_blocked = (
		blocked_event.state == "inactive"
	)

	_out([
		"Condition correctly blocked: ",
		condition_blocked
	])


	# ------------------------------------------------------------
	# BLOCKED CONDITION DIAGNOSTIC
	# ------------------------------------------------------------

	var blocked_conditions = (
		blocked_event.get_conditions()
	)

	if not blocked_conditions.is_empty():

		var blocked_explanation = (
			synchronizer.explain_condition(
				world,
				blocked_conditions[0]
			)
		)

		_out([
			"Blocking condition explanation: ",
			blocked_explanation
		])


	var conditional_success = (
		population_event_added
		and blocked_event_added
		and condition_passed
		and condition_blocked
	)


	TestLogger.section(
		"CONDITIONAL EVENT RESULT"
	)

	_out([
		"Passing condition: ",
		condition_passed
	])

	_out([
		"Blocking condition: ",
		condition_blocked
	])

	_out([
		"Conditional event test passed: ",
		conditional_success
	])


	# ============================================================
	# FINAL RESULT
	# ============================================================

	var overall_success = (
		lifecycle_success
		and scheduled_success
		and conditional_success
	)

	TestLogger.section(
		"EVENT SYNCHRONIZER RESULT"
	)

	_out([
		"Basic lifecycle: ",
		lifecycle_success
	])

	_out([
		"Scheduled events: ",
		scheduled_success
	])

	_out([
		"Conditional events: ",
		conditional_success
	])

	_out([
		"Overall test passed: ",
		overall_success
	])

	if overall_success:

		_out([
			"Event Synchronizer tests: PASS"
		])

	else:

		_out([
			"Event Synchronizer tests: FAILED"
		])

	_out([
		"Event Synchronizer test complete."
	])
