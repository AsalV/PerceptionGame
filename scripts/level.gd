
extends Node3D

## Set per level instance in the Inspector — where to go after this one.
## For the last level, point this back at level_01 to complete the loop.
@export_file("*.tscn") var next_level_scene: String = ""

@export var advance_button_action := "ax_button"  # only used by the placeholder below

var _advance_controller: XRController3D = null
var _has_won := false


func _ready() -> void:
	_advance_controller = get_tree().root.get_node_or_null(
		"Main/PlayerBody/XROrigin3D/RightController"
	) as XRController3D


func _process(_delta: float) -> void:
	if _has_won:
		return

	if _check_win_condition():
		_has_won = true
		on_win()


#############################################
# >>> THIS IS THE ONLY FUNCTION THAT SHOULD NEED TO CHANGE <<<
# -----------------------------------------------------------------
# Right now it just checks whether the test "A" button is pressed.
# Replace the body with the real check, e.g.:
#     return GameManager.all_props_sorted()
# Add whatever helper functions/variables you need elsewhere in this
# script or in GameManager — that's fine. Just make sure this function
# returns true exactly once, when the level should be considered complete.
#############################################
func _check_win_condition() -> bool:
	return _advance_controller != null and _advance_controller.is_button_pressed(advance_button_action)
## once ready return GameManager.all_boxes_valid()
#############################################
# >>> END OF THE FUNCTION THAT SHOULD CHANGE <<<
#############################################


func on_win() -> void:
	_advance()


func _advance() -> void:
	LevelManager.load_level(next_level_scene)
