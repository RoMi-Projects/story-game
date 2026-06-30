extends CharacterBody2D
## Desi: the quest-giver. She wanders the house, stops to face and talk to the
## player when they come near, and her dialogue, portrait, and head marker all
## depend on the trash quest's state.

const ANGRY := preload("res://assets/desi_portrait.png")
const KISS := preload("res://assets/desi_kiss.png")
const WINK := preload("res://assets/desi_wink.png")
const EXCLAIM := preload("res://assets/marker_exclaim.png")
const CHECK := preload("res://assets/marker_check.png")
const HEART := preload("res://assets/heart.png")

const SPEAKER := "Desi"
const HEART_SECONDS := 1.6

# The quest-giving intro, shown one popup at a time. The quest is accepted after
# the last line.
const INTRO_LINES := [
	"This house is a pigsty! There's trash absolutely everywhere.",
	"Grab a bag from the kitchen and pick up every last piece!",
]

const WALK_SPEED := 26.0
const FRAME_WIDTH := 16
const FRAME_HEIGHT := 24
const WALK_FRAME_COUNT := 4
const SECONDS_PER_FRAME := 0.18
const ROW_FOR_FACING := {"down": 0, "up": 1, "left": 2, "right": 3}

# The patch of floor she roams, kept clear of the walls.
const ROAM_MIN := Vector2(40, 44)
const ROAM_MAX := Vector2(280, 148)
const ARRIVAL_DISTANCE := 4.0
const MAX_SECONDS_PER_TARGET := 3.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _interaction_area: Area2D = $InteractionArea
@onready var _marker: Node2D = $QuestMarker
@onready var _heart: Sprite2D = $Heart

var _dialogue_box: Node = null
var _intro_line := 0
var _player_in_range := false
var _facing := "down"
var _walk_frame := 0
var _time_on_frame := 0.0
var _target := Vector2.ZERO
var _pause_timer := 0.0
var _seconds_on_target := 0.0


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.changed.connect(_refresh_marker)
	_heart.texture = HEART
	_heart.visible = false
	_refresh_marker()
	_pick_new_target()


func _physics_process(delta: float) -> void:
	if _player_in_range:
		_pause_and_face_player()
		return
	_wander(delta)


func _wander(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		_stand_still()
		return
	_seconds_on_target += delta
	var to_target := _target - global_position
	if to_target.length() < ARRIVAL_DISTANCE or _seconds_on_target > MAX_SECONDS_PER_TARGET:
		_pick_new_target()
		return
	var direction := to_target.normalized()
	velocity = direction * WALK_SPEED
	move_and_slide()
	_face_towards(direction)
	_advance_walk(delta)


func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(ROAM_MIN.x, ROAM_MAX.x),
		randf_range(ROAM_MIN.y, ROAM_MAX.y))
	_pause_timer = randf_range(0.4, 1.6)
	_seconds_on_target = 0.0


func _stand_still() -> void:
	velocity = Vector2.ZERO
	_reset_to_idle_frame()


func _pause_and_face_player() -> void:
	_stand_still()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		_face_towards(player.global_position - global_position)


func _face_towards(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) > absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"
	_show_current_frame()


func _advance_walk(delta: float) -> void:
	_time_on_frame += delta
	if _time_on_frame >= SECONDS_PER_FRAME:
		_time_on_frame -= SECONDS_PER_FRAME
		_walk_frame = (_walk_frame + 1) % WALK_FRAME_COUNT
	_show_current_frame()


func _reset_to_idle_frame() -> void:
	_walk_frame = 0
	_time_on_frame = 0.0
	_show_current_frame()


func _show_current_frame() -> void:
	var row: int = ROW_FOR_FACING[_facing]
	_sprite.region_rect = Rect2(
		_walk_frame * FRAME_WIDTH, row * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)


func on_primary() -> void:
	match QuestManager.state:
		QuestManager.State.NOT_STARTED:
			_advance_intro()
		QuestManager.State.ACCEPTED, QuestManager.State.COLLECTING:
			_say(ANGRY, "The trash won't pick itself up, you know.")
		QuestManager.State.DELIVERED:
			_say(KISS, "Finally! Thank you, my hero. *mwah*")
			_pop_heart()
			QuestManager.turn_in()
		QuestManager.State.COMPLETED:
			_say(WINK, "Next time don't make me ask you!")


func _advance_intro() -> void:
	_say(ANGRY, INTRO_LINES[_intro_line])
	_intro_line += 1
	if _intro_line >= INTRO_LINES.size():
		QuestManager.accept()


func _say(portrait: Texture2D, message: String) -> void:
	var dialogue := _dialogue()
	if dialogue != null:
		dialogue.open(SPEAKER, portrait, message)


func _refresh_marker() -> void:
	match QuestManager.state:
		QuestManager.State.NOT_STARTED:
			_marker.show_icon(EXCLAIM)
		QuestManager.State.DELIVERED:
			_marker.show_icon(CHECK)
		_:
			_marker.hide_icon()


func _pop_heart() -> void:
	_heart.visible = true
	await get_tree().create_timer(HEART_SECONDS).timeout
	if is_instance_valid(self):
		_heart.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		InteractionManager.register(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_intro_line = 0
		InteractionManager.unregister(self)
		var dialogue := _dialogue()
		if dialogue != null:
			dialogue.close()


func _dialogue() -> Node:
	if _dialogue_box == null:
		_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	return _dialogue_box
