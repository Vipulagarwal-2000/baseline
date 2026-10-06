class_name IndustryProcessResourceDemandTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true
	var system := ProductionProcessSystem.new()

	var basic_steel := system.catalog.get_process(
		"steel_basic"
	)

	var advanced_steel := system.catalog.get_process(
		"advanced_steel_production"
	)

	# Test 1 — Basic process demand.
	var basic_demand := (
		ProductionProcessSystem.calculate_process_resource_demand(
			basic_steel,
			10.0,
			1.0,
			1.0
		)
	)

	var basic_demand_passed := (
		is_equal_approx(
			float(basic_demand.get("iron", 0.0)),
			20.0
		)
		and is_equal_approx(
			float(basic_demand.get("coal", 0.0)),
			10.0
		)
	)

	passed = passed and basic_demand_passed

	TestLogger.write_line(
		"Step 9 basic process resource demand: "
		+ ("PASS" if basic_demand_passed else "FAIL")
	)

	# Test 2 — Advanced process has different demand.
	var advanced_demand := (
		ProductionProcessSystem.calculate_process_resource_demand(
			advanced_steel,
			10.0,
			1.0,
			1.0
		)
	)

	var advanced_demand_passed := (
		is_equal_approx(
			float(advanced_demand.get("iron", 0.0)),
			19.8
		)
		and is_equal_approx(
			float(advanced_demand.get("coal", 0.0)),
			8.8
		)
	)

	passed = passed and advanced_demand_passed

	TestLogger.write_line(
		"Step 9 advanced process resource demand: "
		+ ("PASS" if advanced_demand_passed else "FAIL")
	)

	# Test 3 — Competing process adoption changes total demand.
	var definitions := {
		"steel_basic": basic_steel,
		"advanced_steel_production": advanced_steel
	}

	var capacities := {
		"steel_basic": 10.0,
		"advanced_steel_production": 10.0
	}

	var adoption := {
		"steel_basic": 0.60,
		"advanced_steel_production": 0.40
	}

	var mixed_demand := (
		ProductionProcessSystem.calculate_resource_demand_for_process_mix(
			definitions,
			capacities,
			adoption
		)
	)

	# Basic output: 10 * 0.60 * 1.00 = 6.0
	# Advanced output: 10 * 0.40 * 1.10 = 4.4
	# Iron: 6.0 * 2.0 + 4.4 * 1.8 = 19.92
	# Coal: 6.0 * 1.0 + 4.4 * 0.8 = 9.52
	var mixed_demand_passed := (
		is_equal_approx(
			float(mixed_demand.get("iron", 0.0)),
			19.92
		)
		and is_equal_approx(
			float(mixed_demand.get("coal", 0.0)),
			9.52
		)
	)

	passed = passed and mixed_demand_passed

	TestLogger.write_line(
		"Step 9 competing-process resource demand: "
		+ ("PASS" if mixed_demand_passed else "FAIL")
	)

	# Test 4 — Old-resource demand falls as the new process takes share.
	var coal_reduction_passed := (
		float(mixed_demand.get("coal", 0.0))
		< float(basic_demand.get("coal", 0.0))
	)

	passed = passed and coal_reduction_passed

	TestLogger.write_line(
		"Step 9 old-resource demand changes with adoption: "
		+ ("PASS" if coal_reduction_passed else "FAIL")
	)

	# Test 5 — A process can introduce a new resource.
	var new_resource_process := {
		"inputs": {
			"coal": 0.5,
			"electricity": 0.2
		},
		"efficiency": 1.0
	}

	var new_resource_demand := (
		ProductionProcessSystem.calculate_process_resource_demand(
			new_resource_process,
			10.0,
			0.50,
			1.0
		)
	)

	var new_resource_passed := (
		is_equal_approx(
			float(new_resource_demand.get("coal", 0.0)),
			2.5
		)
		and is_equal_approx(
			float(new_resource_demand.get("electricity", 0.0)),
			1.0
		)
	)

	passed = passed and new_resource_passed

	TestLogger.write_line(
		"Step 9 new resource demand introduced by process: "
		+ ("PASS" if new_resource_passed else "FAIL")
	)

	# Test 6 — Zero adoption creates no demand.
	var zero_adoption_demand := (
		ProductionProcessSystem.calculate_process_resource_demand(
			advanced_steel,
			10.0,
			0.0,
			1.0
		)
	)

	var zero_adoption_passed := (
		zero_adoption_demand.is_empty()
	)

	passed = passed and zero_adoption_passed

	TestLogger.write_line(
		"Step 9 zero adoption resource demand: "
		+ ("PASS" if zero_adoption_passed else "FAIL")
	)

	# Test 7 — Demand calculation does not mutate the definition.
	var original_inputs: Dictionary = (
		advanced_steel.get(
			"inputs",
			{}
		).duplicate(true)
	)

	ProductionProcessSystem.calculate_process_resource_demand(
		advanced_steel,
		100.0,
		0.75,
		1.0
	)

	var definition_unchanged_passed :float= (
		advanced_steel.get(
			"inputs",
			{}
		) == original_inputs
	)

	passed = passed and definition_unchanged_passed

	TestLogger.write_line(
		"Step 9 demand calculation preserves process definition: "
		+ ("PASS" if definition_unchanged_passed else "FAIL")
	)

	TestLogger.write_line(
		"Industry process resource-demand test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
