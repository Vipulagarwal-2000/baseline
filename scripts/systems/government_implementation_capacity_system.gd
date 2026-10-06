class_name GovernmentImplementationCapacitySystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.9
# IMPLEMENTATION CAPACITY
# ============================================================
#
# The master defines the causal chain:
#
# intended effect
#       ×
# implementation capacity
#       =
# actual effect
#
# The master does not prescribe a formula for deriving capacity from
# institutional variables. This MVP therefore keeps the capacity as an
# explicit government-owned scalar bounded to 0..1.
#
# Existing Step 8.4 policies remain backward-compatible. A policy opts
# into implementation-capacity scaling through:
#
# metadata: {
#     "implementation_capacity_enabled": true
# }
#
# This system resolves the effective factor before GovernmentPolicyEffectSystem
# applies policy effects. It does not own or duplicate the effect targets.
# ============================================================

const METADATA_FLAG: String = "implementation_capacity_enabled"


func _init() -> void:
	super("government_implementation_capacity_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component("government")

		if government == null:
			continue

		_process_country(government)


func _process_country(government: GovernmentComponent) -> void:

	var raw_capacity = government.get_state(
		"implementation_capacity",
		1.0
	)

	var capacity_valid: bool = (
		raw_capacity is int
		or raw_capacity is float
	)

	if not capacity_valid:
		_record_result(
			government,
			"rejected",
			["invalid_implementation_capacity"],
			{}
		)
		return

	var capacity: float = clamp(
		float(raw_capacity),
		0.0,
		1.0
	)

	if not is_equal_approx(
		float(raw_capacity),
		capacity
	):
		government.set_state(
			"implementation_capacity",
			capacity
		)

	var active_policies: Dictionary = government.get_active_policies()
	var factors: Dictionary = {}
	var target_keys: Array = active_policies.keys()
	target_keys.sort()

	for target_key in target_keys:

		var active_value = active_policies[target_key]

		if not active_value is Dictionary:
			continue

		var active_policy: Dictionary = active_value
		var policy_id: String = str(
			active_policy.get(
				"policy_id",
                ""
			)
		).strip_edges()

		if policy_id.is_empty():
			continue

		var definition: Dictionary = government.get_policy_definition(
			policy_id
		)

		if definition.is_empty():
			continue

		var metadata_value = definition.get(
			"metadata",
			{}
		)

		var enabled: bool = false
		if metadata_value is Dictionary:
			enabled = metadata_value.get(
				METADATA_FLAG,
				false
			) == true

		factors[str(target_key)] = {
			"policy_id": policy_id,
			"enabled": enabled,
			"factor": capacity if enabled else 1.0
		}

	var previous_factors: Dictionary = government.get_policy_implementation_factors()
	var changed: bool = previous_factors != factors

	government.set_state(
		"policy_implementation_factors",
		factors
	)

	if not changed:
		_record_result(
			government,
			"no_change",
			[],
			{
				"implementation_capacity": capacity,
				"policy_count": factors.size()
			}
		)
		return

	var revision: int = int(
		government.get_state(
			"implementation_capacity_revision",
			0
		)
	) + 1

	var ledger: Dictionary = government.get_implementation_capacity_ledger()

	var result_data: Dictionary = {
		"implementation_capacity": capacity,
		"policy_factors": factors.duplicate(true)
	}

	ledger[str(revision)] = {
		"action": "updated",
		"revision": revision,
		"data": result_data.duplicate(true)
	}

	government.set_state(
		"implementation_capacity_revision",
		revision
	)

	government.set_state(
		"implementation_capacity_ledger",
		ledger
	)

	_record_result(
		government,
		"updated",
		[],
		result_data
	)


func _record_result(
	government: GovernmentComponent,
	action: String,
	errors: Array,
	data: Dictionary
	) -> void:

	government.set_state(
		"implementation_capacity_last_result",
		{
			"action": action,
			"errors": errors.duplicate(true),
			"data": data.duplicate(true)
		}
	)
