class_name GameplaySession
extends RefCounted

## Step 20.2 — Minimal player gameplay/session state.
##
## This class belongs to the interaction layer. It stores session intent
## such as the selected player country and the live SimulationEngine reference.
## It does not own or duplicate authoritative WorldState data.

var simulation: SimulationEngine = null
var player_country_id: String = "india"


func initialize(live_simulation: SimulationEngine, country_id: String = "india") -> void:
	simulation = live_simulation

	var normalized_country_id := country_id.strip_edges().to_lower()
	if not normalized_country_id.is_empty():
		player_country_id = normalized_country_id


func set_player_country_id(country_id: String) -> bool:
	var normalized_country_id := country_id.strip_edges().to_lower()
	if normalized_country_id.is_empty():
		return false

	player_country_id = normalized_country_id
	return true


func get_player_country_id() -> String:
	return player_country_id


func get_world() -> WorldState:
	if simulation == null:
		return null

	return simulation.get_world()


func get_player_country():
	var world := get_world()
	if world == null:
		return null

	return world.get_entity(player_country_id)


func has_player_country() -> bool:
	return get_player_country() != null


func is_ready() -> bool:
	return simulation != null and simulation.is_ready()
