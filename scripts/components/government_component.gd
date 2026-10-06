class_name GovernmentComponent
extends SimComponent


func _init(owner_id_value: String):

	super(
		"government",
		owner_id_value
	)

	set_state(
		"government_type",
        "default"
	)

	# Core political condition
	set_state(
		"stability",
		0.70
	)

	set_state(
		"approval",
		0.60
	)

	set_state(
		"political_pressure",
		0.30
	)

	set_state(
		"institutional_strength",
		0.50
	)

	set_state(
		"policy_capacity",
		0.50
	)

	set_state(
		"legitimacy",
		0.60
	)

	# Structural characteristics
	set_state(
		"corruption",
		0.30
	)

	set_state(
		"centralization",
		0.50
	)

	set_state(
		"political_freedom",
		0.50
	)

	# Previous-month values
	set_state(
		"previous_stability",
		0.70
	)

	set_state(
		"previous_approval",
		0.60
	)

	set_state(
		"previous_pressure",
		0.30
	)

	# ========================================================
	# GOVERNMENT POLICY DEFINITIONS — STEP 8.1
	# ========================================================
	# Definitions are declarative state only. Activation, costs and
	# effects belong to later government-causal substeps.

	set_state(
		"policy_definitions",
		{}
	)

	set_state(
		"policy_definition_revision",
		0
	)

	set_state(
		"policy_definition_ledger",
		{}
	)

	# ========================================================
	# GOVERNMENT POLICY ACTIVATION — STEP 8.2
	# ========================================================
	# Activation selects a defined policy as the current policy state.
	# No policy cost is charged and no policy effect is applied here.

	set_state(
		"active_policies",
		{}
	)

	set_state(
		"policy_activation_revision",
		0
	)

	set_state(
		"policy_activation_ledger",
		{}
	)

	# ========================================================
	# GOVERNMENT POLICY COST — STEP 8.3
	# ========================================================
	# Requests are processed by the registered
	# GovernmentPolicyCostSystem. Treasury remains owned by
	# EconomyComponent; this component only stores the request
	# and the audit state.

	set_state(
		"pending_policy_activation",
		{}
	)

	set_state(
		"policy_cost_revision",
		0
	)

	set_state(
		"policy_cost_ledger",
		{}
	)

	set_state(
		"policy_cost_last_result",
		{}
	)

	# ========================================================
	# GOVERNMENT POLICY EFFECTS — STEP 8.4
	# ========================================================
	# Effects modify existing system-owned state. This component only
	# keeps the audit/baseline information needed for deterministic
	# application and safe replacement of active policies.

	set_state(
		"policy_effect_revision",
		0
	)

	set_state(
		"policy_effect_ledger",
		{}
	)

	set_state(
		"policy_effect_last_result",
		{}
	)

	set_state(
		"policy_effect_bindings",
		{}
	)

	# ========================================================
	# GOVERNMENT SPENDING ALLOCATION — STEP 8.6
	# ========================================================
	# EconomyComponent owns total government_spending. GovernmentComponent
	# owns the allocation shares and the derived category amounts.
	#
	# MVP default allocation:
	# infrastructure 30%, military 20%, public services 30%,
	# administration 20%.
	set_state(
		"government_spending_allocation_shares",
		{
			"infrastructure": 0.30,
			"military": 0.20,
			"public_services": 0.30,
			"administration": 0.20
		}
	)

	set_state(
		"government_spending_allocation",
		{
			"infrastructure": 0.0,
			"military": 0.0,
			"public_services": 0.0,
			"administration": 0.0
		}
	)

	set_state(
		"government_spending_allocation_total",
		0.0
	)

	set_state(
		"government_spending_allocation_revision",
		0
	)

	set_state(
		"government_spending_allocation_ledger",
		{}
	)

	set_state(
		"government_spending_allocation_last_result",
		{}
	)

	# ========================================================
	# GOVERNMENT PUBLIC-SERVICE OUTPUT — STEP 8.7
	# ========================================================
	# Public-service output is derived from the already-allocated
	# public-services spending. This keeps total spending owned by
	# EconomyComponent and allocation owned by this component.
	set_state(
		"public_service_spending",
		0.0
	)

	set_state(
		"public_service_output",
		0.0
	)

	set_state(
		"public_service_capacity",
		0.0
	)

	set_state(
		"public_service_output_per_capita",
		0.0
	)

	set_state(
		"public_service_output_revision",
		0
	)

	set_state(
		"public_service_output_ledger",
		{}
	)

	set_state(
		"public_service_output_last_result",
		{}
	)

	# ========================================================
	# GOVERNMENT BASIC LAW / AMENDMENT — STEP 8.8
	# ========================================================
	# This is a deliberately small law-state transition. It models one
	# current law with a small provision dictionary and an explicit
	# approved amendment request. It does not model parliament, parties,
	# elections, constitutional procedures or a separate legal simulator.
	set_state(
		"current_law_state",
		{
			"law_id": "mvp_government_law",
			"title": "Basic Government Framework",
			"version": 1,
			"status": "active",
			"provisions": {
				"taxation_authority": "baseline",
				"spending_authority": "baseline",
				"administrative_authority": "baseline"
			}
		}
	)

	set_state(
		"pending_law_amendment",
		{}
	)

	set_state(
		"law_amendment_revision",
		0
	)

	set_state(
		"law_amendment_ledger",
		{}
	)

	set_state(
		"law_amendment_last_result",
		{}
	)

	# ========================================================
	# GOVERNMENT IMPLEMENTATION CAPACITY — STEP 8.9
	# ========================================================
	# Explicit MVP scalar. The master state defines the causal
	# relationship but does not prescribe a derivation formula, so
	# capacity remains directly state-owned and bounded by the
	# implementation-capacity system. Existing policies remain at
	# full intended effect unless their metadata explicitly opts
	# into implementation-capacity scaling.
	set_state(
		"implementation_capacity",
		1.0
	)

	set_state(
		"implementation_capacity_revision",
		0
	)

	set_state(
		"implementation_capacity_ledger",
		{}
	)

	set_state(
		"implementation_capacity_last_result",
		{}
	)

	set_state(
		"policy_implementation_factors",
		{}
	)


	# ========================================================
	# GOVERNMENT SIMPLIFIED TRANSITION — STEP 8.10
	# ========================================================
	# Deliberately limited government-state transition. The request is
	# explicit and can be approved before the registered transition
	# system applies it. No constitutional or parliamentary model is
	# introduced here.
	set_state(
		"pending_government_transition",
		{}
	)

	set_state(
		"government_transition_revision",
		0
	)

	set_state(
		"government_transition_ledger",
		{}
	)

	set_state(
		"government_transition_last_result",
		{}
	)


# ============================================================
# STEP 8.1 — POLICY DEFINITION API
# ============================================================

func define_policy(
	policy: GovernmentPolicyDefinition
) -> bool:

	if policy == null:
		return false

	if not policy.is_valid():
		return false

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	if definitions.has(
		policy.policy_id
	):
		return false

	definitions[policy.policy_id] = (
		policy.to_dict()
	)

	set_state(
		"policy_definitions",
		definitions
	)

	var revision := int(
		get_state(
			"policy_definition_revision",
			0
		)
	)

	revision += 1

	set_state(
		"policy_definition_revision",
		revision
	)

	var ledger: Dictionary = get_state(
		"policy_definition_ledger",
		{}
	)

	ledger[policy.policy_id] = {
		"action": "defined",
		"revision": revision,
		"policy": policy.to_dict()
	}

	set_state(
		"policy_definition_ledger",
		ledger
	)

	return true


func has_policy_definition(
	policy_id: String
) -> bool:

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	return definitions.has(
		policy_id
	)


func get_policy_definition(
	policy_id: String
) -> Dictionary:

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	if not definitions.has(
		policy_id
	):
		return {}

	var definition = definitions[
		policy_id
	]

	if not definition is Dictionary:
		return {}

	return definition.duplicate(true)


func get_policy_definitions() -> Dictionary:

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	return definitions.duplicate(true)

# ============================================================
# STEP 8.2 — POLICY ACTIVATION / CHANGE API
# ============================================================

func activate_policy(
	policy_id: String
) -> bool:

	var requested_policy_id: String = policy_id.strip_edges()

	if requested_policy_id.is_empty():
		return false

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	if not definitions.has(requested_policy_id):
		return false

	var definition_value = definitions[
		requested_policy_id
	]

	if not definition_value is Dictionary:
		return false

	var definition: Dictionary = definition_value

	var category: String = str(
		definition.get(
			"category",
            ""
		)
	).strip_edges()

	var target: String = str(
		definition.get(
			"target",
            ""
		)
	).strip_edges()

	if category.is_empty() or target.is_empty():
		return false

	var target_key: String = _policy_target_key(
		category,
		target
	)

	var active_policies: Dictionary = get_state(
		"active_policies",
		{}
	)

	var previous_policy_id: String = ""

	if active_policies.has(target_key):

		var previous_value = active_policies[
			target_key
		]

		if previous_value is Dictionary:
			previous_policy_id = str(
				previous_value.get(
					"policy_id",
                    ""
				)
			)

		if previous_policy_id == requested_policy_id:
			# Re-applying the current policy is an idempotent no-op.
			return true

	var active_state: Dictionary = {
		"policy_id": requested_policy_id,
		"category": category,
		"target": target,
		"value": float(
			definition.get(
				"value",
				0.0
			)
		),
		"duration_months": int(
			definition.get(
				"duration_months",
				0
			)
		),
		"active": true
	}

	active_policies[target_key] = active_state

	set_state(
		"active_policies",
		active_policies
	)

	var revision: int = int(
		get_state(
			"policy_activation_revision",
			0
		)
	)

	revision += 1

	set_state(
		"policy_activation_revision",
		revision
	)

	var ledger: Dictionary = get_state(
		"policy_activation_ledger",
		{}
	)

	var action: String = (
        "changed"
		if not previous_policy_id.is_empty()
		else "activated"
	)

	ledger[str(revision)] = {
		"action": action,
		"revision": revision,
		"target_key": target_key,
		"previous_policy_id": previous_policy_id,
		"policy_id": requested_policy_id
	}

	set_state(
		"policy_activation_ledger",
		ledger
	)

	return true


func is_policy_active(
	policy_id: String
) -> bool:

	var requested_policy_id: String = policy_id.strip_edges()

	if requested_policy_id.is_empty():
		return false

	var definitions: Dictionary = get_state(
		"policy_definitions",
		{}
	)

	if not definitions.has(requested_policy_id):
		return false

	var definition_value = definitions[
		requested_policy_id
	]

	if not definition_value is Dictionary:
		return false

	var definition: Dictionary = definition_value

	var target_key: String = _policy_target_key(
		str(
			definition.get(
				"category",
                ""
			)
		),
		str(
			definition.get(
				"target",
                ""
			)
		)
	)

	var active_policy: Dictionary = get_active_policy(
		target_key
	)

	return not active_policy.is_empty() and str(
		active_policy.get(
			"policy_id",
            ""
		)
	) == requested_policy_id


func get_active_policy(
	target_key: String
) -> Dictionary:

	var active_policies: Dictionary = get_state(
		"active_policies",
		{}
	)

	if not active_policies.has(target_key):
		return {}

	var active_value = active_policies[
		target_key
	]

	if not active_value is Dictionary:
		return {}

	return active_value.duplicate(true)


func get_active_policies() -> Dictionary:

	var active_policies: Dictionary = get_state(
		"active_policies",
		{}
	)

	return active_policies.duplicate(true)


# ============================================================
# STEP 8.3 — POLICY COST / ACTIVATION REQUEST API
# ============================================================

func request_policy_activation(
	policy_id: String
) -> bool:

	var requested_policy_id: String = policy_id.strip_edges()

	if requested_policy_id.is_empty():
		return false

	if not has_policy_definition(requested_policy_id):
		return false

	var pending_value = get_state(
		"pending_policy_activation",
		{}
	)

	if pending_value is Dictionary and not pending_value.is_empty():
		return false

	set_state(
		"pending_policy_activation",
		{
			"policy_id": requested_policy_id,
			"requested": true
		}
	)

	return true


func get_pending_policy_activation() -> Dictionary:

	var pending_value = get_state(
		"pending_policy_activation",
		{}
	)

	if not pending_value is Dictionary:
		return {}

	return pending_value.duplicate(true)


func clear_pending_policy_activation() -> void:

	set_state(
		"pending_policy_activation",
		{}
	)


func get_policy_cost_last_result() -> Dictionary:

	var result_value = get_state(
		"policy_cost_last_result",
		{}
	)

	if not result_value is Dictionary:
		return {}

	return result_value.duplicate(true)


func get_policy_cost_ledger() -> Dictionary:

	var ledger_value = get_state(
		"policy_cost_ledger",
		{}
	)

	if not ledger_value is Dictionary:
		return {}

	return ledger_value.duplicate(true)


func get_policy_effect_ledger() -> Dictionary:

	var ledger_value = get_state(
		"policy_effect_ledger",
		{}
	)

	if not ledger_value is Dictionary:
		return {}

	return ledger_value.duplicate(true)


func get_policy_effect_last_result() -> Dictionary:

	var result_value = get_state(
		"policy_effect_last_result",
		{}
	)

	if not result_value is Dictionary:
		return {}

	return result_value.duplicate(true)


func get_policy_effect_bindings() -> Dictionary:

	var bindings_value = get_state(
		"policy_effect_bindings",
		{}
	)

	if not bindings_value is Dictionary:
		return {}

	return bindings_value.duplicate(true)


func get_government_spending_allocation_shares() -> Dictionary:

	var value = get_state(
		"government_spending_allocation_shares",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_government_spending_allocation() -> Dictionary:

	var value = get_state(
		"government_spending_allocation",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_government_spending_allocation_ledger() -> Dictionary:

	var value = get_state(
		"government_spending_allocation_ledger",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_government_spending_allocation_last_result() -> Dictionary:

	var value = get_state(
		"government_spending_allocation_last_result",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


# ============================================================
# STEP 8.8 — BASIC LAW / AMENDMENT API
# ============================================================

func propose_law_amendment(
	amendment: Dictionary
) -> bool:

	if not _is_valid_law_amendment(amendment):
		return false

	var pending_value = get_state(
		"pending_law_amendment",
		{}
	)

	if pending_value is Dictionary and not pending_value.is_empty():
		return false

	set_state(
		"pending_law_amendment",
		amendment.duplicate(true)
	)

	return true


func get_current_law_state() -> Dictionary:

	var value = get_state(
		"current_law_state",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_pending_law_amendment() -> Dictionary:

	var value = get_state(
		"pending_law_amendment",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func clear_pending_law_amendment() -> void:

	set_state(
		"pending_law_amendment",
		{}
	)


func get_law_amendment_ledger() -> Dictionary:

	var value = get_state(
		"law_amendment_ledger",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_law_amendment_last_result() -> Dictionary:

	var value = get_state(
		"law_amendment_last_result",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


# ============================================================
# STEP 8.9 — IMPLEMENTATION CAPACITY API
# ============================================================

func get_implementation_capacity() -> float:

	return clamp(
		float(
			get_state(
				"implementation_capacity",
				1.0
			)
		),
		0.0,
		1.0
	)


func set_implementation_capacity(value: float) -> void:

	set_state(
		"implementation_capacity",
		clamp(value, 0.0, 1.0)
	)


func get_implementation_capacity_ledger() -> Dictionary:

	var value = get_state(
		"implementation_capacity_ledger",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_implementation_capacity_last_result() -> Dictionary:

	var value = get_state(
		"implementation_capacity_last_result",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_policy_implementation_factors() -> Dictionary:

	var value = get_state(
		"policy_implementation_factors",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


# ============================================================
# STEP 8.10 — SIMPLIFIED GOVERNMENT TRANSITION API
# ============================================================

func propose_government_transition(
	transition_id: String,
	target_government_type: String,
	required_current_type: String = ""
) -> bool:

	var normalized_id: String = transition_id.strip_edges()
	var normalized_target: String = target_government_type.strip_edges()
	var normalized_required: String = required_current_type.strip_edges()
	var current_type: String = str(
		get_state(
			"government_type",
            "default"
		)
	).strip_edges()

	if normalized_id.is_empty():
		return false

	if normalized_target.is_empty():
		return false

	if normalized_target == current_type:
		return false

	if not normalized_required.is_empty() and normalized_required != current_type:
		return false

	var existing = get_pending_government_transition()
	if not existing.is_empty():
		var existing_id: String = str(
			existing.get(
				"transition_id",
                ""
			)
		)

		if existing_id == normalized_id:
			return true

		return false

	set_state(
		"pending_government_transition",
		{
			"transition_id": normalized_id,
			"from_type": current_type,
			"to_type": normalized_target,
			"required_current_type": normalized_required,
			"approved": false,
			"status": "pending"
		}
	)

	return true


func approve_pending_government_transition(
	transition_id: String
) -> bool:

	var pending := get_pending_government_transition()

	if pending.is_empty():
		return false

	var normalized_id: String = transition_id.strip_edges()
	if normalized_id.is_empty():
		return false

	if str(
		pending.get(
			"transition_id",
            ""
		)
	) != normalized_id:
		return false

	if pending.get("approved", false) == true:
		return true

	pending["approved"] = true
	pending["status"] = "approved"

	set_state(
		"pending_government_transition",
		pending
	)

	return true


func get_pending_government_transition() -> Dictionary:

	var value = get_state(
		"pending_government_transition",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func clear_pending_government_transition() -> void:

	set_state(
		"pending_government_transition",
		{}
	)


func get_government_transition_ledger() -> Dictionary:

	var value = get_state(
		"government_transition_ledger",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func get_government_transition_last_result() -> Dictionary:

	var value = get_state(
		"government_transition_last_result",
		{}
	)

	if not value is Dictionary:
		return {}

	return value.duplicate(true)


func _is_valid_law_amendment(
	amendment: Dictionary
) -> bool:

	var amendment_id: String = str(
		amendment.get(
			"amendment_id",
            ""
		)
	).strip_edges()

	var law_id: String = str(
		amendment.get(
			"law_id",
            ""
		)
	).strip_edges()

	var provision: String = str(
		amendment.get(
			"provision",
            ""
		)
	).strip_edges()

	if amendment_id.is_empty():
		return false

	if law_id.is_empty():
		return false

	if provision.is_empty():
		return false

	if not amendment.has("new_value"):
		return false

	if amendment.get("approved", false) != true:
		return false

	return true


func _policy_target_key(
	category: String,
	target: String
) -> String:

	return (
		category.strip_edges()
		+ "::"
		+ target.strip_edges()
	)
