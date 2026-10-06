class_name Step19CausalArchitectureCoverageAuditTest
extends RefCounted


# ============================================================
# STEP 19.A — CAUSAL ARCHITECTURE COVERAGE AUDIT
# ============================================================
#
# This audit validates the CURRENT live SimulationEngine registration graph.
# It is structural only: it does not advance the world and does not mutate
# domain state.
#
# Active architecture baseline established from the current main.gd plus the
# two systems internally registered by SimulationEngine:
#   main.gd registrations               = 93
#   SimulationEngine internal registers = 2
#   total                               = 95
#
# The complete graph is represented here intentionally. Step 19.A is the
# registration / timing audit, so a missing or substituted registered system
# must be detected rather than silently ignored.
# ============================================================

const EXPECTED_MAIN_REGISTRATION_COUNT: int = 93
const EXPECTED_INTERNAL_REGISTRATION_COUNT: int = 2
const EXPECTED_REGISTERED_SYSTEM_COUNT: int = 95


# Full active registration contract: system_name -> phase/order.
const EXPECTED_REGISTRATION: Dictionary = {
	"demographics_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 5},
	"migration_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 8},
	"population_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 10},
	"labor_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 12},
	"infrastructure_maintenance_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 25},
	"infrastructure_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 26},
	"infrastructure_investment_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 23},
	"infrastructure_construction_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 24},
	"infrastructure_bottleneck_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 27},
	"trade_embargo_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 28},
	"trade_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 29},
	"resource_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 30},
	"trade_diplomatic_consequences_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 31},
	"military_resource_demand_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 34},
	"production_process_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 35},
	"aggregate_demand_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 36},
	"aggregate_consumption_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 37},
	"supply_demand_resolution_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 38},
	"capacity_utilization_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 39},
	"basic_price_formation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 40},
	"income_wage_flow_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 41},
	"purchasing_power_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 42},
	"resource_allocation_distribution_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 43},
	"currency_identity_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 44},
	"trade_valuation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 45},
	"currency_conversion_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 46},
	"payment_affordability_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 47},
	"trade_payment_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 48},
	"monetary_invariant_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 49},
	"research_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 50},
	"technology_effect_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 51},
	"technology_adoption_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 52},
	"capability_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 53},
	"constraint_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 54},
	"geography_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 55},
	"government_implementation_capacity_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 56},
	"economy_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 57},
	"government_policy_cost_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_production_capacity_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_resource_readiness_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_transport_logistics_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_port_naval_logistics_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_power_infrastructure_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 58},
	"military_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 59},
	"military_economic_pressure_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 60},
	"government_policy_effect_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 61},
	"military_relationship_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 62},
	"government_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 63},
	"influence_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 64},
	"tax_incidence_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 65},
	"conflict_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 66},
	"military_event_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 67},
	"event_synchronizer": {"phase": SimulationPhase.WORLD_UPDATE, "order": 68},
	"domestic_accessibility_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 69},
	"scarce_resource_allocation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 70},
	"infrastructure_damage_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 71},
	"priority_class_allocation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 71},
	"allocation_consequences_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 72},
	"government_spending_allocation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 73},
	"government_public_service_output_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 74},
	"government_law_amendment_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 75},
	"government_transition_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 76},
	"standard_of_living_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 77},
	"welfare_effect_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 78},
	"income_consumption_feedback_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 79},
	"economic_pressure_political_feedback_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 80},
	"basic_population_response_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 81},
	"government_feedback_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 82},
	"external_event_relevance_filter": {"phase": SimulationPhase.WORLD_UPDATE, "order": 83},
	"external_event_causality": {"phase": SimulationPhase.WORLD_UPDATE, "order": 84},
	"external_actor_limited_simulation": {"phase": SimulationPhase.WORLD_UPDATE, "order": 85},
	"trade_route_restriction_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 86},
	"trade_restriction_interaction_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 87},
	"trade_restriction_recovery_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 88},
	"regionalization_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 89},
	"regional_ownership_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 90},
	"regional_terrain_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 91},
	"regional_population_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 92},
	"regional_resource_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 93},
	"regional_infrastructure_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 94},
	"regional_industry_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 95},
	"regional_transport_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 96},
	"country_aggregation_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 97},
	"infrastructure_reconstruction_investment_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 98},
	"infrastructure_recovery_system": {"phase": SimulationPhase.WORLD_UPDATE, "order": 99},
	"action_manager": {"phase": SimulationPhase.ACTIONS, "order": 10},
	"event_simulation_integration": {"phase": SimulationPhase.EVENTS, "order": 10},
	"country_strategy_system": {"phase": SimulationPhase.DECISIONS, "order": 10},
	"goal_system": {"phase": SimulationPhase.DECISIONS, "order": 20},
	"decision_system": {"phase": SimulationPhase.DECISIONS, "order": 30},
	"decision_trajectory_system": {"phase": SimulationPhase.DECISIONS, "order": 40},
	"ai_decision_system": {"phase": SimulationPhase.DECISIONS, "order": 51},
	"history_system": {"phase": SimulationPhase.POST_SIMULATION, "order": 10},
	"military_history_system": {"phase": SimulationPhase.POST_SIMULATION, "order": 15},
	"ai_memory_system": {"phase": SimulationPhase.POST_SIMULATION, "order": 20}
}


const EXPECTED_PHASE_COUNTS: Dictionary = {
	SimulationPhase.PRE_SIMULATION: 0,
	SimulationPhase.WORLD_UPDATE: 85,
	SimulationPhase.ACTIONS: 1,
	SimulationPhase.EVENTS: 1,
	SimulationPhase.DECISIONS: 5,
	SimulationPhase.POST_SIMULATION: 3
}


# Critical producer -> consumer timing contracts.
const CRITICAL_ORDER_EDGES: Array = [
	["infrastructure_system", "resource_system", "same_cycle"],
	["infrastructure_system", "production_process_system", "same_cycle"],
	["trade_system", "resource_system", "same_cycle"],
	["resource_system", "production_process_system", "same_cycle"],
	["military_resource_demand_system", "aggregate_demand_system", "same_cycle"],
	["production_process_system", "aggregate_demand_system", "same_cycle"],
	["aggregate_demand_system", "aggregate_consumption_system", "same_cycle"],
	["aggregate_consumption_system", "supply_demand_resolution_system", "same_cycle"],
	["research_system", "technology_effect_system", "same_cycle"],
	["technology_effect_system", "technology_adoption_system", "same_cycle"],
	["technology_adoption_system", "capability_system", "same_cycle"],
	["technology_adoption_system", "constraint_system", "same_cycle"],
	["production_process_system", "economy_system", "same_cycle"],
	["military_system", "military_economic_pressure_system", "same_cycle"],
	["population_system", "labor_system", "same_cycle"],
	["labor_system", "production_process_system", "same_cycle"],
	["trade_diplomatic_consequences_system", "trade_restriction_interaction_system", "same_cycle"],
	["conflict_system", "infrastructure_damage_system", "same_cycle"],
	["event_synchronizer", "event_simulation_integration", "next_phase"],
	["government_policy_effect_system", "economy_system", "next_cycle_required"],
	["infrastructure_damage_system", "infrastructure_system", "next_cycle_required"]
]


const EXPECTED_SHARED_ORDER_GROUPS: Dictionary = {
	SimulationPhase.WORLD_UPDATE + "|58": [
		"government_policy_cost_system",
		"military_production_capacity_system",
		"military_resource_readiness_system",
		"military_transport_logistics_system",
		"military_port_naval_logistics_system",
		"military_power_infrastructure_system"
	],
	SimulationPhase.WORLD_UPDATE + "|71": [
		"infrastructure_damage_system",
		"priority_class_allocation_system"
	]
}


static func run(world: WorldState, simulation: SimulationEngine) -> bool:
	TestLogger.section("STEP 19.A — CAUSAL ARCHITECTURE COVERAGE AUDIT")

	if world == null:
		_log_result("World available", false)
		return false
	_log_result("World available", true)

	if simulation == null:
		_log_result("Simulation available", false)
		return false
	_log_result("Simulation available", true)

	var registered: Array = simulation.get_system_order()
	var passed: bool = true

	passed = _check(
		registered.size() == EXPECTED_REGISTERED_SYSTEM_COUNT,
		"Registered system count = %d (observed=%d)" % [EXPECTED_REGISTERED_SYSTEM_COUNT, registered.size()]
	) and passed

	passed = _check(
		_registered_system_names_unique(registered),
		"Registered system names are unique"
	) and passed

	passed = _check(
		_phase_order_is_monotonic(registered),
		"Registered phase ordering is monotonic"
	) and passed

	passed = _check(
		_phase_counts_match(registered),
		"Registered phase counts match the active architecture"
	) and passed

	passed = _check(
		_full_registration_contract_matches(registered),
		"Full 95-system registration contract matches the active architecture"
	) and passed

	passed = _check(
		_critical_order_edges_hold(registered),
		"Critical producer/consumer timing contracts hold"
	) and passed

	passed = _check(
		_allowed_shared_orders_only(registered),
		"Only documented shared numeric orders are present"
	) and passed

	passed = _check(
		_shared_order_membership_matches(registered),
		"Documented shared-order groups contain the expected systems"
	) and passed

	_log_result("Step 19.A Causal Architecture Coverage Audit overall", passed)
	return passed


static func _registered_system_names_unique(registered: Array) -> bool:
	var seen: Dictionary = {}
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		if entry.is_empty():
			TestLogger.write_line("19.A DIAGNOSTIC: empty registration entry")
			return false
		var name: String = str(entry.get("name", ""))
		if name.is_empty():
			TestLogger.write_line("19.A DIAGNOSTIC: empty system name | entry=" + str(entry))
			return false
		if seen.has(name):
			TestLogger.write_line("19.A DIAGNOSTIC: duplicate system name | " + name)
			return false
		seen[name] = true
	return true


static func _phase_order_is_monotonic(registered: Array) -> bool:
	var phase_rank: Dictionary = {
		SimulationPhase.PRE_SIMULATION: 0,
		SimulationPhase.WORLD_UPDATE: 1,
		SimulationPhase.ACTIONS: 2,
		SimulationPhase.EVENTS: 3,
		SimulationPhase.DECISIONS: 4,
		SimulationPhase.POST_SIMULATION: 5
	}
	var previous_rank: int = -1
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		var phase: String = str(entry.get("phase", ""))
		if not phase_rank.has(phase):
			TestLogger.write_line("19.A DIAGNOSTIC: unknown phase | system=" + str(entry.get("name", "")) + " phase=" + phase)
			return false
		var rank: int = int(phase_rank[phase])
		if rank < previous_rank:
			TestLogger.write_line("19.A DIAGNOSTIC: phase regression | system=" + str(entry.get("name", "")))
			return false
		previous_rank = rank
	return true


static func _phase_counts_match(registered: Array) -> bool:
	var observed: Dictionary = {}
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		var phase: String = str(entry.get("phase", ""))
		observed[phase] = int(observed.get(phase, 0)) + 1
	for phase in EXPECTED_PHASE_COUNTS.keys():
		var expected: int = int(EXPECTED_PHASE_COUNTS[phase])
		var actual: int = int(observed.get(phase, 0))
		if expected != actual:
			TestLogger.write_line("19.A DIAGNOSTIC: phase count mismatch | phase=%s expected=%d actual=%d" % [phase, expected, actual])
			return false
	return true


static func _full_registration_contract_matches(registered: Array) -> bool:
	var observed: Dictionary = {}
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		var name: String = str(entry.get("name", ""))
		observed[name] = {
			"phase": str(entry.get("phase", "")),
			"order": int(entry.get("order", -1))
		}

	if observed.size() != EXPECTED_REGISTRATION.size():
		TestLogger.write_line("19.A DIAGNOSTIC: expected registration map size=%d observed=%d" % [EXPECTED_REGISTRATION.size(), observed.size()])
		return false

	var passed: bool = true
	for expected_name in EXPECTED_REGISTRATION.keys():
		if not observed.has(expected_name):
			TestLogger.write_line("19.A DIAGNOSTIC: missing registered system | " + expected_name)
			passed = false
			continue
		var expected_entry: Dictionary = EXPECTED_REGISTRATION[expected_name]
		var actual_entry: Dictionary = observed[expected_name]
		if str(actual_entry.get("phase", "")) != str(expected_entry.get("phase", "")):
			TestLogger.write_line("19.A DIAGNOSTIC: phase mismatch | %s expected=%s actual=%s" % [expected_name, str(expected_entry.get("phase", "")), str(actual_entry.get("phase", ""))])
			passed = false
		if int(actual_entry.get("order", -1)) != int(expected_entry.get("order", -1)):
			TestLogger.write_line("19.A DIAGNOSTIC: order mismatch | %s expected=%d actual=%d" % [expected_name, int(expected_entry.get("order", -1)), int(actual_entry.get("order", -1))])
			passed = false

	for observed_name in observed.keys():
		if not EXPECTED_REGISTRATION.has(observed_name):
			TestLogger.write_line("19.A DIAGNOSTIC: unexpected registered system | " + str(observed_name))
			passed = false

	return passed


static func _find_entry(registered: Array, system_name: String) -> Dictionary:
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		if str(entry.get("name", "")) == system_name:
			return entry
	return {}


static func _find_order(registered: Array, system_name: String) -> int:
	var entry: Dictionary = _find_entry(registered, system_name)
	return int(entry.get("order", -1))


static func _find_phase(registered: Array, system_name: String) -> String:
	var entry: Dictionary = _find_entry(registered, system_name)
	return str(entry.get("phase", ""))


static func _critical_order_edges_hold(registered: Array) -> bool:
	var passed: bool = true
	for raw_edge in CRITICAL_ORDER_EDGES:
		var edge: Array = raw_edge as Array
		if edge.size() != 3:
			TestLogger.write_line("19.A DIAGNOSTIC: malformed timing edge | " + str(edge))
			passed = false
			continue

		var producer: String = str(edge[0])
		var consumer: String = str(edge[1])
		var timing: String = str(edge[2])
		var producer_phase: String = _find_phase(registered, producer)
		var consumer_phase: String = _find_phase(registered, consumer)
		var producer_order: int = _find_order(registered, producer)
		var consumer_order: int = _find_order(registered, consumer)

		if producer_order < 0 or consumer_order < 0:
			TestLogger.write_line("19.A DIAGNOSTIC: timing edge system missing | producer=%s consumer=%s" % [producer, consumer])
			passed = false
			continue

		match timing:
			"same_cycle":
				if producer_phase != SimulationPhase.WORLD_UPDATE or consumer_phase != SimulationPhase.WORLD_UPDATE or producer_order >= consumer_order:
					TestLogger.write_line("19.A DIAGNOSTIC: same-cycle edge violation | %s(%s,%d) -> %s(%s,%d)" % [producer, producer_phase, producer_order, consumer, consumer_phase, consumer_order])
					passed = false
			"next_phase":
				if producer_phase != SimulationPhase.WORLD_UPDATE or consumer_phase != SimulationPhase.EVENTS:
					TestLogger.write_line("19.A DIAGNOSTIC: next-phase edge violation | %s(%s,%d) -> %s(%s,%d)" % [producer, producer_phase, producer_order, consumer, consumer_phase, consumer_order])
					passed = false
			"next_cycle_required":
				if producer_phase != SimulationPhase.WORLD_UPDATE or consumer_phase != SimulationPhase.WORLD_UPDATE or producer_order <= consumer_order:
					TestLogger.write_line("19.A DIAGNOSTIC: next-cycle edge violation | %s(%s,%d) -> %s(%s,%d)" % [producer, producer_phase, producer_order, consumer, consumer_phase, consumer_order])
					passed = false
			_:
				TestLogger.write_line("19.A DIAGNOSTIC: unknown timing contract | " + timing)
				passed = false

	return passed


static func _allowed_shared_orders_only(registered: Array) -> bool:
	var groups: Dictionary = {}
	for raw_entry in registered:
		var entry: Dictionary = raw_entry as Dictionary
		var key: String = str(entry.get("phase", "")) + "|" + str(int(entry.get("order", -1)))
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(str(entry.get("name", "")))

	var passed: bool = true
	for key in groups.keys():
		var members: Array = groups[key]
		if members.size() <= 1:
			continue
		if not EXPECTED_SHARED_ORDER_GROUPS.has(key):
			TestLogger.write_line("19.A DIAGNOSTIC: unexpected shared order | " + str(key) + " members=" + str(members))
			passed = false
			continue
		var expected: Array = EXPECTED_SHARED_ORDER_GROUPS[key].duplicate(true)
		expected.sort()
		var observed: Array = members.duplicate(true)
		observed.sort()
		if expected != observed:
			TestLogger.write_line("19.A DIAGNOSTIC: shared order mismatch | " + str(key) + " expected=" + str(expected) + " observed=" + str(observed))
			passed = false
	return passed


static func _shared_order_membership_matches(registered: Array) -> bool:
	# Kept as a separate explicit invariant so the acceptance report names this
	# contract independently from the general duplicate-order check.
	return _allowed_shared_orders_only(registered)


static func _check(condition: bool, label: String) -> bool:
	_log_result(label, condition)
	return condition


static func _log_result(label: String, value: bool) -> void:
	TestLogger.write_line(label + ": " + ("PASS" if value else "FAIL"))
