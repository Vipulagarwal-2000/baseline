class_name DecisionEvaluator
extends RefCounted


func evaluate_option(
	world: WorldState,
	actor,
	option: DecisionOption
) -> float:

	if world == null:
		return 0.0

	if actor == null:
		return 0.0

	if option == null:
		return 0.0

	if not option.is_available():
		option.final_score = -INF
		return option.final_score


	option.goal_score = _evaluate_goals(
		actor,
		option
	)

	option.strategy_score = _evaluate_strategy(
		actor,
		option
	)

	option.relationship_score = _evaluate_relationships(
		world,
		actor,
		option
	)

	option.economic_score = _evaluate_economy(
		actor,
		option
	)

	option.military_score = _evaluate_military(
		actor,
		option
	)

	option.diplomatic_score = _evaluate_diplomacy(
		actor,
		option
	)

	option.risk_score = _evaluate_risk(
		actor,
		option
	)

	option.uncertainty_score = _evaluate_uncertainty(
		option
	)

	# Government structure now influences
	# how feasible an option is.
	#
	# This is deliberately applied as a separate
	# modifier instead of changing the existing
	# scoring dimensions.

	var government_modifier = _evaluate_government(
		actor,
		option
	)

	var base_score = option.calculate_final_score()

	return base_score + government_modifier


# ============================================================
# GOALS
# ============================================================

func _evaluate_goals(
	actor,
	option: DecisionOption
) -> float:

	if actor == null:

		return 0.0


	var goals = actor.goals


	if typeof(goals) != TYPE_ARRAY:

		return 0.0


	var score = 0.0


	for goal in goals:

		if goal == null:

			continue


		if not goal is SimGoal:

			continue


		if not goal.is_active():

			continue


		if goal.is_completed():

			continue


		var relevance = _get_goal_relevance(
			goal,
			option
		)


		var effective_priority = (
			goal.priority
		)


		# ----------------------------------------------------
		# Dynamic goal priority
		#
		# GoalSystem stores situation-dependent modifiers
		# separately from the base goal priority.
		# ----------------------------------------------------

		var dynamic_priorities = actor.get_sim_metadata(
			"goal_dynamic_priorities",
			{}
		)


		if typeof(dynamic_priorities) == TYPE_DICTIONARY:

			effective_priority += float(
				dynamic_priorities.get(
					goal.id,
					0.0
				)
			)


		effective_priority = clamp(
			effective_priority,
			0.0,
			1.0
		)


		score += (
			effective_priority
			* goal.importance
			* relevance
		)


	return score


func _get_goal_relevance(
	goal,
	option: DecisionOption
) -> float:

	if goal == null:
		return 0.0

	if option == null:
		return 0.0

	if option.metadata.has("goal_relevance"):

		var relevance_data = (
			option.metadata["goal_relevance"]
		)

		if typeof(relevance_data) == TYPE_DICTIONARY:

			return float(
				relevance_data.get(
					goal.id,
					0.0
				)
			)

	if goal.goal_type == option.action_type:
		return 1.0

	return 0.1


# ============================================================
# STRATEGY
# ============================================================

func _evaluate_strategy(
	actor,
	option: DecisionOption
) -> float:

	var profile = actor.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return 0.0

	if not profile is CountryStrategyProfile:
		return 0.0

	var score = 0.0

	match option.action_type:

		"economic":
			score += profile.economic_priority

		"military":
			score += profile.military_priority
			score += profile.military_action_preference

		"diplomatic":
			score += profile.diplomatic_priority
			score += profile.negotiation_preference

		"technology":
			score += profile.technology_priority

		"resource":
			score += profile.resource_security_priority

		"influence":
			score += profile.influence_priority

		_:
			score += (
				profile.long_term_planning
				* 0.25
			)

	return score


# ============================================================
# RELATIONSHIPS
# ============================================================

func _evaluate_relationships(
	world: WorldState,
	actor,
	option: DecisionOption
) -> float:

	if option.target_id.is_empty():
		return 0.0

	var relationship = actor.get_relationship(
		option.target_id,
		0.0
	)

	var normalized = (
		relationship + 100.0
	) / 200.0

	return normalized


# ============================================================
# ECONOMY
# ============================================================

func _evaluate_economy(
	actor,
	option: DecisionOption
) -> float:

	var economy = actor.get_component(
		"economy"
	)

	if economy == null:
		return 0.0

	var gdp = float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	if gdp <= 0.0:
		return 0.0

	if option.action_type == "economic":
		return 0.5

	return 0.0


# ============================================================
# MILITARY
# ============================================================

func _evaluate_military(
	actor,
	option: DecisionOption
) -> float:

	if actor == null:
		return 0.0

	if option == null:
		return 0.0

	if option.action_type != "military":
		return 0.0

	# ========================================================
	# STRATEGIC PROFILE
	# ========================================================

	var profile = actor.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return 0.0

	if not profile is CountryStrategyProfile:
		return 0.0

	var military_priority = clamp(
		profile.military_priority,
		0.0,
		1.0
	)

	var military_action_preference = clamp(
		profile.military_action_preference,
		0.0,
		1.0
	)


	# ========================================================
	# DYNAMIC MILITARY STRATEGY SIGNAL
	# ========================================================

	var strategy_signal = actor.get_sim_metadata(
		"military_strategy_signal",
		{}
	)

	if typeof(strategy_signal) != TYPE_DICTIONARY:
		strategy_signal = {}

	var military_priority_signal = clamp(
		float(
			strategy_signal.get(
				"military_priority_signal",
				0.0
			)
		),
		0.0,
		1.0
	)

	var defensive_need = clamp(
		float(
			strategy_signal.get(
				"defensive_need",
				0.0
			)
		),
		0.0,
		1.0
	)

	var projection_opportunity = clamp(
		float(
			strategy_signal.get(
				"projection_opportunity",
				0.0
			)
		),
		0.0,
		1.0
	)


	# ========================================================
	# MILITARY DECISION SCORE
	# ========================================================
	#
	# Persistent strategy remains important, but current
	# military conditions now influence the decision.
	#
	# Personality:
	#   military priority + military action preference
	#
	# Current situation:
	#   overall military priority signal
	#   defensive need
	#   projection opportunity
	#
	# The dynamic signal is deliberately moderate so that
	# military conditions do not completely override goals,
	# relationships, economy, government or risk.
	# ========================================================

	var score = (
		military_priority * 0.30
		+ military_action_preference * 0.20
		+ military_priority_signal * 0.25
		+ defensive_need * 0.15
		+ projection_opportunity * 0.10
	)

	return clamp(
		score,
		0.0,
		1.0
	)
# ============================================================
# DIPLOMACY
# ============================================================

func _evaluate_diplomacy(
	actor,
	option: DecisionOption
) -> float:

	if option.action_type != "diplomatic":
		return 0.0

	var profile = actor.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return 0.0

	if not profile is CountryStrategyProfile:
		return 0.0

	return profile.diplomatic_priority


# ============================================================
# RISK
# ============================================================

func _evaluate_risk(
	actor,
	option: DecisionOption
) -> float:

	var profile = actor.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return 0.0

	if not profile is CountryStrategyProfile:
		return 0.0

	var risk_tolerance = profile.risk_tolerance

	if option.metadata.has("risk"):

		var risk = float(
			option.metadata["risk"]
		)

		return risk_tolerance - risk

	return risk_tolerance * 0.25


# ============================================================
# UNCERTAINTY
# ============================================================

func _evaluate_uncertainty(
	option: DecisionOption
) -> float:

	if option == null:
		return 0.0

	if not option.metadata.has(
		"uncertainty"
	):
		return 0.0

	var uncertainty = float(
		option.metadata["uncertainty"]
	)

	return -uncertainty


# ============================================================
# GOVERNMENT
# ============================================================

func _evaluate_government(
	actor,
	option: DecisionOption
) -> float:

	if actor == null:
		return 0.0

	var government = actor.get_component(
		"government"
	)

	if government == null:
		return 0.0


	# --------------------------------------------------------
	# GOVERNMENT STATE
	# --------------------------------------------------------

	var policy_capacity = float(
		government.get_state(
			"policy_capacity",
			0.50
		)
	)

	var political_pressure = float(
		government.get_state(
			"political_pressure",
			0.30
		)
	)

	var institutional_strength = float(
		government.get_state(
			"institutional_strength",
			0.50
		)
	)

	var bureaucratic_capacity = float(
		government.get_state(
			"bureaucratic_capacity",
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


	# --------------------------------------------------------
	# GENERAL IMPLEMENTATION CAPACITY
	# --------------------------------------------------------

	var implementation_capacity = (
		policy_capacity * 0.40
		+ institutional_strength * 0.20
		+ bureaucratic_capacity * 0.20
		+ executive_strength * 0.10
		+ mobilization_capacity * 0.10
	)


	# --------------------------------------------------------
	# ACTION-SPECIFIC GOVERNMENT EFFECT
	# --------------------------------------------------------

	var action_fit = 0.0

	match option.action_type:

		"economic":

			action_fit = (
				implementation_capacity * 0.60
				+ reform_flexibility * 0.40
			)

		"military":

			action_fit = (
				mobilization_capacity * 0.50
				+ executive_strength * 0.20
				+ policy_capacity * 0.20
				+ institutional_strength * 0.10
			)

		"diplomatic":

			action_fit = (
				policy_capacity * 0.40
				+ institutional_strength * 0.25
				+ executive_strength * 0.15
				+ reform_flexibility * 0.20
			)

		"technology":

			action_fit = (
				bureaucratic_capacity * 0.30
				+ policy_capacity * 0.30
				+ institutional_strength * 0.20
				+ reform_flexibility * 0.20
			)

		"resource":

			action_fit = (
				bureaucratic_capacity * 0.35
				+ policy_capacity * 0.35
				+ mobilization_capacity * 0.15
				+ institutional_strength * 0.15
			)

		"influence":

			action_fit = (
				policy_capacity * 0.35
				+ executive_strength * 0.20
				+ institutional_strength * 0.20
				+ bureaucratic_capacity * 0.25
			)

		_:

			action_fit = implementation_capacity


	# --------------------------------------------------------
	# DOMESTIC POLITICAL COST
	# --------------------------------------------------------

	# Higher political pressure makes major actions
	# harder to sustain.
	#
	# Legislative constraint also matters because actions
	# requiring broad policy implementation are harder when
	# institutional checks are strong.

	var political_cost = (
		political_pressure * 0.60
		+ legislative_constraint * 0.20
		+ (1.0 - reform_flexibility) * 0.20
	)


	# --------------------------------------------------------
	# FINAL GOVERNMENT MODIFIER
	# --------------------------------------------------------

	var feasibility = (
		action_fit
		- political_cost
	)

	# Keep the government contribution deliberately modest.
	# Government should influence decisions without
	# completely overriding goals and strategy.

	return feasibility * 0.50
