class_name DefaultTechnologies
extends RefCounted


static func create_library() -> TechnologyLibrary:

	var library = TechnologyLibrary.new()


	# ========================================================
	# ELECTRICITY
	# ========================================================

	var electricity = TechnologyData.new(
		"electricity",
		"Electricity",
		"Generation and practical use of electrical power."
	)

	electricity.research_cost = 100.0
	electricity.research_duration_months = 24
	electricity.required_technology_level = 10.0

	electricity.add_capability(
		"electrical_power"
	)

	electricity.add_capability(
		"electrical_grid"
	)

	# Military support:
	# Reliable electrical infrastructure supports military
	# industrial and command capabilities.

	electricity.add_effect(
		"military_industrial_support",
		2.0
	)

	electricity.historical_start_year = 1880

	library.add_technology(
		electricity
	)


	# ========================================================
	# RADIO
	# ========================================================

	var radio = TechnologyData.new(
		"radio",
		"Radio",
		"Wireless communication and mass broadcasting."
	)

	radio.research_cost = 80.0
	radio.research_duration_months = 18
	radio.required_technology_level = 15.0

	radio.add_capability(
		"wireless_communication"
	)

	radio.add_capability(
		"mass_broadcasting"
	)

	# Military support:
	# Radio improves basic military communications.

	radio.add_effect(
		"military_command_capacity",
		4.0
	)

	radio.historical_start_year = 1900

	library.add_technology(
		radio
	)


	# ========================================================
	# INDUSTRIAL MACHINERY
	# ========================================================

	var industrial_machinery = TechnologyData.new(
		"industrial_machinery",
		"Industrial Machinery",
		"Advanced machinery for industrial production."
	)

	industrial_machinery.research_cost = 120.0
	industrial_machinery.research_duration_months = 30
	industrial_machinery.required_technology_level = 12.0

	industrial_machinery.add_capability(
		"industrial_production"
	)

	industrial_machinery.add_capability(
		"manufacturing_efficiency"
	)
	
	industrial_machinery.add_effect(
	"industrial_production_efficiency",
	1.10
)

	# Military support:
	# Industrial machinery improves the ability to support
	# military production and logistics.

	industrial_machinery.add_effect(
		"military_industrial_support",
		6.0
	)

	industrial_machinery.add_effect(
		"military_logistics_support",
		3.0
	)

	industrial_machinery.historical_start_year = 1850

	library.add_technology(
		industrial_machinery
	)


	# ========================================================
	# TELECOMMUNICATIONS
	# ========================================================

	var telecommunications = TechnologyData.new(
		"telecommunications",
		"Telecommunications",
		"Long-distance communication infrastructure."
	)

	telecommunications.research_cost = 150.0
	telecommunications.research_duration_months = 30
	telecommunications.required_technology_level = 20.0

	telecommunications.add_prerequisite(
		"electricity"
	)

	telecommunications.add_capability(
		"long_distance_communication"
	)

	telecommunications.add_capability(
		"communications_network"
	)

	# Military support:
	# Long-distance communications improve command and
	# operational coordination.

	telecommunications.add_effect(
		"military_command_capacity",
		6.0
	)

	telecommunications.add_effect(
		"military_logistics_support",
		3.0
	)

	telecommunications.historical_start_year = 1920

	library.add_technology(
		telecommunications
	)


	# ========================================================
	# NUCLEAR PHYSICS
	# ========================================================

	var nuclear_physics = TechnologyData.new(
		"nuclear_physics",
		"Nuclear Physics",
		"Scientific knowledge required for nuclear research."
	)

	nuclear_physics.research_cost = 300.0
	nuclear_physics.research_duration_months = 48
	nuclear_physics.required_technology_level = 35.0

	nuclear_physics.add_prerequisite(
		"electricity"
	)

	nuclear_physics.add_capability(
		"nuclear_research"
	)

	nuclear_physics.add_capability(
		"nuclear_engineering"
	)

	nuclear_physics.add_effect(
		"nuclear_research_capacity",
		10.0
	)

	nuclear_physics.add_effect(
		"advanced_scientific_capacity",
		5.0
	)

	# Military support:
	# Nuclear physics contributes to advanced military
	# technology capacity without directly creating weapons.

	nuclear_physics.add_effect(
		"military_technology_support",
		5.0
	)

	nuclear_physics.historical_start_year = 1930

	library.add_technology(
		nuclear_physics
	)


	# ========================================================
	# COMPUTERS
	# ========================================================

	var computers = TechnologyData.new(
		"computers",
		"Computers",
		"Electronic computing and early automation."
	)

	computers.research_cost = 350.0
	computers.research_duration_months = 48
	computers.required_technology_level = 40.0

	computers.add_prerequisite(
		"electricity"
	)

	computers.add_prerequisite(
		"industrial_machinery"
	)

	computers.add_capability(
		"electronic_computing"
	)

	computers.add_capability(
		"automation"
	)

	# Military support:
	# Early computing provides additional command and
	# technological support.

	computers.add_effect(
		"military_command_capacity",
		3.0
	)

	computers.add_effect(
		"military_technology_support",
		4.0
	)

	computers.historical_start_year = 1940

	library.add_technology(
		computers
	)


	# ========================================================
	# SEMICONDUCTORS
	# ========================================================

	var semiconductors = TechnologyData.new(
		"semiconductors",
		"Semiconductors",
		"Advanced electronic components and microelectronics."
	)

	semiconductors.research_cost = 500.0
	semiconductors.research_duration_months = 60
	semiconductors.required_technology_level = 50.0

	semiconductors.add_prerequisite(
		"computers"
	)

	semiconductors.add_capability(
		"advanced_electronics"
	)

	semiconductors.add_capability(
		"microelectronics"
	)

	semiconductors.add_effect(
		"military_command_capacity",
		5.0
	)

	semiconductors.add_effect(
		"military_technology_support",
		6.0
	)

	semiconductors.historical_start_year = 1950

	library.add_technology(
		semiconductors
	)


	# ========================================================
	# NUCLEAR POWER
	# ========================================================

	var nuclear_power = TechnologyData.new(
		"nuclear_power",
		"Nuclear Power",
		"Controlled nuclear energy for power generation."
	)

	nuclear_power.research_cost = 450.0
	nuclear_power.research_duration_months = 60
	nuclear_power.required_technology_level = 50.0

	nuclear_power.add_prerequisite(
		"nuclear_physics"
	)

	nuclear_power.add_capability(
		"nuclear_energy"
	)

	nuclear_power.add_capability(
		"advanced_power_generation"
	)

	nuclear_power.historical_start_year = 1950

	library.add_technology(
		nuclear_power
	)


	# ========================================================
	# SATELLITES
	# ========================================================

	var satellites = TechnologyData.new(
		"satellites",
		"Satellites",
		"Orbital technology for communications and observation."
	)

	satellites.research_cost = 600.0
	satellites.research_duration_months = 72
	satellites.required_technology_level = 60.0

	satellites.add_prerequisite(
		"computers"
	)

	satellites.add_prerequisite(
		"telecommunications"
	)

	satellites.add_capability(
		"satellite_communication"
	)

	satellites.add_capability(
		"space_observation"
	)

	satellites.historical_start_year = 1957

	library.add_technology(
		satellites
	)


	# ========================================================
	# INTERNET
	# ========================================================

	var internet = TechnologyData.new(
		"internet",
		"Internet",
		"Global digital networking and information exchange."
	)

	internet.research_cost = 800.0
	internet.research_duration_months = 84
	internet.required_technology_level = 70.0

	internet.add_prerequisite(
		"computers"
	)

	internet.add_prerequisite(
		"semiconductors"
	)

	internet.add_prerequisite(
		"telecommunications"
	)

	internet.add_capability(
		"digital_networking"
	)

	internet.add_capability(
		"global_information_network"
	)

	internet.historical_start_year = 1969

	library.add_technology(
		internet
	)


	return library
