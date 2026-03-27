class_name SaveManager
extends Node

signal save_completed
signal load_completed(success: bool)

const SAVE_PATH := "user://cozy_village_save.json"

var build_manager: BuildManager
var economy_manager: EconomyManager
var resident_manager: ResidentManager
var town_score_manager: TownScoreManager
var game_manager: GameManager

func setup(builds: BuildManager, economy: EconomyManager, residents: ResidentManager, town_score: TownScoreManager, game: GameManager) -> void:
	build_manager = builds
	economy_manager = economy
	resident_manager = residents
	town_score_manager = town_score
	game_manager = game

func save_game() -> void:
	var payload := {
		"game": game_manager.export_state(),
		"economy": economy_manager.export_state(),
		"build": build_manager.export_state(),
		"residents": resident_manager.export_state(),
		"town_score": town_score_manager.export_state()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		game_manager.push_notification("The save file could not be written.")
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		load_completed.emit(false)
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		load_completed.emit(false)
		return false
	var parsed := JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		load_completed.emit(false)
		return false
	var data: Dictionary = parsed
	build_manager.import_state(data.get("build", {}))
	economy_manager.import_state(data.get("economy", {}))
	resident_manager.import_state(data.get("residents", {}))
	town_score_manager.import_state(data.get("town_score", {}))
	game_manager.import_state(data.get("game", {}))
	load_completed.emit(true)
	return true
