class_name TradeSystem
extends SimulationSystem


# ============================================================
# TRADE SYSTEM — STEPS 4.5 + 4.6 + 4.7
# ============================================================
#
# Extends the verified 4.4 quantity / availability resolution by
# consuming the existing InfrastructureComponent state.
#
# 4.5 does NOT create a second infrastructure model.
# It reads the existing normalized country-level values for:
#   ports
#   transport
#   roads
#   railways
#
# Each is treated as a capacity / accessibility ceiling. For a trade
# between two countries, the weaker endpoint is the effective limit.
# The final physical trade quantity is the minimum of:
#   requested quantity
#   exporter stockpile availability
#   route throughput
#   port capacity
#   transport availability
#   roads accessibility
#   railways accessibility
#
# Physical trade flows are written to dedicated ResourceComponent states
# so ResourceSystem can settle them without applying port throughput a
# second time. Existing imports / exports remain populated with the
# final physically scheduled quantity for compatibility with 4.3 / 4.4.
#
# TradeSystem remains at WORLD_UPDATE order 29, immediately before
# ResourceSystem order 30.
#
# Step 4.6 additionally advances active agreement duration once per
# newly-created monthly trade transaction / contract processing cycle.
# The final contracted month is allowed to execute, then the agreement
# expires. Re-running the same simulation date does not decrement the
# agreement twice because an existing transaction for that date is
# treated as already processed.
#
# Step 4.7 adds lifecycle control. Cancelled and interrupted agreements
# do not execute trade. A linked disrupted route automatically interrupts
# an otherwise active agreement with the route-disruption cause. An
# interrupted agreement remains paused until explicitly resumed.
# ============================================================

func _init():
	super("trade_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("TradeSystem: World is null.")
		return

	# --------------------------------------------------------
	# RESET CURRENT-MONTH INTERNATIONAL FLOWS
	# --------------------------------------------------------

	for entity in world.entities.values():

		if entity == null:
			continue

		var resources = entity.get_component("resources")

		if resources == null:
			continue

		var imports: Dictionary = resources.get_state(
			"imports",
			{}
		)

		var exports: Dictionary = resources.get_state(
			"exports",
			{}
		)

		var trade_imports: Dictionary = resources.get_state(
			"trade_imports",
			{}
		)

		var trade_exports: Dictionary = resources.get_state(
			"trade_exports",
			{}
		)

		imports.clear()
		exports.clear()
		trade_imports.clear()
		trade_exports.clear()

	# --------------------------------------------------------
	# EXECUTE ACTIVE AGREEMENTS
	# --------------------------------------------------------

	var agreement_ids: Array = world.trade_agreements.keys()
	agreement_ids.sort()

	# Prevent multiple active agreements from using the same exporter
	# stockpile units during this monthly trade resolution.
	var reserved_exports: Dictionary = {}

	# Agreements whose current monthly cycle was newly processed. They
	# advance exactly once after the trade resolution completes.
	var duration_progression_ids: Array[String] = []

	for agreement_id in agreement_ids:

		var agreement = world.get_trade_agreement(
			agreement_id
		)

		if agreement == null:
			continue

		if not agreement is TradeAgreement:
			continue

		if agreement.status != TradeAgreement.STATUS_ACTIVE:
			continue

		if not agreement.has_remaining_duration():
			agreement.expire()
			continue

		var linked_route = _find_linked_route(
			world,
			agreement_id
		)

		if linked_route != null and linked_route.status == TradeRoute.STATUS_DISRUPTED:
			agreement.interrupt(
				TradeAgreement.CAUSE_ROUTE_DISRUPTION
			)
			continue

		if linked_route == null:
			continue

		if linked_route.status != TradeRoute.STATUS_ACTIVE:
			continue

		var route = linked_route

		var transaction_id = _build_transaction_id(
			world,
			agreement_id,
			route.id
		)

		if world.has_trade_transaction(transaction_id):
			continue

		duration_progression_ids.append(agreement_id)

		var exporter = world.get_entity(
			agreement.exporter_id
		)

		var importer = world.get_entity(
			agreement.importer_id
		)

		if exporter == null or importer == null:
			_record_rejected_transaction(
				world,
				transaction_id,
				agreement,
				route
			)
			continue

		var exporter_resources = exporter.get_component(
            "resources"
		)

		var importer_resources = importer.get_component(
            "resources"
		)

		var exporter_infrastructure = exporter.get_component(
            "infrastructure"
		)

		var importer_infrastructure = importer.get_component(
            "infrastructure"
		)

		if (
			exporter_resources == null
			or importer_resources == null
			or exporter_infrastructure == null
			or importer_infrastructure == null
		):
			_record_rejected_transaction(
				world,
				transaction_id,
				agreement,
				route
			)
			continue

		var stockpile: Dictionary = exporter_resources.get_state(
			"stockpile",
			{}
		)

		var requested_quantity = max(
			0.0,
			float(agreement.quantity)
		)

		var current_stockpile = max(
			0.0,
			float(
				stockpile.get(
					agreement.resource_id,
					0.0
				)
			)
		)

		var reserve_key = (
			agreement.exporter_id
			+ "::"
			+ agreement.resource_id
		)

		var already_reserved = max(
			0.0,
			float(
				reserved_exports.get(
					reserve_key,
					0.0
				)
			)
		)

		var available_export_quantity = max(
			0.0,
			current_stockpile - already_reserved
		)

		var route_available_quantity = route.get_available_throughput(
			requested_quantity
		)

		var infrastructure_resolution = _resolve_infrastructure_availability(
			exporter_infrastructure,
			importer_infrastructure,
			requested_quantity
		)

		var port_available_quantity = infrastructure_resolution["ports"]
		var transport_available_quantity = infrastructure_resolution["transport"]
		var roads_available_quantity = infrastructure_resolution["roads"]
		var railways_available_quantity = infrastructure_resolution["railways"]
		var infrastructure_available_quantity = infrastructure_resolution["combined"]

		var actual_exported_quantity = min(
			requested_quantity,
			available_export_quantity,
			route_available_quantity,
			port_available_quantity,
			transport_available_quantity,
			roads_available_quantity,
			railways_available_quantity,
			infrastructure_available_quantity
		)

		# 4.5 treats the resolved physical infrastructure chain as the
		# complete route bottleneck. A successfully exported unit therefore
		# arrives at the importer in the same monthly transaction.
		var actual_imported_quantity = actual_exported_quantity

		if actual_exported_quantity > 0.0:

			reserved_exports[reserve_key] = (
				already_reserved
				+ actual_exported_quantity
			)

			var exporter_flows = exporter_resources.get_state(
				"exports",
				{}
			)

			var importer_flows = importer_resources.get_state(
				"imports",
				{}
			)

			var exporter_trade_flows = exporter_resources.get_state(
				"trade_exports",
				{}
			)

			var importer_trade_flows = importer_resources.get_state(
				"trade_imports",
				{}
			)

			exporter_flows[agreement.resource_id] = (
				float(
					exporter_flows.get(
						agreement.resource_id,
						0.0
					)
				)
				+ actual_exported_quantity
			)

			importer_flows[agreement.resource_id] = (
				float(
					importer_flows.get(
						agreement.resource_id,
						0.0
					)
				)
				+ actual_imported_quantity
			)

			exporter_trade_flows[agreement.resource_id] = (
				float(
					exporter_trade_flows.get(
						agreement.resource_id,
						0.0
					)
				)
				+ actual_exported_quantity
			)

			importer_trade_flows[agreement.resource_id] = (
				float(
					importer_trade_flows.get(
						agreement.resource_id,
						0.0
					)
				)
				+ actual_imported_quantity
			)

		var transaction = TradeTransaction.new(
			transaction_id,
			agreement.id,
			route.id,
			agreement.exporter_id,
			agreement.importer_id,
			agreement.resource_id,
			requested_quantity,
			actual_exported_quantity,
			world.current_date,
			available_export_quantity,
			route_available_quantity,
			actual_exported_quantity,
			actual_imported_quantity,
			port_available_quantity,
			transport_available_quantity,
			roads_available_quantity,
			railways_available_quantity,
			infrastructure_available_quantity
		)

		if not world.add_trade_transaction(transaction):
			push_error(
                "TradeSystem: Failed to register transaction: "
				+ transaction_id
			)

	# --------------------------------------------------------
	# STEP 4.6 — ADVANCE CONTRACT DURATION
	# --------------------------------------------------------
	# Duration advances only for agreements whose current monthly cycle
	# was newly processed. The final month is therefore executable, and
	# expiration occurs immediately after that month's transaction.

	for agreement_id in duration_progression_ids:

		var processed_agreement = world.get_trade_agreement(
			agreement_id
		)

		if processed_agreement == null:
			continue

		if processed_agreement.status != TradeAgreement.STATUS_ACTIVE:
			continue

		processed_agreement.advance_one_month()


func _resolve_infrastructure_availability(
	exporter_infrastructure: InfrastructureComponent,
	importer_infrastructure: InfrastructureComponent,
	requested_quantity: float
) -> Dictionary:

	var requested = max(
		0.0,
		requested_quantity
	)

	var exporter_ports = _normalized_infrastructure_value(
		exporter_infrastructure,
        "ports"
	)

	var importer_ports = _normalized_infrastructure_value(
		importer_infrastructure,
        "ports"
	)

	var exporter_transport = _normalized_infrastructure_value(
		exporter_infrastructure,
        "transport"
	)

	var importer_transport = _normalized_infrastructure_value(
		importer_infrastructure,
        "transport"
	)

	var exporter_roads = _normalized_infrastructure_value(
		exporter_infrastructure,
        "roads"
	)

	var importer_roads = _normalized_infrastructure_value(
		importer_infrastructure,
        "roads"
	)

	var exporter_railways = _normalized_infrastructure_value(
		exporter_infrastructure,
        "railways"
	)

	var importer_railways = _normalized_infrastructure_value(
		importer_infrastructure,
        "railways"
	)

	var port_factor = min(
		exporter_ports,
		importer_ports
	)

	var transport_factor = min(
		exporter_transport,
		importer_transport
	)

	var roads_factor = min(
		exporter_roads,
		importer_roads
	)

	var railways_factor = min(
		exporter_railways,
		importer_railways
	)

	var combined_factor = min(
		port_factor,
		transport_factor,
		roads_factor,
		railways_factor
	)

	return {
		"ports": requested * port_factor,
		"transport": requested * transport_factor,
		"roads": requested * roads_factor,
		"railways": requested * railways_factor,
		"combined": requested * combined_factor
	}


func _normalized_infrastructure_value(
	infrastructure: InfrastructureComponent,
	key: String
) -> float:

	if infrastructure == null:
		return 0.0

	return clampf(
		max(
			0.0,
			float(
				infrastructure.get_state(
					key,
					1.0
				)
			)
		),
		0.0,
		1.0
	)


func _find_linked_route(
	world: WorldState,
	agreement_id: String
):

	var route_ids: Array = world.trade_routes.keys()
	route_ids.sort()

	for route_id in route_ids:

		var route = world.get_trade_route(
			route_id
		)

		if route == null:
			continue

		if not route is TradeRoute:
			continue

		if route.agreement_id != agreement_id:
			continue

		return route

	return null


func _build_transaction_id(
	world: WorldState,
	agreement_id: String,
	route_id: String
) -> String:

	var year = int(
		world.current_date.get(
			"year",
			0
		)
	)

	var month = int(
		world.current_date.get(
			"month",
			0
		)
	)

	return (
        "trade_transaction_"
		+ str(year)
		+ "_"
		+ str(month)
		+ "_"
		+ agreement_id
		+ "_"
		+ route_id
	)


func _record_rejected_transaction(
	world: WorldState,
	transaction_id: String,
	agreement: TradeAgreement,
	route: TradeRoute
) -> void:

	var transaction = TradeTransaction.new(
		transaction_id,
		agreement.id,
		route.id,
		agreement.exporter_id,
		agreement.importer_id,
		agreement.resource_id,
		max(0.0, float(agreement.quantity)),
		0.0,
		world.current_date,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0
	)

	transaction.status = TradeTransaction.STATUS_REJECTED

	world.add_trade_transaction(
		transaction
	)
