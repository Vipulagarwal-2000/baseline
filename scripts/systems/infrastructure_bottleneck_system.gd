class_name InfrastructureBottleneckSystem
extends SimulationSystem


# Fixed order is intentional.
# It guarantees deterministic tie-breaking when multiple infrastructure
# components share the same minimum value.
const COMPONENT_ORDER := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


var production_process_catalog: ProductionProcessCatalog = null


func _init(
	production_process_catalog: ProductionProcessCatalog = null
):
	super("infrastructure_bottleneck_system")
	self.production_process_catalog = production_process_catalog


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
			"InfrastructureBottleneckSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var infrastructure = entity.get_component(
			"infrastructure"
		)

		if infrastructure == null:
			continue

		var mapping := get_bottleneck(
			infrastructure
		)

		infrastructure.set_state(
			"bottleneck_mapping",
			mapping
		)


func get_bottleneck(
	infrastructure: InfrastructureComponent
) -> Dictionary:

	if infrastructure == null:
		return _empty_mapping()

	var component_values: Dictionary = {}
	var bottleneck_component := ""
	var bottleneck_factor := 1.0
	var initialized := false

	for component_name in COMPONENT_ORDER:

		var value: float = clampf(
			_safe_value(
				infrastructure.get_state(
					component_name,
					0.0
				)
			),
			0.0,
			1.0
		)

		component_values[component_name] = value

		if not initialized:
			bottleneck_component = component_name
			bottleneck_factor = value
			initialized = true
			continue

		# Strictly less-than preserves COMPONENT_ORDER as the tie-breaker.
		if value < bottleneck_factor:
			bottleneck_component = component_name
			bottleneck_factor = value

	return {
		"component": bottleneck_component,
		"factor": bottleneck_factor,
		"components": component_values
	}


func get_process_bottleneck(
	entity,
	process_id: String
) -> Dictionary:

	if entity == null:
		return _empty_process_mapping()

	if production_process_catalog == null:
		return _empty_process_mapping()

	if not production_process_catalog.has_process(
		process_id
	):
		return _empty_process_mapping()

	var definition: Dictionary = production_process_catalog.get_process(
		process_id
	)

	if definition.is_empty():
		return _empty_process_mapping()

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	var resources = entity.get_component(
		"resources"
	)

	if infrastructure == null or resources == null:
		return _empty_process_mapping()

	var requirements: Array = []

	var generic_usage = definition.get(
		"infrastructure_usage",
		{}
	)

	if typeof(generic_usage) == TYPE_DICTIONARY:
		for requirement_name in generic_usage.keys():
			var required_value := float(
				generic_usage[requirement_name]
			)

			if required_value <= 0.0:
				continue

			var name := str(requirement_name)
			var available_value := 0.0
			var source := "resource_capacity"

			if COMPONENT_ORDER.has(name):
				available_value = clampf(
					float(
						infrastructure.get_state(
							name,
							0.0
						)
					),
					0.0,
					1.0
				)
				source = "infrastructure_component"
			else:
				var infrastructure_capacity = resources.get_state(
					"infrastructure_capacity",
					{}
				)

				if typeof(infrastructure_capacity) == TYPE_DICTIONARY:
					available_value = clampf(
						float(
							infrastructure_capacity.get(
								name,
								0.0
							)
						),
						0.0,
						1.0
					)

			requirements.append({
				"name": name,
				"required": required_value,
				"available": available_value,
				"source": source
			})

	var industrial_usage = definition.get(
		"industrial_infrastructure_usage",
		{}
	)

	if typeof(industrial_usage) == TYPE_DICTIONARY:
		for requirement_name in industrial_usage.keys():
			var required_value := float(
				industrial_usage[requirement_name]
			)

			if required_value <= 0.0:
				continue

			var name := str(requirement_name)
			var available_value := 0.0
			if name == "industrial":
				available_value = clampf(
					float(
						infrastructure.get_state(
							"industrial",
							0.0
						)
					),
					0.0,
					1.0
				)
			else:
				available_value = clampf(
					float(
						infrastructure.get_state(
							name,
							0.0
						)
					),
					0.0,
					1.0
				)

			requirements.append({
				"name": name,
				"required": required_value,
				"available": available_value,
				"source": "infrastructure_component"
			})

	if requirements.is_empty():
		return _empty_process_mapping()

	# Deterministic requirement order: specialized infrastructure first in
	# COMPONENT_ORDER, followed by generic names alphabetically.
	requirements.sort_custom(
		func(a, b):
			var a_name := str(a.get("name", ""))
			var b_name := str(b.get("name", ""))
			var a_index := COMPONENT_ORDER.find(a_name)
			var b_index := COMPONENT_ORDER.find(b_name)

			if a_index == -1 and b_index == -1:
				return a_name < b_name

			if a_index == -1:
				return false

			if b_index == -1:
				return true

			return a_index < b_index
	)

	var bottleneck_name := ""
	var bottleneck_factor := 1.0
	var initialized := false
	var requirement_map: Dictionary = {}

	for requirement in requirements:
		var name := str(requirement.get("name", ""))
		var required_value := maxf(
			float(requirement.get("required", 0.0)),
			0.0
		)
		var available_value := maxf(
			float(requirement.get("available", 0.0)),
			0.0
		)

		if required_value <= 0.0:
			continue

		var factor := clampf(
			available_value / required_value,
			0.0,
			1.0
		)

		requirement_map[name] = {
			"required": required_value,
			"available": available_value,
			"factor": factor,
			"source": requirement.get("source", "")
		}

		if not initialized:
			bottleneck_name = name
			bottleneck_factor = factor
			initialized = true
			continue

		if factor < bottleneck_factor:
			bottleneck_name = name
			bottleneck_factor = factor

	return {
		"process_id": process_id,
		"component": bottleneck_name,
		"factor": bottleneck_factor,
		"requirements": requirement_map
	}


func get_entity_bottleneck(
	entity
) -> Dictionary:

	if entity == null:
		return _empty_mapping()

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		return _empty_mapping()

	return get_bottleneck(
		infrastructure
	)


func _empty_mapping() -> Dictionary:
	return {
		"component": "",
		"factor": 1.0,
		"components": {}
	}


func _empty_process_mapping() -> Dictionary:
	return {
		"process_id": "",
		"component": "",
		"factor": 1.0,
		"requirements": {}
	}


func _safe_value(
	value
) -> float:

	if typeof(value) == TYPE_INT:
		return float(value)

	if typeof(value) == TYPE_FLOAT:
		return value

	return 0.0
