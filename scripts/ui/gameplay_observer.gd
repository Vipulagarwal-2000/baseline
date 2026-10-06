class_name GameplayObserver
extends RefCounted

## Step 20.3 — Minimal gameplay observation/read helper.
##
## This is a thin presentation read adapter. It never calculates or stores
## authoritative simulation values. Every value is read directly from the
## existing SimulationEngine / WorldState.

var simulation: SimulationEngine = null


func initialize(live_simulation: SimulationEngine) -> void:
	simulation = live_simulation


func is_available() -> bool:
	return simulation != null


func is_ready() -> bool:
	return simulation != null and simulation.is_ready()


func get_world() -> WorldState:
	if simulation == null:
		return null

	return simulation.get_world()


func get_date_string() -> String:
	var world := get_world()
	if world == null:
		return ""

	return world.get_date_string()


func get_entity_count() -> int:
	var world := get_world()
	if world == null:
		return 0

	return world.get_entity_count()


func get_country(country_id: String):
	var world := get_world()
	if world == null:
		return null

	var normalized_id := country_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return null

	return world.get_entity(normalized_id)


func get_country_display_name(country_id: String) -> String:
	var country = get_country(country_id)
	if country == null:
		return ""

	return str(country.name)


func get_country_exists(country_id: String) -> bool:
	return get_country(country_id) != null

func get_decision_options(country_id: String) -> Array:
	var country = get_country(country_id)
	if country == null:
		return []

	var raw_options = country.get_sim_metadata("decision_options", [])
	if raw_options is Array:
		return raw_options.duplicate()
	return []


func get_player_selected_decision(country_id: String):
	var country = get_country(country_id)
	if country == null:
		return null

	return country.get_sim_metadata("selected_decision", null)

func get_player_pending_actions(country_id: String) -> Array:
	if simulation == null:
		return []

	var pending: Array = simulation.get_pending_actions()
	var result: Array = []

	for raw_action in pending:
		var action: SimAction = raw_action as SimAction
		if action == null:
			continue
		if action.actor_id != country_id:
			continue
		result.append(action)

	return result


func get_action_outcome_history() -> Array:
	if simulation == null:
		return []
	if simulation.action_manager == null:
		return []
	return simulation.action_manager.get_outcome_history()
