class_name GovernmentSystem
extends SimulationSystem


func _init():
	super("government_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component(
			"government"
		)

		if government == null:
			continue

		_update_government(
			entity,
			government
		)


func _update_government(
	entity: SimEntity,
	government: GovernmentComponent
) -> void:

	var stability = float(
		government.get_state(
			"stability",
			0.70
		)
	)

	var approval = float(
		government.get_state(
			"approval",
			0.60
		)
	)

	var pressure = float(
		government.get_state(
			"political_pressure",
			0.30
		)
	)

	# Preserve previous-month values.

	government.set_state(
		"previous_stability",
		stability
	)

	government.set_state(
		"previous_approval",
		approval
	)

	government.set_state(
		"previous_pressure",
		pressure
	)


	# ====================================================
	# GOVERNMENT STRUCTURAL PARAMETERS
	# ====================================================

	var institutional_strength = float(
		government.get_state(
			"institutional_strength",
			0.50
		)
	)

	var legitimacy = float(
		government.get_state(
			"legitimacy",
			0.60
		)
	)

	var corruption = float(
		government.get_state(
			"corruption",
			0.30
		)
	)

	var centralization = float(
		government.get_state(
			"centralization",
			0.50
		)
	)

	var political_freedom = float(
		government.get_state(
			"political_freedom",
			0.50
		)
	)

	var executive_strength = float(
		government.get_state(
			"executive_strength",
			0.50
		)
	)

	var legislative_constraint = float(
		government.get_state(
			"legislative_constraint",
			0.50
		)
	)

	var electoral_competition = float(
		government.get_state(
			"electoral_competition",
			0.50
		)
	)

	var party_control = float(
		government.get_state(
			"party_control",
			0.50
		)
	)

	var bureaucratic_capacity = float(
		government.get_state(
			"bureaucratic_capacity",
			0.50
		)
	)

	var military_civilian_control = float(
		government.get_state(
			"military_civilian_control",
			0.50
		)
	)

	var reform_flexibility = float(
		government.get_state(
			"reform_flexibility",
			0.50
		)
	)

	var mobilization_capacity = float(
		government.get_state(
			"mobilization_capacity",
			0.50
		)
	)

	var political_pluralism = float(
		government.get_state(
			"political_pluralism",
			0.50
		)
	)

	var regional_autonomy = float(
		government.get_state(
			"regional_autonomy",
			0.50
		)
	)


	# ====================================================
	# ECONOMIC SIGNAL
	# ====================================================

	var economic_signal = _get_economic_signal(
		entity
	)


	# ====================================================
	# DIPLOMATIC SIGNAL
	# ====================================================

	var diplomatic_signal = _get_diplomatic_signal(
		entity,
		government
	)

	# Step 17.1 — publish the derived diplomatic feedback signal so
	# downstream systems and tests can observe the consequence produced
	# by the registered relationship state.
	government.set_state(
		"diplomatic_signal",
		diplomatic_signal
	)


	# ====================================================
	# MILITARY SIGNAL
	# ====================================================

	var military_burden = _get_military_burden(
		entity
	)

	government.set_state(
		"military_burden",
		military_burden
	)


	# ====================================================
	# POLITICAL PRESSURE
	# ====================================================

	var economic_pressure = clamp(
		-economic_signal,
		0.0,
		1.0
	)

	var competition_pressure = (
		electoral_competition
		* 0.25
	)

	var pluralism_pressure = (
		political_pluralism
		* 0.10
	)

	var centralization_relief = (
		centralization
		* 0.10
	)

	var diplomatic_pressure = (
		-diplomatic_signal
		* 0.10
	)

	var military_pressure_signal = (
		military_burden
		* 0.12
	)

	var target_pressure = clamp(
		0.30
		+ economic_pressure * 0.35
		+ competition_pressure
		+ pluralism_pressure
		+ diplomatic_pressure
		+ military_pressure_signal
		- centralization_relief,
		0.0,
		1.0
	)

	pressure = lerp(
		pressure,
		target_pressure,
		0.10
	)


	# ====================================================
	# POLICY CAPACITY
	# ====================================================

	var policy_capacity = clamp(
		(
			institutional_strength * 0.20
			+ executive_strength * 0.15
			+ bureaucratic_capacity * 0.20
			+ centralization * 0.15
			+ party_control * 0.10
			+ mobilization_capacity * 0.10
			+ military_civilian_control * 0.05
			+ reform_flexibility * 0.05
		),
		0.0,
		1.0
	)

	government.set_state(
		"policy_capacity",
		policy_capacity
	)


	# ====================================================
	# STABILITY
	# ====================================================

	var stability_change = (

		economic_signal
		* 0.020

		+ diplomatic_signal
		* 0.008

		+ (
			institutional_strength
			- 0.50
		)
		* 0.015

		+ (
			legitimacy
			- 0.50
		)
		* 0.015

		+ (
			bureaucratic_capacity
			- 0.50
		)
		* 0.010

		+ (
			military_civilian_control
			- 0.50
		)
		* 0.005

		- (
			corruption
			- 0.30
		)
		* 0.010

		- (
			pressure
			- 0.30
		)
		* 0.015

		- (
			legislative_constraint
			- 0.50
		)
		* 0.005

		- military_burden
		* 0.008
	)


	# Strong institutional systems are less sensitive
	# to short-term political pressure.

	var institutional_buffer = (
		institutional_strength
		* 0.50
	)

	stability_change *= (
		1.0
		- institutional_buffer * 0.20
	)

	stability = clamp(
		stability + stability_change,
		0.0,
		1.0
	)


	# ====================================================
	# APPROVAL
	# ====================================================

	var approval_change = (

		(
			stability
			- 0.50
		)
		* 0.010

		+ economic_signal
		* 0.010

		+ diplomatic_signal
		* 0.004

		+ (
			legitimacy
			- 0.50
		)
		* 0.005

		+ (
			political_freedom
			- 0.50
		)
		* 0.003

		- (
			pressure
			- 0.30
		)
		* 0.005

		- (
			corruption
			- 0.30
		)
		* 0.005

		- military_burden
		* 0.004
	)

	approval = clamp(
		approval + approval_change,
		0.0,
		1.0
	)


	# ====================================================
	# STORE UPDATED STATE
	# ====================================================

	government.set_state(
		"stability",
		stability
	)

	government.set_state(
		"approval",
		approval
	)

	government.set_state(
		"political_pressure",
		pressure
	)

	government.set_state(
		"institutional_strength",
		institutional_strength
	)

	government.set_state(
		"legitimacy",
		legitimacy
	)

	government.set_state(
		"corruption",
		corruption
	)

	government.set_state(
		"centralization",
		centralization
	)

	government.set_state(
		"political_freedom",
		political_freedom
	)

	government.set_state(
		"executive_strength",
		executive_strength
	)

	government.set_state(
		"legislative_constraint",
		legislative_constraint
	)

	government.set_state(
		"electoral_competition",
		electoral_competition
	)

	government.set_state(
		"party_control",
		party_control
	)

	government.set_state(
		"bureaucratic_capacity",
		bureaucratic_capacity
	)

	government.set_state(
		"military_civilian_control",
		military_civilian_control
	)

	government.set_state(
		"reform_flexibility",
		reform_flexibility
	)

	government.set_state(
		"mobilization_capacity",
		mobilization_capacity
	)

	government.set_state(
		"political_pluralism",
		political_pluralism
	)

	government.set_state(
		"regional_autonomy",
		regional_autonomy
	)


# ========================================================
# MILITARY BURDEN
# ========================================================

func _get_military_burden(
	entity: SimEntity
) -> float:

	var military = entity.get_component(
		"military"
	)

	if military == null:
		return 0.0

	var military_pressure = clamp(
		float(
			military.get_state(
				"military_pressure",
				0.20
			)
		),
		0.0,
		1.0
	)

	var war_exhaustion = clamp(
		float(
			military.get_state(
				"war_exhaustion",
				0.0
			)
		),
		0.0,
		1.0
	)

	var at_war = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	var war_signal = 0.20 if at_war else 0.0

	var burden = (
		military_pressure * 0.45
		+ war_exhaustion * 0.35
		+ war_signal
	)

	return clamp(
		burden,
		0.0,
		1.0
	)


# ========================================================
# DIPLOMATIC SIGNAL
# ========================================================

func _get_diplomatic_signal(
	entity: SimEntity,
	government: GovernmentComponent
) -> float:

	var relationships = entity.get_all_relationships()

	if relationships.is_empty():
		return 0.0

	var total_change = 0.0
	var relationship_count = 0

	for target_id in relationships.keys():

		var current_value = entity.get_relationship(
			str(target_id),
			0.0
		)

		var previous_key = (
			"previous_relationship_"
			+ str(target_id)
		)

		var previous_value = float(
			government.get_state(
				previous_key,
				current_value
			)
		)

		var change = current_value - previous_value

		total_change += clamp(
			change / 100.0,
			-1.0,
			1.0
		)

		relationship_count += 1

		government.set_state(
			previous_key,
			current_value
		)

	if relationship_count <= 0:
		return 0.0

	return clamp(
		total_change / float(relationship_count),
		-1.0,
		1.0
	)


# ========================================================
# ECONOMIC SIGNAL
# ========================================================

func _get_economic_signal(
	entity: SimEntity
) -> float:

	var economy = entity.get_component(
		"economy"
	)

	if economy == null:
		return 0.0

	var growth_rate = float(
		economy.get_state(
			"growth_rate",
			0.0
		)
	)

	var unemployment = float(
		economy.get_state(
			"unemployment",
			0.0
		)
	)

	var inflation = float(
		economy.get_state(
			"inflation",
			0.0
		)
	)

	var growth_signal = clamp(
		growth_rate / 5.0,
		-1.0,
		1.0
	)

	var unemployment_signal = clamp(
		-unemployment / 10.0,
		-1.0,
		0.0
	)

	var inflation_signal = clamp(
		-inflation / 10.0,
		-1.0,
		0.0
	)

	return (
		growth_signal * 0.50
		+ unemployment_signal * 0.30
		+ inflation_signal * 0.20
	)
