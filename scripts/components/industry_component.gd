class_name IndustryComponent
extends SimComponent


func _init(owner: String = "") -> void:
	super._init("industry", owner)


func setup(
	processes: Dictionary = {},
	process_adoption: Dictionary = {},
	process_adoption_rate: Dictionary = {}
) -> void:

	set_state("processes", processes)

	# ============================================================
	# PROCESS ADOPTION
	# ============================================================

	var adoption := {}

	for process_id in processes.keys():

		var current_adoption := 1.0

		if process_adoption.has(process_id):
			current_adoption = clampf(
				float(process_adoption[process_id]),
				0.0,
				1.0
			)

		adoption[process_id] = current_adoption

	# Preserve explicitly supplied adoption values even if a
	# process is not present in the process dictionary.
	for process_id in process_adoption.keys():

		if not adoption.has(process_id):
			adoption[process_id] = clampf(
				float(process_adoption[process_id]),
				0.0,
				1.0
			)

	set_state("process_adoption", adoption)


	# ============================================================
	# PROCESS ADOPTION TARGET
	# ============================================================

	var adoption_targets := {}

	for process_id in adoption.keys():

		adoption_targets[process_id] = adoption[process_id]

	set_state(
		"process_adoption_target",
		adoption_targets
	)


	# ============================================================
	# PROCESS ADOPTION RATE
	# ============================================================

	var adoption_rates := {}

	for process_id in adoption.keys():

		var rate := 0.0

		if process_adoption_rate.has(process_id):
			rate = clampf(
				float(process_adoption_rate[process_id]),
				0.0,
				1.0
			)

		adoption_rates[process_id] = rate

	for process_id in process_adoption_rate.keys():

		if not adoption_rates.has(process_id):
			adoption_rates[process_id] = clampf(
				float(process_adoption_rate[process_id]),
				0.0,
				1.0
			)

	set_state(
		"process_adoption_rate",
		adoption_rates
	)


	# ============================================================
	# PROCESS TRANSITION STATE
	# ============================================================

	var transition_state := {}

	for process_id in adoption.keys():

		var current_adoption :float= adoption[process_id]
		var adoption_rate :float= adoption_rates.get(
			process_id,
			0.0
		)

		transition_state[process_id] = {
			"active": false,
			"elapsed_months": 0,
			"duration_months": 0,
			"start_adoption": current_adoption,
			"target_adoption": current_adoption,
			"adoption_rate": adoption_rate,
			"progress": 0.0,
			"transition_cost": 0.0,
			"cost_per_month": 0.0,
			"accumulated_cost": 0.0
		}

	set_state(
		"process_transition_state",
		transition_state
	)


	# ============================================================
	# PROCESS ADOPTION ALLOCATION
	# ============================================================
	#
	# This is the Step 8 state-model layer.
	#
	# Adoption represents each process's share/allocation.
	# Values are always constrained to 0..1.
	#
	# We deliberately do NOT normalize automatically during setup.
	# This allows:
	#
	#   old = 0.60
	#   new_a = 0.30
	#   new_b = 0.10
	#
	# to coexist as an exact 100% allocation.
	#
	# Normalization is an explicit operation.

	set_state(
		"process_adoption_allocation",
		adoption.duplicate(true)
	)


	# ============================================================
	# STEP 10E — PERSISTENT PRODUCTION OUTCOME STATE
	# ============================================================
	#
	# ProductionProcessSystem writes the most recent process outcome
	# and cumulative process totals here after each attempted execution.
	# This is state only; it does not perform production itself.

	set_state(
		"production_state",
		{}
	)

	set_state(
		"production_totals",
		{}
	)


# ================================================================
# STEP 2 — ADOPTION RATE
# ================================================================

static func calculate_next_adoption(
	current_adoption: float,
	target_adoption: float,
	adoption_rate: float
) -> float:

	var current := clampf(
		current_adoption,
		0.0,
		1.0
	)

	var target := clampf(
		target_adoption,
		0.0,
		1.0
	)

	var rate := clampf(
		adoption_rate,
		0.0,
		1.0
	)

	if is_equal_approx(current, target):
		return target

	if rate <= 0.0:
		return current

	if target > current:
		return minf(
			current + rate,
			target
		)

	return maxf(
		current - rate,
		target
	)


# ================================================================
# STEP 3 — TRANSITION PROGRESS
# ================================================================

static func calculate_transition_progress(
	elapsed_months: int,
	duration_months: int
) -> float:

	if duration_months <= 0:
		return 1.0

	return clampf(
		float(elapsed_months)
		/ float(duration_months),
		0.0,
		1.0
	)


static func calculate_transition_adoption(
	start_adoption: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var start := clampf(
		start_adoption,
		0.0,
		1.0
	)

	var target := clampf(
		target_adoption,
		0.0,
		1.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return clampf(
		start
		+ (target - start) * progress,
		0.0,
		1.0
	)


# ================================================================
# STEP 4 — TRANSITION COST
# ================================================================

static func calculate_transition_cost_per_month(
	total_transition_cost: float,
	duration_months: int
) -> float:

	var cost := maxf(
		total_transition_cost,
		0.0
	)

	if duration_months <= 0:
		return cost

	return cost / float(duration_months)


static func calculate_accumulated_transition_cost(
	total_transition_cost: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var cost := maxf(
		total_transition_cost,
		0.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return cost * progress


# ================================================================
# STEP 5 — NEW PROCESS CAPACITY
# ================================================================

static func calculate_transition_capacity(
	initial_capacity: float,
	target_capacity: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var initial := maxf(
		initial_capacity,
		0.0
	)

	var target := maxf(
		target_capacity,
		0.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return maxf(
		initial
		+ (target - initial) * progress,
		0.0
	)


static func calculate_new_process_capacity(
	target_capacity: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var capacity := maxf(
		target_capacity,
		0.0
	)

	var adoption := clampf(
		target_adoption,
		0.0,
		1.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return capacity * adoption * progress


# ================================================================
# STEP 6 — OLD PROCESS DISPLACEMENT
# ================================================================

static func calculate_displaced_capacity(
	initial_capacity: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var capacity := maxf(
		initial_capacity,
		0.0
	)

	var adoption := clampf(
		target_adoption,
		0.0,
		1.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return capacity * adoption * progress


static func calculate_remaining_old_process_capacity(
	initial_capacity: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var capacity := maxf(
		initial_capacity,
		0.0
	)

	var displaced := calculate_displaced_capacity(
		capacity,
		target_adoption,
		elapsed_months,
		duration_months
	)

	return maxf(
		capacity - displaced,
		0.0
	)


# ----------------------------------------------------------------
# Compatibility wrappers for the existing Step 6 test API.
# Preserve the Step 6 semantics while exposing the names used by
# IndustryProcessDisplacementTest.gd.
# ----------------------------------------------------------------

static func calculate_old_process_capacity(
	initial_capacity: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	return calculate_remaining_old_process_capacity(
		initial_capacity,
		target_adoption,
		elapsed_months,
		duration_months
	)


static func calculate_process_displacement(
	initial_capacity: float,
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	return calculate_displaced_capacity(
		initial_capacity,
		target_adoption,
		elapsed_months,
		duration_months
	)


# ================================================================
# STEP 7 — OBSOLESCENCE
# ================================================================

static func is_process_obsolete(
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> bool:

	var adoption := clampf(
		target_adoption,
		0.0,
		1.0
	)

	if adoption < 1.0:
		return false

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return is_equal_approx(
		progress,
		1.0
	)


static func calculate_obsolescence_progress(
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	var adoption := clampf(
		target_adoption,
		0.0,
		1.0
	)

	var progress := calculate_transition_progress(
		elapsed_months,
		duration_months
	)

	return clampf(
		adoption * progress,
		0.0,
		1.0
	)


# ----------------------------------------------------------------
# Compatibility wrappers for the existing Step 7 test API.
# Preserve the Step 7 semantics while exposing the names used by
# IndustryProcessObsolescenceTest.gd.
# ----------------------------------------------------------------

static func calculate_process_obsolescence(
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> bool:

	return is_process_obsolete(
		target_adoption,
		elapsed_months,
		duration_months
	)


static func calculate_process_obsolescence_progress(
	target_adoption: float,
	elapsed_months: int,
	duration_months: int
) -> float:

	return calculate_obsolescence_progress(
		target_adoption,
		elapsed_months,
		duration_months
	)


# ================================================================
# STEP 8 — COMPETING PROCESSES / PARTIAL ADOPTION
# ================================================================

static func clamp_process_adoption(
	adoption: float
) -> float:

	return clampf(
		adoption,
		0.0,
		1.0
	)


static func build_process_adoption_allocation(
	process_adoption: Dictionary
) -> Dictionary:

	var allocation := {}

	for process_id in process_adoption.keys():

		allocation[process_id] = clamp_process_adoption(
			float(process_adoption[process_id])
		)

	return allocation


static func calculate_adoption_total(
	process_adoption: Dictionary
) -> float:

	var total := 0.0

	for process_id in process_adoption.keys():

		total += clamp_process_adoption(
			float(process_adoption[process_id])
		)

	return total


static func normalize_process_adoption(
	process_adoption: Dictionary
) -> Dictionary:

	var allocation := build_process_adoption_allocation(
		process_adoption
	)

	var total := calculate_adoption_total(
		allocation
	)

	if total <= 0.0:
		return allocation

	var normalized := {}

	for process_id in allocation.keys():

		normalized[process_id] = (
			allocation[process_id]
			/ total
		)

	return normalized


static func is_valid_process_allocation(
	process_adoption: Dictionary
) -> bool:

	var total := calculate_adoption_total(
		process_adoption
	)

	return (
		total >= 0.0
		and total <= 1.0 + 0.000001
	)


static func get_process_adoption_share(
	process_adoption: Dictionary,
	process_id: String
) -> float:

	if not process_adoption.has(process_id):
		return 0.0

	return clamp_process_adoption(
		float(process_adoption[process_id])
	)


# ================================================================
# STEP 10A — INFRASTRUCTURE / CAPABILITY PRESSURE
# ================================================================
#
# These helpers measure the pressure created by adoption.
# They do not modify infrastructure, capabilities, investment,
# construction, or production capacity.
#
# Infrastructure pressure uses infrastructure_usage because that
# field represents capacity consumption. infrastructure_requirements
# remain eligibility requirements handled by the existing evaluator.
# ================================================================

static func calculate_adoption_scaled_requirements(
	requirements: Dictionary,
	adoption: float
) -> Dictionary:

	var scaled := {}
	var adoption_value := clampf(
		adoption,
		0.0,
		1.0
	)

	for requirement_id in requirements.keys():

		var requirement_value = requirements[requirement_id]

		if requirement_value is float or requirement_value is int:
			scaled[requirement_id] = (
				maxf(float(requirement_value), 0.0)
				* adoption_value
			)
		else:
			# Non-numeric requirements do not create artificial
			# numeric pressure.
			scaled[requirement_id] = requirement_value

	return scaled


static func calculate_requirement_gap(
	required: float,
	available: float
) -> float:

	var required_value := maxf(
		required,
		0.0
	)

	var available_value := maxf(
		available,
		0.0
	)

	return maxf(
		required_value - available_value,
		0.0
	)


static func calculate_process_infrastructure_pressure(
	process: Dictionary,
	adoption: float
) -> Dictionary:

	var usage = process.get(
		"infrastructure_usage",
		{}
	)

	if not usage is Dictionary:
		return {}

	return calculate_adoption_scaled_requirements(
		usage,
		adoption
	)


static func calculate_process_capability_pressure(
	process: Dictionary,
	adoption: float
) -> Dictionary:

	var requirements = process.get(
		"capability_requirements",
		{}
	)

	if not requirements is Dictionary:
		return {}

	return calculate_adoption_scaled_requirements(
		requirements,
		adoption
	)


# ================================================================
# STEP 10B — LIVE INFRASTRUCTURE / CAPABILITY AVAILABILITY
# ================================================================
#
# Step 10A calculated adoption-scaled pressure from the process
# definition alone. Step 10B connects that pressure to the current
# entity state so the simulator can measure an actual gap.
#
# This layer is diagnostic only. It does not build infrastructure,
# invest capital, research technology, or change production capacity.
# ================================================================

static func _coerce_process_infrastructure_capacity(value) -> float:

	# Process-specific infrastructure is an installed-capacity quantity,
	# so values are bounded only at zero. Unlike country-level
	# infrastructure factors, values above 1.0 are valid and meaningful.
	if typeof(value) == TYPE_BOOL:
		return 1.0 if bool(value) else 0.0

	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return maxf(float(value), 0.0)

	return 0.0


static func _coerce_live_availability(value) -> float:

	if typeof(value) == TYPE_BOOL:
		return 1.0 if bool(value) else 0.0

	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return clampf(
			float(value),
			0.0,
			1.0
		)

	return 0.0


static func _calculate_requirement_pressure_map(
	required_values: Dictionary,
	available_values: Dictionary,
	source: String
) -> Dictionary:

	var result := {}

	for requirement_name in required_values.keys():

		var required_value := maxf(
			float(required_values[requirement_name]),
			0.0
		)

		var requirement_id := str(requirement_name)
		var available_value := _coerce_live_availability(
			available_values.get(
				requirement_id,
				0.0
			)
		)

		var gap := calculate_requirement_gap(
			required_value,
			available_value
		)

		var coverage := 1.0
		if required_value > 0.0:
			coverage = clampf(
				available_value / required_value,
				0.0,
				1.0
			)

		result[requirement_id] = {
			"required": required_value,
			"available": available_value,
			"gap": gap,
			"coverage": coverage,
			"pressure": gap,
			"source": source
		}

	return result


static func calculate_process_requirement_pressure(
	process: Dictionary,
	adoption: float,
	infrastructure_available: Dictionary = {},
	capability_available: Dictionary = {}
) -> Dictionary:

	if typeof(process) != TYPE_DICTIONARY:
		return {
			"adoption": clamp_process_adoption(adoption),
			"infrastructure": {},
			"capability": {}
		}

	var scaled_infrastructure := calculate_process_infrastructure_pressure(
		process,
		adoption
	)

	var scaled_capabilities := calculate_process_capability_pressure(
		process,
		adoption
	)

	var infrastructure_gaps := _calculate_requirement_pressure_map(
		scaled_infrastructure,
		infrastructure_available,
		"live_infrastructure"
	)

	var capability_gaps := _calculate_requirement_pressure_map(
		scaled_capabilities,
		capability_available,
		"live_capability"
	)

	return {
		"adoption": clamp_process_adoption(adoption),
		"infrastructure": infrastructure_gaps,
		"capability": capability_gaps
	}


static func get_entity_infrastructure_availability(
	entity
) -> Dictionary:

	var availability := {}

	if entity == null:
		return availability

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	if infrastructure != null:

		# Raw component state is the existing source used by the
		# infrastructure bottleneck path for named components.
		var infrastructure_state = infrastructure.state

		if typeof(infrastructure_state) == TYPE_DICTIONARY:
			for infrastructure_name in infrastructure_state.keys():

				var value = infrastructure_state[infrastructure_name]

				if typeof(value) == TYPE_BOOL \
				or typeof(value) == TYPE_INT \
				or typeof(value) == TYPE_FLOAT:
					availability[str(infrastructure_name)] = (
						_coerce_live_availability(value)
					)

		# Effective values can provide specialized keys that are not
		# explicitly stored on the component. Existing named component
		# values remain authoritative, matching the current bottleneck path.
		var effective_capacity = infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		)

		if typeof(effective_capacity) == TYPE_DICTIONARY:
			for infrastructure_name in effective_capacity.keys():

				var key := str(infrastructure_name)

				if not availability.has(key):
					availability[key] = (
						_coerce_live_availability(
							effective_capacity[infrastructure_name]
						)
					)

	# Named process-specific infrastructure capacity is owned by the
	# InfrastructureComponent. This is intentionally separate from the
	# seven normalized national infrastructure dimensions and from the
	# ResourceComponent compatibility bridge.
	#
	# IMPORTANT UNIT BOUNDARY:
	# process_infrastructure_capacity stores installed process capacity,
	# not a normalized 0..1 availability factor. Values such as 2.0 or
	# 5.0 must therefore remain intact. The normalized coercion used by
	# country-level infrastructure dimensions must not be reused here.
	var process_capacity = infrastructure.get_state(
		"process_infrastructure_capacity",
		{}
	)

	if typeof(process_capacity) == TYPE_DICTIONARY:
		for infrastructure_name in process_capacity.keys():

			var key := str(infrastructure_name)

			availability[key] = _coerce_process_infrastructure_capacity(
				process_capacity[infrastructure_name]
			)

	# Generic resource infrastructure capacity remains a compatibility
	# bridge. It only fills process-infrastructure names that do not have
	# an explicit authoritative value on InfrastructureComponent.
	var resources = entity.get_component(
		"resources"
	)

	if resources != null:
		var resource_infrastructure_capacity = resources.get_state(
			"infrastructure_capacity",
			{}
		)

		if typeof(resource_infrastructure_capacity) == TYPE_DICTIONARY:
			for infrastructure_name in resource_infrastructure_capacity.keys():

				var key := str(infrastructure_name)

				if not availability.has(key):
					availability[key] = (
						_coerce_live_availability(
							resource_infrastructure_capacity[infrastructure_name]
						)
					)

	return availability


static func get_entity_capability_availability(
	entity
) -> Dictionary:

	var availability := {}

	if entity == null:
		return availability

	var capabilities = entity.get_sim_metadata(
		"capabilities",
		{}
	)

	if typeof(capabilities) != TYPE_DICTIONARY:
		return availability

	for capability_name in capabilities.keys():

		availability[str(capability_name)] = (
			_coerce_live_availability(
				capabilities[capability_name]
			)
		)

	return availability


static func calculate_entity_process_requirement_pressure(
	entity,
	process: Dictionary,
	adoption: float
) -> Dictionary:

	if entity == null:
		return {
			"adoption": clamp_process_adoption(adoption),
			"infrastructure": {},
			"capability": {}
		}

	return calculate_process_requirement_pressure(
		process,
		adoption,
		get_entity_infrastructure_availability(entity),
		get_entity_capability_availability(entity)
	)


# ================================================================
# STEP 10C — OPERATIONAL CONSEQUENCE
# ================================================================
#
# Step 10C converts the Step 10B live requirement state into a
# deterministic production-capacity consequence without creating a
# second production engine.
#
# Rules:
# 1. Process adoption scales the installed/base capacity.
# 2. Infrastructure usage is a proportional operational bottleneck.
# 3. Infrastructure requirements remain hard eligibility gates,
#    matching ProductionProcessSystem's existing requirement evaluator.
# 4. Capability requirements remain hard eligibility gates,
#    matching the existing production requirement architecture.
# 5. The result is diagnostic/reusable and does not mutate world state.
#
# ProductionProcessSystem remains authoritative for actual production.
# ================================================================

static func _calculate_infrastructure_usage_operational_factor(
	process: Dictionary,
	infrastructure_available: Dictionary
) -> Dictionary:

	var usage = process.get(
		"infrastructure_usage",
		{}
	)

	if typeof(usage) != TYPE_DICTIONARY:
		return {
			"factor": 1.0,
			"requirements": {},
			"constrained_by": []
		}

	var factor := 1.0
	var requirements := {}
	var constrained_by: Array[String] = []

	for infrastructure_name in usage.keys():

		var raw_requirement = usage[infrastructure_name]

		if (
			typeof(raw_requirement) != TYPE_INT
			and
			typeof(raw_requirement) != TYPE_FLOAT
		):
			continue

		var required_per_capacity := maxf(
			float(raw_requirement),
			0.0
		)

		if required_per_capacity <= 0.0:
			continue

		var key := str(infrastructure_name)
		# infrastructure_available is already resolved into each
		# infrastructure key's native unit. Country-level values are
		# normalized 0..1; process-specific installed capacities may be
		# greater than 1. Do not re-normalize the resolved value here.
		var available := maxf(
			float(
				infrastructure_available.get(
					key,
					0.0
				)
			),
			0.0
		)

		var local_factor := clampf(
			available / required_per_capacity,
			0.0,
			1.0
		)

		factor = minf(
			factor,
			local_factor
		)

		requirements[key] = {
			"required_per_capacity": required_per_capacity,
			"available": available,
			"factor": local_factor,
			"shortfall": maxf(
				required_per_capacity - available,
				0.0
			)
		}

		if local_factor < 1.0:
			constrained_by.append(key)

	return {
		"factor": factor,
		"requirements": requirements,
		"constrained_by": constrained_by
	}


static func _calculate_numeric_requirement_gate(
	requirements: Dictionary,
	available_values: Dictionary
) -> Dictionary:

	var factor := 1.0
	var unmet: Array[String] = []
	var evaluated := {}
	var skipped_non_numeric: Array[String] = []

	if typeof(requirements) != TYPE_DICTIONARY:
		return {
			"factor": 1.0,
			"met": true,
			"unmet": unmet,
			"evaluated": evaluated,
			"skipped_non_numeric": skipped_non_numeric
		}

	for requirement_name in requirements.keys():

		var raw_required = requirements[requirement_name]
		var key := str(requirement_name)

		if (
			typeof(raw_required) != TYPE_INT
			and
			typeof(raw_required) != TYPE_FLOAT
		):
			# Non-numeric requirements remain governed by the existing
			# requirement evaluator. They are deliberately not converted
			# into an artificial numeric capacity factor here.
			skipped_non_numeric.append(key)
			continue

		var required := maxf(
			float(raw_required),
			0.0
		)

		var available := _coerce_live_availability(
			available_values.get(
				key,
				0.0
			)
		)

		var met := available >= required

		evaluated[key] = {
			"required": required,
			"available": available,
			"met": met,
			"gap": calculate_requirement_gap(
				required,
				available
			)
		}

		if not met:
			factor = 0.0
			unmet.append(key)

	return {
		"factor": factor,
		"met": unmet.is_empty(),
		"unmet": unmet,
		"evaluated": evaluated,
		"skipped_non_numeric": skipped_non_numeric
	}


static func calculate_process_operational_consequence(
	process: Dictionary,
	base_capacity: float,
	adoption: float,
	infrastructure_available: Dictionary = {},
	capability_available: Dictionary = {}
) -> Dictionary:

	var adoption_value := clamp_process_adoption(
		adoption
	)

	var base_capacity_value := maxf(
		base_capacity,
		0.0
	)

	var adopted_capacity := (
		base_capacity_value
		* adoption_value
	)

	if typeof(process) != TYPE_DICTIONARY:
		return {
			"adoption": adoption_value,
			"base_capacity": base_capacity_value,
			"adopted_capacity": adopted_capacity,
			"infrastructure_usage_factor": 1.0,
			"infrastructure_requirement_factor": 1.0,
			"capability_requirement_factor": 1.0,
			"operational_factor": 1.0,
			"effective_capacity": adopted_capacity,
			"blocked_by_requirements": false,
			"constraint_sources": []
		}

	var infrastructure_usage_result := (
		_calculate_infrastructure_usage_operational_factor(
			process,
			infrastructure_available
		)
	)

	var infrastructure_requirement_gate := (
		_calculate_numeric_requirement_gate(
			process.get(
				"infrastructure_requirements",
				{}
			),
			infrastructure_available
		)
	)

	var capability_requirement_gate := (
		_calculate_numeric_requirement_gate(
			process.get(
				"capability_requirements",
				{}
			),
			capability_available
		)
	)

	var infrastructure_usage_factor := clampf(
		float(
			infrastructure_usage_result.get(
				"factor",
				1.0
			)
		),
		0.0,
		1.0
	)

	var infrastructure_requirement_factor := clampf(
		float(
			infrastructure_requirement_gate.get(
				"factor",
				1.0
			)
		),
		0.0,
		1.0
	)

	var capability_requirement_factor := clampf(
		float(
			capability_requirement_gate.get(
				"factor",
				1.0
			)
		),
		0.0,
		1.0
	)

	var operational_factor: float = minf(
		infrastructure_usage_factor,
		infrastructure_requirement_factor
	)

	operational_factor = minf(
		operational_factor,
		capability_requirement_factor
	)

	var constraint_sources: Array[String] = []

	for source_name in infrastructure_usage_result.get(
		"constrained_by",
		[]
	):
		constraint_sources.append(
			"infrastructure_usage:" + str(source_name)
		)

	for source_name in infrastructure_requirement_gate.get(
		"unmet",
		[]
	):
		constraint_sources.append(
			"infrastructure_requirement:" + str(source_name)
		)

	for source_name in capability_requirement_gate.get(
		"unmet",
		[]
	):
		constraint_sources.append(
			"capability_requirement:" + str(source_name)
		)

	var effective_capacity: float = (
		adopted_capacity
		* clampf(
			float(operational_factor),
			0.0,
			1.0
		)
	)

	var blocked_by_requirements := (
		adopted_capacity > 0.0
		and
		(
			infrastructure_requirement_factor <= 0.0
			or
			capability_requirement_factor <= 0.0
		)
	)

	return {
		"adoption": adoption_value,
		"base_capacity": base_capacity_value,
		"adopted_capacity": adopted_capacity,
		"infrastructure_usage_factor": infrastructure_usage_factor,
		"infrastructure_requirement_factor": infrastructure_requirement_factor,
		"capability_requirement_factor": capability_requirement_factor,
		"operational_factor": clampf(
			operational_factor,
			0.0,
			1.0
		),
		"effective_capacity": effective_capacity,
		"blocked_by_requirements": blocked_by_requirements,
		"constraint_sources": constraint_sources,
		"infrastructure_usage": infrastructure_usage_result.get(
			"requirements",
			{}
		),
		"infrastructure_requirements": infrastructure_requirement_gate.get(
			"evaluated",
			{}
		),
		"capability_requirements": capability_requirement_gate.get(
			"evaluated",
			{}
		),
		"skipped_non_numeric_infrastructure_requirements": (
			infrastructure_requirement_gate.get(
				"skipped_non_numeric",
				[]
			)
		),
		"skipped_non_numeric_capability_requirements": (
			capability_requirement_gate.get(
				"skipped_non_numeric",
				[]
			)
		),
		"adoption_scaled_pressure": calculate_process_requirement_pressure(
			process,
			adoption,
			infrastructure_available,
			capability_available
		)
	}


static func calculate_entity_process_operational_consequence(
	entity,
	process: Dictionary,
	base_capacity: float,
	adoption: float
) -> Dictionary:

	if entity == null:
		return calculate_process_operational_consequence(
			process,
			base_capacity,
			adoption,
			{},
			{}
		)

	return calculate_process_operational_consequence(
		process,
		base_capacity,
		adoption,
		get_entity_infrastructure_availability(entity),
		get_entity_capability_availability(entity)
	)


static func calculate_entity_process_operational_consequence_from_state(
	entity,
	process_id: String
) -> Dictionary:

	if entity == null or process_id.is_empty():
		return {}

	var industry = entity.get_component(
		"industry"
	)

	if industry == null:
		return {}

	var processes = industry.get_state(
		"processes",
		{}
	)

	if typeof(processes) != TYPE_DICTIONARY:
		return {}

	var process = processes.get(
		process_id,
		{}
	)

	if typeof(process) != TYPE_DICTIONARY or process.is_empty():
		return {}

	var process_adoption = industry.get_state(
		"process_adoption",
		{}
	)

	var adoption := 1.0

	if typeof(process_adoption) == TYPE_DICTIONARY:
		adoption = clamp_process_adoption(
			float(
				process_adoption.get(
					process_id,
					1.0
				)
			)
		)

	var base_capacity := maxf(
		float(
			process.get(
				"capacity",
				0.0
			)
		),
		0.0
	)

	return calculate_entity_process_operational_consequence(
		entity,
		process,
		base_capacity,
		adoption
	)


static func calculate_entity_process_requirement_pressure_from_state(
	entity,
	process_id: String
) -> Dictionary:

	if entity == null or process_id.is_empty():
		return {}

	var industry = entity.get_component(
		"industry"
	)

	if industry == null:
		return {}

	var processes = industry.get_state(
		"processes",
		{}
	)

	if typeof(processes) != TYPE_DICTIONARY:
		return {}

	var process = processes.get(
		process_id,
		{}
	)

	if typeof(process) != TYPE_DICTIONARY or process.is_empty():
		return {}

	var process_adoption = industry.get_state(
		"process_adoption",
		{}
	)

	var adoption := 1.0

	if typeof(process_adoption) == TYPE_DICTIONARY:
		adoption = clamp_process_adoption(
			float(
				process_adoption.get(
					process_id,
					1.0
				)
			)
		)

	return calculate_entity_process_requirement_pressure(
		entity,
		process,
		adoption
	)

# ================================================================
# STEP 10E — PERSISTENT PRODUCTION OUTCOME STATE
# ================================================================
#
# These methods store production outcomes produced by the authoritative
# ProductionProcessSystem. They do not calculate or execute production.
#
# production_state[process_id] stores the latest outcome.
# production_totals[process_id] stores cumulative totals.
# ================================================================

func record_production_outcome(
	process_id: String,
	outcome: Dictionary
) -> void:

	if process_id.is_empty():
		return

	var production_state = get_state(
		"production_state",
		{}
	)

	if typeof(production_state) != TYPE_DICTIONARY:
		production_state = {}

	var production_totals = get_state(
		"production_totals",
		{}
	)

	if typeof(production_totals) != TYPE_DICTIONARY:
		production_totals = {}

	var normalized := outcome.duplicate(true)

	var actual_production := maxf(
		float(
			normalized.get(
				"actual_production",
				0.0
			)
		),
		0.0
	)

	var status := str(
		normalized.get(
			"status",
			"unknown"
		)
	)

	var blocked := bool(
		normalized.get(
			"blocked",
			false
		)
	)

	normalized["actual_production"] = actual_production
	normalized["status"] = status
	normalized["blocked"] = blocked

	production_state[process_id] = normalized

	var totals = production_totals.get(
		process_id,
		{}
	)

	if typeof(totals) != TYPE_DICTIONARY:
		totals = {}
	else:
		totals = totals.duplicate(true)

	totals["total_production"] = (
		float(
			totals.get(
				"total_production",
				0.0
			)
		)
		+ actual_production
	)

	totals["execution_count"] = (
		int(
			totals.get(
				"execution_count",
				0
			)
		)
		+ 1
	)

	if blocked:
		totals["blocked_count"] = (
			int(
				totals.get(
					"blocked_count",
					0
				)
			)
			+ 1
		)

	if actual_production > 0.0:
		totals["successful_execution_count"] = (
			int(
				totals.get(
					"successful_execution_count",
					0
				)
			)
			+ 1
		)
	else:
		totals["zero_output_count"] = (
			int(
				totals.get(
					"zero_output_count",
					0
				)
			)
			+ 1
		)

	var cumulative_inputs := {}
	var existing_inputs = totals.get(
		"total_inputs_consumed",
		{}
	)

	if typeof(existing_inputs) == TYPE_DICTIONARY:
		cumulative_inputs = existing_inputs.duplicate(true)

	var inputs_consumed = normalized.get(
		"inputs_consumed",
		{}
	)

	if typeof(inputs_consumed) == TYPE_DICTIONARY:
		for resource_id in inputs_consumed.keys():
			var key := str(resource_id)
			cumulative_inputs[key] = (
				float(
					cumulative_inputs.get(
						key,
						0.0
					)
				)
				+ maxf(
					float(inputs_consumed[resource_id]),
					0.0
				)
			)

	totals["total_inputs_consumed"] = cumulative_inputs

	var cumulative_outputs := {}
	var existing_outputs = totals.get(
		"total_outputs_produced",
		{}
	)

	if typeof(existing_outputs) == TYPE_DICTIONARY:
		cumulative_outputs = existing_outputs.duplicate(true)

	var outputs_produced = normalized.get(
		"outputs_produced",
		{}
	)

	if typeof(outputs_produced) == TYPE_DICTIONARY:
		for resource_id in outputs_produced.keys():
			var key := str(resource_id)
			cumulative_outputs[key] = (
				float(
					cumulative_outputs.get(
						key,
						0.0
					)
				)
				+ maxf(
					float(outputs_produced[resource_id]),
					0.0
				)
			)

	totals["total_outputs_produced"] = cumulative_outputs

	var cumulative_byproducts := {}
	var existing_byproducts = totals.get(
		"total_byproducts_produced",
		{}
	)

	if typeof(existing_byproducts) == TYPE_DICTIONARY:
		cumulative_byproducts = existing_byproducts.duplicate(true)

	var byproducts_produced = normalized.get(
		"byproducts_produced",
		{}
	)

	if typeof(byproducts_produced) == TYPE_DICTIONARY:
		for resource_id in byproducts_produced.keys():
			var key := str(resource_id)
			cumulative_byproducts[key] = (
				float(
					cumulative_byproducts.get(
						key,
						0.0
					)
				)
				+ maxf(
					float(byproducts_produced[resource_id]),
					0.0
				)
			)

	totals["total_byproducts_produced"] = cumulative_byproducts
	totals["last_status"] = status
	totals["last_blocked"] = blocked
	totals["last_actual_production"] = actual_production

	production_totals[process_id] = totals

	set_state(
		"production_state",
		production_state
	)

	set_state(
		"production_totals",
		production_totals
	)


func get_production_outcome(
	process_id: String
) -> Dictionary:

	var production_state = get_state(
		"production_state",
		{}
	)

	if typeof(production_state) != TYPE_DICTIONARY:
		return {}

	var outcome = production_state.get(
		process_id,
		{}
	)

	if typeof(outcome) != TYPE_DICTIONARY:
		return {}

	return outcome.duplicate(true)


func get_production_totals(
	process_id: String
) -> Dictionary:

	var production_totals = get_state(
		"production_totals",
		{}
	)

	if typeof(production_totals) != TYPE_DICTIONARY:
		return {}

	var totals = production_totals.get(
		process_id,
		{}
	)

	if typeof(totals) != TYPE_DICTIONARY:
		return {}

	return totals.duplicate(true)
