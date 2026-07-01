extends Node2D
## A fixture that lives inside the wall — its picture is baked into the wall tile
## (see the wall_window / wall_portrait tiles). It carries no sprite or collision of
## its own; it exists only so the player can inspect it. The child InteractableArea
## handles registration; this script just shows the popup.

@export var item_name := ""
@export_multiline var description := ""
@export var texture: Texture2D


func on_primary() -> void:
	var popup := get_tree().get_first_node_in_group("item_popup")
	if popup == null:
		return
	if popup.is_open():
		popup.close()
	else:
		popup.show_item(item_name, description, texture)
