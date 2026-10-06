class_name MilitaryProductionCapacitySystem
extends SimulationSystem


# ================================================================
# STEP 13.1 — PRODUCTION → MILITARY CAPACITY
# ================================================================
#
# This system is a derived bridge only.
#
# Authority remains:
#   IndustryComponent
#       -> configured process structure / adoption
#   ProductionProcessSystem
#       -> actual monthly production outcome
#   MilitarySystem
#       -> authoritative military capability/readiness calculation
#
# This system does not execute production, consume resources, or
# directly calculate military_power/readiness.
#
# It converts the current industrial/production state into a bounded
# production-capacity modifier that MilitarySystem consumes.
# ================================================================


const MIN_PRODUCTION_CAPACITY_MODIFIER: float = 0.70

# Production is considered militarily relevant when its actual process
# output contains one of these industrial-support outputs. The catalog
# remains authoritative for process definitions; this list only declares
# which outputs can support the strategic military-capacity bridge.
const RELEVANT_OUTPUTS: Dictionary = {
	"steel": 1.0,
	"machinery": 1.0,
	"vehicles": 1.0,
	"aircraft": 1.0,
	"fuel": 1.0,
	"petroleum": 1.0,
	"refined_petroleum": 1.0,
	"electronics": 1.0,
	"chemicals": 1.0,
	"weapons": 1.0,
	"ammunition": 1.0,
	"munitions": 1.0
}

var catalog: ProductionProcessCatalog


func _init() -> void:
	super("military_production_capacity_system")
	catalog = ProductionProcessCatalog.new()


func process_month(world: WorldState) -> void:
	if world == null:
		push_error(
			"MilitaryProductionCapacitySystem: World is null."
		)
		return

	for entity in world.entities.values():
		if entity == null:
			continue

		var industry = entity.get_component("industry")
		var military = entity.get_component("military")

		if industry == null or military == null:
			continue

		_update_entity(
			entity,
			industry,
			military
		)


func _update_entity(
	entity,
	industry,
	military
) -> void:
	var processes = industry.get_state(
		"processes",
		{}
	)

	var process_adoption = industry.get_state(
		"process_adoption",
		{}
	)

	var production_state = industry.get_state(
		"production_state",
		{}
	)

	if typeof(processes) != TYPE_DICTIONARY:
		processes = {}

	if typeof(process_adoption) != TYPE_DICTIONARY:
		process_adoption = {}

	if typeof(production_state) != TYPE_DICTIONARY:
		production_state = {}

	var configured_capacity: float = 0.0
	var effective_capacity: float = 0.0

	var relevant_configured_capacity: float = 0.0
	var relevant_potential_output: float = 0.0
	var relevant_actual_output: float = 0.0

	var relevant_process_count: int = 0
	var executable_process_count: int = 0

	for raw_process_id in processes.keys():
		var process_id := str(raw_process_id)
		var instance = processes[raw_process_id]

		if typeof(instance) != TYPE_DICTIONARY:
			continue

		if not bool(instance.get("active", false)):
			continue

		if not catalog.has_process(process_id):
			continue

		var definition := catalog.get_process(process_id)
		if definition.is_empty():
			continue

		# Natural-resource extraction remains owned by ResourceSystem and
		# must not be counted as industrial transformation capacity here.
		if str(definition.get("category", "")) == "extraction":
			continue

		var capacity := maxf(
			float(instance.get("capacity", 0.0)),
			0.0
		)

		var instance_efficiency := clampf(
			float(instance.get("efficiency", 1.0)),
			0.0,
			1.0
		)

		var catalog_efficiency := maxf(
			float(definition.get("efficiency", 1.0)),
			0.0
		)

		var adoption := clampf(
			float(process_adoption.get(process_id, 1.0)),
			0.0,
			1.0
		)

		if capacity <= 0.0 or adoption <= 0.0:
			continue

		executable_process_count += 1

		var configured_process_capacity := (
			capacity
			* adoption
			* instance_efficiency
			* catalog_efficiency
		)

		configured_capacity += configured_process_capacity

		var outcome = production_state.get(
			process_id,
			{}
		)

		if typeof(outcome) != TYPE_DICTIONARY:
			outcome = {}

		var outcome_effective_capacity := maxf(
			float(
				outcome.get(
					"effective_capacity",
					0.0
				)
			),
			0.0
		)

		# Effective production capacity cannot exceed the process's
		# configured executable capacity.
		effective_capacity += minf(
			outcome_effective_capacity,
			configured_process_capacity
		)

		var output_map = definition.get("outputs", {})
		if typeof(output_map) != TYPE_DICTIONARY:
			output_map = {}

		var relevant_output_coefficient: float = 0.0

		for raw_output_id in output_map.keys():
			var output_id := str(raw_output_id)
			var weight := float(
				RELEVANT_OUTPUTS.get(
					output_id,
					0.0
				)
			)

			if weight <= 0.0:
				continue

			var output_coefficient := maxf(
				float(output_map[raw_output_id]),
				0.0
			)

			relevant_output_coefficient += (
				output_coefficient * weight
			)

		if relevant_output_coefficient <= 0.0:
			continue

		relevant_process_count += 1
		relevant_configured_capacity += configured_process_capacity

		# Potential relevant output is based on the operational capacity
		# exposed by ProductionProcessSystem, not on configured capacity.
		# This prevents this bridge from inventing production that the
		# authoritative production system did not make operationally usable.
		var process_potential_output := (
			minf(
				outcome_effective_capacity,
				configured_process_capacity
			)
			* relevant_output_coefficient
		)

		relevant_potential_output += process_potential_output

		var outputs_produced = outcome.get(
			"outputs_produced",
			{}
		)

		if typeof(outputs_produced) != TYPE_DICTIONARY:
			outputs_produced = {}

		for raw_output_id in outputs_produced.keys():
			var output_id := str(raw_output_id)
			var weight := float(
				RELEVANT_OUTPUTS.get(
					output_id,
					0.0
				)
			)

			if weight <= 0.0:
				continue

			relevant_actual_output += (
				maxf(float(outputs_produced[raw_output_id]), 0.0)
				* weight
			)

	var industrial_capacity_index := 0.0
	if configured_capacity > 0.0:
		industrial_capacity_index = clampf(
			effective_capacity / configured_capacity,
			0.0,
			1.0
		)

	var relevant_capacity_share := 0.0
	if configured_capacity > 0.0:
		relevant_capacity_share = clampf(
			relevant_configured_capacity / configured_capacity,
			0.0,
			1.0
		)

	var relevant_output_utilization := 0.0
	if relevant_potential_output > 0.0:
		relevant_output_utilization = clampf(
			relevant_actual_output / relevant_potential_output,
			0.0,
			1.0
		)

	# Production support is deliberately multiplicative:
	#
	#   operating industrial capacity
	#       × share of industry that is militarily relevant
	#       × realized relevant production
	#
	# This produces a bounded 0..1 signal without creating a second
	# industrial or military inventory model.
	var production_military_support := clampf(
		industrial_capacity_index
		* relevant_capacity_share
		* relevant_output_utilization,
		0.0,
		1.0
	)

	# 13.1 is a constraint bridge, not a second military power formula.
	# At full industrial/production support the economy-side military
	# capacity target is unchanged. Weak production can reduce that target
	# by at most 30% at this MVP abstraction level.
	var production_capacity_modifier := (
		MIN_PRODUCTION_CAPACITY_MODIFIER
		+ (
			1.0 - MIN_PRODUCTION_CAPACITY_MODIFIER
			) * production_military_support
	)

	if executable_process_count <= 0:
		production_military_support = 0.0
		production_capacity_modifier = MIN_PRODUCTION_CAPACITY_MODIFIER

	if relevant_process_count <= 0:
		relevant_capacity_share = 0.0
		relevant_output_utilization = 0.0
		production_military_support = 0.0
		production_capacity_modifier = MIN_PRODUCTION_CAPACITY_MODIFIER

	military.set_state(
		"production_industrial_capacity_index",
		industrial_capacity_index
	)

	military.set_state(
		"production_relevant_capacity_share",
		relevant_capacity_share
	)

	military.set_state(
		"production_relevant_output_utilization",
		relevant_output_utilization
	)

	military.set_state(
		"production_military_support",
		production_military_support
	)

	military.set_state(
		"production_capacity_modifier",
		production_capacity_modifier
	)

	military.set_state(
		"production_relevant_actual_output",
		relevant_actual_output
	)

	military.set_state(
		"production_relevant_potential_output",
		relevant_potential_output
	)

	military.set_state(
		"production_executable_process_count",
		executable_process_count
	)

	military.set_state(
		"production_relevant_process_count",
		relevant_process_count
	)
