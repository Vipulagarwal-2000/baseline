class_name TradeEmbargoTest
extends RefCounted


# ============================================================
# TRADE — STEP 11.1 TEST
# ============================================================
#
# Validates the MVP embargo boundary:
#   - embargo applies to an eligible active agreement
#   - embargo records explicit restriction state
#   - embargo blocks trade execution
#   - embargo preserves remaining contract duration
#   - repeated enforcement/application is idempotent
#   - embargo state is represented in WorldSnapshot
#   - removing the embargo explicitly resumes the agreement
#   - trade resumes on the next eligible processing cycle
#   - actor/resource targeting is specific to the requested trade
#
# This test deliberately does not implement partial embargoes, route
# restrictions, or downstream payment/diplomatic consequence changes; those
# belong to later Step 11 substeps.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"TRADE EMBARGO 11.1 TEST"
	)

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false

	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false

	TestLogger.write_line("Simulation available: PASS")

	var embargo_system: TradeEmbargoSystem = (
		simulation.get_system("trade_embargo_system")
		as TradeEmbargoSystem
	)
	var trade_system: TradeSystem = (
		simulation.get_system("trade_system")
		as TradeSystem
	)

	var all_passed := true

	all_passed = _assert(
		embargo_system != null,
		"Registered TradeEmbargoSystem available",
		all_passed
	)

	all_passed = _assert(
		trade_system != null,
		"Registered TradeSystem available",
		all_passed
	)

	if embargo_system == null or trade_system == null:
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

	const agreement_id := "test_trade_agreement_11_1_embargo"
	const route_id := "test_trade_route_11_1_embargo"
	const non_target_agreement_id := "test_trade_agreement_11_1_other_resource"
	const non_target_route_id := "test_trade_route_11_1_other_resource"

	var original_date = world.current_date.duplicate(true)
	var original_china_resource_state = china_resources.state.duplicate(true)
	var original_india_resource_state = india_resources.state.duplicate(true)
	var original_china_infrastructure_state = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state = india_infrastructure.state.duplicate(true)

	var original_objects := {
		"agreement": world.trade_agreements.get(agreement_id, null),
		"route": world.trade_routes.get(route_id, null),
		"other_agreement": world.trade_agreements.get(non_target_agreement_id, null),
		"other_route": world.trade_routes.get(non_target_route_id, null)
	}

	var original_trade_transactions: Dictionary = (
		world.trade_transactions.duplicate(true)
	)

	_set_all_trade_infrastructure(china_infrastructure, 1.0)
	_set_all_trade_infrastructure(india_infrastructure, 1.0)

	var china_stockpile = china_resources.get_state("stockpile", {})
	var india_stockpile = india_resources.get_state("stockpile", {})

	china_stockpile["coal"] = 200.0
	china_stockpile["iron"] = 200.0
	india_stockpile["coal"] = 0.0
	india_stockpile["iron"] = 0.0

	# ========================================================
	# FIXTURE — TARGET AND NON-TARGET AGREEMENTS
	# ========================================================

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		20.0,
		3
	)

	agreement.activate(world.current_date)

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india",
		100.0
	)

	route.activate()

	var non_target_agreement := TradeAgreement.new(
		non_target_agreement_id,
		"china",
		"india",
		"iron",
		10.0,
		3
	)

	non_target_agreement.activate(world.current_date)

	var non_target_route := TradeRoute.new(
		non_target_route_id,
		non_target_agreement_id,
		"china",
		"india",
		100.0
	)

	non_target_route.activate()

	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(non_target_agreement_id)
	world.trade_routes.erase(non_target_route_id)

	all_passed = _assert(
		world.add_trade_agreement(agreement)
		and world.add_trade_route(route)
		and world.add_trade_agreement(non_target_agreement)
		and world.add_trade_route(non_target_route),
		"Embargo fixture agreements / routes registered",
		all_passed
	)

	# ========================================================
	# BASELINE TRADE
	# ========================================================

	trade_system.process_month(world)

	var baseline_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	all_passed = _assert(
		world.has_trade_transaction(baseline_transaction_id),
		"Pre-embargo trade executes normally",
		all_passed
	)

	all_passed = _assert(
		agreement.remaining_duration_months == 2
		and agreement.status == TradeAgreement.STATUS_ACTIVE,
		"Pre-embargo trade consumes one contract month",
		all_passed
	)

	# The TradeSystem has already populated both agreements' monthly flow
	# state. Move to the next date; TradeSystem will clear stale flow state at
	# the beginning of the next processing cycle.
	_advance_test_month(world)

	# ========================================================
	# TARGETED EMBARGO
	# ========================================================

	var targeted_count: int = embargo_system.apply_embargo_to_trade(
		world,
		"china",
		"india",
		"coal"
	)

	all_passed = _assert(
		targeted_count == 1,
		"Targeted actor/resource embargo applies to exactly one agreement",
		all_passed
	)

	all_passed = _assert(
		agreement.embargoed
		and agreement.status == TradeAgreement.STATUS_INTERRUPTED
		and agreement.lifecycle_reason == TradeAgreement.CAUSE_EMBARGO
		and agreement.remaining_duration_months == 2,
		"Embargo records interruption without consuming contract duration",
		all_passed
	)

	all_passed = _assert(
		not non_target_agreement.embargoed
		and non_target_agreement.status == TradeAgreement.STATUS_ACTIVE,
		"Embargo does not affect a different resource agreement",
		all_passed
	)

	# ========================================================
	# EMBARGO ENFORCEMENT / IDEMPOTENCE
	# ========================================================

	embargo_system.process_month(world)
	trade_system.process_month(world)

	var embargo_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	all_passed = _assert(
		not world.has_trade_transaction(embargo_transaction_id),
		"Embargo blocks eligible trade execution",
		all_passed
	)

	all_passed = _assert(
		agreement.remaining_duration_months == 2,
		"Embargoed agreement duration remains unchanged",
		all_passed
	)

	all_passed = _assert(
		agreement.status == TradeAgreement.STATUS_INTERRUPTED
		and agreement.lifecycle_reason == TradeAgreement.CAUSE_EMBARGO,
		"Embargo remains explicitly enforced",
		all_passed
	)

	var repeated_count: bool = embargo_system.apply_embargo_to_agreement(
		world,
		agreement_id
	)

	all_passed = _assert(
		repeated_count,
		"Repeated embargo application is idempotent",
		all_passed
	)

	all_passed = _assert(
		agreement.remaining_duration_months == 2
		and agreement.status == TradeAgreement.STATUS_INTERRUPTED,
		"Repeated embargo does not alter preserved contract state",
		all_passed
	)

	# ========================================================
	# SNAPSHOT
	# ========================================================

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_state: Dictionary = snapshot.trade_agreements.get(
		agreement_id,
		{}
	)

	all_passed = _assert(
		bool(snapshot_state.get("embargoed", false))
		and snapshot_state.get("status", "") == TradeAgreement.STATUS_INTERRUPTED
		and snapshot_state.get("lifecycle_reason", "") == TradeAgreement.CAUSE_EMBARGO
		and int(snapshot_state.get("remaining_duration_months", -1)) == 2,
		"Snapshot preserves embargo restriction state",
		all_passed
	)

	snapshot_state["embargoed"] = false

	all_passed = _assert(
		agreement.embargoed,
		"Snapshot embargo state is isolated from live agreement state",
		all_passed
	)

	# ========================================================
	# REMOVE EMBARGO / RESUME
	# ========================================================

	all_passed = _assert(
		embargo_system.remove_embargo_from_agreement(
			world,
			agreement_id
		),
		"Embargo can be removed explicitly",
		all_passed
	)

	all_passed = _assert(
		not agreement.embargoed
		and agreement.status == TradeAgreement.STATUS_ACTIVE
		and agreement.remaining_duration_months == 2,
		"Removing embargo explicitly resumes the agreement",
		all_passed
	)

	trade_system.process_month(world)

	var resumed_transaction_id := _transaction_id(
		world,
		agreement_id,
		route_id
	)

	all_passed = _assert(
		world.has_trade_transaction(resumed_transaction_id),
		"Trade resumes after explicit embargo removal",
		all_passed
	)

	all_passed = _assert(
		agreement.remaining_duration_months == 1
		and agreement.status == TradeAgreement.STATUS_ACTIVE,
		"Resumed trade advances contract duration normally",
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

	world.trade_transactions.clear()
	world.trade_transactions = original_trade_transactions.duplicate(true)

	world.trade_routes.erase(route_id)
	world.trade_agreements.erase(agreement_id)
	world.trade_routes.erase(non_target_route_id)
	world.trade_agreements.erase(non_target_agreement_id)

	if original_objects["agreement"] != null:
		world.trade_agreements[agreement_id] = original_objects["agreement"]

	if original_objects["route"] != null:
		world.trade_routes[route_id] = original_objects["route"]

	if original_objects["other_agreement"] != null:
		world.trade_agreements[non_target_agreement_id] = original_objects["other_agreement"]

	if original_objects["other_route"] != null:
		world.trade_routes[non_target_route_id] = original_objects["other_route"]

	TestLogger.write_line(
		"Trade Embargo 11.1 overall: "
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
