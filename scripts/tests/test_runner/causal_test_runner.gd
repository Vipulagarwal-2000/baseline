class_name CausalTestRunner
extends RefCounted


# ============================================================
# CAUSAL TEST RUNNER
# ============================================================
#
# Owns the complete Step 19 causal validation family:
#
#   Step 19.1  Coal Shortage Causal Validation
#   Step 19.2  Railway Investment Causal Validation
#   Step 19.3  Power Shortage Causal Validation
#   Step 19.4  Technology Transition Causal Validation
#   Step 19.5  War / Military Burden Causal Validation
#   Step 19.6  Trade Disruption Causal Validation
#   Step 19.7  Recovery Causal Validation
#   Step 19.8  Divergence Causal Validation
#   Step 19.9  Event-Driven Scenario Validation
#   Step 19.A  Causal Architecture Coverage Audit
#
# The runner deliberately preserves the execution order used by the legacy
# master path. It does not create another SimulationEngine and does not add
# a second execution path for any causal scenario.
#
# Dynamic loading is retained for Step 19.5–19.A because those source files
# were already isolated behind ResourceLoader in the authoritative legacy
# path. This avoids introducing a second compile-time dependency boundary or
# duplicate class-resolution path.
# ============================================================


const RUNNER_ID := "causal"
const DISPLAY_NAME := "Causal Test Runner"
const EXPECTED_TEST_COUNT := 10


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> TestRunResult:

	var result := TestRunResult.new(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.start_scope(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.section(
        "CAUSAL TEST RUNNER"
	)

	TestLogger.write_line(
        "Step 19.1–19.A causal validation"
	)

	if world == null:
		_record(
			result,
			"Step 19.1 Coal Shortage Causal Validation",
			false,
			"res://scripts/tests/CoalShortageCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record(
			result,
			"Step 19.2 Railway Investment Causal Validation",
			false,
			"res://scripts/tests/RailwayInvestmentCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record(
			result,
			"Step 19.3 Power Shortage Causal Validation",
			false,
			"res://scripts/tests/PowerShortageCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record(
			result,
			"Step 19.4 Technology Transition Causal Validation",
			false,
			"res://scripts/tests/TechnologyTransitionCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.5 War / Military Burden Causal Validation",
			"res://scripts/tests/Step19_5WarMilitaryBurdenCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.6 Trade Disruption Causal Validation",
			"res://scripts/tests/Step19_6TradeDisruptionCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.7 Recovery Causal Validation",
			"res://scripts/tests/Step19_7RecoveryCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.8 Divergence Causal Validation",
			"res://scripts/tests/Step19_8DivergenceCausalValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.9 Event-Driven Scenario Validation",
			"res://scripts/tests/Step19_9EventDrivenScenarioValidationTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.A Causal Architecture Coverage Audit",
			"res://scripts/tests/Step19_CausalArchitectureCoverageAuditTest.gd",
			"Causal validation world was null.",
            "Provide the active WorldState used by the validation suite."
		)
	elif simulation == null:
		_record(
			result,
			"Step 19.1 Coal Shortage Causal Validation",
			false,
			"res://scripts/tests/CoalShortageCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record(
			result,
			"Step 19.2 Railway Investment Causal Validation",
			false,
			"res://scripts/tests/RailwayInvestmentCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record(
			result,
			"Step 19.3 Power Shortage Causal Validation",
			false,
			"res://scripts/tests/PowerShortageCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record(
			result,
			"Step 19.4 Technology Transition Causal Validation",
			false,
			"res://scripts/tests/TechnologyTransitionCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.5 War / Military Burden Causal Validation",
			"res://scripts/tests/Step19_5WarMilitaryBurdenCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.6 Trade Disruption Causal Validation",
			"res://scripts/tests/Step19_6TradeDisruptionCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.7 Recovery Causal Validation",
			"res://scripts/tests/Step19_7RecoveryCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.8 Divergence Causal Validation",
			"res://scripts/tests/Step19_8DivergenceCausalValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.9 Event-Driven Scenario Validation",
			"res://scripts/tests/Step19_9EventDrivenScenarioValidationTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
		_record_dynamic_failure(
			result,
			"Step 19.A Causal Architecture Coverage Audit",
			"res://scripts/tests/Step19_CausalArchitectureCoverageAuditTest.gd",
			"Causal validation simulation was null.",
            "Provide the active SimulationEngine used by the validation suite."
		)
	else:
		_record(
			result,
			"Step 19.1 Coal Shortage Causal Validation",
			Step19_1CoalShortageCausalValidationTest.run(
				world,
				simulation
			),
			"res://scripts/tests/CoalShortageCausalValidationTest.gd",
			"Step 19.1 coal-shortage causal chain returned FAIL.",
            "Inspect coal availability, steel and machinery constraints, realized output, economic pressure, and recovery behavior."
		)

		_record(
			result,
			"Step 19.2 Railway Investment Causal Validation",
			Step19_2RailwayInvestmentCausalValidationTest.run(
				world,
				simulation
			),
			"res://scripts/tests/RailwayInvestmentCausalValidationTest.gd",
			"Step 19.2 railway-investment causal chain returned FAIL.",
            "Inspect railway capacity, accessibility, steel/machinery production, physical output, and GDP propagation."
		)

		_record(
			result,
			"Step 19.3 Power Shortage Causal Validation",
			Step19_3PowerShortageCausalValidationTest.run(
				world,
				simulation
			),
			"res://scripts/tests/PowerShortageCausalValidationTest.gd",
			"Step 19.3 power-shortage causal chain returned FAIL.",
            "Inspect power availability, energy-intensive production, realized output, GDP, and economic pressure."
		)

		_record(
			result,
			"Step 19.4 Technology Transition Causal Validation",
			Step19_4TechnologyTransitionCausalValidationTest.run(
				world,
				simulation
			),
			"res://scripts/tests/TechnologyTransitionCausalValidationTest.gd",
			"Step 19.4 technology-transition causal chain returned FAIL.",
            "Inspect process adoption, resource-mix change, infrastructure requirements, production consequences, and recovery."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.5 War / Military Burden Causal Validation",
			"res://scripts/tests/Step19_5WarMilitaryBurdenCausalValidationTest.gd",
			"Step 19.5 war/military-burden causal validation returned FAIL.",
            "Inspect military demand, resource consumption, logistics burden, infrastructure disruption, production pressure, and economic pressure."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.6 Trade Disruption Causal Validation",
			"res://scripts/tests/Step19_6TradeDisruptionCausalValidationTest.gd",
			"Step 19.6 trade-disruption causal validation returned FAIL.",
            "Inspect route restriction, actual imports, resource availability, realized production, GDP, and explicit recovery."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.7 Recovery Causal Validation",
			"res://scripts/tests/Step19_7RecoveryCausalValidationTest.gd",
			"Step 19.7 recovery causal validation returned FAIL.",
            "Inspect recovery funding, reconstruction progress, authoritative damage reduction, next-cycle capacity refresh, and downstream recovery."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.8 Divergence Causal Validation",
			"res://scripts/tests/Step19_8DivergenceCausalValidationTest.gd",
			"Step 19.8 divergence causal validation returned FAIL.",
            "Inspect controlled branch setup, executable action admission, monthly action execution, relationship divergence, persistence, and divergence analysis."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.9 Event-Driven Scenario Validation",
			"res://scripts/tests/Step19_9EventDrivenScenarioValidationTest.gd",
			"Step 19.9 event-driven causal validation returned FAIL.",
            "Inspect the authoritative military trigger, EVENTS phase, event execution/effect path, government-state consequence, next-month consumption, and repeatability."
		)

		_record_dynamic(
			result,
			world,
			simulation,
			"Step 19.A Causal Architecture Coverage Audit",
			"res://scripts/tests/Step19_CausalArchitectureCoverageAuditTest.gd",
			"Step 19.A causal architecture coverage audit returned FAIL.",
            "Inspect the live SimulationEngine registration graph, expected phase/order contract, and registered-system coverage."
		)

	result.set_metadata(
		"scope",
        "Step 19.1–19.A causal validation"
	)

	result.set_metadata(
		"tests_expected",
		EXPECTED_TEST_COUNT
	)

	result.set_metadata(
		"requires_world",
		true
	)

	result.set_metadata(
		"requires_simulation",
		true
	)

	result.set_metadata(
		"mutation_policy",
        "controlled_fixture_restore_or_isolated_scenario"
	)

	result.set_metadata(
		"execution_order_preserved",
		true
	)

	result.set_metadata(
		"dynamic_sources",
		[
			"Step19_5WarMilitaryBurdenCausalValidationTest.gd",
			"Step19_6TradeDisruptionCausalValidationTest.gd",
			"Step19_7RecoveryCausalValidationTest.gd",
			"Step19_8DivergenceCausalValidationTest.gd",
			"Step19_9EventDrivenScenarioValidationTest.gd",
            "Step19_CausalArchitectureCoverageAuditTest.gd"
		]
	)

	result.set_metadata(
		"detail_source",
        "legacy TestLogger report"
	)

	result.set_metadata(
		"compact_result",
		true
	)

	result.finish()

	TestLogger.write_line("")
	TestLogger.write_line(
		result.summary_line()
	)

	TestLogger.finish()

	return result


static func _record_dynamic(
	result: TestRunResult,
	world: WorldState,
	simulation: SimulationEngine,
	test_name: String,
	source_file: String,
	diagnostic_message: String,
	action: String
) -> void:

	var passed: bool = false

	if ResourceLoader.exists(source_file):
		var script = load(source_file)

		if script != null and script.has_method("run"):
			passed = bool(
				script.run(
					world,
					simulation
				)
			)
		else:
			diagnostic_message = (
				diagnostic_message
				+ " Source loaded but does not expose static run(world, simulation)."
			)
			action = (
				action
				+ " Verify the source exposes static run(world, simulation)."
			)
	else:
		diagnostic_message = (
			diagnostic_message
			+ " Source file was not found."
		)
		action = (
			action
			+ " Restore the expected source file at the recorded path."
		)

	_record(
		result,
		test_name,
		passed,
		source_file,
		diagnostic_message,
		action
	)


static func _record_dynamic_failure(
	result: TestRunResult,
	test_name: String,
	source_file: String,
	diagnostic_message: String,
	action: String
) -> void:

	_record(
		result,
		test_name,
		false,
		source_file,
		diagnostic_message,
		action
	)


static func _record(
	result: TestRunResult,
	test_name: String,
	passed: bool,
	source_file: String,
	diagnostic_message: String,
	action: String
) -> void:

	result.record_test(
		test_name,
		passed,
		"",
		source_file,
		diagnostic_message,
		action
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		test_name
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)
