class_name GovernmentPolicyCostSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.3
# POLICY COST SYSTEM
# ============================================================
#
# The smallest cost mechanism compatible with the existing
# architecture is a one-time treasury charge on policy change.
#
# Ownership boundary:
#   GovernmentComponent -> policy definitions / activation state
#   EconomyComponent    -> treasury
#   GovernmentPolicyCostSystem -> cross-component transaction
#
# Step 8.3 intentionally does NOT:
# - apply policy effects
# - change tax rates
# - allocate government spending
# - create administrative-capacity simulation
# - create political-capacity simulation
# - create borrowing or credit mechanics
# ============================================================

const SUPPORTED_RESOURCE: String = "treasury"


func _init():
	super("government_policy_cost_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component(
			"government"
		)

		if government == null:
			continue

		var pending = government.get_pending_policy_activation()

		if pending.is_empty():
			continue

		_process_request(
			entity,
			government,
			pending
		)


func _process_request(
	entity: SimEntity,
	government: GovernmentComponent,
	request: Dictionary
) -> void:

	var policy_id: String = str(
		request.get(
			"policy_id",
			""
		)
	).strip_edges()

	if policy_id.is_empty():
		_record_failure(
			government,
			policy_id,
			"missing_policy_id",
			0.0,
			0.0
		)
		return

	var definition: Dictionary = government.get_policy_definition(
		policy_id
	)

	if definition.is_empty():
		_record_failure(
			government,
			policy_id,
			"undefined_policy",
			0.0,
			0.0
		)
		return

	# Re-requesting the already-active policy is a no-cost idempotent
	# operation. It is still cleared from the pending queue.
	if government.is_policy_active(policy_id):

		var current_treasury: float = 0.0

		var current_economy = entity.get_component(
			"economy"
		)

		if current_economy != null:
			current_treasury = float(
				current_economy.get_state(
					"treasury",
					0.0
				)
			)

		_record_result(
			government,
			policy_id,
			"already_active",
			0.0,
			current_treasury,
			current_treasury,
			true
		)
		return

	var cost_value = definition.get(
		"cost",
		{}
	)

	if not cost_value is Dictionary:
		_record_failure(
			government,
			policy_id,
			"invalid_cost_schema",
			0.0,
			0.0
		)
		return

	var cost: Dictionary = cost_value
	var treasury_cost: float = 0.0

	for key in cost.keys():

		var raw_cost = cost[key]
		var numeric_cost: float = 0.0

		if raw_cost is int or raw_cost is float:
			numeric_cost = float(raw_cost)
		else:
			_record_failure(
				government,
				policy_id,
				"invalid_cost_value",
				0.0,
				0.0
			)
			return

		if numeric_cost < 0.0:
			_record_failure(
				government,
				policy_id,
				"negative_cost",
				0.0,
				0.0
			)
			return

		if str(key) == SUPPORTED_RESOURCE:
			treasury_cost += numeric_cost
		elif numeric_cost > 0.0:
			# Unsupported positive resources must not become silently free.
			_record_failure(
				government,
				policy_id,
				"unsupported_cost_resource:" + str(key),
				0.0,
				0.0
			)
			return

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		_record_failure(
			government,
			policy_id,
			"missing_economy_component",
			0.0,
			0.0
		)
		return

	var treasury_before: float = float(
		economy.get_state(
			"treasury",
			0.0
		)
	)

	if treasury_cost > treasury_before:
		_record_failure(
			government,
			policy_id,
			"insufficient_treasury",
			treasury_cost,
			treasury_before
		)
		return

	# The existing GovernmentComponent owns policy activation state.
	# Charge only after the activation request has been validated and
	# the treasury has been proven sufficient.
	var activated: bool = government.activate_policy(
		policy_id
	)

	if not activated:
		_record_failure(
			government,
			policy_id,
			"activation_rejected",
			treasury_cost,
			treasury_before
		)
		return

	var treasury_after: float = (
		treasury_before
		- treasury_cost
	)

	economy.set_state(
		"treasury",
		treasury_after
	)

	_record_result(
		government,
		policy_id,
		"charged_and_activated",
		treasury_cost,
		treasury_before,
		treasury_after,
		true
	)


func _record_failure(
	government: GovernmentComponent,
	policy_id: String,
	reason: String,
	requested_cost: float,
	treasury_before: float
) -> void:

	var revision: int = int(
		government.get_state(
			"policy_cost_revision",
			0
		)
	) + 1

	var result: Dictionary = {
		"action": "rejected",
		"revision": revision,
		"policy_id": policy_id,
		"reason": reason,
		"requested_treasury_cost": requested_cost,
		"treasury_before": treasury_before,
		"treasury_after": treasury_before,
		"activated": false
	}

	var ledger: Dictionary = government.get_policy_cost_ledger()
	ledger[str(revision)] = result.duplicate(true)

	government.set_state(
		"policy_cost_revision",
		revision
	)

	government.set_state(
		"policy_cost_ledger",
		ledger
	)

	government.set_state(
		"policy_cost_last_result",
		result
	)

	government.clear_pending_policy_activation()


func _record_result(
	government: GovernmentComponent,
	policy_id: String,
	action: String,
	charged_cost: float,
	treasury_before: float,
	treasury_after: float,
	activated: bool
) -> void:

	var previous_revision: int = int(
		government.get_state(
			"policy_cost_revision",
			0
		)
	)

	var revision: int = previous_revision + 1

	var ledger: Dictionary = government.get_policy_cost_ledger()

	var result: Dictionary = {
		"action": action,
		"revision": revision,
		"policy_id": policy_id,
		"charged_treasury": charged_cost,
		"treasury_before": treasury_before,
		"treasury_after": treasury_after,
		"activated": activated
	}

	ledger[str(revision)] = result.duplicate(true)

	government.set_state(
		"policy_cost_revision",
		revision
	)

	government.set_state(
		"policy_cost_ledger",
		ledger
	)

	government.set_state(
		"policy_cost_last_result",
		result
	)

	government.clear_pending_policy_activation()
