class_name CurrencyConversionSystem
extends SimulationSystem


const STATUS_PENDING := "pending"
const STATUS_CONVERTED := "converted"
const STATUS_SAME_CURRENCY := "same_currency"
const STATUS_ZERO_DELIVERY := "zero_delivery"
const STATUS_MISSING_RATE := "missing_rate"
const STATUS_INVALID := "invalid"

const FX_DATA_PATH := "res://data/currency_exchange_rates.json"
const EPSILON := 0.0000001


var base_currency_id: String = ""
var rates_to_base: Dictionary = {}


func _init() -> void:
	super("currency_conversion_system")
	_load_rates()


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("CurrencyConversionSystem: World is null.")
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

		if transaction.conversion_status in [
			STATUS_CONVERTED,
			STATUS_SAME_CURRENCY,
			STATUS_ZERO_DELIVERY
		]:
			continue

		_convert_transaction(world, transaction)


func _load_rates() -> void:
	base_currency_id = ""
	rates_to_base = {}

	if not FileAccess.file_exists(FX_DATA_PATH):
		push_error(
			"CurrencyConversionSystem: FX data file missing: "
			+ FX_DATA_PATH
		)
		return

	var file := FileAccess.open(FX_DATA_PATH, FileAccess.READ)

	if file == null:
		push_error(
			"CurrencyConversionSystem: Could not open FX data file."
		)
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(
			"CurrencyConversionSystem: FX data root must be a dictionary."
		)
		return

	base_currency_id = str(
		parsed.get("base_currency", "")
	)

	var raw_rates = parsed.get(
		"rates_to_base",
		{}
	)

	if typeof(raw_rates) != TYPE_DICTIONARY:
		push_error(
			"CurrencyConversionSystem: rates_to_base must be a dictionary."
		)
		base_currency_id = ""
		return

	for key in raw_rates.keys():
		var rate := float(raw_rates[key])

		if rate <= 0.0:
			continue

		rates_to_base[str(key)] = rate

	if base_currency_id.is_empty():
		push_error(
			"CurrencyConversionSystem: Base currency is missing."
	)


func _convert_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> void:
	if transaction.valuation_status == "zero_delivery":
		transaction.conversion_status = STATUS_ZERO_DELIVERY
		transaction.conversion_checked = true
		transaction.payer_payment_amount = 0.0
		transaction.receiver_payment_amount = 0.0
		transaction.payment_currency_id = ""
		transaction.fx_rate = 1.0
		transaction.fx_applied = false
		transaction.conversion_ledger = {
			"status": STATUS_ZERO_DELIVERY,
			"converted": true,
			"reason": "zero_delivery"
		}
		return

	if transaction.valuation_status != "valued":
		_mark_invalid(
			transaction,
			"missing_trade_valuation"
		)
		return

	var importer = world.get_entity(
		transaction.importer_id
	)
	var exporter = world.get_entity(
		transaction.exporter_id
	)

	if importer == null or exporter == null:
		_mark_invalid(
			transaction,
			"missing_counterparty"
		)
		return

	var importer_economy = importer.get_component("economy")
	var exporter_economy = exporter.get_component("economy")

	if importer_economy == null or exporter_economy == null:
		_mark_invalid(
			transaction,
			"missing_economy_component"
		)
		return

	var payer_currency_id := str(
		importer_economy.get_state(
			"currency_id",
			""
		)
	)
	var receiver_currency_id := str(
		exporter_economy.get_state(
			"currency_id",
			""
		)
	)

	var source_currency_id := transaction.valuation_currency_id
	var target_currency_id := payer_currency_id
	var source_amount := maxf(
		float(transaction.trade_value),
		0.0
	)

	transaction.conversion_checked = false
	transaction.fx_source_currency_id = source_currency_id
	transaction.fx_target_currency_id = target_currency_id
	transaction.payment_currency_id = target_currency_id
	transaction.payer_payment_amount = 0.0
	transaction.receiver_payment_amount = source_amount

	if source_currency_id.is_empty() or target_currency_id.is_empty():
		_mark_invalid(
			transaction,
			"missing_currency_identity"
		)
		return

	if source_currency_id == target_currency_id:
		transaction.fx_rate = 1.0
		transaction.fx_applied = false
		transaction.payer_payment_amount = source_amount
		transaction.conversion_status = STATUS_SAME_CURRENCY
		transaction.conversion_checked = true
		transaction.conversion_ledger = {
			"status": STATUS_SAME_CURRENCY,
			"source_currency_id": source_currency_id,
			"target_currency_id": target_currency_id,
			"source_amount": source_amount,
			"target_amount": source_amount,
			"fx_rate": 1.0,
			"fx_applied": false,
			"receiver_currency_id": receiver_currency_id
		}
		return

	if not rates_to_base.has(source_currency_id):
		_mark_missing_rate(
			transaction,
			"missing_source_currency_rate"
		)
		return

	if not rates_to_base.has(target_currency_id):
		_mark_missing_rate(
			transaction,
			"missing_target_currency_rate"
		)
		return

	var source_to_base := float(
		rates_to_base[source_currency_id]
	)
	var target_to_base := float(
		rates_to_base[target_currency_id]
	)

	if source_to_base <= 0.0 or target_to_base <= 0.0:
		_mark_missing_rate(
			transaction,
			"non_positive_fx_rate"
		)
		return

	# Rates are stored as currency units per one base-currency unit.
	# Therefore:
	# target amount =
	# source amount × target units/base ÷ source units/base.
	var fx_rate := target_to_base / source_to_base
	var target_amount := maxf(
		source_amount * fx_rate,
		0.0
	)

	transaction.fx_rate = fx_rate
	transaction.fx_applied = true
	transaction.payer_payment_amount = target_amount
	transaction.conversion_status = STATUS_CONVERTED
	transaction.conversion_checked = true
	transaction.conversion_ledger = {
		"status": STATUS_CONVERTED,
		"source_currency_id": source_currency_id,
		"target_currency_id": target_currency_id,
		"source_amount": source_amount,
		"target_amount": target_amount,
		"fx_rate": fx_rate,
		"fx_applied": true,
		"source_rate_to_base": source_to_base,
		"target_rate_to_base": target_to_base,
		"receiver_currency_id": receiver_currency_id
	}


func _mark_missing_rate(
	transaction: TradeTransaction,
	reason: String
) -> void:
	transaction.conversion_checked = true
	transaction.conversion_status = STATUS_MISSING_RATE
	transaction.fx_rate = 0.0
	transaction.fx_applied = false
	transaction.payer_payment_amount = 0.0
	transaction.conversion_ledger = {
		"status": STATUS_MISSING_RATE,
		"reason": reason,
		"source_currency_id": transaction.valuation_currency_id
	}


func _mark_invalid(
	transaction: TradeTransaction,
	reason: String
) -> void:
	transaction.conversion_checked = true
	transaction.conversion_status = STATUS_INVALID
	transaction.fx_rate = 0.0
	transaction.fx_applied = false
	transaction.payer_payment_amount = 0.0
	transaction.conversion_ledger = {
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
