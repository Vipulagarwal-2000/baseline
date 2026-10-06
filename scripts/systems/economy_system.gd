class_name EconomySystem
extends SimulationSystem


func _init():
	super("economy_system")


func process_month(world: WorldState) -> void:

	if world == null:

		push_error(
			"EconomySystem: World is null."
		)

		return


	for entity in world.entities.values():

		if entity == null:
			continue

		var economy = entity.get_component(
			"economy"
		)

		if economy == null:
			continue

		_update_economy(
			entity,
			economy
		)


func _update_economy(
	entity,
	economy
) -> void:

	# ============================================================
	# INDUSTRY
	# ============================================================

	var industry = entity.get_component(
		"industry"
	)

	var infrastructure = entity.get_component(
		"infrastructure"
	)

	var industrial_capacity: float = 0.0
	var agricultural_capacity: float = 0.0
	var weighted_efficiency: float = 0.0
	var industrial_process_count: int = 0

	# Specialized industrial infrastructure constrains the usable
	# capacity of active production processes.
	# It does not rewrite the configured process capacities.
	var industrial_infrastructure_factor: float = 1.0

	if infrastructure != null:
		industrial_infrastructure_factor = float(
			infrastructure.get_state(
				"industrial",
				1.0
			)
		)

	industrial_infrastructure_factor = clamp(
		industrial_infrastructure_factor,
		0.0,
		1.0
		)


	# ------------------------------------------------------------
	# PREVIOUS INVESTMENT CAPACITY
	# ------------------------------------------------------------

	var investment_capacity := float(
		economy.get_state(
			"investment_capacity",
			0.0
		)
	)

	investment_capacity = max(
		investment_capacity,
		0.0
	)


	if industry != null:

		var processes = industry.get_state(
			"processes",
			{}
		)

		if typeof(processes) == TYPE_DICTIONARY:

			for process_id in processes.keys():

				var process = processes.get(
					process_id,
					null
				)

				if typeof(process) != TYPE_DICTIONARY:
					continue

				var active = bool(
					process.get(
						"active",
						false
					)
				)

				if not active:
					continue


				var capacity := float(
					process.get(
						"capacity",
						0.0
					)
				)

				var efficiency := float(
					process.get(
						"efficiency",
						1.0
					)
				)

				capacity = max(
					capacity,
					0.0
				)

				efficiency = max(
					efficiency,
					0.0
				)

				# Keep the configured process capacity unchanged.
				# Infrastructure limits only the capacity economically
				# usable during this monthly economy calculation.
				var effective_capacity: float = (
					capacity
					* industrial_infrastructure_factor
				)

				industrial_capacity += effective_capacity

				weighted_efficiency += (
					effective_capacity
					* efficiency
				)

				industrial_process_count += 1


				var process_name := str(
					process_id
				).to_lower()

				if (
					"agriculture" in process_name
					or "farming" in process_name
					or "food_agriculture" in process_name
				):

					agricultural_capacity += effective_capacity


	industrial_capacity += investment_capacity


	# ============================================================
	# PRODUCTION EFFICIENCY
	# ============================================================

	var production_efficiency: float = 1.0

	if industrial_capacity > 0.0:

		production_efficiency = (
			weighted_efficiency
			/ (
				industrial_capacity
				- investment_capacity
			)
			if (
				industrial_capacity
				- investment_capacity
			) > 0.0
			else 1.0
		)

	production_efficiency = max(
		production_efficiency,
		0.0
	)

	if industrial_process_count == 0:
		production_efficiency = 1.0


	economy.set_state(
		"industrial_capacity",
		industrial_capacity
	)

	economy.set_state(
		"agricultural_capacity",
		agricultural_capacity
	)

	economy.set_state(
		"production_efficiency",
		production_efficiency
	)


	# ============================================================
	# RESOURCE INTEGRATION
	# ============================================================

	var resources = entity.get_component(
		"resources"
	)

	var resource_efficiency: float = 1.0

	if resources != null:

		resource_efficiency = float(
			resources.get_state(
				"resource_efficiency",
				1.0
			)
		)

	resource_efficiency = max(
		resource_efficiency,
		0.0
	)

	economy.set_state(
		"resource_efficiency",
		resource_efficiency
	)


	# ============================================================
	# STEP 3.2 — RESOURCE SHORTAGES -> ECONOMIC PRESSURE
	# ============================================================
	#
	# ResourceSystem is the authoritative owner of resource shortages.
	# EconomySystem consumes its persisted shortage_ratio state here and
	# converts the most severe resource shortage into a normalized
	# country-level economic pressure value.
	#
	# This is intentionally a bottleneck pressure signal, not yet a
	# second growth/inflation/unemployment model. Later economy
	# integration steps can consume economic_pressure without making
	# this substep silently change existing macro calculations.
	#
	# shortage_ratio is stored by ResourceSystem as 0..100 percent.
	# economic_pressure is stored as a normalized 0..1 value.
	# ============================================================

	var resource_shortage_pressure: float = (
		_calculate_resource_shortage_pressure(
			entity
		)
	)

	var power_shortage_pressure: float = (
		_calculate_power_shortage_pressure(
			entity
		)
	)

	# Economic pressure is the strongest currently measured physical
	# production bottleneck. Resource and power shortages are independent
	# constraint paths, so the most severe normalized pressure is persisted
	# as the country-level signal consumed by later economy layers.
	var economic_pressure: float = maxf(
		resource_shortage_pressure,
		power_shortage_pressure
	)

	economy.set_state(
		"resource_shortage_pressure",
		resource_shortage_pressure
	)

	economy.set_state(
		"power_shortage_pressure",
		power_shortage_pressure
	)

	economy.set_state(
		"economic_pressure",
		economic_pressure
	)


	# ============================================================
	# TECHNOLOGY INTEGRATION
	# ============================================================

	var research = entity.get_component(
		"research"
	)

	var technology_efficiency: float = 1.0

	if research != null:

		var technology_effects = research.get_state(
			"technology_effects",
			{}
		)

		if typeof(technology_effects) == TYPE_DICTIONARY:

			technology_efficiency = float(
				technology_effects.get(
					"industrial_production_efficiency",
					1.0
				)
			)

	technology_efficiency = max(
		technology_efficiency,
		0.0
	)

	economy.set_state(
		"technology_efficiency",
		technology_efficiency
	)


	# ============================================================
	# INFRASTRUCTURE / TRADE
	# ============================================================

	var infrastructure_efficiency: float = float(
		economy.get_state(
			"infrastructure_efficiency",
			1.0
		)
	)

	var trade_efficiency: float = float(
		economy.get_state(
			"trade_efficiency",
			1.0
		)
	)

	infrastructure_efficiency = max(
		infrastructure_efficiency,
		0.0
	)

	trade_efficiency = max(
		trade_efficiency,
		0.0
	)

	economy.set_state(
		"infrastructure_efficiency",
		infrastructure_efficiency
	)

	economy.set_state(
		"trade_efficiency",
		trade_efficiency
	)


	# ============================================================
	# ECONOMIC EFFICIENCY
	# ============================================================

	var economic_efficiency: float = (
		production_efficiency
		* resource_efficiency
		* technology_efficiency
	)

	economic_efficiency = max(
		economic_efficiency,
		0.0
	)

	economy.set_state(
		"economic_efficiency",
		economic_efficiency
	)


	# ============================================================
	# STEP 2.3 — PRODUCTION -> ECONOMIC OUTPUT
	# ============================================================
	#
	# ProductionProcessSystem is the authoritative owner of actual
	# process execution. EconomySystem consumes that persisted outcome
	# here and converts realized physical production into a production
	# activity factor for the monthly economy calculation.
	#
	# This is intentionally not a price model or a full national-accounts
	# model. It establishes the first physical feedback: lower realized
	# production lowers economic growth; higher realized production
	# preserves the existing growth calculation.
	#
	# If no production outcome/capacity state exists, the factor remains
	# neutral at 1.0 so the existing EconomySystem tests and legacy
	# economy-only usage retain their previous behavior.
	# ============================================================

	var physical_production_output: float = (
		_calculate_physical_production_output(
			entity
		)
	)

	var physical_production_capacity: float = (
		_calculate_physical_production_capacity(
			entity
		)
	)

	var production_output_factor: float = 1.0

	if physical_production_capacity > 0.0:
		production_output_factor = clamp(
			physical_production_output
			/ physical_production_capacity,
			0.0,
			1.0
		)

	economy.set_state(
		"physical_production_output",
		physical_production_output
	)

	economy.set_state(
		"physical_production_capacity",
		physical_production_capacity
	)

	economy.set_state(
		"production_output_factor",
		production_output_factor
	)


	# ============================================================
	# BASE ECONOMIC VALUES
	# ============================================================

	var current_gdp: float = float(
		economy.get_state(
			"gdp",
			0.0
		)
	)

	var growth_rate: float = float(
		economy.get_state(
			"growth_rate",
			0.0
		)
	)

	var inflation: float = float(
		economy.get_state(
			"inflation",
			0.0
		)
	)

	var unemployment: float = float(
		economy.get_state(
			"unemployment",
			0.0
		)
	)

	current_gdp = max(
		current_gdp,
		0.0
	)


	# ============================================================
	# EFFECTIVE GROWTH
	# ============================================================

	var effective_growth_rate: float = (
		growth_rate
		* economic_efficiency
		* production_output_factor
	)

	economy.set_state(
		"effective_growth_rate",
		effective_growth_rate
	)


	# ============================================================
	# GDP UPDATE
	# ============================================================

	var monthly_growth_factor: float = (
		effective_growth_rate
		/ 12.0
		/ 100.0
	)

	var new_gdp: float = (
		current_gdp
		+
		(
			current_gdp
			* monthly_growth_factor
		)
	)

	new_gdp = max(
		new_gdp,
		0.0
	)

	economy.set_state(
		"gdp",
		new_gdp
	)


	# ============================================================
	# GDP PER CAPITA
	# ============================================================

	var population = entity.get_component(
		"population"
	)

	if population != null:

		var total_population: float = float(
			population.get_state(
				"total_population",
				0.0
			)
		)

		if total_population > 0.0:

			economy.set_state(
				"gdp_per_capita",
				new_gdp
				/ total_population
			)


	# ============================================================
	# GOVERNMENT REVENUE
	# ============================================================
	#
	# Government revenue is currently represented by a simple
	# GDP-linked tax revenue model.
	#
	# Revenue = GDP × tax revenue rate
	#
	# This is intentionally separate from government spending,
	# treasury and debt. Those will be integrated later.
	# ============================================================

	var tax_revenue_rate: float = float(
		economy.get_state(
			"tax_revenue_rate",
			0.10
		)
	)

	tax_revenue_rate = clamp(
		tax_revenue_rate,
		0.0,
		1.0
	)

	var government_revenue: float = (
		new_gdp
		* tax_revenue_rate
	)

	government_revenue = max(
		government_revenue,
		0.0
	)

	economy.set_state(
		"government_revenue",
		government_revenue
	)
	
	
	# ============================================================
	# GOVERNMENT SPENDING
	# ============================================================
	#
	# Government spending is currently represented by a simple
	# GDP-linked spending model.
	#
	# Spending = GDP × government spending rate
	#
	# Budget balance, treasury and debt are intentionally not
	# calculated here yet.
	# ============================================================

	var government_spending_rate: float = float(
		economy.get_state(
			"government_spending_rate",
			0.10
		)
	)

	government_spending_rate = clamp(
		government_spending_rate,
		0.0,
		1.0
	)

	var government_spending: float = (
		new_gdp
		* government_spending_rate
	)

	government_spending = max(
		government_spending,
		0.0
	)

	economy.set_state(
		"government_spending",
		government_spending
	)


	# ============================================================
	# BUDGET BALANCE
	# ============================================================
	#
	# Budget balance is the difference between government revenue
	# and government spending.
	#
	# Budget balance = government revenue - government spending
	#
	# Positive value = budget surplus.
	# Negative value = budget deficit.
	# ============================================================

	var budget_balance: float = (
		government_revenue
		- government_spending
	)

	economy.set_state(
		"budget_balance",
		budget_balance
	)


	# ============================================================
	# TREASURY
	# ============================================================
	#
	# Treasury carries the government's accumulated cash position
	# from one monthly economy update to the next.
	#
	# Treasury = previous treasury + budget balance
	#
	# A budget surplus increases treasury.
	# A budget deficit decreases treasury.
	#
	# Government debt is intentionally not modified here.
	# ============================================================

	var previous_treasury: float = float(
		economy.get_state(
			"treasury",
			0.0
		)
	)

	var new_treasury: float = (
		previous_treasury
		+ budget_balance
	)

	economy.set_state(
		"treasury",
		new_treasury
	)


	# ============================================================
	# GOVERNMENT DEBT
	# ============================================================
	#
	# Government debt changes according to the monthly budget balance.
	#
	# Debt = previous debt - budget balance
	#
	# A budget surplus reduces debt.
	# A budget deficit increases debt.
	# Debt cannot become negative.
	#
	# Interest, borrowing costs and debt limits are intentionally
	# outside this first debt implementation.
	# ============================================================

	var previous_debt: float = float(
		economy.get_state(
			"government_debt",
			0.0
		)
	)

	var new_debt: float = (
		previous_debt
		- budget_balance
	)

	new_debt = max(
		new_debt,
		0.0
	)

	economy.set_state(
		"government_debt",
		new_debt
	)


	# ============================================================
	# STEP 3.5 — GOVERNMENT FINANCES -> INVESTMENT CAPACITY
	# ============================================================
	#
	# Planned investment is still determined by GDP and the
	# configured investment rate. Government finances now determine
	# how much of that planned investment can become new productive
	# capacity.
	#
	# Fiscal factor:
	#
	#     clamp(1 + budget_balance / GDP, 0, 1)
	#
	# A balanced budget is neutral (1.0).
	# A surplus preserves the full planned investment amount.
	# A deficit reduces the amount that can become capacity.
	#
	# This step deliberately does not add debt service, borrowing
	# costs, sovereign financing or project allocation.
	# ============================================================

	# ============================================================
	# INVESTMENT
	# ============================================================

	var investment_rate: float = float(
		economy.get_state(
			"investment_rate",
			0.10
		)
	)

	investment_rate = max(
		investment_rate,
		0.0
	)

	var investment: float = (
		new_gdp
		* investment_rate
	)

	investment = max(
		investment,
		0.0
	)

	economy.set_state(
		"investment",
		investment
	)


	# ------------------------------------------------------------
	# GOVERNMENT-FINANCE CONSTRAINT ON INVESTMENT CAPACITY
	# ------------------------------------------------------------

	var government_finance_investment_factor: float = 1.0

	if new_gdp > 0.0:
		government_finance_investment_factor = clamp(
			1.0
			+ (
				budget_balance
				/ new_gdp
			),
			0.0,
			1.0
		)

	var government_finance_limited_investment: float = (
		investment
		* government_finance_investment_factor
	)

	government_finance_limited_investment = max(
		government_finance_limited_investment,
		0.0
	)

	economy.set_state(
		"government_finance_investment_factor",
		government_finance_investment_factor
	)

	economy.set_state(
		"government_finance_limited_investment",
		government_finance_limited_investment
	)


	# ============================================================
	# INVESTMENT → INDUSTRIAL CAPACITY
	# ============================================================

	var investment_to_capacity_rate: float = float(
		economy.get_state(
			"investment_to_capacity_rate",
			0.01
		)
	)

	investment_to_capacity_rate = max(
		investment_to_capacity_rate,
		0.0
	)

	var new_investment_capacity: float = (
		government_finance_limited_investment
		* investment_to_capacity_rate
	)

	var accumulated_investment_capacity: float = (
		investment_capacity
		+ new_investment_capacity
	)

	economy.set_state(
		"investment_capacity",
		accumulated_investment_capacity
	)


	# ============================================================
	# UNALLOCATED INDUSTRIAL CAPACITY
	# ============================================================

	var unallocated_industrial_capacity: float = float(
		economy.get_state(
			"unallocated_industrial_capacity",
			0.0
		)
	)

	unallocated_industrial_capacity = max(
		unallocated_industrial_capacity,
		0.0
	)

	var accumulated_unallocated_capacity: float = (
		unallocated_industrial_capacity
		+ new_investment_capacity
	)

	economy.set_state(
		"unallocated_industrial_capacity",
		accumulated_unallocated_capacity
	)


	# ============================================================
	# GOVERNMENT / MACRO STATE
	# ============================================================

	economy.set_state(
		"inflation",
		inflation
	)

	economy.set_state(
		"unemployment",
		unemployment
	)



func _calculate_resource_shortage_pressure(
	entity
) -> float:

	if entity == null:
		return 0.0

	var resources = entity.get_component(
		"resources"
	)

	if resources == null:
		return 0.0

	var shortage_ratio = resources.get_state(
		"shortage_ratio",
		{}
	)

	if typeof(shortage_ratio) != TYPE_DICTIONARY:
		return 0.0

	var maximum_shortage_ratio: float = 0.0

	for resource_name in shortage_ratio.keys():

		var resource_shortage_ratio: float = clamp(
			float(
				shortage_ratio.get(
					resource_name,
					0.0
				)
			) / 100.0,
			0.0,
			1.0
		)

		maximum_shortage_ratio = max(
			maximum_shortage_ratio,
			resource_shortage_ratio
		)

	return clamp(
		maximum_shortage_ratio,
		0.0,
		1.0
	)



func _calculate_power_shortage_pressure(
	entity
) -> float:

	if entity == null:
		return 0.0

	var industry = entity.get_component(
		"industry"
	)

	if industry == null:
		return 0.0

	var production_state = industry.get_state(
		"production_state",
		{}
	)

	if typeof(production_state) != TYPE_DICTIONARY:
		return 0.0

	var maximum_power_shortage: float = 0.0

	for process_id in production_state.keys():

		var outcome = production_state.get(
			process_id,
			null
		)

		if typeof(outcome) != TYPE_DICTIONARY:
			continue

		var power_constraint_factor: float = clampf(
			float(
				outcome.get(
					"power_constraint_factor",
					1.0
				)
			),
			0.0,
			1.0
		)

		maximum_power_shortage = maxf(
			maximum_power_shortage,
			1.0 - power_constraint_factor
		)

	return clampf(
		maximum_power_shortage,
		0.0,
		1.0
	)


func _calculate_physical_production_output(
	entity
) -> float:

	if entity == null:
		return 0.0

	var industry = entity.get_component(
		"industry"
	)

	if industry == null:
		return 0.0

	var production_state = industry.get_state(
		"production_state",
		{}
	)

	if typeof(production_state) != TYPE_DICTIONARY:
		return 0.0

	var total_output := 0.0

	for process_id in production_state.keys():
		var outcome = production_state.get(
			process_id,
			null
		)

		if typeof(outcome) != TYPE_DICTIONARY:
			continue

		total_output += max(
			float(
				outcome.get(
					"actual_production",
					0.0
				)
			),
			0.0
		)

	return total_output


func _calculate_physical_production_capacity(
	entity
) -> float:

	if entity == null:
		return 0.0

	var industry = entity.get_component(
		"industry"
	)

	if industry == null:
		return 0.0

	# Prefer the authoritative effective capacity persisted by
	# ProductionProcessSystem. This includes adoption and the live
	# operational/physical bottlenecks that were actually resolved
	# for the current production run.
	var production_state = industry.get_state(
		"production_state",
		{}
	)

	if typeof(production_state) == TYPE_DICTIONARY:

		var persisted_capacity := 0.0

		for process_id in production_state.keys():
			var outcome = production_state.get(
				process_id,
				null
			)

			if typeof(outcome) != TYPE_DICTIONARY:
				continue

			var outcome_capacity: float = maxf(
				float(
					outcome.get(
						"effective_capacity",
						0.0
					)
				),
				0.0
			)

			# Step 2.2 applies the resource-availability factor to process
			# capacity before execution. ProductionProcessSystem persists
			# that factor on the outcome. For Step 2.3, the economic output
			# factor must compare realized output against the physical
			# capacity that existed before the resource-shortage constraint,
			# otherwise a 25% resource bottleneck would produce:
			#
			#     output 2.5 / constrained capacity 2.5 = 1.0
			#
			# instead of the intended:
			#
			#     output 2.5 / unconstrained capacity 10 = 0.25
			#
			# Reconstruct the pre-constraint physical capacity from the
			# authoritative persisted execution result without changing
			# production behavior. This includes resource, operational, and
			# explicit power-capacity constraints.
			var resource_constraint_factor: float = clampf(
				float(
					outcome.get(
						"resource_constraint_factor",
						1.0
					)
				),
				0.0,
				1.0
			)
			var power_constraint_factor: float = clampf(
				float(
					outcome.get(
						"power_constraint_factor",
						1.0
					)
				),
				0.0,
				1.0
			)

			var operational_constraint_factor: float = clampf(
				float(
					outcome.get(
						"operational_constraint_factor",
						1.0
					)
				),
				0.0,
				1.0
			)
			var economic_capacity: float = outcome_capacity

			var combined_constraint_factor := (
				resource_constraint_factor
				* operational_constraint_factor
				* power_constraint_factor
			)

			if combined_constraint_factor > 0.0:
				economic_capacity = (
					outcome_capacity
				/ combined_constraint_factor
				)
			elif outcome_capacity <= 0.0:
				# A zero resource-availability factor can legitimately produce
				# zero execution capacity. Keep a positive physical baseline
				# when the process itself had configured capacity so a complete
				# resource failure resolves to an economic output factor of 0.
				economic_capacity = max(
					float(
						outcome.get(
							"base_capacity",
							0.0
						)
					),
					0.0
				)

			persisted_capacity += max(
				economic_capacity,
				0.0
			)

		if persisted_capacity > 0.0:
			return persisted_capacity

	# No authoritative production outcome exists yet. Return zero so
	# the caller can preserve the legacy neutral output-factor path.
	return 0.0
