class_name CurrencyConversionTest
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
		"CURRENCY CONVERSION / FX TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var conversion_system = simulation.get_system(
		"currency_conversion_system"
	)

	var affordability_system = simulation.get_system(
		"payment_affordability_system"
	)

	var payment_system = simulation.get_system(
		"trade_payment_system"
	)

	var systems_ok: bool = (
		conversion_system != null
		and conversion_system is CurrencyConversionSystem
		and affordability_system != null
		and affordability_system is PaymentAffordabilitySystem
		and payment_system != null
		and payment_system is TradePaymentSystem
	)

	_log_result(
		"Registered conversion, affordability and payment systems available",
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
	var original_prices: Dictionary = china_resources.get_state(
		"current_price",
		{}
	).duplicate(true)

	var execution_date: Dictionary = world.current_date.duplicate(true)

	const agreement_id := "test_trade_agreement_6_5"
	const route_id := "test_trade_route_6_5"
	const transaction_id := "test_trade_transaction_6_5"

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)
	india_economy.set_state("treasury", 1500.0)
	china_economy.set_state("treasury", 500.0)

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

	var registered: bool = (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
		and world.add_trade_transaction(transaction)
	)

	_log_result(
		"Cross-currency conversion fixture registration",
		registered
	)

	if not registered:
		return false

	(simulation.get_system("trade_valuation_system") as TradeValuationSystem).process_month(world)
	(conversion_system as CurrencyConversionSystem).process_month(world)

	var conversion_ok: bool = (
		transaction.conversion_status == "converted"
		and transaction.fx_source_currency_id == "CNY"
		and transaction.fx_target_currency_id == "INR"
		and transaction.payment_currency_id == "INR"
		and transaction.fx_applied
		and _approx_equal(transaction.fx_rate, 4.0)
		and _approx_equal(transaction.receiver_payment_amount, 300.0)
		and _approx_equal(transaction.payer_payment_amount, 1200.0)
	)

	# NOTE:
	# rates_to_base: CNY=2.5, INR=10.0
	# => 1 CNY = 4.0 INR under this explicit normalized MVP table.
	_log_result(
		"Fixed/simple FX converts trade value into payer currency",
		conversion_ok
	)

	var conversion_idempotent_amount := transaction.payer_payment_amount
	var conversion_idempotent_rate := transaction.fx_rate
	(conversion_system as CurrencyConversionSystem).process_month(world)

	var idempotent_ok: bool = (
		_approx_equal(
			transaction.payer_payment_amount,
			conversion_idempotent_amount
		)
		and _approx_equal(
			transaction.fx_rate,
			conversion_idempotent_rate
		)
	)

	_log_result(
		"Repeated currency conversion does not compound or change the result",
		idempotent_ok
	)

	# Feed the converted payer amount into affordability.
	(affordability_system as PaymentAffordabilitySystem).process_month(world)

	var affordability_ok: bool = (
		transaction.affordability_status == "affordable"
		and transaction.affordable
		and _approx_equal(
			transaction.affordability_required_payment,
			1200.0
		)
		and _approx_equal(
			transaction.affordability_available_balance,
			1500.0
		)
		and _approx_equal(
			transaction.affordability_shortfall,
			0.0
		)
	)

	_log_result(
		"Converted payer amount feeds payment affordability",
		affordability_ok
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var settlement_ok: bool = (
		transaction.payment_settled
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			300.0
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			800.0
		)
	)

	_log_result(
		"Cross-currency settlement debits payer currency and credits receiver currency",
		settlement_ok
	)

	var ledger_ok: bool = (
		transaction.payment_ledger.get("fx_applied", false)
		and _approx_equal(
			float(transaction.payment_ledger.get("fx_rate", 0.0)),
			4.0
		)
		and _approx_equal(
			float(transaction.payment_ledger.get("payer_payment_amount", -1.0)),
			1200.0
		)
		and _approx_equal(
			float(transaction.payment_ledger.get("receiver_payment_amount", -1.0)),
			300.0
		)
		and str(
			transaction.payment_ledger.get(
				"payment_currency_id",
				""
			)
		) == "INR"
	)

	_log_result(
		"Settlement ledger records payer/receiver amounts and FX context",
		ledger_ok
	)

	# Missing-rate safety using a synthetic unsupported currency identity.
	india_economy.set_state(
		"currency_id",
		"GBP"
	)

	const missing_agreement_id := "test_trade_agreement_6_5_missing"
	const missing_route_id := "test_trade_route_6_5_missing"
	const missing_transaction_id := "test_trade_transaction_6_5_missing"

	var missing_agreement := TradeAgreement.new(
		missing_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
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
		"iron",
		15.0,
		15.0,
		execution_date,
		15.0,
		15.0,
		15.0,
		15.0
	)

	var missing_registered: bool = (
		world.add_trade_agreement(missing_agreement)
		and world.add_trade_route(missing_route)
		and world.add_trade_transaction(missing_transaction)
	)

	_log_result(
		"Missing-rate conversion fixture registration",
		missing_registered
	)

	# Isolate the Step 6.5 missing-rate case from the valuation pipeline.
	# Step 6.2 already validates valuation separately; this fixture enters
	# CurrencyConversionSystem with a valid CNY-denominated trade value and
	# changes only the payer currency to an unsupported GBP identity.
	missing_transaction.valuation_quantity = 15.0
	missing_transaction.valuation_unit_price = 20.0
	missing_transaction.valuation_currency_id = "CNY"
	missing_transaction.trade_value = 300.0
	missing_transaction.valuation_status = "valued"
	missing_transaction.payment_settled = false
	missing_transaction.conversion_status = "pending"
	missing_transaction.conversion_checked = false
	missing_transaction.fx_applied = false
	missing_transaction.fx_rate = 0.0
	missing_transaction.payer_payment_amount = 0.0
	missing_transaction.receiver_payment_amount = 300.0

	(conversion_system as CurrencyConversionSystem).process_month(world)

	var missing_rate_ok: bool = (
		missing_transaction.conversion_status == "missing_rate"
		and not missing_transaction.fx_applied
		and _approx_equal(
			missing_transaction.payer_payment_amount,
			0.0
		)
	)

	if not missing_rate_ok:
		TestLogger.write_line(
			"Missing-rate diagnostic: status="
			+ missing_transaction.conversion_status
			+ " fx_applied="
			+ str(missing_transaction.fx_applied)
			+ " payer_amount="
			+ str(missing_transaction.payer_payment_amount)
		)

	_log_result(
		"Missing FX rate prevents conversion without creating a payment",
		missing_rate_ok
	)

	# Snapshot representation.
	var snapshot := transaction.to_snapshot_dict()
	var snapshot_ok: bool = (
		snapshot.has("conversion_checked")
		and snapshot.has("conversion_status")
		and snapshot.has("fx_source_currency_id")
		and snapshot.has("fx_target_currency_id")
		and snapshot.has("payment_currency_id")
		and snapshot.has("fx_rate")
		and snapshot.has("payer_payment_amount")
		and snapshot.has("receiver_payment_amount")
		and snapshot.has("conversion_ledger")
		and snapshot.get("conversion_status", "") == "converted"
	)

	_log_result(
		"Currency conversion state survives transaction snapshot representation",
		snapshot_ok
	)

	# Cleanup and restore.
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_transactions.erase(transaction_id)
	world.trade_agreements.erase(missing_agreement_id)
	world.trade_routes.erase(missing_route_id)
	world.trade_transactions.erase(missing_transaction_id)

	india_economy.set_state("currency_id", "INR")
	india_economy.set_state("treasury", original_india_treasury)
	china_economy.set_state("treasury", original_china_treasury)
	china_resources.set_state("current_price", original_prices)

	var all_passed: bool = (
		conversion_ok
		and idempotent_ok
		and affordability_ok
		and settlement_ok
		and ledger_ok
		and missing_registered
		and missing_rate_ok
		and snapshot_ok
	)

	TestLogger.write_line(
		"Currency Conversion / FX 6.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
