class_name Step19_6TradeDisruptionCausalValidationTest
extends RefCounted


# ============================================================
# STEP 19.6 — TRADE DISRUPTION CAUSAL VALIDATION
# ============================================================
#
# Controlled causal experiment:
#
# unrestricted trade
#     -> full actual import
#     -> resource availability
#     -> production
#     -> GDP
#
# route restriction
#     -> lower actual import
#     -> lower resource availability
#     -> lower realized production
#     -> lower GDP
#
# explicit recovery
#     -> restriction removed
#     -> full future trade restored
#     -> resource / production / GDP recover
#
# Authority rules:
#   TradeRoute owns durable restriction state.
#   TradeRouteRestrictionSystem applies/removes the restriction.
#   TradeSystem remains the only trade executor.
#   ResourceSystem remains resource-flow / availability authority.
#   ProductionProcessSystem remains production authority.
#   EconomySystem remains GDP authority.
#   TradeRestrictionRecoverySystem performs explicit recovery only.
#
# This test does not introduce a second trade, resource, production,
# or economy model.
# ============================================================

const TARGET_EXPORTER_ID := "china"
const TARGET_IMPORTER_ID := "india"
const TARGET_RESOURCE_ID := "iron"

const AGREEMENT_ID := "step19_6_trade_disruption_agreement"
const ROUTE_ID := "step19_6_trade_disruption_route"

const CONTRACT_QUANTITY := 15.0
const RESTRICTION_FACTOR := 0.25
const ROUTE_BASE_CAPACITY := 100.0


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func _log_result(
	label: String,
	passed: bool
) -> void:
	TestLogger.write_line(
		label + ": " + _pass_fail(passed)
	)


static func _float_state(
	component,
	key: String,
	default_value: float = 0.0
) -> float:
	if component == null:
		return default_value
	return float(
		component.get_state(
			key,
			default_value
		)
	)


static func _transaction_id(
	world: WorldState
) -> String:
	return (
		"trade_transaction_"
		+ str(int(world.current_date.get("year", 0)))
		+ "_"
		+ str(int(world.current_date.get("month", 0)))
		+ "_"
		+ AGREEMENT_ID
		+ "_"
		+ ROUTE_ID
	)


static func _advance_test_month(
	world: WorldState
) -> void:
	world.current_date.month += 1
	if world.current_date.month > 12:
		world.current_date.month = 1
		world.current_date.year += 1


static func _set_infrastructure_baseline(
	infrastructure: InfrastructureComponent
) -> void:
	for key in [
		"ports",
		"transport",
		"roads",
		"railways",
		"power",
		"industrial"
	]:
		infrastructure.set_state(key, 1.0)

	infrastructure.set_state(
		"process_maintenance_capacity",
		{"machinery": 1.0}
	)


static func _prepare_country_fixture(
	india_resources,
	china_resources,
	india_infrastructure,
	china_infrastructure,
	india_industry,
	india_economy,
	india_population,
	india_research
) -> void:

	# --------------------------------------------------------
	# INFRASTRUCTURE / CAPACITY
	# --------------------------------------------------------
	_set_infrastructure_baseline(india_infrastructure)
	_set_infrastructure_baseline(china_infrastructure)

	# --------------------------------------------------------
	# ISOLATE ONE PRODUCTION PROCESS
	# --------------------------------------------------------
	var original_processes: Dictionary = (
		india_industry.get_state(
			"processes",
			{}
		).duplicate(true)
	)

	var isolated_processes: Dictionary = {}

	for process_id in original_processes.keys():
		var process_value = original_processes[process_id]
		if typeof(process_value) != TYPE_DICTIONARY:
			continue
		isolated_processes[str(process_id)] = process_value.duplicate(true)
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

	india_industry.set_state(
		"process_adoption",
		{"steel_basic": 1.0}
	)
	india_industry.set_state(
		"production_state",
		{}
	)
	india_industry.set_state(
		"production_totals",
		{}
	)

	# --------------------------------------------------------
	# LABOR / TECHNOLOGY
	# --------------------------------------------------------
	if india_population != null:
		india_population.set_state(
			"effective_labor_capacity",
			1000.0
		)
		india_population.set_state(
			"effective_skilled_labor_capacity",
			1000.0
		)

	if india_research != null:
		india_research.set_state(
			"technology_effects",
			{
				"industrial_production_efficiency": 1.0
			}
		)

	# --------------------------------------------------------
	# CONTROLLED ECONOMIC STARTING POINT
	# --------------------------------------------------------
	india_economy.set_state("gdp", 1000.0)
	india_economy.set_state("growth_rate", 12.0)
	india_economy.set_state("investment_rate", 0.0)
	india_economy.set_state("investment_capacity", 1000.0)
	india_economy.set_state("resource_efficiency", 1.0)

	# --------------------------------------------------------
	# RESET RESOURCE FLOWS
	# --------------------------------------------------------
	china_resources.set_state("production", {})
	china_resources.set_state("consumption", {})
	china_resources.set_state("imports", {})
	china_resources.set_state("exports", {})
	china_resources.set_state("trade_imports", {})
	china_resources.set_state("trade_exports", {})

	india_resources.set_state("production", {})
	india_resources.set_state("consumption", {})
	india_resources.set_state("imports", {})
	india_resources.set_state("exports", {})
	india_resources.set_state("trade_imports", {})
	india_resources.set_state("trade_exports", {})

	india_resources.set_state(
		"production_process_demand",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)
	india_resources.set_state("production_process_shortages", {})
	india_resources.set_state("production_process_shortage_ratio", {})
	india_resources.set_state("production_process_resource_availability", {})

	var india_stockpile: Dictionary = (
		india_resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)
	india_stockpile["iron"] = 5.0
	india_stockpile["coal"] = 10.0
	india_stockpile["steel"] = 0.0
	india_resources.set_state(
		"stockpile",
		india_stockpile
	)

	var china_stockpile: Dictionary = (
		china_resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)
	china_stockpile["iron"] = 15.0
	china_stockpile["coal"] = 0.0
	china_resources.set_state(
		"stockpile",
		china_stockpile
	)


static func _create_trade_fixture(
	world: WorldState
) -> bool:

	var agreement := TradeAgreement.new(
		AGREEMENT_ID,
		TARGET_EXPORTER_ID,
		TARGET_IMPORTER_ID,
		TARGET_RESOURCE_ID,
		CONTRACT_QUANTITY,
		4
	)
	agreement.activate(world.current_date)

	var route := TradeRoute.new(
		ROUTE_ID,
		AGREEMENT_ID,
		TARGET_EXPORTER_ID,
		TARGET_IMPORTER_ID,
		ROUTE_BASE_CAPACITY
	)

	if not route.activate():
		return false

	world.trade_agreements.erase(AGREEMENT_ID)
	world.trade_routes.erase(ROUTE_ID)

	return (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
	)


static func _run_trade_to_gdp_chain(
	world: WorldState,
	trade_system: TradeSystem,
	resource_system: ResourceSystem,
	production_process_system: ProductionProcessSystem,
	economy_system: EconomySystem
) -> Dictionary:

	trade_system.process_month(world)

	var transaction = world.get_trade_transaction(
		_transaction_id(world)
	)

	var actual_imported_quantity := 0.0
	if transaction != null:
		actual_imported_quantity = float(
			transaction.actual_imported_quantity
		)

	resource_system.process_month(world)

	var importer = world.get_entity(TARGET_IMPORTER_ID)
	var importer_resources = importer.get_component("resources")
	var importer_industry = importer.get_component("industry")
	var importer_economy = importer.get_component("economy")

	var availability: Dictionary = importer_resources.get_state(
		"production_process_resource_availability",
		{}
	)
	var shortages: Dictionary = importer_resources.get_state(
		"production_process_shortages",
		{}
	)
	var trade_imports: Dictionary = importer_resources.get_state(
		"trade_imports",
		{}
	)

	var iron_availability := float(
		availability.get("iron", 0.0)
	)
	var iron_shortage := float(
		shortages.get("iron", 0.0)
	)
	var recorded_trade_import := float(
		trade_imports.get("iron", 0.0)
	)

	production_process_system.process_month(world)
	economy_system.process_month(world)

	var production := float(
		importer_economy.get_state(
			"physical_production_output",
			0.0
		)
	)
	var production_factor := float(
		importer_economy.get_state(
			"production_output_factor",
			0.0
		)
	)
	var gdp := float(
		importer_economy.get_state(
			"gdp",
			0.0
		)
	)

	return {
		"transaction": transaction,
		"actual_imported_quantity": actual_imported_quantity,
		"recorded_trade_import": recorded_trade_import,
		"iron_availability": iron_availability,
		"iron_shortage": iron_shortage,
		"production": production,
		"production_factor": production_factor,
		"gdp": gdp
	}


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 19.6 — TRADE DISRUPTION CAUSAL VALIDATION"
	)

	if world == null:
		_log_result("World available", false)
		return false
	if simulation == null:
		_log_result("Simulation available", false)
		return false

	_log_result("World available", true)
	_log_result("Simulation available", true)

	var trade_system: TradeSystem = (
		simulation.get_system("trade_system") as TradeSystem
	)
	var route_restriction_system: TradeRouteRestrictionSystem = (
		simulation.get_system("trade_route_restriction_system")
		as TradeRouteRestrictionSystem
	)
	var recovery_system: TradeRestrictionRecoverySystem = (
		simulation.get_system("trade_restriction_recovery_system")
		as TradeRestrictionRecoverySystem
	)
	var resource_system: ResourceSystem = (
		simulation.get_system("resource_system") as ResourceSystem
	)
	var production_process_system: ProductionProcessSystem = (
		simulation.get_system("production_process_system")
		as ProductionProcessSystem
	)
	var economy_system: EconomySystem = (
		simulation.get_system("economy_system") as EconomySystem
	)

	var systems_available := (
		trade_system != null
		and route_restriction_system != null
		and recovery_system != null
		and resource_system != null
		and production_process_system != null
		and economy_system != null
	)

	_log_result(
		"Required Step 19.6 causal systems available",
		systems_available
	)
	if not systems_available:
		return false

	var china = world.get_entity(TARGET_EXPORTER_ID)
	var india = world.get_entity(TARGET_IMPORTER_ID)

	var countries_available := (
		china != null
		and india != null
	)
	_log_result(
		"China / India available",
		countries_available
	)
	if not countries_available:
		return false

	var china_resources = china.get_component("resources")
	var india_resources = india.get_component("resources")
	var china_infrastructure = china.get_component("infrastructure")
	var india_infrastructure = india.get_component("infrastructure")
	var india_industry = india.get_component("industry")
	var india_economy = india.get_component("economy")
	var india_population = india.get_component("population")
	var india_research = india.get_component("research")

	var components_available := (
		china_resources != null
		and india_resources != null
		and china_infrastructure != null
		and india_infrastructure != null
		and india_industry != null
		and india_economy != null
	)

	_log_result(
		"Required trade/resource/production/economy components available",
		components_available
	)
	if not components_available:
		return false

	# --------------------------------------------------------
	# EXACT RESTORATION SNAPSHOTS
	# --------------------------------------------------------
	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_china_resource_state: Dictionary = china_resources.state.duplicate(true)
	var original_india_resource_state: Dictionary = india_resources.state.duplicate(true)
	var original_china_infrastructure_state: Dictionary = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state: Dictionary = india_infrastructure.state.duplicate(true)
	var original_industry_state: Dictionary = india_industry.state.duplicate(true)
	var original_economy_state: Dictionary = india_economy.state.duplicate(true)
	var original_population_state: Dictionary = {}
	if india_population != null:
		original_population_state = india_population.state.duplicate(true)
	var original_research_state: Dictionary = {}
	if india_research != null:
		original_research_state = india_research.state.duplicate(true)

	var original_trade_agreements: Dictionary = world.trade_agreements.duplicate(true)
	var original_trade_routes: Dictionary = world.trade_routes.duplicate(true)
	var original_trade_transactions: Dictionary = world.trade_transactions.duplicate(true)

	var original_agreement = world.trade_agreements.get(AGREEMENT_ID, null)
	var original_route = world.trade_routes.get(ROUTE_ID, null)
	var original_transaction = world.trade_transactions.get(
		_transaction_id(world),
		null
	)

	var all_passed := true

	# Isolate trade execution from unrelated persistent fixtures. The test
	# restores the complete trade dictionaries at the end.
	world.trade_agreements.clear()
	world.trade_routes.clear()
	world.trade_transactions.clear()

	# --------------------------------------------------------
	# BASELINE — FULL TRADE DELIVERY
	# --------------------------------------------------------
	_prepare_country_fixture(
		india_resources,
		china_resources,
		india_infrastructure,
		china_infrastructure,
		india_industry,
		india_economy,
		india_population,
		india_research
	)
	
	if not _create_trade_fixture(world):
		_log_result("Controlled trade agreement / route registration", false)
		all_passed = false
	else:
		_log_result("Controlled trade agreement / route registration", true)

	var baseline := _run_trade_to_gdp_chain(
		world,
		trade_system,
		resource_system,
		production_process_system,
		economy_system
	)

	var baseline_import_pass := (
		baseline["transaction"] != null
		and is_equal_approx(
			float(baseline["actual_imported_quantity"]),
			CONTRACT_QUANTITY
		)
		and is_equal_approx(
			float(baseline["recorded_trade_import"]),
			CONTRACT_QUANTITY
		)
	)
	_log_result(
		"Unrestricted route delivers the full contracted quantity",
		baseline_import_pass
	)
	if not baseline_import_pass:
		all_passed = false

	var baseline_resource_pass := (
		float(baseline["iron_availability"]) > 0.99
		and is_equal_approx(
			float(baseline["iron_shortage"]),
			0.0
		)
	)
	_log_result(
		"Full trade delivery restores iron availability without shortage",
		baseline_resource_pass
	)
	if not baseline_resource_pass:
		all_passed = false

	var baseline_production: float = float(baseline["production"])
	var baseline_gdp: float = float(baseline["gdp"])

	var baseline_output_pass := (
		baseline_production > 2.5
	)
	_log_result(
		"Full resource availability produces above the constrained no-trade level",
		baseline_output_pass
	)
	if not baseline_output_pass:
		all_passed = false

	# --------------------------------------------------------
	# RESTRICTED TRADE — CAUSAL INTERRUPTION
	# --------------------------------------------------------
	_prepare_country_fixture(
		india_resources,
		china_resources,
		india_infrastructure,
		china_infrastructure,
		india_industry,
		india_economy,
		india_population,
		india_research
	)
	_advance_test_month(world)

	var restriction_applied := route_restriction_system.apply_route_restriction(
		world,
		ROUTE_ID,
		RESTRICTION_FACTOR,
		"step19_6_trade_disruption"
	)
	_log_result(
		"Controlled route restriction applied through registered authority",
		restriction_applied
	)
	if not restriction_applied:
		all_passed = false

	var route: TradeRoute = world.get_trade_route(ROUTE_ID) as TradeRoute
	var base_capacity_before: float = route.monthly_throughput_capacity

	var restricted_snapshot := WorldSnapshot.new()
	restricted_snapshot.capture(world)
	var restricted_route_snapshot: Dictionary = (
		restricted_snapshot.trade_routes.get(ROUTE_ID, {})
	)

	var snapshot_preserves_restriction := (
		bool(restricted_route_snapshot.get("route_restriction_active", false))
		and is_equal_approx(
			float(restricted_route_snapshot.get("route_restriction_factor", -1.0)),
			RESTRICTION_FACTOR
		)
		and is_equal_approx(
			float(restricted_route_snapshot.get("monthly_throughput_capacity", -1.0)),
			ROUTE_BASE_CAPACITY
		)
	)
	_log_result(
		"WorldSnapshot preserves restriction state while retaining base route capacity",
		snapshot_preserves_restriction
	)
	if not snapshot_preserves_restriction:
		all_passed = false

	var restricted := _run_trade_to_gdp_chain(
		world,
		trade_system,
		resource_system,
		production_process_system,
		economy_system
	)

	var expected_restricted_import := CONTRACT_QUANTITY * RESTRICTION_FACTOR
	var restricted_import_pass := (
		restricted["transaction"] != null
		and is_equal_approx(
			float(restricted["actual_imported_quantity"]),
			expected_restricted_import
		)
		and float(restricted["actual_imported_quantity"]) < float(baseline["actual_imported_quantity"])
	)
	_log_result(
		"Route restriction lowers actual imported trade quantity",
		restricted_import_pass
	)
	if not restricted_import_pass:
		all_passed = false

	var transaction_fulfillment_ratio := 0.0
	if restricted["transaction"] != null:
		var restricted_transaction = restricted["transaction"]
		var requested_quantity: float = maxf(
			0.0,
			float(restricted_transaction.requested_quantity)
		)
		if requested_quantity > 0.0:
			transaction_fulfillment_ratio = clampf(
				float(restricted_transaction.actual_imported_quantity)
				/ requested_quantity,
				0.0,
				1.0
			)

	var fulfillment_pass := is_equal_approx(
		transaction_fulfillment_ratio,
		RESTRICTION_FACTOR
	)
	_log_result(
		"Restricted transaction records the reduced fulfillment ratio",
		fulfillment_pass
	)
	if not fulfillment_pass:
		all_passed = false

	var restricted_resource_pass := (
		float(restricted["iron_availability"]) < float(baseline["iron_availability"])
		and float(restricted["iron_shortage"]) > 0.0
	)
	_log_result(
		"Lower trade flow reduces resource availability and creates iron shortage",
		restricted_resource_pass
	)
	if not restricted_resource_pass:
		all_passed = false

	var restricted_production_pass := (
		float(restricted["production"]) < baseline_production
		and float(restricted["production_factor"]) < float(baseline["production_factor"])
	)
	_log_result(
		"Trade disruption lowers realized physical production",
		restricted_production_pass
	)
	if not restricted_production_pass:
		all_passed = false

	var restricted_gdp_pass := (
		float(restricted["gdp"]) < baseline_gdp
	)
	_log_result(
		"Trade disruption lowers GDP through the production consequence",
		restricted_gdp_pass
	)
	if not restricted_gdp_pass:
		all_passed = false

	var raw_capacity_preserved := is_equal_approx(
		route.monthly_throughput_capacity,
		base_capacity_before
	)
	_log_result(
		"Route restriction does not rewrite base monthly throughput capacity",
		raw_capacity_preserved
	)
	if not raw_capacity_preserved:
		all_passed = false

	# --------------------------------------------------------
	# EXPLICIT RECOVERY
	# --------------------------------------------------------
	_prepare_country_fixture(
		india_resources,
		china_resources,
		india_infrastructure,
		china_infrastructure,
		india_industry,
		india_economy,
		india_population,
		india_research
	)
	_advance_test_month(world)

	var recovery_changed := recovery_system.remove_route_restriction(
		world,
		ROUTE_ID
	)
	_log_result(
		"Explicit recovery removes the route restriction",
		recovery_changed
	)
	if not recovery_changed:
		all_passed = false

	var recovery_route: TradeRoute = world.get_trade_route(ROUTE_ID) as TradeRoute
	var recovery_state_pass := (
		not recovery_route.route_restriction_active
		and is_equal_approx(
			recovery_route.route_restriction_factor,
		1.0
		)
		and is_equal_approx(
			recovery_route.monthly_throughput_capacity,
		ROUTE_BASE_CAPACITY
		)
	)
	_log_result(
		"Recovery restores effective route semantics without changing base capacity",
		recovery_state_pass
	)
	if not recovery_state_pass:
		all_passed = false

	var recovered := _run_trade_to_gdp_chain(
		world,
		trade_system,
		resource_system,
		production_process_system,
		economy_system
	)

	var recovery_import_pass := (
		recovered["transaction"] != null
		and is_equal_approx(
			float(recovered["actual_imported_quantity"]),
			CONTRACT_QUANTITY
		)
	)
	_log_result(
		"Recovered trade returns to full future delivery",
		recovery_import_pass
	)
	if not recovery_import_pass:
		all_passed = false

	var recovery_economic_pass := (
		is_equal_approx(
			float(recovered["iron_availability"]),
			float(baseline["iron_availability"])
		)
		and is_equal_approx(
			float(recovered["production"]),
			baseline_production
		)
		and is_equal_approx(
			float(recovered["gdp"]),
			baseline_gdp
		)
	)
	_log_result(
		"Recovered trade restores resource availability, production, and GDP",
		recovery_economic_pass
	)
	if not recovery_economic_pass:
		all_passed = false

	var repeated_recovery_is_idempotent := (
		recovery_system.remove_route_restriction(
			world,
			ROUTE_ID
		) == false
	)
	_log_result(
		"Repeated route recovery is idempotent",
		repeated_recovery_is_idempotent
	)
	if not repeated_recovery_is_idempotent:
		all_passed = false

	# --------------------------------------------------------
	# RESTORE ORIGINAL WORLD STATE
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

	world.trade_agreements.clear()
	for agreement_id in original_trade_agreements.keys():
		world.trade_agreements[agreement_id] = original_trade_agreements[agreement_id]

	world.trade_routes.clear()
	for route_id in original_trade_routes.keys():
		world.trade_routes[route_id] = original_trade_routes[route_id]

	world.trade_transactions.clear()
	for transaction_id in original_trade_transactions.keys():
		world.trade_transactions[transaction_id] = original_trade_transactions[transaction_id]

	if original_agreement != null:
		world.trade_agreements[AGREEMENT_ID] = original_agreement
	if original_route != null:
		world.trade_routes[ROUTE_ID] = original_route
	if original_transaction != null:
		world.trade_transactions[_transaction_id(world)] = original_transaction

	TestLogger.write_line(
		"Step 19.6 Trade Disruption Causal Validation overall: "
		+ _pass_fail(all_passed)
	)

	return all_passed
