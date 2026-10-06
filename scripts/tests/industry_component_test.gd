class_name IndustryComponentTest
extends RefCounted


static func run() -> bool:
	var industry = IndustryComponent.new("india")

	industry.setup(
		{
			"steel_basic_process": {
				"active": true,
				"capacity": 100.0,
				"efficiency": 0.85
			},
			"coal_mining_process": {
				"active": false,
				"capacity": 50.0,
				"efficiency": 0.70
			}
		}
	)

	var passed := true

	var processes = industry.get_state(
		"processes",
		{}
	)

	passed = _check(
		processes.has("steel_basic_process"),
		"Steel process exists"
	) and passed

	passed = _check(
		processes.has("coal_mining_process"),
		"Coal process exists"
	) and passed

	passed = _check(
		processes["steel_basic_process"]["active"] == true,
		"Active state"
	) and passed

	passed = _check(
		is_equal_approx(
			float(processes["steel_basic_process"]["capacity"]),
			100.0
		),
		"Capacity"
	) and passed

	passed = _check(
		is_equal_approx(
			float(processes["steel_basic_process"]["efficiency"]),
			0.85
		),
		"Efficiency"
	) and passed

	passed = _check(
		processes["coal_mining_process"]["active"] == false,
		"Inactive process"
	) and passed

	var process_adoption = industry.get_state(
		"process_adoption",
		{}
	)
	
	
	passed = _check(
		is_equal_approx(
			float(
				process_adoption.get(
					"steel_basic_process",
					0.0
				)
			),
			1.0
		),
		"Existing process adoption"
	) and passed

	passed = _check(
		typeof(process_adoption) == TYPE_DICTIONARY,
		"Process adoption state"
	) and passed

	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:
	if condition:
		print("Industry " + label + ": PASS")
		return true

	push_error(
		"Industry " + label + ": FAIL"
	)

	return false
