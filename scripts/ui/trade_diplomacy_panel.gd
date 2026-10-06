class_name TradeDiplomacyPanel
extends PanelContainer

## Step 20.5.8 — formatted trade / diplomacy dashboard.

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
		_card("FOREIGN AFFAIRS", "Authoritative observation is not ready.", Color("#FB7185"))
		return

	var world: WorldState = observer.get_world()
	var country = observer.get_country(country_id)

	if world == null or country == null:
		_card("FOREIGN AFFAIRS", "Country/world state unavailable.", Color("#FB7185"))
		return

	_card(
		"TRADE RECORDS",
		"Agreements "
		+ str(world.get_trade_agreement_count())
		+ "  •  Routes "
		+ str(world.get_trade_route_count())
		+ "  •  Transactions "
		+ str(world.get_trade_transaction_count()),
		Color("#38BDF8")
	)

	var agreement_lines: Array[String] = []
	for raw_id in world.trade_agreements.keys():
		var agreement = world.get_trade_agreement(str(raw_id))
		if agreement == null:
			continue
		if str(agreement.exporter_id) != country_id and str(agreement.importer_id) != country_id:
			continue

		agreement_lines.append(
			str(agreement.exporter_id)
			+ " → "
			+ str(agreement.importer_id)
			+ "  •  "
			+ str(agreement.resource_id)
			+ "  •  "
			+ UIFormatters.quantity(agreement.quantity)
			+ "  •  "
			+ UIFormatters.duration_months(
				agreement.remaining_duration_months
			)
			+ " remaining"
			+ "  •  "
			+ UIFormatters.status(agreement.status)
		)

		if agreement_lines.size() >= 8:
			break

	_card(
		"ACTIVE AGREEMENTS",
		"None" if agreement_lines.is_empty() else "\n".join(agreement_lines),
		Color("#34D399")
	)

	var route_lines: Array[String] = []
	for raw_id in world.trade_routes.keys():
		var route = world.get_trade_route(str(raw_id))
		if route == null:
			continue
		if str(route.exporter_id) != country_id and str(route.importer_id) != country_id:
			continue

		route_lines.append(
			str(route.exporter_id)
			+ " → "
			+ str(route.importer_id)
			+ "  •  capacity "
			+ UIFormatters.rate(route.monthly_throughput_capacity)
			+ "  •  "
			+ UIFormatters.status(route.status)
			+ "  •  restriction "
			+ UIFormatters.bool_status(route.route_restriction_active)
			+ " ("
			+ UIFormatters.percent(route.route_restriction_factor)
			+ ")"
		)

		if route_lines.size() >= 8:
			break

	_card(
		"TRADE ROUTES",
		"None" if route_lines.is_empty() else "\n".join(route_lines),
		Color("#60A5FA")
	)

	var relationship_lines: Array[String] = []
	var relationships: Dictionary = country.relationships
	for raw_target in relationships.keys():
		relationship_lines.append(
			str(raw_target).capitalize()
			+ "  •  "
			+ str(relationships.get(raw_target))
		)

		if relationship_lines.size() >= 10:
			break

	_card(
		"BILATERAL RELATIONSHIPS",
		"None" if relationship_lines.is_empty() else "\n".join(relationship_lines),
		Color("#A78BFA")
	)
