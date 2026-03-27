class_name ResidentManager
extends Node

signal residents_changed(residents: Array)
signal resident_selected(resident: Dictionary)

var build_manager: BuildManager
var game_manager: GameManager

var templates: Array[ResidentProfile] = []
var residents: Array[Dictionary] = []
var selected_resident_id := ""
var _sequence := 0

func setup(builds: BuildManager, game: GameManager) -> void:
	build_manager = builds
	game_manager = game
	templates = GameDatabase.load_residents()

func reset_new_game() -> void:
	residents.clear()
	selected_resident_id = ""
	_sequence = 0
	residents_changed.emit(get_residents())

func refresh_from_build() -> void:
	_sync_homes()
	residents_changed.emit(get_residents())

func update_daily() -> void:
	_sync_homes()
	_update_happiness_and_requests()
	residents_changed.emit(get_residents())

func _sync_homes() -> void:
	var active_homes := build_manager.get_active_house_cells()
	var resident_by_home := {}
	for resident in residents:
		resident_by_home[resident["home_key"]] = resident

	var next_residents: Array[Dictionary] = []
	for cell in active_homes:
		var key := _cell_key(cell)
		if resident_by_home.has(key):
			next_residents.append(resident_by_home[key])
		elif next_residents.size() < 8:
			next_residents.append(_create_resident_for_home(cell))
		if next_residents.size() >= 8:
			break
	residents = next_residents

func _create_resident_for_home(cell: Vector2i) -> Dictionary:
	var profile := templates[_sequence % templates.size()]
	_sequence += 1
	var resident := {
		"id": "%s_%d" % [profile.id, _sequence],
		"name": profile.display_name,
		"species": profile.species,
		"personality": profile.personality,
		"preferred_tag": profile.preferred_tag,
		"favorite_line": profile.favorite_line,
		"happiness": 58,
		"current_line": "This cottage feels promising.",
		"request": "",
		"request_done": false,
		"home": cell,
		"home_key": _cell_key(cell)
	}
	game_manager.push_notification("%s the %s wants to move in." % [resident["name"], resident["species"]])
	return resident

func _update_happiness_and_requests() -> void:
	for resident in residents:
		var home: Vector2i = resident["home"]
		var preferred_tag := String(resident["preferred_tag"])
		var nearby_preference := build_manager.has_tag_near(home, preferred_tag, 2)
		var nearby_plaza := build_manager.has_tag_near(home, "plaza", 3)
		var nearby_road := build_manager.has_tag_near(home, "road", 1)
		var happiness := int(resident["happiness"])
		happiness += (2 if nearby_preference else -3)
		happiness += (1 if nearby_plaza else 0)
		happiness += (1 if nearby_road else -1)
		happiness = clamp(happiness, 20, 100)
		resident["happiness"] = happiness
		if not nearby_preference:
			resident["request"] = _request_text(preferred_tag)
			resident["request_done"] = false
			resident["current_line"] = resident["request"]
		else:
			if not bool(resident["request_done"]):
				game_manager.push_notification("%s looks happier after the new decoration." % resident["name"])
			resident["request_done"] = true
			resident["current_line"] = resident["favorite_line"]

func _request_text(tag: String) -> String:
	match tag:
		"flowers":
			return "Could we plant a few flowers nearby?"
		"trees":
			return "A quiet tree-lined corner would be lovely."
		"bench":
			return "I want a bench close to home."
		"cafe":
			return "A cafe nearby would make mornings better."
		"lamp":
			return "A street lamp would make this lane cozy at night."
		_:
			return "I hope this area gets a little cozier."

func get_residents() -> Array[Dictionary]:
	return residents.duplicate(true)

func get_average_happiness() -> int:
	if residents.is_empty():
		return 50
	var total := 0
	for resident in residents:
		total += int(resident["happiness"])
	return int(round(float(total) / residents.size()))

func get_resident_at(cell: Vector2i) -> Dictionary:
	for resident in residents:
		if resident["home"] == cell:
			return resident.duplicate(true)
	return {}

func select_resident_at(cell: Vector2i) -> bool:
	var resident := get_resident_at(cell)
	if resident.is_empty():
		return false
	selected_resident_id = resident["id"]
	residents_changed.emit(get_residents())
	resident_selected.emit(resident)
	return true

func export_state() -> Dictionary:
	var export_residents: Array[Dictionary] = []
	for resident in residents:
		export_residents.append({
			"id": resident["id"],
			"name": resident["name"],
			"species": resident["species"],
			"personality": resident["personality"],
			"preferred_tag": resident["preferred_tag"],
			"favorite_line": resident["favorite_line"],
			"happiness": resident["happiness"],
			"current_line": resident["current_line"],
			"request": resident["request"],
			"request_done": resident["request_done"],
			"home_x": resident["home"].x,
			"home_y": resident["home"].y
		})
	return {
		"residents": export_residents,
		"selected_resident_id": selected_resident_id,
		"sequence": _sequence
	}

func import_state(data: Dictionary) -> void:
	residents.clear()
	for raw_resident in data.get("residents", []):
		var item: Dictionary = raw_resident
		var home := Vector2i(int(item.get("home_x", 0)), int(item.get("home_y", 0)))
		residents.append({
			"id": String(item.get("id", "")),
			"name": item.get("name", ""),
			"species": item.get("species", ""),
			"personality": item.get("personality", ""),
			"preferred_tag": item.get("preferred_tag", ""),
			"favorite_line": item.get("favorite_line", ""),
			"happiness": int(item.get("happiness", 55)),
			"current_line": item.get("current_line", ""),
			"request": item.get("request", ""),
			"request_done": bool(item.get("request_done", false)),
			"home": home,
			"home_key": _cell_key(home)
		})
	selected_resident_id = String(data.get("selected_resident_id", ""))
	_sequence = int(data.get("sequence", residents.size()))
	residents_changed.emit(get_residents())

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
