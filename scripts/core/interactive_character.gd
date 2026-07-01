extends Character
class_name InteractiveCharacter
## A walking Character the player can talk to: it registers with the
## InteractionManager while the player stands inside its `InteractionArea`, and
## offers a shared dialogue helper. Subclasses override `on_primary()` (the
## interact button) and `_speaker()`; `_on_player_entered/exited()` are optional
## hooks. Desi and the garden cat both build on this.

@onready var _interaction_area: Area2D = $InteractionArea

var _dialogue_box: Node = null
var _player_in_range := false


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


func on_primary() -> void:
	pass


func player_in_range() -> bool:
	return _player_in_range


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		InteractionManager.register(self)
		_on_player_entered()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		InteractionManager.unregister(self)
		var dialogue := _dialogue()
		if dialogue != null:
			dialogue.close()
		_on_player_exited()


func _on_player_entered() -> void:
	pass


func _on_player_exited() -> void:
	pass


func _say(portrait: Texture2D, message: String) -> void:
	var dialogue := _dialogue()
	if dialogue != null:
		dialogue.open(_speaker(), portrait, message)


func _speaker() -> String:
	return ""


func _dialogue() -> Node:
	if _dialogue_box == null:
		_dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	return _dialogue_box
