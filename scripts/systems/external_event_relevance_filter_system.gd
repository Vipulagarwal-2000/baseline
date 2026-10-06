class_name ExternalEventRelevanceFilterSystem
extends SimulationSystem


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.5
# EXTERNAL EVENT RELEVANCE FILTERING
# ============================================================
#
# Filters externally originated causal-event packets before the
# Step 10.3 causality system materializes core-country consequences.
#
# Contract:
#   external event exists
#       -> relevance filter
#       -> only relevant core-country target impacts remain
#       -> Step 10.3 materializes those consequences
#
# This system does NOT:
#   - simulate external countries
#   - mutate core-country state
#   - create trade/resource transactions
#   - replace EventSynchronizer
#
# It only filters and records external-event relevance decisions.
# ============================================================

const PENDING_EVENT_KEY: String = "pending_causal_events"
const FILTER_STATE_KEY: String = "relevance_filter_state"
const FILTERED_EVENT_KEY: String = "filtered_causal_events"
const SUPPRESSED_EVENT_KEY: String = "suppressed_causal_events"

const ALLOWED_IMPACT_GROUPS: Array[String] = [
	"resource",
	"trade",
	"strategic"
]


func _init() -> void:
	super("external_event_relevance_filter")


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
# EVENT FILTERING
# ============================================================

func filter_pending_event(
	world: WorldState,
	actor: ExternalWorldActor,
	event_id: String
) -> bool:
	if world == null or actor == null:
		return false

	if event_id.is_empty():
		return false

	var pending = actor.get_event_state(
		PENDING_EVENT_KEY,
		{}
	)

	if typeof(pending) != TYPE_DICTIONARY:
		return false

	if not pending.has(event_id):
		return false

	var filtered = actor.get_event_state(
		FILTERED_EVENT_KEY,
		{}
	)

	if typeof(filtered) != TYPE_DICTIONARY:
		filtered = {}

	# A relevance decision is immutable for the queued event.
	if filtered.has(event_id):
		return true

	var packet = pending.get(event_id, {})

	if typeof(packet) != TYPE_DICTIONARY:
		return false

	var target_impacts = packet.get(
		"target_impacts",
		{}
	)

	if typeof(target_impacts) != TYPE_DICTIONARY:
		return false

	var relevant_targets: Dictionary = {}
	var filtered_targets: Array[String] = []
	var sanitized_target_ids: Array[String] = []

	for target_id_value in target_impacts.keys():
		var target_id = str(target_id_value)
		var impact = target_impacts[target_id_value]

		if target_id.is_empty() or typeof(impact) != TYPE_DICTIONARY:
			continue

		if not CoreCountryRegistry.is_core_country(target_id):
			filtered_targets.append(target_id)
			continue

		if not _is_relevant_impact(impact):
			filtered_targets.append(target_id)
			continue

		var sanitized_impact = _sanitize_impact(impact)

		if sanitized_impact.is_empty():
			filtered_targets.append(target_id)
			continue

		relevant_targets[target_id] = sanitized_impact
		sanitized_target_ids.append(target_id)

	sanitized_target_ids.sort()
	filtered_targets.sort()

	var filtered_packet = packet.duplicate(true)
	filtered_packet["target_impacts"] = relevant_targets
	filtered_packet["target_ids"] = sanitized_target_ids
	filtered_packet["relevance_filtered"] = true
	filtered_packet["filtered_target_ids"] = filtered_targets
	filtered_packet["filtered_date"] = world.current_date.duplicate(true)

	filtered[event_id] = filtered_packet

	actor.set_event_state(
		FILTERED_EVENT_KEY,
		filtered
	)

	var relevance_state = actor.get_event_state(
		FILTER_STATE_KEY,
		{}
	)

	if typeof(relevance_state) != TYPE_DICTIONARY:
		relevance_state = {}

	relevance_state["last_event_id"] = event_id
	relevance_state["last_relevant_target_ids"] = sanitized_target_ids.duplicate()
	relevance_state["last_filtered_target_ids"] = filtered_targets.duplicate()
	relevance_state["last_filtered_date"] = world.current_date.duplicate(true)

	actor.set_event_state(
		FILTER_STATE_KEY,
		relevance_state
	)

	if relevant_targets.is_empty():
		var suppressed = actor.get_event_state(
			SUPPRESSED_EVENT_KEY,
			{}
		)

		if typeof(suppressed) != TYPE_DICTIONARY:
			suppressed = {}

		suppressed[event_id] = filtered_packet.duplicate(true)

		actor.set_event_state(
			SUPPRESSED_EVENT_KEY,
			suppressed
		)

		# The event exists and is recorded, but no core-world consequence
		# should be materialized for an entirely irrelevant event.
		pending.erase(event_id)

	else:
		# Replace the original packet with the filtered packet. Step 10.3
		# consumes the remaining relevant target impacts only.
		pending[event_id] = filtered_packet

	actor.set_event_state(
		PENDING_EVENT_KEY,
		pending
	)

	return true


func _is_relevant_impact(
	impact: Dictionary
) -> bool:
	if impact.is_empty():
		return false

	if impact.has("relevant"):
		if not bool(impact.get("relevant", true)):
			return false

	if impact.has("relevance_score"):
		var score = clampf(
			float(impact.get("relevance_score", 0.0)),
			0.0,
			1.0
		)

		var threshold = clampf(
			float(impact.get("relevance_threshold", 0.5)),
			0.0,
			1.0
		)

		if score < threshold:
			return false

	return true


func _sanitize_impact(
	impact: Dictionary
) -> Dictionary:
	var sanitized: Dictionary = {}

	for group in ALLOWED_IMPACT_GROUPS:
		if not impact.has(group):
			continue

		var value = impact[group]

		if typeof(value) == TYPE_DICTIONARY:
			sanitized[group] = value.duplicate(true)
		else:
			sanitized[group] = value

	return sanitized


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
		filter_pending_event(
			world,
			actor,
			event_id
		)
