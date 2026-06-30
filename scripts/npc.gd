extends Character
## Desi: the quest-giver. Movement and the walk animation come from `Character`;
## this script adds her behaviour: wandering the house, stopping to face and talk
## to the player when they come near, and a head marker / portrait / dialogue that
## all depend on the trash quest's state.

const ANGRY := preload("res://assets/desi_portrait.png")
const KISS := preload("res://assets/desi_kiss.png")
const WINK := preload("res://assets/desi_wink.png")
const SMILE := preload("res://assets/desi_smile.png")
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

# The patch of floor she roams, kept clear of the walls.
const ROAM_MIN := Vector2(40, 44)
const ROAM_MAX := Vector2(280, 148)
const ARRIVAL_DISTANCE := 4.0
const MAX_SECONDS_PER_TARGET := 3.0

@onready var _interaction_area: Area2D = $InteractionArea
@onready var _marker: Node2D = $QuestMarker
@onready var _heart: Sprite2D = $Heart

var _dialogue_box: Node = null
var _intro_line := 0
var _player_in_range := false
var _target := Vector2.ZERO
var _pause_timer := 0.0
var _seconds_on_target := 0.0
var _approaching_after_loss := false


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.changed.connect(_refresh_marker)
	_heart.texture = HEART
	_heart.visible = false
	_refresh_marker()
	_pick_new_target()
	# Being back in the house means the garden mouse gets another go next visit.
	GameState.activate_mouse()
	_approaching_after_loss = GameState.take_mouse_loss()


func _physics_process(delta: float) -> void:
	if _approaching_after_loss:
		_approach_player_after_loss(delta)
		return
	if _player_in_range:
		_stop_and_face_player()
		return
	_wander(delta)


func _approach_player_after_loss(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_approaching_after_loss = false
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= ARRIVAL_DISTANCE + 12.0:
		stop_walking()
		face_towards(to_player)
		_say(SMILE, "You saw the mouse again?")
		_approaching_after_loss = false
		return
	walk(to_player.normalized(), delta)


func _wander(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer -= delta
		stop_walking()
		return
	_seconds_on_target += delta
	var to_target := _target - global_position
	if to_target.length() < ARRIVAL_DISTANCE or _seconds_on_target > MAX_SECONDS_PER_TARGET:
		_pick_new_target()
		return
	walk(to_target.normalized(), delta)


func _pick_new_target() -> void:
	_target = Vector2(
		randf_range(ROAM_MIN.x, ROAM_MAX.x),
		randf_range(ROAM_MIN.y, ROAM_MAX.y))
	_pause_timer = randf_range(0.4, 1.6)
	_seconds_on_target = 0.0


func _stop_and_face_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		face_towards(player.global_position - global_position)
	stop_walking()


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
