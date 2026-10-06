class_name IndustryProcessCompetingProcessesTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS COMPETING PROCESSES TEST"
	)

	var passed := true

	# --------------------------------------------------
	# Multiple production processes can coexist in one
	# production structure.
	# --------------------------------------------------

	var competing := {
		"old_process": 0.60,
		"new_process_a": 0.30,
		"new_process_b": 0.10
	}

	var allocation := IndustryComponent.build_process_adoption_allocation(
		competing
	)

	var coexistence_passed := (
		allocation.size() == 3
		and is_equal_approx(allocation["old_process"], 0.60)
		and is_equal_approx(allocation["new_process_a"], 0.30)
		and is_equal_approx(allocation["new_process_b"], 0.10)
	)

	TestLogger.write_line(
		"Three competing processes coexist: "
		+ (
			"PASS"
			if coexistence_passed
			else "FAIL"
		)
	)

	passed = passed and coexistence_passed

	# --------------------------------------------------
	# The competing process shares form a complete 100%
	# allocation when they explicitly sum to 1.0.
	# --------------------------------------------------

	var total := IndustryComponent.calculate_adoption_total(
		competing
	)

	var total_passed := is_equal_approx(
		total,
		1.0
	)

	TestLogger.write_line(
		"Competing process allocation totals 100%: "
		+ (
			"PASS"
			if total_passed
			else "FAIL"
		)
		+ " | expected=1.0 actual="
		+ str(total)
	)

	passed = passed and total_passed

	# --------------------------------------------------
	# Each process keeps its own adoption share.
	# --------------------------------------------------

	var share_passed := (
		is_equal_approx(
			IndustryComponent.get_process_adoption_share(
				competing,
				"old_process"
			),
			0.60
		)
		and is_equal_approx(
			IndustryComponent.get_process_adoption_share(
				competing,
				"new_process_a"
			),
			0.30
		)
		and is_equal_approx(
			IndustryComponent.get_process_adoption_share(
				competing,
				"new_process_b"
			),
			0.10
		)
	)

	TestLogger.write_line(
		"Competing process shares remain distinct: "
		+ (
			"PASS"
			if share_passed
			else "FAIL"
		)
	)

	passed = passed and share_passed

	# --------------------------------------------------
	# A missing process does not silently receive adoption.
	# --------------------------------------------------

	var missing_share := IndustryComponent.get_process_adoption_share(
		competing,
		"missing_process"
	)

	var missing_process_passed := is_equal_approx(
		missing_share,
		0.0
	)

	TestLogger.write_line(
		"Missing competing process defaults to zero share: "
		+ (
			"PASS"
			if missing_process_passed
			else "FAIL"
		)
	)

	passed = passed and missing_process_passed

	# --------------------------------------------------
	# Unbalanced raw shares remain explicit until the caller
	# requests normalization.
	# --------------------------------------------------

	var unbalanced := {
		"process_a": 0.60,
		"process_b": 0.60,
		"process_c": 0.20
	}

	var raw_total := IndustryComponent.calculate_adoption_total(
		unbalanced
	)

	var raw_total_passed := is_equal_approx(
		raw_total,
		1.40
	)

	TestLogger.write_line(
		"Unbalanced competing shares remain explicit: "
		+ (
			"PASS"
			if raw_total_passed
			else "FAIL"
		)
		+ " | expected=1.4 actual="
		+ str(raw_total)
	)

	passed = passed and raw_total_passed

	# --------------------------------------------------
	# Explicit normalization creates a valid 100% allocation
	# without changing the relative proportions.
	# --------------------------------------------------

	var normalized := IndustryComponent.normalize_process_adoption(
		unbalanced
	)

	var normalized_total := IndustryComponent.calculate_adoption_total(
		normalized
	)

	var normalized_passed := (
		is_equal_approx(normalized_total, 1.0)
		and is_equal_approx(normalized["process_a"], 0.60 / 1.40)
		and is_equal_approx(normalized["process_b"], 0.60 / 1.40)
		and is_equal_approx(normalized["process_c"], 0.20 / 1.40)
	)

	TestLogger.write_line(
		"Explicit competing-process normalization: "
		+ (
			"PASS"
			if normalized_passed
			else "FAIL"
		)
	)

	passed = passed and normalized_passed

	# --------------------------------------------------
	# A valid competing allocation is accepted by the model.
	# --------------------------------------------------

	var valid := IndustryComponent.is_valid_process_allocation(
		competing
	)

	var valid_passed := valid

	TestLogger.write_line(
		"Competing process allocation is valid: "
		+ (
			"PASS"
			if valid_passed
			else "FAIL"
		)
	)

	passed = passed and valid_passed

	return passed
