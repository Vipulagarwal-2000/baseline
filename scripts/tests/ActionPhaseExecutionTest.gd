class_name ActionPhaseExecutionTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"STEP 15.3 — ACTIONS PHASE → ACTION MANAGER EXECUTION TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	if simulation == null:
		TestLogger.write_line(
			"Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)
	TestLogger.write_line(
		"Simulation available: PASS"
	)

	# ------------------------------------------------------------
	# 1. AUTHORITATIVE REGISTRATION
	# ------------------------------------------------------------

	var registered_manager: ActionManager = (
		simulation.get_system("action_manager")
		as ActionManager
	)

	var registration_pass: bool = (
		registered_manager != null
		and registered_manager == simulation.action_manager
	)

	TestLogger.write_line(
		"SimulationEngine registers its ActionManager: "
		+ ("PASS" if registration_pass else "FAIL")
	)

	var actions_phase_pass: bool = false
	var action_manager_order_pass: bool = false
	var system_order: Array = simulation.get_system_order()

	for entry_variant in system_order:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = entry_variant
		var name: String = String(
			entry.get("name", "")
		)
		if name != "action_manager":
			continue

		var phase: String = String(
			entry.get("phase", "")
		)
		var order: int = int(
			entry.get("order", -1)
		)

		actions_phase_pass = (
			phase == SimulationPhase.ACTIONS
		)
		action_manager_order_pass = (
			order == 10
		)
		break

	TestLogger.write_line(
		"ActionManager registered in ACTIONS phase: "
		+ ("PASS" if actions_phase_pass else "FAIL")
	)

	TestLogger.write_line(
		"ActionManager uses deterministic ACTIONS order 10: "
		+ ("PASS" if action_manager_order_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 2. ISOLATED RUNTIME PROOF
	# ------------------------------------------------------------
	# Use a minimal isolated world so the full production simulation
	# state is not advanced or mutated by this test.

	var test_config: SimulationConfig = (
		SimulationConfig.create_default()
	)
	var test_world: WorldState = WorldState.new(
		test_config
	)

	var actor: SimEntity = SimEntity.new(
		"step15_3_actor",
		"Step 15.3 Actor",
		"country"
	)
	var target: SimEntity = SimEntity.new(
		"step15_3_target",
		"Step 15.3 Target",
		"country"
	)

	test_world.add_entity(actor)
	test_world.add_entity(target)

	actor.set_relationship(
		target.id,
		0.0
	)

	var isolated_simulation: SimulationEngine = (
		SimulationEngine.new(test_world)
	)

	var test_action: SimAction = SimAction.new(
		"diplomatic_outreach",
		actor.id,
		target.id,
		10.0,
		1
	)

	var queued: bool = isolated_simulation.add_action(
		test_action
	)
	var queued_pass: bool = (
		queued
		and isolated_simulation.get_pending_action_count() == 1
	)

	TestLogger.write_line(
		"Executable action enters ActionManager queue: "
		+ ("PASS" if queued_pass else "FAIL")
	)

	var diplomatic_before: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var relationship_before: float = actor.get_relationship(
		target.id,
		0.0
	)

	# The test intentionally advances the normal simulation entry point.
	# It never bypasses the registered ACTIONS phase with a direct manager call.
	isolated_simulation.tick_month()

	var diplomatic_after: float = actor.get_relationship_dimension(
		target.id,
		"diplomatic",
		0.0
	)

	var relationship_after: float = actor.get_relationship(
		target.id,
		0.0
	)

	# The diplomatic action value is authoritative in the diplomatic
	# relationship dimension. Overall relationship is a derived aggregate
	# and must not be used as the raw action-effect assertion.
	var diplomatic_effect_pass: bool = is_equal_approx(
		diplomatic_after,
		diplomatic_before + 10.0
	)

	var derived_relationship_changed_pass: bool = (
		not is_equal_approx(
			relationship_after,
			relationship_before
		)
	)

	TestLogger.write_line(
		"Normal monthly tick applies diplomatic effect through the authoritative dimension: "
		+ ("PASS" if diplomatic_effect_pass else "FAIL")
	)

	TestLogger.write_line(
		"Derived overall relationship reflects the completed diplomatic effect: "
		+ ("PASS" if derived_relationship_changed_pass else "FAIL")
	)

	var queue_drained_pass: bool = (
		isolated_simulation.get_pending_action_count() == 0
	)

	TestLogger.write_line(
		"Completed action is removed from pending queue: "
		+ ("PASS" if queue_drained_pass else "FAIL")
	)

	var duration_completion_pass: bool = (
		test_action.duration_months == 0
	)

	TestLogger.write_line(
		"One-month action reaches completion boundary: "
		+ ("PASS" if duration_completion_pass else "FAIL")
	)

	# ------------------------------------------------------------
	# 3. SINGLE-PATH GUARANTEE
	# ------------------------------------------------------------
	# The isolated SimulationEngine is itself the execution path. The
	# action phase is therefore exercised through SimulationEngine.tick_month,
	# rather than an ad-hoc direct ActionManager call.

	var isolated_registered_manager: ActionManager = (
		isolated_simulation.get_system("action_manager")
		as ActionManager
	)
	var single_path_pass: bool = (
		isolated_registered_manager != null
	)

	TestLogger.write_line(
		"ACTIONS execution uses the registered ActionManager path: "
		+ ("PASS" if single_path_pass else "FAIL")
	)

	var passed: bool = (
		registration_pass
		and actions_phase_pass
		and action_manager_order_pass
		and queued_pass
		and diplomatic_effect_pass
		and derived_relationship_changed_pass
		and queue_drained_pass
		and duration_completion_pass
		and single_path_pass
	)

	TestLogger.write_line(
		"Step 15.3 ACTIONS Phase → ActionManager execution test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
