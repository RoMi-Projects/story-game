extends InteractiveCharacter
## Desi: the quest-giver. Movement, wandering, interaction registration and the
## dialogue helper all come from `InteractiveCharacter`; this script adds her
## behaviour: stopping to face and talk to the player when they come near, and a
## head marker / portrait / dialogue that all depend on the trash quest's state.

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

@onready var _marker: Node2D = $QuestMarker
@onready var _heart: Sprite2D = $Heart

var _intro_line := 0
var _loss_enemy := ""
var _approaching_after_loss := false


func _ready() -> void:
	super()
	QuestManager.changed.connect(_refresh_marker)
	_heart.texture = HEART
	_heart.visible = false
	_refresh_marker()
	_pick_new_target()
	# Being back in the house means the garden mouse gets another go next visit.
	GameState.activate_mouse()
	_loss_enemy = GameState.take_loss()
	_approaching_after_loss = _loss_enemy != ""


func _physics_process(delta: float) -> void:
	if _approaching_after_loss:
		_approach_player_after_loss(delta)
		return
	if player_in_range():
		_stop_and_face_player()
		return
	wander(delta)


func _approach_player_after_loss(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_approaching_after_loss = false
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= arrival_distance + 12.0:
		stop_walking()
		face_towards(to_player)
		_say(SMILE, _loss_line())
		_approaching_after_loss = false
		return
	walk(to_player.normalized(), delta)


func _loss_line() -> String:
	return "Baby scared you off again?" if _loss_enemy == "cat" else "You saw the mouse again?"


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


func _on_player_exited() -> void:
	_intro_line = 0


func _speaker() -> String:
	return SPEAKER
