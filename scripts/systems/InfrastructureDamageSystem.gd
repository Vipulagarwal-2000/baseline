class_name InfrastructureDamageSystem
extends SimulationSystem


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


func _init():
	super("infrastructure_damage_system")


func process_month(
	world: WorldState
) -> void:
	# Step 14.1 is an explicit damage-creation API layer. It does not
	# automatically inflict damage each month and does not reduce raw or
	# effective infrastructure capacity. Those consequences belong to 14.2+.
	if world == null:
		push_error("InfrastructureDamageSystem: World is null.")
		return


func apply_event_damage(
	world: WorldState,
	target_id: String,
	infrastructure_type: String,
	amount: float,
	event: SimulationEvent,
	damage_id: String = "",
	reason: String = ""
) -> bool:
	return apply_damage(
		world,
		target_id,
		infrastructure_type,
		amount,
		event,
		damage_id,
		reason
	)


func apply_conflict_damage(
	world: WorldState,
	target_id: String,
	infrastructure_type: String,
	amount: float,
	conflict: MilitaryConflict,
	damage_id: String = "",
	reason: String = ""
) -> bool:
	return apply_damage(
		world,
		target_id,
		infrastructure_type,
		amount,
		conflict,
		damage_id,
		reason
	)


func apply_damage(
	world: WorldState,
	target_id: String,
	infrastructure_type: String,
	amount: float,
	source,
	damage_id: String = "",
	reason: String = ""
) -> bool:
	if world == null:
		return false

	if target_id.is_empty():
		return false

	if not INFRASTRUCTURE_TYPES.has(infrastructure_type):
		return false

	var requested_amount: float = clamp(
		amount,
		0.0,
		1.0
	)

	if is_zero_approx(requested_amount):
		return false

	var source_metadata: Dictionary = _resolve_source(
		world,
		source
	)

	if source_metadata.is_empty():
		return false

	var country = world.get_entity(target_id)
	if country == null:
		return false

	var infrastructure = country.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return false

	var effective_damage_id := damage_id
	if effective_damage_id.is_empty():
		effective_damage_id = _default_damage_id(
			world,
			target_id,
			infrastructure_type,
			source_metadata
		)

	var source_key := _build_source_key(
		target_id,
		infrastructure_type,
		effective_damage_id,
		source_metadata
	)

	var records := _get_damage_records(
		infrastructure
	)

	if _has_application_key(
		records,
		source_key
	):
		# The same explicit source application is idempotent.
		return false

	var damage_state := _get_damage_state(
		infrastructure
	)

	var previous_damage: float = clamp(
		float(
			damage_state.get(
				infrastructure_type,
				0.0
			)
		),
		0.0,
		1.0
	)

	var applied_damage: float = min(
		requested_amount,
		1.0 - previous_damage
	)

	if is_zero_approx(applied_damage):
		return false

	var new_damage: float = clamp(
		previous_damage + applied_damage,
		0.0,
		1.0
	)

	damage_state[infrastructure_type] = new_damage

	infrastructure.set_state(
		"infrastructure_damage",
		damage_state
	)

	var damage_total: float = _calculate_total_damage(
		damage_state
	)

	infrastructure.set_state(
		"infrastructure_damage_total",
		damage_total
	)

	var record := {
		"damage_id": effective_damage_id,
		"application_key": source_key,
		"source_type": source_metadata.get(
			"source_type",
			""
		),
		"source_id": source_metadata.get(
			"source_id",
			""
		),
		"source_name": source_metadata.get(
			"source_name",
			""
		),
		"source_state": source_metadata.get(
			"source_state",
			""
		),
		"target_id": target_id,
		"infrastructure_type": infrastructure_type,
		"requested_amount": requested_amount,
		"applied_amount": applied_damage,
		"cumulative_damage": new_damage,
		"reason": reason,
		"year": world.get_year(),
		"month": world.get_month(),
		"day": world.get_day()
	}

	records.append(record)

	infrastructure.set_state(
		"infrastructure_damage_records",
		records
	)

	infrastructure.set_state(
		"last_damage_source",
		record.duplicate(true)
	)

	return true


func get_damage(
	country,
	infrastructure_type: String
) -> float:
	if country == null:
		return 0.0

	if not INFRASTRUCTURE_TYPES.has(infrastructure_type):
		return 0.0

	var infrastructure = country.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return 0.0

	var damage_state := _get_damage_state(
		infrastructure
	)

	return clamp(
		float(
			damage_state.get(
				infrastructure_type,
				0.0
			)
		),
		0.0,
		1.0
	)


func get_damage_total(
	country
) -> float:
	if country == null:
		return 0.0

	var infrastructure = country.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return 0.0

	return clamp(
		float(
			infrastructure.get_state(
				"infrastructure_damage_total",
				0.0
			)
		),
		0.0,
		1.0
	)


func _resolve_source(
	world: WorldState,
	source
) -> Dictionary:
	if world == null or source == null:
		return {}

	if source is SimulationEvent:
		var event: SimulationEvent = source
		if not _world_contains_event(
			world,
			event
		):
			return {}

		if event.id.is_empty():
			return {}

		return {
			"source_type": "event",
			"source_id": event.id,
			"source_name": event.name,
			"source_state": event.state
		}

	if source is MilitaryConflict:
		var conflict: MilitaryConflict = source
		if not _world_contains_conflict(
			world,
			conflict
		):
			return {}

		if conflict.id.is_empty():
			return {}

		return {
			"source_type": "conflict",
			"source_id": conflict.id,
			"source_name": conflict.attacker_id + "_vs_" + conflict.defender_id,
			"source_state": conflict.state
		}

	return {}


func _world_contains_event(
	world: WorldState,
	event: SimulationEvent
) -> bool:
	return (
		world.active_events.has(event)
		or world.completed_events.has(event)
	)


func _world_contains_conflict(
	world: WorldState,
	conflict: MilitaryConflict
) -> bool:
	return (
		world.active_conflicts.has(conflict)
		or world.completed_conflicts.has(conflict)
	)


func _default_damage_id(
	world: WorldState,
	target_id: String,
	infrastructure_type: String,
	source_metadata: Dictionary
) -> String:
	return (
		String(source_metadata.get("source_type", ""))
		+ ":"
		+ String(source_metadata.get("source_id", ""))
		+ ":"
		+ target_id
		+ ":"
		+ infrastructure_type
		+ ":"
		+ str(world.get_year())
		+ "-"
		+ str(world.get_month())
		+ "-"
		+ str(world.get_day())
	)


func _build_source_key(
	target_id: String,
	infrastructure_type: String,
	damage_id: String,
	source_metadata: Dictionary
) -> String:
	return (
		String(source_metadata.get("source_type", ""))
		+ ":"
		+ String(source_metadata.get("source_id", ""))
		+ ":"
		+ damage_id
		+ ":"
		+ target_id
		+ ":"
		+ infrastructure_type
	)


func _get_damage_state(
	infrastructure
) -> Dictionary:
	var raw = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)

	if typeof(raw) != TYPE_DICTIONARY:
		raw = {}

	var result: Dictionary = {}

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		result[infrastructure_type] = clamp(
			float(
				raw.get(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

	return result


func _get_damage_records(
	infrastructure
) -> Array:
	var raw = infrastructure.get_state(
		"infrastructure_damage_records",
		[]
	)

	if typeof(raw) != TYPE_ARRAY:
		return []

	return raw.duplicate(true)


func _has_application_key(
	records: Array,
	application_key: String
) -> bool:
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue

		if String(
			record.get(
				"application_key",
				""
			)
		) == application_key:
			return true

	return false


func _calculate_total_damage(
	damage_state: Dictionary
) -> float:
	var total: float = 0.0

	for infrastructure_type in INFRASTRUCTURE_TYPES:
		total += clamp(
			float(
				damage_state.get(
					infrastructure_type,
					0.0
				)
			),
			0.0,
			1.0
		)

	return clamp(
		total / float(INFRASTRUCTURE_TYPES.size()),
		0.0,
		1.0
	)
