class_name PaymentAffordabilitySystem
extends SimulationSystem


const STATUS_PENDING := "pending"
const STATUS_AFFORDABLE := "affordable"
const STATUS_INSUFFICIENT_FUNDS := "insufficient_funds"
const STATUS_DEFERRED_FX := "deferred_fx"
const STATUS_ZERO_DELIVERY := "zero_delivery"
const STATUS_INVALID := "invalid"


func _init() -> void:
	super("payment_affordability_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("PaymentAffordabilitySystem: World is null.")
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

		_evaluate_affordability(world, transaction)


func _evaluate_affordability(
	world: WorldState,
	transaction: TradeTransaction
) -> void:
	var importer = world.get_entity(transaction.importer_id)

	if importer == null:
		_mark_invalid(
			transaction,
			"missing_importer"
		)
		return

	var importer_economy = importer.get_component("economy")

	if importer_economy == null:
		_mark_invalid(
			transaction,
			"missing_importer_economy_component"
		)
		return

	transaction.affordability_checked = false
	transaction.affordability_required_payment = maxf(
		float(transaction.trade_value),
		0.0
	)

	# Step 6.5 supplies the payer-currency amount when FX is available.
	if transaction.conversion_status in [
		"converted",
		"same_currency"
	]:
		transaction.affordability_required_payment = maxf(
			float(transaction.payer_payment_amount),
			0.0
		)
	transaction.affordability_available_balance = float(
		importer_economy.get_state(
			"treasury",
			0.0
		)
	)
	transaction.affordability_shortfall = 0.0
	transaction.affordability_max_quantity = 0.0

	var payer_currency_id: String = str(
		importer_economy.get_state(
			"currency_id",
			""
		)
	)

	if transaction.valuation_status == "zero_delivery":
		transaction.affordable = true
		transaction.affordability_status = STATUS_ZERO_DELIVERY
		transaction.affordability_ledger = {
			"checked": true,
			"status": STATUS_ZERO_DELIVERY,
			"required_payment": 0.0,
			"available_balance": transaction.affordability_available_balance,
			"shortfall": 0.0,
			"max_affordable_quantity": 0.0,
			"payer_currency_id": payer_currency_id,
			"settlement_currency_id": transaction.valuation_currency_id,
			"fx_required": false
		}
		return

	if transaction.valuation_status != "valued":
		transaction.affordable = false
		transaction.affordability_status = STATUS_INVALID
		transaction.affordability_ledger = {
			"checked": true,
			"status": STATUS_INVALID,
			"reason": "missing_trade_valuation",
			"valuation_status": transaction.valuation_status,
			"required_payment": transaction.affordability_required_payment
		}
		return

	if payer_currency_id.is_empty() or transaction.valuation_currency_id.is_empty():
		_mark_invalid(
			transaction,
			"missing_currency_identity"
		)
		return

	# Cross-currency affordability is deferred only when 6.5 has not
	# produced a usable conversion state. Do not invent a 1:1 rate.
	if payer_currency_id != transaction.valuation_currency_id:
		if transaction.conversion_status != "converted":
			transaction.affordable = false
			transaction.affordability_status = STATUS_DEFERRED_FX
			transaction.affordability_ledger = {
				"checked": false,
				"status": STATUS_DEFERRED_FX,
				"reason": "currency_conversion_required",
				"required_payment": transaction.affordability_required_payment,
				"available_balance": transaction.affordability_available_balance,
				"shortfall": 0.0,
				"payer_currency_id": payer_currency_id,
				"settlement_currency_id": transaction.valuation_currency_id,
				"fx_required": true
			}
			return

	# At this point the payment amount is expressed in the payer's
	# currency, either because currencies match or because Step 6.5
	# supplied a valid conversion. Affordability is now actually evaluated.
	transaction.affordability_checked = true

	var required_payment: float = transaction.affordability_required_payment
	var available_balance: float = transaction.affordability_available_balance

	transaction.affordability_max_quantity = _max_affordable_quantity(
		transaction,
		available_balance
	)

	if required_payment <= available_balance:
		transaction.affordable = true
		transaction.affordability_status = STATUS_AFFORDABLE
	else:
		transaction.affordable = false
		transaction.affordability_status = STATUS_INSUFFICIENT_FUNDS
		transaction.affordability_shortfall = (
			required_payment - available_balance
		)

	transaction.affordability_ledger = {
		"checked": true,
		"status": transaction.affordability_status,
		"required_payment": required_payment,
		"available_balance": available_balance,
		"shortfall": transaction.affordability_shortfall,
		"max_affordable_quantity": transaction.affordability_max_quantity,
		"payer_currency_id": payer_currency_id,
		"settlement_currency_id": transaction.valuation_currency_id,
		"fx_required": false
	}


func _max_affordable_quantity(
	transaction: TradeTransaction,
	available_balance: float
) -> float:
	var unit_price: float = maxf(
		float(transaction.valuation_unit_price),
		0.0
	)

	if transaction.conversion_status in [
		"converted",
		"same_currency"
	]:
		unit_price = maxf(
			unit_price * maxf(
				float(transaction.fx_rate),
				1.0
			),
			0.0
		)
	var requested_quantity: float = maxf(
		float(transaction.valuation_quantity),
		0.0
	)

	if unit_price <= 0.0:
		return requested_quantity

	return clampf(
		available_balance / unit_price,
		0.0,
		requested_quantity
	)


func _mark_invalid(
	transaction: TradeTransaction,
	reason: String
) -> void:
	transaction.affordability_checked = true
	transaction.affordable = false
	transaction.affordability_status = STATUS_INVALID
	transaction.affordability_shortfall = 0.0
	transaction.affordability_ledger = {
		"checked": true,
		"status": STATUS_INVALID,
		"reason": reason
	}


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
