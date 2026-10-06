class_name DecisionSystem
extends SimulationSystem


var evaluator: DecisionEvaluator


func _init():
	super("decision_system")
	evaluator = DecisionEvaluator.new()


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("DecisionSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		_prepare_entity_decisions(
			world,
			entity
		)


func _prepare_entity_decisions(
	world: WorldState,
	entity
) -> void:

	var options: Array = []

	# --------------------------------------------------
	# FIND A BASIC TARGET
	# --------------------------------------------------
	#
	# For the MVP, countries need another country
	# to interact with.
	#
	# This is intentionally simple. More advanced
	# target selection will come later.

	var target = _find_basic_target(
		world,
		entity
	)

	if target != null:

		# --------------------------------------------------
		# ECONOMIC OPTION
		# --------------------------------------------------

		var trade_option = DecisionOption.new(
			"expand_trade",
			"Expand Trade",
			"economic"
		)

		trade_option.description = (
			"Increase economic cooperation and trade with another country."
		)

		trade_option.actor_id = entity.id
		trade_option.target_id = target.id

		trade_option.base_score = 1.0

		trade_option.metadata = {
			"risk": 0.20,
			"uncertainty": 0.10
		}

		options.append(
			trade_option
		)


		# --------------------------------------------------
		# DIPLOMATIC OPTION
		# --------------------------------------------------

		var diplomatic_option = DecisionOption.new(
			"diplomatic_outreach",
			"Diplomatic Outreach",
			"diplomatic"
		)

		diplomatic_option.description = (
			"Improve diplomatic relations with another country."
		)

		diplomatic_option.actor_id = entity.id
		diplomatic_option.target_id = target.id

		diplomatic_option.base_score = 1.0

		diplomatic_option.metadata = {
			"risk": 0.10,
			"uncertainty": 0.05
		}

		options.append(
			diplomatic_option
		)


	# --------------------------------------------------
	# STORE OPTIONS
	# --------------------------------------------------

	entity.set_sim_metadata(
		"decision_options",
		options
	)


func _find_basic_target(
	world: WorldState,
	actor
):

	if world == null:
		return null

	if actor == null:
		return null

	for candidate in world.entities.values():

		if candidate == null:
			continue

		if candidate == actor:
			continue

		if candidate.entity_type != "country":
			continue

		return candidate

	return null


func evaluate_option(
	world: WorldState,
	actor,
	option: DecisionOption
) -> float:

	if evaluator == null:
		evaluator = DecisionEvaluator.new()

	return evaluator.evaluate_option(
		world,
		actor,
		option
	)


func rank_options(
	world: WorldState,
	actor,
	options: Array
) -> Array:

	if actor == null:
		return []

	var evaluated: Array = []

	for option in options:

		if option == null:
			continue

		if not option is DecisionOption:
			continue

		evaluate_option(
			world,
			actor,
			option
		)

		evaluated.append(
			option
		)

	evaluated.sort_custom(
		_compare_options
	)

	return evaluated


func _compare_options(
	a: DecisionOption,
	b: DecisionOption
) -> bool:

	return a.final_score > b.final_score


# ============================================================
# STEP 15.2 — DECISION → ACTION CONVERSION
# ============================================================

func convert_decision_to_action(
	option: DecisionOption,
	start_date: String = ""
) -> SimAction:
	if option == null:
		return null

	return option.to_executable_action(
		start_date
	)
