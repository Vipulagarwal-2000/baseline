class_name TradeValuationTest
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
		"TRADE VALUATION / TRADE VALUE TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)

	var system_ok := (
		valuation_system != null
		and valuation_system is TradeValuationSystem
	)

	_log_result(
		"Registered TradeValuationSystem available",
		system_ok
	)

	if not system_ok:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null or india == null:
		TestLogger.write_line("China and India available: FAIL")
		return false

	TestLogger.write_line("China and India available: PASS")

	var china_economy = china.get_component("economy")
	var china_resources = china.get_component("resources")
	var india_economy = india.get_component("economy")

	if china_economy == null or china_resources == null or india_economy == null:
		TestLogger.write_line(
			"Required economy/resource components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required economy/resource components available: PASS"
	)

	var original_treasury_china := float(
		china_economy.get_state("treasury", 0.0)
	)
	var original_treasury_india := float(
		india_economy.get_state("treasury", 0.0)
	)
	var original_prices: Dictionary = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)

	var execution_date: Dictionary = world.current_date.duplicate(true)

	const agreement_id := "test_trade_agreement_6_2"
	const route_id := "test_trade_route_6_2"
	const transaction_id := "test_trade_transaction_6_2"

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

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)
	china_economy.set_state("treasury", 500.0)
	india_economy.set_state("treasury", 800.0)

	var registered := (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
		and world.add_trade_transaction(transaction)
	)

	_log_result(
		"Trade valuation fixture registration",
		registered
	)

	if not registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)

	var valuation_passed := (
		transaction.valuation_status == "valued"
		and transaction.valuation_currency_id == "CNY"
		and _approx_equal(transaction.valuation_quantity, 15.0)
		and _approx_equal(transaction.valuation_unit_price, 20.0)
		and _approx_equal(transaction.trade_value, 300.0)
	)

	_log_result(
		"Quantity × unit price produces trade value in exporter currency",
		valuation_passed
	)

	var no_treasury_mutation := (
		_approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			500.0
		)
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			800.0
		)
	)

	_log_result(
		"Trade valuation does not mutate treasury balances",
		no_treasury_mutation
	)

	var value_before_repeat := transaction.trade_value
	var currency_before_repeat := transaction.valuation_currency_id
	(valuation_system as TradeValuationSystem).process_month(world)

	var idempotent := (
		_approx_equal(transaction.trade_value, value_before_repeat)
		and transaction.valuation_currency_id == currency_before_repeat
	)

	_log_result(
		"Repeated valuation does not change an already-valued transaction",
		idempotent
	)

	var snapshot := transaction.to_snapshot_dict()
	var snapshot_ok :bool= (
		snapshot.has("trade_value")
		and snapshot.has("valuation_unit_price")
		and snapshot.has("valuation_currency_id")
		and snapshot.has("valuation_status")
		and _approx_equal(
			float(snapshot.get("trade_value", -1.0)),
			300.0
		)
		and snapshot.get("valuation_currency_id", "") == "CNY"
	)

	_log_result(
		"Trade valuation survives transaction snapshot representation",
		snapshot_ok
	)

	# Missing price safety
	const missing_agreement_id := "test_trade_agreement_6_2_missing_price"
	const missing_route_id := "test_trade_route_6_2_missing_price"
	const missing_transaction_id := "test_trade_transaction_6_2_missing_price"

	var missing_agreement := TradeAgreement.new(
		missing_agreement_id,
		"china",
		"india",
		"gold",
		5.0,
		2
	)
	missing_agreement.activate(execution_date)

	var missing_route := TradeRoute.new(
		missing_route_id,
		missing_agreement_id,
		"china",
		"india",
		100.0
	)
	missing_route.activate()

	var missing_transaction := TradeTransaction.new(
		missing_transaction_id,
		missing_agreement_id,
		missing_route_id,
		"china",
		"india",
		"gold",
		5.0,
		5.0,
		execution_date,
		5.0,
		5.0,
		5.0,
		5.0
	)

	var missing_registered := (
		world.add_trade_agreement(missing_agreement)
		and world.add_trade_route(missing_route)
		and world.add_trade_transaction(missing_transaction)
	)

	_log_result(
		"Missing-price valuation fixture registration",
		missing_registered
	)

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)

	(valuation_system as TradeValuationSystem).process_month(world)

	var missing_price_safe := (
		missing_transaction.valuation_status == "unpriced"
		and _approx_equal(missing_transaction.trade_value, 0.0)
	)

	_log_result(
		"Missing price prevents trade valuation without creating value",
		missing_price_safe
	)

	# Zero delivery
	const zero_agreement_id := "test_trade_agreement_6_2_zero"
	const zero_route_id := "test_trade_route_6_2_zero"
	const zero_transaction_id := "test_trade_transaction_6_2_zero"

	var zero_agreement := TradeAgreement.new(
		zero_agreement_id,
		"china",
		"india",
		"iron",
		10.0,
		2
	)
	zero_agreement.activate(execution_date)

	var zero_route := TradeRoute.new(
		zero_route_id,
		zero_agreement_id,
		"china",
		"india",
		100.0
	)
	zero_route.activate()

	var zero_transaction := TradeTransaction.new(
		zero_transaction_id,
		zero_agreement_id,
		zero_route_id,
		"china",
		"india",
		"iron",
		10.0,
		0.0,
		execution_date,
		0.0,
		0.0,
		0.0,
		0.0
	)

	var zero_registered := (
		world.add_trade_agreement(zero_agreement)
		and world.add_trade_route(zero_route)
		and world.add_trade_transaction(zero_transaction)
	)

	_log_result(
		"Zero-delivery valuation fixture registration",
		zero_registered
	)

	(valuation_system as TradeValuationSystem).process_month(world)

	var zero_safe := (
		zero_transaction.valuation_status == "zero_delivery"
		and _approx_equal(zero_transaction.trade_value, 0.0)
	)

	_log_result(
		"Zero delivery produces zero trade value safely",
		zero_safe
	)

	# Cleanup
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_transactions.erase(transaction_id)
	world.trade_agreements.erase(missing_agreement_id)
	world.trade_routes.erase(missing_route_id)
	world.trade_transactions.erase(missing_transaction_id)
	world.trade_agreements.erase(zero_agreement_id)
	world.trade_routes.erase(zero_route_id)
	world.trade_transactions.erase(zero_transaction_id)

	china_resources.set_state("current_price", original_prices)
	china_economy.set_state("treasury", original_treasury_china)
	india_economy.set_state("treasury", original_treasury_india)

	var all_passed := (
		valuation_passed
		and no_treasury_mutation
		and idempotent
		and snapshot_ok
		and missing_registered
		and missing_price_safe
		and zero_registered
		and zero_safe
	)

	TestLogger.write_line(
		"Trade Valuation 6.2 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
