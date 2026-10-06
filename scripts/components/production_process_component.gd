class_name ProductionProcess
extends SimComponent


func _init(
	owner: String = ""
) -> void:
	super._init(
		"production_process",
		owner
	)


func setup(
	process_inputs: Dictionary = {},
	process_outputs: Dictionary = {},
	process_byproducts: Dictionary = {},
	process_technology_requirements: Dictionary = {},
	process_capability_requirements: Dictionary = {},
	process_infrastructure_requirements: Dictionary = {},
	process_labor_requirement: float = 0.0,
	process_capital_requirement: float = 0.0,
	process_operating_cost: float = 0.0,
	process_transition_cost: float = 0.0,
	process_efficiency: float = 1.0,
	process_adoption: float = 0.0,
	process_displacement: Dictionary = {},
	process_obsolescence: float = 0.0,
	process_capacity: float = 0.0,
	process_duration: float = 1.0,
	process_labor_skill_requirement: Dictionary = {},
	process_equipment_requirement: Dictionary = {},
	process_energy_requirement: Dictionary = {},
	process_land_requirement: float = 0.0,
	process_maintenance_requirement: Dictionary = {},
	process_reliability: float = 1.0,
	process_seasonality: Dictionary = {},
	process_waste: Dictionary = {},
	process_infrastructure_usage: Dictionary = {}
) -> void:

	set_state(
		"inputs",
		process_inputs
	)

	set_state(
		"outputs",
		process_outputs
	)

	set_state(
		"byproducts",
		process_byproducts
	)

	set_state(
		"technology_requirements",
		process_technology_requirements
	)

	set_state(
		"capability_requirements",
		process_capability_requirements
	)

	set_state(
		"infrastructure_requirements",
		process_infrastructure_requirements
	)

	set_state(
		"labor_requirement",
		process_labor_requirement
	)

	set_state(
		"capital_requirement",
		process_capital_requirement
	)

	set_state(
		"operating_cost",
		process_operating_cost
	)

	set_state(
		"transition_cost",
		process_transition_cost
	)

	set_state(
		"efficiency",
		process_efficiency
	)

	set_state(
		"adoption",
		process_adoption
	)

	set_state(
		"displacement",
		process_displacement
	)

	set_state(
		"obsolescence",
		process_obsolescence
	)

	set_state(
		"capacity",
		process_capacity
	)

	set_state(
		"duration",
		process_duration
	)

	set_state(
		"labor_skill_requirement",
		process_labor_skill_requirement
	)

	set_state(
		"equipment_requirement",
		process_equipment_requirement
	)

	set_state(
		"energy_requirement",
		process_energy_requirement
	)

	set_state(
		"land_requirement",
		process_land_requirement
	)

	set_state(
		"maintenance_requirement",
		process_maintenance_requirement
	)

	set_state(
		"reliability",
		process_reliability
	)

	set_state(
		"seasonality",
		process_seasonality
	)

	set_state(
		"waste",
		process_waste
	)

	set_state(
		"infrastructure_usage",
		process_infrastructure_usage
	)
