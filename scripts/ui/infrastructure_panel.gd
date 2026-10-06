class_name InfrastructurePanel
extends PanelContainer

## Step 20.5.3 — formatted infrastructure dashboard.

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
	title.add_theme_color_override("font_color", accent)
	title.add_theme_font_size_override("font_size", 13)
	column.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 11)
	column.add_child(body)


func _format_map(value: Dictionary) -> String:
	if value.is_empty():
		return "None"

	var keys: Array = value.keys()
	keys.sort()

	var parts: Array[String] = []
	for raw_key in keys:
		var n := float(value.get(raw_key, 0.0))
		parts.append(
			str(raw_key).capitalize()
			+ ": "
			+ (
				UIFormatters.percent(n)
				if n >= 0.0 and n <= 1.0
				else UIFormatters.quantity(n)
			)
		)

	return " • ".join(parts)


func _refresh() -> void:
	if content == null:
		return

	for child in content.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		_card("INFRASTRUCTURE", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_card("INFRASTRUCTURE", "Country unavailable.", Color("#FB7185"))
		return

	var infrastructure = country.get_component("infrastructure")
	if infrastructure == null:
		_card("INFRASTRUCTURE", "InfrastructureComponent is unavailable.", Color("#FB7185"))
		return

	var raw_state: Dictionary = {}
	var effective_state: Dictionary = {}
	var damage_state: Dictionary = {}

	var raw_variant = infrastructure.get_state("infrastructure", {})
	var effective_variant = infrastructure.get_state(
		"effective_infrastructure_capacity",
		{}
	)
	var damage_variant = infrastructure.get_state(
		"infrastructure_damage",
		{}
	)

	if raw_variant is Dictionary:
		raw_state = raw_variant
	if effective_variant is Dictionary:
		effective_state = effective_variant
	if damage_variant is Dictionary:
		damage_state = damage_variant

	if raw_state.is_empty():
		for key in ["transport", "railways", "roads", "ports", "power", "industrial", "storage"]:
			raw_state[key] = float(infrastructure.get_state(key, 0.0))

	_card("RAW CAPACITY", _format_map(raw_state), Color("#38BDF8"))
	_card("EFFECTIVE CAPACITY", _format_map(effective_state), Color("#34D399"))
	_card("DAMAGE", _format_map(damage_state), Color("#FB7185"))

	_card(
		"TOTAL CAPACITY",
		"Total effective capacity "
		+ UIFormatters.quantity(
			infrastructure.get_state("total_capacity", 0.0)
		)
		+ "\nAggregate infrastructure damage "
		+ UIFormatters.number(
			infrastructure.get_state("infrastructure_damage_total", 0.0),
			2
		),
		Color("#F59E0B")
	)
