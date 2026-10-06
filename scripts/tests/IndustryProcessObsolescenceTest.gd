class_name IndustryProcessObsolescenceTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "INDUSTRY PROCESS OBSOLESCENCE TEST"
	)

	var passed := true


	# ============================================================
	# TEST 1 — INITIAL TRANSITION IS NOT OBSOLETE
	# ============================================================

	var initial_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			1.0,
			0,
			10
		)
	)

	var initial_passed := (
		initial_obsolete == false
	)

	TestLogger.write_line(
        "Initial transition is not obsolete: "
		+ (
            "PASS"
			if initial_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(initial_obsolete)
	)

	passed = passed and initial_passed


	# ============================================================
	# TEST 2 — MIDPOINT IS NOT OBSOLETE
	# ============================================================

	var midpoint_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			1.0,
			5,
			10
		)
	)

	var midpoint_passed := (
		midpoint_obsolete == false
	)

	TestLogger.write_line(
        "Midpoint transition is not obsolete: "
		+ (
            "PASS"
			if midpoint_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(midpoint_obsolete)
	)

	passed = passed and midpoint_passed


	# ============================================================
	# TEST 3 — COMPLETE TRANSITION BECOMES OBSOLETE
	# ============================================================

	var completed_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			1.0,
			10,
			10
		)
	)

	var completed_passed := (
		completed_obsolete == true
	)

	TestLogger.write_line(
        "Completed full transition becomes obsolete: "
		+ (
            "PASS"
			if completed_passed
			else "FAIL"
		)
		+ " | expected=true actual="
		+ str(completed_obsolete)
	)

	passed = passed and completed_passed


	# ============================================================
	# TEST 4 — OVER-DURATION REMAINS OBSOLETE
	# ============================================================

	var over_duration_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			1.0,
			20,
			10
		)
	)

	var over_duration_passed := (
		over_duration_obsolete == true
	)

	TestLogger.write_line(
        "Over-duration completed transition remains obsolete: "
		+ (
            "PASS"
			if over_duration_passed
			else "FAIL"
		)
		+ " | expected=true actual="
		+ str(over_duration_obsolete)
	)

	passed = passed and over_duration_passed


	# ============================================================
	# TEST 5 — PARTIAL TARGET ADOPTION IS NOT OBSOLETE
	# ============================================================

	var partial_adoption_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			0.6,
			10,
			10
		)
	)

	var partial_adoption_passed := (
		partial_adoption_obsolete == false
	)

	TestLogger.write_line(
        "Partial target adoption prevents obsolescence: "
		+ (
            "PASS"
			if partial_adoption_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(partial_adoption_obsolete)
	)

	passed = passed and partial_adoption_passed


	# ============================================================
	# TEST 6 — PARTIAL ADOPTION MIDPOINT IS NOT OBSOLETE
	# ============================================================

	var partial_midpoint_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			0.6,
			5,
			10
		)
	)

	var partial_midpoint_passed := (
		partial_midpoint_obsolete == false
	)

	TestLogger.write_line(
        "Partial adoption midpoint is not obsolete: "
		+ (
            "PASS"
			if partial_midpoint_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(partial_midpoint_obsolete)
	)

	passed = passed and partial_midpoint_passed


	# ============================================================
	# TEST 7 — ZERO TARGET ADOPTION IS NOT OBSOLETE
	# ============================================================

	var zero_adoption_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			0.0,
			10,
			10
		)
	)

	var zero_adoption_passed := (
		zero_adoption_obsolete == false
	)

	TestLogger.write_line(
        "Zero target adoption prevents obsolescence: "
		+ (
            "PASS"
			if zero_adoption_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(zero_adoption_obsolete)
	)

	passed = passed and zero_adoption_passed


	# ============================================================
	# TEST 8 — ZERO-DURATION FULL ADOPTION
	# ============================================================

	var zero_duration_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			1.0,
			0,
			0
		)
	)

	var zero_duration_passed := (
		zero_duration_obsolete == true
	)

	TestLogger.write_line(
        "Zero-duration full transition becomes obsolete: "
		+ (
            "PASS"
			if zero_duration_passed
			else "FAIL"
		)
		+ " | expected=true actual="
		+ str(zero_duration_obsolete)
	)

	passed = passed and zero_duration_passed


	# ============================================================
	# TEST 9 — NEGATIVE ADOPTION CLAMPS TO ZERO
	# ============================================================

	var negative_adoption_obsolete := (
		IndustryComponent.calculate_process_obsolescence(
			-0.5,
			10,
			10
		)
	)

	var negative_adoption_passed := (
		negative_adoption_obsolete == false
	)

	TestLogger.write_line(
        "Negative target adoption prevents obsolescence: "
		+ (
            "PASS"
			if negative_adoption_passed
			else "FAIL"
		)
		+ " | expected=false actual="
		+ str(negative_adoption_obsolete)
	)

	passed = passed and negative_adoption_passed


	# ============================================================
	# TEST 10 — OBSOLESCENCE PROGRESS
	# ============================================================

	var progress := (
		IndustryComponent.calculate_process_obsolescence_progress(
			1.0,
			5,
			10
		)
	)

	var progress_passed := is_equal_approx(
		progress,
		0.5
	)

	TestLogger.write_line(
        "Full-adoption obsolescence progress: "
		+ (
            "PASS"
			if progress_passed
			else "FAIL"
		)
		+ " | expected=0.5 actual="
		+ str(progress)
	)

	passed = passed and progress_passed


	# ============================================================
	# TEST 11 — PARTIAL ADOPTION PROGRESS
	# ============================================================

	var partial_progress := (
		IndustryComponent.calculate_process_obsolescence_progress(
			0.6,
			5,
			10
		)
	)

	var partial_progress_passed := is_equal_approx(
		partial_progress,
		0.3
	)

	TestLogger.write_line(
        "Partial-adoption obsolescence progress: "
		+ (
            "PASS"
			if partial_progress_passed
			else "FAIL"
		)
		+ " | expected=0.3 actual="
		+ str(partial_progress)
	)

	passed = passed and partial_progress_passed


	# ============================================================
	# TEST 12 — PARTIAL ADOPTION COMPLETION
	# ============================================================

	var partial_completion_progress := (
		IndustryComponent.calculate_process_obsolescence_progress(
			0.6,
			10,
			10
		)
	)

	var partial_completion_passed := is_equal_approx(
		partial_completion_progress,
		0.6
	)

	TestLogger.write_line(
        "Partial-adoption completion progress: "
		+ (
            "PASS"
			if partial_completion_passed
			else "FAIL"
		)
		+ " | expected=0.6 actual="
		+ str(partial_completion_progress)
	)

	passed = passed and partial_completion_passed


	# ============================================================
	# FINAL RESULT
	# ============================================================

	TestLogger.write_line("")
	TestLogger.write_line(
        "Old-process obsolescence test passed: "
		+ str(passed)
	)

	return passed
