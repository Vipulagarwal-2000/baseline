class_name RegionalTransportRoute
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.8
# REGIONAL TRANSPORT ROUTE
# ============================================================
#
# A route is a graph edge between two parent-region transport nodes.
# It does not move resources or execute trade. Existing trade/resource
# systems remain responsible for those operations.
# ============================================================


var route_id: String = ""
var structural_country_id: String = ""
var from_region_id: String = ""
var to_region_id: String = ""

var base_capacity: float = 0.0
var effective_capacity: float = 0.0
var transport_cost: float = 1.0
var condition: float = 1.0
var blocked: bool = false

var route_type: String = "domestic"
var restriction_active: bool = false
var restriction_factor: float = 1.0
var restriction_reason: String = ""

var transport_authority: String = "regional_network"


func _init(
	target_route_id: String = "",
	target_country_id: String = "",
	target_from_region_id: String = "",
	target_to_region_id: String = ""
) -> void:
	route_id = target_route_id
	structural_country_id = target_country_id
	from_region_id = target_from_region_id
	to_region_id = target_to_region_id


func apply_profile(
	target_base_capacity: float,
	target_transport_cost: float,
	target_condition: float,
	target_blocked: bool,
	target_route_type: String = "domestic"
) -> bool:
	if target_base_capacity <= 0.0:
		return false
	if target_transport_cost <= 0.0:
		return false
	if target_condition < 0.0 or target_condition > 1.0:
		return false
	if target_route_type.is_empty():
		return false

	base_capacity = target_base_capacity
	transport_cost = target_transport_cost
	condition = target_condition
	blocked = target_blocked
	route_type = target_route_type
	recalculate_effective_capacity(null, null)
	return is_valid()


func recalculate_effective_capacity(
	from_node: RegionalTransportNode,
	to_node: RegionalTransportNode
) -> void:
	var endpoint_capacity: float = base_capacity

	if from_node != null:
		endpoint_capacity = min(endpoint_capacity, from_node.effective_capacity)
	if to_node != null:
		endpoint_capacity = min(endpoint_capacity, to_node.effective_capacity)

	var availability_factor: float = condition
	if blocked:
		availability_factor = 0.0

	availability_factor *= clampf(
		restriction_factor,
		0.0,
		1.0
	)

	effective_capacity = endpoint_capacity * availability_factor
	effective_capacity = clampf(
		effective_capacity,
		0.0,
		base_capacity
	)


func apply_route_restriction(
	factor: float,
	reason: String = "restriction"
) -> bool:
	if factor < 0.0 or factor > 1.0:
		return false

	restriction_active = true
	restriction_factor = factor
	restriction_reason = reason.strip_edges()
	return true


func clear_route_restriction() -> bool:
	if not restriction_active:
		return false

	restriction_active = false
	restriction_factor = 1.0
	restriction_reason = ""
	return true


func set_condition(value: float) -> bool:
	if value < 0.0 or value > 1.0:
		return false
	condition = value
	return true


func set_blocked(value: bool) -> void:
	blocked = value


func is_valid() -> bool:
	if route_id.is_empty():
		return false
	if structural_country_id.is_empty():
		return false
	if from_region_id.is_empty() or to_region_id.is_empty():
		return false
	if from_region_id == to_region_id:
		return false
	if base_capacity <= 0.0:
		return false
	if effective_capacity < 0.0 or effective_capacity > base_capacity + 0.000001:
		return false
	if transport_cost <= 0.0:
		return false
	if condition < 0.0 or condition > 1.0:
		return false
	if restriction_factor < 0.0 or restriction_factor > 1.0:
		return false
	if route_type.is_empty():
		return false
	return true


func get_other_endpoint(region_id: String) -> String:
	if region_id == from_region_id:
		return to_region_id
	if region_id == to_region_id:
		return from_region_id
	return ""


func to_snapshot_dict() -> Dictionary:
	return {
		"route_id": route_id,
		"structural_country_id": structural_country_id,
		"from_region_id": from_region_id,
		"to_region_id": to_region_id,
		"base_capacity": base_capacity,
		"effective_capacity": effective_capacity,
		"transport_cost": transport_cost,
		"condition": condition,
		"blocked": blocked,
		"route_type": route_type,
		"restriction_active": restriction_active,
		"restriction_factor": restriction_factor,
		"restriction_reason": restriction_reason
	}
