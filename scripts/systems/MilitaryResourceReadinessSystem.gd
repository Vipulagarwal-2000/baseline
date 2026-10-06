class_name MilitaryResourceReadinessSystem
extends SimulationSystem


# ================================================================
# STEP 13.2 — RESOURCES → READINESS
# ================================================================
#
# Derived bridge only.
#
# Authority remains:
#   ResourceSystem
#       -> authoritative resource shortage / military modifier state
#   MilitarySystem
#       -> authoritative military readiness calculation
#
# This system does not recalculate shortages, consume resources, or
# create a second resource model.
#
# It translates the existing ResourceSystem military resource effects
# into an explicit readiness modifier consumed by MilitarySystem.
# ================================================================


const STRATEGIC_RESOURCES: Array = [
	"coal",
	"iron",
	"oil"
]

const DEFAULT_RESOURCE_READINESS_MODIFIER: float = 1.0


func _init() -> void:
	super("military_resource_readiness_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error(
			"MilitaryResourceReadinessSystem: World is null."
		)
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var resources = entity.get_component("resources")
		var military = entity.get_component("military")

		if resources == null or military == null:
			continue

		_update_entity(resources, military)


func _update_entity(resources, military) -> void:

	var per_resource_value = resources.get_state(
		"military_resource_modifier_by_resource",
		{}
	)

	var aggregate_value = resources.get_state(
		"military_resource_modifier",
		DEFAULT_RESOURCE_READINESS_MODIFIER
	)

	if typeof(per_resource_value) != TYPE_DICTIONARY:
		per_resource_value = {}

	var readiness_modifier: float = clampf(
		float(aggregate_value),
		0.0,
		1.0
	)

	var constrained_resources: Array = []
	var resource_modifiers: Dictionary = {}
	var found_strategic_modifier := false

	# Prefer explicit strategic-resource modifiers when ResourceSystem
	# has supplied them. The most limiting strategic resource controls
	# the readiness constraint.
	for resource_id in STRATEGIC_RESOURCES:
		var raw_value = per_resource_value.get(
			resource_id,
			null
		)

		if raw_value == null:
			continue

		var modifier: float = clampf(
			float(raw_value),
			0.0,
			1.0
		)

		resource_modifiers[resource_id] = modifier

		if not found_strategic_modifier:
			readiness_modifier = modifier
			found_strategic_modifier = true
		else:
			readiness_modifier = minf(
				readiness_modifier,
				modifier
			)

	for resource_id in resource_modifiers.keys():
		var modifier: float = float(
			resource_modifiers[resource_id]
		)

		if modifier < 0.999999:
			constrained_resources.append(resource_id)

	readiness_modifier = clampf(
		readiness_modifier,
		0.0,
		1.0
	)

	military.set_state(
		"resource_readiness_modifier",
		readiness_modifier
	)

	military.set_state(
		"resource_readiness_constraint",
		1.0 - readiness_modifier
	)

	military.set_state(
		"resource_military_constraint_active",
		readiness_modifier < 0.999999
	)

	military.set_state(
		"resource_readiness_modifiers_by_resource",
		resource_modifiers
	)

	military.set_state(
		"resource_readiness_constrained_resources",
		constrained_resources
	)

	military.set_state(
		"resource_readiness_source",
		"ResourceSystem.military_resource_modifier"
	)
