class_name GovernmentFeedbackSystem
extends SimulationSystem


# ============================================================
# POPULATION / WELFARE — STEP 9.6
# GOVERNMENT FEEDBACK
# ============================================================
#
# Aggregate bridge only.
#
# Inputs already owned by earlier systems:
# - PopulationComponent.population_response_pressure (9.5)
# - PopulationComponent.welfare_pressure (9.2)
# - GovernmentComponent.political_pressure (9.4)
# - GovernmentComponent.policy_capacity
# - GovernmentComponent.implementation_capacity (8.9)
#
# Outputs are explicit government-response demand/capacity state.
# The existing GovernmentComponent remains the owner of the state.
#
# Because Step 8 government systems already execute earlier in the
# monthly WORLD_UPDATE order, Step 9.6 intentionally creates a
# next-cycle response handoff rather than mutating an already-executed
# Step 8 policy/state transition in the middle of the same cycle.
#
# No automatic policy is selected, paid for, or applied here.
# No approval/stability/legitimacy/political-pressure state is changed.
# ============================================================

const EPSILON: float = 0.000001
const DEFAULT_NEUTRAL_PRESSURE: float = 0.0
const DEFAULT_POLICY_CAPACITY: float = 0.50
const DEFAULT_IMPLEMENTATION_CAPACITY: float = 1.0


func _init() -> void:
	super("government_feedback_system")


func process_month(
	world: WorldState
) -> void:

	if world == null:
		push_error(
            "GovernmentFeedbackSystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		_process_entity(entity)


func _process_entity(
	entity
) -> void:

	var population = entity.get_component(
        "population"
	)

	var government = entity.get_component(
        "government"
	)

	if population == null or government == null:
		return

	var population_response_pressure := clampf(
		maxf(
			float(
				population.get_state(
					"population_response_pressure",
					DEFAULT_NEUTRAL_PRESSURE
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var welfare_pressure := clampf(
		maxf(
			float(
				population.get_state(
					"welfare_pressure",
					DEFAULT_NEUTRAL_PRESSURE
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var political_pressure := clampf(
		maxf(
			float(
				government.get_state(
					"political_pressure",
					DEFAULT_NEUTRAL_PRESSURE
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	# Use the strongest already-derived pressure signal as the
	# government's aggregate response need.
	var response_need := clampf(
		maxf(
			population_response_pressure,
			maxf(welfare_pressure, political_pressure)
		),
		0.0,
		1.0
	)

	var policy_capacity := clampf(
		maxf(
			float(
				government.get_state(
					"policy_capacity",
					DEFAULT_POLICY_CAPACITY
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var implementation_capacity := clampf(
		maxf(
			float(
				government.get_state(
					"implementation_capacity",
					DEFAULT_IMPLEMENTATION_CAPACITY
				)
			),
			0.0
		),
		0.0,
		1.0
	)

	var response_capacity := clampf(
		policy_capacity * implementation_capacity,
		0.0,
		1.0
	)

	var response_intensity := clampf(
		response_need * response_capacity,
		0.0,
		1.0
	)

	var response_gap := clampf(
		response_need - response_intensity,
		0.0,
		1.0
	)

	var ledger: Dictionary = {
		"population_response_pressure": population_response_pressure,
		"welfare_pressure": welfare_pressure,
		"political_pressure": political_pressure,
		"response_need": response_need,
		"policy_capacity": policy_capacity,
		"implementation_capacity": implementation_capacity,
		"response_capacity": response_capacity,
		"response_intensity": response_intensity,
		"response_gap": response_gap,
		"next_cycle_handoff": true
	}

	var current_need := clampf(
		float(
			government.get_state(
				"government_response_need",
				DEFAULT_NEUTRAL_PRESSURE
			)
		),
		0.0,
		1.0
	)

	var current_intensity := clampf(
		float(
			government.get_state(
				"government_response_intensity",
				DEFAULT_NEUTRAL_PRESSURE
			)
		),
		0.0,
		1.0
	)

	var current_capacity := clampf(
		float(
			government.get_state(
				"government_response_capacity",
				DEFAULT_NEUTRAL_PRESSURE
			)
		),
		0.0,
		1.0
	)

	var unchanged := (
		is_equal_approx(current_need, response_need)
		and is_equal_approx(current_intensity, response_intensity)
		and is_equal_approx(current_capacity, response_capacity)
	)

	government.set_state(
		"government_response_need",
		response_need
	)

	government.set_state(
		"government_response_capacity",
		response_capacity
	)

	government.set_state(
		"government_response_intensity",
		response_intensity
	)

	government.set_state(
		"government_response_gap",
		response_gap
	)

	government.set_state(
		"government_response_source",
		{
			"population_response_pressure": population_response_pressure,
			"welfare_pressure": welfare_pressure,
			"political_pressure": political_pressure
		}
	)

	government.set_state(
		"government_response_ledger",
		ledger
	)

	if unchanged:
		government.set_state(
			"government_response_last_result",
			{
				"action": "no_change",
				"revision": int(
					government.get_state(
						"government_response_revision",
						0
					)
				),
				"inputs": ledger.duplicate(true)
			}
		)
		return

	var revision := int(
		government.get_state(
			"government_response_revision",
			0
		)
	) + 1

	government.set_state(
		"government_response_revision",
		revision
	)

	government.set_state(
		"government_response_last_result",
		{
			"action": "calculated",
			"revision": revision,
			"inputs": ledger.duplicate(true)
		}
	)
