class_name UIFormatters
extends RefCounted

## Step 20 UI presentation layer.
##
## Converts authoritative simulation values into human-readable display
## representations. It does not calculate or mutate simulation state.

static func number(value: Variant, decimals: int = 1) -> String:
	if value == null:
		return "—"

	var n := float(value)

	if is_zero_approx(n):
		return "0"

	if decimals <= 0:
		return str(int(round(n)))

	var format_string := "%." + str(decimals) + "f"
	return format_string % n


static func compact(value: Variant, decimals: int = 2) -> String:
	if value == null:
		return "—"

	var n := float(value)
	var abs_n := absf(n)

	if abs_n >= 1_000_000_000_000.0:
		return ("%.2fT" % (n / 1_000_000_000_000.0))
	if abs_n >= 1_000_000_000.0:
		return ("%.2fB" % (n / 1_000_000_000.0))
	if abs_n >= 1_000_000.0:
		return ("%.2fM" % (n / 1_000_000.0))
	if abs_n >= 1_000.0:
		return ("%.1fK" % (n / 1_000.0))

	return ("%.2f" % n) if decimals >= 2 else ("%.1f" % n)


static func population(value: Variant) -> String:
	if value == null:
		return "—"

	var n := float(value)
	var abs_n := absf(n)

	if abs_n >= 1_000_000_000.0:
		return "%.2fB" % (n / 1_000_000_000.0)
	if abs_n >= 1_000_000.0:
		return "%.1fM" % (n / 1_000_000.0)
	if abs_n >= 1_000.0:
		return "%.1fK" % (n / 1_000.0)

	return "%.0f" % n


static func percent(value: Variant, decimals: int = 1) -> String:
	if value == null:
		return "—"

	var n := float(value)

	if decimals <= 0:
		return "%d%%" % int(round(n * 100.0))

	return ("%." + str(decimals) + "f%%") % (n * 100.0)


static func signed_percent_delta(before: Variant, after: Variant) -> String:
	var delta := float(after) - float(before)
	if is_zero_approx(delta):
		return "0.0%"

	return ("%+.1f%%" % (delta * 100.0))


static func quantity(value: Variant, unit: String = "units") -> String:
	if value == null:
		return "—"

	return compact(value, 2) + (" " + unit if not unit.is_empty() else "")


static func rate(value: Variant, unit: String = "/ month") -> String:
	if value == null:
		return "—"

	return compact(value, 2) + " " + unit


static func duration_months(months: Variant) -> String:
	var m := int(months)

	if m <= 0:
		return "Immediate"

	if m == 1:
		return "1 month"

	return str(m) + " months"


static func currency_symbol(currency_id: String) -> String:
	match currency_id.to_upper():
		"INR":
			return "₹"
		"CNY":
			return "¥"
		"USD":
			return "$"
		_:
			return currency_id.to_upper()


static func currency_code(country) -> String:
	if country == null:
		return "USD"

	var economy = country.get_component("economy")
	if economy == null:
		return "USD"

	var state_variant = economy.state
	if not state_variant is Dictionary:
		return "USD"

	var state: Dictionary = state_variant
	return str(state.get("currency_id", "USD"))


static func money(value: Variant, currency_id: String = "USD") -> String:
	if value == null:
		return "—"

	var symbol := currency_symbol(currency_id)
	var n := float(value)
	var abs_n := absf(n)

	if abs_n >= 1_000_000_000_000.0:
		return "%s%.2fT" % [symbol, n / 1_000_000_000_000.0]
	if abs_n >= 1_000_000_000.0:
		return "%s%.2fB" % [symbol, n / 1_000_000_000.0]
	if abs_n >= 1_000_000.0:
		return "%s%.2fM" % [symbol, n / 1_000_000.0]
	if abs_n >= 1_000.0:
		return "%s%.1fK" % [symbol, n / 1_000.0]

	return "%s%.2f" % [symbol, n]


static func money_per_capita(value: Variant, currency_id: String) -> String:
	return money(value, currency_id) + " / person"


static func normalized_or_percent(value: Variant, decimals: int = 1) -> String:
	var n := float(value)

	# Existing simulation uses 0..1 for many capability/pressure scores.
	if n >= 0.0 and n <= 1.0:
		return percent(n, decimals)

	return number(n, decimals)


static func signed_quantity_delta(before: Variant, after: Variant, unit: String = "") -> String:
	var delta := float(after) - float(before)

	var delta_text := ""
	if absf(delta) >= 1000.0:
		delta_text = compact(delta, 2)
	else:
		delta_text = number(delta, 1)

	if delta > 0.0:
		delta_text = "+" + delta_text

	if not unit.is_empty():
		delta_text += " " + unit

	return delta_text


static func status(value: Variant) -> String:
	var text := str(value).strip_edges()
	if text.is_empty():
		return "—"

	return text.replace("_", " ").capitalize()


static func bool_status(value: Variant) -> String:
	return "YES" if bool(value) else "NO"
