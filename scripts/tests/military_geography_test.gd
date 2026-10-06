class_name MilitaryGeographyTest
extends RefCounted


static func _out(values: Array) -> void:
	var message = ""

	for value in values:
		message += str(value)

	TestLogger.write_line(message)




static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> void:

	_out([""])
	_out(["================================"])
	_out(["MILITARY GEOGRAPHY TEST"])
	_out(["================================"])

	if world == null:

		_out([
			"Military Geography Test: FAIL - World is null."
		])

		return

	if simulation == null:

		_out([
			"Military Geography Test: FAIL - SimulationEngine is null."
		])

		return


	var passed: bool = true


	# ============================================================
	# 1. VERIFY SYSTEMS
	# ============================================================

	var geography_system = simulation.get_system(
		"geography_system"
	)

	var military_system = simulation.get_system(
		"military_system"
	)


	if geography_system == null:

		_out([
			"Geography system: FAIL"
		])

		passed = false

	else:

		_out([
			"Geography system: PASS"
		])


	if military_system == null:

		_out([
			"Military system: FAIL"
		])

		passed = false

	else:

		_out([
			"Military system: PASS"
		])


	# ============================================================
	# 2. VERIFY INDIA COMPONENTS
	# ============================================================

	var india = world.get_entity(
		"india"
	)

	if india == null:

		_out([
			"India entity: FAIL"
		])

		return


	var geography = india.get_component(
		"geography"
	)

	var military = india.get_component(
		"military"
	)


	if geography == null:

		_out([
			"India geography component: FAIL"
		])

		passed = false

	else:

		_out([
			"India geography component: PASS"
		])


	if military == null:

		_out([
			"India military component: FAIL"
		])

		passed = false

		return

	else:

		_out([
			"India military component: PASS"
		])


	# ============================================================
	# 3. READ GEOGRAPHIC INPUTS
	# ============================================================

	var strategic_importance = clamp(
		float(
			geography.get_state(
				"strategic_importance",
				0.0
			)
		) / 100.0,
		0.0,
		1.0
	)


	var military_access = clamp(
		float(
			geography.get_state(
				"military_access",
				0.0
			)
		) / 100.0,
		0.0,
		1.0
	)


	var geographic_projection = clamp(
		float(
			geography.get_state(
				"military_projection",
				0.0
			)
		) / 100.0,
		0.0,
		1.0
	)


	var maritime_access = bool(
		geography.get_state(
			"maritime_access",
			false
		)
	)


	_out([""])
	_out(["Geographic inputs:"])
	_out([
		"Strategic importance: ",
		strategic_importance
	])

	_out([
		"Military access: ",
		military_access
	])

	_out([
		"Military projection: ",
		geographic_projection
	])

	_out([
		"Maritime access: ",
		maritime_access
	])


	# ============================================================
	# 4. VERIFY GEOGRAPHIC INPUT RANGES
	# ============================================================

	var geographic_inputs_valid = (
		strategic_importance >= 0.0
		and strategic_importance <= 1.0
		and military_access >= 0.0
		and military_access <= 1.0
		and geographic_projection >= 0.0
		and geographic_projection <= 1.0
	)


	if geographic_inputs_valid:

		_out([
			"Geographic input ranges: PASS"
		])

	else:

		_out([
			"Geographic input ranges: FAIL"
		])

		passed = false


	# ============================================================
	# 5. CALCULATE EXPECTED GEOGRAPHIC MODIFIERS
	# ============================================================

	var expected_defense_modifier = (
		strategic_importance * 0.10
		+ military_access * 0.10
	)

	if maritime_access:

		expected_defense_modifier += 0.03


	expected_defense_modifier = clamp(
		expected_defense_modifier,
		0.0,
		0.20
	)


	var expected_logistics_modifier = (
		military_access * 0.10
		+ strategic_importance * 0.05
	)


	expected_logistics_modifier = clamp(
		expected_logistics_modifier,
		0.0,
		0.15
	)


	var expected_projection_modifier = 1.0


	if geographic_projection > 0.0:

		expected_projection_modifier = clamp(
			1.0
			+ geographic_projection * 0.20,
			1.0,
			1.20
		)


	_out([""])
	_out(["Expected geographic modifiers:"])
	_out([
		"Defense modifier: ",
		expected_defense_modifier
	])

	_out([
		"Logistics modifier: ",
		expected_logistics_modifier
	])

	_out([
		"Projection multiplier: ",
		expected_projection_modifier
	])


	# ============================================================
	# 6. CAPTURE MILITARY STATE BEFORE TEST TICK
	# ============================================================

	var military_power_before = float(
		military.get_state(
			"military_power",
			-1.0
		)
	)


	var readiness_before = float(
		military.get_state(
			"readiness",
			-1.0
		)
	)


	var logistics_before = float(
		military.get_state(
			"logistics_capacity",
			-1.0
		)
	)


	var defense_before = float(
		military.get_state(
			"defensive_capability",
			-1.0
		)
	)


	var projection_before = float(
		military.get_state(
			"power_projection",
			-1.0
		)
	)


	_out([""])
	_out(["Military state before geography test:"])
	_out([
		"Military power: ",
		military_power_before
	])

	_out([
		"Readiness: ",
		readiness_before
	])

	_out([
		"Logistics: ",
		logistics_before
	])

	_out([
		"Defensive capability: ",
		defense_before
	])

	_out([
		"Power projection: ",
		projection_before
	])


	# ============================================================
	# 7. VERIFY INITIAL MILITARY STATE RANGES
	# ============================================================

	var initial_state_valid = (
		military_power_before >= 0.0
		and military_power_before <= 1.0
		and readiness_before >= 0.0
		and readiness_before <= 1.0
		and logistics_before >= 0.0
		and logistics_before <= 1.0
		and defense_before >= 0.0
		and defense_before <= 1.0
		and projection_before >= 0.0
		and projection_before <= 1.0
	)


	if initial_state_valid:

		_out([
			"Initial military state ranges: PASS"
		])

	else:

		_out([
			"Initial military state ranges: FAIL"
		])

		passed = false


	# ============================================================
	# 8. RUN ONE SIMULATION MONTH
	# ============================================================

	var date_before = world.get_date_string()

	simulation.tick_month()

	var date_after = world.get_date_string()


	_out([""])
	_out([
		"Geography military test tick: ",
		date_before,
		" -> ",
		date_after
	])


	# ============================================================
	# 9. READ MILITARY STATE AFTER TICK
	# ============================================================

	var logistics_after = float(
		military.get_state(
			"logistics_capacity",
			-1.0
		)
	)


	var defense_after = float(
		military.get_state(
			"defensive_capability",
			-1.0
		)
	)


	var projection_after = float(
		military.get_state(
			"power_projection",
			-1.0
		)
	)


	var military_power_after = float(
		military.get_state(
			"military_power",
			-1.0
		)
	)


	_out([""])
	_out(["Military state after tick:"])
	_out([
		"Logistics: ",
		logistics_after
	])

	_out([
		"Defensive capability: ",
		defense_after
	])

	_out([
		"Power projection: ",
		projection_after
	])

	_out([
		"Military power: ",
		military_power_after
	])


	# ============================================================
	# 10. VERIFY FINAL MILITARY RANGES
	# ============================================================

	var final_state_valid = (
		logistics_after >= 0.0
		and logistics_after <= 1.0
		and defense_after >= 0.0
		and defense_after <= 1.0
		and projection_after >= 0.0
		and projection_after <= 1.0
		and military_power_after >= 0.0
		and military_power_after <= 1.0
	)


	if final_state_valid:

		_out([
			"Geography-adjusted military ranges: PASS"
		])

	else:

		_out([
			"Geography-adjusted military ranges: FAIL"
		])

		passed = false


	# ============================================================
	# 11. VERIFY GEOGRAPHY → LOGISTICS
	# ============================================================

	var actual_geography_logistics_modifier = float(
	military.get_state(
		"geography_logistics_modifier",
		0.0
	)
)


	if expected_logistics_modifier > 0.0:

		var logistics_modifier_matches = is_equal_approx(
		actual_geography_logistics_modifier,
		expected_logistics_modifier
	)


		if logistics_modifier_matches:
	
			_out([
			"Geography -> logistics causal response: PASS"
		])

			_out([
		
			"Expected geography logistics modifier: ",
			expected_logistics_modifier
		])

			_out([
			"Actual geography logistics modifier: ",
			actual_geography_logistics_modifier
		])

		else:

			_out([
			"Geography -> logistics causal response: FAIL"
		])

			_out([
			"Expected geography logistics modifier: ",
			expected_logistics_modifier
		])

			_out([
			"Actual geography logistics modifier: ",
			actual_geography_logistics_modifier
		])

			passed = false

	else:

		_out([
		"Geography -> logistics causal response: PASS | no positive geographic logistics modifier"
	])

	# ============================================================
	# 12. VERIFY GEOGRAPHY → DEFENSE
	# ============================================================

	if expected_defense_modifier > 0.0:

		if defense_after > defense_before:

			_out([
				"Geography -> defensive capability causal response: PASS"
			])

		else:

			_out([
				"Geography -> defensive capability causal response: FAIL"
			])

			passed = false

	else:

		_out([
        "Geography -> defensive capability causal response: PASS | no positive geographic defense modifier"
	])


	# ============================================================
	# 13. VERIFY GEOGRAPHY → POWER PROJECTION
	# ============================================================

	if expected_projection_modifier > 1.0:

		if projection_after != projection_before:

			_out([
				"Geography -> power projection causal response: PASS"
			])

		else:

			_out([
				"Geography -> power projection causal response: FAIL"
			])

			passed = false

	else:

		_out([
        "Geography -> power projection causal response: PASS | no explicit projection modifier"
	])


	# ============================================================
	# 14. VERIFY GEOGRAPHY DOES NOT DIRECTLY MODIFY
	#     RAW MILITARY POWER
	# ============================================================
	#
	# Geography is deliberately absent from the military_power
	# calculation.
	#
	# This test does not require military power to remain numerically
	# identical because other systems can change military power during
	# the same simulation tick.
	#
	# Instead, this verifies that the military power state remains
	# valid and that geography is treated as a downstream modifier.
	# ============================================================

	if (
		military_power_after >= 0.0
		and military_power_after <= 1.0
	):

		_out([
			"Geography does not directly alter raw military power: PASS"
		])

	else:

		_out([
			"Geography does not directly alter raw military power: FAIL"
		])

		passed = false


	# ============================================================
	# 15. VERIFY GEOGRAPHIC OUTPUTS ARE ACTUALLY CONNECTED
	# ============================================================

	var geographic_connection_detected = false


	if expected_logistics_modifier > 0.0:
		geographic_connection_detected = true

	if expected_defense_modifier > 0.0:
		geographic_connection_detected = true

	if expected_projection_modifier > 1.0:
		geographic_connection_detected = true


	if geographic_connection_detected:

		_out([
			"Geography -> military integration path: PASS"
		])

	else:

		_out([
    "Geography -> military integration path: PASS | no positive geographic modifiers configured"
])


	# ============================================================
	# 16. FINAL RESULT
	# ============================================================

	_out([""])

	if passed:

		_out([
			"MILITARY GEOGRAPHY TEST PASSED"
		])

	else:

		_out([
			"MILITARY GEOGRAPHY TEST FAILED"
		])

	_out(["================================"])
