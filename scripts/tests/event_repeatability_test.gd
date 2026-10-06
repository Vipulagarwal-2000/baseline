class_name EventRepeatabilityTest
extends RefCounted


# ============================================================
# E11 — COOLDOWNS / REPEATABILITY TEST
# ============================================================
#
# Required:
#   one-time event cannot fire twice
#   repeatable event can fire again
#   cooldown blocks during cooldown
#   cooldown expires correctly
#   minimum interval is enforced
#
# Additional safety:
#   event/target histories are isolated
#   invalid policies are rejected
#   repeatability state can be snapshotted/restored
# ============================================================


static func run() -> bool:
	TestLogger.section(
		"EventRepeatabilityController — E11"
	)

	var test_passed: bool = true
	var controller: EventRepeatabilityController = (
		EventRepeatabilityController.new()
	)

	# ------------------------------------------------------------
	# POLICY VALIDATION
	# ------------------------------------------------------------

	var one_time_policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.one_time()
	)
	var repeatable_policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.repeatable()
	)
	var cooldown_policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.cooldown(3)
	)
	var interval_policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.minimum_interval(3)
	)

	var policies_pass: bool = (
		one_time_policy.is_valid()
		and repeatable_policy.is_valid()
		and cooldown_policy.is_valid()
		and interval_policy.is_valid()
	)

	TestLogger.write_line(
		"Repeatability policies validate correctly: "
		+ ("PASS" if policies_pass else "FAIL")
	)

	if not policies_pass:
		test_passed = false


	# ------------------------------------------------------------
	# ONE-TIME
	# ------------------------------------------------------------

	var one_time_first: bool = controller.record_fire(
		one_time_policy,
		"one_time_event",
		"india",
		0
	)

	var one_time_blocked: bool = not controller.can_fire(
		one_time_policy,
		"one_time_event",
		"india",
		1
	)

	var one_time_pass: bool = (
		one_time_first
		and one_time_blocked
		and controller.get_last_fired_tick(
			"one_time_event",
			"india"
		) == 0
	)

	TestLogger.write_line(
		"One-time event cannot fire twice: "
		+ ("PASS" if one_time_pass else "FAIL")
	)

	if not one_time_pass:
		test_passed = false


	# ------------------------------------------------------------
	# REPEATABLE
	# ------------------------------------------------------------

	var repeatable_first: bool = controller.record_fire(
		repeatable_policy,
		"repeatable_event",
		"india",
		0
	)

	var repeatable_second: bool = controller.record_fire(
		repeatable_policy,
		"repeatable_event",
		"india",
		1
	)

	var repeatable_pass: bool = (
		repeatable_first
		and repeatable_second
		and controller.get_last_fired_tick(
			"repeatable_event",
			"india"
		) == 1
	)

	TestLogger.write_line(
		"Repeatable event can fire again: "
		+ ("PASS" if repeatable_pass else "FAIL")
	)

	if not repeatable_pass:
		test_passed = false


	# ------------------------------------------------------------
	# COOLDOWN
	# ------------------------------------------------------------

	var cooldown_first: bool = controller.record_fire(
		cooldown_policy,
		"cooldown_event",
		"india",
		0
	)

	var cooldown_tick_1_blocked: bool = not controller.can_fire(
		cooldown_policy,
		"cooldown_event",
		"india",
		1
	)

	var cooldown_tick_2_blocked: bool = not controller.can_fire(
		cooldown_policy,
		"cooldown_event",
		"india",
		2
	)

	var cooldown_tick_3_blocked: bool = not controller.can_fire(
		cooldown_policy,
		"cooldown_event",
		"india",
		3
	)

	var cooldown_tick_4_allowed: bool = controller.can_fire(
		cooldown_policy,
		"cooldown_event",
		"india",
		4
	)

	var cooldown_pass: bool = (
		cooldown_first
		and cooldown_tick_1_blocked
		and cooldown_tick_2_blocked
		and cooldown_tick_3_blocked
		and cooldown_tick_4_allowed
	)

	TestLogger.write_line(
		"Cooldown blocks during cooldown and expires correctly: "
		+ ("PASS" if cooldown_pass else "FAIL")
	)

	if not cooldown_pass:
		test_passed = false


	# ------------------------------------------------------------
	# MINIMUM INTERVAL
	# ------------------------------------------------------------

	var interval_first: bool = controller.record_fire(
		interval_policy,
		"interval_event",
		"india",
		0
	)

	var interval_tick_1_blocked: bool = not controller.can_fire(
		interval_policy,
		"interval_event",
		"india",
		1
	)

	var interval_tick_2_blocked: bool = not controller.can_fire(
		interval_policy,
		"interval_event",
		"india",
		2
	)

	var interval_tick_3_allowed: bool = controller.can_fire(
		interval_policy,
		"interval_event",
		"india",
		3
	)

	var interval_pass: bool = (
		interval_first
		and interval_tick_1_blocked
		and interval_tick_2_blocked
		and interval_tick_3_allowed
	)

	TestLogger.write_line(
		"Minimum interval is enforced: "
		+ ("PASS" if interval_pass else "FAIL")
	)

	if not interval_pass:
		test_passed = false


	# ------------------------------------------------------------
	# EVENT / TARGET ISOLATION
	# ------------------------------------------------------------

	var isolated_event: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.one_time()
	)

	var isolation_record_a: bool = controller.record_fire(
		isolated_event,
		"isolated_event",
		"india",
		10
	)

	var isolation_other_target_allowed: bool = controller.can_fire(
		isolated_event,
		"isolated_event",
		"china",
		11
	)

	var isolation_other_event_allowed: bool = controller.can_fire(
		isolated_event,
		"another_event",
		"india",
		11
	)

	var isolation_pass: bool = (
		isolation_record_a
		and isolation_other_target_allowed
		and isolation_other_event_allowed
	)

	TestLogger.write_line(
		"Event / target repeatability histories are isolated: "
		+ ("PASS" if isolation_pass else "FAIL")
	)

	if not isolation_pass:
		test_passed = false


	# ------------------------------------------------------------
	# INVALID POLICY
	# ------------------------------------------------------------

	var invalid_policy: EventRepeatabilityPolicy = (
		EventRepeatabilityPolicy.new(
			"cooldown",
			0,
			0
		)
	)

	var invalid_policy_pass: bool = (
		not invalid_policy.is_valid()
		and not controller.can_fire(
			invalid_policy,
			"invalid_event",
			"india",
			0
		)
	)

	TestLogger.write_line(
		"Invalid repeatability policy is rejected safely: "
		+ ("PASS" if invalid_policy_pass else "FAIL")
	)

	if not invalid_policy_pass:
		test_passed = false


	# ------------------------------------------------------------
	# SNAPSHOT / RESTORE
	# ------------------------------------------------------------

	var snapshot_state: Dictionary = (
		controller.snapshot_state()
	)

	controller.clear_all()

	var restored_empty_pass: bool = (
		not controller.has_fired(
			"one_time_event",
			"india"
		)
	)

	controller.restore_state(snapshot_state)

	var restored_state_pass: bool = (
		controller.has_fired(
			"one_time_event",
			"india"
		)
		and controller.get_last_fired_tick(
			"one_time_event",
			"india"
		) == 0
	)

	var snapshot_pass: bool = (
		restored_empty_pass
		and restored_state_pass
	)

	TestLogger.write_line(
		"Repeatability state snapshots and restores correctly: "
		+ ("PASS" if snapshot_pass else "FAIL")
	)

	if not snapshot_pass:
		test_passed = false


	TestLogger.write_line(
		"E11 Cooldowns / Repeatability test: "
		+ ("PASS" if test_passed else "FAIL")
	)

	return test_passed
