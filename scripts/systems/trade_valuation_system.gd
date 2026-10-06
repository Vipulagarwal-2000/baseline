class_name TradeValuationSystem
extends SimulationSystem


const EPSILON := 0.0000001
const VALUATION_STATUS_VALUED := "valued"
const VALUATION_STATUS_ZERO_DELIVERY := "zero_delivery"
const VALUATION_STATUS_UNPRICED := "unpriced"
const VALUATION_STATUS_INVALID := "invalid"


func _init() -> void:
	super("trade_valuation_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("TradeValuationSystem: World is null.")
		return

	var transaction_ids: Array = world.trade_transactions.keys()
	transaction_ids.sort()

	for transaction_id in transaction_ids:
		var transaction = world.get_trade_transaction(transaction_id)

		if transaction == null:
			continue

		if not transaction is TradeTransaction:
			continue

		if transaction.valuation_status in [
			VALUATION_STATUS_VALUED,
			VALUATION_STATUS_ZERO_DELIVERY
		]:
			continue

		if not _is_current_month_transaction(world, transaction):
			continue

		_value_transaction(world, transaction)


func _value_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> void:
	var exporter = world.get_entity(transaction.exporter_id)

	if exporter == null:
		transaction.valuation_status = VALUATION_STATUS_INVALID
		transaction.valuation_ledger = {
			"valued": false,
			"reason": "missing_exporter"
		}
		return

	var exporter_economy = exporter.get_component("economy")
	var exporter_resources = exporter.get_component("resources")

	if exporter_economy == null:
		transaction.valuation_status = VALUATION_STATUS_INVALID
		transaction.valuation_ledger = {
			"valued": false,
			"reason": "missing_exporter_economy_component"
		}
		return

	if exporter_resources == null:
		transaction.valuation_status = VALUATION_STATUS_UNPRICED
		transaction.valuation_ledger = {
			"valued": false,
			"reason": "missing_exporter_resources_component"
		}
		return

	var currency_id: String = str(
		exporter_economy.get_state("currency_id", "")
	)

	if currency_id.is_empty():
		transaction.valuation_status = VALUATION_STATUS_INVALID
		transaction.valuation_ledger = {
			"valued": false,
			"reason": "missing_exporter_currency_identity"
		}
		return

	var imported_quantity: float = maxf(
		float(transaction.actual_imported_quantity),
		0.0
	)

	transaction.valuation_quantity = imported_quantity
	transaction.valuation_currency_id = currency_id

	if imported_quantity <= EPSILON:
		transaction.valuation_unit_price = 0.0
		transaction.trade_value = 0.0
		transaction.valuation_status = VALUATION_STATUS_ZERO_DELIVERY
		transaction.valuation_ledger = {
			"valued": true,
			"status": VALUATION_STATUS_ZERO_DELIVERY,
			"exporter_id": transaction.exporter_id,
			"importer_id": transaction.importer_id,
			"resource_id": transaction.resource_id,
			"quantity": 0.0,
			"unit_price": 0.0,
			"currency_id": currency_id,
			"trade_value": 0.0
		}
		return

	var current_prices: Dictionary = exporter_resources.get_state(
		"current_price",
		{}
	)

	var unit_price: float = float(
		current_prices.get(
			transaction.resource_id,
			-1.0
		)
	)

	if unit_price < 0.0:
		transaction.valuation_status = VALUATION_STATUS_UNPRICED
		transaction.valuation_ledger = {
			"valued": false,
			"reason": "missing_current_price",
			"resource_id": transaction.resource_id,
			"currency_id": currency_id
		}
		return

	unit_price = maxf(unit_price, 0.0)

	var trade_value: float = maxf(
		imported_quantity * unit_price,
		0.0
	)

	transaction.valuation_unit_price = unit_price
	transaction.trade_value = trade_value
	transaction.valuation_status = VALUATION_STATUS_VALUED
	transaction.valuation_ledger = {
		"valued": true,
		"status": VALUATION_STATUS_VALUED,
		"exporter_id": transaction.exporter_id,
		"importer_id": transaction.importer_id,
		"resource_id": transaction.resource_id,
		"quantity": imported_quantity,
		"unit_price": unit_price,
		"currency_id": currency_id,
		"trade_value": trade_value
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
