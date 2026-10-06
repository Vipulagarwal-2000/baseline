class_name CurrencyIdentityTest
extends RefCounted


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:

	var passed := true

	TestLogger.write_line(
		"World available: "
		+ ("PASS" if world != null else "FAIL")
	)
	if world == null:
		return false

	TestLogger.write_line(
		"Simulation available: "
		+ ("PASS" if simulation != null else "FAIL")
	)
	if simulation == null:
		return false

	# SimulationEngine is the authoritative registry for registered systems.
	var system = simulation.get_system("currency_identity_system")
	var system_ok = system != null and system is CurrencyIdentitySystem
	TestLogger.write_line(
		"Registered CurrencyIdentitySystem available: "
		+ ("PASS" if system_ok else "FAIL")
	)
	passed = passed and system_ok

	var china = world.get_entity("china")
	var india = world.get_entity("india")
	var usa = world.get_entity("usa")

	var countries_ok = china != null and india != null and usa != null
	TestLogger.write_line(
		"China, India and United States available: "
		+ ("PASS" if countries_ok else "FAIL")
	)
	passed = passed and countries_ok

	if not countries_ok:
		return false

	var economy_ok = (
		china.get_component("economy") != null
		and india.get_component("economy") != null
		and usa.get_component("economy") != null
	)

	TestLogger.write_line(
		"Required economy components available: "
		+ ("PASS" if economy_ok else "FAIL")
	)
	passed = passed and economy_ok

	if not economy_ok:
		return false

	# The loaded JSON is the source of truth. Check it BEFORE the system runs.
	var china_loaded_ok = _currency_matches(
		china, "CNY", "Chinese Yuan", "¥"
	)
	var india_loaded_ok = _currency_matches(
		india, "INR", "Indian Rupee", "₹"
	)
	var usa_loaded_ok = _currency_matches(
		usa, "USD", "US Dollar", "$"
	)

	TestLogger.write_line(
		"China JSON currency identity is CNY / Chinese Yuan / ¥: "
		+ ("PASS" if china_loaded_ok else "FAIL")
	)
	TestLogger.write_line(
		"India JSON currency identity is INR / Indian Rupee / ₹: "
		+ ("PASS" if india_loaded_ok else "FAIL")
	)
	TestLogger.write_line(
		"United States JSON currency identity is USD / US Dollar / $: "
		+ ("PASS" if usa_loaded_ok else "FAIL")
	)

	passed = passed and china_loaded_ok and india_loaded_ok and usa_loaded_ok

	if not passed:
		TestLogger.write_line(
			"Currency Identity 6.1 stopped because loaded JSON identity is incomplete or incorrect."
		)
		return false

	var india_economy = india.get_component("economy")
	var china_economy = china.get_component("economy")
	var usa_economy = usa.get_component("economy")

	var india_money_supply_before = float(
		india_economy.get_state("money_supply", 0.0)
	)
	var india_treasury_before = float(
		india_economy.get_state("treasury", 0.0)
	)

	var china_identity_before = _currency_state(china)
	var india_identity_before = _currency_state(india)
	var usa_identity_before = _currency_state(usa)

	# Execute the registered system. It must preserve the JSON-defined values.
	(system as CurrencyIdentitySystem).process_month(world)

	var identity_preserved_ok = (
		_currency_state(china) == china_identity_before
		and _currency_state(india) == india_identity_before
		and _currency_state(usa) == usa_identity_before
	)

	TestLogger.write_line(
		"CurrencyIdentitySystem preserves JSON-defined identity: "
		+ ("PASS" if identity_preserved_ok else "FAIL")
	)
	passed = passed and identity_preserved_ok

	var balances_unchanged_ok = (
		is_equal_approx(
			float(india_economy.get_state("money_supply", 0.0)),
			india_money_supply_before
		)
		and is_equal_approx(
			float(india_economy.get_state("treasury", 0.0)),
			india_treasury_before
		)
	)

	TestLogger.write_line(
		"Currency identity processing does not mutate monetary balances: "
		+ ("PASS" if balances_unchanged_ok else "FAIL")
	)
	passed = passed and balances_unchanged_ok

	var snapshot = WorldSnapshot.new()
	snapshot.capture(world)

	var snapshot_ok := false
	if snapshot != null and snapshot.entities.has("india"):
		var entity_snapshot = snapshot.entities["india"]
		var components = entity_snapshot.get("components", {})
		var economy_snapshot = components.get("economy", {})
		var state = economy_snapshot.get("state", {})
		snapshot_ok = (
			state.get("currency_id", "") == "INR"
			and state.get("currency_name", "") == "Indian Rupee"
			and state.get("currency_symbol", "") == "₹"
		)

	TestLogger.write_line(
		"Currency identity survives existing world snapshot representation: "
		+ ("PASS" if snapshot_ok else "FAIL")
	)
	passed = passed and snapshot_ok

	TestLogger.write_line(
		"Currency Identity 6.1 overall: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _currency_state(country) -> Dictionary:
	if country == null:
		return {}

	var economy = country.get_component("economy")
	if economy == null:
		return {}

	return {
		"currency_id": economy.get_state("currency_id", ""),
		"currency_name": economy.get_state("currency_name", ""),
		"currency_symbol": economy.get_state("currency_symbol", "")
	}


static func _currency_matches(
	country,
	currency_id: String,
	currency_name: String,
	currency_symbol: String
) -> bool:

	var state = _currency_state(country)

	return (
		state.get("currency_id", "") == currency_id
		and state.get("currency_name", "") == currency_name
		and state.get("currency_symbol", "") == currency_symbol
	)
