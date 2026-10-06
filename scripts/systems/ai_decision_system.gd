class_name AIDecisionSystem
extends SimulationSystem


var decision_maker: AIDecisionMaker


func _init():
	super("ai_decision_system")
	decision_maker = AIDecisionMaker.new()


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("AIDecisionSystem: World is null.")
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		if entity.entity_type != "country":
			continue

		_process_country(
			world,
			entity
		)


func _process_country(
	world: WorldState,
	country
) -> void:

	var options = country.get_sim_metadata(
		"decision_options",
		[]
	)

	if typeof(options) != TYPE_ARRAY:
		options = []

	if options.is_empty():
		return

	var selected_action = decision_maker.choose_action(
		world,
		country,
		options
	)

	if selected_action == null:
		return

	country.set_sim_metadata(
		"selected_decision",
		selected_action
	)


func get_selected_decision(country):

	if country == null:
		return null

	return country.get_sim_metadata(
		"selected_decision",
		null
	)


func clear_selected_decision(country) -> void:

	if country == null:
		return

	country.set_sim_metadata(
		"selected_decision",
		null
	)


# ============================================================
# STEP 15.2 — SELECTED DECISION → EXECUTABLE ACTION
# ============================================================

func get_selected_action(
	country,
	start_date: String = ""
) -> SimAction:
	var selected_decision = get_selected_decision(
		country
	)

	if selected_decision == null:
		return null

	if not selected_decision is DecisionOption:
		return null

	return selected_decision.to_executable_action(
		start_date
	)
