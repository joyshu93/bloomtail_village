extends Node

@onready var game: Node2D = $Game
@onready var ui_root: Control = $CanvasLayer/UIRoot
@onready var game_manager: GameManager = $Managers/GameManager
@onready var build_manager: BuildManager = $Managers/BuildManager
@onready var economy_manager: EconomyManager = $Managers/EconomyManager
@onready var resident_manager: ResidentManager = $Managers/ResidentManager
@onready var town_score_manager: TownScoreManager = $Managers/TownScoreManager
@onready var save_manager: SaveManager = $Managers/SaveManager

func _ready() -> void:
	build_manager.setup(economy_manager, game_manager)
	resident_manager.setup(build_manager, game_manager)
	save_manager.setup(build_manager, economy_manager, resident_manager, town_score_manager, game_manager)
	game.setup(build_manager, resident_manager)
	ui_root.setup(build_manager, economy_manager, resident_manager, town_score_manager, save_manager, game_manager)

	game_manager.day_passed.connect(_on_day_passed)
	build_manager.map_changed.connect(_on_build_map_changed)
	economy_manager.reset_new_game()
	resident_manager.reset_new_game()
	town_score_manager.recalculate(build_manager, resident_manager)
	game_manager.start_new_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == Key.SPACE:
		game_manager.toggle_pause()

func _on_day_passed(_day: int) -> void:
	economy_manager.add_income(build_manager.get_daily_income_total())
	resident_manager.update_daily()
	town_score_manager.recalculate(build_manager, resident_manager)

func _on_build_map_changed() -> void:
	resident_manager.refresh_from_build()
	town_score_manager.recalculate(build_manager, resident_manager)
