extends Node3D

const GROUND_Y := 0.0
const CAMERA_MOVE_SPEED := 16.0
const MIN_CAMERA_DISTANCE := 14.0
const MAX_CAMERA_DISTANCE := 34.0
const ZOOM_STEP := 1.6

@onready var ground_tiles: Node3D = $GroundTiles
@onready var placed_objects: Node3D = $PlacedObjects
@onready var hover_indicator: MeshInstance3D = $HoverIndicator
@onready var preview: PlaceablePreview = $Preview
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D

var build_manager: BuildManager
var game_manager: GameManager
var hover_cell := Vector2i(-1, -1)
var camera_distance := 22.0
var ground_plane: Plane = Plane(Vector3.UP, GROUND_Y)

func setup(manager: BuildManager, game: GameManager) -> void:
	build_manager = manager
	game_manager = game
	if not build_manager.placements_changed.is_connected(_rebuild_placed_objects):
		build_manager.placements_changed.connect(_rebuild_placed_objects)
	if not build_manager.selection_changed.is_connected(_on_selection_changed):
		build_manager.selection_changed.connect(_on_selection_changed)
	preview.setup(BuildManager.CELL_SIZE)
	_build_ground()
	_setup_hover_indicator()
	_update_camera_transform()
	_rebuild_placed_objects()

func _process(delta: float) -> void:
	if build_manager == null:
		return
	_handle_camera_move(delta)
	_update_hover_from_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if build_manager == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_hovered()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(MIN_CAMERA_DISTANCE, camera_distance - ZOOM_STEP)
			_update_camera_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(MAX_CAMERA_DISTANCE, camera_distance + ZOOM_STEP)
			_update_camera_transform()

func _build_ground() -> void:
	for child in ground_tiles.get_children():
		child.queue_free()
	var light_material := _make_material(Color(0.82, 0.91, 0.78, 1.0))
	var dark_material := _make_material(Color(0.78, 0.87, 0.74, 1.0))
	for x in range(BuildManager.GRID_WIDTH):
		for z in range(BuildManager.GRID_DEPTH):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(BuildManager.CELL_SIZE * 0.98, 0.1, BuildManager.CELL_SIZE * 0.98)
			tile.mesh = mesh
			tile.position = build_manager.cell_to_world(Vector2i(x, z)) + Vector3(0.0, -0.05, 0.0)
			tile.material_override = light_material if (x + z) % 2 == 0 else dark_material
			ground_tiles.add_child(tile)

func _setup_hover_indicator() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(BuildManager.CELL_SIZE * 0.98, 0.06, BuildManager.CELL_SIZE * 0.98)
	hover_indicator.mesh = mesh
	hover_indicator.material_override = _make_material(Color(1.0, 0.95, 0.55, 0.45), true)
	hover_indicator.visible = false

func _rebuild_placed_objects() -> void:
	for child in placed_objects.get_children():
		child.queue_free()
	for item in build_manager.get_placements():
		var data: PlaceableData = item["data"]
		var cell: Vector2i = item["cell"]
		var node := PlaceablePreview.create_visual(data, BuildManager.CELL_SIZE)
		PlaceablePreview.apply_color(node, data.active_color if item["active"] else data.inactive_color, false)
		node.position = build_manager.cell_to_world(cell)
		placed_objects.add_child(node)
	_refresh_preview()

func _update_hover_from_mouse() -> void:
	var hit: Variant = _mouse_hit_on_ground()
	if hit == null:
		hover_cell = Vector2i(-1, -1)
		hover_indicator.visible = false
		preview.hide_preview()
		return
	var cell: Vector2i = build_manager.world_to_cell(hit)
	if not build_manager.is_inside(cell):
		hover_cell = Vector2i(-1, -1)
		hover_indicator.visible = false
		preview.hide_preview()
		return
	hover_cell = cell
	hover_indicator.visible = true
	hover_indicator.position = build_manager.cell_to_world(cell) + Vector3(0.0, 0.03, 0.0)
	_refresh_preview()

func _refresh_preview() -> void:
	if hover_cell.x < 0 or not build_manager.is_inside(hover_cell):
		preview.hide_preview()
		return
	var selected: PlaceableData = build_manager.get_selected_data()
	if selected == null:
		preview.hide_preview()
		return
	preview.show_preview(
		selected,
		build_manager.cell_to_world(hover_cell),
		build_manager.can_place(hover_cell),
		build_manager.would_be_active(hover_cell, selected)
	)

func _try_place_hovered() -> void:
	if hover_cell.x < 0:
		return
	if not build_manager.place_selected(hover_cell):
		_refresh_preview()

func _handle_camera_move(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.z += 1.0
	if move == Vector3.ZERO:
		return
	camera_rig.position += move.normalized() * CAMERA_MOVE_SPEED * delta
	var half_extent := build_manager.board_half_extent() - Vector2(BuildManager.CELL_SIZE * 1.5, BuildManager.CELL_SIZE * 1.5)
	camera_rig.position.x = clampf(camera_rig.position.x, -half_extent.x, half_extent.x)
	camera_rig.position.z = clampf(camera_rig.position.z, -half_extent.y, half_extent.y)

func _update_camera_transform() -> void:
	camera.position = Vector3(0.0, camera_distance * 0.82, camera_distance)
	camera.rotation_degrees = Vector3(-42.0, 0.0, 0.0)

func _mouse_hit_on_ground() -> Variant:
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_position)
	var ray_direction := camera.project_ray_normal(mouse_position)
	return ground_plane.intersects_ray(ray_origin, ray_direction)

func _make_material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _on_selection_changed(_placeable_id: String) -> void:
	_refresh_preview()
