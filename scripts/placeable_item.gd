extends StaticBody2D
## A single piece of furniture the player can inspect or pick up.
##
## Primary button: toggle a popup showing the item's picture, name, and a fun
## description. Secondary button: remove it from the room and add it to the
## inventory. Collision and interaction shapes are sized from the texture, so
## every instance only needs its name, description, texture, and solidity.

const INTERACTION_MARGIN := 8.0

@export var item_name := ""
@export_multiline var description := ""
@export var texture: Texture2D
@export var solid := true

@onready var _sprite: Sprite2D = $Sprite
@onready var _body_shape: CollisionShape2D = $Collision
@onready var _interaction_area: Area2D = $InteractionArea
@onready var _area_shape: CollisionShape2D = $InteractionArea/AreaShape


func _ready() -> void:
	_sprite.texture = texture
	_build_shapes()
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func _build_shapes() -> void:
	var picture_size := texture.get_size()
	_body_shape.shape = _rectangle(picture_size)
	_body_shape.disabled = not solid
	_area_shape.shape = _rectangle(picture_size + Vector2.ONE * INTERACTION_MARGIN * 2.0)


func _rectangle(size: Vector2) -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	return shape


func on_primary() -> void:
	var popup := _popup()
	if popup.is_open():
		popup.close()
	else:
		popup.show_item(item_name, description, texture)


func on_secondary() -> void:
	_close_popup()
	Inventory.add_item(item_name, description, texture)
	InteractionManager.unregister(self)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister(self)
		_close_popup()


func _close_popup() -> void:
	var popup := _popup()
	if popup != null:
		popup.close()


func _popup() -> Node:
	return get_tree().get_first_node_in_group("item_popup")
