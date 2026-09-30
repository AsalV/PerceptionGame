extends Node

var current_level: Node

func load_level(scene_path: String) -> void:
	if scene_path == "":
		push_warning("LevelManager: next_level_scene is empty!")
		return

	var container := get_tree().root.get_node("Main/LevelContainer")

	if current_level:
		current_level.queue_free()

	current_level = load(scene_path).instantiate()
	container.add_child(current_level)
