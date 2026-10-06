class_name IndustryProcessAdoptionRateTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS ADOPTION RATE TEST"
	)

	var passed := true

	# --------------------------------------------------
	# Increasing adoption
	# --------------------------------------------------

	var increasing := IndustryComponent.calculate_next_adoption(
		0.20,
		1.00,
		0.10
	)

	if is_equal_approx(
		increasing,
		0.30
	):
		TestLogger.write_line(
			"Adoption increases by rate: PASS"
		)
	else:
		TestLogger.write_line(
			"Adoption increases by rate: FAIL | actual="
			+ str(increasing)
		)
		passed = false


	# --------------------------------------------------
	# No overshoot when approaching target
	# --------------------------------------------------

	var capped := IndustryComponent.calculate_next_adoption(
		0.95,
		1.00,
		0.10
	)

	if is_equal_approx(
		capped,
		1.00
	):
		TestLogger.write_line(
			"Adoption does not overshoot target: PASS"
		)
	else:
		TestLogger.write_line(
			"Adoption does not overshoot target: FAIL | actual="
			+ str(capped)
		)
		passed = false


	# --------------------------------------------------
	# Decreasing adoption
	# --------------------------------------------------

	var decreasing := IndustryComponent.calculate_next_adoption(
		0.80,
		0.20,
		0.10
	)

	if is_equal_approx(
		decreasing,
		0.70
	):
		TestLogger.write_line(
			"Adoption decreases by rate: PASS"
		)
	else:
		TestLogger.write_line(
			"Adoption decreases by rate: FAIL | actual="
			+ str(decreasing)
		)
		passed = false


	# --------------------------------------------------
	# No undershoot when approaching lower target
	# --------------------------------------------------

	var lower_capped := IndustryComponent.calculate_next_adoption(
		0.05,
		0.00,
		0.10
	)

	if is_equal_approx(
		lower_capped,
		0.00
	):
		TestLogger.write_line(
			"Adoption does not undershoot target: PASS"
		)
	else:
		TestLogger.write_line(
			"Adoption does not undershoot target: FAIL | actual="
			+ str(lower_capped)
		)
		passed = false


	# --------------------------------------------------
	# Already at target
	# --------------------------------------------------

	var unchanged := IndustryComponent.calculate_next_adoption(
		0.50,
		0.50,
		0.10
	)

	if is_equal_approx(
		unchanged,
		0.50
	):
		TestLogger.write_line(
			"Adoption remains unchanged at target: PASS"
		)
	else:
		TestLogger.write_line(
			"Adoption remains unchanged at target: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Zero rate
	# --------------------------------------------------

	var zero_rate := IndustryComponent.calculate_next_adoption(
		0.20,
		1.00,
		0.00
	)

	if is_equal_approx(
		zero_rate,
		0.20
	):
		TestLogger.write_line(
			"Zero adoption rate causes no movement: PASS"
		)
	else:
		TestLogger.write_line(
			"Zero adoption rate causes no movement: FAIL"
		)
		passed = false


	# --------------------------------------------------
	# Rate state initialization
	# --------------------------------------------------

	var industry := IndustryComponent.new()

	industry.setup(
		{
			"steel_basic": {
				"active": true,
				"capacity": 100.0,
				"efficiency": 1.0
			},
			"machinery_basic": {
				"active": true,
				"capacity": 50.0,
				"efficiency": 1.0
			}
		},
		{
			"steel_basic": 0.20
		},
		{
			"steel_basic": 0.10
		}
	)

	var rates = industry.get_state(
		"process_adoption_rate",
		{}
	)

	var transitions = industry.get_state(
		"process_transition_state",
		{}
	)

	var steel_rate := float(
		rates.get(
			"steel_basic",
			-1.0
		)
	)

	if is_equal_approx(
		steel_rate,
		0.10
	):
		TestLogger.write_line(
			"Explicit adoption rate preserved: PASS"
		)
	else:
		TestLogger.write_line(
			"Explicit adoption rate preserved: FAIL"
		)
		passed = false


	var machinery_rate := float(
		rates.get(
			"machinery_basic",
			-1.0
		)
	)

	if is_equal_approx(
		machinery_rate,
		0.0
	):
		TestLogger.write_line(
			"Missing adoption rate defaults to 0.0: PASS"
		)
	else:
		TestLogger.write_line(
			"Missing adoption rate defaults to 0.0: FAIL"
		)
		passed = false


	var steel_transition = transitions.get(
		"steel_basic",
		{}
	)

	if (
		typeof(steel_transition) == TYPE_DICTIONARY
		and is_equal_approx(
			float(
				steel_transition.get(
					"adoption_rate",
					-1.0
				)
			),
			0.10
		)
		and not bool(
			steel_transition.get(
				"active",
				true
			)
		)
	):
		TestLogger.write_line(
			"Transition stores adoption rate without activating: PASS"
		)
	else:
		TestLogger.write_line(
			"Transition stores adoption rate without activating: FAIL"
		)
		passed = false


	return passed
