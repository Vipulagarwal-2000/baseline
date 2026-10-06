class_name InfrastructureDamageTest
extends RefCounted


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


static func _log_result(
	label: String,
	passed: bool
) -> void:
	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if passed else "FAIL")
	)


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	TestLogger.write_line("")
	TestLogger.write_line("============================================================")
	TestLogger.write_line("STEP 14.1 — INFRASTRUCTURE DAMAGE CREATION TEST")
	TestLogger.write_line("============================================================")

	if world == null:
		_log_result("World available", false)
		return false
	_log_result("World available", true)

	if simulation == null:
		_log_result("Simulation available", false)
		return false
	_log_result("Simulation available", true)

	var damage_system_instance: SimulationSystem = simulation.get_system(
		"infrastructure_damage_system"
	)

	var infrastructure_system_instance: SimulationSystem = simulation.get_system(
		"infrastructure_system"
	)

	var damage_system_ok: bool = (
		damage_system_instance != null
		and damage_system_instance is InfrastructureDamageSystem
	)
	var infrastructure_system_ok: bool = (
		infrastructure_system_instance != null
	)

	_log_result(
		"Registered InfrastructureDamageSystem available",
		damage_system_ok
	)
	_log_result(
		"Registered InfrastructureSystem available",
		infrastructure_system_ok
	)

	if not damage_system_ok or not infrastructure_system_ok:
		return false

	var india: SimEntity = world.get_entity("india")
	if india == null:
		_log_result("India available", false)
		return false
	_log_result("India available", true)

	var infrastructure: InfrastructureComponent = india.get_component(
		"infrastructure"
	)

	if infrastructure == null:
		_log_result("India InfrastructureComponent available", false)
		return false
	_log_result("India InfrastructureComponent available", true)

	var damage_system: InfrastructureDamageSystem = (
		damage_system_instance as InfrastructureDamageSystem
	)

	var original_state: Dictionary = infrastructure.state.duplicate(true)
	var original_active_events: Array = world.active_events.duplicate()
	var original_completed_events: Array = world.completed_events.duplicate()
	var original_active_conflicts: Array = world.active_conflicts.duplicate()
	var original_completed_conflicts: Array = world.completed_conflicts.duplicate()

	var original_transport: float = float(
		infrastructure.get_state("transport", 0.0)
	)
	var original_total_capacity: float = float(
		infrastructure.get_state("total_capacity", 0.0)
	)

	var passed := true

	# ------------------------------------------------------------
	# FIXTURE SOURCE 1 — REGISTERED SIMULATION EVENT
	# ------------------------------------------------------------
	var fixture_event := SimulationEvent.new(
		"step14_1_fixture_event",
		"Step 14.1 Infrastructure Damage Fixture",
		"infrastructure_damage"
	)
	fixture_event.add_target("india")
	fixture_event.activate()
	world.add_active_event(fixture_event)

	var event_damage_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.25,
		fixture_event,
		"damage_event_001",
		"controlled_event_fixture"
	)
	_log_result(
		"Registered event source creates infrastructure damage",
		event_damage_created
	)
	passed = passed and event_damage_created

	var damage_state = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	var transport_damage: float = 0.0
	if typeof(damage_state) == TYPE_DICTIONARY:
		transport_damage = float(
			damage_state.get("transport", 0.0)
		)

	var transport_damage_correct: bool = is_equal_approx(
		transport_damage,
		0.25
	)
	_log_result(
		"Created damage amount is bounded and explicit",
		transport_damage_correct
	)
	passed = passed and transport_damage_correct

	var records = infrastructure.get_state(
		"infrastructure_damage_records",
		[]
	)
	var record_exists: bool = (
		typeof(records) == TYPE_ARRAY
		and records.size() == 1
	)
	_log_result(
		"Damage record is stored with provenance",
		record_exists
	)
	passed = passed and record_exists

	var provenance_correct := false
	if record_exists:
		var first_record: Dictionary = records[0]
		provenance_correct = (
			String(first_record.get("source_type", "")) == "event"
			and String(first_record.get("source_id", "")) == "step14_1_fixture_event"
			and String(first_record.get("target_id", "")) == "india"
			and String(first_record.get("infrastructure_type", "")) == "transport"
		)
	_log_result(
		"Damage provenance identifies the causal event",
		provenance_correct
	)
	passed = passed and provenance_correct

	var raw_source_preserved: bool = (
		is_equal_approx(
			float(infrastructure.get_state("transport", 0.0)),
			original_transport
		)
		and is_equal_approx(
			float(infrastructure.get_state("total_capacity", 0.0)),
			original_total_capacity
		)
	)
	_log_result(
		"Step 14.1 does not reduce raw infrastructure capacity",
		raw_source_preserved
	)
	passed = passed and raw_source_preserved

	# ------------------------------------------------------------
	# DUPLICATE APPLICATION
	# ------------------------------------------------------------
	var duplicate_created: bool = damage_system.apply_event_damage(
		world,
		"india",
		"transport",
		0.25,
		fixture_event,
		"damage_event_001",
		"controlled_event_fixture_duplicate"
	)

	var duplicate_blocked: bool = not duplicate_created
	_log_result(
		"Repeated damage application is idempotently rejected",
		duplicate_blocked
	)
	passed = passed and duplicate_blocked

	var damage_after_duplicate = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	var duplicate_state_preserved := false
	if typeof(damage_after_duplicate) == TYPE_DICTIONARY:
		duplicate_state_preserved = is_equal_approx(
			float(
				damage_after_duplicate.get(
					"transport",
					0.0
				)
			),
			0.25
		)
	_log_result(
		"Duplicate source application does not increase damage",
		duplicate_state_preserved
	)
	passed = passed and duplicate_state_preserved

	# ------------------------------------------------------------
	# FIXTURE SOURCE 2 — REGISTERED MILITARY CONFLICT
	# ------------------------------------------------------------
	var fixture_conflict := MilitaryConflict.new(
		"step14_1_fixture_conflict",
		"china",
		"india"
	)
	fixture_conflict.set_intensity(0.80)
	fixture_conflict.activate()
	world.add_active_conflict(fixture_conflict)

	var conflict_damage_created: bool = damage_system.apply_conflict_damage(
		world,
		"india",
		"industrial",
		0.15,
		fixture_conflict,
		"damage_conflict_001",
		"controlled_conflict_fixture"
	)
	_log_result(
		"Registered conflict source creates infrastructure damage",
		conflict_damage_created
	)
	passed = passed and conflict_damage_created

	var industrial_damage: float = damage_system.get_damage(
		india,
		"industrial"
	)
	var industrial_damage_correct: bool = is_equal_approx(
		industrial_damage,
		0.15
	)
	_log_result(
		"Conflict-derived damage is stored on the target infrastructure type",
		industrial_damage_correct
	)
	passed = passed and industrial_damage_correct

	var total_damage: float = damage_system.get_damage_total(
		india
	)
	var total_damage_bounded: bool = (
		total_damage >= 0.0
		and total_damage <= 1.0
	)
	_log_result(
		"Aggregate infrastructure damage remains bounded",
		total_damage_bounded
	)
	passed = passed and total_damage_bounded

	# ------------------------------------------------------------
	# INVALID / UNREGISTERED SOURCE
	# ------------------------------------------------------------
	var unregistered_event := SimulationEvent.new(
		"step14_1_unregistered_event",
		"Unregistered Fixture Event",
		"infrastructure_damage"
	)
	unregistered_event.activate()

	var rejected_unregistered_source: bool = not damage_system.apply_event_damage(
		world,
		"india",
		"roads",
		0.10,
		unregistered_event,
		"damage_unregistered_001",
		"invalid_source_fixture"
	)
	_log_result(
		"Unregistered event source is rejected",
		rejected_unregistered_source
	)
	passed = passed and rejected_unregistered_source

	# ------------------------------------------------------------
	# SNAPSHOT / DEEP COPY
	# ------------------------------------------------------------
	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_damage: float = -1.0
	var snapshot_record_count: int = -1
	if snapshot.entities.has("india"):
		var snapshot_entity: Dictionary = snapshot.entities[
			"india"
		]
		var snapshot_components: Dictionary = snapshot_entity.get(
			"components",
			{}
		)
		var snapshot_infrastructure: Dictionary = snapshot_components.get(
			"infrastructure",
			{}
		)
		var snapshot_state: Dictionary = snapshot_infrastructure.get(
			"state",
			{}
		)
		var snapshot_damage_state = snapshot_state.get(
			"infrastructure_damage",
			{}
		)
		var snapshot_records = snapshot_state.get(
			"infrastructure_damage_records",
			[]
		)
		if typeof(snapshot_damage_state) == TYPE_DICTIONARY:
			snapshot_damage = float(
				snapshot_damage_state.get(
					"transport",
					-1.0
				)
			)
		if typeof(snapshot_records) == TYPE_ARRAY:
			snapshot_record_count = snapshot_records.size()

	var snapshot_preserved: bool = (
		is_equal_approx(snapshot_damage, 0.25)
		and snapshot_record_count == 2
	)
	_log_result(
		"WorldSnapshot preserves Step 14.1 damage state",
		snapshot_preserved
	)
	passed = passed and snapshot_preserved

	# Mutate live state after capture; snapshot must remain isolated.
	var live_damage_state = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)
	if typeof(live_damage_state) == TYPE_DICTIONARY:
		live_damage_state["transport"] = 0.90
		infrastructure.set_state(
			"infrastructure_damage",
			live_damage_state
		)

	var snapshot_still_isolated: bool = true
	if snapshot.entities.has("india"):
		var snapshot_entity_after_mutation: Dictionary = snapshot.entities[
			"india"
		]
		var snapshot_components_after_mutation: Dictionary = snapshot_entity_after_mutation.get(
			"components",
			{}
		)
		var snapshot_infrastructure_after_mutation: Dictionary = snapshot_components_after_mutation.get(
			"infrastructure",
			{}
		)
		var snapshot_state_after_mutation: Dictionary = snapshot_infrastructure_after_mutation.get(
			"state",
			{}
		)
		var snapshot_damage_after_mutation = snapshot_state_after_mutation.get(
			"infrastructure_damage",
			{}
		)
		if typeof(snapshot_damage_after_mutation) == TYPE_DICTIONARY:
			snapshot_still_isolated = is_equal_approx(
				float(
					snapshot_damage_after_mutation.get(
						"transport",
						-1.0
					)
				),
				0.25
			)
	_log_result(
		"WorldSnapshot damage state is deep-copy isolated",
		snapshot_still_isolated
	)
	passed = passed and snapshot_still_isolated

	# ------------------------------------------------------------
	# RESTORE EXACT FIXTURE STATE
	# ------------------------------------------------------------
	infrastructure.state = original_state.duplicate(true)
	world.active_events = original_active_events.duplicate()
	world.completed_events = original_completed_events.duplicate()
	world.active_conflicts = original_active_conflicts.duplicate()
	world.completed_conflicts = original_completed_conflicts.duplicate()

	var restoration_passed: bool = (
		infrastructure.state == original_state
	)
	_log_result(
		"Step 14.1 fixture restoration",
		restoration_passed
	)
	passed = passed and restoration_passed

	_log_result(
		"Step 14.1 damage creation overall",
		passed
	)

	if passed:
		TestLogger.write_line(
			"Infrastructure Damage 14.1 test: PASS"
		)
	else:
		TestLogger.write_line(
			"Infrastructure Damage 14.1 test: FAIL"
		)

	return passed
