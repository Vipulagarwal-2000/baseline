class_name TradeTransaction
extends RefCounted


# ============================================================
# TRADE TRANSACTION — STEPS 4.5 + 4.9 + 5.11
# ============================================================
#
# Durable physical trade execution state plus the Step 5.11 monetary
# settlement record.
#
# Physical trade remains authoritative in the existing trade/resource
# pipeline. Step 5.11 only adds the monetary consequence of the actual
# quantity imported: importer pays, exporter receives.
# ============================================================

const STATUS_EXECUTED := "executed"
const STATUS_UNFULFILLED := "unfulfilled"
const STATUS_REJECTED := "rejected"

const PAYMENT_STATUS_PENDING := "pending"


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""
var agreement_id: String = ""
var route_id: String = ""

var exporter_id: String = ""
var importer_id: String = ""
var resource_id: String = ""


# ============================================================
# PHYSICAL QUANTITIES
# ============================================================

var requested_quantity: float = 0.0

var available_export_quantity: float = 0.0
var route_available_quantity: float = 0.0
var actual_exported_quantity: float = 0.0
var actual_imported_quantity: float = 0.0

var port_available_quantity: float = 0.0
var transport_available_quantity: float = 0.0
var roads_available_quantity: float = 0.0
var railways_available_quantity: float = 0.0
var infrastructure_available_quantity: float = 0.0

var executed_quantity: float = 0.0
var unfulfilled_quantity: float = 0.0


# ============================================================
# EXECUTION DATE / STATUS
# ============================================================

var execution_date: Dictionary = {}
var status: String = STATUS_REJECTED


# ============================================================
# STEP 4.9 — DIPLOMATIC CONSEQUENCE STATE
# ============================================================

var diplomatic_consequence_applied: bool = false
var diplomatic_consequence_metadata: Dictionary = {}


# ============================================================
# STEP 11.3 — TRADE RESTRICTION INTERACTION STATE
# ============================================================
#
# Records the downstream consequences of a restriction that actually
# affected this monthly transaction. The transaction remains the owner of
# transaction-specific interaction history; no second resource, payment,
# diplomacy, or economy model is introduced.
var restriction_interaction_applied: bool = false
var restriction_interaction_metadata: Dictionary = {}


# ============================================================
# STEP 6.2 — TRADE VALUATION STATE
# ============================================================

# Quantity valued financially from the actual imported quantity.
var valuation_quantity: float = 0.0

# Unit price used to establish the trade value.
var valuation_unit_price: float = 0.0

# Currency in which the trade value is denominated.
# Step 6.2 uses the exporter's currency identity.
var valuation_currency_id: String = ""

# Total nominal trade value before payment settlement.
var trade_value: float = 0.0

const VALUATION_STATUS_PENDING := "pending"
var valuation_status: String = VALUATION_STATUS_PENDING

var valuation_ledger: Dictionary = {}


# ============================================================
# STEP 6.3 — PAYMENT SETTLEMENT STATE
# ============================================================

# Currency in which this settlement is recorded.
# 6.3 does not perform FX; the valuation currency is carried through.
var settlement_currency_id: String = ""

# Native currency identity of the payer.
var payer_currency_id: String = ""

# Native currency identity of the receiver.
var receiver_currency_id: String = ""

const SETTLEMENT_STATUS_PENDING := "pending"
var settlement_status: String = SETTLEMENT_STATUS_PENDING

var settlement_ledger: Dictionary = {}


# ============================================================
# STEP 6.5 — CURRENCY CONVERSION STATE
# ============================================================

const CONVERSION_STATUS_PENDING := "pending"
const CONVERSION_STATUS_CONVERTED := "converted"
const CONVERSION_STATUS_SAME_CURRENCY := "same_currency"
const CONVERSION_STATUS_ZERO_DELIVERY := "zero_delivery"
const CONVERSION_STATUS_MISSING_RATE := "missing_rate"
const CONVERSION_STATUS_INVALID := "invalid"

var conversion_checked: bool = false
var conversion_status: String = CONVERSION_STATUS_PENDING

# Currency of the original trade valuation.
var fx_source_currency_id: String = ""

# Currency in which the payer's treasury is denominated.
var fx_target_currency_id: String = ""

# Payment currency used on the payer side.
var payment_currency_id: String = ""

# Target-currency units per one source-currency unit.
var fx_rate: float = 0.0

var fx_applied: bool = false

# Amount received by the exporter in the valuation/receiver currency.
var receiver_payment_amount: float = 0.0

# Amount debited from the importer in the payer currency.
var payer_payment_amount: float = 0.0

var conversion_ledger: Dictionary = {}


# ============================================================
# STEP 6.4 — PAYMENT AFFORDABILITY STATE
# ============================================================

const AFFORDABILITY_STATUS_PENDING := "pending"
const AFFORDABILITY_STATUS_AFFORDABLE := "affordable"
const AFFORDABILITY_STATUS_INSUFFICIENT_FUNDS := "insufficient_funds"
const AFFORDABILITY_STATUS_DEFERRED_FX := "deferred_fx"
const AFFORDABILITY_STATUS_ZERO_DELIVERY := "zero_delivery"
const AFFORDABILITY_STATUS_INVALID := "invalid"

# Whether affordability could be evaluated in the current monetary model.
var affordability_checked: bool = false

# True only when the payer can cover the nominal payment in the
# payer/settlement currency without needing an FX conversion.
var affordable: bool = false

# Required payment amount for the executed transaction.
var affordability_required_payment: float = 0.0

# Payer's available treasury balance used for the affordability test.
var affordability_available_balance: float = 0.0

# Amount by which the payment exceeds the payer's available balance.
var affordability_shortfall: float = 0.0

# Maximum physical quantity that could be paid for at the current
# valuation price, when the currencies are directly comparable.
var affordability_max_quantity: float = 0.0

var affordability_status: String = AFFORDABILITY_STATUS_PENDING
var affordability_ledger: Dictionary = {}


# ============================================================
# STEP 5.11 — TRADE PAYMENT STATE
# ============================================================

# Quantity actually settled financially. This is the imported quantity,
# because the importer receives that physical quantity.
var payment_quantity: float = 0.0

# Monetary value per unit used for this settlement.
# Step 5.11 derives it from the exporter's current resource price.
var payment_unit_price: float = 0.0

# Total payment transferred from importer to exporter.
var trade_payment: float = 0.0

# Kept as an explicit transaction-cost/value field for downstream systems.
# In 5.11 this equals trade_payment; no separate fee is invented here.
var transaction_cost: float = 0.0

var payment_settled: bool = false
var payment_status: String = PAYMENT_STATUS_PENDING
var payment_ledger: Dictionary = {}


# ============================================================
# STEP 6.6 — MONETARY INVARIANT STATE
# ============================================================

const MONETARY_INVARIANT_STATUS_PENDING := "pending"
const MONETARY_INVARIANT_STATUS_PASS := "pass"
const MONETARY_INVARIANT_STATUS_FAIL := "fail"
const MONETARY_INVARIANT_STATUS_SKIPPED := "skipped"

var monetary_invariants_checked: bool = false
var monetary_invariants_passed: bool = false
var monetary_invariant_status: String = (
	MONETARY_INVARIANT_STATUS_PENDING
)
var monetary_invariant_errors: Array = []
var monetary_invariant_ledger: Dictionary = {}


func _init(
	transaction_id: String = "",
	linked_agreement_id: String = "",
	linked_route_id: String = "",
	exporter: String = "",
	importer: String = "",
	resource: String = "",
	requested: float = 0.0,
	executed: float = 0.0,
	date: Dictionary = {},
	available_export: float = -1.0,
	route_available: float = -1.0,
	actual_exported: float = -1.0,
	actual_imported: float = -1.0,
	port_available: float = -1.0,
	transport_available: float = -1.0,
	roads_available: float = -1.0,
	railways_available: float = -1.0,
	infrastructure_available: float = -1.0
):

	id = transaction_id
	agreement_id = linked_agreement_id
	route_id = linked_route_id
	exporter_id = exporter
	importer_id = importer
	resource_id = resource
	requested_quantity = max(0.0, requested)

	available_export_quantity = (
		max(0.0, available_export)
		if available_export >= 0.0
		else requested_quantity
	)

	route_available_quantity = (
		max(0.0, route_available)
		if route_available >= 0.0
		else requested_quantity
	)

	port_available_quantity = (
		max(0.0, port_available)
		if port_available >= 0.0
		else requested_quantity
	)

	transport_available_quantity = (
		max(0.0, transport_available)
		if transport_available >= 0.0
		else requested_quantity
	)

	roads_available_quantity = (
		max(0.0, roads_available)
		if roads_available >= 0.0
		else requested_quantity
	)

	railways_available_quantity = (
		max(0.0, railways_available)
		if railways_available >= 0.0
		else requested_quantity
	)

	infrastructure_available_quantity = (
		max(0.0, infrastructure_available)
		if infrastructure_available >= 0.0
		else requested_quantity
	)

	if actual_exported >= 0.0:
		actual_exported_quantity = clamp(
			actual_exported,
			0.0,
			requested_quantity
		)
	else:
		actual_exported_quantity = clamp(
			executed,
			0.0,
			requested_quantity
		)

	if actual_imported >= 0.0:
		actual_imported_quantity = clamp(
			actual_imported,
			0.0,
			actual_exported_quantity
		)
	else:
		actual_imported_quantity = actual_exported_quantity

	executed_quantity = actual_exported_quantity

	unfulfilled_quantity = max(
		0.0,
		requested_quantity - min(
			actual_exported_quantity,
			actual_imported_quantity
		)
	)

	execution_date = date.duplicate(true)

	_refresh_status()


# ============================================================
# VALIDATION
# ============================================================

func is_valid() -> bool:

	if id.is_empty():
		return false

	if agreement_id.is_empty():
		return false

	if route_id.is_empty():
		return false

	if exporter_id.is_empty():
		return false

	if importer_id.is_empty():
		return false

	if exporter_id == importer_id:
		return false

	if resource_id.is_empty():
		return false

	if requested_quantity < 0.0:
		return false

	if available_export_quantity < 0.0:
		return false

	if route_available_quantity < 0.0:
		return false

	if port_available_quantity < 0.0:
		return false

	if transport_available_quantity < 0.0:
		return false

	if roads_available_quantity < 0.0:
		return false

	if railways_available_quantity < 0.0:
		return false

	if infrastructure_available_quantity < 0.0:
		return false

	if actual_exported_quantity < 0.0:
		return false

	if actual_imported_quantity < 0.0:
		return false

	if executed_quantity < 0.0:
		return false

	if executed_quantity > requested_quantity:
		return false

	if actual_imported_quantity > actual_exported_quantity:
		return false

	var physical_limit = min(
		requested_quantity,
		available_export_quantity,
		route_available_quantity,
		port_available_quantity,
		transport_available_quantity,
		roads_available_quantity,
		railways_available_quantity,
		infrastructure_available_quantity
	)

	if actual_exported_quantity > physical_limit + 0.0000001:
		return false

	if unfulfilled_quantity < 0.0:
		return false

	if not _is_valid_status(status):
		return false

	if typeof(restriction_interaction_metadata) != TYPE_DICTIONARY:
		return false

	if valuation_quantity < 0.0:
		return false

	if valuation_unit_price < 0.0:
		return false

	if trade_value < 0.0:
		return false

	if valuation_status.is_empty():
		return false

	if settlement_status.is_empty():
		return false

	if settlement_currency_id != "":
		if not settlement_currency_id.is_valid_identifier():
			return false

	if fx_rate < 0.0:
		return false

	if payer_payment_amount < 0.0:
		return false

	if receiver_payment_amount < 0.0:
		return false

	if conversion_status.is_empty():
		return false

	if affordability_required_payment < 0.0:
		return false

	if affordability_available_balance < 0.0:
		return false

	if affordability_shortfall < 0.0:
		return false

	if affordability_max_quantity < 0.0:
		return false

	if affordability_status.is_empty():
		return false

	if payment_quantity < 0.0:
		return false

	if payment_unit_price < 0.0:
		return false

	if trade_payment < 0.0:
		return false

	if transaction_cost < 0.0:
		return false

	if monetary_invariant_status.is_empty():
		return false

	return true


func _is_valid_status(value: String) -> bool:

	return value in [
		STATUS_EXECUTED,
		STATUS_UNFULFILLED,
		STATUS_REJECTED
	]


func _refresh_status() -> void:

	if executed_quantity > 0.0 and unfulfilled_quantity <= 0.0000001:
		status = STATUS_EXECUTED
		return

	if executed_quantity > 0.0 and unfulfilled_quantity > 0.0000001:
		status = STATUS_UNFULFILLED
		return

	if requested_quantity <= 0.0:
		status = STATUS_EXECUTED
		return

	status = STATUS_UNFULFILLED


# ============================================================
# SNAPSHOT REPRESENTATION
# ============================================================

func to_snapshot_dict() -> Dictionary:

	return {
		"id": id,
		"agreement_id": agreement_id,
		"route_id": route_id,
		"exporter_id": exporter_id,
		"importer_id": importer_id,
		"resource_id": resource_id,
		"requested_quantity": requested_quantity,
		"available_export_quantity": available_export_quantity,
		"route_available_quantity": route_available_quantity,
		"port_available_quantity": port_available_quantity,
		"transport_available_quantity": transport_available_quantity,
		"roads_available_quantity": roads_available_quantity,
		"railways_available_quantity": railways_available_quantity,
		"infrastructure_available_quantity": infrastructure_available_quantity,
		"actual_exported_quantity": actual_exported_quantity,
		"actual_imported_quantity": actual_imported_quantity,
		"executed_quantity": executed_quantity,
		"unfulfilled_quantity": unfulfilled_quantity,
		"execution_date": execution_date.duplicate(true),
		"status": status,
		"diplomatic_consequence_applied": diplomatic_consequence_applied,
		"diplomatic_consequence_metadata": diplomatic_consequence_metadata.duplicate(true),
		"restriction_interaction_applied": restriction_interaction_applied,
		"restriction_interaction_metadata": restriction_interaction_metadata.duplicate(true),
		"valuation_quantity": valuation_quantity,
		"valuation_unit_price": valuation_unit_price,
		"valuation_currency_id": valuation_currency_id,
		"trade_value": trade_value,
		"valuation_status": valuation_status,
		"valuation_ledger": valuation_ledger.duplicate(true),
		"settlement_currency_id": settlement_currency_id,
		"payer_currency_id": payer_currency_id,
		"receiver_currency_id": receiver_currency_id,
		"settlement_status": settlement_status,
		"settlement_ledger": settlement_ledger.duplicate(true),
		"conversion_checked": conversion_checked,
		"conversion_status": conversion_status,
		"fx_source_currency_id": fx_source_currency_id,
		"fx_target_currency_id": fx_target_currency_id,
		"payment_currency_id": payment_currency_id,
		"fx_rate": fx_rate,
		"fx_applied": fx_applied,
		"receiver_payment_amount": receiver_payment_amount,
		"payer_payment_amount": payer_payment_amount,
		"conversion_ledger": conversion_ledger.duplicate(true),
		"affordability_checked": affordability_checked,
		"affordable": affordable,
		"affordability_required_payment": affordability_required_payment,
		"affordability_available_balance": affordability_available_balance,
		"affordability_shortfall": affordability_shortfall,
		"affordability_max_quantity": affordability_max_quantity,
		"affordability_status": affordability_status,
		"affordability_ledger": affordability_ledger.duplicate(true),
		"payment_quantity": payment_quantity,
		"payment_unit_price": payment_unit_price,
		"trade_payment": trade_payment,
		"transaction_cost": transaction_cost,
		"payment_settled": payment_settled,
		"payment_status": payment_status,
		"payment_ledger": payment_ledger.duplicate(true),
		"monetary_invariants_checked": monetary_invariants_checked,
		"monetary_invariants_passed": monetary_invariants_passed,
		"monetary_invariant_status": monetary_invariant_status,
		"monetary_invariant_errors": monetary_invariant_errors.duplicate(true),
		"monetary_invariant_ledger": monetary_invariant_ledger.duplicate(true)
	}
