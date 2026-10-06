class_name MonetaryInvariantTest
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
		"MONETARY INVARIANTS TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)
	var conversion_system = simulation.get_system(
		"currency_conversion_system"
	)
	var affordability_system = simulation.get_system(
		"payment_affordability_system"
	)
	var payment_system = simulation.get_system(
		"trade_payment_system"
	)
	var invariant_system = simulation.get_system(
		"monetary_invariant_system"
	)

	var systems_ok := (
		valuation_system != null
		and valuation_system is TradeValuationSystem
		and conversion_system != null
		and conversion_system is CurrencyConversionSystem
		and affordability_system != null
		and affordability_system is PaymentAffordabilitySystem
		and payment_system != null
		and payment_system is TradePaymentSystem
		and invariant_system != null
		and invariant_system is MonetaryInvariantSystem
	)

	_log_result(
		"Required 6.2–6.6 monetary systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	var china_economy = (
		china.get_component("economy")
		if china != null
		else null
	)
	var india_economy = (
		india.get_component("economy")
		if india != null
		else null
	)

	var china_resources = (
		china.get_component("resources")
		if china != null
		else null
	)

	var components_ok := (
		china != null
		and india != null
		and china_economy != null
		and india_economy != null
		and china_resources != null
	)

	_log_result(
		"China, India and required monetary components available",
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

	var execution_date: Dictionary = (
		world.current_date.duplicate(true)
	)

	const agreement_id := "test_trade_agreement_6_6_invariants"
	const route_id := "test_trade_route_6_6_invariants"
	const transaction_id := "test_trade_transaction_6_6_invariants"

	china_resources.set_state(
		"current_price",
		{"iron": 20.0}
	)
	china_economy.set_state("treasury", 500.0)
	india_economy.set_state("treasury", 1500.0)

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
		"Monetary invariant cross-currency fixture registration",
		registered
	)

	if not registered:
		return false

	(valuation_system as TradeValuationSystem).process_month(world)

	var valuation_ok := (
		transaction.valuation_status == "valued"
		and _approx_equal(transaction.trade_value, 300.0)
		and transaction.valuation_currency_id == "CNY"
	)

	_log_result(
		"Fixture valuation exists before monetary invariant checks",
		valuation_ok
	)

	(conversion_system as CurrencyConversionSystem).process_month(world)

	var conversion_ok := (
		transaction.conversion_status == "converted"
		and _approx_equal(transaction.fx_rate, 4.0)
		and _approx_equal(transaction.payer_payment_amount, 1200.0)
		and _approx_equal(transaction.receiver_payment_amount, 300.0)
	)

	_log_result(
		"FX produces the expected payer/receiver amounts",
		conversion_ok
	)

	(affordability_system as PaymentAffordabilitySystem).process_month(
		world
	)

	var affordability_ok := (
		transaction.affordability_status == "affordable"
		and transaction.affordability_checked
		and _approx_equal(
			transaction.affordability_required_payment,
			1200.0
		)
	)

	_log_result(
		"Affordability is based on the converted payer amount",
		affordability_ok
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var settled := (
		transaction.payment_settled
		and transaction.settlement_status == "settled"
	)

	_log_result(
		"Fixture reaches completed monetary settlement",
		settled
	)

	var balances_after_settlement := {
		"india": float(
			india_economy.get_state("treasury", 0.0)
		),
		"china": float(
			china_economy.get_state("treasury", 0.0)
		)
	}

	var balance_transfer_ok := (
		_approx_equal(
			balances_after_settlement["india"],
			300.0
		)
		and _approx_equal(
			balances_after_settlement["china"],
			800.0
		)
	)

	_log_result(
		"Settlement debits payer and credits receiver by actual amounts",
		balance_transfer_ok
	)

	(invariant_system as MonetaryInvariantSystem).process_month(world)

	var invariant_status_ok := (
		transaction.monetary_invariants_checked
		and transaction.monetary_invariants_passed
		and transaction.monetary_invariant_status == "pass"
		and transaction.monetary_invariant_errors.is_empty()
	)

	_log_result(
		"Completed settlement passes monetary invariants",
		invariant_status_ok
	)

	var settlement_ledger_ok := (
		_approx_equal(
			float(
				transaction.settlement_ledger.get(
					"importer_treasury_before",
					0.0
				)
			),
			1500.0
		)
		and _approx_equal(
			float(
				transaction.settlement_ledger.get(
					"importer_treasury_after",
					0.0
				)
			),
			300.0
		)
		and _approx_equal(
			float(
				transaction.settlement_ledger.get(
					"exporter_treasury_before",
					0.0
				)
			),
			500.0
		)
		and _approx_equal(
			float(
				transaction.settlement_ledger.get(
					"exporter_treasury_after",
					0.0
				)
			),
			800.0
		)
	)

	_log_result(
		"Settlement ledger preserves exact before/after treasury state",
		settlement_ledger_ok
	)

	var base_value_conservation_ok := false

	if transaction.conversion_status == "converted":
		var conversion_ledger := transaction.conversion_ledger
		var source_rate := float(
			conversion_ledger.get(
				"source_rate_to_base",
				0.0
			)
		)
		var target_rate := float(
			conversion_ledger.get(
				"target_rate_to_base",
				0.0
			)
		)

		if source_rate > 0.0 and target_rate > 0.0:
			var receiver_base_value := (
				transaction.receiver_payment_amount
				/ source_rate
			)
			var payer_base_value := (
				transaction.payer_payment_amount
				/ target_rate
			)

			base_value_conservation_ok = _approx_equal(
				payer_base_value,
				receiver_base_value
			)

	_log_result(
		"Cross-currency settlement conserves base-equivalent monetary value",
		base_value_conservation_ok
	)

	var balances_before_invariant_rerun := {
		"india": float(
			india_economy.get_state("treasury", 0.0)
		),
		"china": float(
			china_economy.get_state("treasury", 0.0)
		)
	}

	(invariant_system as MonetaryInvariantSystem).process_month(world)

	var invariant_rerun_balance_ok := (
		_approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			balances_before_invariant_rerun["india"]
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			balances_before_invariant_rerun["china"]
		)
	)

	_log_result(
		"Monetary invariant validation does not mutate treasury balances",
		invariant_rerun_balance_ok
	)

	var india_after_settlement := float(
		india_economy.get_state("treasury", 0.0)
	)
	var china_after_settlement := float(
		china_economy.get_state("treasury", 0.0)
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var settlement_idempotence_ok := (
		_approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			india_after_settlement
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			china_after_settlement
		)
	)

	_log_result(
		"Repeated settlement does not create or destroy additional money",
		settlement_idempotence_ok
	)

	# FX itself must never mutate treasury balances.
	const fx_agreement_id := "test_trade_agreement_6_6_fx_only"
	const fx_route_id := "test_trade_route_6_6_fx_only"
	const fx_transaction_id := "test_trade_transaction_6_6_fx_only"

	var fx_agreement := TradeAgreement.new(
		fx_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	fx_agreement.activate(execution_date)

	var fx_route := TradeRoute.new(
		fx_route_id,
		fx_agreement_id,
		"china",
		"india",
		100.0
	)
	fx_route.activate()

	var fx_transaction := TradeTransaction.new(
		fx_transaction_id,
		fx_agreement_id,
		fx_route_id,
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

	var fx_registered := (
		world.add_trade_agreement(fx_agreement)
		and world.add_trade_route(fx_route)
		and world.add_trade_transaction(fx_transaction)
	)

	_log_result(
		"FX-only invariant fixture registration",
		fx_registered
	)

	if fx_registered:
		(valuation_system as TradeValuationSystem).process_month(
			world
		)

	var fx_before := {
		"india": float(
			india_economy.get_state("treasury", 0.0)
		),
		"china": float(
			china_economy.get_state("treasury", 0.0)
		)
	}

	if fx_registered:
		(conversion_system as CurrencyConversionSystem).process_month(
			world
		)

	var fx_balance_unchanged := (
		fx_registered
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			fx_before["india"]
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			fx_before["china"]
		)
		and fx_transaction.conversion_status == "converted"
	)

	_log_result(
		"FX conversion itself does not mutate treasury balances",
		fx_balance_unchanged
	)

	# A missing FX rate must not produce a settlement or mutate treasury.
	const failed_fx_agreement_id := (
		"test_trade_agreement_6_6_failed_fx"
	)
	const failed_fx_route_id := (
		"test_trade_route_6_6_failed_fx"
	)
	const failed_fx_transaction_id := (
		"test_trade_transaction_6_6_failed_fx"
	)

	var failed_fx_agreement := TradeAgreement.new(
		failed_fx_agreement_id,
		"china",
		"india",
		"iron",
		15.0,
		2
	)
	failed_fx_agreement.activate(execution_date)

	var failed_fx_route := TradeRoute.new(
		failed_fx_route_id,
		failed_fx_agreement_id,
		"china",
		"india",
		100.0
	)
	failed_fx_route.activate()

	var failed_fx_transaction := TradeTransaction.new(
		failed_fx_transaction_id,
		failed_fx_agreement_id,
		failed_fx_route_id,
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

	var failed_fx_registered := (
		world.add_trade_agreement(failed_fx_agreement)
		and world.add_trade_route(failed_fx_route)
		and world.add_trade_transaction(failed_fx_transaction)
	)

	_log_result(
		"Failed-FX invariant fixture registration",
		failed_fx_registered
	)

	failed_fx_transaction.valuation_quantity = 15.0
	failed_fx_transaction.valuation_unit_price = 20.0
	failed_fx_transaction.valuation_currency_id = "GBP"
	failed_fx_transaction.trade_value = 300.0
	failed_fx_transaction.valuation_status = "valued"
	failed_fx_transaction.conversion_status = "pending"
	failed_fx_transaction.conversion_checked = false
	failed_fx_transaction.fx_applied = false
	failed_fx_transaction.fx_rate = 0.0
	failed_fx_transaction.payer_payment_amount = 0.0
	failed_fx_transaction.receiver_payment_amount = 300.0

	var failed_fx_before := {
		"india": float(
			india_economy.get_state("treasury", 0.0)
		),
		"china": float(
			china_economy.get_state("treasury", 0.0)
		)
	}

	if failed_fx_registered:
		(conversion_system as CurrencyConversionSystem).process_month(
			world
		)

	var failed_fx_no_transfer := (
		failed_fx_registered
		and failed_fx_transaction.conversion_status == "missing_rate"
		and not failed_fx_transaction.fx_applied
		and _approx_equal(
			failed_fx_transaction.payer_payment_amount,
			0.0
		)
		and not failed_fx_transaction.payment_settled
		and _approx_equal(
			float(india_economy.get_state("treasury", 0.0)),
			failed_fx_before["india"]
		)
		and _approx_equal(
			float(china_economy.get_state("treasury", 0.0)),
			failed_fx_before["china"]
		)
	)

	_log_result(
		"Failed FX cannot mutate treasury balances or create a settlement",
		failed_fx_no_transfer
	)

	var snapshot := transaction.to_snapshot_dict()

	var snapshot_ok := (
		snapshot.has("monetary_invariants_checked")
		and snapshot.has("monetary_invariants_passed")
		and snapshot.has("monetary_invariant_status")
		and snapshot.has("monetary_invariant_errors")
		and snapshot.has("monetary_invariant_ledger")
		and bool(
			snapshot.get(
				"monetary_invariants_passed",
				false
			)
		)
		and str(
			snapshot.get(
				"monetary_invariant_status",
				""
			)
		) == "pass"
	)

	_log_result(
		"Monetary invariant state survives transaction snapshot representation",
		snapshot_ok
	)

	# Restore fixtures and original country state.
	for fixture_id in [
		agreement_id,
		fx_agreement_id,
		failed_fx_agreement_id
	]:
		world.trade_agreements.erase(fixture_id)

	for fixture_id in [
		route_id,
		fx_route_id,
		failed_fx_route_id
	]:
		world.trade_routes.erase(fixture_id)

	for fixture_id in [
		transaction_id,
		fx_transaction_id,
		failed_fx_transaction_id
	]:
		world.trade_transactions.erase(fixture_id)

	china_resources.set_state(
		"current_price",
		original_prices
	)
	china_economy.set_state(
		"treasury",
		original_china_treasury
	)
	india_economy.set_state(
		"treasury",
		original_india_treasury
	)

	var all_passed := (
		systems_ok
		and components_ok
		and registered
		and valuation_ok
		and conversion_ok
		and affordability_ok
		and settled
		and balance_transfer_ok
		and invariant_status_ok
		and settlement_ledger_ok
		and base_value_conservation_ok
		and invariant_rerun_balance_ok
		and settlement_idempotence_ok
		and fx_registered
		and fx_balance_unchanged
		and failed_fx_registered
		and failed_fx_no_transfer
		and snapshot_ok
	)

	TestLogger.write_line(
		"Monetary Invariants 6.6 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
