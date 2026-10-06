class_name ExternalActorLimitedSimulationSystem
extends SimulationSystem


# ============================================================
# INTERNATIONAL / EXTERNAL-WORLD ABSTRACTION — STEP 10.4
# EXTERNAL ACTOR LIMITED SIMULATION
# ============================================================
#
# This system advances only explicitly-declared external state that is
# relevant to generating or persisting international consequences.
#
# It deliberately does NOT simulate:
#   population
#   domestic economy
#   government
#   industry
#   infrastructure
#   military
#   research
#   technology
#   geography
#
# The existing ExternalWorldActorComponent remains the storage owner.
# Step 10.4 stores its limited simulation rules under:
#
#   event_state["limited_simulation"]
#
# Supported bounded state:
#   resource availability trends
#   trade-capacity trends
#   strategic-status trends
#   finite event timers
#
# Each actor is processed at most once for a given world date.
# ============================================================

const LIMITED_SIMULATION_KEY: String = "limited_simulation"
const LAST_PROCESSED_DATE_KEY: String = "last_processed_date"


func _init() -> void:
	super("external_actor_limited_simulation")


# ============================================================
# MONTHLY EXECUTION
# ============================================================

func process_month(world: WorldState) -> void:
	if world == null:
		return

	var actor_ids: Array[String] = []

	for entity_id in world.entities.keys():
		var entity = world.entities[entity_id]

		if entity == null:
			continue

		if not entity is ExternalWorldActor:
			continue

		actor_ids.append(str(entity_id))

	actor_ids.sort()

	for actor_id in actor_ids:
		var actor = world.get_entity(actor_id)

		if actor == null:
			continue

		_process_actor(world, actor)


# ============================================================
# RULE CONFIGURATION
# ============================================================

func configure_limited_simulation(
	actor: ExternalWorldActor,
	rules: Dictionary
) -> bool:
	if actor == null:
		return false

	if typeof(rules) != TYPE_DICTIONARY:
		return false

	var normalized: Dictionary = {
		"resource_rules": {},
		"trade_rules": {},
		"strategic_rules": {},
		"event_rules": {}
	}

	for key in normalized.keys():
		var value = rules.get(key, {})

		if typeof(value) != TYPE_DICTIONARY:
			return false

		normalized[key] = value.duplicate(true)

	actor.set_event_state(
		LIMITED_SIMULATION_KEY,
		normalized
	)

	return true


func get_limited_simulation(
	actor: ExternalWorldActor
) -> Dictionary:
	if actor == null:
		return {}

	var rules = actor.get_event_state(
		LIMITED_SIMULATION_KEY,
		{}
	)

	if typeof(rules) != TYPE_DICTIONARY:
		return {}

	return rules.duplicate(true)


# ============================================================
# ACTOR PROCESSING
# ============================================================

func _process_actor(
	world: WorldState,
	actor: ExternalWorldActor
) -> void:
	var limited_state = actor.get_event_state(
		LIMITED_SIMULATION_KEY,
		{}
	)

	if typeof(limited_state) != TYPE_DICTIONARY:
		return

	var current_date = world.current_date.duplicate(true)
	var last_processed_date = limited_state.get(
		LAST_PROCESSED_DATE_KEY,
		{}
	)

	if typeof(last_processed_date) == TYPE_DICTIONARY:
		if last_processed_date == current_date:
			return

	_process_resource_rules(
		actor,
		limited_state.get("resource_rules", {})
	)

	_process_trade_rules(
		actor,
		limited_state.get("trade_rules", {})
	)

	_process_strategic_rules(
		actor,
		limited_state.get("strategic_rules", {})
	)

	_process_event_rules(
		actor,
		limited_state.get("event_rules", {})
	)

	limited_state[LAST_PROCESSED_DATE_KEY] = current_date

	actor.set_event_state(
		LIMITED_SIMULATION_KEY,
		limited_state
	)


# ============================================================
# RESOURCE TRENDS
# ============================================================

func _process_resource_rules(
	actor: ExternalWorldActor,
	rules
) -> void:
	if typeof(rules) != TYPE_DICTIONARY:
		return

	for resource_id_value in rules.keys():
		var resource_id = str(resource_id_value)
		var rule = rules[resource_id_value]

		if resource_id.is_empty():
			continue

		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var delta = float(rule.get("availability_delta", 0.0))
		var minimum = float(rule.get("minimum", 0.0))
		var maximum = float(rule.get("maximum", 1.0))

		if maximum < minimum:
			maximum = minimum

		var status = actor.get_resource_status(
			resource_id,
			null
		)

		if status is Dictionary:
			var resource_status = status.duplicate(true)
			var current = float(
				resource_status.get(
					"availability",
					0.0
				)
			)

			resource_status["availability"] = clampf(
				current + delta,
				minimum,
				maximum
			)

			actor.set_resource_status(
				resource_id,
				resource_status
			)

		elif status != null:
			var current_numeric = float(status)

			actor.set_resource_status(
				resource_id,
				clampf(
					current_numeric + delta,
					minimum,
					maximum
				)
			)


# ============================================================
# TRADE-CAPACITY TRENDS
# ============================================================

func _process_trade_rules(
	actor: ExternalWorldActor,
	rules
) -> void:
	if typeof(rules) != TYPE_DICTIONARY:
		return

	for resource_id_value in rules.keys():
		var resource_id = str(resource_id_value)
		var rule = rules[resource_id_value]

		if resource_id.is_empty():
			continue

		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var delta = float(
			rule.get(
				"capacity_delta",
				0.0
			)
		)

		var minimum = maxf(
			0.0,
			float(
				rule.get(
					"minimum",
					0.0
				)
			)
		)

		var maximum = maxf(
			minimum,
			float(
				rule.get(
					"maximum",
					1.0e30
				)
			)
		)

		var current = actor.get_trade_capacity(
			resource_id,
			0.0
		)

		actor.set_trade_capacity(
			resource_id,
			clampf(
				current + delta,
				minimum,
				maximum
			)
		)


# ============================================================
# STRATEGIC STATUS TRENDS
# ============================================================

func _process_strategic_rules(
	actor: ExternalWorldActor,
	rules
) -> void:
	if typeof(rules) != TYPE_DICTIONARY:
		return

	for key_value in rules.keys():
		var key = str(key_value)
		var rule = rules[key_value]

		if key.is_empty():
			continue

		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var delta = float(rule.get("delta", 0.0))
		var minimum = float(rule.get("minimum", 0.0))
		var maximum = float(rule.get("maximum", 1.0))

		if maximum < minimum:
			maximum = minimum

		var current = float(
			actor.get_strategic_status(
				key,
				0.0
			)
		)

		actor.set_strategic_status(
			key,
			clampf(
				current + delta,
				minimum,
				maximum
			)
		)


# ============================================================
# FINITE EVENT TIMERS
# ============================================================

func _process_event_rules(
	actor: ExternalWorldActor,
	rules
) -> void:
	if typeof(rules) != TYPE_DICTIONARY:
		return

	for event_id_value in rules.keys():
		var event_id = str(event_id_value)
		var rule = rules[event_id_value]

		if event_id.is_empty():
			continue

		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var remaining = maxf(
			0.0,
			float(
				rule.get(
					"remaining_months",
					0.0
				)
			)
		)

		var decrement = maxf(
			0.0,
			float(
				rule.get(
					"decrement_per_month",
					1.0
				)
			)
		)

		var next_remaining = maxf(
			0.0,
			remaining - decrement
		)

		rule = rule.duplicate(true)
		rule["remaining_months"] = next_remaining

		if next_remaining <= 0.0:
			rule["active"] = false
		else:
			rule["active"] = true

		var current_event_state = actor.get_event_state(
			event_id,
			{}
		)

		if typeof(current_event_state) != TYPE_DICTIONARY:
			current_event_state = {}

		current_event_state["limited_simulation"] = rule.duplicate(true)

		actor.set_event_state(
			event_id,
			current_event_state
		)

		var limited_rules = actor.get_event_state(
			LIMITED_SIMULATION_KEY,
			{}
		)

		if typeof(limited_rules) != TYPE_DICTIONARY:
			limited_rules = {}

		var event_rules = limited_rules.get(
			"event_rules",
			{}
		)

		if typeof(event_rules) != TYPE_DICTIONARY:
			event_rules = {}

		event_rules[event_id] = rule
		limited_rules["event_rules"] = event_rules

		actor.set_event_state(
			LIMITED_SIMULATION_KEY,
			limited_rules
		)
