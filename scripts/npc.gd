extends StaticBody2D
## A character the player can stand next to and talk to.
##
## While the player is within the interaction area, pressing "interact" opens
## this NPC's message in the shared dialogue box; pressing it again closes it.

@export var speaker_name := "Desi"
@export_multiline var message := ""
@export var portrait: Texture2D

@onready var _interaction_area: Area2D = $InteractionArea

var _player_is_near := false
var _dialogue_box: Node = null


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_is_near and Input.is_action_just_pressed("interact"):
		_toggle_dialogue()


func _toggle_dialogue() -> void:
	if _dialogue().is_open():
		_dialogue().close()
	else:
		_dialogue().open(speaker_name, portrait, message)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_is_near = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_is_near = false
		_dialogue().close()


func _dialogue() -> Node:
	if _dialogue_box == null:
		_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	return _dialogue_box
