class_name ProductionProcessLevel2CausalValidationTest
extends RefCounted


const TARGET_PROCESS_IDS: Array[String] = [
	"natural_gas_extraction",
	"fertilizer_production",
	"cement_production",
	"chemical_production"
]


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	TestLogger.section(
		"PRODUCTION PROCESS LEVEL 2 — CAUSAL VALIDATION TEST"
	)

	var passed: bool = true

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var production_system: ProductionProcessSystem = (
		simulation.get_system(
			"production_process_system"
		) as ProductionProcessSystem
	)

	var resource_system: ResourceSystem = (
		simulation.get_system(
			"resource_system"
		) as ResourceSystem
	)

	var production_system_available: bool = (
		production_system != null
	)

	var resource_system_available: bool = (
		resource_system != null
	)

	TestLogger.write_line(
		"Registered ProductionProcessSystem available: "
		+ (
			"PASS"
			if production_system_available
			else "FAIL"
		)
	)

	TestLogger.write_line(
		"Registered ResourceSystem available: "
		+ (
			"PASS"
			if resource_system_available
			else "FAIL"
		)
	)

	if not production_system_available:
		passed = false

	if not resource_system_available:
		passed = false

	if not passed:
		TestLogger.write_line(
			"Production Process Level 2 causal validation: FAIL"
		)
		return false

	var catalog: ProductionProcessCatalog = (
		production_system.catalog
	)

	var catalog_available: bool = (
		catalog != null
		and catalog is ProductionProcessCatalog
	)

	TestLogger.write_line(
		"ProductionProcessSystem authoritative catalog available: "
		+ (
			"PASS"
			if catalog_available
			else "FAIL"
		)
	)

	if not catalog_available:
		return false

	for process_id in TARGET_PROCESS_IDS:
		var exists: bool = catalog.has_process(process_id)

		TestLogger.write_line(
			"Level 2 process resolves in authoritative catalog | "
			+ process_id
			+ ": "
			+ (
				"PASS"
				if exists
				else "FAIL"
			)
		)

		if not exists:
			passed = false

	if not passed:
		TestLogger.write_line(
			"Production Process Level 2 causal validation: FAIL"
		)
		return false

	var india: SimEntity = world.get_entity(
		"india"
	)

	if india == null:
		TestLogger.write_line(
			"India available: FAIL"
		)
		return false

	TestLogger.write_line(
		"India available: PASS"
	)

	var resources: ResourceComponent = (
		india.get_component(
			"resources"
		) as ResourceComponent
	)

	var industry: IndustryComponent = (
		india.get_component(
			"industry"
		) as IndustryComponent
	)

	var infrastructure: InfrastructureComponent = (
		india.get_component(
			"infrastructure"
		) as InfrastructureComponent
	)

	var population: PopulationComponent = (
		india.get_component(
			"population"
		) as PopulationComponent
	)

	var economy: EconomyComponent = (
		india.get_component(
			"economy"
		) as EconomyComponent
	)

	var components_available: bool = (
		resources != null
		and industry != null
		and infrastructure != null
		and population != null
		and economy != null
	)

	TestLogger.write_line(
		"Controlled India physical-economy components available: "
		+ (
			"PASS"
			if components_available
			else "FAIL"
		)
	)

	if not components_available:
		return false

	# ============================================================
	# CONTROLLED FIXTURE SNAPSHOT
	# ============================================================
	#
	# This test uses the actual registered systems but executes their
	# entity-scoped authoritative paths so the fixture does not advance
	# unrelated countries in the shared world.
	# ============================================================

	var original_resource_state: Dictionary = (
		resources.state.duplicate(true)
	)

	var original_industry_state: Dictionary = (
		industry.state.duplicate(true)
	)

	var original_infrastructure_state: Dictionary = (
		infrastructure.state.duplicate(true)
	)

	var original_population_state: Dictionary = (
		population.state.duplicate(true)
	)

	var original_economy_state: Dictionary = (
		economy.state.duplicate(true)
	)

	# ============================================================
	# ISOLATED PHYSICAL CAPACITY
	# ============================================================

	infrastructure.state = {
		"power": 1.0,
		"industrial": 1.0,
		"process_maintenance_capacity": {
			"machinery": 1.0
		}
	}

	population.state = {
		"effective_labor_capacity": 1000.0,
		"effective_skilled_labor_capacity": 1000.0
	}

	economy.state = {
		"investment_capacity": 1000.0
	}

	industry.state = {
		"processes": {
			"natural_gas_extraction": {
				"active": true,
				"capacity": 10.0,
				"efficiency": 1.0
			},
			"fertilizer_production": {
				"active": true,
				"capacity": 10.0,
				"efficiency": 1.0
			},
			"cement_production": {
				"active": true,
				"capacity": 10.0,
				"efficiency": 1.0
			},
			"chemical_production": {
				"active": true,
				"capacity": 10.0,
				"efficiency": 1.0
			}
		},
		"process_adoption": {
			"natural_gas_extraction": 1.0,
			"fertilizer_production": 1.0,
			"cement_production": 1.0,
			"chemical_production": 1.0
		},
		"production_state": {},
		"production_totals": {}
	}

	# ============================================================
	# LEVEL 2A — RESOURCE SYSTEM → NATURAL GAS → FERTILIZER
	# ============================================================
	#
	# ResourceSystem is the authoritative extraction boundary.
	# natural_gas_extraction exists in the catalog and is active in the
	# fixture, but ProductionProcessSystem must not execute it.
	#
	# The upstream intervention is supplied through ResourceComponent
	# production/reserve state, then the real ResourceSystem settles that
	# raw material before ProductionProcessSystem transforms it.
	# ============================================================

	resources.state = {
		"production": {
			"natural_gas": 10.0
		},
		"consumption": {},
		"reserves": {
			"natural_gas": 100.0
		},
		"stockpile": {
			"natural_gas": 0.0,
			"fertilizer": 0.0,
			"cement": 0.0,
			"chemicals": 0.0,
			"coal": 10.0,
			"oil": 10.0
		},
		"imports": {},
		"exports": {},
		"trade_imports": {},
		"trade_exports": {},
		"production_process_demand": {},
		"production_process_resource_availability": {},
		"critical_production_allocation_ratio": {},
		"quality": {
			"natural_gas": 1.0
		},
		"accessibility": {
			"natural_gas": 1.0
		},
		"production_efficiency": {
			"natural_gas": 1.0
		},
		"technology_efficiency": {
			"natural_gas": 1.0
		},
		"technology_access": {
			"natural_gas": 1.0
		},
		"infrastructure_capacity": {
			"natural_gas": 1.0
		},
		"extraction_capacity": {
			"natural_gas": 10.0
		},
		"processing_capacity": {
			"natural_gas": 10.0
		}
	}

	resource_system._process_entity_resources(
		india,
		resources
	)

	var resource_actual_production: Dictionary = (
		resources.get_state(
			"actual_production",
			{}
		)
	)

	var raw_gas_produced: float = float(
		resource_actual_production.get(
			"natural_gas",
			0.0
		)
	)

	var raw_gas_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var raw_gas_stockpile_value: float = float(
		raw_gas_stockpile.get(
			"natural_gas",
			0.0
		)
	)

	var raw_gas_settlement_passed: bool = (
		is_equal_approx(
			raw_gas_produced,
			10.0
		)
		and is_equal_approx(
			raw_gas_stockpile_value,
			10.0
		)
	)

	TestLogger.write_line(
		"ResourceSystem natural-gas settlement: "
		+ (
			"PASS"
			if raw_gas_settlement_passed
			else "FAIL"
		)
		+ " | expected_production=10.0 actual="
		+ str(raw_gas_produced)
		+ " expected_stockpile=10.0 actual="
		+ str(raw_gas_stockpile_value)
	)

	if not raw_gas_settlement_passed:
		passed = false

	# ============================================================
	# LEVEL 2B — EXPANDED PROCESS EXECUTION + EXTRACTION BOUNDARY
	# ============================================================

	production_system._process_entity(
		india,
		industry,
		resources,
		world
	)

	var full_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var fertilizer_output: float = float(
		full_stockpile.get(
			"fertilizer",
			0.0
		)
	)

	var cement_output: float = float(
		full_stockpile.get(
			"cement",
			0.0
		)
	)

	var chemical_output: float = float(
		full_stockpile.get(
			"chemicals",
			0.0
		)
	)

	var gas_after_transformation: float = float(
		full_stockpile.get(
			"natural_gas",
			0.0
		)
	)

	var coal_after_transformation: float = float(
		full_stockpile.get(
			"coal",
			0.0
		)
	)

	var oil_after_transformation: float = float(
		full_stockpile.get(
			"oil",
			0.0
		)
	)

	var production_state: Dictionary = (
		industry.get_state(
			"production_state",
			{}
		)
	)

	var extraction_state_present: bool = (
		production_state.has(
			"natural_gas_extraction"
		)
	)

	var transformation_passed: bool = (
		is_equal_approx(
			fertilizer_output,
			10.0
		)
		and is_equal_approx(
			cement_output,
			10.0
		)
		and is_equal_approx(
			chemical_output,
			10.0
		)
		and is_equal_approx(
			gas_after_transformation,
			0.0
		)
		and is_equal_approx(
			coal_after_transformation,
			0.0
		)
		and is_equal_approx(
			oil_after_transformation,
			0.0
		)
		and not extraction_state_present
	)

	TestLogger.write_line(
		"Natural gas -> fertilizer causal transformation: "
		+ (
			"PASS"
			if is_equal_approx(fertilizer_output, 10.0)
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(fertilizer_output)
	)

	TestLogger.write_line(
		"Coal -> cement causal transformation: "
		+ (
			"PASS"
			if is_equal_approx(cement_output, 10.0)
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(cement_output)
	)

	TestLogger.write_line(
		"Oil -> chemicals causal transformation: "
		+ (
			"PASS"
			if is_equal_approx(chemical_output, 10.0)
			else "FAIL"
		)
		+ " | expected=10.0 actual="
		+ str(chemical_output)
	)

	TestLogger.write_line(
		"Natural-gas extraction remains outside ProductionProcessSystem: "
		+ (
			"PASS"
			if not extraction_state_present
			else "FAIL"
		)
	)

	if not transformation_passed:
		passed = false

	# ============================================================
	# LEVEL 2C — UPSTREAM CAUSAL CUT
	# ============================================================
	#
	# Intervention 1: remove upstream natural-gas supply.
	# Intervention 2: restore it.
	#
	# The downstream fertilizer output must move from zero to full
	# capacity without changing the fertilizer process definition.
	# ============================================================

	var causal_processes: Dictionary = {
		"natural_gas_extraction": {
			"active": true,
			"capacity": 10.0,
			"efficiency": 1.0
		},
		"fertilizer_production": {
			"active": true,
			"capacity": 10.0,
			"efficiency": 1.0
		}
	}

	industry.set_state(
		"processes",
		causal_processes
	)

	industry.set_state(
		"process_adoption",
		{
			"natural_gas_extraction": 1.0,
			"fertilizer_production": 1.0
		}
	)

	industry.set_state(
		"production_state",
		{}
	)

	industry.set_state(
		"production_totals",
		{}
	)

	resources.state = {
		"production": {},
		"consumption": {},
		"reserves": {},
		"stockpile": {
			"natural_gas": 0.0,
			"fertilizer": 0.0
		},
		"imports": {},
		"exports": {},
		"trade_imports": {},
		"trade_exports": {},
		"production_process_demand": {},
		"production_process_resource_availability": {},
		"critical_production_allocation_ratio": {}
	}

	resource_system._process_entity_resources(
		india,
		resources
	)

	production_system._process_entity(
		india,
		industry,
		resources,
		world
	)

	var no_supply_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var fertilizer_without_upstream_supply: float = float(
		no_supply_stockpile.get(
			"fertilizer",
			0.0
		)
	)

	# Restore the upstream raw-material intervention without changing
	# the downstream fertilizer process.
	resources.state = {
		"production": {
			"natural_gas": 10.0
		},
		"consumption": {},
		"reserves": {
			"natural_gas": 100.0
		},
		"stockpile": {
			"natural_gas": 0.0,
			"fertilizer": 0.0
		},
		"imports": {},
		"exports": {},
		"trade_imports": {},
		"trade_exports": {},
		"production_process_demand": {},
		"production_process_resource_availability": {},
		"critical_production_allocation_ratio": {},
		"quality": {
			"natural_gas": 1.0
		},
		"accessibility": {
			"natural_gas": 1.0
		},
		"production_efficiency": {
			"natural_gas": 1.0
		},
		"technology_efficiency": {
			"natural_gas": 1.0
		},
		"technology_access": {
			"natural_gas": 1.0
		},
		"infrastructure_capacity": {
			"natural_gas": 1.0
		},
		"extraction_capacity": {
			"natural_gas": 10.0
		},
		"processing_capacity": {
			"natural_gas": 10.0
		}
	}

	industry.set_state(
		"production_state",
		{}
	)

	industry.set_state(
		"production_totals",
		{}
	)

	resource_system._process_entity_resources(
		india,
		resources
	)

	production_system._process_entity(
		india,
		industry,
		resources,
		world
	)

	var restored_supply_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var fertilizer_with_upstream_supply: float = float(
		restored_supply_stockpile.get(
			"fertilizer",
			0.0
		)
	)

	var causal_cut_passed: bool = (
		is_equal_approx(
			fertilizer_without_upstream_supply,
			0.0
		)
		and is_equal_approx(
			fertilizer_with_upstream_supply,
			10.0
		)
		and fertilizer_with_upstream_supply > fertilizer_without_upstream_supply
	)

	TestLogger.write_line(
		"Upstream natural-gas supply cut -> fertilizer output: "
		+ (
			"PASS"
			if causal_cut_passed
			else "FAIL"
		)
		+ " | without_supply="
		+ str(fertilizer_without_upstream_supply)
		+ " with_supply="
		+ str(fertilizer_with_upstream_supply)
	)

	if not causal_cut_passed:
		passed = false

	# ============================================================
	# LEVEL 2D — PARTIAL INPUT SHORTAGE
	# ============================================================
	#
	# The production process itself must respect partial physical input
	# availability rather than inventing missing natural gas.
	# ============================================================

	resources.state = {
		"production": {},
		"consumption": {},
		"reserves": {},
		"stockpile": {
			"natural_gas": 5.0,
			"fertilizer": 0.0
		},
		"imports": {},
		"exports": {},
		"trade_imports": {},
		"trade_exports": {},
		"production_process_demand": {},
		"production_process_resource_availability": {},
		"critical_production_allocation_ratio": {}
	}

	industry.set_state(
		"production_state",
		{}
	)

	industry.set_state(
		"production_totals",
		{}
	)

	production_system._process_entity(
		india,
		industry,
		resources,
		world
	)

	var partial_stockpile: Dictionary = (
		resources.get_state(
			"stockpile",
			{}
		)
	)

	var fertilizer_partial_output: float = float(
		partial_stockpile.get(
			"fertilizer",
			0.0
		)
	)

	var fertilizer_partial_gas: float = float(
		partial_stockpile.get(
			"natural_gas",
			0.0
		)
	)

	var partial_shortage_passed: bool = (
		is_equal_approx(
			fertilizer_partial_output,
			5.0
		)
		and is_equal_approx(
			fertilizer_partial_gas,
			0.0
		)
	)

	TestLogger.write_line(
		"Partial natural-gas supply constrains fertilizer output: "
		+ (
			"PASS"
			if partial_shortage_passed
			else "FAIL"
		)
		+ " | expected_output=5.0 actual="
		+ str(fertilizer_partial_output)
		+ " remaining_gas="
		+ str(fertilizer_partial_gas)
	)

	if not partial_shortage_passed:
		passed = false

	# ============================================================
	# RESTORE ORIGINAL COMPONENT STATE
	# ============================================================

	resources.state = original_resource_state.duplicate(true)
	industry.state = original_industry_state.duplicate(true)
	infrastructure.state = original_infrastructure_state.duplicate(true)
	population.state = original_population_state.duplicate(true)
	economy.state = original_economy_state.duplicate(true)

	TestLogger.write_line(
		"Production Process Level 2 causal validation: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
