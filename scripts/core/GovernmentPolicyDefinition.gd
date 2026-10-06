class_name GovernmentPolicyDefinition
extends RefCounted


# ============================================================
# GOVERNMENT POLICY DEFINITION — STEP 8.1
# ============================================================
#
# Data-only policy definition.
#
# Step 8.1 deliberately does NOT:
# - activate policies
# - charge policy costs
# - apply policy effects
# - alter economy / military / trade / population state
# - simulate parliament, parties, elections, ministries, or
#   constitutional mechanics
#
# Those behaviors belong to later Step 8 substeps.
# ============================================================

var policy_id: String = ""
var category: String = ""
var target: String = ""
var value: float = 0.0
var cost: Dictionary = {}
var duration_months: int = 0
var effects: Dictionary = {}
var metadata: Dictionary = {}


func _init(
	policy_id_value: String = "",
	category_value: String = "",
	target_value: String = "",
	value_value: float = 0.0,
	cost_value: Dictionary = {},
	duration_months_value: int = 0,
	effects_value: Dictionary = {},
	metadata_value: Dictionary = {}
) -> void:

	policy_id = str(policy_id_value).strip_edges()
	category = str(category_value).strip_edges()
	target = str(target_value).strip_edges()
	value = float(value_value)

	cost = cost_value.duplicate(true)
	duration_months = max(
		int(duration_months_value),
		0
	)

	effects = effects_value.duplicate(true)
	metadata = metadata_value.duplicate(true)


func is_valid() -> bool:

	if policy_id.is_empty():
		return false

	if category.is_empty():
		return false

	if target.is_empty():
		return false

	if duration_months < 0:
		return false

	for key in cost.keys():

		var cost_value = cost[key]

		if cost_value is int or cost_value is float:

			if float(cost_value) < 0.0:
				return false

		else:
			return false

	return true


func to_dict() -> Dictionary:

	return {
		"policy_id": policy_id,
		"category": category,
		"target": target,
		"value": value,
		"cost": cost.duplicate(true),
		"duration_months": duration_months,
		"effects": effects.duplicate(true),
		"metadata": metadata.duplicate(true)
	}


static func from_dict(
	data: Dictionary
) -> GovernmentPolicyDefinition:

	if data == null:
		return null

	var cost_data: Dictionary = {}
	var effects_data: Dictionary = {}
	var metadata_data: Dictionary = {}

	var raw_cost = data.get(
		"cost",
		{}
	)

	if raw_cost is Dictionary:
		cost_data = raw_cost.duplicate(true)

	var raw_effects = data.get(
		"effects",
		{}
	)

	if raw_effects is Dictionary:
		effects_data = raw_effects.duplicate(true)

	var raw_metadata = data.get(
		"metadata",
		{}
	)

	if raw_metadata is Dictionary:
		metadata_data = raw_metadata.duplicate(true)

	return GovernmentPolicyDefinition.new(
		str(
			data.get(
				"policy_id",
				""
			)
		),
		str(
			data.get(
				"category",
				""
			)
		),
		str(
			data.get(
				"target",
				""
			)
		),
		float(
			data.get(
				"value",
				0.0
			)
		),
		cost_data,
		int(
			data.get(
				"duration_months",
				0
			)
		),
		effects_data,
		metadata_data
	)
