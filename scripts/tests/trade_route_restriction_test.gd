class_name TradeRouteRestrictionTest
extends RefCounted


# ============================================================
# TRADE — STEP 11.2 TEST
# ============================================================
#
# Validates the lightweight route restriction / blockade layer:
#   - registered restriction system
#   - unrestricted baseline throughput
#   - partial restriction scales effective throughput
#   - base route capacity remains unchanged
#   - identical restriction is idempotent
#   - TradeSystem consumes the restricted effective quantity
#   - complete restriction resolves to zero effective throughput
#   - unrelated route remains unaffected
#   - snapshot preserves restriction state
#   - snapshot state is deep-copy isolated
#   - restriction removal restores original route semantics
#   - trade resumes at the original route capacity after removal
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"TRADE ROUTE RESTRICTION / BLOCKADE 11.2 TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var restriction_system: TradeRouteRestrictionSystem = (
		simulation.get_system("trade_route_restriction_system")
		as TradeRouteRestrictionSystem
	)

	var trade_system: TradeSystem = (
		simulation.get_system("trade_system")
		as TradeSystem
	)

	var all_passed: bool = true

	all_passed = _assert(
		restriction_system != null,
		"Registered TradeRouteRestrictionSystem available",
		all_passed
	)

	all_passed = _assert(
		trade_system != null,
		"Registered TradeSystem available",
		all_passed
	)

	if restriction_system == null or trade_system == null:
		return false

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	all_passed = _assert(
		china != null and india != null,
		"China and India available",
		all_passed
	)

	if china == null or india == null:
		return false

	var china_resources = china.get_component("resources")
	var india_resources = india.get_component("resources")
	var china_infrastructure = china.get_component("infrastructure")
	var india_infrastructure = india.get_component("infrastructure")

	all_passed = _assert(
		china_resources != null
		and india_resources != null
		and china_infrastructure != null
		and india_infrastructure != null,
		"Required resource / infrastructure components available",
		all_passed
	)

	if (
		china_resources == null
		or india_resources == null
		or china_infrastructure == null
		or india_infrastructure == null
	):
		return false

	const agreement_id: String = "test_trade_agreement_11_2_route_restriction"
	const route_id: String = "test_trade_route_11_2_route_restriction"
	const other_agreement_id: String = "test_trade_agreement_11_2_unrelated"
	const other_route_id: String = "test_trade_route_11_2_unrelated"

	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_china_resource_state: Dictionary = china_resources.state.duplicate(true)
	var original_india_resource_state: Dictionary = india_resources.state.duplicate(true)
	var original_china_infrastructure_state: Dictionary = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state: Dictionary = india_infrastructure.state.duplicate(true)
	var original_trade_transactions: Dictionary = world.trade_transactions.duplicate(true)

	var original_agreement = world.trade_agreements.get(
		agreement_id,
		null
	)
	var original_route = world.trade_routes.get(
		route_id,
		null
	)
	var original_other_agreement = world.trade_agreements.get(
		other_agreement_id,
		null
	)
	var original_other_route = world.trade_routes.get(
		other_route_id,
		null
	)

	_set_all_trade_infrastructure(china_infrastructure, 1.0)
	_set_all_trade_infrastructure(india_infrastructure, 1.0)

	var china_stockpile: Dictionary = china_resources.get_state(
		"stockpile",
		{}
	)
	china_stockpile["coal"] = 200.0

	var agreement: TradeAgreement = TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		80.0,
		3
	)
	agreement.activate(world.current_date)

	var route: TradeRoute = TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)
	route.activate()

	var other_agreement: TradeAgreement = TradeAgreement.new(
		other_agreement_id,
		"china",
		"india",
		"iron",
		40.0,
		3
	)
	other_agreement.activate(world.current_date)

	var other_route: TradeRoute = TradeRoute.new(
		other_route_id,
		other_agreement_id,
		"china",
		"india",
		100.0
	)
	other_route.activate()

	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(other_agreement_id)
	world.trade_routes.erase(other_route_id)

	if (
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
		and world.add_trade_agreement(other_agreement)
		and world.add_trade_route(other_route)
	):
		TestLogger.write_line(
			"Controlled agreement / route fixture registration: PASS"
		)
	else:
		TestLogger.write_line(
			"Controlled agreement / route fixture registration: FAIL"
		)
		all_passed = false

	# ========================================================
	# BASELINE
	# ========================================================

	trade_system.process_month(world)

	var baseline_transaction_id: String = _transaction_id(
		world,
		agreement_id,
		route_id
	)

	var baseline_transaction = world.trade_transactions.get(
		baseline_transaction_id,
		null
	)

	all_passed = _assert(
		baseline_transaction != null
		and is_equal_approx(
			float(baseline_transaction.actual_exported_quantity),
			80.0
		),
		"Unrestricted route executes full requested quantity",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(route.monthly_throughput_capacity, 100.0),
		"Base route capacity remains 100 before restriction",
		all_passed
	)

	# ========================================================
	# PARTIAL ROUTE RESTRICTION
	# ========================================================

	_advance_test_month(world)

	var restricted: bool = restriction_system.apply_route_restriction(
		world,
		route_id,
		0.25,
		"blockade"
	)

	all_passed = _assert(
		restricted,
		"Partial route restriction applies",
		all_passed
	)

	all_passed = _assert(
		route.has_route_restriction()
		and is_equal_approx(route.route_restriction_factor, 0.25)
		and route.route_restriction_reason == "blockade",
		"Route restriction state is explicit",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(route.monthly_throughput_capacity, 100.0),
		"Route restriction does not overwrite base throughput capacity",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			route.get_available_throughput(80.0),
			20.0
		),
		"25% route capacity resolves to 20 units",
		all_passed
	)

	var repeated_application: bool = restriction_system.apply_route_restriction(
		world,
		route_id,
		0.25,
		"blockade"
	)

	all_passed = _assert(
		not repeated_application,
		"Repeated identical route restriction is idempotent",
		all_passed
	)

	trade_system.process_month(world)

	var partial_transaction_id: String = _transaction_id(
		world,
		agreement_id,
		route_id
	)

	var partial_transaction = world.trade_transactions.get(
		partial_transaction_id,
		null
	)

	all_passed = _assert(
		partial_transaction != null
		and is_equal_approx(
			float(partial_transaction.actual_exported_quantity),
			20.0
		),
		"TradeSystem executes only restricted route quantity",
		all_passed
	)

	all_passed = _assert(
		not other_route.has_route_restriction()
		and is_equal_approx(
			other_route.get_available_throughput(40.0),
			40.0
		),
		"Unrelated route remains unaffected",
		all_passed
	)

	# ========================================================
	# COMPLETE ROUTE BLOCK
	# ========================================================

	_advance_test_month(world)

	var fully_blocked: bool = restriction_system.apply_route_restriction(
		world,
		route_id,
		0.0,
		"full_blockade"
	)

	all_passed = _assert(
		fully_blocked,
		"Complete route restriction applies",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(
			route.get_available_throughput(80.0),
			0.0
		),
		"Complete route restriction resolves to zero effective throughput",
		all_passed
	)

	# The existing TradeSystem records zero-quantity transactions and still
	# advances contract duration when a route resolves to zero throughput.
	# Step 11.2 only establishes the route-capacity block; that broader
	# execution-status behavior belongs to Step 11.3.

	# ========================================================
	# SNAPSHOT
	# ========================================================

	var snapshot: WorldSnapshot = WorldSnapshot.new()
	snapshot.capture(world)

	var captured = snapshot.trade_routes.get(
		route_id,
		null
	)

	all_passed = _assert(
		captured != null
		and bool(captured.get("route_restriction_active", false))
		and is_equal_approx(
			float(captured.get("route_restriction_factor", -1.0)),
			0.0
		)
		and captured.get("route_restriction_reason", "") == "full_blockade",
		"Snapshot preserves complete route restriction state",
		all_passed
	)

	if captured != null:
		captured["route_restriction_factor"] = 0.75

	all_passed = _assert(
		is_equal_approx(route.route_restriction_factor, 0.0),
		"Snapshot route restriction state is deep-copy isolated",
		all_passed
	)

	# ========================================================
	# REMOVE RESTRICTION
	# ========================================================

	var removed: bool = restriction_system.clear_route_restriction(
		world,
		route_id
	)

	all_passed = _assert(
		removed,
		"Route restriction clears explicitly",
		all_passed
	)

	all_passed = _assert(
		not route.has_route_restriction()
		and is_equal_approx(route.route_restriction_factor, 1.0)
		and route.route_restriction_reason.is_empty(),
		"Route returns to unrestricted state",
		all_passed
	)

	all_passed = _assert(
		is_equal_approx(route.monthly_throughput_capacity, 100.0)
		and is_equal_approx(
			route.get_available_throughput(80.0),
			80.0
		),
		"Removing restriction restores original route throughput semantics",
		all_passed
	)

	trade_system.process_month(world)

	var resumed_transaction_id: String = _transaction_id(
		world,
		agreement_id,
		route_id
	)

	var resumed_transaction = world.trade_transactions.get(
		resumed_transaction_id,
		null
	)

	all_passed = _assert(
		resumed_transaction != null
		and is_equal_approx(
			float(resumed_transaction.actual_exported_quantity),
			80.0
		),
		"Trade resumes at full route capacity after removal",
		all_passed
	)

	# ========================================================
	# RESTORE FIXTURE
	# ========================================================

	world.current_date = original_date.duplicate(true)
	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)
	world.trade_transactions = original_trade_transactions.duplicate(true)

	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(other_route_id)
	world.trade_agreements.erase(other_agreement_id)

	if original_route != null:
		world.trade_routes[route_id] = original_route

	if original_agreement != null:
		world.trade_agreements[agreement_id] = original_agreement

	if original_other_route != null:
		world.trade_routes[other_route_id] = original_other_route

	if original_other_agreement != null:
		world.trade_agreements[other_agreement_id] = original_other_agreement

	TestLogger.write_line(
		"Trade Route Restriction 11.2 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


static func _assert(
	condition: bool,
	label: String,
	current: bool
) -> bool:

	if condition:
		TestLogger.write_line(label + ": PASS")
		return current

	TestLogger.write_line(label + ": FAIL")
	return false


static func _set_all_trade_infrastructure(
	infrastructure: InfrastructureComponent,
	value: float
) -> void:

	infrastructure.state["ports"] = value
	infrastructure.state["transport"] = value
	infrastructure.state["roads"] = value
	infrastructure.state["railways"] = value


static func _advance_test_month(
	world: WorldState
) -> void:

	world.current_date.month += 1

	if world.current_date.month > 12:
		world.current_date.month = 1
		world.current_date.year += 1


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
