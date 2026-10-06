class_name EventSimulationIntegrationSystem
extends SimulationSystem


# ============================================================
# E13 — SIMULATION INTEGRATION
# ============================================================
#
# Monthly boundary:
#
# WORLD_UPDATE
#      ↓
# ACTIONS
#      ↓
# EVENTS
#      ↓
# EventSimulationIntegrationSystem
#      ↓
# EventTriggerEvaluator
#      ↓
# EventExecutor
#      ↓
# EventResult
#      ↓
# EventHistoryBridge
#      ↓
# history sink
#
# This is deliberately an interaction layer.
# It does not replace:
# - SimulationEngine
# - ActionManager
# - EventExecutor
# - EventTriggerEvaluator
# - HistorySystem
#
# Event definitions currently remain the E8/E9 minimum models.
# Conditions/effects are registered explicitly at runtime because the
# current EventDefinition JSON schema intentionally does not yet contain
# those fields.
# ============================================================


var _registrations: Array = []
var _repeatability: EventRepeatabilityController = (
	EventRepeatabilityController.new()
)
var _history_sink: Object = null
var _last_results: Array = []
var _processed_month_count: int = 0


func _init() -> void:
	super("event_simulation_integration")


# ============================================================
# REGISTRATION
# ============================================================

func register_event(
	event_definition: EventDefinition,
	conditions: Array,
	effects: Array,
	target_ids: Array,
	repeatability_policy: EventRepeatabilityPolicy = null
) -> bool:

	if event_definition == null:
		return false

	if event_definition.id.strip_edges().is_empty():
		return false

	if conditions == null:
		return false

	if effects == null:
		return false

	if target_ids == null or target_ids.is_empty():
		return false

	var normalized_targets: Array[String] = []

	for target_value in target_ids:
		var target_id: String = str(target_value).strip_edges()
		if target_id.is_empty():
			return false
		normalized_targets.append(target_id)

	normalized_targets.sort()

	var policy: EventRepeatabilityPolicy = repeatability_policy

	if policy == null:
		policy = EventRepeatabilityPolicy.repeatable()

	if not policy.is_valid():
		return false

	_registrations.append({
		"definition": event_definition,
		"conditions": conditions.duplicate(true),
		"effects": effects.duplicate(true),
		"targets": normalized_targets,
		"policy": policy,
	})

	_sort_registrations()
	return true


func clear_registrations() -> void:
	_registrations.clear()


func get_registration_count() -> int:
	return _registrations.size()


# ============================================================
# HISTORY SINK
# ============================================================

func set_history_sink(
	history_sink: Object
) -> void:
	_history_sink = history_sink


func get_history_sink() -> Object:
	return _history_sink


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	_last_results.clear()
	_processed_month_count += 1

	if world == null:
		return

	# Deterministic registration ordering is already established.
	for registration in _registrations:
		if typeof(registration) != TYPE_DICTIONARY:
			continue

		var definition: EventDefinition = (
			registration.get("definition")
			as EventDefinition
		)

		var conditions: Array = registration.get(
			"conditions",
			[]
		)

		var effects: Array = registration.get(
			"effects",
			[]
		)

		var targets: Array = registration.get(
			"targets",
			[]
		)

		var policy: EventRepeatabilityPolicy = (
			registration.get("policy")
			as EventRepeatabilityPolicy
		)

		if definition == null:
			continue

		var target_ids: Array[String] = []

		for target_value in targets:
			target_ids.append(
				str(target_value).strip_edges()
			)

		target_ids.sort()

		for target_id in target_ids:
			_process_event_target(
				world,
				definition,
				conditions,
				effects,
				target_id,
				policy
			)


func _process_event_target(
	world: WorldState,
	definition: EventDefinition,
	conditions: Array,
	effects: Array,
	target_id: String,
	policy: EventRepeatabilityPolicy
) -> void:

	var current_tick: int = _get_current_tick(world)

	if not _repeatability.can_fire(
		policy,
		definition.id,
		target_id,
		current_tick
	):
		return

	var result: EventResult = EventExecutor.execute(
		definition,
		conditions,
		effects,
		world,
		target_id
	)

	if result == null:
		return

	result.set_context(
		current_tick,
		world.get_date_string(),
		"event_simulation"
	)

	# E11 restrictions are consumed only by an actually executed event.
	if result.is_successful():
		_repeatability.record_fire(
			policy,
			definition.id,
			target_id,
			current_tick
		)

	# E12 output boundary.
	if _history_sink != null:
		EventHistoryBridge.record_result(
			_history_sink,
			result
		)

	_last_results.append(
		result.to_dict().duplicate(true)
	)


# ============================================================
# RESULTS / DIAGNOSTICS
# ============================================================

func get_last_results() -> Array:
	return _last_results.duplicate(true)


func get_last_result_count() -> int:
	return _last_results.size()


func get_processed_month_count() -> int:
	return _processed_month_count


func get_repeatability_controller() -> EventRepeatabilityController:
	return _repeatability


# ============================================================
# DETERMINISTIC TICK KEY
# ============================================================

func _get_current_tick(
	world: WorldState
) -> int:

	if world == null:
		return _processed_month_count - 1

	return world.get_elapsed_months()


# ============================================================
# REGISTRATION ORDER
# ============================================================

func _sort_registrations() -> void:
	_registrations.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_definition: EventDefinition = (
				left.get("definition")
				as EventDefinition
			)
			var right_definition: EventDefinition = (
				right.get("definition")
				as EventDefinition
			)

			if left_definition == null:
				return false

			if right_definition == null:
				return true

			return left_definition.id < right_definition.id
	)
