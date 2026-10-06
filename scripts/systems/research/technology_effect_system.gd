class_name TechnologyEffectSystem
extends SimulationSystem


var technology_manager: TechnologyManager


func _init(
	manager: TechnologyManager = null
):

	super(
		"technology_effect_system"
	)

	if manager == null:

		technology_manager = (
			TechnologyManager.new()
		)

	else:

		technology_manager = manager


# ============================================================
# MONTHLY PROCESSING
# ============================================================

func process_month(
	world: WorldState
) -> void:

	if world == null:

		push_error(
			"TechnologyEffectSystem: World is null."
		)

		return


	for entity in world.entities.values():

		var research = (
			entity.get_component(
				"research"
			)
		)

		if research == null:

			continue


		rebuild_technology_effects(
			research
		)


# ============================================================
# REBUILD ALL TECHNOLOGY EFFECTS
# ============================================================

func rebuild_technology_effects(
	research: ResearchComponent
) -> void:

	if research == null:

		return


	var completed_technologies = (
		research.get_state(
			"technologies",
			{}
		)
	)

	if typeof(
		completed_technologies
	) != TYPE_DICTIONARY:

		completed_technologies = {}


	# --------------------------------------------------------
	# Start from zero every month.
	#
	# This prevents effects from being accidentally applied
	# again and again every simulation tick.
	# --------------------------------------------------------

	var technology_effects: Dictionary = {}


	# --------------------------------------------------------
	# Process every completed technology.
	# --------------------------------------------------------

	for technology_id in (
		completed_technologies.keys()
	):

		if not bool(
			completed_technologies[
				technology_id
			]
		):

			continue


		var technology = (
			technology_manager.get_technology(
				str(technology_id)
			)
		)

		if technology == null:

			continue


		_accumulate_technology_effects(
			technology_effects,
			technology
		)


	# --------------------------------------------------------
	# Store the complete aggregated effect set.
	# --------------------------------------------------------

	research.set_state(
		"technology_effects",
		technology_effects
	)


	# --------------------------------------------------------
	# Also expose individual effects directly in the research
	# component so other systems can easily consume them.
	# --------------------------------------------------------

	for effect_id in technology_effects.keys():

		research.set_state(
			str(effect_id),
			technology_effects[
				effect_id
			]
		)


# ============================================================
# ACCUMULATE ONE TECHNOLOGY
# ============================================================

func _accumulate_technology_effects(
	technology_effects: Dictionary,
	technology: TechnologyData
) -> void:

	if technology == null:

		return


	var effects = (
		technology.get_all_effects()
	)

	if typeof(
		effects
	) != TYPE_DICTIONARY:

		return


	for effect_id in effects.keys():

		var effect_key = str(
			effect_id
		)

		var effect_value = effects[
			effect_id
		]


		# ----------------------------------------------------
		# Numeric technology effects are additive.
		# ----------------------------------------------------

		if (
			typeof(effect_value) == TYPE_INT
			or typeof(effect_value) == TYPE_FLOAT
		):

			var current_value = float(
				technology_effects.get(
					effect_key,
					0.0
				)
			)

			technology_effects[
				effect_key
			] = (
				current_value
				+ float(effect_value)
			)

		else:

			# ------------------------------------------------
			# Non-numeric effects are preserved as-is.
			#
			# We are not using complex non-numeric effects
			# yet, but keeping them here makes the system
			# extensible.
			# ------------------------------------------------

			if not technology_effects.has(
				effect_key
			):

				technology_effects[
					effect_key
				] = effect_value
