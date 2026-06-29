extends Node
## Carries the player's spawn position across area (scene) changes.
##
## A door sets the spawn for the next scene; the player reads and clears it on
## `_ready`. If none is set (e.g. first launch), the player keeps the position
## placed in the scene.

var _spawn := Vector2.ZERO
var _has_spawn := false


func set_spawn(position: Vector2) -> void:
	_spawn = position
	_has_spawn = true


func has_spawn() -> bool:
	return _has_spawn


func take_spawn() -> Vector2:
	_has_spawn = false
	return _spawn
