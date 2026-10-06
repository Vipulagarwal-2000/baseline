class_name TradePaymentSystem
extends SimulationSystem


const PAYMENT_STATUS_SETTLED := "settled"
const PAYMENT_STATUS_ZERO_DELIVERY := "zero_delivery"
const PAYMENT_STATUS_UNPRICED := "unpriced"
const PAYMENT_STATUS_INVALID := "invalid"
const PAYMENT_STATUS_INSUFFICIENT_FUNDS := "insufficient_funds"


func _init() -> void:
	super("trade_payment_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("TradePaymentSystem: World is null.")
		return

	var transaction_ids: Array = world.trade_transactions.keys()
	transaction_ids.sort()

	for transaction_id in transaction_ids:
		var transaction = world.get_trade_transaction(transaction_id)

		if transaction == null:
			continue

		if not transaction is TradeTransaction:
			continue

		if transaction.payment_settled:
			continue

		if not _is_current_month_transaction(world, transaction):
			continue

		_settle_transaction(world, transaction)


func _settle_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> void:
	var exporter = world.get_entity(transaction.exporter_id)
	var importer = world.get_entity(transaction.importer_id)

	if exporter == null or importer == null:
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_ledger = {
			"settled": false,
			"reason": "missing_counterparty"
		}
		return

	var importer_economy = importer.get_component("economy")
	var exporter_economy = exporter.get_component("economy")

	if importer_economy == null or exporter_economy == null:
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_ledger = {
			"settled": false,
			"reason": "missing_economy_component"
		}
		return

	# Step 6.2 is now the authoritative valuation stage. Payment settlement
	# consumes that result rather than recomputing the price.
	# Step 6.3 — settlement consumes the already-completed valuation.
	# It does not recalculate price, quantity, or FX.
	var payer_currency_id: String = str(
		importer_economy.get_state("currency_id", "")
	)
	var receiver_currency_id: String = str(
		exporter_economy.get_state("currency_id", "")
	)

	if payer_currency_id.is_empty() or receiver_currency_id.is_empty():
		transaction.settlement_status = PAYMENT_STATUS_INVALID
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.settlement_ledger = {
			"settled": false,
			"reason": "missing_currency_identity",
			"payer_currency_id": payer_currency_id,
			"receiver_currency_id": receiver_currency_id
		}
		transaction.payment_ledger = transaction.settlement_ledger.duplicate(true)
		return

	# Step 6.4 — an evaluated affordability failure blocks monetary
	# settlement. Cross-currency affordability is explicitly deferred to
	# the later FX step rather than inventing a 1:1 conversion rate.
	if transaction.affordability_status == "insufficient_funds":
		transaction.payment_status = PAYMENT_STATUS_INSUFFICIENT_FUNDS
		transaction.payment_settled = false
		transaction.payment_ledger = {
			"settled": false,
			"status": PAYMENT_STATUS_INSUFFICIENT_FUNDS,
			"reason": "payment_affordability_failed",
			"required_payment": transaction.affordability_required_payment,
			"available_balance": transaction.affordability_available_balance,
			"shortfall": transaction.affordability_shortfall,
			"currency_id": transaction.valuation_currency_id
		}
		transaction.settlement_status = "insufficient_funds"
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	if transaction.affordability_status == "invalid":
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_settled = false
		transaction.payment_ledger = {
			"settled": false,
			"status": "invalid",
			"reason": "payment_affordability_invalid"
		}
		transaction.settlement_status = "invalid"
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	if transaction.affordability_status == "deferred_fx":
		# 6.5 must provide a converted payer-side amount before a real
		# cross-currency settlement can occur.
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_settled = false
		transaction.payment_ledger = {
			"settled": false,
			"status": "deferred_fx",
			"reason": "currency_conversion_required"
		}
		transaction.settlement_status = "deferred_fx"
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	var legacy_nominal_settlement: bool = (
		transaction.conversion_status == "pending"
	)

	if transaction.conversion_status not in [
		"converted",
		"same_currency",
		"zero_delivery",
		"pending"
	]:
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_settled = false
		transaction.payment_ledger = {
			"settled": false,
			"status": "invalid",
			"reason": "missing_currency_conversion",
			"conversion_status": transaction.conversion_status
		}
		transaction.settlement_status = "invalid"
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	if transaction.valuation_status == "zero_delivery":
		transaction.settlement_currency_id = transaction.valuation_currency_id
		transaction.payer_currency_id = payer_currency_id
		transaction.receiver_currency_id = receiver_currency_id
		transaction.payment_quantity = 0.0
		transaction.payment_unit_price = 0.0
		transaction.trade_payment = 0.0
		transaction.transaction_cost = 0.0
		transaction.settlement_status = PAYMENT_STATUS_ZERO_DELIVERY
		transaction.payment_status = PAYMENT_STATUS_ZERO_DELIVERY
		transaction.payment_settled = true

		var zero_ledger := {
			"settled": true,
			"status": PAYMENT_STATUS_ZERO_DELIVERY,
			"payer_id": transaction.importer_id,
			"receiver_id": transaction.exporter_id,
			"resource_id": transaction.resource_id,
			"quantity": 0.0,
			"unit_price": 0.0,
			"payment": 0.0,
			"settlement_currency_id": transaction.valuation_currency_id,
			"payer_currency_id": payer_currency_id,
			"receiver_currency_id": receiver_currency_id,
			"fx_applied": false if legacy_nominal_settlement else transaction.fx_applied,
		"fx_rate": 1.0 if legacy_nominal_settlement else transaction.fx_rate,
			"importer_treasury_before": float(
				importer_economy.get_state("treasury", 0.0)
			),
			"importer_treasury_after": float(
				importer_economy.get_state("treasury", 0.0)
			),
			"exporter_treasury_before": float(
				exporter_economy.get_state("treasury", 0.0)
			),
			"exporter_treasury_after": float(
				exporter_economy.get_state("treasury", 0.0)
			)
		}

		transaction.settlement_ledger = zero_ledger
		transaction.payment_ledger = zero_ledger.duplicate(true)
		return

	if transaction.valuation_status != "valued":
		transaction.settlement_status = PAYMENT_STATUS_UNPRICED
		transaction.payment_status = PAYMENT_STATUS_UNPRICED
		transaction.payment_ledger = {
			"settled": false,
			"reason": "missing_trade_valuation",
			"valuation_status": transaction.valuation_status
		}
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	if transaction.valuation_currency_id.is_empty():
		transaction.settlement_status = PAYMENT_STATUS_INVALID
		transaction.payment_status = PAYMENT_STATUS_INVALID
		transaction.payment_ledger = {
			"settled": false,
			"reason": "missing_valuation_currency"
		}
		transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)
		return

	var payment_quantity: float = maxf(
		float(transaction.valuation_quantity),
		0.0
	)
	var unit_price: float = maxf(
		float(transaction.valuation_unit_price),
		0.0
	)
	var receiver_payment: float = maxf(
		float(transaction.receiver_payment_amount),
		0.0
	)

	if receiver_payment <= 0.0 and transaction.valuation_status == "valued":
		receiver_payment = maxf(
			float(transaction.trade_value),
			0.0
		)

	var payer_payment: float = maxf(
		float(transaction.payer_payment_amount),
		0.0
	)

	if transaction.conversion_status == "same_currency" and payer_payment <= 0.0:
		payer_payment = receiver_payment

	# Preserve the validated 5.11/6.3 direct-test path when those tests invoke
	# TradePaymentSystem without running the new FX system first.
	if legacy_nominal_settlement:
		payer_payment = receiver_payment

	transaction.payment_quantity = payment_quantity
	transaction.payment_unit_price = unit_price

	var importer_treasury_before: float = float(
		importer_economy.get_state("treasury", 0.0)
	)
	var exporter_treasury_before: float = float(
		exporter_economy.get_state("treasury", 0.0)
	)

	var importer_treasury_after: float = (
		importer_treasury_before - payer_payment
	)
	var exporter_treasury_after: float = (
		exporter_treasury_before + receiver_payment
	)

	# The payer is debited in its own currency; the receiver is credited
	# in the valuation/exporter currency. Step 6.5 supplies the fixed/simple
	# conversion between the two when they differ.
	importer_economy.set_state(
		"treasury",
		importer_treasury_after
	)
	exporter_economy.set_state(
		"treasury",
		exporter_treasury_after
	)

	transaction.settlement_currency_id = transaction.valuation_currency_id
	transaction.payer_currency_id = payer_currency_id
	transaction.receiver_currency_id = receiver_currency_id
	transaction.settlement_status = PAYMENT_STATUS_SETTLED

	transaction.trade_payment = receiver_payment
	transaction.transaction_cost = payer_payment
	transaction.payment_status = PAYMENT_STATUS_SETTLED
	transaction.payment_settled = true
	transaction.payment_ledger = {
		"settled": true,
		"status": PAYMENT_STATUS_SETTLED,
		"payer_id": transaction.importer_id,
		"receiver_id": transaction.exporter_id,
		"resource_id": transaction.resource_id,
		"quantity": payment_quantity,
		"unit_price": unit_price,
		"payment": receiver_payment,
		"payer_payment_amount": payer_payment,
		"receiver_payment_amount": receiver_payment,
		"payment_currency_id": transaction.payment_currency_id,
		"currency_id": transaction.valuation_currency_id,
		"settlement_currency_id": transaction.settlement_currency_id,
		"payer_currency_id": transaction.payer_currency_id,
		"receiver_currency_id": transaction.receiver_currency_id,
		"fx_applied": false if legacy_nominal_settlement else transaction.fx_applied,
		"fx_rate": 1.0 if legacy_nominal_settlement else transaction.fx_rate,
		"importer_treasury_before": importer_treasury_before,
		"importer_treasury_after": importer_treasury_after,
		"exporter_treasury_before": exporter_treasury_before,
		"exporter_treasury_after": exporter_treasury_after,
		"payer_treasury_delta": (
			importer_treasury_before - importer_treasury_after
		),
		"receiver_treasury_delta": (
			exporter_treasury_after - exporter_treasury_before
		)
	}

	transaction.settlement_ledger = transaction.payment_ledger.duplicate(true)


func _is_current_month_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> bool:
	return (
		int(world.current_date.get("year", 0))
		== int(transaction.execution_date.get("year", -1))
		and
		int(world.current_date.get("month", 0))
		== int(transaction.execution_date.get("month", -1))
	)
