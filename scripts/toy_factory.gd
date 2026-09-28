class_name ToyFactory
extends RefCounted

const SILHOUETTE := Color("#293044")
const INK := Color("#4a3550")
const CREAM := Color("#fff4dc")
const PINK := Color("#f7a9c4")
const BLUE := Color("#79cbe8")
const YELLOW := Color("#ffd66b")
const MINT := Color("#85d9b5")
const RED := Color("#ef6d68")
const ORANGE := Color("#f4a261")
const BROWN := Color("#a66b4f")


static func create_toy(toy_name: String, category: String, detail_level: int) -> Area3D:
	var toy := Area3D.new()
	toy.name = toy_name
	toy.collision_layer = 4
	toy.collision_mask = 0
	toy.set_meta("is_sortable_toy", true)
	toy.set_meta("toy_name", toy_name)
	toy.set_meta("category", category)
	toy.set_meta("home_position", Vector3.ZERO)

	var collision := CollisionShape3D.new()
	collision.name = "PickShape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.45, 1.45, 1.2)
	collision.shape = shape
	collision.position.y = 0.7
	toy.add_child(collision)

	var visual := Node3D.new()
	visual.name = "Visual"
	toy.add_child(visual)
	apply_detail(toy, detail_level)
	return toy


static func apply_detail(toy: Area3D, detail_level: int) -> void:
	var visual := toy.get_node("Visual") as Node3D
	for child in visual.get_children():
		child.free()
	var toy_name := String(toy.get_meta("toy_name"))
	match toy_name:
		"Cat": _build_cat(visual, detail_level)
		"Dog": _build_dog(visual, detail_level)
		"Cow": _build_cow(visual, detail_level)
		"Car": _build_car(visual, detail_level)
		"Bike": _build_bike(visual, detail_level)
		"Train": _build_train(visual, detail_level)


static func _color(detail: int, full_color: Color) -> Color:
	return SILHOUETTE if detail == 1 else full_color


static func _material(color: Color, emission_strength := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emission_strength > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength
	return material


static func _sphere(parent: Node3D, position: Vector3, scale: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(parent, mesh, position, scale, color)


static func _box(parent: Node3D, position: Vector3, scale: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	return _mesh(parent, mesh, position, scale, color, rotation)


static func _cylinder(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return _mesh(parent, mesh, position, Vector3.ONE, color, rotation)


static func _cone(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _mesh(parent, mesh, position, Vector3.ONE, color, rotation)


static func _torus(parent: Node3D, position: Vector3, color: Color, rotation := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.21
	mesh.outer_radius = 0.29
	mesh.rings = 16
	mesh.ring_segments = 8
	return _mesh(parent, mesh, position, scale, color, rotation)


static func _mesh(parent: Node3D, shape: PrimitiveMesh, position: Vector3, scale: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = position
	instance.scale = scale
	instance.rotation = rotation
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


static func _bar(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var direction := to - from
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 10
	var instance := _mesh(parent, mesh, from + direction * 0.5, Vector3.ONE, color)
	instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return instance


static func _eye(parent: Node3D, position: Vector3) -> void:
	_sphere(parent, position, Vector3(0.10, 0.14, 0.06), INK)
	_sphere(parent, position + Vector3(-0.018, 0.035, -0.025), Vector3(0.025, 0.035, 0.018), Color.WHITE)


static func _cheek(parent: Node3D, position: Vector3) -> void:
	_sphere(parent, position, Vector3(0.12, 0.065, 0.035), Color("#ff9eb5"))


static func _build_cat(v: Node3D, detail: int) -> void:
	var orange := _color(detail, ORANGE)
	var pale := _color(detail, CREAM)
	_sphere(v, Vector3(0, 0.62, 0), Vector3(0.82, 1.0, 0.68), orange)
	_sphere(v, Vector3(0, 1.28, -0.03), Vector3(0.88, 0.78, 0.72), orange)
	_cone(v, Vector3(-0.30, 1.72, 0), 0.23, 0.48, orange, Vector3(0, 0, -0.08))
	_cone(v, Vector3(0.30, 1.72, 0), 0.23, 0.48, orange, Vector3(0, 0, 0.08))
	_bar(v, Vector3(0.34, 0.62, 0.15), Vector3(0.70, 1.05, 0.15), 0.10, orange)
	_bar(v, Vector3(0.70, 1.05, 0.15), Vector3(0.58, 1.35, 0.15), 0.09, orange)
	if detail >= 2:
		_sphere(v, Vector3(0, 1.17, -0.35), Vector3(0.42, 0.30, 0.12), pale)
		_box(v, Vector3(0, 0.38, -0.38), Vector3(0.46, 0.34, 0.08), PINK)
	if detail == 3:
		_eye(v, Vector3(-0.22, 1.40, -0.37))
		_eye(v, Vector3(0.22, 1.40, -0.37))
		_sphere(v, Vector3(0, 1.19, -0.47), Vector3(0.08, 0.06, 0.045), PINK)
		_cheek(v, Vector3(-0.37, 1.17, -0.38))
		_cheek(v, Vector3(0.37, 1.17, -0.38))
		for x in [-0.25, 0.0, 0.25]:
			_box(v, Vector3(x, 0.72, -0.52), Vector3(0.06, 0.38, 0.04), BROWN, Vector3(0, 0, x * 0.8))


static func _build_dog(v: Node3D, detail: int) -> void:
	var tan := _color(detail, Color("#c98962"))
	var pale := _color(detail, CREAM)
	_sphere(v, Vector3(0, 0.60, 0), Vector3(0.88, 1.0, 0.72), tan)
	_sphere(v, Vector3(0, 1.30, -0.03), Vector3(0.92, 0.80, 0.76), tan)
	_sphere(v, Vector3(-0.48, 1.33, 0), Vector3(0.34, 0.68, 0.25), _color(detail, BROWN))
	_sphere(v, Vector3(0.48, 1.33, 0), Vector3(0.34, 0.68, 0.25), _color(detail, BROWN))
	_bar(v, Vector3(0.37, 0.66, 0.15), Vector3(0.68, 1.00, 0.12), 0.11, tan)
	if detail >= 2:
		_sphere(v, Vector3(0, 1.15, -0.42), Vector3(0.46, 0.34, 0.22), pale)
		_box(v, Vector3(0, 0.70, -0.49), Vector3(0.60, 0.14, 0.08), BLUE)
	if detail == 3:
		_eye(v, Vector3(-0.22, 1.43, -0.41))
		_eye(v, Vector3(0.22, 1.43, -0.41))
		_sphere(v, Vector3(0, 1.18, -0.56), Vector3(0.11, 0.08, 0.06), INK)
		_cheek(v, Vector3(-0.37, 1.17, -0.43))
		_cheek(v, Vector3(0.37, 1.17, -0.43))
		_sphere(v, Vector3(0, 1.02, -0.50), Vector3(0.10, 0.13, 0.05), PINK)


static func _build_cow(v: Node3D, detail: int) -> void:
	var white := _color(detail, CREAM)
	_sphere(v, Vector3(0, 0.67, 0), Vector3(1.02, 1.05, 0.78), white)
	_sphere(v, Vector3(0, 1.38, -0.04), Vector3(0.90, 0.76, 0.72), white)
	_sphere(v, Vector3(-0.46, 1.45, -0.02), Vector3(0.30, 0.22, 0.18), _color(detail, PINK))
	_sphere(v, Vector3(0.46, 1.45, -0.02), Vector3(0.30, 0.22, 0.18), _color(detail, PINK))
	_cone(v, Vector3(-0.28, 1.80, 0), 0.10, 0.32, _color(detail, YELLOW), Vector3(0, 0, -0.25))
	_cone(v, Vector3(0.28, 1.80, 0), 0.10, 0.32, _color(detail, YELLOW), Vector3(0, 0, 0.25))
	if detail >= 2:
		_sphere(v, Vector3(0, 1.18, -0.43), Vector3(0.50, 0.30, 0.20), PINK)
		_sphere(v, Vector3(-0.28, 0.82, -0.40), Vector3(0.28, 0.34, 0.10), INK)
		_sphere(v, Vector3(0.24, 0.48, -0.43), Vector3(0.22, 0.28, 0.10), INK)
	if detail == 3:
		_eye(v, Vector3(-0.22, 1.48, -0.40))
		_eye(v, Vector3(0.22, 1.48, -0.40))
		_sphere(v, Vector3(-0.14, 1.16, -0.56), Vector3(0.05, 0.06, 0.035), INK)
		_sphere(v, Vector3(0.14, 1.16, -0.56), Vector3(0.05, 0.06, 0.035), INK)
		_cheek(v, Vector3(-0.40, 1.22, -0.42))
		_cheek(v, Vector3(0.40, 1.22, -0.42))


static func _build_car(v: Node3D, detail: int) -> void:
	var body := _color(detail, RED)
	_box(v, Vector3(0, 0.58, 0), Vector3(1.55, 0.55, 0.86), body)
	_box(v, Vector3(-0.12, 1.00, 0), Vector3(0.82, 0.46, 0.76), _color(detail, YELLOW))
	for x in [-0.52, 0.52]:
		for z in [-0.45, 0.45]:
			_cylinder(v, Vector3(x, 0.36, z), 0.25, 0.16, SILHOUETTE, Vector3(deg_to_rad(90), 0, 0))
	if detail >= 2:
		_box(v, Vector3(-0.12, 1.04, -0.40), Vector3(0.58, 0.28, 0.04), BLUE)
		_sphere(v, Vector3(-0.51, 0.59, -0.46), Vector3(0.12, 0.12, 0.05), YELLOW)
		_sphere(v, Vector3(0.51, 0.59, -0.46), Vector3(0.12, 0.12, 0.05), YELLOW)
	if detail == 3:
		_eye(v, Vector3(-0.23, 0.78, -0.46))
		_eye(v, Vector3(0.23, 0.78, -0.46))
		_box(v, Vector3(0, 0.50, -0.47), Vector3(0.42, 0.06, 0.03), CREAM)
		_box(v, Vector3(0, 1.35, 0), Vector3(0.38, 0.08, 0.55), PINK)


static func _build_bike(v: Node3D, detail: int) -> void:
	var frame := _color(detail, PINK)
	_torus(v, Vector3(-0.52, 0.53, 0), SILHOUETTE, Vector3(deg_to_rad(90), 0, 0), Vector3(1.12, 1.12, 1.12))
	_torus(v, Vector3(0.52, 0.53, 0), SILHOUETTE, Vector3(deg_to_rad(90), 0, 0), Vector3(1.12, 1.12, 1.12))
	_bar(v, Vector3(-0.52, 0.53, 0), Vector3(0, 1.05, 0), 0.055, frame)
	_bar(v, Vector3(0, 1.05, 0), Vector3(0.52, 0.53, 0), 0.055, frame)
	_bar(v, Vector3(-0.52, 0.53, 0), Vector3(0.24, 0.53, 0), 0.055, frame)
	_bar(v, Vector3(0.24, 0.53, 0), Vector3(0, 1.05, 0), 0.055, frame)
	_bar(v, Vector3(0.52, 0.53, 0), Vector3(0.38, 1.20, 0), 0.045, frame)
	if detail >= 2:
		_box(v, Vector3(-0.03, 1.13, 0), Vector3(0.34, 0.10, 0.20), BLUE)
		_bar(v, Vector3(0.22, 1.20, 0), Vector3(0.58, 1.20, 0), 0.045, MINT)
		_sphere(v, Vector3(0.00, 0.54, -0.05), Vector3(0.16, 0.16, 0.08), YELLOW)
	if detail == 3:
		_box(v, Vector3(0.37, 1.42, 0), Vector3(0.42, 0.32, 0.32), YELLOW)
		_box(v, Vector3(0.37, 1.42, -0.17), Vector3(0.34, 0.24, 0.04), CREAM)
		_eye(v, Vector3(0.27, 1.47, -0.21))
		_eye(v, Vector3(0.47, 1.47, -0.21))


static func _build_train(v: Node3D, detail: int) -> void:
	var blue := _color(detail, BLUE)
	_box(v, Vector3(0.26, 0.70, 0), Vector3(1.12, 0.52, 0.78), blue)
	_cylinder(v, Vector3(-0.43, 0.78, 0), 0.38, 0.88, _color(detail, RED), Vector3(0, 0, deg_to_rad(90)))
	_box(v, Vector3(0.36, 1.18, 0), Vector3(0.52, 0.62, 0.70), _color(detail, YELLOW))
	_cylinder(v, Vector3(-0.52, 1.31, 0), 0.12, 0.48, _color(detail, INK))
	for x in [-0.48, 0.12, 0.50]:
		for z in [-0.43, 0.43]:
			_cylinder(v, Vector3(x, 0.39, z), 0.22, 0.14, SILHOUETTE, Vector3(deg_to_rad(90), 0, 0))
	if detail >= 2:
		_box(v, Vector3(0.36, 1.24, -0.38), Vector3(0.30, 0.30, 0.04), MINT)
		_sphere(v, Vector3(-0.78, 0.79, -0.12), Vector3(0.14, 0.14, 0.10), YELLOW)
	if detail == 3:
		_eye(v, Vector3(-0.61, 0.90, -0.36))
		_eye(v, Vector3(-0.35, 0.90, -0.36))
		_box(v, Vector3(-0.48, 0.66, -0.41), Vector3(0.36, 0.06, 0.03), CREAM)
		_cone(v, Vector3(-0.52, 1.64, 0), 0.22, 0.18, PINK)
