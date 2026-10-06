class_name DivergenceAnalyzer
extends RefCounted


# ============================================================
# ANALYZE WORLD
# ============================================================

func analyze_world(
	baseline: WorldSnapshot,
	current: WorldSnapshot
) -> Dictionary:

	var result: Dictionary = {
		"baseline_date": {},
		"current_date": {},
		"entities": {},
		"entity_count": 0,
		"world_divergence": 0.0
	}


	# ========================================================
	# VALIDATION
	# ========================================================

	if baseline == null:
		push_error(
			"DivergenceAnalyzer: Baseline snapshot is null."
		)
		return result

	if current == null:
		push_error(
			"DivergenceAnalyzer: Current snapshot is null."
		)
		return result


	# ========================================================
	# DATES
	# ========================================================

	result["baseline_date"] = (
		baseline.date.duplicate(true)
	)

	result["current_date"] = (
		current.date.duplicate(true)
	)


	# ========================================================
	# ENTITY ANALYSIS
	# ========================================================

	var analyzed_count := 0

	for entity_id in current.entities.keys():

		# ----------------------------------------------------
		# Entity did not exist in baseline.
		# ----------------------------------------------------

		if not baseline.entities.has(entity_id):

			var new_entity = current.entities[entity_id]

			result["entities"][entity_id] = {
				"name": new_entity.get(
					"name",
					entity_id
				),
				"entity_type": new_entity.get(
					"entity_type",
					""
				),
				"status": "new",
				"components": {},
				"relationships": {}
			}

			analyzed_count += 1
			continue


		var current_entity = (
			current.entities[entity_id]
		)

		var baseline_entity = (
			baseline.entities[entity_id]
		)


		var entity_result: Dictionary = {
			"name": current_entity.get(
				"name",
				entity_id
			),
			"entity_type": current_entity.get(
				"entity_type",
				""
			),
			"status": "existing",
			"components": {},
			"relationships": {}
		}


		# ====================================================
		# COMPONENTS
		# ====================================================

		var current_components = (
			current_entity.get(
				"components",
				{}
			)
		)

		var baseline_components = (
			baseline_entity.get(
				"components",
				{}
			)
		)


		for component_type in current_components.keys():

			if not baseline_components.has(
				component_type
			):
				continue


			var current_component = (
				current_components[
					component_type
				]
			)

			var baseline_component = (
				baseline_components[
					component_type
				]
			)


			var current_state = (
				current_component.get(
					"state",
					{}
				)
			)

			var baseline_state = (
				baseline_component.get(
					"state",
					{}
				)
			)


			var component_result: Dictionary = {}


			for key in current_state.keys():

				if not baseline_state.has(key):
					continue


				var current_value = (
					current_state[key]
				)

				var baseline_value = (
					baseline_state[key]
				)


				if not _is_numeric(
					current_value
				):
					continue

				if not _is_numeric(
					baseline_value
				):
					continue


				var current_number := float(
					current_value
				)

				var baseline_number := float(
					baseline_value
				)


				var absolute_change := (
					current_number
					- baseline_number
				)


				var percentage_change := 0.0


				if not is_zero_approx(
					baseline_number
				):

					percentage_change = (
						absolute_change
						/ baseline_number
					) * 100.0


				component_result[key] = {
					"current": current_number,
					"baseline": baseline_number,
					"absolute_change": absolute_change,
					"percentage_change": percentage_change
				}


			entity_result["components"][
				component_type
			] = component_result


		# ====================================================
		# RELATIONSHIPS
		# ====================================================

		var current_relationships = (
			current_entity.get(
				"relationships",
				{}
			)
		)

		var baseline_relationships = (
			baseline_entity.get(
				"relationships",
				{}
			)
		)


		for target_id in current_relationships.keys():

			if not baseline_relationships.has(
				target_id
			):
				continue


			var current_relationship = (
				_get_relationship_overall(
					current_relationships[
						target_id
					]
				)
			)

			var baseline_relationship = (
				_get_relationship_overall(
					baseline_relationships[
						target_id
					]
				)
			)


			entity_result["relationships"][
				target_id
			] = {
				"current": current_relationship,
				"baseline": baseline_relationship,
				"change":
					current_relationship
					- baseline_relationship
			}


		# ====================================================
		# SAVE ENTITY
		# ====================================================

		result["entities"][
			entity_id
		] = entity_result

		analyzed_count += 1


	# ========================================================
	# SUMMARY
	# ========================================================

	result["entity_count"] = analyzed_count

	result["world_divergence"] = (
		_calculate_world_divergence(
			result["entities"]
		)
	)


	return result


# ============================================================
# WORLD DIVERGENCE
# ============================================================

func _calculate_world_divergence(
	entities: Dictionary
) -> float:

	if entities.is_empty():
		return 0.0


	var total_change := 0.0
	var change_count := 0


	for entity_id in entities.keys():

		var entity_result = entities[
			entity_id
		]

		if typeof(entity_result) != TYPE_DICTIONARY:
			continue


		var components = entity_result.get(
			"components",
			{}
		)

		if typeof(components) != TYPE_DICTIONARY:
			continue


		for component_type in components.keys():

			var component_result = (
				components[
					component_type
				]
			)

			if typeof(component_result) != TYPE_DICTIONARY:
				continue


			for key in component_result.keys():

				var value = (
					component_result[key]
				)

				if typeof(value) != TYPE_DICTIONARY:
					continue

				if not value.has(
					"percentage_change"
				):
					continue


				total_change += abs(
					float(
						value[
							"percentage_change"
						]
					)
				)

				change_count += 1


	return 0.0 if change_count == 0 else (
		total_change
		/ float(change_count)
	)


# ============================================================
# RELATIONSHIP VALUE
# ============================================================

func _get_relationship_overall(
	value
) -> float:

	if _is_numeric(value):
		return float(value)


	if typeof(value) == TYPE_DICTIONARY:

		return float(
			value.get(
				"overall",
				0.0
			)
		)


	return 0.0


# ============================================================
# NUMERIC CHECK
# ============================================================

func _is_numeric(
	value
) -> bool:

	return (
		typeof(value) == TYPE_INT
		or
		typeof(value) == TYPE_FLOAT
	)
