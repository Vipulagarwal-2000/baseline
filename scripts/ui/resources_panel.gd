class_name ResourcesPanel
extends PanelContainer

## Step 20.5.1 — formatted resource dashboard.

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


func _map(value) -> String:
	if not value is Dictionary:
		return "None"

	var dictionary_value: Dictionary = value
	if dictionary_value.is_empty():
		return "None"

	var keys: Array = dictionary_value.keys()
	keys.sort()
	var parts: Array[String] = []

	for raw_key in keys:
		parts.append(
			str(raw_key).capitalize()
			+ ": "
			+ UIFormatters.quantity(dictionary_value.get(raw_key, 0.0))
		)

	return " • ".join(parts)


func _refresh() -> void:
	if content == null:
		return

	for child in content.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		_card("RESOURCES", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("RESOURCES", "Country unavailable.", Color("#FB7185"))
		return

	var resources = country.get_component("resources")
	if resources == null:
		_card("RESOURCES", "ResourceComponent is unavailable.", Color("#FB7185"))
		return

	_card(
		"PLANNED PRODUCTION",
		_map(resources.get_state("production", {})),
		Color("#38BDF8")
	)

	_card(
		"ACTUAL PRODUCTION",
		_map(resources.get_state("actual_production", {})),
		Color("#34D399")
	)

	_card(
		"CONSUMPTION",
		_map(resources.get_state("consumption", {})),
		Color("#F59E0B")
	)

	_card(
		"STOCKPILE",
		_map(resources.get_state("stockpile", {})),
		Color("#60A5FA")
	)

	_card(
		"SHORTAGES",
		_map(resources.get_state("shortages", {})),
		Color("#FB7185")
	)

	_card(
		"IMPORTS / EXPORTS",
		"Imports  " + _map(resources.get_state("imports", {}))
		+ "\nExports  " + _map(resources.get_state("exports", {})),
		Color("#A78BFA")
	)

	_card(
		"NET BALANCE",
		_map(resources.get_state("net_balance", {})),
		Color("#2DD4BF")
	)
