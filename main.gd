extends Node3D

var xr_interface: OpenXRInterface
var desktop_mode := false
var desktop_pitch := 0.0

## Preferred refresh rate. Will fallback to what the headset reports
@export var target_refresh_rate := 72.0
@export var desktop_move_speed := 4.5
@export var desktop_look_sensitivity := 0.0025

@onready var desktop_rig: Node3D = $DesktopCameraRig
@onready var desktop_camera: Camera3D = $DesktopCameraRig/DesktopCamera3D

func _ready() -> void:
	# Standalone Quest builds use OpenXR. Editor and desktop builds use a
	# regular camera so the project is easy to preview without a headset.
	if OS.get_name() != "Android":
		_start_desktop_preview()
		return

	_start_xr()


func _start_xr() -> void:
	desktop_camera.current = false

	xr_interface = XRServer.find_interface("OpenXR") as OpenXRInterface
	if xr_interface == null:
		push_warning("Main|WARN: OpenXR unavailable; using desktop preview")
		_start_desktop_preview()
		return

	if not xr_interface.is_initialized() and not xr_interface.initialize():
		push_warning("Main|WARN: OpenXR failed to initialise; using desktop preview")
		_start_desktop_preview()
		return

	print("Main|INFO: OpenXR initialised successfully")

	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	get_viewport().use_xr = true
	xr_interface.session_begun.connect(_on_session_begun)


func _start_desktop_preview() -> void:
	desktop_mode = true
	desktop_pitch = desktop_camera.rotation.x
	get_viewport().use_xr = false
	desktop_camera.current = true
	$PlayerBody.process_mode = Node.PROCESS_MODE_DISABLED
	$PlayerBody.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_add_desktop_help()
	print("Main|INFO: desktop preview enabled")


func _on_session_begun() -> void:
	var rates := xr_interface.get_available_display_refresh_rates()
	if target_refresh_rate in rates:
		xr_interface.display_refresh_rate = target_refresh_rate
	elif not rates.is_empty():
		print("Main|WARN: %s Hz unavailable, runtime offers %s" % [target_refresh_rate, rates])

	var actual: float = xr_interface.display_refresh_rate
	if actual > 0.0:
		Engine.physics_ticks_per_second = int(round(actual))
	print("Main|INFO: running at %s Hz" % Engine.physics_ticks_per_second)


func _process(delta: float) -> void:
	if not desktop_mode:
		return

	var input_x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) \
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var input_z := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) \
		- float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	var input_y := float(Input.is_key_pressed(KEY_SPACE)) \
		- float(Input.is_key_pressed(KEY_SHIFT))

	var forward := -desktop_rig.global_transform.basis.z
	var right := desktop_rig.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	var direction := right.normalized() * input_x + forward.normalized() * input_z
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	direction.y = input_y
	desktop_rig.global_position += direction * desktop_move_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if not desktop_mode:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		desktop_rig.rotation.y -= event.relative.x * desktop_look_sensitivity
		desktop_pitch = clampf(
			desktop_pitch - event.relative.y * desktop_look_sensitivity,
			deg_to_rad(-85.0),
			deg_to_rad(85.0)
		)
		desktop_camera.rotation.x = desktop_pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _add_desktop_help() -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = "WASD / ARROWS  Move    MOUSE  Look    SPACE / SHIFT  Up / Down    ESC  Release mouse"
	label.position = Vector2(18, 16)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
