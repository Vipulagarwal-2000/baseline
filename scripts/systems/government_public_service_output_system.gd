class_name GovernmentPublicServiceOutputSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.7
# PUBLIC-SERVICE OUTPUT
# ============================================================
#
# Step 8.6 determines where total government spending goes.
# Step 8.7 turns the existing public-services allocation into an
# observable aggregate service/output signal.
#
# MVP rule:
#   public-service output = public-services spending
#   public-service capacity = public-service output / total government spending
#
# This deliberately avoids an invented service production function,
# detailed ministries, quality models, implementation capacity or welfare
# effects. Those are outside this substep and later steps own them.
#
# EconomyComponent remains the owner of total government_spending.
# GovernmentComponent remains the owner of allocation and service-output
# diagnostics.
# ============================================================

const EPSILON: float = 0.000001


func _init() -> void:
	super("government_public_service_output_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component("government")
		var economy = entity.get_component("economy")

		if government == null or economy == null:
			continue

		_process_country(
			entity,
			government,
			economy
		)


func _process_country(entity, government, economy) -> void:

	var raw_allocation = government.get_state(
		"government_spending_allocation",
		{}
	)

	if not raw_allocation is Dictionary:
		_record_result(
			government,
			"rejected",
			["invalid_spending_allocation_state"],
			{}
		)
		return

	var allocation: Dictionary = raw_allocation

	var raw_total = economy.get_state(
		"government_spending",
		0.0
	)

	if not (raw_total is int or raw_total is float):
		_record_result(
			government,
			"rejected",
			["invalid_government_spending"],
			{}
		)
		return

	var government_spending: float = maxf(
		float(raw_total),
		0.0
	)

	var raw_allocation_total = government.get_state(
		"government_spending_allocation_total",
		0.0
	)

	if not (raw_allocation_total is int or raw_allocation_total is float):
		_record_result(
			government,
			"rejected",
			["invalid_spending_allocation_total"],
			{}
		)
		return

	var allocation_total: float = maxf(
		float(raw_allocation_total),
		0.0
	)

	if not is_equal_approx(
		allocation_total,
		government_spending
	):
		_record_result(
			government,
			"rejected",
			["allocation_total_does_not_match_government_spending"],
			{}
		)
		return

	var raw_public_services = allocation.get(
		"public_services",
		0.0
	)

	if not (raw_public_services is int or raw_public_services is float):
		_record_result(
			government,
			"rejected",
			["invalid_public_services_allocation"],
			{}
		)
		return

	var public_service_spending: float = clampf(
		float(raw_public_services),
		0.0,
		government_spending
	)

	var public_service_output: float = public_service_spending

	var public_service_capacity: float = 0.0

	if government_spending > EPSILON:
		public_service_capacity = clampf(
			public_service_output / government_spending,
			0.0,
			1.0
		)

	var population = entity.get_component("population")
	var population_value: float = 0.0

	if population != null:
		population_value = maxf(
			float(
				population.get_state(
					"total_population",
					0.0
				)
			),
			0.0
		)

	var public_service_output_per_capita: float = 0.0

	if population_value > EPSILON:
		public_service_output_per_capita = (
			public_service_output
			/ population_value
		)

	var ledger: Dictionary = {
		"government_spending": government_spending,
		"public_service_spending": public_service_spending,
		"public_service_output": public_service_output,
		"public_service_capacity": public_service_capacity,
		"population": population_value,
		"public_service_output_per_capita": public_service_output_per_capita
	}

	var current_output: float = float(
		government.get_state(
			"public_service_output",
			0.0
		)
	)

	var current_capacity: float = float(
		government.get_state(
			"public_service_capacity",
			0.0
		)
	)

	var current_spending: float = float(
		government.get_state(
			"public_service_spending",
			0.0
		)
	)

	var current_per_capita: float = float(
		government.get_state(
			"public_service_output_per_capita",
			0.0
		)
	)

	var unchanged: bool = (
		is_equal_approx(current_spending, public_service_spending)
		and is_equal_approx(current_output, public_service_output)
		and is_equal_approx(current_capacity, public_service_capacity)
		and is_equal_approx(current_per_capita, public_service_output_per_capita)
	)

	if unchanged:
		_record_result(
			government,
			"no_change",
			[],
			ledger
		)
		return

	government.set_state(
		"public_service_spending",
		public_service_spending
	)
	government.set_state(
		"public_service_output",
		public_service_output
	)
	government.set_state(
		"public_service_capacity",
		public_service_capacity
	)
	government.set_state(
		"public_service_output_per_capita",
		public_service_output_per_capita
	)
	government.set_state(
		"public_service_output_ledger",
		ledger.duplicate(true)
	)

	_record_result(
		government,
		"applied",
		[],
		ledger
	)


func _record_result(
	government,
	action: String,
	errors: Array,
	result_data: Dictionary
	) -> void:

	var previous_revision: int = int(
		government.get_state(
			"public_service_output_revision",
			0
		)
	)

	var changed: bool = (
		action == "applied"
	)

	var revision: int = previous_revision

	if changed:
		revision += 1

	var result: Dictionary = {
		"action": action,
		"revision": revision,
		"errors": errors.duplicate(true),
		"output": result_data.duplicate(true)
	}

	if changed:
		var ledger = government.get_state(
			"public_service_output_ledger",
			{}
		)

		if not ledger is Dictionary:
			ledger = {}

		ledger[str(revision)] = result.duplicate(true)
		government.set_state(
			"public_service_output_revision",
			revision
		)
		government.set_state(
			"public_service_output_ledger",
			ledger
		)

	government.set_state(
		"public_service_output_last_result",
		result
	)
