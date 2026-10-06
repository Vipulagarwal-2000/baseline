class_name CountryOverview
extends PanelContainer

## Step 20.4 — formatted country dashboard.
## Read-only presentation of authoritative country state.

var observer: GameplayObserver = null
var country_id: String = "india"

var title_label: Label
var grid: GridContainer
var resources_label: Label
var government_label: Label
var military_label: Label


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

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	column.add_child(title_label)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)

	resources_label = _body_label(column)
	government_label = _body_label(column)
	military_label = _body_label(column)


func _body_label(parent: Node) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	return label


func _metric(label_text: String, value_text: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(
		"panel",
		_style("#101B2E", accent, 1, 9)
	)
	grid.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	var caption := Label.new()
	caption.text = label_text
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", Color("#94A3B8"))
	column.add_child(caption)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 17)
	value.add_theme_color_override("font_color", accent)
	column.add_child(value)


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


func _clear() -> void:
	for child in grid.get_children():
		child.queue_free()


func _refresh() -> void:
	if title_label == null:
		return

	_clear()

	if observer == null or not observer.is_ready():
		title_label.text = "COUNTRY OVERVIEW — unavailable"
		resources_label.text = "Authoritative observation is not ready."
		government_label.text = ""
		military_label.text = ""
		return

	var country = observer.get_country(country_id)
	if country == null:
		title_label.text = "COUNTRY OVERVIEW — country unavailable"
		resources_label.text = ""
		government_label.text = ""
		military_label.text = ""
		return

	title_label.text = "COUNTRY OVERVIEW — " + str(country.name)

	var population = country.get_component("population")
	var economy = country.get_component("economy")
	var government = country.get_component("government")
	var resources = country.get_component("resources")
	var military = country.get_component("military")

	if population != null:
		_metric(
			"POPULATION",
			UIFormatters.population(population.get_state("population", 0.0)),
			Color("#2DD4BF")
		)

	if economy != null:
		var currency := str(economy.get_state("currency_id", "USD"))
		_metric(
			"GDP",
			UIFormatters.money(economy.get_state("gdp", 0.0), currency),
			Color("#38BDF8")
		)
		_metric(
			"TREASURY",
			UIFormatters.money(economy.get_state("treasury", 0.0), currency),
			Color("#A78BFA")
		)

	if government != null:
		_metric(
			"STABILITY",
			UIFormatters.normalized_or_percent(
				government.get_state("stability", 0.0)
			),
			Color("#34D399")
		)

	if military != null:
		_metric(
			"MILITARY READINESS",
			UIFormatters.normalized_or_percent(
				military.get_state("readiness", 0.0)
			),
			Color("#F59E0B")
		)

	if resources != null:
		var stock: Dictionary = resources.get_state("stockpile", {}) as Dictionary
		var shortages: Dictionary = resources.get_state("shortages", {}) as Dictionary
		resources_label.text = (
			"KEY RESOURCES\n"
			+ _format_map(stock)
			+ "\n\nSHORTAGES\n"
			+ _format_map(shortages)
		)
	else:
		resources_label.text = "KEY RESOURCES\nUnavailable."

	if government != null:
		government_label.text = (
			"GOVERNMENT\n"
			+ "Type: " + UIFormatters.status(
				government.get_state("government_type", "—")
			)
			+ "\nStability: "
			+ UIFormatters.percent(government.get_state("stability", 0.0))
			+ "\nPolitical pressure: "
			+ UIFormatters.percent(
				government.get_state("political_pressure", 0.0)
			)
		)
	else:
		government_label.text = "GOVERNMENT\nUnavailable."

	if military != null:
		military_label.text = (
			"MILITARY\n"
			+ "Readiness: "
			+ UIFormatters.percent(military.get_state("readiness", 0.0))
			+ "\nPower: "
			+ UIFormatters.percent(military.get_state("military_power", 0.0))
			+ "\nPressure: "
			+ UIFormatters.percent(
				military.get_state("military_pressure", 0.0)
			)
		)
	else:
		military_label.text = "MILITARY\nUnavailable."


func _format_map(value) -> String:
	if not value is Dictionary:
		return "—"

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
