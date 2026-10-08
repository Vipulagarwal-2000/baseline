class_name CurrencyConversionSystem
extends SimulationSystem


const STATUS_PENDING: String = "pending"
const STATUS_CONVERTED: String = "converted"
const STATUS_SAME_CURRENCY: String = "same_currency"
const STATUS_ZERO_DELIVERY: String = "zero_delivery"
const STATUS_MISSING_RATE: String = "missing_rate"
const STATUS_INVALID: String = "invalid"

const FX_DATA_PATH: String = "res://data/currency_exchange_rates.json"
const EXPECTED_RATE_BASIS: String = "units_of_currency_per_one_base_currency"
const EXPECTED_CONFIGURATION_STATUS: String = "fixed_mvp_configuration"
const EXPECTED_HISTORICAL_STATUS: String = "not_a_historical_exchange_rate_claim"
const EXPECTED_BASE_CURRENCY_SEMANTICS: String = "comparison_and_conversion_anchor"
const EXPECTED_CONVERSION_FORMULA: String = (
	"target_amount = source_amount * target_rate_to_base / source_rate_to_base"
)
const EXPECTED_RATE_SCOPE: String = (
	"cross_country_mvp_valuation_and_payment_support"
)
const EXPECTED_RUNTIME_BALANCE_AUTHORITY: String = (
	"country_economy_component"
)
const EXPECTED_RATE_CONFIGURATION_AUTHORITY: String = (
	"currency_exchange_rates.json"
)
const EPSILON: float = 0.0000001


var base_currency_id: String = ""
var rate_basis: String = ""
var rates_to_base: Dictionary = {}
var semantic_contract: Dictionary = {}
var semantic_contract_valid: bool = false


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


func is_semantic_contract_valid() -> bool:
	return semantic_contract_valid


func get_base_currency_id() -> String:
	return base_currency_id


func get_rate_basis() -> String:
	return rate_basis


func get_rate_to_base(currency_id: String) -> float:
	if not rates_to_base.has(currency_id):
		return 0.0
	return float(rates_to_base.get(currency_id, 0.0))


func get_loaded_rate_ids() -> Array:
	var ids: Array = rates_to_base.keys()
	ids.sort()
	return ids


func get_semantic_contract() -> Dictionary:
	return semantic_contract.duplicate(true)


func _load_rates() -> void:
	base_currency_id = ""
	rate_basis = ""
	rates_to_base = {}
	semantic_contract = {}
	semantic_contract_valid = false

	if not FileAccess.file_exists(FX_DATA_PATH):
		push_error(
			"CurrencyConversionSystem: FX data file missing: "
			+ FX_DATA_PATH
		)
		return

	var file: FileAccess = FileAccess.open(
		FX_DATA_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"CurrencyConversionSystem: Could not open FX data file."
		)
		return

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(
			"CurrencyConversionSystem: FX data root must be a dictionary."
		)
		return

	var config: Dictionary = parsed

	base_currency_id = str(
		config.get("base_currency", "")
	)

	rate_basis = str(
		config.get("rate_basis", "")
	)

	var raw_rates: Variant = config.get(
		"rates_to_base",
		{}
	)

	if typeof(raw_rates) != TYPE_DICTIONARY:
		push_error(
			"CurrencyConversionSystem: rates_to_base must be a dictionary."
		)
		base_currency_id = ""
		rate_basis = ""
		return

	var rates: Dictionary = raw_rates

	for key in rates.keys():
		var rate: float = float(rates[key])

		if rate <= 0.0:
			continue

		rates_to_base[str(key)] = rate

	var raw_contract: Variant = config.get(
		"semantic_contract",
		{}
	)

	if typeof(raw_contract) == TYPE_DICTIONARY:
		semantic_contract = raw_contract
	else:
		semantic_contract = {}

	if base_currency_id.is_empty():
		push_error(
			"CurrencyConversionSystem: Base currency is missing."
		)

	if rate_basis.is_empty():
		push_error(
			"CurrencyConversionSystem: Rate basis is missing."
		)

	semantic_contract_valid = _validate_semantic_contract(
		config,
		semantic_contract
	)

	if not semantic_contract_valid:
		push_error(
			"CurrencyConversionSystem: Currency semantic contract is invalid."
		)


func _validate_semantic_contract(
	config: Dictionary,
	contract: Dictionary
) -> bool:
	if contract.is_empty():
		return false

	if str(contract.get("configuration_status", "")) != EXPECTED_CONFIGURATION_STATUS:
		return false

	if str(contract.get("historical_status", "")) != EXPECTED_HISTORICAL_STATUS:
		return false

	if str(contract.get("base_currency_semantics", "")) != EXPECTED_BASE_CURRENCY_SEMANTICS:
		return false

	if str(contract.get("rate_direction", "")) != EXPECTED_RATE_BASIS:
		return false

	if str(contract.get("conversion_formula", "")) != EXPECTED_CONVERSION_FORMULA:
		return false

	if str(contract.get("rate_scope", "")) != EXPECTED_RATE_SCOPE:
		return false

	if str(contract.get("runtime_balance_authority", "")) != EXPECTED_RUNTIME_BALANCE_AUTHORITY:
		return false

	if str(contract.get("rate_configuration_authority", "")) != EXPECTED_RATE_CONFIGURATION_AUTHORITY:
		return false

	var valuation_usage_value: Variant = contract.get(
		"valuation_usage",
		[]
	)

	if typeof(valuation_usage_value) != TYPE_ARRAY:
		return false

	var valuation_usage: Array = valuation_usage_value

	if not valuation_usage.has("cross_currency_comparison"):
		return false

	if not valuation_usage.has("trade_payment_conversion"):
		return false

	if not valuation_usage.has("monetary_reconciliation"):
		return false

	if rate_basis != EXPECTED_RATE_BASIS:
		return false

	if base_currency_id.is_empty():
		return false

	if not rates_to_base.has(base_currency_id):
		return false

	if not is_equal_approx(
		get_rate_to_base(base_currency_id),
		1.0
	):
		return false

	if rates_to_base.is_empty():
		return false

	for currency_id_value in rates_to_base.keys():
		var currency_id: String = str(currency_id_value)
		var rate: float = get_rate_to_base(currency_id)

		if currency_id.is_empty() or rate <= 0.0:
			return false

	var canonical_currency_ids: Array = _load_canonical_currency_ids()

	if canonical_currency_ids.is_empty():
		return false

	for currency_id_value in rates_to_base.keys():
		var currency_id: String = str(currency_id_value)

		if not canonical_currency_ids.has(currency_id):
			return false

	return true


func _load_canonical_currency_ids() -> Array:
	const canonical_path: String = "res://data/canonical_ids.json"

	if not FileAccess.file_exists(canonical_path):
		return []

	var file: FileAccess = FileAccess.open(
		canonical_path,
		FileAccess.READ
	)

	if file == null:
		return []

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return []

	var root: Dictionary = parsed
	var domains_value: Variant = root.get(
		"domains",
		{}
	)

	if typeof(domains_value) != TYPE_DICTIONARY:
		return []

	var domains: Dictionary = domains_value
	var currency_value: Variant = domains.get(
		"currency",
		{}
	)

	if typeof(currency_value) != TYPE_DICTIONARY:
		return []

	var currency_domain: Dictionary = currency_value
	var entries_value: Variant = currency_domain.get(
		"entries",
		{}
	)

	if typeof(entries_value) != TYPE_DICTIONARY:
		return []

	var entries: Dictionary = entries_value
	var ids: Array = entries.keys()
	ids.sort()

	return ids


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

	if not semantic_contract_valid:
		_mark_invalid(
			transaction,
			"invalid_currency_semantic_contract"
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

	var payer_currency_id: String = str(
		importer_economy.get_state(
			"currency_id",
			""
		)
	)

	var receiver_currency_id: String = str(
		exporter_economy.get_state(
			"currency_id",
			""
		)
	)

	var source_currency_id: String = transaction.valuation_currency_id
	var target_currency_id: String = payer_currency_id

	var source_amount: float = maxf(
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
			"receiver_currency_id": receiver_currency_id,
			"rate_basis": rate_basis,
			"semantic_contract_valid": semantic_contract_valid
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

	var source_to_base: float = get_rate_to_base(
		source_currency_id
	)
	var target_to_base: float = get_rate_to_base(
		target_currency_id
	)

	if source_to_base <= EPSILON or target_to_base <= EPSILON:
		_mark_missing_rate(
			transaction,
			"non_positive_fx_rate"
		)
		return

	# Rates are stored as currency units per one base-currency unit.
	# Therefore:
	# target amount =
	# source amount × target units/base ÷ source units/base.
	var fx_rate: float = (
		target_to_base
		/ source_to_base
	)

	var target_amount: float = maxf(
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
		"receiver_currency_id": receiver_currency_id,
		"rate_basis": rate_basis,
		"semantic_contract_valid": semantic_contract_valid
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
		"source_currency_id": transaction.valuation_currency_id,
		"rate_basis": rate_basis,
		"semantic_contract_valid": semantic_contract_valid
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
