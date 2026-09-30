#############################################
# Joystick locomotion. Left stick to move, right stick to rotate.
# Uses a CharacterBody3D so movement respects collision.
#############################################

extends Node3D
class_name XRMovement

## Kill switch. Turn it off for cutscenes, menus, whatever
@export var enabled := true

## Stick action from the action map. "primary" is the thumbstick.
@export var stick_action := "primary"

@export_group("Nodes")
@export_node_path("XRCamera3D") var camera: NodePath
@export_node_path("XRController3D") var move_controller: NodePath
@export_node_path("XRController3D") var turn_controller: NodePath

@export_group("Parameters")
@export var move_speed := 2.0 ## m/s
@export_range(0.0, 0.9) var deadzone := 0.2 ## for stick drift
@export var gravity := 9.8
@export var turn_speed := 90.0 ## degrees per second

var _origin: XROrigin3D = null
var _body: CharacterBody3D = null
var _camera: XRCamera3D = null
var _move_controller: XRController3D = null
var _turn_controller: XRController3D = null


func _ready() -> void:
	_origin = get_parent() as XROrigin3D
	if _origin == null:
		push_error("XRMovement|FATAL: this node must be a child of an XROrigin3D")
		set_physics_process(false)
		return

	_body = _origin.get_parent() as CharacterBody3D
	if _body == null:
		push_error("XRMovement|FATAL: XROrigin3D's parent must be a CharacterBody3D")
		set_physics_process(false)
		return

	_camera = get_node_or_null(camera) as XRCamera3D
	_move_controller = get_node_or_null(move_controller) as XRController3D
	_turn_controller = get_node_or_null(turn_controller) as XRController3D

	if _camera == null:
		push_error("XRMovement|FATAL: Camera NodePath is not set or invalid")
	if _move_controller == null:
		push_error("XRMovement|FATAL: Move Controller NodePath is not set or invalid")
	if _turn_controller == null:
		push_error("XRMovement|FATAL: Turn Controller NodePath is not set or invalid")


func _physics_process(delta: float) -> void:
	if not enabled:
		return

	_apply_gravity(delta)
	_slide(delta)
	_smooth_turn(delta)
	_body.move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not _body.is_on_floor():
		_body.velocity.y -= gravity * delta
	else:
		_body.velocity.y = 0.0


func _slide(_delta: float) -> void:
	if _move_controller == null or _camera == null:
		return

	var stick := _move_controller.get_vector2(stick_action)
	if stick.length() < deadzone:
		_body.velocity.x = 0.0
		_body.velocity.z = 0.0
		return

	var basis := _camera.global_transform.basis
	var forward := -basis.z
	var right := basis.x
	forward.y = 0.0
	right.y = 0.0

	var direction := (right.normalized() * stick.x + forward.normalized() * stick.y).limit_length(1.0)
	_body.velocity.x = direction.x * move_speed
	_body.velocity.z = direction.z * move_speed


func _smooth_turn(delta: float) -> void:
	if _turn_controller == null or _camera == null:
		return

	var stick := _turn_controller.get_vector2(stick_action)
	if absf(stick.x) < deadzone:
		return

	var angle := deg_to_rad(turn_speed) * delta * -stick.x

	var pivot := _camera.global_position
	pivot.y = _origin.global_position.y

	var t := _origin.global_transform
	t = t.translated(-pivot)
	t = Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) * t
	t = t.translated(pivot)
	_origin.global_transform = t
