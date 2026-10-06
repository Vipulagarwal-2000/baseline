class_name MilitaryTest
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
	_out(["MILITARY SYSTEM TEST"])
	_out(["================================"])

	if world == null:

		_out([
			"Military Test: FAIL - World is null."
		])

		return

	if simulation == null:

		_out([
			"Military Test: FAIL - SimulationEngine is null."
		])

		return

	var passed: bool = true


	# ============================================================
	# 1. VERIFY MILITARY SYSTEM REGISTRATION
	# ============================================================

	var military_system = simulation.get_system(
		"military_system"
	)

	if military_system == null:

		_out([
			"Military system registration: FAIL"
		])

		passed = false

	else:

		_out([
			"Military system registration: PASS"
		])


	# ============================================================
	# 2. VERIFY MILITARY COMPONENTS
	# ============================================================

	var country_ids = [
		"china",
		"india",
		"usa"
	]

	for country_id in country_ids:

		var country = world.get_entity(
			country_id
		)

		if country == null:

			_out([
				country_id,
				" entity: FAIL"
			])

			passed = false
			continue

		var military = country.get_component(
			"military"
		)

		if military == null:

			_out([
				country_id,
				" military component: FAIL"
			])

			passed = false
			continue

		_out([
			country_id,
			" military component: PASS"
		])


	# ============================================================
	# 3. VERIFY INDIA COMPONENTS
	# ============================================================

	var india = world.get_entity(
		"india"
	)

	if india == null:

		_out([
			"India lookup: FAIL"
		])

		passed = false
		return


	var india_population = india.get_component(
		"population"
	)

	var india_economy = india.get_component(
		"economy"
	)

	var india_resources = india.get_component(
		"resources"
	)

	var india_research = india.get_component(
		"research"
	)

	var india_technology_adoption = india.get_component(
		"technology_adoption"
	)

	var india_military = india.get_component(
		"military"
	)


	if india_population == null:

		_out([
			"India population component: FAIL"
		])

		passed = false

	else:

		_out([
			"India population component: PASS"
		])


	if india_economy == null:

		_out([
			"India economy component: FAIL"
		])

		passed = false

	else:

		_out([
			"India economy component: PASS"
		])


	if india_resources == null:

		_out([
			"India resources component: FAIL"
		])

		passed = false

	else:

		_out([
			"India resources component: PASS"
		])


	if india_research == null:

		_out([
			"India research component: FAIL"
		])

		passed = false

	else:

		_out([
			"India research component: PASS"
		])


	if india_technology_adoption == null:

		_out([
			"India technology adoption component: FAIL"
		])

		passed = false

	else:

		_out([
			"India technology adoption component: PASS"
		])


	if india_military == null:

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
	# 4. VERIFY INITIAL POPULATION AND MILITARY STATE
	# ============================================================

	var initial_population = float(
		india_population.get_state(
			"population",
			-1.0
		)
	)

	var initial_manpower = float(
		india_military.get_state(
			"manpower",
			-1.0
		)
	)

	if initial_population <= 0.0:

		_out([
			"Initial population state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial population state: PASS | ",
			initial_population
		])


	if (
		initial_manpower < 0.0
		or initial_manpower > 1.0
	):

		_out([
			"Initial manpower state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial manpower state: PASS | ",
			initial_manpower
		])


	# ============================================================
	# 5. POPULATION → MANPOWER TARGET
	# ============================================================

	var manpower_reference = 600000000.0

	var expected_manpower_target = clamp(
		initial_population / manpower_reference,
		0.0,
		1.0
	)

	_out([
		"Population-derived manpower target: ",
		expected_manpower_target
	])


	# ============================================================
	# 6. CAPTURE INITIAL ECONOMY → MILITARY STATE
	# ============================================================

	var initial_gdp = float(
		india_economy.get_state(
			"gdp",
			-1.0
		)
	)

	var initial_industrial_support = float(
		india_military.get_state(
			"industrial_support",
			-1.0
		)
	)

	var initial_logistics = float(
		india_military.get_state(
			"logistics_capacity",
			-1.0
		)
	)

	var initial_military_technology = float(
		india_military.get_state(
			"military_technology",
			-1.0
		)
	)

	var initial_command_capacity = float(
		india_military.get_state(
			"command_capacity",
			-1.0
		)
	)


	if initial_gdp <= 0.0:

		_out([
			"Initial GDP state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial GDP state: PASS | ",
			initial_gdp
		])


	if (
		initial_industrial_support < 0.0
		or initial_industrial_support > 1.0
	):

		_out([
			"Initial industrial support state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial industrial support state: PASS | ",
			initial_industrial_support
		])


	if (
		initial_logistics < 0.0
		or initial_logistics > 1.0
	):

		_out([
			"Initial logistics state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial logistics state: PASS | ",
			initial_logistics
		])


	if (
		initial_military_technology < 0.0
		or initial_military_technology > 1.0
	):

		_out([
			"Initial military technology state: FAIL"
		])

		passed = false

	else:

		_out([
			"Initial military technology state: PASS | ",
			initial_military_technology
		])


	if (
		india_research != null
	):

		var initial_research_technology_level = float(
			india_research.get_state(
				"technology_level",
				-1.0
			)
		)

		if initial_research_technology_level < 0.0:

			_out([
				"Initial research technology level: FAIL"
			])

			passed = false

		else:

			_out([
				"Initial research technology level: PASS | ",
				initial_research_technology_level
			])


		var research_technologies = (
			india_research.get_state(
				"technologies",
				{}
			)
		)

		if typeof(
			research_technologies
		) == TYPE_DICTIONARY:

			_out([
				"Research technology dictionary: PASS"
			])

		else:

			_out([
				"Research technology dictionary: FAIL"
			])

			passed = false


	# ============================================================
	# 7. RUN ONE REAL SIMULATION MONTH
	# ============================================================

	var date_before = world.get_date_string()

	simulation.tick_month()

	var date_after = world.get_date_string()

	_out([""])

	_out([
		"Military monthly execution: ",
		date_before,
		" -> ",
		date_after
	])


	# ============================================================
	# 8. READ POPULATION AND MANPOWER AFTER TICK
	# ============================================================

	var population_after = float(
		india_population.get_state(
			"population",
			-1.0
		)
	)

	var manpower_after = float(
		india_military.get_state(
			"manpower",
			-1.0
		)
	)

	_out([
		"Population before: ",
		initial_population
	])

	_out([
		"Population after: ",
		population_after
	])

	_out([
		"Manpower before: ",
		initial_manpower
	])

	_out([
		"Manpower after: ",
		manpower_after
	])


	# ============================================================
	# 9. VERIFY POPULATION CHANGED
	# ============================================================

	if abs(
		population_after
		- initial_population
	) <= 0.0:

		_out([
			"Population monthly change: FAIL"
		])

		passed = false

	else:

		_out([
			"Population monthly change: PASS"
		])


	# ============================================================
	# 10. VERIFY MANPOWER MOVED TOWARD POPULATION TARGET
	# ============================================================

	var initial_distance = abs(
		initial_manpower
		- expected_manpower_target
	)

	var final_population_target = clamp(
		population_after / manpower_reference,
		0.0,
		1.0
	)

	var final_distance = abs(
		manpower_after
		- final_population_target
	)

	if final_distance < initial_distance:

		_out([
			"Population -> manpower causal response: PASS"
		])

	else:

		_out([
			"Population -> manpower causal response: FAIL"
		])

		passed = false


	# ============================================================
	# 11. VERIFY POPULATION → MANPOWER FORMULA
	# ============================================================

	var expected_first_step = lerp(
		initial_manpower,
		final_population_target,
		0.10
	)

	var formula_error = abs(
		manpower_after
		- expected_first_step
	)

	if formula_error <= 0.000001:

		_out([
			"Population -> manpower formula: PASS"
		])

	else:

		_out([
			"Population -> manpower formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_first_step
		])

		_out([
			"Actual: ",
			manpower_after
		])

		passed = false


	# ============================================================
	# 12. READ ECONOMY AFTER ECONOMYSYSTEM
	# ============================================================

	var gdp_after = float(
		india_economy.get_state(
			"gdp",
			-1.0
		)
	)

	var industrial_support_after = float(
		india_military.get_state(
			"industrial_support",
			-1.0
		)
	)

	var logistics_after = float(
		india_military.get_state(
			"logistics_capacity",
			-1.0
		)
	)

	var military_technology_after = float(
		india_military.get_state(
			"military_technology",
			-1.0
		)
	)

	var command_capacity_after = float(
		india_military.get_state(
			"command_capacity",
			-1.0
		)
	)


	_out([""])
	_out(["================================"])
	_out(["ECONOMY -> MILITARY TEST"])
	_out(["================================"])

	_out([
		"GDP before: ",
		initial_gdp
	])

	_out([
		"GDP after: ",
		gdp_after
	])

	_out([
		"Industrial support before: ",
		initial_industrial_support
	])

	_out([
		"Industrial support after: ",
		industrial_support_after
	])

	_out([
		"Logistics before: ",
		initial_logistics
	])

	_out([
		"Logistics after: ",
		logistics_after
	])


	# ============================================================
	# 13. VERIFY GDP CHANGED
	# ============================================================

	if abs(
		gdp_after
		- initial_gdp
	) <= 0.0:

		_out([
			"Economy GDP monthly change: FAIL"
		])

		passed = false

	else:

		_out([
			"Economy GDP monthly change: PASS"
		])


	# ============================================================
	# 14. CALCULATE ECONOMIC CAPACITY
	# ============================================================

	var economic_capacity = clamp(
		gdp_after / 1500000000000.0,
		0.0,
		1.0
	)

	_out([
		"Economic capacity target: ",
		economic_capacity
	])


	# ============================================================
	# 15. CALCULATE ECONOMY → MILITARY INTERMEDIATE VALUES
	# ============================================================

	var expected_economy_industrial_support = lerp(
		initial_industrial_support,
		economic_capacity,
		0.05
	)

	var expected_economy_logistics = lerp(
		initial_logistics,
		economic_capacity,
		0.05
	)


	# ============================================================
	# 16. VERIFY INDUSTRIAL SUPPORT RESPONSE
	#
	# Technology may modify this value later in MilitarySystem,
	# so we compare the economy-only intermediate value here.
	# ============================================================

	var industrial_economy_distance = abs(
		initial_industrial_support
		- economic_capacity
	)

	var industrial_after_economy_distance = abs(
		expected_economy_industrial_support
		- economic_capacity
	)

	if industrial_after_economy_distance < industrial_economy_distance:

		_out([
			"Economy -> industrial support causal response: PASS"
		])

	else:

		_out([
			"Economy -> industrial support causal response: FAIL"
		])

		passed = false


	var industrial_economy_formula_error = abs(
		expected_economy_industrial_support
		- lerp(
			initial_industrial_support,
			economic_capacity,
			0.05
		)
	)

	if industrial_economy_formula_error <= 0.000001:

		_out([
			"Economy -> industrial support formula: PASS"
		])

	else:

		_out([
			"Economy -> industrial support formula: FAIL"
		])

		passed = false


	# ============================================================
	# 17. VERIFY ECONOMY → LOGISTICS INTERMEDIATE VALUE
	# ============================================================

	var logistics_economy_distance = abs(
		initial_logistics
		- economic_capacity
	)

	var logistics_after_economy_distance = abs(
		expected_economy_logistics
		- economic_capacity
	)

	if logistics_after_economy_distance < logistics_economy_distance:

		_out([
			"Economy -> logistics causal response: PASS"
		])

	else:

		_out([
			"Economy -> logistics causal response: FAIL"
		])

		passed = false


	# ============================================================
	# 18. VERIFY RESOURCES → MILITARY
	# ============================================================

	_out([""])
	_out(["================================"])
	_out(["RESOURCES -> MILITARY TEST"])
	_out(["================================"])

	var net_balance = india_resources.get_state(
		"net_balance",
		{}
	)

	var consumption = india_resources.get_state(
		"consumption",
		{}
	)

	var shortages = india_resources.get_state(
		"shortages",
		{}
	)

	var shortage_ratio = india_resources.get_state(
		"shortage_ratio",
		{}
	)

	var strategic_resources = [
		"coal",
		"iron",
		"oil"
	]

	var security_total = 0.0
	var security_count = 0


	for resource_name in strategic_resources:

		var balance = float(
			net_balance.get(
				resource_name,
				0.0
			)
		)

		var demand = float(
			consumption.get(
				resource_name,
				0.0
			)
		)

		var shortage = float(
			shortages.get(
				resource_name,
				0.0
			)
		)

		var shortage_percent = float(
			shortage_ratio.get(
				resource_name,
				0.0
			)
		)


		_out([
			resource_name,
			" net balance: ",
			balance
		])

		_out([
			resource_name,
			" consumption: ",
			demand
		])

		_out([
			resource_name,
			" shortage: ",
			shortage
		])

		_out([
			resource_name,
			" shortage ratio: ",
			shortage_percent
		])


		if demand <= 0.0:

			continue


		var balance_ratio = clamp(
			balance / demand,
			-1.0,
			1.0
		)

		var resource_score = (
			0.50
			+ balance_ratio * 0.50
		)

		security_total += resource_score
		security_count += 1


		_out([
			resource_name,
			" security score: ",
			resource_score
		])


	var expected_resource_security = 0.50

	if security_count > 0:

		expected_resource_security = (
			security_total
			/ float(security_count)
		)


	expected_resource_security = clamp(
		expected_resource_security,
		0.0,
		1.0
	)


	var actual_resource_security = float(
		india_military.get_state(
			"resource_security",
			-1.0
		)
	)


	_out([
		"Expected resource security: ",
		expected_resource_security
	])

	_out([
		"Actual resource security: ",
		actual_resource_security
	])


	# ============================================================
	# 19. VERIFY RESOURCE SECURITY FORMULA
	# ============================================================

	var resource_security_error = abs(
		actual_resource_security
		- expected_resource_security
	)

	if resource_security_error <= 0.000001:

		_out([
			"Resources -> resource security formula: PASS"
		])

	else:

		_out([
			"Resources -> resource security formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_resource_security
		])

		_out([
			"Actual: ",
			actual_resource_security
		])

		_out([
			"Error: ",
			resource_security_error
		])

		passed = false


	# ============================================================
	# 20. TECHNOLOGY EFFECTS → MILITARY CAPABILITIES
	# ============================================================

	_out([""])
	_out(["================================"])
	_out(["TECHNOLOGY EFFECTS -> MILITARY"])
	_out(["================================"])


	# ------------------------------------------------------------
	# IMPORTANT:
	# Use a local research reference inside this scope.
	# This avoids the previous "research not declared" error.
	# ------------------------------------------------------------

	var technology_research = india.get_component(
		"research"
	)


	if technology_research == null:

		_out([
			"Technology research component: FAIL"
		])

		passed = false

	else:

		_out([
			"Technology research component: PASS"
		])


	var technology_effects: Dictionary = {}

	if technology_research != null:

		var raw_technology_effects = (
			technology_research.get_state(
				"technology_effects",
				{}
			)
		)

		if typeof(
			raw_technology_effects
		) == TYPE_DICTIONARY:

			technology_effects = (
				raw_technology_effects
			)

			_out([
				"Technology effects dictionary: PASS"
			])

		else:

			_out([
				"Technology effects dictionary: FAIL"
			])

			passed = false


	# ------------------------------------------------------------
	# Read aggregated technology effects.
	# ------------------------------------------------------------

	var military_industrial_effect = float(
		technology_effects.get(
			"military_industrial_support",
			0.0
		)
	)

	var military_logistics_effect = float(
		technology_effects.get(
			"military_logistics_support",
			0.0
		)
	)

	var military_command_effect = float(
		technology_effects.get(
			"military_command_capacity",
			0.0
		)
	)

	var military_technology_effect = float(
		technology_effects.get(
			"military_technology_support",
			0.0
		))


	_out([
		"Military industrial technology effect: ",
		military_industrial_effect
	])

	_out([
		"Military logistics technology effect: ",
		military_logistics_effect
	])

	_out([
		"Military command technology effect: ",
		military_command_effect
	])

	_out([
		"Military technology support effect: ",
		military_technology_effect
	])


	# ------------------------------------------------------------
	# Verify that the expected technology effects are valid.
	#
	# Industrial, logistics, and command effects are expected to
	# be present in India's current technology state.
	#
	# Military technology support is allowed to be zero because
	# it depends on whether India has completed a technology that
	# provides that specific effect.
	# ------------------------------------------------------------

	var technology_effects_present = (
	military_industrial_effect > 0.0
	and military_logistics_effect > 0.0
	and military_command_effect > 0.0
	and military_technology_effect >= 0.0
)


	if technology_effects_present:

		_out([
			"Military technology effects present: PASS"
		])

	else:

		_out([
			"Military technology effects present: FAIL"
		])

		passed = false


	# ============================================================
	# 21. CALCULATE TECHNOLOGY-ADJUSTED MILITARY VALUES
	# ============================================================

	# ------------------------------------------------------------
	# Convert the technology effect values into the normalized
	# 0-1 range used by MilitaryComponent.
	# ------------------------------------------------------------

	var normalized_industrial_effect = clamp(
		military_industrial_effect / 100.0,
		0.0,
		1.0
	)

	var normalized_logistics_effect = clamp(
		military_logistics_effect / 100.0,
		0.0,
		1.0
	)

	var normalized_command_effect = clamp(
		military_command_effect / 100.0,
		0.0,
		1.0
	)

	var normalized_military_technology_effect = clamp(
		military_technology_effect / 100.0,
		0.0,
		1.0
	)


	# ------------------------------------------------------------
	# MilitarySystem first applies economy effects.
	# Then technology effects.
	# Then resource effects to logistics.
	# ------------------------------------------------------------

	var expected_technology_industrial_support = (
		expected_economy_industrial_support
	)

	if normalized_industrial_effect > 0.0:

		expected_technology_industrial_support = lerp(
			expected_economy_industrial_support,
			clamp(
				expected_economy_industrial_support
				+ normalized_industrial_effect * 0.25,
				0.0,
				1.0
			),
			0.05
		)


	var expected_technology_logistics = (
		expected_economy_logistics
	)

	if normalized_logistics_effect > 0.0:

		expected_technology_logistics = lerp(
			expected_economy_logistics,
			clamp(
				expected_economy_logistics
				+ normalized_logistics_effect * 0.25,
				0.0,
				1.0
			),
			0.05
		)


	var expected_technology_command = (
		initial_command_capacity
	)

	if normalized_command_effect > 0.0:

		expected_technology_command = lerp(
			initial_command_capacity,
			clamp(
				initial_command_capacity
				+ normalized_command_effect * 0.25,
				0.0,
				1.0
			),
			0.05
		)


	# ============================================================
	# 22. VERIFY TECHNOLOGY → INDUSTRIAL SUPPORT
	# ============================================================

	var technology_industrial_error = abs(
		industrial_support_after
		- expected_technology_industrial_support
	)


	_out([
		"Expected technology-adjusted industrial support: ",
		expected_technology_industrial_support
	])

	_out([
		"Actual industrial support: ",
		industrial_support_after
	])


	if technology_industrial_error <= 0.000001:

		_out([
			"Technology -> industrial support formula: PASS"
		])

	else:

		_out([
			"Technology -> industrial support formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_technology_industrial_support
		])

		_out([
			"Actual: ",
			industrial_support_after
		])

		_out([
			"Error: ",
			technology_industrial_error
		])

		passed = false


	# ============================================================
	# 23. VERIFY TECHNOLOGY → LOGISTICS INTERMEDIATE VALUE
	# ============================================================

	_out([
		"Technology-adjusted logistics before resources: ",
		expected_technology_logistics
	])


	# ============================================================
	# 24. VERIFY TECHNOLOGY → COMMAND CAPACITY
	# ============================================================

	var technology_command_error = abs(
		command_capacity_after
		- expected_technology_command
	)


	_out([
		"Expected technology-adjusted command capacity: ",
		expected_technology_command
	])

	_out([
		"Actual command capacity: ",
		command_capacity_after
	])


	if technology_command_error <= 0.000001:

		_out([
			"Technology -> command capacity formula: PASS"
		])

	else:

		_out([
			"Technology -> command capacity formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_technology_command
		])

		_out([
			"Actual: ",
			command_capacity_after
		])

		_out([
			"Error: ",
			technology_command_error
		])

		passed = false


	# ============================================================
	# 25. RESEARCH → MILITARY TECHNOLOGY
	# ============================================================

	_out([""])
	_out(["================================"])
	_out(["RESEARCH -> MILITARY TEST"])
	_out(["================================"])


	var research_technology_level_before = float(
		technology_research.get_state(
			"technology_level",
			0.0
		)
	)

	_out([
		"Research technology level before: ",
		research_technology_level_before
	])


	var research_technology_level_after = float(
		technology_research.get_state(
			"technology_level",
			0.0
		)
	)


	_out([
		"Research technology level after: ",
		research_technology_level_after
	])


	if research_technology_level_after >= (
		research_technology_level_before
	):

		_out([
			"Research technology level after tick: PASS"
		])

	else:

		_out([
			"Research technology level after tick: FAIL"
		])

		passed = false


	var completed_technologies = (
		technology_research.get_state(
			"technologies",
			{}
		)
	)


	if typeof(
		completed_technologies
	) == TYPE_DICTIONARY:

		_out([
			"Completed technologies state: PASS"
		])

	else:

		_out([
			"Completed technologies state: FAIL"
		])

		passed = false


	var research_maturity = clamp(
		research_technology_level_after / 40.0,
		0.0,
		1.0
	)


	var adoption_factor = 0.0
	var adoption_count = 0


	if (
		typeof(completed_technologies)
		== TYPE_DICTIONARY
	):

		for technology_id in (
			completed_technologies.keys()
		):

			if not bool(
				completed_technologies[
					technology_id
				]
			):

				continue


			var adoption_value = (
				india_technology_adoption.get_adoption(
					str(technology_id)
				)
			)


			_out([
				"Technology ",
				str(technology_id),
				" adoption: ",
				adoption_value
			])


			adoption_factor += adoption_value
			adoption_count += 1


	if adoption_count > 0:

		adoption_factor = (
			adoption_factor
			/ float(adoption_count)
		)


	var research_military_target = (
		research_maturity
		* (
			0.50
			+ adoption_factor * 0.50
		)
	)


	research_military_target = clamp(
		research_military_target,
		0.0,
		1.0
	)


	# ------------------------------------------------------------
	# Add explicit military technology support from the
	# TechnologyEffectSystem.
	# ------------------------------------------------------------

	var technology_adjusted_research_target = clamp(
		research_military_target
		+ normalized_military_technology_effect * 0.25,
		0.0,
		1.0
	)


	_out([
		"Research maturity: ",
		research_maturity
	])

	_out([
		"Technology adoption factor: ",
		adoption_factor
	])

	_out([
		"Completed technology count: ",
		adoption_count
	])

	_out([
		"Research-derived military technology target: ",
		research_military_target
	])

	_out([
		"Technology-adjusted military technology target: ",
		technology_adjusted_research_target
	])


	var expected_military_technology = lerp(
		initial_military_technology,
		technology_adjusted_research_target,
		0.05
	)


	_out([
		"Military technology before: ",
		initial_military_technology
	])

	_out([
		"Expected military technology after: ",
		expected_military_technology
	])

	_out([
		"Actual military technology after: ",
		military_technology_after
	])


	var military_technology_error = abs(
		military_technology_after
		- expected_military_technology
	)


	if military_technology_error <= 0.000001:

		_out([
			"Research -> military technology formula: PASS"
		])

	else:

		_out([
			"Research -> military technology formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_military_technology
		])

		_out([
			"Actual: ",
			military_technology_after
		])

		_out([
			"Error: ",
			military_technology_error
		])

		passed = false


	if (
		military_technology_after >= 0.0
		and military_technology_after <= 1.0
	):

		_out([
			"Military technology range: PASS"
		])

	else:

		_out([
			"Military technology range: FAIL"
		])

		passed = false


	if (
		military_technology_after
		!= initial_military_technology
	):

		_out([
			"Research -> military technology causal response: PASS"
		])

	else:

		_out([
			"Research -> military technology causal response: FAIL"
		])

		passed = false


	# ============================================================
	# 26. VERIFY RESOURCES → LOGISTICS AFTER TECHNOLOGY
	# ============================================================

	var expected_final_logistics = lerp(
		expected_technology_logistics,
		expected_resource_security,
		0.05
	)


	var final_logistics_error = abs(
		logistics_after
		- expected_final_logistics
	)


	_out([""])
	_out([
		"Economy logistics intermediate value: ",
		expected_economy_logistics
	])

	_out([
		"Technology logistics intermediate value: ",
		expected_technology_logistics
	])

	_out([
		"Expected final logistics: ",
		expected_final_logistics
	])

	_out([
		"Actual final logistics: ",
		logistics_after
	])


	if final_logistics_error <= 0.000001:

		_out([
			"Resources -> logistics formula: PASS"
		])

	else:

		_out([
			"Resources -> logistics formula: FAIL"
		])

		_out([
			"Expected: ",
			expected_final_logistics
		])

		_out([
			"Actual: ",
			logistics_after
		])

		_out([
			"Error: ",
			final_logistics_error
		])

		passed = false


	# ============================================================
	# 27. VERIFY RESOURCE-SECURITY CAUSAL RESPONSE
	# ============================================================

	var resource_effect_distance = abs(
		logistics_after
		- expected_technology_logistics
	)

	if resource_effect_distance > 0.0:

		_out([
			"Resources -> logistics causal response: PASS"
		])

	else:

		_out([
			"Resources -> logistics causal response: FAIL"
		])

		passed = false


	# ============================================================
	# 28. OVERALL RESOURCE → MILITARY VERIFICATION
	# ============================================================

	var resources_military_valid: bool = (
		resource_security_error <= 0.000001
		and final_logistics_error <= 0.000001
		and resource_effect_distance > 0.0
	)


	if resources_military_valid:

		_out([
			"Resources -> military causal response: PASS"
		])

	else:

		_out([
			"Resources -> military causal response: FAIL"
		])

		passed = false


	# ============================================================
	# 29. VERIFY DOWNSTREAM MILITARY CALCULATIONS
	# ============================================================

	var readiness = float(
		india_military.get_state(
			"readiness",
			-1.0
		)
	)

	var military_power = float(
		india_military.get_state(
			"military_power",
			-1.0
		)
	)

	var defensive_capability = float(
		india_military.get_state(
			"defensive_capability",
			-1.0
		)
	)

	var power_projection = float(
		india_military.get_state(
			"power_projection",
			-1.0
		)
	)

	var mobilization_capacity = float(
		india_military.get_state(
			"mobilization_capacity",
			-1.0
		)
	)

	var military_pressure = float(
		india_military.get_state(
			"military_pressure",
			-1.0
		)
	)


	var derived_values = [
		readiness,
		military_power,
		defensive_capability,
		power_projection,
		mobilization_capacity,
		military_pressure
	]


	var derived_state_valid: bool = true


	for value in derived_values:

		if value < 0.0 or value > 1.0:

			derived_state_valid = false
			break


	if derived_state_valid:

		_out([
			"Military derived state: PASS"
		])

	else:

		_out([
			"Military derived state: FAIL"
		])

		passed = false


	# ============================================================
	# 30. VERIFY PREVIOUS-STATE TRACKING
	# ============================================================

	var previous_power = float(
		india_military.get_state(
			"previous_military_power",
			-1.0
		)
	)

	var previous_readiness = float(
		india_military.get_state(
			"previous_readiness",
			-1.0
		)
	)

	var previous_resource_security = float(
		india_military.get_state(
			"previous_resource_security",
			-1.0
		)
	)


	if (
		previous_power < 0.0
		or previous_power > 1.0
	):

		_out([
			"Military previous power tracking: FAIL"
		])

		passed = false

	else:

		_out([
			"Military previous power tracking: PASS"
		])


	if (
		previous_readiness < 0.0
		or previous_readiness > 1.0
	):

		_out([
			"Military previous readiness tracking: FAIL"
		])

		passed = false

	else:

		_out([
			"Military previous readiness tracking: PASS"
		])


	if (
		previous_resource_security < 0.0
		or previous_resource_security > 1.0
	):

		_out([
			"Military previous resource security tracking: FAIL"
		])

		passed = false

	else:

		_out([
			"Military previous resource security tracking: PASS"
		])


	# ============================================================
	# FINAL RESULT
	# ============================================================

	_out([""])

	if passed:

		_out([
			"MILITARY SYSTEM TEST PASSED"
		])

	else:

		_out([
			"MILITARY SYSTEM TEST FAILED"
		])

	_out(["================================"])
