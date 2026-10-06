class_name CountryAggregationState
extends RefCounted


# ============================================================
# WORLD SIMULATOR — STEP 12.9
# COUNTRY AGGREGATION STATE
# ============================================================
#
# This is a transient calculation/result object for the explicit
# regional -> country authority handoff.
#
# It is deliberately NOT a second country authority. Existing
# country components remain the authoritative country state after
# an explicit aggregation operation.
# ============================================================


const INFRASTRUCTURE_KEYS: Array[String] = [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]

var country_id: String = ""
var parent_region_ids: Array[String] = []

var population: float = 0.0
var urbanization: float = 0.0
var immigration: float = 0.0
var emigration: float = 0.0
var net_migration: float = 0.0

var resource_production: Dictionary = {}
var resource_reserves: Dictionary = {}
var resource_stockpile: Dictionary = {}

var infrastructure: Dictionary = {}
var infrastructure_total_capacity: float = 0.0
var infrastructure_weight_total: float = 0.0

var industry_process_capacity: Dictionary = {}

var authority: String = "regional_parent_aggregation"
var aggregation_version: String = "12.9"


func _init(target_country_id: String = "") -> void:
	country_id = target_country_id
	for key in INFRASTRUCTURE_KEYS:
		infrastructure[key] = 0.0


func is_valid() -> bool:
	if country_id.is_empty():
		return false
	if parent_region_ids.is_empty():
		return false
	if authority != "regional_parent_aggregation":
		return false
	if aggregation_version != "12.9":
		return false

	if population < 0.0:
		return false
	if urbanization < 0.0:
		return false
	if immigration < 0.0:
		return false
	if emigration < 0.0:
		return false

	for key in INFRASTRUCTURE_KEYS:
		var value: float = float(infrastructure.get(key, -1.0))
		if value < 0.0 or value > 1.0:
			return false

	if infrastructure_total_capacity < 0.0 or infrastructure_total_capacity > 1.0:
		return false
	if infrastructure_weight_total <= 0.0:
		return false

	for value in resource_production.values():
		if float(value) < 0.0:
			return false
	for value in resource_reserves.values():
		if float(value) < 0.0:
			return false
	for value in resource_stockpile.values():
		if float(value) < 0.0:
			return false
	for value in industry_process_capacity.values():
		if float(value) < 0.0:
			return false

	return true


func to_snapshot_dict() -> Dictionary:
	return {
		"country_id": country_id,
		"parent_region_ids": parent_region_ids.duplicate(true),
		"population": population,
		"urbanization": urbanization,
		"immigration": immigration,
		"emigration": emigration,
		"net_migration": net_migration,
		"resource_production": resource_production.duplicate(true),
		"resource_reserves": resource_reserves.duplicate(true),
		"resource_stockpile": resource_stockpile.duplicate(true),
		"infrastructure": infrastructure.duplicate(true),
		"infrastructure_total_capacity": infrastructure_total_capacity,
		"infrastructure_weight_total": infrastructure_weight_total,
		"industry_process_capacity": industry_process_capacity.duplicate(true),
		"authority": authority,
		"aggregation_version": aggregation_version
	}
