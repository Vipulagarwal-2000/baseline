class_name AIUncertainty
extends RefCounted


static func calculate_uncertainty(
	actor,
	option: DecisionOption
) -> float:

	if actor == null:
		return 1.0

	if option == null:
		return 1.0

	var uncertainty = 0.25

	# Limited information increases uncertainty.
	var memory_count = actor.get_memory_count()

	if memory_count < 3:
		uncertainty += 0.20
	elif memory_count < 10:
		uncertainty += 0.10

	# Explicit uncertainty supplied by the option.
	if option.metadata.has("uncertainty"):
		uncertainty += float(
			option.metadata["uncertainty"]
		)

	return clamp(
		uncertainty,
		0.0,
		1.0
	)


static func apply_uncertainty(
	score: float,
	uncertainty: float,
	risk_tolerance: float
) -> float:

	uncertainty = clamp(
		uncertainty,
		0.0,
		1.0
	)

	risk_tolerance = clamp(
		risk_tolerance,
		0.0,
		1.0
	)

	# Risk-tolerant actors are less affected
	# by uncertain outcomes.
	var uncertainty_penalty = (
		uncertainty *
		(1.0 - risk_tolerance)
	)

	return score - uncertainty_penalty
