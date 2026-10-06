class_name MilitaryEconomicPressureTest
extends RefCounted


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.write_line("")
	TestLogger.write_line("============================================================")
	TestLogger.write_line("STEP 13.7 — MILITARY STATE → ECONOMIC PRESSURE TEST")
	TestLogger.write_line("============================================================")

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var pressure_system_instance: SimulationSystem = simulation.get_system(
		"military_economic_pressure_system"
	)
	var economy_system_instance: SimulationSystem = simulation.get_system(
		"economy_system"
	)
	var military_system_instance: SimulationSystem = simulation.get_system(
		"military_system"
	)

	var pressure_system_ok: bool = (
		pressure_system_instance != null
		and pressure_system_instance is MilitaryEconomicPressureSystem
	)
	var economy_system_ok: bool = economy_system_instance != null
	var military_system_ok: bool = military_system_instance != null

	_log_result(
		"Registered MilitaryEconomicPressureSystem available",
		pressure_system_ok
	)
	_log_result(
		"Registered EconomySystem available",
		economy_system_ok
	)
	_log_result(
		"Registered MilitarySystem available",
		military_system_ok
	)

	if not pressure_system_ok or not economy_system_ok or not military_system_ok:
		return false

	var india: SimEntity = world.get_entity("india")
	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false
	TestLogger.write_line("India available: PASS")

	var military: MilitaryComponent = india.get_component("military")
	var economy: EconomyComponent = india.get_component("economy")

	var components_ok: bool = (
		military != null
		and economy != null
	)
	_log_result(
		"India military and economy components available",
		components_ok
	)
	if not components_ok:
		return false

	var original_military_state: Dictionary = military.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	var pressure_system: MilitaryEconomicPressureSystem = (
		pressure_system_instance as MilitaryEconomicPressureSystem
	)

	var passed: bool = true

	# ------------------------------------------------------------
	# CASE 1 — NEUTRAL / LOW MILITARY BURDEN
	# ------------------------------------------------------------
	military.state = original_military_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)

	military.set_state("military_spending", 0.10)
	military.set_state("military_pressure", 0.05)
	military.set_state("war_exhaustion", 0.00)
	military.set_state("at_war", false)
	economy.set_state("economic_pressure", 0.0)

	pressure_system.process_month(world)

	var baseline_military_pressure: float = float(
		economy.get_state(
			"military_economic_pressure",
			-1.0
		)
	)
	var baseline_combined_pressure: float = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)
	var baseline_burden: float = float(
		economy.get_state(
			"military_economic_burden",
			-1.0
		)
	)

	var baseline_bounds_passed: bool = (
		baseline_military_pressure >= 0.0
		and baseline_military_pressure <= 1.0
		and baseline_combined_pressure >= 0.0
		and baseline_combined_pressure <= 1.0
		and baseline_burden >= 0.0
		and baseline_burden <= 1.0
	)
	_log_result(
		"Baseline military economic pressure remains bounded",
		baseline_bounds_passed
	)
	passed = passed and baseline_bounds_passed

	# ------------------------------------------------------------
	# CASE 2 — HIGH MILITARY BURDEN / CONFLICT
	# ------------------------------------------------------------
	military.set_state("military_spending", 0.90)
	military.set_state("military_pressure", 0.90)
	military.set_state("war_exhaustion", 0.60)
	military.set_state("at_war", true)
	economy.set_state("economic_pressure", 0.0)

	pressure_system.process_month(world)

	var conflict_military_pressure: float = float(
		economy.get_state(
			"military_economic_pressure",
			-1.0
		)
	)
	var conflict_combined_pressure: float = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)
	var conflict_burden: float = float(
		economy.get_state(
			"military_economic_burden",
			-1.0
		)
	)

	var high_burden_response_passed: bool = (
		conflict_military_pressure > baseline_military_pressure
		and conflict_combined_pressure > baseline_combined_pressure
		and conflict_burden > baseline_burden
	)
	_log_result(
		"Higher military burden increases economic pressure",
		high_burden_response_passed
	)
	passed = passed and high_burden_response_passed

	var conflict_bounds_passed: bool = (
		conflict_military_pressure >= 0.0
		and conflict_military_pressure <= 1.0
		and conflict_combined_pressure >= 0.0
		and conflict_combined_pressure <= 1.0
		and conflict_burden >= 0.0
		and conflict_burden <= 1.0
	)
	_log_result(
		"Conflict-derived economic pressure remains bounded",
		conflict_bounds_passed
	)
	passed = passed and conflict_bounds_passed

	# ------------------------------------------------------------
	# CASE 3 — PRESERVE EXISTING STRONGER ECONOMIC PRESSURE
	# ------------------------------------------------------------
	economy.set_state("economic_pressure", 0.85)
	military.set_state("military_spending", 0.10)
	military.set_state("military_pressure", 0.05)
	military.set_state("war_exhaustion", 0.00)
	military.set_state("at_war", false)

	pressure_system.process_month(world)

	var preserved_pressure: float = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)
	var preservation_passed: bool = is_equal_approx(
		preserved_pressure,
		0.85
	)
	_log_result(
		"Existing stronger economic pressure is preserved",
		preservation_passed
	)
	passed = passed and preservation_passed

	# ------------------------------------------------------------
	# CASE 4 — SOURCE MILITARY STATE IS NOT REWRITTEN
	# ------------------------------------------------------------
	var source_state_passed: bool = (
		is_equal_approx(
			float(military.get_state("military_spending", -1.0)),
			0.10
		)
		and is_equal_approx(
			float(military.get_state("military_pressure", -1.0)),
			0.05
		)
		and is_equal_approx(
			float(military.get_state("war_exhaustion", -1.0)),
			0.00
		)
		and bool(military.get_state("at_war", true)) == false
	)
	_log_result(
		"13.7 bridge does not rewrite source military state",
		source_state_passed
	)
	passed = passed and source_state_passed

	# ------------------------------------------------------------
	# CASE 5 — SAME SIGNAL EXISTS ON BOTH DOMAIN LEDGERS
	# ------------------------------------------------------------
	var ledger_link_passed: bool = (
		is_equal_approx(
			float(
				economy.get_state(
					"military_economic_pressure",
					-1.0
				)
			),
			float(
				military.get_state(
					"military_economic_pressure",
					-2.0
				)
			)
		)
		and str(
			economy.get_state(
				"military_economic_pressure_source",
				""
			)
		) == "MilitaryEconomicPressureSystem"
	)
	_log_result(
		"Military economic-pressure signal is explicit on both ledgers",
		ledger_link_passed
	)
	passed = passed and ledger_link_passed

	# ------------------------------------------------------------
	# RESTORE EXACT ORIGINAL STATE
	# ------------------------------------------------------------
	military.state = original_military_state
	economy.state = original_economy_state

	var restoration_passed: bool = (
		military.state == original_military_state
		and economy.state == original_economy_state
	)
	_log_result(
		"Step 13.7 fixture restoration",
		restoration_passed
	)
	passed = passed and restoration_passed

	TestLogger.write_line(
		"Step 13.7 military state → economic pressure overall: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
