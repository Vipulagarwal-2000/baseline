class_name TradePaymentTest
extends RefCounted


const EPSILON := 0.0000001


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
		"TRADE PAYMENT / TRANSACTION COST TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var payment_system = simulation.get_system(
		"trade_payment_system"
	)
	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)

	var valuation_available := (
		valuation_system != null
		and valuation_system is TradeValuationSystem
	)

	_log_result(
		"Registered TradeValuationSystem available",
		valuation_available
	)

	if not valuation_available:
		return false


	var system_available: bool = (
		payment_system != null
		and payment_system is TradePaymentSystem
	)

	_log_result(
		"Registered TradePaymentSystem available",
		system_available
	)

	if not system_available:
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

	if (
		china_economy == null
		or india_economy == null
		or china_resources == null
	):
		TestLogger.write_line(
			"Required economy/resource components available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Required economy/resource components available: PASS"
	)

	var original_entities: Dictionary = world.entities.duplicate()
	var original_treasury_china: float = float(
		china_economy.get_state("treasury", 0.0)
	)
	var original_treasury_india: float = float(
		india_economy.get_state("treasury", 0.0)
	)
	var original_price_state: Dictionary = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)
	var original_agreements: Dictionary = {}
	var original_routes: Dictionary = {}
	var original_transactions: Dictionary = {}

	const agreement_id := "test_trade_agreement_5_11"
	const route_id := "test_trade_route_5_11"
	const transaction_id := "test_trade_transaction_5_11"
	const missing_price_agreement_id := "test_trade_agreement_5_11_missing_price"
	const missing_price_route_id := "test_trade_route_5_11_missing_price"
	const missing_price_transaction_id := "test_trade_transaction_5_11_missing_price"

	for id in [agreement_id, missing_price_agreement_id]:
		if world.has_trade_agreement(id):
			original_agreements[id] = world.get_trade_agreement(id)

	for id in [route_id, missing_price_route_id]:
		if world.has_trade_route(id):
			original_routes[id] = world.get_trade_route(id)

	for id in [transaction_id, missing_price_transaction_id]:
		if world.has_trade_transaction(id):
			original_transactions[id] = world.get_trade_transaction(id)

	var execution_date: Dictionary = world.current_date.duplicate(true)

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
		"Full-payment fixture registration",
		registered
	)

	if not registered:
		_cleanup(
			world,
			china_economy,
			india_economy,
			china_resources,
			original_treasury_china,
			original_treasury_india,
			original_price_state,
			original_agreements,
			original_routes,
			original_transactions,
			original_entities
		)
		return false

	(valuation_system as TradeValuationSystem).process_month(world)
	payment_system.process_month(world)

	var full_payment_passed := (
		_approx_equal(transaction.payment_quantity, 15.0)
		and _approx_equal(transaction.payment_unit_price, 20.0)
		and _approx_equal(transaction.trade_payment, 300.0)
		and _approx_equal(transaction.transaction_cost, 300.0)
		and transaction.payment_settled
		and transaction.payment_status == "settled"
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			500.0
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			800.0
		)
	)
	_log_result(
		"Full delivery transfers payment from importer to exporter",
		full_payment_passed
	)

	var importer_after_first_settlement := float(
		india_economy.get_state("treasury", 0.0)
	)
	var exporter_after_first_settlement := float(
		china_economy.get_state("treasury", 0.0)
	)

	(valuation_system as TradeValuationSystem).process_month(world)
	payment_system.process_month(world)

	var idempotence_passed := (
		_approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			importer_after_first_settlement
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			exporter_after_first_settlement
		)
	)
	_log_result(
		"Repeated processing does not double-charge or double-credit",
		idempotence_passed
	)

	# ------------------------------------------------------------
	# MISSING PRICE — safe non-settlement
	# ------------------------------------------------------------

	var missing_price_agreement := TradeAgreement.new(
		missing_price_agreement_id,
		"china",
		"india",
		"gold",
		5.0,
		2
	)
	missing_price_agreement.activate(execution_date)

	var missing_price_route := TradeRoute.new(
		missing_price_route_id,
		missing_price_agreement_id,
		"china",
		"india",
		100.0
	)
	missing_price_route.activate()

	var missing_price_transaction := TradeTransaction.new(
		missing_price_transaction_id,
		missing_price_agreement_id,
		missing_price_route_id,
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

	var previous_gold_price = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)
	var no_gold_price = previous_gold_price.duplicate(true)
	no_gold_price.erase("gold")
	china_resources.set_state("current_price", no_gold_price)

	var missing_price_registered := (
		world.add_trade_agreement(missing_price_agreement)
		and world.add_trade_route(missing_price_route)
		and world.add_trade_transaction(missing_price_transaction)
	)
	_log_result(
		"Missing-price fixture registration",
		missing_price_registered
	)

	var missing_price_before_importer := float(
		india_economy.get_state("treasury", 0.0)
	)
	var missing_price_before_exporter := float(
		china_economy.get_state("treasury", 0.0)
	)

	(valuation_system as TradeValuationSystem).process_month(world)
	payment_system.process_month(world)

	var missing_price_passed := (
		missing_price_transaction.payment_status == "unpriced"
		and not missing_price_transaction.payment_settled
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			missing_price_before_importer
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			missing_price_before_exporter
		)
	)
	_log_result(
		"Missing price prevents monetary settlement without mutating treasury",
		missing_price_passed
	)

	# ------------------------------------------------------------
	# ZERO DELIVERY
	# ------------------------------------------------------------

	const zero_agreement_id := "test_trade_agreement_5_11_zero"
	const zero_route_id := "test_trade_route_5_11_zero"
	const zero_transaction_id := "test_trade_transaction_5_11_zero"

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
		"Zero-delivery fixture registration",
		zero_registered
	)

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)

	var zero_before_importer := float(
		india_economy.get_state("treasury", 0.0)
	)
	var zero_before_exporter := float(
		china_economy.get_state("treasury", 0.0)
	)

	(valuation_system as TradeValuationSystem).process_month(world)
	payment_system.process_month(world)

	var zero_delivery_passed := (
		zero_transaction.payment_settled
		and zero_transaction.payment_status == "zero_delivery"
		and _approx_equal(zero_transaction.trade_payment, 0.0)
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			zero_before_importer
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			zero_before_exporter
		)
	)
	_log_result(
		"Zero delivery creates zero payment safely",
		zero_delivery_passed
	)

	var snapshot := transaction.to_snapshot_dict()
	var snapshot_passed := (
		snapshot.has("trade_payment")
		and snapshot.has("payment_settled")
		and snapshot.has("payment_ledger")
		and _approx_equal(
			float(snapshot.get("trade_payment", -1.0)),
			300.0
		)
	)
	_log_result(
		"Payment state survives transaction snapshot representation",
		snapshot_passed
	)

	var all_passed := (
		full_payment_passed
		and idempotence_passed
		and missing_price_registered
		and missing_price_passed
		and zero_registered
		and zero_delivery_passed
		and snapshot_passed
	)

	_cleanup(
		world,
		china_economy,
		india_economy,
		china_resources,
		original_treasury_china,
		original_treasury_india,
		original_price_state,
		original_agreements,
		original_routes,
		original_transactions,
		original_entities
	)

	TestLogger.write_line(
		"Trade Payment / Transaction Cost 5.11 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)
	return all_passed


static func _cleanup(
	world: WorldState,
	china_economy,
	india_economy,
	china_resources,
	original_treasury_china: float,
	original_treasury_india: float,
	original_price_state: Dictionary,
	original_agreements: Dictionary,
	original_routes: Dictionary,
	original_transactions: Dictionary,
	original_entities: Dictionary
) -> void:

	china_economy.set_state(
		"treasury",
		original_treasury_china
	)
	india_economy.set_state(
		"treasury",
		original_treasury_india
	)
	china_resources.set_state(
		"current_price",
		original_price_state
	)

	for id in [
		"test_trade_transaction_5_11",
		"test_trade_transaction_5_11_missing_price",
		"test_trade_transaction_5_11_zero"
	]:
		world.remove_trade_transaction(id)

	for id in [
		"test_trade_route_5_11",
		"test_trade_route_5_11_missing_price",
		"test_trade_route_5_11_zero"
	]:
		world.remove_trade_route(id)

	for id in [
		"test_trade_agreement_5_11",
		"test_trade_agreement_5_11_missing_price",
		"test_trade_agreement_5_11_zero"
	]:
		world.remove_trade_agreement(id)

	for id in original_transactions.keys():
		world.trade_transactions[id] = original_transactions[id]

	for id in original_routes.keys():
		world.trade_routes[id] = original_routes[id]

	for id in original_agreements.keys():
		world.trade_agreements[id] = original_agreements[id]

	world.entities.clear()
	for entity_id in original_entities.keys():
		world.entities[entity_id] = original_entities[entity_id]
