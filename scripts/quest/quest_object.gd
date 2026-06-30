extends StaticBody2D
class_name QuestObject
## Shared behaviour for solid objects the player inspects or uses during a quest.
##
## Handles the sprite, interaction registration, the inspect popup, and a quest
## marker that appears when `_wants_marker()` is true. Subclasses define what the
## primary button does, the displayed name/description, and when the marker shows.

const EXCLAIM := preload("res://assets/marker_exclaim.png")

@export var texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite
@onready var _marker: Node2D = $QuestMarker
@onready var _interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	_sprite.texture = texture
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.changed.connect(_refresh_marker)
	_refresh_marker()


func on_primary() -> void:
	pass


func item_name() -> String:
	return ""


func description() -> String:
	return ""


func _wants_marker() -> bool:
	return false


func _toggle_info() -> void:
	var popup := _popup()
	if popup.is_open():
		popup.close()
	else:
		popup.show_item(item_name(), description(), texture)


func _flash_popup(text: String) -> void:
	var popup := _popup()
	if popup != null:
		popup.show_item(item_name(), text, texture)


func _refresh_marker() -> void:
	if _wants_marker():
		_marker.show_icon(EXCLAIM)
	else:
		_marker.hide_icon()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister(self)
		var popup := _popup()
		if popup != null:
			popup.close()


func _popup() -> Node:
	return get_tree().get_first_node_in_group("item_popup")
