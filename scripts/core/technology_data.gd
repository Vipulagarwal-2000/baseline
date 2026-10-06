class_name TechnologyData
extends RefCounted


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""

var name: String = ""

var description: String = ""


# ============================================================
# RESEARCH REQUIREMENTS
# ============================================================

var research_cost: float = 0.0

var research_duration_months: int = 0

var prerequisites: Array = []

var required_technology_level: float = 0.0


# ============================================================
# CAPABILITIES
# ============================================================

var capabilities: Array = []


# ============================================================
# TECHNOLOGY EFFECTS
# ============================================================

var effects: Dictionary = {}


# ============================================================
# HISTORICAL AVAILABILITY
# ============================================================

var historical_start_year: int = 0

var historical_end_year: int = 0


# ============================================================
# ENABLED
# ============================================================

var enabled: bool = true


# ============================================================
# CONSTRUCTOR
# ============================================================

func _init(
	technology_id: String = "",
	technology_name: String = "",
	technology_description: String = ""
):

	id = technology_id

	name = technology_name

	description = technology_description


# ============================================================
# PREREQUISITES
# ============================================================

func add_prerequisite(
	technology_id: String
) -> void:

	if technology_id.is_empty():
		return

	if technology_id in prerequisites:
		return

	prerequisites.append(
		technology_id
	)


func has_prerequisite(
	technology_id: String
) -> bool:

	return technology_id in prerequisites


# ============================================================
# CAPABILITIES
# ============================================================

func add_capability(
	capability_id: String
) -> void:

	if capability_id.is_empty():
		return

	if capability_id in capabilities:
		return

	capabilities.append(
		capability_id
	)


func has_capability(
	capability_id: String
) -> bool:

	return capability_id in capabilities


# ============================================================
# TECHNOLOGY EFFECTS
# ============================================================

func add_effect(
	effect_id: String,
	value
) -> void:

	if effect_id.is_empty():
		return

	effects[effect_id] = value


func get_effect(
	effect_id: String,
	default_value = null
):

	return effects.get(
		effect_id,
		default_value
	)


func has_effect(
	effect_id: String
) -> bool:

	return effects.has(
		effect_id
	)


func get_all_effects() -> Dictionary:

	return effects


# ============================================================
# HISTORICAL AVAILABILITY
# ============================================================

func is_available_for_year(
	year: int
) -> bool:

	if not enabled:
		return false

	if historical_start_year > 0:

		if year < historical_start_year:
			return false

	if historical_end_year > 0:

		if year > historical_end_year:
			return false

	return true


# ============================================================
# PREREQUISITE CHECK
# ============================================================

func check_prerequisites(
	completed_technologies: Dictionary
) -> bool:

	for prerequisite_id in prerequisites:

		if not completed_technologies.has(
			prerequisite_id
		):

			return false

		if not bool(
			completed_technologies[
				prerequisite_id
			]
		):

			return false

	return true


# ============================================================
# RESEARCH AVAILABILITY
# ============================================================

func can_be_researched(
	technology_level: float,
	completed_technologies: Dictionary,
	current_year: int
) -> bool:

	if not enabled:
		return false

	if not is_available_for_year(
		current_year
	):

		return false

	if technology_level < required_technology_level:
		return false

	if not check_prerequisites(
		completed_technologies
	):

		return false

	return true
