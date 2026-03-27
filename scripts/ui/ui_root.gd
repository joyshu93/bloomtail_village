extends Control

var build_manager: BuildManager
var game_manager: GameManager
var resident_manager: ResidentManager

var top_panel: PanelContainer
var top_stats_label: Label
var button_panel: PanelContainer
var button_box: VBoxContainer
var resident_panel: PanelContainer
var resident_box: VBoxContainer
var status_panel: PanelContainer
var status_title: Label
var status_label: Label
var selection_title: Label
var selection_detail: Label
var selected_buttons := {}
var is_ready := false
var signals_connected := false

func setup(manager: BuildManager, game: GameManager, residents: ResidentManager = null) -> void:
	build_manager = manager
	game_manager = game
	resident_manager = residents
	if is_node_ready():
		_finish_setup()

func _ready() -> void:
	_build_layout()
	is_ready = true
	if build_manager != null:
		_finish_setup()

func _build_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	top_panel = PanelContainer.new()
	add_child(top_panel)
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 16
	top_panel.offset_top = 16
	top_panel.offset_right = -16
	top_panel.offset_bottom = 72

	top_stats_label = Label.new()
	top_panel.add_child(top_stats_label)
	top_stats_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_stats_label.offset_left = 14
	top_stats_label.offset_top = 12
	top_stats_label.offset_right = -14
	top_stats_label.offset_bottom = -12
	top_stats_label.text = "Funds: 0   Day: 1   Village: 0   Cafe Income: 0/day"

	button_panel = PanelContainer.new()
	add_child(button_panel)
	button_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	button_panel.offset_left = 16
	button_panel.offset_top = 88
	button_panel.offset_right = 274
	button_panel.offset_bottom = 430

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

	resident_panel = PanelContainer.new()
	add_child(resident_panel)
	resident_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	resident_panel.offset_left = -320
	resident_panel.offset_top = 88
	resident_panel.offset_right = -16
	resident_panel.offset_bottom = 410

	resident_box = VBoxContainer.new()
	resident_box.add_theme_constant_override("separation", 8)
	resident_panel.add_child(resident_box)
	resident_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resident_box.offset_left = 12
	resident_box.offset_top = 12
	resident_box.offset_right = -12
	resident_box.offset_bottom = -12

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
		game_manager.stats_changed.connect(_on_stats_changed)
		if resident_manager != null:
			resident_manager.residents_changed.connect(_on_residents_changed)
		signals_connected = true
	_rebuild_placeable_buttons()
	_on_selection_changed(build_manager.selected_id)
	_on_status_changed(game_manager.status_text)
	_on_stats_changed(game_manager.money, game_manager.day, game_manager.population, game_manager.daily_income)
	_on_residents_changed([] if resident_manager == null else resident_manager.get_residents())

func _rebuild_placeable_buttons() -> void:
	for id in selected_buttons.keys():
		var existing: Button = selected_buttons[id]
		existing.queue_free()
	selected_buttons.clear()
	for placeable in build_manager.get_placeables():
		var button := Button.new()
		button.text = "%s  [%s]  %d c" % [placeable.display_name, placeable.category.capitalize(), placeable.cost]
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
	var income_text: String = "" if selected.daily_income <= 0 else "Income +%d/day" % selected.daily_income
	var population_text: String = "" if selected.resident_capacity <= 0 else "Village +%d" % selected.resident_capacity
	var extra_bits: PackedStringArray = PackedStringArray([road_text])
	if income_text != "":
		extra_bits.append(income_text)
	if population_text != "":
		extra_bits.append(population_text)
	selection_detail.text = "%s\nCost: %d\n%s" % [selected.description, selected.cost, ", ".join(extra_bits)]

func _on_status_changed(text: String) -> void:
	status_label.text = "%s\n\nControls:\nWASD / Arrow Keys move camera\nMouse Wheel zoom\nLeft Click place\nRoad: drag to paint" % text

func _on_stats_changed(money: int, day: int, population: int, daily_income: int) -> void:
	top_stats_label.text = "Funds: %d   Day: %d   Village: %d   Cafe Income: %d/day" % [money, day, population, daily_income]

func _on_residents_changed(residents: Array[Dictionary]) -> void:
	for child in resident_box.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "Residents"
	title.add_theme_font_size_override("font_size", 20)
	resident_box.add_child(title)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Active houses invite villagers in. Their reactions change with roads, trees, and cafes."
	resident_box.add_child(hint)
	if residents.is_empty():
		var empty := Label.new()
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.text = "No residents yet. Activate a house to welcome someone."
		resident_box.add_child(empty)
		return
	for resident in residents:
		var card := PanelContainer.new()
		resident_box.add_child(card)
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 4)
		card.add_child(card_box)
		var name := Label.new()
		name.text = "%s the %s" % [resident["name"], resident["species"]]
		name.add_theme_font_size_override("font_size", 16)
		card_box.add_child(name)
		var state := Label.new()
		state.text = "%s | prefers %s" % [String(resident["state"]).capitalize(), String(resident["preferred_tag"])]
		card_box.add_child(state)
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.text = resident["reaction"]
		card_box.add_child(line)
