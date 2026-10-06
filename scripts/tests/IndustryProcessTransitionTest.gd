class_name IndustryProcessTransitionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS TRANSITION TEST"
	)

	var passed := true


	# --------------------------------------------------
	# Transition progress
	# --------------------------------------------------

	var progress := IndustryComponent.calculate_transition_progress(
		2,
		10
	)

	if is_equal_approx(progress, 0.20):
		TestLogger.write_line(
			"Transition progress at 2/10 months: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition progress at 2/10 months: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Start of transition
	# --------------------------------------------------

	var start := IndustryComponent.calculate_transition_adoption(
		0.20,
		1.00,
		0,
		10
	)

	if is_equal_approx(start, 0.20):
		TestLogger.write_line(
			"Transition starts at current adoption: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition starts at current adoption: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Middle of transition
	# --------------------------------------------------

	var middle := IndustryComponent.calculate_transition_adoption(
		0.20,
		1.00,
		5,
		10
	)

	if is_equal_approx(middle, 0.60):
		TestLogger.write_line(
			"Transition reaches midpoint correctly: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition reaches midpoint correctly: FAIL | actual="
			+ str(middle)
		)
		passed = false


	# --------------------------------------------------
	# End of transition
	# --------------------------------------------------

	var complete := IndustryComponent.calculate_transition_adoption(
		0.20,
		1.00,
		10,
		10
	)

	if is_equal_approx(complete, 1.00):
		TestLogger.write_line(
			"Transition reaches target at completion: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition reaches target at completion: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Progress cannot exceed 1
	# --------------------------------------------------

	var over_duration := IndustryComponent.calculate_transition_adoption(
		0.20,
		1.00,
		15,
		10
	)

	if is_equal_approx(over_duration, 1.00):
		TestLogger.write_line(
			"Transition clamps after duration: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition clamps after duration: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Zero duration
	# --------------------------------------------------

	var zero_duration := IndustryComponent.calculate_transition_adoption(
		0.20,
		1.00,
		0,
		0
	)

	if is_equal_approx(zero_duration, 1.00):
		TestLogger.write_line(
			"Zero-duration transition completes immediately: PASS"
		)
	else:
		TestLogger.write_line(
			"Zero-duration transition completes immediately: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Downward transition
	# --------------------------------------------------

	var decreasing := IndustryComponent.calculate_transition_adoption(
		0.80,
		0.20,
		5,
		10
	)

	if is_equal_approx(decreasing, 0.50):
		TestLogger.write_line(
			"Downward transition progresses correctly: PASS"
		)
	else:
		TestLogger.write_line(
			"Downward transition progresses correctly: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Transition state initialization
	# --------------------------------------------------

	var industry := IndustryComponent.new()

	industry.setup(
		{
			"steel_basic": {
				"active": true,
				"capacity": 100.0,
				"efficiency": 1.0
			}
		},
		{
			"steel_basic": 0.20
		},
		{
			"steel_basic": 0.10
		}
	)

	var transitions = industry.get_state(
		"process_transition_state",
		{}
	)

	var state = transitions.get(
		"steel_basic",
		{}
	)

	if (
		typeof(state) == TYPE_DICTIONARY
		and not bool(state.get("active", true))
		and int(state.get("elapsed_months", -1)) == 0
		and int(state.get("duration_months", -1)) == 0
		and is_equal_approx(
			float(state.get("progress", -1.0)),
			0.0
		)
	):
		TestLogger.write_line(
			"Transition state initialized correctly: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition state initialized correctly: FAIL"
		)
		passed = false


	return passed
