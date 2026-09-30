class_name SortingBox
extends Area3D

@export var min_props_required := 3

func _ready() -> void:
	add_to_group("boxes")

## Props currently resting (not being held) inside this box, checked live.
func get_settled_props() -> Array[Prop]:
	var result: Array[Prop] = []
	for body in get_overlapping_bodies():
		if body is Prop and not body.freeze:
			result.append(body as Prop)
	return result

## True only if this box has at least min_props_required props, all the same category.
func is_valid() -> bool:
	var props := get_settled_props()

	if props.size() < min_props_required:
		return false

	var first_category = props[0].category
	for prop in props:
		if prop.category != first_category:
			return false

	return true
