class_name PhysicalEconomyTestRunner
extends RefCounted


# ============================================================
# PHYSICAL ECONOMY TEST RUNNER
# ============================================================
#
# Step 9 — domain validation for infrastructure, integrated physical
# economy, resources, production, trade, and economy.
#
# This is deliberately narrower than a generic "domain" runner so it
# does not become another monolith.
#
# Included:
#   Infrastructure                         4
#   Integrated physical economy            7
#   Resource system                        1
#   Resource semantic readiness            1
#   Currency valuation semantics           1
#   Production / industry / catalogs     14
#   Trade                                  9
#   Economy                                6
#   -----------------------------------------
#   Total                                 43
#
# Not included here:
#   industry-process transition/adoption tests whose legacy master runner
#   does not currently capture a boolean result;
#   currency / monetary invariant runtime settlement tests;
#   government / population / regional tests;
#   military / infrastructure-damage tests;
#   feedback / campaign / causal tests.
#
# Existing run_all_tests.gd is intentionally not modified in this step.
# ============================================================


const RUNNER_ID := "physical_economy"
const DISPLAY_NAME := "Physical Economy Test Runner"
const EXPECTED_TEST_COUNT := 45


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
        "PHYSICAL ECONOMY TEST RUNNER"
	)

	TestLogger.write_line(
        "Infrastructure, physical economy, resources, production, trade, and economy validation"
	)

	TestLogger.section(
		"[DOMAIN] INFRASTRUCTURE"
	)

	_record(
		result,
		"Infrastructure System",
		InfrastructureSystemTest.run(world, simulation),
		"res://scripts/tests/InfrastructureSystemTest.gd",
		"Infrastructure System validation returned FAIL.",
        "Inspect InfrastructureSystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Infrastructure Investment System",
		InfrastructureInvestmentSystemTest.run(world, simulation),
		"res://scripts/tests/InfrastructureInvestmentSystemTest.gd",
		"Infrastructure Investment System validation returned FAIL.",
        "Inspect InfrastructureInvestmentSystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Infrastructure Maintenance System",
		InfrastructureMaintenanceSystemTest.run(world, simulation),
		"res://scripts/tests/InfrastructureMaintenanceSystemTest.gd",
		"Infrastructure Maintenance System validation returned FAIL.",
        "Inspect InfrastructureMaintenanceSystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Infrastructure Construction System",
		InfrastructureConstructionSystemTest.run(world, simulation),
		"res://scripts/tests/InfrastructureConstructionSystemTest.gd",
		"Infrastructure Construction System validation returned FAIL.",
        "Inspect InfrastructureConstructionSystemTest.gd and the authoritative domain path exercised by the test."
	)

	TestLogger.section(
		"[DOMAIN] INTEGRATED PHYSICAL ECONOMY"
	)

	_record(
		result,
		"Integrated Physical Economy — Production → Resource Demand",
		IntegratedPhysicalEconomyProductionResourceDemandTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyProductionResourceDemandTest.gd",
		"Integrated Physical Economy — Production → Resource Demand validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyProductionResourceDemandTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Resource Shortage → Production Constraint",
		IntegratedPhysicalEconomyResourceShortageConstraintTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyResourceShortageConstraintTest.gd",
		"Integrated Physical Economy — Resource Shortage → Production Constraint validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyResourceShortageConstraintTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Production → Economic Output",
		IntegratedPhysicalEconomyProductionEconomicOutputTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyProductionEconomicOutputTest.gd",
		"Integrated Physical Economy — Production → Economic Output validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyProductionEconomicOutputTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Infrastructure → Physical Output",
		IntegratedPhysicalEconomyInfrastructurePhysicalOutputTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyInfrastructurePhysicalOutputTest.gd",
		"Integrated Physical Economy — Infrastructure → Physical Output validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyInfrastructurePhysicalOutputTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Labor / Capital / Energy Persistence",
		IntegratedPhysicalEconomyLaborCapitalEnergyPersistenceTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyLaborCapitalEnergyPersistenceTest.gd",
		"Integrated Physical Economy — Labor / Capital / Energy Persistence validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyLaborCapitalEnergyPersistenceTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Technology Transition → Resource Mix",
		IntegratedPhysicalEconomyTechnologyResourceMixTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyTechnologyResourceMixTest.gd",
		"Integrated Physical Economy — Technology Transition → Resource Mix validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyTechnologyResourceMixTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Integrated Physical Economy — Multi-Month Interaction",
		IntegratedPhysicalEconomyMultiMonthInteractionTest.run(world, simulation),
		"res://scripts/tests/IntegratedPhysicalEconomyMultiMonthInteractionTest.gd",
		"Integrated Physical Economy — Multi-Month Interaction validation returned FAIL.",
        "Inspect IntegratedPhysicalEconomyMultiMonthInteractionTest.gd and the authoritative domain path exercised by the test."
	)

	TestLogger.section(
		"[DOMAIN] RESOURCES"
	)

	_record(
		result,
		"Currency / Valuation Semantic Foundation",
		CurrencyValuationSemanticsTest.run(),
		"res://scripts/tests/CurrencyValuationSemanticsTest.gd",
		"Currency / valuation semantic foundation validation returned FAIL.",
		"Inspect CurrencyValuationSemanticsTest.gd and the currency configuration / country identity authority."
	)

	_record(
		result,
		"Currency Runtime ↔ Semantic Integration",
		CurrencyRuntimeIntegrationSemanticsTest.run(world, simulation),
		"res://scripts/tests/CurrencyRuntimeIntegrationSemanticsTest.gd",
		"Currency runtime ↔ semantic integration validation returned FAIL.",
		"Inspect CurrencyRuntimeIntegrationSemanticsTest.gd and CurrencyConversionSystem.gd for semantic-authority/runtime integration."
	)

	_record(
		result,
		"Resource System",
		ResourceSystemTest.run(world, simulation),
		"res://scripts/tests/ResourceSystemTest.gd",
		"Resource System validation returned FAIL.",
        "Inspect ResourceSystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Resource ↔ Production Semantic Readiness",
		ResourceCatalogProductionSemanticsTest.run(),
		"res://scripts/tests/ResourceCatalogProductionSemanticsTest.gd",
		"Resource ↔ Production semantic readiness validation returned FAIL.",
        "Inspect ResourceCatalogProductionSemanticsTest.gd for unresolved resource references, incompatible roles/capabilities, or unsupported flow connections."
	)

	TestLogger.section(
		"[DOMAIN] PRODUCTION / INDUSTRY"
	)

	_record(
		result,
		"Production Process Component",
		ProductionProcessComponentTest.run(),
		"res://scripts/tests/ProductionProcessComponentTest.gd",
		"Production Process Component validation returned FAIL.",
        "Inspect ProductionProcessComponentTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Industry Component",
		IndustryComponentTest.run(),
		"res://scripts/tests/IndustryComponentTest.gd",
		"Industry Component validation returned FAIL.",
        "Inspect IndustryComponentTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Industry Loader",
		IndustryLoaderTest.run(world),
		"res://scripts/tests/IndustryLoaderTest.gd",
		"Industry Loader validation returned FAIL.",
        "Inspect IndustryLoaderTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process System",
		ProductionProcessSystemTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessSystemTest.gd",
		"Production Process System validation returned FAIL.",
        "Inspect ProductionProcessSystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Catalog",
		ProductionProcessCatalogTest.run(),
		"res://scripts/tests/ProductionProcessCatalogTest.gd",
		"Production Process Catalog validation returned FAIL.",
        "Inspect ProductionProcessCatalogTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Catalog Schema",
		ProductionProcessCatalogSchemaTest.run(),
		"res://scripts/tests/ProductionProcessCatalogSchemaTest.gd",
		"Production Process Catalog Schema validation returned FAIL.",
        "Inspect ProductionProcessCatalogSchemaTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Catalog Semantic",
		ProductionProcessCatalogSemanticTest.run(),
		"res://scripts/tests/ProductionProcessCatalogSemanticTest.gd",
		"Production Process Catalog Semantic validation returned FAIL.",
        "Inspect ProductionProcessCatalogSemanticTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Catalog Efficiency",
		ProductionProcessCatalogEfficiencyTest.run(),
		"res://scripts/tests/ProductionProcessCatalogEfficiencyTest.gd",
		"Production Process Catalog Efficiency validation returned FAIL.",
        "Inspect ProductionProcessCatalogEfficiencyTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Chain Catalog",
		ProductionProcessChainCatalogTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessChainCatalogTest.gd",
		"Production Process Chain Catalog validation returned FAIL.",
        "Inspect ProductionProcessChainCatalogTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Chain Execution",
		ProductionProcessChainExecutionTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessChainExecutionTest.gd",
		"Production Process Chain Execution validation returned FAIL.",
        "Inspect ProductionProcessChainExecutionTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Extraction Boundary",
		ProductionProcessExtractionBoundaryTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessExtractionBoundaryTest.gd",
		"Production Process Extraction Boundary validation returned FAIL.",
        "Inspect ProductionProcessExtractionBoundaryTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Requirement Evaluator",
		ProductionProcessRequirementEvaluatorTest.run(),
		"res://scripts/tests/ProductionProcessRequirementEvaluatorTest.gd",
		"Production Process Requirement Evaluator validation returned FAIL.",
        "Inspect ProductionProcessRequirementEvaluatorTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Requirement Integration",
		ProductionProcessRequirementIntegrationTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessRequirementIntegrationTest.gd",
		"Production Process Requirement Integration validation returned FAIL.",
        "Inspect ProductionProcessRequirementIntegrationTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Production Process Maintenance Integration",
		ProductionProcessMaintenanceIntegrationTest.run(world, simulation),
		"res://scripts/tests/ProductionProcessMaintenanceIntegrationTest.gd",
		"Production Process Maintenance Integration validation returned FAIL.",
        "Inspect ProductionProcessMaintenanceIntegrationTest.gd and the authoritative domain path exercised by the test."
	)

	var production_catalog_runtime_integration_passed: bool = (
		ProductionProcessCatalogRuntimeIntegrationTest.run(
			world,
			simulation
		)
	)

	var production_catalog_runtime_integration_diagnostic: String = (
		ProductionProcessCatalogRuntimeIntegrationTest.get_failure_reason()
	)

	_record(
		result,
		"Production Process Catalog ↔ Runtime Integration",
		production_catalog_runtime_integration_passed,
		"res://scripts/tests/ProductionProcessCatalogRuntimeIntegrationTest.gd",
		(
			"Production Process Catalog ↔ Runtime Integration validation returned FAIL. "
			+ production_catalog_runtime_integration_diagnostic
			if not production_catalog_runtime_integration_passed
			else "Production Process Catalog ↔ Runtime Integration validation returned FAIL."
		),
        "Inspect ProductionProcessCatalogRuntimeIntegrationTest.gd and the reported source/runtime catalog mismatch before changing any production data."
	)

	TestLogger.section(
		"[DOMAIN] TRADE"
	)

	_record(
		result,
		"Trade Agreement",
		TradeAgreementTest.run(world, simulation),
		"res://scripts/tests/TradeAgreementTest.gd",
		"Trade Agreement validation returned FAIL.",
        "Inspect TradeAgreementTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Route",
		TradeRouteTest.run(world, simulation),
		"res://scripts/tests/TradeRouteTest.gd",
		"Trade Route validation returned FAIL.",
        "Inspect TradeRouteTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Transaction",
		TradeTransactionTest.run(world, simulation),
		"res://scripts/tests/TradeTransactionTest.gd",
		"Trade Transaction validation returned FAIL.",
        "Inspect TradeTransactionTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Quantity / Availability",
		TradeQuantityAvailabilityTest.run(world, simulation),
		"res://scripts/tests/TradeQuantityAvailabilityTest.gd",
		"Trade Quantity / Availability validation returned FAIL.",
        "Inspect TradeQuantityAvailabilityTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Transport / Port Constraints",
		TradeTransportPortConstraintsTest.run(world, simulation),
		"res://scripts/tests/TradeTransportPortConstraintsTest.gd",
		"Trade Transport / Port Constraints validation returned FAIL.",
        "Inspect TradeTransportPortConstraintsTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Contract Duration",
		TradeContractDurationTest.run(world, simulation),
		"res://scripts/tests/TradeContractDurationTest.gd",
		"Trade Contract Duration validation returned FAIL.",
        "Inspect TradeContractDurationTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Disruption / Cancellation",
		TradeDisruptionCancellationTest.run(world, simulation),
		"res://scripts/tests/TradeDisruptionCancellationTest.gd",
		"Trade Disruption / Cancellation validation returned FAIL.",
        "Inspect TradeDisruptionCancellationTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Resource / Economic Consequences",
		TradeResourceEconomicConsequencesTest.run(world, simulation),
		"res://scripts/tests/TradeResourceEconomicConsequencesTest.gd",
		"Trade Resource / Economic Consequences validation returned FAIL.",
        "Inspect TradeResourceEconomicConsequencesTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Trade Diplomatic Consequences",
		TradeDiplomaticConsequencesTest.run(world, simulation),
		"res://scripts/tests/TradeDiplomaticConsequencesTest.gd",
		"Trade Diplomatic Consequences validation returned FAIL.",
        "Inspect TradeDiplomaticConsequencesTest.gd and the authoritative domain path exercised by the test."
	)

	TestLogger.section(
		"[DOMAIN] ECONOMY"
	)

	_record(
		result,
		"Economy System",
		EconomySystemTest.new().run_test(world),
		"res://scripts/tests/EconomySystemTest.gd",
		"Economy System validation returned FAIL.",
        "Inspect EconomySystemTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Economy Integration — Shortage → Economic Pressure",
		EconomyShortagePressureTest.run(world, simulation),
		"res://scripts/tests/EconomyShortagePressureTest.gd",
		"Economy Integration — Shortage → Economic Pressure validation returned FAIL.",
        "Inspect EconomyShortagePressureTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Economy Integration — Investment → Productive Capacity",
		EconomyInvestmentProductiveCapacityTest.run(world, simulation),
		"res://scripts/tests/EconomyInvestmentProductiveCapacityTest.gd",
		"Economy Integration — Investment → Productive Capacity validation returned FAIL.",
        "Inspect EconomyInvestmentProductiveCapacityTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Economy Integration — Economic Conditions → Government Finances",
		EconomyEconomicConditionsGovernmentFinancesTest.run(world, simulation),
		"res://scripts/tests/EconomyEconomicConditionsGovernmentFinancesTest.gd",
		"Economy Integration — Economic Conditions → Government Finances validation returned FAIL.",
        "Inspect EconomyEconomicConditionsGovernmentFinancesTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Economy Integration — Government Finances → Investment Capacity",
		EconomyGovernmentFinancesInvestmentCapacityTest.run(world, simulation),
		"res://scripts/tests/EconomyGovernmentFinancesInvestmentCapacityTest.gd",
		"Economy Integration — Government Finances → Investment Capacity validation returned FAIL.",
        "Inspect EconomyGovernmentFinancesInvestmentCapacityTest.gd and the authoritative domain path exercised by the test."
	)

	_record(
		result,
		"Economy Integration — Multi-Month Stability",
		EconomyMultiMonthStabilityTest.run(world, simulation),
		"res://scripts/tests/EconomyMultiMonthStabilityTest.gd",
		"Economy Integration — Multi-Month Stability validation returned FAIL.",
        "Inspect EconomyMultiMonthStabilityTest.gd and the authoritative domain path exercised by the test."
	)

	result.set_metadata(
		"scope",
        "infrastructure + integrated physical economy + resources + production + trade + economy"
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
        "controlled_fixture_restore"
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
		+ (
            "PASS"
			if passed
			else "FAIL"
		)
	)
