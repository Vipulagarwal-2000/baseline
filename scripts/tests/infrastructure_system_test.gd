class_name InfrastructureSystemTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	if world == null:
		return false

	var infrastructure_system = InfrastructureSystem.new()
	infrastructure_system.process_month(world)

	var india = world.get_entity("india")
	var china = world.get_entity("china")
	var usa = world.get_entity("usa")

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


	if india != null:

		passed = _check(
			india.get_component("infrastructure") != null,
			"India InfrastructureComponent"
		) and passed

		var infrastructure = india.get_component(
			"infrastructure"
		)

		var resources = india.get_component(
			"resources"
		)

		passed = _check(
			resources != null,
			"India ResourceComponent"
		) and passed

		if infrastructure != null:

			passed = _check(
				infrastructure.get_state(
					"transport",
					-1.0
				) >= 0.0,
				"India transport value"
			) and passed

			passed = _check(
				infrastructure.get_state(
					"total_capacity",
					-1.0
				) >= 0.0,
				"India total capacity"
			) and passed

			passed = _check(
				infrastructure.get_state(
					"storage",
					-1.0
				) >= 0.0,
				"India storage value"
			) and passed

		if resources != null and infrastructure != null:

			var resource_storage_capacity = resources.get_state(
				"storage_capacity",
				{}
			)

			var expected_storage = clamp(
				float(
					infrastructure.get_state(
						"storage",
						0.0
					)
				),
				0.0,
				1.0
			)

			passed = _check(
				typeof(resource_storage_capacity) == TYPE_DICTIONARY,
				"India storage capacity dictionary"
			) and passed

			if typeof(resource_storage_capacity) == TYPE_DICTIONARY:

				var coal_storage_capacity = float(
					resource_storage_capacity.get(
						"coal",
						-1.0
					)
				)

				passed = _check(
					is_equal_approx(
						coal_storage_capacity,
						expected_storage
					),
					"India coal storage capacity synced"
				) and passed


	if china != null:

		passed = _check(
			china.get_component("infrastructure") != null,
			"China InfrastructureComponent"
		) and passed

		var infrastructure = china.get_component(
			"infrastructure"
		)

		if infrastructure != null:

			passed = _check(
				infrastructure.get_state(
					"total_capacity",
					-1.0
				) >= 0.0,
				"China total capacity"
			) and passed


	if usa != null:

		passed = _check(
			usa.get_component("infrastructure") != null,
			"USA InfrastructureComponent"
		) and passed

		var infrastructure = usa.get_component(
			"infrastructure"
		)

		if infrastructure != null:

			passed = _check(
				infrastructure.get_state(
					"total_capacity",
					-1.0
				) >= 0.0,
				"USA total capacity"
			) and passed



	# ============================================================
	# INFRASTRUCTURE BOTTLENECK MAPPING
	# ============================================================

	var bottleneck_system = null

	if simulation != null:
		bottleneck_system = simulation.get_system(
			"infrastructure_bottleneck_system"
		)

	passed = _check(
		bottleneck_system != null,
		"Infrastructure Bottleneck System registered"
	) and passed

	if bottleneck_system == null:
		return passed

	if not bottleneck_system is InfrastructureBottleneckSystem:
		passed = _check(
			false,
			"Infrastructure Bottleneck System type"
		) and passed
		return passed

	if india != null:

		var bottleneck_infrastructure = india.get_component(
			"infrastructure"
		)

		if bottleneck_infrastructure != null:

			var original_bottleneck_state: Dictionary = {}

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				original_bottleneck_state[component_name] = (
					bottleneck_infrastructure.get_state(
						component_name,
						0.0
					)
				)

			var original_mapping = bottleneck_infrastructure.get_state(
				"bottleneck_mapping",
				null
			)

			# --------------------------------------------------------
			# Baseline: all infrastructure at full capacity.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					1.0
				)

			var baseline_mapping = bottleneck_system.get_bottleneck(
				bottleneck_infrastructure
			)

			passed = _check(
				baseline_mapping.get("component", "") == "transport",
				"Bottleneck baseline deterministic component"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						baseline_mapping.get(
							"factor",
							-1.0
						)
					),
					1.0
				),
				"Bottleneck baseline factor = 1.0"
			) and passed

			# --------------------------------------------------------
			# Industrial bottleneck.
			# --------------------------------------------------------

			bottleneck_infrastructure.set_state(
				"industrial",
				0.60
			)

			var industrial_mapping = bottleneck_system.get_bottleneck(
				bottleneck_infrastructure
			)

			passed = _check(
				industrial_mapping.get("component", "") == "industrial",
				"Industrial bottleneck identified"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						industrial_mapping.get(
							"factor",
							-1.0
						)
					),
					0.60
				),
				"Industrial bottleneck factor = 0.60"
			) and passed

			# --------------------------------------------------------
			# Power bottleneck.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					1.0
				)

			bottleneck_infrastructure.set_state(
				"power",
				0.50
			)

			var power_mapping = bottleneck_system.get_bottleneck(
				bottleneck_infrastructure
			)

			passed = _check(
				power_mapping.get("component", "") == "power",
				"Power bottleneck identified"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						power_mapping.get(
							"factor",
							-1.0
						)
					),
					0.50
				),
				"Power bottleneck factor = 0.50"
			) and passed

			# --------------------------------------------------------
			# Railways bottleneck.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					1.0
				)

			bottleneck_infrastructure.set_state(
				"railways",
				0.40
			)

			var railways_mapping = bottleneck_system.get_bottleneck(
				bottleneck_infrastructure
			)

			passed = _check(
				railways_mapping.get("component", "") == "railways",
				"Railways bottleneck identified"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						railways_mapping.get(
							"factor",
							-1.0
						)
					),
					0.40
				),
				"Railways bottleneck factor = 0.40"
			) and passed

			# --------------------------------------------------------
			# Deterministic tie handling.
			# COMPONENT_ORDER puts power before industrial.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					1.0
				)

			bottleneck_infrastructure.set_state(
				"power",
				0.30
			)
			bottleneck_infrastructure.set_state(
				"industrial",
				0.30
			)

			var tie_mapping = bottleneck_system.get_bottleneck(
				bottleneck_infrastructure
			)

			passed = _check(
				tie_mapping.get("component", "") == "power",
				"Equal bottleneck values use deterministic order"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						tie_mapping.get(
							"factor",
							-1.0
						)
					),
					0.30
				),
				"Equal bottleneck factor = 0.30"
			) and passed

			# --------------------------------------------------------
			# Mapping preserves all component values.
			# --------------------------------------------------------

			var mapped_components = tie_mapping.get(
				"components",
				{}
			)

			passed = _check(
				typeof(mapped_components) == TYPE_DICTIONARY,
				"Bottleneck component map is a dictionary"
			) and passed

			if typeof(mapped_components) == TYPE_DICTIONARY:
				passed = _check(
					is_equal_approx(
						float(
							mapped_components.get(
								"power",
								-1.0
							)
						),
						0.30
					),
					"Power value preserved in bottleneck map"
				) and passed

				passed = _check(
					is_equal_approx(
						float(
							mapped_components.get(
								"industrial",
								-1.0
							)
						),
						0.30
					),
					"Industrial value preserved in bottleneck map"
				) and passed

			# --------------------------------------------------------
			# process_month writes the derived mapping into the component.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					1.0
				)

			bottleneck_infrastructure.set_state(
				"industrial",
				0.55
			)

			bottleneck_system.process_month(world)

			var stored_mapping: Dictionary = bottleneck_infrastructure.get_state(
				"bottleneck_mapping",
				{}
			)

			passed = _check(
				stored_mapping.get("component", "") == "industrial",
				"Process month stores industrial bottleneck"
			) and passed

			passed = _check(
				is_equal_approx(
					float(
						stored_mapping.get(
							"factor",
							-1.0
						)
					),
					0.55
				),
				"Process month stores bottleneck factor"
			) and passed

			# ========================================================
			# PROCESS-SPECIFIC BOTTLENECK MAPPING
			# ========================================================

			var production_process_system = null
			if simulation != null:
				production_process_system = simulation.get_system(
					"production_process_system"
				)

			passed = _check(
				production_process_system != null,
				"Production Process System registered for process bottleneck mapping"
			) and passed

			if production_process_system != null:

				var original_steel_definition: Dictionary = (
					production_process_system.catalog.get_process(
						"steel_basic"
					)
				)

				var process_resources = india.get_component(
					"resources"
				)

				var process_infrastructure = india.get_component(
					"infrastructure"
				)

				if process_resources != null and process_infrastructure != null:

					var original_process_infrastructure_capacity: Dictionary = (
						process_resources.get_state(
							"infrastructure_capacity",
							{}
						)
					)

					var process_catalog_definition: Dictionary = (
						original_steel_definition.duplicate(true)
					)

					process_catalog_definition["infrastructure_usage"] = {
						"power": 1.0,
						"steel_mill": 1.0
					}

					process_catalog_definition["industrial_infrastructure_usage"] = {
						"industrial": 1.0
					}

					production_process_system.catalog.processes[
						"steel_basic"
					] = process_catalog_definition

					var process_infrastructure_capacity: Dictionary = (
						original_process_infrastructure_capacity.duplicate(true)
					)

					process_infrastructure_capacity["power"] = 0.80
					process_infrastructure_capacity["steel_mill"] = 0.90

					process_resources.set_state(
						"infrastructure_capacity",
						process_infrastructure_capacity
					)

					for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
						process_infrastructure.set_state(
							component_name,
							1.0
						)

					process_infrastructure.set_state(
						"industrial",
						0.60
					)

					var industrial_process_mapping: Dictionary = (
						bottleneck_system.get_process_bottleneck(
						india,
						"steel_basic"
						)
					)

					passed = _check(
						industrial_process_mapping.get("process_id", "") == "steel_basic",
						"Process bottleneck identifies steel_basic"
					) and passed

					passed = _check(
						industrial_process_mapping.get("component", "") == "industrial",
						"Process-specific industrial bottleneck identified"
					) and passed

					passed = _check(
						is_equal_approx(
							float(
								industrial_process_mapping.get(
									"factor",
									-1.0
								)
							),
							0.60
						),
						"Process-specific industrial bottleneck factor = 0.60"
					) and passed

					# Power becomes the tighter valid requirement.
					process_infrastructure.set_state(
						"industrial",
						0.80
					)

					process_infrastructure.set_state(
						"power",
						0.50
					)

					var power_process_mapping: Dictionary = (
						bottleneck_system.get_process_bottleneck(
						india,
						"steel_basic"
						)
					)

					passed = _check(
						power_process_mapping.get("component", "") == "power",
						"Process-specific power bottleneck identified"
					) and passed

					passed = _check(
						is_equal_approx(
							float(
								power_process_mapping.get(
									"factor",
									-1.0
								)
							),
							0.50
						),
						"Process-specific power bottleneck factor = 0.50"
					) and passed

					# Equal valid minima must remain deterministic. COMPONENT_ORDER
					# puts power before industrial.
					process_infrastructure.set_state(
						"industrial",
						0.50
					)

					var process_tie_mapping: Dictionary = (
						bottleneck_system.get_process_bottleneck(
						india,
						"steel_basic"
						)
					)

					passed = _check(
						process_tie_mapping.get("component", "") == "power",
						"Process bottleneck equal minima use deterministic order"
					) and passed

					var process_requirements: Dictionary = process_tie_mapping.get(
						"requirements",
						{}
					)

					passed = _check(
						typeof(process_requirements) == TYPE_DICTIONARY,
						"Process bottleneck requirements map is a dictionary"
					) and passed

					if typeof(process_requirements) == TYPE_DICTIONARY:

						var industrial_requirement: Dictionary = process_requirements.get(
							"industrial",
							{}
						)

						var power_requirement: Dictionary = process_requirements.get(
							"power",
							{}
						)

						var steel_mill_requirement: Dictionary = process_requirements.get(
							"steel_mill",
							{}
						)

						passed = _check(
							is_equal_approx(
							float(industrial_requirement.get("factor", -1.0)),
							0.50
						),
						"Industrial process requirement factor = 0.50"
						) and passed

						passed = _check(
							is_equal_approx(
							float(power_requirement.get("factor", -1.0)),
							0.50
						),
						"Power process requirement factor = 0.50"
						) and passed

						passed = _check(
							is_equal_approx(
							float(steel_mill_requirement.get("factor", -1.0)),
							0.90
						),
						"Generic steel_mill requirement factor = 0.90"
						) and passed

					production_process_system.catalog.processes[
						"steel_basic"
					] = original_steel_definition

					process_resources.set_state(
						"infrastructure_capacity",
						original_process_infrastructure_capacity
					)

					for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
						process_infrastructure.set_state(
							component_name,
							original_bottleneck_state.get(
								component_name,
								0.0
							)
						)

			# --------------------------------------------------------
			# Restore exact original state.
			# --------------------------------------------------------

			for component_name in InfrastructureBottleneckSystem.COMPONENT_ORDER:
				bottleneck_infrastructure.set_state(
					component_name,
					original_bottleneck_state.get(
						component_name,
						0.0
					)
				)

			if original_mapping == null:
				bottleneck_infrastructure.set_state(
					"bottleneck_mapping",
					{}
				)
			else:
				bottleneck_infrastructure.set_state(
					"bottleneck_mapping",
					original_mapping
				)


	return passed


static func _check(

	condition: bool,
	label: String
) -> bool:

	if condition:

		print(
			"Infrastructure System "
			+ label
			+ ": PASS"
		)

		return true

	push_error(
		"Infrastructure System "
		+ label
		+ ": FAIL"
	)

	return false
