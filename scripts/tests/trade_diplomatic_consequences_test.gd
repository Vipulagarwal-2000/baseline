class_name TradeDiplomaticConsequencesTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"TRADE DIPLOMATIC CONSEQUENCES TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line("World/simulation available: FAIL")
		return false

	TestLogger.write_line("World/simulation available: PASS")

	var diplomatic_system = simulation.get_system(
		"trade_diplomatic_consequences_system"
	)

	if diplomatic_system == null:
		TestLogger.write_line(
			"Registered TradeDiplomaticConsequencesSystem available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Registered TradeDiplomaticConsequencesSystem available: PASS"
	)

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null or india == null:
		TestLogger.write_line(
			"China and India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"China and India available: PASS"
	)

	var original_china_relationships: Dictionary = (
		china.relationships.duplicate(true)
	)
	var original_india_relationships: Dictionary = (
		india.relationships.duplicate(true)
	)

	const agreement_full_id = "test_trade_agreement_4_9_full"
	const route_full_id = "test_trade_route_4_9_full"
	const transaction_full_id = "test_trade_transaction_4_9_full"

	const agreement_partial_id = "test_trade_agreement_4_9_partial"
	const route_partial_id = "test_trade_route_4_9_partial"
	const transaction_partial_id = "test_trade_transaction_4_9_partial"

	const agreement_zero_id = "test_trade_agreement_4_9_zero"
	const route_zero_id = "test_trade_route_4_9_zero"
	const transaction_zero_id = "test_trade_transaction_4_9_zero"

	var original_agreements: Dictionary = {}
	var original_routes: Dictionary = {}
	var original_transactions: Dictionary = {}

	for id in [
		agreement_full_id,
		agreement_partial_id,
		agreement_zero_id
	]:
		if world.has_trade_agreement(id):
			original_agreements[id] = world.get_trade_agreement(id)

	for id in [
		route_full_id,
		route_partial_id,
		route_zero_id
	]:
		if world.has_trade_route(id):
			original_routes[id] = world.get_trade_route(id)

	for id in [
		transaction_full_id,
		transaction_partial_id,
		transaction_zero_id
	]:
		if world.has_trade_transaction(id):
			original_transactions[id] = world.get_trade_transaction(id)

	var execution_date: Dictionary = world.current_date.duplicate(true)

	var full_agreement: TradeAgreement = TradeAgreement.new(
		agreement_full_id,
		"china",
		"india",
		"iron",
		10.0,
		2
	)
	full_agreement.activate(execution_date)

	var full_route: TradeRoute = TradeRoute.new(
		route_full_id,
		agreement_full_id,
		"china",
		"india",
		100.0
	)
	full_route.activate()

	var full_transaction: TradeTransaction = TradeTransaction.new(
		transaction_full_id,
		agreement_full_id,
		route_full_id,
		"china",
		"india",
		"iron",
		10.0,
		10.0,
		execution_date,
		10.0,
		10.0,
		10.0,
		10.0
	)

	var full_registered: bool = (
		world.add_trade_agreement(full_agreement)
		and world.add_trade_route(full_route)
		and world.add_trade_transaction(full_transaction)
	)

	TestLogger.write_line(
		"Full trade fixture registration: "
		+ ("PASS" if full_registered else "FAIL")
	)

	if not full_registered:
		china.relationships = original_china_relationships
		india.relationships = original_india_relationships
		return false

	var before_full: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	diplomatic_system.process_month(world)

	var after_full_china: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	var after_full_india: float = float(india.get_relationship_dimension(
		"china",
		"trade",
		0.0
	))

	var full_change: float = (
		TradeDiplomaticConsequencesSystem
		.TRADE_RELATIONSHIP_CHANGE_AT_FULL_FULFILLMENT
	)

	var full_change_pass: bool = is_equal_approx(
		after_full_china - before_full,
		full_change
	)

	TestLogger.write_line(
		"Full fulfillment changes exporter relationship: "
		+ ("PASS" if full_change_pass else "FAIL")
	)

	# The importer baseline must be read from the saved original
	# relationship data because the post-processing query is current.
	var original_importer_trade: float = 0.0
	if original_india_relationships.has("china"):
		var original_importer_data = original_india_relationships["china"]
		if typeof(original_importer_data) == TYPE_DICTIONARY:
			original_importer_trade = float(
				original_importer_data.get("trade", 0.0)
			)

	var bilateral_pass: bool = is_equal_approx(
		after_full_india - original_importer_trade,
		full_change
	)

	TestLogger.write_line(
		"Full fulfillment changes importer relationship: "
		+ ("PASS" if bilateral_pass else "FAIL")
	)

	var flag_pass: bool = (
		full_transaction.diplomatic_consequence_applied
		and is_equal_approx(
			float(
				full_transaction.diplomatic_consequence_metadata.get(
					"fulfillment_ratio",
					-1.0
				)
			),
			1.0
		)
	)

	TestLogger.write_line(
		"Transaction records diplomatic consequence state: "
		+ ("PASS" if flag_pass else "FAIL")
	)

	diplomatic_system.process_month(world)

	var after_repeat: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	var idempotence_pass: bool = is_equal_approx(
		after_repeat,
		after_full_china
	)

	TestLogger.write_line(
		"Repeated processing does not double-apply transaction: "
		+ ("PASS" if idempotence_pass else "FAIL")
	)

	var partial_agreement: TradeAgreement = TradeAgreement.new(
		agreement_partial_id,
		"china",
		"india",
		"coal",
		10.0,
		2
	)
	partial_agreement.activate(execution_date)

	var partial_route: TradeRoute = TradeRoute.new(
		route_partial_id,
		agreement_partial_id,
		"china",
		"india",
		100.0
	)
	partial_route.activate()

	var partial_transaction: TradeTransaction = TradeTransaction.new(
		transaction_partial_id,
		agreement_partial_id,
		route_partial_id,
		"china",
		"india",
		"coal",
		10.0,
		5.0,
		execution_date,
		5.0,
		10.0,
		5.0,
		5.0
	)

	var partial_registered: bool = (
		world.add_trade_agreement(partial_agreement)
		and world.add_trade_route(partial_route)
		and world.add_trade_transaction(partial_transaction)
	)

	TestLogger.write_line(
		"Partial trade fixture registration: "
		+ ("PASS" if partial_registered else "FAIL")
	)

	var before_partial: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	diplomatic_system.process_month(world)

	var after_partial: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	var partial_pass: bool = is_equal_approx(
		after_partial - before_partial,
		full_change * 0.5
	)

	TestLogger.write_line(
		"Partial fulfillment scales consequence by delivery ratio: "
		+ ("PASS" if partial_pass else "FAIL")
	)

	var zero_agreement: TradeAgreement = TradeAgreement.new(
		agreement_zero_id,
		"china",
		"india",
		"coal",
		10.0,
		2
	)
	zero_agreement.activate(execution_date)

	var zero_route: TradeRoute = TradeRoute.new(
		route_zero_id,
		agreement_zero_id,
		"china",
		"india",
		100.0
	)
	zero_route.activate()

	var zero_transaction: TradeTransaction = TradeTransaction.new(
		transaction_zero_id,
		agreement_zero_id,
		route_zero_id,
		"china",
		"india",
		"coal",
		10.0,
		0.0,
		execution_date,
		0.0,
		0.0,
		0.0,
		0.0
	)
	zero_transaction.status = TradeTransaction.STATUS_REJECTED

	var zero_registered: bool = (
		world.add_trade_agreement(zero_agreement)
		and world.add_trade_route(zero_route)
		and world.add_trade_transaction(zero_transaction)
	)

	TestLogger.write_line(
		"Zero-delivery fixture registration: "
		+ ("PASS" if zero_registered else "FAIL")
	)

	var before_zero: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	diplomatic_system.process_month(world)

	var after_zero: float = float(china.get_relationship_dimension(
		"india",
		"trade",
		0.0
	))

	var zero_pass: bool = (
		is_equal_approx(after_zero, before_zero)
		and zero_transaction.diplomatic_consequence_applied
	)

	TestLogger.write_line(
		"Zero delivered quantity creates no positive consequence: "
		+ ("PASS" if zero_pass else "FAIL")
	)

	var snapshot: WorldSnapshot = WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_full: Dictionary = snapshot.trade_transactions.get(
		transaction_full_id,
		{}
	)

	var snapshot_pass: bool = (
		bool(
			snapshot_full.get(
				"diplomatic_consequence_applied",
				false
			)
		)
		and is_equal_approx(
			float(
				snapshot_full.get(
					"diplomatic_consequence_metadata",
					{}
				).get(
					"relationship_change",
					-1.0
				)
			),
			full_change
		)
	)

	TestLogger.write_line(
		"Snapshot preserves diplomatic consequence state: "
		+ ("PASS" if snapshot_pass else "FAIL")
	)

	var relationship_data: Dictionary = china.get_relationship_data(
		"india"
	)

	var expected_overall: float = 0.0
	var total: float = 0.0
	var count: int = 0

	for dimension in [
		"diplomatic",
		"economic",
		"military",
		"trade",
		"political",
		"cultural",
		"trust",
		"hostility"
	]:
		if not relationship_data.has(dimension):
			continue
		total += float(relationship_data[dimension])
		count += 1

	if count > 0:
		expected_overall = total / float(count)

	var overall_pass: bool = is_equal_approx(
		float(relationship_data.get("overall", 0.0)),
		expected_overall
	)

	TestLogger.write_line(
		"Overall relationship recalculates from trade dimension: "
		+ ("PASS" if overall_pass else "FAIL")
	)

	var all_passed: bool = (
		full_change_pass
		and bilateral_pass
		and flag_pass
		and idempotence_pass
		and partial_pass
		and zero_pass
		and snapshot_pass
		and overall_pass
	)

	# Restore all touched state.
	china.relationships = original_china_relationships
	india.relationships = original_india_relationships

	for id in [
		transaction_full_id,
		transaction_partial_id,
		transaction_zero_id
	]:
		world.trade_transactions.erase(id)

	for id in [
		route_full_id,
		route_partial_id,
		route_zero_id
	]:
		world.trade_routes.erase(id)

	for id in [
		agreement_full_id,
		agreement_partial_id,
		agreement_zero_id
	]:
		world.trade_agreements.erase(id)

	for id in original_transactions.keys():
		world.trade_transactions[id] = original_transactions[id]

	for id in original_routes.keys():
		world.trade_routes[id] = original_routes[id]

	for id in original_agreements.keys():
		world.trade_agreements[id] = original_agreements[id]

	TestLogger.write_line(
		"Trade 4.9 state restoration: PASS"
	)

	TestLogger.section(
		"TRADE DIPLOMATIC CONSEQUENCES RESULT"
	)

	TestLogger.write_line(
		"Trade Diplomatic Consequences 4.9 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
