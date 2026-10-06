class_name GovernmentPolicyEffectSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.4
# POLICY EFFECT SYSTEM
# ============================================================
#
# Policy definitions remain data. Active policies are interpreted
# here and modify state owned by existing systems/components.
#
# Supported MVP effects remain deliberately small:
#
#   economy.tax_revenue_rate
#   economy.investment_rate
#   government.spending.infrastructure_share
#   government.spending.military_share
#   government.spending.public_services_share
#   government.spending.administration_share
#
# Step 8.6 uses the four government spending shares as policy-controlled
# allocation inputs. The allocation system derives actual category amounts
# from the existing economy.government_spending total.
#
# No new economic model is created. The EconomySystem remains the
# authoritative consumer of these existing fields on its next
# monthly update.
#
# Effect schema inside GovernmentPolicyDefinition.effects:
#
#   {
#       "economy.tax_revenue_rate": 0.15
#   }
#
# Rates are bounded to 0..1. Unsupported effect keys reject the
# entire policy-effect application for that policy, preventing
# partial mutation.
# ============================================================

const EFFECT_TAX_REVENUE_RATE: String = (
    "economy.tax_revenue_rate"
)

const EFFECT_INVESTMENT_RATE: String = (
    "economy.investment_rate"
)

const EFFECT_SPENDING_INFRASTRUCTURE: String = (
    "government.spending.infrastructure_share"
)

const EFFECT_SPENDING_MILITARY: String = (
    "government.spending.military_share"
)

const EFFECT_SPENDING_PUBLIC_SERVICES: String = (
    "government.spending.public_services_share"
)

const EFFECT_SPENDING_ADMINISTRATION: String = (
    "government.spending.administration_share"
)

const SUPPORTED_EFFECTS: Dictionary = {
	EFFECT_TAX_REVENUE_RATE: true,
	EFFECT_INVESTMENT_RATE: true,
	EFFECT_SPENDING_INFRASTRUCTURE: true,
	EFFECT_SPENDING_MILITARY: true,
	EFFECT_SPENDING_PUBLIC_SERVICES: true,
	EFFECT_SPENDING_ADMINISTRATION: true
}


func _init():
	super("government_policy_effect_system")


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

		_apply_country_effects(
			entity,
			government
		)


func _apply_country_effects(
	entity: SimEntity,
	government: GovernmentComponent
	) -> void:

	var economy = entity.get_component(
        "economy"
	)

	if economy == null:
		_record_result(
			government,
			"missing_economy_component",
			[],
			[]
		)
		return

	var active_policies: Dictionary = government.get_active_policies()
	var desired_effects: Dictionary = {}
	var validation_errors: Array[String] = []

	var target_keys: Array = active_policies.keys()
	target_keys.sort()

	for target_key in target_keys:

		var active_value = active_policies[target_key]

		if not active_value is Dictionary:
			validation_errors.append(
				"invalid_active_policy_state:" + str(target_key)
			)
			continue

		var active_policy: Dictionary = active_value
		var policy_id: String = str(
			active_policy.get(
				"policy_id",
                ""
			)
		).strip_edges()

		if policy_id.is_empty():
			validation_errors.append(
				"missing_policy_id:" + str(target_key)
			)
			continue

		var definition: Dictionary = government.get_policy_definition(
			policy_id
		)

		if definition.is_empty():
			validation_errors.append(
				"undefined_policy:" + policy_id
			)
			continue

		var raw_effects = definition.get(
			"effects",
			{}
		)

		if not raw_effects is Dictionary:
			validation_errors.append(
				"invalid_effect_schema:" + policy_id
			)
			continue

		var effects: Dictionary = raw_effects

		for effect_key in effects.keys():

			var normalized_key: String = str(effect_key)

			if not SUPPORTED_EFFECTS.has(normalized_key):
				validation_errors.append(
					"unsupported_effect:" + normalized_key
				)
				continue

			var raw_value = effects[effect_key]

			if not (raw_value is int or raw_value is float):
				validation_errors.append(
					"invalid_effect_value:" + normalized_key
				)
				continue

			var effect_value: float = float(raw_value)

			if effect_value < 0.0 or effect_value > 1.0:
				validation_errors.append(
					"effect_out_of_range:" + normalized_key
				)
				continue

			if desired_effects.has(normalized_key):
				validation_errors.append(
					"effect_collision:" + normalized_key
				)
				continue

			var metadata_value = definition.get(
				"metadata",
				{}
			)

			var implementation_enabled: bool = false

			if metadata_value is Dictionary:
				implementation_enabled = metadata_value.get(
					"implementation_capacity_enabled",
					false
				) == true

			var implementation_factor: float = government.get_implementation_capacity()

			desired_effects[normalized_key] = {
				"policy_id": policy_id,
				"target_key": str(target_key),
				"value": effect_value,
				"implementation_enabled": implementation_enabled,
				"implementation_factor": implementation_factor
			}

	if not validation_errors.is_empty():
		_record_result(
			government,
			"rejected",
			validation_errors,
			[]
		)
		return

	var bindings: Dictionary = government.get_policy_effect_bindings()
	var changed_effects: Array = []
	var restored_effects: Array = []

	# Restore baselines for effect keys which are no longer represented
	# by any currently active policy. This prevents stale policy state.
	var existing_keys: Array = bindings.keys()
	for effect_key in existing_keys:

		if desired_effects.has(effect_key):
			continue

		var binding_value = bindings[effect_key]

		if binding_value is Dictionary:
			var baseline_value: float = float(
				binding_value.get(
					"baseline_value",
					0.0
				)
			)

			if _set_existing_state(
				government,
				economy,
				effect_key,
				baseline_value
			):
				restored_effects.append({
					"effect_key": effect_key,
					"value": baseline_value
				})

		bindings.erase(effect_key)

	# Apply every currently desired effect. A new effect captures the
	# pre-policy value as its restoration baseline. A replacement policy
	# keeps the original baseline while changing the active value.
	var desired_keys: Array = desired_effects.keys()
	desired_keys.sort()

	for effect_key in desired_keys:

		var desired: Dictionary = desired_effects[effect_key]
		var intended_value: float = float(
			desired.get(
				"value",
				0.0
			)
		)
		var policy_id: String = str(
			desired.get(
				"policy_id",
                ""
			)
		)
		var target_key: String = str(
			desired.get(
				"target_key",
                ""
			)
		)

		var implementation_enabled: bool = desired.get(
			"implementation_enabled",
			false
		) == true

		var implementation_factor: float = clamp(
			float(
				desired.get(
					"implementation_factor",
					1.0
				)
			),
			0.0,
			1.0
		)

		var current_value: float = _get_existing_state(
			government,
			economy,
			effect_key
		)

		if not bindings.has(effect_key):
			bindings[effect_key] = {
				"policy_id": policy_id,
				"target_key": target_key,
				"baseline_value": current_value
			}

		elif bindings[effect_key] is Dictionary:
			var existing_binding: Dictionary = bindings[effect_key]
			existing_binding["policy_id"] = policy_id
			existing_binding["target_key"] = target_key
			bindings[effect_key] = existing_binding

		var baseline_value: float = float(
			bindings[effect_key].get(
				"baseline_value",
				current_value
			)
		) if bindings[effect_key] is Dictionary else current_value

		var actual_value: float = intended_value

		if implementation_enabled:
			actual_value = baseline_value + (
				intended_value - baseline_value
			) * implementation_factor

		actual_value = clamp(
			actual_value,
			0.0,
			1.0
		)

		if not is_equal_approx(
			current_value,
			actual_value
		):
			if _set_existing_state(
				government,
				economy,
				effect_key,
				actual_value
			):
				changed_effects.append({
					"effect_key": effect_key,
					"policy_id": policy_id,
					"previous_value": current_value,
					"intended_value": intended_value,
					"implementation_capacity_enabled": implementation_enabled,
					"implementation_capacity_factor": implementation_factor,
					"actual_value": actual_value
				})

	government.set_state(
		"policy_effect_bindings",
		bindings
	)

	if changed_effects.is_empty() and restored_effects.is_empty():
		_record_result(
			government,
			"no_change",
			[],
			[]
		)
		return

	_record_result(
		government,
		"applied",
		[],
		changed_effects,
		restored_effects
	)


func _get_existing_state(
	government: GovernmentComponent,
	economy,
	effect_key: String
) -> float:

	match effect_key:
		EFFECT_TAX_REVENUE_RATE:
			return float(
				economy.get_state(
					"tax_revenue_rate",
					0.10
				)
			)
		EFFECT_INVESTMENT_RATE:
			return float(
				economy.get_state(
					"investment_rate",
					0.10
				)
			)
		EFFECT_SPENDING_INFRASTRUCTURE:
			return _get_spending_share(
				government,
				"infrastructure",
				0.30
			)
		EFFECT_SPENDING_MILITARY:
			return _get_spending_share(
				government,
				"military",
				0.20
			)
		EFFECT_SPENDING_PUBLIC_SERVICES:
			return _get_spending_share(
				government,
				"public_services",
				0.30
			)
		EFFECT_SPENDING_ADMINISTRATION:
			return _get_spending_share(
				government,
				"administration",
				0.20
			)
		_:
			return 0.0


func _set_existing_state(
	government: GovernmentComponent,
	economy,
	effect_key: String,
	value: float
	) -> bool:

	var bounded_value: float = clamp(
		value,
		0.0,
		1.0
	)

	match effect_key:
		EFFECT_TAX_REVENUE_RATE:
			economy.set_state(
				"tax_revenue_rate",
				bounded_value
			)
			return true
		EFFECT_INVESTMENT_RATE:
			economy.set_state(
				"investment_rate",
				bounded_value
			)
			return true
		EFFECT_SPENDING_INFRASTRUCTURE:
			return _set_spending_share(
				government,
				"infrastructure",
				bounded_value
			)
		EFFECT_SPENDING_MILITARY:
			return _set_spending_share(
				government,
				"military",
				bounded_value
			)
		EFFECT_SPENDING_PUBLIC_SERVICES:
			return _set_spending_share(
				government,
				"public_services",
				bounded_value
			)
		EFFECT_SPENDING_ADMINISTRATION:
			return _set_spending_share(
				government,
				"administration",
				bounded_value
			)
		_:
			return false


func _get_spending_share(
	government: GovernmentComponent,
	category: String,
	fallback: float
	) -> float:

	var raw_shares = government.get_state(
		"government_spending_allocation_shares",
		{}
	)

	if not raw_shares is Dictionary:
		return fallback

	return float(
		raw_shares.get(
			category,
			fallback
		)
	)


func _set_spending_share(
	government: GovernmentComponent,
	category: String,
	value: float
	) -> bool:

	var raw_shares = government.get_state(
		"government_spending_allocation_shares",
		{}
	)

	var shares: Dictionary = {}

	if raw_shares is Dictionary:
		shares = raw_shares.duplicate(true)

	shares[category] = clamp(
		value,
		0.0,
		1.0
	)

	government.set_state(
		"government_spending_allocation_shares",
		shares
	)

	return true


func _record_result(
	government: GovernmentComponent,
	action: String,
	errors: Array,
	changes: Array,    restores: Array = []
	) -> void:

	var previous_revision: int = int(
		government.get_state(
			"policy_effect_revision",
			0
		)
	)

	var changed: bool = (
		action == "applied"
		and (not changes.is_empty() or not restores.is_empty())
	)

	var revision: int = previous_revision

	if changed:
		revision += 1

	var result: Dictionary = {
		"action": action,
		"revision": revision,
		"errors": errors.duplicate(true),
		"changes": changes.duplicate(true),
		"restored": restores.duplicate(true)
	}

	if changed:
		var ledger: Dictionary = government.get_policy_effect_ledger()
		ledger[str(revision)] = result.duplicate(true)
		government.set_state(
			"policy_effect_revision",
			revision
		)
		government.set_state(
			"policy_effect_ledger",
			ledger
		)

	government.set_state(
		"policy_effect_last_result",
		result
	)
