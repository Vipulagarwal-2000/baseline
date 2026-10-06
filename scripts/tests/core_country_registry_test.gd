class_name CoreCountryRegistryTest
extends RefCounted


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.1
# CORE COUNTRY REGISTRY TEST
# ============================================================
#
# Validates that China, India and the United States remain the
# fully simulated authoritative core-country entities.
#
# The test does not create replacement country state and does not
# mutate the world. It resolves the existing entities through the
# registry and checks the authoritative component structure used by
# the current three-country validation gate.
# ============================================================

const REQUIRED_AUTHORITATIVE_COMPONENTS: Array[String] = [
	"population",
	"economy",
	"government",
	"resources",
	"research",
	"technology_adoption"
]


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"CORE COUNTRY REGISTRY 10.1 TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"Simulation available: PASS"
	)

	var expected_ids: Array[String] = [
		"china",
		"india",
		"usa"
	]

	var registry_ids: Array[String] = (
		CoreCountryRegistry.get_core_country_ids()
	)

	var registry_ids_ok: bool = (
		registry_ids == expected_ids
	)

	TestLogger.write_line(
		"Core country IDs are exactly China/India/USA: "
		+ ("PASS" if registry_ids_ok else "FAIL")
	)
	all_passed = all_passed and registry_ids_ok

	var unknown_country_ok: bool = (
		not CoreCountryRegistry.is_core_country("soviet_union")
		and not CoreCountryRegistry.is_core_country("external_country")
	)

	TestLogger.write_line(
		"Unknown/external IDs are not core countries: "
		+ ("PASS" if unknown_country_ok else "FAIL")
	)
	all_passed = all_passed and unknown_country_ok

	var resolve_snapshot: Dictionary = (
		CoreCountryRegistry.resolve_core_countries(world)
	)

	var resolve_count_ok: bool = (
		resolve_snapshot.size() == expected_ids.size()
	)

	TestLogger.write_line(
		"All three core countries resolve from existing WorldState: "
		+ ("PASS" if resolve_count_ok else "FAIL")
	)
	all_passed = all_passed and resolve_count_ok

	for country_id in expected_ids:

		var entity = world.get_entity(country_id)
		var resolved_entity = resolve_snapshot.get(
			country_id,
			null
		)

		var entity_available: bool = (
			entity != null
		)

		TestLogger.write_line(
			country_id + " authoritative entity available: "
			+ ("PASS" if entity_available else "FAIL")
		)
		all_passed = all_passed and entity_available

		if not entity_available:
			continue

		var authoritative_identity_ok: bool = (
			resolved_entity == entity
			and entity.id == country_id
		)

		TestLogger.write_line(
			country_id + " registry resolves existing authoritative entity: "
			+ ("PASS" if authoritative_identity_ok else "FAIL")
		)
		all_passed = all_passed and authoritative_identity_ok

		var components_ok: bool = true
		for component_name in REQUIRED_AUTHORITATIVE_COMPONENTS:
			if entity.get_component(component_name) == null:
				components_ok = false
				break

		TestLogger.write_line(
			country_id + " retains required authoritative simulation components: "
			+ ("PASS" if components_ok else "FAIL")
		)
		all_passed = all_passed and components_ok

		# The registry must not mutate the existing authoritative state.
		var before_component_keys: Array = entity.components.keys()
		var before_component_states: Dictionary = {}

		for component_name in REQUIRED_AUTHORITATIVE_COMPONENTS:
			var component = entity.get_component(component_name)
			if component != null:
				before_component_states[component_name] = (
					component.state.duplicate(true)
				)

		CoreCountryRegistry.resolve_core_countries(world)

		var keys_unchanged: bool = (
			entity.components.keys() == before_component_keys
		)

		var state_unchanged: bool = true
		for component_name in before_component_states.keys():
			var current_component = entity.get_component(component_name)
			if current_component == null:
				state_unchanged = false
				break
			if current_component.state != before_component_states[component_name]:
				state_unchanged = false
				break

		TestLogger.write_line(
			country_id + " authoritative state is not duplicated or mutated by registry: "
			+ (
				"PASS"
				if keys_unchanged and state_unchanged
				else "FAIL"
			)
		)
		all_passed = all_passed and keys_unchanged and state_unchanged

	var first_ids: Array[String] = (
		CoreCountryRegistry.get_core_country_ids()
	)
	var second_ids: Array[String] = (
		CoreCountryRegistry.get_core_country_ids()
	)
	var deterministic_ok: bool = (
		first_ids == second_ids
		and CoreCountryRegistry.resolve_core_countries(world).keys()
			== CoreCountryRegistry.resolve_core_countries(world).keys()
	)

	TestLogger.write_line(
		"Core-country registry resolution is deterministic: "
		+ ("PASS" if deterministic_ok else "FAIL")
	)
	all_passed = all_passed and deterministic_ok

	TestLogger.write_line(
		"Core Country Registry 10.1 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
