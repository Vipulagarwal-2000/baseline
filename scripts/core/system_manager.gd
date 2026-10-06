class_name SystemManager
extends RefCounted


var systems: Array = []


func register_system(
	system,
	phase: String = SimulationPhase.WORLD_UPDATE,
	order: int = 100
) -> void:

	if system == null:
		push_error(
			"SystemManager: Cannot register null system."
		)
		return

	systems.append({
		"system": system,
		"phase": phase,
		"order": order
	})

	systems.sort_custom(
		_compare_system_order
	)


func _compare_system_order(
	a: Dictionary,
	b: Dictionary
) -> bool:

	if a["phase"] == b["phase"]:
		return a["order"] < b["order"]

	return _get_phase_order(
		a["phase"]
	) < _get_phase_order(
		b["phase"]
	)


func _get_phase_order(
	phase: String
) -> int:

	match phase:

		SimulationPhase.PRE_SIMULATION:
			return 0

		SimulationPhase.WORLD_UPDATE:
			return 1

		SimulationPhase.ACTIONS:
			return 2

		SimulationPhase.EVENTS:
			return 3

		SimulationPhase.DECISIONS:
			return 4

		SimulationPhase.POST_SIMULATION:
			return 5

		_:
			return 100


func process_phase(
	world: WorldState,
	phase: String
) -> void:

	if world == null:
		push_error(
			"SystemManager: World is null."
		)
		return

	for entry in systems:

		if entry["phase"] != phase:
			continue

		var system = entry["system"]

		if system.has_method(
			"process_month"
		):
			system.process_month(
				world
			)


func get_system_count() -> int:

	return systems.size()


func get_system_order() -> Array:

	var result: Array = []

	for entry in systems:

		result.append({
			"name": entry["system"].system_name,
			"phase": entry["phase"],
			"order": entry["order"]
		})

	return result


func get_system(system_name: String):
	
	for entry in systems:
		
		var system = entry["system"]
		
		if system.system_name == system_name:
			return system
	
	return null
