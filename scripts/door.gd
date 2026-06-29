extends Area2D
## Walking into this door loads another area and places the player at a spawn.

@export_file("*.tscn") var target_scene := ""
@export var target_spawn := Vector2.ZERO

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	GameState.set_spawn(target_spawn)
	# Scene changes can't run during the physics callback that fires this signal.
	get_tree().change_scene_to_file.call_deferred(target_scene)
