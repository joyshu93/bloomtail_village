class_name PlaceableData
extends Resource

@export var id := ""
@export var display_name := ""
@export var category := ""
@export var layer := "buildings"
@export var cost := 0
@export_multiline var description := ""
@export var effect_text := ""
@export var requires_road := false
@export var daily_income := 0
@export var resident_capacity := 0
@export var color := Color.WHITE
@export var tags: PackedStringArray = []
@export var score_coziness := 0
@export var score_nature := 0
@export var score_convenience := 0
@export var score_vibe := 0

@export var mesh_kind := "box"
@export var mesh_scale := Vector3.ONE
@export var active_color := Color.WHITE
@export var inactive_color := Color(0.45, 0.45, 0.45, 1.0)
@export var preview_color := Color(0.35, 0.85, 1.0, 0.45)
@export var blocked_color := Color(1.0, 0.35, 0.35, 0.4)
