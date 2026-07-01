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

# Bounds and pacing for `wander()`. A wandering subclass sets `roam_min`/`roam_max`
# (usually per scene); the pacing defaults suit a relaxed stroll.
@export var roam_min: Vector2 = Vector2.ZERO
@export var roam_max: Vector2 = Vector2.ZERO
@export var arrival_distance: float = 4.0
@export var max_seconds_per_target: float = 3.0
@export var pause_min: float = 0.4
@export var pause_max: float = 1.6

@onready var _sprite: Sprite2D = $Sprite

var _facing := "down"
var _walk_frame := 0
var _time_on_frame := 0.0

var _target := Vector2.ZERO
var _pause_timer := 0.0
var _seconds_on_target := 0.0


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


## Stroll toward a random point inside the roam box, pausing on arrival before
## picking the next one. Shared by every wandering character (Desi, the mouse, the
## cat). Call `_pick_new_target()` once before the first `wander()`.
func wander(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		stop_walking()
		return
	_seconds_on_target += delta
	var to_target := _target - global_position
	if to_target.length() < arrival_distance or _seconds_on_target > max_seconds_per_target:
		_pick_new_target()
		return
	walk(to_target.normalized(), delta)


func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(roam_min.x, roam_max.x),
		randf_range(roam_min.y, roam_max.y))
	_pause_timer = randf_range(pause_min, pause_max)
	_seconds_on_target = 0.0


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
