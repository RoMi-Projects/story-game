extends CharacterBody2D
## Moves the character around the room and animates the walk cycle.
##
## Input comes from the engine's input actions, which are driven by both the
## keyboard (arrows / WASD) and the on-screen touch buttons. This script never
## needs to know which one is in use.

const SPEED := 70.0

const FRAME_WIDTH := 16
const FRAME_HEIGHT := 24
const WALK_FRAME_COUNT := 4
const SECONDS_PER_FRAME := 0.15

const ROW_FOR_FACING := {
	"down": 0,
	"up": 1,
	"left": 2,
	"right": 3,
}

const DEFAULT_SHEET := preload("res://assets/player_spritesheet.png")
const CARRY_SHEET := preload("res://assets/player_carry_spritesheet.png")

@onready var _sprite: Sprite2D = $Sprite

var _facing := "down"


func _ready() -> void:
	add_to_group("player")
	_apply_spawn()
	QuestManager.changed.connect(_update_spritesheet)
	_update_spritesheet()


func _apply_spawn() -> void:
	if GameState.has_spawn():
		global_position = GameState.take_spawn()


func _update_spritesheet() -> void:
	_sprite.texture = CARRY_SHEET if QuestManager.is_carrying() else DEFAULT_SHEET
var _walk_frame := 0
var _time_on_frame := 0.0


func _physics_process(delta: float) -> void:
	var direction := _read_movement_direction()
	_move(direction)
	_face_towards(direction)
	_advance_walk_animation(delta, direction)
	_show_current_frame()


func _read_movement_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _move(direction: Vector2) -> void:
	velocity = direction * SPEED
	move_and_slide()


func _face_towards(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"


func _advance_walk_animation(delta: float, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		_reset_to_idle_frame()
		return
	_time_on_frame += delta
	if _time_on_frame >= SECONDS_PER_FRAME:
		_time_on_frame -= SECONDS_PER_FRAME
		_walk_frame = (_walk_frame + 1) % WALK_FRAME_COUNT


func _reset_to_idle_frame() -> void:
	_walk_frame = 0
	_time_on_frame = 0.0


func _show_current_frame() -> void:
	var row: int = ROW_FOR_FACING[_facing]
	_sprite.region_rect = Rect2(
		_walk_frame * FRAME_WIDTH,
		row * FRAME_HEIGHT,
		FRAME_WIDTH,
		FRAME_HEIGHT
	)
