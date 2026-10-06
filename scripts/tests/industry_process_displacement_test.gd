class_name IndustryProcessDisplacementTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "INDUSTRY PROCESS DISPLACEMENT TEST"
	)

	var passed := true


	# ============================================================
	# TEST 1 — INITIAL STATE
	# ============================================================

	var initial_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			1.0,
			0,
			10
		)
	)

	var initial_passed := is_equal_approx(
		initial_capacity,
		100.0
	)

	TestLogger.write_line(
        "Initial old-process capacity: "
		+ (
            "PASS"
			if initial_passed
			else "FAIL"
		)
		+ " | expected=100.0 actual="
		+ str(initial_capacity)
	)

	passed = passed and initial_passed


	# ============================================================
	# TEST 2 — PARTIAL DISPLACEMENT
	# ============================================================

	var partial_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			1.0,
			2,
			10
		)
	)

	var partial_passed := is_equal_approx(
		partial_capacity,
		80.0
	)

	TestLogger.write_line(
        "2/10 month old-process capacity: "
		+ (
            "PASS"
			if partial_passed
			else "FAIL"
		)
		+ " | expected=80.0 actual="
		+ str(partial_capacity)
	)

	passed = passed and partial_passed


	# ============================================================
	# TEST 3 — MIDPOINT DISPLACEMENT
	# ============================================================

	var midpoint_capacity := (
		IndustryComponent.calculate_old_process_capacity(
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
        "Halfway old-process capacity: "
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
	# TEST 4 — COMPLETE DISPLACEMENT
	# ============================================================

	var completed_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			1.0,
			10,
			10
		)
	)

	var completed_passed := is_equal_approx(
		completed_capacity,
		0.0
	)

	TestLogger.write_line(
        "Completed old-process displacement: "
		+ (
            "PASS"
			if completed_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(completed_capacity)
	)

	passed = passed and completed_passed


	# ============================================================
	# TEST 5 — OVER-DURATION CLAMP
	# ============================================================

	var over_duration_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			1.0,
			20,
			10
		)
	)

	var over_duration_passed := is_equal_approx(
		over_duration_capacity,
		0.0
	)

	TestLogger.write_line(
        "Over-duration displacement clamp: "
		+ (
            "PASS"
			if over_duration_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(over_duration_capacity)
	)

	passed = passed and over_duration_passed


	# ============================================================
	# TEST 6 — PARTIAL TARGET ADOPTION
	# ============================================================

	var partial_adoption_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			0.6,
			10,
			10
		)
	)

	var partial_adoption_passed := is_equal_approx(
		partial_adoption_capacity,
		40.0
	)

	TestLogger.write_line(
        "Partial target adoption preserves old capacity: "
		+ (
            "PASS"
			if partial_adoption_passed
			else "FAIL"
		)
		+ " | expected=40.0 actual="
		+ str(partial_adoption_capacity)
	)

	passed = passed and partial_adoption_passed


	# ============================================================
	# TEST 7 — PARTIAL ADOPTION MIDPOINT
	# ============================================================

	var partial_midpoint_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			0.6,
			5,
			10
		)
	)

	var partial_midpoint_passed := is_equal_approx(
		partial_midpoint_capacity,
		70.0
	)

	TestLogger.write_line(
        "Partial adoption midpoint old capacity: "
		+ (
            "PASS"
			if partial_midpoint_passed
			else "FAIL"
		)
		+ " | expected=70.0 actual="
		+ str(partial_midpoint_capacity)
	)

	passed = passed and partial_midpoint_passed


	# ============================================================
	# TEST 8 — DISPLACED CAPACITY
	# ============================================================

	var displaced_capacity := (
		IndustryComponent.calculate_process_displacement(
			100.0,
			1.0,
			5,
			10
		)
	)

	var displaced_passed := is_equal_approx(
		displaced_capacity,
		50.0
	)

	TestLogger.write_line(
        "Halfway displaced capacity: "
		+ (
            "PASS"
			if displaced_passed
			else "FAIL"
		)
		+ " | expected=50.0 actual="
		+ str(displaced_capacity)
	)

	passed = passed and displaced_passed


	# ============================================================
	# TEST 9 — PARTIAL TARGET DISPLACEMENT
	# ============================================================

	var partial_displaced_capacity := (
		IndustryComponent.calculate_process_displacement(
			100.0,
			0.6,
			10,
			10
		)
	)

	var partial_displaced_passed := is_equal_approx(
		partial_displaced_capacity,
		60.0
	)

	TestLogger.write_line(
        "Partial target adoption displacement: "
		+ (
            "PASS"
			if partial_displaced_passed
			else "FAIL"
		)
		+ " | expected=60.0 actual="
		+ str(partial_displaced_capacity)
	)

	passed = passed and partial_displaced_passed


	# ============================================================
	# TEST 10 — NEGATIVE CAPACITY
	# ============================================================

	var negative_capacity := (
		IndustryComponent.calculate_old_process_capacity(
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
        "Negative initial capacity clamps to zero: "
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
	# TEST 11 — NEGATIVE TARGET ADOPTION
	# ============================================================

	var negative_adoption_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			-0.5,
			10,
			10
		)
	)

	var negative_adoption_passed := is_equal_approx(
		negative_adoption_capacity,
		100.0
	)

	TestLogger.write_line(
        "Negative target adoption clamps to zero displacement: "
		+ (
            "PASS"
			if negative_adoption_passed
			else "FAIL"
		)
		+ " | expected=100.0 actual="
		+ str(negative_adoption_capacity)
	)

	passed = passed and negative_adoption_passed


	# ============================================================
	# TEST 12 — ZERO DURATION
	# ============================================================

	var zero_duration_capacity := (
		IndustryComponent.calculate_old_process_capacity(
			100.0,
			1.0,
			0,
			0
		)
	)

	var zero_duration_passed := is_equal_approx(
		zero_duration_capacity,
		0.0
	)

	TestLogger.write_line(
        "Zero-duration full displacement: "
		+ (
            "PASS"
			if zero_duration_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(zero_duration_capacity)
	)

	passed = passed and zero_duration_passed


	# ============================================================
	# FINAL RESULT
	# ============================================================

	TestLogger.write_line("")
	TestLogger.write_line(
        "Old-process displacement test passed: "
		+ str(passed)
	)

	return passed
