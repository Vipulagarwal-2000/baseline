class_name CoreCountryRegistry
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.1
# CORE COUNTRY REGISTRY
# ============================================================
#
# This registry defines which countries remain fully simulated by
# the MVP. It does not create, copy, or own country simulation state.
#
# Authoritative country state remains on the existing WorldState /,
# SimEntity and component instances loaded by WorldLoader.
# ============================================================

const CORE_COUNTRY_IDS: Array[String] = [
	"china",
	"india",
	"usa"
]

const CORE_COUNTRY_NAMES: Dictionary = {
	"china": "China",
	"india": "India",
	"usa": "United States"
}


static func get_core_country_ids() -> Array[String]:
	return CORE_COUNTRY_IDS.duplicate()


static func is_core_country(country_id: String) -> bool:
	return CORE_COUNTRY_IDS.has(
		country_id.to_lower()
	)


static func get_core_country_name(country_id: String) -> String:
	return str(
		CORE_COUNTRY_NAMES.get(
			country_id.to_lower(),
			""
		)
	)


static func resolve_core_countries(world: WorldState) -> Dictionary:
	var resolved: Dictionary = {}

	if world == null:
		return resolved

	for country_id in CORE_COUNTRY_IDS:
		var entity = world.get_entity(country_id)

		if entity != null:
			resolved[country_id] = entity

	return resolved
