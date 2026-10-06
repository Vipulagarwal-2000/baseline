class_name PaymentSettlementTest
extends RefCounted


static func _approx_equal(actual: float, expected: float) -> bool:
	return is_equal_approx(actual, expected)


static func _log_result(label: String, passed: bool) -> void:
	TestLogger.write_line(
		label + ": " + ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.section(
		"PAYMENT SETTLEMENT TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var payment_system = simulation.get_system(
		"trade_payment_system"
	)
	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)

	var systems_ok := (
		payment_system != null
		and payment_system is TradePaymentSystem
		and valuation_system != null
		and valuation_system is TradeValuationSystem
	)

	_log_result(
		"Registered valuation and payment settlement systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	var china_economy = china.get_component("economy") if china != null else null
	var india_economy = india.get_component("economy") if india != null else null
	var china_resources = china.get_component("resources") if china != null else null

	var components_ok := (
		china != null
		and india != null
		and china_economy != null
		and india_economy != null
		and china_resources != null
	)

	_log_result(
		"China, India and required financial components available",
		components_ok
	)

	if not components_ok:
		return false

	var original_china_treasury := float(
		china_economy.get_state("treasury", 0.0)
	)
	var original_india_treasury := float(
		india_economy.get_state("treasury", 0.0)
	)
	var original_prices: Dictionary = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)

	var execution_date: Dictionary = world.current_date.duplicate(true)

	const agreement_id := "test_trade_agreement_6_3"
	const route_id := "test_trade_route_6_3"
	const transaction_id := "test_trade_transaction_6_3"

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)
	china_economy.set_state("treasury", 500.0)
	india_economy.set_state("treasury", 800.0)

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	agreement.activate(execution_date)

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)
	route.activate()

	var transaction := TradeTransaction.new(
		transaction_id,
		agreement_id,
		route_id,
		"china",
		"india",
		"iron",
		15.0,
		15.0,
		execution_date,
		15.0,
		15.0,
		15.0,
		15.0
	)

	var registered := (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
		and world.add_trade_transaction(transaction)
	)

	_log_result(
		"Payment settlement fixture registration",
		registered
	)

	if not registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)
	payment_system.process_month(world)

	var settlement_fields_ok := (
		transaction.settlement_status == "settled"
		and transaction.settlement_currency_id == "CNY"
		and transaction.payer_currency_id == "INR"
		and transaction.receiver_currency_id == "CNY"
	)

	_log_result(
		"Settlement records payer, receiver and settlement currency identities",
		settlement_fields_ok
	)

	var treasury_delta_ok := (
		_approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			500.0
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			800.0
		)
	)

	_log_result(
		"Settlement debits payer and credits receiver by trade value",
		treasury_delta_ok
	)

	# Combined nominal balance must be unchanged: payer loss equals receiver gain.
	var initial_total := 500.0 + 800.0
	var final_total := (
		float(india_economy.get_state("treasury", 0.0))
		+ float(china_economy.get_state("treasury", 0.0))
	)
	var conservation_ok := _approx_equal(initial_total, final_total)

	_log_result(
		"Settlement conserves combined nominal treasury balance",
		conservation_ok
	)

	var ledger_ok: bool = (
		bool(transaction.settlement_ledger.get("settled", false))
		and str(transaction.settlement_ledger.get("settlement_currency_id", "")) == "CNY"
		and str(transaction.settlement_ledger.get("payer_currency_id", "")) == "INR"
		and str(transaction.settlement_ledger.get("receiver_currency_id", "")) == "CNY"
		and bool(transaction.settlement_ledger.get("fx_applied", true)) == false
	)

	_log_result(
		"Settlement ledger records currency context without applying FX",
		ledger_ok
	)

	var importer_after_first := float(
		india_economy.get_state("treasury", 0.0)
	)
	var exporter_after_first := float(
		china_economy.get_state("treasury", 0.0)
	)

	payment_system.process_month(world)

	var idempotent_ok := (
		_approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			importer_after_first
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			exporter_after_first
		)
	)

	_log_result(
		"Repeated settlement does not double-transfer funds",
		idempotent_ok
	)

	# Step 6.3 does not enforce affordability.
	# A negative treasury remains a valid settlement outcome until 6.4.
	const affordability_agreement_id := "test_trade_agreement_6_3_affordability"
	const affordability_route_id := "test_trade_route_6_3_affordability"
	const affordability_transaction_id := "test_trade_transaction_6_3_affordability"

	var affordability_agreement := TradeAgreement.new(
		affordability_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	affordability_agreement.activate(execution_date)

	var affordability_route := TradeRoute.new(
		affordability_route_id,
		affordability_agreement_id,
		"china",
		"india",
		100.0
	)
	affordability_route.activate()

	var affordability_transaction := TradeTransaction.new(
		affordability_transaction_id,
		affordability_agreement_id,
		affordability_route_id,
		"china",
		"india",
		"iron",
		15.0,
		15.0,
		execution_date,
		15.0,
		15.0,
		15.0,
		15.0
	)

	var affordability_registered := (
		world.add_trade_agreement(affordability_agreement)
		and world.add_trade_route(affordability_route)
		and world.add_trade_transaction(affordability_transaction)
	)

	_log_result(
		"Insufficient-balance settlement fixture registration",
		affordability_registered
	)

	india_economy.set_state("treasury", 0.0)
	china_economy.set_state("treasury", 0.0)

	if affordability_registered:
		(valuation_system as TradeValuationSystem).process_month(world)
		payment_system.process_month(world)

	var affordability_deferred_ok := (
		affordability_registered
		and affordability_transaction.settlement_status == "settled"
		and float(india_economy.get_state("treasury", 0.0)) < 0.0
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			300.0
		)
	)

	_log_result(
		"Settlement occurs without affordability rejection; affordability remains deferred to Step 6.4",
		affordability_deferred_ok
	)

	var snapshot :Dictionary= transaction.to_snapshot_dict()
	var snapshot_ok :bool= (
		snapshot.has("settlement_currency_id")
		and snapshot.has("payer_currency_id")
		and snapshot.has("receiver_currency_id")
		and snapshot.has("settlement_status")
		and snapshot.has("settlement_ledger")
		and snapshot.get("settlement_currency_id", "") == "CNY"
		and snapshot.get("payer_currency_id", "") == "INR"
	)

	_log_result(
		"Settlement state survives transaction snapshot representation",
		snapshot_ok
	)

	# Restore world fixture state.
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_transactions.erase(transaction_id)
	world.trade_agreements.erase(affordability_agreement_id)
	world.trade_routes.erase(affordability_route_id)
	world.trade_transactions.erase(affordability_transaction_id)

	china_resources.set_state("current_price", original_prices)
	china_economy.set_state("treasury", original_china_treasury)
	india_economy.set_state("treasury", original_india_treasury)

	var all_passed :bool= (
		settlement_fields_ok
		and treasury_delta_ok
		and conservation_ok
		and ledger_ok
		and idempotent_ok
		and affordability_deferred_ok
		and snapshot_ok
	)

	TestLogger.write_line(
		"Payment Settlement 6.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
