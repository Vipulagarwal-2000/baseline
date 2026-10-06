class_name IndustryLoaderTest
extends RefCounted


static func run(
	world: WorldState
) -> bool:

	var passed := true

	var india = world.get_entity("india")
	var china = world.get_entity("china")
	var usa = world.get_entity("usa")


	# ============================================================
	# COUNTRY LOADING
	# ============================================================

	passed = _check(
		india != null,
		"India loaded"
	) and passed

	passed = _check(
		china != null,
		"China loaded"
	) and passed

	passed = _check(
		usa != null,
		"USA loaded"
	) and passed


	# ============================================================
	# INDUSTRY COMPONENT
	# ============================================================

	if india != null:

		passed = _check(
			india.get_component("industry") != null,
			"India IndustryComponent"
		) and passed

		var india_industry = india.get_component(
			"industry"
		)

		if india_industry != null:

			var processes = india_industry.get_state(
				"processes",
				{}
			)

			passed = _check(
				processes.has("steel_basic"),
				"India steel process"
			) and passed


	if china != null:

		passed = _check(
			china.get_component("industry") != null,
			"China IndustryComponent"
		) and passed


	if usa != null:

		passed = _check(
			usa.get_component("industry") != null,
			"USA IndustryComponent"
		) and passed


	# ============================================================
	# INFRASTRUCTURE COMPONENT
	# ============================================================

	if india != null:

		passed = _check(
			india.get_component("infrastructure") != null,
			"India InfrastructureComponent"
		) and passed

		var india_infrastructure = india.get_component(
			"infrastructure"
		)

		if india_infrastructure != null:

			passed = _check(
				india_infrastructure.get_state("transport", null) != null,
				"India infrastructure transport"
			) and passed

			passed = _check(
				india_infrastructure.get_state("total_capacity", null) != null,
				"India infrastructure total capacity"
			) and passed


	if china != null:

		passed = _check(
			china.get_component("infrastructure") != null,
			"China InfrastructureComponent"
		) and passed

		var china_infrastructure = china.get_component(
			"infrastructure"
		)

		if china_infrastructure != null:

			passed = _check(
				china_infrastructure.get_state("transport", null) != null,
				"China infrastructure transport"
			) and passed

			passed = _check(
				china_infrastructure.get_state("total_capacity", null) != null,
				"China infrastructure total capacity"
			) and passed


	if usa != null:

		passed = _check(
			usa.get_component("infrastructure") != null,
			"USA InfrastructureComponent"
		) and passed

		var usa_infrastructure = usa.get_component(
			"infrastructure"
		)

		if usa_infrastructure != null:

			passed = _check(
				usa_infrastructure.get_state("transport", null) != null,
				"USA infrastructure transport"
			) and passed

			passed = _check(
				usa_infrastructure.get_state("total_capacity", null) != null,
				"USA infrastructure total capacity"
			) and passed


	return passed


static func _check(
	condition: bool,
	label: String
) -> bool:

	if condition:

		print(
			"Industry Loader "
			+ label
			+ ": PASS"
		)

		return true


	push_error(
		"Industry Loader "
		+ label
		+ ": FAIL"
	)

	return false
