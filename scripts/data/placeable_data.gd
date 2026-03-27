class_name PlaceableData
extends Resource

@export var id := ""
@export var display_name := ""
@export var category := ""
@export var layer := "decor"
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
