extends Node2D

const CELL_SIZE := 32

var build_manager: BuildManager
var hover_cell := Vector2i(-1, -1)

func setup(manager: BuildManager) -> void:
	build_manager = manager

func set_hover(cell: Vector2i) -> void:
	if hover_cell == cell:
		return
	hover_cell = cell
	queue_redraw()

func _draw() -> void:
	if build_manager == null or not build_manager.is_in_bounds(hover_cell):
		return
	var rect := Rect2(Vector2(hover_cell.x, hover_cell.y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE)).grow(-1)
	var color := Color(1, 1, 1, 0.35)
	if build_manager.remove_mode:
		color = Color(0.92, 0.3, 0.3, 0.35)
	elif not build_manager.selected_definition_id.is_empty():
		color = Color(0.3, 0.8, 1.0, 0.35) if build_manager.can_place(hover_cell) else Color(0.95, 0.25, 0.25, 0.35)
	draw_rect(rect, color, true)
	draw_rect(rect, color.darkened(0.5), false, 2.0)
