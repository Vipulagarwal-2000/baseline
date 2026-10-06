class_name PaymentAffordabilityTest
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
		"PAYMENT AFFORDABILITY TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var affordability_system = simulation.get_system(
		"payment_affordability_system"
	)
	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)
	var payment_system = simulation.get_system(
		"trade_payment_system"
	)

	var systems_ok: bool = (
		affordability_system != null
		and affordability_system is PaymentAffordabilitySystem
		and valuation_system != null
		and valuation_system is TradeValuationSystem
		and payment_system != null
		and payment_system is TradePaymentSystem
	)

	_log_result(
		"Registered valuation, affordability and payment systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null or india == null:
		TestLogger.write_line("China and India available: FAIL")
		return false

	TestLogger.write_line("China and India available: PASS")

	var china_economy = china.get_component("economy")
	var india_economy = india.get_component("economy")
	var china_resources = china.get_component("resources")

	if china_economy == null or india_economy == null or china_resources == null:
		TestLogger.write_line(
			"Required economy/resource components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required economy/resource components available: PASS"
	)

	var original_china_treasury: float = float(
		china_economy.get_state("treasury", 0.0)
	)
	var original_india_treasury: float = float(
		india_economy.get_state("treasury", 0.0)
	)
	var original_india_currency_id: String = str(
		india_economy.get_state("currency_id", "")
	)
	var original_prices: Dictionary = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)

	var execution_date: Dictionary = world.current_date.duplicate(true)

	# --------------------------------------------------------
	# Same-currency affordable case
	# --------------------------------------------------------
	const affordable_agreement_id := "test_trade_agreement_6_4_affordable"
	const affordable_route_id := "test_trade_route_6_4_affordable"
	const affordable_transaction_id := "test_trade_transaction_6_4_affordable"

	# Controlled test fixture only: compare a CNY obligation against a CNY balance.
	india_economy.set_state("currency_id", "CNY")
	china_resources.set_state("current_price", {"iron": 20.0})
	india_economy.set_state("treasury", 500.0)
	china_economy.set_state("treasury", 500.0)

	var affordable_agreement := TradeAgreement.new(
		affordable_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	affordable_agreement.activate(execution_date)

	var affordable_route := TradeRoute.new(
		affordable_route_id,
		affordable_agreement_id,
		"china",
		"india",
		100.0
	)
	affordable_route.activate()

	var affordable_transaction := TradeTransaction.new(
		affordable_transaction_id,
		affordable_agreement_id,
		affordable_route_id,
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

	var affordable_registered: bool = (
		world.add_trade_agreement(affordable_agreement)
		and world.add_trade_route(affordable_route)
		and world.add_trade_transaction(affordable_transaction)
	)

	_log_result(
		"Affordable payment fixture registration",
		affordable_registered
	)

	if not affordable_registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)
	(affordability_system as PaymentAffordabilitySystem).process_month(world)

	var affordable_eval: bool = (
		affordable_transaction.affordability_checked
		and affordable_transaction.affordable
		and affordable_transaction.affordability_status == "affordable"
		and _approx_equal(
			affordable_transaction.affordability_required_payment,
			300.0
		)
		and _approx_equal(
			affordable_transaction.affordability_available_balance,
			500.0
		)
		and _approx_equal(
			affordable_transaction.affordability_shortfall,
			0.0
		)
	)

	_log_result(
		"Sufficient balance marks payment affordable",
		affordable_eval
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var affordable_settled: bool = (
		affordable_transaction.payment_settled
		and affordable_transaction.payment_status == "settled"
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			200.0
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			800.0
		)
	)

	_log_result(
		"Affordable payment proceeds to settlement",
		affordable_settled
	)

	# --------------------------------------------------------
	# Same-currency insufficient-funds case
	# --------------------------------------------------------
	const insufficient_agreement_id := "test_trade_agreement_6_4_insufficient"
	const insufficient_route_id := "test_trade_route_6_4_insufficient"
	const insufficient_transaction_id := "test_trade_transaction_6_4_insufficient"

	world.trade_agreements.erase(affordable_agreement_id)
	world.trade_routes.erase(affordable_route_id)
	world.trade_transactions.erase(affordable_transaction_id)

	india_economy.set_state("treasury", 100.0)
	china_economy.set_state("treasury", 500.0)

	var insufficient_agreement := TradeAgreement.new(
		insufficient_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	insufficient_agreement.activate(execution_date)

	var insufficient_route := TradeRoute.new(
		insufficient_route_id,
		insufficient_agreement_id,
		"china",
		"india",
		100.0
	)
	insufficient_route.activate()

	var insufficient_transaction := TradeTransaction.new(
		insufficient_transaction_id,
		insufficient_agreement_id,
		insufficient_route_id,
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

	var insufficient_registered: bool = (
		world.add_trade_agreement(insufficient_agreement)
		and world.add_trade_route(insufficient_route)
		and world.add_trade_transaction(insufficient_transaction)
	)

	_log_result(
		"Insufficient-funds payment fixture registration",
		insufficient_registered
	)

	if not insufficient_registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)
	(affordability_system as PaymentAffordabilitySystem).process_month(world)

	var insufficient_eval: bool = (
		insufficient_transaction.affordability_checked
		and not insufficient_transaction.affordable
		and insufficient_transaction.affordability_status == "insufficient_funds"
		and _approx_equal(
			insufficient_transaction.affordability_required_payment,
			300.0
		)
		and _approx_equal(
			insufficient_transaction.affordability_available_balance,
			100.0
		)
		and _approx_equal(
			insufficient_transaction.affordability_shortfall,
			200.0
		)
		and _approx_equal(
			insufficient_transaction.affordability_max_quantity,
			5.0
		)
	)

	_log_result(
		"Insufficient balance is detected with explicit shortfall",
		insufficient_eval
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var insufficient_blocked: bool = (
		not insufficient_transaction.payment_settled
		and insufficient_transaction.payment_status == "insufficient_funds"
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			100.0
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			500.0
		)
	)

	_log_result(
		"Insufficient balance blocks monetary settlement without mutating treasury",
		insufficient_blocked
	)

	# --------------------------------------------------------
	# Cross-currency deferred case
	# --------------------------------------------------------
	const deferred_agreement_id := "test_trade_agreement_6_4_deferred"
	const deferred_route_id := "test_trade_route_6_4_deferred"
	const deferred_transaction_id := "test_trade_transaction_6_4_deferred"

	world.trade_agreements.erase(insufficient_agreement_id)
	world.trade_routes.erase(insufficient_route_id)
	world.trade_transactions.erase(insufficient_transaction_id)

	india_economy.set_state("currency_id", "INR")
	india_economy.set_state("treasury", 500.0)
	china_economy.set_state("treasury", 500.0)

	var deferred_agreement := TradeAgreement.new(
		deferred_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	deferred_agreement.activate(execution_date)

	var deferred_route := TradeRoute.new(
		deferred_route_id,
		deferred_agreement_id,
		"china",
		"india",
		100.0
	)
	deferred_route.activate()

	var deferred_transaction := TradeTransaction.new(
		deferred_transaction_id,
		deferred_agreement_id,
		deferred_route_id,
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

	var deferred_registered: bool = (
		world.add_trade_agreement(deferred_agreement)
		and world.add_trade_route(deferred_route)
		and world.add_trade_transaction(deferred_transaction)
	)

	_log_result(
		"Cross-currency affordability fixture registration",
		deferred_registered
	)

	if not deferred_registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)
	(affordability_system as PaymentAffordabilitySystem).process_month(world)

	var cross_currency_ok: bool = (
		deferred_transaction.affordability_status == "deferred_fx"
		and not deferred_transaction.affordable
		and not deferred_transaction.affordability_checked
		and _approx_equal(
			deferred_transaction.affordability_required_payment,
			300.0
		)
	)

	_log_result(
		"Cross-currency affordability defers honestly until FX exists",
		cross_currency_ok
	)

	# Cleanup
	world.trade_agreements.erase(deferred_agreement_id)
	world.trade_routes.erase(deferred_route_id)
	world.trade_transactions.erase(deferred_transaction_id)

	india_economy.set_state("currency_id", original_india_currency_id)
	india_economy.set_state("treasury", original_india_treasury)
	china_economy.set_state("treasury", original_china_treasury)
	china_resources.set_state("current_price", original_prices)

	var snapshot := insufficient_transaction.to_snapshot_dict()
	var snapshot_ok: bool = (
		snapshot.has("affordability_checked")
		and snapshot.has("affordable")
		and snapshot.has("affordability_required_payment")
		and snapshot.has("affordability_available_balance")
		and snapshot.has("affordability_shortfall")
		and snapshot.has("affordability_max_quantity")
		and snapshot.has("affordability_status")
		and snapshot.has("affordability_ledger")
	)

	_log_result(
		"Affordability state survives transaction snapshot representation",
		snapshot_ok
	)

	var all_passed: bool = (
		affordable_eval
		and affordable_settled
		and insufficient_eval
		and insufficient_blocked
		and cross_currency_ok
		and snapshot_ok
	)

	TestLogger.write_line(
		"Payment Affordability 6.4 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
