class_name MilitaryEventSystem
extends SimulationSystem


const HIGH_PRESSURE_THRESHOLD: float = 0.70
const HIGH_WAR_EXHAUSTION_THRESHOLD: float = 0.70


func _init():
	super("military_event_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("MilitaryEventSystem: World is null.")
		return

	_process_active_conflicts(world)
	_process_high_military_pressure(world)
	_process_high_war_exhaustion(world)
	_process_completed_conflicts(world)


# ============================================================
# CONFLICT STARTED
# ============================================================

func _process_active_conflicts(world: WorldState) -> void:
	if typeof(world.active_conflicts) != TYPE_ARRAY:
		return

	for conflict in world.active_conflicts:
		if conflict == null:
			continue

		if not conflict is MilitaryConflict:
			continue

		_create_conflict_started_event(
			world,
			conflict
		)


func _create_conflict_started_event(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:
	if world == null:
		return

	if conflict == null:
		return

	var event_key = (
		"military_conflict_started_"
		+ conflict.id
	)

	# Prevent duplicate events for the same conflict.
	if world.has_metadata(event_key):
		return

	var event = SimulationEvent.new(
		event_key,
		"Military Conflict Started",
		"military"
	)

	event.description = (
		"A military conflict has begun between "
		+ conflict.attacker_id
		+ " and "
		+ conflict.defender_id
		+ "."
	)

	event.add_actor(
		conflict.attacker_id
	)

	event.add_target(
		conflict.defender_id
	)

	event.priority = 1

	event.set_metadata_value(
		"military_event_type",
		"conflict_started"
	)

	event.set_metadata_value(
		"conflict_id",
		conflict.id
	)

	event.set_metadata_value(
		"attacker_id",
		conflict.attacker_id
	)

	event.set_metadata_value(
		"defender_id",
		conflict.defender_id
	)

	world.add_active_event(event)

	world.set_metadata(
		event_key,
		true
	)


# ============================================================
# HIGH MILITARY PRESSURE
# ============================================================

func _process_high_military_pressure(
	world: WorldState
) -> void:

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		var military = entity.get_component(
			"military"
		)

		if military == null:
			continue

		var military_pressure = clamp(
			float(
				military.get_state(
					"military_pressure",
					0.0
				)
			),
			0.0,
			1.0
		)

		if military_pressure < HIGH_PRESSURE_THRESHOLD:
			continue

		_create_high_pressure_event(
			world,
			entity,
			military_pressure
		)


func _create_high_pressure_event(
	world: WorldState,
	entity,
	military_pressure: float
) -> void:

	if world == null:
		return

	if entity == null:
		return

	var event_key = (
		"military_pressure_high_"
		+ entity.id
	)

	# Prevent duplicate events for the same country.
	if world.has_metadata(event_key):
		return

	var event = SimulationEvent.new(
		event_key,
		"High Military Pressure",
		"military"
	)

	event.description = (
		entity.id
		+ " is experiencing high military pressure."
	)

	event.add_actor(
		entity.id
	)

	event.priority = 1

	event.set_metadata_value(
		"military_event_type",
		"military_pressure_high"
	)

	event.set_metadata_value(
		"country_id",
		entity.id
	)

	event.set_metadata_value(
		"military_pressure",
		military_pressure
	)

	event.set_metadata_value(
		"threshold",
		HIGH_PRESSURE_THRESHOLD
	)

	world.add_active_event(event)

	world.set_metadata(
		event_key,
		true
	)


# ============================================================
# HIGH WAR EXHAUSTION
# ============================================================

func _process_high_war_exhaustion(
	world: WorldState
) -> void:

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		var military = entity.get_component(
			"military"
		)

		if military == null:
			continue

		var war_exhaustion = clamp(
			float(
				military.get_state(
					"war_exhaustion",
					0.0
				)
			),
			0.0,
			1.0
		)

		if war_exhaustion < HIGH_WAR_EXHAUSTION_THRESHOLD:
			continue

		_create_high_war_exhaustion_event(
			world,
			entity,
			war_exhaustion
		)


func _create_high_war_exhaustion_event(
	world: WorldState,
	entity,
	war_exhaustion: float
) -> void:

	if world == null:
		return

	if entity == null:
		return

	var event_key = (
		"war_exhaustion_high_"
		+ entity.id
	)

	# Prevent duplicate events for the same country.
	if world.has_metadata(event_key):
		return

	var event = SimulationEvent.new(
		event_key,
		"High War Exhaustion",
		"military"
	)

	event.description = (
		entity.id
		+ " is experiencing high war exhaustion."
	)

	event.add_actor(
		entity.id
	)

	event.priority = 1

	event.set_metadata_value(
		"military_event_type",
		"war_exhaustion_high"
	)

	event.set_metadata_value(
		"country_id",
		entity.id
	)

	event.set_metadata_value(
		"war_exhaustion",
		war_exhaustion
	)

	event.set_metadata_value(
		"threshold",
		HIGH_WAR_EXHAUSTION_THRESHOLD
	)

	world.add_active_event(event)

	world.set_metadata(
		event_key,
		true
	)


# ============================================================
# CONFLICT RESOLVED
# ============================================================

func _process_completed_conflicts(
	world: WorldState
) -> void:

	if typeof(world.completed_conflicts) != TYPE_ARRAY:
		return

	for conflict in world.completed_conflicts:

		if conflict == null:
			continue

		if not conflict is MilitaryConflict:
			continue

		if not conflict.is_completed():
			continue

		_create_conflict_resolved_event(
			world,
			conflict
		)


func _create_conflict_resolved_event(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	if world == null:
		return

	if conflict == null:
		return

	var event_key = (
		"military_conflict_resolved_"
		+ conflict.id
	)

	# Prevent duplicate events for the same conflict.
	if world.has_metadata(event_key):
		return

	var event = SimulationEvent.new(
		event_key,
		"Military Conflict Resolved",
		"military"
	)

	event.description = (
		"The military conflict between "
		+ conflict.attacker_id
		+ " and "
		+ conflict.defender_id
		+ " has ended."
	)

	event.add_actor(
		conflict.attacker_id
	)

	event.add_target(
		conflict.defender_id
	)

	event.priority = 1

	event.set_metadata_value(
		"military_event_type",
		"conflict_resolved"
	)

	event.set_metadata_value(
		"conflict_id",
		conflict.id
	)

	event.set_metadata_value(
		"attacker_id",
		conflict.attacker_id
	)

	event.set_metadata_value(
		"defender_id",
		conflict.defender_id
	)

	event.set_metadata_value(
		"outcome",
		conflict.outcome
	)

	event.set_metadata_value(
		"termination_reason",
		conflict.termination_reason
	)

	event.set_metadata_value(
		"duration_months",
		conflict.duration_months
	)

	world.add_active_event(event)

	world.set_metadata(
		event_key,
		true
	)
