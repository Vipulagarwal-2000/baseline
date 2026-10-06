class_name CapacityUtilizationSystem
extends SimulationSystem


func _init():
	super("capacity_utilization_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("CapacityUtilizationSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var industry = entity.get_component("industry")
		var resources = entity.get_component("resources")

		if industry == null or resources == null:
			continue

		_process_entity_capacity(industry, resources)


func _process_entity_capacity(
	industry,
	resources: ResourceComponent
) -> void:

	var process_definitions_value = industry.get_state("processes", {})
	var production_state_value = industry.get_state("production_state", {})

	var process_definitions: Dictionary = {}
	var production_state: Dictionary = {}

	if typeof(process_definitions_value) == TYPE_DICTIONARY:
		process_definitions = process_definitions_value

	if typeof(production_state_value) == TYPE_DICTIONARY:
		production_state = production_state_value

	var installed_capacity := 0.0
	var effective_capacity := 0.0
	var actual_production := 0.0
	var unused_effective_capacity := 0.0
	var capacity_gap := 0.0
	var process_ledger: Dictionary = {}
	var process_utilization: Dictionary = {}

	for process_id_value in process_definitions.keys():

		var process_id := str(process_id_value)
		var definition = process_definitions.get(process_id_value, {})

		if typeof(definition) != TYPE_DICTIONARY:
			continue

		var outcome = production_state.get(process_id, {})
		if typeof(outcome) != TYPE_DICTIONARY:
			outcome = {}

		var installed := maxf(
			float(definition.get("capacity", 0.0)),
			0.0
		)

		# ProductionProcessSystem persists effective_capacity in its
		# authoritative outcome. This is the usable capacity before input
		# stock constraints determine actual output.
		var effective := maxf(
			float(outcome.get("effective_capacity", 0.0)),
			0.0
		)

		var actual := maxf(
			float(outcome.get("actual_production", 0.0)),
			0.0
		)

		# Bound the diagnostic only; do not rewrite authoritative output.
		var measured_actual := minf(actual, effective)
		var unused_effective := maxf(effective - measured_actual, 0.0)
		var gap := maxf(installed - effective, 0.0)

		var utilization := 0.0
		if effective > 0.0:
			utilization = (measured_actual / effective) * 100.0

		var installed_utilization := 0.0
		if installed > 0.0:
			installed_utilization = (measured_actual / installed) * 100.0

		var effective_ratio := 0.0
		if installed > 0.0:
			effective_ratio = (effective / installed) * 100.0

		utilization = clampf(utilization, 0.0, 100.0)
		installed_utilization = clampf(installed_utilization, 0.0, 100.0)
		effective_ratio = clampf(effective_ratio, 0.0, 100.0)

		process_utilization[process_id] = utilization

		process_ledger[process_id] = {
			"installed_capacity": installed,
			"effective_capacity": effective,
			"actual_production": actual,
			"measured_actual_production": measured_actual,
			"unused_effective_capacity": unused_effective,
			"capacity_gap": gap,
			"capacity_utilization": utilization,
			"installed_capacity_utilization": installed_utilization,
			"effective_capacity_ratio": effective_ratio,
			"status": str(outcome.get("status", "no_outcome")),
			"blocked": bool(outcome.get("blocked", false)),
			"reason": str(outcome.get("reason", ""))
		}

		installed_capacity += installed
		effective_capacity += effective
		actual_production += actual
		unused_effective_capacity += unused_effective
		capacity_gap += gap

	var measured_total_actual := minf(actual_production, effective_capacity)

	var aggregate_utilization := 0.0
	if effective_capacity > 0.0:
		aggregate_utilization = (measured_total_actual / effective_capacity) * 100.0

	var aggregate_installed_utilization := 0.0
	if installed_capacity > 0.0:
		aggregate_installed_utilization = (measured_total_actual / installed_capacity) * 100.0

	var aggregate_effective_ratio := 0.0
	if installed_capacity > 0.0:
		aggregate_effective_ratio = (effective_capacity / installed_capacity) * 100.0

	resources.set_state("installed_capacity", installed_capacity)
	resources.set_state("effective_capacity", effective_capacity)
	resources.set_state("actual_capacity_production", actual_production)
	resources.set_state("unused_effective_capacity", unused_effective_capacity)
	resources.set_state("capacity_gap", capacity_gap)
	resources.set_state("capacity_utilization", clampf(aggregate_utilization, 0.0, 100.0))
	resources.set_state("installed_capacity_utilization", clampf(aggregate_installed_utilization, 0.0, 100.0))
	resources.set_state("effective_capacity_ratio", clampf(aggregate_effective_ratio, 0.0, 100.0))
	resources.set_state("capacity_utilization_by_process", process_utilization)
	resources.set_state("capacity_utilization_ledger", process_ledger)
