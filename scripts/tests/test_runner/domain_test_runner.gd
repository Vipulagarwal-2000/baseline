class_name DomainTestRunner
extends RefCounted


# ============================================================
# DOMAIN TEST RUNNER
# ============================================================
#
# Owns the remaining domain-level regression/validation families that are
# not already owned by DataTestRunner, InteractionTestRunner, or
# PhysicalEconomyTestRunner.
#
# Structured checks: 94
#
# One local-domain check remains outside the structured runner:
# IndustryProcessInfrastructurePressureTest.
# Its current local contract is not present in the authoritative source set
# used to construct this runner, so the master suite preserves that call as
# a legacy-domain check instead of inventing its result contract.
# ============================================================


const RUNNER_ID := "domain"
const DISPLAY_NAME := "Domain Test Runner"
const EXPECTED_TEST_COUNT := 94


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
		"DOMAIN TEST RUNNER"
	)

	TestLogger.write_line(
		"Remaining domain validation"
	)


	TestLogger.section(
		"[DOMAIN] EVENT FRAMEWORK"
	)


	_record(
		result,
		"Event Condition",
				EventConditionTest.run(),
		"res://scripts/tests/EventConditionTest.gd",
		"Event Condition validation returned FAIL.",
		"Inspect res://scripts/tests/EventConditionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Condition Evaluator",
				EventConditionEvaluatorTest.run(),
		"res://scripts/tests/EventConditionEvaluatorTest.gd",
		"Event Condition Evaluator validation returned FAIL.",
		"Inspect res://scripts/tests/EventConditionEvaluatorTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Condition Validation",
				EventConditionValidationTest.run(),
		"res://scripts/tests/EventConditionValidationTest.gd",
		"Event Condition Validation validation returned FAIL.",
		"Inspect res://scripts/tests/EventConditionValidationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Trigger Evaluator",
				EventTriggerEvaluatorTest.run(
					world,
					simulation
				),
		"res://scripts/tests/EventTriggerEvaluatorTest.gd",
		"Event Trigger Evaluator validation returned FAIL.",
		"Inspect res://scripts/tests/EventTriggerEvaluatorTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Effect",
				EventEffectTest.run(),
		"res://scripts/tests/EventEffectTest.gd",
		"Event Effect validation returned FAIL.",
		"Inspect res://scripts/tests/EventEffectTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Effect Execution",
				EventEffectExecutionTest.run(),
		"res://scripts/tests/EventEffectExecutionTest.gd",
		"Event Effect Execution validation returned FAIL.",
		"Inspect res://scripts/tests/EventEffectExecutionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Execution",
				EventExecutionTest.run(),
		"res://scripts/tests/EventExecutionTest.gd",
		"Event Execution validation returned FAIL.",
		"Inspect res://scripts/tests/EventExecutionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Choice",
				EventChoiceTest.run(),
		"res://scripts/tests/EventChoiceTest.gd",
		"Event Choice validation returned FAIL.",
		"Inspect res://scripts/tests/EventChoiceTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Randomness",
				EventRandomnessTest.run(),
		"res://scripts/tests/EventRandomnessTest.gd",
		"Event Randomness validation returned FAIL.",
		"Inspect res://scripts/tests/EventRandomnessTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Repeatability",
				EventRepeatabilityTest.run(),
		"res://scripts/tests/EventRepeatabilityTest.gd",
		"Event Repeatability validation returned FAIL.",
		"Inspect res://scripts/tests/EventRepeatabilityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event History Integration",
				EventHistoryIntegrationTest.run(),
		"res://scripts/tests/EventHistoryIntegrationTest.gd",
		"Event History Integration validation returned FAIL.",
		"Inspect res://scripts/tests/EventHistoryIntegrationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Event Simulation Integration",
				EventSimulationIntegrationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/EventSimulationIntegrationTest.gd",
		"Event Simulation Integration validation returned FAIL.",
		"Inspect res://scripts/tests/EventSimulationIntegrationTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] INDUSTRY PROCESS / TRANSITION"
	)


	_record(
		result,
		"Industry Process Adoption State",
				IndustryProcessAdoptionStateTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessAdoptionStateTest.gd",
		"Industry Process Adoption State validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessAdoptionStateTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Adoption Rate",
				IndustryProcessAdoptionRateTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessAdoptionRateTest.gd",
		"Industry Process Adoption Rate validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessAdoptionRateTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Transition",
				IndustryProcessTransitionTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessTransitionTest.gd",
		"Industry Process Transition validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessTransitionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Transition Cost",
				IndustryProcessTransitionCostTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessTransitionCostTest.gd",
		"Industry Process Transition Cost validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessTransitionCostTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Capacity Growth",
				IndustryProcessCapacityGrowthTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessCapacityGrowthTest.gd",
		"Industry Process Capacity Growth validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessCapacityGrowthTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Displacement",
				IndustryProcessDisplacementTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessDisplacementTest.gd",
		"Industry Process Displacement validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessDisplacementTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Obsolescence",
				IndustryProcessObsolescenceTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessObsolescenceTest.gd",
		"Industry Process Obsolescence validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessObsolescenceTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Competing Adoption",
				IndustryProcessCompetingAdoptionTest.run(
			world,
			simulation
		),
		"res://scripts/tests/IndustryProcessCompetingAdoptionTest.gd",
		"Industry Process Competing Adoption validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessCompetingAdoptionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Gradual Transition",
				IndustryProcessGradualTransitionTest.run(
				world,
				simulation
			),
		"res://scripts/tests/IndustryProcessGradualTransitionTest.gd",
		"Industry Process Gradual Transition validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessGradualTransitionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Incomplete Transition",
				IndustryProcessIncompleteTransitionTest.run(
				world,
				simulation
			),
		"res://scripts/tests/IndustryProcessIncompleteTransitionTest.gd",
		"Industry Process Incomplete Transition validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessIncompleteTransitionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Competing Processes",
				IndustryProcessCompetingProcessesTest.run(
				world,
				simulation
			),
		"res://scripts/tests/IndustryProcessCompetingProcessesTest.gd",
		"Industry Process Competing Processes validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessCompetingProcessesTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Industry Process Resource Demand",
				IndustryProcessResourceDemandTest.run(
				world,
				simulation
			),
		"res://scripts/tests/IndustryProcessResourceDemandTest.gd",
		"Industry Process Resource Demand validation returned FAIL.",
		"Inspect res://scripts/tests/IndustryProcessResourceDemandTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] MVP CAUSAL CLOSURE"
	)


	_record(
		result,
		"Resource Stock Flow Accounting",
				ResourceStockFlowAccountingTest.run(
					world,
					simulation
				),
		"res://scripts/tests/ResourceStockFlowAccountingTest.gd",
		"Resource Stock Flow Accounting validation returned FAIL.",
		"Inspect res://scripts/tests/ResourceStockFlowAccountingTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Inventory Stock Buffer Semantics",
				InventoryStockBufferSemanticsTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InventoryStockBufferSemanticsTest.gd",
		"Inventory Stock Buffer Semantics validation returned FAIL.",
		"Inspect res://scripts/tests/InventoryStockBufferSemanticsTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Aggregate Demand",
				AggregateDemandTest.run(
					world,
					simulation
				),
		"res://scripts/tests/AggregateDemandTest.gd",
		"Aggregate Demand validation returned FAIL.",
		"Inspect res://scripts/tests/AggregateDemandTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Aggregate Consumption",
				AggregateConsumptionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/AggregateConsumptionTest.gd",
		"Aggregate Consumption validation returned FAIL.",
		"Inspect res://scripts/tests/AggregateConsumptionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Supply Demand Resolution",
				SupplyDemandResolutionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/SupplyDemandResolutionTest.gd",
		"Supply Demand Resolution validation returned FAIL.",
		"Inspect res://scripts/tests/SupplyDemandResolutionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Capacity Utilization",
				CapacityUtilizationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/CapacityUtilizationTest.gd",
		"Capacity Utilization validation returned FAIL.",
		"Inspect res://scripts/tests/CapacityUtilizationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Basic Price Formation",
				BasicPriceFormationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/BasicPriceFormationTest.gd",
		"Basic Price Formation validation returned FAIL.",
		"Inspect res://scripts/tests/BasicPriceFormationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Income Wage Flow",
				IncomeWageFlowTest.run(
					world,
					simulation
				),
		"res://scripts/tests/IncomeWageFlowTest.gd",
		"Income Wage Flow validation returned FAIL.",
		"Inspect res://scripts/tests/IncomeWageFlowTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Purchasing Power",
				PurchasingPowerTest.run(
					world,
					simulation
				),
		"res://scripts/tests/PurchasingPowerTest.gd",
		"Purchasing Power validation returned FAIL.",
		"Inspect res://scripts/tests/PurchasingPowerTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Resource Allocation Distribution",
				ResourceAllocationDistributionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/ResourceAllocationDistributionTest.gd",
		"Resource Allocation Distribution validation returned FAIL.",
		"Inspect res://scripts/tests/ResourceAllocationDistributionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Payment",
				TradePaymentTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradePaymentTest.gd",
		"Trade Payment validation returned FAIL.",
		"Inspect res://scripts/tests/TradePaymentTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] FINANCIAL / ALLOCATION"
	)


	_record(
		result,
		"Currency Identity",
				CurrencyIdentityTest.run(
					world,
					simulation
				),
		"res://scripts/tests/CurrencyIdentityTest.gd",
		"Currency Identity validation returned FAIL.",
		"Inspect res://scripts/tests/CurrencyIdentityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Valuation",
				TradeValuationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeValuationTest.gd",
		"Trade Valuation validation returned FAIL.",
		"Inspect res://scripts/tests/TradeValuationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Payment Settlement",
				PaymentSettlementTest.run(
					world,
					simulation
				),
		"res://scripts/tests/PaymentSettlementTest.gd",
		"Payment Settlement validation returned FAIL.",
		"Inspect res://scripts/tests/PaymentSettlementTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Payment Affordability",
				PaymentAffordabilityTest.run(
					world,
					simulation
				),
		"res://scripts/tests/PaymentAffordabilityTest.gd",
		"Payment Affordability validation returned FAIL.",
		"Inspect res://scripts/tests/PaymentAffordabilityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Currency Conversion",
				CurrencyConversionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/CurrencyConversionTest.gd",
		"Currency Conversion validation returned FAIL.",
		"Inspect res://scripts/tests/CurrencyConversionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Monetary Invariant",
				MonetaryInvariantTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MonetaryInvariantTest.gd",
		"Monetary Invariant validation returned FAIL.",
		"Inspect res://scripts/tests/MonetaryInvariantTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Integration",
				TradeIntegrationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeIntegrationTest.gd",
		"Trade Integration validation returned FAIL.",
		"Inspect res://scripts/tests/TradeIntegrationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Scarce Resource Allocation",
				ScarceResourceAllocationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/ScarceResourceAllocationTest.gd",
		"Scarce Resource Allocation validation returned FAIL.",
		"Inspect res://scripts/tests/ScarceResourceAllocationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Priority Class Allocation",
				PriorityClassAllocationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/PriorityClassAllocationTest.gd",
		"Priority Class Allocation validation returned FAIL.",
		"Inspect res://scripts/tests/PriorityClassAllocationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Domestic Accessibility",
				DomesticAccessibilityTest.run(
					world,
					simulation
				),
		"res://scripts/tests/DomesticAccessibilityTest.gd",
		"Domestic Accessibility validation returned FAIL.",
		"Inspect res://scripts/tests/DomesticAccessibilityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Allocation Consequences",
				AllocationConsequencesTest.run(
					world,
					simulation
				),
		"res://scripts/tests/AllocationConsequencesTest.gd",
		"Allocation Consequences validation returned FAIL.",
		"Inspect res://scripts/tests/AllocationConsequencesTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] GOVERNMENT"
	)


	_record(
		result,
		"Government Policy Definition",
				GovernmentPolicyDefinitionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentPolicyDefinitionTest.gd",
		"Government Policy Definition validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentPolicyDefinitionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Policy Activation",
				GovernmentPolicyActivationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentPolicyActivationTest.gd",
		"Government Policy Activation validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentPolicyActivationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Policy Cost",
				GovernmentPolicyCostTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentPolicyCostTest.gd",
		"Government Policy Cost validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentPolicyCostTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Policy Effect",
				GovernmentPolicyEffectTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentPolicyEffectTest.gd",
		"Government Policy Effect validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentPolicyEffectTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Tax Incidence",
				TaxIncidenceTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TaxIncidenceTest.gd",
		"Tax Incidence validation returned FAIL.",
		"Inspect res://scripts/tests/TaxIncidenceTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Spending Allocation",
				GovernmentSpendingAllocationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentSpendingAllocationTest.gd",
		"Government Spending Allocation validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentSpendingAllocationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Public Service Output",
				GovernmentPublicServiceOutputTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentPublicServiceOutputTest.gd",
		"Government Public Service Output validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentPublicServiceOutputTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Law Amendment",
				GovernmentLawAmendmentTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentLawAmendmentTest.gd",
		"Government Law Amendment validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentLawAmendmentTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Implementation Capacity",
				GovernmentImplementationCapacityTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentImplementationCapacityTest.gd",
		"Government Implementation Capacity validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentImplementationCapacityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Transition",
				GovernmentTransitionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/GovernmentTransitionTest.gd",
		"Government Transition validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentTransitionTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] POPULATION / WELFARE"
	)


	_record(
		result,
		"Standard Of Living",
				StandardOfLivingTest.run(
					world,
					simulation
				),
		"res://scripts/tests/StandardOfLivingTest.gd",
		"Standard Of Living validation returned FAIL.",
		"Inspect res://scripts/tests/StandardOfLivingTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Welfare Effect",
				WelfareEffectTest.run(
					world,
					simulation
				),
		"res://scripts/tests/WelfareEffectTest.gd",
		"Welfare Effect validation returned FAIL.",
		"Inspect res://scripts/tests/WelfareEffectTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Income Consumption Feedback",
				IncomeConsumptionFeedbackTest.run(
					world,
					simulation
				),
		"res://scripts/tests/IncomeConsumptionFeedbackTest.gd",
		"Income Consumption Feedback validation returned FAIL.",
		"Inspect res://scripts/tests/IncomeConsumptionFeedbackTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Economic Pressure Political Feedback",
				EconomicPressurePoliticalFeedbackTest.run(
					world,
					simulation
				),
		"res://scripts/tests/EconomicPressurePoliticalFeedbackTest.gd",
		"Economic Pressure Political Feedback validation returned FAIL.",
		"Inspect res://scripts/tests/EconomicPressurePoliticalFeedbackTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Basic Population Response",
				BasicPopulationResponseTest.run(
					world,
					simulation
				),
		"res://scripts/tests/BasicPopulationResponseTest.gd",
		"Basic Population Response validation returned FAIL.",
		"Inspect res://scripts/tests/BasicPopulationResponseTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Government Feedback",
		GovernmentFeedbackTest.run(
			world,
			simulation
		),
		"res://scripts/tests/GovernmentFeedbackTest.gd",
		"Government Feedback validation returned FAIL.",
		"Inspect res://scripts/tests/GovernmentFeedbackTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] INTERNATIONAL / EXTERNAL WORLD"
	)


	_record(
		result,
		"Core Country Registry",
				CoreCountryRegistryTest.run(
					world,
					simulation
				),
		"res://scripts/tests/CoreCountryRegistryTest.gd",
		"Core Country Registry validation returned FAIL.",
		"Inspect res://scripts/tests/CoreCountryRegistryTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"External World Actor",
				ExternalWorldActorTest.run(
				world,
				simulation
			),
		"res://scripts/tests/ExternalWorldActorTest.gd",
		"External World Actor validation returned FAIL.",
		"Inspect res://scripts/tests/ExternalWorldActorTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"External Event Causality",
				ExternalEventCausalityTest.run(
				world,
				simulation
			),
		"res://scripts/tests/ExternalEventCausalityTest.gd",
		"External Event Causality validation returned FAIL.",
		"Inspect res://scripts/tests/ExternalEventCausalityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"External Actor Limited Simulation",
				ExternalActorLimitedSimulationTest.run(
				world,
				simulation
			),
		"res://scripts/tests/ExternalActorLimitedSimulationTest.gd",
		"External Actor Limited Simulation validation returned FAIL.",
		"Inspect res://scripts/tests/ExternalActorLimitedSimulationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"External Event Relevance Filter",
				ExternalEventRelevanceFilterTest.run(
				world,
				simulation
			),
		"res://scripts/tests/ExternalEventRelevanceFilterTest.gd",
		"External Event Relevance Filter validation returned FAIL.",
		"Inspect res://scripts/tests/ExternalEventRelevanceFilterTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] TRADE RESTRICTIONS"
	)


	_record(
		result,
		"Trade Embargo",
				TradeEmbargoTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeEmbargoTest.gd",
		"Trade Embargo validation returned FAIL.",
		"Inspect res://scripts/tests/TradeEmbargoTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Route Restriction",
				TradeRouteRestrictionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeRouteRestrictionTest.gd",
		"Trade Route Restriction validation returned FAIL.",
		"Inspect res://scripts/tests/TradeRouteRestrictionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Restriction Interaction",
				TradeRestrictionInteractionTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeRestrictionInteractionTest.gd",
		"Trade Restriction Interaction validation returned FAIL.",
		"Inspect res://scripts/tests/TradeRestrictionInteractionTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Trade Restriction Recovery",
				TradeRestrictionRecoveryTest.run(
					world,
					simulation
				),
		"res://scripts/tests/TradeRestrictionRecoveryTest.gd",
		"Trade Restriction Recovery validation returned FAIL.",
		"Inspect res://scripts/tests/TradeRestrictionRecoveryTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] REGIONALIZATION"
	)


	_record(
		result,
		"Regionalization",
				RegionalizationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalizationTest.gd",
		"Regionalization validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalizationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Ownership",
				RegionalOwnershipTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalOwnershipTest.gd",
		"Regional Ownership validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalOwnershipTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Terrain",
				RegionalTerrainTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalTerrainTest.gd",
		"Regional Terrain validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalTerrainTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Population",
				RegionalPopulationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalPopulationTest.gd",
		"Regional Population validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalPopulationTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Resource",
				RegionalResourceTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalResourceTest.gd",
		"Regional Resource validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalResourceTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Infrastructure",
				RegionalInfrastructureTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalInfrastructureTest.gd",
		"Regional Infrastructure validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalInfrastructureTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Industry",
				RegionalIndustryTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalIndustryTest.gd",
		"Regional Industry validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalIndustryTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Regional Transport",
				RegionalTransportTest.run(
					world,
					simulation
				),
		"res://scripts/tests/RegionalTransportTest.gd",
		"Regional Transport validation returned FAIL.",
		"Inspect res://scripts/tests/RegionalTransportTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Country Aggregation",
				CountryAggregationTest.run(
					world,
					simulation
				),
		"res://scripts/tests/CountryAggregationTest.gd",
		"Country Aggregation validation returned FAIL.",
		"Inspect res://scripts/tests/CountryAggregationTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] MILITARY / ECONOMY / INFRASTRUCTURE"
	)


	_record(
		result,
		"Military Production Capacity",
				MilitaryProductionCapacityTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryProductionCapacityTest.gd",
		"Military Production Capacity validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryProductionCapacityTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Resource Readiness",
				MilitaryResourceReadinessTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryResourceReadinessTest.gd",
		"Military Resource Readiness validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryResourceReadinessTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Transport Logistics",
				MilitaryTransportLogisticsTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryTransportLogisticsTest.gd",
		"Military Transport Logistics validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryTransportLogisticsTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Port Naval Logistics",
				MilitaryPortNavalLogisticsTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryPortNavalLogisticsTest.gd",
		"Military Port Naval Logistics validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryPortNavalLogisticsTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Power Infrastructure",
				MilitaryPowerInfrastructureTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryPowerInfrastructureTest.gd",
		"Military Power Infrastructure validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryPowerInfrastructureTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Resource Demand",
				MilitaryResourceDemandTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryResourceDemandTest.gd",
		"Military Resource Demand validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryResourceDemandTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Military Economic Pressure",
				MilitaryEconomicPressureTest.run(
					world,
					simulation
				),
		"res://scripts/tests/MilitaryEconomicPressureTest.gd",
		"Military Economic Pressure validation returned FAIL.",
		"Inspect res://scripts/tests/MilitaryEconomicPressureTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] INFRASTRUCTURE DAMAGE / RECONSTRUCTION"
	)


	_record(
		result,
		"Infrastructure Damage",
				InfrastructureDamageTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructureDamageTest.gd",
		"Infrastructure Damage validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructureDamageTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Infrastructure Capacity Loss",
				InfrastructureCapacityLossTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructureCapacityLossTest.gd",
		"Infrastructure Capacity Loss validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructureCapacityLossTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Infrastructure Physical Consequences",
				InfrastructurePhysicalConsequencesTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructurePhysicalConsequencesTest.gd",
		"Infrastructure Physical Consequences validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructurePhysicalConsequencesTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Infrastructure Economic Consequences",
				InfrastructureEconomicConsequencesTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructureEconomicConsequencesTest.gd",
		"Infrastructure Economic Consequences validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructureEconomicConsequencesTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Infrastructure Reconstruction Investment",
				InfrastructureReconstructionInvestmentTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructureReconstructionInvestmentTest.gd",
		"Infrastructure Reconstruction Investment validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructureReconstructionInvestmentTest.gd and the authoritative domain path exercised by the test."
	)


	_record(
		result,
		"Infrastructure Recovery",
				InfrastructureRecoveryTest.run(
					world,
					simulation
				),
		"res://scripts/tests/InfrastructureRecoveryTest.gd",
		"Infrastructure Recovery validation returned FAIL.",
		"Inspect res://scripts/tests/InfrastructureRecoveryTest.gd and the authoritative domain path exercised by the test."
	)


	TestLogger.section(
		"[DOMAIN] WORLD VALIDATION"
	)


	_record(
		result,
		"World State Validation",
				WorldStateValidationTest.run(
				world
			),
		"res://scripts/tests/WorldStateValidationTest.gd",
		"World State Validation validation returned FAIL.",
		"Inspect res://scripts/tests/WorldStateValidationTest.gd and the authoritative domain path exercised by the test."
	)


	result.set_metadata(
		"scope",
		"remaining domain validation"
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

	result.set_metadata(
		"legacy_domain_checks",
		[
			"IndustryProcessInfrastructurePressureTest"
		]
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
