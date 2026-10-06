class_name TradeResourceEconomicConsequencesTest
extends RefCounted


# ============================================================
# TRADE — STEP 4.8 TEST
# ============================================================
#
# Validates the existing physical-economy chain with trade as the
# new upstream resource source:
#
# trade import
#     ↓
# ResourceSystem availability
#     ↓
# production-process constraint
#     ↓
# realized physical production
#     ↓
# EconomySystem output / GDP consequence
#
# This test deliberately does not create a new resource inventory,
# production model, or economic model. It uses the registered
# TradeSystem, ResourceSystem, ProductionProcessSystem, and
# EconomySystem.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE RESOURCE / ECONOMIC CONSEQUENCES TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var trade_system = simulation.get_system("trade_system")
	var resource_system = simulation.get_system("resource_system")
	var production_process_system = simulation.get_system("production_process_system")
	var economy_system = simulation.get_system("economy_system")

	if trade_system == null:
		TestLogger.write_line("Registered TradeSystem available: FAIL")
		return false

	if resource_system == null:
		TestLogger.write_line("Registered ResourceSystem available: FAIL")
		return false

	if production_process_system == null:
		TestLogger.write_line("Registered ProductionProcessSystem available: FAIL")
		return false

	if economy_system == null:
		TestLogger.write_line("Registered EconomySystem available: FAIL")
		return false

	TestLogger.write_line("Registered TradeSystem available: PASS")
	TestLogger.write_line("Registered ResourceSystem available: PASS")
	TestLogger.write_line("Registered ProductionProcessSystem available: PASS")
	TestLogger.write_line("Registered EconomySystem available: PASS")

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null or india == null:
		TestLogger.write_line("China and India available: FAIL")
		return false

	TestLogger.write_line("China and India available: PASS")

	var china_resources = china.get_component("resources")
	var india_resources = india.get_component("resources")
	var china_infrastructure = china.get_component("infrastructure")
	var india_infrastructure = india.get_component("infrastructure")
	var india_industry = india.get_component("industry")
	var india_population = india.get_component("population")
	var india_economy = india.get_component("economy")
	var india_research = india.get_component("research")

	if (
		china_resources == null
		or india_resources == null
		or china_infrastructure == null
		or india_infrastructure == null
		or india_industry == null
		or india_economy == null
	):
		TestLogger.write_line(
            "Required resource / production / economy components available: FAIL"
		)
		return false

	TestLogger.write_line(
        "Required resource / production / economy components available: PASS"
	)

	const agreement_id = "test_trade_agreement_4_8_resource_economic"
	const route_id = "test_trade_route_4_8_resource_economic"
	const transaction_id = ""

	var original_date = world.current_date.duplicate(true)

	var original_china_resource_state = china_resources.state.duplicate(true)
	var original_india_resource_state = india_resources.state.duplicate(true)
	var original_china_infrastructure_state = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state = india_infrastructure.state.duplicate(true)
	var original_industry_state = india_industry.state.duplicate(true)
	var original_economy_state = india_economy.state.duplicate(true)

	var original_population_state: Dictionary = {}
	if india_population != null:
		original_population_state = india_population.state.duplicate(true)

	var original_research_state: Dictionary = {}
	if india_research != null:
		original_research_state = india_research.state.duplicate(true)

	var original_agreement = world.trade_agreements.get(
		agreement_id,
		null
	)
	var original_route = world.trade_routes.get(
		route_id,
		null
	)
	var original_transaction = world.trade_transactions.get(
		transaction_id,
		null
	)

	var all_passed := true

	# --------------------------------------------------------
	# ISOLATE INDIA'S PRODUCTION PROCESS
	# --------------------------------------------------------

	var original_processes: Dictionary = (
		india_industry.get_state(
			"processes",
			{}
		).duplicate(true)
	)

	var isolated_processes: Dictionary = {}

	for process_id in original_processes.keys():
		var original_process = original_processes[process_id]
		if typeof(original_process) != TYPE_DICTIONARY:
			continue

		isolated_processes[str(process_id)] = (
			original_process.duplicate(true)
		)
		isolated_processes[str(process_id)]["active"] = false

	isolated_processes["steel_basic"] = {
		"active": true,
		"capacity": 10.0,
		"efficiency": 1.0
	}

	india_industry.set_state(
		"processes",
		isolated_processes
	)

	var original_adoption: Dictionary = (
		india_industry.get_state(
			"process_adoption",
			{}
		).duplicate(true)
	)

	var isolated_adoption: Dictionary = (
		original_adoption.duplicate(true)
	)
	isolated_adoption["steel_basic"] = 1.0

	india_industry.set_state(
		"process_adoption",
		isolated_adoption
	)

	# Clear persisted production outcomes from earlier tests.
	# EconomySystem intentionally consumes every entry in production_state,
	# so stale outcomes would contaminate this isolated causal comparison.
	india_industry.set_state(
		"production_state",
		{}
	)
	india_industry.set_state(
		"production_totals",
		{}
	)

	if india_population != null:
		india_population.set_state(
			"effective_labor_capacity",
			1000.0
		)
		india_population.set_state(
			"effective_skilled_labor_capacity",
			1000.0
		)

	india_infrastructure.set_state("power", 1.0)
	india_infrastructure.set_state("industrial", 1.0)
	india_infrastructure.set_state(
		"process_maintenance_capacity",
		{
			"machinery": 1.0
		}
	)

	china_infrastructure.state["ports"] = 1.0
	china_infrastructure.state["transport"] = 1.0
	china_infrastructure.state["roads"] = 1.0
	china_infrastructure.state["railways"] = 1.0

	india_infrastructure.state["ports"] = 1.0
	india_infrastructure.state["transport"] = 1.0
	india_infrastructure.state["roads"] = 1.0
	india_infrastructure.state["railways"] = 1.0

	if india_research != null:
		india_research.set_state(
			"technology_effects",
			{
				"industrial_production_efficiency": 1.0
			}
		)

	india_economy.set_state("gdp", 1000.0)
	india_economy.set_state("growth_rate", 12.0)
	india_economy.set_state("investment_rate", 0.0)
	india_economy.set_state("investment_capacity", 1000.0)
	india_economy.set_state("resource_efficiency", 1.0)

	# Remove unrelated domestic resource flows so the controlled causal
	# comparison is driven by iron availability and the trade import.
	china_resources.set_state("production", {})
	china_resources.set_state("consumption", {})
	china_resources.set_state("imports", {})
	china_resources.set_state("exports", {})

	india_resources.set_state("production", {})
	india_resources.set_state("consumption", {})
	india_resources.set_state("imports", {})
	india_resources.set_state("exports", {})

	# Start with no stale process-shortage state.
	india_resources.set_state("production_process_demand", {})
	india_resources.set_state("production_process_shortages", {})
	india_resources.set_state("production_process_shortage_ratio", {})
	india_resources.set_state("production_process_resource_availability", {})

	# --------------------------------------------------------
	# BASELINE — NO TRADE
	# --------------------------------------------------------

	var baseline_stockpile: Dictionary = (
		original_india_resource_state.get("stockpile", {}).duplicate(true)
	)
	baseline_stockpile["iron"] = 5.0
	baseline_stockpile["coal"] = 10.0
	baseline_stockpile["steel"] = 0.0

	india_resources.set_state(
		"stockpile",
		baseline_stockpile
	)

	india_resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	resource_system.process_month(world)

	var baseline_availability: Dictionary = (
		india_resources.get_state(
			"production_process_resource_availability",
			{}
		)
	)

	var baseline_iron_availability := float(
		baseline_availability.get("iron", 0.0)
	)

	production_process_system.process_month(world)
	economy_system.process_month(world)

	var baseline_output := float(
		india_economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var baseline_factor := float(
		india_economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var baseline_gdp := float(
		india_economy.get_state(
			"gdp",
			0.0
		)
	)

	var baseline_pass := (
		is_equal_approx(baseline_iron_availability, 0.25)
		and is_equal_approx(baseline_output, 2.5)
		and is_equal_approx(baseline_factor, 0.25)
		and is_equal_approx(baseline_gdp, 1002.5)
	)

	TestLogger.write_line(
        "No-trade baseline shows iron shortage constraining production: "
		+ ("PASS" if baseline_pass else "FAIL")
		+ " | iron_availability="
		+ str(baseline_iron_availability)
		+ " production="
		+ str(baseline_output)
		+ " output_factor="
		+ str(baseline_factor)
		+ " gdp="
		+ str(baseline_gdp)
	)

	if not baseline_pass:
		all_passed = false

	# --------------------------------------------------------
	# TRADE RESTORES RESOURCE AVAILABILITY
	# --------------------------------------------------------

	# Reset the importer to the same constrained starting stockpile and
	# provide exactly the missing 15 iron units at the exporter.
	var trade_importer_stockpile: Dictionary = (
		original_india_resource_state.get("stockpile", {}).duplicate(true)
	)
	trade_importer_stockpile["iron"] = 5.0
	trade_importer_stockpile["coal"] = 10.0
	trade_importer_stockpile["steel"] = 0.0

	india_resources.set_state(
		"stockpile",
		trade_importer_stockpile
	)

	var trade_exporter_stockpile: Dictionary = (
		original_china_resource_state.get("stockpile", {}).duplicate(true)
	)
	trade_exporter_stockpile["iron"] = 15.0
	trade_exporter_stockpile["coal"] = 0.0

	china_resources.set_state(
		"stockpile",
		trade_exporter_stockpile
	)

	india_resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	india_economy.set_state("gdp", 1000.0)

	# Ensure the trade transaction gets a fresh monthly identifier.
	_advance_test_month(world)

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	agreement.activate(world.current_date)

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)
	route.activate()

	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)

	var registered := (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
	)

	if registered:
		TestLogger.write_line(
            "Controlled trade consequence agreement / route registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Controlled trade consequence agreement / route registration: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var generated_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	var transaction = world.get_trade_transaction(
		generated_transaction_id
	)

	var imported_quantity := 0.0
	if transaction != null:
		imported_quantity = float(
			transaction.actual_imported_quantity
		)

	resource_system.process_month(world)

	var trade_availability: Dictionary = (
		india_resources.get_state(
			"production_process_resource_availability",
			{}
		)
	)

	var trade_iron_availability := float(
		trade_availability.get("iron", 0.0)
	)

	var trade_shortages: Dictionary = (
		india_resources.get_state(
			"production_process_shortages",
			{}
		)
	)

	var trade_iron_shortage := float(
		trade_shortages.get("iron", 0.0)
	)

	var importer_trade_imports: Dictionary = (
		india_resources.get_state(
			"trade_imports",
			{}
		)
	)

	var recorded_trade_import := float(
		importer_trade_imports.get("iron", 0.0)
	)

	var transaction_pass := (
		transaction != null
		and is_equal_approx(imported_quantity, 15.0)
		and is_equal_approx(recorded_trade_import, 15.0)
	)

	TestLogger.write_line(
        "Trade transaction delivers the contracted resource quantity: "
		+ ("PASS" if transaction_pass else "FAIL")
		+ " | imported="
		+ str(imported_quantity)
		+ " recorded_trade_import="
		+ str(recorded_trade_import)
	)

	if not transaction_pass:
		all_passed = false

	var resource_consequence_pass := (
		is_equal_approx(trade_iron_availability, 1.0)
		and is_equal_approx(trade_iron_shortage, 0.0)
	)

	TestLogger.write_line(
        "Trade import restores resource availability and removes production-input shortage: "
		+ ("PASS" if resource_consequence_pass else "FAIL")
		+ " | iron_availability="
		+ str(trade_iron_availability)
		+ " iron_shortage="
		+ str(trade_iron_shortage)
	)

	if not resource_consequence_pass:
		all_passed = false

	production_process_system.process_month(world)
	economy_system.process_month(world)

	var trade_output := float(
		india_economy.get_state(
			"physical_production_output",
			0.0
		)
	)

	var trade_factor := float(
		india_economy.get_state(
			"production_output_factor",
			0.0
		)
	)

	var trade_gdp := float(
		india_economy.get_state(
			"gdp",
			0.0
		)
	)

	var production_consequence_pass := (
		is_equal_approx(trade_output, 10.0)
		and is_equal_approx(trade_factor, 1.0)
	)

	TestLogger.write_line(
        "Trade-driven resource recovery restores physical production: "
		+ ("PASS" if production_consequence_pass else "FAIL")
		+ " | production="
		+ str(trade_output)
		+ " output_factor="
		+ str(trade_factor)
	)

	if not production_consequence_pass:
		all_passed = false

	var economic_consequence_pass := (
		trade_gdp > baseline_gdp
		and is_equal_approx(trade_gdp, 1010.0)
	)

	TestLogger.write_line(
        "Trade-driven production recovery raises economic output: "
		+ ("PASS" if economic_consequence_pass else "FAIL")
		+ " | baseline_gdp="
		+ str(baseline_gdp)
		+ " trade_gdp="
		+ str(trade_gdp)
	)

	if not economic_consequence_pass:
		all_passed = false

	var causal_chain_pass := (
		baseline_iron_availability < trade_iron_availability
		and baseline_output < trade_output
		and baseline_gdp < trade_gdp
	)

	TestLogger.write_line(
        "Trade resource -> production -> economy causal chain is observable: "
		+ ("PASS" if causal_chain_pass else "FAIL")
		+ " | availability="
		+ str(baseline_iron_availability)
		+ "->"
		+ str(trade_iron_availability)
		+ " production="
		+ str(baseline_output)
		+ "->"
		+ str(trade_output)
		+ " gdp="
		+ str(baseline_gdp)
		+ "->"
		+ str(trade_gdp)
	)

	if not causal_chain_pass:
		all_passed = false

	# --------------------------------------------------------
	# RESTORE ORIGINAL STATE
	# --------------------------------------------------------

	world.current_date = original_date.duplicate(true)

	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)
	india_industry.state = original_industry_state.duplicate(true)
	india_economy.state = original_economy_state.duplicate(true)

	if india_population != null:
		india_population.state = original_population_state.duplicate(true)

	if india_research != null:
		india_research.state = original_research_state.duplicate(true)

	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_transactions.erase(generated_transaction_id)

	if original_agreement != null:
		world.trade_agreements[agreement_id] = original_agreement

	if original_route != null:
		world.trade_routes[route_id] = original_route

	if original_transaction != null:
		world.trade_transactions[transaction_id] = original_transaction

	TestLogger.write_line(
        "Trade Resource / Economic Consequences 4.8 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _advance_test_month(
	world: WorldState
) -> void:

	world.current_date.month += 1

	if world.current_date.month > 12:
		world.current_date.month = 1
		world.current_date.year += 1


static func _transaction_id(
	world: WorldState,
	agreement_id: String,
	route_id: String
) -> String:

	return (
        "trade_transaction_"
		+ str(int(world.current_date.get("year", 0)))
		+ "_"
		+ str(int(world.current_date.get("month", 0)))
		+ "_"
		+ agreement_id
		+ "_"
		+ route_id
	)
