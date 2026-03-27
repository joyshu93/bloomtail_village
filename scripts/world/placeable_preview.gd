class_name PlaceablePreview
extends Node3D

var cell_size := 2.0
var current_id := ""
var current_visual: Node3D

func setup(size: float) -> void:
	cell_size = size
	visible = false

func show_preview(data: PlaceableData, world_position: Vector3, can_place: bool, would_be_active: bool) -> void:
	if data == null:
		hide_preview()
		return
	if current_visual == null or current_id != data.id:
		_clear_visual()
		current_id = data.id
		current_visual = create_visual(data, cell_size)
		add_child(current_visual)
	position = world_position
	visible = true
	apply_state(current_visual, data, can_place, would_be_active, true)

func hide_preview() -> void:
	visible = false

static func create_visual(data: PlaceableData, size: float) -> Node3D:
	var root := Node3D.new()
	match data.mesh_kind:
		"road":
			_add_box(root, Vector3(size * 0.94, 0.08, size * 0.94), Vector3(0.0, 0.04, 0.0))
			_add_box(root, Vector3(size * 0.14, 0.085, size * 0.55), Vector3(0.0, 0.05, 0.0))
		"house":
			_add_box(root, Vector3(size * 0.78, 1.5, size * 0.78), Vector3(0.0, 0.75, 0.0))
			_add_box(root, Vector3(size * 0.96, 0.18, size * 0.96), Vector3(0.0, 1.58, 0.0))
			_add_box(root, Vector3(size * 0.2, 0.72, size * 0.16), Vector3(0.0, 0.36, size * 0.31))
			_add_box(root, Vector3(size * 0.14, 0.45, size * 0.14), Vector3(size * 0.24, 1.96, -size * 0.12))
		"cafe":
			_add_box(root, Vector3(size * 0.9, 1.2, size * 0.9), Vector3(0.0, 0.6, 0.0))
			_add_box(root, Vector3(size * 0.98, 0.12, size * 0.42), Vector3(0.0, 1.15, size * 0.16))
			_add_cylinder(root, size * 0.1, 0.85, Vector3(-size * 0.22, 0.42, size * 0.32))
			_add_cylinder(root, size * 0.1, 0.85, Vector3(size * 0.22, 0.42, size * 0.32))
			_add_cylinder(root, size * 0.12, 0.9, Vector3(size * 0.22, 1.65, -size * 0.22))
			_add_sphere(root, size * 0.1, Vector3(size * 0.22, 2.05, -size * 0.22))
		"tree":
			_add_cylinder(root, size * 0.12, 1.0, Vector3(0.0, 0.5, 0.0))
			_add_sphere(root, size * 0.28, Vector3(0.0, 1.2, 0.0))
			_add_sphere(root, size * 0.22, Vector3(-size * 0.16, 1.42, 0.0))
			_add_sphere(root, size * 0.22, Vector3(size * 0.16, 1.42, 0.0))
			_add_sphere(root, size * 0.18, Vector3(0.0, 1.66, size * 0.12))
		_:
			_add_box(root, Vector3(size * 0.8, 0.8, size * 0.8), Vector3(0.0, 0.4, 0.0))
	return root

static func apply_color(root: Node3D, color: Color, transparent: bool) -> void:
	_apply_material(root, color, transparent)

static func apply_state(root: Node3D, data: PlaceableData, can_place: bool, is_active: bool, transparent: bool) -> void:
	var target_color := data.active_color
	if transparent:
		target_color = data.preview_color
	if not can_place:
		target_color = data.blocked_color
	elif data.requires_road and not is_active:
		target_color = data.inactive_color
		if transparent:
			target_color.a = 0.45
	_apply_material(root, target_color, transparent)
	_update_state_marker(root, can_place, is_active, transparent)

static func _apply_material(root: Node, color: Color, transparent: bool) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var material := StandardMaterial3D.new()
			material.albedo_color = color
			material.emission_enabled = true
			material.emission = color * 0.25
			material.roughness = 0.92
			if transparent:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			child.material_override = material
		if child.get_child_count() > 0:
			_apply_material(child, color, transparent)

func _clear_visual() -> void:
	for child in get_children():
		child.queue_free()

static func _update_state_marker(root: Node3D, can_place: bool, is_active: bool, transparent: bool) -> void:
	var marker_name := "__StateMarker"
	var marker_root := root.get_node_or_null(marker_name) as Node3D
	if can_place and is_active:
		if marker_root != null:
			marker_root.queue_free()
		return
	if marker_root == null:
		marker_root = Node3D.new()
		marker_root.name = marker_name
		root.add_child(marker_root)
		_add_box(marker_root, Vector3(0.26, 1.2, 0.26), Vector3(0.0, 2.0, 0.0))
		_add_box(marker_root, Vector3(0.26, 0.26, 0.26), Vector3(0.0, 1.2, 0.0))
	var marker_color := Color(1.0, 0.28, 0.28, 0.9)
	if can_place and not is_active:
		marker_color = Color(1.0, 0.77, 0.34, 0.9)
	_apply_material(marker_root, marker_color, transparent)

static func _add_box(parent: Node3D, mesh_size: Vector3, mesh_position: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = mesh_size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = mesh_position
	parent.add_child(node)

static func _add_cylinder(parent: Node3D, radius: float, height: float, mesh_position: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = mesh_position
	parent.add_child(node)

static func _add_sphere(parent: Node3D, radius: float, mesh_position: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = mesh_position
	parent.add_child(node)
