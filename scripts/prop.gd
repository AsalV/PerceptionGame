class_name Prop
extends RigidBody3D

enum Category { VEHICLE,  ANIMAL }

@export var category: Category

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _was_frozen := false

func _ready() -> void:
	add_to_group("grabbable")
	add_to_group("props")
	
	gravity_scale = 1.0
	freeze = false
	_was_frozen = freeze


func _physics_process(_delta: float) -> void:
	if freeze != _was_frozen:
		_was_frozen = freeze
		if freeze:
			_on_grabbed()
		else:
			_on_released()


func _on_grabbed() -> void:
	if audio_player:
		audio_player.play()


func _on_released() -> void:
	pass
