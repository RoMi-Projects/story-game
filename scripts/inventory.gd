extends Node
## Holds the items the player has picked up from the room.
##
## Each entry is { "name": String, "description": String, "texture": Texture2D }.
## Emits `changed` so the inventory panel can refresh. The store will later add
## and remove items through this same singleton.

signal changed

var items: Array[Dictionary] = []


func add_item(item_name: String, description: String, texture: Texture2D, is_quest := false) -> void:
	items.append({
		"name": item_name,
		"description": description,
		"texture": texture,
		"quest": is_quest,
	})
	changed.emit()


func remove_item(item_name: String) -> void:
	for index in items.size():
		if items[index]["name"] == item_name:
			items.remove_at(index)
			changed.emit()
			return
