class_name EventRandomnessTest
extends RefCounted


# ============================================================
# E10 — DETERMINISTIC RANDOMNESS TEST
# ============================================================
#
# Required proof:
#   same seed → same sequence
#   same seed → same event outcome
#   different seed → sequence may differ
#
# Additional boundary proof:
#   reset reproduces the same sequence
#   event identity changes event-scoped result
#   world signature changes event-scoped result
#
# No WorldState is mutated by this test.
# ============================================================


static func run() -> bool:
	TestLogger.section(
		"EventRandomness — E10 Deterministic Randomness"
	)

	var test_passed: bool = true


	# ------------------------------------------------------------
	# SAME SEED → SAME SEQUENCE
	# ------------------------------------------------------------

	var randomness_a: EventRandomness = (
		EventRandomness.new(123456)
	)
	var randomness_b: EventRandomness = (
		EventRandomness.new(123456)
	)

	var sequence_a: Array[float] = (
		randomness_a.sequence(8)
	)
	var sequence_b: Array[float] = (
		randomness_b.sequence(8)
	)

	var same_seed_sequence_pass: bool = (
		sequence_a == sequence_b
		and sequence_a.size() == 8
	)

	TestLogger.write_line(
		"Same seed produces the same sequence: "
		+ (
			"PASS"
			if same_seed_sequence_pass
			else "FAIL"
		)
	)

	if not same_seed_sequence_pass:
		test_passed = false


	# ------------------------------------------------------------
	# RESET → SAME SEQUENCE
	# ------------------------------------------------------------

	randomness_a.reset()

	var reset_sequence: Array[float] = (
		randomness_a.sequence(8)
	)

	var reset_pass: bool = (
		reset_sequence == sequence_a
	)

	TestLogger.write_line(
		"Reset reproduces the same seeded sequence: "
		+ (
			"PASS"
			if reset_pass
			else "FAIL"
		)
	)

	if not reset_pass:
		test_passed = false


	# ------------------------------------------------------------
	# DIFFERENT SEEDS MAY PRODUCE DIFFERENT SEQUENCES
	# ------------------------------------------------------------

	var randomness_c: EventRandomness = (
		EventRandomness.new(654321)
	)

	var different_seed_sequence: Array[float] = (
		randomness_c.sequence(8)
	)

	var different_seed_pass: bool = (
		different_seed_sequence != sequence_a
	)

	TestLogger.write_line(
		"Different seed produces an independent sequence: "
		+ (
			"PASS"
			if different_seed_pass
			else "FAIL"
		)
	)

	if not different_seed_pass:
		test_passed = false


	# ------------------------------------------------------------
	# SAME SEED + SAME EVENT + SAME WORLD SIGNATURE
	# → SAME EVENT OUTCOME
	# ------------------------------------------------------------

	var event_a: EventRandomness = (
		EventRandomness.new(777)
	)
	var event_b: EventRandomness = (
		EventRandomness.new(777)
	)

	var event_id: String = "test_stability_event"
	var world_signature: String = (
		"country=india;government.stability=0.40"
	)

	var outcome_a: float = event_a.roll_for_event(
		event_id,
		world_signature
	)

	var outcome_b: float = event_b.roll_for_event(
		event_id,
		world_signature
	)

	var same_event_outcome_pass: bool = (
		is_equal_approx(
			outcome_a,
			outcome_b
		)
	)

	TestLogger.write_line(
		"Same seed + event + world signature gives same outcome: "
		+ (
			"PASS"
			if same_event_outcome_pass
			else "FAIL"
		)
	)

	if not same_event_outcome_pass:
		test_passed = false


	# ------------------------------------------------------------
	# EVENT ID CONTEXT CHANGES DETERMINISTIC ROLL
	# ------------------------------------------------------------

	var different_event_outcome: float = (
		event_a.roll_for_event(
			"another_event",
			world_signature
		)
	)

	var event_context_pass: bool = (
		not is_equal_approx(
			outcome_a,
			different_event_outcome
		)
	)

	TestLogger.write_line(
		"Event identity contributes to deterministic outcome: "
		+ (
			"PASS"
			if event_context_pass
			else "FAIL"
		)
	)

	if not event_context_pass:
		test_passed = false


	# ------------------------------------------------------------
	# WORLD SIGNATURE CONTEXT CHANGES DETERMINISTIC ROLL
	# ------------------------------------------------------------

	var different_world_outcome: float = (
		event_a.roll_for_event(
			event_id,
			"country=india;government.stability=0.70"
		)
	)

	var world_context_pass: bool = (
		not is_equal_approx(
			outcome_a,
			different_world_outcome
		)
	)

	TestLogger.write_line(
		"World signature contributes to deterministic outcome: "
		+ (
			"PASS"
			if world_context_pass
			else "FAIL"
		)
	)

	if not world_context_pass:
		test_passed = false


	# ------------------------------------------------------------
	# NO WORLD MUTATION / DATA-ONLY RNG BOUNDARY
	# ------------------------------------------------------------

	var data_only_pass: bool = (
		randomness_a != null
		and randomness_b != null
		and randomness_c != null
		and sequence_a.size() == 8
	)

	TestLogger.write_line(
		"Deterministic randomness remains independent of WorldState: "
		+ (
			"PASS"
			if data_only_pass
			else "FAIL"
		)
	)

	if not data_only_pass:
		test_passed = false


	TestLogger.write_line(
		"E10 Deterministic Randomness test: "
		+ (
			"PASS"
			if test_passed
			else "FAIL"
		)
	)

	return test_passed
