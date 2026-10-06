class_name AIDecisionMaker
extends RefCounted


var decision_evaluator: DecisionEvaluator


func _init():
	decision_evaluator = DecisionEvaluator.new()


func choose_action(
	world: WorldState,
	actor,
	options: Array
):

	if world == null:
		return null

	if actor == null:
		return null

	if options.is_empty():
		return null

	var valid_options: Array = []

	for option in options:

		if option == null:
			continue

		if not option is DecisionOption:
			continue

		if not option.is_available():
			continue

		var score = decision_evaluator.evaluate_option(
			world,
			actor,
			option
		)

		var uncertainty = AIUncertainty.calculate_uncertainty(
			actor,
			option
		)

		var risk_tolerance = 0.5

		var profile = actor.get_sim_metadata(
			"strategy_profile",
			null
		)

		if profile != null:
			if profile is CountryStrategyProfile:
				risk_tolerance = profile.risk_tolerance

		option.uncertainty_score = (
			AIUncertainty.apply_uncertainty(
				score,
				uncertainty,
				risk_tolerance
			)
		)

		option.final_score = option.uncertainty_score

		valid_options.append(option)

	if valid_options.is_empty():
		return null

	valid_options.sort_custom(
		_compare_options
	)

	return _select_from_ranked_options(
		actor,
		valid_options
	)


func _compare_options(
	a: DecisionOption,
	b: DecisionOption
) -> bool:

	return a.final_score > b.final_score


func _select_from_ranked_options(
	actor,
	options: Array
):

	if options.is_empty():
		return null

	var profile = actor.get_sim_metadata(
		"strategy_profile",
		null
	)

	if profile == null:
		return options[0]

	if not profile is CountryStrategyProfile:
		return options[0]

	var risk_tolerance = profile.risk_tolerance

	if risk_tolerance >= 0.75:
		if options.size() > 1:
			return _weighted_selection(
				options,
				0.75
			)

	if risk_tolerance >= 0.50:
		if options.size() > 2:
			return _weighted_selection(
				options,
				0.85
			)

	return options[0]


func _weighted_selection(
	options: Array,
	top_weight: float
):

	if options.is_empty():
		return null

	var best_option = options[0]

	if options.size() == 1:
		return best_option

	var second_option = options[1]

	if second_option.final_score >= (
		best_option.final_score
		* top_weight
	):
		return second_option

	return best_option
