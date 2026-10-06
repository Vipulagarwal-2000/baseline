class_name ProductionPanel
extends PanelContainer

## Step 20.5.2 — formatted production dashboard.

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
	title.add_theme_color_override("font_color", accent)
	title.add_theme_font_size_override("font_size", 13)
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
		_card("PRODUCTION", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("PRODUCTION", "Country unavailable.", Color("#FB7185"))
		return

	var industry = country.get_component("industry")
	var economy = country.get_component("economy")

	if industry == null:
		_card("PRODUCTION", "IndustryComponent is unavailable.", Color("#FB7185"))
		return

	if economy != null:
		_card(
			"CAPACITY",
			"Industrial capacity "
			+ UIFormatters.quantity(
				economy.get_state("industrial_capacity", 0.0)
			)
			+ "\nAgricultural capacity "
			+ UIFormatters.quantity(
				economy.get_state("agricultural_capacity", 0.0)
			)
			+ "  •  Production efficiency "
			+ UIFormatters.percent(
				economy.get_state("production_efficiency", 0.0)
			),
			Color("#38BDF8")
		)

	var processes_variant = industry.get_state("processes", {})
	if not processes_variant is Dictionary or processes_variant.is_empty():
		_card("ACTIVE PROCESSES", "No process records are currently exposed.", Color("#94A3B8"))
		return

	var process_ids: Array = processes_variant.keys()
	process_ids.sort()

	for raw_id in process_ids:
		var process_id := str(raw_id)
		var process_data = processes_variant.get(raw_id, {})
		if not process_data is Dictionary:
			continue

		var active := bool(process_data.get("active", false))
		var capacity := float(process_data.get("capacity", 0.0))
		var efficiency := float(process_data.get("efficiency", 0.0))

		var state_text := "ACTIVE" if active else "INACTIVE"

		var line := (
			state_text
			+ "  •  "
			+ process_id.replace("_", " ").capitalize()
			+ "\nCapacity "
			+ UIFormatters.quantity(capacity)
			+ " / month"
			+ "  •  Efficiency "
			+ UIFormatters.normalized_or_percent(efficiency)
		)

		_card(
			"PRODUCTION PROCESS",
			line,
			Color("#34D399") if active else Color("#64748B")
		)
