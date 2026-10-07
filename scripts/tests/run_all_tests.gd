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
) -> TestSuiteResult:
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

		return null

	if simulation == null:

		TestLogger.write_line(
            "TEST SUITE FAILED: simulation is null."
		)

		TestLogger.finish()

		return null


	var suite_result := TestSuiteResult.new()

	if TestLogger.current != null:
		suite_result.run_id = TestLogger.current.get_run_id()

	suite_result.set_metadata(
		"validation_scope",
		"full_suite"
	)

	suite_result.set_metadata(
		"migration_complete",
		true
	)

	suite_result.set_metadata(
		"migrated_runners",
		[
			"data",
			"interaction",
			"physical_economy",
			"domain",
			"feedback",
			"campaign",
			"causal"
		]
	)

	suite_result.set_metadata(
		"migrated_runner_count",
		7
	)

	suite_result.set_metadata(
		"pending_runners",
		[]
	)

	suite_result.set_metadata(
		"diagnostic_authority",
		"structured_result_for_all_migrated_runners; legacy_domain_checks remain explicitly tracked"
	)
	suite_result.set_metadata(
		"legacy_domain_checks",
		[
			"IndustryProcessInfrastructurePressureTest"
		]
	)


	# ============================================================
	# DATA RUNNER — PHASE 3
	# ============================================================

	var data_test_result: TestRunResult = (
		DataTestRunner.run()
	)

	if data_test_result != null:
		suite_result.add_runner_result(
			data_test_result
		)
		TestLogger.write_line(
			"Data Test Runner: "
			+ data_test_result.status
		)
	else:
		TestLogger.write_line(
			"Data Test Runner: ERROR | result was null."
		)


	# ============================================================
	# INTERACTION RUNNER — STEP 8
	# ============================================================
	#
	# Action / concurrent-action validation is now owned by
	# InteractionTestRunner.
	#
	# It runs inside a child logger scope and restores the master logger
	# after completion. TestLogger forwards the child transcript into the
	# active legacy report without duplicating the structured result.
	# ============================================================

	var interaction_test_result: TestRunResult = (
		InteractionTestRunner.run(
			world,
			simulation
		)
	)

	if interaction_test_result != null:

		suite_result.add_runner_result(
			interaction_test_result
		)

		TestLogger.write_line(
			"Interaction Test Runner: "
			+ interaction_test_result.status
		)

		TestLogger.write_line(
			"Interaction tests run: "
			+ str(
				interaction_test_result.tests_run
			)
		)

		TestLogger.write_line(
			"Interaction tests failed: "
			+ str(
				interaction_test_result.tests_failed
			)
		)

		TestLogger.write_line(
			"Interaction test errors: "
			+ str(
				interaction_test_result.tests_errored
			)
		)

		if not interaction_test_result.passed():

			var primary_interaction_diagnostic := (
				interaction_test_result.primary_diagnostic()
			)

			if primary_interaction_diagnostic != null:

				TestLogger.write_line(
					"Interaction primary diagnostic: "
					+ primary_interaction_diagnostic.format_for_human()
				)

	else:

		TestLogger.write_line(
			"Interaction Test Runner: ERROR | result was null."
		)


	# ============================================================
	# PHYSICAL ECONOMY RUNNER — STEP 9
	# ============================================================

	var physical_economy_test_result: TestRunResult = (
		PhysicalEconomyTestRunner.run(
			world,
			simulation
		)
	)

	if physical_economy_test_result != null:
		suite_result.add_runner_result(
			physical_economy_test_result
		)
		TestLogger.write_line(
			"Physical Economy Test Runner: "
			+ physical_economy_test_result.status
		)
	else:
		TestLogger.write_line(
			"Physical Economy Test Runner: ERROR | result was null."
		)


	# ============================================================
	# DOMAIN RUNNER — STRUCTURED DOMAIN VALIDATION
	# ============================================================

	var domain_test_result: TestRunResult = (
		DomainTestRunner.run(
			world,
			simulation
		)
	)

	if domain_test_result != null:
		suite_result.add_runner_result(
			domain_test_result
		)

		TestLogger.write_line(
			"Domain Test Runner: "
			+ domain_test_result.status
		)

	else:
		TestLogger.write_line(
			"Domain Test Runner: ERROR | result was null."
		)


	# ============================================================
	# LEGACY DOMAIN CHECK — INDUSTRY PROCESS INFRASTRUCTURE PRESSURE
	# ============================================================

	IndustryProcessInfrastructurePressureTest.run(
		world,
		simulation
	)


	# ============================================================
	# FEEDBACK RUNNER — STEP 17.1–17.8
	# ============================================================

	var feedback_test_result: TestRunResult = (
		FeedbackTestRunner.run(
			world,
			simulation
		)
	)

	if feedback_test_result != null:

		suite_result.add_runner_result(
			feedback_test_result
		)

		TestLogger.write_line(
			"Feedback Test Runner: "
			+ feedback_test_result.status
		)

		TestLogger.write_line(
			"Feedback tests run: "
			+ str(
				feedback_test_result.tests_run
			)
		)

		TestLogger.write_line(
			"Feedback tests failed: "
			+ str(
				feedback_test_result.tests_failed
			)
		)

		TestLogger.write_line(
			"Feedback test errors: "
			+ str(
				feedback_test_result.tests_errored
			)
		)

		if not feedback_test_result.passed():

			var primary_feedback_diagnostic := (
				feedback_test_result.primary_diagnostic()
			)

			if primary_feedback_diagnostic != null:

				TestLogger.write_line(
					"Feedback primary diagnostic: "
					+ primary_feedback_diagnostic.format_for_human()
				)

	else:

		TestLogger.write_line(
			"Feedback Test Runner: ERROR | result was null."
		)




	# ============================================================
	# CAMPAIGN RUNNER — STEP 18.2–18.5
	# ============================================================
	#
	# Campaign validation is now owned by CampaignTestRunner.
	#
	# It executes one dedicated 60-month campaign through Step 18.2 and
	# transfers the SAME campaign result to Steps 18.3–18.5.
	#
	# Step 18.1 remains an explicit/manual harness smoke test because it
	# intentionally advances the supplied campaign context.
	# ============================================================

	var campaign_test_result: TestRunResult = (
		CampaignTestRunner.run(
			campaign_world,
			campaign_simulation,
			campaign_months
		)
	)

	if campaign_test_result != null:

		suite_result.add_runner_result(
			campaign_test_result
		)

		TestLogger.write_line(
			"Campaign Test Runner: "
			+ campaign_test_result.status
		)

		TestLogger.write_line(
			"Campaign tests run: "
			+ str(
				campaign_test_result.tests_run
			)
		)

		TestLogger.write_line(
			"Campaign tests failed: "
			+ str(
				campaign_test_result.tests_failed
			)
		)

		TestLogger.write_line(
			"Campaign test errors: "
			+ str(
				campaign_test_result.tests_errored
			)
		)

		if not campaign_test_result.passed():

			var primary_campaign_diagnostic := (
				campaign_test_result.primary_diagnostic()
			)

			if primary_campaign_diagnostic != null:

				TestLogger.write_line(
					"Campaign primary diagnostic: "
					+ primary_campaign_diagnostic.format_for_human()
				)

	else:

		TestLogger.write_line(
			"Campaign Test Runner: ERROR | result was null."
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
	# STEP 18.2–18.5 — CAMPAIGN VALIDATION
	# ============================================================
	#
	# Steps 18.2–18.5 are now fully owned by CampaignTestRunner above.
	# This location is intentionally left empty so the master path does not
	# execute the campaign a second time.
	# ============================================================


	# ============================================================
	# CAUSAL RUNNER — STEP 19.1–19.A
	# ============================================================
	#
	# The complete causal validation family is now owned by
	# CausalTestRunner. The runner preserves the legacy execution order:
	# Step 19.1 through Step 19.9, followed by the Step 19.A structural audit.
	#
	# No causal test is executed again through the legacy master path.
	# ============================================================

	var causal_test_result: TestRunResult = (
		CausalTestRunner.run(
			world,
			simulation
		)
	)

	if causal_test_result != null:

		suite_result.add_runner_result(
			causal_test_result
		)

		TestLogger.write_line(
			"Causal Test Runner: "
			+ causal_test_result.status
		)

		TestLogger.write_line(
			"Causal tests run: "
			+ str(
				causal_test_result.tests_run
			)
		)

		TestLogger.write_line(
			"Causal tests failed: "
			+ str(
				causal_test_result.tests_failed
			)
		)

		TestLogger.write_line(
			"Causal test errors: "
			+ str(
				causal_test_result.tests_errored
			)
		)

		if not causal_test_result.passed():

			var primary_causal_diagnostic := (
				causal_test_result.primary_diagnostic()
			)

			if primary_causal_diagnostic != null:

				TestLogger.write_line(
					"Causal primary diagnostic: "
					+ primary_causal_diagnostic.format_for_human()
				)

	else:

		TestLogger.write_line(
			"Causal Test Runner: ERROR | result was null."
		)


	# ============================================================
	# COMPLETE
	# ============================================================

	TestLogger.section(
		"ACTIVE TEST SUITE COMPLETE"
	)

	# ============================================================
	# STEP 7 — STRUCTURED MASTER RESULT / DIAGNOSTIC PACKAGE
	# ============================================================
	#
	# At this migration stage Data, Interaction, Physical Economy, Domain,
	# Feedback, Campaign, and Causal runners are represented structurally in
	# TestSuiteResult. No causal scenario remains on the legacy master path.
	#
	# The only explicitly retained legacy check is the previously documented
	# IndustryProcessInfrastructurePressureTest domain check.
	# ============================================================

	suite_result.finish()

	if TestLogger.current != null:

		suite_result.set_metadata(
			"legacy_report_path",
			TestLogger.current.get_report_path()
		)

	var result_write := TestResultWriter.write_suite_result(
		suite_result
	)

	TestLogger.write_line(
		"Master structured result: "
		+ (
			"PASS"
			if bool(result_write.get("passed", false))
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Diagnostic summary written: "
		+ str(
			result_write.get(
				"latest_path",
				""
			)
		)
	)

	TestLogger.finish()

	return suite_result
