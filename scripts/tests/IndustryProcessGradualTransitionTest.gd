class_name IndustryProcessGradualTransitionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS GRADUAL TRANSITION TEST"
	)

	var passed := true

	# --------------------------------------------------
	# A transition must move through intermediate states
	# over multiple months rather than jumping directly
	# from start adoption to target adoption.
	# --------------------------------------------------

	var start_adoption := 0.20
	var target_adoption := 1.00
	var duration_months := 10

	var previous_adoption := -1.0

	for month in range(0, duration_months + 1):

		var actual := IndustryComponent.calculate_transition_adoption(
			start_adoption,
			target_adoption,
			month,
			duration_months
		)

		var expected := (
			start_adoption
			+ (target_adoption - start_adoption)
			* (float(month) / float(duration_months))
		)

		var month_passed := is_equal_approx(
			actual,
			expected
		)

		if not month_passed:
			TestLogger.write_line(
				"Gradual transition month "
				+ str(month)
				+ ": FAIL | expected="
				+ str(expected)
				+ " actual="
				+ str(actual)
			)

		passed = passed and month_passed

		if previous_adoption >= 0.0:
			var monotonic := actual >= previous_adoption

			if not monotonic:
				TestLogger.write_line(
					"Gradual transition monotonicity at month "
					+ str(month)
					+ ": FAIL"
				)

			passed = passed and monotonic

		previous_adoption = actual

	TestLogger.write_line(
		"Gradual transition progresses month by month: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	# --------------------------------------------------
	# Explicit checkpoints across the transition
	# --------------------------------------------------

	var month_0 := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		0,
		duration_months
	)

	var month_5 := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		5,
		duration_months
	)

	var month_10 := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		10,
		duration_months
	)

	var checkpoints_passed := (
		is_equal_approx(month_0, 0.20)
		and is_equal_approx(month_5, 0.60)
		and is_equal_approx(month_10, 1.00)
	)

	TestLogger.write_line(
		"Gradual transition checkpoints 0/5/10 months: "
		+ (
			"PASS"
			if checkpoints_passed
			else "FAIL"
		)
		+ " | month0="
		+ str(month_0)
		+ " month5="
		+ str(month_5)
		+ " month10="
		+ str(month_10)
	)

	passed = passed and checkpoints_passed

	# --------------------------------------------------
	# The final state must be the target and not exceed it
	# --------------------------------------------------

	var over_duration := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		15,
		duration_months
	)

	var completion_clamped := is_equal_approx(
		over_duration,
		target_adoption
	)

	TestLogger.write_line(
		"Gradual transition completion clamps at target: "
		+ (
			"PASS"
			if completion_clamped
			else "FAIL"
		)
	)

	passed = passed and completion_clamped

	return passed
