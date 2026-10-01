
extends Node3D

## Set per level instance in the Inspector — where to go after this one.
## For the last level, point this back at level_01 to complete the loop.
@export_file("*.tscn") var next_level_scene: String = ""

var _has_won := false

func _process(_delta: float) -> void:
	if _has_won:
		return

	if _check_win_condition():
		_has_won = true
		on_win()

func _check_win_condition() -> bool:
	return GameManager.all_boxes_valid()

func on_win() -> void:
	_advance()

func _advance() -> void:
	LevelManager.load_level(next_level_scene)
