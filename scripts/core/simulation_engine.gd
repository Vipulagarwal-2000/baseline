class_name SimulationEngine
extends RefCounted


# ============================================================
# CORE REFERENCES
# ============================================================

var world: WorldState
var config: SimulationConfig

var system_manager: SystemManager
var action_manager: ActionManager
var snapshot_manager: SnapshotManager
var technology_manager: TechnologyManager
var divergence_analyzer: DivergenceAnalyzer


# ============================================================
# INITIALIZATION
# ============================================================

func _init(world_state: WorldState):

	world = world_state

	if world == null:
		push_error(
			"SimulationEngine: WorldState is null."
		)
		return

	config = world.config

	system_manager = SystemManager.new()
	action_manager = ActionManager.new(world)
	_register_action_manager()
	_register_event_integration()
	snapshot_manager = SnapshotManager.new()
	technology_manager = TechnologyManager.new()
	divergence_analyzer = DivergenceAnalyzer.new()


# ============================================================
# SYSTEM MANAGEMENT
# ============================================================

func register_system(
	system: SimulationSystem,
	phase = SimulationPhase.WORLD_UPDATE,
	order: int = 100
) -> void:

	if system == null:
		push_error(
			"SimulationEngine: Cannot register null system."
		)
		return

	if system_manager == null:
		push_error(
			"SimulationEngine: SystemManager is null."
		)
		return

	system_manager.register_system(
		system,
		phase,
		order
	)


func get_system_count() -> int:

	if system_manager == null:
		return 0

	return system_manager.get_system_count()


func get_system_order() -> Array:

	if system_manager == null:
		return []

	return system_manager.get_system_order()


func get_system(system_name: String):

	if system_manager == null:
		return null

	return system_manager.get_system(
		system_name
	)


# ============================================================
# TECHNOLOGY MANAGER
# ============================================================

func get_technology_manager() -> TechnologyManager:

	return technology_manager


# ============================================================
# ACTION SYSTEM REGISTRATION
# ============================================================

func _register_action_manager() -> void:
	if action_manager == null:
		push_error(
			"SimulationEngine: Cannot register null ActionManager."
		)
		return

	if system_manager == null:
		push_error(
			"SimulationEngine: Cannot register ActionManager because SystemManager is null."
		)
		return

	system_manager.register_system(
		action_manager,
		SimulationPhase.ACTIONS,
		10
	)


# ============================================================
# E13 — EVENT SIMULATION INTEGRATION REGISTRATION
# ============================================================
#
# Registers the E13 interaction layer with the existing authoritative
# EVENTS phase. It does not alter tick sequencing or create a second
# event execution engine.
# ============================================================

func _register_event_integration() -> void:
	if system_manager == null:
		push_error(
			"SimulationEngine: Cannot register EventSimulationIntegrationSystem because SystemManager is null."
		)
		return

	var event_integration: EventSimulationIntegrationSystem = (
		EventSimulationIntegrationSystem.new()
	)

	system_manager.register_system(
		event_integration,
		SimulationPhase.EVENTS,
		10
	)


# ============================================================
# ACTION MANAGEMENT
# ============================================================

func add_action(action) -> bool:

	if action_manager == null:
		return false

	if action == null:
		return false

	return action_manager.add_action(
		action,
		world
	)

# ============================================================
# STEP 15.14 — PLAYER ACTION ISSUANCE
# ============================================================
#
# This is the single player-facing action issuance path.
#
# The method deliberately stops at ActionManager admission. It does
# not execute actions, advance time, mutate domain state, or create a
# second execution engine. Player-issued actions therefore enter the
# exact same validation / reservation / queue / ACTIONS-phase machinery
# already used by AI and internal action callers.
# ============================================================

func issue_player_action(
	actor_id: String,
	decision: DecisionOption,
	start_date_override: String = ""
) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"action": null,
		"actor_id": actor_id,
		"option_id": "" if decision == null else decision.id,
		"failure_reason": ""
	}

	if world == null:
		result["failure_reason"] = (
			"Player action issuance failed: world context is required."
		)
		return result

	if action_manager == null:
		result["failure_reason"] = (
			"Player action issuance failed: ActionManager is unavailable."
		)
		return result

	if actor_id.strip_edges().is_empty():
		result["failure_reason"] = (
			"Player action issuance failed: actor is required."
		)
		return result

	if not world.has_entity(actor_id):
		result["failure_reason"] = (
			"Player action issuance failed: actor does not exist: "
			+ actor_id
		)
		return result

	if decision == null:
		result["failure_reason"] = (
			"Player action issuance failed: decision option is required."
		)
		return result

	if not decision.is_available():
		result["failure_reason"] = (
			"Player action issuance failed: decision is unavailable."
		)
		return result

	if decision.actor_id.strip_edges().is_empty():
		result["failure_reason"] = (
			"Player action issuance failed: decision actor is required."
		)
		return result

	if decision.actor_id != actor_id:
		result["failure_reason"] = (
			"Player action issuance failed: decision actor does not match the issuing actor."
		)
		return result

	var action: SimAction = decision.to_executable_action(
		start_date_override
	)
	if action == null:
		result["failure_reason"] = (
			"Player action issuance failed: decision did not produce an action."
		)
		return result

	if action.actor_id != actor_id:
		result["failure_reason"] = (
			"Player action issuance failed: converted action actor does not match the issuing actor."
		)
		return result

	var admitted: bool = add_action(action)
	result["action"] = action

	if not admitted:
		result["failure_reason"] = action.failure_reason
		if str(result["failure_reason"]).is_empty():
			result["failure_reason"] = (
				"Player action issuance failed: ActionManager rejected the action."
			)
		return result

	result["success"] = true
	return result


# ============================================================
# STEP 15.15 — AI ACTION ISSUANCE
# ============================================================
#
# Converts the decision already selected by the registered
# AIDecisionSystem into the same executable action contract used by
# the player path. No AI-specific execution engine is introduced.
# Admission still flows through SimulationEngine.add_action() and the
# registered ActionManager.
# ============================================================

func issue_ai_action(
	actor_id: String,
	start_date_override: String = ""
) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"action": null,
		"actor_id": actor_id,
		"option_id": "",
		"failure_reason": ""
	}

	if world == null:
		result["failure_reason"] = (
			"AI action issuance failed: world context is required."
		)
		return result

	if action_manager == null:
		result["failure_reason"] = (
			"AI action issuance failed: ActionManager is unavailable."
		)
		return result

	if actor_id.strip_edges().is_empty():
		result["failure_reason"] = (
			"AI action issuance failed: actor is required."
		)
		return result

	var actor: SimEntity = world.get_entity(actor_id)
	if actor == null:
		result["failure_reason"] = (
			"AI action issuance failed: actor does not exist: "
			+ actor_id
		)
		return result

	if system_manager == null:
		result["failure_reason"] = (
			"AI action issuance failed: SystemManager is unavailable."
		)
		return result

	var ai_system_value: Variant = system_manager.get_system(
		"ai_decision_system"
	)
	if not ai_system_value is AIDecisionSystem:
		result["failure_reason"] = (
			"AI action issuance failed: registered AI decision system is unavailable."
		)
		return result

	var ai_system: AIDecisionSystem = ai_system_value as AIDecisionSystem
	var decision: DecisionOption = (
		ai_system.get_selected_decision(actor)
		as DecisionOption
	)

	if decision == null:
		result["failure_reason"] = (
			"AI action issuance failed: no selected decision exists."
		)
		return result

	result["option_id"] = decision.id

	if not decision.is_available():
		result["failure_reason"] = (
			"AI action issuance failed: selected decision is unavailable."
		)
		return result

	if decision.actor_id != actor_id:
		result["failure_reason"] = (
			"AI action issuance failed: selected decision actor does not match the issuing actor."
		)
		return result

	var action: SimAction = ai_system.get_selected_action(
		actor,
		start_date_override
	)

	if action == null:
		result["failure_reason"] = (
			"AI action issuance failed: selected decision did not produce an action."
		)
		return result

	if action.actor_id != actor_id:
		result["failure_reason"] = (
			"AI action issuance failed: converted action actor does not match the issuing actor."
		)
		return result

	var admitted: bool = add_action(action)
	result["action"] = action

	if not admitted:
		result["failure_reason"] = action.failure_reason
		if str(result["failure_reason"]).is_empty():
			result["failure_reason"] = (
				"AI action issuance failed: ActionManager rejected the action."
			)
		return result

	ai_system.clear_selected_decision(actor)
	result["success"] = true
	return result



func get_pending_action_count() -> int:

	if action_manager == null:
		return 0

	return action_manager.get_pending_count()


func get_pending_actions() -> Array:

	if action_manager == null:
		return []

	return action_manager.pending_actions


# ============================================================
# BASELINE
# ============================================================

func capture_baseline() -> WorldSnapshot:

	if world == null:
		push_error(
			"SimulationEngine: Cannot capture baseline because world is null."
		)
		return null

	if snapshot_manager == null:
		push_error(
			"SimulationEngine: Cannot capture baseline because snapshot_manager is null."
		)
		return null

	var baseline_snapshot: WorldSnapshot = snapshot_manager.capture_baseline(
		world
	)

	_attach_action_snapshot_state(baseline_snapshot)
	return baseline_snapshot


func get_baseline_snapshot():

	if snapshot_manager == null:
		return null

	return snapshot_manager.get_baseline_snapshot()


# ============================================================
# SNAPSHOTS
# ============================================================

func capture_snapshot() -> void:

	if snapshot_manager == null:
		return

	if world == null:
		return

	snapshot_manager.capture_world(
		world
	)

	var latest_snapshot: WorldSnapshot = snapshot_manager.get_latest_snapshot()
	_attach_action_snapshot_state(latest_snapshot)


func _attach_action_snapshot_state(
	snapshot: WorldSnapshot
	) -> void:
	if snapshot == null or action_manager == null:
		return

	snapshot.set_action_snapshot_state(
		action_manager.capture_snapshot_state()
	)


func get_action_snapshot_state(
	index: int = -1
	) -> Dictionary:
	var snapshot: WorldSnapshot = _get_snapshot_by_index(index)
	if snapshot == null:
		return {}

	return snapshot.get_action_snapshot_state()


func restore_action_snapshot_state(
	index: int = -1
	) -> bool:
	if action_manager == null:
		return false

	var snapshot: WorldSnapshot = _get_snapshot_by_index(index)
	if snapshot == null:
		return false

	var state: Dictionary = snapshot.get_action_snapshot_state()
	if state.is_empty():
		return false

	return action_manager.restore_snapshot_state(
		state,
		world
	)


func _get_snapshot_by_index(
	index: int
	) -> WorldSnapshot:
	if snapshot_manager == null:
		return null

	var count: int = snapshot_manager.get_snapshot_count()
	if count <= 0:
		return null

	var resolved_index: int = index
	if resolved_index < 0:
		resolved_index = count - 1

	if resolved_index < 0 or resolved_index >= count:
		return null

	return snapshot_manager.get_snapshot(resolved_index)


func get_latest_snapshot():

	if snapshot_manager == null:
		return null

	return snapshot_manager.get_latest_snapshot()


func get_snapshot(index: int):

	if snapshot_manager == null:
		return null

	return snapshot_manager.get_snapshot(
		index
	)


func get_snapshot_count() -> int:

	if snapshot_manager == null:
		return 0

	return snapshot_manager.get_snapshot_count()


func get_snapshots() -> Array:

	if snapshot_manager == null:
		return []

	var result: Array = []

	var count: int = snapshot_manager.get_snapshot_count()

	for index in range(count):

		var snapshot: WorldSnapshot = snapshot_manager.get_snapshot(
			index
		)

		if snapshot != null:
			result.append(snapshot)

	return result


# ============================================================
# DIVERGENCE ANALYSIS
# ============================================================

func analyze_divergence() -> Dictionary:

	var result: Dictionary = {
		"baseline_date": {},
		"current_date": {},
		"entities": {}
	}

	if snapshot_manager == null:
		push_error(
			"SimulationEngine: SnapshotManager is null."
		)
		return result

	if divergence_analyzer == null:
		divergence_analyzer = DivergenceAnalyzer.new()


	var baseline: WorldSnapshot = snapshot_manager.get_baseline_snapshot()
	var current: WorldSnapshot = snapshot_manager.get_latest_snapshot()


	if baseline == null:
		push_error(
			"SimulationEngine: Baseline snapshot is null."
		)
		return result


	if current == null:
		push_error(
			"SimulationEngine: Current snapshot is null."
		)
		return result


	return divergence_analyzer.analyze_world(
		baseline,
		current
	)


# ============================================================
# SIMULATION TICK
# ============================================================

func tick_month() -> void:

	if world == null:
		push_error(
			"SimulationEngine: Cannot tick without a world."
		)
		return


	# ========================================================
	# PRE-SIMULATION
	# ========================================================

	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.PRE_SIMULATION
		)


	# ========================================================
	# ADVANCE TIME
	# ========================================================

	world.advance_month()


	# ========================================================
	# WORLD UPDATE
	# ========================================================

	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.WORLD_UPDATE
		)


	# ========================================================
	# ACTIONS
	# ========================================================

	# ActionManager is registered as the authoritative ACTIONS-phase
	# system during engine initialization. Do not call it directly here.
	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.ACTIONS
		)


	# ========================================================
	# AI FEEDBACK
	# ========================================================

	process_action_feedback()


	# ========================================================
	# EVENTS
	# ========================================================

	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.EVENTS
		)


	# ========================================================
	# DECISIONS
	# ========================================================

	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.DECISIONS
		)

	# Step 17.2 — convert each AI decision selected during the DECISIONS
	# phase into the existing executable action contract. The action is
	# intentionally admitted after DECISIONS, so the registered ACTIONS
	# phase resolves it on the following monthly tick. This preserves the
	# existing authoritative ActionManager path and gives the AI a real
	# changing-world feedback cycle.
	process_ai_action_issuance()


	# ========================================================
	# POST-SIMULATION
	# ========================================================

	if system_manager != null:

		system_manager.process_phase(
			world,
			SimulationPhase.POST_SIMULATION
		)


	# ========================================================
	# SNAPSHOT
	# ========================================================

	capture_snapshot()


# ============================================================
# STEP 15.13 — ACTION OUTCOME → AI FEEDBACK
# ============================================================

func process_action_feedback() -> Dictionary:
	var result: Dictionary = {
		"outcomes_considered": 0,
		"memory_records_added": 0,
		"trajectory_records_added": 0
	}

	if action_manager == null or system_manager == null:
		return result

	var outcomes: Array = action_manager.get_outcome_history()
	var memory_system = system_manager.get_system("ai_memory_system")
	var trajectory_system = system_manager.get_system("decision_trajectory_system")

	for outcome_variant in outcomes:
		if typeof(outcome_variant) != TYPE_DICTIONARY:
			continue

		var outcome: Dictionary = outcome_variant
		var status: String = str(outcome.get("status", ""))
		if not _is_ai_feedback_eligible_status(status):
			continue

		result["outcomes_considered"] = int(result["outcomes_considered"]) + 1

		if memory_system is AIMemorySystem:
			var memory_recorded: bool = memory_system.record_action_outcome_memory(world, outcome)
			if memory_recorded:
				result["memory_records_added"] = int(result["memory_records_added"]) + 1

		if trajectory_system is DecisionTrajectorySystem:
			var trajectory_record_count: int = trajectory_system.record_action_outcome_feedback(world, outcome)
			result["trajectory_records_added"] = int(result["trajectory_records_added"]) + trajectory_record_count

	return result


func _is_ai_feedback_eligible_status(status: String) -> bool:
	return (
		status == SimAction.STATE_COMPLETED
		or status == SimAction.STATE_FAILED
		or status == SimAction.STATE_CANCELLED
		or status == SimAction.STATE_INTERRUPTED
	)


# ============================================================
# STEP 17.2 — AI ACTION ISSUANCE
# ============================================================

func process_ai_action_issuance() -> Dictionary:
	var result: Dictionary = {
		"actors_considered": 0,
		"actions_issued": 0,
		"actions_rejected": 0
	}

	if world == null or system_manager == null:
		return result

	var ai_system_value: Variant = system_manager.get_system(
		"ai_decision_system"
	)

	if not ai_system_value is AIDecisionSystem:
		return result

	var ai_system: AIDecisionSystem = ai_system_value as AIDecisionSystem

	for entity_variant in world.entities.values():
		if entity_variant == null:
			continue

		if entity_variant.entity_type != "country":
			continue

		var actor: SimEntity = entity_variant as SimEntity
		if actor == null:
			continue

		result["actors_considered"] = int(result["actors_considered"]) + 1

		var selected_decision: Variant = ai_system.get_selected_decision(
			actor
		)

		if selected_decision == null:
			continue

		if not selected_decision is DecisionOption:
			continue

		var issuance_result: Dictionary = issue_ai_action(
			actor.id,
			world.get_date_string()
		)

		if bool(issuance_result.get("success", false)):
			result["actions_issued"] = int(result["actions_issued"]) + 1
		else:
			result["actions_rejected"] = int(result["actions_rejected"]) + 1

	return result


# WORLD ACCESS
# ============================================================

func get_world() -> WorldState:

	return world


func get_config() -> SimulationConfig:

	return config


# ============================================================
# ENGINE STATUS
# ============================================================

func is_ready() -> bool:

	return (
		world != null
		and system_manager != null
		and action_manager != null
		and snapshot_manager != null
		and technology_manager != null
		and divergence_analyzer != null
	)
