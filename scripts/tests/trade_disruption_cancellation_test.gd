class_name TradeDisruptionCancellationTest
extends RefCounted


# ============================================================
# TRADE — STEP 4.7 TEST
# ============================================================
#
# Validates the minimum disruption / cancellation lifecycle:
#   - explicit interruption pauses trade without consuming duration
#   - interruption records a cause
#   - interrupted agreements can resume explicitly
#   - cancellation is terminal
#   - cancelled agreements cannot resume or reactivate
#   - a disrupted linked route automatically interrupts an active agreement
#   - restored route infrastructure does not silently resume an interrupted
#     agreement
#   - snapshot preserves disruption / cancellation lifecycle state
#
# Broader diplomacy, conflict, and country-decision systems are intentionally
# not implemented here. The country-decision cause is represented only as a
# lifecycle reason on explicit cancellation.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE DISRUPTION / CANCELLATION TEST"
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

	if trade_system == null:
		TestLogger.write_line("Registered TradeSystem available: FAIL")
		return false

	TestLogger.write_line("Registered TradeSystem available: PASS")

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

	const interruption_agreement_id = "test_trade_agreement_4_7_interruption"
	const interruption_route_id = "test_trade_route_4_7_interruption"
	const route_disruption_agreement_id = "test_trade_agreement_4_7_route_disruption"
	const route_disruption_route_id = "test_trade_route_4_7_route_disruption"
	const cancellation_agreement_id = "test_trade_agreement_4_7_cancellation"
	const cancellation_route_id = "test_trade_route_4_7_cancellation"

	var original_date = world.current_date.duplicate(true)
	var original_china_resource_state = china_resources.state.duplicate(true)
	var original_india_resource_state = india_resources.state.duplicate(true)
	var original_china_infrastructure_state = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state = india_infrastructure.state.duplicate(true)

	var original_objects := {
		"interruption_agreement": world.trade_agreements.get(interruption_agreement_id, null),
		"interruption_route": world.trade_routes.get(interruption_route_id, null),
		"route_disruption_agreement": world.trade_agreements.get(route_disruption_agreement_id, null),
		"route_disruption_route": world.trade_routes.get(route_disruption_route_id, null),
		"cancellation_agreement": world.trade_agreements.get(cancellation_agreement_id, null),
		"cancellation_route": world.trade_routes.get(cancellation_route_id, null)
	}

	var generated_transaction_ids: Array[String] = []
	var all_passed := true

	_set_all_trade_infrastructure(china_infrastructure, 1.0)
	_set_all_trade_infrastructure(india_infrastructure, 1.0)

	var china_stockpile = china_resources.get_state("stockpile", {})
	var india_stockpile = india_resources.get_state("stockpile", {})

	china_stockpile["coal"] = 200.0
	india_stockpile["coal"] = 0.0

	# ========================================================
	# EXPLICIT INTERRUPTION
	# ========================================================

	var interruption_agreement := TradeAgreement.new(
		interruption_agreement_id,
		"china",
		"india",
		"coal",
		20.0,
		3
	)

	var start_date := world.current_date.duplicate(true)
	interruption_agreement.activate(start_date)

	var interruption_route := TradeRoute.new(
		interruption_route_id,
		interruption_agreement_id,
		"china",
		"india",
		100.0
	)
	interruption_route.activate()

	world.trade_agreements.erase(interruption_agreement_id)
	world.trade_routes.erase(interruption_route_id)

	if (
		world.add_trade_agreement(interruption_agreement)
		and world.add_trade_route(interruption_route)
	):
		TestLogger.write_line(
            "Explicit interruption agreement / route registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Explicit interruption agreement / route registration: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var first_transaction_id := _transaction_id(
		world,
		interruption_agreement_id,
		interruption_route_id
	)
	generated_transaction_ids.append(first_transaction_id)

	if (
		world.has_trade_transaction(first_transaction_id)
		and interruption_agreement.remaining_duration_months == 2
	):
		TestLogger.write_line(
            "Pre-interruption month executes and consumes one contract month: PASS"
		)
	else:
		TestLogger.write_line(
            "Pre-interruption month executes and consumes one contract month: FAIL"
		)
		all_passed = false

	var interrupted_remaining = interruption_agreement.remaining_duration_months

	if interruption_agreement.interrupt(TradeAgreement.CAUSE_MANUAL):
		TestLogger.write_line(
            "Explicit interruption changes agreement state: PASS"
		)
	else:
		TestLogger.write_line(
            "Explicit interruption changes agreement state: FAIL"
		)
		all_passed = false

	if (
		interruption_agreement.status == TradeAgreement.STATUS_INTERRUPTED
		and interruption_agreement.lifecycle_reason == TradeAgreement.CAUSE_MANUAL
		and interruption_agreement.remaining_duration_months == interrupted_remaining
	):
		TestLogger.write_line(
            "Interruption preserves duration and records cause: PASS"
		)
	else:
		TestLogger.write_line(
            "Interruption preserves duration and records cause: FAIL"
		)
		all_passed = false

	_advance_test_month(world)
	trade_system.process_month(world)

	var interrupted_transaction_id := _transaction_id(
		world,
		interruption_agreement_id,
		interruption_route_id
	)

	if (
		not world.has_trade_transaction(interrupted_transaction_id)
		and interruption_agreement.remaining_duration_months == interrupted_remaining
	):
		TestLogger.write_line(
            "Interrupted agreement blocks trade without consuming duration: PASS"
		)
	else:
		TestLogger.write_line(
            "Interrupted agreement blocks trade without consuming duration: FAIL"
		)
		all_passed = false

	var interruption_snapshot := WorldSnapshot.new()
	interruption_snapshot.capture(world)
	var interruption_snapshot_state = interruption_snapshot.trade_agreements.get(
		interruption_agreement_id,
		{}
	)

	if (
		interruption_snapshot_state.get("status", "") == TradeAgreement.STATUS_INTERRUPTED
		and interruption_snapshot_state.get("lifecycle_reason", "") == TradeAgreement.CAUSE_MANUAL
	):
		TestLogger.write_line(
            "Snapshot preserves interruption state and cause: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot preserves interruption state and cause: FAIL"
		)
		all_passed = false

	if interruption_agreement.resume():
		TestLogger.write_line(
            "Interrupted agreement resumes explicitly: PASS"
		)
	else:
		TestLogger.write_line(
            "Interrupted agreement resumes explicitly: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var resumed_transaction_id := _transaction_id(
		world,
		interruption_agreement_id,
		interruption_route_id
	)
	generated_transaction_ids.append(resumed_transaction_id)

	if (
		world.has_trade_transaction(resumed_transaction_id)
		and interruption_agreement.remaining_duration_months == interrupted_remaining - 1
		and interruption_agreement.status == TradeAgreement.STATUS_ACTIVE
	):
		TestLogger.write_line(
            "Resumed agreement executes and resumes duration progression: PASS"
		)
	else:
		TestLogger.write_line(
            "Resumed agreement executes and resumes duration progression: FAIL"
		)
		all_passed = false

	# ========================================================
	# ROUTE DISRUPTION -> AUTOMATIC INTERRUPTION
	# ========================================================

	var route_disruption_agreement := TradeAgreement.new(
		route_disruption_agreement_id,
		"china",
		"india",
		"coal",
		15.0,
		2
	)
	route_disruption_agreement.activate(world.current_date)

	var route_disruption_route := TradeRoute.new(
		route_disruption_route_id,
		route_disruption_agreement_id,
		"china",
		"india",
		100.0
	)
	route_disruption_route.activate()

	world.trade_agreements.erase(route_disruption_agreement_id)
	world.trade_routes.erase(route_disruption_route_id)

	if (
		world.add_trade_agreement(route_disruption_agreement)
		and world.add_trade_route(route_disruption_route)
	):
		TestLogger.write_line(
            "Route-disruption agreement / route registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Route-disruption agreement / route registration: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var route_first_transaction_id := _transaction_id(
		world,
		route_disruption_agreement_id,
		route_disruption_route_id
	)
	generated_transaction_ids.append(route_first_transaction_id)

	if world.has_trade_transaction(route_first_transaction_id):
		TestLogger.write_line(
            "Route-disruption contract trades before disruption: PASS"
		)
	else:
		TestLogger.write_line(
            "Route-disruption contract trades before disruption: FAIL"
		)
		all_passed = false

	route_disruption_route.disrupt()
	var route_disruption_remaining = route_disruption_agreement.remaining_duration_months

	_advance_test_month(world)
	trade_system.process_month(world)

	var route_disruption_transaction_id := _transaction_id(
		world,
		route_disruption_agreement_id,
		route_disruption_route_id
	)

	if (
		route_disruption_agreement.status == TradeAgreement.STATUS_INTERRUPTED
		and route_disruption_agreement.lifecycle_reason == TradeAgreement.CAUSE_ROUTE_DISRUPTION
		and route_disruption_agreement.remaining_duration_months == route_disruption_remaining
		and not world.has_trade_transaction(route_disruption_transaction_id)
	):
		TestLogger.write_line(
            "Disrupted route automatically interrupts agreement and preserves duration: PASS"
		)
	else:
		TestLogger.write_line(
            "Disrupted route automatically interrupts agreement and preserves duration: FAIL"
		)
		all_passed = false

	route_disruption_route.activate()
	trade_system.process_month(world)

	if (
		route_disruption_agreement.status == TradeAgreement.STATUS_INTERRUPTED
		and not world.has_trade_transaction(route_disruption_transaction_id)
	):
		TestLogger.write_line(
            "Restored route does not silently resume interrupted agreement: PASS"
		)
	else:
		TestLogger.write_line(
            "Restored route does not silently resume interrupted agreement: FAIL"
		)
		all_passed = false

	if route_disruption_agreement.resume():
		TestLogger.write_line(
            "Route-disrupted agreement can resume explicitly after route recovery: PASS"
		)
	else:
		TestLogger.write_line(
            "Route-disrupted agreement can resume explicitly after route recovery: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var resumed_route_transaction_id := _transaction_id(
		world,
		route_disruption_agreement_id,
		route_disruption_route_id
	)
	generated_transaction_ids.append(resumed_route_transaction_id)

	if world.has_trade_transaction(resumed_route_transaction_id):
		TestLogger.write_line(
            "Explicitly resumed route-disrupted agreement executes: PASS"
		)
	else:
		TestLogger.write_line(
            "Explicitly resumed route-disrupted agreement executes: FAIL"
		)
		all_passed = false

	# ========================================================
	# CANCELLATION
	# ========================================================

	var cancellation_agreement := TradeAgreement.new(
		cancellation_agreement_id,
		"china",
		"india",
		"coal",
		10.0,
		3
	)
	cancellation_agreement.activate(world.current_date)

	var cancellation_route := TradeRoute.new(
		cancellation_route_id,
		cancellation_agreement_id,
		"china",
		"india",
		100.0
	)
	cancellation_route.activate()

	world.trade_agreements.erase(cancellation_agreement_id)
	world.trade_routes.erase(cancellation_route_id)

	if (
		world.add_trade_agreement(cancellation_agreement)
		and world.add_trade_route(cancellation_route)
	):
		TestLogger.write_line(
            "Cancellation agreement / route registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Cancellation agreement / route registration: FAIL"
		)
		all_passed = false

	var cancelled_remaining = cancellation_agreement.remaining_duration_months

	if cancellation_agreement.cancel(TradeAgreement.CAUSE_COUNTRY_DECISION):
		TestLogger.write_line(
            "Country-decision cancellation sets terminal state: PASS"
		)
	else:
		TestLogger.write_line(
            "Country-decision cancellation sets terminal state: FAIL"
		)
		all_passed = false

	if (
		cancellation_agreement.status == TradeAgreement.STATUS_CANCELLED
		and cancellation_agreement.lifecycle_reason == TradeAgreement.CAUSE_COUNTRY_DECISION
		and cancellation_agreement.remaining_duration_months == cancelled_remaining
	):
		TestLogger.write_line(
            "Cancellation records cause without altering remaining duration: PASS"
		)
	else:
		TestLogger.write_line(
            "Cancellation records cause without altering remaining duration: FAIL"
		)
		all_passed = false

	if not cancellation_agreement.resume():
		TestLogger.write_line(
            "Cancelled agreement cannot resume: PASS"
		)
	else:
		TestLogger.write_line(
            "Cancelled agreement cannot resume: FAIL"
		)
		all_passed = false

	if not cancellation_agreement.activate(world.current_date):
		TestLogger.write_line(
            "Cancelled agreement cannot reactivate: PASS"
		)
	else:
		TestLogger.write_line(
            "Cancelled agreement cannot reactivate: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	var cancellation_transaction_id := _transaction_id(
		world,
		cancellation_agreement_id,
		cancellation_route_id
	)

	if (
		not world.has_trade_transaction(cancellation_transaction_id)
		and cancellation_agreement.status == TradeAgreement.STATUS_CANCELLED
	):
		TestLogger.write_line(
            "Cancelled agreement blocks subsequent trade: PASS"
		)
	else:
		TestLogger.write_line(
            "Cancelled agreement blocks subsequent trade: FAIL"
		)
		all_passed = false

	var cancellation_snapshot := WorldSnapshot.new()
	cancellation_snapshot.capture(world)
	var cancellation_snapshot_state = cancellation_snapshot.trade_agreements.get(
		cancellation_agreement_id,
		{}
	)

	if (
		cancellation_snapshot_state.get("status", "") == TradeAgreement.STATUS_CANCELLED
		and cancellation_snapshot_state.get("lifecycle_reason", "") == TradeAgreement.CAUSE_COUNTRY_DECISION
	):
		TestLogger.write_line(
            "Snapshot preserves cancellation state and cause: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot preserves cancellation state and cause: FAIL"
		)
		all_passed = false

	# ========================================================
	# RESTORE TEST STATE
	# ========================================================

	world.current_date = original_date.duplicate(true)

	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)

	for transaction_id in generated_transaction_ids:
		world.trade_transactions.erase(transaction_id)

	world.trade_routes.erase(interruption_route_id)
	world.trade_agreements.erase(interruption_agreement_id)
	world.trade_routes.erase(route_disruption_route_id)
	world.trade_agreements.erase(route_disruption_agreement_id)
	world.trade_routes.erase(cancellation_route_id)
	world.trade_agreements.erase(cancellation_agreement_id)

	if original_objects["interruption_agreement"] != null:
		world.trade_agreements[interruption_agreement_id] = original_objects["interruption_agreement"]

	if original_objects["interruption_route"] != null:
		world.trade_routes[interruption_route_id] = original_objects["interruption_route"]

	if original_objects["route_disruption_agreement"] != null:
		world.trade_agreements[route_disruption_agreement_id] = original_objects["route_disruption_agreement"]

	if original_objects["route_disruption_route"] != null:
		world.trade_routes[route_disruption_route_id] = original_objects["route_disruption_route"]

	if original_objects["cancellation_agreement"] != null:
		world.trade_agreements[cancellation_agreement_id] = original_objects["cancellation_agreement"]

	if original_objects["cancellation_route"] != null:
		world.trade_routes[cancellation_route_id] = original_objects["cancellation_route"]

	TestLogger.write_line(
        "Trade Disruption / Cancellation 4.7 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed


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
