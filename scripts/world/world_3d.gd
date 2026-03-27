extends Node3D

const GROUND_Y := 0.0
const CAMERA_MOVE_SPEED := 16.0
const MIN_CAMERA_DISTANCE := 14.0
const MAX_CAMERA_DISTANCE := 34.0
const ZOOM_STEP := 1.6
const HOVER_VALID_COLOR := Color(0.45, 0.98, 0.68, 0.58)
const HOVER_BLOCKED_COLOR := Color(1.0, 0.42, 0.42, 0.72)
const HOVER_INACTIVE_COLOR := Color(1.0, 0.78, 0.38, 0.64)
const HOVER_RING_COLOR := Color(1.0, 1.0, 1.0, 0.7)

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
var hover_ring: MeshInstance3D
var is_dragging_road := false
var drag_placed_cells: Dictionary = {}
var last_hover_summary := ""
var last_drag_cell := Vector2i(-1, -1)

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
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_update_hover_from_mouse()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_begin_or_place()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = maxf(MIN_CAMERA_DISTANCE, camera_distance - ZOOM_STEP)
			_update_camera_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = minf(MAX_CAMERA_DISTANCE, camera_distance + ZOOM_STEP)
			_update_camera_transform()
	elif event is InputEventMouseMotion and is_dragging_road:
		_drag_place_road()

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
	mesh.size = Vector3(BuildManager.CELL_SIZE * 0.98, 0.18, BuildManager.CELL_SIZE * 0.98)
	hover_indicator.mesh = mesh
	hover_indicator.material_override = _make_material(HOVER_VALID_COLOR, true)
	hover_indicator.visible = false
	if hover_ring == null:
		hover_ring = MeshInstance3D.new()
		var ring_mesh := CylinderMesh.new()
		ring_mesh.top_radius = BuildManager.CELL_SIZE * 0.5
		ring_mesh.bottom_radius = BuildManager.CELL_SIZE * 0.5
		ring_mesh.height = 0.04
		hover_ring.mesh = ring_mesh
		hover_ring.material_override = _make_material(HOVER_RING_COLOR, true)
		add_child(hover_ring)
	hover_ring.visible = false

func _rebuild_placed_objects() -> void:
	for child in placed_objects.get_children():
		child.queue_free()
	for item in build_manager.get_placements():
		var data: PlaceableData = item["data"]
		var cell: Vector2i = item["cell"]
		var node := PlaceablePreview.create_visual(data, BuildManager.CELL_SIZE)
		PlaceablePreview.apply_state(node, data, true, bool(item["active"]), false)
		node.position = build_manager.cell_to_world(cell)
		placed_objects.add_child(node)
	_refresh_preview()

func _update_hover_from_mouse() -> void:
	var hit: Variant = _mouse_hit_on_ground()
	if hit == null:
		hover_cell = Vector2i(-1, -1)
		hover_indicator.visible = false
		hover_ring.visible = false
		preview.hide_preview()
		last_hover_summary = ""
		return
	var cell: Vector2i = build_manager.world_to_cell(hit)
	if not build_manager.is_inside(cell):
		hover_cell = Vector2i(-1, -1)
		hover_indicator.visible = false
		hover_ring.visible = false
		preview.hide_preview()
		last_hover_summary = ""
		return
	hover_cell = cell
	hover_indicator.visible = true
	hover_indicator.position = build_manager.cell_to_world(cell) + Vector3(0.0, 0.09, 0.0)
	hover_ring.visible = true
	hover_ring.position = build_manager.cell_to_world(cell) + Vector3(0.0, 0.02, 0.0)
	_update_hover_indicator_visuals()
	_update_hover_status()
	if is_dragging_road:
		_drag_place_road()
	_refresh_preview()

func _refresh_preview() -> void:
	if hover_cell.x < 0 or not build_manager.is_inside(hover_cell):
		preview.hide_preview()
		return
	var selected: PlaceableData = build_manager.get_selected_data()
	if selected == null:
		preview.hide_preview()
		return
	var can_place := build_manager.can_place(hover_cell)
	var would_be_active := build_manager.would_be_active(hover_cell, selected)
	preview.show_preview(
		selected,
		build_manager.cell_to_world(hover_cell),
		can_place,
		would_be_active
	)

func _try_place_hovered() -> void:
	if hover_cell.x < 0:
		return
	if not build_manager.place_selected(hover_cell):
		_refresh_preview()
	else:
		_update_hover_indicator_visuals()

func _begin_or_place() -> void:
	if _is_pointer_over_ui():
		return
	if hover_cell.x < 0:
		return
	if build_manager.selected_id == "road":
		is_dragging_road = true
		drag_placed_cells.clear()
		last_drag_cell = hover_cell
		_drag_place_road()
		return
	_try_place_hovered()

func _drag_place_road() -> void:
	if hover_cell.x < 0 or not build_manager.is_inside(hover_cell):
		return
	if last_drag_cell.x < 0:
		last_drag_cell = hover_cell
	for cell in _cells_between(last_drag_cell, hover_cell):
		var key := "%d,%d" % [cell.x, cell.y]
		if drag_placed_cells.has(key):
			continue
		if build_manager.place("road", cell, true):
			drag_placed_cells[key] = true
			game_manager.set_status("Laying road... release left mouse to stop.")
			last_hover_summary = ""
	last_drag_cell = hover_cell

func _end_drag() -> void:
	if not is_dragging_road:
		return
	is_dragging_road = false
	var placed_count := drag_placed_cells.size()
	if placed_count > 0:
		game_manager.set_status("Road drag placed %d tile%s." % [placed_count, "" if placed_count == 1 else "s"])
	elif build_manager.selected_id == "road":
		game_manager.set_status("Road selected. Drag across the ground or click a single cell to place.")
	drag_placed_cells.clear()
	last_hover_summary = ""
	last_drag_cell = Vector2i(-1, -1)

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
	material.emission_enabled = true
	material.emission = color * 0.35
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _on_selection_changed(_placeable_id: String) -> void:
	_update_hover_indicator_visuals()
	last_hover_summary = ""
	_refresh_preview()

func _update_hover_indicator_visuals() -> void:
	if hover_cell.x < 0 or not build_manager.is_inside(hover_cell):
		return
	var selected: PlaceableData = build_manager.get_selected_data()
	if selected == null:
		hover_indicator.material_override = _make_material(HOVER_BLOCKED_COLOR, true)
		return
	var can_place := build_manager.can_place(hover_cell)
	var would_be_active := build_manager.would_be_active(hover_cell, selected)
	var color := HOVER_VALID_COLOR
	var hover_height := 0.18
	var ring_scale := 1.0
	if not can_place:
		color = HOVER_BLOCKED_COLOR
		hover_height = 0.22
		ring_scale = 1.08
	elif selected.requires_road and not would_be_active:
		color = HOVER_INACTIVE_COLOR
		hover_height = 0.2
		ring_scale = 1.04
	var mesh := hover_indicator.mesh as BoxMesh
	if mesh != null:
		mesh.size = Vector3(BuildManager.CELL_SIZE * 0.98, hover_height, BuildManager.CELL_SIZE * 0.98)
	hover_indicator.material_override = _make_material(color, true)
	hover_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
	hover_ring.material_override = _make_material(color.lightened(0.2), true)

func _update_hover_status() -> void:
	if is_dragging_road:
		return
	var message := build_manager.get_hover_message(hover_cell)
	if message == last_hover_summary:
		return
	last_hover_summary = message
	game_manager.set_status(message)

func _is_pointer_over_ui() -> bool:
	return get_viewport().gui_get_hovered_control() != null

func _cells_between(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var current := start
	cells.append(current)
	while current != finish:
		var delta := finish - current
		if abs(delta.x) >= abs(delta.y) and delta.x != 0:
			current.x += 1 if delta.x > 0 else -1
		elif delta.y != 0:
			current.y += 1 if delta.y > 0 else -1
		cells.append(current)
	return cells
