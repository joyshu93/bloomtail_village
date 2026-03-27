extends Control

var build_manager: BuildManager
var economy_manager: EconomyManager
var resident_manager: ResidentManager
var town_score_manager: TownScoreManager
var save_manager: SaveManager
var game_manager: GameManager

var funds_label: Label
var residents_label: Label
var happiness_label: Label
var date_label: Label
var build_status_label: Label
var info_title_label: Label
var info_body_label: RichTextLabel
var notifications_box: VBoxContainer
var resident_popup_label: RichTextLabel
var town_report_label: RichTextLabel
var save_popup_label: Label
var category_button_row: HFlowContainer
var item_list_box: VBoxContainer
var save_button_widget: Button
var load_button_widget: Button
var sound_button_widget: Button

var selected_category := "road"
var notifications: Array[String] = []
var sound_on := true
var last_scores := {
	"coziness": 0,
	"nature": 0,
	"convenience": 0,
	"atmosphere": 0
}
var last_comment := ""
var _layout_ready := false
var _signals_connected := false

func setup(builds: BuildManager, economy: EconomyManager, residents: ResidentManager, town_score: TownScoreManager, saver: SaveManager, game: GameManager) -> void:
	build_manager = builds
	economy_manager = economy
	resident_manager = residents
	town_score_manager = town_score
	save_manager = saver
	game_manager = game
	if is_node_ready():
		_finish_setup()

func _ready() -> void:
	_build_layout()
	if build_manager != null:
		_finish_setup()

func _finish_setup() -> void:
	if not _signals_connected:
		_wire_signals()
		_signals_connected = true
	if not save_button_widget.pressed.is_connected(save_manager.save_game):
		save_button_widget.pressed.connect(save_manager.save_game)
	if not load_button_widget.pressed.is_connected(save_manager.load_game):
		load_button_widget.pressed.connect(save_manager.load_game)
	var sound_callable := _toggle_sound.bind(sound_button_widget)
	if not sound_button_widget.pressed.is_connected(sound_callable):
		sound_button_widget.pressed.connect(sound_callable)
	_refresh_build_menu()
	_on_funds_changed(economy_manager.funds)
	_on_residents_changed(resident_manager.get_residents())
	_on_build_mode_changed(build_manager.selected_definition_id, build_manager.remove_mode)
	_on_clock_changed(game_manager.current_day, game_manager.get_season_name(), game_manager.speed, game_manager.paused)
	_on_scores_changed(town_score_manager.scores, town_score_manager.get_summary_comment())
	_on_selection_changed({
		"name": "Meadow Tile",
		"description": "Pick a tool on the left, then place it on the map.",
		"effects": "No active effect yet.",
		"cell": Vector2i(12, 12)
	})

func _build_layout() -> void:
	if _layout_ready:
		return
	_layout_ready = true
	anchor_right = 1.0
	anchor_bottom = 1.0

	var top_margin := $TopBar
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_bottom = 58
	var top_inner := HBoxContainer.new()
	top_inner.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_inner)
	top_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_inner.offset_left = 16
	top_inner.offset_top = 10
	top_inner.offset_right = -16
	top_inner.offset_bottom = -10
	funds_label = Label.new()
	residents_label = Label.new()
	happiness_label = Label.new()
	date_label = Label.new()
	build_status_label = Label.new()
	for label in [funds_label, residents_label, happiness_label, date_label, build_status_label]:
		top_inner.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_inner.add_child(spacer)
	for speed in [0, 1, 2, 4]:
		var button := Button.new()
		button.text = "Pause" if speed == 0 else "%dx" % speed
		button.pressed.connect(_on_speed_button.bind(speed))
		top_inner.add_child(button)
	var report_button := Button.new()
	report_button.text = "Village Report"
	report_button.pressed.connect(_toggle_panel.bind($TownReportPopup))
	top_inner.add_child(report_button)
	var save_button := Button.new()
	save_button.text = "Save / Settings"
	save_button.pressed.connect(_toggle_panel.bind($SavePopup))
	top_inner.add_child(save_button)

	var build_panel := $BuildMenu
	build_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	build_panel.offset_top = 72
	build_panel.offset_right = 250
	build_panel.offset_bottom = -120
	var build_inner := VBoxContainer.new()
	build_inner.add_theme_constant_override("separation", 8)
	build_panel.add_child(build_inner)
	build_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_inner.offset_left = 12
	build_inner.offset_top = 12
	build_inner.offset_right = -12
	build_inner.offset_bottom = -12
	var build_title := Label.new()
	build_title.text = "Build Menu"
	build_inner.add_child(build_title)
	category_button_row = HFlowContainer.new()
	category_button_row.add_theme_constant_override("h_separation", 6)
	category_button_row.add_theme_constant_override("v_separation", 6)
	build_inner.add_child(category_button_row)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_inner.add_child(scroll)
	item_list_box = VBoxContainer.new()
	item_list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(item_list_box)

	var info_panel := $InfoPanel
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	info_panel.offset_left = -340
	info_panel.offset_top = 72
	info_panel.offset_bottom = -120
	var info_inner := VBoxContainer.new()
	info_inner.add_theme_constant_override("separation", 8)
	info_panel.add_child(info_inner)
	info_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	info_inner.offset_left = 12
	info_inner.offset_top = 12
	info_inner.offset_right = -12
	info_inner.offset_bottom = -12
	info_title_label = Label.new()
	info_inner.add_child(info_title_label)
	info_body_label = RichTextLabel.new()
	info_body_label.fit_content = true
	info_body_label.scroll_active = false
	info_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_inner.add_child(info_body_label)

	var notifications_panel := $NotificationPanel
	notifications_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	notifications_panel.offset_top = -100
	notifications_panel.offset_bottom = -16
	notifications_panel.offset_left = 270
	notifications_panel.offset_right = -360
	notifications_box = VBoxContainer.new()
	notifications_box.add_theme_constant_override("separation", 4)
	notifications_panel.add_child(notifications_box)
	notifications_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notifications_box.offset_left = 12
	notifications_box.offset_top = 10
	notifications_box.offset_right = -12
	notifications_box.offset_bottom = -10

	_setup_popup($ResidentPopup, "Resident Details")
	_setup_popup($TownReportPopup, "Village Report")
	_setup_popup($SavePopup, "Save / Settings")
	resident_popup_label = RichTextLabel.new()
	resident_popup_label.fit_content = true
	resident_popup_label.scroll_active = false
	$ResidentPopup.get_child(0).add_child(resident_popup_label)
	town_report_label = RichTextLabel.new()
	town_report_label.fit_content = true
	town_report_label.scroll_active = false
	$TownReportPopup.get_child(0).add_child(town_report_label)
	save_popup_label = Label.new()
	save_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$SavePopup.get_child(0).add_child(save_popup_label)
	var save_actions := HBoxContainer.new()
	$SavePopup.get_child(0).add_child(save_actions)
	save_button_widget = Button.new()
	save_button_widget.text = "Save"
	save_actions.add_child(save_button_widget)
	load_button_widget = Button.new()
	load_button_widget.text = "Load"
	save_actions.add_child(load_button_widget)
	sound_button_widget = Button.new()
	sound_button_widget.text = "Sound: On"
	save_actions.add_child(sound_button_widget)
	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.pressed.connect(func() -> void: _push_notification("Main menu flow is still outside this MVP."))
	save_actions.add_child(menu_btn)

func _setup_popup(panel: Control, title: String) -> void:
	panel.visible = false
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -220
	panel.offset_top = -150
	panel.offset_right = 220
	panel.offset_bottom = 150
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 14
	box.offset_right = -14
	box.offset_bottom = -14
	var title_label := Label.new()
	title_label.text = title
	box.add_child(title_label)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_hide_panel.bind(panel))
	box.add_child(close_button)

func _wire_signals() -> void:
	build_manager.selection_changed.connect(_on_selection_changed)
	build_manager.build_mode_changed.connect(_on_build_mode_changed)
	economy_manager.funds_changed.connect(_on_funds_changed)
	economy_manager.income_applied.connect(_on_income_applied)
	resident_manager.residents_changed.connect(_on_residents_changed)
	resident_manager.resident_selected.connect(_on_resident_selected)
	town_score_manager.scores_changed.connect(_on_scores_changed)
	game_manager.clock_changed.connect(_on_clock_changed)
	game_manager.notification_pushed.connect(_push_notification)
	save_manager.save_completed.connect(_on_save_completed)
	save_manager.load_completed.connect(_on_load_completed)

func _refresh_build_menu() -> void:
	for child in category_button_row.get_children():
		child.queue_free()
	for category in build_manager.get_categories():
		var button := Button.new()
		button.text = category.capitalize()
		button.pressed.connect(_select_category.bind(category))
		category_button_row.add_child(button)
	_refresh_item_buttons()

func _refresh_item_buttons() -> void:
	for child in item_list_box.get_children():
		child.queue_free()
	if selected_category == "remove":
		var remove_button := Button.new()
		remove_button.text = "Enable Remove Tool"
		remove_button.pressed.connect(func() -> void: build_manager.set_build_mode("", true))
		item_list_box.add_child(remove_button)
		return
	for definition in build_manager.get_definitions_for_category(selected_category):
		var button := Button.new()
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = "%s (%d)\n%s\n%s" % [definition.display_name, definition.cost, definition.description, definition.effect_text]
		button.custom_minimum_size = Vector2(0, 76)
		button.pressed.connect(_select_building.bind(definition.id))
		item_list_box.add_child(button)

func _select_category(category: String) -> void:
	selected_category = category
	_refresh_item_buttons()

func _select_building(definition_id: String) -> void:
	build_manager.set_build_mode(definition_id, false)

func _on_selection_changed(info: Dictionary) -> void:
	info_title_label.text = "%s [%s]" % [info.get("name", "Tile"), _format_cell(info.get("cell", Vector2i.ZERO))]
	var active_text := ""
	if info.has("type") and info["type"] == "building":
		active_text = "\nStatus: %s" % ("Connected to road" if info.get("active", false) else "Needs road access")
	info_body_label.text = "[b]Effect[/b]\n%s%s\n\n[b]Description[/b]\n%s" % [info.get("effects", "-"), active_text, info.get("description", "-")]

func _on_build_mode_changed(definition_id: String, remove_mode: bool) -> void:
	if remove_mode:
		build_status_label.text = "Tool: Remove"
	elif definition_id.is_empty():
		build_status_label.text = "Tool: Inspect"
	else:
		var definition := build_manager.get_definition(definition_id)
		build_status_label.text = "Tool: %s" % definition.display_name

func _on_funds_changed(amount: int) -> void:
	funds_label.text = "Funds: %d" % amount

func _on_income_applied(amount: int) -> void:
	_push_notification("Daily income arrived: +%d" % amount)

func _on_residents_changed(residents: Array) -> void:
	residents_label.text = "Residents: %d / 8" % residents.size()
	happiness_label.text = "Happiness: %d" % resident_manager.get_average_happiness()
	if not residents.is_empty():
		for resident in residents:
			if not bool(resident["request_done"]) and String(resident["request"]) != "":
				_push_notification("%s says: %s" % [resident["name"], resident["request"]])
				break

func _on_resident_selected(resident: Dictionary) -> void:
	resident_popup_label.text = "[b]%s[/b]\nSpecies: %s\nPersonality: %s\nHappiness: %d\nPreferred environment: %s\n\n%s" % [
		resident["name"],
		resident["species"],
		resident["personality"],
		resident["happiness"],
		resident["preferred_tag"],
		resident["current_line"]
	]
	$ResidentPopup.visible = true

func _on_scores_changed(scores: Dictionary, comment: String) -> void:
	last_scores = scores.duplicate(true)
	last_comment = comment
	town_report_label.text = "[b]Coziness[/b]: %d\n[b]Nature[/b]: %d\n[b]Convenience[/b]: %d\n[b]Atmosphere[/b]: %d\n\n%s" % [
		int(scores.get("coziness", 0)),
		int(scores.get("nature", 0)),
		int(scores.get("convenience", 0)),
		int(scores.get("atmosphere", scores.get("vibe", 0))),
		comment
	]

func _on_clock_changed(day: int, season_name: String, speed: int, paused: bool) -> void:
	date_label.text = "%s Day %d" % [season_name, game_manager.get_day_in_season(day)]
	if paused:
		date_label.text += " [Paused]"
	elif speed > 1:
		date_label.text += " [%dx]" % speed

func _on_speed_button(speed: int) -> void:
	game_manager.set_speed(speed)

func _push_notification(text: String) -> void:
	if notifications.has(text):
		return
	notifications.push_front(text)
	while notifications.size() > 3:
		notifications.pop_back()
	for child in notifications_box.get_children():
		child.queue_free()
	for message in notifications:
		var label := Label.new()
		label.text = message
		notifications_box.add_child(label)

func _toggle_panel(panel: Control) -> void:
	panel.visible = not panel.visible
	if panel == $SavePopup:
		save_popup_label.text = "Save slot: cozy_village_save.json\nTime controls: Pause, 1x, 2x, 4x.\nSound is a placeholder toggle for MVP."

func _hide_panel(panel: Control) -> void:
	panel.visible = false

func _toggle_sound(button: Button) -> void:
	sound_on = not sound_on
	button.text = "Sound: %s" % ("On" if sound_on else "Off")

func _on_save_completed() -> void:
	_push_notification("Village saved.")

func _on_load_completed(success: bool) -> void:
	_push_notification("Village loaded." if success else "No save file found yet.")
	if success:
		town_score_manager.recalculate(build_manager, resident_manager)

func _format_cell(cell: Vector2i) -> String:
	return "%d, %d" % [cell.x, cell.y]
