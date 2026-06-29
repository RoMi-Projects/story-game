extends StaticBody2D
## Desi: the quest-giver. Her dialogue, portrait, and head marker all depend on
## the trash quest's state. She registers with the interaction manager while the
## player is in range; the primary button drives the conversation.

const ANGRY := preload("res://assets/desi_portrait.png")
const KISS := preload("res://assets/desi_kiss.png")
const WINK := preload("res://assets/desi_wink.png")
const EXCLAIM := preload("res://assets/marker_exclaim.png")
const CHECK := preload("res://assets/marker_check.png")
const HEART := preload("res://assets/heart.png")

const SPEAKER := "Desi"
const HEART_SECONDS := 1.6

@onready var _interaction_area: Area2D = $InteractionArea
@onready var _marker: Node2D = $QuestMarker
@onready var _heart: Sprite2D = $Heart

var _dialogue_box: Node = null


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	QuestManager.changed.connect(_refresh_marker)
	_heart.texture = HEART
	_heart.visible = false
	_refresh_marker()


func on_primary() -> void:
	match QuestManager.state:
		QuestManager.State.NOT_STARTED:
			_say(ANGRY, "This house is a pigsty! You should have taken the trash out days ago. Go on, out with it!")
			QuestManager.accept()
		QuestManager.State.ACCEPTED, QuestManager.State.CARRYING:
			_say(ANGRY, "The trash won't take itself out, you know.")
		QuestManager.State.DELIVERED:
			_say(KISS, "Finally! Thank you, my hero. *mwah*")
			_pop_heart()
			QuestManager.turn_in()
		QuestManager.State.COMPLETED:
			_say(WINK, "Next time don't make me ask you!")


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
		InteractionManager.register(self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister(self)
		var dialogue := _dialogue()
		if dialogue != null:
			dialogue.close()


func _dialogue() -> Node:
	if _dialogue_box == null:
		_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	return _dialogue_box
