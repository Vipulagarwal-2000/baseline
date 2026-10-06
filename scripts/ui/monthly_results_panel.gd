class_name MonthlyResultsPanel
extends PanelContainer

## Step 20.9 — Monthly results / consequence view.
##
## Presentation-only. The panel receives an evidence-backed result payload
## assembled from authoritative simulation state and recorded action/event
## results. It does not calculate or mutate the simulation.

signal closed

var title_label: Label
var date_label: Label
var summary_label: Label
var result_list: VBoxContainer
var close_button: Button
var backdrop: ColorRect


func _ready() -> void:
	set_mouse_filter(Control.MOUSE_FILTER_STOP)
	_build_ui()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()
	hide()


func _on_viewport_resized() -> void:
	if not is_inside_tree():
		return
	var viewport := get_viewport()
	if viewport == null:
		return

	# This node fills the viewport. The visible card and its backdrop are
	# managed as children so the modal remains centered at any resolution.
	var card := get_node_or_null("Card") as PanelContainer
	if card == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	var card_size := Vector2(
		minf(820.0, maxf(560.0, viewport_size.x - 80.0)),
		minf(500.0, maxf(360.0, viewport_size.y - 80.0))
	)
	card.size = card_size
	card.position = (viewport_size - card_size) * 0.5


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.0, 0.0, 0.0, 0.58)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var card := PanelContainer.new()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override(
		"panel",
		_make_style("#101B2E", "#38BDF8", 2, 14)
	)
	add_child(card)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 20)
	outer.add_theme_constant_override("margin_top", 16)
	outer.add_theme_constant_override("margin_right", 20)
	outer.add_theme_constant_override("margin_bottom", 16)
	card.add_child(outer)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	outer.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)

	var heading_column := VBoxContainer.new()
	heading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_column.add_theme_constant_override("separation", 2)
	header.add_child(heading_column)

	title_label = Label.new()
	title_label.text = "MONTHLY RESULTS"
	title_label.add_theme_font_size_override("font_size", 21)
	heading_column.add_child(title_label)

	date_label = Label.new()
	date_label.text = ""
	date_label.add_theme_font_size_override("font_size", 11)
	date_label.add_theme_color_override("font_color", Color("#94A3B8"))
	heading_column.add_child(date_label)

	close_button = Button.new()
	close_button.text = "CONTINUE"
	close_button.custom_minimum_size = Vector2(116, 38)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 12)
	column.add_child(summary_label)

	var separator := HSeparator.new()
	column.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.name = "ResultsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	result_list = content


func _make_style(background: String, border: String, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _clear_results() -> void:
	if result_list == null:
		return

	for child in result_list.get_children():
		child.queue_free()



func _format_large_number(value: float) -> String:
	if absf(value) >= 1000000000000.0:
		return "%.2fT" % (value / 1000000000000.0)
	if absf(value) >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)
	if absf(value) >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if absf(value) >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return "%.1f" % value


func _format_change_pair(before: float, after: float, delta: float) -> String:
	return (
		_format_large_number(before)
		+ " → "
		+ _format_large_number(after)
		+ " (Δ "
		+ _format_large_number(delta)
		+ ")"
	)


func _add_section(title_text: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		_make_style("#0D1626", "#26364D", 1, 10)
	)
	result_list.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", Color("#38BDF8"))
	column.add_child(heading)

	for line in lines:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func show_result(report: Dictionary) -> void:
	_clear_results()

	var before_date: String = str(report.get("before_date", "—"))
	var after_date: String = str(report.get("after_date", "—"))
	var country_name: String = str(report.get("country_name", "Player country"))

	title_label.text = "MONTHLY RESULTS"
	date_label.text = country_name + "  •  " + before_date + " → " + after_date

	var action_lines: Array[String] = report.get("action_lines", [])
	var event_lines: Array[String] = report.get("event_lines", [])
	var change_lines: Array[String] = report.get("change_lines", [])
	var resource_lines: Array[String] = report.get("resource_lines", [])

	var total_items: int = (
		action_lines.size()
		+ event_lines.size()
		+ change_lines.size()
		+ resource_lines.size()
	)

	summary_label.text = (
		str(total_items)
		+ " recorded change(s) or outcome(s) • "
		+ "authoritative simulation state"
	)

	_add_section("ACTIONS", action_lines)
	_add_section("MAJOR CHANGES", change_lines)
	_add_section("RESOURCES", resource_lines)
	_add_section("EVENTS", event_lines)

	if total_items == 0:
		var no_change := Label.new()
		no_change.text = (
			"No significant recorded results for this month. "
			+ "The simulation still advanced normally."
		)
		result_list.add_child(no_change)

	show()
