class_name IndustryProcessTransitionCostTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS TRANSITION COST TEST"
	)

	var passed := true


	# --------------------------------------------------
	# Cost distributed across transition
	# --------------------------------------------------

	var monthly_cost := IndustryComponent.calculate_transition_cost_per_month(
		100.0,
		10
	)

	if is_equal_approx(
		monthly_cost,
		10.0
	):
		TestLogger.write_line(
			"Transition cost distributed across duration: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition cost distributed across duration: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Halfway accumulated cost
	# --------------------------------------------------

	var halfway_cost := IndustryComponent.calculate_accumulated_transition_cost(
		100.0,
		5,
		10
	)

	if is_equal_approx(
		halfway_cost,
		50.0
	):
		TestLogger.write_line(
			"Halfway accumulated transition cost: PASS"
		)
	else:
		TestLogger.write_line(
			"Halfway accumulated transition cost: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Completed transition cost
	# --------------------------------------------------

	var completed_cost := IndustryComponent.calculate_accumulated_transition_cost(
		100.0,
		10,
		10
	)

	if is_equal_approx(
		completed_cost,
		100.0
	):
		TestLogger.write_line(
			"Completed transition accumulates full cost: PASS"
		)
	else:
		TestLogger.write_line(
			"Completed transition accumulates full cost: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Cost cannot exceed total
	# --------------------------------------------------

	var excessive_cost := IndustryComponent.calculate_accumulated_transition_cost(
		100.0,
		15,
		10
	)

	if is_equal_approx(
		excessive_cost,
		100.0
	):
		TestLogger.write_line(
			"Accumulated cost capped at total cost: PASS"
		)
	else:
		TestLogger.write_line(
			"Accumulated cost capped at total cost: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Negative cost is neutralized
	# --------------------------------------------------

	var negative_cost := IndustryComponent.calculate_transition_cost_per_month(
		-100.0,
		10
	)

	if is_equal_approx(
		negative_cost,
		0.0
	):
		TestLogger.write_line(
			"Negative transition cost clamped to zero: PASS"
		)
	else:
		TestLogger.write_line(
			"Negative transition cost clamped to zero: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Zero duration
	# --------------------------------------------------

	var zero_duration := IndustryComponent.calculate_transition_cost_per_month(
		100.0,
		0
	)

	if is_equal_approx(
		zero_duration,
		100.0
	):
		TestLogger.write_line(
			"Zero-duration transition cost handled safely: PASS"
		)
	else:
		TestLogger.write_line(
			"Zero-duration transition cost handled safely: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Transition state contains cost fields
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
		and state.has("transition_cost")
		and state.has("cost_per_month")
		and state.has("accumulated_cost")
	):
		TestLogger.write_line(
			"Transition cost state initialized: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition cost state initialized: FAIL"
		)
		passed = false


	return passed
