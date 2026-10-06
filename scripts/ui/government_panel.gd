class_name GovernmentPanel
extends PanelContainer

## Step 20.5.5 — formatted government/political dashboard.

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
		_card("GOVERNMENT", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("GOVERNMENT", "Country unavailable.", Color("#FB7185"))
		return

	var government = country.get_component("government")
	if government == null:
		_card("GOVERNMENT", "GovernmentComponent is unavailable.", Color("#FB7185"))
		return

	var state: Dictionary = government.state

	_card(
		"POLITICAL STATE",
		"Government type: "
		+ UIFormatters.status(state.get("government_type", "—"))
		+ "\nStability "
		+ UIFormatters.percent(state.get("stability", 0.0))
		+ "  •  Approval "
		+ UIFormatters.percent(state.get("approval", 0.0))
		+ "  •  Political pressure "
		+ UIFormatters.percent(state.get("political_pressure", 0.0)),
		Color("#34D399")
	)

	_card(
		"INSTITUTIONS",
		"Institutional strength "
		+ UIFormatters.normalized_or_percent(state.get("institutional_strength", 0.0))
		+ "  •  Policy capacity "
		+ UIFormatters.normalized_or_percent(state.get("policy_capacity", 0.0))
		+ "\nLegitimacy "
		+ UIFormatters.normalized_or_percent(state.get("legitimacy", 0.0)),
		Color("#38BDF8")
	)

	_card(
		"POWER STRUCTURE",
		"Corruption "
		+ UIFormatters.percent(state.get("corruption", 0.0))
		+ "  •  Centralization "
		+ UIFormatters.percent(state.get("centralization", 0.0))
		+ "\nPolitical freedom "
		+ UIFormatters.percent(state.get("political_freedom", 0.0))
		+ "  •  Executive strength "
		+ UIFormatters.percent(state.get("executive_strength", 0.0))
		+ "  •  Legislative constraint "
		+ UIFormatters.percent(state.get("legislative_constraint", 0.0)),
		Color("#A78BFA")
	)

	_card(
		"PREVIOUS MONTH",
		"Stability "
		+ UIFormatters.percent(state.get("previous_stability", 0.0))
		+ "  •  Approval "
		+ UIFormatters.percent(state.get("previous_approval", 0.0))
		+ "  •  Pressure "
		+ UIFormatters.percent(state.get("previous_pressure", 0.0)),
		Color("#94A3B8")
	)

	var active_policies = state.get("active_policies", {})
	var pending_activation = state.get("pending_policy_activation", {})
	_card(
		"POLICY STATE",
		"Active policies: " + str(active_policies)
		+ "\nPending activation: "
		+ str(pending_activation),
		Color("#F59E0B")
	)
