class_name BuildManager
extends Node

signal selection_changed(placeable_id: String)
signal placements_changed

const GRID_WIDTH := 24
const GRID_DEPTH := 24
const CELL_SIZE := 2.0

const PLACEABLE_PATHS := [
	"res://resources/vertical_slice/road.tres",
	"res://resources/vertical_slice/house.tres",
	"res://resources/vertical_slice/cafe.tres",
	"res://resources/vertical_slice/tree.tres"
]

var game_manager: GameManager
var placeables: Dictionary = {}
var ordered_placeables: Array[PlaceableData] = []
var selected_id := ""
var placements: Dictionary = {}

func setup(manager: GameManager) -> void:
	game_manager = manager
	_load_placeables()
	placements.clear()
	select_placeable("road")

func get_placeables() -> Array[PlaceableData]:
	return ordered_placeables

func get_placeable(placeable_id: String) -> PlaceableData:
	return placeables.get(placeable_id) as PlaceableData

func get_selected_data() -> PlaceableData:
	return placeables.get(selected_id) as PlaceableData

func select_placeable(placeable_id: String) -> void:
	if not placeables.has(placeable_id):
		return
	selected_id = placeable_id
	selection_changed.emit(selected_id)
	game_manager.set_status("%s selected. Move the mouse over the grid and left click to place." % get_selected_data().display_name)

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_DEPTH

func is_occupied(cell: Vector2i) -> bool:
	return placements.has(_cell_key(cell))

func can_place(cell: Vector2i) -> bool:
	return is_inside(cell) and not is_occupied(cell)

func would_be_active(cell: Vector2i, data: PlaceableData = null) -> bool:
	var current_data := data if data != null else get_selected_data()
	if current_data == null or not current_data.requires_road:
		return true
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_key := _cell_key(cell + offset)
		if placements.has(neighbor_key) and placements[neighbor_key]["id"] == "road":
			return true
	return false

func place_selected(cell: Vector2i) -> bool:
	if not can_place(cell):
		game_manager.set_status("That cell is already occupied or outside the buildable area.")
		return false
	var data: PlaceableData = get_selected_data()
	if data == null:
		return false
	var active_after_place := would_be_active(cell, data)
	placements[_cell_key(cell)] = {
		"id": data.id,
		"active": active_after_place
	}
	_recalculate_activation()
	placements_changed.emit()
	if data.requires_road and not active_after_place:
		game_manager.set_status("%s placed at %d, %d, but it is inactive until a road touches it." % [data.display_name, cell.x + 1, cell.y + 1])
	else:
		game_manager.set_status("%s placed at %d, %d." % [data.display_name, cell.x + 1, cell.y + 1])
	return true

func get_placements() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for key in placements.keys():
		var cell: Vector2i = _key_to_cell(String(key))
		var entry: Dictionary = placements[key]
		items.append({
			"cell": cell,
			"data": placeables.get(String(entry["id"])),
			"active": bool(entry.get("active", true))
		})
	return items

func world_to_cell(world_position: Vector3) -> Vector2i:
	var origin := _origin_offset()
	var local_x := world_position.x - origin.x
	var local_z := world_position.z - origin.z
	return Vector2i(floor(local_x / CELL_SIZE), floor(local_z / CELL_SIZE))

func cell_to_world(cell: Vector2i) -> Vector3:
	var origin := _origin_offset()
	return origin + Vector3((cell.x + 0.5) * CELL_SIZE, 0.0, (cell.y + 0.5) * CELL_SIZE)

func board_half_extent() -> Vector2:
	return Vector2(GRID_WIDTH * CELL_SIZE, GRID_DEPTH * CELL_SIZE) * 0.5

func _load_placeables() -> void:
	placeables.clear()
	ordered_placeables.clear()
	for path in PLACEABLE_PATHS:
		var resource: Resource = load(path)
		if resource is PlaceableData:
			var data: PlaceableData = resource
			placeables[data.id] = data
			ordered_placeables.append(data)

func _recalculate_activation() -> void:
	for key in placements.keys():
		var entry: Dictionary = placements[key]
		var data: PlaceableData = placeables.get(String(entry["id"]))
		if data == null:
			continue
		entry["active"] = would_be_active(_key_to_cell(String(key)), data)
		placements[key] = entry

func _origin_offset() -> Vector3:
	return Vector3(-GRID_WIDTH * CELL_SIZE * 0.5, 0.0, -GRID_DEPTH * CELL_SIZE * 0.5)

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _key_to_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
