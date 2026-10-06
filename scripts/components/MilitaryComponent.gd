class_name MilitaryComponent
extends SimComponent


func _init(owner_id_value: String):
	super(
		"military",
		owner_id_value
	)

	# ============================================================
	# CORE MILITARY CAPABILITY
	# ============================================================

	set_state("military_power", 0.50)
	set_state("readiness", 0.60)
	set_state("manpower", 0.50)
	set_state("logistics_capacity", 0.50)

	# ============================================================
	# FORCE STRUCTURE
	# ============================================================

	set_state("army_strength", 0.50)
	set_state("naval_strength", 0.30)
	set_state("air_strength", 0.20)

	# ============================================================
	# SUPPORT CAPABILITIES
	# ============================================================

	set_state("industrial_support", 0.50)
	set_state("military_technology", 0.30)
	set_state("command_capacity", 0.50)

	# ============================================================
	# RESOURCE SUPPORT
	# ============================================================

	set_state("resource_security", 0.50)

	# ============================================================
	# STEP 13.3 — TRANSPORT / LOGISTICS SUPPORT
	# ============================================================

	set_state("transport_logistics_modifier", 1.00)
	set_state("transport_logistics_constraint", 0.00)
	set_state("transport_infrastructure_factor", 1.00)
	set_state("transport_node_factor", 1.00)
	set_state("transport_route_factor", 1.00)
	set_state("transport_cost_factor", 1.00)
	set_state("transport_network_factor", 1.00)
	set_state(
		"transport_logistics_source",
		"neutral"
	)

	# ============================================================
	# STEP 13.4 — PORT / NAVAL LOGISTICS SUPPORT
	# ============================================================

	set_state("naval_logistics_modifier", 1.00)
	set_state("naval_logistics_constraint", 0.00)
	set_state("naval_port_capacity_factor", 1.00)
	set_state("naval_country_port_factor", 1.00)
	set_state("naval_regional_port_factor", 1.00)
	set_state("effective_naval_strength", 0.30)
	set_state(
		"naval_logistics_source",
		"neutral"
	)

	# ============================================================
	# STEP 13.5 — POWER / MILITARY INFRASTRUCTURE SUPPORT
	# ============================================================

	set_state("military_infrastructure_modifier", 1.00)
	set_state("military_infrastructure_constraint", 0.00)
	set_state("military_infrastructure_power_factor", 1.00)
	set_state(
		"military_infrastructure_source",
		"neutral"
	)
	set_state("effective_command_capacity", 0.50)

	# ============================================================
	# STEP 13.6 — MILITARY DEMAND / RESOURCE CONSUMPTION
	# ============================================================

	set_state("resource_demand_activity_index", 0.30)
	set_state("resource_demand_war_multiplier", 1.00)
	set_state("resource_demand_total", 0.00)
	set_state("resource_demand_by_resource", {})
	set_state(
		"resource_demand_source",
		"neutral"
	)

	# ============================================================
	# STEP 13.7 — MILITARY / ECONOMIC PRESSURE
	# ============================================================

	set_state("military_economic_burden", 0.0)
	set_state("military_economic_pressure", 0.0)
	set_state(
		"military_economic_pressure_source",
		"neutral"
	)

	# ============================================================
	# STRATEGIC STATE
	# ============================================================

	set_state("defensive_capability", 0.50)
	set_state("power_projection", 0.30)
	set_state("mobilization_capacity", 0.50)

	# ============================================================
	# COST / PRESSURE
	# ============================================================

	set_state("military_spending", 0.30)
	set_state("military_pressure", 0.20)

	# ============================================================
	# CONFLICT STATE
	# ============================================================

	set_state("at_war", false)
	set_state("war_exhaustion", 0.00)

	# ============================================================
	# TRACK PREVIOUS STATE
	# ============================================================

	set_state("previous_readiness", 0.60)
	set_state("previous_military_power", 0.50)
	set_state("previous_war_exhaustion", 0.00)
	set_state("previous_resource_security", 0.50)
