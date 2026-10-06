class_name RegionalTerrainState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.3
# EXPLICIT REGIONAL TERRAIN STATE
# ============================================================
#
# Step 12.3 keeps terrain as a bounded regional layer. It does not
# replace the country-level geography component and it does not mutate
# the Region hierarchy.
#
# Province nodes inherit their parent region profile in this MVP unless
# a future province-level override is explicitly supplied.
# ============================================================

const MIN_FACTOR: float = 0.0
const MAX_FACTOR: float = 1.0

var region_id: String = ""
var structural_country_id: String = ""
var source_profile_id: String = ""
var inherited_from_parent: bool = false

var mountains: float = 0.0
var plateaus: float = 0.0
var deserts: float = 0.0
var plains: float = 0.0
var coastal_lowlands: float = 0.0
var major_rivers: float = 0.0
var coastal_access: bool = false

# Derived, deterministic modifiers intended for later systems.
# These are not separate authorities; they are functions of the stored
# terrain profile and therefore remain reproducible.
var mobility_modifier: float = 1.0
var agriculture_modifier: float = 1.0
var infrastructure_cost_modifier: float = 1.0
var defense_modifier: float = 1.0


func _init(
	terrain_region_id: String,
	country_id: String,
	profile_id: String,
	inherited_profile: bool = false
) -> void:
	region_id = terrain_region_id
	structural_country_id = country_id
	source_profile_id = profile_id
	inherited_from_parent = inherited_profile


func apply_profile(profile: Dictionary) -> bool:
	if typeof(profile) != TYPE_DICTIONARY:
		return false

	var required_keys := [
		"mountains",
		"plateaus",
		"deserts",
		"plains",
		"coastal_lowlands",
		"major_rivers",
        "coastal_access"
	]

	for key in required_keys:
		if not profile.has(key):
			return false

	mountains = _clamp_factor(float(profile["mountains"]))
	plateaus = _clamp_factor(float(profile["plateaus"]))
	deserts = _clamp_factor(float(profile["deserts"]))
	plains = _clamp_factor(float(profile["plains"]))
	coastal_lowlands = _clamp_factor(float(profile["coastal_lowlands"]))
	major_rivers = _clamp_factor(float(profile["major_rivers"]))
	coastal_access = bool(profile["coastal_access"])

	_recalculate_modifiers()
	return true


func is_valid() -> bool:
	return (
		not region_id.is_empty()
		and not structural_country_id.is_empty()
		and not source_profile_id.is_empty()
		and _is_factor_valid(mountains)
		and _is_factor_valid(plateaus)
		and _is_factor_valid(deserts)
		and _is_factor_valid(plains)
		and _is_factor_valid(coastal_lowlands)
		and _is_factor_valid(major_rivers)
		and _modifier_is_valid(mobility_modifier)
		and _modifier_is_valid(agriculture_modifier)
		and _modifier_is_valid(infrastructure_cost_modifier)
		and _modifier_is_valid(defense_modifier)
	)


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_profile_id": source_profile_id,
		"inherited_from_parent": inherited_from_parent,
		"mountains": mountains,
		"plateaus": plateaus,
		"deserts": deserts,
		"plains": plains,
		"coastal_lowlands": coastal_lowlands,
		"major_rivers": major_rivers,
		"coastal_access": coastal_access,
		"mobility_modifier": mobility_modifier,
		"agriculture_modifier": agriculture_modifier,
		"infrastructure_cost_modifier": infrastructure_cost_modifier,
		"defense_modifier": defense_modifier
	}


func _recalculate_modifiers() -> void:
	mobility_modifier = clamp(
		1.0
		- (0.45 * mountains)
		- (0.15 * plateaus)
		- (0.12 * deserts)
		+ (0.15 * plains),
		0.35,
		1.10
	)

	agriculture_modifier = clamp(
		0.65
		+ (0.35 * plains)
		+ (0.20 * major_rivers)
		+ (0.10 * coastal_lowlands)
		- (0.25 * deserts)
		- (0.20 * mountains),
		0.35,
		1.20
	)

	infrastructure_cost_modifier = clamp(
		1.0
		+ (0.45 * mountains)
		+ (0.15 * plateaus)
		+ (0.12 * deserts)
		- (0.15 * plains),
		0.85,
		1.80
	)

	defense_modifier = clamp(
		1.0
		+ (0.45 * mountains)
		+ (0.20 * plateaus)
		+ (0.08 * deserts)
		- (0.12 * plains),
		0.90,
		1.60
	)


func _clamp_factor(value: float) -> float:
	return clamp(value, MIN_FACTOR, MAX_FACTOR)


func _is_factor_valid(value: float) -> bool:
	return value >= MIN_FACTOR and value <= MAX_FACTOR


func _modifier_is_valid(value: float) -> bool:
	return is_finite(value) and value > 0.0
