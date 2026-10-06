class_name EventTriggerEvaluator
extends RefCounted


# ============================================================
# E5 — EVENT TRIGGER EVALUATION
# ============================================================
#
# Responsibility:
#   Answer only whether an event is currently eligible to fire.
#
# This layer bridges:
#   EventCondition
#       ↓
#   authoritative world-state read
#       ↓
#   EventConditionEvaluator
#       ↓
#   eligible / not eligible
#
# It deliberately does NOT:
# - execute effects
# - mutate WorldState
# - record history
# - start cooldowns
# - evaluate choices
# - advance simulation time
#
# Current path contract:
#   <component>.<state_key>[.<nested_dictionary_key>...]
#
# Example:
#   government.stability
#
# The first path segment identifies an existing SimComponent on the
# target entity. The remaining segments are resolved through that
# component's authoritative state dictionary.
#
# Top-level condition arrays are interpreted as AND. More complex
# composition must use EventCondition's AND / OR / NOT tree from E4.4.
# ============================================================


# ============================================================
# PUBLIC ENTRY POINT — SINGLE CONDITION
# ============================================================

static func evaluate(
	event_definition: EventDefinition,
	condition: EventCondition,
	world: WorldState,
	target_id: String
) -> bool:

	if not _is_valid_event_definition(event_definition):
		return false

	if world == null:
		return false

	if condition == null:
		return false

	if target_id.strip_edges().is_empty():
		return false

	var target: SimEntity = world.get_entity(target_id) as SimEntity
	if target == null:
		return false

	return _evaluate_condition(
		condition,
		target
	)


# ============================================================
# PUBLIC ENTRY POINT — MULTIPLE TOP-LEVEL CONDITIONS
# ============================================================

static func evaluate_conditions(
	event_definition: EventDefinition,
	conditions: Array,
	world: WorldState,
	target_id: String
) -> bool:

	if not _is_valid_event_definition(event_definition):
		return false

	if world == null:
		return false

	if target_id.strip_edges().is_empty():
		return false

	var target: SimEntity = world.get_entity(target_id) as SimEntity
	if target == null:
		return false

	# No declared condition means there is no blocking condition at
	# this layer. This is useful for future unconditional event
	# definitions without introducing execution behavior here.
	if conditions.is_empty():
		return true

	for condition in conditions:
		if condition == null:
			return false
		if not (condition is EventCondition):
			return false
		if not _evaluate_condition(condition, target):
			return false

	return true


# ============================================================
# CONDITION TREE EVALUATION
# ============================================================

static func _evaluate_condition(
	condition: EventCondition,
	target: SimEntity
) -> bool:

	if condition == null or target == null:
		return false

	if not condition.is_valid():
		return false

	if condition.is_logical_condition():
		return _evaluate_logical_condition(
			condition,
			target
		)

	return _evaluate_leaf_condition(
		condition,
		target
	)


static func _evaluate_logical_condition(
	condition: EventCondition,
	target: SimEntity
) -> bool:

	if not condition.is_valid_logical_structure():
		return false

	var child_results: Array = []

	for child_condition in condition.conditions:
		if child_condition == null:
			return false

		if not (child_condition is EventCondition):
			return false

		child_results.append(
			_evaluate_condition(
				child_condition,
				target
			)
		)

	return EventConditionEvaluator.evaluate_logical(
		condition.logical_operator,
		child_results
	)


static func _evaluate_leaf_condition(
	condition: EventCondition,
	target: SimEntity
) -> bool:

	if condition.is_logical_condition():
		return false

	var resolved := _resolve_path(
		target,
		condition.path
	)

	if not bool(resolved.get("found", false)):
		return false

	return EventConditionEvaluator.evaluate(
		condition,
		resolved.get("value")
	)


# ============================================================
# AUTHORITATIVE PATH RESOLUTION
# ============================================================

static func _resolve_path(
	target: SimEntity,
	path: String
) -> Dictionary:

	if target == null:
		return {
			"found": false,
			"value": null
		}

	var normalized_path := path.strip_edges()
	if normalized_path.is_empty():
		return {
			"found": false,
			"value": null
		}

	var segments := normalized_path.split(".", false)
	if segments.size() < 2:
		return {
			"found": false,
			"value": null
		}

	var component_name := str(segments[0]).strip_edges()
	if component_name.is_empty():
		return {
			"found": false,
			"value": null
		}

	var component = target.get_component(component_name)
	if component == null:
		return {
			"found": false,
			"value": null
		}

	var state_key := str(segments[1]).strip_edges()
	if state_key.is_empty():
		return {
			"found": false,
			"value": null
		}

	# SimComponent exposes its authoritative state dictionary. Use
	# dictionary membership to distinguish a missing state key from a
	# legitimate value (including null) without comparing unrelated
	# Variant types such as float and Object.
	var component_state = component.state
	if typeof(component_state) != TYPE_DICTIONARY:
		return {
			"found": false,
			"value": null
		}

	if not component_state.has(state_key):
		return {
			"found": false,
			"value": null
		}

	var current = component_state[state_key]

	for index in range(2, segments.size()):
		if typeof(current) != TYPE_DICTIONARY:
			return {
				"found": false,
				"value": null
			}

		var nested_key := str(segments[index]).strip_edges()
		if nested_key.is_empty() or not current.has(nested_key):
			return {
				"found": false,
				"value": null
			}

		current = current[nested_key]

	return {
		"found": true,
		"value": current
	}


# ============================================================
# EVENT DEFINITION VALIDATION
# ============================================================

static func _is_valid_event_definition(
	event_definition: EventDefinition
) -> bool:

	if event_definition == null:
		return false

	return not event_definition.id.strip_edges().is_empty()
