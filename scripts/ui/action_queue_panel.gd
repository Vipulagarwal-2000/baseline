class_name ActionQueuePanel
extends PanelContainer

## Step 20.7 — Action validation / queue / progress.
## Reads authoritative SimAction state and ActionManager outcome history.

var observer: GameplayObserver = null
var player_country_id: String = "india"

var title_label: Label
var summary_label: Label
var queue_list: VBoxContainer
var history_list: VBoxContainer


func initialize(live_observer: GameplayObserver, country_id: String = "india") -> void:
	observer = live_observer
	if not country_id.strip_edges().is_empty():
		player_country_id = country_id.strip_edges().to_lower()
	_refresh()


func set_player_country_id(country_id: String) -> void:
	if country_id.strip_edges().is_empty():
		return
	player_country_id = country_id.strip_edges().to_lower()
	_refresh()


func refresh() -> void:
	_refresh()


func _ready() -> void:
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "QueueScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	title_label = Label.new()
	title_label.text = "ACTION QUEUE"
	title_label.add_theme_font_size_override("font_size", 18)
	column.add_child(title_label)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary_label)

	var queue_heading := Label.new()
	queue_heading.text = "CURRENT ACTIONS"
	queue_heading.add_theme_font_size_override("font_size", 14)
	column.add_child(queue_heading)

	queue_list = VBoxContainer.new()
	queue_list.add_theme_constant_override("separation", 7)
	column.add_child(queue_list)

	var separator := HSeparator.new()
	column.add_child(separator)

	var history_heading := Label.new()
	history_heading.text = "RECENT OUTCOMES"
	history_heading.add_theme_font_size_override("font_size", 14)
	column.add_child(history_heading)

	history_list = VBoxContainer.new()
	history_list.add_theme_constant_override("separation", 6)
	column.add_child(history_list)


func _clear(container: VBoxContainer) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func _action_card(action: SimAction) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var title := Label.new()
	title.text = str(action.action_type)
	title.add_theme_font_size_override("font_size", 15)
	column.add_child(title)

	var status := Label.new()
	status.text = (
		"Status: " + str(action.state)
		+ "  |  Target: "
		+ (str(action.target_id) if not action.target_id.is_empty() else "—")
	)
	column.add_child(status)

	var progress := Label.new()
	progress.text = (
		"Progress: %.1f%%  |  Remaining: %d month(s)"
		% [action.progress * 100.0, action.duration_months]
	)
	column.add_child(progress)

	var start := Label.new()
	start.text = "Start: " + (
		action.start_date if not action.start_date.is_empty() else "pending"
	)
	column.add_child(start)

	if not action.failure_reason.is_empty():
		var reason := Label.new()
		reason.text = "Reason: " + action.failure_reason
		reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(reason)

	return panel


func _history_card(record: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var title := Label.new()
	title.text = (
		str(record.get("type", "action"))
		+ " → "
		+ (str(record.get("target", "—")) if not str(record.get("target", "")).is_empty() else "—")
	)
	column.add_child(title)

	var status := Label.new()
	status.text = (
		"Status: " + str(record.get("status", "—"))
		+ " | " + str(record.get("start", "—"))
		+ " → " + str(record.get("end", "—"))
	)
	column.add_child(status)

	var reason_text := str(record.get("failure_reason", ""))
	if not reason_text.is_empty():
		var reason := Label.new()
		reason.text = "Reason: " + reason_text
		reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(reason)

	return panel


func _refresh() -> void:
	if title_label == null:
		return

	_clear(queue_list)
	_clear(history_list)

	if observer == null or not observer.is_ready():
		title_label.text = "ACTION QUEUE — unavailable"
		summary_label.text = "Authoritative observation is not ready."
		return

	title_label.text = "ACTION QUEUE — " + player_country_id.capitalize()

	var pending: Array = observer.get_player_pending_actions(player_country_id)
	summary_label.text = (
		"Queued / active: " + str(pending.size())
		+ " | Progress is read from authoritative SimAction state."
	)

	if pending.is_empty():
		var empty := Label.new()
		empty.text = "No queued or active player actions."
		queue_list.add_child(empty)
	else:
		for raw_action in pending:
			var action := raw_action as SimAction
			if action != null:
				queue_list.add_child(_action_card(action))

	var history: Array = observer.get_action_outcome_history()
	var shown: int = 0

	for index in range(history.size() - 1, -1, -1):
		var record_variant = history[index]
		if not record_variant is Dictionary:
			continue

		var record: Dictionary = record_variant
		if str(record.get("actor", "")) != player_country_id:
			continue

		history_list.add_child(_history_card(record))
		shown += 1

		if shown >= 6:
			break

	if shown == 0:
		var empty_history := Label.new()
		empty_history.text = "No terminal player action outcomes recorded yet."
		history_list.add_child(empty_history)
