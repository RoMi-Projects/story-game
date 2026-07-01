extends Node
## Carries small bits of state across area (scene) changes.
##
## A door sets the spawn for the next scene; the player reads and clears it on
## `_ready`. If none is set (e.g. first launch), the player keeps the position
## placed in the scene. It also remembers whether the garden mouse is currently
## "gone" (so it stays away after a fight until the player visits the house and
## comes back) and which creature, if any, just beat the player (so Desi can
## react to the right culprit — the mouse or the cat).

var _spawn := Vector2.ZERO
var _has_spawn := false

var _mouse_active := true
var _loss_enemy := ""


func set_spawn(position: Vector2) -> void:
	_spawn = position
	_has_spawn = true


func has_spawn() -> bool:
	return _has_spawn


func take_spawn() -> Vector2:
	_has_spawn = false
	return _spawn


func mouse_is_active() -> bool:
	return _mouse_active


func suppress_mouse() -> void:
	_mouse_active = false


func activate_mouse() -> void:
	_mouse_active = true


func flag_loss(enemy: String) -> void:
	_loss_enemy = enemy


## Returns the creature that last beat the player ("mouse" / "cat"), then clears
## it. An empty string means there is no unread loss.
func take_loss() -> String:
	var enemy := _loss_enemy
	_loss_enemy = ""
	return enemy
