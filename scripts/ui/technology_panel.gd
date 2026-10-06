class_name TechnologyPanel
extends PanelContainer

## Step 20.5.7 — formatted technology/research dashboard.

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


func _dictionary_summary(value, empty_text: String = "None") -> String:
	if not value is Dictionary:
		return empty_text

	var dictionary_value: Dictionary = value
	if dictionary_value.is_empty():
		return empty_text

	var keys: Array = dictionary_value.keys()
	keys.sort()

	var lines: Array[String] = []
	for raw_key in keys:
		lines.append(
			str(raw_key).replace("_", " ").capitalize()
			+ ": "
			+ UIFormatters.number(
				dictionary_value.get(raw_key, 0.0),
				2
			)
		)
	return " • ".join(lines)


func _refresh() -> void:
	if content == null:
		return

	for child in content.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		_card("TECHNOLOGY", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("TECHNOLOGY", "Country unavailable.", Color("#FB7185"))
		return

	var research = country.get_component("research")
	if research == null:
		_card("TECHNOLOGY", "ResearchComponent is unavailable.", Color("#FB7185"))
		return

	var state: Dictionary = research.state
	var currency := "USD"
	var economy = country.get_component("economy")
	if economy != null:
		currency = str(economy.get_state("currency_id", "USD"))

	_card(
		"RESEARCH CAPACITY",
		"Capacity "
		+ UIFormatters.quantity(state.get("research_capacity", 0.0))
		+ "  •  Researchers "
		+ UIFormatters.quantity(state.get("researchers", 0.0))
		+ "  •  Institutions "
		+ UIFormatters.quantity(state.get("research_institutions", 0.0))
		+ "\nFunding "
		+ UIFormatters.money(state.get("research_funding", 0.0), currency),
		Color("#38BDF8")
	)

	_card(
		"RESEARCH OUTPUT",
		"Efficiency "
		+ UIFormatters.normalized_or_percent(
			state.get("research_efficiency", 1.0)
		)
		+ "  •  Output "
		+ UIFormatters.rate(state.get("research_output", 0.0)),
		Color("#2DD4BF")
	)

	_card(
		"TECHNOLOGY LEVEL",
		UIFormatters.number(state.get("technology_level", 0.0), 2),
		Color("#A78BFA")
	)

	_card(
		"COMPLETED TECHNOLOGIES",
		_dictionary_summary(state.get("technologies", {})),
		Color("#34D399")
	)

	_card(
		"CAPABILITIES",
		_dictionary_summary(state.get("capabilities", {})),
		Color("#60A5FA")
	)

	var active_projects = state.get("active_projects", {})
	var completed_projects = state.get("completed_projects", {})

	var completed_count := 0
	if completed_projects is Dictionary:
		completed_count = completed_projects.size()

	_card(
		"PROJECTS",
		"Active "
		+ str(research.get_active_project_count())
		+ "  •  Completed "
		+ str(completed_count),
		Color("#F59E0B")
	)

	_card(
		"PROGRESS",
		_dictionary_summary(
			active_projects,
			"No active project records"
		)
		+ "\n"
		+ _dictionary_summary(
			state.get("research_progress", {}),
			"No research progress records"
		),
		Color("#F59E0B")
	)
