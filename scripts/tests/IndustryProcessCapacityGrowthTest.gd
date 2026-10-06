class_name IndustryProcessCapacityGrowthTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS CAPACITY GROWTH TEST"
	)

	var passed := true


	# ============================================================
	# TEST 1 — ZERO-MONTH CAPACITY
	# ============================================================

	var zero_month_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			0,
			10
		)
	)

	var zero_month_passed := is_equal_approx(
		zero_month_capacity,
		0.0
	)

	TestLogger.write_line(
		"Zero-month new-process capacity: "
		+ (
			"PASS"
			if zero_month_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(zero_month_capacity)
	)

	passed = passed and zero_month_passed


	# ============================================================
	# TEST 2 — PARTIAL TRANSITION CAPACITY
	# ============================================================

	var partial_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			2,
			10
		)
	)

	var partial_passed := is_equal_approx(
		partial_capacity,
		20.0
	)

	TestLogger.write_line(
		"2/10 month new-process capacity: "
		+ (
			"PASS"
			if partial_passed
			else "FAIL"
		)
		+ " | expected=20.0 actual="
		+ str(partial_capacity)
	)

	passed = passed and partial_passed


	# ============================================================
	# TEST 3 — MIDPOINT CAPACITY
	# ============================================================

	var midpoint_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			5,
			10
		)
	)

	var midpoint_passed := is_equal_approx(
		midpoint_capacity,
		50.0
	)

	TestLogger.write_line(
		"Halfway new-process capacity: "
		+ (
			"PASS"
			if midpoint_passed
			else "FAIL"
		)
		+ " | expected=50.0 actual="
		+ str(midpoint_capacity)
	)

	passed = passed and midpoint_passed


	# ============================================================
	# TEST 4 — COMPLETION
	# ============================================================

	var completed_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			10,
			10
		)
	)

	var completed_passed := is_equal_approx(
		completed_capacity,
		100.0
	)

	TestLogger.write_line(
		"Completed new-process capacity: "
		+ (
			"PASS"
			if completed_passed
			else "FAIL"
		)
		+ " | expected=100.0 actual="
		+ str(completed_capacity)
	)

	passed = passed and completed_passed


	# ============================================================
	# TEST 5 — OVER-DURATION CLAMP
	# ============================================================

	var over_duration_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			20,
			10
		)
	)

	var over_duration_passed := is_equal_approx(
		over_duration_capacity,
		100.0
	)

	TestLogger.write_line(
		"Over-duration capacity clamp: "
		+ (
			"PASS"
			if over_duration_passed
			else "FAIL"
		)
		+ " | expected=100.0 actual="
		+ str(over_duration_capacity)
	)

	passed = passed and over_duration_passed


	# ============================================================
	# TEST 6 — ZERO-DURATION TRANSITION
	# ============================================================

	var zero_duration_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			1.0,
			0,
			0
		)
	)

	var zero_duration_passed := is_equal_approx(
		zero_duration_capacity,
		100.0
	)

	TestLogger.write_line(
		"Zero-duration capacity completion: "
		+ (
			"PASS"
			if zero_duration_passed
			else "FAIL"
		)
		+ " | expected=100.0 actual="
		+ str(zero_duration_capacity)
	)

	passed = passed and zero_duration_passed


	# ============================================================
	# TEST 7 — PARTIAL TARGET ADOPTION
	# ============================================================

	var partial_adoption_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			0.6,
			10,
			10
		)
	)

	var partial_adoption_passed := is_equal_approx(
		partial_adoption_capacity,
		60.0
	)

	TestLogger.write_line(
		"Partial target adoption limits capacity: "
		+ (
			"PASS"
			if partial_adoption_passed
			else "FAIL"
		)
		+ " | expected=60.0 actual="
		+ str(partial_adoption_capacity)
	)

	passed = passed and partial_adoption_passed


	# ============================================================
	# TEST 8 — NEGATIVE CAPACITY
	# ============================================================

	var negative_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			-100.0,
			1.0,
			5,
			10
		)
	)

	var negative_capacity_passed := is_equal_approx(
		negative_capacity,
		0.0
	)

	TestLogger.write_line(
		"Negative target capacity clamps to zero: "
		+ (
			"PASS"
			if negative_capacity_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(negative_capacity)
	)

	passed = passed and negative_capacity_passed


	# ============================================================
	# TEST 9 — NEGATIVE TARGET ADOPTION
	# ============================================================

	var negative_adoption_capacity := (
		IndustryComponent.calculate_new_process_capacity(
			100.0,
			-0.5,
			10,
			10
		)
	)

	var negative_adoption_passed := is_equal_approx(
		negative_adoption_capacity,
		0.0
	)

	TestLogger.write_line(
		"Negative target adoption clamps to zero: "
		+ (
			"PASS"
			if negative_adoption_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(negative_adoption_capacity)
	)

	passed = passed and negative_adoption_passed


	# ============================================================
	# TEST 10 — CAPACITY GROWTH HELPER
	# ============================================================

	var interpolated_capacity := (
		IndustryComponent.calculate_transition_capacity(
			20.0,
			100.0,
			5,
			10
		)
	)

	var interpolated_passed := is_equal_approx(
		interpolated_capacity,
		60.0
	)

	TestLogger.write_line(
		"Transition capacity interpolation: "
		+ (
			"PASS"
			if interpolated_passed
			else "FAIL"
		)
		+ " | expected=60.0 actual="
		+ str(interpolated_capacity)
	)

	passed = passed and interpolated_passed


	# ============================================================
	# FINAL RESULT
	# ============================================================

	TestLogger.write_line("")
	TestLogger.write_line(
		"New-process capacity growth test passed: "
		+ str(passed)
	)

	return passed
