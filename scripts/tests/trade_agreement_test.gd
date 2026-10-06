class_name TradeAgreementTest
extends RefCounted


# ============================================================
# TRADE AGREEMENT — STEP 4.1 TEST
# ============================================================
#
# Scope:
# - agreement identity and required fields
# - basic lifecycle state
# - WorldState ownership/registration
# - duplicate/invalid protection
# - snapshot capture and deep-copy behavior
#
# This test intentionally does NOT execute trade transactions.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"TRADE AGREEMENT TEST"
	)

	if world == null:
		TestLogger.write_line(
			"World available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World available: PASS"
	)

	var china = world.get_entity("china")
	var india = world.get_entity("india")

	if china == null:
		TestLogger.write_line(
			"China available: FAIL"
		)
		return false

	TestLogger.write_line(
		"China available: PASS"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	const agreement_id = "test_trade_agreement_4_1"

	var had_original_agreement := world.has_trade_agreement(
		agreement_id
	)

	var original_agreement = world.get_trade_agreement(
		agreement_id
	)

	var all_passed := true

	# ========================================================
	# VALID AGREEMENT
	# ========================================================

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		125.0,
		24
	)

	if not agreement.is_valid():
		TestLogger.write_line(
			"Valid agreement validation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Valid agreement validation: PASS"
		)


	if agreement.duration_months != 24:
		TestLogger.write_line(
			"Contract duration initialization: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Contract duration initialization: PASS"
		)


	if agreement.remaining_duration_months != 24:
		TestLogger.write_line(
			"Remaining duration initialization: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Remaining duration initialization: PASS"
		)


	if agreement.status != TradeAgreement.STATUS_DRAFT:
		TestLogger.write_line(
			"Initial draft status: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Initial draft status: PASS"
		)


	if not agreement.activate({"year": 1950, "month": 1, "day": 1}):
		TestLogger.write_line(
			"Agreement activation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Agreement activation: PASS"
		)


	if agreement.status != TradeAgreement.STATUS_ACTIVE:
		TestLogger.write_line(
			"Active status: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Active status: PASS"
		)


	# ========================================================
	# WORLD REGISTRATION
	# ========================================================

	if not world.add_trade_agreement(agreement):
		TestLogger.write_line(
			"World registration: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"World registration: PASS"
		)


	if world.get_trade_agreement(agreement_id) != agreement:
		TestLogger.write_line(
			"World retrieval: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"World retrieval: PASS"
		)


	if not world.has_trade_agreement(agreement_id):
		TestLogger.write_line(
			"World presence check: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"World presence check: PASS"
		)


	# ========================================================
	# DUPLICATE PROTECTION
	# ========================================================

	var duplicate_agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		125.0,
		24
	)

	if world.add_trade_agreement(duplicate_agreement):
		TestLogger.write_line(
			"Duplicate protection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Duplicate protection: PASS"
		)


	# ========================================================
	# INVALID AGREEMENT PROTECTION
	# ========================================================

	var invalid_agreement := TradeAgreement.new(
		"test_invalid_trade_agreement_4_1",
		"china",
		"china",
		"coal",
		100.0,
		12
	)

	if invalid_agreement.is_valid():
		TestLogger.write_line(
			"Invalid exporter/importer protection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Invalid exporter/importer protection: PASS"
		)


	if world.add_trade_agreement(invalid_agreement):
		TestLogger.write_line(
			"Invalid agreement rejection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Invalid agreement rejection: PASS"
		)


	# ========================================================
	# SNAPSHOT CAPTURE
	# ========================================================

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var captured = snapshot.trade_agreements.get(
		agreement_id,
		null
	)

	if captured == null:
		TestLogger.write_line(
			"Snapshot trade agreement capture: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot trade agreement capture: PASS"
		)


	if snapshot.trade_agreement_count != world.get_trade_agreement_count():
		TestLogger.write_line(
			"Snapshot trade agreement count: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot trade agreement count: PASS"
		)


	if captured != agreement.to_snapshot_dict():
		TestLogger.write_line(
			"Snapshot agreement state: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot agreement state: PASS"
		)


	# Prove snapshot data is detached from later agreement mutation.
	agreement.quantity = 200.0

	if float(
		captured.get(
			"quantity",
			-1.0
		)
	) != 125.0:
		TestLogger.write_line(
			"Snapshot deep-copy isolation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot deep-copy isolation: PASS"
		)


	# ========================================================
	# CLEANUP
	# ========================================================

	world.remove_trade_agreement(
		agreement_id
	)

	if had_original_agreement:
		world.trade_agreements[agreement_id] = original_agreement


	TestLogger.write_line(
		"Trade Agreement 4.1 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
