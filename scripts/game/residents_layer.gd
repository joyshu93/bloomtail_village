extends Node2D

const CELL_SIZE := 32

var resident_manager: ResidentManager

func setup(manager: ResidentManager) -> void:
	resident_manager = manager
	if not resident_manager.residents_changed.is_connected(_on_residents_changed):
		resident_manager.residents_changed.connect(_on_residents_changed)
	queue_redraw()

func _on_residents_changed(_residents: Array) -> void:
	queue_redraw()

func _draw() -> void:
	if resident_manager == null:
		return
	for resident in resident_manager.get_residents():
		var home: Vector2i = resident["home"]
		var center := Vector2(home.x * CELL_SIZE + CELL_SIZE * 0.5, home.y * CELL_SIZE + CELL_SIZE * 0.5)
		var color := _personality_color(resident["personality"])
		draw_circle(center, 8.0, color)
		if resident["id"] == resident_manager.selected_resident_id:
			draw_arc(center, 12.0, 0.0, TAU, 16, Color.WHITE, 2.0)

func _personality_color(personality: String) -> Color:
	match personality:
		"Bubbly":
			return Color("ff9f7a")
		"Calm":
			return Color("8ed1b1")
		"Bookish":
			return Color("91a6ff")
		"Crafty":
			return Color("f0c36a")
		_:
			return Color.WHITE
