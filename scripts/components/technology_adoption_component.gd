class_name TechnologyAdoptionComponent
extends SimComponent


func _init(owner: String = ""):

	super(
		"technology_adoption",
		owner
	)

	state = {
		"adoption": {},
		"deployment_capacity": 0.0,
		"deployment_efficiency": 1.0
	}


# ========================================================
# ADOPTION
# ========================================================

func set_adoption(
	technology_id: String,
	value: float
) -> void:

	if technology_id.is_empty():
		return

	var adoption = get_state(
		"adoption",
		{}
	)

	if typeof(adoption) != TYPE_DICTIONARY:
		adoption = {}

	adoption[technology_id] = clamp(
		value,
		0.0,
		1.0
	)

	set_state(
		"adoption",
		adoption
	)


func get_adoption(
	technology_id: String
) -> float:

	var adoption = get_state(
		"adoption",
		{}
	)

	if typeof(adoption) != TYPE_DICTIONARY:
		return 0.0

	return float(
		adoption.get(
			technology_id,
			0.0
		)
	)


func has_adoption(
	technology_id: String
) -> bool:

	return get_adoption(
		technology_id
	) > 0.0


func is_fully_adopted(
	technology_id: String
) -> bool:

	return get_adoption(
		technology_id
	) >= 1.0


# ========================================================
# CHANGE ADOPTION
# ========================================================

func change_adoption(
	technology_id: String,
	change: float
) -> void:

	var current = get_adoption(
		technology_id
	)

	set_adoption(
		technology_id,
		current + change
	)


# ========================================================
# GET ALL ADOPTION
# ========================================================

func get_all_adoption() -> Dictionary:

	var adoption = get_state(
		"adoption",
		{}
	)

	if typeof(adoption) != TYPE_DICTIONARY:
		return {}

	return adoption
