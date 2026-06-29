extends Node2D
## A small icon that floats above a quest object and bobs gently.
## Reused by Desi, the trash can, and the garden container.

const BOB_AMPLITUDE := 1.5
const BOB_SPEED := 3.0

@onready var _sprite: Sprite2D = $Sprite

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	hide_icon()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_AMPLITUDE


func show_icon(texture: Texture2D) -> void:
	_sprite.texture = texture
	visible = true


func hide_icon() -> void:
	visible = false
