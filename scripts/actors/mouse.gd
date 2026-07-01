extends Character
## The garden mouse. It wanders until the player comes near, then chases them;
## on contact it starts the combat scene. Movement, the walk animation and the
## wander loop come from `Character`. The mouse stays gone after a fight (see
## `GameState`) until the player has left for the house and returned.

const COMBAT_SCENE := "res://scenes/combat/combat.tscn"

# How close the player must be for the mouse to notice and to pounce.
const DETECT_RANGE := 70.0
const TOUCH_RANGE := 10.0

var _engaged := false


func _ready() -> void:
	if not GameState.mouse_is_active():
		queue_free()
		return
	_pick_new_target()


func _physics_process(delta: float) -> void:
	if _engaged:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		wander(delta)
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= TOUCH_RANGE:
		_start_combat(player)
	elif to_player.length() <= DETECT_RANGE:
		walk(to_player.normalized(), delta)
	else:
		wander(delta)
	_clamp_inside_garden()


func _start_combat(player: Node) -> void:
	_engaged = true
	stop_walking()
	# Remember where the player stood so the garden restores them after the fight.
	GameState.set_spawn(player.global_position)
	get_tree().change_scene_to_file.call_deferred(COMBAT_SCENE)


func _clamp_inside_garden() -> void:
	global_position.x = clampf(global_position.x, roam_min.x, roam_max.x)
	global_position.y = clampf(global_position.y, roam_min.y, roam_max.y)
