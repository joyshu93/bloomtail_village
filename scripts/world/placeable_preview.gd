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
	var target_color := data.preview_color
	if not can_place:
		target_color = data.blocked_color
	elif data.requires_road and not would_be_active:
		target_color = data.inactive_color
		target_color.a = 0.45
	_apply_material(current_visual, target_color, true)

func hide_preview() -> void:
	visible = false

static func create_visual(data: PlaceableData, size: float) -> Node3D:
	var root := Node3D.new()
	match data.mesh_kind:
		"road":
			_add_box(root, Vector3(size * 0.92, 0.12, size * 0.92), Vector3(0.0, 0.06, 0.0))
		"house":
			_add_box(root, Vector3(size * 0.78, 1.5, size * 0.78), Vector3(0.0, 0.75, 0.0))
			_add_box(root, Vector3(size * 0.92, 0.18, size * 0.92), Vector3(0.0, 1.58, 0.0))
		"cafe":
			_add_box(root, Vector3(size * 0.9, 1.2, size * 0.9), Vector3(0.0, 0.6, 0.0))
			_add_cylinder(root, size * 0.12, 0.9, Vector3(size * 0.22, 1.65, -size * 0.22))
		"tree":
			_add_cylinder(root, size * 0.12, 1.0, Vector3(0.0, 0.5, 0.0))
			_add_sphere(root, size * 0.34, Vector3(0.0, 1.35, 0.0))
		_:
			_add_box(root, Vector3(size * 0.8, 0.8, size * 0.8), Vector3(0.0, 0.4, 0.0))
	return root

static func apply_color(root: Node3D, color: Color, transparent: bool) -> void:
	_apply_material(root, color, transparent)

static func _apply_material(root: Node, color: Color, transparent: bool) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var material := StandardMaterial3D.new()
			material.albedo_color = color
			if transparent:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			child.material_override = material
		if child.get_child_count() > 0:
			_apply_material(child, color, transparent)

func _clear_visual() -> void:
	for child in get_children():
		child.queue_free()

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
