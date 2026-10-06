class_name MilitaryProductionCapacityTest
extends RefCounted


static func _out(values: Array) -> void:
	var message := ""
	for value in values:
		message += str(value)
	TestLogger.write_line(message)


static func _log_result(label: String, passed: bool) -> void:
	_out([
		label,
		": ",
		"PASS" if passed else "FAIL"
	])


static func _in_range(value: float) -> bool:
	return value >= -0.000001 and value <= 1.000001


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	_out([""])
	_out(["============================================================"])
	_out(["STEP 13.1 — PRODUCTION → MILITARY CAPACITY TEST"])
	_out(["============================================================"])

	if world == null:
		_out(["World available: FAIL"])
		return false

	_out(["World available: PASS"])

	if simulation == null:
		_out(["Simulation available: FAIL"])
		return false

	_out(["Simulation available: PASS"])

	var system_instance = simulation.get_system(
		"military_production_capacity_system"
	)

	var system_ok := (
		system_instance != null
		and system_instance is MilitaryProductionCapacitySystem
	)

	_log_result(
		"Registered MilitaryProductionCapacitySystem available",
		system_ok
	)

	if not system_ok:
		return false

	var military_system_instance = simulation.get_system(
		"military_system"
	)

	var military_system_ok := (
		military_system_instance != null
		and military_system_instance is MilitarySystem
	)

	_log_result(
		"Registered MilitarySystem available",
		military_system_ok
	)

	if not military_system_ok:
		return false

	var india = world.get_entity("india")

	if india == null:
		_out(["India available: FAIL"])
		return false

	_out(["India available: PASS"])

	var industry = india.get_component("industry")
	var military = india.get_component("military")

	var components_ok := industry != null and military != null

	_log_result(
		"India industry and military components available",
		components_ok
	)

	if not components_ok:
		return false

	# Preserve the exact state touched by this test. The test may be
	# executed inside the broader suite, so it must be fully restorative.
	var original_industry_processes = industry.get_state(
		"processes",
		{}
	).duplicate(true)

	var original_industry_adoption = industry.get_state(
		"process_adoption",
		{}
	).duplicate(true)

	var original_production_state = industry.get_state(
		"production_state",
		{}
	).duplicate(true)

	var original_military_state :Dictionary= military.state.duplicate(true)

	var passed := true

	# ------------------------------------------------------------
	# CONTROLLED PRODUCTION FIXTURE
	# ------------------------------------------------------------
	# Use the executable catalog processes already present in the current
	# IndustryComponent and give the relevant processes deterministic
	# operational outcomes. This keeps the test independent from whether
	# the broader suite has already advanced the monthly simulation.

	var fixture_processes = original_industry_processes.duplicate(true)
	var fixture_adoption = original_industry_adoption.duplicate(true)
	var fixture_production_state := {}

	var relevant_fixture_created := false

	for raw_process_id in fixture_processes.keys():
		var process_id := str(raw_process_id)
		var instance = fixture_processes[raw_process_id]

		if typeof(instance) != TYPE_DICTIONARY:
			continue

		if not bool(instance.get("active", false)):
			continue

		if not process_id in ["steel_basic", "advanced_steel_production", "machinery_basic"]:
			continue

		var capacity := maxf(
			float(instance.get("capacity", 0.0)),
			0.0
		)

		if capacity <= 0.0:
			continue

		var efficiency := clampf(
			float(instance.get("efficiency", 1.0)),
			0.0,
			1.0
		)

		var catalog_efficiency := 1.0
		if process_id == "steel_basic":
			catalog_efficiency = 1.0
		elif process_id == "advanced_steel_production":
			catalog_efficiency = 1.10
		elif process_id == "machinery_basic":
			catalog_efficiency = 1.0

		var effective_capacity := (
			capacity
			* clampf(float(fixture_adoption.get(process_id, 1.0)), 0.0, 1.0)
			* efficiency
			* catalog_efficiency
		)

		if effective_capacity <= 0.0:
			continue

		var output_id := "steel"
		if process_id == "machinery_basic":
			output_id = "machinery"

		fixture_production_state[process_id] = {
			"status": "produced",
			"blocked": false,
			"reason": "",
			"effective_capacity": effective_capacity,
			"actual_production": effective_capacity,
			"outputs_produced": {
				output_id: effective_capacity
			},
			"inputs_consumed": {},
			"byproducts_produced": {}
		}

		relevant_fixture_created = true
		break

	_log_result(
		"Relevant production fixture available",
		relevant_fixture_created
	)

	if not relevant_fixture_created:
		passed = false

	else:
		industry.set_state(
			"processes",
			fixture_processes
		)
		industry.set_state(
			"process_adoption",
			fixture_adoption
		)
		industry.set_state(
			"production_state",
			fixture_production_state
		)

		var system: MilitaryProductionCapacitySystem = (
			system_instance as MilitaryProductionCapacitySystem
		)

		system.process_month(world)

		var baseline_support := float(
			military.get_state(
				"production_military_support",
				-1.0
			)
		)
		var baseline_modifier := float(
			military.get_state(
				"production_capacity_modifier",
				-1.0
			)
		)
		var baseline_industrial_capacity := float(
			military.get_state(
				"production_industrial_capacity_index",
				-1.0
			))
		
		_log_result(
			"Production military support remains bounded",
			_in_range(baseline_support)
		)
		_log_result(
			"Production capacity modifier remains bounded",
			_in_range(baseline_modifier)
		)
		_log_result(
			"Industrial capacity index remains bounded",
			_in_range(baseline_industrial_capacity)
		)

		if not _in_range(baseline_support):
			passed = false
		if not _in_range(baseline_modifier):
			passed = false
		if not _in_range(baseline_industrial_capacity):
			passed = false

		var baseline_industrial_support := float(
			military.get_state(
				"industrial_support",
				0.0
			)
		)
		var baseline_readiness := float(
			military.get_state(
				"readiness",
				0.0
			))
		var baseline_power := float(
			military.get_state(
				"military_power",
				0.0
			))
		
		# --------------------------------------------------------
		# PRODUCTION FAILURE FIXTURE
		# --------------------------------------------------------
		# Remove all executable industrial capacity and production output.
		# The production bridge must then reduce its military-capacity
		# support signal.
		var collapsed_processes = fixture_processes.duplicate(true)

		for raw_process_id in collapsed_processes.keys():
			var instance = collapsed_processes[raw_process_id]
			if typeof(instance) != TYPE_DICTIONARY:
				continue
			instance["active"] = false
			instance["capacity"] = 0.0

		industry.set_state(
			"processes",
			collapsed_processes
		)
		industry.set_state(
			"production_state",
			{}
		)

		system.process_month(world)

		var collapsed_support := float(
			military.get_state(
				"production_military_support",
				-1.0
			)
		)
		var collapsed_modifier := float(
			military.get_state(
				"production_capacity_modifier",
				-1.0
			)
		)

		_log_result(
			"Production collapse lowers military production support",
			collapsed_support < baseline_support
		)
		_log_result(
			"Production collapse lowers/maintains constrained capacity modifier",
			collapsed_modifier < baseline_modifier
		)

		if not (
			collapsed_support < baseline_support
		):
			passed = false

		if not (
			collapsed_modifier < baseline_modifier
		):
			passed = false

		# --------------------------------------------------------
		# MILITARY INTEGRATION
		# --------------------------------------------------------
		# Run the authoritative MilitarySystem after the production bridge.
		# The existing military model should respond through its existing
		# industrial_support path rather than through a second power model.
		var authoritative_military_system: MilitarySystem = (
			military_system_instance as MilitarySystem
		)

		authoritative_military_system.process_month(world)

		var collapsed_industrial_support := float(
			military.get_state(
				"industrial_support",
				0.0
			)
		)
		var collapsed_readiness := float(
			military.get_state(
				"readiness",
				0.0
			))
		var collapsed_power := float(
			military.get_state(
				"military_power",
				0.0
			))

		_log_result(
			"Production capacity constrains MilitarySystem industrial support",
			collapsed_industrial_support < baseline_industrial_support
		)
		_log_result(
			"Production capacity remains causally visible in readiness/power path",
			collapsed_readiness < baseline_readiness
			or collapsed_power < baseline_power
		)

		if not (
			collapsed_industrial_support < baseline_industrial_support
		):
			passed = false

		if not (
			collapsed_readiness < baseline_readiness
			or collapsed_power < baseline_power
		):
			passed = false

	# ------------------------------------------------------------
	# RESTORE EXACT BASELINE
	# ------------------------------------------------------------
	industry.set_state(
		"processes",
		original_industry_processes
	)
	industry.set_state(
		"process_adoption",
		original_industry_adoption
	)
	industry.set_state(
		"production_state",
		original_production_state
	)
	military.state = original_military_state

	# Direct structural restoration check.
	var restoration_ok :float= (
		industry.get_state("processes", {}) == original_industry_processes
		and industry.get_state("process_adoption", {}) == original_industry_adoption
		and industry.get_state("production_state", {}) == original_production_state
		and military.state == original_military_state
	)

	_log_result(
		"Step 13.1 fixture restoration",
		restoration_ok
	)

	if industry.get_state("processes", {}) != original_industry_processes:
		passed = false
	if industry.get_state("process_adoption", {}) != original_industry_adoption:
		passed = false
	if industry.get_state("production_state", {}) != original_production_state:
		passed = false
	if military.state != original_military_state:
		passed = false

	_out([""])
	_out(["Step 13.1 production → military capacity overall: ", "PASS" if passed else "FAIL"])
	_out(["Step 13.1 test: ", "PASS" if passed else "FAIL"])

	return passed
