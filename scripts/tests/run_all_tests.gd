class_name RunAllTests
extends RefCounted


# ============================================================
# STEP 18.2 — DEDICATED 60-MONTH CAMPAIGN ENTRY POINT
# ============================================================
#
# Compatibility entry point for isolated/manual Step 18.2 execution.
#
# The normal project path now executes Step 18.2 through run() using a
# dedicated fresh campaign context supplied by main.gd. This method is
# retained only as an explicit isolated entry point and is not required
# for the ordinary `godot --path .` test run.
# ============================================================


static func run_step_18_2(
	world: WorldState,
	simulation: SimulationEngine,
	months: int = 60
) -> bool:

	TestLogger.start()

	TestLogger.section(
		"STEP 18.2 — DEDICATED 60-MONTH CAMPAIGN"
	)

	if world == null:
		TestLogger.write_line(
			"18.2 dedicated campaign world: FAIL"
		)
		TestLogger.finish()
		return false

	if simulation == null:
		TestLogger.write_line(
			"18.2 dedicated campaign simulation: FAIL"
		)
		TestLogger.finish()
		return false

	var passed: bool = (
		Step18_2Campaign60MonthValidationTest.run(
			world,
			simulation,
			months
		)
	)

	TestLogger.write_line(
		"Step 18.2 Dedicated 60-Month Campaign test: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	TestLogger.section(
		"STEP 18.2 COMPLETE"
	)

	TestLogger.finish()

	return passed


static func run(
	world: WorldState,
	simulation: SimulationEngine,
	run_step_18_1: bool = false,
	step_18_1_months: int = 1,
	campaign_world: WorldState = null,
	campaign_simulation: SimulationEngine = null,
	campaign_months: int = 60
) -> void:
	# Step 18.1 is opt-in so the default Step 15–17 regression remains
	# mutation-safe. Enable it with:
	# RunAllTests.run(world, simulation, true, 1)

	TestLogger.start()

	TestLogger.section(
        "RUNNING ACTIVE TEST SUITE"
	)

	if world == null:

		TestLogger.write_line(
            "TEST SUITE FAILED: world is null."
		)

		TestLogger.finish()

		return

	if simulation == null:

		TestLogger.write_line(
            "TEST SUITE FAILED: simulation is null."
		)

		TestLogger.finish()

		return


	# ============================================================
	# STEP 15.1 — ACTION CONTRACT
	# ============================================================

	# ============================================================
	# STEP 3.1 — CANONICAL RESOURCE DATA CONTRACT
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL RESOURCE CATALOG"
	)

	var resource_catalog_schema_test_passed := (
		ResourceCatalogSchemaTest.run()
	)

	TestLogger.write_line(
		"Step 3.1 Resource Catalog Schema test: "
		+ (
			"PASS"
			if resource_catalog_schema_test_passed
			else "FAIL"
		)
	)

	var resource_catalog_integrity_test_passed := (
		ResourceCatalogReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.1 Resource Catalog Referential Integrity test: "
		+ (
			"PASS"
			if resource_catalog_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# PHASE 3.1 — COMPLETE DATA INVENTORY
	# ============================================================

	TestLogger.section(
		"[DATA] COMPLETE DATA INVENTORY"
	)

	var data_inventory_test_passed := (
		DataInventoryTest.run()
	)

	TestLogger.write_line(
		"Phase 3.1 Data Inventory test: "
		+ (
			"PASS"
			if data_inventory_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.2 — CANONICAL ID REGISTRY
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL ID REGISTRY"
	)

	var canonical_id_registry_test_passed := (
		CanonicalIdRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.2 Canonical ID Registry schema test: "
		+ (
			"PASS"
			if canonical_id_registry_test_passed
			else "FAIL"
		)
	)

	var canonical_id_integrity_test_passed := (
		CanonicalIdReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.2 Canonical ID Referential Integrity test: "
		+ (
			"PASS"
			if canonical_id_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.3 — DOMAIN OWNERSHIP
	# ============================================================

	TestLogger.section(
		"[DATA] DOMAIN OWNERSHIP"
	)

	var domain_ownership_registry_test_passed := (
		DomainOwnershipRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.3 Domain Ownership Registry test: "
		+ (
			"PASS"
			if domain_ownership_registry_test_passed
			else "FAIL"
		)
	)

	var domain_ownership_integrity_test_passed := (
		DomainOwnershipReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.3 Domain Ownership Referential Integrity test: "
		+ (
			"PASS"
			if domain_ownership_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.4 — CANONICAL SCHEMAS
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL SCHEMAS"
	)

	var canonical_schema_registry_test_passed := (
		CanonicalSchemaRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.4 Canonical Schema Registry test: "
		+ (
			"PASS"
			if canonical_schema_registry_test_passed
			else "FAIL"
		)
	)

	var canonical_schema_integrity_test_passed := (
		CanonicalSchemaReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.4 Canonical Schema Referential Integrity test: "
		+ (
			"PASS"
			if canonical_schema_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.5 — REFERENTIAL INTEGRITY
	# ============================================================

	TestLogger.section(
		"[DATA] REFERENTIAL INTEGRITY"
	)

	var referential_integrity_rules_registry_test_passed := (
		ReferentialIntegrityRulesRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.5 Referential Integrity Rules Registry test: "
		+ (
			"PASS"
			if referential_integrity_rules_registry_test_passed
			else "FAIL"
		)
	)

	var referential_integrity_audit_test_passed := (
		ReferentialIntegrityAuditTest.run()
	)

	TestLogger.write_line(
		"Step 3.5 Referential Integrity Audit test: "
		+ (
			"PASS"
			if referential_integrity_audit_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.6 — PROVENANCE
	# ============================================================

	TestLogger.section(
		"[DATA] PROVENANCE"
	)

	var provenance_registry_test_passed := (
		ProvenanceRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.6 Provenance Registry test: "
		+ (
			"PASS"
			if provenance_registry_test_passed
			else "FAIL"
		)
	)

	var provenance_referential_integrity_test_passed := (
		ProvenanceReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.6 Provenance Referential Integrity test: "
		+ (
			"PASS"
			if provenance_referential_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.7 — VERSIONING
	# ============================================================

	TestLogger.section(
		"[DATA] VERSIONING"
	)

	var versioning_registry_test_passed := (
		VersioningRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.7 Versioning Registry test: "
		+ (
			"PASS"
			if versioning_registry_test_passed
			else "FAIL"
		)
	)

	var versioning_referential_integrity_test_passed := (
		VersioningReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.7 Versioning Referential Integrity test: "
		+ (
			"PASS"
			if versioning_referential_integrity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 3.8 — CATALOG / LOADER OWNERSHIP
	# ============================================================

	TestLogger.section(
		"[DATA] CATALOG / LOADER OWNERSHIP"
	)

	var catalog_loader_ownership_registry_test_passed := (
		CatalogLoaderOwnershipRegistryTest.run()
	)

	TestLogger.write_line(
		"Step 3.8 Catalog/Loader Ownership Registry test: "
		+ (
			"PASS"
			if catalog_loader_ownership_registry_test_passed
			else "FAIL"
		)
	)

	var catalog_loader_ownership_referential_integrity_test_passed := (
		CatalogLoaderOwnershipReferentialIntegrityTest.run()
	)

	TestLogger.write_line(
		"Step 3.8 Catalog/Loader Ownership Referential Integrity test: "
		+ (
			"PASS"
			if catalog_loader_ownership_referential_integrity_test_passed
			else "FAIL"
		)
	)

	TestLogger.section(
		"[2.4] ACTION CONTRACT"
	)

	var action_contract_test_passed = (
		ActionContractTest.run()
	)

	TestLogger.write_line(
		"Step 15.1 Action Contract test: "
		+ (
			"PASS"
			if action_contract_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.2 — DECISION → ACTION CONVERSION
	# ============================================================

	TestLogger.section(
		"[2.4.1] DECISION → ACTION CONVERSION"
	)

	var decision_action_conversion_test_passed: bool = (
		DecisionActionConversionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.2 Decision → Action Conversion test: "
		+ (
			"PASS"
			if decision_action_conversion_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.3 — ACTIONS PHASE → ACTION MANAGER
	# ============================================================

	TestLogger.section(
		"[2.4.2] ACTIONS PHASE → ACTION MANAGER"
	)

	var action_phase_execution_test_passed: bool = (
		ActionPhaseExecutionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.3 ACTIONS Phase → ActionManager execution test: "
		+ (
			"PASS"
			if action_phase_execution_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.4 — ACTION VALIDATION
	# ============================================================

	TestLogger.section(
		"[2.4.3] ACTION VALIDATION"
	)

	var action_validation_test_passed: bool = (
		ActionValidationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.4 Action Validation test: "
		+ (
			"PASS"
			if action_validation_test_passed
			else "FAIL"
		)
	)



	# ============================================================
	# STEP 15.5 — RESOURCE / FINANCIAL / CAPABILITY / CAPACITY
	# ============================================================

	TestLogger.section(
		"[2.4.4] ACTION REQUIREMENT CHECKS"
	)

	var action_requirement_checks_test_passed: bool = (
		ActionRequirementChecksTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.5 Resource / Financial / Capability / Capacity Checks test: "
		+ (
			"PASS"
			if action_requirement_checks_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 15.6 — RESERVATION / COMMITMENT
	# ============================================================

	TestLogger.section(
		"[2.4.5] RESERVATION / COMMITMENT"
	)

	var action_reservation_commitment_test_passed: bool = (
		ActionReservationCommitmentTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.6 Reservation / Commitment test: "
		+ (
			"PASS"
			if action_reservation_commitment_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 15.7 — DURATION / MONTHLY PROGRESS
	# ============================================================

	TestLogger.section(
		"[2.4.6] DURATION / MONTHLY PROGRESS"
	)

	var action_duration_progress_test_passed: bool = (
		ActionDurationProgressTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.7 Duration / Monthly Progress test: "
		+ (
			"PASS"
			if action_duration_progress_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 15.8 — COMPLETION / WORLD-STATE CHANGE
	# ============================================================

	TestLogger.section(
		"[2.4.7] COMPLETION / WORLD-STATE CHANGE"
	)

	var action_completion_world_state_test_passed: bool = (
		ActionCompletionWorldStateTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.8 Completion / World-State Change test: "
		+ (
			"PASS"
			if action_completion_world_state_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 15.9 — FAILURE / CANCELLATION
	# ============================================================

	TestLogger.section(
		"[2.4.8] FAILURE / CANCELLATION"
	)

	var action_failure_cancellation_test_passed: bool = (
		ActionFailureCancellationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.9 Failure / Cancellation test: "
		+ (
			"PASS"
			if action_failure_cancellation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.10 — PLAYER / AI PARITY
	# ============================================================

	TestLogger.section(
		"[2.4.9] PLAYER / AI PARITY"
	)

	var action_player_ai_parity_test_passed: bool = (
		ActionPlayerAIParityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.10 Player / AI Parity test: "
		+ (
			"PASS"
			if action_player_ai_parity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.11 — ACTION OUTCOME / HISTORY RECORD
	# ============================================================

	TestLogger.section(
		"[2.4.10] ACTION OUTCOME / HISTORY"
	)

	var action_outcome_history_test_passed: bool = (
		ActionOutcomeHistoryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.11 Action Outcome / History test: "
		+ (
			"PASS"
			if action_outcome_history_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.12 — SNAPSHOT SAFETY
	# ============================================================

	TestLogger.section(
		"[2.4.11] ACTION SNAPSHOT SAFETY"
	)

	var action_snapshot_safety_test_passed: bool = (
		ActionSnapshotSafetyTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.12 Snapshot Safety test: "
		+ (
			"PASS"
			if action_snapshot_safety_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.13 — AI FEEDBACK
	# ============================================================

	TestLogger.section(
		"[2.4.12] AI FEEDBACK"
	)

	var action_ai_feedback_test_passed: bool = (
		ActionAIFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.13 AI Feedback test: "
		+ (
			"PASS"
			if action_ai_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.14 — PLAYER-ISSUED ACTION PATHWAY
	# ============================================================

	TestLogger.section(
		"[2.4.13] PLAYER-ISSUED ACTION PATHWAY"
	)

	var player_action_issuance_test_passed: bool = (
		PlayerActionIssuanceTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.14 Player-Issued Action Pathway test: "
		+ (
			"PASS"
			if player_action_issuance_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 15.15 — ACTION EXECUTION END-TO-END ACCEPTANCE
	# ============================================================

	TestLogger.section(
		"[2.4.14] ACTION EXECUTION END-TO-END ACCEPTANCE"
	)

	var action_execution_end_to_end_test_passed: bool = (
		ActionExecutionEndToEndTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 15.15 Action Execution End-to-End Acceptance test: "
		+ (
			"PASS"
			if action_execution_end_to_end_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.1 — ACTION CAPACITY
	# ============================================================

	TestLogger.section(
		"[2.4.15] CONCURRENT ACTION CAPACITY"
	)

	var action_capacity_test_passed: bool = (
		ActionCapacityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.1 Action Capacity test: "
		+ (
			"PASS"
			if action_capacity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.2 — CONCURRENT ACTION ADMISSION
	# ============================================================

	TestLogger.section(
		"[2.4.16] CONCURRENT ACTION ADMISSION"
	)

	var concurrent_action_admission_test_passed: bool = (
		ConcurrentActionAdmissionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.2 Concurrent Admission test: "
		+ (
			"PASS"
			if concurrent_action_admission_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.3 — CONTENTION
	# ============================================================

	TestLogger.section(
		"[2.4.17] ACTION CONTENTION"
	)

	var action_contention_test_passed: bool = (
		ActionContentionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.3 Contention test: "
		+ (
			"PASS"
			if action_contention_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.4 — DETERMINISTIC RESOLUTION
	# ============================================================

	TestLogger.section(
		"[2.4.18] DETERMINISTIC ACTION RESOLUTION"
	)

	var deterministic_action_resolution_test_passed: bool = (
		DeterministicActionResolutionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.4 Deterministic Resolution test: "
		+ (
			"PASS"
			if deterministic_action_resolution_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.5 — CANCELLATION / INTERRUPTION
	# ============================================================

	TestLogger.section(
		"[2.4.19] CANCELLATION / INTERRUPTION"
	)

	var concurrent_action_cancellation_test_passed: bool = (
		ConcurrentActionCancellationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.5 Cancellation / Interruption test: "
		+ (
			"PASS"
			if concurrent_action_cancellation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.6 — SNAPSHOT / LOAD
	# ============================================================

	TestLogger.section(
		"[2.4.20] SNAPSHOT / LOAD"
	)

	var concurrent_action_snapshot_load_test_passed: bool = (
		ConcurrentActionSnapshotLoadTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.6 Snapshot / Load test: "
		+ (
			"PASS"
			if concurrent_action_snapshot_load_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 16.7 — CONCURRENT ACTION REGRESSION / ACCEPTANCE
	# ============================================================

	TestLogger.section(
		"[2.4.21] CONCURRENT ACTION REGRESSION / ACCEPTANCE"
	)

	var concurrent_action_regression_test_passed: bool = (
		ConcurrentActionRegressionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 16.7 Concurrent Action Regression test: "
		+ (
			"PASS"
			if concurrent_action_regression_test_passed
			else "FAIL"
		)
	)



	# ============================================================
	# EVENT FRAMEWORK — E4.4 AND / OR / NOT
	# ============================================================

	TestLogger.section(
		"[EVENT] E4.4 — AND / OR / NOT"
	)

	var event_condition_e4_4_test_passed: bool = (
		EventConditionTest.run()
	)

	TestLogger.write_line(
		"E4.4 EventCondition test: "
		+ (
			"PASS"
			if event_condition_e4_4_test_passed
			else "FAIL"
		)
	)

	var event_condition_evaluator_e4_4_test_passed: bool = (
		EventConditionEvaluatorTest.run()
	)

	TestLogger.write_line(
		"E4.4 EventConditionEvaluator test: "
		+ (
			"PASS"
			if event_condition_evaluator_e4_4_test_passed
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"E4.4 AND / OR / NOT overall: "
		+ (
			"PASS"
			if (
				event_condition_e4_4_test_passed
				and event_condition_evaluator_e4_4_test_passed
			)
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E4.5 COMPLETE CONDITION VALIDATION
	# ============================================================

	TestLogger.section(
		"[EVENT] E4.5 — COMPLETE CONDITION VALIDATION"
	)

	var event_condition_e4_5_validation_test_passed: bool = (
		EventConditionValidationTest.run()
	)

	TestLogger.write_line(
		"E4.5 Complete Condition Validation test: "
		+ (
			"PASS"
			if event_condition_e4_5_validation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E5 EVENT TRIGGER EVALUATION
	# ============================================================

	TestLogger.section(
		"[EVENT] E5 — EVENT TRIGGER EVALUATION"
	)

	var event_trigger_e5_test_passed: bool = (
		EventTriggerEvaluatorTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"E5 Event Trigger Evaluation test: "
		+ (
			"PASS"
			if event_trigger_e5_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E6 EFFECT MODEL
	# ============================================================

	TestLogger.section(
		"[EVENT] E6 — EFFECT MODEL"
	)

	var event_effect_e6_test_passed: bool = (
		EventEffectTest.run()
	)

	TestLogger.write_line(
		"E6 Effect Model test: "
		+ (
			"PASS"
			if event_effect_e6_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E7 EFFECT EXECUTION
	# ============================================================

	TestLogger.section(
		"[EVENT] E7 — EFFECT EXECUTION"
	)

	var event_effect_e7_test_passed: bool = (
		EventEffectExecutionTest.run()
	)

	TestLogger.write_line(
		"E7 Effect Execution test: "
		+ (
			"PASS"
			if event_effect_e7_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E8 EVENT EXECUTION
	# ============================================================

	TestLogger.section(
		"[EVENT] E8 — EVENT EXECUTION"
	)

	var event_execution_e8_test_passed: bool = (
		EventExecutionTest.run()
	)

	TestLogger.write_line(
		"E8 Event Execution test: "
		+ (
			"PASS"
			if event_execution_e8_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E9 CHOICES
	# ============================================================

	TestLogger.section(
		"[EVENT] E9 — CHOICES"
	)

	var event_choice_e9_test_passed: bool = (
		EventChoiceTest.run()
	)

	TestLogger.write_line(
		"E9 Choices test: "
		+ (
			"PASS"
			if event_choice_e9_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E10 DETERMINISTIC RANDOMNESS
	# ============================================================

	TestLogger.section(
		"[EVENT] E10 — DETERMINISTIC RANDOMNESS"
	)

	var event_randomness_e10_test_passed: bool = (
		EventRandomnessTest.run()
	)

	TestLogger.write_line(
		"E10 Deterministic Randomness test: "
		+ (
			"PASS"
			if event_randomness_e10_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E11 COOLDOWNS / REPEATABILITY
	# ============================================================

	TestLogger.section(
		"[EVENT] E11 — COOLDOWNS / REPEATABILITY"
	)

	var event_repeatability_e11_test_passed: bool = (
		EventRepeatabilityTest.run()
	)

	TestLogger.write_line(
		"E11 Cooldowns / Repeatability test: "
		+ (
			"PASS"
			if event_repeatability_e11_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E12 HISTORY INTEGRATION
	# ============================================================

	TestLogger.section(
		"[EVENT] E12 — HISTORY INTEGRATION"
	)

	var event_history_e12_test_passed: bool = (
		EventHistoryIntegrationTest.run()
	)

	TestLogger.write_line(
		"E12 History Integration test: "
		+ (
			"PASS"
			if event_history_e12_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# EVENT FRAMEWORK — E13 SIMULATION INTEGRATION
	# ============================================================

	TestLogger.section(
		"[EVENT] E13 — SIMULATION INTEGRATION"
	)

	var event_simulation_e13_test_passed: bool = (
		EventSimulationIntegrationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"E13 Simulation Integration test: "
		+ (
			"PASS"
			if event_simulation_e13_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# DECISION / AI
	# ============================================================

	# TestLogger.section(
	# "[1] DECISION / AI"
	# )

	# DecisionIntegrationTest.run(
	# world,
	# simulation
	# )

	# AIMonthlyExecutionTest.run(
	# world,
	# simulation
	# )


	# ============================================================
	# EVENTS
	# ============================================================

	# TestLogger.section(
	# "[2] EVENTS"
# )

	# EventDefinitionTest.run()

	# EventDefinitionLoaderTest.run()

	# EventConditionTest.run()

	# EventConditionEvaluatorTest.run()

	# EventSynchronizerTest.run(
	# world
	# )

	# ============================================================
	# MILITARY / RESEARCH
	#
	# Military regression tests are temporarily disabled.
	# They are already completed and remain available as files.
	# ============================================================

	# TestLogger.section(
	#     "[3] MILITARY / RESEARCH"
	# )

	# ResearchTest.run(
	#     world
	# )

	# MilitaryTest.run(
	#     world,
	#     simulation
	# )

	# MilitaryGeographyTest.run(
	#     world,
	#     simulation
	# )

	# var military_government_test = (
	#     MilitaryGovernmentTest.new()
	# )

	# military_government_test.run(
	#     world,
	#     simulation
	# )

	# MilitaryGovernmentFeedbackTest.run(
	#     world,
	#     simulation
	# )

	# MilitaryCapabilityTest.run(
	#     world,
	#     simulation
	# )

	# MilitaryInfluenceTest.run(
	#     world,
	#     simulation
	# )

	# MilitaryRelationshipTest.run(
	#     world,
	#     simulation
	# )

	# var military_strategy_test = (
	#     MilitaryStrategyTest.new()
	# )

	# military_strategy_test.run(
	#     world,
	#     simulation
	# )

	# var military_goal_test = (
	#     MilitaryGoalTest.new()
	# )

	# military_goal_test.run_test(
	#     world,
	#     simulation
	# )

	# var military_integration_test = (
	#     MilitaryIntegrationTest.new()
	# )

	# military_integration_test.run(
	#     world,
	#     simulation
	# )


	# ============================================================
	# BASIC CONFLICT
	# ============================================================

	# TestLogger.section(
	#     "BASIC CONFLICT"
	# )

	# var conflict_test_passed = ConflictTest.run(
	#     world,
	#     simulation
	# )

	# TestLogger.write_line(
	#     "Basic Conflict tests: "
	#     + (
	#         "PASS"
	#         if conflict_test_passed
	#         else "FAIL"
	#     )
	# )


	# ============================================================
	# WAR EXHAUSTION
	# ============================================================

	# TestLogger.section(
	#     "WAR EXHAUSTION"
	# )

	# var war_exhaustion_test_passed = WarExhaustionTest.run(
	#     world,
	#     simulation
	# )

	# TestLogger.write_line(
	#     "War Exhaustion tests: "
	#     + (
	#         "PASS"
	#         if war_exhaustion_test_passed
	#         else "FAIL"
	#     )
	# )


	# ============================================================
	# MILITARY EVENTS
	# ============================================================

	# var military_event_test_passed = MilitaryEventTest.run(
	#     world,
	#     simulation
	# )

	# TestLogger.write_line(
	#     "Military Event tests: "
	#     + (
	#         "PASS"
	#         if military_event_test_passed
	#         else "FAIL"
	#     )
	# )


	# var military_pressure_event_test_passed = (
	#     MilitaryPressureEventTest.run(
	#         world,
	#         simulation
	#     )
	# )

	# TestLogger.write_line(
	#     "Military Pressure Event tests: "
	#     + (
	#         "PASS"
	#         if military_pressure_event_test_passed
	#         else "FAIL"
	#     )
	# )


	# var war_exhaustion_event_test_passed = (
	#     WarExhaustionEventTest.run(
	#         world,
	#         simulation
	#     )
	# )

	# TestLogger.write_line(
	#     "War Exhaustion Event tests: "
	#     + (
	#         "PASS"
	#         if war_exhaustion_event_test_passed
	#         else "FAIL"
	#     )
	# )


	# var conflict_resolved_event_test_passed = (
	#     ConflictResolvedEventTest.run(
	#         world,
	#         simulation
	#     )
	# )

	# TestLogger.write_line(
	#     "Conflict Resolved Event tests: "
	#     + (
	#         "PASS"
	#         if conflict_resolved_event_test_passed
	#         else "FAIL"
	#     )
	# )


	# var military_history_test_passed = (
	#     MilitaryHistoryTest.run(
	#         world,
	#         simulation
	#     )
	# )

	# TestLogger.write_line(
	#     "Military History tests: "
	#     + (
	#         "PASS"
	#         if military_history_test_passed
	#         else "FAIL"
	#     )
	# )

	# ============================================================
	# Infrastructure
	# ============================================================

	TestLogger.section(
        "[2.5] RESOURCES"
	)


	var infrastructure_system_test_passed = (
		InfrastructureSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Infrastructure System test: "
		+ (
            "PASS"
			if infrastructure_system_test_passed
			else "FAIL"
		)
	)


	var infrastructure_investment_system_test_passed = (
		InfrastructureInvestmentSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Infrastructure Investment System test: "
		+ (
            "PASS"
			if infrastructure_investment_system_test_passed
			else "FAIL"
		)
	)


	var infrastructure_maintenance_system_test_passed = (
		InfrastructureMaintenanceSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Infrastructure Maintenance System test: "
		+ (
            "PASS"
			if infrastructure_maintenance_system_test_passed
			else "FAIL"
		)
	)


	var infrastructure_construction_system_test_passed = (
		InfrastructureConstructionSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Infrastructure Construction System test: "
		+ (
            "PASS"
			if infrastructure_construction_system_test_passed
			else "FAIL"
		)
	)

	IndustryProcessAdoptionStateTest.run(
	world,
	simulation
)

	IndustryProcessAdoptionRateTest.run(
	world,
	simulation
)

	IndustryProcessTransitionTest.run(
	world,
	simulation
)

	IndustryProcessTransitionCostTest.run(
	world,
	simulation
)

	IndustryProcessCapacityGrowthTest.run(
	world,
	simulation
)

	IndustryProcessDisplacementTest.run(
	world,
	simulation
)

	IndustryProcessObsolescenceTest.run(
	world,
	simulation
)



	IndustryProcessCompetingAdoptionTest.run(
	world,
	simulation
)

	# ------------------------------------------------------------
	# TRANSITION VALIDATION GATE
	# Gradual, incomplete, and competing-process behavior are
	# validated together before moving to integrated physical economy.
	# ------------------------------------------------------------

	IndustryProcessGradualTransitionTest.run(
		world,
		simulation
	)

	IndustryProcessIncompleteTransitionTest.run(
		world,
		simulation
	)

	IndustryProcessCompetingProcessesTest.run(
		world,
		simulation
	)

	IndustryProcessResourceDemandTest.run(
		world,
		simulation
	)

	var integrated_physical_economy_production_resource_demand_test_passed = (
		IntegratedPhysicalEconomyProductionResourceDemandTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Production -> Resource Demand test: "
		+ (
            "PASS"
			if integrated_physical_economy_production_resource_demand_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_resource_shortage_constraint_test_passed = (
		IntegratedPhysicalEconomyResourceShortageConstraintTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Resource Shortage -> Production Constraint test: "
		+ (
            "PASS"
			if integrated_physical_economy_resource_shortage_constraint_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_production_economic_output_test_passed = (
		IntegratedPhysicalEconomyProductionEconomicOutputTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Production -> Economic Output test: "
		+ (
            "PASS"
			if integrated_physical_economy_production_economic_output_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_infrastructure_physical_output_test_passed = (
		IntegratedPhysicalEconomyInfrastructurePhysicalOutputTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Infrastructure -> Physical Output test: "
		+ (
            "PASS"
			if integrated_physical_economy_infrastructure_physical_output_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_labor_capital_energy_persistence_test_passed = (
		IntegratedPhysicalEconomyLaborCapitalEnergyPersistenceTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Labor / Capital / Energy Persistence test: "
		+ (
            "PASS"
			if integrated_physical_economy_labor_capital_energy_persistence_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_technology_resource_mix_test_passed = (
		IntegratedPhysicalEconomyTechnologyResourceMixTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Technology Transition -> Resource Mix test: "
		+ (
            "PASS"
			if integrated_physical_economy_technology_resource_mix_test_passed
			else "FAIL"
		)
	)

	var integrated_physical_economy_multi_month_interaction_test_passed = (
		IntegratedPhysicalEconomyMultiMonthInteractionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Integrated Physical Economy — Multi-Month Interaction test: "
		+ (
            "PASS"
			if integrated_physical_economy_multi_month_interaction_test_passed
			else "FAIL"
		)
	)

	IndustryProcessInfrastructurePressureTest.run(
		world,
		simulation
	)


	# ============================================================
	# RESOURCES
	# ============================================================

	TestLogger.section(
        "[3] RESOURCES"
	)

	var resource_system_test_passed = (
		ResourceSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Resource System tests: "
		+ (
            "PASS"
			if resource_system_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# PRODUCTION PROCESS
	# ============================================================

	TestLogger.section(
        "[4] PRODUCTION PROCESS"
	)

	var production_process_component_test_passed = (
		ProductionProcessComponentTest.run()
	)

	TestLogger.write_line(
        "ProductionProcess component test: "
		+ (
            "PASS"
			if production_process_component_test_passed
			else "FAIL"
		)
	)


	var industry_component_test_passed = (
		IndustryComponentTest.run()
	)

	TestLogger.write_line(
        "Industry Component test: "
		+ (
            "PASS"
			if industry_component_test_passed
			else "FAIL"
		)
	)


	var industry_loader_test_passed = (
		IndustryLoaderTest.run(
			world
		)
	)

	TestLogger.write_line(
        "Industry Loader test: "
		+ (
            "PASS"
			if industry_loader_test_passed
			else "FAIL"
		)
	)


	var production_process_system_test_passed = (
		ProductionProcessSystemTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "ProductionProcessSystem test: "
		+ (
            "PASS"
			if production_process_system_test_passed
			else "FAIL"
		)
	)


	var production_process_catalog_test_passed = (
		ProductionProcessCatalogTest.run()
	)

	TestLogger.write_line(
        "Production Process Catalog test: "
		+ (
            "PASS"
			if production_process_catalog_test_passed
			else "FAIL"
		)
	)


	var production_process_catalog_schema_test_passed = (
		ProductionProcessCatalogSchemaTest.run()
	)

	TestLogger.write_line(
        "Production Process Catalog Schema test: "
		+ (
            "PASS"
			if production_process_catalog_schema_test_passed
			else "FAIL"
		)
	)


	var production_process_catalog_semantic_test_passed = (
		ProductionProcessCatalogSemanticTest.run()
	)

	TestLogger.write_line(
        "Production Process Catalog Semantic test: "
		+ (
            "PASS"
			if production_process_catalog_semantic_test_passed
			else "FAIL"
		)
	)


	var production_process_catalog_efficiency_test_passed = (
		ProductionProcessCatalogEfficiencyTest.run()
	)

	TestLogger.write_line(
        "Production Process Catalog Efficiency test: "
		+ (
            "PASS"
			if production_process_catalog_efficiency_test_passed
			else "FAIL"
		)
	)


	var production_process_chain_catalog_test: bool = (
		ProductionProcessChainCatalogTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Production Process Chain Catalog test: "
		+ (
            "PASS"
			if production_process_chain_catalog_test
			else "FAIL"
		)
	)


	var production_process_chain_execution_test: bool = (
		ProductionProcessChainExecutionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Production Process Chain Execution test: "
		+ (
            "PASS"
			if production_process_chain_execution_test
			else "FAIL"
		)
	)


	var production_process_extraction_boundary_test: bool = (
		ProductionProcessExtractionBoundaryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Production Process Extraction Boundary test: "
		+ (
            "PASS"
			if production_process_extraction_boundary_test
			else "FAIL"
		)
	)

	var production_process_requirement_evaluator_test: bool = (
		ProductionProcessRequirementEvaluatorTest.run()
	)

	TestLogger.write_line(
        "Production Process Requirement Evaluator test: "
		+ (
            "PASS"
			if production_process_requirement_evaluator_test
			else "FAIL"
		)
	)


	var production_process_requirement_integration_test: bool = (
		ProductionProcessRequirementIntegrationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Production Process Requirement Integration test: "
		+ (
            "PASS"
			if production_process_requirement_integration_test
			else "FAIL"
		)
	)


	var production_process_maintenance_integration_test: bool = (
		ProductionProcessMaintenanceIntegrationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Production Process Maintenance Integration test: "
		+ (
            "PASS"
			if production_process_maintenance_integration_test
			else "FAIL"
		)
	)


		# ============================================================
	# TRADE — STEP 4.1
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.1"
	)

	var trade_agreement_test_passed: bool = (
		TradeAgreementTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Agreement 4.1 test: "
		+ (
            "PASS"
			if trade_agreement_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.2
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.2"
	)

	var trade_route_test_passed: bool = (
		TradeRouteTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Route 4.2 test: "
		+ (
            "PASS"
			if trade_route_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.3
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.3"
	)

	var trade_transaction_test_passed: bool = (
		TradeTransactionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Transaction 4.3 test: "
		+ (
            "PASS"
			if trade_transaction_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.4
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.4"
	)

	var trade_quantity_availability_test_passed: bool = (
		TradeQuantityAvailabilityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Quantity / Availability 4.4 test: "
		+ (
            "PASS"
			if trade_quantity_availability_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.5
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.5"
	)

	var trade_transport_port_constraints_test_passed: bool = (
		TradeTransportPortConstraintsTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Transport / Port Constraints 4.5 test: "
		+ (
            "PASS"
			if trade_transport_port_constraints_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.6
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.6"
	)

	var trade_contract_duration_test_passed: bool = (
		TradeContractDurationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Contract Duration 4.6 test: "
		+ (
            "PASS"
			if trade_contract_duration_test_passed
			else "FAIL"
		)
	)



	# ============================================================
	# TRADE — STEP 4.7
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.7"
	)

	var trade_disruption_cancellation_test_passed: bool = (
		TradeDisruptionCancellationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Disruption / Cancellation 4.7 test: "
		+ (
            "PASS"
			if trade_disruption_cancellation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.8
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.8"
	)

	var trade_resource_economic_consequences_test_passed: bool = (
		TradeResourceEconomicConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Resource / Economic Consequences 4.8 test: "
		+ (
            "PASS"
			if trade_resource_economic_consequences_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 4.9
	# ============================================================

	TestLogger.section(
        "[5] TRADE — STEP 4.9"
	)

	var trade_diplomatic_consequences_test_passed: bool = (
		TradeDiplomaticConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Diplomatic Consequences 4.9 test: "
		+ (
            "PASS"
			if trade_diplomatic_consequences_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# ECONOMY
	# ============================================================

	TestLogger.section(
        "[5] ECONOMY"
	)

	var economy_system_test: EconomySystemTest = EconomySystemTest.new()

	var economy_system_test_passed: bool = (
		economy_system_test.run_test(
			world
		)
	)

	TestLogger.write_line(
        "Economy System test: "
		+ (
            "PASS"
			if economy_system_test_passed
			else "FAIL"
		)
	)

	var economy_shortage_pressure_test_passed: bool = (
		EconomyShortagePressureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economy Integration — Shortage -> Economic Pressure test: "
		+ (
            "PASS"
			if economy_shortage_pressure_test_passed
			else "FAIL"
		)
	)

	var economy_investment_productive_capacity_test_passed: bool = (
		EconomyInvestmentProductiveCapacityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economy Integration — Investment -> Productive Capacity test: "
		+ (
            "PASS"
			if economy_investment_productive_capacity_test_passed
			else "FAIL"
		)
	)

	var economy_economic_conditions_government_finances_test_passed: bool = (
		EconomyEconomicConditionsGovernmentFinancesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economy Integration — Economic Conditions -> Government Finances test: "
		+ (
            "PASS"
			if economy_economic_conditions_government_finances_test_passed
			else "FAIL"
		)
	)

	var economy_government_finances_investment_capacity_test_passed: bool = (
		EconomyGovernmentFinancesInvestmentCapacityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economy Integration — Government Finances -> Investment Capacity test: "
		+ (
            "PASS"
			if economy_government_finances_investment_capacity_test_passed
			else "FAIL"
		)
	)

	var economy_multi_month_stability_test_passed: bool = (
		EconomyMultiMonthStabilityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economy Integration — Multi-Month Stability test: "
		+ (
            "PASS"
			if economy_multi_month_stability_test_passed
			else "FAIL"
		)
	)




	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.1
	# ============================================================

	TestLogger.section(
        "[6] MVP CAUSAL CLOSURE — STEP 5.1"
	)

	var resource_stock_flow_accounting_test_passed: bool = (
		ResourceStockFlowAccountingTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Resource Stock / Flow Accounting 5.1 test: "
		+ (
            "PASS"
			if resource_stock_flow_accounting_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.2
	# ============================================================

	TestLogger.section(
        "[7] MVP CAUSAL CLOSURE — STEP 5.2"
	)

	var inventory_stock_buffer_semantics_test_passed: bool = (
		InventoryStockBufferSemanticsTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Inventory / Stock Buffer Semantics 5.2 test: "
		+ (
            "PASS"
			if inventory_stock_buffer_semantics_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.3
	# ============================================================

	TestLogger.section(
        "[8] MVP CAUSAL CLOSURE — STEP 5.3"
	)

	var aggregate_demand_test_passed: bool = (
		AggregateDemandTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Aggregate Demand 5.3 test: "
		+ (
            "PASS"
			if aggregate_demand_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.4
	# ============================================================

	TestLogger.section(
        "[9] MVP CAUSAL CLOSURE — STEP 5.4"
	)

	var aggregate_consumption_test_passed: bool = (
		AggregateConsumptionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Aggregate Consumption 5.4 test: "
		+ (
            "PASS"
			if aggregate_consumption_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.5
	# ============================================================

	TestLogger.section(
        "[10] MVP CAUSAL CLOSURE — STEP 5.5"
	)

	var supply_demand_resolution_test_passed: bool = (
		SupplyDemandResolutionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Supply / Demand Resolution 5.5 test: "
		+ (
            "PASS"
			if supply_demand_resolution_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.6
	# ============================================================

	TestLogger.section(
        "[11] MVP CAUSAL CLOSURE — STEP 5.6"
	)

	var capacity_utilization_test_passed: bool = (
		CapacityUtilizationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Capacity Utilization 5.6 test: "
		+ (
            "PASS"
			if capacity_utilization_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.7
	# ============================================================

	TestLogger.section(
        "[12] MVP CAUSAL CLOSURE — STEP 5.7"
	)

	var basic_price_formation_test_passed: bool = (
		BasicPriceFormationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Basic Price Formation 5.7 test: "
		+ (
            "PASS"
			if basic_price_formation_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.8
	# ============================================================

	TestLogger.section(
        "[13] MVP CAUSAL CLOSURE — STEP 5.8"
	)

	var income_wage_flow_test_passed: bool = (
		IncomeWageFlowTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Income / Wage Flow 5.8 test: "
		+ (
            "PASS"
			if income_wage_flow_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.9
	# ============================================================

	TestLogger.section(
        "[14] MVP CAUSAL CLOSURE — STEP 5.9"
	)

	var purchasing_power_test_passed: bool = (
		PurchasingPowerTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Purchasing Power 5.9 test: "
		+ (
            "PASS"
			if purchasing_power_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.10
	# ============================================================

	TestLogger.section(
        "[15] MVP CAUSAL CLOSURE — STEP 5.10"
	)

	var resource_allocation_test_passed: bool = (
		ResourceAllocationDistributionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Resource Allocation / Domestic Distribution 5.10 test: "
		+ (
            "PASS"
			if resource_allocation_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# MVP CAUSAL CLOSURE — STEP 5.11
	# ============================================================

	TestLogger.section(
        "[16] MVP CAUSAL CLOSURE — STEP 5.11"
	)

	var trade_payment_test_passed: bool = (
		TradePaymentTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Payment / Transaction Cost 5.11 test: "
		+ (
            "PASS"
			if trade_payment_test_passed
			else "FAIL"
		)
	)

	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.1
	# ============================================================

	TestLogger.section(
        "[17] FINANCIAL SYSTEM — STEP 6.1"
	)

	var currency_identity_test_passed: bool = (
		CurrencyIdentityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Currency Identity 6.1 test: "
		+ (
            "PASS"
			if currency_identity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.2
	# ============================================================

	TestLogger.section(
        "[18] FINANCIAL SYSTEM — STEP 6.2"
	)

	var trade_valuation_test_passed: bool = (
		TradeValuationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Valuation 6.2 test: "
		+ (
            "PASS"
			if trade_valuation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.3
	# ============================================================

	TestLogger.section(
        "[19] FINANCIAL SYSTEM — STEP 6.3"
	)

	var payment_settlement_test_passed: bool = (
		PaymentSettlementTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Payment Settlement 6.3 test: "
		+ (
            "PASS"
			if payment_settlement_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.4
	# ============================================================

	TestLogger.section(
        "[20] FINANCIAL SYSTEM — STEP 6.4"
	)

	var payment_affordability_test_passed: bool = (
		PaymentAffordabilityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Payment Affordability 6.4 test: "
		+ (
            "PASS"
			if payment_affordability_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.5
	# ============================================================

	TestLogger.section(
        "[21] FINANCIAL SYSTEM — STEP 6.5"
	)

	var currency_conversion_test_passed: bool = (
		CurrencyConversionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Currency Conversion / FX 6.5 test: "
		+ (
            "PASS"
			if currency_conversion_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.6
	# ============================================================

	TestLogger.section(
        "[22] FINANCIAL SYSTEM — STEP 6.6"
	)

	var monetary_invariant_test_passed: bool = (
		MonetaryInvariantTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Monetary Invariants 6.6 test: "
		+ (
            "PASS"
			if monetary_invariant_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# FINANCIAL SYSTEM — STEP 6.7
	# ============================================================

	TestLogger.section(
        "[23] FINANCIAL SYSTEM — STEP 6.7"
	)

	var trade_integration_test_passed: bool = (
		TradeIntegrationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Trade Integration 6.7 test: "
		+ (
            "PASS"
			if trade_integration_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# ECONOMIC ALLOCATION — STEP 7.1
	# ============================================================

	TestLogger.section(
        "[24] ECONOMIC ALLOCATION — STEP 7.1"
	)

	var scarce_resource_allocation_test_passed: bool = (
		ScarceResourceAllocationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Scarce Resource Allocation 7.1 test: "
		+ (
            "PASS"
			if scarce_resource_allocation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# ECONOMIC ALLOCATION — STEP 7.2
	# ============================================================

	TestLogger.section(
        "[25] ECONOMIC ALLOCATION — STEP 7.2"
	)

	var priority_class_allocation_test_passed: bool = (
		PriorityClassAllocationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Basic Priority Classes 7.2 test: "
		+ (
            "PASS"
			if priority_class_allocation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# ECONOMIC ALLOCATION — STEP 7.3
	# ============================================================

	TestLogger.section(
        "[26] ECONOMIC ALLOCATION — STEP 7.3"
	)

	var domestic_accessibility_test_passed: bool = (
		DomesticAccessibilityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Domestic Accessibility 7.3 test: "
		+ (
            "PASS"
			if domestic_accessibility_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# ECONOMIC ALLOCATION — STEP 7.4
	# ============================================================

	TestLogger.section(
        "[27] ECONOMIC ALLOCATION — STEP 7.4"
	)

	var allocation_consequences_test_passed: bool = (
		AllocationConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Allocation Consequences 7.4 test: "
		+ (
            "PASS"
			if allocation_consequences_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.1
	# ============================================================

	TestLogger.section(
        "[28] GOVERNMENT — STEP 8.1"
	)

	var government_policy_definition_test_passed: bool = (
		GovernmentPolicyDefinitionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Policy Definition 8.1 test: "
		+ (
            "PASS"
			if government_policy_definition_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.2
	# ============================================================

	TestLogger.section(
        "[29] GOVERNMENT — STEP 8.2"
	)

	var government_policy_activation_test_passed: bool = (
		GovernmentPolicyActivationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Policy Activation / Change 8.2 test: "
		+ (
            "PASS"
			if government_policy_activation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.3
	# ============================================================

	TestLogger.section(
        "[30] GOVERNMENT — STEP 8.3"
	)

	var government_policy_cost_test_passed: bool = (
		GovernmentPolicyCostTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Policy Cost 8.3 test: "
		+ (
            "PASS"
			if government_policy_cost_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.4
	# ============================================================

	TestLogger.section(
        "[31] GOVERNMENT — STEP 8.4"
	)

	var government_policy_effect_test_passed: bool = (
		GovernmentPolicyEffectTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Policy Effects 8.4 test: "
		+ (
            "PASS"
			if government_policy_effect_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.5
	# ============================================================

	TestLogger.section(
        "[32] GOVERNMENT — STEP 8.5"
	)

	var tax_incidence_test_passed: bool = (
		TaxIncidenceTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Tax Incidence 8.5 test: "
		+ (
            "PASS"
			if tax_incidence_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.6
	# ============================================================

	TestLogger.section(
        "[33] GOVERNMENT — STEP 8.6"
	)

	var government_spending_allocation_test_passed: bool = (
		GovernmentSpendingAllocationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Spending Allocation 8.6 test: "
		+ (
            "PASS"
			if government_spending_allocation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.7
	# ============================================================

	TestLogger.section(
        "[34] GOVERNMENT — STEP 8.7"
	)

	var government_public_service_output_test_passed: bool = (
		GovernmentPublicServiceOutputTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Public-Service Output 8.7 test: "
		+ (
            "PASS"
			if government_public_service_output_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.8
	# ============================================================

	TestLogger.section(
        "[35] GOVERNMENT — STEP 8.8"
	)

	var government_law_amendment_test_passed: bool = (
		GovernmentLawAmendmentTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Basic Law / Amendment 8.8 test: "
		+ (
            "PASS"
			if government_law_amendment_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.9
	# ============================================================

	TestLogger.section(
        "[36] GOVERNMENT — STEP 8.9"
	)

	var government_implementation_capacity_test_passed: bool = (
		GovernmentImplementationCapacityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Implementation Capacity 8.9 test: "
		+ (
            "PASS"
			if government_implementation_capacity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# GOVERNMENT — STEP 8.10
	# ============================================================

	TestLogger.section(
        "[37] GOVERNMENT — STEP 8.10"
	)

	var government_transition_test_passed: bool = (
		GovernmentTransitionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Simplified Transition 8.10 test: "
		+ (
            "PASS"
			if government_transition_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.1
	# ============================================================

	TestLogger.section(
        "[38] POPULATION / WELFARE — STEP 9.1"
	)

	var standard_of_living_test_passed: bool = (
		StandardOfLivingTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Standard of Living 9.1 test: "
		+ (
            "PASS"
			if standard_of_living_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.2
	# ============================================================

	TestLogger.section(
        "[39] POPULATION / WELFARE — STEP 9.2"
	)

	var welfare_effect_test_passed: bool = (
		WelfareEffectTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Welfare Effect 9.2 test: "
		+ (
            "PASS"
			if welfare_effect_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.3
	# ============================================================

	TestLogger.section(
        "[40] POPULATION / WELFARE — STEP 9.3"
	)

	var income_consumption_feedback_test_passed: bool = (
		IncomeConsumptionFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Income -> Purchasing Power -> Consumption 9.3 test: "
		+ (
            "PASS"
			if income_consumption_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.4
	# ============================================================

	TestLogger.section(
        "[41] POPULATION / WELFARE — STEP 9.4"
	)

	var economic_pressure_political_feedback_test_passed: bool = (
		EconomicPressurePoliticalFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Economic Pressure -> Political Pressure 9.4 test: "
		+ (
            "PASS"
			if economic_pressure_political_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.5
	# ============================================================

	TestLogger.section(
        "[42] POPULATION / WELFARE — STEP 9.5"
	)

	var basic_population_response_test_passed: bool = (
		BasicPopulationResponseTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Basic Population Response 9.5 test: "
		+ (
            "PASS"
			if basic_population_response_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# POPULATION / WELFARE — STEP 9.6
	# ============================================================

	TestLogger.section(
        "[43] POPULATION / WELFARE — STEP 9.6"
	)

	var government_feedback_test_passed: bool = (
		GovernmentFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Government Feedback 9.6 test: "
		+ (
            "PASS"
			if government_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.1
	# ============================================================

	TestLogger.section(
        "[44] INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.1"
	)

	var core_country_registry_test_passed: bool = (
		CoreCountryRegistryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
        "Core Country Registry 10.1 test: "
		+ (
            "PASS"
			if core_country_registry_test_passed
			else "FAIL"
		)
	)
	
	
	# ============================================================
	# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.2
	# ============================================================

	TestLogger.section(
    "[45] INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.2"
)

	var external_world_actor_test_passed: bool = (
	ExternalWorldActorTest.run(
		world,
		simulation
	)
)

	TestLogger.write_line(
    "External World Actor 10.2 test: "
	+ (
        "PASS"
		if external_world_actor_test_passed
		else "FAIL"
	)
)


	# ============================================================
	# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.3
	# ============================================================

	TestLogger.section(
    "[46] INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.3"
)

	var external_event_causality_test_passed: bool = (
	ExternalEventCausalityTest.run(
		world,
		simulation
	)
)

	TestLogger.write_line(
    "External Event Causality 10.3 test: "
	+ (
        "PASS"
		if external_event_causality_test_passed
		else "FAIL"
	)
)



	# ============================================================
	# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.4
	# ============================================================

	TestLogger.section(
    "[47] INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.4"
)

	var external_actor_limited_simulation_test_passed: bool = (
	ExternalActorLimitedSimulationTest.run(
		world,
		simulation
	)
)

	TestLogger.write_line(
    "External Actor Limited Simulation 10.4 test: "
	+ (
        "PASS"
		if external_actor_limited_simulation_test_passed
		else "FAIL"
	)
)


	# ============================================================
	# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.5
	# ============================================================

	TestLogger.section(
    "[48] INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.5"
)

	var external_event_relevance_filter_test_passed: bool = (
	ExternalEventRelevanceFilterTest.run(
		world,
		simulation
	)
)

	TestLogger.write_line(
    "External Event Relevance Filter 10.5 test: "
	+ (
        "PASS"
		if external_event_relevance_filter_test_passed
		else "FAIL"
	)
)


	# ============================================================
	# TRADE — STEP 11.1
	# ============================================================

	TestLogger.section(
		"[49] TRADE — STEP 11.1"
	)

	var trade_embargo_test_passed: bool = (
		TradeEmbargoTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade Embargo 11.1 test: "
		+ (
			"PASS"
			if trade_embargo_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 11.2
	# ============================================================

	TestLogger.section(
		"[50] TRADE — STEP 11.2"
	)

	var trade_route_restriction_test_passed: bool = (
		TradeRouteRestrictionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade Route Restriction 11.2 test: "
		+ (
			"PASS"
			if trade_route_restriction_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 11.3
	# ============================================================

	TestLogger.section(
		"[51] TRADE — STEP 11.3"
	)

	var trade_restriction_interaction_test_passed: bool = (
		TradeRestrictionInteractionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade Restriction Interaction 11.3 test: "
		+ (
			"PASS"
			if trade_restriction_interaction_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# TRADE — STEP 11.4
	# ============================================================

	TestLogger.section(
		"[52] TRADE — STEP 11.4"
	)

	var trade_restriction_recovery_test_passed: bool = (
		TradeRestrictionRecoveryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade Restriction Recovery 11.4 test: "
		+ (
			"PASS"
			if trade_restriction_recovery_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.1
	# ============================================================

	TestLogger.section(
		"[53] REGIONALIZATION — STEP 12.1"
	)

	var regionalization_test_passed: bool = (
		RegionalizationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.1 test: "
		+ (
			"PASS"
			if regionalization_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.2
	# ============================================================

	TestLogger.section(
		"[54] REGIONALIZATION — STEP 12.2"
	)

	var regional_ownership_test_passed: bool = (
		RegionalOwnershipTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.2 test: "
		+ (
			"PASS"
			if regional_ownership_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.3
	# ============================================================

	TestLogger.section(
		"[55] REGIONALIZATION — STEP 12.3"
	)

	var regional_terrain_test_passed: bool = (
		RegionalTerrainTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.3 test: "
		+ (
			"PASS"
			if regional_terrain_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.4
	# ============================================================

	TestLogger.section(
		"[56] REGIONALIZATION — STEP 12.4"
	)

	var regional_population_test_passed: bool = (
		RegionalPopulationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.4 test: "
		+ (
			"PASS"
			if regional_population_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.5
	# ============================================================

	TestLogger.section(
		"[57] REGIONALIZATION — STEP 12.5"
	)

	var regional_resource_test_passed: bool = (
		RegionalResourceTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.5 test: "
		+ (
			"PASS"
			if regional_resource_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.6
	# ============================================================

	TestLogger.section(
		"[58] REGIONALIZATION — STEP 12.6"
	)

	var regional_infrastructure_test_passed: bool = (
		RegionalInfrastructureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.6 test: "
		+ (
			"PASS"
			if regional_infrastructure_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.7
	# ============================================================

	TestLogger.section(
		"[59] REGIONALIZATION — STEP 12.7"
	)

	var regional_industry_test_passed: bool = (
		RegionalIndustryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.7 test: "
		+ (
			"PASS"
			if regional_industry_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.8
	# ============================================================

	TestLogger.section(
		"[60] REGIONALIZATION — STEP 12.8"
	)

	var regional_transport_test_passed: bool = (
		RegionalTransportTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.8 test: "
		+ (
			"PASS"
			if regional_transport_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# REGIONALIZATION — STEP 12.9
	# ============================================================

	TestLogger.section(
		"[61] REGIONALIZATION — STEP 12.9"
	)

	var country_aggregation_test_passed: bool = (
		CountryAggregationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Regionalization 12.9 test: "
		+ (
			"PASS"
			if country_aggregation_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.1
	# ============================================================

	TestLogger.section(
		"[62] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.1"
	)

	var military_production_capacity_test_passed: bool = (
		MilitaryProductionCapacityTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Production Capacity 13.1 test: "
		+ (
			"PASS"
			if military_production_capacity_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# SNAPSHOTS
	#
	# Military snapshot regression tests are temporarily disabled.
	# ============================================================

	# TestLogger.section(
	#     "[5] SNAPSHOTS"
	# )

	# SnapshotDiagnosticTest.run(
	#     world,
	#     simulation
	# )

	# var military_snapshot_test = (
	#     MilitarySnapshotTest.new()
	# )

	# military_snapshot_test.run(
	#     world
	# )

	# var military_divergence_test = (
	#     MilitaryDivergenceTest.new()
	# )

	# military_divergence_test.run(
	#     world,
	#     simulation
	# )

	# var military_country_data_test = (
	#     MilitaryCountryDataTest.new()
	# )

	# military_country_data_test.run(
	#     world
	# )


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.2
	# ============================================================

	TestLogger.section(
		"[63] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.2"
	)

	var military_resource_readiness_test_passed: bool = (
		MilitaryResourceReadinessTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Resource Readiness 13.2 test: "
		+ (
			"PASS"
			if military_resource_readiness_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.3
	# ============================================================

	TestLogger.section(
		"[64] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.3"
	)

	var military_transport_logistics_test_passed: bool = (
		MilitaryTransportLogisticsTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Transport Logistics 13.3 test: "
		+ (
			"PASS"
			if military_transport_logistics_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.4
	# ============================================================

	TestLogger.section(
		"[65] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.4"
	)

	var military_port_naval_logistics_test_passed: bool = (
		MilitaryPortNavalLogisticsTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Port Naval Logistics 13.4 test: "
		+ (
			"PASS"
			if military_port_naval_logistics_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.5
	# ============================================================

	TestLogger.section(
		"[66] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.5"
	)

	var military_power_infrastructure_test_passed: bool = (
		MilitaryPowerInfrastructureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Power Infrastructure 13.5 test: "
		+ (
			"PASS"
			if military_power_infrastructure_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.6
	# ============================================================

	TestLogger.section(
		"[67] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.6"
	)

	var military_resource_demand_test_passed: bool = (
		MilitaryResourceDemandTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Resource Demand 13.6 test: "
		+ (
			"PASS"
			if military_resource_demand_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.7
	# ============================================================

	TestLogger.section(
		"[68] MILITARY ↔ ECONOMY / INFRASTRUCTURE — STEP 13.7"
	)

	var military_economic_pressure_test_passed: bool = (
		MilitaryEconomicPressureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military Economic Pressure 13.7 test: "
		+ (
			"PASS"
			if military_economic_pressure_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.1
	# ============================================================

	TestLogger.section(
		"[69] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.1"
	)

	var infrastructure_damage_test_passed: bool = (
		InfrastructureDamageTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Damage 14.1 test: "
		+ (
			"PASS"
			if infrastructure_damage_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.2
	# ============================================================

	TestLogger.section(
		"[70] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.2"
	)

	var infrastructure_capacity_loss_test_passed: bool = (
		InfrastructureCapacityLossTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Capacity Loss 14.2 test: "
		+ (
			"PASS"
			if infrastructure_capacity_loss_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.3
	# ============================================================

	TestLogger.section(
		"[71] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.3"
	)

	var infrastructure_physical_consequences_test_passed: bool = (
		InfrastructurePhysicalConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Physical Consequences 14.3 test: "
		+ (
			"PASS"
			if infrastructure_physical_consequences_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.4
	# ============================================================

	TestLogger.section(
		"[72] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.4"
	)

	var infrastructure_economic_consequences_test_passed: bool = (
		InfrastructureEconomicConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Economic Consequences 14.4 test: "
		+ (
			"PASS"
			if infrastructure_economic_consequences_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.5
	# ============================================================

	TestLogger.section(
		"[73] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.5"
	)

	var infrastructure_reconstruction_investment_test_passed: bool = (
		InfrastructureReconstructionInvestmentTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Reconstruction Investment 14.5 test: "
		+ (
			"PASS"
			if infrastructure_reconstruction_investment_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.6
	# ============================================================

	TestLogger.section(
		"[74] INFRASTRUCTURE DAMAGE / RECONSTRUCTION — STEP 14.6"
	)

	var infrastructure_recovery_test_passed: bool = (
		InfrastructureRecoveryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Infrastructure Recovery 14.6 test: "
		+ (
			"PASS"
			if infrastructure_recovery_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.1 — PLAYER FEEDBACK
	# ============================================================

	TestLogger.section(
		"[2.5.1] PLAYER FEEDBACK — STEP 17.1"
	)

	var player_feedback_test_passed: bool = (
		PlayerFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.1 Player Feedback test: "
		+ (
			"PASS"
			if player_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.2 — AI FEEDBACK
	# ============================================================

	TestLogger.section(
		"[2.5.2] AI FEEDBACK — STEP 17.2"
	)

	var ai_feedback_step17_2_test_passed: bool = (
		AIFeedbackStep17_2Test.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.2 AI Feedback test: "
		+ (
			"PASS"
			if ai_feedback_step17_2_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.3 — CROSS-DOMAIN FEEDBACK
	# ============================================================

	TestLogger.section(
		"[2.5.3] CROSS-DOMAIN FEEDBACK — STEP 17.3"
	)

	var step17_3_cross_domain_feedback_test_passed: bool = (
		Step17_3CrossDomainFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.3 Cross-Domain Feedback test: "
		+ (
			"PASS"
			if step17_3_cross_domain_feedback_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.4 — MULTI-MONTH CLOSURE
	# ============================================================

	TestLogger.section(
		"[2.5.4] MULTI-MONTH CLOSURE — STEP 17.4"
	)

	var step17_4_multi_month_closure_test_passed: bool = (
		Step17_4MultiMonthClosureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.4 Multi-Month Closure test: "
		+ (
			"PASS"
			if step17_4_multi_month_closure_test_passed
			else "FAIL"
		)
	)




	# ============================================================
	# STEP 17.5 — EVENT-DRIVEN FEEDBACK
	# ============================================================

	TestLogger.section(
		"[2.5.5] EVENT-DRIVEN FEEDBACK — STEP 17.5"
	)

	var step17_5_event_driven_feedback_test_passed: bool = (
		Step17_5EventDrivenFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.5 Event-Driven Feedback test: "
		+ (
			"PASS"
			if step17_5_event_driven_feedback_test_passed
			else "FAIL"
		)
	)



	# ============================================================
	# STEP 17.6 — FULL INTEGRATED FEEDBACK CLOSURE
	# ============================================================

	TestLogger.section(
		"[2.5.6] FULL INTEGRATED FEEDBACK CLOSURE — STEP 17.6"
	)

	var step17_6_full_integrated_feedback_closure_test_passed: bool = (
		Step17_6FullIntegratedFeedbackClosureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.6 Full Integrated Feedback Closure test: "
		+ (
			"PASS"
			if step17_6_full_integrated_feedback_closure_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.7 — SNAPSHOT / PERSISTENCE BOUNDARY
	# ============================================================

	TestLogger.section(
		"[2.5.7] SNAPSHOT / PERSISTENCE BOUNDARY — STEP 17.7"
	)

	var step17_7_snapshot_persistence_boundary_test_passed: bool = (
		Step17_7SnapshotPersistenceBoundaryTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.7 Snapshot / Persistence Boundary test: "
		+ (
			"PASS"
			if step17_7_snapshot_persistence_boundary_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 17.8 — FULL DYNAMIC FEEDBACK ACCEPTANCE
	# ============================================================

	TestLogger.section(
		"[2.5.8] FULL DYNAMIC FEEDBACK ACCEPTANCE — STEP 17.8"
	)

	var step17_8_full_dynamic_feedback_acceptance_test_passed: bool = (
		Step17_8Step17AcceptanceTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 17.8 Full Dynamic Feedback Acceptance test: "
		+ (
			"PASS"
			if step17_8_full_dynamic_feedback_acceptance_test_passed
			else "FAIL"
		)
	)


	# ============================================================
	# WORLD VALIDATION
	# ============================================================

	TestLogger.section(
        "[5] WORLD VALIDATION"
	)

	WorldStateValidationTest.run(
		world
	)


	# ============================================================
	# STEP 18.1 — CAMPAIGN HARNESS
	# ============================================================
	#
	# This is optional in the default regression run because the campaign
	# harness intentionally advances the supplied WorldState. The active
	# Step 15–17 suite remains unchanged unless the caller explicitly
	# enables Step 18.1.
	#
	# Recommended usage for a dedicated campaign-context run:
	#
	#     RunAllTests.run(world, simulation, true, 1)
	#
	# Use a larger month count only with a deliberately fresh campaign
	# context.
	# ============================================================

	if run_step_18_1:

		TestLogger.section(
			"[6] CAMPAIGN HARNESS — STEP 18.1"
		)

		var step18_1_passed: bool = (
			Step18_1CampaignHarnessTest.run(
				world,
				simulation,
				step_18_1_months
			)
		)

		TestLogger.write_line(
			"Step 18.1 Campaign Harness test: "
			+ (
				"PASS"
				if step18_1_passed
				else "FAIL"
			)
		)



	# ============================================================
	# STEP 18.2 — 60-MONTH CAMPAIGN
	# ============================================================
	#
	# Step 18.2 runs inside the normal active test suite, but against
	# a dedicated fresh campaign context supplied by main.gd.
	#
	# This avoids:
	#   - command-line-only execution
	#   - running the campaign after Step 15–17 has mutated the world
	#   - introducing a second simulation engine for the same world
	#
	# The authoritative monthly execution remains
	# SimulationEngine.tick_month().
	# ============================================================

	TestLogger.section(
		"[7] 60-MONTH CAMPAIGN — STEP 18.2"
	)

	var step18_2_passed: bool = false
	var step18_2_report: Dictionary = {}

	if campaign_world == null:
		TestLogger.write_line(
			"Step 18.2 campaign world: FAIL"
		)
	elif campaign_simulation == null:
		TestLogger.write_line(
			"Step 18.2 campaign simulation: FAIL"
		)
	else:
		# Step 18.3 observes the SAME 60-month execution performed by
		# Step 18.2. No second campaign loop is introduced.
		step18_2_report = (
			Step18_2Campaign60MonthValidationTest.run_with_report(
				campaign_world,
				campaign_simulation,
				campaign_months,
				true
			)
		)
		step18_2_passed = bool(
			step18_2_report.get(
				"passed",
				false
			)
		)

	TestLogger.write_line(
		"Step 18.2 Dedicated 60-Month Campaign test: "
		+ (
			"PASS"
			if step18_2_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 18.3 — CAMPAIGN INVARIANT / TELEMETRY COLLECTION
	# ============================================================
	#
	# This validates the telemetry collected during the exact same
	# Step 18.2 monthly execution. It does not advance the campaign again.
	# ============================================================

	TestLogger.section(
		"[8] CAMPAIGN INVARIANT / TELEMETRY — STEP 18.3"
	)

	var step18_3_passed: bool = false

	if step18_2_report.is_empty():
		TestLogger.write_line(
			"Step 18.3 campaign report available: FAIL"
		)
	else:
		var step18_3_campaign_result: Dictionary = step18_2_report.get(
			"campaign_result",
			{}
		)
		step18_3_passed = (
			Step18_3CampaignInvariantTelemetryTest.validate_campaign_result(
				step18_3_campaign_result,
				campaign_months
			)
		)

	TestLogger.write_line(
		"Step 18.3 Campaign Invariant / Telemetry test: "
		+ (
			"PASS"
			if step18_3_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 18.4 — FAILURE LOCALIZATION / REGRESSION ANALYSIS
	# ============================================================
	#
	# Consumes the SAME campaign_result already produced by Step 18.2.
	# No second campaign execution is permitted here.
	# ============================================================

	TestLogger.section(
		"[9] CAMPAIGN FAILURE LOCALIZATION / REGRESSION — STEP 18.4"
	)

	var step18_4_passed: bool = false
	var step18_4_report_for_18_5: Dictionary = {}

	if step18_2_report.is_empty():
		TestLogger.write_line(
			"Step 18.4 campaign report available: FAIL"
		)
	else:
		var step18_4_campaign_result: Dictionary = step18_2_report.get(
			"campaign_result",
			{}
		)

		var step18_4_report: Dictionary = (
			Step18_4CampaignFailureLocalizationTest.run(
				step18_4_campaign_result,
				campaign_months
			)
		)
		step18_4_report_for_18_5 = step18_4_report

		step18_4_passed = bool(
			step18_4_report.get(
				"passed",
				false
			)
		)

		var step18_4_analysis: Dictionary = step18_4_report.get(
			"analysis",
			{}
		)

		TestLogger.write_line(
			"18.4 status: "
			+ str(step18_4_analysis.get("status", ""))
		)

		TestLogger.write_line(
			"18.4 first failure month: "
			+ str(step18_4_analysis.get("first_failure_month", -1))
		)

		TestLogger.write_line(
			"18.4 failure stage: "
			+ str(step18_4_analysis.get("failure_stage", ""))
		)

		TestLogger.write_line(
			"18.4 failure invariant: "
			+ str(step18_4_analysis.get("failure_invariant", ""))
		)

		TestLogger.write_line(
			"18.4 failure path: "
			+ str(step18_4_analysis.get("failure_path", ""))
		)

		TestLogger.write_line(
			"18.4 failure reason: "
			+ str(step18_4_analysis.get("failure_reason", ""))
		)

	TestLogger.write_line(
		"Step 18.4 Failure Localization / Regression test: "
		+ (
			"PASS"
			if step18_4_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 18.5 — CAMPAIGN EVIDENCE / ACCEPTANCE
	# ============================================================
	#
	# Consumes the SAME campaign_result already produced by Step 18.2
	# and the SAME Step 18.4 acceptance report. No second campaign
	# execution, observer pass, or simulation engine is introduced.
	# ============================================================

	TestLogger.section(
		"[10] CAMPAIGN EVIDENCE / ACCEPTANCE — STEP 18.5"
	)

	var step18_5_passed: bool = false

	if step18_2_report.is_empty():
		TestLogger.write_line(
			"Step 18.5 campaign report available: FAIL"
		)
	else:
		var step18_5_campaign_result: Dictionary = step18_2_report.get(
			"campaign_result",
			{}
		)

		var step18_5_4_report: Dictionary = step18_4_report_for_18_5

		var step18_5_report: Dictionary = (
			Step18_5CampaignEvidenceAcceptanceTest.run(
				step18_5_campaign_result,
				step18_5_4_report,
				campaign_months
			)
		)

		step18_5_passed = bool(
			step18_5_report.get(
				"passed",
				false
			)
		)

	TestLogger.write_line(
		"Step 18.5 Campaign Evidence / Acceptance test: "
		+ (
			"PASS"
			if step18_5_passed
			else "FAIL"
		)
	)

	# ============================================================
	# STEP 19.1 — COAL SHORTAGE CAUSAL VALIDATION
	# ============================================================
	#
	# Deliberate cause-and-effect experiment:
	# coal shortage -> steel constraint -> machinery constraint
	# -> physical output pressure -> economic pressure -> recovery.
	#
	# The test consumes the same registered ResourceSystem,
	# ProductionProcessSystem, and EconomySystem already owned by the
	# active SimulationEngine. No second simulation engine is created.
	# ============================================================

	TestLogger.section(
		"[11] CAUSAL SCENARIO VALIDATION — STEP 19.1"
	)

	var step19_1_passed: bool = (
		Step19_1CoalShortageCausalValidationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 19.1 Coal Shortage Causal Validation test: "
		+ (
			"PASS"
			if step19_1_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.2 — RAILWAY INVESTMENT CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# railway capacity -> resource accessibility
	# -> steel/machinery production -> physical output -> GDP.
	#
	# Step 19.2 reuses the authoritative infrastructure, resource,
	# production, and economy systems already registered on the active
	# SimulationEngine. It does not introduce a second investment or
	# simulation authority.
	# ============================================================

	TestLogger.section(
		"[12] CAUSAL SCENARIO VALIDATION — STEP 19.2"
	)

	var step19_2_passed: bool = (
		Step19_2RailwayInvestmentCausalValidationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 19.2 Railway Investment Causal Validation test: "
		+ (
			"PASS"
			if step19_2_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.3 — POWER SHORTAGE CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# power shortage -> lower electricity availability ->
	# energy-intensive production decline -> lower physical output ->
	# lower GDP + higher economic pressure.
	#
	# Step 19.3 reuses the registered ResourceSystem,
	# ProductionProcessSystem, and EconomySystem. No second simulation
	# engine or duplicate production/economic authority is introduced.
	# ============================================================

	TestLogger.section(
		"[13] CAUSAL SCENARIO VALIDATION — STEP 19.3"
	)

	var step19_3_passed: bool = (
		Step19_3PowerShortageCausalValidationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 19.3 Power Shortage Causal Validation test: "
		+ (
			"PASS"
			if step19_3_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.4 — TECHNOLOGY TRANSITION CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# technology transition -> process adoption -> resource-mix change
	# -> new infrastructure requirement -> production consequence
	# -> physical/economic consequence -> infrastructure recovery.
	#
	# Step 19.4 reuses the registered ResourceSystem,
	# ProductionProcessSystem, and EconomySystem. No second simulation
	# engine or duplicate production/economic authority is introduced.
	# ============================================================

	TestLogger.section(
		"[14] CAUSAL SCENARIO VALIDATION — STEP 19.4"
	)

	var step19_4_passed: bool = (
		Step19_4TechnologyTransitionCausalValidationTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Step 19.4 Technology Transition Causal Validation test: "
		+ (
			"PASS"
			if step19_4_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.5 — WAR / MILITARY BURDEN CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# war / military demand
	# -> military resource demand / resource consumption
	# -> strategic logistics burden
	# -> conflict-derived infrastructure disruption
	# -> production pressure
	# -> economic pressure.
	#
	# Step 19.5 must reuse the authoritative MilitarySystem,
	# MilitaryResourceDemandSystem, existing resource aggregation,
	# MilitaryTransportLogisticsSystem, InfrastructureDamageSystem,
	# ProductionProcessSystem, EconomySystem, and the existing
	# military-economic-pressure bridge.
	#
	# No second military engine, war engine, resource settlement engine,
	# production engine, or economy engine is introduced.
	# ============================================================

	TestLogger.section(
		"[15] CAUSAL SCENARIO VALIDATION — STEP 19.5"
	)

	var step19_5_passed: bool = false
	var step19_5_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_5WarMilitaryBurdenCausalValidationTest.gd"
	)

	if ResourceLoader.exists(step19_5_script_path):
		var step19_5_script = load(step19_5_script_path)
		if step19_5_script != null and step19_5_script.has_method("run"):
			step19_5_passed = bool(
				step19_5_script.run(
					world,
					simulation
				)
			)
		else:
			TestLogger.write_line(
				"Step 19.5 test script loaded but does not expose static run(world, simulation): FAIL"
			)
	else:
		TestLogger.write_line(
			"Step 19.5 test source not yet present: FAIL | expected="
			+ step19_5_script_path
		)

	TestLogger.write_line(
		"Step 19.5 War / Military Burden Causal Validation test: "
		+ (
			"PASS"
			if step19_5_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.6 — TRADE DISRUPTION CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# route restriction
	# -> actual imported quantity
	# -> resource availability / shortage
	# -> realized production
	# -> GDP
	# -> explicit recovery.
	#
	# The test is loaded dynamically so the active suite has no duplicate
	# class definition or compile-time dependency on an alternate copy.
	# ============================================================

	TestLogger.section(
		"[16] CAUSAL SCENARIO VALIDATION — STEP 19.6"
	)

	var step19_6_passed: bool = false
	var step19_6_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_6TradeDisruptionCausalValidationTest.gd"
	)

	if ResourceLoader.exists(step19_6_script_path):
		var step19_6_script = load(step19_6_script_path)
		if step19_6_script != null and step19_6_script.has_method("run"):
			step19_6_passed = bool(
				step19_6_script.run(
					world,
					simulation
				)
			)
		else:
			TestLogger.write_line(
				"Step 19.6 test script loaded but does not expose static run(world, simulation): FAIL"
			)
	else:
		TestLogger.write_line(
			"Step 19.6 test source not yet present: FAIL | expected="
			+ step19_6_script_path
		)

	TestLogger.write_line(
		"Step 19.6 Trade Disruption Causal Validation test: "
		+ (
			"PASS"
			if step19_6_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.7 — RECOVERY CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled causal experiment:
	# infrastructure damage -> recovery funding -> reconstruction
	# progress -> authoritative damage reduction -> next-cycle
	# infrastructure refresh -> physical/economic recovery.
	#
	# The test is loaded dynamically so the active suite has no duplicate
	# class definition or compile-time dependency on an alternate copy.
	# ============================================================

	TestLogger.section(
		"[17] CAUSAL SCENARIO VALIDATION — STEP 19.7"
	)

	var step19_7_passed: bool = false
	var step19_7_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_7RecoveryCausalValidationTest.gd"
	)

	if ResourceLoader.exists(step19_7_script_path):
		var step19_7_script = load(step19_7_script_path)
		if step19_7_script != null and step19_7_script.has_method("run"):
			step19_7_passed = bool(
				step19_7_script.run(
					world,
					simulation
				)
			)
		else:
			TestLogger.write_line(
				"Step 19.7 test script loaded but does not expose static run(world, simulation): FAIL"
			)
	else:
		TestLogger.write_line(
			"Step 19.7 test source not yet present: FAIL | expected="
			+ step19_7_script_path
		)

	TestLogger.write_line(
		"Step 19.7 Recovery Causal Validation test: "
		+ (
			"PASS"
			if step19_7_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.8 — DIVERGENCE CAUSAL VALIDATION
	# ============================================================
	#
	# Controlled branch experiment:
	# identical live baseline -> two DecisionOption branches ->
	# same executable diplomatic action contract -> different
	# authoritative relationship trajectories -> persistent divergence.
	# ============================================================

	TestLogger.section(
		"[18] CAUSAL SCENARIO VALIDATION — STEP 19.8"
	)

	var step19_8_passed: bool = false
	var step19_8_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_8DivergenceCausalValidationTest.gd"
	)

	if ResourceLoader.exists(step19_8_script_path):
		var step19_8_script = load(step19_8_script_path)
		if step19_8_script != null and step19_8_script.has_method("run"):
			step19_8_passed = bool(
				step19_8_script.run(
					world,
					simulation
				)
			)
		else:
			TestLogger.write_line(
				"Step 19.8 test script loaded but does not expose static run(world, simulation): FAIL"
			)
	else:
		TestLogger.write_line(
			"Step 19.8 test source not yet present: FAIL | expected="
			+ step19_8_script_path
		)

	TestLogger.write_line(
		"Step 19.8 Divergence Causal Validation test: "
		+ (
			"PASS"
			if step19_8_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.9 — EVENT-DRIVEN SCENARIO VALIDATION
	# ============================================================
	#
	# Controlled event-driven scenario:
	# authoritative military trigger
	# -> real EVENTS phase
	# -> E13 event execution/effect
	# -> authoritative government state
	# -> next-month GovernmentSystem consumption
	# -> one-time repeatability / isolation.
	#
	# The test is loaded dynamically so the active suite does not create
	# a duplicate event-test class or dependency path.
	# ============================================================

	TestLogger.section(
		"[19] CAUSAL SCENARIO VALIDATION — STEP 19.9"
	)

	var step19_9_passed: bool = false
	var step19_9_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_9EventDrivenScenarioValidationTest.gd"
	)

	if ResourceLoader.exists(step19_9_script_path):
		var step19_9_script = load(step19_9_script_path)
		if step19_9_script != null and step19_9_script.has_method("run"):
			step19_9_passed = bool(
				step19_9_script.run(
					world,
					simulation
				)
			)
		else:
			TestLogger.write_line(
				"Step 19.9 test script loaded but does not expose static run(world, simulation): FAIL"
			)
	else:
		TestLogger.write_line(
			"Step 19.9 test source not yet present: FAIL | expected="
			+ step19_9_script_path
		)

	TestLogger.write_line(
		"Step 19.9 Event-Driven Scenario Validation test: "
		+ (
			"PASS"
			if step19_9_passed
			else "FAIL"
		)
	)


	# ============================================================
	# STEP 19.A — CAUSAL ARCHITECTURE COVERAGE AUDIT
	# ============================================================
	#
	# This is intentionally placed after Step 19.9 because the Step 19
	# causal scenarios are now complete. The audit itself is structural:
	# it consumes the already-active SimulationEngine registration graph
	# and does not advance or mutate the world.
	#
	# The source is loaded dynamically so the active suite depends on exactly
	# one installed audit file at:
	#   res://scripts/tests/Step19_CausalArchitectureCoverageAuditTest.gd
	# ============================================================

	TestLogger.section(
		"[19.A] CAUSAL ARCHITECTURE COVERAGE AUDIT"
	)

	var step19_a_passed: bool = false
	var step19_a_script_path: String = (
		"res://scripts/tests/"
		+ "Step19_CausalArchitectureCoverageAuditTest.gd"
	)

	if ResourceLoader.exists(step19_a_script_path):

		var step19_a_script = load(
			step19_a_script_path
		)

		if (
			step19_a_script != null
			and step19_a_script.has_method("run")
		):

			step19_a_passed = bool(
				step19_a_script.run(
					world,
					simulation
				)
			)

		else:

			TestLogger.write_line(
				"Step 19.A audit script loaded but does not expose "
				+ "static run(world, simulation): FAIL"
			)

	else:

		TestLogger.write_line(
			"Step 19.A audit source not yet present: FAIL | expected="
			+ step19_a_script_path
		)

	TestLogger.write_line(
		"Step 19.A Causal Architecture Coverage Audit test: "
		+ (
			"PASS"
			if step19_a_passed
			else "FAIL"
		)
	)


	# ============================================================
	# COMPLETE
	# ============================================================

	TestLogger.section(
        "ACTIVE TEST SUITE COMPLETE"
	)

	TestLogger.finish()
