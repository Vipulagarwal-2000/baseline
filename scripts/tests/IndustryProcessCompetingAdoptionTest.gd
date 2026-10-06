class_name IndustryProcessCompetingAdoptionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "INDUSTRY PROCESS COMPETING ADOPTION TEST"
	)

	var passed := true


	# ============================================================
	# TEST 1 — MULTIPLE PROCESSES CAN COEXIST
	# ============================================================

	var coexistence := {
		"old_process": 0.60,
		"new_process_a": 0.30,
		"new_process_b": 0.10
	}

	var coexistence_allocation := (
		IndustryComponent.build_process_adoption_allocation(
			coexistence
		)
	)

	var coexistence_passed := (
		coexistence_allocation.size() == 3
		and is_equal_approx(
			coexistence_allocation["old_process"],
			0.60
		)
		and is_equal_approx(
			coexistence_allocation["new_process_a"],
			0.30
		)
		and is_equal_approx(
			coexistence_allocation["new_process_b"],
			0.10
		)
	)

	TestLogger.write_line(
        "Multiple processes coexist: "
		+ (
            "PASS"
			if coexistence_passed
			else "FAIL"
		)
	)

	passed = passed and coexistence_passed


	# ============================================================
	# TEST 2 — ADOPTION VALUES CLAMP TO 0..1
	# ============================================================

	var clamped := (
		IndustryComponent.build_process_adoption_allocation(
			{
				"negative": -0.5,
				"partial": 0.4,
				"excess": 1.7
			}
		)
	)

	var clamping_passed := (
		is_equal_approx(
			clamped["negative"],
			0.0
		)
		and is_equal_approx(
			clamped["partial"],
			0.4
		)
		and is_equal_approx(
			clamped["excess"],
			1.0
		)
	)

	TestLogger.write_line(
        "Competing adoption values clamp to 0..1: "
		+ (
            "PASS"
			if clamping_passed
			else "FAIL"
		)
		+ " | negative="
		+ str(clamped["negative"])
		+ " partial="
		+ str(clamped["partial"])
		+ " excess="
		+ str(clamped["excess"])
	)

	passed = passed and clamping_passed


	# ============================================================
	# TEST 3 — PARTIAL ADOPTION IS PRESERVED
	# ============================================================

	var partial := {
		"old_process": 0.60,
		"new_process": 0.30
	}

	var partial_allocation := (
		IndustryComponent.build_process_adoption_allocation(
			partial
		)
	)

	var partial_passed := (
		is_equal_approx(
			partial_allocation["old_process"],
			0.60
		)
		and is_equal_approx(
			partial_allocation["new_process"],
			0.30
		)
	)

	TestLogger.write_line(
        "Partial adoption preserved: "
		+ (
            "PASS"
			if partial_passed
			else "FAIL"
		)
		+ " | old="
		+ str(partial_allocation["old_process"])
		+ " new="
		+ str(partial_allocation["new_process"])
	)

	passed = passed and partial_passed


	# ============================================================
	# TEST 4 — ADOPTION TOTAL
	# ============================================================

	var total := (
		IndustryComponent.calculate_adoption_total(
			coexistence
		)
	)

	var total_passed := is_equal_approx(
		total,
		1.0
	)

	TestLogger.write_line(
        "Competing adoption total calculated: "
		+ (
            "PASS"
			if total_passed
			else "FAIL"
		)
		+ " | expected=1.0 actual="
		+ str(total)
	)

	passed = passed and total_passed


	# ============================================================
	# TEST 5 — VALID 100% ALLOCATION
	# ============================================================

	var valid_allocation := (
		IndustryComponent.is_valid_process_allocation(
			coexistence
		)
	)

	var valid_passed := valid_allocation

	TestLogger.write_line(
        "100% competing allocation is valid: "
		+ (
            "PASS"
			if valid_passed
			else "FAIL"
		)
	)

	passed = passed and valid_passed


	# ============================================================
	# TEST 6 — PARTIAL ALLOCATION DOES NOT GET FORCED TO 100%
	# ============================================================

	var partial_total := (
		IndustryComponent.calculate_adoption_total(
			partial
		)
	)

	var partial_total_passed := is_equal_approx(
		partial_total,
		0.90
	)

	TestLogger.write_line(
        "Partial allocation is not forced to 100%: "
		+ (
            "PASS"
			if partial_total_passed
			else "FAIL"
		)
		+ " | expected=0.9 actual="
		+ str(partial_total)
	)

	passed = passed and partial_total_passed


	# ============================================================
	# TEST 7 — NORMALIZATION IS EXPLICIT
	# ============================================================

	var unbalanced := {
		"process_a": 0.60,
		"process_b": 0.60,
		"process_c": 0.20
	}

	var unbalanced_total := (
		IndustryComponent.calculate_adoption_total(
			unbalanced
		)
	)

	var unbalanced_passed := is_equal_approx(
		unbalanced_total,
		1.40
	)

	TestLogger.write_line(
        "Unnormalized competing total preserved: "
		+ (
            "PASS"
			if unbalanced_passed
			else "FAIL"
		)
		+ " | expected=1.4 actual="
		+ str(unbalanced_total)
	)

	passed = passed and unbalanced_passed


	# ============================================================
	# TEST 8 — NORMALIZATION PRODUCES 100% TOTAL
	# ============================================================

	var normalized := (
		IndustryComponent.normalize_process_adoption(
			unbalanced
		)
	)

	var normalized_total := (
		IndustryComponent.calculate_adoption_total(
			normalized
		)
	)

	var normalization_passed := (
		is_equal_approx(
			normalized_total,
			1.0
		)
		and is_equal_approx(
			normalized["process_a"],
			0.60 / 1.40
		)
		and is_equal_approx(
			normalized["process_b"],
			0.60 / 1.40
		)
		and is_equal_approx(
			normalized["process_c"],
			0.20 / 1.40
		)
	)

	TestLogger.write_line(
        "Explicit normalization produces 100% total: "
		+ (
            "PASS"
			if normalization_passed
			else "FAIL"
		)
		+ " | total="
		+ str(normalized_total)
	)

	passed = passed and normalization_passed


	# ============================================================
	# TEST 9 — PROCESS SHARE LOOKUP
	# ============================================================

	var share := (
		IndustryComponent.get_process_adoption_share(
			coexistence,
            "new_process_a"
		)
	)

	var share_passed := is_equal_approx(
		share,
		0.30
	)

	TestLogger.write_line(
        "Individual process adoption share: "
		+ (
            "PASS"
			if share_passed
			else "FAIL"
		)
		+ " | expected=0.3 actual="
		+ str(share)
	)

	passed = passed and share_passed


	# ============================================================
	# TEST 10 — UNKNOWN PROCESS SHARE IS ZERO
	# ============================================================

	var unknown_share := (
		IndustryComponent.get_process_adoption_share(
			coexistence,
            "unknown_process"
		)
	)

	var unknown_passed := is_equal_approx(
		unknown_share,
		0.0
	)

	TestLogger.write_line(
        "Unknown process adoption share is zero: "
		+ (
            "PASS"
			if unknown_passed
			else "FAIL"
		)
		+ " | expected=0.0 actual="
		+ str(unknown_share)
	)

	passed = passed and unknown_passed


	# ============================================================
	# TEST 11 — SETUP CREATES ALLOCATION STATE
	# ============================================================

	var component := IndustryComponent.new(
        "step_8_test"
	)

	component.setup(
		{
			"old_process": {},
			"new_process_a": {},
			"new_process_b": {}
		},
		coexistence,
		{
			"old_process": 0.0,
			"new_process_a": 0.1,
			"new_process_b": 0.1
		}
	)

	var state_allocation: Dictionary = component.get_state(
		"process_adoption_allocation",
		{}
	)

	var state_passed := (
		state_allocation.size() == 3
		and is_equal_approx(
			state_allocation["old_process"],
			0.60
		)
		and is_equal_approx(
			state_allocation["new_process_a"],
			0.30
		)
		and is_equal_approx(
			state_allocation["new_process_b"],
			0.10
		)
	)

	TestLogger.write_line(
        "Setup creates competing-process allocation state: "
		+ (
            "PASS"
			if state_passed
			else "FAIL"
		)
	)

	passed = passed and state_passed


	# ============================================================
	# TEST 12 — EXISTING TRANSITION MODEL REMAINS INDEPENDENT
	# ============================================================

	var transition_midpoint := (
		IndustryComponent.calculate_transition_adoption(
			0.0,
			1.0,
			5,
			10
		)
	)

	var transition_passed := is_equal_approx(
		transition_midpoint,
		0.5
	)

	TestLogger.write_line(
        "Existing transition calculation remains unchanged: "
		+ (
            "PASS"
			if transition_passed
			else "FAIL"
		)
		+ " | expected=0.5 actual="
		+ str(transition_midpoint)
	)

	passed = passed and transition_passed


	# ============================================================
	# FINAL RESULT
	# ============================================================

	TestLogger.write_line("")
	TestLogger.write_line(
        "Competing process adoption test passed: "
		+ str(passed)
	)

	return passed
