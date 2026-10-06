class_name MilitaryPanel
extends PanelContainer

## Step 20.5.6 — formatted military dashboard.

var observer: GameplayObserver = null
var country_id: String = "india"
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
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)


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


func _card(title_text: String, body_text: String, accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style("#0F1B2E", accent, 1, 9))
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


func _refresh() -> void:
	if content == null:
		return

	for child in content.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		_card("MILITARY", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("MILITARY", "Country unavailable.", Color("#FB7185"))
		return

	var military = country.get_component("military")
	if military == null:
		_card("MILITARY", "MilitaryComponent is unavailable.", Color("#FB7185"))
		return

	var state: Dictionary = military.state

	_card(
		"READINESS",
		"Military power "
		+ UIFormatters.percent(state.get("military_power", 0.0))
		+ "  •  Readiness "
		+ UIFormatters.percent(state.get("readiness", 0.0))
		+ "\nDefensive capability "
		+ UIFormatters.percent(state.get("defensive_capability", 0.0))
		+ "  •  Power projection "
		+ UIFormatters.percent(state.get("power_projection", 0.0)),
		Color("#F59E0B")
	)

	_card(
		"FORCES",
		"Army "
		+ UIFormatters.percent(state.get("army_strength", 0.0))
		+ "  •  Navy "
		+ UIFormatters.percent(state.get("naval_strength", 0.0))
		+ "  •  Air "
		+ UIFormatters.percent(state.get("air_strength", 0.0))
		+ "\nManpower "
		+ UIFormatters.percent(state.get("manpower", 0.0)),
		Color("#38BDF8")
	)

	_card(
		"SUPPORT & COMMAND",
		"Industrial support "
		+ UIFormatters.percent(state.get("industrial_support", 0.0))
		+ "  •  Military technology "
		+ UIFormatters.percent(state.get("military_technology", 0.0))
		+ "\nCommand capacity "
		+ UIFormatters.percent(state.get("command_capacity", 0.0))
		+ "  •  Effective command "
		+ UIFormatters.percent(state.get("effective_command_capacity", 0.0)),
		Color("#A78BFA")
	)

	var currency := "USD"
	var economy = country.get_component("economy")
	if economy != null:
		currency = str(economy.get_state("currency_id", "USD"))

	_card(
		"STRATEGIC & FINANCIAL",
		"Mobilization "
		+ UIFormatters.percent(state.get("mobilization_capacity", 0.0))
		+ "  •  Military pressure "
		+ UIFormatters.percent(state.get("military_pressure", 0.0))
		+ "\nMilitary spending "
		+ UIFormatters.money(state.get("military_spending", 0.0), currency),
		Color("#34D399")
	)

	_card(
		"LOGISTICS",
		"Logistics capacity "
		+ UIFormatters.percent(state.get("logistics_capacity", 0.0))
		+ "  •  Resource security "
		+ UIFormatters.percent(state.get("resource_security", 0.0))
		+ "\nTransport "
		+ UIFormatters.percent(state.get("transport_logistics_modifier", 0.0))
		+ "  •  Naval "
		+ UIFormatters.percent(state.get("naval_logistics_modifier", 0.0)),
		Color("#60A5FA")
	)

	_card(
		"CONFLICT",
		"At war: "
		+ UIFormatters.bool_status(state.get("at_war", false))
		+ "  •  War exhaustion "
		+ UIFormatters.percent(state.get("war_exhaustion", 0.0))
		+ "\nPrevious readiness "
		+ UIFormatters.percent(state.get("previous_readiness", 0.0)),
		Color("#FB7185")
	)
