class_name ProductionProcessRequirementEvaluator
extends RefCounted


static func requirements_met(
	requirements: Dictionary,
	available: Dictionary
) -> bool:

	if requirements.is_empty():
		return true

	if available == null:
		return false

	for requirement_id in requirements.keys():

		var required_value = requirements[
			requirement_id
		]

		var available_value = available.get(
			requirement_id,
			null
		)

		if available_value == null:
			return false

		if not _requirement_satisfied(
			required_value,
			available_value
		):
			return false

	return true


static func get_failed_requirements(
	requirements: Dictionary,
	available: Dictionary
) -> Array:

	var failed: Array = []

	if requirements.is_empty():
		return failed

	if available == null:

		for requirement_id in requirements.keys():
			failed.append(
				str(requirement_id)
			)

		return failed

	for requirement_id in requirements.keys():

		var required_value = requirements[
			requirement_id
		]

		var available_value = available.get(
			requirement_id,
			null
		)

		if available_value == null:

			failed.append(
				str(requirement_id)
			)

			continue

		if not _requirement_satisfied(
			required_value,
			available_value
		):

			failed.append(
				str(requirement_id)
			)

	return failed


static func _requirement_satisfied(
	required_value,
	available_value
) -> bool:

	var required_type := typeof(
		required_value
	)

	var available_type := typeof(
		available_value
	)


	# Boolean requirement:
	#
	# required = true
	# available = true
	#
	# must be explicitly available.

	if required_type == TYPE_BOOL:

		if available_type != TYPE_BOOL:
			return false

		return (
			bool(available_value)
			or not bool(required_value)
		)


	# Numeric requirement:
	#
	# required = 0.5
	# available = 0.7
	#
	# passes because available >= required.

	if (
		required_type == TYPE_INT
		or required_type == TYPE_FLOAT
	):

		if (
			available_type != TYPE_INT
			and available_type != TYPE_FLOAT
		):
			return false

		return (
			float(available_value)
			>= float(required_value)
		)


	# String requirement:
	#
	# Used for categorical requirements.
	#
	# Example:
	# required = "modern"
	# available = "modern"

	if required_type == TYPE_STRING:

		return str(
			available_value
		) == str(
			required_value
		)


	# Dictionary requirement:
	#
	# Nested dictionaries are evaluated recursively.

	if required_type == TYPE_DICTIONARY:

		if available_type != TYPE_DICTIONARY:
			return false

		return requirements_met(
			required_value,
			available_value
		)


	# Arrays are treated as membership requirements.
	#
	# Every required entry must exist in the
	# available array.

	if required_type == TYPE_ARRAY:

		if available_type != TYPE_ARRAY:
			return false

		for required_entry in required_value:

			if not available_value.has(
				required_entry
			):
				return false

		return true


	# Unknown requirement types fail safely
	# instead of silently granting access.

	return false
