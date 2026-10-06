class_name TradeRouteRestrictionSystem
extends SimulationSystem


# ============================================================
# TRADE — STEP 11.2 ROUTE RESTRICTION / BLOCKADE
# ============================================================
#
# Implements a lightweight route-level restriction without building
# tactical naval warfare or a second trade model.
#
# Ownership:
#   TradeRoute             -> durable restriction state
#   TradeRouteRestrictionSystem -> apply / remove / target restriction
#   TradeSystem            -> remains authoritative trade executor
#
# A restriction is an overlay on the route's effective throughput:
#
#   base route capacity
#        * restriction factor [0..1]
#        -> effective trade capacity
#
# The base monthly_throughput_capacity is never overwritten. This means
# removing a restriction restores the original route semantics exactly.
# Factor 1.0 is neutral, factor 0.0 is a complete route block.
# ============================================================

const SYSTEM_NAME := "trade_route_restriction_system"
const DEFAULT_REASON := "blockade"


func _init():
	super(SYSTEM_NAME)


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("TradeRouteRestrictionSystem: World is null.")
		return

	# Restriction state lives on TradeRoute and is therefore already durable.
	# The monthly system pass only clamps malformed state defensively; it does
	# not recreate, decrement, or otherwise mutate a valid restriction.
	var route_ids: Array = world.trade_routes.keys()
	route_ids.sort()

	for route_id in route_ids:

		var route: TradeRoute = world.get_trade_route(
			route_id
		) as TradeRoute

		if route == null:
			continue

		if not route.route_restriction_active:
			continue

		if route.route_restriction_factor < 0.0 or route.route_restriction_factor > 1.0:
			route.route_restriction_factor = clampf(
				route.route_restriction_factor,
				0.0,
				1.0
			)


# ============================================================
# ROUTE CONTROL
# ============================================================

func apply_route_restriction(
	world: WorldState,
	route_id: String,
	factor: float,
	reason: String = DEFAULT_REASON
) -> bool:

	if world == null:
		return false

	var route: TradeRoute = world.get_trade_route(
		route_id
	) as TradeRoute

	if route == null:
		return false

	return route.apply_route_restriction(
		factor,
		reason
	)


func clear_route_restriction(
	world: WorldState,
	route_id: String
) -> bool:

	if world == null:
		return false

	var route: TradeRoute = world.get_trade_route(
		route_id
	) as TradeRoute

	if route == null:
		return false

	return route.clear_route_restriction()


# ============================================================
# ACTOR-PAIR TARGETING
# ============================================================
#
# Applies the same restriction to every active/durable route matching the
# ordered exporter/importer pair. The route itself remains the owner of the
# restriction state.
# ============================================================

func apply_restriction_to_trade(
	world: WorldState,
	exporter_id: String,
	importer_id: String,
	factor: float,
	reason: String = DEFAULT_REASON
) -> int:

	return _set_trade_restriction(
		world,
		exporter_id,
		importer_id,
		factor,
		reason,
		true
	)


func clear_restriction_from_trade(
	world: WorldState,
	exporter_id: String,
	importer_id: String
) -> int:

	return _set_trade_restriction(
		world,
		exporter_id,
		importer_id,
		1.0,
		"",
		false
	)


func _set_trade_restriction(
	world: WorldState,
	exporter_id: String,
	importer_id: String,
	factor: float,
	reason: String,
	enabled: bool
) -> int:

	if world == null:
		return 0

	var changed_count: int = 0
	var route_ids: Array = world.trade_routes.keys()
	route_ids.sort()

	for route_id in route_ids:

		var route: TradeRoute = world.get_trade_route(
			route_id
		) as TradeRoute

		if route == null:
			continue

		if (
			route.exporter_id != exporter_id
			or route.importer_id != importer_id
		):
			continue

		var changed: bool = false

		if enabled:
			changed = route.apply_route_restriction(
				factor,
				reason
			)
		else:
			changed = route.clear_route_restriction()

		if changed:
			changed_count += 1

	return changed_count
