class_name TradeRestrictionInteractionSystem
extends SimulationSystem


# ============================================================
# TRADE — STEP 11.3 RESTRICTION INTERACTION
# ============================================================
#
# This is a derived interaction / reconciliation layer. It does NOT own:
#   TradeRoute restriction state
#   physical stock
#   production output
#   economy output
#   valuation
#   payment
#   diplomatic relationships
#
# Those remain owned by the existing authoritative systems. This system
# records how an actually restrictive route changed the already-resolved
# monthly trade transaction and what downstream systems produced from it.
#
# Chain:
#   route restriction
#       -> actual trade quantity
#       -> resource flow / availability
#       -> production / economy outcome
#       -> valuation / payment
#       -> diplomatic consequence
#       -> transaction-visible interaction history
#
# A fully blocked route still produces a zero-delivery TradeTransaction in
# the existing TradeSystem. That transaction is recorded here with the
# downstream zero-delivery payment / diplomatic outcomes.
# ============================================================

const SYSTEM_NAME := "trade_restriction_interaction_system"
const EPSILON := 0.0000001


func _init() -> void:
	super(SYSTEM_NAME)


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("TradeRestrictionInteractionSystem: World is null.")
		return

	var transaction_ids: Array = world.trade_transactions.keys()
	transaction_ids.sort()

	for transaction_id in transaction_ids:

		var transaction: TradeTransaction = (
			world.get_trade_transaction(transaction_id)
			as TradeTransaction
		)

		if transaction == null:
			continue

		if transaction.restriction_interaction_applied:
			continue

		if not _is_current_month_transaction(world, transaction):
			continue

		var route: TradeRoute = (
			world.get_trade_route(transaction.route_id)
			as TradeRoute
		)

		if route == null:
			continue

		if not route.route_restriction_active:
			continue

		_record_restricted_transaction(
			world,
			transaction,
			route
		)


func _record_restricted_transaction(
	world: WorldState,
	transaction: TradeTransaction,
	route: TradeRoute
) -> void:

	var exporter = world.get_entity(transaction.exporter_id)
	var importer = world.get_entity(transaction.importer_id)

	var requested_quantity: float = maxf(
		float(transaction.requested_quantity),
		0.0
	)

	var actual_exported_quantity: float = maxf(
		float(transaction.actual_exported_quantity),
		0.0
	)

	var actual_imported_quantity: float = maxf(
		float(transaction.actual_imported_quantity),
		0.0
	)

	var fulfillment_ratio: float = 0.0
	if requested_quantity > EPSILON:
		fulfillment_ratio = clampf(
			actual_imported_quantity / requested_quantity,
			0.0,
			1.0
		)

	var interaction_status: String = "unaffected"
	if actual_imported_quantity <= EPSILON:
		interaction_status = "blocked"
	elif actual_imported_quantity + EPSILON < requested_quantity:
		interaction_status = "partial"
	else:
		interaction_status = "non_binding"

	var importer_resource_state: Dictionary = {}
	var importer_production_state: Dictionary = {}
	var importer_economy_state: Dictionary = {}
	var exporter_resource_state: Dictionary = {}

	if importer != null:

		var importer_resources = importer.get_component("resources")
		if importer_resources != null:
			importer_resource_state = {
				"trade_import": float(
					importer_resources.get_state(
						"trade_imports",
						{}
					).get(transaction.resource_id, 0.0)
				),
				"availability": float(
					importer_resources.get_state(
						"production_process_resource_availability",
						{}
					).get(transaction.resource_id, 0.0)
				),
				"shortage": float(
					importer_resources.get_state(
						"production_process_shortages",
						{}
					).get(transaction.resource_id, 0.0)
				)
			}

		var importer_industry = importer.get_component("industry")
		if importer_industry != null:
			importer_production_state = {
				"production_totals": importer_industry.get_state(
					"production_totals",
					{}
				).duplicate(true),
				"production_state": importer_industry.get_state(
					"production_state",
					{}
				).duplicate(true)
			}

		var importer_economy = importer.get_component("economy")
		if importer_economy != null:
			importer_economy_state = {
				"physical_production_output": float(
					importer_economy.get_state(
						"physical_production_output",
						0.0
					)
				),
				"production_output_factor": float(
					importer_economy.get_state(
						"production_output_factor",
						0.0
					)
				),
				"gdp": float(
					importer_economy.get_state(
						"gdp",
						0.0
					)
				)
			}

	if exporter != null:
		var exporter_resources = exporter.get_component("resources")
		if exporter_resources != null:
			exporter_resource_state = {
				"trade_export": float(
					exporter_resources.get_state(
						"trade_exports",
						{}
					).get(transaction.resource_id, 0.0)
			)
			}

	var relationship_metadata: Dictionary = (
		transaction.diplomatic_consequence_metadata.duplicate(true)
	)

	transaction.restriction_interaction_metadata = {
		"applied": true,
		"interaction_status": interaction_status,
		"restriction_type": "route",
		"restriction_active": route.route_restriction_active,
		"restriction_factor": route.route_restriction_factor,
		"restriction_reason": route.route_restriction_reason,
		"route_id": route.id,
		"agreement_id": transaction.agreement_id,
		"exporter_id": transaction.exporter_id,
		"importer_id": transaction.importer_id,
		"resource_id": transaction.resource_id,
		"requested_quantity": requested_quantity,
		"actual_exported_quantity": actual_exported_quantity,
		"actual_imported_quantity": actual_imported_quantity,
		"unfulfilled_quantity": float(transaction.unfulfilled_quantity),
		"fulfillment_ratio": fulfillment_ratio,
		"transaction_status": transaction.status,
		"resource_consequence": importer_resource_state.duplicate(true),
		"export_resource_consequence": exporter_resource_state.duplicate(true),
		"production_consequence": importer_production_state.duplicate(true),
		"economic_consequence": importer_economy_state.duplicate(true),
		"valuation": {
			"status": transaction.valuation_status,
			"quantity": transaction.valuation_quantity,
			"unit_price": transaction.valuation_unit_price,
			"trade_value": transaction.trade_value,
			"currency_id": transaction.valuation_currency_id
		},
		"payment": {
			"status": transaction.payment_status,
			"settled": transaction.payment_settled,
			"payment": transaction.trade_payment,
			"quantity": transaction.payment_quantity,
			"payer_payment_amount": transaction.payer_payment_amount,
			"receiver_payment_amount": transaction.receiver_payment_amount
		},
		"diplomatic_consequence": relationship_metadata,
		"history_output": {
			"recorded": true,
			"summary": (
				"Route restriction produced "
				+ interaction_status
				+ " trade fulfillment for "
				+ transaction.resource_id
			),
			"execution_date": transaction.execution_date.duplicate(true)
		}
	}

	transaction.restriction_interaction_applied = true


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
