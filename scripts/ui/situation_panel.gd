class_name SituationPanel
extends PanelContainer

## Lightweight situation/alerts view using currently exposed authoritative state.

var simulation: SimulationEngine = null
var observer: GameplayObserver = null
var country_id: String = "india"
var content: VBoxContainer


func initialize(
	live_simulation: SimulationEngine,
	live_observer: GameplayObserver,
	live_country_id: String
) -> void:
	simulation = live_simulation
	observer = live_observer
	country_id = live_country_id
	_refresh()


func _ready() -> void:
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)


func _clear() -> void:
	for child in content.get_children():
		child.queue_free()


func _add(title_text: String, body_text: String, accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_style("#0F1B2E", accent, 1, 9)
	)
	content.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
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

	_clear()

	if observer == null or not observer.is_ready():
		_add("SITUATION", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var country = observer.get_country(country_id)
	if country == null:
		_add("SITUATION", "Player country is not available.", Color("#FB7185"))
		return

	var economy = country.get_component("economy")
	var government = country.get_component("government")
	var military = country.get_component("military")
	var resources = country.get_component("resources")

	if economy != null:
		var pressure := float(economy.get_state("economic_pressure", 0.0))
		var inflation := float(economy.get_state("inflation", 0.0))
		if pressure > 0.35:
			_add(
				"ECONOMIC PRESSURE",
				"Pressure is currently "
					+ UIFormatters.percent(pressure)
					+ ". Review the economy before committing new costs.",
				Color("#F59E0B")
			)
		else:
			_add(
				"ECONOMY",
				"Pressure "
					+ UIFormatters.percent(pressure)
					+ " • Inflation "
					+ UIFormatters.percent(inflation),
				Color("#34D399")
			)

	if government != null:
		var stability := float(government.get_state("stability", 0.0))
		var political_pressure := float(
			government.get_state("political_pressure", 0.0)
		)
		var accent := Color("#34D399")
		if stability < 0.5 or political_pressure > 0.5:
			accent = Color("#FB7185")

		_add(
			"GOVERNMENT",
			"Stability "
				+ UIFormatters.percent(stability)
				+ " • Political pressure "
				+ UIFormatters.percent(political_pressure),
			accent
		)

	if military != null:
		var readiness := float(military.get_state("readiness", 0.0))
		var military_pressure := float(
			military.get_state("military_pressure", 0.0)
		)

		_add(
			"MILITARY",
			"Readiness "
				+ UIFormatters.percent(readiness)
				+ " • Pressure "
				+ UIFormatters.percent(military_pressure),
			Color("#F59E0B") if readiness < 0.5 else Color("#34D399")
		)

	if resources != null:
		var shortages = resources.get_state("shortages", {})
		var shortage_count := 0
		var shortage_names: Array[String] = []

		if shortages is Dictionary:
			for raw_key in shortages.keys():
				if float(shortages.get(raw_key, 0.0)) > 0.0:
					shortage_count += 1
					shortage_names.append(str(raw_key).capitalize())

		if shortage_count > 0:
			_add(
				"RESOURCE SHORTAGES",
				str(shortage_count)
					+ " shortage category(ies): "
					+ ", ".join(shortage_names),
				Color("#FB7185")
			)
		else:
			_add(
				"RESOURCES",
				"No current shortage quantities are exposed.",
				Color("#34D399")
			)
