class_name TradeContractDurationTest
extends RefCounted


# ============================================================
# TRADE — STEP 4.6 TEST
# ============================================================
#
# Validates the minimum contract-duration lifecycle:
#   start date
#   remaining duration
#   active / inactive state
#   monthly duration progression
#   final-month execution followed by expiration
#   same-date reprocessing does not decrement twice
#   expired contracts do not execute later
#   snapshot preserves duration lifecycle state
#
# This test does not implement disruption/cancellation causes;
# those belong to Step 4.7.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "TRADE CONTRACT DURATION TEST"
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

	const agreement_id = "test_trade_agreement_4_6_duration"
	const route_id = "test_trade_route_4_6_duration"
	const inactive_agreement_id = "test_trade_agreement_4_6_inactive"
	const inactive_route_id = "test_trade_route_4_6_inactive"

	var original_date = world.current_date.duplicate(true)
	var original_china_state = china_resources.state.duplicate(true)
	var original_india_state = india_resources.state.duplicate(true)
	var original_china_infrastructure = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure = india_infrastructure.state.duplicate(true)

	var original_agreement = world.trade_agreements.get(
		agreement_id,
		null
	)
	var original_route = world.trade_routes.get(
		route_id,
		null
	)
	var original_inactive_agreement = world.trade_agreements.get(
		inactive_agreement_id,
		null
	)
	var original_inactive_route = world.trade_routes.get(
		inactive_route_id,
		null
	)

	var generated_transaction_ids: Array[String] = []
	var all_passed := true

	_set_all_trade_infrastructure(
		china_infrastructure,
		1.0
	)
	_set_all_trade_infrastructure(
		india_infrastructure,
		1.0
	)

	var china_stockpile = china_resources.get_state(
		"stockpile",
		{}
	)
	var india_stockpile = india_resources.get_state(
		"stockpile",
		{}
	)

	china_stockpile["coal"] = 200.0
	india_stockpile["coal"] = 0.0

	# --------------------------------------------------------
	# START / INITIAL DURATION
	# --------------------------------------------------------

	var start_date := {
		"year": int(world.current_date.get("year", 1950)),
		"month": int(world.current_date.get("month", 1)),
		"day": int(world.current_date.get("day", 1))
	}

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		20.0,
		3
	)

	if (
		agreement.duration_months == 3
		and agreement.remaining_duration_months == 3
	):
		TestLogger.write_line(
            "Contract duration initializes correctly: PASS"
		)
	else:
		TestLogger.write_line(
            "Contract duration initializes correctly: FAIL"
		)
		all_passed = false

	if agreement.activate(start_date):
		TestLogger.write_line(
            "Contract activation records start date: PASS"
		)
	else:
		TestLogger.write_line(
            "Contract activation records start date: FAIL"
		)
		all_passed = false

	if (
		agreement.status == TradeAgreement.STATUS_ACTIVE
		and agreement.start_date == start_date
	):
		TestLogger.write_line(
            "Active state and start date preserved: PASS"
		)
	else:
		TestLogger.write_line(
            "Active state and start date preserved: FAIL"
		)
		all_passed = false

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)
	route.activate()

	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)

	if world.add_trade_agreement(agreement) and world.add_trade_route(route):
		TestLogger.write_line(
            "Duration test agreement / route registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Duration test agreement / route registration: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# MONTH 1
	# --------------------------------------------------------

	trade_system.process_month(world)

	var month_1_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	generated_transaction_ids.append(
		month_1_transaction_id
	)

	var month_1_transaction = world.get_trade_transaction(
		month_1_transaction_id
	)

	if (
		month_1_transaction != null
		and agreement.remaining_duration_months == 2
		and agreement.status == TradeAgreement.STATUS_ACTIVE
	):
		TestLogger.write_line(
            "Month 1 executes trade and reduces remaining duration to 2: PASS"
		)
	else:
		TestLogger.write_line(
            "Month 1 executes trade and reduces remaining duration to 2: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# SAME-DATE REPROCESSING
	# --------------------------------------------------------

	trade_system.process_month(world)

	if agreement.remaining_duration_months == 2:
		TestLogger.write_line(
            "Same-date reprocessing does not double-decrement duration: PASS"
		)
	else:
		TestLogger.write_line(
            "Same-date reprocessing does not double-decrement duration: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# SNAPSHOT AFTER MONTH 1
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_agreement = snapshot.trade_agreements.get(
		agreement_id,
		{}
	)

	if (
		is_equal_approx(
			float(
				snapshot_agreement.get(
					"remaining_duration_months",
					-1.0
				)
			),
			2.0
		)
		and snapshot_agreement.get("start_date", {}) == start_date
		and snapshot_agreement.get("status", "") == TradeAgreement.STATUS_ACTIVE
	):
		TestLogger.write_line(
            "Snapshot preserves duration state: PASS"
		)
	else:
		TestLogger.write_line(
            "Snapshot preserves duration state: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# MONTH 2
	# --------------------------------------------------------

	_advance_test_month(world)
	trade_system.process_month(world)

	var month_2_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	generated_transaction_ids.append(
		month_2_transaction_id
	)

	if (
		world.has_trade_transaction(month_2_transaction_id)
		and agreement.remaining_duration_months == 1
		and agreement.status == TradeAgreement.STATUS_ACTIVE
	):
		TestLogger.write_line(
            "Month 2 preserves active contract with 1 month remaining: PASS"
		)
	else:
		TestLogger.write_line(
            "Month 2 preserves active contract with 1 month remaining: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# MONTH 3 — FINAL CONTRACTED MONTH
	# --------------------------------------------------------

	_advance_test_month(world)
	trade_system.process_month(world)

	var month_3_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	generated_transaction_ids.append(
		month_3_transaction_id
	)

	if world.has_trade_transaction(month_3_transaction_id):
		TestLogger.write_line(
            "Final contracted month executes before expiration: PASS"
		)
	else:
		TestLogger.write_line(
            "Final contracted month executes before expiration: FAIL"
		)
		all_passed = false

	if (
		agreement.remaining_duration_months == 0
		and agreement.status == TradeAgreement.STATUS_EXPIRED
	):
		TestLogger.write_line(
            "Contract expires exactly at duration completion: PASS"
		)
	else:
		TestLogger.write_line(
            "Contract expires exactly at duration completion: FAIL"
		)
		all_passed = false

	if not agreement.activate(world.current_date):
		TestLogger.write_line(
            "Expired contract cannot reactivate: PASS"
		)
	else:
		TestLogger.write_line(
            "Expired contract cannot reactivate: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# MONTH 4 — EXPIRED CONTRACT DOES NOT EXECUTE
	# --------------------------------------------------------

	_advance_test_month(world)
	trade_system.process_month(world)

	var month_4_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	if not world.has_trade_transaction(month_4_transaction_id):
		TestLogger.write_line(
            "Expired contract does not execute after expiration: PASS"
		)
	else:
		TestLogger.write_line(
            "Expired contract does not execute after expiration: FAIL"
		)
		all_passed = false

	# --------------------------------------------------------
	# INACTIVE STATE DOES NOT CONSUME DURATION
	# --------------------------------------------------------

	var inactive_agreement := TradeAgreement.new(
		inactive_agreement_id,
		"china",
		"india",
		"coal",
		10.0,
		2
	)

	inactive_agreement.activate(world.current_date)
	inactive_agreement.set_inactive()

	var inactive_route := TradeRoute.new(
		inactive_route_id,
		inactive_agreement_id,
		"china",
		"india",
		100.0
	)
	inactive_route.activate()

	world.trade_agreements.erase(inactive_agreement_id)
	world.trade_routes.erase(inactive_route_id)

	if (
		world.add_trade_agreement(inactive_agreement)
		and world.add_trade_route(inactive_route)
	):
		TestLogger.write_line(
            "Inactive contract registration: PASS"
		)
	else:
		TestLogger.write_line(
            "Inactive contract registration: FAIL"
		)
		all_passed = false

	var inactive_before = inactive_agreement.remaining_duration_months

	trade_system.process_month(world)

	if (
		inactive_agreement.status == TradeAgreement.STATUS_INACTIVE
		and inactive_agreement.remaining_duration_months == inactive_before
		and not world.has_trade_transaction(
			_transaction_id(world, inactive_agreement_id, inactive_route_id)
		)
	):
		TestLogger.write_line(
            "Inactive contract preserves duration and blocks trade: PASS"
		)
	else:
		TestLogger.write_line(
            "Inactive contract preserves duration and blocks trade: FAIL"
		)
		all_passed = false

	if inactive_agreement.activate(world.current_date):
		TestLogger.write_line(
            "Inactive contract can reactivate: PASS"
		)
	else:
		TestLogger.write_line(
            "Inactive contract can reactivate: FAIL"
		)
		all_passed = false

	trade_system.process_month(world)

	if (
		inactive_agreement.status == TradeAgreement.STATUS_ACTIVE
		and inactive_agreement.remaining_duration_months == inactive_before - 1
	):
		TestLogger.write_line(
            "Reactivated contract resumes duration progression: PASS"
		)
	else:
		TestLogger.write_line(
            "Reactivated contract resumes duration progression: FAIL"
		)
		all_passed = false

	var inactive_transaction_id := _transaction_id(
		world,
		inactive_agreement_id,
		inactive_route_id
	)
	generated_transaction_ids.append(inactive_transaction_id)

	# --------------------------------------------------------
	# RESTORE TEST STATE
	# --------------------------------------------------------

	world.current_date = original_date.duplicate(true)

	china_resources.state = original_china_state.duplicate(true)
	india_resources.state = original_india_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure.duplicate(true)
	india_infrastructure.state = original_india_infrastructure.duplicate(true)

	for transaction_id in generated_transaction_ids:
		world.trade_transactions.erase(transaction_id)

	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(inactive_route_id)
	world.trade_agreements.erase(inactive_agreement_id)

	if original_agreement != null:
		world.trade_agreements[agreement_id] = original_agreement

	if original_route != null:
		world.trade_routes[route_id] = original_route

	if original_inactive_agreement != null:
		world.trade_agreements[inactive_agreement_id] = original_inactive_agreement

	if original_inactive_route != null:
		world.trade_routes[inactive_route_id] = original_inactive_route

	TestLogger.write_line(
        "Trade Contract Duration 4.6 overall: "
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
