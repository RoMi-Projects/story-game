extends StaticBody2D
## A single piece of furniture the player can inspect or pick up.
##
## Primary button: toggle a popup showing the item's picture, name, and a fun
## description. Secondary button: remove it from the room and add it to the
## inventory. Collision and interaction shapes are sized from the texture, so
## every instance only needs its name, description, texture, and solidity.

# How far the interaction reach extends beyond the blocking footprint, per side, so
# that standing adjacent (where the footprint stops you) reliably registers.
const INTERACTION_MARGIN := 10.0

@export var item_name := ""
@export_multiline var description := ""
@export var texture: Texture2D
@export var solid := true
# Grid cell of the footprint's top-left. Left at (-1, -1) it is derived from the
# node's authored position, so existing scenes snap without hand-editing.
@export var cell := Vector2i(-1, -1)
# Tiles this object blocks. Zero = auto from the texture (ceil to whole tiles).
@export var footprint_override := Vector2i.ZERO
# Shifts the picture off the footprint so a tall/wide sprite can overflow into a
# neighbouring (free) cell while still only blocking its footprint.
@export var art_offset := Vector2.ZERO

var _footprint := Vector2i.ONE

@onready var _sprite: Sprite2D = $Sprite
@onready var _body_shape: CollisionShape2D = $Collision
@onready var _area_shape: CollisionShape2D = $InteractionArea/AreaShape


func _ready() -> void:
	_sprite.texture = texture
	_sprite.position = art_offset
	_place_on_grid()


func _place_on_grid() -> void:
	_footprint = footprint_override if footprint_override != Vector2i.ZERO else WorldGrid.footprint_of(texture)
	var grid := WorldGrid.of(self)
	if grid != null:
		cell = grid.place(self, _body_shape, cell, _footprint, solid)
	else:
		_body_shape.shape = _rectangle(Vector2(_footprint) * WorldGrid.TILE)
		_body_shape.disabled = not solid
	_area_shape.shape = _rectangle(WorldGrid.interaction_extent(_footprint, INTERACTION_MARGIN))


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
	if solid:
		var grid := WorldGrid.of(self)
		if grid != null:
			grid.release(cell, _footprint)
	Inventory.add_item(item_name, description, texture)
	InteractionManager.unregister(self)
	queue_free()


func _close_popup() -> void:
	var popup := _popup()
	if popup != null:
		popup.close()


func _popup() -> Node:
	return get_tree().get_first_node_in_group("item_popup")
