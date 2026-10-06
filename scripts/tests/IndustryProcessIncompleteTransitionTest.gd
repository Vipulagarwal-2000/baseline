class_name IndustryProcessIncompleteTransitionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS INCOMPLETE TRANSITION TEST"
	)

	var passed := true

	var start_adoption := 0.20
	var target_adoption := 0.60
	var duration_months := 10

	# --------------------------------------------------
	# A transition may intentionally finish below 100%.
	# --------------------------------------------------

	var halfway := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		5,
		duration_months
	)

	var midpoint_passed := is_equal_approx(
		halfway,
		0.40
	)

	TestLogger.write_line(
		"Incomplete transition midpoint adoption: "
		+ (
			"PASS"
			if midpoint_passed
			else "FAIL"
		)
		+ " | expected=0.4 actual="
		+ str(halfway)
	)

	passed = passed and midpoint_passed

	# --------------------------------------------------
	# Completion reaches the incomplete target, not 1.0.
	# --------------------------------------------------

	var completed := IndustryComponent.calculate_transition_adoption(
		start_adoption,
		target_adoption,
		duration_months,
		duration_months
	)

	var completion_passed := (
		is_equal_approx(completed, 0.60)
		and not is_equal_approx(completed, 1.00)
	)

	TestLogger.write_line(
		"Incomplete transition stops at partial target: "
		+ (
			"PASS"
			if completion_passed
			else "FAIL"
		)
		+ " | expected=0.6 actual="
		+ str(completed)
	)

	passed = passed and completion_passed

	# --------------------------------------------------
	# The incomplete transition leaves part of the old
	# process capacity in place.
	# --------------------------------------------------

	var old_remaining := IndustryComponent.calculate_old_process_capacity(
		100.0,
		target_adoption,
		duration_months,
		duration_months
	)

	var old_capacity_passed := is_equal_approx(
		old_remaining,
		40.0
	)

	TestLogger.write_line(
		"Incomplete transition preserves old-process capacity: "
		+ (
			"PASS"
			if old_capacity_passed
			else "FAIL"
		)
		+ " | expected=40.0 actual="
		+ str(old_remaining)
	)

	passed = passed and old_capacity_passed

	# --------------------------------------------------
	# New-process capacity is limited by the partial target.
	# --------------------------------------------------

	var new_capacity := IndustryComponent.calculate_new_process_capacity(
		100.0,
		target_adoption,
		duration_months,
		duration_months
	)

	var new_capacity_passed := is_equal_approx(
		new_capacity,
		60.0
	)

	TestLogger.write_line(
		"Incomplete transition limits new-process capacity: "
		+ (
			"PASS"
			if new_capacity_passed
			else "FAIL"
		)
		+ " | expected=60.0 actual="
		+ str(new_capacity)
	)

	passed = passed and new_capacity_passed

	# --------------------------------------------------
	# A process with a sub-100% target is not obsolete at
	# transition completion.
	# --------------------------------------------------

	var obsolete := IndustryComponent.is_process_obsolete(
		target_adoption,
		duration_months,
		duration_months
	)

	var obsolescence_passed := not obsolete

	TestLogger.write_line(
		"Incomplete transition does not force obsolescence: "
		+ (
			"PASS"
			if obsolescence_passed
			else "FAIL"
		)
	)

	passed = passed and obsolescence_passed

	return passed
