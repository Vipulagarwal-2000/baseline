class_name TradeQuantityAvailabilityTest
extends RefCounted


# ============================================================
# TRADE — STEP 4.4 TEST
# ============================================================
#
# Validates explicit quantity / availability resolution using the
# registered TradeSystem.
#
# Scope:
# - requested quantity is preserved
# - exporter availability caps execution
# - route throughput caps execution
# - actual exported/imported quantities are explicit
# - unfulfilled quantity is explicit
# - ResourceComponent receives only actual scheduled quantity
# - route throughput state survives snapshots
# - previous 4.3-compatible transaction fields remain valid
#
# Step 4.5 physical infrastructure throughput is intentionally NOT
# calculated here.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE QUANTITY / AVAILABILITY TEST"
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
            "Required resource / infrastructure components available: FAIL"
		)
		return false

	TestLogger.write_line(
        "Required resource components available: PASS"
	)

	const stock_limited_agreement_id = "test_trade_agreement_4_4_stock"
	const stock_limited_route_id = "test_trade_route_4_4_stock"
	const route_limited_agreement_id = "test_trade_agreement_4_4_route"
	const route_limited_route_id = "test_trade_route_4_4_route"

	var original_china_state = china_resources.state.duplicate(true)
	var original_india_state = india_resources.state.duplicate(true)
	var original_china_infrastructure = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure = india_infrastructure.state.duplicate(true)

	var original_agreements: Dictionary = {}
	var original_routes: Dictionary = {}
	var original_transactions: Dictionary = {}

	for agreement_id in [
		stock_limited_agreement_id,
		route_limited_agreement_id
	]:
		if world.has_trade_agreement(agreement_id):
			original_agreements[agreement_id] = world.get_trade_agreement(
				agreement_id
			)

	for route_id in [
		stock_limited_route_id,
		route_limited_route_id
	]:
		if world.has_trade_route(route_id):
			original_routes[route_id] = world.get_trade_route(
				route_id
			)

	var stock_transaction_id = _transaction_id(
		world,
		stock_limited_agreement_id,
		stock_limited_route_id
	)

	var route_transaction_id = _transaction_id(
		world,
		route_limited_agreement_id,
		route_limited_route_id
	)

	for transaction_id in [
		stock_transaction_id,
		route_transaction_id
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
	china_consumption["coal"] = 0.0
	china_process_demand["coal"] = 0.0
	china_production["iron"] = 0.0
	china_consumption["iron"] = 0.0
	china_process_demand["iron"] = 0.0

	india_production["coal"] = 0.0
	india_consumption["coal"] = 0.0
	india_process_demand["coal"] = 0.0
	india_production["iron"] = 0.0
	india_consumption["iron"] = 0.0
	india_process_demand["iron"] = 0.0

	china_stockpile["coal"] = 7.0
	china_stockpile["iron"] = 0.0
	india_stockpile["coal"] = 0.0
	# Keep route-limited iron availability at 7 so 4.4 independently
	# demonstrates exporter availability = 7 and route throughput = 4.
	india_stockpile["iron"] = 7.0

	# --------------------------------------------------------
	# EXPORTER AVAILABILITY LIMIT
	# --------------------------------------------------------

	var stock_agreement := TradeAgreement.new(
		stock_limited_agreement_id,
		"china",
		"india",
		"coal",
		20.0,
		12
	)
	stock_agreement.activate(world.current_date)

	var stock_route := TradeRoute.new(
		stock_limited_route_id,
		stock_limited_agreement_id,
		"china",
        "india"
	)
	stock_route.activate()

	if not world.add_trade_agreement(stock_agreement):
		TestLogger.write_line("Exporter-limited agreement registration: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Exporter-limited agreement registration: PASS")

	if not world.add_trade_route(stock_route):
		TestLogger.write_line("Exporter-limited route registration: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Exporter-limited route registration: PASS")

	# --------------------------------------------------------
	# ROUTE THROUGHPUT LIMIT
	# --------------------------------------------------------

	var route_agreement := TradeAgreement.new(
		route_limited_agreement_id,
		"india",
		"china",
		"iron",
		10.0,
		12
	)
	route_agreement.activate(world.current_date)

	var route_limited_route := TradeRoute.new(
		route_limited_route_id,
		route_limited_agreement_id,
		"india",
		"china",
		4.0
	)
	route_limited_route.activate()

	if not world.add_trade_agreement(route_agreement):
		TestLogger.write_line("Route-limited agreement registration: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Route-limited agreement registration: PASS")

	if not world.add_trade_route(route_limited_route):
		TestLogger.write_line("Route-limited route registration: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Route-limited route registration: PASS")

	if not route_limited_route.has_throughput_limit():
		TestLogger.write_line("Route throughput limit recognized: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Route throughput limit recognized: PASS")

	if not is_equal_approx(
		route_limited_route.get_available_throughput(10.0),
		4.0
	):
		TestLogger.write_line("Route throughput clamps requested quantity: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Route throughput clamps requested quantity: PASS")

	# --------------------------------------------------------
	# QUANTITY RESOLUTION
	# --------------------------------------------------------

	trade_system.process_month(world)

	var stock_transaction = world.get_trade_transaction(
		stock_transaction_id
	)

	var route_transaction = world.get_trade_transaction(
		route_transaction_id
	)

	if stock_transaction == null or route_transaction == null:
		TestLogger.write_line("Quantity resolution transaction creation: FAIL")
		all_passed = false
	else:
		TestLogger.write_line("Quantity resolution transaction creation: PASS")

	if stock_transaction != null:
		var stock_ok = (
			is_equal_approx(stock_transaction.requested_quantity, 20.0)
			and is_equal_approx(stock_transaction.available_export_quantity, 7.0)
			and is_equal_approx(stock_transaction.route_available_quantity, 20.0)
			and is_equal_approx(stock_transaction.actual_exported_quantity, 7.0)
			and is_equal_approx(stock_transaction.actual_imported_quantity, 7.0)
			and is_equal_approx(stock_transaction.executed_quantity, 7.0)
			and is_equal_approx(stock_transaction.unfulfilled_quantity, 13.0)
			and stock_transaction.status == TradeTransaction.STATUS_UNFULFILLED
		)

		if stock_ok:
			TestLogger.write_line(
                "Exporter availability caps actual trade quantity: PASS"
			)
		else:
			TestLogger.write_line(
                "Exporter availability caps actual trade quantity: FAIL"
			)
			all_passed = false

	if route_transaction != null:
		var route_ok = (
			is_equal_approx(route_transaction.requested_quantity, 10.0)
			and is_equal_approx(route_transaction.available_export_quantity, 7.0)
			and is_equal_approx(route_transaction.route_available_quantity, 4.0)
			and is_equal_approx(route_transaction.actual_exported_quantity, 4.0)
			and is_equal_approx(route_transaction.actual_imported_quantity, 4.0)
			and is_equal_approx(route_transaction.executed_quantity, 4.0)
			and is_equal_approx(route_transaction.unfulfilled_quantity, 6.0)
			and route_transaction.status == TradeTransaction.STATUS_UNFULFILLED
		)

		if route_ok:
			TestLogger.write_line(
                "Route throughput caps actual trade quantity: PASS"
			)
		else:
			TestLogger.write_line(
                "Route throughput caps actual trade quantity: FAIL"
			)
			all_passed = false

	# --------------------------------------------------------
	# RESOURCE FLOW STATE
	# --------------------------------------------------------

	var china_exports = china_resources.get_state("exports", {})
	var india_exports = india_resources.get_state("exports", {})
	var china_imports = china_resources.get_state("imports", {})
	var india_imports = india_resources.get_state("imports", {})

	if (
		is_equal_approx(float(china_exports.get("coal", 0.0)), 7.0)
		and is_equal_approx(float(india_imports.get("coal", 0.0)), 7.0)
		and is_equal_approx(float(india_exports.get("iron", 0.0)), 4.0)
		and is_equal_approx(float(china_imports.get("iron", 0.0)), 4.0)
	):
		TestLogger.write_line(
            "ResourceComponent schedules actual rather than requested quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "ResourceComponent schedules actual rather than requested quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# SNAPSHOT
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_route = snapshot.trade_routes.get(
		route_limited_route_id,
		{}
	)

	var snapshot_transaction = snapshot.trade_transactions.get(
		route_transaction_id,
		{}
	)

	if is_equal_approx(
		float(snapshot_route.get("monthly_throughput_capacity", -999.0)),
		4.0
	):
		TestLogger.write_line(
            "Snapshot route throughput state: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot route throughput state: FAIL"
		)
		all_passed = false

	if (
		is_equal_approx(float(snapshot_transaction.get("available_export_quantity", -1.0)), 7.0)
		and is_equal_approx(float(snapshot_transaction.get("route_available_quantity", -1.0)), 4.0)
		and is_equal_approx(float(snapshot_transaction.get("actual_exported_quantity", -1.0)), 4.0)
		and is_equal_approx(float(snapshot_transaction.get("actual_imported_quantity", -1.0)), 4.0)
		and is_equal_approx(float(snapshot_transaction.get("unfulfilled_quantity", -1.0)), 6.0)
	):
		TestLogger.write_line(
            "Snapshot quantity / availability state: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot quantity / availability state: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	china_resources.state = original_china_state.duplicate(true)
	india_resources.state = original_india_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure.duplicate(true)
	india_infrastructure.state = original_india_infrastructure.duplicate(true)

	world.trade_transactions.erase(stock_transaction_id)
	world.trade_transactions.erase(route_transaction_id)
	world.trade_routes.erase(stock_limited_route_id)
	world.trade_routes.erase(route_limited_route_id)
	world.trade_agreements.erase(stock_limited_agreement_id)
	world.trade_agreements.erase(route_limited_agreement_id)

	for agreement_id in original_agreements.keys():
		world.trade_agreements[agreement_id] = original_agreements[agreement_id]

	for route_id in original_routes.keys():
		world.trade_routes[route_id] = original_routes[route_id]

	for transaction_id in original_transactions.keys():
		world.trade_transactions[transaction_id] = original_transactions[transaction_id]

	if (
		china_resources.state == original_china_state
		and india_resources.state == original_india_state
		and china_infrastructure.state == original_china_infrastructure
		and india_infrastructure.state == original_india_infrastructure
	):
		TestLogger.write_line("Trade 4.4 state restoration: PASS")
	else:
		TestLogger.write_line("Trade 4.4 state restoration: FAIL")
		all_passed = false

	TestLogger.write_line(
        "Trade Quantity / Availability 4.4 overall: "
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
