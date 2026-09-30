extends Node

func all_boxes_valid() -> bool:
	var boxes := get_tree().get_nodes_in_group("boxes")

	if boxes.is_empty():
		return false

	for box in boxes:
		if not box.is_valid():
			return false

	return true
