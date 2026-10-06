class_name MilitaryCountryDataTest
extends RefCounted


func run(world: WorldState) -> bool:
	var logger = TestLogger.current

	logger.section("MILITARY COUNTRY DATA TEST")

	if world == null:
		logger.write_line("World: FAIL")
		return false

	var passed = true

	passed = _check_country(
		world,
		"china",
		{
			"military_power": 0.62,
			"readiness": 0.60,
			"manpower": 0.72,
			"logistics_capacity": 0.38,
			"army_strength": 0.78,
			"naval_strength": 0.08,
			"air_strength": 0.08,
			"industrial_support": 0.28,
			"military_technology": 0.18,
			"command_capacity": 0.45,
			"resource_security": 0.48,
			"defensive_capability": 0.64,
			"power_projection": 0.28,
			"mobilization_capacity": 0.76,
			"military_spending": 0.65,
			"military_pressure": 0.48
		}
	) and passed

	passed = _check_country(
		world,
		"india",
		{
			"military_power": 0.50,
			"readiness": 0.55,
			"manpower": 0.58,
			"logistics_capacity": 0.43,
			"army_strength": 0.65,
			"naval_strength": 0.18,
			"air_strength": 0.16,
			"industrial_support": 0.32,
			"military_technology": 0.24,
			"command_capacity": 0.50,
			"resource_security": 0.52,
			"defensive_capability": 0.68,
			"power_projection": 0.34,
			"mobilization_capacity": 0.60,
			"military_spending": 0.42,
			"military_pressure": 0.35
		}
	) and passed

	passed = _check_country(
		world,
		"usa",
		{
			"military_power": 0.78,
			"readiness": 0.72,
			"manpower": 0.62,
			"logistics_capacity": 0.82,
			"army_strength": 0.62,
			"naval_strength": 0.88,
			"air_strength": 0.86,
			"industrial_support": 0.92,
			"military_technology": 0.82,
			"command_capacity": 0.84,
			"resource_security": 0.88,
			"defensive_capability": 0.82,
			"power_projection": 0.92,
			"mobilization_capacity": 0.68,
			"military_spending": 0.58,
			"military_pressure": 0.30
		}
	) and passed

	if passed:
		logger.write_line("")
		logger.write_line("MILITARY COUNTRY DATA TEST PASSED")
	else:
		logger.write_line("")
		logger.write_line("MILITARY COUNTRY DATA TEST FAILED")

	return passed


func _check_country(
	world: WorldState,
	country_id: String,
	expected: Dictionary
) -> bool:

	var logger = TestLogger.current
	var country = world.get_entity(country_id)

	if country == null:
		logger.write_line(country_id + " country: FAIL")
		return false

	var military = country.get_component("military")

	if military == null:
		logger.write_line(country_id + " military component: FAIL")
		return false

	var country_passed = true

	logger.write_line("")
	logger.write_line("Country: " + country_id)

	for key in expected.keys():
		var actual = _get_baseline_value(
			military,
			str(key)
		)

		var expected_value = float(expected[key])

		var matches = is_equal_approx(
			actual,
			expected_value
		)

		logger.write_line(
			"  "
			+ str(key)
			+ ": "
			+ ("PASS" if matches else "FAIL")
			+ " | expected="
			+ str(expected_value)
			+ " actual="
			+ str(actual)
		)

		if not matches:
			country_passed = false

	logger.write_line(
		"Country military baseline: "
		+ ("PASS" if country_passed else "FAIL")
	)

	return country_passed


func _get_baseline_value(
	component,
	key: String
) -> float:

	var value = component.get_baseline(
	key,
	-999.0
)

	return float(value)
