extends Node
## Carries small bits of state across area (scene) changes.
##
## A door sets the spawn for the next scene; the player reads and clears it on
## `_ready`. If none is set (e.g. first launch), the player keeps the position
## placed in the scene. It also remembers whether the garden mouse is currently
## "gone" (so it stays away after a fight until the player visits the house and
## comes back) and whether the player just lost a fight (so Desi can react).

var _spawn := Vector2.ZERO
var _has_spawn := false

var _mouse_active := true
var _lost_to_mouse := false


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


func flag_mouse_loss() -> void:
	_lost_to_mouse = true


func take_mouse_loss() -> bool:
	var lost := _lost_to_mouse
	_lost_to_mouse = false
	return lost
