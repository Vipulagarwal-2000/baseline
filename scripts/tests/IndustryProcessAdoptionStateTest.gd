class_name IndustryProcessAdoptionStateTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"INDUSTRY PROCESS ADOPTION STATE TEST"
	)

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
			"steel_basic": 0.75
		}
	)

	var adoption = industry.get_state(
		"process_adoption",
		{}
	)

	var targets = industry.get_state(
		"process_adoption_target",
		{}
	)

	var transitions = industry.get_state(
		"process_transition_state",
		{}
	)

	var passed := true

	var steel_adoption := float(
		adoption.get(
			"steel_basic",
			-1.0
		)
	)

	if is_equal_approx(
		steel_adoption,
		0.75
	):
		TestLogger.write_line(
			"Explicit adoption preserved: PASS"
		)
	else:
		TestLogger.write_line(
			"Explicit adoption preserved: FAIL"
		)
		passed = false

	var machinery_adoption := float(
		adoption.get(
			"machinery_basic",
			-1.0
		)
	)

	if is_equal_approx(
		machinery_adoption,
		1.0
	):
		TestLogger.write_line(
			"Missing adoption defaults to 1.0: PASS"
		)
	else:
		TestLogger.write_line(
			"Missing adoption defaults to 1.0: FAIL"
		)
		passed = false

	var steel_target := float(
		targets.get(
			"steel_basic",
			-1.0
		)
	)

	if is_equal_approx(
		steel_target,
		0.75
	):
		TestLogger.write_line(
			"Initial target matches current adoption: PASS"
		)
	else:
		TestLogger.write_line(
			"Initial target matches current adoption: FAIL"
		)
		passed = false

	var machinery_target := float(
		targets.get(
			"machinery_basic",
			-1.0
		)
	)

	if is_equal_approx(
		machinery_target,
		1.0
	):
		TestLogger.write_line(
			"Default target matches current adoption: PASS"
		)
	else:
		TestLogger.write_line(
			"Default target matches current adoption: FAIL"
		)
		passed = false

	var steel_transition = transitions.get(
		"steel_basic",
		{}
	)

	if (
		typeof(steel_transition) == TYPE_DICTIONARY
		and not bool(
			steel_transition.get(
				"active",
				true
			)
		)
		and int(
			steel_transition.get(
				"elapsed_months",
				-1
			)
		) == 0
		and int(
			steel_transition.get(
				"duration_months",
				-1
			)
		) == 0
		and is_equal_approx(
			float(
				steel_transition.get(
					"start_adoption",
					-1.0
				)
			),
			0.75
		)
		and is_equal_approx(
			float(
				steel_transition.get(
					"target_adoption",
					-1.0
				)
			),
			0.75
		)
	):
		TestLogger.write_line(
			"Initial transition state: PASS"
		)
	else:
		TestLogger.write_line(
			"Initial transition state: FAIL"
		)
		passed = false

	if (
		adoption.has("steel_basic")
		and adoption.has("machinery_basic")
		and targets.has("steel_basic")
		and targets.has("machinery_basic")
		and transitions.has("steel_basic")
		and transitions.has("machinery_basic")
	):
		TestLogger.write_line(
			"All process adoption states initialized: PASS"
		)
	else:
		TestLogger.write_line(
			"All process adoption states initialized: FAIL"
		)
		passed = false

	return passed
