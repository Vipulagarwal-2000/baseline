class_name ResearchProject
extends RefCounted


var id: String = ""
var technology_id: String = ""
var country_id: String = ""

var started: bool = false
var completed: bool = false

var progress: float = 0.0
var research_cost: float = 0.0
var duration_months: int = 0
var elapsed_months: int = 0

var priority: float = 1.0

var start_date: Dictionary = {}
var completion_date: Dictionary = {}


func _init(
	project_id: String = "",
	target_technology_id: String = "",
	owner_country_id: String = ""
):

	id = project_id
	technology_id = target_technology_id
	country_id = owner_country_id


func start(
	date: Dictionary
) -> bool:

	if started:
		return false

	if completed:
		return false

	started = true
	start_date = date.duplicate(true)

	return true


func add_progress(
	amount: float
) -> void:

	if not started:
		return

	if completed:
		return

	if amount <= 0.0:
		return

	progress += amount

	progress = clamp(
		progress,
		0.0,
		research_cost
	)


func is_complete() -> bool:

	return completed


func check_completion(
	date: Dictionary
) -> bool:

	if completed:
		return true

	if research_cost <= 0.0:
		completed = true
		completion_date = date.duplicate(true)
		return true

	if progress >= research_cost:

		progress = research_cost
		completed = true
		completion_date = date.duplicate(true)

		return true

	return false


func get_progress_percentage() -> float:

	if research_cost <= 0.0:
		return 100.0

	return (
		progress
		/ research_cost
	) * 100.0
