class_name WorldSnapshot
extends RefCounted


# ============================================================
# SNAPSHOT DATA
# ============================================================

var date: Dictionary = {}

var elapsed_months: int = 0

var elapsed_years: float = 0.0

var entity_count: int = 0

var entities: Dictionary = {}

var trade_agreement_count: int = 0

var trade_agreements: Dictionary = {}

var trade_route_count: int = 0

var trade_routes: Dictionary = {}

var trade_transaction_count: int = 0

var trade_transactions: Dictionary = {}


# Step 15.12 — transient executable-action state captured alongside
# the world snapshot. Domain state remains owned by WorldState.
var action_snapshot_state: Dictionary = {}


# ============================================================
# CAPTURE WORLD
# ============================================================

func capture(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"WorldSnapshot: World is null."
		)

		return


	# ========================================================
	# DATE
	# ========================================================

	date = world.current_date.duplicate(
		true
	)


	# ========================================================
	# SIMULATION TIME
	# ========================================================

	elapsed_months = world.get_elapsed_months()

	elapsed_years = world.get_elapsed_years()


	# ========================================================
	# ENTITY COUNT
	# ========================================================

	entity_count = world.entities.size()


	# ========================================================
	# CLEAR PREVIOUS SNAPSHOT
	# ========================================================

	entities.clear()
	trade_agreements.clear()
	trade_routes.clear()
	trade_transactions.clear()

	# Action state is attached by SimulationEngine after world capture.
	action_snapshot_state.clear()


	# ========================================================
	# CAPTURE ENTITIES
	# ========================================================

	for entity_id in world.entities.keys():

		var entity = world.entities[entity_id]

		if entity == null:
			continue


		var entity_snapshot = {
			"id": entity.id,
			"name": entity.name,
			"entity_type": entity.entity_type,
			"relationships": entity.relationships.duplicate(true)
		}


		# ====================================================
		# COMPONENTS
		# ====================================================

		var component_snapshots: Dictionary = {}


		for component_type in entity.components.keys():

			var component = entity.components[
				component_type
			]

			if component == null:
				continue


			component_snapshots[component_type] = {
				"state": component.state.duplicate(true),
				"baseline_state": component.baseline_state.duplicate(true),
				"capabilities": component.capabilities.duplicate(true),
				"constraints": component.constraints.duplicate(true)
			}


		entity_snapshot["components"] = (
			component_snapshots
		)


		entities[entity_id] = entity_snapshot


	# ========================================================
	# TRADE AGREEMENTS
	# ========================================================

	trade_agreement_count = world.trade_agreements.size()

	for agreement_id in world.trade_agreements.keys():

		var agreement = world.trade_agreements[agreement_id]

		if agreement == null:
			continue

		if agreement is TradeAgreement:
			trade_agreements[agreement_id] = (
				agreement.to_snapshot_dict()
			)


	# ========================================================
	# TRADE ROUTES
	# ========================================================

	trade_route_count = world.trade_routes.size()

	for route_id in world.trade_routes.keys():

		var route = world.trade_routes[route_id]

		if route == null:
			continue

		if route is TradeRoute:
			trade_routes[route_id] = (
				route.to_snapshot_dict()
			)


# ============================================================
# ========================================================
# TRADE TRANSACTIONS
# ========================================================

	trade_transaction_count = world.trade_transactions.size()

	for transaction_id in world.trade_transactions.keys():

		var transaction = world.trade_transactions[transaction_id]

		if transaction == null:
			continue

		if transaction is TradeTransaction:
			trade_transactions[transaction_id] = (
				transaction.to_snapshot_dict()
			)


# ============================================================
# STEP 15.12 — ACTION SNAPSHOT ACCESS
# ============================================================

func set_action_snapshot_state(
	state: Dictionary
) -> void:
	action_snapshot_state = state.duplicate(true)


func get_action_snapshot_state() -> Dictionary:
	return action_snapshot_state.duplicate(true)


# ============================================================
# COMPARE SNAPSHOT
# ============================================================

func compare_with(
	other: WorldSnapshot
) -> Dictionary:

	var result: Dictionary = {
		"date_difference": {},
		"entity_changes": {},
		"trade_agreement_changes": {
			"added": [],
			"removed": [],
			"changed": {}
		},
		"trade_route_changes": {
			"added": [],
			"removed": [],
			"changed": {}
		},
		"trade_transaction_changes": {
			"added": [],
			"removed": [],
			"changed": {}
		}
	}


	# ========================================================
	# VALIDATE OTHER SNAPSHOT
	# ========================================================

	if other == null:

		push_error(
			"WorldSnapshot: Cannot compare with null snapshot."
		)

		return result






	

	# ========================================================
	# DATE DIFFERENCE
	# ========================================================

	result["date_difference"] = {
		"year":
			int(date.get("year", 0))
			- int(other.date.get("year", 0)),

		"month":
			int(date.get("month", 0))
			- int(other.date.get("month", 0)),

		"day":
			int(date.get("day", 0))
			- int(other.date.get("day", 0)),

		"elapsed_months":
			elapsed_months
			- other.elapsed_months,

		"elapsed_years":
			elapsed_years
			- other.elapsed_years
	}


	# ========================================================
	# ENTITY COMPARISON
	# ========================================================

	for entity_id in entities.keys():

		if not other.entities.has(entity_id):
			continue


		var current_entity = entities[
			entity_id
		]

		var previous_entity = other.entities[
			entity_id
		]


		var entity_result: Dictionary = {
			"components": {},
			"relationships": {}
		}


		# ====================================================
		# RELATIONSHIPS
		# ====================================================

		var current_relationships = (
			current_entity.get(
				"relationships",
				{}
			)
		)

		var previous_relationships = (
			previous_entity.get(
				"relationships",
				{}
			)
		)


		for target_id in current_relationships.keys():

			if not previous_relationships.has(
				target_id
			):

				continue


			var current_value = float(
				current_relationships[
					target_id
				]
			)

			var previous_value = float(
				previous_relationships[
					target_id
				]
			)


			entity_result["relationships"][
				target_id
			] = (
				current_value
				- previous_value
			)


		# ====================================================
		# COMPONENTS
		# ====================================================

		var current_components = (
			current_entity.get(
				"components",
				{}
			)
		)

		var previous_components = (
			previous_entity.get(
				"components",
				{}
			)
		)


		for component_type in current_components.keys():

			if not previous_components.has(
				component_type
			):

				continue


			var current_component = (
				current_components[
					component_type
				]
			)

			var previous_component = (
				previous_components[
					component_type
				]
			)


			var current_state = (
				current_component.get(
					"state",
					{}
				)
			)

			var previous_state = (
				previous_component.get(
					"state",
					{}
				)
			)


			var state_changes: Dictionary = {}


			# =================================================
			# STATE VALUES
			# =================================================

			for key in current_state.keys():

				if not previous_state.has(
					key
				):

					continue


				var current_value = (
					current_state[key]
				)

				var previous_value = (
					previous_state[key]
				)


				if (
					typeof(current_value)
					== TYPE_INT
					or
					typeof(current_value)
					== TYPE_FLOAT
				):

					if (
						typeof(previous_value)
						== TYPE_INT
						or
						typeof(previous_value)
						== TYPE_FLOAT
					):

						state_changes[key] = (
							float(current_value)
							- float(previous_value)
						)


			entity_result["components"][
				component_type
			] = state_changes


		# ====================================================
		# SAVE ENTITY RESULT
		# ====================================================

		result["entity_changes"][
			entity_id
		] = entity_result


	# ========================================================
	# TRADE AGREEMENT COMPARISON
	# ========================================================

	for agreement_id in trade_agreements.keys():

		if not other.trade_agreements.has(agreement_id):
			result["trade_agreement_changes"]["added"].append(
				agreement_id
			)
			continue

		var current_agreement = trade_agreements[agreement_id]
		var previous_agreement = other.trade_agreements[agreement_id]

		if current_agreement != previous_agreement:
			result["trade_agreement_changes"]["changed"][
				agreement_id
			] = {
				"current": current_agreement.duplicate(true),
				"previous": previous_agreement.duplicate(true)
			}

	for agreement_id in other.trade_agreements.keys():

		if not trade_agreements.has(agreement_id):
			result["trade_agreement_changes"]["removed"].append(
				agreement_id
			)


	# ========================================================
	# TRADE ROUTE COMPARISON
	# ========================================================

	for route_id in trade_routes.keys():

		if not other.trade_routes.has(route_id):
			result["trade_route_changes"]["added"].append(
				route_id
			)
			continue

		var current_route = trade_routes[route_id]
		var previous_route = other.trade_routes[route_id]

		if current_route != previous_route:
			result["trade_route_changes"]["changed"][route_id] = {
				"current": current_route.duplicate(true),
				"previous": previous_route.duplicate(true)
			}

	for route_id in other.trade_routes.keys():

		if not trade_routes.has(route_id):
			result["trade_route_changes"]["removed"].append(
				route_id
			)


	# ========================================================
	# ========================================================
# TRADE TRANSACTION COMPARISON
# ========================================================

	for transaction_id in trade_transactions.keys():

		if not other.trade_transactions.has(transaction_id):
			result["trade_transaction_changes"]["added"].append(
				transaction_id
			)
			continue

		var current_transaction = trade_transactions[transaction_id]
		var previous_transaction = other.trade_transactions[transaction_id]

		if current_transaction != previous_transaction:
			result["trade_transaction_changes"]["changed"][transaction_id] = {
				"current": current_transaction.duplicate(true),
				"previous": previous_transaction.duplicate(true)
			}

	for transaction_id in other.trade_transactions.keys():

		if not trade_transactions.has(transaction_id):
			result["trade_transaction_changes"]["removed"].append(
				transaction_id
			)


# RETURN RESULT
	# ========================================================

	return result
	
	
	
	# ============================================================
	# MILITARY SNAPSHOT HELPERS
	# ============================================================

func get_military_snapshot(entity_id: String) -> Dictionary:

	var result: Dictionary = {}

	if entity_id.is_empty():
		return result

	if not entities.has(entity_id):
		return result

	var entity_snapshot = entities[entity_id]

	var components = entity_snapshot.get(
		"components",
		{}
	)

	if not components.has("military"):
		return result

	var military_component = components["military"]

	var military_state = military_component.get(
		"state",
		{}
	)

	result = {
		"entity_id": entity_id,
		"entity_name": entity_snapshot.get(
			"name",
			entity_id
		),
		"date": date.duplicate(true),
		"elapsed_months": elapsed_months,
		"elapsed_years": elapsed_years,
		"state": military_state.duplicate(true)
	}

	return result
