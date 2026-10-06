class_name TradeTransportPortConstraintsTest
extends RefCounted


# ============================================================
# TRADE — STEP 4.5 TEST
# ============================================================
#
# Validates that TradeSystem consumes the existing
# InfrastructureComponent state without creating a second
# infrastructure calculation model.
#
# Covered constraints:
#   ports
#   transport
#   roads accessibility
#   railways accessibility
#   weakest endpoint resolution
#   combined infrastructure bottleneck
#   ResourceSystem settlement without double-applying port throughput
#   transaction snapshot persistence
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE TRANSPORT / PORT CONSTRAINTS TEST"
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
        "Required resource / infrastructure components available: PASS"
	)

	const agreement_id = "test_trade_agreement_4_5_infra"
	const route_id = "test_trade_route_4_5_infra"

	var original_date = world.current_date.duplicate(true)
	var original_china_resource_state = china_resources.state.duplicate(true)
	var original_india_resource_state = india_resources.state.duplicate(true)
	var original_china_infrastructure_state = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state = india_infrastructure.state.duplicate(true)

	var original_agreement = null
	var original_route = null
	var original_transactions: Dictionary = {}

	if world.has_trade_agreement(agreement_id):
		original_agreement = world.get_trade_agreement(agreement_id)

	if world.has_trade_route(route_id):
		original_route = world.get_trade_route(route_id)

	var generated_transaction_ids: Array[String] = []

	if not _prepare_fixture(
		world,
		china_resources,
		india_resources,
		china_infrastructure,
		india_infrastructure,
		agreement_id,
		route_id
	):
		TestLogger.write_line("Controlled 4.5 fixture setup: FAIL")
		_restore_state(
			world,
			china_resources,
			india_resources,
			china_infrastructure,
			india_infrastructure,
			original_date,
			original_china_resource_state,
			original_india_resource_state,
			original_china_infrastructure_state,
			original_india_infrastructure_state,
			agreement_id,
			route_id,
			original_agreement,
			original_route,
			generated_transaction_ids
		)
		return false

	TestLogger.write_line("Controlled 4.5 fixture setup: PASS")

	var all_passed := true

	# --------------------------------------------------------
	# BASELINE — ALL INFRASTRUCTURE AT 100%
	# --------------------------------------------------------

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)

	var baseline_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if baseline_transaction != null and (
		is_equal_approx(baseline_transaction.actual_exported_quantity, 40.0)
		and is_equal_approx(baseline_transaction.actual_imported_quantity, 40.0)
		and is_equal_approx(baseline_transaction.port_available_quantity, 40.0)
		and is_equal_approx(baseline_transaction.transport_available_quantity, 40.0)
		and is_equal_approx(baseline_transaction.roads_available_quantity, 40.0)
		and is_equal_approx(baseline_transaction.railways_available_quantity, 40.0)
		and is_equal_approx(baseline_transaction.infrastructure_available_quantity, 40.0)
	):
		TestLogger.write_line(
            "Full infrastructure preserves requested trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "Full infrastructure preserves requested trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# PORT BOTTLENECK
	# --------------------------------------------------------

	_advance_test_month(world)

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)
	china_infrastructure.state["ports"] = 0.5

	var port_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if port_transaction != null and (
		is_equal_approx(port_transaction.port_available_quantity, 20.0)
		and is_equal_approx(port_transaction.infrastructure_available_quantity, 20.0)
		and is_equal_approx(port_transaction.actual_exported_quantity, 20.0)
	):
		TestLogger.write_line(
            "Port throughput limits trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "Port throughput limits trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# TRANSPORT BOTTLENECK
	# --------------------------------------------------------

	_advance_test_month(world)

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)
	china_infrastructure.state["transport"] = 0.5

	var transport_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if transport_transaction != null and (
		is_equal_approx(transport_transaction.transport_available_quantity, 20.0)
		and is_equal_approx(transport_transaction.infrastructure_available_quantity, 20.0)
		and is_equal_approx(transport_transaction.actual_exported_quantity, 20.0)
	):
		TestLogger.write_line(
            "Transport availability limits trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "Transport availability limits trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# ROADS BOTTLENECK
	# --------------------------------------------------------

	_advance_test_month(world)

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)
	china_infrastructure.state["roads"] = 0.5

	var roads_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if roads_transaction != null and (
		is_equal_approx(roads_transaction.roads_available_quantity, 20.0)
		and is_equal_approx(roads_transaction.infrastructure_available_quantity, 20.0)
		and is_equal_approx(roads_transaction.actual_exported_quantity, 20.0)
	):
		TestLogger.write_line(
            "Road accessibility limits trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "Road accessibility limits trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# RAILWAY BOTTLENECK
	# --------------------------------------------------------

	_advance_test_month(world)

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)
	china_infrastructure.state["railways"] = 0.5

	var railway_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if railway_transaction != null and (
		is_equal_approx(railway_transaction.railways_available_quantity, 20.0)
		and is_equal_approx(railway_transaction.infrastructure_available_quantity, 20.0)
		and is_equal_approx(railway_transaction.actual_exported_quantity, 20.0)
	):
		TestLogger.write_line(
            "Railway accessibility limits trade quantity: PASS"
		)
	else:
		TestLogger.write_line(
            "Railway accessibility limits trade quantity: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# WEAKEST ENDPOINT + RESOURCE SETTLEMENT
	# --------------------------------------------------------

	_advance_test_month(world)

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)

	# Different endpoint values prove that TradeSystem consumes the
	# existing country infrastructure and resolves the weaker side.
	china_infrastructure.state["ports"] = 0.5
	china_infrastructure.state["transport"] = 0.8
	china_infrastructure.state["roads"] = 0.7
	china_infrastructure.state["railways"] = 0.9

	india_infrastructure.state["ports"] = 0.8
	india_infrastructure.state["transport"] = 0.6
	india_infrastructure.state["roads"] = 0.5
	india_infrastructure.state["railways"] = 0.9

	var combined_transaction_id = _transaction_id(
		world,
		agreement_id,
		route_id
	)

	var combined_transaction = _run_trade_month(
		world,
		trade_system,
		agreement_id,
		route_id,
		generated_transaction_ids
	)

	if combined_transaction != null and (
		is_equal_approx(combined_transaction.port_available_quantity, 20.0)
		and is_equal_approx(combined_transaction.transport_available_quantity, 24.0)
		and is_equal_approx(combined_transaction.roads_available_quantity, 20.0)
		and is_equal_approx(combined_transaction.railways_available_quantity, 36.0)
		and is_equal_approx(combined_transaction.infrastructure_available_quantity, 20.0)
		and is_equal_approx(combined_transaction.actual_exported_quantity, 20.0)
		and is_equal_approx(combined_transaction.actual_imported_quantity, 20.0)
	):
		TestLogger.write_line(
            "Weakest infrastructure endpoint resolves final trade capacity: PASS"
		)
	else:
		TestLogger.write_line(
            "Weakest infrastructure endpoint resolves final trade capacity: FAIL"
		)
		all_passed = false

	# ResourceSystem must settle the physical trade quantity once. The
	# trade flow is already port-constrained, so it must not be halved again.
	var china_stockpile = china_resources.get_state("stockpile", {})
	var india_stockpile = india_resources.get_state("stockpile", {})

	resource_system.process_month(world)

	if (
		is_equal_approx(float(china_stockpile.get("coal", 0.0)), 80.0)
		and is_equal_approx(float(india_stockpile.get("coal", 0.0)), 20.0)
	):
		TestLogger.write_line(
            "ResourceSystem settles infrastructure-constrained trade once: PASS"
		)
	else:
		TestLogger.write_line(
            "ResourceSystem settles infrastructure-constrained trade once: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# SNAPSHOT
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_transaction = snapshot.trade_transactions.get(
		combined_transaction_id,
		{}
	)

	if (
		is_equal_approx(
			float(snapshot_transaction.get("port_available_quantity", -1.0)),
			20.0
		)
		and is_equal_approx(
			float(snapshot_transaction.get("transport_available_quantity", -1.0)),
			24.0
		)
		and is_equal_approx(
			float(snapshot_transaction.get("roads_available_quantity", -1.0)),
			20.0
		)
		and is_equal_approx(
			float(snapshot_transaction.get("railways_available_quantity", -1.0)),
			36.0
		)
		and is_equal_approx(
			float(snapshot_transaction.get("infrastructure_available_quantity", -1.0)),
			20.0
		)
		and is_equal_approx(
			float(snapshot_transaction.get("actual_imported_quantity", -1.0)),
			20.0
		)
	):
		TestLogger.write_line(
            "Snapshot physical trade constraint state: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot physical trade constraint state: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	_restore_state(
		world,
		china_resources,
		india_resources,
		china_infrastructure,
		india_infrastructure,
		original_date,
		original_china_resource_state,
		original_india_resource_state,
		original_china_infrastructure_state,
		original_india_infrastructure_state,
		agreement_id,
		route_id,
		original_agreement,
		original_route,
		generated_transaction_ids
	)

	if (
		world.current_date == original_date
		and china_resources.state == original_china_resource_state
		and india_resources.state == original_india_resource_state
		and china_infrastructure.state == original_china_infrastructure_state
		and india_infrastructure.state == original_india_infrastructure_state
	):
		TestLogger.write_line("Trade 4.5 state restoration: PASS")
	else:
		TestLogger.write_line("Trade 4.5 state restoration: FAIL")
		all_passed = false

	TestLogger.write_line(
        "Trade Transport / Port Constraints 4.5 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _prepare_fixture(
	world: WorldState,
	china_resources: ResourceComponent,
	india_resources: ResourceComponent,
	china_infrastructure: InfrastructureComponent,
	india_infrastructure: InfrastructureComponent,
	agreement_id: String,
	route_id: String
) -> bool:

	world.trade_transactions.erase(
		_transaction_id(world, agreement_id, route_id)
	)
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)

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

	china_production["coal"] = 0.0
	china_consumption["coal"] = 0.0
	china_process_demand["coal"] = 0.0
	china_stockpile["coal"] = 100.0

	india_production["coal"] = 0.0
	india_consumption["coal"] = 0.0
	india_process_demand["coal"] = 0.0
	india_stockpile["coal"] = 0.0

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		40.0,
		12
	)

	if not agreement.activate(world.current_date):
		return false

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)

	if not route.activate():
		return false

	if not world.add_trade_agreement(agreement):
		return false

	if not world.add_trade_route(route):
		world.trade_agreements.erase(agreement_id)
		return false

	return true


static func _set_all_trade_infrastructure(
	infrastructure: InfrastructureComponent,
	value: float
) -> void:

	infrastructure.state["ports"] = value
	infrastructure.state["transport"] = value
	infrastructure.state["roads"] = value
	infrastructure.state["railways"] = value


static func _run_trade_month(
	world: WorldState,
	trade_system,
	agreement_id: String,
	route_id: String,
	generated_transaction_ids: Array[String]
):

	trade_system.process_month(world)

	var transaction_id = _transaction_id(
		world,
		agreement_id,
		route_id
	)

	generated_transaction_ids.append(transaction_id)

	var transaction = world.get_trade_transaction(
		transaction_id
	)

	return transaction


static func _advance_test_month(world: WorldState) -> void:

	world.current_date.month += 1

	if world.current_date.month > 12:
		world.current_date.month = 1
		world.current_date.year += 1


static func _restore_state(
	world: WorldState,
	china_resources: ResourceComponent,
	india_resources: ResourceComponent,
	china_infrastructure: InfrastructureComponent,
	india_infrastructure: InfrastructureComponent,
	original_date: Dictionary,
	original_china_resource_state: Dictionary,
	original_india_resource_state: Dictionary,
	original_china_infrastructure_state: Dictionary,
	original_india_infrastructure_state: Dictionary,
	agreement_id: String,
	route_id: String,
	original_agreement,
	original_route,
	generated_transaction_ids: Array[String]
) -> void:

	world.current_date = original_date.duplicate(true)

	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)

	for transaction_id in generated_transaction_ids:
		world.trade_transactions.erase(transaction_id)

	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(agreement_id)

	if original_agreement != null:
		world.trade_agreements[agreement_id] = original_agreement

	if original_route != null:
		world.trade_routes[route_id] = original_route


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
