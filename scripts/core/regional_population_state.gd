class_name RegionalPopulationState
extends RefCounted


# ============================================================
# REGIONALIZATION — STEP 12.4
# REGIONAL POPULATION STATE
# ============================================================


var region_id: String = ""
var structural_country_id: String = ""

var source_country_population: float = 0.0
var allocation_share: float = 0.0

var population: float = 0.0
var urbanization: float = 0.0
var population_growth_rate: float = 0.0
var birth_rate: float = 0.0
var death_rate: float = 0.0
var migration_in: float = 0.0
var migration_out: float = 0.0

var population_authority: String = "regional_seed"
var migration_authority: String = "country"
var province_population_authority: bool = false

var population_capacity_enabled: bool = false
var population_capacity: float = 0.0


func _init(
	target_region_id: String = "",
	target_country_id: String = ""
) -> void:
	region_id = target_region_id
	structural_country_id = target_country_id


func apply_localization(
	country_population: float,
	share: float,
	regional_urbanization: float,
	regional_growth_rate: float,
	regional_birth_rate: float,
	regional_death_rate: float,
	regional_migration_in: float,
	regional_migration_out: float
) -> bool:
	if country_population < 0.0:
		return false
	if share < 0.0 or share > 1.0:
		return false
	if regional_urbanization < 0.0:
		return false
	if regional_growth_rate < 0.0:
		return false
	if regional_birth_rate < 0.0 or regional_death_rate < 0.0:
		return false
	if regional_migration_in < 0.0 or regional_migration_out < 0.0:
		return false

	source_country_population = country_population
	allocation_share = share
	population = country_population * share
	urbanization = regional_urbanization
	population_growth_rate = regional_growth_rate
	birth_rate = regional_birth_rate
	death_rate = regional_death_rate
	migration_in = regional_migration_in
	migration_out = regional_migration_out

	population_authority = "regional_seed"
	migration_authority = "country"
	province_population_authority = false

	_sanitize()
	return is_valid()


func _sanitize() -> void:
	source_country_population = maxf(source_country_population, 0.0)
	allocation_share = clampf(allocation_share, 0.0, 1.0)
	population = maxf(population, 0.0)
	urbanization = maxf(urbanization, 0.0)
	population_growth_rate = maxf(population_growth_rate, 0.0)
	birth_rate = maxf(birth_rate, 0.0)
	death_rate = maxf(death_rate, 0.0)
	migration_in = maxf(migration_in, 0.0)
	migration_out = maxf(migration_out, 0.0)


func is_valid() -> bool:
	return (
		not region_id.is_empty()
		and not structural_country_id.is_empty()
		and source_country_population >= 0.0
		and allocation_share >= 0.0
		and allocation_share <= 1.0
		and population >= 0.0
		and urbanization >= 0.0
		and population_growth_rate >= 0.0
		and birth_rate >= 0.0
		and death_rate >= 0.0
		and migration_in >= 0.0
		and migration_out >= 0.0
	)


func to_snapshot_dict() -> Dictionary:
	return {
		"region_id": region_id,
		"structural_country_id": structural_country_id,
		"source_country_population": source_country_population,
		"allocation_share": allocation_share,
		"population": population,
		"urbanization": urbanization,
		"population_growth_rate": population_growth_rate,
		"birth_rate": birth_rate,
		"death_rate": death_rate,
		"migration_in": migration_in,
		"migration_out": migration_out,
		"population_authority": population_authority,
		"migration_authority": migration_authority,
		"province_population_authority": province_population_authority,
		"population_capacity_enabled": population_capacity_enabled,
		"population_capacity": population_capacity
	}
