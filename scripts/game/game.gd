extends Node2D

const CELL_SIZE := 32
const CAMERA_PAN_SPEED := 260.0
const ZOOM_STEP := 0.1
const MIN_ZOOM := 0.8
const MAX_ZOOM := 1.6

var build_manager: BuildManager
var resident_manager: ResidentManager

@onready var ground_layer: Node2D = $TileMapGround
@onready var road_layer: Node2D = $TileMapRoad
@onready var building_layer: Node2D = $TileMapBuildings
@onready var decor_layer: Node2D = $TileMapDecor
@onready var residents_layer: Node2D = $Residents
@onready var placement_cursor: Node2D = $PlacementCursor
@onready var camera: Camera2D = $Camera2D

func setup(builds: BuildManager, residents: ResidentManager) -> void:
	build_manager = builds
	resident_manager = residents
	ground_layer.setup(build_manager)
	road_layer.setup(build_manager)
	building_layer.setup(build_manager)
	decor_layer.setup(build_manager)
	residents_layer.setup(resident_manager)
	placement_cursor.setup(build_manager)
	camera.position = Vector2(24 * CELL_SIZE, 24 * CELL_SIZE) * 0.5

func _process(delta: float) -> void:
	if build_manager == null:
		return
	var move := Vector2.ZERO
	if Input.is_key_pressed(Key.A) or Input.is_key_pressed(Key.LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(Key.D) or Input.is_key_pressed(Key.RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(Key.W) or Input.is_key_pressed(Key.UP):
		move.y -= 1.0
	if Input.is_key_pressed(Key.S) or Input.is_key_pressed(Key.DOWN):
		move.y += 1.0
	if move != Vector2.ZERO:
		camera.position += move.normalized() * CAMERA_PAN_SPEED * delta
	var cell := world_to_cell(get_local_mouse_position())
	placement_cursor.set_hover(cell)

func _unhandled_input(event: InputEvent) -> void:
	if build_manager == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == Key.ESCAPE:
		build_manager.cancel_build_mode()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.WHEEL_UP:
		_set_zoom(camera.zoom.x - ZOOM_STEP)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.WHEEL_DOWN:
		_set_zoom(camera.zoom.x + ZOOM_STEP)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.RIGHT:
		build_manager.cancel_build_mode()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MouseButton.LEFT:
		var cell := world_to_cell(get_local_mouse_position())
		if not build_manager.is_in_bounds(cell):
			return
		if resident_manager.select_resident_at(cell):
			build_manager.select_cell(cell)
			return
		if build_manager.selected_definition_id.is_empty() and not build_manager.remove_mode:
			build_manager.select_cell(cell)
			return
		if not build_manager.try_place(cell):
			build_manager.select_cell(cell)

func world_to_cell(local_position: Vector2) -> Vector2i:
	return Vector2i(floor(local_position.x / CELL_SIZE), floor(local_position.y / CELL_SIZE))

func _set_zoom(value: float) -> void:
	var clamped := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(clamped, clamped)
