class_name BuildManager
extends Node

signal map_changed
signal selection_changed(info: Dictionary)
signal build_mode_changed(definition_id: String, remove_mode: bool)

const MAP_SIZE := Vector2i(24, 24)
const NEIGHBORS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var economy_manager: EconomyManager
var game_manager: GameManager

var definitions: Dictionary = {}
var definitions_by_category: Dictionary = {}
var selected_definition_id := ""
var remove_mode := false

var roads: Dictionary = {}
var buildings: Dictionary = {}
var decor: Dictionary = {}

func setup(economy: EconomyManager, game: GameManager) -> void:
	economy_manager = economy
	game_manager = game
	_load_definitions()
	reset_new_game()

func reset_new_game() -> void:
	roads.clear()
	buildings.clear()
	decor.clear()
	selected_definition_id = ""
	remove_mode = false
	map_changed.emit()
	select_cell(Vector2i(12, 12))
	build_mode_changed.emit(selected_definition_id, remove_mode)

func _load_definitions() -> void:
	definitions.clear()
	definitions_by_category.clear()
	for data in GameDatabase.load_placeables():
		definitions[data.id] = data
		if not definitions_by_category.has(data.category):
			definitions_by_category[data.category] = []
		definitions_by_category[data.category].append(data)

func get_categories() -> Array[String]:
	return ["road", "housing", "commercial", "public", "decor", "remove"]

func get_definitions_for_category(category: String) -> Array:
	if category == "remove":
		return []
	return definitions_by_category.get(category, [])

func set_build_mode(definition_id: String, is_remove := false) -> void:
	selected_definition_id = definition_id
	remove_mode = is_remove
	build_mode_changed.emit(selected_definition_id, remove_mode)

func cancel_build_mode() -> void:
	selected_definition_id = ""
	remove_mode = false
	build_mode_changed.emit(selected_definition_id, remove_mode)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < MAP_SIZE.x and cell.y < MAP_SIZE.y

func can_place(cell: Vector2i, definition_id := selected_definition_id) -> bool:
	if not is_in_bounds(cell):
		return false
	if definition_id.is_empty():
		return false
	var data: PlaceableData = definitions.get(definition_id)
	if data == null:
		return false
	match data.layer:
		"road":
			return not roads.has(cell) and not buildings.has(cell) and not decor.has(cell)
		"buildings":
			return not buildings.has(cell) and not roads.has(cell) and not decor.has(cell)
		"decor":
			return not decor.has(cell) and not buildings.has(cell) and not roads.has(cell)
		_:
			return false

func try_place(cell: Vector2i) -> bool:
	if remove_mode:
		return remove_at(cell)
	if not can_place(cell):
		return false
	var data: PlaceableData = definitions[selected_definition_id]
	if not economy_manager.spend(data.cost):
		game_manager.push_notification("Not enough funds for %s." % data.display_name)
		return false
	match data.layer:
		"road":
			roads[cell] = {"id": data.id}
		"buildings":
			buildings[cell] = {"id": data.id, "active": false}
		"decor":
			decor[cell] = {"id": data.id}
	recalculate_activation()
	map_changed.emit()
	select_cell(cell)
	game_manager.push_notification("%s placed." % data.display_name)
	return true

func remove_at(cell: Vector2i) -> bool:
	var removed_name := ""
	if decor.has(cell):
		removed_name = get_definition(decor[cell]["id"]).display_name
		decor.erase(cell)
	elif buildings.has(cell):
		removed_name = get_definition(buildings[cell]["id"]).display_name
		buildings.erase(cell)
	elif roads.has(cell):
		removed_name = "Road"
		roads.erase(cell)
	else:
		return false
	recalculate_activation()
	map_changed.emit()
	select_cell(cell)
	game_manager.push_notification("%s removed." % removed_name)
	return true

func recalculate_activation() -> void:
	for cell in buildings.keys():
		var active := false
		for offset in NEIGHBORS:
			if roads.has(cell + offset):
				active = true
				break
		buildings[cell]["active"] = active

func get_definition(definition_id: String) -> PlaceableData:
	return definitions.get(definition_id)

func get_layer_cells(layer_name: String) -> Dictionary:
	match layer_name:
		"ground":
			return {}
		"road":
			return roads
		"buildings":
			return buildings
		"decor":
			return decor
		_:
			return {}

func get_cell_payload(cell: Vector2i) -> Dictionary:
	if buildings.has(cell):
		var building: Dictionary = buildings[cell]
		var data: PlaceableData = get_definition(building["id"])
		return {
			"type": "building",
			"id": data.id,
			"name": data.display_name,
			"description": data.description,
			"effects": data.effect_text,
			"active": building.get("active", false),
			"tags": data.tags
		}
	if decor.has(cell):
		var decor_data: PlaceableData = get_definition(decor[cell]["id"])
		return {
			"type": "decor",
			"id": decor_data.id,
			"name": decor_data.display_name,
			"description": decor_data.description,
			"effects": decor_data.effect_text,
			"active": true,
			"tags": decor_data.tags
		}
	if roads.has(cell):
		var road_data: PlaceableData = get_definition("road")
		return {
			"type": "road",
			"id": road_data.id,
			"name": road_data.display_name,
			"description": road_data.description,
			"effects": road_data.effect_text,
			"active": true,
			"tags": road_data.tags
		}
	return {
		"type": "ground",
		"name": "Meadow Tile",
		"description": "A quiet patch of grass waiting for a village touch.",
		"effects": "No direct effect",
		"active": false,
		"tags": PackedStringArray()
	}

func select_cell(cell: Vector2i) -> void:
	if not is_in_bounds(cell):
		return
	var payload := get_cell_payload(cell)
	payload["cell"] = cell
	selection_changed.emit(payload)

func has_tag_near(cell: Vector2i, tag: String, radius := 2) -> bool:
	for x in range(cell.x - radius, cell.x + radius + 1):
		for y in range(cell.y - radius, cell.y + radius + 1):
			var candidate := Vector2i(x, y)
			if not is_in_bounds(candidate):
				continue
			var payload := get_cell_payload(candidate)
			if payload.has("tags") and tag in payload["tags"]:
				return true
	return false

func get_active_house_cells() -> Array[Vector2i]:
	var homes: Array[Vector2i] = []
	for cell in buildings.keys():
		var entry: Dictionary = buildings[cell]
		var data: PlaceableData = get_definition(entry["id"])
		if data.id == "house" and entry.get("active", false):
			homes.append(cell)
	return homes

func get_daily_income_total() -> int:
	var total := 0
	for cell in buildings.keys():
		var entry: Dictionary = buildings[cell]
		if not entry.get("active", false):
			continue
		var data: PlaceableData = get_definition(entry["id"])
		total += data.daily_income
	return total

func get_base_scores() -> Dictionary:
	var scores := {
		"coziness": 0,
		"nature": 0,
		"convenience": 0,
		"atmosphere": 0
	}
	for source in [roads, buildings, decor]:
		for cell in source.keys():
			var data: PlaceableData = get_definition(source[cell]["id"])
			scores["coziness"] += data.score_coziness
			scores["nature"] += data.score_nature
			scores["convenience"] += data.score_convenience
			scores["atmosphere"] += data.score_vibe
	return scores

func export_state() -> Dictionary:
	return {
		"roads": _serialize_layer(roads),
		"buildings": _serialize_layer(buildings),
		"decor": _serialize_layer(decor),
		"selected_definition_id": selected_definition_id,
		"remove_mode": remove_mode
	}

func import_state(data: Dictionary) -> void:
	roads = _deserialize_layer(data.get("roads", []))
	buildings = _deserialize_layer(data.get("buildings", []))
	decor = _deserialize_layer(data.get("decor", []))
	selected_definition_id = String(data.get("selected_definition_id", ""))
	remove_mode = bool(data.get("remove_mode", false))
	recalculate_activation()
	map_changed.emit()
	build_mode_changed.emit(selected_definition_id, remove_mode)
	select_cell(Vector2i(12, 12))

func _serialize_layer(layer: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for cell in layer.keys():
		var entry: Dictionary = layer[cell]
		output.append({
			"x": cell.x,
			"y": cell.y,
			"id": entry["id"],
			"active": entry.get("active", true)
		})
	return output

func _deserialize_layer(items: Array) -> Dictionary:
	var output := {}
	for raw_item in items:
		var item: Dictionary = raw_item
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		output[cell] = {
			"id": String(item.get("id", "")),
			"active": bool(item.get("active", true))
		}
	return output
