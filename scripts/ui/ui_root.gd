extends Control

var build_manager: BuildManager
var game_manager: GameManager

var button_panel: PanelContainer
var button_box: VBoxContainer
var status_panel: PanelContainer
var status_title: Label
var status_label: Label
var selection_title: Label
var selection_detail: Label
var selected_buttons := {}
var is_ready := false
var signals_connected := false

func setup(manager: BuildManager, game: GameManager) -> void:
	build_manager = manager
	game_manager = game
	if is_node_ready():
		_finish_setup()

func _ready() -> void:
	_build_layout()
	is_ready = true
	if build_manager != null:
		_finish_setup()

func _build_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	button_panel = PanelContainer.new()
	add_child(button_panel)
	button_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	button_panel.offset_left = 16
	button_panel.offset_top = 16
	button_panel.offset_right = 274
	button_panel.offset_bottom = 348

	button_box = VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	button_panel.add_child(button_box)
	button_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_box.offset_left = 12
	button_box.offset_top = 12
	button_box.offset_right = -12
	button_box.offset_bottom = -12

	var title := Label.new()
	title.text = "Build Menu"
	title.add_theme_font_size_override("font_size", 20)
	button_box.add_child(title)

	var hint := Label.new()
	hint.text = "Pick a placeable, then click the ground.\nRoad supports drag placement."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button_box.add_child(hint)

	var separator := HSeparator.new()
	button_box.add_child(separator)

	selection_title = Label.new()
	selection_title.text = "Selected: -"
	selection_title.add_theme_font_size_override("font_size", 16)
	button_box.add_child(selection_title)

	selection_detail = Label.new()
	selection_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_detail.text = "Choose an item to start placing."
	button_box.add_child(selection_detail)

	var button_separator := HSeparator.new()
	button_box.add_child(button_separator)

	status_panel = PanelContainer.new()
	add_child(status_panel)
	status_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status_panel.offset_left = 16
	status_panel.offset_top = -132
	status_panel.offset_right = 430
	status_panel.offset_bottom = -16

	status_label = Label.new()
	status_title = Label.new()
	status_title.text = "Status"
	status_title.add_theme_font_size_override("font_size", 16)
	status_panel.add_child(status_title)
	status_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	status_title.offset_left = 12
	status_title.offset_top = 10
	status_title.offset_right = 120
	status_title.offset_bottom = 32

	status_panel.add_child(status_label)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_label.offset_left = 12
	status_label.offset_top = 36
	status_label.offset_right = -12
	status_label.offset_bottom = -12
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "Loading..."

func _finish_setup() -> void:
	if not signals_connected:
		build_manager.selection_changed.connect(_on_selection_changed)
		game_manager.status_changed.connect(_on_status_changed)
		signals_connected = true
	_rebuild_placeable_buttons()
	_on_selection_changed(build_manager.selected_id)
	_on_status_changed(game_manager.status_text)

func _rebuild_placeable_buttons() -> void:
	for id in selected_buttons.keys():
		var existing: Button = selected_buttons[id]
		existing.queue_free()
	selected_buttons.clear()
	for placeable in build_manager.get_placeables():
		var button := Button.new()
		button.text = "%s  [%s]" % [placeable.display_name, placeable.category.capitalize()]
		button.custom_minimum_size = Vector2(0, 46)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.pressed.connect(_on_placeable_button_pressed.bind(placeable.id))
		button_box.add_child(button)
		selected_buttons[placeable.id] = button
	var remove_button := Button.new()
	remove_button.text = "Remove  [Tool]"
	remove_button.custom_minimum_size = Vector2(0, 46)
	remove_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	remove_button.toggle_mode = true
	remove_button.pressed.connect(_on_placeable_button_pressed.bind(BuildManager.REMOVE_TOOL_ID))
	button_box.add_child(remove_button)
	selected_buttons[BuildManager.REMOVE_TOOL_ID] = remove_button

func _on_placeable_button_pressed(placeable_id: String) -> void:
	build_manager.select_placeable(placeable_id)

func _on_selection_changed(placeable_id: String) -> void:
	for id in selected_buttons.keys():
		var button: Button = selected_buttons[id]
		var is_selected: bool = String(id) == placeable_id
		button.button_pressed = is_selected
		button.modulate = Color(1.0, 0.95, 0.8, 1.0) if is_selected else Color(1, 1, 1, 1)
	var selected: PlaceableData = build_manager.get_selected_data()
	if build_manager.is_remove_selected():
		selection_title.text = "Selected: Remove"
		selection_detail.text = "Click a placed object to remove it.\nEmpty cells cannot be removed."
		return
	if selected == null:
		selection_title.text = "Selected: -"
		selection_detail.text = "Choose an item to start placing."
		return
	selection_title.text = "Selected: %s" % selected.display_name
	var road_text: String = "Needs adjacent road" if selected.requires_road else "No road needed"
	selection_detail.text = "%s\n%s" % [selected.description, road_text]

func _on_status_changed(text: String) -> void:
	status_label.text = "%s\n\nControls:\nWASD / Arrow Keys move camera\nMouse Wheel zoom\nLeft Click place\nRoad: drag to paint" % text
