class_name ExternalEventCausalitySystem
extends SimulationSystem


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.3
# EXTERNAL EVENT CAUSALITY
# ============================================================
#
# Converts an externally-originated event request stored on an
# ExternalWorldActor into:
#
#   external actor
#       -> SimulationEvent
#       -> one or more core-country targets
#       -> material external-event impact state
#
# This stage establishes causality and persistence of the consequence
# ledger. It does not implement the later 10.4 external simulation
# layer or the 10.5 relevance filter.
# ============================================================

const PENDING_EVENT_KEY: String = "pending_causal_events"
const PROCESSED_EVENT_KEY: String = "processed_causal_events"
const LAST_CREATED_EVENT_KEY: String = "last_created_causal_event"
const LAST_APPLIED_EVENT_KEY: String = "last_applied_causal_event"
const IMPACT_COMPONENT_TYPE: String = "external_event_impact"


func _init() -> void:
	super("external_event_causality")


# ============================================================
# MONTHLY EXECUTION
# ============================================================

func process_month(world: WorldState) -> void:
	if world == null:
		return

	var actor_ids: Array[String] = []

	for entity_id in world.entities.keys():
		var entity = world.entities[entity_id]

		if entity == null:
			continue

		if not entity is ExternalWorldActor:
			continue

		actor_ids.append(str(entity_id))

	actor_ids.sort()

	for actor_id in actor_ids:
		var actor = world.get_entity(actor_id)
		if actor == null:
			continue

		_process_actor_pending_events(
			world,
			actor
		)


# ============================================================
# EXTERNAL EVENT QUEUE
# ============================================================

func queue_external_event(
	world: WorldState,
	actor_id: String,
	event_id: String,
	event_name: String,
	event_category: String,
	description: String,
	target_impacts: Dictionary,
	priority: int = 0
) -> bool:
	if world == null:
		return false

	if actor_id.is_empty() or event_id.is_empty():
		return false

	var actor = world.get_entity(actor_id)

	if actor == null:
		return false

	if not actor is ExternalWorldActor:
		return false

	if event_name.is_empty() or event_category.is_empty():
		return false

	if typeof(target_impacts) != TYPE_DICTIONARY:
		return false

	if target_impacts.is_empty():
		return false

	# Existing pending/processed IDs are authoritative for idempotence
	# before the event enters the monthly processing path.
	var pending = actor.get_event_state(
		PENDING_EVENT_KEY,
		{}
	)

	if typeof(pending) != TYPE_DICTIONARY:
		pending = {}

	var processed = actor.get_event_state(
		PROCESSED_EVENT_KEY,
		{}
	)

	if typeof(processed) != TYPE_DICTIONARY:
		processed = {}

	if pending.has(event_id) or processed.has(event_id):
		return false

	var normalized_targets: Dictionary = {}
	var target_ids: Array[String] = []

	for target_id_value in target_impacts.keys():
		var target_id = str(target_id_value)

		if target_id.is_empty():
			return false

		if not CoreCountryRegistry.is_core_country(target_id):
			return false

		var target = world.get_entity(target_id)

		if target == null:
			return false

		if target.entity_type != "country":
			return false

		var impact_value = target_impacts[target_id_value]

		if typeof(impact_value) != TYPE_DICTIONARY:
			return false

		normalized_targets[target_id] = impact_value.duplicate(true)
		target_ids.append(target_id)

	target_ids.sort()

	pending[event_id] = {
		"event_id": event_id,
		"event_name": event_name,
		"category": event_category,
		"description": description,
		"priority": priority,
		"actor_id": actor_id,
		"target_ids": target_ids,
		"target_impacts": normalized_targets
	}

	actor.set_event_state(
		PENDING_EVENT_KEY,
		pending
	)

	return true


# ============================================================
# PENDING EVENT PROCESSING
# ============================================================

func _process_actor_pending_events(
	world: WorldState,
	actor: ExternalWorldActor
) -> void:
	var pending = actor.get_event_state(
		PENDING_EVENT_KEY,
		{}
	)

	if typeof(pending) != TYPE_DICTIONARY:
		return

	var event_ids: Array[String] = []

	for event_id_value in pending.keys():
		event_ids.append(str(event_id_value))

	event_ids.sort()

	for event_id in event_ids:
		var packet = pending.get(event_id, {})

		if typeof(packet) != TYPE_DICTIONARY:
			continue

		_process_pending_packet(
			world,
			actor,
			packet
		)

	# Re-read after processing because processed packets are removed.
	pending = actor.get_event_state(
		PENDING_EVENT_KEY,
		{}
	)

	if typeof(pending) != TYPE_DICTIONARY:
		pending = {}

	actor.set_event_state(
		PENDING_EVENT_KEY,
		pending
	)


func _process_pending_packet(
	world: WorldState,
	actor: ExternalWorldActor,
	packet: Dictionary
) -> bool:
	var event_id: String = str(
		packet.get("event_id", "")
	)

	if event_id.is_empty():
		return false

	var processed = actor.get_event_state(
		PROCESSED_EVENT_KEY,
		{}
	)

	if typeof(processed) != TYPE_DICTIONARY:
		processed = {}

	if processed.has(event_id):
		return false

	var target_impacts = packet.get(
		"target_impacts",
		{}
	)

	if typeof(target_impacts) != TYPE_DICTIONARY:
		return false

	# Validate every target before mutating any target state.
	var target_ids: Array[String] = []

	for target_id_value in target_impacts.keys():
		var target_id = str(target_id_value)
		var target = world.get_entity(target_id)

		if target == null:
			return false

		if not CoreCountryRegistry.is_core_country(target_id):
			return false

		if target.entity_type != "country":
			return false

		target_ids.append(target_id)

	target_ids.sort()

	# Create the real event object used by the existing EventSynchronizer.
	var simulation_event := SimulationEvent.new(
		event_id,
		str(packet.get("event_name", event_id)),
		str(packet.get("category", "international"))
	)

	simulation_event.description = str(
		packet.get(
			"description",
			"External event originating outside the core simulated world."
		)
	)

	simulation_event.priority = int(
		packet.get("priority", 0)
	)

	var event_added := false

	# Reuse the existing event-management contract rather than directly
	# implementing another active/completed event container.
	var synchronizer := EventSynchronizer.new()
	event_added = synchronizer.add_event(
		world,
		simulation_event
	)

	if not event_added:
		return false

	# Apply target impacts exactly once per target/event pair.
	for target_id in target_ids:
		var target = world.get_entity(target_id)
		var impact_component = _get_or_create_impact_component(
			target
		)

		if impact_component == null:
			return false

		var impact = target_impacts.get(
			target_id,
			{}
		)

		if not impact_component.record_external_event(
			event_id,
			actor.id,
			str(packet.get("event_name", event_id)),
			impact
		):
			# Existing event state means the consequence was already
			# applied. This is idempotent and is not a new failure.
			if not impact_component.is_event_applied(event_id):
				return false

	var processed_record: Dictionary = packet.duplicate(true)
	processed_record["created_at"] = world.current_date.duplicate(true)
	processed_record["applied"] = true

	processed[event_id] = processed_record
	actor.set_event_state(
		PROCESSED_EVENT_KEY,
		processed
	)

	actor.set_event_state(
		LAST_CREATED_EVENT_KEY,
		processed_record.duplicate(true)
	)

	actor.set_event_state(
		LAST_APPLIED_EVENT_KEY,
		processed_record.duplicate(true)
	)

	# Remove the queued packet after successful materialization.
	var pending = actor.get_event_state(
		PENDING_EVENT_KEY,
		{}
	)

	if typeof(pending) == TYPE_DICTIONARY:
		pending.erase(event_id)
		actor.set_event_state(
			PENDING_EVENT_KEY,
			pending
		)

	return true


# ============================================================
# CORE-COUNTRY IMPACT COMPONENT
# ============================================================

func _get_or_create_impact_component(
	country
) -> ExternalEventImpactComponent:
	if country == null:
		return null

	var existing = country.get_component(
		IMPACT_COMPONENT_TYPE
	)

	if existing is ExternalEventImpactComponent:
		return existing

	if existing != null:
		return null

	var component := ExternalEventImpactComponent.new(
		country.id
	)

	country.add_component(component)

	return component


func get_impact_component(
	country
) -> ExternalEventImpactComponent:
	if country == null:
		return null

	var component = country.get_component(
		IMPACT_COMPONENT_TYPE
	)

	if component is ExternalEventImpactComponent:
		return component

	return null


# ============================================================
# DIRECT EVENT CREATION HELPER
# ============================================================
#
# Convenience method for controlled tests and later action/event
# producers. It queues first; process_month performs the mutation.
# ============================================================

func create_external_event(
	world: WorldState,
	actor_id: String,
	event_id: String,
	event_name: String,
	event_category: String,
	description: String,
	target_impacts: Dictionary,
	priority: int = 0
) -> bool:
	return queue_external_event(
		world,
		actor_id,
		event_id,
		event_name,
		event_category,
		description,
		target_impacts,
		priority
	)
