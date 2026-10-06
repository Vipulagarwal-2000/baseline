class_name ActionManager
extends SimulationSystem


# ============================================================
# STEP 15 — ACTION MANAGER
# ============================================================
#
# Step 15.4 remains the structural validation boundary.
# Step 15.5 adds read-only checks against authoritative domain
# state. Step 15.6 adds reservation/commitment accounting before
# the action enters the authoritative execution queue.
#
# Domain ownership remains outside ActionManager:
#   resources -> ResourceComponent / ResourceSystem
#   finances  -> EconomyComponent / EconomySystem
#   capability -> entity capability metadata maintained by
#                 CapabilitySystem and other authoritative systems
#   capacity -> existing domain state (economy / industry /
#               resources / explicit capacity metadata)
#
# Step 15.6 reservation accounting does not mutate authoritative
# domain state. Payment, consumption, and capacity mutation remain
# later Step 15 work.
# ============================================================


var pending_actions: Array = []
var validation_world: WorldState = null

# Step 15.11 auditable terminal outcome ledger.
# This is an execution-history source for the later OUTPUT/History layer.
# It does not replace HistorySystem or become a second simulation state.
var outcome_history: Array = []
var outcome_index: Dictionary = {}

# Step 15.6 reservation/commitment ledger.
# This ledger tracks claims without mutating authoritative domain state.
const RESERVATION_STATUS_RESERVED: String = "reserved"
const RESERVATION_STATUS_COMMITTED: String = "committed"
var reservation_ledger: Dictionary = {}

# Step 16.4 deterministic admission-order ledger.
# The ledger provides a stable tie-breaker for equal-priority actions
# without changing the pending queue into a second authority.
var admission_order_ledger: Dictionary = {}
var next_admission_order: int = 0


func _init(validation_world_state: WorldState = null) -> void:
	super("action_manager")
	validation_world = validation_world_state


func set_validation_world(world: WorldState) -> void:
	validation_world = world


func add_action(
	action: SimAction,
	validation_world_override: WorldState = null
) -> bool:
	if action == null:
		push_error("ActionManager: Cannot add null action.")
		return false

	var world_for_validation: WorldState = validation_world
	if validation_world_override != null:
		world_for_validation = validation_world_override

	if not validate_action(world_for_validation, action):
		_record_terminal_outcome(world_for_validation, action)
		return false

	if not check_action_requirements(world_for_validation, action):
		_record_terminal_outcome(world_for_validation, action)
		return false

	# ========================================================
	# STEP 16.1 — CONCURRENT ACTION CAPACITY
	# ========================================================
	#
	# This is a bounded execution-slot check. It does not replace
	# resource, financial, capability, or domain-capacity checks.
	# Pending queued/active actions are the authoritative occupancy
	# representation for this execution capacity.
	#
	# Because the simulator is single-threaded and admission occurs
	# synchronously, the pending-action list provides deterministic
	# slot ownership without introducing a second capacity ledger.

	if not _check_concurrent_action_capacity(
		world_for_validation,
		action
	):
		_record_terminal_outcome(world_for_validation, action)
		return false

	_ensure_action_start_date(world_for_validation, action)

	# Establish the original duration before the action enters the queue.
	# duration_months remains the legacy remaining-duration field.
	if action.progress <= 0.0 and action.state == SimAction.STATE_QUEUED:
		action.total_duration_months = action.duration_months

	if not reserve_action(world_for_validation, action):
		_record_terminal_outcome(world_for_validation, action)
		return false

	if not commit_action(action):
		release_action_reservation(action)
		_record_terminal_outcome(world_for_validation, action)
		return false

	admission_order_ledger[action.get_instance_id()] = next_admission_order
	next_admission_order += 1
	pending_actions.append(action)
	return true


# ============================================================
# STEP 15.4 — STRUCTURAL VALIDATION
# ============================================================

func validate_action(
	world: WorldState,
	action: SimAction
) -> bool:
	if action == null:
		return false

	if not _is_terminal_state(action.state):
		action.failure_reason = ""

	var reason: String = _get_validation_failure_reason(
		world,
		action
	)

	if reason.is_empty():
		return true

	if _is_terminal_state(action.state):
		return false

	action.state = SimAction.STATE_FAILED
	action.failure_reason = reason
	return false


func _is_terminal_state(state: String) -> bool:
	return (
		state == SimAction.STATE_COMPLETED
		or state == SimAction.STATE_FAILED
		or state == SimAction.STATE_CANCELLED
		or state == SimAction.STATE_INTERRUPTED
	)


func _remove_pending_action(action: SimAction) -> void:
	if action == null:
		return

	pending_actions.erase(action)
	admission_order_ledger.erase(action.get_instance_id())


func cancel_action(
	action: SimAction,
	reason: String = "Action cancelled."
) -> bool:
	if action == null:
		return false

	if (
		action.state != SimAction.STATE_QUEUED
		and action.state != SimAction.STATE_ACTIVE
	):
		return false

	action.state = SimAction.STATE_CANCELLED
	action.failure_reason = (
		reason
		if not reason.strip_edges().is_empty()
		else "Action cancelled."
	)
	release_action_reservation(action)
	_remove_pending_action(action)
	_record_terminal_outcome(validation_world, action)
	return true


func interrupt_action(
	action: SimAction,
	reason: String = "Action interrupted."
) -> bool:
	if action == null:
		return false

	if action.state != SimAction.STATE_ACTIVE:
		return false

	action.state = SimAction.STATE_INTERRUPTED
	action.failure_reason = (
		reason
		if not reason.strip_edges().is_empty()
		else "Action interrupted."
	)
	release_action_reservation(action)
	_remove_pending_action(action)
	_record_terminal_outcome(validation_world, action)
	return true


func fail_action(
	action: SimAction,
	reason: String = "Action failed."
) -> bool:
	if action == null:
		return false

	if _is_terminal_state(action.state):
		return false

	action.state = SimAction.STATE_FAILED
	action.failure_reason = (
		reason
		if not reason.strip_edges().is_empty()
		else "Action failed."
	)
	release_action_reservation(action)
	_remove_pending_action(action)
	_record_terminal_outcome(validation_world, action)
	return true


func _get_validation_failure_reason(
	world: WorldState,
	action: SimAction
) -> String:
	if world == null:
		return "Action validation failed: world context is required."

	if action.actor_id.strip_edges().is_empty():
		return "Action validation failed: actor is required."

	if not world.has_entity(action.actor_id):
		return (
			"Action validation failed: actor does not exist: "
			+ action.actor_id
		)

	if action.action_type.strip_edges().is_empty():
		return "Action validation failed: action type is required."

	if action.duration_months <= 0:
		return "Action validation failed: duration must be greater than zero."

	if action.state != SimAction.STATE_QUEUED:
		return "Action validation failed: action must be queued before commitment."

	if not action.target_id.strip_edges().is_empty():
		if not world.has_entity(action.target_id):
			return (
				"Action validation failed: target does not exist: "
				+ action.target_id
			)

	if action.cost < 0.0:
		return "Action validation failed: cost cannot be negative."

	if not (action.resource_requirements is Dictionary):
		return "Action validation failed: resource requirements must be a Dictionary."

	if not (action.financial_requirements is Dictionary):
		return "Action validation failed: financial requirements must be a Dictionary."

	if not (action.capability_requirements is Dictionary):
		return "Action validation failed: capability requirements must be a Dictionary."

	if not (action.capacity_requirements is Dictionary):
		return "Action validation failed: capacity requirements must be a Dictionary."

	if not (action.effects is Dictionary):
		return "Action validation failed: effects must be a Dictionary."

	if not (action.completion_result is Dictionary):
		return "Action validation failed: completion result must be a Dictionary."

	return ""


# ============================================================
# STEP 15.5 — AUTHORITATIVE DOMAIN REQUIREMENT CHECKS
# ============================================================

func check_action_requirements(
	world: WorldState,
	action: SimAction
) -> bool:
	if action == null:
		return false

	action.failure_reason = ""

	var reason: String = _get_requirement_failure_reason(
		world,
		action
	)

	if reason.is_empty():
		return true

	action.state = SimAction.STATE_FAILED
	action.failure_reason = reason
	return false


func _get_requirement_failure_reason(
	world: WorldState,
	action: SimAction
) -> String:
	if world == null:
		return "Action requirement check failed: world context is required."

	var actor: SimEntity = world.get_entity(action.actor_id) as SimEntity
	if actor == null:
		return (
			"Action requirement check failed: actor does not exist: "
			+ action.actor_id
		)

	# ------------------------------------------------------------
	# RESOURCE AVAILABILITY
	# ------------------------------------------------------------
	if not action.resource_requirements.is_empty():
		var resources: SimComponent = actor.get_component("resources") as SimComponent
		if resources == null:
			return "Action requirement check failed: actor has no resource component."

		var stockpile_value: Variant = resources.get_state(
			"stockpile",
			{}
		)
		if typeof(stockpile_value) != TYPE_DICTIONARY:
			return "Action requirement check failed: resource stockpile state is invalid."

		var stockpile: Dictionary = stockpile_value

		for resource_key in action.resource_requirements.keys():
			var resource_name: String = str(resource_key)
			var required_raw: Variant = action.resource_requirements[resource_key]

			var numeric_error: String = _validate_non_negative_numeric_requirement(
				required_raw,
				"resource",
				resource_name
			)
			if not numeric_error.is_empty():
				return numeric_error

			var required_amount: float = float(required_raw)
			var available_raw: Variant = stockpile.get(
				resource_name,
				0.0
			)
			if not _is_numeric(available_raw):
				return (
					"Action requirement check failed: resource state is not numeric: "
					+ resource_name
				)

			var available_amount: float = maxf(
				float(available_raw),
				0.0
			)

			if available_amount + 0.000001 < required_amount:
				return (
					"Action requirement check failed: insufficient resource "
					+ resource_name
					+ " (required="
					+ str(required_amount)
					+ ", available="
					+ str(available_amount)
					+ ")"
				)

	# ------------------------------------------------------------
	# FINANCIAL AVAILABILITY
	# ------------------------------------------------------------
	if action.cost > 0.0 or not action.financial_requirements.is_empty():
		var economy: SimComponent = actor.get_component("economy") as SimComponent
		if economy == null:
			return "Action requirement check failed: actor has no economy component."

		if action.cost > 0.0:
			var treasury_raw: Variant = economy.get_state(
				"treasury",
				0.0
			)
			if not _is_numeric(treasury_raw):
				return "Action requirement check failed: treasury state is not numeric."

			var treasury: float = maxf(float(treasury_raw), 0.0)
			if treasury + 0.000001 < action.cost:
				return (
					"Action requirement check failed: insufficient treasury (required="
					+ str(action.cost)
					+ ", available="
					+ str(treasury)
					+ ")"
				)

		for financial_key in action.financial_requirements.keys():
			var financial_key_name: String = str(financial_key)
			var required_raw: Variant = action.financial_requirements[financial_key]

			var numeric_error: String = _validate_non_negative_numeric_requirement(
				required_raw,
				"financial",
				financial_key_name
			)
			if not numeric_error.is_empty():
				return numeric_error

			var required_amount: float = float(required_raw)
			var available_raw: Variant = economy.get_state(
				financial_key_name,
				0.0
			)
			if not _is_numeric(available_raw):
				return (
					"Action requirement check failed: financial state is not numeric: "
					+ financial_key_name
				)

			var available_value: float = maxf(
				float(available_raw),
				0.0
			)
			if available_value + 0.000001 < required_amount:
				return (
					"Action requirement check failed: insufficient financial state "
					+ financial_key_name
					+ " (required="
					+ str(required_amount)
					+ ", available="
					+ str(available_value)
					+ ")"
				)

	# ------------------------------------------------------------
	# CAPABILITY AVAILABILITY
	# ------------------------------------------------------------
	if not action.capability_requirements.is_empty():
		var capabilities_value: Variant = actor.get_sim_metadata(
			"capabilities",
			null
		)
		if typeof(capabilities_value) != TYPE_DICTIONARY:
			return "Action requirement check failed: capability state is invalid."

		var capabilities: Dictionary = capabilities_value
		var capability_failure: String = _check_requirement_dictionary(
			action.capability_requirements,
			capabilities,
			"capability"
		)
		if not capability_failure.is_empty():
			return capability_failure

	# ------------------------------------------------------------
	# CAPACITY AVAILABILITY
	# ------------------------------------------------------------
	if not action.capacity_requirements.is_empty():
		var capacity_failure: String = _check_capacity_requirements(
			actor,
			action.capacity_requirements
		)
		if not capacity_failure.is_empty():
			return capacity_failure

	return ""


func _check_capacity_requirements(
	actor: SimEntity,
	requirements: Dictionary
) -> String:
	# Capacity is read from existing authoritative state only. The action
	# layer does not create or modify a capacity ledger.
	var capacity_sources: Array = []

	var economy: SimComponent = actor.get_component("economy") as SimComponent
	if economy != null:
		capacity_sources.append(economy.state)

	var industry: SimComponent = actor.get_component("industry") as SimComponent
	if industry != null:
		capacity_sources.append(industry.state)

	var resources: SimComponent = actor.get_component("resources") as SimComponent
	if resources != null:
		capacity_sources.append(resources.state)

	var capacity_metadata: Variant = actor.get_sim_metadata(
		"capacity",
		null
	)
	if typeof(capacity_metadata) == TYPE_DICTIONARY:
		capacity_sources.append(capacity_metadata)

	for capacity_key in requirements.keys():
		var key: String = str(capacity_key)
		var required_raw: Variant = requirements[capacity_key]

		var numeric_error: String = _validate_non_negative_numeric_requirement(
			required_raw,
			"capacity",
			key
		)
		if not numeric_error.is_empty():
			return numeric_error

		var required_amount: float = float(required_raw)
		var found: bool = false
		var available_value: float = 0.0

		for source_variant in capacity_sources:
			if typeof(source_variant) != TYPE_DICTIONARY:
				continue

			var source: Dictionary = source_variant
			if not source.has(key):
				continue

			var raw_available: Variant = source.get(key, 0.0)
			if not _is_numeric(raw_available):
				return (
					"Action requirement check failed: capacity state is not numeric: "
					+ key
				)

			available_value = maxf(
				float(raw_available),
				0.0
			)
			found = true
			break

		if not found:
			return (
				"Action requirement check failed: capacity state not found: "
				+ key
			)

		if available_value + 0.000001 < required_amount:
			return (
				"Action requirement check failed: insufficient capacity "
				+ key
				+ " (required="
				+ str(required_amount)
				+ ", available="
				+ str(available_value)
				+ ")"
			)

	return ""


func _check_requirement_dictionary(
	requirements: Dictionary,
	available: Dictionary,
	label: String
) -> String:
	for requirement_key in requirements.keys():
		var key: String = str(requirement_key)
		var required_value: Variant = requirements[requirement_key]

		if not available.has(key):
			return (
				"Action requirement check failed: missing "
				+ label
				+ " state: "
				+ key
			)

		var available_value: Variant = available[key]

		if _is_numeric(required_value):
			var numeric_error: String = _validate_non_negative_numeric_requirement(
				required_value,
				label,
				key
			)
			if not numeric_error.is_empty():
				return numeric_error

			if not _is_numeric(available_value):
				return (
					"Action requirement check failed: "
					+ label
					+ " state is not numeric: "
					+ key
				)

			var required_amount: float = float(required_value)
			var actual_amount: float = maxf(float(available_value), 0.0)
			if actual_amount + 0.000001 < required_amount:
				return (
					"Action requirement check failed: insufficient "
					+ label
					+ " "
					+ key
					+ " (required="
					+ str(required_amount)
					+ ", available="
					+ str(actual_amount)
					+ ")"
				)

		elif typeof(required_value) == TYPE_BOOL:
			if (
				typeof(available_value) != TYPE_BOOL
				or bool(available_value) != bool(required_value)
			):
				return (
					"Action requirement check failed: "
					+ label
					+ " requirement not satisfied: "
					+ key
				)

		else:
			if str(available_value) != str(required_value):
				return (
					"Action requirement check failed: "
					+ label
					+ " requirement mismatch: "
					+ key
				)

	return ""


func _validate_non_negative_numeric_requirement(
	value: Variant,
	label: String,
	key: String
) -> String:
	if not _is_numeric(value):
		return (
			"Action requirement check failed: "
			+ label
			+ " requirement is not numeric: "
			+ key
		)

	if float(value) < 0.0:
		return (
			"Action requirement check failed: "
			+ label
			+ " requirement cannot be negative: "
			+ key
		)

	return ""


func _is_numeric(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_INT
		or typeof(value) == TYPE_FLOAT
	)


# ============================================================
# STEP 16.1 — CONCURRENT ACTION CAPACITY
# ============================================================

func get_concurrent_action_count(actor_id: String) -> int:
	if actor_id.strip_edges().is_empty():
		return 0

	var count: int = 0

	for action_variant in pending_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue

		if action.actor_id != actor_id:
			continue

		if (
			action.state == SimAction.STATE_QUEUED
			or action.state == SimAction.STATE_ACTIVE
		):
			count += 1

	return count


func get_action_capacity_limit(
	world: WorldState,
	actor_id: String
) -> int:
	var default_limit: int = 1

	if world != null and world.config != null:
		default_limit = maxi(
			world.config.max_concurrent_actions_per_actor,
			1
		)

	if world == null:
		return default_limit

	var actor: SimEntity = world.get_entity(actor_id) as SimEntity
	if actor == null:
		return default_limit

	# Optional actor-level override uses existing SimEntity metadata.
	# This does not create a new component or authority system.
	var override_value: Variant = actor.get_sim_metadata(
		"max_concurrent_actions",
		null
	)

	if typeof(override_value) == TYPE_INT:
		return maxi(
			int(override_value),
			1
		)

	if typeof(override_value) == TYPE_FLOAT:
		return maxi(
			int(round(float(override_value))),
			1
		)

	return default_limit


func _check_concurrent_action_capacity(
	world: WorldState,
	action: SimAction
) -> bool:
	if world == null or action == null:
		return false

	var limit: int = get_action_capacity_limit(
		world,
		action.actor_id
	)

	var current_count: int = get_concurrent_action_count(
		action.actor_id
	)

	if current_count >= limit:
		action.state = SimAction.STATE_FAILED
		action.failure_reason = (
		"Action admission failed: concurrent action capacity exceeded "
		+ "(active="
		+ str(current_count)
		+ ", limit="
		+ str(limit)
		+ ")."
	)
		return false

	return true


# ============================================================
# STEP 16.4 — DETERMINISTIC RESOLUTION
# ============================================================
#
# Resolution policy:
#   1. Higher action priority resolves first.
#   2. Equal-priority actions resolve by deterministic admission order.
#   3. Reservation/commitment remains established at admission and is
#      not retroactively displaced by a later higher-priority action.
#   4. Completion effects are applied in the same deterministic order
#      in which actions were resolved for the monthly pass.
#
# The pending_actions list remains the admission queue. This ordered
# copy is an execution-resolution view, not a second queue authority.
# ============================================================

func get_deterministic_resolution_order() -> Array:
	var ordered_actions: Array = _get_deterministic_resolution_actions()
	var result: Array = []

	for action_variant in ordered_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue
		result.append({
			"action_id": action.get_instance_id(),
			"action_type": action.action_type,
			"priority": action.priority,
			"admission_order": _get_admission_order(action)
		})

	return result


func _get_deterministic_resolution_actions() -> Array:
	var ordered_actions: Array = []

	for action_variant in pending_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue

		var insert_index: int = ordered_actions.size()
		for index in range(ordered_actions.size()):
			var existing_action: SimAction = ordered_actions[index] as SimAction
			if existing_action == null:
				continue

			if _action_precedes_for_resolution(action, existing_action):
				insert_index = index
				break

		ordered_actions.insert(insert_index, action)

	return ordered_actions


func _action_precedes_for_resolution(
	left_action: SimAction,
	right_action: SimAction
) -> bool:
	if left_action == null:
		return false
	if right_action == null:
		return true

	if left_action.priority != right_action.priority:
		return left_action.priority > right_action.priority

	return _get_admission_order(left_action) < _get_admission_order(right_action)


func _get_admission_order(action: SimAction) -> int:
	if action == null:
		return 2147483647

	var order_value: Variant = admission_order_ledger.get(
		action.get_instance_id(),
		-1
	)
	if typeof(order_value) == TYPE_INT:
		return int(order_value)

	# Restored/legacy actions without an explicit ledger entry are placed
	# after explicitly admitted actions while preserving pending-array order.
	return 2147483647


func _rebuild_admission_order_ledger() -> void:
	admission_order_ledger.clear()
	next_admission_order = 0

	for action_variant in pending_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue

		admission_order_ledger[action.get_instance_id()] = next_admission_order
		next_admission_order += 1


# ============================================================
# STEP 15.6 — RESERVATION / COMMITMENT
# ============================================================

func reserve_action(
	world: WorldState,
	action: SimAction
) -> bool:
	if action == null:
		return false

	var action_instance_id: int = action.get_instance_id()
	if reservation_ledger.has(action_instance_id):
		action.state = SimAction.STATE_FAILED
		action.failure_reason = (
			"Action commitment failed: action is already reserved."
		)
		return false

	var reason: String = _get_reservation_failure_reason(
		world,
		action
	)
	if not reason.is_empty():
		action.state = SimAction.STATE_FAILED
		action.failure_reason = reason
		return false

	var reservation: Dictionary = _build_reservation_record(action)
	reservation_ledger[action_instance_id] = reservation
	action.failure_reason = ""
	return true


func commit_action(action: SimAction) -> bool:
	if action == null:
		return false

	var action_instance_id: int = action.get_instance_id()
	if not reservation_ledger.has(action_instance_id):
		action.state = SimAction.STATE_FAILED
		action.failure_reason = (
			"Action commitment failed: reservation is missing."
		)
		return false

	var reservation_value: Variant = reservation_ledger.get(
		action_instance_id,
		{}
	)
	if typeof(reservation_value) != TYPE_DICTIONARY:
		action.state = SimAction.STATE_FAILED
		action.failure_reason = (
			"Action commitment failed: reservation record is invalid."
		)
		return false

	var reservation: Dictionary = reservation_value
	reservation["status"] = RESERVATION_STATUS_COMMITTED
	reservation_ledger[action_instance_id] = reservation
	return true


func release_action_reservation(action: SimAction) -> bool:
	if action == null:
		return false

	var action_instance_id: int = action.get_instance_id()
	if not reservation_ledger.has(action_instance_id):
		return false

	reservation_ledger.erase(action_instance_id)
	return true


func has_action_reservation(action: SimAction) -> bool:
	if action == null:
		return false
	return reservation_ledger.has(action.get_instance_id())


func get_action_reservation(action: SimAction) -> Dictionary:
	if action == null:
		return {}

	var reservation_value: Variant = reservation_ledger.get(
		action.get_instance_id(),
		{}
	)
	if typeof(reservation_value) != TYPE_DICTIONARY:
		return {}

	var reservation: Dictionary = reservation_value
	return reservation.duplicate(true)


func get_reservation_count() -> int:
	return reservation_ledger.size()


func get_reservation_ledger() -> Dictionary:
	return reservation_ledger.duplicate(true)


func _get_reservation_failure_reason(
	world: WorldState,
	action: SimAction
) -> String:
	if world == null:
		return "Action commitment failed: world context is required."

	var actor: SimEntity = world.get_entity(action.actor_id) as SimEntity
	if actor == null:
		return (
			"Action commitment failed: actor does not exist: "
			+ action.actor_id
		)

	for resource_key in action.resource_requirements.keys():
		var resource_name: String = str(resource_key)
		var required_raw: Variant = action.resource_requirements[resource_key]
		if not _is_numeric(required_raw):
			continue

		var required_amount: float = float(required_raw)
		var reserved_amount: float = _get_reserved_amount(
			action.actor_id,
			"resources",
			resource_name,
			action.get_instance_id()
		)
		var available_amount: Variant = _get_resource_available_value(
			actor,
			resource_name
		)
		if available_amount == null:
			return (
				"Action commitment failed: resource state is unavailable: "
				+ resource_name
			)

		if reserved_amount + required_amount > float(available_amount) + 0.000001:
			return (
				"Action commitment failed: reservation exceeds available resource: "
				+ resource_name
			)

	var treasury_requirement: float = action.cost
	if action.financial_requirements.has("treasury"):
		var explicit_treasury: Variant = action.financial_requirements.get(
			"treasury",
			0.0
		)
		if _is_numeric(explicit_treasury):
			treasury_requirement = maxf(
				treasury_requirement,
				float(explicit_treasury)
			)

	if treasury_requirement > 0.0:
		var reserved_treasury: float = _get_reserved_amount(
			action.actor_id,
			"financial",
			"treasury",
			action.get_instance_id()
		)
		var treasury_available_value: Variant = _get_financial_available_value(
			actor,
			"treasury"
		)
		if treasury_available_value == null:
			return "Action commitment failed: treasury state is unavailable."

		if reserved_treasury + treasury_requirement > float(treasury_available_value) + 0.000001:
			return "Action commitment failed: reservation exceeds available treasury."

	for financial_key in action.financial_requirements.keys():
		var financial_key_name: String = str(financial_key)
		if financial_key_name == "treasury":
			continue
		var required_financial: Variant = action.financial_requirements[financial_key]
		if not _is_numeric(required_financial):
			continue
		var reserved_financial: float = _get_reserved_amount(
			action.actor_id,
			"financial",
			financial_key_name,
			action.get_instance_id()
		)
		var financial_available_value: Variant = _get_financial_available_value(
			actor,
			financial_key_name
		)
		if financial_available_value == null:
			return (
				"Action commitment failed: financial state is unavailable: "
				+ financial_key_name
			)

		if reserved_financial + float(required_financial) > float(financial_available_value) + 0.000001:
			return (
				"Action commitment failed: reservation exceeds available financial state: "
				+ financial_key_name
			)

	for capability_key in action.capability_requirements.keys():
		var capability_name: String = str(capability_key)
		var required_capability: Variant = action.capability_requirements[capability_key]
		if typeof(required_capability) == TYPE_BOOL:
			if not bool(required_capability):
				continue
			var reserved_bool_capability: float = _get_reserved_amount(
				action.actor_id,
				"capabilities",
				capability_name,
				action.get_instance_id()
			)
			var available_bool_capability: Variant = _get_capability_available_value(
				actor,
				capability_name
			)
			if available_bool_capability == null:
				return (
					"Action commitment failed: capability state is unavailable: "
					+ capability_name
				)
			var available_bool_amount: float = 1.0 if bool(available_bool_capability) else 0.0
			if reserved_bool_capability + 1.0 > available_bool_amount + 0.000001:
				return (
					"Action commitment failed: reservation exceeds available capability: "
					+ capability_name
				)
			continue

		if not _is_numeric(required_capability):
			continue
		var required_capability_amount: float = float(required_capability)
		var reserved_capability: float = _get_reserved_amount(
			action.actor_id,
			"capabilities",
			capability_name,
			action.get_instance_id()
		)
		var available_capability: Variant = _get_capability_available_value(
			actor,
			capability_name
		)
		if available_capability == null:
			return (
				"Action commitment failed: capability state is unavailable: "
				+ capability_name
			)
		if reserved_capability + required_capability_amount > float(available_capability) + 0.000001:
			return (
				"Action commitment failed: reservation exceeds available capability: "
				+ capability_name
			)

	for capacity_key in action.capacity_requirements.keys():
		var capacity_name: String = str(capacity_key)
		var required_capacity: Variant = action.capacity_requirements[capacity_key]
		if not _is_numeric(required_capacity):
			continue
		var required_capacity_amount: float = float(required_capacity)
		var reserved_capacity: float = _get_reserved_amount(
			action.actor_id,
			"capacity",
			capacity_name,
			action.get_instance_id()
		)
		var available_capacity: Variant = _get_capacity_available_value(
			actor,
			capacity_name
		)
		if available_capacity == null:
			return (
				"Action commitment failed: capacity state is unavailable: "
				+ capacity_name
			)
		if reserved_capacity + required_capacity_amount > float(available_capacity) + 0.000001:
			return (
				"Action commitment failed: reservation exceeds available capacity: "
				+ capacity_name
			)

	return ""


func _build_reservation_record(action: SimAction) -> Dictionary:
	var resources: Dictionary = {}
	for key in action.resource_requirements.keys():
		var raw_value: Variant = action.resource_requirements[key]
		if _is_numeric(raw_value):
			resources[str(key)] = float(raw_value)

	var financial: Dictionary = {}
	var treasury_requirement: float = action.cost
	if action.financial_requirements.has("treasury"):
		var explicit_treasury: Variant = action.financial_requirements.get("treasury", 0.0)
		if _is_numeric(explicit_treasury):
			treasury_requirement = maxf(treasury_requirement, float(explicit_treasury))
	if treasury_requirement > 0.0:
		financial["treasury"] = treasury_requirement
	for key in action.financial_requirements.keys():
		var raw_financial: Variant = action.financial_requirements[key]
		if str(key) != "treasury" and _is_numeric(raw_financial):
			financial[str(key)] = float(raw_financial)

	var capabilities: Dictionary = {}
	for key in action.capability_requirements.keys():
		var raw_capability: Variant = action.capability_requirements[key]
		if typeof(raw_capability) == TYPE_BOOL:
			if bool(raw_capability):
				capabilities[str(key)] = 1.0
		elif _is_numeric(raw_capability):
			capabilities[str(key)] = float(raw_capability)

	var capacity: Dictionary = {}
	for key in action.capacity_requirements.keys():
		var raw_capacity: Variant = action.capacity_requirements[key]
		if _is_numeric(raw_capacity):
			capacity[str(key)] = float(raw_capacity)

	return {
		"action_instance_id": action.get_instance_id(),
		"actor_id": action.actor_id,
		"status": RESERVATION_STATUS_RESERVED,
		"resources": resources,
		"financial": financial,
		"capabilities": capabilities,
		"capacity": capacity
	}


func _get_reserved_amount(
	actor_id: String,
	category: String,
	key: String,
	excluding_action_instance_id: int = -1
) -> float:
	var total_reserved: float = 0.0
	for entry_variant in reservation_ledger.values():
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("actor_id", "")) != actor_id:
			continue
		if int(entry.get("action_instance_id", -1)) == excluding_action_instance_id:
			continue
		var category_value: Variant = entry.get(category, {})
		if typeof(category_value) != TYPE_DICTIONARY:
			continue
		var category_values: Dictionary = category_value
		var raw_amount: Variant = category_values.get(key, 0.0)
		if _is_numeric(raw_amount):
			total_reserved += float(raw_amount)
	return total_reserved


func _get_resource_available_value(
	actor: SimEntity,
	resource_name: String
) -> Variant:
	var resources: SimComponent = actor.get_component("resources") as SimComponent
	if resources == null:
		return null
	var stockpile_value: Variant = resources.get_state("stockpile", null)
	if typeof(stockpile_value) != TYPE_DICTIONARY:
		return null
	var stockpile: Dictionary = stockpile_value
	var available: Variant = stockpile.get(resource_name, null)
	if not _is_numeric(available):
		return null
	return maxf(float(available), 0.0)


func _get_financial_available_value(
	actor: SimEntity,
	financial_key: String
) -> Variant:
	var economy: SimComponent = actor.get_component("economy") as SimComponent
	if economy == null:
		return null
	var available: Variant = economy.get_state(financial_key, null)
	if not _is_numeric(available):
		return null
	return maxf(float(available), 0.0)


func _get_capability_available_value(
	actor: SimEntity,
	capability_name: String
) -> Variant:
	var capabilities_value: Variant = actor.get_sim_metadata("capabilities", null)
	if typeof(capabilities_value) != TYPE_DICTIONARY:
		return null
	var capabilities: Dictionary = capabilities_value
	if not capabilities.has(capability_name):
		return null
	return capabilities.get(capability_name, null)


func _get_capacity_available_value(
	actor: SimEntity,
	capacity_name: String
) -> Variant:
	var economy: SimComponent = actor.get_component("economy") as SimComponent
	if economy != null:
		var economy_value: Variant = economy.get_state(capacity_name, null)
		if _is_numeric(economy_value):
			return maxf(float(economy_value), 0.0)

	var industry: SimComponent = actor.get_component("industry") as SimComponent
	if industry != null:
		var industry_value: Variant = industry.get_state(capacity_name, null)
		if _is_numeric(industry_value):
			return maxf(float(industry_value), 0.0)

	var resources: SimComponent = actor.get_component("resources") as SimComponent
	if resources != null:
		var resource_value: Variant = resources.get_state(capacity_name, null)
		if _is_numeric(resource_value):
			return maxf(float(resource_value), 0.0)

	var capacity_metadata: Variant = actor.get_sim_metadata("capacity", null)
	if typeof(capacity_metadata) == TYPE_DICTIONARY:
		var metadata: Dictionary = capacity_metadata
		var metadata_value: Variant = metadata.get(capacity_name, null)
		if _is_numeric(metadata_value):
			return maxf(float(metadata_value), 0.0)

	return null


# ============================================================
# STEP 15.3 — AUTHORITATIVE ACTION EXECUTION
# ============================================================

func process_month(world: WorldState) -> void:
	if world == null:
		push_error("ActionManager: World is null.")
		return

	var completed_actions: Array = []
	var ordered_actions: Array = _get_deterministic_resolution_actions()

	for action_variant in ordered_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue

		if action.state == SimAction.STATE_QUEUED:
			action.state = SimAction.STATE_ACTIVE

		if action.state != SimAction.STATE_ACTIVE:
			continue

		var total_duration_months: int = action.total_duration_months
		if total_duration_months <= 0:
			total_duration_months = max(action.duration_months, 1)
			action.total_duration_months = total_duration_months

		var remaining_before: int = max(action.duration_months, 0)
		if remaining_before <= 0:
			action.progress = 1.0
			completed_actions.append(action)
			continue

		action.duration_months = remaining_before - 1

		var elapsed_months: int = (
			total_duration_months - action.duration_months
		)
		action.progress = clampf(
			float(elapsed_months) / float(total_duration_months),
			0.0,
			1.0
		)

		if action.duration_months <= 0:
			action.progress = 1.0
			completed_actions.append(action)

	for completed_variant in completed_actions:
		var completed_action: SimAction = completed_variant as SimAction
		if completed_action == null:
			continue

		var execution_result: bool = _apply_completion_effect(
			world,
			completed_action
		)

		if execution_result:
			completed_action.state = SimAction.STATE_COMPLETED
			release_action_reservation(completed_action)
			_remove_pending_action(completed_action)
			_record_terminal_outcome(world, completed_action)
		else:
			var failure_message: String = completed_action.failure_reason
			if failure_message.is_empty():
				failure_message = "Action completion effect execution failed."
			fail_action(
				completed_action,
				failure_message
			)


func _apply_completion_effect(
	world: WorldState,
	action: SimAction
) -> bool:
	if world == null:
		return false

	if action == null:
		return false

	# ActionSystem is the existing authoritative action/domain bridge.
	# ActionManager does not mutate country/domain state directly.
	var action_system: ActionSystem = ActionSystem.new()
	var execution_result: bool = action_system.execute_action(
		world,
		action
	)

	var execution_details: Dictionary = action.completion_result.duplicate(true)
	var actual_effect: Dictionary = {}
	var actual_effect_value: Variant = execution_details.get(
		"actual_effect",
		{}
	)
	if typeof(actual_effect_value) == TYPE_DICTIONARY:
		actual_effect = actual_effect_value.duplicate(true)
	elif not action.effects.is_empty():
		actual_effect = action.effects.duplicate(true)

	action.completion_result = {
		"status": "completed" if execution_result else "effect_execution_failed",
		"effect_applied": execution_result,
		"action_type": action.action_type,
		"actor_id": action.actor_id,
		"target_id": action.target_id,
		"value": action.value,
		"actual_effect": actual_effect,
		"execution_details": execution_details
	}

	if not execution_result and action.failure_reason.is_empty():
		action.failure_reason = "Action completion effect execution failed."

	return execution_result


# ============================================================
# STEP 15.11 — OUTCOME / HISTORY RECORD
# ============================================================

func get_outcome_history() -> Array:
	var result: Array = []
	for entry_variant in outcome_history:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		result.append(entry.duplicate(true))
	return result


func get_action_outcome(action: SimAction) -> Dictionary:
	if action == null:
		return {}

	var action_id: int = action.get_instance_id()
	if not outcome_index.has(action_id):
		return {}

	var index_value: Variant = outcome_index.get(action_id, -1)
	if typeof(index_value) != TYPE_INT:
		return {}

	var index: int = int(index_value)
	if index < 0 or index >= outcome_history.size():
		return {}

	var record_variant: Variant = outcome_history[index]
	if typeof(record_variant) != TYPE_DICTIONARY:
		return {}

	var record: Dictionary = record_variant
	return record.duplicate(true)


func get_outcome_count() -> int:
	return outcome_history.size()


func _ensure_action_start_date(
	world: WorldState,
	action: SimAction
) -> void:
	if world == null or action == null:
		return

	if not action.start_date.strip_edges().is_empty():
		return

	action.start_date = _format_world_date(world)


func _format_world_date(world: WorldState) -> String:
	if world == null:
		return ""

	return "%04d-%02d-%02d" % [
		world.get_year(),
		world.get_month(),
		world.get_day()
	]


func _record_terminal_outcome(
	world: WorldState,
	action: SimAction
) -> void:
	if action == null:
		return

	if not _is_terminal_state(action.state):
		return

	var action_id: int = action.get_instance_id()
	var end_date: String = _format_world_date(world)
	var completion_result: Dictionary = action.completion_result.duplicate(true)

	var actual_effect: Dictionary = {}
	var actual_effect_value: Variant = completion_result.get(
		"actual_effect",
		{}
	)
	if typeof(actual_effect_value) == TYPE_DICTIONARY:
		actual_effect = actual_effect_value.duplicate(true)
	elif not action.effects.is_empty() and action.state == SimAction.STATE_COMPLETED:
		actual_effect = action.effects.duplicate(true)

	var record: Dictionary = {
		"action_id": action_id,
		"actor": action.actor_id,
		"type": action.action_type,
		"target": action.target_id,
		"start": action.start_date,
		"end": end_date,
		"status": action.state,
		"cost": action.cost,
		"actual_effect": actual_effect,
		"failure_reason": action.failure_reason,
		"completion_result": completion_result
	}

	if outcome_index.has(action_id):
		return

	outcome_index[action_id] = outcome_history.size()
	outcome_history.append(record)




# ============================================================
# STEP 15.12 — ACTION SNAPSHOT STATE
# ============================================================
#
# Action execution state is transient state owned by ActionManager.
# It is attached to the existing WorldSnapshot lifecycle by
# SimulationEngine; it does not create a second simulation world.
#
# Snapshot state contains deep-copied executable action contracts and
# reservation commitments. Restore reconstructs pending actions and
# remaps reservation keys to the newly created in-memory action IDs.
# ============================================================

func capture_snapshot_state() -> Dictionary:
	var snapshot: Dictionary = {
		"version": 1,
		"pending_actions": [],
		"reservations": []
	}

	for action_variant in pending_actions:
		var action: SimAction = action_variant as SimAction
		if action == null:
			continue

		var action_record: Dictionary = _serialize_action_for_snapshot(action)
		snapshot["pending_actions"].append(action_record)

	for reservation_key in reservation_ledger.keys():
		var reservation_value: Variant = reservation_ledger.get(
			reservation_key,
			{}
		)
		if typeof(reservation_value) != TYPE_DICTIONARY:
			continue

		var reservation: Dictionary = reservation_value
		var reservation_record: Dictionary = {
			"source_action_instance_id": int(reservation_key),
			"reservation": reservation.duplicate(true)
		}
		snapshot["reservations"].append(reservation_record)

	return snapshot.duplicate(true)


func restore_snapshot_state(
	snapshot_state: Dictionary,
	world: WorldState = null
) -> bool:
	if typeof(snapshot_state) != TYPE_DICTIONARY:
		return false

	var pending_value: Variant = snapshot_state.get(
		"pending_actions",
		[]
	)
	var reservations_value: Variant = snapshot_state.get(
		"reservations",
		[]
	)

	if typeof(pending_value) != TYPE_ARRAY:
		return false
	if typeof(reservations_value) != TYPE_ARRAY:
		return false

	var rebuilt_actions: Array = []
	var source_to_restored_id: Dictionary = {}

	for action_value in pending_value:
		if typeof(action_value) != TYPE_DICTIONARY:
			return false

		var action_record: Dictionary = action_value
		var state: String = str(action_record.get(
			"state",
			SimAction.STATE_QUEUED
		))
		if (
			state != SimAction.STATE_QUEUED
			and state != SimAction.STATE_ACTIVE
		):
			return false

		var value_raw: Variant = action_record.get("value", 0.0)
		var duration_raw: Variant = action_record.get(
			"duration_months",
			1
		)
		if not _is_numeric(value_raw):
			return false
		if typeof(duration_raw) != TYPE_INT:
			return false

		var restored_action: SimAction = SimAction.new(
			str(action_record.get("action_type", "")),
			str(action_record.get("actor_id", "")),
			str(action_record.get("target_id", "")),
			float(value_raw),
			int(duration_raw)
		)

		var total_duration_raw: Variant = action_record.get(
			"total_duration_months",
			duration_raw
		)
		var cost_raw: Variant = action_record.get("cost", 0.0)
		var progress_raw: Variant = action_record.get("progress", 0.0)
		if typeof(total_duration_raw) != TYPE_INT:
			return false
		if not _is_numeric(cost_raw):
			return false
		if not _is_numeric(progress_raw):
			return false

		var resource_requirements: Variant = action_record.get(
			"resource_requirements",
			{}
		)
		var financial_requirements: Variant = action_record.get(
			"financial_requirements",
			{}
		)
		var capability_requirements: Variant = action_record.get(
			"capability_requirements",
			{}
		)
		var capacity_requirements: Variant = action_record.get(
			"capacity_requirements",
			{}
		)
		var effects_value: Variant = action_record.get("effects", {})
		var completion_result_value: Variant = action_record.get(
			"completion_result",
			{}
		)

		if typeof(resource_requirements) != TYPE_DICTIONARY:
			return false
		if typeof(financial_requirements) != TYPE_DICTIONARY:
			return false
		if typeof(capability_requirements) != TYPE_DICTIONARY:
			return false
		if typeof(capacity_requirements) != TYPE_DICTIONARY:
			return false
		if typeof(effects_value) != TYPE_DICTIONARY:
			return false
		if typeof(completion_result_value) != TYPE_DICTIONARY:
			return false

		var priority_raw: Variant = action_record.get("priority", 0)
		if typeof(priority_raw) != TYPE_INT:
			return false

		restored_action.total_duration_months = int(total_duration_raw)
		restored_action.priority = int(priority_raw)
		restored_action.cost = float(cost_raw)
		restored_action.resource_requirements = resource_requirements.duplicate(true)
		restored_action.financial_requirements = financial_requirements.duplicate(true)
		restored_action.capability_requirements = capability_requirements.duplicate(true)
		restored_action.capacity_requirements = capacity_requirements.duplicate(true)
		restored_action.state = state
		restored_action.start_date = str(action_record.get("start_date", ""))
		restored_action.progress = clampf(
			float(progress_raw),
			0.0,
			1.0
		)
		restored_action.effects = effects_value.duplicate(true)
		restored_action.failure_reason = str(
			action_record.get("failure_reason", "")
		)
		restored_action.completion_result = completion_result_value.duplicate(true)
		restored_action.duration_months = int(duration_raw)

		var source_id_raw: Variant = action_record.get(
			"snapshot_action_id",
			-1
		)
		if typeof(source_id_raw) != TYPE_INT:
			return false
		var source_id: int = int(source_id_raw)
		if source_to_restored_id.has(source_id):
			return false

		source_to_restored_id[source_id] = restored_action.get_instance_id()
		rebuilt_actions.append(restored_action)

	var rebuilt_reservations: Dictionary = {}

	for reservation_entry_value in reservations_value:
		if typeof(reservation_entry_value) != TYPE_DICTIONARY:
			return false

		var reservation_entry: Dictionary = reservation_entry_value
		var source_id_value: Variant = reservation_entry.get(
			"source_action_instance_id",
			-1
		)
		var reservation_value: Variant = reservation_entry.get(
			"reservation",
			{}
		)
		if typeof(source_id_value) != TYPE_INT:
			return false
		if typeof(reservation_value) != TYPE_DICTIONARY:
			return false
		if not source_to_restored_id.has(int(source_id_value)):
			return false

		var reservation: Dictionary = reservation_value.duplicate(true)
		var restored_id: int = int(
			source_to_restored_id[int(source_id_value)]
		)
		reservation["action_instance_id"] = restored_id
		rebuilt_reservations[restored_id] = reservation

	pending_actions = rebuilt_actions
	reservation_ledger = rebuilt_reservations
	_rebuild_admission_order_ledger()
	if world != null:
		validation_world = world

	return true


func _serialize_action_for_snapshot(
	action: SimAction
) -> Dictionary:
	return {
		"snapshot_action_id": action.get_instance_id(),
		"action_type": action.action_type,
		"actor_id": action.actor_id,
		"target_id": action.target_id,
		"value": action.value,
		"duration_months": action.duration_months,
		"total_duration_months": action.total_duration_months,
		"priority": action.priority,
		"cost": action.cost,
		"resource_requirements": action.resource_requirements.duplicate(true),
		"financial_requirements": action.financial_requirements.duplicate(true),
		"capability_requirements": action.capability_requirements.duplicate(true),
		"capacity_requirements": action.capacity_requirements.duplicate(true),
		"state": action.state,
		"start_date": action.start_date,
		"progress": action.progress,
		"effects": action.effects.duplicate(true),
		"failure_reason": action.failure_reason,
		"completion_result": action.completion_result.duplicate(true)
	}

func get_pending_actions() -> Array:
	return pending_actions.duplicate()


func get_pending_count() -> int:
	return pending_actions.size()
