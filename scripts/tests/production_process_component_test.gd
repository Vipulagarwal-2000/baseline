class_name ProductionProcessComponentTest
extends RefCounted


static func run() -> bool:
	var process = ProductionProcess.new("test_country")

	process.setup(
		{
			"iron_ore": 2.0,
			"coal": 1.0
		},
		{
			"steel": 2.0
		},
		{
			"slag": 0.2
		},
		{
			"steelmaking": 1.0
		},
		{
			"industrial_processing": 1.0
		},
		{
			"steel_mill": 1.0
		},
		10.0,
		500.0,
		50.0,
		100.0,
		0.9,
		0.5,
		{
			"old_steel_process": 0.2
		},
		0.1,
		100.0,
		2.0,
		{
			"steelmaking": 3.0
		},
		{
			"blast_furnace": 1.0
		},
		{
			"coal": 5.0,
			"electricity": 10.0
		},
		5.0,
		{
			"machinery": 2.0
		},
		0.95,
		{
			"winter": 0.8,
			"summer": 1.0
		},
		{
			"slag": 0.2,
			"dust": 0.05
		},
		{
			"steel_mill": 1.0
		}
	)

	var passed := true

	passed = _check(
		process.get_state("inputs", {}).get("iron_ore", -1) == 2.0,
		"Inputs"
	) and passed

	passed = _check(
		process.get_state("outputs", {}).get("steel", -1) == 2.0,
		"Outputs"
	) and passed

	passed = _check(
		process.get_state("byproducts", {}).get("slag", -1) == 0.2,
		"Byproducts"
	) and passed

	passed = _check(
		process.get_state("technology_requirements", {}).get("steelmaking", -1) == 1.0,
		"Technology requirements"
	) and passed

	passed = _check(
		process.get_state("capability_requirements", {}).get("industrial_processing", -1) == 1.0,
		"Capability requirements"
	) and passed

	passed = _check(
		process.get_state("infrastructure_requirements", {}).get("steel_mill", -1) == 1.0,
		"Infrastructure requirements"
	) and passed

	passed = _check(
		process.get_state("infrastructure_usage", {}).get("steel_mill", -1) == 1.0,
		"Infrastructure usage"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("labor_requirement", -1)),
			10.0
		),
		"Labor requirement"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("capital_requirement", -1)),
			500.0
		),
		"Capital requirement"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("operating_cost", -1)),
			50.0
		),
		"Operating cost"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("transition_cost", -1)),
			100.0
		),
		"Transition cost"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("efficiency", -1)),
			0.9
		),
		"Efficiency"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("adoption", -1)),
			0.5
		),
		"Adoption"
	) and passed

	passed = _check(
		process.get_state("displacement", {}).get("old_steel_process", -1) == 0.2,
		"Displacement"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("obsolescence", -1)),
			0.1
		),
		"Obsolescence"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("capacity", -1)),
			100.0
		),
		"Capacity"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("duration", -1)),
			2.0
		),
		"Duration"
	) and passed

	passed = _check(
		process.get_state("labor_skill_requirement", {}).get("steelmaking", -1) == 3.0,
		"Labor skill requirement"
	) and passed

	passed = _check(
		process.get_state("equipment_requirement", {}).get("blast_furnace", -1) == 1.0,
		"Equipment requirement"
	) and passed

	passed = _check(
		process.get_state("energy_requirement", {}).get("electricity", -1) == 10.0,
		"Energy requirement"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("land_requirement", -1)),
			5.0
		),
		"Land requirement"
	) and passed

	passed = _check(
		process.get_state("maintenance_requirement", {}).get("machinery", -1) == 2.0,
		"Maintenance requirement"
	) and passed

	passed = _check(
		is_equal_approx(
			float(process.get_state("reliability", -1)),
			0.95
		),
		"Reliability"
	) and passed

	passed = _check(
		process.get_state("seasonality", {}).get("winter", -1) == 0.8,
		"Seasonality"
	) and passed

	passed = _check(
		process.get_state("waste", {}).get("dust", -1) == 0.05,
		"Waste"
	) and passed

	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:
	if condition:
		print("ProductionProcess " + label + ": PASS")
		return true

	push_error(
		"ProductionProcess " + label + ": FAIL"
	)

	return false
