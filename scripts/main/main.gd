extends Node

@onready var world_3d: Node3D = $World3D
@onready var ui_root: Control = $CanvasLayer/UIRoot
@onready var game_manager: GameManager = $Managers/GameManager
@onready var build_manager: BuildManager = $Managers/BuildManager
@onready var resident_manager: ResidentManager = $Managers/ResidentManager

func _ready() -> void:
	game_manager.setup()
	build_manager.setup(game_manager)
	game_manager.attach_build_manager(build_manager)
	resident_manager.setup(build_manager, game_manager)
	world_3d.setup(build_manager, game_manager)
	ui_root.setup(build_manager, game_manager, resident_manager)
