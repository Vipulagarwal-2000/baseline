class_name CountryStrategySystem
extends SimulationSystem


func _init():
	super("country_strategy_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("CountryStrategySystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		_ensure_strategy_profile(entity)
		_update_military_strategy_signal(entity)


func _ensure_strategy_profile(entity) -> void:
	if entity == null:
		return

	var existing_profile = entity.get_sim_metadata(
		"strategy_profile",
		null
	)

	if existing_profile != null:
		return

	var profile = CountryStrategyProfile.new(
		entity.id
	)

	# ============================================================
	# DEFAULT PRIORITIES
	# ============================================================

	profile.economic_priority = 0.5
	profile.military_priority = 0.5
	profile.diplomatic_priority = 0.5
	profile.technology_priority = 0.5
	profile.domestic_stability_priority = 0.5
	profile.resource_security_priority = 0.5
	profile.influence_priority = 0.5

	# ============================================================
	# DEFAULT BEHAVIOUR
	# ============================================================

	profile.risk_tolerance = 0.5
	profile.cooperation_preference = 0.5
	profile.negotiation_preference = 0.5
	profile.military_action_preference = 0.5
	profile.economic_pressure_preference = 0.5

	# ============================================================
	# DEFAULT STRATEGIC ORIENTATION
	# ============================================================

	profile.expansionism = 0.0
	profile.defensive_orientation = 0.5
	profile.long_term_planning = 0.5

	entity.set_sim_metadata(
		"strategy_profile",
		profile
	)


func _update_military_strategy_signal(entity) -> void:
	if entity == null:
		return

	var military = entity.get_component("military")

	if military == null:
		entity.set_sim_metadata(
			"military_strategy_signal",
			{}
		)
		return

	# ============================================================
	# CURRENT MILITARY STATE
	# ============================================================

	var military_power = clamp(
		float(military.get_state("military_power", 0.0)),
		0.0,
		1.0
	)

	var readiness = clamp(
		float(military.get_state("readiness", 0.0)),
		0.0,
		1.0
	)

	var manpower = clamp(
		float(military.get_state("manpower", 0.0)),
		0.0,
		1.0
	)

	var logistics_capacity = clamp(
		float(military.get_state("logistics_capacity", 0.0)),
		0.0,
		1.0
	)

	var defensive_capability = clamp(
		float(military.get_state("defensive_capability", 0.0)),
		0.0,
		1.0
	)

	var power_projection = clamp(
		float(military.get_state("power_projection", 0.0)),
		0.0,
		1.0
	)

	var mobilization_capacity = clamp(
		float(military.get_state("mobilization_capacity", 0.0)),
		0.0,
		1.0
	)

	var military_pressure = clamp(
		float(military.get_state("military_pressure", 0.0)),
		0.0,
		1.0
	)

	var war_exhaustion = clamp(
		float(military.get_state("war_exhaustion", 0.0)),
		0.0,
		1.0
	)

	var at_war = bool(
		military.get_state("at_war", false)
	)

	# ============================================================
	# MILITARY CAPABILITY SIGNAL
	#
	# Represents how much usable military capacity the country
	# currently has available.
	# ============================================================

	var capability_signal = (
		military_power * 0.30
		+ readiness * 0.20
		+ logistics_capacity * 0.15
		+ defensive_capability * 0.15
		+ power_projection * 0.10
		+ mobilization_capacity * 0.10
	)

	capability_signal = clamp(
		capability_signal,
		0.0,
		1.0
	)

	# ============================================================
	# MILITARY STRAIN SIGNAL
	#
	# High pressure, war exhaustion and active war increase
	# the strategic importance of military conditions.
	# ============================================================

	var strain_signal = (
		military_pressure * 0.50
		+ war_exhaustion * 0.30
		+ (0.20 if at_war else 0.0)
	)

	strain_signal = clamp(
		strain_signal,
		0.0,
		1.0
	)

	# ============================================================
	# DEFENSIVE NEED
	#
	# Weak defensive capability combined with military pressure
	# creates a stronger defensive strategic signal.
	# ============================================================

	var defensive_need = (
		(1.0 - defensive_capability) * 0.45
		+ military_pressure * 0.35
		+ war_exhaustion * 0.20
	)

	defensive_need = clamp(
		defensive_need,
		0.0,
		1.0
	)

	# ============================================================
	# POWER PROJECTION OPPORTUNITY
	#
	# Represents the country's current ability to project force.
	# This is an opportunity signal, not a decision to use force.
	# ============================================================

	var projection_opportunity = (
		power_projection * 0.45
		+ readiness * 0.20
		+ logistics_capacity * 0.15
		+ mobilization_capacity * 0.20
	)

	projection_opportunity = clamp(
		projection_opportunity,
		0.0,
		1.0
	)

	# ============================================================
	# OVERALL MILITARY STRATEGIC SIGNAL
	# ============================================================

	var military_priority_signal = (
		capability_signal * 0.35
		+ strain_signal * 0.35
		+ defensive_need * 0.20
		+ projection_opportunity * 0.10
	)

	military_priority_signal = clamp(
		military_priority_signal,
		0.0,
		1.0
	)

	# ============================================================
	# STORE DYNAMIC SIGNALS
	# ============================================================

	var signal_data: Dictionary = {
		"capability_signal": capability_signal,
		"strain_signal": strain_signal,
		"defensive_need": defensive_need,
		"projection_opportunity": projection_opportunity,
		"military_priority_signal": military_priority_signal,
		"military_power": military_power,
		"readiness": readiness,
		"manpower": manpower,
		"logistics_capacity": logistics_capacity,
		"defensive_capability": defensive_capability,
		"power_projection": power_projection,
		"mobilization_capacity": mobilization_capacity,
		"military_pressure": military_pressure,
		"war_exhaustion": war_exhaustion,
		"at_war": at_war
	}

	entity.set_sim_metadata(
		"military_strategy_signal",
		signal_data
	)


func get_strategy_profile(entity):

	if entity == null:
		return null

	var profile = entity.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return null

	if not profile is CountryStrategyProfile:
		return null

	return profile


func get_military_strategy_signal(entity) -> Dictionary:

	if entity == null:
		return {}

	var signal_data = entity.get_sim_metadata(
		"military_strategy_signal",
		{}
	)

	if typeof(signal_data) != TYPE_DICTIONARY:
		return {}

	return signal_data


func get_military_strategy_value(
	entity,
	signal_name: String
) -> float:

	var signal_data = get_military_strategy_signal(
		entity
	)

	return clamp(
		float(signal_data.get(signal_name, 0.0)),
		0.0,
		1.0
	)


func set_priority(
	entity,
	priority_name: String,
	value: float
) -> bool:

	var profile = get_strategy_profile(
		entity
	)

	if profile == null:
		return false

	profile.set_priority(
		priority_name,
		value
	)

	return true


func get_priority(
	entity,
	priority_name: String
) -> float:

	var profile = get_strategy_profile(
		entity
	)

	if profile == null:
		return 0.0

	return profile.get_priority(
		priority_name
	)


func set_behavior(
	entity,
	behavior_name: String,
	value: float
) -> bool:

	var profile = get_strategy_profile(
		entity
	)

	if profile == null:
		return false

	profile.set_behavior(
		behavior_name,
		value
	)

	return true


func get_behavior(
	entity,
	behavior_name: String
) -> float:

	var profile = get_strategy_profile(
		entity
	)

	if profile == null:
		return 0.0

	return profile.get_behavior(
		behavior_name
	)
