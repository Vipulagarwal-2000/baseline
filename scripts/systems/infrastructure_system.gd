class_name InfrastructureSystem
extends SimulationSystem


func _init():
	super("infrastructure_system")


# Step 14.2 — Infrastructure capacity loss is a derived layer inside the
# existing country-level infrastructure authority. Raw infrastructure
# values remain unchanged. Effective capacity is rebuilt from:
# raw capacity × maintenance condition × (1 - recorded damage).


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"InfrastructureSystem: World is null."
		)
		return

	for country in world.entities.values():

		if country == null:
			continue

		var infrastructure = country.get_component(
			"infrastructure"
		)

		if infrastructure == null:
			continue

		_recalculate_total_capacity(
			infrastructure
		)

		_sync_resource_capacity(
			country,
			infrastructure
		)


func _recalculate_total_capacity(
	infrastructure: InfrastructureComponent
) -> void:

	# Step 14.2:
	# Rebuild effective infrastructure capacity from the authoritative raw
	# infrastructure values, the existing maintenance condition state, and
	# the Step 14.1 damage ledger.
	#
	# Re-deriving from raw + condition on every monthly pass is important:
	# it prevents repeated calls from multiplying the same damage more than
	# once and keeps raw infrastructure values immutable.

	var conditions = infrastructure.get_state(
		"infrastructure_condition",
		{}
	)

	if typeof(conditions) != TYPE_DICTIONARY:
		conditions = {}

	var damage_state = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)

	if typeof(damage_state) != TYPE_DICTIONARY:
		damage_state = {}

	var effective_capacity: Dictionary = {}
	var values: Dictionary = {}

	for infrastructure_type in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage"
	]:
		var raw_value: float = clampf(
			_safe_value(
				infrastructure.get_state(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

		var condition: float = clampf(
			_safe_value(
				conditions.get(
					infrastructure_type,
					1.0
				)
			),
			0.0,
			1.0
		)

		var damage: float = clampf(
			_safe_value(
				damage_state.get(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

		var maintenance_adjusted_capacity: float = clampf(
			raw_value * condition,
			0.0,
			1.0
		)

		var damage_multiplier: float = 1.0 - damage

		var damaged_effective_capacity: float = clampf(
			maintenance_adjusted_capacity * damage_multiplier,
			0.0,
			1.0
		)

		effective_capacity[infrastructure_type] = (
			damaged_effective_capacity
		)
		values[infrastructure_type] = damaged_effective_capacity

	infrastructure.set_state(
		"effective_infrastructure_capacity",
		effective_capacity
	)

	var total: float = 0.0

	for infrastructure_type in values.keys():
		total += float(values[infrastructure_type])

	total /= float(values.size())

	infrastructure.set_state(
		"total_capacity",
		clampf(
			total,
			0.0,
			1.0
		)
	)


func _sync_resource_capacity(
	country,
	infrastructure: InfrastructureComponent
) -> void:

	var resources = country.get_component(
		"resources"
	)

	if resources == null:
		return

	var total_capacity = clampf(
		float(
			infrastructure.get_state(
				"total_capacity",
				1.0
			)
		),
		0.0,
		1.0
	)

	# Rebuild both derived bridge dictionaries from the current authoritative
	# resource set. Do not mutate the existing dictionaries in place because
	# that would retain resource keys that no longer exist in the current
	# resource state.
	var infrastructure_capacity: Dictionary = {}
	var storage_capacity: Dictionary = {}

	var effective_capacity = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)

	var storage_level = clampf(
		_safe_value(
			infrastructure.get_state(
				"storage",
				0.0
			)
		),
		0.0,
		1.0
	)

	if typeof(effective_capacity) == TYPE_DICTIONARY and not effective_capacity.is_empty():
		storage_level = clampf(
			_safe_value(
				effective_capacity.get(
					"storage",
					storage_level
				)
			),
			0.0,
			1.0
		)

	var resource_names: Dictionary = {}

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"production",
			{}
		)
	)

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"consumption",
			{}
		)
	)

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"reserves",
			{}
		)
	)

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"stockpile",
			{}
		)
	)

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"imports",
			{}
		)
	)

	_collect_resource_names(
		resource_names,
		resources.get_state(
			"exports",
			{}
		)
	)

	for resource_name in resource_names.keys():
		infrastructure_capacity[resource_name] = total_capacity
		storage_capacity[resource_name] = storage_level

	resources.set_state(
		"infrastructure_capacity",
		infrastructure_capacity
	)

	resources.set_state(
		"storage_capacity",
		storage_capacity
	)


func _collect_resource_names(
	resource_names: Dictionary,
	resource_data
) -> void:

	if typeof(resource_data) != TYPE_DICTIONARY:
		return

	for resource_name in resource_data.keys():
		resource_names[resource_name] = true


func _safe_value(
	value
) -> float:

	if typeof(value) == TYPE_INT:
		return float(value)

	if typeof(value) == TYPE_FLOAT:
		return value

	return 0.0
