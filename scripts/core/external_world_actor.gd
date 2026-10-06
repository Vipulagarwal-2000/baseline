class_name ExternalWorldActor
extends SimEntity


# ============================================================
# STEP 10.2 — EXTERNAL ACTOR REPRESENTATION
# ============================================================
#
# A lightweight world entity for important external actors.
# It is intentionally not a Country and does not receive the
# fully simulated country component stack.
# ============================================================

const ENTITY_TYPE: String = "external_actor"
const COMPONENT_TYPE: String = "external_world_actor"


func _init(
	actor_id: String,
	actor_name: String
) -> void:
	super._init(
		actor_id,
		actor_name,
		ENTITY_TYPE
	)

	add_component(
		ExternalWorldActorComponent.new(actor_id)
	)


func get_external_actor_component() -> ExternalWorldActorComponent:
	var component = get_component(
		COMPONENT_TYPE
	)

	if component is ExternalWorldActorComponent:
		return component

	return null


func set_resource_status(
	resource_id: String,
	status
) -> void:
	var component = get_external_actor_component()
	if component == null:
		return

	component.set_resource_status(
		resource_id,
		status
	)


func get_resource_status(
	resource_id: String,
	default_value = null
):
	var component = get_external_actor_component()
	if component == null:
		return default_value

	return component.get_resource_status(
		resource_id,
		default_value
	)


func set_strategic_status(
	key: String,
	value
) -> void:
	var component = get_external_actor_component()
	if component == null:
		return

	component.set_strategic_status(
		key,
		value
	)


func get_strategic_status(
	key: String,
	default_value = null
):
	var component = get_external_actor_component()
	if component == null:
		return default_value

	return component.get_strategic_status(
		key,
		default_value
	)


func set_trade_capacity(
	resource_id: String,
	monthly_capacity: float
) -> void:
	var component = get_external_actor_component()
	if component == null:
		return

	component.set_trade_capacity(
		resource_id,
		monthly_capacity
	)


func get_trade_capacity(
	resource_id: String,
	default_value: float = 0.0
) -> float:
	var component = get_external_actor_component()
	if component == null:
		return default_value

	return component.get_trade_capacity(
		resource_id,
		default_value
	)


func set_event_state(
	key: String,
	value
) -> void:
	var component = get_external_actor_component()
	if component == null:
		return

	component.set_event_state(
		key,
		value
	)


func get_event_state(
	key: String,
	default_value = null
):
	var component = get_external_actor_component()
	if component == null:
		return default_value

	return component.get_event_state(
		key,
		default_value
	)


func is_lightweight_representation() -> bool:
	const FORBIDDEN_COUNTRY_COMPONENTS: Array[String] = [
		"population",
		"economy",
		"government",
		"resources",
		"research",
		"technology_adoption",
		"industry",
		"infrastructure",
		"military",
		"geography",
		"production_process"
	]

	if entity_type != ENTITY_TYPE:
		return false

	if get_external_actor_component() == null:
		return false

	for component_name in FORBIDDEN_COUNTRY_COMPONENTS:
		if has_component(component_name):
			return false

	return true
