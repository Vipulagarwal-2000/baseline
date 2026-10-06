class_name CountryStrategyProfile
extends RefCounted

var country_id: String = ""

# Core strategic preferences
var economic_priority: float = 0.5
var military_priority: float = 0.5
var diplomatic_priority: float = 0.5
var technology_priority: float = 0.5
var domestic_stability_priority: float = 0.5
var resource_security_priority: float = 0.5
var influence_priority: float = 0.5

# Behavioural characteristics
var risk_tolerance: float = 0.5
var cooperation_preference: float = 0.5
var negotiation_preference: float = 0.5
var military_action_preference: float = 0.5
var economic_pressure_preference: float = 0.5

# Strategic characteristics
var expansionism: float = 0.0
var defensive_orientation: float = 0.5
var long_term_planning: float = 0.5

# Strategic interests
var strategic_interests: Array = []

# Threats / concerns
var major_concerns: Array = []

func _init(id: String = ""):
	country_id = id


func set_priority(priority_name: String, value: float) -> void:
	value = clamp(value, 0.0, 1.0)

	match priority_name:
		"economic":
			economic_priority = value
		"military":
			military_priority = value
		"diplomatic":
			diplomatic_priority = value
		"technology":
			technology_priority = value
		"domestic_stability":
			domestic_stability_priority = value
		"resource_security":
			resource_security_priority = value
		"influence":
			influence_priority = value


func get_priority(priority_name: String) -> float:
	match priority_name:
		"economic":
			return economic_priority
		"military":
			return military_priority
		"diplomatic":
			return diplomatic_priority
		"technology":
			return technology_priority
		"domestic_stability":
			return domestic_stability_priority
		"resource_security":
			return resource_security_priority
		"influence":
			return influence_priority
		_:
			return 0.0


func set_behavior(behavior_name: String, value: float) -> void:
	value = clamp(value, 0.0, 1.0)

	match behavior_name:
		"risk_tolerance":
			risk_tolerance = value
		"cooperation":
			cooperation_preference = value
		"negotiation":
			negotiation_preference = value
		"military_action":
			military_action_preference = value
		"economic_pressure":
			economic_pressure_preference = value
		"expansionism":
			expansionism = value
		"defensive_orientation":
			defensive_orientation = value
		"long_term_planning":
			long_term_planning = value


func get_behavior(behavior_name: String) -> float:
	match behavior_name:
		"risk_tolerance":
			return risk_tolerance
		"cooperation":
			return cooperation_preference
		"negotiation":
			return negotiation_preference
		"military_action":
			return military_action_preference
		"economic_pressure":
			return economic_pressure_preference
		"expansionism":
			return expansionism
		"defensive_orientation":
			return defensive_orientation
		"long_term_planning":
			return long_term_planning
		_:
			return 0.0


func add_strategic_interest(interest: String) -> void:
	if interest.is_empty():
		return

	if not strategic_interests.has(interest):
		strategic_interests.append(interest)


func add_concern(concern: String) -> void:
	if concern.is_empty():
		return

	if not major_concerns.has(concern):
		major_concerns.append(concern)


func has_strategic_interest(interest: String) -> bool:
	return strategic_interests.has(interest)


func has_concern(concern: String) -> bool:
	return major_concerns.has(concern)
