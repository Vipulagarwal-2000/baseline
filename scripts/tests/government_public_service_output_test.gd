class_name GovernmentPublicServiceOutputTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
	) -> bool:

	TestLogger.section(
        "GOVERNMENT PUBLIC-SERVICE OUTPUT TEST"
	)

	var all_passed: bool = true

	if world == null:
		TestLogger.write_line("World available: FAIL")
		return false
	TestLogger.write_line("World available: PASS")

	if simulation == null:
		TestLogger.write_line("Simulation available: FAIL")
		return false
	TestLogger.write_line("Simulation available: PASS")

	var output_system_instance = simulation.get_system(
        "government_public_service_output_system"
	)
	var output_system_ok: bool = (
		output_system_instance != null
		and output_system_instance is GovernmentPublicServiceOutputSystem
	)
	TestLogger.write_line(
        "Registered GovernmentPublicServiceOutputSystem available: "
		+ ("PASS" if output_system_ok else "FAIL")
	)
	all_passed = all_passed and output_system_ok
	if not output_system_ok:
		return false

	var allocation_system_instance = simulation.get_system(
        "government_spending_allocation_system"
	)
	var allocation_system_ok: bool = (
		allocation_system_instance != null
		and allocation_system_instance is GovernmentSpendingAllocationSystem
	)
	TestLogger.write_line(
        "Registered GovernmentSpendingAllocationSystem available: "
		+ ("PASS" if allocation_system_ok else "FAIL")
	)
	all_passed = all_passed and allocation_system_ok
	if not allocation_system_ok:
		return false

	var effect_system_instance = simulation.get_system(
        "government_policy_effect_system"
	)
	var effect_system_ok: bool = (
		effect_system_instance != null
		and effect_system_instance is GovernmentPolicyEffectSystem
	)
	TestLogger.write_line(
        "Registered GovernmentPolicyEffectSystem available: "
		+ ("PASS" if effect_system_ok else "FAIL")
	)
	all_passed = all_passed and effect_system_ok
	if not effect_system_ok:
		return false

	var output_system: GovernmentPublicServiceOutputSystem = (
		output_system_instance as GovernmentPublicServiceOutputSystem
	)
	var allocation_system: GovernmentSpendingAllocationSystem = (
		allocation_system_instance as GovernmentSpendingAllocationSystem
	)
	var effect_system: GovernmentPolicyEffectSystem = (
		effect_system_instance as GovernmentPolicyEffectSystem
	)

	var india = world.get_entity("india")
	if india == null:
		TestLogger.write_line("India available: FAIL")
		return false
	TestLogger.write_line("India available: PASS")

	var government = india.get_component("government")
	var economy = india.get_component("economy")
	var components_ok: bool = government != null and economy != null
	TestLogger.write_line(
        "India government/economy components available: "
		+ ("PASS" if components_ok else "FAIL")
	)
	all_passed = all_passed and components_ok
	if not components_ok:
		return false

	var original_government_state: Dictionary = government.state.duplicate(true)
	var original_economy_state: Dictionary = economy.state.duplicate(true)

	var policy_id := "government_public_services_8_7"
	var replacement_policy_id := "government_public_services_replacement_8_7"

	var policy = GovernmentPolicyDefinition.new(
		policy_id,
		"fiscal",
		"government_spending_allocation",
		1.0,
		{},
		12,
		{
			"government.spending.infrastructure_share": 0.20,
			"government.spending.military_share": 0.20,
			"government.spending.public_services_share": 0.40,
			"government.spending.administration_share": 0.20
		},
		{"source": "step_8_7_test"}
	)

	var replacement_policy = GovernmentPolicyDefinition.new(
		replacement_policy_id,
		"fiscal",
		"government_spending_allocation",
		1.0,
		{},
		12,
		{
			"government.spending.infrastructure_share": 0.10,
			"government.spending.military_share": 0.10,
			"government.spending.public_services_share": 0.60,
			"government.spending.administration_share": 0.20
		},
		{"source": "step_8_7_test"}
	)

	var definitions_registered: bool = (
		government.define_policy(policy)
		and government.define_policy(replacement_policy)
	)
	TestLogger.write_line(
        "Controlled Step 8.7 service policies register: "
		+ ("PASS" if definitions_registered else "FAIL")
	)
	all_passed = all_passed and definitions_registered
	if not definitions_registered:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	economy.set_state("government_spending", 100.0)

	var activation_ok: bool = government.activate_policy(policy_id)
	TestLogger.write_line(
        "Controlled public-services policy activation succeeds: "
		+ ("PASS" if activation_ok else "FAIL")
	)
	all_passed = all_passed and activation_ok
	if not activation_ok:
		government.state = original_government_state
		economy.state = original_economy_state
		return false

	effect_system.process_month(world)
	allocation_system.process_month(world)
	output_system.process_month(world)

	var allocation = government.get_state("government_spending_allocation", {})
	var public_service_spending := float(
		government.get_state("public_service_spending", 0.0)
	)
	var public_service_output := float(
		government.get_state("public_service_output", 0.0)
	)
	var public_service_capacity := float(
		government.get_state("public_service_capacity", 0.0)
	)

	var observable_output_ok: bool = (
		allocation is Dictionary
		and is_equal_approx(float(allocation.get("public_services", 0.0)), 40.0)
		and is_equal_approx(public_service_spending, 40.0)
		and is_equal_approx(public_service_output, 40.0)
		and is_equal_approx(public_service_capacity, 0.40)
	)
	TestLogger.write_line(
        "Public-services spending creates observable output/capacity effect: "
		+ ("PASS" if observable_output_ok else "FAIL")
	)
	all_passed = all_passed and observable_output_ok

	var ledger = government.get_state("public_service_output_ledger", {})
	var ledger_ok: bool = (
		ledger is Dictionary
		and not ledger.is_empty()
		and government.get_state("public_service_output_last_result", {}) is Dictionary
	)
	TestLogger.write_line(
        "Public-service output ledger and last-result state are explicit: "
		+ ("PASS" if ledger_ok else "FAIL")
	)
	all_passed = all_passed and ledger_ok

	var spending_before_repeat: float = float(
		government.get_state("public_service_spending", 0.0)
	)
	var output_before_repeat: float = float(
		government.get_state("public_service_output", 0.0)
	)
	var capacity_before_repeat: float = float(
		government.get_state("public_service_capacity", 0.0)
	)
	var revision_before_repeat: int = int(
		government.get_state("public_service_output_revision", 0)
	)

	output_system.process_month(world)

	var idempotent: bool = (
		is_equal_approx(float(government.get_state("public_service_spending", 0.0)), spending_before_repeat)
		and is_equal_approx(float(government.get_state("public_service_output", 0.0)), output_before_repeat)
		and is_equal_approx(float(government.get_state("public_service_capacity", 0.0)), capacity_before_repeat)
		and int(government.get_state("public_service_output_revision", 0)) == revision_before_repeat
	)
	TestLogger.write_line(
        "Repeated public-service output processing is idempotent: "
		+ ("PASS" if idempotent else "FAIL")
	)
	all_passed = all_passed and idempotent

	# --------------------------------------------------------
	# POLICY REPLACEMENT
	# --------------------------------------------------------

	var replacement_activation_ok: bool = government.activate_policy(
		replacement_policy_id
	)
	effect_system.process_month(world)
	allocation_system.process_month(world)
	output_system.process_month(world)

	var replacement_output: float = float(
		government.get_state("public_service_output", 0.0)
	)
	var replacement_capacity: float = float(
		government.get_state("public_service_capacity", 0.0)
	)
	var replacement_ok: bool = (
		replacement_activation_ok
		and is_equal_approx(replacement_output, 60.0)
		and is_equal_approx(replacement_capacity, 0.60)
	)
	TestLogger.write_line(
        "Replacing spending policy changes public-service output deterministically: "
		+ ("PASS" if replacement_ok else "FAIL")
	)
	all_passed = all_passed and replacement_ok

	# --------------------------------------------------------
	# INVALID ALLOCATION INTEGRITY
	# --------------------------------------------------------

	var output_before_invalid: float = float(
		government.get_state("public_service_output", 0.0)
	)
	var capacity_before_invalid: float = float(
		government.get_state("public_service_capacity", 0.0)
	)

	government.set_state(
		"government_spending_allocation_total",
		50.0
	)
	output_system.process_month(world)

	var invalid_preserves_state: bool = (
		is_equal_approx(
			float(government.get_state("public_service_output", 0.0)),
			output_before_invalid
		)
		and is_equal_approx(
			float(government.get_state("public_service_capacity", 0.0)),
			capacity_before_invalid
		)
	)
	TestLogger.write_line(
        "Invalid allocation state is rejected without mutating service output: "
		+ ("PASS" if invalid_preserves_state else "FAIL")
	)
	all_passed = all_passed and invalid_preserves_state

	# Restore valid allocation total before zero-spending check.
	government.set_state(
		"government_spending_allocation_total",
		100.0
	)

	# --------------------------------------------------------
	# ZERO SPENDING
	# --------------------------------------------------------

	economy.set_state("government_spending", 0.0)
	allocation_system.process_month(world)
	output_system.process_month(world)

	var zero_output: bool = (
		is_equal_approx(float(government.get_state("public_service_spending", 0.0)), 0.0)
		and is_equal_approx(float(government.get_state("public_service_output", 0.0)), 0.0)
		and is_equal_approx(float(government.get_state("public_service_capacity", 0.0)), 0.0)
	)
	TestLogger.write_line(
        "Zero government spending produces zero public-service output safely: "
		+ ("PASS" if zero_output else "FAIL")
	)
	all_passed = all_passed and zero_output

	# Restore positive spending for snapshot.
	economy.set_state("government_spending", 100.0)
	allocation_system.process_month(world)
	output_system.process_month(world)

	# --------------------------------------------------------
	# SNAPSHOT REPRESENTATION / DEEP COPY
	# --------------------------------------------------------

	var snapshot := WorldSnapshot.new()
	snapshot.capture(world)

	var entity_snapshot = snapshot.entities.get("india", {})
	var snapshot_components = entity_snapshot.get("components", {})
	var snapshot_government = snapshot_components.get("government", {})
	var snapshot_state = snapshot_government.get("state", {})

	var snapshot_has_output_state: bool = (
		snapshot_state is Dictionary
		and snapshot_state.has("public_service_output")
		and snapshot_state.has("public_service_capacity")
		and snapshot_state.has("public_service_output_ledger")
	)
	TestLogger.write_line(
        "WorldSnapshot preserves public-service output state: "
		+ ("PASS" if snapshot_has_output_state else "FAIL")
	)
	all_passed = all_passed and snapshot_has_output_state

	var live_output: float = float(
		government.get_state("public_service_output", 0.0)
	)
	if snapshot_state is Dictionary:
		snapshot_state["public_service_output"] = -999.0

	var snapshot_isolated: bool = is_equal_approx(
		float(government.get_state("public_service_output", 0.0)),
		live_output
	)
	TestLogger.write_line(
        "WorldSnapshot public-service output state is deep-copy isolated: "
		+ ("PASS" if snapshot_isolated else "FAIL")
	)
	all_passed = all_passed and snapshot_isolated

	# --------------------------------------------------------
	# RESTORE
	# --------------------------------------------------------

	government.state = original_government_state
	economy.state = original_economy_state

	var restored: bool = (
		government.state == original_government_state
		and economy.state == original_economy_state
	)
	TestLogger.write_line(
        "Step 8.7 government/economy state restoration: "
		+ ("PASS" if restored else "FAIL")
	)
	all_passed = all_passed and restored

	var countries_ok: bool = true
	for country_id in ["china", "india", "usa"]:
		var entity = world.get_entity(country_id)
		if entity == null:
			countries_ok = false
			break
		if entity.get_component("economy") == null:
			countries_ok = false
			break
		if entity.get_component("government") == null:
			countries_ok = false
			break

	TestLogger.write_line(
        "Three-country world remains structurally clean: "
		+ ("PASS" if countries_ok else "FAIL")
	)
	all_passed = all_passed and countries_ok

	TestLogger.write_line(
        "Government Public-Service Output 8.7 overall: "
		+ ("PASS" if all_passed else "FAIL")
	)

	return all_passed
