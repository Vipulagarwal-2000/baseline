class_name IndustryProcessInfrastructurePressureTest
extends RefCounted


static func _log(message: String) -> void:
	TestLogger.write_line(message)


static func _pass_fail(value: bool) -> String:
	return "PASS" if value else "FAIL"


static func run(
	world = null,
	_simulation = null
) -> bool:

	var all_passed: bool = true

	TestLogger.section(
		"INDUSTRY PROCESS INFRASTRUCTURE / CAPABILITY PRESSURE TEST"
	)


	# ============================================================
	# BASE PROCESS DEFINITION
	# ============================================================

	var process: Dictionary = {
		"infrastructure_usage": {
			"modern_steelworks": 1.0,
			"power": 0.5
		},
		"capability_requirements": {
			"advanced_metallurgy": 0.5
		}
	}

	var adoption: float = 0.60


	# ============================================================
	# STEP 10A REGRESSION — ADOPTION-SCALED INFRASTRUCTURE
	# ============================================================

	var infrastructure_pressure: Dictionary = (
		IndustryComponent.calculate_process_infrastructure_pressure(
			process,
			adoption
		)
	)

	var infrastructure_test: bool = (
		is_equal_approx(
			float(
				infrastructure_pressure.get(
					"modern_steelworks",
					-1.0
				)
			),
			0.60
		)
		and
		is_equal_approx(
			float(
				infrastructure_pressure.get(
					"power",
					-1.0
				)
			),
			0.30
		)
	)

	_log(
		"Adoption-scaled infrastructure pressure: "
		+ _pass_fail(infrastructure_test)
		+ " | modern_steelworks expected=0.60 actual="
		+ str(infrastructure_pressure.get("modern_steelworks", -1.0))
		+ " | power expected=0.30 actual="
		+ str(infrastructure_pressure.get("power", -1.0))
	)

	all_passed = all_passed and infrastructure_test


	# ============================================================
	# STEP 10A REGRESSION — ADOPTION-SCALED CAPABILITY
	# ============================================================

	var capability_pressure: Dictionary = (
		IndustryComponent.calculate_process_capability_pressure(
			process,
			adoption
		)
	)

	var capability_test: bool = is_equal_approx(
		float(
			capability_pressure.get(
				"advanced_metallurgy",
				-1.0
			)
		),
		0.30
	)

	_log(
		"Adoption-scaled capability pressure: "
		+ _pass_fail(capability_test)
		+ " | expected=0.30 actual="
		+ str(capability_pressure.get("advanced_metallurgy", -1.0))
	)

	all_passed = all_passed and capability_test


	# ============================================================
	# STEP 10A REGRESSION — REQUIREMENT GAP
	# ============================================================

	var infrastructure_gap: float = (
		IndustryComponent.calculate_requirement_gap(
			0.30,
			0.20
		)
	)

	var infrastructure_gap_test: bool = is_equal_approx(
		infrastructure_gap,
		0.10
	)

	_log(
		"Infrastructure requirement gap: "
		+ _pass_fail(infrastructure_gap_test)
		+ " | expected=0.10 actual="
		+ str(infrastructure_gap)
	)

	all_passed = all_passed and infrastructure_gap_test


	# ============================================================
	# STEP 10A REGRESSION — SUFFICIENT AVAILABILITY
	# ============================================================

	var sufficient_gap: float = (
		IndustryComponent.calculate_requirement_gap(
			0.30,
			0.50
		)
	)

	var sufficient_gap_test: bool = is_zero_approx(
		sufficient_gap
	)

	_log(
		"Sufficient availability produces zero gap: "
		+ _pass_fail(sufficient_gap_test)
		+ " | expected=0.00 actual="
		+ str(sufficient_gap)
	)

	all_passed = all_passed and sufficient_gap_test


	# ============================================================
	# STEP 10A REGRESSION — ZERO ADOPTION
	# ============================================================

	var zero_adoption_infrastructure: Dictionary = (
		IndustryComponent.calculate_process_infrastructure_pressure(
			process,
			0.0
		)
	)

	var zero_adoption_capability: Dictionary = (
		IndustryComponent.calculate_process_capability_pressure(
			process,
			0.0
		)
	)

	var zero_adoption_test: bool = (
		is_zero_approx(
			float(
				zero_adoption_infrastructure.get(
					"modern_steelworks",
					-1.0
				)
			)
		)
		and
		is_zero_approx(
			float(
				zero_adoption_infrastructure.get(
					"power",
					-1.0
				)
			)
		)
		and
		is_zero_approx(
			float(
				zero_adoption_capability.get(
					"advanced_metallurgy",
					-1.0
				)
			)
		)
	)

	_log(
		"Zero adoption creates zero pressure: "
		+ _pass_fail(zero_adoption_test)
	)

	all_passed = all_passed and zero_adoption_test


	# ============================================================
	# STEP 10A REGRESSION — FULL ADOPTION
	# ============================================================

	var full_adoption_infrastructure: Dictionary = (
		IndustryComponent.calculate_process_infrastructure_pressure(
			process,
			1.0
		)
	)

	var full_adoption_capability: Dictionary = (
		IndustryComponent.calculate_process_capability_pressure(
			process,
			1.0
		)
	)

	var full_adoption_test: bool = (
		is_equal_approx(
			float(
				full_adoption_infrastructure.get(
					"modern_steelworks",
					-1.0
				)
			),
			1.0
		)
		and
		is_equal_approx(
			float(
				full_adoption_infrastructure.get(
					"power",
					-1.0
				)
			),
			0.5
		)
		and
		is_equal_approx(
			float(
				full_adoption_capability.get(
					"advanced_metallurgy",
					-1.0
				)
			),
			0.5
		)
	)

	_log(
		"Full adoption preserves full pressure: "
		+ _pass_fail(full_adoption_test)
	)

	all_passed = all_passed and full_adoption_test


	# ============================================================
	# STEP 10A REGRESSION — MISSING INFRASTRUCTURE USAGE
	# ============================================================

	var no_infrastructure_process: Dictionary = {
		"capability_requirements": {
			"test_capability": 0.5
		}
	}

	var no_infrastructure_pressure: Dictionary = (
		IndustryComponent.calculate_process_infrastructure_pressure(
			no_infrastructure_process,
			1.0
		)
	)

	var no_infrastructure_test: bool = (
		no_infrastructure_pressure.is_empty()
	)

	_log(
		"Missing infrastructure usage is safe: "
		+ _pass_fail(no_infrastructure_test)
	)

	all_passed = all_passed and no_infrastructure_test


	# ============================================================
	# STEP 10A REGRESSION — MISSING CAPABILITY REQUIREMENTS
	# ============================================================

	var no_capability_process: Dictionary = {
		"infrastructure_usage": {
			"modern_steelworks": 1.0
		}
	}

	var no_capability_pressure: Dictionary = (
		IndustryComponent.calculate_process_capability_pressure(
			no_capability_process,
			1.0
		)
	)

	var no_capability_test: bool = no_capability_pressure.is_empty()

	_log(
		"Missing capability requirements are safe: "
		+ _pass_fail(no_capability_test)
	)

	all_passed = all_passed and no_capability_test


	# ============================================================
	# STEP 10A REGRESSION — PROCESS DEFINITION IS NOT MUTATED
	# ============================================================

	var original_usage: float = float(
		process["infrastructure_usage"]["modern_steelworks"]
	)

	var original_capability: float = float(
		process["capability_requirements"]["advanced_metallurgy"]
	)

	IndustryComponent.calculate_process_infrastructure_pressure(
		process,
		0.25
	)

	IndustryComponent.calculate_process_capability_pressure(
		process,
		0.25
	)

	var definition_unchanged_test: bool = (
		is_equal_approx(
			float(
				process["infrastructure_usage"]["modern_steelworks"]
			),
			original_usage
		)
		and
		is_equal_approx(
			float(
				process["capability_requirements"]["advanced_metallurgy"]
			),
			original_capability
		)
	)

	_log(
		"Process definition remains unchanged: "
		+ _pass_fail(definition_unchanged_test)
	)

	all_passed = all_passed and definition_unchanged_test


	# ============================================================
	# STEP 10B — ENTITY LIVE AVAILABILITY INTEGRATION
	# ============================================================

	var live_integration_test: bool = false
	var live_sufficient_test: bool = false
	var live_dynamic_test: bool = false
	var entity_state_resolver_test: bool = false

	var india: SimEntity = null
	if world != null and typeof(world.entities) == TYPE_DICTIONARY:
		india = world.entities.get("india")

	if india == null:
		_log(
			"Live entity availability integration: FAIL"
			+ " | India entity not available"
		)
		all_passed = false
	else:
		var infrastructure: SimComponent = india.get_component(
			"infrastructure"
		) as SimComponent

		var industry: IndustryComponent = india.get_component(
			"industry"
		) as IndustryComponent

		if infrastructure == null or industry == null:
			_log(
				"Live entity availability integration: FAIL"
				+ " | required components missing"
			)
			all_passed = false
		else:
			var original_infrastructure_state: Dictionary = (
				infrastructure.state.duplicate(true)
			)

			var original_capabilities_value: Variant = (
				india.get_sim_metadata(
					"capabilities",
					null
				)
			)
			var original_capabilities: Dictionary = {}
			if typeof(original_capabilities_value) == TYPE_DICTIONARY:
				original_capabilities = original_capabilities_value.duplicate(true)

			# Inject deterministic temporary live state, then restore it
			# before the next registered test runs.
			infrastructure.set_state(
				"modern_steelworks",
				0.20
			)

			infrastructure.set_state(
				"power",
				0.40
			)

			var temporary_capabilities: Dictionary = original_capabilities.duplicate(true)
			temporary_capabilities[
				"advanced_metallurgy"
			] = 0.25

			india.set_sim_metadata(
				"capabilities",
				temporary_capabilities
			)

			var live_pressure: Dictionary = (
				IndustryComponent.calculate_entity_process_requirement_pressure(
					india,
					process,
					adoption
				)
			)

			var live_infrastructure = live_pressure.get(
				"infrastructure",
				{}
			)

			var live_capability = live_pressure.get(
				"capability",
				{}
			)

			live_integration_test = (
				is_equal_approx(
					float(
						live_infrastructure.get(
							"modern_steelworks",
							{}
						).get("required", -1.0)
					),
					0.60
				)
				and
				is_equal_approx(
					float(
						live_infrastructure.get(
							"modern_steelworks",
							{}
						).get("available", -1.0)
					),
					0.20
				)
				and
				is_equal_approx(
					float(
						live_infrastructure.get(
							"modern_steelworks",
							{}
						).get("gap", -1.0)
					),
					0.40
				)
				and
				is_equal_approx(
					float(
						live_infrastructure.get(
							"power",
							{}
						).get("gap", -1.0)
					),
					0.0
				)
				and
				is_equal_approx(
					float(
						live_capability.get(
							"advanced_metallurgy",
							{}
						).get("required", -1.0)
					),
					0.30
				)
				and
				is_equal_approx(
					float(
						live_capability.get(
							"advanced_metallurgy",
							{}
						).get("available", -1.0)
					),
					0.25
				)
				and
				is_equal_approx(
					float(
						live_capability.get(
							"advanced_metallurgy",
							{}
						).get("gap", -1.0)
					),
					0.05
				)
			)

			_log(
				"Live entity availability produces actual infrastructure/capability gaps: "
				+ _pass_fail(live_integration_test)
				+ " | modern_steelworks gap expected=0.40 actual="
				+ str(
					live_infrastructure.get(
						"modern_steelworks",
						{}
					).get("gap", -1.0)
				)
				+ " | advanced_metallurgy gap expected=0.05 actual="
				+ str(
					live_capability.get(
						"advanced_metallurgy",
						{}
					).get("gap", -1.0)
				)
			)

			all_passed = all_passed and live_integration_test


			# Increase live availability above the adoption-scaled
			# requirements. The gap should then collapse to zero.
			infrastructure.set_state(
				"modern_steelworks",
				0.80
			)

			temporary_capabilities[
				"advanced_metallurgy"
			] = 0.50

			india.set_sim_metadata(
				"capabilities",
				temporary_capabilities
			)

			var sufficient_pressure: Dictionary = (
				IndustryComponent.calculate_entity_process_requirement_pressure(
					india,
					process,
					adoption
				)
			)

			live_sufficient_test = (
				is_zero_approx(
					float(
						sufficient_pressure[
							"infrastructure"
						][
							"modern_steelworks"
						][
							"gap"
						]
					)
				)
				and
				is_zero_approx(
					float(
						sufficient_pressure[
							"capability"
						][
							"advanced_metallurgy"
						][
							"gap"
						]
					)
				)
			)

			_log(
				"Sufficient live availability removes requirement gaps: "
				+ _pass_fail(live_sufficient_test)
			)

			all_passed = all_passed and live_sufficient_test


			# Reduce one availability value below the requirement while
			# leaving the other above it. The result must change with state.
			infrastructure.set_state(
				"modern_steelworks",
				0.10
			)

			var dynamic_pressure: Dictionary = (
				IndustryComponent.calculate_entity_process_requirement_pressure(
					india,
					process,
					adoption
				)
			)

			live_dynamic_test = is_equal_approx(
				float(
					dynamic_pressure[
						"infrastructure"
					][
						"modern_steelworks"
					][
						"gap"
					]
				),
				0.50
			)

			_log(
				"Live pressure changes with infrastructure state: "
				+ _pass_fail(live_dynamic_test)
				+ " | expected=0.50 actual="
				+ str(
					dynamic_pressure[
						"infrastructure"
					][
						"modern_steelworks"
					][
						"gap"
					]
				)
			)

			all_passed = all_passed and live_dynamic_test


			# The convenience resolver must use the industry's live
			# adoption state rather than requiring a second adoption source.
			var original_processes: Dictionary = (
				industry.get_state(
					"processes",
					{}
				).duplicate(true)
			)

			var original_adoption: Dictionary = (
				industry.get_state(
					"process_adoption",
					{}
				).duplicate(true)
			)

			var temporary_processes: Dictionary = original_processes.duplicate(true)
			temporary_processes[
				"step10b_test_process"
			] = process.duplicate(true)

			var temporary_adoption: Dictionary = original_adoption.duplicate(true)
			temporary_adoption[
				"step10b_test_process"
			] = adoption

			industry.set_state(
				"processes",
				temporary_processes
			)

			industry.set_state(
				"process_adoption",
				temporary_adoption
			)

			var state_pressure: Dictionary = (
				IndustryComponent.calculate_entity_process_requirement_pressure_from_state(
					india,
					"step10b_test_process"
				)
			)

			entity_state_resolver_test = (
				not state_pressure.is_empty()
				and
				is_equal_approx(
					float(
						state_pressure[
							"adoption"
						]
					),
					adoption
				)
				and
				is_equal_approx(
					float(
						state_pressure[
							"infrastructure"
						][
							"modern_steelworks"
						][
							"gap"
						]
					),
					0.50
				)
			)

			_log(
				"Entity/state resolver uses live industry adoption: "
				+ _pass_fail(entity_state_resolver_test)
			)

			all_passed = all_passed and entity_state_resolver_test


			# ============================================================
			# STEP 10C — LIVE OPERATIONAL CONSEQUENCE RESOLUTION
			# ============================================================

			var live_consequence_process: Dictionary = {
				"capacity": 100.0,
				"infrastructure_usage": {
					"modern_steelworks": 1.0,
					"power": 0.5
				},
				"infrastructure_requirements": {
					"modern_steelworks": 0.2
				},
				"capability_requirements": {
					"advanced_metallurgy": 0.3
				}
			}

			temporary_processes[
				"step10c_test_process"
			] = live_consequence_process.duplicate(true)

			temporary_adoption[
				"step10c_test_process"
			] = adoption

			industry.set_state(
				"processes",
				temporary_processes
			)

			industry.set_state(
				"process_adoption",
				temporary_adoption
			)

			infrastructure.set_state(
				"modern_steelworks",
				0.80
			)

			infrastructure.set_state(
				"power",
				0.50
			)

			temporary_capabilities[
				"advanced_metallurgy"
			] = 0.30

			india.set_sim_metadata(
				"capabilities",
				temporary_capabilities
			)

			var live_consequence: Dictionary = (
				IndustryComponent.calculate_entity_process_operational_consequence_from_state(
					india,
					"step10c_test_process"
				)
			)

			var live_consequence_test: bool = (
				not live_consequence.is_empty()
				and
				is_equal_approx(
					float(
						live_consequence["operational_factor"]
					),
					0.80
				)
				and
				is_equal_approx(
					float(
						live_consequence["effective_capacity"]
					),
					48.0
				)
			)

			_log(
				"Live entity operational consequence: "
				+ _pass_fail(live_consequence_test)
				+ " | expected_factor=0.80 actual="
				+ str(
					live_consequence.get(
						"operational_factor",
						-1.0
					)
				)
				+ " | expected_capacity=48.0 actual="
				+ str(
					live_consequence.get(
						"effective_capacity",
						-1.0
					)
				)
			)

			all_passed = all_passed and live_consequence_test


			# Restore all modified live state before the next test.
			infrastructure.state.clear()
			for key in original_infrastructure_state.keys():
				infrastructure.state[key] = (
					original_infrastructure_state[key]
				)

			india.set_sim_metadata(
				"capabilities",
				original_capabilities
			)

			industry.set_state(
				"processes",
				original_processes
			)

			industry.set_state(
				"process_adoption",
				original_adoption
			)


	# ============================================================
	# STEP 10C — OPERATIONAL CONSEQUENCE UNIT TESTS
	# ============================================================

	var consequence_process: Dictionary = {
		"infrastructure_usage": {
			"modern_steelworks": 1.0,
			"power": 0.5
		},
		"infrastructure_requirements": {
			"modern_steelworks": 0.2
		},
		"capability_requirements": {
			"advanced_metallurgy": 0.3
		}
	}

	var partial_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_process,
			100.0,
			0.60,
			{
				"modern_steelworks": 0.40,
				"power": 0.50
			},
			{
				"advanced_metallurgy": 0.30
			}
		)
	)

	var partial_consequence_test: bool = (
		is_equal_approx(
			float(partial_consequence["adopted_capacity"]),
			60.0
		)
		and
		is_equal_approx(
			float(partial_consequence["infrastructure_usage_factor"]),
			0.40
		)
		and
		is_equal_approx(
			float(partial_consequence["operational_factor"]),
			0.40
		)
		and
		is_equal_approx(
			float(partial_consequence["effective_capacity"]),
			24.0
		)
		and
		not bool(
			partial_consequence["blocked_by_requirements"]
		)
	)

	_log(
		"Operational factor reflects infrastructure usage bottleneck: "
		+ _pass_fail(partial_consequence_test)
		+ " | expected_factor=0.40 actual="
		+ str(partial_consequence.get("operational_factor", -1.0))
		+ " | expected_capacity=24.0 actual="
		+ str(partial_consequence.get("effective_capacity", -1.0))
	)

	all_passed = all_passed and partial_consequence_test


	var sufficient_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_process,
			100.0,
			0.60,
			{
				"modern_steelworks": 0.80,
				"power": 0.50
			},
			{
				"advanced_metallurgy": 0.30
			}
		)
	)

	var sufficient_consequence_test: bool = (
		is_equal_approx(
			float(sufficient_consequence["operational_factor"]),
			0.80
		)
		and
		is_equal_approx(
			float(sufficient_consequence["effective_capacity"]),
			48.0
		)
		and
		not bool(
			sufficient_consequence["blocked_by_requirements"]
		)
	)

	_log(
		"Sufficient requirements preserve proportional operating capacity: "
		+ _pass_fail(sufficient_consequence_test)
		+ " | expected_factor=0.80 actual="
		+ str(sufficient_consequence.get("operational_factor", -1.0))
		+ " | expected_capacity=48.0 actual="
		+ str(sufficient_consequence.get("effective_capacity", -1.0))
	)

	all_passed = all_passed and sufficient_consequence_test


	var infrastructure_gate_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_process,
			100.0,
			0.60,
			{
				"modern_steelworks": 0.10,
				"power": 0.50
			},
			{
				"advanced_metallurgy": 0.30
			}
		)
	)

	var infrastructure_gate_test: bool = (
		is_zero_approx(
			float(infrastructure_gate_consequence["operational_factor"])
		)
		and
		is_zero_approx(
			float(infrastructure_gate_consequence["effective_capacity"])
		)
		and
		bool(
			infrastructure_gate_consequence["blocked_by_requirements"]
		)
		and
		String("infrastructure_requirement:modern_steelworks") in (
			infrastructure_gate_consequence["constraint_sources"]
		)
	)

	_log(
		"Infrastructure requirement gap becomes production block: "
		+ _pass_fail(infrastructure_gate_test)
	)

	all_passed = all_passed and infrastructure_gate_test


	var capability_gate_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_process,
			100.0,
			0.60,
			{
				"modern_steelworks": 0.80,
				"power": 0.50
			},
			{
				"advanced_metallurgy": 0.20
			}
		)
	)

	var capability_gate_test: bool = (
		is_zero_approx(
			float(capability_gate_consequence["operational_factor"])
		)
		and
		is_zero_approx(
			float(capability_gate_consequence["effective_capacity"])
		)
		and
		bool(
			capability_gate_consequence["blocked_by_requirements"]
		)
		and
		String("capability_requirement:advanced_metallurgy") in (
			capability_gate_consequence["constraint_sources"]
		)
	)

	_log(
		"Capability requirement gap becomes production block: "
		+ _pass_fail(capability_gate_test)
	)

	all_passed = all_passed and capability_gate_test


	var zero_adoption_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_process,
			100.0,
			0.0,
			{},
			{}
		)
	)

	var zero_adoption_consequence_test: bool = (
		is_zero_approx(
			float(zero_adoption_consequence["adopted_capacity"])
		)
		and
		is_zero_approx(
			float(zero_adoption_consequence["effective_capacity"])
		)
		and
		not bool(
			zero_adoption_consequence["blocked_by_requirements"]
		)
	)

	_log(
		"Zero adoption produces zero operational capacity without a requirement block: "
		+ _pass_fail(zero_adoption_consequence_test)
	)

	all_passed = all_passed and zero_adoption_consequence_test


	var consequence_no_requirements_process: Dictionary = {}

	var neutral_consequence: Dictionary = (
		IndustryComponent.calculate_process_operational_consequence(
			consequence_no_requirements_process,
			100.0,
			0.60,
			{},
			{}
		)
	)

	var neutral_consequence_test: bool = (
		is_equal_approx(
			float(neutral_consequence["operational_factor"]),
			1.0
		)
		and
		is_equal_approx(
			float(neutral_consequence["effective_capacity"]),
			60.0
		)
	)

	_log(
		"No infrastructure/capability constraints remain neutral: "
		+ _pass_fail(neutral_consequence_test)
		+ " | expected_capacity=60.0 actual="
		+ str(neutral_consequence.get("effective_capacity", -1.0))
	)

	all_passed = all_passed and neutral_consequence_test



	# ============================================================
	# STEP 10D — PRODUCTION PROCESS EXECUTION INTEGRATION
	# ============================================================
	#
	# This exercises the real ProductionProcessSystem execution path.
	# The test uses a temporary catalog process so it can isolate the
	# Step 10D consequence from unrelated catalog requirements.
	#
	# The temporary process has:
	#   capacity = 100
	#   adoption = 0.60
	#   infrastructure usage = 1.0 modern_steelworks / capacity
	#   infrastructure requirement = 0.50
	#   capability requirement = 0.50 advanced_metallurgy
	#
	# With modern_steelworks availability = 0.50 and capability = 0.50,
	# the normal production path must produce 30 units:
	#   100 * 0.60 * 0.50 = 30
	#
	# Requirement gaps must block production at the execution layer.
	# ============================================================

	var production_execution_test: bool = false
	var infrastructure_execution_gate_test: bool = false
	var capability_execution_gate_test: bool = false
	var full_live_execution_test: bool = false

	if world == null or typeof(world.entities) != TYPE_DICTIONARY:
		_log(
			"Step 10D production execution integration: FAIL"
			+ " | world unavailable"
		)
		all_passed = false
	else:
		var india_10d: SimEntity = world.entities.get("india") as SimEntity

		if india_10d == null:
			_log(
				"Step 10D production execution integration: FAIL"
				+ " | India entity unavailable"
			)
			all_passed = false
		else:
			var industry_10d: IndustryComponent = india_10d.get_component("industry") as IndustryComponent
			var resources_10d: ResourceComponent = india_10d.get_component("resources") as ResourceComponent
			var infrastructure_10d: SimComponent = india_10d.get_component("infrastructure") as SimComponent

			if (
				industry_10d == null
				or resources_10d == null
				or infrastructure_10d == null
			):
				_log(
					"Step 10D production execution integration: FAIL"
					+ " | required components missing"
				)
				all_passed = false
			else:
				var original_processes: Dictionary = (
					industry_10d.get_state(
						"processes",
						{}
					).duplicate(true)
				)

				var original_adoption: Dictionary = (
					industry_10d.get_state(
						"process_adoption",
						{}
					).duplicate(true)
				)

				var original_stockpile: Dictionary = (
					resources_10d.get_state(
						"stockpile",
						{}
					).duplicate(true)
				)

				var original_resource_infrastructure: Dictionary = (
					resources_10d.get_state(
						"infrastructure_capacity",
						{}
					).duplicate(true)
				)

				var original_infrastructure_state: Dictionary = (
					infrastructure_10d.state.duplicate(true)
				)

				var original_capabilities_value: Variant = (
					india_10d.get_sim_metadata(
						"capabilities",
						null
					)
				)
				var original_capabilities: Dictionary = {}
				if typeof(original_capabilities_value) == TYPE_DICTIONARY:
					original_capabilities = original_capabilities_value.duplicate(true)

				var original_production_state: Dictionary = (
					industry_10d.get_state(
						"production_state",
						{}
					).duplicate(true)
				)

				var original_production_totals: Dictionary = (
					industry_10d.get_state(
						"production_totals",
						{}
					).duplicate(true)
				)

				var temporary_process_id: String = (
					"step10d_operational_integration_process"
				)

				var production_system: ProductionProcessSystem = ProductionProcessSystem.new()

				var temporary_definition: Dictionary = {
					"name": "Step 10D Integration Process",
					"category": "manufacturing",
					"production_stage": 20,
					"available_from": 1950,
					"available_until": null,
					"technology_requirements": {},
					"capability_requirements": {
						"advanced_metallurgy": 0.5
					},
					"infrastructure_requirements": {
						"modern_steelworks": 0.5
					},
					"infrastructure_usage": {
						"modern_steelworks": 1.0
					},
					"inputs": {},
					"outputs": {
						"step10d_output": 1.0
					},
					"byproducts": {},
					"labor_requirement": 0.0,
					"capital_requirement": 0.0,
					"equipment_requirement": {},
					"energy_requirement": {},
					"maintenance_requirement": {},
					"efficiency": 1.0,
					"reliability": 1.0
				}

				production_system.catalog.processes[
					temporary_process_id
				] = temporary_definition.duplicate(true)

				var temporary_processes: Dictionary = {}
				temporary_processes[temporary_process_id] = {
					"active": true,
					"capacity": 100.0,
					"efficiency": 1.0
				}

				industry_10d.set_state(
					"processes",
					temporary_processes
				)

				var temporary_adoption: Dictionary = {}
				temporary_adoption[temporary_process_id] = 0.60

				industry_10d.set_state(
					"process_adoption",
					temporary_adoption
				)

				# Deliberately make the generic ResourceComponent bridge
				# insufficient. Step 10D must use the live
				# InfrastructureComponent availability selected by the
				# IndustryComponent resolver.
				var temporary_resource_infrastructure: Dictionary = (
					original_resource_infrastructure.duplicate(true)
				)
				temporary_resource_infrastructure[
					"modern_steelworks"
				] = 0.0

				resources_10d.set_state(
					"infrastructure_capacity",
					temporary_resource_infrastructure
				)

				var temporary_capabilities: Dictionary = (
					original_capabilities.duplicate(true)
				)
				temporary_capabilities[
					"advanced_metallurgy"
				] = 0.50

				india_10d.set_sim_metadata(
					"capabilities",
					temporary_capabilities
				)

				infrastructure_10d.set_state(
					"modern_steelworks",
					0.50
				)

				var first_stockpile: Dictionary = (
					original_stockpile.duplicate(true)
				)
				first_stockpile[
					"step10d_output"
				] = 0.0

				resources_10d.set_state(
					"stockpile",
					first_stockpile
				)

				production_system._process_entity(
					india_10d,
					industry_10d,
					resources_10d,
					world
				)

				var first_output: float = float(
					resources_10d.get_state(
						"stockpile",
						{}
					).get(
						"step10d_output",
						0.0
					)
				)

				production_execution_test = is_equal_approx(
					first_output,
					30.0
				)

				_log(
					"Step 10D live production uses operational consequence: "
					+ _pass_fail(production_execution_test)
					+ " | expected_output=30.0 actual="
					+ str(first_output)
				)

				all_passed = all_passed and production_execution_test

				# Infrastructure requirement gap must block the actual
				# ProductionProcessSystem execution path.
				infrastructure_10d.set_state(
					"modern_steelworks",
					0.40
				)

				var blocked_infrastructure_stockpile: Dictionary = (
					original_stockpile.duplicate(true)
				)
				blocked_infrastructure_stockpile[
					"step10d_output"
				] = 0.0

				resources_10d.set_state(
					"stockpile",
					blocked_infrastructure_stockpile
				)

				production_system._process_entity(
					india_10d,
					industry_10d,
					resources_10d,
					world
				)

				var infrastructure_blocked_output: float = float(
					resources_10d.get_state(
						"stockpile",
						{}
					).get(
						"step10d_output",
						0.0
					)
				)

				infrastructure_execution_gate_test = is_zero_approx(
					infrastructure_blocked_output
				)

				_log(
					"Step 10D infrastructure requirement blocks production: "
					+ _pass_fail(infrastructure_execution_gate_test)
				)

				all_passed = (
					all_passed
					and infrastructure_execution_gate_test
				)

				# Capability requirement gap must also block actual
				# ProductionProcessSystem execution.
				infrastructure_10d.set_state(
					"modern_steelworks",
					1.0
				)

				var blocked_capability_metadata: Dictionary = (
					original_capabilities.duplicate(true)
				)
				blocked_capability_metadata[
					"advanced_metallurgy"
				] = 0.40

				india_10d.set_sim_metadata(
					"capabilities",
					blocked_capability_metadata
				)

				var blocked_capability_stockpile: Dictionary = (
					original_stockpile.duplicate(true)
				)
				blocked_capability_stockpile[
					"step10d_output"
				] = 0.0

				resources_10d.set_state(
					"stockpile",
					blocked_capability_stockpile
				)

				production_system._process_entity(
					india_10d,
					industry_10d,
					resources_10d,
					world
				)

				var capability_blocked_output: float = float(
					resources_10d.get_state(
						"stockpile",
						{}
					).get(
						"step10d_output",
						0.0
					)
				)

				capability_execution_gate_test = is_zero_approx(
					capability_blocked_output
				)

				_log(
					"Step 10D capability requirement blocks production: "
					+ _pass_fail(capability_execution_gate_test)
				)

				all_passed = (
					all_passed
					and capability_execution_gate_test
				)

				# With both requirements fully available the same normal
				# execution path must restore the full adoption-scaled
				# capacity: 100 * 0.60 = 60.
				var full_capability_metadata: Dictionary = (
					original_capabilities.duplicate(true)
				)
				full_capability_metadata[
					"advanced_metallurgy"
				] = 0.50

				india_10d.set_sim_metadata(
					"capabilities",
					full_capability_metadata
				)

				infrastructure_10d.set_state(
					"modern_steelworks",
					1.0
				)

				var full_capacity_stockpile: Dictionary = (
					original_stockpile.duplicate(true)
				)
				full_capacity_stockpile[
					"step10d_output"
				] = 0.0

				resources_10d.set_state(
					"stockpile",
					full_capacity_stockpile
				)

				production_system._process_entity(
					india_10d,
					industry_10d,
					resources_10d,
					world
				)

				var full_output: float = float(
					resources_10d.get_state(
						"stockpile",
						{}
					).get(
						"step10d_output",
						0.0
					)
				)

				full_live_execution_test = is_equal_approx(
					full_output,
					60.0
				)

				_log(
					"Step 10D sufficient live requirements restore production: "
					+ _pass_fail(full_live_execution_test)
					+ " | expected_output=60.0 actual="
					+ str(full_output)
				)

				all_passed = all_passed and full_live_execution_test

				# ========================================================
				# STEP 10E — PERSISTENT PRODUCTION OUTCOME STATE
				# ========================================================
				# The same production execution path must persist the latest
				# outcome and cumulative totals on the IndustryComponent.

				var persisted_outcome: Dictionary = industry_10d.get_production_outcome(
					temporary_process_id
				)

				var persisted_totals: Dictionary = industry_10d.get_production_totals(
					temporary_process_id
				)

				var persistence_test: bool = (
					str(persisted_outcome.get("status", "")) == "produced"
					and
					is_equal_approx(
						float(persisted_outcome.get("actual_production", 0.0)),
						60.0
					)
					and
					is_equal_approx(
						float(persisted_outcome.get("effective_capacity", 0.0)),
						60.0
					)
					and
					is_equal_approx(
						float(persisted_outcome.get("operational_factor", 0.0)),
						1.0
					)
				)

				_log(
					"Step 10E latest production outcome persists: "
					+ _pass_fail(persistence_test)
					+ " | expected_production=60.0 actual="
					+ str(persisted_outcome.get("actual_production", -1.0))
				)

				all_passed = all_passed and persistence_test

				var totals_persistence_test: bool = (
					is_equal_approx(
						float(persisted_totals.get("total_production", 0.0)),
						90.0
					)
					and
					int(persisted_totals.get("execution_count", 0)) == 4
					and
					int(persisted_totals.get("blocked_count", 0)) == 2
					and
					is_equal_approx(
						float(
							Dictionary(persisted_totals.get("total_outputs_produced", {})).get(
								"step10d_output",
								0.0
							)
						),
						90.0
					)
				)

				_log(
					"Step 10E cumulative production state persists: "
					+ _pass_fail(totals_persistence_test)
					+ " | expected_total=90.0 actual="
					+ str(persisted_totals.get("total_production", -1.0))
				)

				all_passed = all_passed and totals_persistence_test

				# Restore all mutable test state.
				industry_10d.set_state(
					"processes",
					original_processes
				)

				industry_10d.set_state(
					"process_adoption",
					original_adoption
				)

				resources_10d.set_state(
					"stockpile",
					original_stockpile
				)

				resources_10d.set_state(
					"infrastructure_capacity",
					original_resource_infrastructure
				)

				infrastructure_10d.state = original_infrastructure_state

				india_10d.set_sim_metadata(
					"capabilities",
					original_capabilities
				)

				industry_10d.set_state(
					"production_state",
					original_production_state
				)

				industry_10d.set_state(
					"production_totals",
					original_production_totals
				)

				production_system.catalog.processes.erase(
					temporary_process_id
				)


	# ============================================================
	# FINAL RESULT
	# ============================================================

	TestLogger.write_line("")
	TestLogger.write_line(
		"Industry Process Infrastructure Pressure / Production Execution / Persistence test: "
		+ _pass_fail(all_passed)
	)

	return all_passed
