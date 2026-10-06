class_name HistoryPanel
extends PanelContainer

var observer: GameplayObserver = null
var country_id: String = "india"
var list: VBoxContainer

func initialize(live_observer: GameplayObserver, live_country_id: String) -> void:
	observer = live_observer
	country_id = live_country_id
	_refresh()

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	margin.add_child(list)
	_refresh()

func _refresh() -> void:
	if list == null:
		return

	for child in list.get_children():
		child.queue_free()

	if observer == null or not observer.is_ready():
		var label := Label.new()
		label.text = "History is not available."
		list.add_child(label)
		return

	var history: Array = observer.get_action_outcome_history()
	var shown := 0

	for i in range(history.size() - 1, -1, -1):
		var record_variant = history[i]
		if not record_variant is Dictionary:
			continue

		var record: Dictionary = record_variant
		if str(record.get("actor", "")) != country_id:
			continue

		var item := PanelContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 7)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 7)
		item.add_child(margin)

		var line := Label.new()
		line.text = (
			UIFormatters.status(record.get("type", "action"))
			+ " → "
			+ str(record.get("target", "—"))
			+ "  •  "
			+ UIFormatters.status(record.get("status", "—"))
			+ "  •  "
			+ str(record.get("start", "—"))
			+ " → "
			+ str(record.get("end", "—"))
		)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(line)

		list.add_child(item)
		shown += 1

		if shown >= 12:
			break

	if shown == 0:
		var empty := Label.new()
		empty.text = "No player action outcomes recorded yet."
		list.add_child(empty)

func set_country_id(live_country_id: String) -> void:
	if live_country_id.strip_edges().is_empty():
		return
	country_id = live_country_id.strip_edges().to_lower()
	_refresh()


func refresh() -> void:
	_refresh()
