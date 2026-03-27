extends Control

var build_manager: BuildManager
var game_manager: GameManager

var button_panel: PanelContainer
var button_box: VBoxContainer
var status_panel: PanelContainer
var status_label: Label
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
	button_panel.offset_right = 206
	button_panel.offset_bottom = 250

	button_box = VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	button_panel.add_child(button_box)
	button_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_box.offset_left = 12
	button_box.offset_top = 12
	button_box.offset_right = -12
	button_box.offset_bottom = -12

	var title := Label.new()
	title.text = "Placeables"
	button_box.add_child(title)

	var hint := Label.new()
	hint.text = "Select an item and click the ground."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button_box.add_child(hint)

	status_panel = PanelContainer.new()
	add_child(status_panel)
	status_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status_panel.offset_left = 16
	status_panel.offset_top = -116
	status_panel.offset_right = 380
	status_panel.offset_bottom = -16

	status_label = Label.new()
	status_panel.add_child(status_label)
	status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_label.offset_left = 12
	status_label.offset_top = 12
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
	for name in selected_buttons.keys():
		var button: Button = selected_buttons[name]
		button.queue_free()
	selected_buttons.clear()
	for placeable in build_manager.get_placeables():
		var button := Button.new()
		button.text = placeable.display_name
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_placeable_button_pressed.bind(placeable.id))
		button_box.add_child(button)
		selected_buttons[placeable.id] = button

func _on_placeable_button_pressed(placeable_id: String) -> void:
	build_manager.select_placeable(placeable_id)

func _on_selection_changed(placeable_id: String) -> void:
	for id in selected_buttons.keys():
		selected_buttons[id].modulate = Color(1, 1, 1, 1)
	if placeable_id != "" and selected_buttons.has(placeable_id):
		selected_buttons[placeable_id].modulate = Color(1.0, 0.94, 0.76, 1.0)

func _on_status_changed(text: String) -> void:
	status_label.text = "%s\n\nControls:\nWASD / Arrow Keys move camera\nMouse Wheel zoom\nLeft Click place" % text
