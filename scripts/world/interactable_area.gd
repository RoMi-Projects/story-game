extends Area2D
class_name InteractableArea
## A drop-in child Area2D that registers its parent with the InteractionManager
## while the player stands inside it, and closes any open item popup when they
## leave. The parent must expose `on_primary()` (and optionally `on_secondary()`).
## Reused by PlaceableItem and the wall fixtures so that register/unregister logic
## lives in exactly one place.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register(get_parent())


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister(get_parent())
		var popup := get_tree().get_first_node_in_group("item_popup")
		if popup != null:
			popup.close()
