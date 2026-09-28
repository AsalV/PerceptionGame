extends Node3D

const ToyFactoryScript := preload("res://scripts/toy_factory.gd")

const ANIMAL := "Animals"
const TRANSPORT := "Transportation"
const TOYS := [
	{"name": "Cat", "category": ANIMAL, "cue": "Meow!"},
	{"name": "Dog", "category": ANIMAL, "cue": "Woof!"},
	{"name": "Cow", "category": ANIMAL, "cue": "Moo!"},
	{"name": "Car", "category": TRANSPORT, "cue": "Beep beep!"},
	{"name": "Bike", "category": TRANSPORT, "cue": "Ring ring!"},
	{"name": "Train", "category": TRANSPORT, "cue": "Choo choo!"},
]
const TOY_POSITIONS := [
	Vector3(-3.8, -0.13, 1.4), Vector3(-2.25, -0.11, 0.5),
	Vector3(-0.75, -0.155, 1.3), Vector3(0.85, -0.12, 0.45),
	Vector3(2.35, -0.215, 1.35), Vector3(3.85, -0.18, 0.45),
]

@export_node_path("Camera3D") var desktop_camera_path: NodePath

var camera: Camera3D
var current_level := 1
var sorted_count := 0
var selected_toy: Area3D
var toys: Array[Area3D] = []
var bins: Dictionary = {}
var game_finished := false

var level_label: Label
var objective_label: Label
var score_label: Label
var feedback_panel: PanelContainer
var feedback_label: Label
var reticle: Label
var fade_rect: ColorRect
var audio_player: AudioStreamPlayer

var palette := {
	"cream": Color("#fff5df"),
	"pink": Color("#f7b2cd"),
	"rose": Color("#ee7899"),
	"blue": Color("#7ecce8"),
	"sky": Color("#95dcf3"),
	"yellow": Color("#ffd874"),
	"mint": Color("#8ddab9"),
	"lavender": Color("#bba8e8"),
	"wood": Color("#d99a65"),
	"wood_light": Color("#efbd82"),
	"ink": Color("#513a55"),
}


func _ready() -> void:
	camera = get_node(desktop_camera_path) as Camera3D
	if camera == null:
		push_error("GameController: desktop camera is not assigned")
		return
	_setup_camera()
	_setup_environment()
	_build_playroom()
	_build_sorting_bins()
	_build_ui()
	_start_level(1)


func _setup_camera() -> void:
	var rig := camera.get_parent() as Node3D
	rig.position = Vector3(0, 2.25, 8.2)
	rig.rotation = Vector3.ZERO
	camera.rotation.x = deg_to_rad(-7.5)


func _setup_environment() -> void:
	var world_environment := get_node_or_null("../WorldEnvironment") as WorldEnvironment
	if world_environment and world_environment.environment:
		var environment := world_environment.environment
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color("#94d7ef")
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color("#fff0dc")
		environment.ambient_light_energy = 0.42
		environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var sun := get_node_or_null("../SunLight") as DirectionalLight3D
	if sun:
		sun.light_color = Color("#fff0d4")
		sun.light_energy = 0.78
		sun.rotation_degrees = Vector3(-48, -35, 0)

	var warm_light := OmniLight3D.new()
	warm_light.name = "WarmWindowLight"
	warm_light.position = Vector3(-4.8, 3.6, 2.6)
	warm_light.light_color = Color("#ffd7a1")
	warm_light.light_energy = 1.9
	warm_light.omni_range = 11.0
	warm_light.shadow_enabled = true
	add_child(warm_light)


func _build_playroom() -> void:
	var room := Node3D.new()
	room.name = "CozyPlayroom"
	add_child(room)

	# Wooden plank floor.
	for index in 18:
		var x := -6.8 + index * 0.8
		var plank_color: Color = palette["wood_light"] if index % 2 == 0 else palette["wood"]
		_add_box(room, Vector3(x, -0.10, 0), Vector3(0.76, 0.18, 13.5), plank_color)

	# Sky-blue back wall and warm side walls.
	_add_box(room, Vector3(0, 2.6, -6.2), Vector3(14.5, 5.4, 0.18), palette["sky"])
	_add_box(room, Vector3(-7.1, 2.6, 0), Vector3(0.18, 5.4, 12.5), palette["cream"])
	_add_box(room, Vector3(7.1, 2.6, 0), Vector3(0.18, 5.4, 12.5), palette["cream"])

	# Puffy painted clouds inspired by the reference room.
	_add_cloud(room, Vector3(-4.4, 3.8, -6.05), 1.15)
	_add_cloud(room, Vector3(0.1, 4.2, -6.05), 0.82)
	_add_cloud(room, Vector3(4.25, 3.45, -6.05), 1.00)
	_add_cloud(room, Vector3(-1.9, 2.75, -6.05), 0.58)
	_add_cloud(room, Vector3(2.25, 2.55, -6.05), 0.62)

	# Pastel star garland.
	var garland_colors := [palette["pink"], palette["yellow"], palette["mint"], palette["lavender"], palette["blue"]]
	for index in 9:
		var x := -5.2 + index * 1.3
		var y := 4.65 - absf(float(index - 4)) * 0.06
		_add_star(room, Vector3(x, y, -5.96), 0.24, garland_colors[index % garland_colors.size()])
		if index < 8:
			_add_bar(room, Vector3(x, y + 0.10, -5.97), Vector3(x + 1.3, 4.65 - absf(float(index + 1 - 4)) * 0.06 + 0.10, -5.97), 0.018, palette["ink"])

	# Two rounded rugs define the play and sorting zones.
	_add_cylinder(room, Vector3(0, 0.025, 0.8), 3.35, 0.05, Color("#f9cfdf"))
	_add_cylinder(room, Vector3(0, 0.045, 0.8), 2.70, 0.03, Color("#fff0be"))
	_add_star(room, Vector3(0, 0.08, 0.8), 1.25, Color("#fff9e8"), Vector3(deg_to_rad(90), 0, 0))

	_build_window(room)
	_build_bookshelf(room)
	_build_block_castle(room)
	_build_rocket(room, Vector3(-5.35, 0.05, -2.35))
	_build_rocket(room, Vector3(5.35, 0.05, -2.35), 0.75)


func _build_window(parent: Node3D) -> void:
	var window := Node3D.new()
	window.name = "SunnyWindow"
	window.position = Vector3(-6.98, 2.9, 0.7)
	window.rotation.y = deg_to_rad(90)
	parent.add_child(window)
	_add_box(window, Vector3.ZERO, Vector3(3.2, 2.55, 0.10), Color("#bfeaff"))
	_add_box(window, Vector3(0, 0, -0.08), Vector3(0.12, 2.70, 0.12), Color.WHITE)
	_add_box(window, Vector3(0, 0, -0.08), Vector3(3.35, 0.12, 0.12), Color.WHITE)
	_add_box(window, Vector3(0, -1.36, -0.02), Vector3(3.55, 0.20, 0.32), Color.WHITE)
	# Soft curtains.
	_add_box(window, Vector3(-1.63, 0, -0.18), Vector3(0.36, 2.85, 0.16), palette["pink"])
	_add_box(window, Vector3(1.63, 0, -0.18), Vector3(0.36, 2.85, 0.16), palette["blue"])
	_add_sphere(window, Vector3(-1.48, -0.15, -0.30), Vector3(0.18, 0.18, 0.12), palette["yellow"])
	_add_sphere(window, Vector3(1.48, -0.15, -0.30), Vector3(0.18, 0.18, 0.12), palette["yellow"])


func _build_bookshelf(parent: Node3D) -> void:
	var shelf := Node3D.new()
	shelf.name = "PastelBookshelf"
	shelf.position = Vector3(5.7, 0, -0.2)
	parent.add_child(shelf)
	_add_box(shelf, Vector3(0, 1.55, 0.20), Vector3(2.0, 3.1, 0.65), Color("#f5d8ba"))
	_add_box(shelf, Vector3(0, 1.58, -0.18), Vector3(1.66, 2.70, 0.20), palette["cream"])
	for y in [0.52, 1.38, 2.24]:
		_add_box(shelf, Vector3(0, y, -0.40), Vector3(1.85, 0.10, 0.72), Color("#c88a63"))
	var colors := [palette["pink"], palette["blue"], palette["yellow"], palette["mint"], palette["lavender"]]
	for index in 10:
		var row := index / 5
		var col := index % 5
		_add_box(shelf, Vector3(-0.62 + col * 0.30, 0.78 + row * 0.86, -0.52), Vector3(0.22, 0.48, 0.32), colors[index % colors.size()])
	_add_star(shelf, Vector3(0, 2.93, -0.52), 0.30, palette["yellow"])


func _build_block_castle(parent: Node3D) -> void:
	var blocks := Node3D.new()
	blocks.name = "BlockCastle"
	blocks.position = Vector3(-5.2, 0.05, 1.1)
	parent.add_child(blocks)
	var colors := [palette["pink"], palette["blue"], palette["yellow"], palette["mint"], palette["lavender"]]
	for row in 4:
		for column in 4 - row:
			_add_box(blocks, Vector3((column - (3 - row) * 0.5) * 0.48, 0.23 + row * 0.45, 0), Vector3(0.42, 0.40, 0.42), colors[(row + column) % colors.size()])
	_add_cone(blocks, Vector3(0, 2.02, 0), 0.34, 0.72, palette["pink"])


func _build_rocket(parent: Node3D, position: Vector3, scale_value := 1.0) -> void:
	var rocket := Node3D.new()
	rocket.name = "ToyRocket"
	rocket.position = position
	rocket.scale = Vector3.ONE * scale_value
	parent.add_child(rocket)
	_add_cylinder(rocket, Vector3(0, 0.78, 0), 0.30, 1.25, palette["cream"])
	_add_cone(rocket, Vector3(0, 1.62, 0), 0.31, 0.48, palette["rose"])
	_add_box(rocket, Vector3(-0.32, 0.34, 0), Vector3(0.22, 0.65, 0.18), palette["rose"], Vector3(0, 0, -0.28))
	_add_box(rocket, Vector3(0.32, 0.34, 0), Vector3(0.22, 0.65, 0.18), palette["blue"], Vector3(0, 0, 0.28))
	_add_cylinder(rocket, Vector3(0, 0.98, -0.30), 0.14, 0.05, palette["blue"], Vector3(deg_to_rad(90), 0, 0))


func _build_sorting_bins() -> void:
	bins[ANIMAL] = _create_bin(ANIMAL, Vector3(-3.0, 0, -3.75), palette["pink"], "ANIMAL TOYS")
	bins[TRANSPORT] = _create_bin(TRANSPORT, Vector3(3.0, 0, -3.75), palette["blue"], "THINGS THAT GO")


func _create_bin(category: String, position: Vector3, color: Color, title: String) -> Area3D:
	var bin := Area3D.new()
	bin.name = category + "Bin"
	bin.position = position
	bin.collision_layer = 8
	bin.collision_mask = 0
	bin.set_meta("is_sorting_bin", true)
	bin.set_meta("category", category)
	add_child(bin)

	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 2.1, 1.8)
	shape_node.shape = shape
	shape_node.position.y = 1.05
	bin.add_child(shape_node)

	_add_box(bin, Vector3(0, 0.18, 0), Vector3(3.0, 0.32, 1.8), color)
	_add_box(bin, Vector3(-1.38, 1.0, 0), Vector3(0.24, 1.75, 1.8), color)
	_add_box(bin, Vector3(1.38, 1.0, 0), Vector3(0.24, 1.75, 1.8), color)
	_add_box(bin, Vector3(0, 1.0, 0.78), Vector3(2.55, 1.75, 0.24), color)
	_add_box(bin, Vector3(0, 0.72, -0.78), Vector3(2.55, 1.18, 0.18), color.lightened(0.12))

	var label := Label3D.new()
	label.text = title
	label.font_size = 54
	label.modulate = palette["ink"]
	label.outline_modulate = Color.WHITE
	label.outline_size = 10
	label.position = Vector3(0, 1.86, -0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bin.add_child(label)

	for x in [-0.62, 0.0, 0.62]:
		_add_star(bin, Vector3(x, 0.48, -0.92), 0.17, palette["yellow"])
	return bin


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameUI"
	add_child(layer)

	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(24, 24)
	top_panel.size = Vector2(550, 132)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fdf5f0e8"), Color("#f1a9c2"), 22))
	layer.add_child(top_panel)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_box)
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 23)
	level_label.add_theme_color_override("font_color", palette["ink"])
	top_box.add_child(level_label)
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color("#70546f"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_box.add_child(objective_label)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 18)
	score_label.add_theme_color_override("font_color", Color("#d65f87"))
	top_box.add_child(score_label)

	var help_panel := PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help_panel.position = Vector2(-335, -80)
	help_panel.size = Vector2(670, 54)
	help_panel.add_theme_stylebox_override("panel", _panel_style(Color("#44364ac9"), Color("#ffffff55"), 18))
	layer.add_child(help_panel)
	var help := Label.new()
	help.text = "LEFT CLICK: pick up    E: drop into box    RIGHT CLICK: put back    WASD: move    MOUSE: look"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color.WHITE)
	help_panel.add_child(help)

	feedback_panel = PanelContainer.new()
	_set_feedback_top_right()
	feedback_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff5dff2"), palette["yellow"], 22))
	layer.add_child(feedback_panel)
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 23)
	feedback_label.add_theme_color_override("font_color", palette["ink"])
	feedback_panel.add_child(feedback_label)

	reticle = Label.new()
	reticle.text = "+"
	reticle.set_anchors_preset(Control.PRESET_CENTER)
	reticle.position = Vector2(-8, -19)
	reticle.add_theme_font_size_override("font_size", 30)
	reticle.add_theme_color_override("font_color", Color("#ffffffdd"))
	reticle.add_theme_color_override("font_shadow_color", palette["ink"])
	reticle.add_theme_constant_override("shadow_offset_x", 2)
	reticle.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(reticle)

	fade_rect = ColorRect.new()
	fade_rect.color = Color("#fff1f8")
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0
	layer.add_child(fade_rect)

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)


func _start_level(level_number: int) -> void:
	current_level = level_number
	sorted_count = 0
	selected_toy = null
	game_finished = false
	_set_feedback_top_right()
	feedback_label.add_theme_font_size_override("font_size", 23)
	_clear_toys()
	for index in TOYS.size():
		var info: Dictionary = TOYS[index]
		var toy := ToyFactoryScript.create_toy(info["name"], info["category"], current_level)
		toy.position = TOY_POSITIONS[index]
		toy.set_meta("home_position", toy.position)
		toy.set_meta("cue", info["cue"])
		toy.set_meta("cue_frequency", 380.0 + index * 75.0)
		add_child(toy)
		toys.append(toy)
	_update_ui()
	var messages := [
		"Listen and study each silhouette.",
		"Now use shape and color clues.",
		"Great! Sort the fully detailed toys.",
	]
	_show_feedback(messages[current_level - 1], palette["yellow"])
	_play_tone(520.0 + current_level * 80.0, 0.18)


func _clear_toys() -> void:
	for toy in toys:
		if is_instance_valid(toy):
			toy.queue_free()
	toys.clear()


func _update_ui() -> void:
	var level_names := ["SILHOUETTES + SOUND", "SHAPES + COLORS", "FULL TOY DETAILS"]
	level_label.text = "LEVEL %d OF 3  -  %s" % [current_level, level_names[current_level - 1]]
	objective_label.text = "Click a toy to pick it up. Aim at ANIMAL TOYS or THINGS THAT GO and press E to drop it. Sort all six to continue."
	score_label.text = "Sorted: %d / 6" % sorted_count


func _unhandled_input(event: InputEvent) -> void:
	if game_finished:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			_start_level(1)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_handle_drop_key()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_toy:
			_return_selected_toy()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if selected_toy and is_instance_valid(selected_toy):
		var target := camera.global_position - camera.global_transform.basis.z * 2.05 + Vector3(0, -0.42, 0)
		selected_toy.global_position = selected_toy.global_position.lerp(target, minf(delta * 11.0, 1.0))
		selected_toy.rotation.y += delta * 0.8


func _handle_click() -> void:
	if selected_toy:
		_show_feedback("Aim at a sorting box and press E to drop the toy.", palette["yellow"])
		return

	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var direction := camera.project_ray_normal(center)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 30.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider := result.get("collider") as Node
	if collider == null:
		return
	if collider.has_meta("is_sortable_toy"):
		_pick_up_toy(collider as Area3D)


func _handle_drop_key() -> void:
	if selected_toy == null:
		_show_feedback("Aim at a toy and left-click to pick it up first.", palette["blue"])
		return
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var direction := camera.project_ray_normal(center)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 30.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		_show_feedback("Aim at one of the two sorting boxes, then press E.", palette["yellow"])
		return
	var collider := result.get("collider") as Node
	if collider and collider.has_meta("is_sorting_bin"):
		_attempt_sort(String(collider.get_meta("category")))
	else:
		_show_feedback("That is not a sorting box. Aim at a labeled box and press E.", palette["yellow"])


func _pick_up_toy(toy: Area3D) -> void:
	selected_toy = toy
	var collision := toy.get_node("PickShape") as CollisionShape3D
	collision.disabled = true
	var cue := String(toy.get_meta("cue"))
	var toy_name := String(toy.get_meta("toy_name"))
	_show_feedback("%s says: %s  Which box?" % [toy_name, cue], palette["mint"])
	_play_tone(float(toy.get_meta("cue_frequency")), 0.28)


func _return_selected_toy() -> void:
	selected_toy.position = selected_toy.get_meta("home_position") as Vector3
	selected_toy.rotation = Vector3.ZERO
	(selected_toy.get_node("PickShape") as CollisionShape3D).disabled = false
	selected_toy = null
	_show_feedback("Toy returned. Choose another one!", palette["blue"])


func _attempt_sort(bin_category: String) -> void:
	var toy_category := String(selected_toy.get_meta("category"))
	var toy_name := String(selected_toy.get_meta("toy_name"))
	if toy_category != bin_category:
		_show_feedback("Not quite - %s belongs with %s." % [toy_name, toy_category], Color("#ffb0b0"))
		_play_tone(190.0, 0.34)
		_shake_selected()
		return

	var completed_toy := selected_toy
	selected_toy = null
	sorted_count += 1
	toys.erase(completed_toy)
	var target_bin := bins[bin_category] as Area3D
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(completed_toy, "global_position", target_bin.global_position + Vector3(0, 0.55, 0), 0.48)
	tween.tween_property(completed_toy, "scale", Vector3.ONE * 0.15, 0.48)
	tween.tween_property(completed_toy, "rotation", Vector3(0, TAU, 0), 0.48)
	tween.finished.connect(completed_toy.queue_free)
	_show_feedback("Correct! %s goes with %s." % [toy_name, bin_category], palette["mint"])
	_play_success_chime()
	_update_ui()
	if sorted_count == TOYS.size():
		_finish_level()


func _shake_selected() -> void:
	if selected_toy == null:
		return
	var start_rotation := selected_toy.rotation
	var tween := create_tween()
	for angle in [0.18, -0.18, 0.12, -0.12, 0.0]:
		tween.tween_property(selected_toy, "rotation:z", angle, 0.07)
	tween.tween_callback(func():
		if selected_toy:
			selected_toy.rotation = start_rotation
	)


func _finish_level() -> void:
	if current_level < 3:
		_show_feedback("Level complete! New visual clues are appearing...", palette["yellow"])
		await get_tree().create_timer(1.6).timeout
		await _fade_transition()
		_start_level(current_level + 1)
	else:
		_show_win_screen()


func _fade_transition() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.32)
	await tween.finished
	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "modulate:a", 0.0, 0.55)


func _show_win_screen() -> void:
	game_finished = true
	feedback_panel.set_anchors_preset(Control.PRESET_CENTER)
	feedback_panel.offset_left = -330
	feedback_panel.offset_top = -105
	feedback_panel.offset_right = 330
	feedback_panel.offset_bottom = 85
	feedback_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff5dff5"), palette["pink"], 30))
	feedback_label.text = "YOU DID IT!\nYou used sound, shape, color, and detail\nto recognize and sort every toy.\n\nPress R to play again."
	feedback_label.add_theme_font_size_override("font_size", 26)
	_play_tone(523.25, 0.18)
	await get_tree().create_timer(0.20).timeout
	_play_tone(659.25, 0.18)
	await get_tree().create_timer(0.20).timeout
	_play_tone(783.99, 0.35)
	_spawn_confetti()


func _spawn_confetti() -> void:
	var colors := [palette["pink"], palette["blue"], palette["yellow"], palette["mint"], palette["lavender"]]
	for index in 45:
		var piece := _add_box(self, Vector3(randf_range(-5.0, 5.0), randf_range(3.5, 6.0), randf_range(-3.0, 3.0)), Vector3(0.08, 0.18, 0.04), colors[index % colors.size()])
		var tween := create_tween().set_parallel(true)
		tween.tween_property(piece, "position:y", 0.25, randf_range(1.8, 3.2))
		tween.tween_property(piece, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), randf_range(1.8, 3.2))


func _show_feedback(message: String, accent: Color) -> void:
	feedback_label.text = message
	feedback_panel.add_theme_stylebox_override("panel", _panel_style(Color("#fff9eff2"), accent, 22))
	feedback_panel.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(feedback_panel, "modulate", Color("#fff7cc"), 0.12)
	tween.tween_property(feedback_panel, "modulate", Color.WHITE, 0.24)


func _set_feedback_top_right() -> void:
	feedback_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	feedback_panel.offset_left = -530
	feedback_panel.offset_top = 24
	feedback_panel.offset_right = -30
	feedback_panel.offset_bottom = 88


func _play_success_chime() -> void:
	_play_tone(660.0, 0.16)
	get_tree().create_timer(0.14).timeout.connect(func(): _play_tone(880.0, 0.22))


func _play_tone(frequency: float, duration: float) -> void:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var envelope := sin(PI * float(index) / float(sample_count))
		var wave := sin(TAU * frequency * float(index) / float(sample_rate))
		data.encode_s16(index * 2, int(wave * envelope * 9000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	audio_player.stream = stream
	audio_player.play()


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	style.shadow_color = Color("#4a355033")
	style.shadow_size = 8
	return style


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material


func _add_box(parent: Node3D, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	return _add_mesh(parent, mesh, position, size, color, rotation)


func _add_sphere(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _add_mesh(parent, mesh, position, size, color)


func _add_cylinder(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _add_mesh(parent, mesh, position, Vector3.ONE, color, rotation)


func _add_cone(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return _add_mesh(parent, mesh, position, Vector3.ONE, color, rotation)


func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = size
	instance.rotation = rotation
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_bar(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var direction := to - from
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 10
	var result := _add_mesh(parent, mesh, from + direction * 0.5, Vector3.ONE, color)
	result.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return result


func _add_cloud(parent: Node3D, position: Vector3, size: float) -> void:
	var cloud := Node3D.new()
	cloud.position = position
	cloud.scale = Vector3.ONE * size
	parent.add_child(cloud)
	_add_sphere(cloud, Vector3(-0.55, 0, 0), Vector3(1.0, 0.62, 0.18), Color("#fffaf0"))
	_add_sphere(cloud, Vector3(0.05, 0.16, 0), Vector3(1.18, 0.82, 0.20), Color("#fffdf7"))
	_add_sphere(cloud, Vector3(0.68, -0.02, 0), Vector3(0.92, 0.58, 0.18), Color("#f7f4ef"))


func _add_star(parent: Node3D, position: Vector3, size: float, color: Color, rotation := Vector3.ZERO) -> Node3D:
	var star := Node3D.new()
	star.position = position
	star.rotation = rotation
	parent.add_child(star)
	for index in 5:
		var angle := index * TAU / 5.0
		var point := Vector3(cos(angle) * size * 0.48, sin(angle) * size * 0.48, 0)
		var ray := Vector3(cos(angle) * size, sin(angle) * size, 0)
		_add_bar(star, point * 0.15, ray, size * 0.19, color)
	_add_sphere(star, Vector3.ZERO, Vector3.ONE * size * 0.48, color)
	return star
