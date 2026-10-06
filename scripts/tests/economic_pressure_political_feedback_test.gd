class_name EconomicPressurePoliticalFeedbackTest
extends RefCounted


# ============================================================
# POPULATION — STEP 9.4 TEST
# ECONOMIC PRESSURE -> POLITICAL PRESSURE
# ============================================================
#
# Validates:
# - registered Step 9.4 system
# - economic + welfare pressure inputs
# - deterministic bounded political-pressure contribution
# - canonical government political_pressure changes
# - approval remains untouched
# - repeated processing is idempotent
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
		"ECONOMIC PRESSURE -> POLITICAL PRESSURE 9.4 TEST"
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
		"economic_pressure_political_feedback_system"
	)

	var system_ok: bool = (
		system_instance != null
		and system_instance is EconomicPressurePoliticalFeedbackSystem
	)

	TestLogger.write_line(
		"Registered EconomicPressurePoliticalFeedbackSystem available: "
		+ (
			"PASS"
			if system_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and system_ok

	if not system_ok:
		return false

	var system: EconomicPressurePoliticalFeedbackSystem = (
		system_instance as EconomicPressurePoliticalFeedbackSystem
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

	var economy = india.get_component(
		"economy"
	)
	var population = india.get_component(
		"population"
	)
	var government = india.get_component(
		"government"
	)

	var components_ok: bool = (
		economy != null
		and population != null
		and government != null
	)

	TestLogger.write_line(
		"India economy/population/government components available: "
		+ (
			"PASS"
			if components_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and components_ok

	if not components_ok:
		return false

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)
	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)
	var original_government_state: Dictionary = (
		government.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# Controlled fixture
	# ------------------------------------------------------------

	economy.set_state(
		"economic_pressure",
		0.60
	)

	population.set_state(
		"welfare_pressure",
		0.80
	)

	government.set_state(
		"political_pressure",
		0.30
	)

	var original_approval: float = float(
		government.get_state(
			"approval",
			0.0
		)
	)

	system.process_month(
		world
	)

	var expected_social_pressure: float = 0.80
	var expected_contribution: float = 0.40
	var expected_political_pressure: float = 0.40

	var actual_social_pressure: float = 0.0
	var actual_contribution: float = float(
		government.get_state(
			"economic_political_pressure",
			-1.0
		)
	)
	var actual_political_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var ledger_value: Variant = government.get_state(
		"economic_political_pressure_ledger",
		{}
	)

	if ledger_value is Dictionary:
		actual_social_pressure = float(
			ledger_value.get(
				"social_economic_pressure",
				-1.0
			)
		)

	var deterministic_ok: bool = (
		is_equal_approx(
			actual_social_pressure,
			expected_social_pressure
		)
		and is_equal_approx(
			actual_contribution,
			expected_contribution
		)
		and is_equal_approx(
			actual_political_pressure,
			expected_political_pressure
		)
	)

	TestLogger.write_line(
		"Severe economic/social pressure converts deterministically: "
		+ (
			"PASS"
			if deterministic_ok
			else "FAIL"
		)
		+ " | expected_social="
		+ str(expected_social_pressure)
		+ " actual_social="
		+ str(actual_social_pressure)
		+ " expected_contribution="
		+ str(expected_contribution)
		+ " actual_contribution="
		+ str(actual_contribution)
		+ " expected_political="
		+ str(expected_political_pressure)
		+ " actual_political="
		+ str(actual_political_pressure)
	)

	all_passed = all_passed and deterministic_ok

	# ------------------------------------------------------------
	# Source-state preservation
	# ------------------------------------------------------------

	var source_state_ok: bool = (
		is_equal_approx(
			float(
				economy.get_state(
					"economic_pressure",
					-1.0
				)
			),
			0.60
		)
		and is_equal_approx(
			float(
				population.get_state(
					"welfare_pressure",
					-1.0
				)
			),
			0.80
		)
	)

	TestLogger.write_line(
		"Economic/welfare source pressure remains unchanged: "
		+ (
			"PASS"
			if source_state_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and source_state_ok

	# Step 9.4 intentionally does not modify approval.
	var approval_preserved_ok: bool = is_equal_approx(
		float(
			government.get_state(
				"approval",
				-1.0
			)
		),
		original_approval
	)

	TestLogger.write_line(
		"Government approval remains unchanged in Step 9.4: "
		+ (
			"PASS"
			if approval_preserved_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and approval_preserved_ok

	# ------------------------------------------------------------
	# Idempotence
	# ------------------------------------------------------------

	var revision_before_repeat: int = int(
		government.get_state(
			"economic_political_pressure_revision",
			0
		)
	)

	var pressure_before_repeat: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	system.process_month(
		world
	)

	var revision_after_repeat: int = int(
		government.get_state(
			"economic_political_pressure_revision",
			0
		)
	)

	var pressure_after_repeat: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var repeated_contribution: float = float(
		government.get_state(
			"economic_political_pressure",
			-1.0
		)
	)

	var idempotent_ok: bool = (
		revision_after_repeat == revision_before_repeat
		and is_equal_approx(
			pressure_after_repeat,
			pressure_before_repeat
		)
		and is_equal_approx(
			repeated_contribution,
			expected_contribution
		)
	)

	TestLogger.write_line(
		"Repeated economic-to-political processing is idempotent: "
		+ (
			"PASS"
			if idempotent_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and idempotent_ok

	# ------------------------------------------------------------
	# Existing higher pressure is never erased
	# ------------------------------------------------------------

	economy.set_state(
		"economic_pressure",
		0.10
	)

	population.set_state(
		"welfare_pressure",
		0.10
	)

	government.set_state(
		"political_pressure",
		0.60
	)

	system.process_month(
		world
	)

	var preserved_existing_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var preserved_existing_ok: bool = is_equal_approx(
		preserved_existing_pressure,
		0.60
	)

	TestLogger.write_line(
		"Existing political pressure is not erased by low economic/social pressure: "
		+ (
			"PASS"
			if preserved_existing_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and preserved_existing_ok

	# ------------------------------------------------------------
	# Severe economic pressure alone still produces a signal
	# ------------------------------------------------------------

	economy.set_state(
		"economic_pressure",
		0.90
	)

	population.set_state(
		"welfare_pressure",
		0.20
	)

	government.set_state(
		"political_pressure",
		0.10
	)

	system.process_month(
		world
	)

	var severe_economic_contribution: float = float(
		government.get_state(
			"economic_political_pressure",
			-1.0
		)
	)

	var severe_economic_pressure: float = float(
		government.get_state(
			"political_pressure",
			-1.0
		)
	)

	var severe_economic_ok: bool = (
		is_equal_approx(
			severe_economic_contribution,
			0.45
		)
		and is_equal_approx(
			severe_economic_pressure,
			0.45
		)
	)

	TestLogger.write_line(
		"Severe economic pressure alone raises political pressure: "
		+ (
			"PASS"
			if severe_economic_ok
			else "FAIL"
		)
		+ " | contribution="
		+ str(severe_economic_contribution)
		+ " political="
		+ str(severe_economic_pressure)
	)

	all_passed = all_passed and severe_economic_ok

	# ------------------------------------------------------------
	# Ledger / result state
	# ------------------------------------------------------------

	var final_ledger_value: Variant = government.get_state(
		"economic_political_pressure_ledger",
		{}
	)

	var final_result_value: Variant = government.get_state(
		"economic_political_pressure_last_result",
		{}
	)

	var ledger_result_ok: bool = (
		final_ledger_value is Dictionary
		and final_ledger_value.has(
			"economic_pressure"
		)
		and final_ledger_value.has(
			"welfare_pressure"
		)
		and final_ledger_value.has(
			"social_economic_pressure"
		)
		and final_ledger_value.has(
			"political_pressure_contribution"
		)
		and final_result_value is Dictionary
		and final_result_value.has(
			"action"
		)
		and final_result_value.has(
			"revision"
		)
		and final_result_value.has(
			"inputs"
		)
	)

	TestLogger.write_line(
		"Economic-political ledger and result state are explicit: "
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
		and snapshot_state.has(
			"political_pressure"
		)
		and snapshot_state.has(
			"economic_political_pressure"
		)
		and snapshot_state.has(
			"economic_political_pressure_ledger"
		)
		and snapshot_state.has(
			"economic_political_pressure_revision"
		)
	)

	TestLogger.write_line(
		"WorldSnapshot preserves economic-political pressure state: "
		+ (
			"PASS"
			if snapshot_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and snapshot_ok

	var live_political_pressure: float = float(
		government.get_state(
			"political_pressure",
			0.0
		)
	)

	var snapshot_copy = snapshot_government.get(
		"state",
		{}
	)

	if snapshot_copy is Dictionary:
		snapshot_copy["political_pressure"] = (
			live_political_pressure
			+ 0.10
		)

	var live_unchanged_ok: bool = is_equal_approx(
		float(
			government.get_state(
				"political_pressure",
				-1.0
			)
		),
		live_political_pressure
	)

	TestLogger.write_line(
		"WorldSnapshot political-pressure state is deep-copy isolated: "
		+ (
			"PASS"
			if live_unchanged_ok
			else "FAIL"
		)
	)

	all_passed = all_passed and live_unchanged_ok

	# ------------------------------------------------------------
	# Restore
	# ------------------------------------------------------------

	economy.state = original_economy_state.duplicate(true)
	population.state = original_population_state.duplicate(true)
	government.state = original_government_state.duplicate(true)

	TestLogger.write_line(
		"Step 9.4 economy/population/government state restoration: PASS"
	)

	TestLogger.section(
		"ECONOMIC PRESSURE -> POLITICAL PRESSURE RESULT"
	)

	TestLogger.write_line(
		"Economic Pressure -> Political Pressure 9.4 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
