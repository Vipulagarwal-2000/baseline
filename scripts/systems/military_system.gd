class_name MilitarySystem
extends SimulationSystem


func _init():
	super("military_system")


func process_month(world: WorldState) -> void:

	if world == null:

		push_error(
			"MilitarySystem: World is null."
		)

		return


	for entity in world.entities.values():

		if entity == null:
			continue

		var military = entity.get_component(
			"military"
		)

		if military == null:
			continue

		_update_military(
			entity,
			military
		)


func _update_military(
	entity,
	military
) -> void:

	# ============================================================
	# PREVIOUS STATE
	# ============================================================

	var previous_readiness = float(
		military.get_state(
			"readiness",
			0.60
		)
	)

	var previous_power = float(
		military.get_state(
			"military_power",
			0.50
		)
	)

	var previous_exhaustion = float(
		military.get_state(
			"war_exhaustion",
			0.00
		)
	)

	var previous_resource_security = float(
		military.get_state(
			"resource_security",
			0.50
		)
	)


	military.set_state(
		"previous_readiness",
		previous_readiness
	)

	military.set_state(
		"previous_military_power",
		previous_power
	)

	military.set_state(
		"previous_war_exhaustion",
		previous_exhaustion
	)

	military.set_state(
		"previous_resource_security",
		previous_resource_security
	)


	# ============================================================
	# BASE MILITARY VALUES
	# ============================================================

	var manpower = clamp(
		float(
			military.get_state(
				"manpower",
				0.50
			)
		),
		0.0,
		1.0
	)

	var logistics = clamp(
		float(
			military.get_state(
				"logistics_capacity",
				0.50
			)
		),
		0.0,
		1.0
	)

	var army = clamp(
		float(
			military.get_state(
				"army_strength",
				0.50
			)
		),
		0.0,
		1.0
	)

	var navy = clamp(
		float(
			military.get_state(
				"naval_strength",
				0.30
			)
		),
		0.0,
		1.0
	)

	var air = clamp(
		float(
			military.get_state(
				"air_strength",
				0.20
			)
		),
		0.0,
		1.0
	)

	var military_technology = clamp(
		float(
			military.get_state(
				"military_technology",
				0.30
			)
		),
		0.0,
		1.0
	)

	var command_capacity = clamp(
		float(
			military.get_state(
				"command_capacity",
				0.50
			)
		),
		0.0,
		1.0
	)

	var industrial_support = clamp(
		float(
			military.get_state(
				"industrial_support",
				0.50
			)
		),
		0.0,
		1.0
	)


	# ============================================================
	# POPULATION → MANPOWER
	# ============================================================

	var population_component = entity.get_component(
		"population"
	)

	if population_component != null:

		var population = float(
			population_component.get_state(
				"population",
				0.0
			)
		)

		var population_manpower = clamp(
			population / 600000000.0,
			0.0,
			1.0
		)

		manpower = lerp(
			manpower,
			population_manpower,
			0.10
		)

		military.set_state(
			"manpower",
			manpower
		)


	manpower = clamp(
		float(
			military.get_state(
				"manpower",
				manpower
			)
		),
		0.0,
		1.0
	)


	# ============================================================
	# ECONOMY → INDUSTRIAL SUPPORT
	# ECONOMY → LOGISTICS
	# ============================================================

	var economy = entity.get_component(
		"economy"
	)

	if economy != null:

		var gdp = float(
			economy.get_state(
				"gdp",
				0.0
			)
		)

		var economic_capacity = clamp(
			gdp / 1500000000000.0,
			0.0,
			1.0
		)

		# ============================================================
		# STEP 13.1 — PRODUCTION → MILITARY CAPACITY
		# ============================================================
		#
		# MilitaryProductionCapacitySystem derives a bounded modifier
		# from the authoritative industry/production state.
		# Default = 1.0 so the legacy military path remains unchanged
		# when Step 13.1 is not installed or no production signal exists.
		#
		# Production acts as a constraint on economy-supported military
		# industrial capacity; this does not create a second military power
		# formula.
		# ============================================================

		var production_capacity_modifier: float = clampf(
			float(
				military.get_state(
					"production_capacity_modifier",
					1.0
				)
			),
			0.0,
			1.0
		)

		var production_adjusted_economic_capacity: float = clampf(
			economic_capacity * production_capacity_modifier,
			0.0,
			1.0
		)

		industrial_support = lerp(
			industrial_support,
			production_adjusted_economic_capacity,
			0.05
		)

		logistics = lerp(
			logistics,
			economic_capacity,
			0.05
		)

		military.set_state(
			"industrial_support",
			industrial_support
		)

		military.set_state(
			"logistics_capacity",
			logistics
		)


	# ============================================================
	# RESEARCH → MILITARY TECHNOLOGY
	# ============================================================

	var research = entity.get_component(
		"research"
	)

	var technology_adoption = entity.get_component(
		"technology_adoption"
	)

	if research != null:

		var research_technology_level = float(
			research.get_state(
				"technology_level",
				0.0
			)
		)

		var research_maturity = clamp(
			research_technology_level / 40.0,
			0.0,
			1.0
		)

		var adoption_factor = 0.0
		var adoption_count = 0

		if technology_adoption != null:

			var completed_technologies = research.get_state(
				"technologies",
				{}
			)

			if typeof(
				completed_technologies
			) == TYPE_DICTIONARY:

				for technology_id in completed_technologies.keys():

					if not bool(
						completed_technologies[
							technology_id
						]
					):
						continue

					var adoption_value = (
						technology_adoption.get_adoption(
							str(technology_id)
						)
					)

					adoption_factor += adoption_value
					adoption_count += 1


		if adoption_count > 0:

			adoption_factor = (
				adoption_factor
				/ float(adoption_count)
			)

		else:

			adoption_factor = 0.0


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


		# --------------------------------------------------------
		# DATA-DRIVEN TECHNOLOGY EFFECTS
		# --------------------------------------------------------
		#
		# TechnologyEffectSystem aggregates completed technology
		# effects into the research component.
		#
		# These effects are intentionally read here rather than
		# hard-coding individual technologies.
		#

		var technology_effects = research.get_state(
			"technology_effects",
			{}
		)

		if typeof(
			technology_effects
		) != TYPE_DICTIONARY:

			technology_effects = {}


		var military_technology_support = clamp(
			float(
				technology_effects.get(
					"military_technology_support",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)


		# Technology effects provide an additional target.
		#
		# Research maturity remains the foundation.
		# Explicit technology effects improve the resulting
		# military technology level.

		research_military_target = clamp(
			research_military_target
			+ military_technology_support * 0.25,
			0.0,
			1.0
		)


		military_technology = lerp(
			military_technology,
			research_military_target,
			0.05
		)

		military.set_state(
			"military_technology",
			clamp(
				military_technology,
				0.0,
				1.0
			)
		)


		# --------------------------------------------------------
		# TECHNOLOGY → INDUSTRIAL SUPPORT
		# --------------------------------------------------------

		var industrial_effect = clamp(
			float(
				technology_effects.get(
					"military_industrial_support",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)

		if industrial_effect > 0.0:

			industrial_support = lerp(
				industrial_support,
				clamp(
					industrial_support
					+ industrial_effect * 0.25,
					0.0,
					1.0
				),
				0.05
			)

			military.set_state(
				"industrial_support",
				industrial_support
			)


		# --------------------------------------------------------
		# TECHNOLOGY → LOGISTICS
		# --------------------------------------------------------

		var logistics_effect = clamp(
			float(
				technology_effects.get(
					"military_logistics_support",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)

		if logistics_effect > 0.0:

			logistics = lerp(
				logistics,
				clamp(
					logistics
					+ logistics_effect * 0.25,
					0.0,
					1.0
				),
				0.05
			)

			military.set_state(
				"logistics_capacity",
				logistics
			)


		# --------------------------------------------------------
		# TECHNOLOGY → COMMAND CAPACITY
		# --------------------------------------------------------

		var command_effect = clamp(
			float(
				technology_effects.get(
					"military_command_capacity",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)

		if command_effect > 0.0:

			command_capacity = lerp(
				command_capacity,
				clamp(
					command_capacity
					+ command_effect * 0.25,
					0.0,
					1.0
				),
				0.05
			)

			military.set_state(
				"command_capacity",
				command_capacity
			)


	# ============================================================
	# RESOURCES → RESOURCE SECURITY
	# RESOURCES → LOGISTICS
	# ============================================================

	var resource_component = entity.get_component(
		"resources"
	)

	var resource_security = 0.50
	var allocation_resource_security_factor = 1.0
	var allocation_security_count = 0

	if resource_component != null:

		var net_balance = resource_component.get_state(
			"net_balance",
			{}
		)

		var consumption = resource_component.get_state(
			"consumption",
			{}
		)

		var military_allocation_value = resource_component.get_state(
			"military_resource_allocation_ratio",
			{}
		)

		if typeof(military_allocation_value) != TYPE_DICTIONARY:
			military_allocation_value = {}

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

			var allocation_ratio = clamp(
				float(
					military_allocation_value.get(
						resource_name,
						1.0
					)
				),
				0.0,
				1.0
			)

			resource_score = min(
				resource_score,
				allocation_ratio
			)

			allocation_resource_security_factor = min(
				allocation_resource_security_factor,
				allocation_ratio
			)

			allocation_security_count += 1
			security_total += resource_score
			security_count += 1


		if security_count > 0:

			resource_security = (
				security_total
				/ float(security_count)
			)


	resource_security = clamp(
		resource_security,
		0.0,
		1.0
	)

	military.set_state(
		"resource_allocation_fulfillment",
		allocation_resource_security_factor
	)

	military.set_state(
		"resource_allocation_shortfall",
		1.0 - allocation_resource_security_factor
	)


	logistics = lerp(
		logistics,
		resource_security,
		0.05
	)


	military.set_state(
		"resource_security",
		resource_security
	)

	military.set_state(
		"logistics_capacity",
		logistics
	)


	# ============================================================
	# STEP 13.2 — RESOURCES → READINESS
	# ============================================================
	#
	# MilitaryResourceReadinessSystem converts the authoritative
	# ResourceSystem military-resource modifier into an explicit
	# readiness constraint. ResourceSystem remains responsible for
	# resource shortage calculation; MilitarySystem remains responsible
	# for the final readiness calculation.
	# ============================================================

	var resource_readiness_modifier: float = clampf(
		float(
			military.get_state(
				"resource_readiness_modifier",
				1.0
			)
		),
		0.0,
		1.0
	)

	var resource_readiness_constraint: float = clampf(
		1.0 - resource_readiness_modifier,
		0.0,
		1.0
	)

	military.set_state(
		"resource_readiness_constraint",
		resource_readiness_constraint
	)


	# ============================================================
	# MILITARY SPENDING
	# ============================================================

	var military_spending = clamp(
		float(
			military.get_state(
				"military_spending",
				0.30
			)
		),
		0.0,
		1.0
	)


	# ============================================================
	# WAR STATE
	# ============================================================

	var at_war = bool(
		military.get_state(
			"at_war",
			false
		)
	)

	var war_exhaustion = clamp(
		float(
			military.get_state(
				"war_exhaustion",
				0.00
			)
		),
		0.0,
		1.0
	)


	# ============================================================
	# GOVERNMENT → MILITARY
	# ============================================================

	var government = entity.get_component(
		"government"
	)

	var government_capacity = 0.50
	var government_mobilization = 0.50
	var government_institutional_strength = 0.50
	var government_political_pressure = 0.30

	if government != null:

		government_capacity = clamp(
			float(
				government.get_state(
					"policy_capacity",
					0.50
				)
			),
			0.0,
			1.0
		)

		government_mobilization = clamp(
			float(
				government.get_state(
					"mobilization_capacity",
					0.50
				)
			),
			0.0,
			1.0
		)

		government_institutional_strength = clamp(
			float(
				government.get_state(
					"institutional_strength",
					0.50
				)
			),
			0.0,
			1.0
		)

		government_political_pressure = clamp(
			float(
				government.get_state(
					"political_pressure",
					0.30
				)
			),
			0.0,
			1.0
		)


	# ------------------------------------------------------------
	# Government → military spending
	#
	# Stronger policy/institutional capacity and mobilization
	# capacity support the ability to sustain military spending.
	# Political pressure constrains that ability.
	# ------------------------------------------------------------

	var government_spending_factor = (
		government_capacity * 0.35
		+ government_institutional_strength * 0.25
		+ government_mobilization * 0.25
		+ (1.0 - government_political_pressure) * 0.15
	)

	government_spending_factor = clamp(
		government_spending_factor,
		0.0,
		1.0
	)

	var government_spending_target = (
		military_spending
		* (
			0.75
			+ government_spending_factor * 0.50
		)
	)

	government_spending_target = clamp(
		government_spending_target,
		0.0,
		1.0
	)

	military_spending = lerp(
		military_spending,
		government_spending_target,
		0.05
	)

	military.set_state(
		"military_spending",
		military_spending
	)

	military.set_state(
		"government_spending_factor",
		government_spending_factor
	)


	# ============================================================
	# READINESS
	# ============================================================

	# ============================================================
	# STEP 13.5 — POWER → MILITARY INFRASTRUCTURE
	# ============================================================

	var military_infrastructure_modifier: float = clampf(
		float(
			military.get_state(
				"military_infrastructure_modifier",
				1.0
			)
		),
		0.0,
		1.0
	)

	var effective_command_capacity: float = clampf(
		command_capacity * military_infrastructure_modifier,
		0.0,
		1.0
	)

	var military_infrastructure_constraint: float = clampf(
		1.0 - military_infrastructure_modifier,
		0.0,
		1.0
	)

	military.set_state(
		"effective_command_capacity",
		effective_command_capacity
	)

	military.set_state(
		"military_infrastructure_constraint",
		military_infrastructure_constraint
	)

	var readiness_target = (
		manpower * 0.20
		+ logistics * 0.18
		+ effective_command_capacity * 0.14
		+ industrial_support * 0.14
		+ military_technology * 0.10
		+ government_capacity * 0.08
		+ government_mobilization * 0.06
		+ 0.10
	)

	readiness_target *= resource_readiness_modifier

	readiness_target -= (
		war_exhaustion
		* 0.10
	)

	readiness_target = clamp(
		readiness_target,
		0.0,
		1.0
	)


	var readiness = lerp(
		previous_readiness,
		readiness_target,
		0.08
	)


	# ============================================================
	# STEP 13.4 — PORTS → NAVAL LOGISTICS
	# ============================================================

	var naval_logistics_modifier: float = clampf(
		float(
			military.get_state(
				"naval_logistics_modifier",
				1.0
			)
		),
		0.0,
		1.0
	)

	var effective_naval_strength: float = clampf(
		navy * naval_logistics_modifier,
		0.0,
		1.0
	)

	military.set_state(
		"effective_naval_strength",
		effective_naval_strength
	)

	# ============================================================
	# MILITARY POWER
	# ============================================================

	var force_structure = (
		army * 0.50
		+ effective_naval_strength * 0.20
		+ air * 0.10
	)

	var support_capacity = (
		manpower * 0.08
		+ logistics * 0.12
		+ industrial_support * 0.10
		+ military_technology * 0.10
		+ effective_command_capacity * 0.10
	)

	var military_power_target = (
		force_structure
		+ support_capacity
	)

	military_power_target -= (
		war_exhaustion
		* 0.08
	)

	military_power_target = clamp(
		military_power_target,
		0.0,
		1.0
	)

	var military_power = lerp(
		previous_power,
		military_power_target,
		0.05
	)


	# ============================================================
	# GEOGRAPHY → MILITARY
	# ============================================================
	#
	# Geography modifies military outcomes without directly
	# changing raw military power.
	#
	# Local geography primarily affects defense.
	# Distance/accessibility primarily affects logistics and
	# power projection.
	#
	# The GeographySystem already provides:
	# - distances[target_id]
	# - relationship shared_border
	# - relationship influence_accessibility
	# - strategic_importance
	# - military_access
	# - military_projection
	#
	# This remains an abstract MVP model. No tactical map,
	# units, or battlefield simulation is introduced here.
	# ============================================================

	var geography = entity.get_component(
		"geography"
	)

	var geographic_defense_modifier = 0.0
	var geographic_logistics_modifier = 0.0
	var geographic_projection_modifier = 1.0

	if geography != null:

		# --------------------------------------------------------
		# Strategic importance
		#
		# Component values use a 0–100 scale.
		# Convert them to the military 0–1 scale.
		# --------------------------------------------------------

		var strategic_importance = clamp(
			float(
				geography.get_state(
					"strategic_importance",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)


		# --------------------------------------------------------
		# Military access
		#
		# Component values use a 0–100 scale.
		# --------------------------------------------------------

		var military_access = clamp(
			float(
				geography.get_state(
					"military_access",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)


		# --------------------------------------------------------
		# Military projection
		#
		# This is a geography-level projection capability.
		# It is kept separate from the military component's
		# resulting power_projection.
		# --------------------------------------------------------

		var geographic_projection = clamp(
			float(
				geography.get_state(
					"military_projection",
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)


		# --------------------------------------------------------
		# Maritime access
		# --------------------------------------------------------

		var maritime_access = bool(
			geography.get_state(
				"maritime_access",
				false
			)
		)


		# --------------------------------------------------------
		# Local geographic defense
		#
		# Strategic position and military access provide a
		# modest local defensive contribution.
		# Maritime access provides a smaller additional
		# contribution because it expands strategic access,
		# but does not automatically mean stronger defense.
		# --------------------------------------------------------

		geographic_defense_modifier = (
			strategic_importance * 0.10
			+ military_access * 0.10
		)

		if maritime_access:
			geographic_defense_modifier += 0.03


		geographic_defense_modifier = clamp(
			geographic_defense_modifier,
			0.0,
			0.20
		)


		# --------------------------------------------------------
		# Home-country logistics
		#
		# Military access improves movement and sustainment.
		# Strategic importance provides a smaller geographic
		# infrastructure/position effect.
		# --------------------------------------------------------

		geographic_logistics_modifier = (
			military_access * 0.10
			+ strategic_importance * 0.05
		)


		geographic_logistics_modifier = clamp(
			geographic_logistics_modifier,
			0.0,
			0.15
		)


		# --------------------------------------------------------
		# Geographic projection
		#
		# If the geography layer has an explicit military
		# projection value, use it as a multiplier.
		# A zero value means no explicit bonus rather than
		# destroying the country's existing projection ability.
		# --------------------------------------------------------

		if geographic_projection > 0.0:

			geographic_projection_modifier = (
				1.0
				+ geographic_projection * 0.20
			)

			geographic_projection_modifier = clamp(
				geographic_projection_modifier,
				1.0,
				1.20
			)


	# ------------------------------------------------------------
	# Apply geography to logistics.
	#
	# Geography is an input to logistics, not a replacement for
	# economic/resource/technology inputs already calculated.
	# ------------------------------------------------------------

	if geographic_logistics_modifier > 0.0:

		logistics = clamp(
			logistics
			+ geographic_logistics_modifier,
			0.0,
			1.0
		)


	military.set_state(
		"geography_logistics_modifier",
		geographic_logistics_modifier
	)


	# ============================================================
	# STEP 13.3 — TRANSPORT → LOGISTICS
	# ============================================================

	var transport_logistics_modifier: float = clampf(
		float(
			military.get_state(
				"transport_logistics_modifier",
				1.0
			)
		),
		0.0,
		1.0
	)

	var transport_logistics_constraint: float = clampf(
		1.0 - transport_logistics_modifier,
		0.0,
		1.0
	)

	logistics *= transport_logistics_modifier

	logistics = clampf(
		logistics,
		0.0,
		1.0
	)

	military.set_state(
		"transport_logistics_constraint",
		transport_logistics_constraint
	)

	military.set_state(
		"logistics_capacity",
		logistics
	)


	# ============================================================
	# DEFENSIVE CAPABILITY
	# ============================================================

	var defensive_capability = (
		military_power * 0.45
		+ readiness * 0.25
		+ logistics * 0.15
		+ manpower * 0.15
		+ geographic_defense_modifier
	)

	defensive_capability = clamp(
		defensive_capability,
		0.0,
		1.0
	)


	# ============================================================
	# POWER PROJECTION
	# ============================================================

	var power_projection = (
		military_power * 0.45
		+ readiness * 0.20
		+ logistics * 0.20
		+ command_capacity * 0.15
	)

	power_projection = (
		power_projection
		* geographic_projection_modifier
	)

	power_projection = clamp(
		power_projection,
		0.0,
		1.0
	)


	# ============================================================
	# MOBILIZATION CAPACITY
	# ============================================================

	var mobilization_capacity = (
		manpower * 0.30
		+ industrial_support * 0.20
		+ command_capacity * 0.15
		+ logistics * 0.15
		+ readiness * 0.10
		+ government_mobilization * 0.10
	)

	mobilization_capacity = clamp(
		mobilization_capacity,
		0.0,
		1.0
	)


	# ============================================================
	# MILITARY PRESSURE
	# ============================================================

	var military_pressure = (
		military_spending * 0.55
		+ military_power * 0.20
		+ readiness * 0.15
		+ war_exhaustion * 0.10
	)

	if at_war:

		military_pressure += 0.05


	military_pressure = clamp(
		military_pressure,
		0.0,
		1.0
	)


	# ============================================================
	# WAR EXHAUSTION
	# ============================================================

	if at_war:

		war_exhaustion += 0.01

	else:

		war_exhaustion -= 0.005


	war_exhaustion = clamp(
		war_exhaustion,
		0.0,
		1.0
	)


	# ============================================================
	# STORE FINAL MILITARY STATE
	# ============================================================

	military.set_state(
		"readiness",
		clamp(
			readiness,
			0.0,
			1.0
		)
	)

	military.set_state(
		"military_power",
		clamp(
			military_power,
			0.0,
			1.0
		)
	)

	military.set_state(
		"defensive_capability",
		defensive_capability
	)

	military.set_state(
		"power_projection",
		power_projection
	)

	military.set_state(
		"mobilization_capacity",
		mobilization_capacity
	)

	military.set_state(
		"military_pressure",
		military_pressure
	)

	military.set_state(
		"war_exhaustion",
		war_exhaustion
	)
