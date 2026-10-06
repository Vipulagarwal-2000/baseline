class_name RegionalIndustryState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.7
# REGIONAL INDUSTRY STATE
# ============================================================

var region_id: String = ""
var structural_country_id: String = ""

# Full source snapshot taken from the authoritative country IndustryComponent
# at localization time. It is a seed/source ledger, not a second monthly authority.
var source_country_industry_state: Dictionary = {}

# Localized parent-region production structure.
# process_id -> {active, capacity, efficiency, adoption, capacity_share,
#                source_capacity, source_efficiency, labor_need, resource_demand}
var processes: Dictionary = {}

var process_adoption: Dictionary = {}
var process_adoption_target: Dictionary = {}
var process_adoption_rate: Dictionary = {}

var industry_authority: String = "regional_seed"
var province_industry_authority: bool = false


func _init(target_region_id: String = "", target_country_id: String = "") -> void:
	region_id = target_region_id
	structural_country_id = target_country_id


func apply_localization(
	country_industry_state: Dictionary,
	process_definitions: Dictionary,
	capacity_shares: Dictionary
) -> bool:
	if not _validate_source_state(country_industry_state):
		return false
	if not capacity_shares is Dictionary:
		return false

	source_country_industry_state = country_industry_state.duplicate(true)

	var source_processes: Dictionary = country_industry_state["processes"]
	var adoption_value: Variant = country_industry_state.get("process_adoption", {})
	var adoption_target_value: Variant = country_industry_state.get("process_adoption_target", {})
	var adoption_rate_value: Variant = country_industry_state.get("process_adoption_rate", {})

	process_adoption = (adoption_value as Dictionary).duplicate(true) if adoption_value is Dictionary else {}
	process_adoption_target = (adoption_target_value as Dictionary).duplicate(true) if adoption_target_value is Dictionary else {}
	process_adoption_rate = (adoption_rate_value as Dictionary).duplicate(true) if adoption_rate_value is Dictionary else {}

	processes = {}

	for process_id_value in source_processes.keys():
		var process_id: String = str(process_id_value)
		var source_value: Variant = source_processes.get(process_id_value, null)
		if not source_value is Dictionary:
			return false
		var source_process: Dictionary = source_value

		var share_value: Variant = capacity_shares.get(process_id, null)
		if share_value == null:
			return false
		var share: float = float(share_value)
		if share < 0.0 or share > 1.0:
			return false

		var active: bool = bool(source_process.get("active", false))
		var capacity: float = maxf(float(source_process.get("capacity", 0.0)), 0.0)
		var efficiency: float = maxf(float(source_process.get("efficiency", 1.0)), 0.0)
		var adoption: float = clampf(float(process_adoption.get(process_id, 1.0)), 0.0, 1.0)

		var definition_value: Variant = process_definitions.get(process_id, null)
		var labor_need: float = 0.0
		var resource_demand: Dictionary = {}
		if definition_value is Dictionary:
			var definition: Dictionary = definition_value
			labor_need = maxf(float(definition.get("labor_requirement", 0.0)), 0.0) * capacity * adoption
			var inputs_value: Variant = definition.get("inputs", {})
			if inputs_value is Dictionary:
				for resource_id_value in inputs_value.keys():
					var resource_id: String = str(resource_id_value)
					var per_capacity: float = maxf(float(inputs_value[resource_id_value]), 0.0)
					# Gross input demand seed. Existing monthly ProductionProcessSystem remains authoritative.
					resource_demand[resource_id] = capacity * share * adoption * efficiency * per_capacity

		processes[process_id] = {
			"active": active,
			"capacity": capacity * share,
			"efficiency": efficiency,
			"adoption": adoption,
			"capacity_share": share,
			"source_capacity": capacity,
			"source_efficiency": efficiency,
			"labor_need": labor_need * share,
			"resource_demand": resource_demand.duplicate(true),
			"province_authority": false
		}

	industry_authority = "regional_seed"
	province_industry_authority = false
	return is_valid()


func set_process_capacity(process_id: String, new_capacity: float) -> bool:
	if process_id.is_empty() or not processes.has(process_id):
		return false

	var process_value: Variant = processes.get(process_id, null)
	if not process_value is Dictionary:
		return false

	var process: Dictionary = process_value
	process["capacity"] = maxf(new_capacity, 0.0)
	processes[process_id] = process
	return true


func is_valid() -> bool:
	if region_id.is_empty() or structural_country_id.is_empty():
		return false
	if not source_country_industry_state.has("processes"):
		return false
	if not source_country_industry_state["processes"] is Dictionary:
		return false
	if not processes is Dictionary:
		return false
	for process_id_value in processes.keys():
		var process_value: Variant = processes[process_id_value]
		if not process_value is Dictionary:
			return false
		var process: Dictionary = process_value
		var capacity: float = float(process.get("capacity", -1.0))
		var efficiency: float = float(process.get("efficiency", -1.0))
		var adoption: float = float(process.get("adoption", -1.0))
		var share: float = float(process.get("capacity_share", -1.0))
		if capacity < 0.0 or efficiency < 0.0 or adoption < 0.0 or adoption > 1.0 or share < 0.0 or share > 1.0:
			return false
	return true


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_country_industry_state": source_country_industry_state.duplicate(true),
		"processes": processes.duplicate(true),
		"process_adoption": process_adoption.duplicate(true),
		"process_adoption_target": process_adoption_target.duplicate(true),
		"process_adoption_rate": process_adoption_rate.duplicate(true),
		"industry_authority": industry_authority,
		"province_industry_authority": province_industry_authority
	}


func _validate_source_state(source_state: Dictionary) -> bool:
	if not source_state.has("processes"):
		return false
	if not source_state["processes"] is Dictionary:
		return false
	return true
