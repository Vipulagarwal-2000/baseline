class_name SimulationSystem
extends RefCounted


var system_name: String = ""


func _init(name: String = "simulation_system"):
	system_name = name


func process_month(world: WorldState) -> void:
	if world == null:
		push_error(
			system_name + ": World is null."
		)
		return
