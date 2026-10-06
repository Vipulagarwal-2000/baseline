class_name CurrencyIdentitySystem
extends SimulationSystem


# ============================================================
# STEP 6.1 — CURRENCY IDENTITY
# ============================================================
#
# Currency identity is authoritative in the country JSON.
# WorldLoader already copies the JSON economy dictionary into the
# existing EconomyComponent state. This system therefore does NOT
# maintain a second country -> currency lookup table.
#
# This step intentionally does NOT:
# - invent a currency for a country;
# - overwrite JSON-defined currency identity;
# - move money;
# - convert currencies;
# - create FX rates;
# - create credit or banking;
# - change treasury or money_supply.
#
# Its role is to make the currency identity part of the active monthly
# simulation contract and to flag missing identity data without
# fabricating it.
# ============================================================


func _init() -> void:
	super("currency_identity_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		if not entity is Country:
			continue

		var economy = entity.get_component("economy")
		if economy == null:
			continue

		var currency_id: String = str(
			economy.get_state(
				"currency_id",
				""
			)
		)
		var currency_name: String = str(
			economy.get_state(
				"currency_name",
				""
			)
		)
		var currency_symbol: String = str(
			economy.get_state(
				"currency_symbol",
				""
			)
		)

		# Do not invent missing identity. JSON is the authoritative source.
		if currency_id.is_empty() or currency_name.is_empty() or currency_symbol.is_empty():
			push_error(
				"CurrencyIdentitySystem: Missing currency identity for country "
				+ entity.id
			)
			continue

		# Identity is already loaded into EconomyComponent. Reading it here
		# establishes the contract for downstream financial systems while
		# preserving the exact loaded values.
