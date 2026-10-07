extends Node

const RUN_VALIDATION_SUITE_ON_BOOT := true

const WorldLoaderScript = preload(
    "res://scripts/core/world_loader.gd"
)

const GameplaySessionScript = preload(
    "res://scripts/ui/gameplay_session.gd"
)

const GameplayObserverScript = preload(
    "res://scripts/ui/gameplay_observer.gd"
)


func _create_simulation_context() -> Dictionary:


	# ============================================================
	# CONFIGURATION
	# ============================================================

	var config = SimulationConfig.create_default()


	# ============================================================
	# WORLD
	# ============================================================

	var world = WorldState.new(
		config
	)


	# ============================================================
	# WORLD LOADER
	# ============================================================

	var loader = WorldLoader.new()

	var countries_directory = (
        "res://data/countries"
	)

	var loaded_countries = loader.load_all_countries(
		countries_directory
	)

	for country in loaded_countries:

		world.add_entity(
			country
		)


	# ============================================================
	# REGIONALIZATION DATA LOAD — STEP 12.1
	# ============================================================
	# Countries remain authoritative entities. Regions are loaded into
	# WorldState.regions through a dedicated regional data layer rather
	# than being inserted as fake country entities.
	var regional_loader = RegionalDataLoader.new()
	var regionalization_system = RegionalizationSystem.new()
	var regional_ownership_system = RegionalOwnershipSystem.new()
	var regional_terrain_loader = RegionalTerrainDataLoader.new()
	var regional_terrain_system = RegionalTerrainSystem.new()
	var regional_population_loader = RegionalPopulationDataLoader.new()
	var regional_population_system = RegionalPopulationSystem.new()
	var regional_resource_loader = RegionalResourceDataLoader.new()
	var regional_resource_system = RegionalResourceSystem.new()
	var regional_infrastructure_loader = RegionalInfrastructureDataLoader.new()
	var regional_infrastructure_system = RegionalInfrastructureSystem.new()
	var regional_industry_loader = RegionalIndustryDataLoader.new()
	var regional_industry_system = RegionalIndustrySystem.new()
	var regional_transport_loader = RegionalTransportDataLoader.new()
	var regional_transport_system = RegionalTransportSystem.new()
	var country_aggregation_system = CountryAggregationSystem.new()

	var regional_definitions = regional_loader.load_all_regions(
		"res://data/regions"
	)

	if not regionalization_system.initialize_world(
		world,
		regional_definitions
	):
		push_error(
			"Main: Step 12.1 regional definitions failed to initialize."
		)

	# Step 12.2 — seed explicit ownership/control state from the
	# already-validated structural home country. This does not rewrite
	# Region.country_id and has no monthly automatic transitions.
	if not regional_ownership_system.initialize_world(world):
		push_error(
			"Main: Step 12.2 regional ownership failed to initialize."
		)

	# Step 12.3 — seed bounded regional terrain profiles. Terrain is a
	# separate regional state layer; provinces inherit their parent-region
	# profile until a later explicit province override is introduced.
	var regional_terrain_definitions = regional_terrain_loader.load_all_terrain_profiles(
		"res://data/regions/terrain"
	)

	if not regional_terrain_system.initialize_world(
		world,
		regional_terrain_definitions
	):
		push_error(
			"Main: Step 12.3 regional terrain failed to initialize."
		)

	# Step 12.4 — seed broad regional population localization from the
	# current authoritative country PopulationComponent. Population is
	# localized to parent regions only in this step; province-level population
	# and regional demographic dynamics remain intentionally deferred.
	var regional_population_definitions = regional_population_loader.load_all_population_profiles(
		"res://data/regions/population"
	)

	if not regional_population_system.initialize_world(
		world,
		regional_population_definitions
	):
		push_error(
			"Main: Step 12.4 regional population failed to initialize."
		)

	# Step 12.5 — seed broad parent-region resource localization from the
	# current authoritative country ResourceComponent. Production, reserves,
	# and stockpile totals remain country-authoritative; the regional JSONs are
	# calibration shares and bounded accessibility/import-dependency signals.
	var regional_resource_definitions = regional_resource_loader.load_all_resource_profiles(
		"res://data/regions/resources"
	)

	if not regional_resource_system.initialize_world(
		world,
		regional_resource_definitions
	):
		push_error(
			"Main: Step 12.5 regional resources failed to initialize."
		)

	# Step 12.6 — seed normalized parent-region infrastructure indices from
	# the authoritative country InfrastructureComponent. The regional layer
	# is static in this step; investment, construction, maintenance, damage,
	# and country authority handoff remain deferred.
	var regional_infrastructure_definitions = regional_infrastructure_loader.load_all_infrastructure_profiles(
		"res://data/regions/infrastructure"
	)

	if not regional_infrastructure_system.initialize_world(
		world,
		regional_infrastructure_definitions
	):
		push_error(
			"Main: Step 12.6 regional infrastructure failed to initialize."
		)

	# Step 12.7 — seed parent-region industry structure from the authoritative
	# country IndustryComponent. The regional layer localizes process capacity
	# and exposes causal labor/resource-demand seeds; monthly production remains
	# owned by the existing ProductionProcessSystem until the later handoff.
	var regional_industry_definitions = regional_industry_loader.load_all_industry_profiles(
		"res://data/regions/industry"
	)

	if not regional_industry_system.initialize_world(
		world,
		regional_industry_definitions
	):
		push_error(
			"Main: Step 12.7 regional industry failed to initialize."
		)

	# Step 12.8 — build a parent-region domestic transport graph from the
	# already-localized regional infrastructure layer. This graph exposes
	# capacity/cost/restriction state but does not execute trade or resource movement.
	var regional_transport_definitions = regional_transport_loader.load_all_transport_profiles(
		"res://data/regions/transport"
	)

	if not regional_transport_system.initialize_world(
		world,
		regional_transport_definitions
	):
		push_error(
			"Main: Step 12.8 regional transport failed to initialize."
		)

	# Step 12.9 — explicit country authority handoff from the localized
	# parent-region state. The aggregation service remains inert during
	# monthly processing until a later step makes regional runtime state
	# continuously authoritative.
	if not country_aggregation_system.aggregate_world(world):
		push_error(
			"Main: Step 12.9 country aggregation failed to initialize."
		)


	# ============================================================
	# SIMULATION ENGINE
	# ============================================================

	var simulation = SimulationEngine.new(
		world
	)


	# ============================================================
	# WORLD UPDATE SYSTEMS
	# ============================================================

	# Instantiate the production system before registration so its existing
	# catalog can be injected into the earlier bottleneck system.
	var production_process_system = ProductionProcessSystem.new()
	var military_production_capacity_system = MilitaryProductionCapacitySystem.new()
	var military_resource_readiness_system = MilitaryResourceReadinessSystem.new()
	var military_transport_logistics_system = MilitaryTransportLogisticsSystem.new()
	var military_port_naval_logistics_system = MilitaryPortNavalLogisticsSystem.new()
	var military_power_infrastructure_system = MilitaryPowerInfrastructureSystem.new()
	var military_resource_demand_system = MilitaryResourceDemandSystem.new()
	var military_economic_pressure_system = MilitaryEconomicPressureSystem.new()
	var infrastructure_damage_system = InfrastructureDamageSystem.new()
	var infrastructure_reconstruction_investment_system = InfrastructureReconstructionInvestmentSystem.new()
	var infrastructure_recovery_system = InfrastructureRecoverySystem.new()

	simulation.register_system(
		DemographicsSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		5
	)

	simulation.register_system(
		MigrationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		8
	)

	simulation.register_system(
		PopulationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		10
	)

	simulation.register_system(
		LaborSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		12
	)

	simulation.register_system(
		InfrastructureMaintenanceSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		25
	)

	simulation.register_system(
		InfrastructureSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		26
	)

	simulation.register_system(
		InfrastructureInvestmentSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		23
	)

	simulation.register_system(
		InfrastructureConstructionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		24
	)

	simulation.register_system(
		InfrastructureBottleneckSystem.new(
			production_process_system.catalog
		),
		SimulationPhase.WORLD_UPDATE,
		27
	)

	# Step 11.1 — embargo enforcement runs immediately before TradeSystem so
	# an embargoed agreement is already in its interrupted lifecycle state
	# when the authoritative trade executor resolves the month.
	simulation.register_system(
		TradeEmbargoSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		28
	)

	simulation.register_system(
		TradeSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		29
	)

	simulation.register_system(
		ResourceSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		30
	)

	simulation.register_system(
		TradeDiplomaticConsequencesSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		31
	)

	# Step 13.6 — derive the explicit military resource-demand signal
	# before AggregateDemandSystem (36) assembles the domestic demand
	# categories. This bridge never directly mutates stockpile/reserves.
	simulation.register_system(
		military_resource_demand_system,
		SimulationPhase.WORLD_UPDATE,
		34
	)

	simulation.register_system(
		production_process_system,
		SimulationPhase.WORLD_UPDATE,
		35
	)

	# Step 5.3 — aggregate demand is calculated after the live production
	# structure has exposed production_process_demand and before the
	# economy/government chain consumes the resulting signal.
	simulation.register_system(
		AggregateDemandSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		36
	)

	# Step 5.4 — convert the current aggregate domestic demand signal
	# into actual monthly consumption requests. Scarcity is intentionally
	# not resolved here; Step 5.5 owns supply/demand resolution.
	simulation.register_system(
		AggregateConsumptionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		37
	)

	# Step 5.5 — resolve current-cycle physical supply against combined
	# domestic consumption and scheduled exports. This layer reports
	# shortage/surplus but does not mutate the physical stockpile.
	simulation.register_system(
		SupplyDemandResolutionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		38
	)

	# Step 5.6 — derive basic capacity-utilization diagnostics from the
	# authoritative ProductionProcessSystem outcomes. This layer does not
	# execute production and does not mutate physical capacity.
	simulation.register_system(
		CapacityUtilizationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		39
	)

	# Step 5.7 — derive a basic resource price signal from the explicit
	# base price and the Step 5.5 supply/demand resolution. This system
	# does not mutate supply, demand, stockpiles, or trade quantities.
	simulation.register_system(
		BasicPriceFormationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		40
	)

	# Step 5.8 — convert realized production labor requirements into a
	# country-level monthly wage/income flow. The system reads the existing
	# authoritative production outcomes and process requirements; it does not
	# create a second labor-capacity model.
	simulation.register_system(
		IncomeWageFlowSystem.new(
			production_process_system.catalog
		),
		SimulationPhase.WORLD_UPDATE,
		41
	)

	# Step 5.9 — convert gross labor income into a price-adjusted
	# purchasing-power signal using the population consumption basket and
	# Step 5.7 resource prices. This system does not mutate consumption.
	simulation.register_system(
		PurchasingPowerSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		42
	)

	# Step 5.10 — allocate already-resolved domestic supply across the
	# existing domestic demand categories using the existing resource
	# accessibility state. Trade exports are reserved first because their
	# physical quantity is already resolved upstream.
	simulation.register_system(
		ResourceAllocationDistributionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		43
	)

	# Step 6.1 — establish explicit country currency identities before any
	# monetary transaction layer executes. This does not move money or trade.
	simulation.register_system(
		CurrencyIdentitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		44
	)

	# Step 6.2 — establish trade value from actual imported quantity,
	# exporter-side current price, and exporter currency identity.
	# This creates no monetary transfer.
	simulation.register_system(
		TradeValuationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		45
	)
	# Step 6.5 — convert the trade valuation from the exporter/valuation
	# currency into the payer's currency using the explicit fixed/simple
	# FX table. No floating FX market is introduced.
	simulation.register_system(
		CurrencyConversionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		46
	)

	# Step 6.4 — evaluate whether the payer can fund the already-valued
	# payment, now using the converted payer-side amount when applicable.
	simulation.register_system(
		PaymentAffordabilitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		47
	)
	# Step 5.11 / Step 6.3 boundary — settle the already-established
	# trade value through the existing treasury state.
	simulation.register_system(
		TradePaymentSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		48
	)

	# Step 6.6 — validate that completed monetary settlements conserve
	# base-equivalent value and match the actual treasury deltas recorded
	# by the settlement ledger. This system is diagnostic only.
	simulation.register_system(
		MonetaryInvariantSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		49
	)
	simulation.register_system(
		ResearchSystem.new(
			simulation.get_technology_manager()
		),
		SimulationPhase.WORLD_UPDATE,
		50
	)
	simulation.register_system(
		TechnologyEffectSystem.new(
			simulation.get_technology_manager()
		),
		SimulationPhase.WORLD_UPDATE,
		51
	)
	simulation.register_system(
		TechnologyAdoptionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		52
	)
	simulation.register_system(
		CapabilitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		53
	)
	simulation.register_system(
		ConstraintSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		54
	)
	simulation.register_system(
		GeographySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		55
	)

	# Step 8.9 — resolve explicit government implementation capacity
	# before policy effects are applied. The system only computes the
	# effective factor; GovernmentPolicyEffectSystem remains the owner
	# of actual effect application.
	simulation.register_system(
		GovernmentImplementationCapacitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		56
	)

	simulation.register_system(
		EconomySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		57
	)
	simulation.register_system(
		GovernmentPolicyCostSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# Step 13.1 — derive the production/industrial support signal before
	# MilitarySystem consumes it. ProductionProcessSystem remains the
	# authority for actual production execution.
	simulation.register_system(
		military_production_capacity_system,
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# Step 13.2 — expose the authoritative ResourceSystem military-resource
	# modifier before MilitarySystem resolves readiness.
	simulation.register_system(
		military_resource_readiness_system,
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# Step 13.3 — expose existing transport/infrastructure capacity
	# before MilitarySystem consumes it for final logistics.
	simulation.register_system(
		military_transport_logistics_system,
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# Step 13.4 — port support is derived before MilitarySystem.
	simulation.register_system(
		military_port_naval_logistics_system,
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# Step 13.5 — derive power-supported military infrastructure
	# before MilitarySystem resolves effective command capacity.
	simulation.register_system(
		military_power_infrastructure_system,
		SimulationPhase.WORLD_UPDATE,
		58
	)

	# MilitarySystem resolves the monthly military state first. Step 13.7
	# then translates that finalized military burden into economic pressure.
	simulation.register_system(
		MilitarySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		59
	)

	# Step 13.7 — expose the finalized military economic burden after
	# MilitarySystem and before downstream government/event systems.
	simulation.register_system(
		military_economic_pressure_system,
		SimulationPhase.WORLD_UPDATE,
		60
	)

	simulation.register_system(
		GovernmentPolicyEffectSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		61
	)
	simulation.register_system(
		MilitaryRelationshipSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		62
	)
	simulation.register_system(
		GovernmentSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		63
	)
	simulation.register_system(
		InfluenceSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		64
	)
	simulation.register_system(
		TaxIncidenceSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		65
	)
	simulation.register_system(
		ConflictSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		66
	)
	simulation.register_system(
		MilitaryEventSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		67
	)
	simulation.register_system(
		EventSynchronizer.new(),
		SimulationPhase.WORLD_UPDATE,
		68
	)

	# Step 7.3 — formalize the already-resolved country-level domestic
	# accessibility result from Step 5.10. This is an explicit derived
	# layer only; it does not create a second inventory or transport model.
	simulation.register_system(
		DomesticAccessibilitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		69
	)

	# Step 7.1 — expose the scarcity/fulfillment outcome of the existing
	# aggregate allocation without creating a second inventory or
	# distribution model.
	simulation.register_system(
		ScarceResourceAllocationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		70
	)

	# Step 14.1 — explicit infrastructure-damage creation/provenance layer.
	# It records damage causes but does not yet reduce capacity; 14.2 owns that.
	simulation.register_system(
		infrastructure_damage_system,
		SimulationPhase.WORLD_UPDATE,
		71
	)

	# Step 7.2 — apply configurable priority classes as a derived
	# allocation overlay without replacing Step 5.10's physical
	# distribution or baseline proportional allocation.
	simulation.register_system(
		PriorityClassAllocationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		71
	)

	# Step 7.4 — propagate priority-allocation outcomes into the existing
	# downstream consequence owners. This remains a derived consequence
	# layer and does not replace physical supply, demand, production,
	# government, or military ownership.
	simulation.register_system(
		AllocationConsequencesSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		72
	)

	# Step 8.6 — separate the existing monthly government-spending total
	# into explicit category allocations. This remains a derived fiscal
	# layer and does not yet generate service/military/infrastructure output.
	simulation.register_system(
		GovernmentSpendingAllocationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		73
	)

	# Step 8.7 — convert the already-allocated public-services spending
	# into an explicit aggregate public-service output/capacity signal.
	# This does not alter total spending or create a second fiscal model.
	simulation.register_system(
		GovernmentPublicServiceOutputSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		74
	)

	# Step 8.8 — apply an explicitly approved basic law amendment as a
	# small state transition. This remains separate from constitutional
	# or parliamentary simulation and does not apply policy effects itself.
	simulation.register_system(
		GovernmentLawAmendmentSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		75
	)


	# Step 8.10 — apply an explicitly approved simplified government-state
	# transition. This changes only government_type and does not introduce
	# constitutional, parliamentary, electoral, or party simulation.
	simulation.register_system(
		GovernmentTransitionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		76
	)


	# Step 9.1 — derive an aggregate standard-of-living index from the
	# existing income, resource-availability, employment and public-service
	# states. This does not create a new economic or social simulation layer.
	simulation.register_system(
		StandardOfLivingSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		77
	)

	# Step 9.2 — derive aggregate welfare signals from the already-derived
	# standard-of-living index. This does not modify living conditions
	# or apply political/population consequences yet.
	simulation.register_system(
		WelfareEffectSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		78
	)

	# Step 9.3 — feed the already-derived purchasing-power state back into
	# next-cycle population consumption demand. This is a bounded feedback
	# bridge and does not create demand above the existing baseline.
	simulation.register_system(
		IncomeConsumptionFeedbackSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		79
	)

	# Step 9.4 — translate severe economic/social pressure into a
	# bounded political-pressure contribution. Existing political
	# pressure is preserved; Step 9.4 does not modify approval,
	# stability or legitimacy.
	simulation.register_system(
		EconomicPressurePoliticalFeedbackSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		80
	)

	# Step 9.5 — derive broad aggregate population-response signals from
	# the already-derived welfare and political pressure state.
	# Authoritative birth/death/migration/labor inputs remain unchanged.
	simulation.register_system(
		BasicPopulationResponseSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		81
	)

	# Step 9.6 — convert aggregate population/welfare pressure into an
	# explicit government-response handoff. Step 8 state transitions have
	# already executed this cycle, so the handoff is available for the
	# next cycle without mutating approval, stability, legitimacy or policy
	# state in the middle of the current cycle.
	simulation.register_system(
		GovernmentFeedbackSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		82
	)

	# Step 8.9 policy effects consume the implementation factors resolved
	# at priority 56. No new policy-target state is created here.

	# Step 10.5 — filter externally-originated event consequences so that
	# only material impacts relevant to the MVP core world reach Step 10.3.
	# The filter runs before external causality materializes consequences.
	simulation.register_system(
		ExternalEventRelevanceFilterSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		83
	)

	# Step 10.3 — external-world event causality.
	# External actors can originate material events that target one or
	# more core countries. The causality layer records the consequence
	# ledger without replacing the authoritative country systems.
	simulation.register_system(
		ExternalEventCausalitySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		84
	)

	# Step 10.4 — advance only explicitly-declared, event-relevant
	# external state. No domestic country simulation is created.
	simulation.register_system(
		ExternalActorLimitedSimulationSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		85
	)

	# Step 11.2 — route-level blockade / restriction service. The durable
	# restriction state belongs to TradeRoute itself, so this registered
	# system provides the control API and defensive monthly normalization.
	# It does not replace TradeSystem and it does not alter route base capacity.
	simulation.register_system(
		TradeRouteRestrictionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		86
	)

	# Step 11.3 — reconcile the consequences of a restriction-affected trade
	# after the existing resource, production, economy, valuation, payment,
	# and diplomatic systems have produced their authoritative outputs.
	# This system records transaction-visible causal/history state only.
	simulation.register_system(
		TradeRestrictionInteractionSystem.new(),
		SimulationPhase.WORLD_UPDATE,
		87
	)

	# Step 11.4 — explicit restriction removal / recovery service.
	# Recovery never runs automatically; this system exposes explicit APIs
	# that lift restrictions without rewriting agreement/route history.
	simulation.register_system(
		TradeRestrictionRecoverySystem.new(),
		SimulationPhase.WORLD_UPDATE,
		88
	)

	# Step 12.1 — structural regionalization. The hierarchy is loaded
	# during startup, while the registered system intentionally has no
	# monthly mutation until later regional substeps add localized state.
	simulation.register_system(
		regionalization_system,
		SimulationPhase.WORLD_UPDATE,
		89
	)

	# Step 12.2 — explicit regional ownership/control state. The system
	# exposes mutation APIs for later conflict/territorial mechanics but
	# performs no automatic monthly ownership changes.
	simulation.register_system(
		regional_ownership_system,
		SimulationPhase.WORLD_UPDATE,
		90
	)

	# Step 12.3 — static regional terrain seed state. No monthly mutation.
	simulation.register_system(
		regional_terrain_system,
		SimulationPhase.WORLD_UPDATE,
		91
	)

	# Step 12.4 — static broad regional population localization. Monthly
	# demographic change remains owned by existing country-level systems.
	simulation.register_system(
		regional_population_system,
		SimulationPhase.WORLD_UPDATE,
		92
	)

	# Step 12.5 — static broad regional resource localization. Monthly
	# resource flows remain owned by the existing country-level ResourceSystem.
	simulation.register_system(
		regional_resource_system,
		SimulationPhase.WORLD_UPDATE,
		93
	)

	# Step 12.6 — static broad regional infrastructure localization. The
	# existing country InfrastructureSystem remains the monthly authority.
	simulation.register_system(
		regional_infrastructure_system,
		SimulationPhase.WORLD_UPDATE,
		94
	)

	# Step 12.7 — static broad regional industry localization. The existing
	# ProductionProcessSystem remains the monthly authority for execution.
	simulation.register_system(
		regional_industry_system,
		SimulationPhase.WORLD_UPDATE,
		95
	)

	# Step 12.8 — static parent-region transport network. Existing trade/resource
	# systems remain the execution authorities; this layer only exposes network state.
	simulation.register_system(
		regional_transport_system,
		SimulationPhase.WORLD_UPDATE,
		96
	)

	# Step 12.9 — explicit country-level aggregation authority.
	# process_month() is intentionally inert at the current authority
	# boundary; later regional runtime steps can activate recurring use.
	simulation.register_system(
		country_aggregation_system,
		SimulationPhase.WORLD_UPDATE,
		97
	)

	# Step 14.5 — reconstruction investment commitment/progress layer.
	# It consumes the existing infrastructure investment budget but does not
	# modify raw infrastructure or the damage ledger; Step 14.6 owns recovery.
	simulation.register_system(
		infrastructure_reconstruction_investment_system,
		SimulationPhase.WORLD_UPDATE,
		98
	)

	# Step 14.6 — progressively translate committed reconstruction progress
	# into physical damage reduction. It does not create investment or
	# replace InfrastructureSystem; that system remains the capacity authority.
	simulation.register_system(
		infrastructure_recovery_system,
		SimulationPhase.WORLD_UPDATE,
		99
	)

	# ============================================================
	# DECISION SYSTEMS
	# ============================================================

	simulation.register_system(
		CountryStrategySystem.new(),
		SimulationPhase.DECISIONS,
		10
	)

	simulation.register_system(
		GoalSystem.new(),
		SimulationPhase.DECISIONS,
		20
	)

	simulation.register_system(
		DecisionSystem.new(),
		SimulationPhase.DECISIONS,
		30
	)

	simulation.register_system(
		DecisionTrajectorySystem.new(),
		SimulationPhase.DECISIONS,
		40
	)

	simulation.register_system(
		AIDecisionSystem.new(),
		SimulationPhase.DECISIONS,
		51
	)


	# ============================================================
	# POST-SIMULATION SYSTEMS
	# ============================================================

	simulation.register_system(
		HistorySystem.new(),
		SimulationPhase.POST_SIMULATION,
		10
	)

	simulation.register_system(
		MilitaryHistorySystem.new(),
		SimulationPhase.POST_SIMULATION,
		15
	)

	simulation.register_system(
		AIMemorySystem.new(),
		SimulationPhase.POST_SIMULATION,
		20
	)


	# ============================================================
	# REQUIRED COUNTRY CHECK
	# ============================================================

	var india = world.get_entity(
        "india"
	)

	var china = world.get_entity(
        "china"
	)

	var united_states = world.get_entity(
        "usa"
	)

	if india == null:
		push_error(
            "Main: India was not loaded."
		)

	if china == null:
		push_error(
            "Main: China was not loaded."
		)

	if united_states == null:
		push_error(
            "Main: United States was not loaded."
		)


	# ============================================================
	# BASELINE SNAPSHOT
	# ============================================================

	var baseline_snapshot = (
		simulation.capture_baseline()
	)

	if baseline_snapshot == null:

		push_error(
            "Main: Baseline snapshot failed."
		)

	return {
		"world": world,
		"simulation": simulation
	}


func _ready() -> void:

	# ============================================================
	# PRIMARY SIMULATION CONTEXT
	# ============================================================

	var primary_context: Dictionary = (
		_create_simulation_context()
	)

	var world = primary_context["world"]
	var simulation = primary_context["simulation"]

	# ============================================================
	# STEP 20.2 PLAYER GAMEPLAY SESSION
	# ============================================================
	# Session state stores player intent/reference only. It does not become
	# authoritative over WorldState or simulation formulas.
	var gameplay_session: GameplaySession = GameplaySessionScript.new()
	gameplay_session.initialize(simulation, "india")

	# ============================================================
	# STEP 20.3 OBSERVATION / READ PATH
	# ============================================================
	# The observer is a thin presentation read adapter. It never becomes a
	# second simulation authority and never writes to WorldState.
	var gameplay_observer: GameplayObserver = GameplayObserverScript.new()
	gameplay_observer.initialize(simulation)

	# ============================================================
	# STEP 20.1 / 20.2 / 20.3 GAMEPLAY UI BOOT
	# ============================================================
	# The normal application runtime owns the primary live simulation.
	# GameplayUI is a consumer of that authoritative context; it does not
	# construct or mutate a second simulation authority.
	var gameplay_ui = get_node_or_null("GameplayCanvas/GameplayUI")

	if gameplay_ui != null and gameplay_ui.has_method("initialize"):
		gameplay_ui.initialize(
			simulation,
			world,
			gameplay_session.get_player_country_id(),
			gameplay_session,
			gameplay_observer
		)
	else:
		push_warning(
			"Main: GameplayUI node or initialize(simulation, world, country_id, session, observer) method not found."
		)

	# ============================================================
	# VALIDATION / TEST HARNESS
	# ============================================================
	# Keep the existing regression harness available, but do not run it on
	# the normal gameplay boot. This prevents the game scene from immediately
	# running the full suite and calling get_tree().quit().
	if not RUN_VALIDATION_SUITE_ON_BOOT:
		return

	var india = world.get_entity(
		"india"
	)

	var china = world.get_entity(
		"china"
	)

	# ============================================================
	# STEP 18.2 CAMPAIGN CONTEXT
	# ============================================================
	# Build a second, completely fresh campaign context only when the
	# validation harness is explicitly enabled. The campaign context uses the
	# same authoritative bootstrap and SimulationEngine implementation.
	var campaign_context: Dictionary = (
		_create_simulation_context()
	)

	var campaign_world = campaign_context["world"]
	var campaign_simulation = campaign_context["simulation"]

	# ============================================================
	# INITIAL SCENARIO ACTION
	# ============================================================

	if india != null and china != null:

		var diplomatic_action = SimAction.new(
			"diplomatic_outreach",
			india.id,
			china.id,
			10.0,
			3
		)

		simulation.add_action(
			diplomatic_action
		)

	# ============================================================
	# FULL TEST SUITE
	# ============================================================

	RunAllTests.run(
		world,
		simulation,
		false,
		1,
		campaign_world,
		campaign_simulation,
		60
	)

	# ============================================================
	# COMPLETE
	# ============================================================

	get_tree().quit()
