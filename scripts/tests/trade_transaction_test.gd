class_name TradeTransactionTest
extends RefCounted


# ============================================================
# TRADE TRANSACTION — STEP 4.3 TEST
# ============================================================
#
# Validates the controlled monthly transaction layer using the
# registered TradeSystem and the registered ResourceSystem.
#
# This intentionally does not validate route throughput or
# infrastructure constraints; those belong to later trade steps.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE TRANSACTION TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var trade_system = simulation.get_system("trade_system")
	var resource_system = simulation.get_system("resource_system")

	if trade_system == null:
		TestLogger.write_line("Registered TradeSystem available: FAIL")
		return false

	TestLogger.write_line("Registered TradeSystem available: PASS")

	if resource_system == null:
		TestLogger.write_line("Registered ResourceSystem available: FAIL")
		return false

	TestLogger.write_line("Registered ResourceSystem available: PASS")

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null or india == null:
		TestLogger.write_line("China and India available: FAIL")
		return false

	TestLogger.write_line("China and India available: PASS")

	var china_resources = china.get_component("resources")
	var india_resources = india.get_component("resources")
	var china_infrastructure = china.get_component("infrastructure")
	var india_infrastructure = india.get_component("infrastructure")

	if (
		china_resources == null
		or india_resources == null
		or china_infrastructure == null
		or india_infrastructure == null
	):
		TestLogger.write_line(
            "Required trade/resource components available: FAIL"
		)
		return false

	TestLogger.write_line(
        "Required trade/resource components available: PASS"
	)

	const full_agreement_id = "test_trade_agreement_4_3_full"
	const full_route_id = "test_trade_route_4_3_full"
	const partial_agreement_id = "test_trade_agreement_4_3_partial"
	const partial_route_id = "test_trade_route_4_3_partial"

	var china_original_state = china_resources.state.duplicate(true)
	var india_original_state = india_resources.state.duplicate(true)
	var china_original_infrastructure = china_infrastructure.state.duplicate(true)
	var india_original_infrastructure = india_infrastructure.state.duplicate(true)

	var original_agreements: Dictionary = {}
	var original_routes: Dictionary = {}
	var original_transactions: Dictionary = {}

	for agreement_id in [
		full_agreement_id,
		partial_agreement_id
	]:
		if world.has_trade_agreement(agreement_id):
			original_agreements[agreement_id] = world.get_trade_agreement(
				agreement_id
			)

	for route_id in [
		full_route_id,
		partial_route_id
	]:
		if world.has_trade_route(route_id):
			original_routes[route_id] = world.get_trade_route(
				route_id
			)

	var full_transaction_id = _transaction_id(
		world,
		full_agreement_id,
		full_route_id
	)

	var partial_transaction_id = _transaction_id(
		world,
		partial_agreement_id,
		partial_route_id
	)

	for transaction_id in [
		full_transaction_id,
		partial_transaction_id
	]:
		if world.has_trade_transaction(transaction_id):
			original_transactions[transaction_id] = world.get_trade_transaction(
				transaction_id
			)

	var all_passed := true

	# --------------------------------------------------------
	# CONTROLLED RESOURCE FIXTURE
	# --------------------------------------------------------

	var china_production = china_resources.get_state("production", {})
	var china_consumption = china_resources.get_state("consumption", {})
	var china_process_demand = china_resources.get_state(
		"production_process_demand",
		{}
	)

	var india_production = india_resources.get_state("production", {})
	var india_consumption = india_resources.get_state("consumption", {})
	var india_process_demand = india_resources.get_state(
		"production_process_demand",
		{}
	)

	var china_stockpile = china_resources.get_state("stockpile", {})
	var india_stockpile = india_resources.get_state("stockpile", {})

	china_infrastructure.state["ports"] = 1.0
	india_infrastructure.state["ports"] = 1.0
	china_infrastructure.state["transport"] = 1.0
	india_infrastructure.state["transport"] = 1.0
	china_infrastructure.state["roads"] = 1.0
	india_infrastructure.state["roads"] = 1.0
	china_infrastructure.state["railways"] = 1.0
	india_infrastructure.state["railways"] = 1.0

	china_production["coal"] = 0.0
	china_production["iron"] = 0.0
	china_consumption["coal"] = 0.0
	china_consumption["iron"] = 0.0
	china_process_demand["coal"] = 0.0
	china_process_demand["iron"] = 0.0

	india_production["coal"] = 0.0
	india_production["iron"] = 0.0
	india_consumption["coal"] = 0.0
	india_consumption["iron"] = 0.0
	india_process_demand["coal"] = 0.0
	india_process_demand["iron"] = 0.0

	china_stockpile["coal"] = 50.0
	china_stockpile["iron"] = 10.0
	india_stockpile["coal"] = 5.0
	india_stockpile["iron"] = 2.0

	# --------------------------------------------------------
	# FULL FULFILLMENT
	# --------------------------------------------------------

	var full_agreement := TradeAgreement.new(
		full_agreement_id,
		"china",
		"india",
		"coal",
		30.0,
		12
	)
	full_agreement.activate(world.current_date)

	var full_route := TradeRoute.new(
		full_route_id,
		full_agreement_id,
		"china",
        "india"
	)
	full_route.activate()

	if world.add_trade_agreement(full_agreement):
		TestLogger.write_line("Full agreement registration: PASS")
	else:
		TestLogger.write_line("Full agreement registration: FAIL")
		all_passed = false

	if world.add_trade_route(full_route):
		TestLogger.write_line("Full route registration: PASS")
	else:
		TestLogger.write_line("Full route registration: FAIL")
		all_passed = false

	# --------------------------------------------------------
	# PARTIAL FULFILLMENT
	# --------------------------------------------------------

	var partial_agreement := TradeAgreement.new(
		partial_agreement_id,
		"china",
		"india",
		"iron",
		25.0,
		12
	)
	partial_agreement.activate(world.current_date)

	var partial_route := TradeRoute.new(
		partial_route_id,
		partial_agreement_id,
		"china",
        "india"
	)
	partial_route.activate()

	if world.add_trade_agreement(partial_agreement):
		TestLogger.write_line("Partial agreement registration: PASS")
	else:
		TestLogger.write_line("Partial agreement registration: FAIL")
		all_passed = false

	if world.add_trade_route(partial_route):
		TestLogger.write_line("Partial route registration: PASS")
	else:
		TestLogger.write_line("Partial route registration: FAIL")
		all_passed = false

	# --------------------------------------------------------
	# TRADE EXECUTION
	# --------------------------------------------------------

	trade_system.process_month(world)

	var full_transaction = world.get_trade_transaction(
		full_transaction_id
	)

	var partial_transaction = world.get_trade_transaction(
		partial_transaction_id
	)

	if full_transaction != null:
		TestLogger.write_line("Full transaction creation: PASS")
	else:
		TestLogger.write_line("Full transaction creation: FAIL")
		all_passed = false

	if partial_transaction != null:
		TestLogger.write_line("Partial transaction creation: PASS")
	else:
		TestLogger.write_line("Partial transaction creation: FAIL")
		all_passed = false

	if full_transaction != null:
		if (
			is_equal_approx(full_transaction.requested_quantity, 30.0)
			and is_equal_approx(full_transaction.executed_quantity, 30.0)
			and is_equal_approx(full_transaction.unfulfilled_quantity, 0.0)
		):
			TestLogger.write_line(
                "Full transaction quantity execution: PASS"
			)
		else:
			TestLogger.write_line(
                "Full transaction quantity execution: FAIL"
			)
			all_passed = false

		if full_transaction.status == TradeTransaction.STATUS_EXECUTED:
			TestLogger.write_line("Full transaction status: PASS")
		else:
			TestLogger.write_line("Full transaction status: FAIL")
			all_passed = false

	if partial_transaction != null:
		if (
			is_equal_approx(partial_transaction.requested_quantity, 25.0)
			and is_equal_approx(partial_transaction.executed_quantity, 10.0)
			and is_equal_approx(partial_transaction.unfulfilled_quantity, 15.0)
		):
			TestLogger.write_line(
                "Exporter stockpile caps transaction quantity: PASS"
			)
		else:
			TestLogger.write_line(
                "Exporter stockpile caps transaction quantity: FAIL"
			)
			all_passed = false

		if partial_transaction.status == TradeTransaction.STATUS_UNFULFILLED:
			TestLogger.write_line("Partial transaction status: PASS")
		else:
			TestLogger.write_line("Partial transaction status: FAIL")
			all_passed = false

	# --------------------------------------------------------
	# EXISTING RESOURCE FLOW STATE
	# --------------------------------------------------------

	var china_exports = china_resources.get_state("exports", {})
	var india_imports = india_resources.get_state("imports", {})

	if (
		is_equal_approx(float(china_exports.get("coal", 0.0)), 30.0)
		and is_equal_approx(float(china_exports.get("iron", 0.0)), 10.0)
		and is_equal_approx(float(india_imports.get("coal", 0.0)), 30.0)
		and is_equal_approx(float(india_imports.get("iron", 0.0)), 10.0)
	):
		TestLogger.write_line(
            "Existing ResourceComponent import/export scheduling: PASS"
		)
	else:
		TestLogger.write_line(
            "Existing ResourceComponent import/export scheduling: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# RESOURCE SYSTEM SETTLEMENT
	# --------------------------------------------------------

	resource_system.process_month(world)

	if (
		is_equal_approx(float(china_stockpile.get("coal", 0.0)), 20.0)
		and is_equal_approx(float(india_stockpile.get("coal", 0.0)), 35.0)
		and is_equal_approx(float(china_stockpile.get("iron", 0.0)), 0.0)
		and is_equal_approx(float(india_stockpile.get("iron", 0.0)), 12.0)
	):
		TestLogger.write_line(
            "ResourceSystem settles executed trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "ResourceSystem settles executed trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# SNAPSHOT
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	if snapshot.trade_transaction_count >= 2:
		TestLogger.write_line("Snapshot trade transaction count: PASS")
	else:
		TestLogger.write_line("Snapshot trade transaction count: FAIL")
		all_passed = false

	if snapshot.trade_transactions.has(full_transaction_id):
		TestLogger.write_line("Snapshot full transaction capture: PASS")
	else:
		TestLogger.write_line("Snapshot full transaction capture: FAIL")
		all_passed = false

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	china_resources.state = china_original_state.duplicate(true)
	india_resources.state = india_original_state.duplicate(true)
	china_infrastructure.state = china_original_infrastructure.duplicate(true)
	india_infrastructure.state = india_original_infrastructure.duplicate(true)

	world.trade_transactions.erase(full_transaction_id)
	world.trade_transactions.erase(partial_transaction_id)
	world.trade_routes.erase(full_route_id)
	world.trade_routes.erase(partial_route_id)
	world.trade_agreements.erase(full_agreement_id)
	world.trade_agreements.erase(partial_agreement_id)

	for agreement_id in original_agreements.keys():
		world.trade_agreements[agreement_id] = original_agreements[agreement_id]

	for route_id in original_routes.keys():
		world.trade_routes[route_id] = original_routes[route_id]

	for transaction_id in original_transactions.keys():
		world.trade_transactions[transaction_id] = original_transactions[transaction_id]

	if (
		china_resources.state == china_original_state
		and india_resources.state == india_original_state
		and china_infrastructure.state == china_original_infrastructure
		and india_infrastructure.state == india_original_infrastructure
	):
		TestLogger.write_line("Trade transaction state restoration: PASS")
	else:
		TestLogger.write_line("Trade transaction state restoration: FAIL")
		all_passed = false

	TestLogger.write_line(
        "Trade Transaction 4.3 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _transaction_id(
	world: WorldState,
	agreement_id: String,
	route_id: String
) -> String:

	return (
        "trade_transaction_"
		+ str(int(world.current_date.get("year", 0)))
		+ "_"
		+ str(int(world.current_date.get("month", 0)))
		+ "_"
		+ agreement_id
		+ "_"
		+ route_id
	)
