class_name RegionalTransportNode
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.8
# REGIONAL TRANSPORT NODE
# ============================================================
#
# Parent regions are the transport-node authority in the MVP.
# This node does not own population, resources, infrastructure, or industry.
# It consumes the already-localized infrastructure state as its physical
# capability source and exposes a graph-facing transport capacity.
#
# Province nodes remain structural only until a later refinement stage.
# ============================================================


var region_id: String = ""
var structural_country_id: String = ""

var source_regional_infrastructure_state: Dictionary = {}
var population_weight: float = 0.0

var base_capacity: float = 0.0
var effective_capacity: float = 0.0
var transport_factor: float = 0.0
var road_factor: float = 0.0
var railway_factor: float = 0.0
var port_factor: float = 0.0

var transport_cost: float = 1.0
var condition: float = 1.0
var blocked: bool = false

var transport_authority: String = "regional_network"
var province_transport_authority: bool = false


func _init(
	target_region_id: String = "",
	target_country_id: String = ""
) -> void:
	region_id = target_region_id
	structural_country_id = target_country_id


func apply_localization(
	infrastructure_state: Dictionary,
	target_population_weight: float,
	target_base_capacity: float,
	target_transport_cost: float,
	target_condition: float,
	target_blocked: bool
) -> bool:
	if infrastructure_state.is_empty():
		return false
	if target_population_weight < 0.0 or target_population_weight > 1.0:
		return false
	if target_base_capacity <= 0.0:
		return false
	if target_transport_cost <= 0.0:
		return false
	if target_condition < 0.0 or target_condition > 1.0:
		return false

	var required_keys := [
		"transport",
		"roads",
		"railways",
		"ports"
	]

	for key in required_keys:
		var value: Variant = infrastructure_state.get(key, null)
		if value == null:
			return false
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		if float(value) < 0.0 or float(value) > 1.0:
			return false

	source_regional_infrastructure_state = infrastructure_state.duplicate(true)
	population_weight = target_population_weight
	base_capacity = target_base_capacity
	transport_cost = target_transport_cost
	condition = target_condition
	blocked = target_blocked

	transport_factor = float(infrastructure_state["transport"])
	road_factor = float(infrastructure_state["roads"])
	railway_factor = float(infrastructure_state["railways"])
	port_factor = float(infrastructure_state["ports"])

	recalculate_effective_capacity()
	return is_valid()


func recalculate_effective_capacity() -> void:
	var connectivity_factor: float = (
		transport_factor * 0.40
		+ road_factor * 0.30
		+ railway_factor * 0.30
	)

	connectivity_factor = clampf(
		connectivity_factor,
		0.0,
		1.0
	)

	var availability_factor: float = condition
	if blocked:
		availability_factor = 0.0

	effective_capacity = (
		base_capacity
		* connectivity_factor
		* availability_factor
	)

	effective_capacity = clampf(
		effective_capacity,
		0.0,
		base_capacity
	)


func set_condition(value: float) -> bool:
	if value < 0.0 or value > 1.0:
		return false
	condition = value
	recalculate_effective_capacity()
	return true


func set_blocked(value: bool) -> void:
	blocked = value
	recalculate_effective_capacity()


func is_valid() -> bool:
	if region_id.is_empty():
		return false
	if structural_country_id.is_empty():
		return false
	if base_capacity <= 0.0:
		return false
	if effective_capacity < 0.0 or effective_capacity > base_capacity + 0.000001:
		return false
	if transport_cost <= 0.0:
		return false
	if condition < 0.0 or condition > 1.0:
		return false
	if population_weight < 0.0 or population_weight > 1.0:
		return false
	if not province_transport_authority:
		return true
	return false


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_regional_infrastructure_state": source_regional_infrastructure_state.duplicate(true),
		"population_weight": population_weight,
		"base_capacity": base_capacity,
		"effective_capacity": effective_capacity,
		"transport_factor": transport_factor,
		"road_factor": road_factor,
		"railway_factor": railway_factor,
		"port_factor": port_factor,
		"transport_cost": transport_cost,
		"condition": condition,
		"blocked": blocked
	}
