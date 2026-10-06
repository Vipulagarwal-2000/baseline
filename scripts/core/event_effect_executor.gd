class_name EventEffectExecutor
extends RefCounted


# ============================================================
# E7 — EFFECT EXECUTION
# ============================================================
#
# Responsibility:
#   Execute validated EventEffect data against authoritative
#   component state.
#
# This layer is the first generic event layer permitted to mutate
# WorldState. E6 remains the declarative data model.
#
# Path contract is shared with E5:
#   <component>.<state_key>[.<nested_dictionary_key>...]
#
# Example:
#   government.stability
# ============================================================


# ============================================================
# SINGLE EFFECT EXECUTION
# ============================================================

static func execute(
	effect: EventEffect,
	world: WorldState,
	target_id: String
) -> bool:

	if effect == null or not effect.is_valid():
		return false

	if world == null:
		return false

	var normalized_target_id := target_id.strip_edges()
	if normalized_target_id.is_empty():
		return false

	var target: SimEntity = world.get_entity(normalized_target_id) as SimEntity
	if target == null:
		return false

	var resolved := _resolve_target(
		target,
		effect.path
	)

	if not bool(resolved.get("found", false)):
		return false

	var component = resolved.get("component")
	var state_key: String = str(resolved.get("state_key", ""))
	var nested_segments: Array = resolved.get("nested_segments", [])
	var current = resolved.get("value")

	if component == null or state_key.is_empty():
		return false

	var result := _calculate_result(
		effect,
		current
	)

	if not bool(result.get("valid", false)):
		return false

	var next_value = result.get("value")

	if nested_segments.is_empty():
		component.set_state(
			state_key,
			next_value
		)
		return true

	if typeof(current) != TYPE_DICTIONARY:
		return false

	var root_value: Dictionary = current.duplicate(true)
	if not _set_nested_value(
		root_value,
		nested_segments,
		next_value
	):
		return false

	component.set_state(
		state_key,
		root_value
	)

	return true


# ============================================================
# MULTIPLE EFFECTS
# ============================================================
#
# Validate every effect and every target path before mutating any
# state. This prevents a later invalid effect from leaving earlier
# effects partially applied.

static func execute_effects(
	effects: Array,
	world: WorldState,
	target_id: String
) -> bool:

	if world == null:
		return false

	var normalized_target_id := target_id.strip_edges()
	if normalized_target_id.is_empty():
		return false

	if effects.is_empty():
		return true

	var target: SimEntity = world.get_entity(normalized_target_id) as SimEntity
	if target == null:
		return false

	for effect in effects:
		if effect == null or not (effect is EventEffect):
			return false
		if not effect.is_valid():
			return false
		if not _can_execute(
				effect,
				target
			):
			return false

	for effect in effects:
		if not execute(
				effect,
				world,
				normalized_target_id
			):
			return false

	return true


# ============================================================
# EXECUTION VALIDATION
# ============================================================

static func _can_execute(
	effect: EventEffect,
	target: SimEntity
) -> bool:

	if effect == null or target == null:
		return false

	var resolved := _resolve_target(
		target,
		effect.path
	)

	if not bool(resolved.get("found", false)):
		return false

	var result := _calculate_result(
		effect,
		resolved.get("value")
	)

	return bool(result.get("valid", false))


static func _calculate_result(
	effect: EventEffect,
	current_value
) -> Dictionary:

	if effect == null or not effect.is_valid():
		return {
			"valid": false,
			"value": null
		}

	match effect.operation:
		EventEffect.OPERATION_SET:
			return {
				"valid": true,
				"value": _copy_value(effect.value)
			}

		EventEffect.OPERATION_ADD:
			if not _is_numeric(current_value):
				return {"valid": false, "value": null}
			return {
				"valid": true,
				"value": float(current_value) + float(effect.value)
			}

		EventEffect.OPERATION_SUBTRACT:
			if not _is_numeric(current_value):
				return {"valid": false, "value": null}
			return {
				"valid": true,
				"value": float(current_value) - float(effect.value)
			}

		EventEffect.OPERATION_MULTIPLY:
			if not _is_numeric(current_value):
				return {"valid": false, "value": null}
			return {
				"valid": true,
				"value": float(current_value) * float(effect.value)
			}

	return {
		"valid": false,
		"value": null
	}


# ============================================================
# AUTHORITATIVE PATH RESOLUTION
# ============================================================

static func _resolve_target(
	target: SimEntity,
	path: String
) -> Dictionary:

	if target == null:
		return {"found": false}

	var normalized_path := path.strip_edges()
	if normalized_path.is_empty():
		return {"found": false}

	var segments := normalized_path.split(".", false)
	if segments.size() < 2:
		return {"found": false}

	var component_name := str(segments[0]).strip_edges()
	var state_key := str(segments[1]).strip_edges()

	if component_name.is_empty() or state_key.is_empty():
		return {"found": false}

	var component = target.get_component(component_name)
	if component == null:
		return {"found": false}

	var component_state = component.state
	if typeof(component_state) != TYPE_DICTIONARY:
		return {"found": false}

	if not component_state.has(state_key):
		return {"found": false}

	var current = component_state[state_key]
	var nested_segments: Array = []

	for index in range(2, segments.size()):
		if typeof(current) != TYPE_DICTIONARY:
			return {"found": false}

		var nested_key := str(segments[index]).strip_edges()
		if nested_key.is_empty() or not current.has(nested_key):
			return {"found": false}

		nested_segments.append(nested_key)
		current = current[nested_key]

	return {
		"found": true,
		"component": component,
		"state_key": state_key,
		"nested_segments": nested_segments,
		"value": current
	}


# ============================================================
# NESTED DICTIONARY WRITE
# ============================================================

static func _set_nested_value(
	root: Dictionary,
	segments: Array,
	new_value
) -> bool:

	if segments.is_empty():
		return false

	var current: Dictionary = root

	for index in range(segments.size() - 1):
		var key := str(segments[index])
		if not current.has(key):
			return false

		var next_value = current[key]
		if typeof(next_value) != TYPE_DICTIONARY:
			return false

		next_value = next_value.duplicate(true)
		current[key] = next_value
		current = next_value

	current[str(segments[segments.size() - 1])] = _copy_value(
		new_value
	)

	return true


# ============================================================
# VALUE HELPERS
# ============================================================

static func _is_numeric(value) -> bool:
	return typeof(value) in [
		TYPE_INT,
		TYPE_FLOAT,
	]


static func _copy_value(value):
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
