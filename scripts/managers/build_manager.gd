class_name BuildManager
extends Node

signal selection_changed(placeable_id: String)
signal placements_changed

const GRID_WIDTH := 24
const GRID_DEPTH := 24
const CELL_SIZE := 2.0
const REMOVE_TOOL_ID := "remove"

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
	selected_id = ""
	select_placeable("road")

func get_placeables() -> Array[PlaceableData]:
	return ordered_placeables

func get_placeable(placeable_id: String) -> PlaceableData:
	return placeables.get(placeable_id) as PlaceableData

func get_selected_data() -> PlaceableData:
	return placeables.get(selected_id) as PlaceableData

func get_selected_name() -> String:
	if is_remove_selected():
		return "Remove"
	var selected := get_selected_data()
	return "" if selected == null else selected.display_name

func is_road_selected() -> bool:
	return selected_id == "road"

func is_remove_selected() -> bool:
	return selected_id == REMOVE_TOOL_ID

func get_selected_cost() -> int:
	var selected := get_selected_data()
	return 0 if selected == null else selected.cost

func get_place_cost(placeable_id: String) -> int:
	var data: PlaceableData = get_placeable(placeable_id)
	return 0 if data == null else data.cost

func select_placeable(placeable_id: String) -> void:
	if placeable_id != REMOVE_TOOL_ID and not placeables.has(placeable_id):
		return
	selected_id = placeable_id
	selection_changed.emit(selected_id)
	if is_remove_selected():
		game_manager.set_status("Remove selected. Click a placed object to clear it.")
	elif is_road_selected():
		game_manager.set_status("Road selected. Cost %d. Left click and drag across the grid to lay roads quickly." % get_selected_cost())
	else:
		game_manager.set_status("%s selected. Cost %d. Move the mouse over the grid and left click to place." % [get_selected_name(), get_selected_cost()])

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_DEPTH

func is_occupied(cell: Vector2i) -> bool:
	return placements.has(_cell_key(cell))

func can_place(cell: Vector2i) -> bool:
	return is_inside(cell) and not is_occupied(cell)

func can_place_id(placeable_id: String, cell: Vector2i) -> bool:
	return placeables.has(placeable_id) and can_place(cell) and can_afford_placeable(placeable_id)

func can_afford_placeable(placeable_id: String) -> bool:
	if placeable_id == REMOVE_TOOL_ID:
		return true
	var data: PlaceableData = get_placeable(placeable_id)
	return data != null and game_manager.can_afford(data.cost)

func can_place_selected_at(cell: Vector2i) -> bool:
	if is_remove_selected():
		return has_entry(cell)
	return can_place_id(selected_id, cell)

func has_entry(cell: Vector2i) -> bool:
	return placements.has(_cell_key(cell))

func get_entry(cell: Vector2i) -> Dictionary:
	var key := _cell_key(cell)
	return placements.get(key, {})

func get_data_at(cell: Vector2i) -> PlaceableData:
	if not has_entry(cell):
		return null
	var entry: Dictionary = placements[_cell_key(cell)]
	return placeables.get(String(entry.get("id", ""))) as PlaceableData

func is_active_at(cell: Vector2i) -> bool:
	if not has_entry(cell):
		return false
	var entry: Dictionary = placements[_cell_key(cell)]
	return bool(entry.get("active", true))

func has_road_neighbor(cell: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_key := _cell_key(cell + offset)
		if placements.has(neighbor_key) and placements[neighbor_key]["id"] == "road":
			return true
	return false

func would_be_active(cell: Vector2i, data: PlaceableData = null) -> bool:
	var current_data := data if data != null else get_selected_data()
	if current_data == null or not current_data.requires_road:
		return true
	return has_road_neighbor(cell)

func get_hover_message(cell: Vector2i, placeable_id: String = selected_id) -> String:
	if placeable_id == REMOVE_TOOL_ID:
		if not is_inside(cell):
			return "Outside the buildable area."
		if has_entry(cell):
			var remove_data: PlaceableData = get_data_at(cell)
			return "Remove %s at %d, %d." % [remove_data.display_name, cell.x + 1, cell.y + 1]
		return "Nothing to remove at %d, %d." % [cell.x + 1, cell.y + 1]
	if not placeables.has(placeable_id):
		return "Select a placeable from the build menu."
	var data: PlaceableData = placeables[placeable_id]
	if not is_inside(cell):
		return "Outside the buildable area."
	if is_occupied(cell):
		return "Cell %d, %d is occupied." % [cell.x + 1, cell.y + 1]
	if not game_manager.can_afford(data.cost):
		return "Not enough money for %s. Need %d coins." % [data.display_name, data.cost]
	if data.requires_road and not would_be_active(cell, data):
		return "%s can be placed here, but it will stay inactive until a road touches it." % data.display_name
	return "Ready to place %s at %d, %d for %d coins." % [data.display_name, cell.x + 1, cell.y + 1, data.cost]

func place_selected(cell: Vector2i) -> bool:
	if is_remove_selected():
		return remove_at(cell)
	return place(selected_id, cell)

func place(placeable_id: String, cell: Vector2i, silent: bool = false) -> bool:
	if not placeables.has(placeable_id):
		return false
	if not can_place(cell):
		if not silent:
			game_manager.set_status("That cell is already occupied or outside the buildable area.")
		return false
	var data: PlaceableData = placeables.get(placeable_id)
	if not game_manager.spend_money(data.cost):
		if not silent:
			game_manager.set_status("Not enough money for %s. Need %d coins, have %d." % [data.display_name, data.cost, game_manager.money])
		return false
	var active_after_place := would_be_active(cell, data)
	placements[_cell_key(cell)] = {
		"id": data.id,
		"active": active_after_place
	}
	_recalculate_activation()
	placements_changed.emit()
	if not silent:
		if data.requires_road and not active_after_place:
			game_manager.set_status("%s placed at %d, %d for %d coins, but it is inactive until a road touches it." % [data.display_name, cell.x + 1, cell.y + 1, data.cost])
		else:
			game_manager.set_status("%s placed at %d, %d for %d coins." % [data.display_name, cell.x + 1, cell.y + 1, data.cost])
	return true

func place_many(placeable_id: String, cells: Array[Vector2i], silent: bool = false) -> int:
	if placeable_id == REMOVE_TOOL_ID:
		return remove_many(cells, silent)
	if not placeables.has(placeable_id):
		return 0
	var placed_count := 0
	var stopped_for_funds := false
	for cell in cells:
		if not can_place(cell):
			continue
		var data: PlaceableData = placeables.get(placeable_id)
		if not game_manager.spend_money(data.cost):
			stopped_for_funds = true
			break
		placements[_cell_key(cell)] = {
			"id": data.id,
			"active": would_be_active(cell, data)
		}
		placed_count += 1
	if placed_count <= 0:
		if not silent:
			if stopped_for_funds:
				var place_cost := get_place_cost(placeable_id)
				game_manager.set_status("Not enough money to place %s. Need %d coins, have %d." % [get_selected_name(), place_cost, game_manager.money])
			else:
				game_manager.set_status("That area is already occupied or outside the buildable area.")
		return 0
	_recalculate_activation()
	placements_changed.emit()
	if not silent:
		var plural := "" if placed_count == 1 else "s"
		var total_spent := placed_count * get_place_cost(placeable_id)
		if stopped_for_funds:
			game_manager.set_status("%s placed on %d tile%s for %d coins before funds ran out." % [get_selected_name(), placed_count, plural, total_spent])
		else:
			game_manager.set_status("%s placed on %d tile%s for %d coins." % [get_selected_name(), placed_count, plural, total_spent])
	return placed_count

func remove_at(cell: Vector2i, silent: bool = false) -> bool:
	if not has_entry(cell):
		if not silent:
			game_manager.set_status("There is nothing to remove there.")
		return false
	var removed_data: PlaceableData = get_data_at(cell)
	placements.erase(_cell_key(cell))
	_recalculate_activation()
	placements_changed.emit()
	if not silent and removed_data != null:
		game_manager.set_status("%s removed from %d, %d." % [removed_data.display_name, cell.x + 1, cell.y + 1])
	return true

func remove_many(cells: Array[Vector2i], silent: bool = false) -> int:
	var removed_count := 0
	for cell in cells:
		if not has_entry(cell):
			continue
		placements.erase(_cell_key(cell))
		removed_count += 1
	if removed_count <= 0:
		if not silent:
			game_manager.set_status("There is nothing to remove there.")
		return 0
	_recalculate_activation()
	placements_changed.emit()
	if not silent:
		var plural := "" if removed_count == 1 else "s"
		game_manager.set_status("Removed %d placed object%s." % [removed_count, plural])
	return removed_count

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

func get_active_house_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for item in get_placements():
		var data: PlaceableData = item["data"]
		if data == null or data.id != "house" or not bool(item["active"]):
			continue
		cells.append(item["cell"])
	for i in range(cells.size()):
		for j in range(i + 1, cells.size()):
			var left: Vector2i = cells[i]
			var right: Vector2i = cells[j]
			if right.x < left.x or (right.x == left.x and right.y < left.y):
				cells[i] = right
				cells[j] = left
	return cells

func count_tag_near(origin: Vector2i, tag: String, radius: int, active_only: bool) -> int:
	var total := 0
	for item in get_placements():
		var data: PlaceableData = item["data"]
		if data == null or not data.tags.has(tag):
			continue
		if active_only and not bool(item["active"]):
			continue
		var cell: Vector2i = item["cell"]
		if abs(cell.x - origin.x) <= radius and abs(cell.y - origin.y) <= radius:
			total += 1
	return total

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
