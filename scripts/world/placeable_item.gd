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
	var grid := _grid()
	_footprint = _resolve_footprint(grid)
	if grid != null:
		var origin := cell
		if origin.x < 0 or origin.y < 0:
			origin = grid.to_cell(position - _footprint_extent() * 0.5)
		position = grid.to_world(origin) + _footprint_extent() * 0.5
		cell = origin
		if solid:
			grid.register(origin, _footprint, self)
	_build_shapes()


func _resolve_footprint(grid: WorldGrid) -> Vector2i:
	if footprint_override != Vector2i.ZERO:
		return footprint_override
	if grid != null:
		return grid.footprint_of(texture)
	var size := texture.get_size()
	return Vector2i(maxi(1, ceili(size.x / WorldGrid.TILE)), maxi(1, ceili(size.y / WorldGrid.TILE)))


func _footprint_extent() -> Vector2:
	return Vector2(_footprint) * WorldGrid.TILE


func _build_shapes() -> void:
	_body_shape.shape = _rectangle(_footprint_extent())
	_body_shape.disabled = not solid
	_area_shape.shape = _rectangle(texture.get_size() + Vector2.ONE * INTERACTION_MARGIN * 2.0)


func _grid() -> WorldGrid:
	return get_tree().get_first_node_in_group("world_grid") as WorldGrid


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
		var grid := _grid()
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
