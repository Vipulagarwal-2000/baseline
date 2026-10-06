class_name EconomyPanel
extends PanelContainer

## Step 20.5.4 — formatted economic dashboard.

var observer: GameplayObserver = null
var country_id: String = "india"

var title_label: Label
var content: VBoxContainer


func initialize(live_observer: GameplayObserver, live_country_id: String = "india") -> void:
	observer = live_observer
	set_country_id(live_country_id)


func set_country_id(live_country_id: String) -> void:
	if live_country_id.strip_edges().is_empty():
		return
	country_id = live_country_id.strip_edges().to_lower()
	_refresh()


func refresh() -> void:
	_refresh()


func _ready() -> void:
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)


func _card(title_text: String, body_text: String, accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_style("#0F1B2E", accent, 1, 9)
	)
	content.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", accent)
	column.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 11)
	column.add_child(body)


func _style(background: String, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _refresh() -> void:
	if content == null:
		return

	for child in content.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		_card("ECONOMY", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("ECONOMY", "Country unavailable.", Color("#FB7185"))
		return

	var economy = country.get_component("economy")
	if economy == null:
		_card("ECONOMY", "EconomyComponent is unavailable.", Color("#FB7185"))
		return

	var state: Dictionary = economy.state
	var currency := str(state.get("currency_id", "USD"))

	_card(
		"OUTPUT",
		"GDP " + UIFormatters.money(state.get("gdp", 0.0), currency)
		+ "  •  GDP per capita "
		+ UIFormatters.money_per_capita(
			state.get("gdp_per_capita", 0.0),
			currency
		),
		Color("#38BDF8")
	)

	_card(
		"GROWTH & PRICES",
		"Growth "
		+ UIFormatters.percent(state.get("growth_rate", 0.0))
		+ "  •  Effective growth "
		+ UIFormatters.percent(state.get("effective_growth_rate", 0.0))
		+ "\nInflation "
		+ UIFormatters.percent(state.get("inflation", 0.0))
		+ "  •  Purchasing power "
		+ UIFormatters.number(state.get("purchasing_power", 1.0), 2),
		Color("#2DD4BF")
	)

	_card(
		"LABOR",
		"Unemployment "
		+ UIFormatters.percent(state.get("unemployment", 0.0))
		+ "  •  Average wage "
		+ UIFormatters.money(state.get("average_wage", 0.0), currency)
		+ "\nLabor income "
		+ UIFormatters.money(state.get("labor_income", 0.0), currency),
		Color("#A78BFA")
	)

	_card(
		"EFFICIENCY",
		"Economic "
		+ UIFormatters.normalized_or_percent(
			state.get("economic_efficiency", 0.0)
		)
		+ "  •  Production "
		+ UIFormatters.normalized_or_percent(
			state.get("production_efficiency", 0.0)
		)
		+ "\nResources "
		+ UIFormatters.normalized_or_percent(
			state.get("resource_efficiency", 1.0)
		)
		+ "  •  Technology "
		+ UIFormatters.normalized_or_percent(
			state.get("technology_efficiency", 1.0)
		)
		+ "  •  Infrastructure "
		+ UIFormatters.normalized_or_percent(
			state.get("infrastructure_efficiency", 1.0)
		)
		+ "  •  Trade "
		+ UIFormatters.normalized_or_percent(
			state.get("trade_efficiency", 1.0)
		),
		Color("#34D399")
	)

	_card(
		"PUBLIC FINANCE",
		"Revenue "
		+ UIFormatters.money(state.get("government_revenue", 0.0), currency)
		+ "  •  Spending "
		+ UIFormatters.money(state.get("government_spending", 0.0), currency)
		+ "\nBudget "
		+ UIFormatters.money(state.get("budget_balance", 0.0), currency)
		+ "  •  Treasury "
		+ UIFormatters.money(state.get("treasury", 0.0), currency)
		+ "  •  Debt "
		+ UIFormatters.money(state.get("government_debt", 0.0), currency),
		Color("#F59E0B")
	)

	_card(
		"INVESTMENT & MONEY",
		"Investment "
		+ UIFormatters.money(state.get("investment", 0.0), currency)
		+ "  •  Public "
		+ UIFormatters.money(state.get("public_investment", 0.0), currency)
		+ "  •  Private "
		+ UIFormatters.money(state.get("private_investment", 0.0), currency)
		+ "\nInvestment capacity "
		+ UIFormatters.money(state.get("investment_capacity", 0.0), currency)
		+ "  •  Money supply "
		+ UIFormatters.money(state.get("money_supply", 0.0), currency),
		Color("#60A5FA")
	)

	_card(
		"PRESSURE",
		"Economic pressure "
		+ UIFormatters.percent(state.get("economic_pressure", 0.0)),
		Color("#FB7185")
	)
