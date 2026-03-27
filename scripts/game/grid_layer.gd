extends Node2D

@export var layer_name := "ground"

const CELL_SIZE := 32
const MAP_SIZE := Vector2i(24, 24)

var build_manager: BuildManager

func setup(manager: BuildManager) -> void:
	build_manager = manager
	if not build_manager.map_changed.is_connected(queue_redraw):
		build_manager.map_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if layer_name == "ground":
		_draw_ground()
		return
	if build_manager == null:
		return
	var cells: Dictionary = build_manager.get_layer_cells(layer_name)
	for cell in cells.keys():
		var entry: Dictionary = cells[cell]
		var data: PlaceableData = build_manager.get_definition(entry["id"])
		if data == null:
			continue
		var rect := Rect2(Vector2(cell.x, cell.y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
		var color := data.color
		if layer_name == "buildings" and not entry.get("active", false):
			color = color.darkened(0.4)
		draw_rect(rect.grow(-3), color, true)
		draw_rect(rect.grow(-3), color.darkened(0.35), false, 2.0)

func _draw_ground() -> void:
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			var rect := Rect2(Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			draw_rect(rect, Color("97c47d"), true)
			draw_rect(rect, Color("7eaa66"), false, 1.0)
