class_name EconomyShortagePressureTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	print("")
	print("====================================================")
	print("ECONOMY INTEGRATION — SHORTAGE -> ECONOMIC PRESSURE TEST")
	print("====================================================")

	var passed := true

	if world == null:
		push_error(
			"EconomyShortagePressureTest: World is null."
		)
		return false

	if simulation == null:
		push_error(
			"EconomyShortagePressureTest: SimulationEngine is null."
		)
		return false

	var india = world.get_entity(
		"india"
	)

	if india == null:
		push_error(
			"EconomyShortagePressureTest: India not found."
		)
		return false

	var resources = india.get_component(
		"resources"
	)

	var economy = india.get_component(
		"economy"
	)

	if resources == null:
		push_error(
			"EconomyShortagePressureTest: Resource component missing."
		)
		return false

	if economy == null:
		push_error(
			"EconomyShortagePressureTest: Economy component missing."
		)
		return false

	# Use the registered systems already owned by SimulationEngine.
	var resource_system = simulation.get_system(
		"resource_system"
	)

	var economy_system = simulation.get_system(
		"economy_system"
	)

	if resource_system == null:
		push_error(
			"EconomyShortagePressureTest: Registered ResourceSystem missing."
		)
		passed = false

	if economy_system == null:
		push_error(
			"EconomyShortagePressureTest: Registered EconomySystem missing."
		)
		passed = false

	if not passed:
		return false

	# Preserve complete mutable state for this isolated integration test.
	var original_resource_state = (
		resources.state.duplicate(true)
	)

	var original_economy_state = (
		economy.state.duplicate(true)
	)

	# ------------------------------------------------------------
	# CONTROLLED RESOURCE INPUTS
	# ------------------------------------------------------------

	resources.set_state(
		"production",
		{}
	)

	resources.set_state(
		"consumption",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	resources.set_state(
		"imports",
		{}
	)

	resources.set_state(
		"exports",
		{}
	)

	resources.set_state(
		"reserves",
		{}
	)

	resources.set_state(
		"stockpile",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	resources.set_state(
		"production_process_demand",
		{}
	)

	# ------------------------------------------------------------
	# BASELINE — NO SHORTAGE
	# ------------------------------------------------------------

	resource_system.process_month(
		world
	)

	var baseline_shortage_ratio = resources.get_state(
		"shortage_ratio",
		{}
	)

	var baseline_iron_shortage = float(
		baseline_shortage_ratio.get(
			"iron",
			-1.0
		)
	)

	var baseline_pressure_before = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	economy_system.process_month(
		world
	)

	var baseline_pressure = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	if (
		is_equal_approx(
			baseline_iron_shortage,
			0.0
		)
		and
		is_equal_approx(
			baseline_pressure,
			0.0
		)
	):
		print(
			"PASS: No resource shortage produces zero economic pressure."
		)
	else:
		push_error(
			"FAIL: No-shortage baseline. "
			+ "iron_shortage_ratio="
			+ str(baseline_iron_shortage)
			+ ", pressure_before="
			+ str(baseline_pressure_before)
			+ ", pressure_after="
			+ str(baseline_pressure)
		)
		passed = false

	# ------------------------------------------------------------
	# SINGLE BOTTLENECK — 75% IRON SHORTAGE
	# ------------------------------------------------------------

	resources.set_state(
		"stockpile",
		{
			"iron": 5.0,
			"coal": 10.0
		}
	)

	resource_system.process_month(
		world
	)

	var shortage_ratios = resources.get_state(
		"shortage_ratio",
		{}
	)

	var iron_shortage_ratio = float(
		shortage_ratios.get(
			"iron",
			-1.0
		)
	)

	var coal_shortage_ratio = float(
		shortage_ratios.get(
			"coal",
			-1.0
		)
	)

	economy_system.process_month(
		world
	)

	var shortage_pressure = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	var expected_shortage_pressure: float = 0.75

	if (
		is_equal_approx(
			iron_shortage_ratio,
			75.0
		)
		and
		is_equal_approx(
			coal_shortage_ratio,
			0.0
		)
		and
		is_equal_approx(
			shortage_pressure,
			expected_shortage_pressure
		)
	):
		print(
			"PASS: 75% iron shortage produces economic_pressure = ",
			shortage_pressure
		)
	else:
		push_error(
			"FAIL: Shortage -> economic pressure. "
			+ "expected_iron_shortage_ratio=75.0, actual="
			+ str(iron_shortage_ratio)
			+ ", expected_pressure="
			+ str(expected_shortage_pressure)
			+ ", actual="
			+ str(shortage_pressure)
		)
		passed = false

	# ------------------------------------------------------------
	# BOTTLENECK SELECTION — SEVERE SHORTAGE DOMINATES
	# ------------------------------------------------------------

	resources.set_state(
		"stockpile",
		{
			"iron": 15.0,
			"coal": 2.0
		}
	)

	resource_system.process_month(
		world
	)

	var mixed_shortage_ratios = resources.get_state(
		"shortage_ratio",
		{}
	)

	var mixed_iron_shortage_ratio = float(
		mixed_shortage_ratios.get(
			"iron",
			-1.0
		)
	)

	var mixed_coal_shortage_ratio = float(
		mixed_shortage_ratios.get(
			"coal",
			-1.0
		)
	)

	economy_system.process_month(
		world
	)

	var mixed_pressure = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	# Iron shortage = 25%, coal shortage = 80%.
	# Step 3.2 uses the most severe resource shortage as the
	# country-level bottleneck pressure.
	var expected_mixed_pressure: float = 0.80

	if (
		is_equal_approx(
			mixed_iron_shortage_ratio,
			25.0
		)
		and
		is_equal_approx(
			mixed_coal_shortage_ratio,
			80.0
		)
		and
		is_equal_approx(
			mixed_pressure,
			expected_mixed_pressure
		)
	):
		print(
			"PASS: Economic pressure follows the most severe resource shortage = ",
			mixed_pressure
		)
	else:
		push_error(
			"FAIL: Bottleneck shortage pressure. "
			+ "iron_ratio="
			+ str(mixed_iron_shortage_ratio)
			+ ", coal_ratio="
			+ str(mixed_coal_shortage_ratio)
			+ ", expected_pressure="
			+ str(expected_mixed_pressure)
			+ ", actual="
			+ str(mixed_pressure)
		)
		passed = false

	# ------------------------------------------------------------
	# RECOVERY — SHORTAGE REMOVED
	# ------------------------------------------------------------

	resources.set_state(
		"stockpile",
		{
			"iron": 20.0,
			"coal": 10.0
		}
	)

	resource_system.process_month(
		world
	)

	economy_system.process_month(
		world
	)

	var recovered_pressure = float(
		economy.get_state(
			"economic_pressure",
			-1.0
		)
	)

	if is_equal_approx(
		recovered_pressure,
		0.0
	):
		print(
			"PASS: Removing the shortage restores zero economic pressure."
		)
	else:
		push_error(
			"FAIL: Economic pressure recovery. "
			+ "Expected 0.0, got "
			+ str(recovered_pressure)
		)
		passed = false

	# ------------------------------------------------------------
	# RESTORE ORIGINAL STATE
	# ------------------------------------------------------------

	for key in resources.state.keys():
		if not original_resource_state.has(key):
			resources.state.erase(key)

	for key in original_resource_state.keys():
		resources.set_state(
			key,
			original_resource_state[key]
		)

	for key in economy.state.keys():
		if not original_economy_state.has(key):
			economy.state.erase(key)

	for key in original_economy_state.keys():
		economy.set_state(
			key,
			original_economy_state[key]
		)

	if passed:
		print(
			"EconomyShortagePressureTest: PASS"
		)
	else:
		print(
			"EconomyShortagePressureTest: FAIL"
		)

	print("====================================================")

	return passed
