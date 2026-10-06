class_name TradeRestrictionRecoveryTest
extends RefCounted


# ============================================================
# TRADE — STEP 11.4 RESTRICTION REMOVAL / RECOVERY TEST
# ============================================================
#
# Verifies:
#   restriction remains effective until explicit removal;
#   embargo removal resumes the existing agreement without resetting it;
#   route restriction removal restores original route capacity;
#   restricted historical transactions remain unchanged;
#   future trade creates a new full-delivery transaction;
#   contract duration continues from its preserved remaining value;
#   repeated recovery is idempotent;
#   cancellation is never reopened;
#   recovery does not mutate unrelated agreements/routes.
# ============================================================

const EPSILON := 0.0000001
const PARTIAL_AGREEMENT_ID := "test_trade_agreement_11_4_partial"
const PARTIAL_ROUTE_ID := "test_trade_route_11_4_partial"
const EMBARGO_AGREEMENT_ID := "test_trade_agreement_11_4_embargo"
const EMBARGO_ROUTE_ID := "test_trade_route_11_4_embargo"
const CANCELLED_AGREEMENT_ID := "test_trade_agreement_11_4_cancelled"
const CANCELLED_ROUTE_ID := "test_trade_route_11_4_cancelled"


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"TRADE RESTRICTION REMOVAL / RECOVERY 11.4 TEST"
	)

	var all_passed: bool = true

	all_passed = _assert(
		world != null,
		"World available",
		all_passed
	)

	all_passed = _assert(
		simulation != null,
		"Simulation available",
		all_passed
	)

	if world == null or simulation == null:
		return false

	var recovery_system: TradeRestrictionRecoverySystem = (
		simulation.get_system(
			"trade_restriction_recovery_system"
		)
		as TradeRestrictionRecoverySystem
	)
	var trade_system: TradeSystem = (
		simulation.get_system("trade_system")
		as TradeSystem
	)
	var resource_system: ResourceSystem = (
		simulation.get_system("resource_system")
		as ResourceSystem
	)
	var route_restriction_system: TradeRouteRestrictionSystem = (
		simulation.get_system(
			"trade_route_restriction_system"
		)
		as TradeRouteRestrictionSystem
	)

	all_passed = _assert(
		recovery_system != null,
		"Registered TradeRestrictionRecoverySystem available",
		all_passed
	)
	all_passed = _assert(
		trade_system != null,
		"Registered TradeSystem available",
		all_passed
	)
	all_passed = _assert(
		resource_system != null,
		"Registered ResourceSystem available",
		all_passed
	)
	all_passed = _assert(
		route_restriction_system != null,
		"Registered TradeRouteRestrictionSystem available",
		all_passed
	)

	if recovery_system == null or trade_system == null or resource_system == null or route_restriction_system == null:
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
	var india_economy = india.get_component("economy")

	all_passed = _assert(
		china_resources != null
		and india_resources != null
		and china_infrastructure != null
		and india_infrastructure != null
		and india_economy != null,
		"Required resource / infrastructure / economy components available",
		all_passed
	)

	if china_resources == null or india_resources == null or china_infrastructure == null or india_infrastructure == null or india_economy == null:
		return false

	var original_date: Dictionary = world.current_date.duplicate(true)
	var original_china_resource_state: Dictionary = china_resources.state.duplicate(true)
	var original_india_resource_state: Dictionary = india_resources.state.duplicate(true)
	var original_china_infrastructure_state: Dictionary = china_infrastructure.state.duplicate(true)
	var original_india_infrastructure_state: Dictionary = india_infrastructure.state.duplicate(true)
	var original_india_economy_state: Dictionary = india_economy.state.duplicate(true)
	var original_trade_transactions: Dictionary = world.trade_transactions.duplicate(true)
	var original_trade_agreements: Dictionary = world.trade_agreements.duplicate(true)
	var original_trade_routes: Dictionary = world.trade_routes.duplicate(true)

	var all_original_entities := {
		"partial_agreement": world.trade_agreements.get(PARTIAL_AGREEMENT_ID, null),
		"partial_route": world.trade_routes.get(PARTIAL_ROUTE_ID, null),
		"embargo_agreement": world.trade_agreements.get(EMBARGO_AGREEMENT_ID, null),
		"embargo_route": world.trade_routes.get(EMBARGO_ROUTE_ID, null),
		"cancelled_agreement": world.trade_agreements.get(CANCELLED_AGREEMENT_ID, null),
		"cancelled_route": world.trade_routes.get(CANCELLED_ROUTE_ID, null)
	}

	# Isolate the recovery scenario from every existing trade fixture.
	world.trade_agreements.clear()
	world.trade_routes.clear()
	world.trade_transactions.clear()

	_set_all_trade_infrastructure(china_infrastructure, 1.0)
	_set_all_trade_infrastructure(india_infrastructure, 1.0)

	var importer_stockpile: Dictionary = (
		original_india_resource_state.get("stockpile", {}).duplicate(true)
	)
	importer_stockpile["iron"] = 0.0
	importer_stockpile["coal"] = 0.0
	india_resources.set_state("stockpile", importer_stockpile.duplicate(true))
	india_resources.set_state("committed_stockpile", {})
	india_resources.set_state("production_process_demand", {})
	india_resources.set_state("production", {})
	india_resources.set_state("consumption", {})
	india_resources.set_state("imports", {})
	india_resources.set_state("exports", {})
	india_resources.set_state("trade_imports", {})
	india_resources.set_state("trade_exports", {})

	var exporter_stockpile: Dictionary = (
		original_china_resource_state.get("stockpile", {}).duplicate(true)
	)
	exporter_stockpile["iron"] = 200.0
	exporter_stockpile["coal"] = 200.0
	china_resources.set_state("stockpile", exporter_stockpile.duplicate(true))
	china_resources.set_state("committed_stockpile", {})
	china_resources.set_state("production", {})
	china_resources.set_state("consumption", {})
	china_resources.set_state("imports", {})
	china_resources.set_state("exports", {})
	china_resources.set_state("trade_imports", {})
	china_resources.set_state("trade_exports", {})

	var china_prices: Dictionary = (
		china_resources.get_state("current_price", {}).duplicate(true)
	)
	china_prices["iron"] = 1.0
	china_prices["coal"] = 1.0
	china_resources.set_state("current_price", china_prices)

	india_economy.set_state("treasury", 100000.0)

	# ========================================================
	# FIXTURES
	# ========================================================

	var partial_agreement := TradeAgreement.new(
		PARTIAL_AGREEMENT_ID,
		"china",
		"india",
		"iron",
		20.0,
		3
	)
	partial_agreement.activate(world.current_date)

	var partial_route := TradeRoute.new(
		PARTIAL_ROUTE_ID,
		PARTIAL_AGREEMENT_ID,
		"china",
		"india",
		100.0
	)
	partial_route.activate()

	var embargo_agreement := TradeAgreement.new(
		EMBARGO_AGREEMENT_ID,
		"china",
		"india",
		"coal",
		20.0,
		3
	)
	embargo_agreement.activate(world.current_date)

	var embargo_route := TradeRoute.new(
		EMBARGO_ROUTE_ID,
		EMBARGO_AGREEMENT_ID,
		"china",
		"india",
		100.0
	)
	embargo_route.activate()

	var cancelled_agreement := TradeAgreement.new(
		CANCELLED_AGREEMENT_ID,
		"china",
		"india",
		"iron",
		5.0,
		3
	)
	cancelled_agreement.activate(world.current_date)
	cancelled_agreement.cancel(TradeAgreement.CAUSE_COUNTRY_DECISION)

	var cancelled_route := TradeRoute.new(
		CANCELLED_ROUTE_ID,
		CANCELLED_AGREEMENT_ID,
		"china",
		"india",
		100.0
	)
	cancelled_route.activate()

	all_passed = _assert(
		world.add_trade_agreement(partial_agreement)
		and world.add_trade_route(partial_route)
		and world.add_trade_agreement(embargo_agreement)
		and world.add_trade_route(embargo_route)
		and world.add_trade_agreement(cancelled_agreement)
		and world.add_trade_route(cancelled_route),
		"Recovery fixture agreements / routes registered",
		all_passed
	)

	# ========================================================
	# RESTRICTED MONTH
	# ========================================================

	var route_applied: bool = route_restriction_system.apply_route_restriction(
		world,
		PARTIAL_ROUTE_ID,
		0.5,
		"blockade"
	)
	var embargo_applied: bool = embargo_agreement.set_embargoed(true)

	all_passed = _assert(
		route_applied and partial_route.route_restriction_active,
		"Route restriction is active before recovery",
		all_passed
	)
	all_passed = _assert(
		embargo_applied
		and embargo_agreement.embargoed
		and embargo_agreement.status == TradeAgreement.STATUS_INTERRUPTED,
		"Embargo is active before recovery",
		all_passed
	)

	var embargo_remaining_before: int = embargo_agreement.remaining_duration_months
	var partial_remaining_before: int = partial_agreement.remaining_duration_months
	var partial_base_capacity_before: float = partial_route.monthly_throughput_capacity
	var embargo_start_date: Dictionary = embargo_agreement.start_date.duplicate(true)
	var partial_start_date: Dictionary = partial_agreement.start_date.duplicate(true)

	trade_system.process_month(world)
	resource_system.process_month(world)

	var partial_transaction_id: String = _transaction_id(
		world,
		PARTIAL_AGREEMENT_ID,
		PARTIAL_ROUTE_ID
	)
	var partial_transaction: TradeTransaction = (
		world.get_trade_transaction(partial_transaction_id)
		as TradeTransaction
	)

	all_passed = _assert(
		partial_transaction != null,
		"Restricted route creates a historical partial transaction",
		all_passed
	)

	if partial_transaction != null:
		all_passed = _assert(
			is_equal_approx(partial_transaction.actual_imported_quantity, 10.0),
			"Historical restricted transaction preserves partial delivery",
			all_passed
		)

	var historical_transaction_snapshot: Dictionary = {}
	if partial_transaction != null:
		historical_transaction_snapshot = partial_transaction.to_snapshot_dict().duplicate(true)

	all_passed = _assert(
		partial_agreement.remaining_duration_months == 2,
		"Partial route trade advances its contract duration once",
		all_passed
	)
	all_passed = _assert(
		embargo_agreement.remaining_duration_months == embargo_remaining_before,
		"Embargoed agreement duration is preserved while blocked",
		all_passed
	)

	# ========================================================
	# EXPLICIT REMOVAL / RECOVERY
	# ========================================================

	var recovery_result: Dictionary = recovery_system.recover_trade(
		world,
		EMBARGO_AGREEMENT_ID,
		PARTIAL_ROUTE_ID,
		true,
		true,
		true
	)

	all_passed = _assert(
		bool(recovery_result.get("embargo_removed", false)),
		"Embargo removal succeeds explicitly",
		all_passed
	)
	all_passed = _assert(
		bool(recovery_result.get("route_restriction_removed", false)),
		"Route restriction removal succeeds explicitly",
		all_passed
	)
	all_passed = _assert(
		bool(recovery_result.get("agreement_resumed", false)),
		"Previously embargoed agreement resumes explicitly",
		all_passed
	)

	all_passed = _assert(
		not embargo_agreement.embargoed
		and embargo_agreement.status == TradeAgreement.STATUS_ACTIVE,
		"Embargoed agreement returns to active state",
		all_passed
	)
	all_passed = _assert(
		partial_route.route_restriction_active == false
		and is_equal_approx(
			partial_route.get_available_throughput(20.0),
			20.0
		),
		"Route returns to unrestricted effective capacity",
		all_passed
	)
	all_passed = _assert(
		is_equal_approx(
			partial_route.monthly_throughput_capacity,
			partial_base_capacity_before
		),
		"Route base throughput capacity is preserved",
		all_passed
	)
	all_passed = _assert(
		embargo_agreement.remaining_duration_months == embargo_remaining_before,
		"Embargo removal does not reset contract duration",
		all_passed
	)
	all_passed = _assert(
		partial_agreement.remaining_duration_months == partial_remaining_before - 1,
		"Route restriction removal does not rewind prior contract progress",
		all_passed
	)
	all_passed = _assert(
		embargo_agreement.start_date == embargo_start_date
		and partial_agreement.start_date == partial_start_date,
		"Restriction removal preserves original contract start dates",
		all_passed
	)

	var repeated_recovery: Dictionary = recovery_system.recover_trade(
		world,
		EMBARGO_AGREEMENT_ID,
		PARTIAL_ROUTE_ID,
		true,
		true,
		true
	)

	all_passed = _assert(
		not bool(repeated_recovery.get("embargo_removed", false))
		and not bool(repeated_recovery.get("route_restriction_removed", false))
		and not bool(repeated_recovery.get("agreement_resumed", false))
		and not bool(repeated_recovery.get("changed", false)),
		"Repeated recovery is idempotent",
		all_passed
	)

	# A terminally cancelled agreement must never be reopened by recovery.
	var cancelled_recovery: bool = recovery_system.resume_interrupted_agreement(
		world,
		CANCELLED_AGREEMENT_ID
	)
	all_passed = _assert(
		not cancelled_recovery
		and cancelled_agreement.status == TradeAgreement.STATUS_CANCELLED,
		"Recovery cannot reopen a cancelled agreement",
		all_passed
	)

	# ========================================================
	# NEXT MONTH — RECOVERED TRADE
	# ========================================================

	_advance_test_month(world)

	trade_system.process_month(world)
	resource_system.process_month(world)

	var recovered_partial_transaction_id: String = _transaction_id(
		world,
		PARTIAL_AGREEMENT_ID,
		PARTIAL_ROUTE_ID
	)
	var recovered_embargo_transaction_id: String = _transaction_id(
		world,
		EMBARGO_AGREEMENT_ID,
		EMBARGO_ROUTE_ID
	)

	var recovered_partial_transaction: TradeTransaction = (
		world.get_trade_transaction(recovered_partial_transaction_id)
		as TradeTransaction
	)
	var recovered_embargo_transaction: TradeTransaction = (
		world.get_trade_transaction(recovered_embargo_transaction_id)
		as TradeTransaction
	)

	all_passed = _assert(
		recovered_partial_transaction != null
		and recovered_embargo_transaction != null,
		"Recovered agreements create new future-month transactions",
		all_passed
	)

	if recovered_partial_transaction != null:
		all_passed = _assert(
			is_equal_approx(
				recovered_partial_transaction.actual_imported_quantity,
				20.0
			),
			"Route restriction removal restores full future trade quantity",
			all_passed
		)

	if recovered_embargo_transaction != null:
		all_passed = _assert(
			is_equal_approx(
				recovered_embargo_transaction.actual_imported_quantity,
				20.0
			),
			"Embargo removal restores full future trade quantity",
			all_passed
		)

	all_passed = _assert(
		world.trade_transactions.size() == 3,
		"Recovery adds future transactions without rewriting historical transactions",
		all_passed
	)

	if partial_transaction != null:
		all_passed = _assert(
			partial_transaction.to_snapshot_dict() == historical_transaction_snapshot,
			"Historical restricted transaction remains unchanged after recovery",
			all_passed
		)

	all_passed = _assert(
		partial_agreement.remaining_duration_months == 1
		and embargo_agreement.remaining_duration_months == 2,
		"Recovered contracts continue from preserved duration state",
		all_passed
	)

	# Re-running the same date must not duplicate the recovered transactions.
	trade_system.process_month(world)

	all_passed = _assert(
		world.trade_transactions.size() == 3,
		"Repeated same-date processing does not duplicate recovered transactions",
		all_passed
	)

	TestLogger.write_line(
		"Trade Restriction Recovery 11.4 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	# ========================================================
	# RESTORE FIXTURE
	# ========================================================

	world.current_date = original_date.duplicate(true)
	china_resources.state = original_china_resource_state.duplicate(true)
	india_resources.state = original_india_resource_state.duplicate(true)
	china_infrastructure.state = original_china_infrastructure_state.duplicate(true)
	india_infrastructure.state = original_india_infrastructure_state.duplicate(true)
	india_economy.state = original_india_economy_state.duplicate(true)
	world.trade_transactions = original_trade_transactions.duplicate(true)
	world.trade_agreements = original_trade_agreements.duplicate(true)
	world.trade_routes = original_trade_routes.duplicate(true)

	for key in [
		"partial_agreement",
		"partial_route",
		"embargo_agreement",
		"embargo_route",
		"cancelled_agreement",
		"cancelled_route"
	]:
		if all_original_entities[key] != null:
			if key.ends_with("agreement"):
				world.trade_agreements[key] = all_original_entities[key]
			else:
				world.trade_routes[key] = all_original_entities[key]

	TestLogger.write_line(
		"Trade Restriction Recovery 11.4 test: "
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
