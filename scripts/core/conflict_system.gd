class_name ConflictSystem
extends SimulationSystem


func _init():
	super("conflict_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("ConflictSystem: World is null.")
		return

	var conflicts = world.active_conflicts

	if typeof(conflicts) != TYPE_ARRAY:
		return

	for conflict in conflicts:

		if conflict == null:
			continue

		if not conflict is MilitaryConflict:
			continue

		if conflict.is_finished():
			continue

		_process_conflict(
			world,
			conflict
		)


# ============================================================
# CONFLICT PROCESSING
# ============================================================

func _process_conflict(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	var attacker = world.get_entity(
		conflict.attacker_id
	)

	var defender = world.get_entity(
		conflict.defender_id
	)

	if attacker == null:
		conflict.cancel("attacker_missing")
		return

	if defender == null:
		conflict.cancel("defender_missing")
		return

	_set_at_war(
		attacker,
		true
	)

	_set_at_war(
		defender,
		true
	)

	var attacker_score = _calculate_attacker_score(
		attacker,
		defender
	)

	var defender_score = _calculate_defender_score(
		attacker,
		defender
	)

	var total_score = (
		attacker_score
		+ defender_score
	)

	if total_score <= 0.0:
		return

	var attacker_share = (
		attacker_score
		/ total_score
	)

	var defender_share = (
		defender_score
		/ total_score
	)

	conflict.set_attacker_pressure(
		clamp(
			conflict.attacker_pressure
			+ attacker_share * 0.10,
			0.0,
			1.0
		)
	)

	conflict.set_defender_pressure(
		clamp(
			conflict.defender_pressure
			+ defender_share * 0.10,
			0.0,
			1.0
		)
	)

	conflict.set_intensity(
		clamp(
			0.40
			+ abs(
				attacker_share
				- defender_share
			),
			0.0,
			1.0
		)
	)

	conflict.increment_duration()

	_apply_monthly_military_effects(
		attacker,
		defender,
		attacker_share,
		defender_share,
		conflict
	)

	_record_conflict_history(
		world,
		conflict,
		attacker_score,
		defender_score
	)

	_check_conflict_resolution(
		world,
		conflict
	)


# ============================================================
# ATTACKER SCORE
# ============================================================

func _calculate_attacker_score(
	attacker,
	defender
) -> float:

	var military = attacker.get_component(
		"military"
	)

	if military == null:
		return 0.0

	var power = _get_military_value(
		military,
		"military_power"
	)

	var readiness = _get_military_value(
		military,
		"readiness"
	)

	var logistics = _get_military_value(
		military,
		"logistics_capacity"
	)

	var manpower = _get_military_value(
		military,
		"manpower"
	)

	var projection = _get_military_value(
		military,
		"power_projection"
	)

	var mobilization = _get_military_value(
		military,
		"mobilization_capacity"
	)

	var score = (
		power * 0.30
		+ readiness * 0.20
		+ logistics * 0.15
		+ manpower * 0.10
		+ projection * 0.15
		+ mobilization * 0.10
	)

	var geographic_modifier = _get_attacker_geography_modifier(
		attacker,
		defender
	)

	return max(
		score * geographic_modifier,
		0.0
	)


# ============================================================
# DEFENDER SCORE
# ============================================================

func _calculate_defender_score(
	attacker,
	defender
) -> float:

	var military = defender.get_component(
		"military"
	)

	if military == null:
		return 0.0

	var power = _get_military_value(
		military,
		"military_power"
	)

	var readiness = _get_military_value(
		military,
		"readiness"
	)

	var logistics = _get_military_value(
		military,
		"logistics_capacity"
	)

	var manpower = _get_military_value(
		military,
		"manpower"
	)

	var defense = _get_military_value(
		military,
		"defensive_capability"
	)

	var mobilization = _get_military_value(
		military,
		"mobilization_capacity"
	)

	var score = (
		power * 0.25
		+ readiness * 0.20
		+ logistics * 0.15
		+ manpower * 0.10
		+ defense * 0.20
		+ mobilization * 0.10
	)

	return max(
		score,
		0.0
	)


# ============================================================
# GEOGRAPHY
# ============================================================

func _get_attacker_geography_modifier(
	attacker,
	defender
) -> float:

	var geography = attacker.get_component(
		"geography"
	)

	if geography == null:
		return 0.85

	var neighbors = geography.get_state(
		"neighbors",
		[]
	)

	if typeof(neighbors) == TYPE_ARRAY:

		if neighbors.has(
			defender.id
		):
			return 1.00

	var projection = 0.30

	var military = attacker.get_component(
		"military"
	)

	if military != null:

		projection = clamp(
			float(
				military.get_state(
					"power_projection",
					0.30
				)
			),
			0.0,
			1.0
		)

	return clamp(
		0.75
		+ projection * 0.35,
		0.75,
		1.10
	)


# ============================================================
# MONTHLY MILITARY EFFECTS
# ============================================================

func _apply_monthly_military_effects(
	attacker,
	defender,
	attacker_share: float,
	defender_share: float,
	conflict: MilitaryConflict
) -> void:

	var attacker_military = attacker.get_component(
		"military"
	)

	var defender_military = defender.get_component(
		"military"
	)

	if attacker_military != null:

		var attacker_readiness = _get_military_value(
			attacker_military,
			"readiness"
		)

		var attacker_pressure = _get_military_value(
			attacker_military,
			"military_pressure"
		)

		attacker_military.set_state(
			"readiness",
			clamp(
				attacker_readiness
				- defender_share * 0.02,
				0.0,
				1.0
			)
		)

		attacker_military.set_state(
			"military_pressure",
			clamp(
				attacker_pressure
				+ 0.02,
				0.0,
				1.0
			)
		)

	if defender_military != null:

		var defender_readiness = _get_military_value(
			defender_military,
			"readiness"
		)

		var defender_pressure = _get_military_value(
			defender_military,
			"military_pressure"
		)

		defender_military.set_state(
			"readiness",
			clamp(
				defender_readiness
				- attacker_share * 0.02,
				0.0,
				1.0
			)
		)

		defender_military.set_state(
			"military_pressure",
			clamp(
				defender_pressure
				+ 0.02,
				0.0,
				1.0
			)
		)


# ============================================================
# CONFLICT RESOLUTION
# ============================================================

func _check_conflict_resolution(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	if conflict.duration_months < 3:
		return

	var pressure_difference = (
		conflict.attacker_pressure
		- conflict.defender_pressure
	)

	if abs(
		pressure_difference
	) < 0.20:
		return

	if conflict.duration_months < 6:
		return

	if pressure_difference >= 0.20:

		conflict.complete(
			"attacker_advantage",
			"attacker_pressure"
		)

	elif pressure_difference <= -0.20:

		conflict.complete(
			"defender_advantage",
			"defender_pressure"
		)

	_clear_conflict_war_state(
		world,
		conflict
	)

	_move_completed_conflict(
		world,
		conflict
	)


# ============================================================
# WAR STATE
# ============================================================

func _set_at_war(
	entity,
	value: bool
) -> void:

	if entity == null:
		return

	var military = entity.get_component(
		"military"
	)

	if military == null:
		return

	military.set_state(
		"at_war",
		value
	)


func _clear_conflict_war_state(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	if world == null:
		return

	if conflict == null:
		return

	var attacker = world.get_entity(
		conflict.attacker_id
	)

	var defender = world.get_entity(
		conflict.defender_id
	)

	if attacker != null:
		_set_at_war(
			attacker,
			false
		)

	if defender != null:
		_set_at_war(
			defender,
			false
		)


# ============================================================
# COMPLETED CONFLICT
# ============================================================

func _move_completed_conflict(
	world: WorldState,
	conflict: MilitaryConflict
) -> void:

	if world == null:
		return

	if conflict == null:
		return

	if world.active_conflicts.has(
		conflict
	):
		world.active_conflicts.erase(
			conflict
		)

	if not world.completed_conflicts.has(
		conflict
	):
		world.completed_conflicts.append(
			conflict
	)


# ============================================================
# CONFLICT HISTORY
# ============================================================

func _record_conflict_history(
	world: WorldState,
	conflict: MilitaryConflict,
	attacker_score: float,
	defender_score: float
) -> void:

	if world == null:
		return

	if conflict == null:
		return

	conflict.add_history_entry({
		"type": "conflict_month",
		"year": world.get_year(),
		"month": world.get_month(),
		"day": world.get_day(),
		"attacker_score": attacker_score,
		"defender_score": defender_score,
		"attacker_pressure": conflict.attacker_pressure,
		"defender_pressure": conflict.defender_pressure,
		"intensity": conflict.intensity,
		"duration_months": conflict.duration_months
	})


# ============================================================
# HELPERS
# ============================================================

func _get_military_value(
	military,
	state_name: String
) -> float:

	if military == null:
		return 0.0

	return clamp(
		float(
			military.get_state(
				state_name,
				0.0
			)
		),
		0.0,
		1.0
	)


# ============================================================
# PUBLIC CONFLICT CREATION
# ============================================================

func start_conflict(
	world: WorldState,
	conflict_id: String,
	attacker_id: String,
	defender_id: String
) -> bool:

	if world == null:
		return false

	if conflict_id.is_empty():
		return false

	if attacker_id.is_empty():
		return false

	if defender_id.is_empty():
		return false

	if attacker_id == defender_id:
		return false

	var attacker = world.get_entity(
		attacker_id
	)

	var defender = world.get_entity(
		defender_id
	)

	if attacker == null:
		return false

	if defender == null:
		return false

	for existing in world.active_conflicts:

		if existing == null:
			continue

		if not existing is MilitaryConflict:
			continue

		if existing.id == conflict_id:
			return false

	var conflict = MilitaryConflict.new(
		conflict_id,
		attacker_id,
		defender_id
	)

	conflict.set_start_date(
		world.get_year(),
		world.get_month(),
		world.get_day()
	)

	conflict.activate()

	world.add_active_conflict(
		conflict
	)

	_set_at_war(
		attacker,
		true
	)

	_set_at_war(
		defender,
		true
	)

	return true
