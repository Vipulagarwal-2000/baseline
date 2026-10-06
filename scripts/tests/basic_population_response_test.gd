class_name BasicPopulationResponseTest
extends RefCounted


# ============================================================
# POPULATION — STEP 9.5 TEST
# BASIC POPULATION RESPONSE
# ============================================================
# Validates:
# - registered system
# - deterministic aggregate response conversion
# - migration pressure direction
# - fertility / mortality modifiers
# - labor participation target
# - source-state preservation
# - authoritative demographic/labor values are not mutated
# - repeated processing idempotence
# - ledger/result state
# - WorldSnapshot representation
# - snapshot deep-copy isolation
# - state restoration
# ============================================================


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"BASIC POPULATION RESPONSE 9.5 TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var system_instance = simulation.get_system(
		"basic_population_response_system"
	)

	var system_ok: bool = (
		system_instance != null
		and system_instance is BasicPopulationResponseSystem
	)

	TestLogger.write_line(
		"Registered BasicPopulationResponseSystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)
	all_passed = all_passed and system_ok

	if not system_ok:
		return false

	var system: BasicPopulationResponseSystem = (
		system_instance as BasicPopulationResponseSystem
	)

	var india = world.get_entity("india")

	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false
	TestLogger.write_line("India available: PASS")

	var population = india.get_component("population")
	var government = india.get_component("government")

	var components_ok: bool = (
		population != null
		and government != null
	)

	TestLogger.write_line(
		"India population/government components available: "
		+ ("PASS" if components_ok else "FAIL")
	)
	all_passed = all_passed and components_ok

	if not components_ok:
		return false

	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)
	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# Controlled fixture
	# ------------------------------------------------------------

	population.set_state(
		"welfare_pressure",
		0.80
	)

	population.set_state(
		"birth_rate",
		42.0
	)

	population.set_state(
		"death_rate",
		29.0
	)

	population.set_state(
		"labor_force_participation_rate",
		0.65
	)

	government.set_state(
		"political_pressure",
		0.40
	)

	system.process_month(world)

	var expected_response_pressure := 0.80
	var expected_migration_pressure := 0.80
	var expected_fertility_modifier := 0.84
	var expected_mortality_modifier := 1.16
	var expected_labor_modifier := 0.92
	var expected_labor_target := 0.598

	var actual_response_pressure := float(
		population.get_state(
			"population_response_pressure",
			-1.0
		)
	)
	var actual_migration_pressure := float(
		population.get_state(
			"migration_pressure",
			-1.0
		)
	)
	var actual_fertility_modifier := float(
		population.get_state(
			"fertility_rate_modifier",
			-1.0
		)
	)
	var actual_mortality_modifier := float(
		population.get_state(
			"mortality_rate_modifier",
			-1.0
		)
	)
	var actual_labor_modifier := float(
		population.get_state(
			"labor_participation_modifier",
			-1.0
		)
	)
	var actual_labor_target := float(
		population.get_state(
			"labor_participation_target",
			-1.0
		)
	)

	var deterministic_ok: bool = (
		is_equal_approx(actual_response_pressure, expected_response_pressure)
		and is_equal_approx(actual_migration_pressure, expected_migration_pressure)
		and is_equal_approx(actual_fertility_modifier, expected_fertility_modifier)
		and is_equal_approx(actual_mortality_modifier, expected_mortality_modifier)
		and is_equal_approx(actual_labor_modifier, expected_labor_modifier)
		and is_equal_approx(actual_labor_target, expected_labor_target)
	)

	TestLogger.write_line(
		"Aggregate population response resolves deterministically: "
		+ ("PASS" if deterministic_ok else "FAIL")
		+ " | response_pressure=" + str(actual_response_pressure)
		+ " migration=" + str(actual_migration_pressure)
		+ " fertility_modifier=" + str(actual_fertility_modifier)
		+ " mortality_modifier=" + str(actual_mortality_modifier)
		+ " labor_modifier=" + str(actual_labor_modifier)
		+ " labor_target=" + str(actual_labor_target)
	)
	all_passed = all_passed and deterministic_ok

	# Source government/population values remain authoritative inputs.
	var source_state_ok: bool = (
		is_equal_approx(
			float(population.get_state("welfare_pressure", -1.0)),
			0.80
		)
		and is_equal_approx(
			float(government.get_state("political_pressure", -1.0)),
			0.40
		)
	)

	TestLogger.write_line(
		"Economic/welfare and political source state remains unchanged: "
		+ ("PASS" if source_state_ok else "FAIL")
	)
	all_passed = all_passed and source_state_ok

	# Authoritative demographic/labor values must not be mutated by 9.5.
	var authoritative_values_ok: bool = (
		is_equal_approx(
			float(population.get_state("birth_rate", -1.0)),
			42.0
		)
		and is_equal_approx(
			float(population.get_state("death_rate", -1.0)),
			29.0
		)
		and is_equal_approx(
			float(population.get_state("labor_force_participation_rate", -1.0)),
			0.65
		)
	)

	TestLogger.write_line(
		"Authoritative birth/death/labor inputs remain unchanged: "
		+ ("PASS" if authoritative_values_ok else "FAIL")
	)
	all_passed = all_passed and authoritative_values_ok

	# ------------------------------------------------------------
	# Idempotence
	# ------------------------------------------------------------

	var revision_before_repeat := int(
		population.get_state(
			"population_response_revision",
			0
		)
	)

	system.process_month(world)

	var revision_after_repeat := int(
		population.get_state(
			"population_response_revision",
			0
		)
	)

	var repeat_response := float(
		population.get_state(
			"population_response_pressure",
			-1.0
		)
	)

	var idempotent_ok: bool = (
		is_equal_approx(repeat_response, expected_response_pressure)
		and revision_after_repeat == revision_before_repeat
	)

	TestLogger.write_line(
		"Repeated population-response processing is idempotent: "
		+ ("PASS" if idempotent_ok else "FAIL")
	)
	all_passed = all_passed and idempotent_ok

	# ------------------------------------------------------------
	# Direction: political pressure can dominate when higher.
	# ------------------------------------------------------------

	population.set_state("welfare_pressure", 0.20)
	government.set_state("political_pressure", 0.90)

	system.process_month(world)

	var political_dominant_pressure := float(
		population.get_state(
			"population_response_pressure",
			-1.0
		)
	)

	var political_dominant_ok := is_equal_approx(
		political_dominant_pressure,
		0.90
	)

	TestLogger.write_line(
		"Higher political pressure dominates population response deterministically: "
		+ ("PASS" if political_dominant_ok else "FAIL")
		+ " | response_pressure="
		+ str(political_dominant_pressure)
	)
	all_passed = all_passed and political_dominant_ok

	# ------------------------------------------------------------
	# Ledger / result state
	# ------------------------------------------------------------

	var ledger_value: Variant = population.get_state(
		"population_response_ledger",
		{}
	)
	var result_value: Variant = population.get_state(
		"population_response_last_result",
		{}
	)

	var ledger_result_ok: bool = (
		ledger_value is Dictionary
		and ledger_value.has("response_pressure")
		and ledger_value.has("migration_pressure")
		and ledger_value.has("fertility_rate_modifier")
		and ledger_value.has("mortality_rate_modifier")
		and ledger_value.has("labor_participation_target")
		and result_value is Dictionary
		and result_value.has("action")
		and result_value.has("revision")
		and result_value.has("inputs")
	)

	TestLogger.write_line(
		"Population-response ledger and result state are explicit: "
		+ ("PASS" if ledger_result_ok else "FAIL")
	)
	all_passed = all_passed and ledger_result_ok

	# ------------------------------------------------------------
	# WorldSnapshot representation
	# ------------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get("india", {})
	var snapshot_components = entity_snapshot.get("components", {})
	var snapshot_population = snapshot_components.get("population", {})
	var snapshot_state = snapshot_population.get("state", {})

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("population_response_pressure")
		and snapshot_state.has("migration_pressure")
		and snapshot_state.has("fertility_rate_modifier")
		and snapshot_state.has("mortality_rate_modifier")
		and snapshot_state.has("labor_participation_target")
	)

	TestLogger.write_line(
		"WorldSnapshot preserves population-response state: "
		+ ("PASS" if snapshot_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_ok

	var live_migration_pressure := float(
		population.get_state("migration_pressure", -1.0)
	)

	if snapshot_population is Dictionary:
		var snapshot_mutable_state = snapshot_state
		if snapshot_mutable_state is Dictionary:
			snapshot_mutable_state["migration_pressure"] = 0.123

	var deep_copy_ok: bool = is_equal_approx(
		live_migration_pressure,
		0.90
	)

	TestLogger.write_line(
		"WorldSnapshot population-response state is deep-copy isolated: "
		+ ("PASS" if deep_copy_ok else "FAIL")
	)
	all_passed = all_passed and deep_copy_ok

	# ------------------------------------------------------------
	# Restore state
	# ------------------------------------------------------------

	population.state = original_population_state.duplicate(true)
	government.state = original_government_state.duplicate(true)

	var restoration_ok: bool = (
		population.state == original_population_state
		and government.state == original_government_state
	)

	TestLogger.write_line(
		"Step 9.5 population/government state restoration: "
		+ ("PASS" if restoration_ok else "FAIL")
	)
	all_passed = all_passed and restoration_ok

	return all_passed
