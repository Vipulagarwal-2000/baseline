class_name ProductionProcessExtractionBoundaryTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS EXTRACTION BOUNDARY TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation available: PASS"
	)


	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)


	var resources = india.get_component(
		"resources"
	)

	var industry = india.get_component(
		"industry"
	)

	if resources == null:
		TestLogger.write_line(
			"India resource component: FAIL"
		)
		return false

	if industry == null:
		TestLogger.write_line(
			"India industry component: FAIL"
		)
		return false

	TestLogger.write_line(
		"India resource component: PASS"
	)

	TestLogger.write_line(
		"India industry component: PASS"
	)


	# ============================================================
	# SAVE ORIGINAL STATE
	# ============================================================

	var original_stockpile = (
		resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)

	var original_processes = (
		industry.get_state(
			"processes",
			{}
		).duplicate(true)
	)


	# ============================================================
	# CREATE ISOLATED PROCESS STATE
	# ============================================================

	var test_processes: Dictionary = {}

	for process_id in original_processes.keys():

		var original_process = (
			original_processes[process_id]
		)

		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		test_processes[process_id] = (
			original_process.duplicate(true)
		)

		test_processes[process_id]["active"] = false


	# Activate both catalog extraction processes.

	test_processes["coal_mining"] = {
		"active": true,
		"capacity": 100.0,
		"efficiency": 1.0
	}

	test_processes["iron_ore_mining"] = {
		"active": true,
		"capacity": 100.0,
		"efficiency": 1.0
	}

	industry.set_state(
		"processes",
		test_processes
	)


	# ============================================================
	# CONTROLLED STOCKPILE
	# ============================================================

	var test_stockpile : Dictionary  = (
		original_stockpile.duplicate(true)
	)

	test_stockpile["coal"] = 25.0
	test_stockpile["iron"] = 15.0

	resources.set_state(
		"stockpile",
		test_stockpile
	)


	# ============================================================
	# EXECUTE PRODUCTION PROCESS SYSTEM
	# ============================================================

	var production_process_system := (
		ProductionProcessSystem.new()
	)

	production_process_system.process_month(
		world
	)


	# ============================================================
	# CHECK EXTRACTION PROCESSES WERE SKIPPED
	# ============================================================

	var result_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var coal_after := float(
		result_stockpile.get(
			"coal",
			0.0
		)
	)

	var iron_after := float(
		result_stockpile.get(
			"iron",
			0.0
		)
	)


	var coal_unchanged := is_equal_approx(
		coal_after,
		25.0
	)

	var iron_unchanged := is_equal_approx(
		iron_after,
		15.0
	)


	TestLogger.write_line(
		"Coal extraction skipped by ProductionProcessSystem: "
		+ (
			"PASS"
			if coal_unchanged
			else "FAIL"
		)
		+ " | expected=25.0 actual="
		+ str(coal_after)
	)

	TestLogger.write_line(
		"Iron extraction skipped by ProductionProcessSystem: "
		+ (
			"PASS"
			if iron_unchanged
			else "FAIL"
		)
		+ " | expected=15.0 actual="
		+ str(iron_after)
	)


	# ============================================================
	# RESTORE ORIGINAL STATE
	# ============================================================

	resources.set_state(
		"stockpile",
		original_stockpile
	)

	industry.set_state(
		"processes",
		original_processes
	)


	# ============================================================
	# FINAL RESULT
	# ============================================================

	var passed := (
		coal_unchanged
		and iron_unchanged
	)

	TestLogger.write_line(
		"ProductionProcess extraction boundary test passed: "
		+ str(passed)
	)

	return passed
