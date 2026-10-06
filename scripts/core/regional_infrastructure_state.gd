class_name RegionalInfrastructureState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.6
# REGIONAL INFRASTRUCTURE STATE
# ============================================================
#
# Parent regions are the Step 12.6 localization authority.
# The country InfrastructureComponent remains authoritative for the
# country baseline. Regional values are calibration/localization state.
#
# Country infrastructure is a normalized index, not a physical stock
# that should be arithmetically summed. Country reconstruction uses the
# explicit regional aggregation weight supplied by the calibration profile.
# ============================================================


var region_id: String = ""
var structural_country_id: String = ""

var source_country_infrastructure_state: Dictionary = {}
var derived_source_total_capacity: float = 0.0
var aggregation_weight: float = 0.0

var transport: float = 0.0
var railways: float = 0.0
var roads: float = 0.0
var ports: float = 0.0
var power: float = 0.0
var industrial: float = 0.0
var storage: float = 0.0
var total_capacity: float = 0.0

var infrastructure_authority: String = "regional_seed"
var aggregation_authority: String = "regional_calibration"
var province_infrastructure_authority: bool = false


func _init(
	target_region_id: String = "",
	target_country_id: String = ""
) -> void:
	region_id = target_region_id
	structural_country_id = target_country_id


func apply_localization(
	country_infrastructure_state: Dictionary,
	target_aggregation_weight: float,
	regional_infrastructure: Dictionary
) -> bool:
	if country_infrastructure_state.is_empty():
		return false
	if target_aggregation_weight < 0.0 or target_aggregation_weight > 1.0:
		return false

	for key in [
		"transport",
		"railways",
		"roads",
		"ports",
		"power",
		"industrial",
		"storage",
        "total_capacity"
	]:
		var source_value: Variant = country_infrastructure_state.get(key, null)
		if source_value == null:
			return false
		if typeof(source_value) != TYPE_FLOAT and typeof(source_value) != TYPE_INT:
			return false

		var regional_value: Variant = regional_infrastructure.get(key, null)
		if regional_value == null:
			return false
		if typeof(regional_value) != TYPE_FLOAT and typeof(regional_value) != TYPE_INT:
			return false

		if float(regional_value) < 0.0 or float(regional_value) > 1.0:
			return false

	source_country_infrastructure_state = country_infrastructure_state.duplicate(true)
	derived_source_total_capacity = (
		float(country_infrastructure_state["transport"])
		+ float(country_infrastructure_state["railways"])
		+ float(country_infrastructure_state["roads"])
		+ float(country_infrastructure_state["ports"])
		+ float(country_infrastructure_state["power"])
		+ float(country_infrastructure_state["industrial"])
		+ float(country_infrastructure_state["storage"])
	) / 7.0
	aggregation_weight = target_aggregation_weight

	transport = float(regional_infrastructure["transport"])
	railways = float(regional_infrastructure["railways"])
	roads = float(regional_infrastructure["roads"])
	ports = float(regional_infrastructure["ports"])
	power = float(regional_infrastructure["power"])
	industrial = float(regional_infrastructure["industrial"])
	storage = float(regional_infrastructure["storage"])

	# The regional aggregate capacity is always derived from the same seven
	# infrastructure dimensions used by the existing InfrastructureSystem.
	total_capacity = (
		transport
		+ railways
		+ roads
		+ ports
		+ power
		+ industrial
		+ storage
	) / 7.0

	infrastructure_authority = "regional_seed"
	aggregation_authority = "regional_calibration"
	province_infrastructure_authority = false

	return is_valid()


func is_valid() -> bool:
	if region_id.is_empty() or structural_country_id.is_empty():
		return false
	if aggregation_weight < 0.0 or aggregation_weight > 1.0:
		return false
	if derived_source_total_capacity < 0.0 or derived_source_total_capacity > 1.0:
		return false

	for value in [
		transport,
		railways,
		roads,
		ports,
		power,
		industrial,
		storage,
		total_capacity
	]:
		if float(value) < 0.0 or float(value) > 1.0:
			return false

	var expected_total: float = (
		transport
		+ railways
		+ roads
		+ ports
		+ power
		+ industrial
		+ storage
	) / 7.0

	return is_equal_approx(expected_total, total_capacity)


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_country_infrastructure_state": source_country_infrastructure_state.duplicate(true),
		"derived_source_total_capacity": derived_source_total_capacity,
		"aggregation_weight": aggregation_weight,
		"transport": transport,
		"railways": railways,
		"roads": roads,
		"ports": ports,
		"power": power,
		"industrial": industrial,
		"storage": storage,
		"total_capacity": total_capacity,
		"infrastructure_authority": infrastructure_authority,
		"aggregation_authority": aggregation_authority,
		"province_infrastructure_authority": province_infrastructure_authority
	}
