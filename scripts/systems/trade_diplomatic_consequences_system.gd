class_name TradeDiplomaticConsequencesSystem
extends SimulationSystem

const TRADE_RELATIONSHIP_CHANGE_AT_FULL_FULFILLMENT := 2.0
const EPSILON := 0.0000001


func _init():
	super("trade_diplomatic_consequences_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"TradeDiplomaticConsequencesSystem: World is null."
		)
		return

	var transaction_ids: Array = world.trade_transactions.keys()
	transaction_ids.sort()

	for transaction_id in transaction_ids:

		var transaction = world.get_trade_transaction(
			transaction_id
		)

		if transaction == null:
			continue

		if not transaction is TradeTransaction:
			continue

		if transaction.diplomatic_consequence_applied:
			continue

		if not _is_current_month_transaction(
			world,
			transaction
		):
			continue

		_apply_transaction_consequence(
			world,
			transaction
		)


func _apply_transaction_consequence(
	world: WorldState,
	transaction: TradeTransaction
) -> void:

	var exporter = world.get_entity(
		transaction.exporter_id
	)

	var importer = world.get_entity(
		transaction.importer_id
	)

	if exporter == null or importer == null:
		return

	var relationship_change := (
		_calculate_trade_relationship_change(
			transaction
		)
	)

	exporter.change_relationship_dimension(
		importer.id,
		"trade",
		relationship_change
	)

	importer.change_relationship_dimension(
		exporter.id,
		"trade",
		relationship_change
	)

	transaction.diplomatic_consequence_metadata = {
		"applied": true,
		"relationship_dimension": "trade",
		"relationship_change": relationship_change,
		"fulfillment_ratio": _calculate_fulfillment_ratio(
			transaction
		)
	}

	transaction.diplomatic_consequence_applied = true


func _calculate_trade_relationship_change(
	transaction: TradeTransaction
) -> float:

	var requested_quantity :float= max(
		0.0,
		transaction.requested_quantity
	)

	if requested_quantity <= EPSILON:
		return 0.0

	var fulfillment_ratio := clampf(
		transaction.actual_imported_quantity
		/ requested_quantity,
		0.0,
		1.0
	)

	return (
		TRADE_RELATIONSHIP_CHANGE_AT_FULL_FULFILLMENT
		* fulfillment_ratio
	)


func _calculate_fulfillment_ratio(
	transaction: TradeTransaction
) -> float:

	var requested_quantity :float= max(
		0.0,
		transaction.requested_quantity
	)

	if requested_quantity <= EPSILON:
		return 0.0

	return clampf(
		transaction.actual_imported_quantity
		/ requested_quantity,
		0.0,
		1.0
	)


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
