class_name WelfareEffectTest
extends RefCounted


# ============================================================
# POPULATION — STEP 9.2 TEST
# WELFARE EFFECT
# ============================================================
#
# Validates:
# - registered system
# - deterministic conversion from living conditions to welfare
# - hardship pressure direction
# - idempotence
# - source-state immutability
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
		"WELFARE EFFECT 9.2 TEST"
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

	var system_instance = simulation.get_system(
		"welfare_effect_system"
	)

	var system_ok: bool = (
		system_instance != null
		and system_instance is WelfareEffectSystem
	)

	TestLogger.write_line(
		"Registered WelfareEffectSystem available: "
		+ (
			"PASS"
			if system_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and system_ok

	if not system_ok:
		return false

	var system: WelfareEffectSystem = (
		system_instance as WelfareEffectSystem
	)

	var india = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var population = india.get_component(
		"population"
	)

	var population_ok: bool = (
		population != null
	)

	TestLogger.write_line(
		"India population component available: "
		+ (
			"PASS"
			if population_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and population_ok

	if not population_ok:
		return false

	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# Controlled fixture
	# ------------------------------------------------------------

	population.set_state(
		"standard_of_living_index",
		0.80
	)

	system.process_month(
		world
	)

	var actual_effect := float(
		population.get_state(
			"welfare_effect",
			999.0
		)
	)

	var actual_pressure := float(
		population.get_state(
			"welfare_pressure",
			999.0
		)
	)

	var expected_effect := 0.30
	var expected_pressure := 0.20

	var deterministic_ok: bool = (
		is_equal_approx(
			actual_effect,
			expected_effect
		)
		and is_equal_approx(
			actual_pressure,
			expected_pressure
		)
	)

	TestLogger.write_line(
		"Controlled Step 9.2 welfare conversion resolves deterministically: "
		+ (
			"PASS"
			if deterministic_ok
			else "FAIL"
		)
		+ " | expected_effect="
		+ str(expected_effect)
		+ " actual_effect="
		+ str(actual_effect)
		+ " expected_pressure="
		+ str(expected_pressure)
		+ " actual_pressure="
		+ str(actual_pressure)
	)

	all_passed = all_passed and deterministic_ok

	# The source living-conditions state is not owned by this system.
	var source_preserved_ok: bool = is_equal_approx(
		float(
			population.get_state(
				"standard_of_living_index",
				-1.0
			)
		),
		0.80
	)

	TestLogger.write_line(
		"Standard-of-living source state remains unchanged: "
		+ (
			"PASS"
			if source_preserved_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and source_preserved_ok

	# ------------------------------------------------------------
	# Idempotence
	# ------------------------------------------------------------

	var revision_before_repeat := int(
		population.get_state(
			"welfare_revision",
			0
		)
	)

	system.process_month(
		world
	)

	var repeated_effect := float(
		population.get_state(
			"welfare_effect",
			999.0
		)
	)

	var repeated_pressure := float(
		population.get_state(
			"welfare_pressure",
			999.0
		)
	)

	var repeated_revision := int(
		population.get_state(
			"welfare_revision",
			0
		)
	)

	var idempotent_ok: bool = (
		is_equal_approx(
			repeated_effect,
			expected_effect
		)
		and is_equal_approx(
			repeated_pressure,
			expected_pressure
		)
		and repeated_revision == revision_before_repeat
	)

	TestLogger.write_line(
		"Repeated welfare processing is idempotent: "
		+ (
			"PASS"
			if idempotent_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and idempotent_ok

	# ------------------------------------------------------------
	# Severe hardship / direction test
	# ------------------------------------------------------------

	population.set_state(
		"standard_of_living_index",
		0.20
	)

	system.process_month(
		world
	)

	var hardship_effect := float(
		population.get_state(
			"welfare_effect",
			999.0
		)
	)

	var hardship_pressure := float(
		population.get_state(
			"welfare_pressure",
			999.0
		)
	)

	var hardship_ok: bool = (
		is_equal_approx(
			hardship_effect,
			-0.30
		)
		and is_equal_approx(
			hardship_pressure,
			0.80
		)
	)

	TestLogger.write_line(
		"Lower living conditions increase welfare pressure deterministically: "
		+ (
			"PASS"
			if hardship_ok
			else "FAIL"
		)
		+ " | effect="
		+ str(hardship_effect)
		+ " pressure="
		+ str(hardship_pressure)
	)

	all_passed = all_passed and hardship_ok

	# ------------------------------------------------------------
	# Ledger / result state
	# ------------------------------------------------------------

	var ledger_value: Variant = (
		population.get_state(
			"welfare_ledger",
			{}
		)
	)

	var ledger_ok: bool = (
		ledger_value is Dictionary
		and ledger_value.has(
			"standard_of_living_index"
		)
		and ledger_value.has(
			"neutral_standard_of_living"
		)
		and ledger_value.has(
			"welfare_effect"
		)
		and ledger_value.has(
			"welfare_pressure"
		)
	)

	var last_result_value: Variant = (
		population.get_state(
			"welfare_last_result",
			{}
		)
	)

	var result_ok: bool = (
		last_result_value is Dictionary
		and last_result_value.has(
			"action"
		)
		and last_result_value.has(
			"revision"
		)
		and last_result_value.has(
			"inputs"
		)
	)

	var ledger_result_ok: bool = (
		ledger_ok
		and result_ok
	)

	TestLogger.write_line(
		"Welfare ledger and result state are explicit: "
		+ (
			"PASS"
			if ledger_result_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and ledger_result_ok

	# ------------------------------------------------------------
	# WorldSnapshot representation
	# ------------------------------------------------------------

	var snapshot := WorldSnapshot.new()

	snapshot.capture(
		world
	)

	var entity_snapshot = snapshot.entities.get(
		"india",
		{}
	)

	var snapshot_components = entity_snapshot.get(
		"components",
		{}
	)

	var snapshot_population = snapshot_components.get(
		"population",
		{}
	)

	var snapshot_state = snapshot_population.get(
		"state",
		{}
	)

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has(
			"welfare_effect"
		)
		and snapshot_state.has(
			"welfare_pressure"
		)
		and snapshot_state.has(
			"welfare_ledger"
		)
		and snapshot_state.has(
			"welfare_revision"
		)
	)

	TestLogger.write_line(
		"WorldSnapshot preserves welfare state: "
		+ (
			"PASS"
			if snapshot_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_ok

	var live_effect := float(
		population.get_state(
			"welfare_effect",
			0.0
		)
	)

	if snapshot_state is Dictionary:
		snapshot_state[
			"welfare_effect"
		] = -999.0

	var snapshot_isolated_ok: bool = is_equal_approx(
		population.get_state(
			"welfare_effect",
			0.0
		),
		live_effect
	)

	TestLogger.write_line(
		"WorldSnapshot welfare state is deep-copy isolated: "
		+ (
			"PASS"
			if snapshot_isolated_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_isolated_ok

	# ------------------------------------------------------------
	# Restore
	# ------------------------------------------------------------

	population.state = original_population_state

	var restored_ok: bool = (
		population.state == original_population_state
	)

	TestLogger.write_line(
		"Step 9.2 population state restoration: "
		+ (
			"PASS"
			if restored_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and restored_ok

	return all_passed
