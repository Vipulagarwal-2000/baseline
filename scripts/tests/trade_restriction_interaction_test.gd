class_name TradeRestrictionInteractionTest
extends RefCounted


# ============================================================
# TRADE — STEP 11.3 TEST
# ============================================================
#
# Validates the interaction boundary required by Step 11.3:
#   route restriction
#       -> trade quantity / execution
#       -> ResourceSystem import + availability
#       -> production consequence
#       -> economic output consequence
#       -> valuation / payment based on actual imported quantity
#       -> diplomatic consequence based on fulfillment ratio
#       -> transaction-visible history/output state
#
# The test uses the existing authoritative systems. It does not create a
# second resource, production, economy, payment, or diplomacy model.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"TRADE RESTRICTION INTERACTION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")
	TestLogger.write_line("Simulation available: PASS")

	var trade_system: TradeSystem = (
		simulation.get_system("trade_system")
		as TradeSystem
	)
	var route_restriction_system: TradeRouteRestrictionSystem = (
		simulation.get_system("trade_route_restriction_system")
		as TradeRouteRestrictionSystem
	)
	var interaction_system: TradeRestrictionInteractionSystem = (
		simulation.get_system("trade_restriction_interaction_system")
		as TradeRestrictionInteractionSystem
	)
	var resource_system: ResourceSystem = (
		simulation.get_system("resource_system")
		as ResourceSystem
	)
	var production_process_system: ProductionProcessSystem = (
		simulation.get_system("production_process_system")
		as ProductionProcessSystem
	)
	var economy_system: EconomySystem = (
		simulation.get_system("economy_system")
		as EconomySystem
	)
	var currency_identity_system: CurrencyIdentitySystem = (
		simulation.get_system("currency_identity_system")
		as CurrencyIdentitySystem
	)
	var valuation_system: TradeValuationSystem = (
		simulation.get_system("trade_valuation_system")
		as TradeValuationSystem
	)
	var conversion_system: CurrencyConversionSystem = (
		simulation.get_system("currency_conversion_system")
		as CurrencyConversionSystem
	)
	var affordability_system: PaymentAffordabilitySystem = (
		simulation.get_system("payment_affordability_system")
		as PaymentAffordabilitySystem
	)
	var payment_system: TradePaymentSystem = (
		simulation.get_system("trade_payment_system")
		as TradePaymentSystem
	)
	var diplomatic_system: TradeDiplomaticConsequencesSystem = (
		simulation.get_system("trade_diplomatic_consequences_system")
		as TradeDiplomaticConsequencesSystem
	)

	var registrations_ok: bool = (
		trade_system != null
		and route_restriction_system != null
		and interaction_system != null
		and resource_system != null
		and production_process_system != null
		and economy_system != null
		and currency_identity_system != null
		and valuation_system != null
		and conversion_system != null
		and affordability_system != null
		and payment_system != null
		and diplomatic_system != null
	)

	TestLogger.write_line(
		"Required registered trade interaction systems available: "
		+ ("PASS" if registrations_ok else "FAIL")
	)

	if not registrations_ok:
		return false

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
	var india_economy = india.get_component("economy")

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

	const partial_agreement_id: String = "test_trade_agreement_11_3_partial"
	const partial_route_id: String = "test_trade_route_11_3_partial"
	const blocked_agreement_id: String = "test_trade_agreement_11_3_blocked"
	const blocked_route_id: String = "test_trade_route_11_3_blocked"

	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_china_resource_state: Dictionary = china_resources.state.duplicate(true)
	var original_india_resource_state: Dictionary = india_resources.state.duplicate(true)
	var original_china_infrastructure_state: Dictionary = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state: Dictionary = india_infrastructure.state.duplicate(true)
	var original_industry_state: Dictionary = india_industry.state.duplicate(true)
	var original_economy_state: Dictionary = india_economy.state.duplicate(true)
	var original_china_relationships: Dictionary = china.relationships.duplicate(true)
	var original_india_relationships: Dictionary = india.relationships.duplicate(true)
	var original_transactions: Dictionary = world.trade_transactions.duplicate(true)
	var original_partial_agreement = world.trade_agreements.get(partial_agreement_id, null)
	var original_partial_route = world.trade_routes.get(partial_route_id, null)
	var original_blocked_agreement = world.trade_agreements.get(blocked_agreement_id, null)
	var original_blocked_route = world.trade_routes.get(blocked_route_id, null)

	# Isolate this test from any trade fixtures that may already exist in the
	# authoritative world. Other trade tests are expected to restore their
	# state, but this test must not depend on that ordering detail.
	var original_trade_agreements: Dictionary = world.trade_agreements.duplicate(true)
	var original_trade_routes: Dictionary = world.trade_routes.duplicate(true)
	world.trade_agreements.clear()
	world.trade_routes.clear()

	var all_passed: bool = true

	# --------------------------------------------------------
	# CONTROLLED FIXTURE
	# --------------------------------------------------------

	_set_all_trade_infrastructure(china_infrastructure, 1.0)
	_set_all_trade_infrastructure(india_infrastructure, 1.0)

	var original_processes: Dictionary = (
		india_industry.get_state("processes", {}).duplicate(true)
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

	india_industry.set_state("processes", isolated_processes)
	india_industry.set_state(
		"production_state",
		{}
	)
	india_industry.set_state(
		"production_totals",
		{}
	)
	india_industry.set_state(
		"process_adoption",
		{"steel_basic": 1.0}
	)

	india_resources.set_state(
		"production_process_demand",
		{"iron": 20.0, "coal": 10.0}
	)
	india_resources.set_state("production_process_shortages", {})
	india_resources.set_state("production_process_shortage_ratio", {})
	india_resources.set_state("production_process_resource_availability", {})
	india_resources.set_state("production", {})
	india_resources.set_state("consumption", {})
	india_resources.set_state("imports", {})
	india_resources.set_state("exports", {})
	india_resources.set_state("trade_imports", {})
	india_resources.set_state("trade_exports", {})
	india_resources.set_state("committed_stockpile", {})

	india_economy.set_state("gdp", 1000.0)
	india_economy.set_state("growth_rate", 12.0)
	india_economy.set_state("investment_rate", 0.0)
	india_economy.set_state("investment_capacity", 1000.0)
	india_economy.set_state("resource_efficiency", 1.0)

	var importer_stockpile: Dictionary = (
		original_india_resource_state.get("stockpile", {}).duplicate(true)
	)
	importer_stockpile["iron"] = 5.0
	importer_stockpile["coal"] = 10.0
	importer_stockpile["steel"] = 0.0
	var importer_stockpile_fixture: Dictionary = importer_stockpile.duplicate(true)
	india_resources.set_state("stockpile", importer_stockpile_fixture.duplicate(true))

	# Step 5.2 — isolate this controlled trade fixture from any existing
	# inventory reservations. committed_stockpile is an overlay on physical
	# stock and directly reduces opening_available_stockpile in ResourceSystem.
	# The 11.3 causal test controls physical stock explicitly, so no external
	# reservation may consume part of the 5-unit importer stockpile.
	india_resources.set_state("committed_stockpile", {})

	var exporter_stockpile: Dictionary = (
		original_china_resource_state.get("stockpile", {}).duplicate(true)
	)
	exporter_stockpile["iron"] = 15.0
	var exporter_stockpile_fixture: Dictionary = exporter_stockpile.duplicate(true)
	china_resources.set_state("stockpile", exporter_stockpile_fixture.duplicate(true))

	# Keep the exporter fixture free of external inventory reservations as well.
	china_resources.set_state("committed_stockpile", {})

	var prices: Dictionary = (
		china_resources.get_state("current_price", {}).duplicate(true)
	)
	prices["iron"] = 1.0
	china_resources.set_state("current_price", prices)

	currency_identity_system.process_month(world)

	var china_economy = china.get_component("economy")
	if china_economy != null:
		china_economy.set_state("treasury", 0.0)
	india_economy.set_state("treasury", 100000.0)

	# --------------------------------------------------------
	# BASELINE WITHOUT TRADE
	# --------------------------------------------------------

	var stockpile_before_resource: float = float(
		india_resources.get_state("stockpile", {}).get("iron", 0.0)
	)
	TestLogger.write_line(
		"Restricted-month importer iron stockpile before ResourceSystem: "
		+ str(stockpile_before_resource)
	)

	resource_system.process_month(world)
	production_process_system.process_month(world)
	economy_system.process_month(world)

	var baseline_availability: float = float(
		india_resources.get_state(
			"production_process_resource_availability",
			{}
		).get("iron", 0.0)
	)
	var baseline_production: float = float(
		india_economy.get_state(
			"physical_production_output",
			0.0
		)
	)
	var baseline_gdp: float = float(
		india_economy.get_state("gdp", 0.0)
	)
	var baseline_effective_growth: float = float(
		india_economy.get_state("effective_growth_rate", 0.0)
	)
	var baseline_expected_gdp: float = (
		1000.0
		+ 1000.0 * (
			baseline_effective_growth / 12.0 / 100.0
		)
	)

	all_passed = _assert(
		is_equal_approx(baseline_availability, 0.25)
		and is_equal_approx(baseline_production, 2.5)
		and is_equal_approx(baseline_gdp, baseline_expected_gdp),
		"Baseline iron shortage establishes the controlled production/economy state",
		all_passed
	)

	# --------------------------------------------------------
	# PARTIAL RESTRICTION — 50%
	# --------------------------------------------------------

	india_resources.set_state("stockpile", importer_stockpile_fixture.duplicate(true))
	india_resources.set_state("committed_stockpile", {})
	china_resources.set_state("committed_stockpile", {})
	# Clear generic monthly resource flows generated by the baseline
	# production pass. ResourceSystem treats these flows as current-month
	# demand; leaving them in place would subtract the baseline iron
	# consumption a second time and distort the restricted-month
	# production-process availability signal.
	india_resources.set_state("production", {})
	india_resources.set_state("consumption", {})
	india_resources.set_state("imports", {})
	india_resources.set_state("exports", {})
	india_resources.set_state("trade_imports", {})
	india_resources.set_state("trade_exports", {})
	india_resources.set_state("committed_stockpile", {})

	china_resources.set_state("trade_imports", {})
	china_resources.set_state("trade_exports", {})
	china_resources.set_state("committed_stockpile", {})
	india_resources.set_state("production_process_demand", {"iron": 20.0, "coal": 10.0})
	india_resources.set_state("production_process_shortages", {})
	india_resources.set_state("production_process_shortage_ratio", {})
	india_resources.set_state("production_process_resource_availability", {})
	india_industry.set_state("production_state", {})
	india_industry.set_state("production_totals", {})
	# Re-establish the full controlled macro/production baseline after the
	# previous no-trade month. EconomySystem persists several derived values,
	# so the restricted month must not inherit them.
	india_economy.set_state("gdp", 1000.0)
	india_economy.set_state("growth_rate", 12.0)
	india_economy.set_state("investment_rate", 0.0)
	india_economy.set_state("investment_capacity", 1000.0)
	india_economy.set_state("investment", 0.0)
	india_economy.set_state("unallocated_industrial_capacity", 0.0)
	india_economy.set_state("production_output_factor", 1.0)
	india_economy.set_state("physical_production_output", 0.0)
	india_economy.set_state("physical_production_capacity", 0.0)
	india_economy.set_state("production_efficiency", 1.0)
	india_economy.set_state("resource_efficiency", 1.0)
	india_economy.set_state("technology_efficiency", 1.0)
	india_economy.set_state("trade_efficiency", 1.0)
	india_economy.set_state("economic_efficiency", 1.0)
	india_industry.set_state("production_state", {})
	india_industry.set_state("production_totals", {})

	_set_trade_fixture(
		world,
		partial_agreement_id,
		partial_route_id,
		"iron",
		15.0
	)

	var partial_route: TradeRoute = world.get_trade_route(
		partial_route_id
	) as TradeRoute
	var partial_agreement: TradeAgreement = world.get_trade_agreement(
		partial_agreement_id
	) as TradeAgreement

	var partial_restriction_applied: bool = (
		route_restriction_system.apply_route_restriction(
		world,
		partial_route_id,
		0.5,
		"blockade"
		)
	)

	all_passed = _assert(
		partial_restriction_applied and partial_route != null and partial_agreement != null,
		"Partial route restriction fixture applies",
		all_passed
	)

	_advance_test_month(world)
	trade_system.process_month(world)

	var partial_transaction_id: String = _transaction_id(
		world,
		partial_agreement_id,
		partial_route_id
	)
	var partial_transaction: TradeTransaction = world.get_trade_transaction(
		partial_transaction_id
	) as TradeTransaction

	all_passed = _assert(
		partial_transaction != null
		and is_equal_approx(partial_transaction.actual_imported_quantity, 7.5),
		"Restriction changes actual trade quantity deterministically",
		all_passed
	)

	resource_system.process_month(world)
	production_process_system.process_month(world)
	economy_system.process_month(world)
	valuation_system.process_month(world)
	conversion_system.process_month(world)
	affordability_system.process_month(world)
	payment_system.process_month(world)
	diplomatic_system.process_month(world)
	interaction_system.process_month(world)

	var partial_import: float = float(
		india_resources.get_state("trade_imports", {}).get("iron", 0.0)
	)
	var partial_availability: float = float(
		india_resources.get_state(
			"production_process_resource_availability",
			{}
		).get("iron", 0.0)
	)
	var partial_production: float = float(
		india_economy.get_state("physical_production_output", 0.0)
	)
	var partial_gdp: float = float(
		india_economy.get_state("gdp", 0.0)
	)
	var partial_effective_growth: float = float(
		india_economy.get_state("effective_growth_rate", 0.0)
	)
	var partial_expected_gdp: float = (
		1000.0
		+ 1000.0 * (
			partial_effective_growth / 12.0 / 100.0
		)
	)

	TestLogger.write_line(
		"Partial restricted causal values: "
		+ "import=" + str(partial_import)
		+ " availability=" + str(partial_availability)
		+ " production=" + str(partial_production)
		+ " gdp=" + str(partial_gdp)
	)

	all_passed = _assert(
		is_equal_approx(partial_import, 7.5)
		and is_equal_approx(partial_availability, 0.625)
		and is_equal_approx(partial_production, 6.25)
		and is_equal_approx(partial_gdp, partial_expected_gdp),
		"Restricted quantity propagates through resource, production and economy",
		all_passed
	)

	all_passed = _assert(
		partial_transaction.restriction_interaction_applied
		and partial_transaction.restriction_interaction_metadata.get("interaction_status", "") == "partial"
		and is_equal_approx(
			float(partial_transaction.restriction_interaction_metadata.get("restriction_factor", -1.0)),
			0.5
		),
		"Restriction interaction ledger records partial route restriction",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(partial_transaction.valuation_quantity, 7.5)
		and partial_transaction.valuation_status == "valued"
		and is_equal_approx(partial_transaction.trade_value, 7.5),
		"Valuation uses actual restricted imported quantity",
		all_passed
	)

	all_passed = _assert(
		partial_transaction.payment_settled
		and partial_transaction.payment_status == "settled"
		and is_equal_approx(partial_transaction.payment_quantity, 7.5)
		and is_equal_approx(partial_transaction.trade_payment, 7.5),
		"Payment settles only the actually imported restricted quantity",
		all_passed
	)

	var partial_relationship_change: float = float(
		partial_transaction.diplomatic_consequence_metadata.get(
			"relationship_change",
			0.0
		)
	)

	all_passed = _assert(
		partial_transaction.diplomatic_consequence_applied
		and is_equal_approx(partial_relationship_change, 1.0),
		"Diplomatic consequence scales from actual fulfillment ratio",
		all_passed
	)

	var metadata_resource = partial_transaction.restriction_interaction_metadata.get(
		"resource_consequence",
		{}
	)
	var metadata_economy = partial_transaction.restriction_interaction_metadata.get(
		"economic_consequence",
		{}
	)

	all_passed = _assert(
		is_equal_approx(float(metadata_resource.get("trade_import", 0.0)), 7.5)
		and is_equal_approx(float(metadata_economy.get("physical_production_output", 0.0)), 6.25)
		and is_equal_approx(float(metadata_economy.get("gdp", 0.0)), partial_gdp),
		"Restriction ledger captures downstream resource and economy output state",
		all_passed
	)

	var partial_snapshot: WorldSnapshot = WorldSnapshot.new()
	partial_snapshot.capture(world)
	var partial_snapshot_transaction = partial_snapshot.trade_transactions.get(
		partial_transaction_id,
		null
	)

	all_passed = _assert(
		partial_snapshot_transaction != null
		and bool(partial_snapshot_transaction.get("restriction_interaction_applied", false)),
		"Snapshot preserves restriction interaction state",
		all_passed
	)

	if partial_snapshot_transaction != null:
		partial_snapshot_transaction["restriction_interaction_metadata"] = {}

	all_passed = _assert(
		not partial_transaction.restriction_interaction_metadata.is_empty(),
		"Snapshot restriction interaction metadata is deep-copy isolated",
		all_passed
	)

	var partial_metadata_before_repeat: Dictionary = (
		partial_transaction.restriction_interaction_metadata.duplicate(true)
	)
	interaction_system.process_month(world)

	all_passed = _assert(
		partial_transaction.restriction_interaction_metadata == partial_metadata_before_repeat,
		"Repeated restriction interaction processing is idempotent",
		all_passed
	)

	# Remove the partial-restriction fixture before the complete-block test so
	# the next monthly TradeSystem resolution contains only the blocked trade.
	world.trade_agreements.erase(partial_agreement_id)
	world.trade_routes.erase(partial_route_id)

	# --------------------------------------------------------
	# COMPLETE BLOCK
	# --------------------------------------------------------

	india_resources.set_state("stockpile", importer_stockpile_fixture.duplicate(true))
	india_resources.set_state("production_process_demand", {"iron": 20.0, "coal": 10.0})
	india_resources.set_state("production_process_shortages", {})
	india_resources.set_state("production_process_shortage_ratio", {})
	india_resources.set_state("production_process_resource_availability", {})
	india_industry.set_state("production_state", {})
	india_industry.set_state("production_totals", {})
	india_economy.set_state("gdp", 1000.0)

	_set_trade_fixture(
		world,
		blocked_agreement_id,
		blocked_route_id,
		"iron",
		15.0
	)

	var blocked_restriction_applied: bool = (
		route_restriction_system.apply_route_restriction(
		world,
		blocked_route_id,
		0.0,
		"full_blockade"
		)
	)

	all_passed = _assert(
		blocked_restriction_applied,
		"Complete route restriction fixture applies",
		all_passed
	)

	_advance_test_month(world)
	trade_system.process_month(world)

	var blocked_transaction_id: String = _transaction_id(
		world,
		blocked_agreement_id,
		blocked_route_id
	)
	var blocked_transaction: TradeTransaction = world.get_trade_transaction(
		blocked_transaction_id
	) as TradeTransaction

	resource_system.process_month(world)
	production_process_system.process_month(world)
	economy_system.process_month(world)
	valuation_system.process_month(world)
	conversion_system.process_month(world)
	affordability_system.process_month(world)
	payment_system.process_month(world)
	diplomatic_system.process_month(world)
	interaction_system.process_month(world)

	all_passed = _assert(
		blocked_transaction != null
		and is_equal_approx(blocked_transaction.actual_imported_quantity, 0.0)
		and blocked_transaction.status == TradeTransaction.STATUS_UNFULFILLED,
		"Complete restriction produces zero delivery and unfulfilled transaction status",
		all_passed
	)

	var blocked_payment_metadata = blocked_transaction.restriction_interaction_metadata.get(
		"payment",
		{}
	)
	var blocked_diplomatic_metadata = blocked_transaction.restriction_interaction_metadata.get(
		"diplomatic_consequence",
		{}
	)

	all_passed = _assert(
		blocked_transaction.valuation_status == "zero_delivery"
		and blocked_transaction.payment_status == "zero_delivery"
		and is_equal_approx(blocked_transaction.trade_payment, 0.0)
		and is_equal_approx(float(blocked_payment_metadata.get("payment", -1.0)), 0.0),
		"Complete restriction prevents monetary settlement movement",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			float(blocked_diplomatic_metadata.get("relationship_change", 0.0)),
			0.0
		)
		and is_equal_approx(
			float(blocked_transaction.restriction_interaction_metadata.get("fulfillment_ratio", -1.0)),
			0.0
		),
		"Complete restriction produces no positive diplomatic consequence",
		all_passed
	)

	all_passed = _assert(
		blocked_transaction.restriction_interaction_applied
		and blocked_transaction.restriction_interaction_metadata.get("interaction_status", "") == "blocked",
		"Complete restriction records blocked interaction history/output state",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(float(blocked_transaction.restriction_interaction_metadata.get("restriction_factor", -1.0)), 0.0),
		"Complete restriction factor remains visible in interaction history",
		all_passed
	)

	# --------------------------------------------------------
	# RESTORE FIXTURE
	# --------------------------------------------------------

	world.current_date = original_date.duplicate(true)
	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)
	india_industry.state = original_industry_state.duplicate(true)
	india_economy.state = original_economy_state.duplicate(true)
	china.relationships = original_china_relationships.duplicate(true)
	india.relationships = original_india_relationships.duplicate(true)
	world.trade_transactions = original_transactions.duplicate(true)

	world.trade_agreements.clear()
	world.trade_routes.clear()

	for existing_agreement_id in original_trade_agreements.keys():
		world.trade_agreements[existing_agreement_id] = original_trade_agreements[existing_agreement_id]

	for existing_route_id in original_trade_routes.keys():
		world.trade_routes[existing_route_id] = original_trade_routes[existing_route_id]

	if original_partial_agreement != null:
		world.trade_agreements[partial_agreement_id] = original_partial_agreement
	if original_partial_route != null:
		world.trade_routes[partial_route_id] = original_partial_route
	if original_blocked_agreement != null:
		world.trade_agreements[blocked_agreement_id] = original_blocked_agreement
	if original_blocked_route != null:
		world.trade_routes[blocked_route_id] = original_blocked_route

	TestLogger.write_line(
		"Trade Restriction Interaction 11.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _set_trade_fixture(
	world: WorldState,
	agreement_id: String,
	route_id: String,
	resource_id: String,
	quantity: float
) -> void:

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		resource_id,
		quantity,
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

	world.add_trade_agreement(agreement)
	world.add_trade_route(route)


static func _assert(
	condition: bool,
	label: String,
	current: bool
) -> bool:

	if condition:
		TestLogger.write_line(label + ": PASS")
		return current

	TestLogger.write_line(label + ": FAIL")
	return false


static func _set_all_trade_infrastructure(
	infrastructure: InfrastructureComponent,
	value: float
) -> void:

	infrastructure.state["ports"] = value
	infrastructure.state["transport"] = value
	infrastructure.state["roads"] = value
	infrastructure.state["railways"] = value


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
