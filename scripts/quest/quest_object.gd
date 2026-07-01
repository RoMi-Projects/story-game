extends StaticBody2D
class_name QuestObject
## Shared behaviour for solid objects the player inspects or uses during a quest.
##
## Handles the sprite, interaction registration, the inspect popup, and a quest
## marker that appears when `_wants_marker()` is true. Subclasses define what the
## primary button does, the displayed name/description, and when the marker shows.

const EXCLAIM := preload("res://assets/marker_exclaim.png")
const INTERACTION_MARGIN := 10.0

@export var texture: Texture2D
# Grid cell of the footprint's top-left; (-1, -1) derives it from the position.
@export var cell := Vector2i(-1, -1)
@export var footprint_override := Vector2i.ZERO
@export var solid := true

var _footprint := Vector2i.ONE

@onready var _sprite: Sprite2D = $Sprite
@onready var _marker: Node2D = $QuestMarker
@onready var _interaction_area: Area2D = $InteractionArea
@onready var _body_shape: CollisionShape2D = get_node_or_null("Collision")
@onready var _area_shape: CollisionShape2D = get_node_or_null("InteractionArea/AreaShape")


func _ready() -> void:
	_sprite.texture = texture
	_place_on_grid()
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.changed.connect(_refresh_marker)
	_refresh_marker()


func _place_on_grid() -> void:
	_footprint = footprint_override if footprint_override != Vector2i.ZERO else WorldGrid.footprint_of(texture)
	var grid := WorldGrid.of(self)
	if grid != null:
		cell = grid.place(self, _body_shape, cell, _footprint, solid)
	elif _body_shape != null:
		_body_shape.shape = _rect(Vector2(_footprint) * WorldGrid.TILE)
		_body_shape.disabled = not solid
	if _area_shape != null:
		_area_shape.shape = _rect(WorldGrid.interaction_extent(_footprint, INTERACTION_MARGIN))


func _rect(size: Vector2) -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	return shape


func _release_occupancy() -> void:
	if not solid:
		return
	var grid := WorldGrid.of(self)
	if grid != null:
		grid.release(cell, _footprint)


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
