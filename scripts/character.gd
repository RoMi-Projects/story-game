extends CharacterBody2D
class_name Character
## Shared movement for any walking character (the player, NPCs, future ones).
##
## Subclasses decide *where* to walk each frame — the player reads input, an NPC
## picks wander targets — then call `walk(direction, delta)`. This base turns that
## direction into motion, facing, and the matching walk-cycle frame on a 4-row
## (down / up / left / right) x 4-frame spritesheet. `walk_speed` is set per
## character in the scene.

const FRAME_WIDTH := 16
const FRAME_HEIGHT := 24
const WALK_FRAME_COUNT := 4
const SECONDS_PER_FRAME := 0.15
const ROW_FOR_FACING := {"down": 0, "up": 1, "left": 2, "right": 3}

@export var walk_speed: float = 60.0

@onready var _sprite: Sprite2D = $Sprite

var _facing := "down"
var _walk_frame := 0
var _time_on_frame := 0.0


func walk(direction: Vector2, delta: float) -> void:
	velocity = direction * walk_speed
	move_and_slide()
	if direction == Vector2.ZERO:
		stop_walking()
		return
	face_towards(direction)
	_advance_walk_frame(delta)


func stop_walking() -> void:
	velocity = Vector2.ZERO
	_walk_frame = 0
	_time_on_frame = 0.0
	_show_frame()


func face_towards(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"


func _advance_walk_frame(delta: float) -> void:
	_time_on_frame += delta
	if _time_on_frame >= SECONDS_PER_FRAME:
		_time_on_frame -= SECONDS_PER_FRAME
		_walk_frame = (_walk_frame + 1) % WALK_FRAME_COUNT
	_show_frame()


func _show_frame() -> void:
	_sprite.region_rect = Rect2(
		_walk_frame * FRAME_WIDTH,
		ROW_FOR_FACING[_facing] * FRAME_HEIGHT,
		FRAME_WIDTH,
		FRAME_HEIGHT)
