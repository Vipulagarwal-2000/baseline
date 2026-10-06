class_name ResourceComponent
extends SimComponent


func _init(owner: String = ""):
	super(
		"resources",
		owner
	)

	state = {
		# ====================================================
		# CORE RESOURCE FLOW
		# ====================================================

		"production": {},
		"consumption": {},
		"reserves": {},
		"stockpile": {},
		"imports": {},
		"exports": {},

		# TradeSystem 4.5 writes flows that have already been constrained
		# by the physical infrastructure chain. ResourceSystem uses these
		# states to avoid applying port throughput a second time.
		"trade_imports": {},
		"trade_exports": {},

		# ====================================================
		# EFFECTIVE PRODUCTION
		# ====================================================

		"actual_production": {},
		"extraction_capacity": {},
		"processing_capacity": {},
		"production_efficiency": {},

		# ====================================================
		# RESOURCE BALANCE
		# ====================================================

		"net_balance": {},

		# Step 5.1 — explicit stock/flow accounting state. These values
		# describe the monthly resource-stock reconciliation without
		# changing the existing ResourceSystem settlement behavior.
		"opening_stockpile": {},
		"closing_stockpile": {},
		"fulfilled_demand": {},
		"stock_flow_ledger": {},
		"stock_flow_reconciliation_error": {},
		"opening_reserves": {},
		"closing_reserves": {},
		"reserve_flow_reconciliation_error": {},

		# Step 5.2 — inventory / stock-buffer semantics.
		# committed_stockpile is an external reservation of physical
		# stock for future obligations. ResourceSystem does not mutate
		# the requested commitment; it derives how much is physically
		# secured and how much remains uncovered.
		"committed_stockpile": {},
		"secured_commitment": {},
		"commitment_shortfall": {},
		"available_stockpile": {},
		"available_supply": {},
		"closing_committed_stockpile": {},
		"closing_available_stockpile": {},
		"closing_commitment_shortfall": {},
		"inventory_buffer_ledger": {},

		# Step 5.3 — aggregate demand inputs and resolved demand ledger.
		# These dictionaries are demand signals supplied by the relevant
		# upstream domains. They are not physical consumption yet.
		"population_resource_demand": {},
		"government_resource_demand": {},
		"military_resource_demand": {},
		"aggregate_demand_by_category": {},
		"aggregate_demand_total_by_category": {},
		"aggregate_demand": {},
		"aggregate_demand_total": 0.0,
		"aggregate_demand_reconciliation_error": {},
		"aggregate_demand_ledger": {},

		# Step 5.4 — aggregate domestic consumption resolution.
		# This converts the current aggregate domestic demand signal into
		# the consumption request used by the next physical resource
		# settlement. Scarcity/shortage resolution remains Step 5.5.
		"consumption_by_category": {},
		"consumption_total_by_category": {},
		"actual_consumption": {},
		"actual_consumption_total": 0.0,
		"consumption_reconciliation_error": {},
		"consumption_ledger": {},

		# Step 5.5 — basic supply / demand resolution. These states are
		# a current-cycle resolution layer and do not directly mutate the
		# physical stockpile. ResourceSystem remains the authoritative
		# monthly physical settlement system.
		"resolved_supply": {},
		"resolved_demand": {},
		"resolved_fulfilled_demand": {},
		"resolved_unmet_demand": {},
		"resolved_surplus": {},
		"resolved_shortage_ratio": {},
		"supply_demand_reconciliation_error": {},
		"supply_demand_ledger": {},
		"supply_demand_total_supply": 0.0,
		"supply_demand_total_demand": 0.0,
		"supply_demand_total_fulfilled": 0.0,
		"supply_demand_total_unmet": 0.0,
		"supply_demand_total_surplus": 0.0,

		# Step 5.6 — basic capacity utilization. These are diagnostics
		# derived from the authoritative ProductionProcessSystem outcome:
		# installed/base capacity, effective usable capacity before input
		# shortages, and actual production after input constraints.
		"installed_capacity": 0.0,
		"effective_capacity": 0.0,
		"actual_capacity_production": 0.0,
		"unused_effective_capacity": 0.0,
		"capacity_gap": 0.0,
		"capacity_utilization": 0.0,
		"installed_capacity_utilization": 0.0,
		"effective_capacity_ratio": 0.0,
		"capacity_utilization_by_process": {},
		"capacity_utilization_ledger": {},

		# Step 5.7 — basic resource price formation. These states derive a
		# current unit price from an explicit base price plus the Step 5.5
		# shortage / surplus result. This is an aggregate diagnostic price
		# signal only; it is not a market-clearing or monetary system.
		"base_price": {},
		"scarcity_price_modifier": {},
		"surplus_price_modifier": {},
		"price_modifier": {},
		"current_price": {},
		"price_formation_ledger": {},

		# Step 5.10 — resource allocation / domestic distribution. These states
		# consume the already-resolved supply and existing accessibility factor.
		# They do not create a second inventory, transport, or market model.
		"domestic_accessible_supply": {},
		"distribution_access_loss": {},
		"allocated_supply_by_category": {},
		"allocated_supply_total": {},
		"allocation_unmet_by_category": {},
		"unallocated_accessible_supply": {},
		"allocation_reconciliation_error": {},
		"domestic_distribution_total_accessible": 0.0,
		"domestic_distribution_total_allocated": 0.0,
		"domestic_distribution_total_unmet": 0.0,
		"domestic_distribution_ledger": {},

		# ====================================================
		# STEP 7.1 — SCARCE RESOURCE ALLOCATION
		# ====================================================

		# Whether accessible domestic supply is insufficient for the
		# current domestic claims of a resource.
		"scarcity_active": {},

		# Total domestic claims before scarce-supply allocation.
		"domestic_claims_total": {},

		# Fulfillment ratio by domestic demand category.
		"allocation_fulfillment_ratio_by_category": {},

		# Explicit shortfall ratio by domestic demand category.
		"allocation_shortfall_ratio_by_category": {},

		# True when the accessible domestic pool is exhausted by claims.
		"allocation_exhausted": {},

		# Per-resource accounting ledger for the scarce-allocation layer.
		"scarce_resource_allocation_ledger": {},

		# Maximum absolute reconciliation error per resource.
		"scarce_resource_allocation_reconciliation_error": {},

		# ====================================================
		# STEP 7.2 — BASIC PRIORITY CLASSES
		# ====================================================

		# Configurable priority-class order used by the Step 7.2
		# derived allocation overlay.
		"priority_class_order": [],

		# Maps each demand category to its configured priority class.
		"priority_class_by_category": {},

		# Total claim assigned to each priority class, per resource.
		"priority_claim_by_class": {},

		# Supply allocated to each priority class, per resource.
		"priority_allocated_supply_by_class": {},

		# Unmet claim remaining in each priority class, per resource.
		"priority_unmet_by_class": {},

		# Priority-aware allocation by original demand category.
		"priority_allocated_supply_by_category": {},

		# Priority-aware unmet demand by original demand category.
		"priority_allocation_unmet_by_category": {},

		# Fulfillment ratio by original demand category after priority allocation.
		"priority_allocation_fulfillment_ratio_by_category": {},

		# Shortfall ratio by original demand category after priority allocation.
		"priority_allocation_shortfall_ratio_by_category": {},

		# Remaining accessible supply after all configured priority classes.
		"priority_allocation_remaining_supply": {},

		# True when priority-aware allocation exhausts accessible supply
		# while positive claims remain unmet.
		"priority_allocation_exhausted": {},

		# Per-resource / per-class priority allocation ledger.
		"priority_allocation_ledger": {},

		# Maximum absolute reconciliation error per resource.
		"priority_allocation_reconciliation_error": {},

		# ====================================================
		# STEP 7.3 — DOMESTIC ACCESSIBILITY
		# ====================================================

		# Explicit country-level physical domestic supply after upstream export
		# reservation. This is derived from the authoritative Step 5.10 result.
		"domestic_physical_supply": {},

		# Effective country-level accessibility factor represented by the
		# existing physical distribution layer.
		"domestic_accessibility_factor": {},

		# Maximum reconciliation error between the explicit 7.3 resolution and
		# the authoritative Step 5.10 accessible/distribution quantities.
		"domestic_accessibility_reconciliation_error": {},

		# Per-resource evidence ledger for the 7.3 accessibility resolution.
		"domestic_accessibility_ledger": {},

		"domestic_accessibility_total_physical": 0.0,
		"domestic_accessibility_total_accessible": 0.0,
		"domestic_accessibility_total_loss": 0.0,

		# ====================================================
		# STEP 7.4 — ALLOCATION CONSEQUENCES
		# ====================================================

		# Explicit downstream allocation result consumed by later physical,
		# consumption, government-resource and military-resource paths.
		"allocation_consequence_allocated_by_category": {},
		"allocation_consequence_unmet_by_category": {},
		"allocation_consequence_fulfillment_ratio_by_category": {},
		"allocation_consequence_shortfall_ratio_by_category": {},
		"allocation_consequence_remaining_supply": {},
		"allocation_consequence_exhausted": {},
		"allocation_consequence_total_allocated": {},
		"allocation_consequence_total_unmet": {},
		"allocation_consequence_reconciliation_error": {},
		"allocation_consequence_ledger": {},

		# Domain-specific consequence factors. These are derived from the
		# authoritative Step 7.2 priority allocation and remain resource-level
		# state so later systems do not need to reconstruct allocation semantics.
		"population_consumption_allocation_ratio": {},
		"critical_production_allocation_ratio": {},
		"government_resource_allocation_ratio": {},
		"military_resource_allocation_ratio": {},

		"shortages": {},
		"shortage_ratio": {},
		"surplus": {},

		# ====================================================
		# RESERVE / STOCKPILE CONDITION
		# ====================================================

		"reserve_depletion": {},
		"reserve_ratio": {},

		# ====================================================
		# RESOURCE QUALITY / ACCESS
		# ====================================================

		"quality": {},
		"accessibility": {},

		# ====================================================
		# TECHNOLOGY INTERACTION
		# ====================================================

		"technology_efficiency": {},
		"technology_access": {},
		"substitution_capacity": {},

		# ====================================================
		# INFRASTRUCTURE INTERACTION
		# ====================================================

		"infrastructure_capacity": {},
		"storage_capacity": {},
		"max_stockpile_capacity": {},
		"storage_overflow": {},

				# ====================================================
		# PER-RESOURCE EFFECTS
		# ====================================================

		"resource_efficiency_by_resource": {},
		"industrial_resource_modifier_by_resource": {},
		"military_resource_modifier_by_resource": {},
		"transport_resource_modifier_by_resource": {},

		# ====================================================
		# AGGREGATE RESOURCE EFFECTS
		# ====================================================

		"resource_efficiency": 1.0,
		"industrial_resource_modifier": 1.0,
		"military_resource_modifier": 1.0,
		"transport_resource_modifier": 1.0 }
