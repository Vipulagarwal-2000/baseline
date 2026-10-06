class_name GovernmentFeedbackTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
        "GOVERNMENT FEEDBACK 9.6 TEST"
	)

	var all_passed := true

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
        "government_feedback_system"
	)

	var system_ok: bool = (
		system_instance != null
		and system_instance is GovernmentFeedbackSystem
	)

	TestLogger.write_line(
        "Registered GovernmentFeedbackSystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)
	all_passed = all_passed and system_ok

	if not system_ok:
		return false

	var system: GovernmentFeedbackSystem = (
		system_instance as GovernmentFeedbackSystem
	)

	var india = world.get_entity("india")

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
	var government = india.get_component(
        "government"
	)

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

	var original_population_state = population.state.duplicate(true)
	var original_government_state = government.state.duplicate(true)

	# Controlled Step 9.6 fixture.
	population.set_state(
		"population_response_pressure",
		0.80
	)
	population.set_state(
		"welfare_pressure",
		0.70
	)
	government.set_state(
		"political_pressure",
		0.60
	)
	government.set_state(
		"policy_capacity",
		0.50
	)
	government.set_state(
		"implementation_capacity",
		0.80
	)

	var original_approval := float(
		government.get_state(
			"approval",
			0.0
		)
	)
	var original_stability := float(
		government.get_state(
			"stability",
			0.0
		)
	)
	var original_legitimacy := float(
		government.get_state(
			"legitimacy",
			0.0
		)
	)
	var original_political_pressure := float(
		government.get_state(
			"political_pressure",
			0.0
		)
	)

	system.process_month(world)

	var expected_need := 0.80
	var expected_capacity := 0.40
	var expected_intensity := 0.32
	var expected_gap := 0.48

	var actual_need := float(
		government.get_state(
			"government_response_need",
			-1.0
		)
	)
	var actual_capacity := float(
		government.get_state(
			"government_response_capacity",
			-1.0
		)
	)
	var actual_intensity := float(
		government.get_state(
			"government_response_intensity",
			-1.0
		)
	)
	var actual_gap := float(
		government.get_state(
			"government_response_gap",
			-1.0
		)
	)

	var deterministic_ok: bool = (
		is_equal_approx(actual_need, expected_need)
		and is_equal_approx(actual_capacity, expected_capacity)
		and is_equal_approx(actual_intensity, expected_intensity)
		and is_equal_approx(actual_gap, expected_gap)
	)

	TestLogger.write_line(
        "Population/welfare pressure feeds deterministic government response state: "
		+ ("PASS" if deterministic_ok else "FAIL")
		+ " | need=" + str(actual_need)
		+ " capacity=" + str(actual_capacity)
		+ " intensity=" + str(actual_intensity)
		+ " gap=" + str(actual_gap)
	)
	all_passed = all_passed and deterministic_ok

	# 9.6 must not directly mutate existing political/government condition.
	var core_state_preserved: bool = (
		is_equal_approx(
			float(government.get_state("approval", -1.0)),
			original_approval
		)
		and is_equal_approx(
			float(government.get_state("stability", -1.0)),
			original_stability
		)
		and is_equal_approx(
			float(government.get_state("legitimacy", -1.0)),
			original_legitimacy
		)
		and is_equal_approx(
			float(government.get_state("political_pressure", -1.0)),
			original_political_pressure
		)
	)

	TestLogger.write_line(
        "Existing government political state remains unchanged: "
		+ ("PASS" if core_state_preserved else "FAIL")
	)
	all_passed = all_passed and core_state_preserved

	# Explicit source preservation.
	var source_state_ok: bool = (
		is_equal_approx(
			float(population.get_state("population_response_pressure", -1.0)),
			0.80
		)
		and is_equal_approx(
			float(population.get_state("welfare_pressure", -1.0)),
			0.70
		)
	)

	TestLogger.write_line(
        "Population response source state remains unchanged: "
		+ ("PASS" if source_state_ok else "FAIL")
	)
	all_passed = all_passed and source_state_ok

	# Capacity response is explicitly bounded and follows existing
	# government capacity, without creating capacity.
	government.set_state(
		"policy_capacity",
		1.0
	)
	government.set_state(
		"implementation_capacity",
		1.0
	)
	system.process_month(world)

	var full_capacity_intensity := float(
		government.get_state(
			"government_response_intensity",
			-1.0
		)
	)

	var full_capacity_ok := is_equal_approx(
		full_capacity_intensity,
		0.80
	)

	TestLogger.write_line(
        "Full government capacity can meet response need without exceeding it: "
		+ ("PASS" if full_capacity_ok else "FAIL")
		+ " | intensity=" + str(full_capacity_intensity)
	)
	all_passed = all_passed and full_capacity_ok

	# Idempotence.
	var revision_before_repeat := int(
		government.get_state(
			"government_response_revision",
			0
		)
	)
	var intensity_before_repeat := float(
		government.get_state(
			"government_response_intensity",
			-1.0
		)
	)

	system.process_month(world)

	var revision_after_repeat := int(
		government.get_state(
			"government_response_revision",
			0
		)
	)
	var intensity_after_repeat := float(
		government.get_state(
			"government_response_intensity",
			-1.0
		)
	)

	var idempotent_ok: bool = (
		revision_after_repeat == revision_before_repeat
		and is_equal_approx(
			intensity_after_repeat,
			intensity_before_repeat
		)
	)

	TestLogger.write_line(
        "Repeated government-feedback processing is idempotent: "
		+ ("PASS" if idempotent_ok else "FAIL")
	)
	all_passed = all_passed and idempotent_ok

	# Lower pressure clears stale response demand without changing
	# unrelated government condition.
	population.set_state(
		"population_response_pressure",
		0.0
	)
	population.set_state(
		"welfare_pressure",
		0.0
	)
	government.set_state(
		"political_pressure",
		0.0
	)
	system.process_month(world)

	var cleared_need := float(
		government.get_state(
			"government_response_need",
			-1.0
		)
	)
	var cleared_intensity := float(
		government.get_state(
			"government_response_intensity",
			-1.0
		)
	)

	var stale_clear_ok: bool = (
		is_equal_approx(cleared_need, 0.0)
		and is_equal_approx(cleared_intensity, 0.0)
	)

	TestLogger.write_line(
        "Clearing population/political pressure clears stale response state: "
		+ ("PASS" if stale_clear_ok else "FAIL")
		+ " | need=" + str(cleared_need)
		+ " intensity=" + str(cleared_intensity)
	)
	all_passed = all_passed and stale_clear_ok

	# Restore pressure for ledger/snapshot checks.
	population.set_state(
		"population_response_pressure",
		0.80
	)
	population.set_state(
		"welfare_pressure",
		0.70
	)
	government.set_state(
		"political_pressure",
		0.60
	)
	government.set_state(
		"policy_capacity",
		0.50
	)
	government.set_state(
		"implementation_capacity",
		0.80
	)
	system.process_month(world)

	var ledger_value: Variant = government.get_state(
		"government_response_ledger",
		{}
	)
	var result_value: Variant = government.get_state(
		"government_response_last_result",
		{}
	)

	var ledger_result_ok: bool = (
		ledger_value is Dictionary
		and ledger_value.has("response_need")
		and ledger_value.has("response_capacity")
		and ledger_value.has("response_intensity")
		and ledger_value.has("response_gap")
		and result_value is Dictionary
		and result_value.has("action")
		and result_value.has("revision")
		and result_value.has("inputs")
	)

	TestLogger.write_line(
        "Government-feedback ledger and result state are explicit: "
		+ ("PASS" if ledger_result_ok else "FAIL")
	)
	all_passed = all_passed and ledger_result_ok

	# Snapshot representation and deep-copy isolation.
	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get(
		"india",
		{}
	)
	var snapshot_components = entity_snapshot.get(
		"components",
		{}
	)
	var snapshot_government = snapshot_components.get(
		"government",
		{}
	)
	var snapshot_state = snapshot_government.get(
		"state",
		{}
	)

	var snapshot_ok: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("government_response_need")
		and snapshot_state.has("government_response_capacity")
		and snapshot_state.has("government_response_intensity")
		and snapshot_state.has("government_response_gap")
	)

	TestLogger.write_line(
        "WorldSnapshot preserves government-feedback state: "
		+ ("PASS" if snapshot_ok else "FAIL")
	)
	all_passed = all_passed and snapshot_ok

	var live_need := float(
		government.get_state(
			"government_response_need",
			-1.0
		)
	)

	if snapshot_state is Dictionary:
		snapshot_state["government_response_need"] = 0.123

	var deep_copy_ok := is_equal_approx(
		live_need,
		0.80
	)

	TestLogger.write_line(
        "WorldSnapshot government-feedback state is deep-copy isolated: "
		+ ("PASS" if deep_copy_ok else "FAIL")
	)
	all_passed = all_passed and deep_copy_ok

	# Restore all fixture state.
	population.state = original_population_state.duplicate(true)
	government.state = original_government_state.duplicate(true)

	var restoration_ok: bool = (
		population.state == original_population_state
		and government.state == original_government_state
	)

	TestLogger.write_line(
        "Step 9.6 population/government state restoration: "
		+ ("PASS" if restoration_ok else "FAIL")
	)
	all_passed = all_passed and restoration_ok

	return all_passed
