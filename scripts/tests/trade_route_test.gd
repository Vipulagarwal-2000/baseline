class_name TradeRouteTest
extends RefCounted


# ============================================================
# TRADE ROUTE — STEP 4.2 TEST
# ============================================================
#
# Scope:
# - route identity and required fields
# - linkage to an existing TradeAgreement
# - exporter/importer endpoint consistency
# - basic route lifecycle state
# - WorldState ownership / registration
# - duplicate / invalid / orphan protection
# - snapshot capture and deep-copy isolation
#
# This test intentionally does NOT execute transactions or
# calculate infrastructure throughput.
# ============================================================

static func run(
	world: WorldState,
	simulation: SimulationEngine = null
) -> bool:

	TestLogger.section(
		"TRADE ROUTE TEST"
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

	const agreement_id = "test_trade_agreement_4_2"
	const route_id = "test_trade_route_4_2"

	var had_original_agreement := world.has_trade_agreement(
		agreement_id
	)
	var original_agreement = world.get_trade_agreement(
		agreement_id
	)

	var had_original_route := world.has_trade_route(
		route_id
	)
	var original_route = world.get_trade_route(
		route_id
	)

	var all_passed := true

	# ========================================================
	# LINKED AGREEMENT
	# ========================================================

	var agreement := TradeAgreement.new(
		agreement_id,
		"china",
		"india",
		"coal",
		100.0,
		12
	)

	if not agreement.is_valid():
		TestLogger.write_line(
			"Linked agreement validation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Linked agreement validation: PASS"
		)

	if not had_original_agreement:
		if not world.add_trade_agreement(agreement):
			TestLogger.write_line(
				"Linked agreement registration: FAIL"
			)
			all_passed = false
		else:
			TestLogger.write_line(
				"Linked agreement registration: PASS"
			)
	else:
		TestLogger.write_line(
			"Linked agreement registration: PASS | existing fixture preserved"
		)

	# ========================================================
	# VALID ROUTE
	# ========================================================

	var route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india"
	)

	if not route.is_valid():
		TestLogger.write_line(
			"Valid route validation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Valid route validation: PASS"
		)

	if route.status != TradeRoute.STATUS_DRAFT:
		TestLogger.write_line(
			"Initial draft route status: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Initial draft route status: PASS"
		)

	if not route.activate():
		TestLogger.write_line(
			"Route activation: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Route activation: PASS"
		)

	if route.status != TradeRoute.STATUS_ACTIVE:
		TestLogger.write_line(
			"Active route status: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Active route status: PASS"
		)

	# ========================================================
	# WORLD REGISTRATION
	# ========================================================

	if not had_original_route:
		if not world.add_trade_route(route):
			TestLogger.write_line(
				"World route registration: FAIL"
			)
			all_passed = false
		else:
			TestLogger.write_line(
				"World route registration: PASS"
			)
	else:
		TestLogger.write_line(
			"World route registration: PASS | existing fixture preserved"
		)

	if world.get_trade_route(route_id) != route:
		TestLogger.write_line(
			"World route retrieval: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"World route retrieval: PASS"
		)

	if not world.has_trade_route(route_id):
		TestLogger.write_line(
			"World route presence check: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"World route presence check: PASS"
		)

	# ========================================================
	# DUPLICATE PROTECTION
	# ========================================================

	var duplicate_route := TradeRoute.new(
		route_id,
		agreement_id,
		"china",
		"india"
	)

	if world.add_trade_route(duplicate_route):
		TestLogger.write_line(
			"Duplicate route protection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Duplicate route protection: PASS"
		)

	# ========================================================
	# INVALID ROUTE PROTECTION
	# ========================================================

	var invalid_route := TradeRoute.new(
		"test_invalid_trade_route_4_2",
		agreement_id,
		"china",
		"china"
	)

	if invalid_route.is_valid():
		TestLogger.write_line(
			"Invalid exporter/importer protection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Invalid exporter/importer protection: PASS"
		)

	if world.add_trade_route(invalid_route):
		TestLogger.write_line(
			"Invalid route rejection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Invalid route rejection: PASS"
		)

	# ========================================================
	# UNKNOWN AGREEMENT PROTECTION
	# ========================================================

	var orphan_route := TradeRoute.new(
		"test_orphan_trade_route_4_2",
		"unknown_trade_agreement_4_2",
		"china",
		"india"
	)

	if world.add_trade_route(orphan_route):
		TestLogger.write_line(
			"Unknown agreement rejection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Unknown agreement rejection: PASS"
		)

	# ========================================================
	# ENDPOINT CONSISTENCY PROTECTION
	# ========================================================

	var mismatched_route := TradeRoute.new(
		"test_mismatched_trade_route_4_2",
		agreement_id,
		"usa",
		"india"
	)

	if world.add_trade_route(mismatched_route):
		TestLogger.write_line(
			"Agreement endpoint consistency rejection: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Agreement endpoint consistency rejection: PASS"
		)

	# ========================================================
	# SNAPSHOT CAPTURE
	# ========================================================

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var captured = snapshot.trade_routes.get(
		route_id,
		null
	)

	if captured == null:
		TestLogger.write_line(
			"Snapshot trade route capture: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot trade route capture: PASS"
		)

	if snapshot.trade_route_count != world.get_trade_route_count():
		TestLogger.write_line(
			"Snapshot trade route count: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot trade route count: PASS"
		)

	if captured.get("agreement_id", "") != agreement_id:
		TestLogger.write_line(
			"Snapshot route agreement linkage: FAIL"
		)
		all_passed = false
	else:
		TestLogger.write_line(
			"Snapshot route agreement linkage: PASS"
		)

	captured["status"] = "changed_in_snapshot"

	if route.status == "changed_in_snapshot":
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

	world.remove_trade_route(route_id)

	if had_original_route:
		if original_route != null:
			world.add_trade_route(original_route)
	else:
		world.remove_trade_route(route_id)

	if not had_original_agreement:
		world.remove_trade_agreement(agreement_id)
	else:
		if original_agreement != null:
			world.trade_agreements[agreement_id] = original_agreement

	TestLogger.write_line(
		"Trade Route 4.2 overall: "
		+ (
			"PASS"
			if all_passed
			else "FAIL"
		)
	)

	return all_passed
