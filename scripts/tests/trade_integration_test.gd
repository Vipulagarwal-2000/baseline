class_name TradeIntegrationTest
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
		"TRADE INTEGRATION TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World / Simulation available: FAIL")
		return false

	TestLogger.write_line("World / Simulation available: PASS")

	var trade_system = simulation.get_system(
		"trade_system"
	)
	var resource_system = simulation.get_system(
		"resource_system"
	)
	var currency_identity_system = simulation.get_system(
		"currency_identity_system"
	)
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
		trade_system != null
		and trade_system is TradeSystem
		and resource_system != null
		and resource_system is ResourceSystem
		and currency_identity_system != null
		and currency_identity_system is CurrencyIdentitySystem
		and valuation_system != null
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
		"Physical trade and full 6.1–6.6 financial chain systems available",
		systems_ok
	)

	if not systems_ok:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	var china_resources = (
		china.get_component("resources")
		if china != null
		else null
	)
	var india_resources = (
		india.get_component("resources")
		if india != null
		else null
	)
	var china_infrastructure = (
		china.get_component("infrastructure")
		if china != null
		else null
	)
	var india_infrastructure = (
		india.get_component("infrastructure")
		if india != null
		else null
	)
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

	var components_ok := (
		china != null
		and india != null
		and china_resources != null
		and india_resources != null
		and china_infrastructure != null
		and india_infrastructure != null
		and china_economy != null
		and india_economy != null
	)

	_log_result(
		"China and India physical/financial components available",
		components_ok
	)

	if not components_ok:
		return false

	var execution_date: Dictionary = (
		world.current_date.duplicate(true)
	)

	const agreement_id := "test_trade_agreement_6_7_integration"
	const route_id := "test_trade_route_6_7_integration"

	# The exporter has 10 units, but the route can physically carry only
	# 8. This forces the financial layer to value the actual delivered
	# quantity rather than the requested quantity.
	const requested_quantity := 15.0
	const exporter_stockpile := 10.0
	const route_throughput := 8.0
	const unit_price := 20.0
	const expected_imported_quantity := 8.0
	const expected_trade_value := 160.0
	const expected_fx_rate := 4.0
	const expected_payer_payment := 640.0

	var original_china_stockpile: Dictionary = (
		china_resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)
	var original_india_stockpile: Dictionary = (
		india_resources.get_state(
			"stockpile",
			{}
		).duplicate(true)
	)
	var original_china_prices: Dictionary = (
		china_resources.get_state(
			"current_price",
			{}
		).duplicate(true)
	)
	var original_china_imports: Dictionary = (
		china_resources.get_state(
			"imports",
			{}
		).duplicate(true)
	)
	var original_china_exports: Dictionary = (
		china_resources.get_state(
			"exports",
			{}
		).duplicate(true)
	)
	var original_china_trade_imports: Dictionary = (
		china_resources.get_state(
			"trade_imports",
			{}
		).duplicate(true)
	)
	var original_china_trade_exports: Dictionary = (
		china_resources.get_state(
			"trade_exports",
			{}
		).duplicate(true)
	)
	var original_india_imports: Dictionary = (
		india_resources.get_state(
			"imports",
			{}
		).duplicate(true)
	)
	var original_india_exports: Dictionary = (
		india_resources.get_state(
			"exports",
			{}
		).duplicate(true)
	)
	var original_india_trade_imports: Dictionary = (
		india_resources.get_state(
			"trade_imports",
			{}
		).duplicate(true)
	)
	var original_india_trade_exports: Dictionary = (
		india_resources.get_state(
			"trade_exports",
			{}
		).duplicate(true)
	)
	var original_china_ports := float(
		china_infrastructure.get_state("ports", 1.0)
	)
	var original_china_transport := float(
		china_infrastructure.get_state("transport", 1.0)
	)
	var original_china_roads := float(
		china_infrastructure.get_state("roads", 1.0)
	)
	var original_china_railways := float(
		china_infrastructure.get_state("railways", 1.0)
	)
	var original_india_ports := float(
		india_infrastructure.get_state("ports", 1.0)
	)
	var original_india_transport := float(
		india_infrastructure.get_state("transport", 1.0)
	)
	var original_india_roads := float(
		india_infrastructure.get_state("roads", 1.0)
	)
	var original_india_railways := float(
		india_infrastructure.get_state("railways", 1.0)
	)
	var original_china_treasury := float(
		china_economy.get_state("treasury", 0.0)
	)
	var original_india_treasury := float(
		india_economy.get_state("treasury", 0.0)
	)

	# Controlled fixture setup. Only the trade-specific resource and
	# treasury states are altered; the authoritative systems remain intact.
	china_resources.set_state(
		"stockpile",
		{"iron": exporter_stockpile}
	)
	india_resources.set_state(
		"stockpile",
		{"iron": 0.0}
	)
	china_resources.set_state(
		"current_price",
		{"iron": unit_price}
	)

	china_infrastructure.set_state("ports", 1.0)
	china_infrastructure.set_state("transport", 1.0)
	china_infrastructure.set_state("roads", 1.0)
	china_infrastructure.set_state("railways", 1.0)

	india_infrastructure.set_state("ports", 1.0)
	india_infrastructure.set_state("transport", 1.0)
	india_infrastructure.set_state("roads", 1.0)
	india_infrastructure.set_state("railways", 1.0)

	china_economy.set_state("treasury", 500.0)
	india_economy.set_state("treasury", 1500.0)

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"iron",
		requested_quantity,
		2
	)
	agreement.activate(execution_date)

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		route_throughput
	)
	route.activate()

	var registered := (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
	)

	_log_result(
		"Real physical trade agreement/route registration",
		registered
	)

	if not registered:
		return false

	# ------------------------------------------------------------
	# Physical trade layer: TradeSystem.
	# ------------------------------------------------------------
	(trade_system as TradeSystem).process_month(world)

	var transaction_id := (
		"trade_transaction_"
		+ str(int(execution_date.get("year", 0)))
		+ "_"
		+ str(int(execution_date.get("month", 0)))
		+ "_"
		+ agreement_id
		+ "_"
		+ route_id
	)

	var transaction = world.get_trade_transaction(
		transaction_id
	)

	var transaction_created := (
		transaction != null
		and transaction is TradeTransaction
	)

	_log_result(
		"TradeSystem creates the real monthly TradeTransaction",
		transaction_created
	)

	if not transaction_created:
		return false

	var physical_resolution_ok: bool = (
		_approx_equal(
			float(transaction.requested_quantity),
			requested_quantity
		)
		and _approx_equal(
			float(transaction.actual_exported_quantity),
			expected_imported_quantity
		)
		and _approx_equal(
			float(transaction.actual_imported_quantity),
			expected_imported_quantity
		)
		and _approx_equal(
			float(transaction.executed_quantity),
			expected_imported_quantity
		)
		and transaction.status == TradeTransaction.STATUS_UNFULFILLED
		and _approx_equal(
			float(transaction.unfulfilled_quantity),
			requested_quantity - expected_imported_quantity
		)
	)

	_log_result(
		"Physical trade resolves actual delivery before financial processing",
		physical_resolution_ok
	)

	var trade_flow_ok: bool = (
		_approx_equal(
			float(
				china_resources.get_state(
					"trade_exports",
					{}
				).get("iron", 0.0)
			),
			expected_imported_quantity
		)
		and _approx_equal(
			float(
				india_resources.get_state(
					"trade_imports",
					{}
				).get("iron", 0.0)
			),
			expected_imported_quantity
		)
	)

	_log_result(
		"Physical trade writes the resolved quantity to ResourceSystem trade flows",
		trade_flow_ok
	)

	# ResourceSystem is the authoritative physical settlement layer.
	(resource_system as ResourceSystem).process_month(world)

	var physical_settlement_state_ok: bool = (
		transaction.actual_imported_quantity
		== expected_imported_quantity
		and not transaction.payment_settled
	)

	_log_result(
		"ResourceSystem settles physical trade without prematurely settling payment",
		physical_settlement_state_ok
	)

	# ------------------------------------------------------------
	# Financial chain: identity -> valuation -> FX -> affordability
	# -> payment -> invariants.
	# ------------------------------------------------------------
	(currency_identity_system as CurrencyIdentitySystem).process_month(
		world
	)
	(valuation_system as TradeValuationSystem).process_month(world)

	var valuation_ok: bool = (
		transaction.valuation_status == "valued"
		and _approx_equal(
			transaction.valuation_quantity,
			expected_imported_quantity
		)
		and _approx_equal(
			transaction.valuation_unit_price,
			unit_price
		)
		and _approx_equal(
			transaction.trade_value,
			expected_trade_value
		)
		and transaction.valuation_currency_id == "CNY"
	)

	_log_result(
		"Trade valuation uses actual imported quantity and exporter price",
		valuation_ok
	)

	(conversion_system as CurrencyConversionSystem).process_month(world)

	var conversion_ok: bool = (
		transaction.conversion_status == "converted"
		and transaction.fx_source_currency_id == "CNY"
		and transaction.fx_target_currency_id == "INR"
		and _approx_equal(
			transaction.fx_rate,
			expected_fx_rate
		)
		and _approx_equal(
			transaction.receiver_payment_amount,
			expected_trade_value
		)
		and _approx_equal(
			transaction.payer_payment_amount,
			expected_payer_payment
		)
	)

	_log_result(
		"Trade valuation flows through fixed FX into payer-currency amount",
		conversion_ok
	)

	(affordability_system as PaymentAffordabilitySystem).process_month(
		world
	)

	var affordability_ok: bool = (
		transaction.affordability_checked
		and transaction.affordable
		and transaction.affordability_status == "affordable"
		and _approx_equal(
			transaction.affordability_required_payment,
			expected_payer_payment
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
		"Actual trade reaches affordability using payer-currency value",
		affordability_ok
	)

	(payment_system as TradePaymentSystem).process_month(world)

	var payment_ok: bool = (
		transaction.payment_settled
		and transaction.payment_status == "settled"
		and transaction.settlement_status == "settled"
		and _approx_equal(
			transaction.payer_payment_amount,
			expected_payer_payment
		)
		and _approx_equal(
			transaction.receiver_payment_amount,
			expected_trade_value
		)
		and _approx_equal(
			float(
				india_economy.get_state(
					"treasury",
					0.0
				)
			),
			860.0
		)
		and _approx_equal(
			float(
				china_economy.get_state(
					"treasury",
					0.0
				)
			),
			660.0
		)
	)

	_log_result(
		"Actual physical trade reaches monetary settlement with correct balances",
		payment_ok
	)

	(invariant_system as MonetaryInvariantSystem).process_month(world)

	var invariant_ok: bool = (
		transaction.monetary_invariants_checked
		and transaction.monetary_invariants_passed
		and transaction.monetary_invariant_status == "pass"
		and transaction.monetary_invariant_errors.is_empty()
	)

	_log_result(
		"Integrated trade transaction passes monetary invariants",
		invariant_ok
	)

	var end_to_end_ok: bool = (
		transaction.actual_imported_quantity
		== expected_imported_quantity
		and transaction.valuation_quantity
		== expected_imported_quantity
		and _approx_equal(
			transaction.trade_value,
			expected_trade_value
		)
		and _approx_equal(
			transaction.payer_payment_amount,
			expected_payer_payment
		)
		and transaction.affordability_status == "affordable"
		and transaction.payment_settled
	)

	_log_result(
		"Physical trade -> valuation -> FX -> affordability -> payment chain closes end-to-end",
		end_to_end_ok
	)

	# Same-date repeated execution must not create a second trade transaction
	# or transfer a second payment.
	var india_after_first_settlement := float(
		india_economy.get_state("treasury", 0.0)
	)
	var china_after_first_settlement := float(
		china_economy.get_state("treasury", 0.0)
	)

	(trade_system as TradeSystem).process_month(world)
	(currency_identity_system as CurrencyIdentitySystem).process_month(
		world
	)
	(valuation_system as TradeValuationSystem).process_month(world)
	(conversion_system as CurrencyConversionSystem).process_month(world)
	(affordability_system as PaymentAffordabilitySystem).process_month(
		world
	)
	(payment_system as TradePaymentSystem).process_month(world)
	(invariant_system as MonetaryInvariantSystem).process_month(
		world
	)

	var repeat_safe: bool = (
		world.has_trade_transaction(transaction_id)
		and _approx_equal(
			float(
				india_economy.get_state(
					"treasury",
					0.0
				)
			),
			india_after_first_settlement
		)
		and _approx_equal(
			float(
				china_economy.get_state(
					"treasury",
					0.0
				)
			),
			china_after_first_settlement
		)
	)

	_log_result(
		"Repeated same-date trade processing does not duplicate physical or monetary settlement",
		repeat_safe
	)

	var snapshot :Dictionary= transaction.to_snapshot_dict()

	var snapshot_ok: bool = (
		snapshot.has("actual_imported_quantity")
		and snapshot.has("valuation_quantity")
		and snapshot.has("trade_value")
		and snapshot.has("fx_rate")
		and snapshot.has("payer_payment_amount")
		and snapshot.has("affordability_status")
		and snapshot.has("payment_settled")
		and snapshot.has("monetary_invariant_status")
		and _approx_equal(
			float(
				snapshot.get(
					"actual_imported_quantity",
					-1.0
				)
			),
			expected_imported_quantity
		)
		and _approx_equal(
			float(
				snapshot.get(
					"trade_value",
					-1.0
				)
			),
			expected_trade_value
		)
		and bool(
			snapshot.get(
				"payment_settled",
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
		"Integrated trade financial state survives transaction snapshot representation",
		snapshot_ok
	)

	# Restore fixture state.
	world.remove_trade_transaction(transaction_id)
	world.remove_trade_route(route_id)
	world.remove_trade_agreement(agreement_id)

	china_resources.set_state(
		"stockpile",
		original_china_stockpile
	)
	india_resources.set_state(
		"stockpile",
		original_india_stockpile
	)
	china_resources.set_state(
		"current_price",
		original_china_prices
	)
	china_resources.set_state(
		"imports",
		original_china_imports
	)
	china_resources.set_state(
		"exports",
		original_china_exports
	)
	china_resources.set_state(
		"trade_imports",
		original_china_trade_imports
	)
	china_resources.set_state(
		"trade_exports",
		original_china_trade_exports
	)
	india_resources.set_state(
		"imports",
		original_india_imports
	)
	india_resources.set_state(
		"exports",
		original_india_exports
	)
	india_resources.set_state(
		"trade_imports",
		original_india_trade_imports
	)
	india_resources.set_state(
		"trade_exports",
		original_india_trade_exports
	)

	china_infrastructure.set_state(
		"ports",
		original_china_ports
	)
	china_infrastructure.set_state(
		"transport",
		original_china_transport
	)
	china_infrastructure.set_state(
		"roads",
		original_china_roads
	)
	china_infrastructure.set_state(
		"railways",
		original_china_railways
	)
	india_infrastructure.set_state(
		"ports",
		original_india_ports
	)
	india_infrastructure.set_state(
		"transport",
		original_india_transport
	)
	india_infrastructure.set_state(
		"roads",
		original_india_roads
	)
	india_infrastructure.set_state(
		"railways",
		original_india_railways
	)

	china_economy.set_state(
		"treasury",
		original_china_treasury
	)
	india_economy.set_state(
		"treasury",
		original_india_treasury
	)

	var all_passed: bool = (
		systems_ok
		and components_ok
		and registered
		and transaction_created
		and physical_resolution_ok
		and trade_flow_ok
		and physical_settlement_state_ok
		and valuation_ok
		and conversion_ok
		and affordability_ok
		and payment_ok
		and invariant_ok
		and end_to_end_ok
		and repeat_safe
		and snapshot_ok
	)

	TestLogger.write_line(
		"Trade Integration 6.7 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
