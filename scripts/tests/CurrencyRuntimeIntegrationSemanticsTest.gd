class_name CurrencyRuntimeIntegrationSemanticsTest
extends RefCounted


const EXCHANGE_CONFIG_PATH: String = "res://data/currency_exchange_rates.json"
const COUNTRY_PATHS: Array[String] = [
	"res://data/countries/china.json",
	"res://data/countries/india.json",
	"res://data/countries/usa.json"
]


static func run(
	world: WorldState,
	simulation: SimulationEngine
) -> bool:
	var passed: bool = true

	TestLogger.section(
		"CURRENCY RUNTIME / SEMANTIC INTEGRATION TEST"
	)

	if world == null or simulation == null:
		TestLogger.write_line(
			"World / Simulation available: FAIL"
		)
		return false

	TestLogger.write_line(
		"World / Simulation available: PASS"
	)

	var conversion_system = simulation.get_system(
		"currency_conversion_system"
	)
	var valuation_system = simulation.get_system(
		"trade_valuation_system"
	)
	var affordability_system = simulation.get_system(
		"payment_affordability_system"
	)
	var payment_system = simulation.get_system(
		"trade_payment_system"
	)
	var invariant_system = simulation.get_system(
		"monetary_invariant_system"
	)
	var identity_system = simulation.get_system(
		"currency_identity_system"
	)

	var systems_ok: bool = (
		conversion_system != null
		and conversion_system is CurrencyConversionSystem
		and valuation_system != null
		and valuation_system is TradeValuationSystem
		and affordability_system != null
		and affordability_system is PaymentAffordabilitySystem
		and payment_system != null
		and payment_system is TradePaymentSystem
		and invariant_system != null
		and invariant_system is MonetaryInvariantSystem
		and identity_system != null
		and identity_system is CurrencyIdentitySystem
	)

	TestLogger.write_line(
		"Financial currency chain systems are registered: "
		+ ("PASS" if systems_ok else "FAIL")
	)

	passed = passed and systems_ok

	if not systems_ok:
		return false

	var config: Variant = _load_json(
		EXCHANGE_CONFIG_PATH
	)

	var config_ok: bool = (
		typeof(config) == TYPE_DICTIONARY
	)

	TestLogger.write_line(
		"Currency configuration is available to runtime integration: "
		+ ("PASS" if config_ok else "FAIL")
	)

	passed = passed and config_ok

	if not config_ok:
		return false

	var root: Dictionary = config
	var configured_base_currency: String = str(
		root.get("base_currency", "")
	)
	var configured_rate_basis: String = str(
		root.get("rate_basis", "")
	)
	var configured_rates_value: Variant = root.get(
		"rates_to_base",
		{}
	)

	var configured_rates_ok: bool = (
		typeof(configured_rates_value) == TYPE_DICTIONARY
		and not configured_base_currency.is_empty()
		and not configured_rate_basis.is_empty()
	)

	TestLogger.write_line(
		"Configured currency semantics are structurally readable: "
		+ ("PASS" if configured_rates_ok else "FAIL")
	)

	passed = passed and configured_rates_ok

	if not configured_rates_ok:
		return false

	var configured_rates: Dictionary = configured_rates_value

	var runtime_contract_ok: bool = (
		conversion_system.is_semantic_contract_valid()
		and conversion_system.get_base_currency_id()
		== configured_base_currency
		and conversion_system.get_rate_basis()
		== configured_rate_basis
	)

	TestLogger.write_line(
		"Active CurrencyConversionSystem accepts the semantic contract: "
		+ ("PASS" if runtime_contract_ok else "FAIL")
	)

	passed = passed and runtime_contract_ok

	var runtime_rate_map_matches: bool = true

	for currency_id_value in configured_rates.keys():
		var currency_id: String = str(
			currency_id_value
		)
		var configured_rate: float = float(
			configured_rates[currency_id_value]
		)
		var runtime_rate: float = (
			conversion_system.get_rate_to_base(
				currency_id
			)
		)

		var rate_matches: bool = is_equal_approx(
			runtime_rate,
			configured_rate
		)

		runtime_rate_map_matches = (
			runtime_rate_map_matches
			and rate_matches
		)

		if not rate_matches:
			TestLogger.write_line(
				"Runtime rate matches configuration | "
				+ currency_id
				+ ": FAIL"
			)

	TestLogger.write_line(
		"Runtime FX rates match authoritative configuration: "
		+ ("PASS" if runtime_rate_map_matches else "FAIL")
	)

	passed = passed and runtime_rate_map_matches

	var country_currency_resolution_ok: bool = true

	for path in COUNTRY_PATHS:
		var country: Variant = _load_json(path)

		if typeof(country) != TYPE_DICTIONARY:
			country_currency_resolution_ok = false
			continue

		var country_dict: Dictionary = country
		var country_id: String = str(
			country_dict.get("id", "")
		)

		var economy_value: Variant = country_dict.get(
			"economy",
			{}
		)

		if typeof(economy_value) != TYPE_DICTIONARY:
			country_currency_resolution_ok = false
			continue

		var economy: Dictionary = economy_value
		var currency_id: String = str(
			economy.get("currency_id", "")
		)

		var resolves: bool = (
			not currency_id.is_empty()
			and configured_rates.has(currency_id)
			and conversion_system.get_rate_to_base(currency_id)
			> 0.0
		)

		country_currency_resolution_ok = (
			country_currency_resolution_ok
			and resolves
		)

		TestLogger.write_line(
			"Country currency reaches runtime FX table | "
			+ country_id
			+ " -> "
			+ currency_id
			+ ": "
			+ ("PASS" if resolves else "FAIL")
		)

	passed = (
		passed
		and country_currency_resolution_ok
	)

	var contract_authority: Dictionary = (
		conversion_system.get_semantic_contract()
	)

	var authority_ok: bool = (
		str(
			contract_authority.get(
				"runtime_balance_authority",
				""
			)
		) == "country_economy_component"
		and str(
			contract_authority.get(
				"rate_configuration_authority",
				""
			)
		) == "currency_exchange_rates.json"
	)

	TestLogger.write_line(
		"Currency ownership boundaries remain explicit: "
		+ ("PASS" if authority_ok else "FAIL")
	)

	passed = passed and authority_ok

	TestLogger.write_line(
		"Currency runtime ↔ semantic integration: "
		+ ("PASS" if passed else "FAIL")
	)

	TestLogger.write_line(
		"CurrencyRuntimeIntegrationSemanticsTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return null

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)

	file.close()

	return parsed
