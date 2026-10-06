class_name ContextualActionPanel
extends PanelContainer

## Step 20 UI — Contextual action discovery.
##
## The player can now discover and submit real actions from the domain
## they are currently inspecting. Submission still uses the existing
## SimulationEngine.issue_player_action() path.

signal action_submitted
signal open_decisions_requested

var simulation: SimulationEngine = null
var observer: GameplayObserver = null
var player_country_id: String = "india"

var context_name: String = "AVAILABLE ACTIONS"
var keywords: Array[String] = []
var show_all: bool = false

var title_label: Label
var subtitle_label: Label
var action_list: VBoxContainer
var command_button: Button


func configure(
	live_simulation: SimulationEngine,
	live_observer: GameplayObserver,
	country_id: String,
	display_name: String,
	filter_keywords: Array[String],
	display_all: bool = false
) -> void:
	simulation = live_simulation
	observer = live_observer
	player_country_id = country_id.strip_edges().to_lower()
	context_name = display_name
	keywords = filter_keywords
	show_all = display_all
	_refresh()


func set_country_id(country_id: String) -> void:
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
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)

	var heading_column := VBoxContainer.new()
	heading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_column.add_theme_constant_override("separation", 1)
	header.add_child(heading_column)

	title_label = Label.new()
	title_label.text = context_name
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#67E8F9"))
	heading_column.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Actions appear here only when the real simulation exposes them."
	subtitle_label.add_theme_font_size_override("font_size", 10)
	subtitle_label.add_theme_color_override("font_color", Color("#94A3B8"))
	heading_column.add_child(subtitle_label)

	command_button = Button.new()
	command_button.text = "VIEW ALL"
	command_button.custom_minimum_size = Vector2(100, 34)
	command_button.pressed.connect(_on_open_decisions)
	header.add_child(command_button)

	action_list = VBoxContainer.new()
	action_list.add_theme_constant_override("separation", 5)
	column.add_child(action_list)


func _clear() -> void:
	if action_list == null:
		return

	for child in action_list.get_children():
		child.queue_free()


func _matches(option: DecisionOption) -> bool:
	if show_all or keywords.is_empty():
		return true

	var haystack := (
		str(option.name)
		+ " "
		+ str(option.action_type)
		+ " "
		+ str(option.description)
	).to_lower()

	for keyword in keywords:
		if haystack.contains(keyword.to_lower()):
			return true

	return false


func _make_action_card(option: DecisionOption) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		_style("#0F1B2E", "#27445E", 1, 9)
	)
	action_list.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = str(option.name)
	name_label.add_theme_font_size_override("font_size", 13)
	info.add_child(name_label)

	var detail := Label.new()
	detail.text = (
		UIFormatters.status(option.action_type)
		+ " • "
		+ (
			str(option.target_id)
			if not str(option.target_id).is_empty()
			else "No specific target"
		)
	)
	detail.add_theme_font_size_override("font_size", 10)
	detail.add_theme_color_override("font_color", Color("#94A3B8"))
	info.add_child(detail)

	var description := Label.new()
	description.text = str(option.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 10)
	info.add_child(description)

	var submit := Button.new()
	submit.text = "QUEUE"
	submit.custom_minimum_size = Vector2(92, 38)
	submit.pressed.connect(_submit.bind(option))
	row.add_child(submit)

	if not option.is_available():
		submit.disabled = true
		submit.text = "BLOCKED"

	return card


func _style(background: String, border: String, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _submit(option: DecisionOption) -> void:
	if simulation == null:
		return

	if not option.is_available():
		return

	var world := simulation.get_world()
	if world == null:
		return

	var result: Dictionary = simulation.issue_player_action(
		player_country_id,
		option,
		world.get_date_string()
	)

	var success := bool(result.get("success", false))

	if success:
		subtitle_label.text = "Queued: " + str(option.name)
	else:
		subtitle_label.text = (
			"Rejected: "
			+ str(result.get("failure_reason", "Action was not admitted."))
		)

	action_submitted.emit()
	_refresh()


func _on_open_decisions() -> void:
	open_decisions_requested.emit()


func _refresh() -> void:
	if action_list == null:
		return

	_clear()

	if observer == null or not observer.is_ready():
		subtitle_label.text = "Simulation observation is not ready."
		return

	var options: Array = observer.get_decision_options(player_country_id)
	var shown := 0

	for raw_option in options:
		if not raw_option is DecisionOption:
			continue

		var option := raw_option as DecisionOption
		if not _matches(option):
			continue

		action_list.add_child(_make_action_card(option))
		shown += 1

		# Context strips should stay compact. Full discovery belongs in Decisions.
		if shown >= 3:
			break

	if shown == 0:
		subtitle_label.text = "No compatible live actions currently exposed."
	else:
		subtitle_label.text = str(shown) + " live action option(s). Queue without leaving this section."
