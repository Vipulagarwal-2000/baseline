class_name CurrencyValuationSemanticsTest
extends RefCounted


const EXCHANGE_CONFIG_PATH: String = "res://data/currency_exchange_rates.json"
const COUNTRY_PATHS: Array[String] = [
	"res://data/countries/china.json",
	"res://data/countries/india.json",
	"res://data/countries/usa.json"
]


static func run() -> bool:
	var passed: bool = true

	var config: Variant = _load_json(EXCHANGE_CONFIG_PATH)
	if typeof(config) != TYPE_DICTIONARY:
		print("Currency exchange configuration loads: FAIL")
		return false

	print("Currency exchange configuration loads: PASS")

	var semantic_contract: Variant = config.get("semantic_contract", {})
	if typeof(semantic_contract) != TYPE_DICTIONARY:
		print("Currency semantic contract exists: FAIL")
		return false

	var contract_checks: Dictionary = {
		"configuration_status": "fixed_mvp_configuration",
		"historical_status": "not_a_historical_exchange_rate_claim",
		"base_currency_semantics": "comparison_and_conversion_anchor",
		"rate_direction": "units_of_currency_per_one_base_currency",
		"conversion_formula": "target_amount = source_amount * target_rate_to_base / source_rate_to_base",
		"rate_scope": "cross_country_mvp_valuation_and_payment_support",
		"runtime_balance_authority": "country_economy_component",
		"rate_configuration_authority": "currency_exchange_rates.json"
	}

	for key in contract_checks.keys():
		var expected: Variant = contract_checks[key]
		var actual: Variant = semantic_contract.get(key, null)
		var ok: bool = actual == expected

		print(
			"Currency semantic contract | "
			+ str(key)
			+ ": "
			+ ("PASS" if ok else "FAIL")
		)

		passed = passed and ok

	var valuation_usage: Variant = semantic_contract.get("valuation_usage", [])
	var valuation_usage_ok: bool = (
		typeof(valuation_usage) == TYPE_ARRAY
		and valuation_usage.has("cross_currency_comparison")
		and valuation_usage.has("trade_payment_conversion")
		and valuation_usage.has("monetary_reconciliation")
	)

	print(
		"Currency valuation usage contract: "
		+ ("PASS" if valuation_usage_ok else "FAIL")
	)

	passed = passed and valuation_usage_ok

	var base_currency: String = str(config.get("base_currency", ""))
	var rate_basis: String = str(config.get("rate_basis", ""))
	var rates_to_base: Variant = config.get("rates_to_base", {})

	var base_ok: bool = not base_currency.is_empty()

	print(
		"Base currency identity exists: "
		+ ("PASS" if base_ok else "FAIL")
	)

	passed = passed and base_ok

	var basis_ok: bool = (
		rate_basis == "units_of_currency_per_one_base_currency"
	)

	print(
		"Exchange-rate direction is explicit: "
		+ ("PASS" if basis_ok else "FAIL")
	)

	passed = passed and basis_ok

	var rates_ok: bool = (
		typeof(rates_to_base) == TYPE_DICTIONARY
		and not rates_to_base.is_empty()
	)

	print(
		"Currency rate map exists: "
		+ ("PASS" if rates_ok else "FAIL")
	)

	passed = passed and rates_ok

	if rates_ok:
		var canonical_base: Array = (
			CurrencyValuationSemanticsTest._canonical_currency_ids()
		)

		var all_rates_positive: bool = true
		var all_rate_ids_canonical: bool = true

		for currency_id_value in rates_to_base.keys():
			var currency_id: String = str(currency_id_value)
			var raw_rate: Variant = rates_to_base[currency_id_value]
			var numeric: bool = (
				typeof(raw_rate) == TYPE_INT
				or typeof(raw_rate) == TYPE_FLOAT
			)
			var rate_positive: bool = (
				numeric
				and float(raw_rate) > 0.0
			)

			if not canonical_base.has(currency_id):
				all_rate_ids_canonical = false
				print(
					"Currency rate key resolves to canonical currency: "
					+ currency_id
					+ ": FAIL"
				)

			all_rates_positive = all_rates_positive and rate_positive

		print(
			"All configured currency rate IDs are canonical: "
			+ ("PASS" if all_rate_ids_canonical else "FAIL")
		)

		print(
			"All configured currency rates are positive numbers: "
			+ ("PASS" if all_rates_positive else "FAIL")
		)

		passed = (
			passed
			and all_rate_ids_canonical
			and all_rates_positive
		)

		var base_rate_value: Variant = rates_to_base.get(
			base_currency,
			0.0
		)
		var base_rate_ok: bool = (
			rates_to_base.has(base_currency)
			and is_equal_approx(
				float(base_rate_value),
				1.0
			)
		)

		print(
			"Base currency rate is exactly the conversion anchor: "
			+ ("PASS" if base_rate_ok else "FAIL")
		)

		passed = passed and base_rate_ok

		var core_currencies_ok: bool = (
			rates_to_base.has("USD")
			and rates_to_base.has("INR")
			and rates_to_base.has("CNY")
		)

		print(
			"Core MVP currencies are covered by the rate table: "
			+ ("PASS" if core_currencies_ok else "FAIL")
		)

		passed = passed and core_currencies_ok

	# Country currency identity remains authoritative in country JSON.
	for path in COUNTRY_PATHS:
		var country: Variant = _load_json(path)

		var country_id: String = ""

		if typeof(country) == TYPE_DICTIONARY:
			country_id = str(country.get("id", ""))

		var economy: Dictionary = {}

		if typeof(country) == TYPE_DICTIONARY:
			var raw_economy: Variant = country.get(
				"economy",
				{}
			)

			if typeof(raw_economy) == TYPE_DICTIONARY:
				economy = raw_economy

		var currency_id: String = str(
			economy.get("currency_id", "")
		)

		var identity_ok: bool = (
			not currency_id.is_empty()
			and typeof(rates_to_base) == TYPE_DICTIONARY
			and rates_to_base.has(currency_id)
		)

		print(
			"Country currency identity resolves through configuration: "
			+ country_id
			+ " -> "
			+ currency_id
			+ ": "
			+ ("PASS" if identity_ok else "FAIL")
		)

		passed = passed and identity_ok

	# Validate the configured conversion formula without changing
	# any runtime state.
	var formula_ok: bool = false

	if (
		rates_ok
		and rates_to_base.has("CNY")
		and rates_to_base.has("INR")
	):
		var source_amount: float = 100.0
		var source_rate: float = float(
			rates_to_base["CNY"]
		)
		var target_rate: float = float(
			rates_to_base["INR"]
		)

		var converted: float = (
			source_amount
			* target_rate
			/ source_rate
		)

		formula_ok = is_equal_approx(
			converted,
			400.0
		)

	print(
		"Configured source→target conversion follows declared formula: "
		+ ("PASS" if formula_ok else "FAIL")
	)

	passed = passed and formula_ok

	print(
		"Currency identity remains country-owned and FX remains configuration-owned: "
		+ ("PASS" if passed else "FAIL")
	)

	print(
		"CurrencyValuationSemanticsTest: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _canonical_currency_ids() -> Array:
	var data: Variant = _load_json(
		"res://data/canonical_ids.json"
	)

	if typeof(data) != TYPE_DICTIONARY:
		return []

	var domains: Variant = data.get(
		"domains",
		{}
	)

	if typeof(domains) != TYPE_DICTIONARY:
		return []

	var currencies: Variant = domains.get(
		"currency",
		{}
	)

	if typeof(currencies) != TYPE_DICTIONARY:
		return []

	var entries: Variant = currencies.get(
		"entries",
		{}
	)

	if typeof(entries) != TYPE_DICTIONARY:
		return []

	var ids: Array = entries.keys()
	ids.sort()

	return ids


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
