class_name SimGoal
extends RefCounted


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""

var name: String = ""

var description: String = ""


# ============================================================
# GOAL STATE
# ============================================================

var priority: float = 0.5

var importance: float = 0.5

var progress: float = 0.0

var target_value: float = 1.0

var active: bool = true

var completed: bool = false


# ============================================================
# GOAL TYPE
# ============================================================

var goal_type: String = "general"


# ============================================================
# CREATION
# ============================================================

func _init(
	goal_id: String = "",
	goal_name: String = "",
	type: String = "general"
):

	id = goal_id

	name = goal_name

	goal_type = type


# ============================================================
# DESCRIPTION
# ============================================================

func set_description(
	text: String
) -> void:

	description = text


# ============================================================
# PRIORITY
# ============================================================

func set_priority(
	value: float
) -> void:

	priority = clamp(
		value,
		0.0,
		1.0
	)


func get_priority() -> float:

	return priority


# ============================================================
# IMPORTANCE
# ============================================================

func set_importance(
	value: float
) -> void:

	importance = clamp(
		value,
		0.0,
		1.0
	)


func get_importance() -> float:

	return importance


# ============================================================
# PROGRESS
# ============================================================

func set_progress(
	value: float
) -> void:

	progress = clamp(
		value,
		0.0,
		target_value
	)


func change_progress(
	change: float
) -> void:

	set_progress(
		progress + change
	)


func get_progress_percentage() -> float:

	if target_value <= 0.0:

		return 100.0


	return clamp(
		(
			progress
			/ target_value
		) * 100.0,
		0.0,
		100.0
	)


# ============================================================
# COMPLETION
# ============================================================

func check_completion() -> bool:

	if completed:

		return true


	if progress >= target_value:

		completed = true

		return true


	return false


# ============================================================
# ACTIVATE / DEACTIVATE
# ============================================================

func activate() -> void:

	active = true


func deactivate() -> void:

	active = false


# ============================================================
# STATE
# ============================================================

func is_active() -> bool:

	return active


func is_completed() -> bool:

	return completed
