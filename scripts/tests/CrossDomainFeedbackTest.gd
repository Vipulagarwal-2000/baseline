class_name Step17_3CrossDomainFeedbackTest
extends RefCounted


# ============================================================
# STEP 17.3 — CROSS-DOMAIN FEEDBACK ACCEPTANCE
# ============================================================
#
# This is ONE acceptance test for the entire current Step 17.3
# cross-domain boundary.
#
# It does not create a second domain engine or replace any
# authoritative system. Instead, it:
#
# 1. verifies the current authoritative monthly ordering edges;
# 2. executes the already-validated cross-domain integration tests
#    that exercise the real registered systems;
# 3. keeps event-driven feedback explicitly deferred until E13
#    simulation integration is complete.
#
# The internal sections are coverage groups only. They are NOT
# additional Step 17.3 roadmap substeps.
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 17.3 — CROSS-DOMAIN FEEDBACK ACCEPTANCE"
	)

	var all_passed: bool = true

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

	# ============================================================
	# 1. AUTHORITATIVE MONTHLY ORDERING GATE
	# ============================================================
	#
	# These edges are derived from the currently registered systems,
	# not from an older architecture diagram.
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — AUTHORITATIVE CROSS-DOMAIN ORDERING"
	)

	var trade_order: int = _get_registered_order(
		simulation,
		"trade_system"
	)
	var resource_order: int = _get_registered_order(
		simulation,
		"resource_system"
	)
	var trade_diplomatic_order: int = _get_registered_order(
		simulation,
		"trade_diplomatic_consequences_system"
	)
	var production_order: int = _get_registered_order(
		simulation,
		"production_process_system"
	)
	var economy_order: int = _get_registered_order(
		simulation,
		"economy_system"
	)
	var military_order: int = _get_registered_order(
		simulation,
		"military_system"
	)
	var military_economic_pressure_order: int = _get_registered_order(
		simulation,
		"military_economic_pressure_system"
	)
	var government_order: int = _get_registered_order(
		simulation,
		"government_system"
	)
	var population_order: int = _get_registered_order(
		simulation,
		"population_system"
	)
	var income_consumption_order: int = _get_registered_order(
		simulation,
		"income_consumption_feedback_system"
	)
	var economic_pressure_order: int = _get_registered_order(
		simulation,
		"economic_pressure_political_feedback_system"
	)
	var basic_population_response_order: int = _get_registered_order(
		simulation,
		"basic_population_response_system"
	)
	var government_feedback_order: int = _get_registered_order(
		simulation,
		"government_feedback_system"
	)

	var ordering_edges: Array = [
		{
			"label": "Trade -> ResourceSystem",
			"before": trade_order,
			"after": resource_order
		},
		{
			"label": "ResourceSystem -> ProductionProcessSystem",
			"before": resource_order,
			"after": production_order
		},
		{
			"label": "ProductionProcessSystem -> EconomySystem",
			"before": production_order,
			"after": economy_order
		},
		{
			"label": "EconomySystem -> GovernmentSystem",
			"before": economy_order,
			"after": government_order
		},
		{
			"label": "Trade -> TradeDiplomaticConsequencesSystem",
			"before": trade_order,
			"after": trade_diplomatic_order
		},
		{
			"label": "MilitarySystem -> MilitaryEconomicPressureSystem",
			"before": military_order,
			"after": military_economic_pressure_order
		},
		{
			"label": "MilitaryEconomicPressureSystem -> GovernmentSystem",
			"before": military_economic_pressure_order,
			"after": government_order
		},
		{
			"label": "PopulationSystem -> IncomeConsumptionFeedbackSystem",
			"before": population_order,
			"after": income_consumption_order
		},
		{
			"label": "IncomeConsumptionFeedbackSystem -> EconomicPressurePoliticalFeedbackSystem",
			"before": income_consumption_order,
			"after": economic_pressure_order
		},
		{
			"label": "EconomicPressurePoliticalFeedbackSystem -> BasicPopulationResponseSystem",
			"before": economic_pressure_order,
			"after": basic_population_response_order
		},
		{
			"label": "BasicPopulationResponseSystem -> GovernmentFeedbackSystem",
			"before": basic_population_response_order,
			"after": government_feedback_order
		}
	]

	for edge_variant in ordering_edges:
		var edge: Dictionary = edge_variant
		var before_order: int = int(edge.get("before", -1))
		var after_order: int = int(edge.get("after", -1))
		var edge_passed: bool = (
			before_order >= 0
			and after_order >= 0
			and before_order < after_order
		)

		TestLogger.write_line(
			String(edge.get("label", "Ordering edge"))
			+ ": "
			+ ("PASS" if edge_passed else "FAIL")
			+ " | before="
			+ str(before_order)
			+ " after="
			+ str(after_order)
		)

		if not edge_passed:
			all_passed = false

	# ============================================================
	# 2. PHYSICAL / ECONOMIC FEEDBACK
	# ============================================================
	#
	# Covers the real multi-month chain:
	# technology/resource mix -> resource availability -> production
	# -> physical economic output -> GDP.
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — PHYSICAL / ECONOMIC FEEDBACK"
	)

	var physical_feedback_passed: bool = (
		IntegratedPhysicalEconomyMultiMonthInteractionTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Cross-domain physical economy feedback: "
		+ ("PASS" if physical_feedback_passed else "FAIL")
	)

	if not physical_feedback_passed:
		all_passed = false

	# ============================================================
	# 3. ECONOMY / GOVERNMENT / POPULATION FEEDBACK
	# ============================================================
	#
	# Reuses existing registered feedback tests rather than creating
	# duplicate economy, population, or government authorities.
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — ECONOMY / GOVERNMENT / POPULATION FEEDBACK"
	)

	var economic_government_passed: bool = (
		EconomyEconomicConditionsGovernmentFinancesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Economic conditions -> government finances: "
		+ ("PASS" if economic_government_passed else "FAIL")
	)

	if not economic_government_passed:
		all_passed = false

	var income_consumption_passed: bool = (
		IncomeConsumptionFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Economy/income -> population consumption feedback: "
		+ ("PASS" if income_consumption_passed else "FAIL")
	)

	if not income_consumption_passed:
		all_passed = false

	var economic_pressure_population_passed: bool = (
		EconomicPressurePoliticalFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Economy -> population/government political pressure feedback: "
		+ ("PASS" if economic_pressure_population_passed else "FAIL")
	)

	if not economic_pressure_population_passed:
		all_passed = false

	var population_response_passed: bool = (
		BasicPopulationResponseTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Population -> government-response feedback: "
		+ ("PASS" if population_response_passed else "FAIL")
	)

	if not population_response_passed:
		all_passed = false

	var government_feedback_passed: bool = (
		GovernmentFeedbackTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Government feedback handoff: "
		+ ("PASS" if government_feedback_passed else "FAIL")
	)

	if not government_feedback_passed:
		all_passed = false

	# ============================================================
	# 4. TRADE / RESOURCE / DIPLOMACY FEEDBACK
	# ============================================================
	#
	# Trade is exercised through the authoritative TradeSystem and the
	# existing ResourceSystem / ProductionProcessSystem / EconomySystem
	# chain. Trade diplomacy remains on the relationship dimension
	# owned by the existing relationship model.
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — TRADE / RESOURCE / DIPLOMACY FEEDBACK"
	)

	var trade_resource_passed: bool = (
		TradeResourceEconomicConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade -> resources -> production -> economy feedback: "
		+ ("PASS" if trade_resource_passed else "FAIL")
	)

	if not trade_resource_passed:
		all_passed = false

	var trade_diplomatic_passed: bool = (
		TradeDiplomaticConsequencesTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Trade -> diplomacy feedback: "
		+ ("PASS" if trade_diplomatic_passed else "FAIL")
	)

	if not trade_diplomatic_passed:
		all_passed = false

	# ============================================================
	# 5. MILITARY / ECONOMY FEEDBACK
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — MILITARY / ECONOMY FEEDBACK"
	)

	var military_economic_passed: bool = (
		MilitaryEconomicPressureTest.run(
			world,
			simulation
		)
	)

	TestLogger.write_line(
		"Military -> economic pressure feedback: "
		+ ("PASS" if military_economic_passed else "FAIL")
	)

	if not military_economic_passed:
		all_passed = false

	# ============================================================
	# 6. DEFERRED EVENT FEEDBACK DEPENDENCY
	# ============================================================
	#
	# The master state explicitly makes event-driven Step 17 feedback
	# dependent on E13 simulation integration. E4.3 is complete, but the
	# event execution/effect/choice/simulation bridge is not yet complete.
	# Do not fake event feedback by introducing test-only event authority.
	# ============================================================

	TestLogger.section(
		"STEP 17.3 — EVENT INTEGRATION DEPENDENCY"
	)

	TestLogger.write_line(
		"Events <-> domain-state conditions: PENDING | E13 simulation integration not complete."
	)
	TestLogger.write_line(
		"Events <-> decisions / choices: PENDING | E13 simulation integration not complete."
	)
	TestLogger.write_line(
		"Events <-> effects / consequences: PENDING | E13 simulation integration not complete."
	)
	TestLogger.write_line(
		"Events <-> history / causal explanation: PENDING | E13 simulation integration not complete."
	)

	# Event dependency is intentionally not converted into a false PASS.
	# It is also not treated as a failure of the current executable
	# cross-domain boundary; it remains an explicit downstream dependency.

	TestLogger.write_line(
		"Event-driven Step 17.3 coverage is deferred to E13."
	)

	TestLogger.write_line(
		"Step 17.3 Cross-Domain Feedback current executable boundary: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _get_registered_order(
	simulation: SimulationEngine,
	system_name: String
) -> int:

	if simulation == null:
		return -1

	var system_order: Array = simulation.get_system_order()

	for entry_variant in system_order:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		var name: String = String(
			entry.get("name", "")
		)

		if name == system_name:
			return int(
				entry.get("order", -1)
			)

	return -1
