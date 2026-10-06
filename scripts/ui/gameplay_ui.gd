class_name GameplayUI
extends Control

## Step 20 UI Presentation Pass — expanded national desk.
##
## This script is presentation/integration code only. It reads from the
## authoritative SimulationEngine / WorldState and requests the existing
## monthly simulation tick. It does not own simulation state or formulas.

signal state_refreshed
signal month_advance_completed(before_date: String, after_date: String)


# -----------------------------------------------------------------------------
# RUNTIME REFERENCES
# -----------------------------------------------------------------------------

var simulation: SimulationEngine = null
var gameplay_session: GameplaySession = null
var gameplay_observer: GameplayObserver = null
var player_country_id: String = "india"


# -----------------------------------------------------------------------------
# UI REFERENCES
# -----------------------------------------------------------------------------

var country_label: Label
var date_label: Label
var status_label: Label
var world_status_label: Label
var advance_month_button: Button
var country_overview: CountryOverview
var resources_panel: ResourcesPanel
var production_panel: ProductionPanel
var infrastructure_panel: InfrastructurePanel
var economy_panel: EconomyPanel
var government_panel: GovernmentPanel
var military_panel: MilitaryPanel
var technology_panel: TechnologyPanel
var trade_diplomacy_panel: TradeDiplomacyPanel
var player_action_panel: PlayerActionPanel
var action_queue_panel: ActionQueuePanel
var monthly_results_panel: MonthlyResultsPanel

var overview_action_panel: ContextualActionPanel
var economy_action_panel: ContextualActionPanel
var government_action_panel: ContextualActionPanel
var military_action_panel: ContextualActionPanel
var foreign_action_panel: ContextualActionPanel
var technology_action_panel: ContextualActionPanel
var history_panel: HistoryPanel
var situation_panel: SituationPanel


# -----------------------------------------------------------------------------
# PUBLIC INTEGRATION API
# -----------------------------------------------------------------------------

## Called by main.gd after the live SimulationEngine has been created.
func initialize(
	live_simulation: SimulationEngine,
	authoritative_world: WorldState = null,
	country_id: String = "india",
	session: GameplaySession = null,
	observer: GameplayObserver = null
) -> void:
	simulation = live_simulation
	gameplay_session = session
	gameplay_observer = observer

	if gameplay_observer == null:
		gameplay_observer = GameplayObserver.new()
		gameplay_observer.initialize(live_simulation)

	if gameplay_session != null:
		player_country_id = gameplay_session.get_player_country_id()

	if country_overview != null:
		country_overview.initialize(gameplay_observer, player_country_id)

	if resources_panel != null:
		resources_panel.initialize(gameplay_observer, player_country_id)

	if production_panel != null:
		production_panel.initialize(gameplay_observer, player_country_id)

	if infrastructure_panel != null:
		infrastructure_panel.initialize(gameplay_observer, player_country_id)

	if economy_panel != null:
		economy_panel.initialize(gameplay_observer, player_country_id)

	if government_panel != null:
		government_panel.initialize(gameplay_observer, player_country_id)

	if military_panel != null:
		military_panel.initialize(gameplay_observer, player_country_id)

	if technology_panel != null:
		technology_panel.initialize(gameplay_observer, player_country_id)

	if trade_diplomacy_panel != null:
		trade_diplomacy_panel.initialize(gameplay_observer, player_country_id)

	if player_action_panel != null:
		player_action_panel.initialize(
			simulation,
			gameplay_observer,
			player_country_id
		)

	if action_queue_panel != null:
		action_queue_panel.initialize(
			gameplay_observer,
			player_country_id
		)
	if overview_action_panel != null:
		overview_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"QUICK ACTIONS",
			[],
			true
		)

	if economy_action_panel != null:
		economy_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"ECONOMIC ACTIONS",
			["economic", "economy", "investment", "budget", "finance"]
		)

	if government_action_panel != null:
		government_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"POLICY ACTIONS",
			["government", "policy", "political", "reform"]
		)

	if military_action_panel != null:
		military_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"MILITARY ACTIONS",
			["military", "defense", "readiness", "mobilization", "army", "navy", "air"]
		)

	if foreign_action_panel != null:
		foreign_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"FOREIGN ACTIONS",
			["trade", "diplomatic", "foreign", "sanction", "agreement", "outreach"]
		)

	if technology_action_panel != null:
		technology_action_panel.configure(
			simulation,
			gameplay_observer,
			player_country_id,
			"RESEARCH ACTIONS",
			["research", "technology", "adoption", "innovation"]
		)

	# `authoritative_world` is supplied by main.gd so the UI can be initialized
	# against the same live world context. The UI still reads the world through
	# SimulationEngine during refresh; it does not own this reference.
	if authoritative_world != null and simulation != null and simulation.get_world() != authoritative_world:
		push_warning("GameplayUI: supplied WorldState differs from SimulationEngine.get_world(); using SimulationEngine authority.")

	if not country_id.strip_edges().is_empty():
		player_country_id = country_id

	_refresh_from_simulation()


## Changes only the presentation/session selection. It does not mutate the
## authoritative country entity.
func set_player_country_id(country_id: String) -> void:
	if country_id.strip_edges().is_empty():
		return

	player_country_id = country_id.strip_edges().to_lower()

	if gameplay_session != null:
		gameplay_session.set_player_country_id(player_country_id)

	_refresh_from_simulation()



# -----------------------------------------------------------------------------
# BEAUTIFUL GAMEPLAY UI — STEP 20.6 SHELL REWORK
# -----------------------------------------------------------------------------

const BG_COLOR: Color = Color("#0B1220")
const SURFACE_COLOR: Color = Color("#111827")
const SURFACE_RAISED_COLOR: Color = Color("#172235")
const SURFACE_HOVER_COLOR: Color = Color("#1C2B42")
const BORDER_COLOR: Color = Color("#26364D")
const TEXT_PRIMARY: Color = Color("#F8FAFC")
const TEXT_SECONDARY: Color = Color("#94A3B8")
const ACCENT_BLUE: Color = Color("#38BDF8")
const ACCENT_TEAL: Color = Color("#2DD4BF")
const ACCENT_GOLD: Color = Color("#F59E0B")
const ACCENT_GREEN: Color = Color("#34D399")
const DANGER_RED: Color = Color("#FB7185")

var section_pages: Array[Control] = []
var nav_buttons: Array[Button] = []
var nav_group: ButtonGroup = null
var current_section_index: int = 0

# Step 20.8 — explicit monthly resolution guard/state.
var is_resolving_month: bool = false
var last_resolved_before_date: String = ""
var last_resolved_after_date: String = ""
var _month_before_state: Dictionary = {}
var _month_before_action_history_size: int = 0

var population_kpi: Label
var gdp_kpi: Label
var stability_kpi: Label
var readiness_kpi: Label
var treasury_kpi: Label
var alert_kpi: Label

var main_content: Control
var status_dot: ColorRect
var status_message_label: Label


func _ready() -> void:
	_sync_to_viewport()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_to_viewport):
		viewport.size_changed.connect(_sync_to_viewport)

	_setup_theme()
	_build_ui()
	_sync_to_viewport()
	call_deferred("_sync_to_viewport")
	_refresh_from_simulation()


func _sync_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	position = Vector2.ZERO
	size = viewport.get_visible_rect().size


func _setup_theme() -> void:
	var theme := Theme.new()

	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.25))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 1)

	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_pressed_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", Color("#64748B"))

	theme.set_font_size("font_size", "Label", 14)
	theme.set_font_size("font_size", "Button", 13)

	theme.set_stylebox("normal", "PanelContainer", _panel_style(SURFACE_COLOR, BORDER_COLOR, 1, 12))
	theme.set_stylebox("normal", "Button", _button_style(SURFACE_COLOR, BORDER_COLOR, 1, 10))
	theme.set_stylebox("hover", "Button", _button_style(SURFACE_HOVER_COLOR, ACCENT_BLUE, 1, 10))
	theme.set_stylebox("pressed", "Button", _button_style("#223653", ACCENT_BLUE, 2, 10))
	theme.set_stylebox("focus", "Button", _button_style(SURFACE_HOVER_COLOR, ACCENT_BLUE, 1, 10))
	theme.set_stylebox("disabled", "Button", _button_style("#0F172A", "#253247", 1, 10))

	self.theme = theme


func _panel_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


func _button_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return _panel_style(background, border, border_width, radius)


func _make_label(
	text_value: String,
	font_size: int,
	color: Color = TEXT_PRIMARY
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_panel(background: Color = SURFACE_COLOR) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(background, BORDER_COLOR, 1, 12)
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func _make_nav_button(text_value: String, index: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(168, 42)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_ALL
	button.button_group = nav_group
	button.pressed.connect(_on_nav_pressed.bind(index))

	var normal := _panel_style(SURFACE_COLOR, Color("#1F2D40"), 1, 9)
	normal.content_margin_left = 14
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)

	var hover := _panel_style(SURFACE_HOVER_COLOR, Color("#31516F"), 1, 9)
	hover.content_margin_left = 14
	hover.content_margin_right = 10
	button.add_theme_stylebox_override("hover", hover)

	var pressed := _panel_style("#16324D", ACCENT_BLUE, 2, 9)
	pressed.content_margin_left = 14
	pressed.content_margin_right = 10
	button.add_theme_stylebox_override("pressed", pressed)

	return button


func _build_header(parent: VBoxContainer) -> void:
	var header := _make_panel("#0F1A2C")
	header.custom_minimum_size = Vector2(0, 84)
	parent.add_child(header)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 11)
	header.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 2)
	row.add_child(title_column)

	var title := _make_label("WORLD SIMULATOR", 24)
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	title_column.add_child(title)

	country_label = _make_label("India", 14, TEXT_SECONDARY)
	title_column.add_child(country_label)

	var date_column := VBoxContainer.new()
	date_column.custom_minimum_size = Vector2(210, 0)
	date_column.add_theme_constant_override("separation", 2)
	row.add_child(date_column)

	var date_caption := _make_label("SIMULATION DATE", 10, TEXT_SECONDARY)
	date_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_column.add_child(date_caption)

	date_label = _make_label("01/01/1950", 17, ACCENT_GOLD)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_column.add_child(date_label)

	advance_month_button = Button.new()
	advance_month_button.text = "ADVANCE MONTH  →"
	advance_month_button.custom_minimum_size = Vector2(200, 46)
	advance_month_button.pressed.connect(_on_advance_month_pressed)
	var advance_style := _button_style("#17415A", ACCENT_BLUE, 1, 10)
	advance_month_button.add_theme_stylebox_override("normal", advance_style)
	advance_month_button.add_theme_stylebox_override(
		"hover",
		_button_style("#1D526F", ACCENT_TEAL, 1, 10)
	)
	advance_month_button.add_theme_stylebox_override(
		"pressed",
		_button_style("#14354C", ACCENT_TEAL, 2, 10)
	)
	row.add_child(advance_month_button)


func _build_kpi_card(
	parent: HBoxContainer,
	caption: String,
	value_node: Label,
	accent: Color
) -> void:
	var card := _make_panel(SURFACE_COLOR)
	card.custom_minimum_size = Vector2(0, 68)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)

	var caption_label := _make_label(caption, 10, TEXT_SECONDARY)
	column.add_child(caption_label)

	value_node.add_theme_font_size_override("font_size", 18)
	value_node.add_theme_color_override("font_color", accent)
	column.add_child(value_node)


func _build_kpis(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "KPIBar"
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 68)
	parent.add_child(row)

	population_kpi = Label.new()
	gdp_kpi = Label.new()
	stability_kpi = Label.new()
	readiness_kpi = Label.new()
	treasury_kpi = Label.new()
	alert_kpi = Label.new()

	_build_kpi_card(row, "POPULATION", population_kpi, ACCENT_TEAL)
	_build_kpi_card(row, "GDP", gdp_kpi, ACCENT_BLUE)
	_build_kpi_card(row, "STABILITY", stability_kpi, ACCENT_GREEN)
	_build_kpi_card(row, "READINESS", readiness_kpi, ACCENT_GOLD)
	_build_kpi_card(row, "TREASURY", treasury_kpi, Color("#A78BFA"))
	_build_kpi_card(row, "ALERTS", alert_kpi, Color("#FB7185"))


func _build_sidebar(parent: HBoxContainer) -> void:
	var sidebar := _make_panel("#0E1726")
	sidebar.custom_minimum_size = Vector2(210, 0)
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(sidebar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	sidebar.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	var nav_title := _make_label("NATIONAL DESK", 11, TEXT_SECONDARY)
	column.add_child(nav_title)

	var divider := ColorRect.new()
	divider.color = ACCENT_BLUE
	divider.custom_minimum_size = Vector2(0, 2)
	column.add_child(divider)

	nav_group = ButtonGroup.new()

	var labels: Array[String] = [
		"OVERVIEW",
		"ECONOMY",
		"GOVERNMENT",
		"MILITARY",
		"FOREIGN",
		"TECHNOLOGY",
		"EVENTS",
		"DECISIONS"
	]

	for index in range(labels.size()):
		var nav_button := _make_nav_button(labels[index], index)
		column.add_child(nav_button)
		nav_buttons.append(nav_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var legend_title := _make_label("STATUS", 10, TEXT_SECONDARY)
	column.add_child(legend_title)

	var legend := _make_label(
		"● READY    ● ATTENTION\n"
		+ "Blue = action    Gold = strategic\n"
		+ "Green = healthy    Red = alert",
		9,
		TEXT_SECONDARY
	)
	column.add_child(legend)

	var hint := _make_label(
		"Inspect a domain, act in context, then advance the month.",
		10,
		TEXT_SECONDARY
	)
	column.add_child(hint)


func _add_page_heading(
	page: VBoxContainer,
	title_text: String,
	subtitle_text: String
) -> void:
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 2)
	page.add_child(heading)

	var title := _make_label(title_text, 20, TEXT_PRIMARY)
	heading.add_child(title)

	var subtitle := _make_label(subtitle_text, 11, TEXT_SECONDARY)
	heading.add_child(subtitle)


func _make_subtabs(parent: VBoxContainer) -> TabContainer:
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(0, 0)
	parent.add_child(tabs)
	return tabs


func _add_panel_tab(tabs: TabContainer, panel: Control, tab_name: String) -> void:
	panel.name = tab_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(panel)


func _build_content_pages(content_host: VBoxContainer) -> void:
	section_pages.clear()

	# 0 — Overview
	var overview_page := VBoxContainer.new()
	overview_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overview_page.add_theme_constant_override("separation", 8)
	content_host.add_child(overview_page)
	section_pages.append(overview_page)

	_add_page_heading(
		overview_page,
		"NATIONAL OVERVIEW",
		"Your country's current state, pressures and immediately available actions."
	)

	overview_action_panel = ContextualActionPanel.new()
	overview_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"QUICK ACTIONS",
		[],
		true
	)
	overview_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	overview_page.add_child(overview_action_panel)

	_add_panel_tab(
		_make_single_panel_container(overview_page),
		country_overview,
		"overview_panel"
	)

	# 1 — Economy
	var economy_page := VBoxContainer.new()
	economy_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	economy_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	economy_page.add_theme_constant_override("separation", 8)
	content_host.add_child(economy_page)
	section_pages.append(economy_page)

	_add_page_heading(
		economy_page,
		"ECONOMY",
		"Financial health, output, purchasing power, prices and state finance."
	)

	economy_action_panel = ContextualActionPanel.new()
	economy_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"ECONOMIC ACTIONS",
		["economic", "economy", "investment", "budget", "finance"]
	)
	economy_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	economy_page.add_child(economy_action_panel)

	var economy_tabs := _make_subtabs(economy_page)
	_add_panel_tab(economy_tabs, economy_panel, "ECONOMY")
	_add_panel_tab(economy_tabs, resources_panel, "RESOURCES")
	_add_panel_tab(economy_tabs, production_panel, "PRODUCTION")
	_add_panel_tab(economy_tabs, infrastructure_panel, "INFRASTRUCTURE")

	# 2 — Government
	var government_page := VBoxContainer.new()
	government_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	government_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	government_page.add_theme_constant_override("separation", 8)
	content_host.add_child(government_page)
	section_pages.append(government_page)

	_add_page_heading(
		government_page,
		"GOVERNMENT",
		"Institutions, political pressure, legitimacy and public stability."
	)

	government_action_panel = ContextualActionPanel.new()
	government_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"POLICY ACTIONS",
		["government", "policy", "political", "reform"]
	)
	government_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	government_page.add_child(government_action_panel)

	_add_panel_tab(
		_make_single_panel_container(government_page),
		government_panel,
		"government_panel"
	)

	# 3 — Military
	var military_page := VBoxContainer.new()
	military_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	military_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	military_page.add_theme_constant_override("separation", 8)
	content_host.add_child(military_page)
	section_pages.append(military_page)

	_add_page_heading(
		military_page,
		"MILITARY",
		"Readiness, force structure, logistics, pressure and strategic capability."
	)

	military_action_panel = ContextualActionPanel.new()
	military_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"MILITARY ACTIONS",
		["military", "defense", "readiness", "mobilization", "army", "navy", "air"]
	)
	military_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	military_page.add_child(military_action_panel)

	_add_panel_tab(
		_make_single_panel_container(military_page),
		military_panel,
		"military_panel"
	)

	# 4 — Foreign
	var foreign_page := VBoxContainer.new()
	foreign_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foreign_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	foreign_page.add_theme_constant_override("separation", 8)
	content_host.add_child(foreign_page)
	section_pages.append(foreign_page)

	_add_page_heading(
		foreign_page,
		"FOREIGN AFFAIRS",
		"Trade, diplomatic relationships, agreements and international position."
	)

	foreign_action_panel = ContextualActionPanel.new()
	foreign_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"FOREIGN ACTIONS",
		["trade", "diplomatic", "foreign", "sanction", "agreement", "outreach"]
	)
	foreign_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	foreign_page.add_child(foreign_action_panel)

	_add_panel_tab(
		_make_single_panel_container(foreign_page),
		trade_diplomacy_panel,
		"foreign_panel"
	)

	# 5 — Technology
	var technology_page := VBoxContainer.new()
	technology_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	technology_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	technology_page.add_theme_constant_override("separation", 8)
	content_host.add_child(technology_page)
	section_pages.append(technology_page)

	_add_page_heading(
		technology_page,
		"TECHNOLOGY & RESEARCH",
		"Research capacity, active projects, adoption and technological capability."
	)

	technology_action_panel = ContextualActionPanel.new()
	technology_action_panel.configure(
		simulation,
		gameplay_observer,
		player_country_id,
		"RESEARCH ACTIONS",
		["research", "technology", "adoption", "innovation"]
	)
	technology_action_panel.open_decisions_requested.connect(func(): _show_section(7))
	technology_page.add_child(technology_action_panel)

	_add_panel_tab(
		_make_single_panel_container(technology_page),
		technology_panel,
		"technology_panel"
	)

	# 6 — Events / Situation
	var events_page := VBoxContainer.new()
	events_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	events_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	events_page.add_theme_constant_override("separation", 8)
	content_host.add_child(events_page)
	section_pages.append(events_page)

	_add_page_heading(
		events_page,
		"EVENTS & SITUATION",
		"Important outcomes, pressure signals and recent changes."
	)

	situation_panel = SituationPanel.new()
	situation_panel.initialize(simulation, gameplay_observer, player_country_id)
	events_page.add_child(situation_panel)


	history_panel = HistoryPanel.new()
	history_panel.initialize(gameplay_observer, player_country_id)
	events_page.add_child(history_panel)

	# 7 — Decisions
	var decisions_page := VBoxContainer.new()
	decisions_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decisions_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	decisions_page.add_theme_constant_override("separation", 8)
	content_host.add_child(decisions_page)
	section_pages.append(decisions_page)

	_add_page_heading(
		decisions_page,
		"DECISION CENTER",
		"See everything currently actionable, admitted actions and progress."
	)

	var decision_tabs := _make_subtabs(decisions_page)
	_add_panel_tab(decision_tabs, player_action_panel, "AVAILABLE")
	_add_panel_tab(decision_tabs, action_queue_panel, "ACTION QUEUE")


func _make_single_panel_container(parent: VBoxContainer) -> TabContainer:
	var tabs := TabContainer.new()
	tabs.tabs_visible = false
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tabs)
	return tabs


func _build_status_bar(parent: VBoxContainer) -> void:
	var status_panel := _make_panel("#0E1726")
	status_panel.custom_minimum_size = Vector2(0, 36)
	parent.add_child(status_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	status_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	status_dot = ColorRect.new()
	status_dot.color = ACCENT_GREEN
	status_dot.custom_minimum_size = Vector2(6, 6)
	row.add_child(status_dot)

	status_message_label = _make_label("READY", 11, TEXT_SECONDARY)
	status_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status_message_label)


func _create_domain_panels() -> void:
	country_overview = CountryOverview.new()
	resources_panel = ResourcesPanel.new()
	production_panel = ProductionPanel.new()
	infrastructure_panel = InfrastructurePanel.new()
	economy_panel = EconomyPanel.new()
	government_panel = GovernmentPanel.new()
	military_panel = MilitaryPanel.new()
	technology_panel = TechnologyPanel.new()
	trade_diplomacy_panel = TradeDiplomacyPanel.new()
	player_action_panel = PlayerActionPanel.new()
	action_queue_panel = ActionQueuePanel.new()
	monthly_results_panel = MonthlyResultsPanel.new()


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background := ColorRect.new()
	background.name = "Background"
	background.color = BG_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)

	var margin := MarginContainer.new()
	margin.name = "MainMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root_column := VBoxContainer.new()
	root_column.name = "RootColumn"
	root_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_theme_constant_override("separation", 8)
	margin.add_child(root_column)

	_build_header(root_column)
	_build_kpis(root_column)
	_create_domain_panels()

	var main_row := HBoxContainer.new()
	main_row.name = "MainRow"
	main_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 10)
	root_column.add_child(main_row)

	_build_sidebar(main_row)

	var content_panel := _make_panel("#0E1726")
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_child(content_panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 12)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_right", 12)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_panel.add_child(content_margin)

	var content_stack := VBoxContainer.new()
	content_stack.name = "ContentStack"
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_stack)

	main_content = content_stack
	_build_content_pages(content_stack)
	_build_status_bar(root_column)

	# Monthly result overlay. It is hidden until the real monthly boundary
	# completes, then presents only recorded/evidence-backed consequences.
	monthly_results_panel.name = "MonthlyResultsPanel"
	monthly_results_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(monthly_results_panel)

	# Default selection.
	if nav_buttons.size() > 0:
		nav_buttons[0].button_pressed = true
	_show_section(0)


func _on_nav_pressed(index: int) -> void:
	_show_section(index)



func _set_month_status(
	message: String,
	accent: Color,
	interactive: bool
) -> void:
	if status_message_label != null:
		status_message_label.text = message
	if status_dot != null:
		status_dot.color = accent
	if advance_month_button != null:
		advance_month_button.disabled = not interactive


func _show_section(index: int) -> void:
	current_section_index = clampi(index, 0, max(section_pages.size() - 1, 0))

	for page_index in range(section_pages.size()):
		var page := section_pages[page_index]
		page.visible = page_index == current_section_index

	for button_index in range(nav_buttons.size()):
		nav_buttons[button_index].button_pressed = button_index == current_section_index


func _format_population(value: float) -> String:
	if value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)
	if value >= 1000000.0:
		return "%.1fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return "%.0f" % value


func _format_money(value: float) -> String:
	var absolute_value := absf(value)
	if absolute_value >= 1000000000000.0:
		return "%.2fT" % (value / 1000000000000.0)
	if absolute_value >= 1000000000.0:
		return "%.2fB" % (value / 1000000000.0)
	if absolute_value >= 1000000.0:
		return "%.2fM" % (value / 1000000.0)
	if absolute_value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return "%.0f" % value


func _format_percent(value: float) -> String:
	return "%.1f%%" % (value * 100.0)


# -----------------------------------------------------------------------------
# AUTHORITATIVE READ PATH
# -----------------------------------------------------------------------------

func _refresh_from_simulation() -> void:
	if country_label == null:
		return

	if gameplay_observer == null:
		country_label.text = "Country: —"
		date_label.text = "Date: —"
		status_message_label.text = "Simulation not connected"
		status_dot.color = DANGER_RED
		advance_month_button.disabled = true
		state_refreshed.emit()
		return

	if not gameplay_observer.is_ready():
		country_label.text = "Country: —"
		date_label.text = "Date: —"
		status_message_label.text = "Simulation is unavailable"
		status_dot.color = DANGER_RED
		advance_month_button.disabled = true
		state_refreshed.emit()
		return

	var world: WorldState = gameplay_observer.get_world()
	if world == null:
		country_label.text = "Country: —"
		date_label.text = "Date: —"
		status_message_label.text = "Authoritative world state unavailable"
		status_dot.color = DANGER_RED
		advance_month_button.disabled = true
		state_refreshed.emit()
		return

	var player_country = gameplay_observer.get_country(player_country_id)
	if player_country == null:
		country_label.text = "Country: —"
		status_message_label.text = (
			"Player country '" + player_country_id
			+ "' is not present in the live world."
		)
		status_dot.color = DANGER_RED
	else:
		country_label.text = (
			"Country: "
			+ gameplay_observer.get_country_display_name(player_country_id)
		)
		status_message_label.text = "Ready"
		status_dot.color = ACCENT_GREEN

	date_label.text = "Date: " + gameplay_observer.get_date_string()
	advance_month_button.disabled = player_country == null

	# Compact authoritative KPI read path.
	if player_country != null:
		var population_component = player_country.get_component("population")
		var economy_component = player_country.get_component("economy")
		var government_component = player_country.get_component("government")
		var military_component = player_country.get_component("military")

		if population_component != null:
			population_kpi.text = UIFormatters.population(population_component.get_state("population", 0.0))
		else:
			population_kpi.text = "—"

		if economy_component != null:
			var currency_id := str(
				economy_component.get_state("currency_id", "USD")
			)
			gdp_kpi.text = UIFormatters.money(
				float(economy_component.get_state("gdp", 0.0)),
				currency_id
			)
			treasury_kpi.text = UIFormatters.money(
				float(economy_component.get_state("treasury", 0.0)),
				currency_id
			)
		else:
			gdp_kpi.text = "—"
			treasury_kpi.text = "—"

		if government_component != null:
			stability_kpi.text = _format_percent(
				float(
					government_component.get_state(
						"stability",
						0.0
					)
				)
			)
		else:
			stability_kpi.text = "—"

		if military_component != null:
			readiness_kpi.text = _format_percent(
				float(
					military_component.get_state(
						"readiness",
						0.0
					)
				)
			)
		else:
			readiness_kpi.text = "—"
		# Compact situation signal: count immediately visible decision options.
		var available_options: Array = gameplay_observer.get_decision_options(
			player_country_id
		)
		alert_kpi.text = str(available_options.size())
	else:
		population_kpi.text = "—"
		gdp_kpi.text = "—"
		stability_kpi.text = "—"
		readiness_kpi.text = "—"
		treasury_kpi.text = "—"
		alert_kpi.text = "—"

	if country_overview != null:
		country_overview.set_country_id(player_country_id)
		country_overview.refresh()

	if resources_panel != null:
		resources_panel.set_country_id(player_country_id)
		resources_panel.refresh()

	if production_panel != null:
		production_panel.set_country_id(player_country_id)
		production_panel.refresh()

	if infrastructure_panel != null:
		infrastructure_panel.set_country_id(player_country_id)
		infrastructure_panel.refresh()

	if economy_panel != null:
		economy_panel.set_country_id(player_country_id)
		economy_panel.refresh()

	if government_panel != null:
		government_panel.set_country_id(player_country_id)
		government_panel.refresh()

	if military_panel != null:
		military_panel.set_country_id(player_country_id)
		military_panel.refresh()

	if technology_panel != null:
		technology_panel.set_country_id(player_country_id)
		technology_panel.refresh()

	if trade_diplomacy_panel != null:
		trade_diplomacy_panel.set_country_id(player_country_id)
		trade_diplomacy_panel.refresh()

	if player_action_panel != null:
		player_action_panel.set_player_country_id(player_country_id)
		player_action_panel.refresh()

	if action_queue_panel != null:
		action_queue_panel.set_player_country_id(player_country_id)
		action_queue_panel.refresh()

	if overview_action_panel != null:
		overview_action_panel.set_country_id(player_country_id)
		overview_action_panel.refresh()
	if economy_action_panel != null:
		economy_action_panel.set_country_id(player_country_id)
		economy_action_panel.refresh()
	if government_action_panel != null:
		government_action_panel.set_country_id(player_country_id)
		government_action_panel.refresh()
	if military_action_panel != null:
		military_action_panel.set_country_id(player_country_id)
		military_action_panel.refresh()
	if foreign_action_panel != null:
		foreign_action_panel.set_country_id(player_country_id)
		foreign_action_panel.refresh()
	if technology_action_panel != null:
		technology_action_panel.set_country_id(player_country_id)
		technology_action_panel.refresh()
	if history_panel != null:
		history_panel.set_country_id(player_country_id)
		history_panel.refresh()
	if situation_panel != null:
		situation_panel.initialize(
			simulation,
			gameplay_observer,
			player_country_id
		)

	state_refreshed.emit()



func _capture_month_start_state(country) -> Dictionary:
	var state: Dictionary = {}

	if country == null:
		return state

	var population = country.get_component("population")
	var economy = country.get_component("economy")
	var government = country.get_component("government")
	var military = country.get_component("military")
	var infrastructure = country.get_component("infrastructure")
	var research = country.get_component("research")
	var resources = country.get_component("resources")

	if population != null:
		state["population"] = float(population.get_state("population", 0.0))

	if economy != null:
		state["gdp"] = float(economy.get_state("gdp", 0.0))
		state["growth_rate"] = float(economy.get_state("growth_rate", 0.0))
		state["inflation"] = float(economy.get_state("inflation", 0.0))
		state["economic_pressure"] = float(economy.get_state("economic_pressure", 0.0))

	if government != null:
		state["stability"] = float(government.get_state("stability", 0.0))
		state["political_pressure"] = float(
			government.get_state("political_pressure", 0.0)
		)
		state["approval"] = float(government.get_state("approval", 0.0))

	if military != null:
		state["military_power"] = float(
			military.get_state("military_power", 0.0)
		)
		state["readiness"] = float(
			military.get_state("readiness", 0.0)
		)
		state["military_pressure"] = float(
			military.get_state("military_pressure", 0.0)
		)

	if infrastructure != null:
		var effective = infrastructure.get_state(
			"effective_infrastructure_capacity",
			{}
		)
		if effective is Dictionary:
			state["effective_infrastructure"] = effective.duplicate(true)

	if research != null:
		state["technology_level"] = float(
			research.get_state("technology_level", 0.0)
		)
		state["research_output"] = float(
			research.get_state("research_output", 0.0)
		)

	if resources != null:
		var stockpile = resources.get_state("stockpile", {})
		if stockpile is Dictionary:
			state["stockpile"] = stockpile.duplicate(true)

	return state


func _compare_number(
	before_state: Dictionary,
	after_component,
	key: String,
	label: String,
	percent: bool = false
) -> String:
	if not before_state.has(key) or after_component == null:
		return ""

	var before: float = float(before_state.get(key, 0.0))
	var after: float = float(after_component.get_state(key, 0.0))
	var delta: float = after - before

	if is_zero_approx(delta):
		return ""

	if percent:
		return (
			label
			+ ": "
			+ _format_percent(before)
			+ " → "
			+ _format_percent(after)
			+ " ("
			+ _format_percent(delta)
			+ ")"
		)

	return (
		label
		+ ": "
		+ str(before)
		+ " → "
		+ str(after)
		+ " (Δ "
		+ str(delta)
		+ ")"
	)


func _collect_monthly_report(
	country,
	before_date: String,
	after_date: String
) -> Dictionary:
	var report: Dictionary = {
		"before_date": before_date,
		"after_date": after_date,
		"country_name": "" if country == null else str(country.name),
		"action_lines": [],
		"event_lines": [],
		"change_lines": [],
		"resource_lines": []
	}

	if country == null:
		return report

	var economy = country.get_component("economy")
	var government = country.get_component("government")
	var military = country.get_component("military")
	var population = country.get_component("population")
	var infrastructure = country.get_component("infrastructure")
	var research = country.get_component("research")
	var resources = country.get_component("resources")

	var changes: Array[String] = []

	var value: String = _compare_number(
		_month_before_state,
		population,
		"population",
		"Population"
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(_month_before_state, economy, "gdp", "GDP")
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		economy,
		"growth_rate",
		"Growth rate",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		economy,
		"inflation",
		"Inflation",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		economy,
		"economic_pressure",
		"Economic pressure",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		government,
		"stability",
		"Government stability",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		government,
		"political_pressure",
		"Political pressure",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		government,
		"approval",
		"Government approval",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		military,
		"military_power",
		"Military power",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		military,
		"readiness",
		"Military readiness",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		military,
		"military_pressure",
		"Military pressure",
		true
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		research,
		"technology_level",
		"Technology level"
	)
	if not value.is_empty():
		changes.append(value)

	value = _compare_number(
		_month_before_state,
		research,
		"research_output",
		"Research output"
	)
	if not value.is_empty():
		changes.append(value)

	report["change_lines"] = changes

	# Resource changes are actual stockpile differences, not derived claims.
	if resources != null and _month_before_state.has("stockpile"):
		var before_stock: Dictionary = _month_before_state["stockpile"]
		var after_stock = resources.get_state("stockpile", {})

		if after_stock is Dictionary:
			var resource_changes: Array[String] = []
			var keys: Array = after_stock.keys()
			keys.sort()

			for raw_key in keys:
				var key: String = str(raw_key)
				if not before_stock.has(raw_key):
					continue

				var before_value: float = float(before_stock.get(raw_key, 0.0))
				var after_value: float = float(after_stock.get(raw_key, 0.0))
				var delta: float = after_value - before_value

				if is_zero_approx(delta):
					continue

				resource_changes.append(
					key.capitalize()
					+ ": "
					+ str(before_value)
					+ " → "
					+ str(after_value)
					+ " (Δ "
					+ str(delta)
					+ ")"
				)

			report["resource_lines"] = resource_changes

	# Action outcomes are taken directly from ActionManager history.
	if gameplay_observer != null:
		var history: Array = gameplay_observer.get_action_outcome_history()
		var new_action_lines: Array[String] = []

		for index in range(history.size() - 1, _month_before_action_history_size - 1, -1):
			var record_variant = history[index]
			if not record_variant is Dictionary:
				continue

			var record: Dictionary = record_variant

			if str(record.get("actor", "")) != player_country_id:
				continue

			var action_line := (
				str(record.get("type", "action"))
				+ " → "
				+ str(record.get("target", "—"))
				+ " | "
				+ str(record.get("status", "—"))
			)

			var reason := str(record.get("failure_reason", ""))
			if not reason.is_empty():
				action_line += " | " + reason

			new_action_lines.append(action_line)

			if new_action_lines.size() >= 8:
				break

		report["action_lines"] = new_action_lines

	# Event results are read directly from the established event integration
	# system. No event semantics are invented here.
	if simulation != null:
		var event_system = simulation.get_system(
			"event_simulation_integration"
		)

		if event_system != null and event_system.has_method("get_last_results"):
			var event_results: Array = event_system.get_last_results()
			var event_lines: Array[String] = []

			for raw_result in event_results:
				if not raw_result is Dictionary:
					continue

				var event_result: Dictionary = raw_result
				var event_line := (
					str(event_result.get("event_id", "event"))
					+ " → "
					+ str(event_result.get("target", "—"))
					+ " | "
					+ str(event_result.get("status", "—"))
				)

				var event_reason := str(
					event_result.get("failure_reason", "")
				)
				if not event_reason.is_empty():
					event_line += " | " + event_reason

				event_lines.append(event_line)

			report["event_lines"] = event_lines

	return report


# -----------------------------------------------------------------------------
# MONTHLY FLOW
# -----------------------------------------------------------------------------

func _on_advance_month_pressed() -> void:
	# Step 20.8 gate:
	# one player command = exactly one authoritative monthly tick.
	if is_resolving_month:
		return

	if simulation == null:
		_set_month_status(
			"Cannot advance: SimulationEngine is not connected.",
			DANGER_RED,
			true
		)
		return

	if not simulation.is_ready():
		_set_month_status(
			"Cannot advance: SimulationEngine is not ready.",
			DANGER_RED,
			true
		)
		return

	var world: WorldState = null
	if gameplay_observer != null:
		world = gameplay_observer.get_world()
	else:
		world = simulation.get_world()

	if world == null:
		_set_month_status(
			"Cannot advance: WorldState is unavailable.",
			DANGER_RED,
			true
		)
		return

	var before_date: String = world.get_date_string()

	var player_country = (
		gameplay_observer.get_country(player_country_id)
		if gameplay_observer != null
		else world.get_entity(player_country_id)
	)

	_month_before_state = _capture_month_start_state(player_country)

	var action_history: Array = []
	if gameplay_observer != null:
		action_history = gameplay_observer.get_action_outcome_history()
	_month_before_action_history_size = action_history.size()

	is_resolving_month = true
	last_resolved_before_date = before_date
	last_resolved_after_date = ""

	_set_month_status(
		"Resolving " + before_date + " → next month...",
		ACCENT_GOLD,
		false
	)

	# The UI does not invoke domain systems, ActionManager, or SystemManager.
	# SimulationEngine remains the sole monthly authority.
	simulation.tick_month()

	var after_date: String = world.get_date_string()

	last_resolved_after_date = after_date
	is_resolving_month = false

	_refresh_from_simulation()

	if monthly_results_panel != null:
		var result_country = (
			gameplay_observer.get_country(player_country_id)
			if gameplay_observer != null
			else world.get_entity(player_country_id)
		)

		var report := _collect_monthly_report(
			result_country,
			before_date,
			after_date
		)

		monthly_results_panel.show_result(report)

	_set_month_status(
		"Month resolved: " + before_date + " → " + after_date,
		ACCENT_GREEN,
		true
	)

	month_advance_completed.emit(before_date, after_date)
