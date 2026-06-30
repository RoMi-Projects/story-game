extends Character
## The garden mouse. It wanders until the player comes near, then chases them;
## on contact it starts the combat scene. Movement and the walk animation come
## from `Character`. The mouse stays gone after a fight (see `GameState`) until
## the player has left for the house and returned.

const COMBAT_SCENE := "res://scenes/combat/combat.tscn"

# How close the player must be for the mouse to notice and to pounce.
const DETECT_RANGE := 70.0
const TOUCH_RANGE := 10.0

# The patch of garden the mouse keeps to, clear of the fence.
const ROAM_MIN := Vector2(28, 28)
const ROAM_MAX := Vector2(292, 156)
const ARRIVAL_DISTANCE := 4.0
const MAX_SECONDS_PER_TARGET := 3.0

var _target := Vector2.ZERO
var _pause_timer := 0.0
var _seconds_on_target := 0.0
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
		_wander(delta)
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() <= TOUCH_RANGE:
		_start_combat(player)
	elif to_player.length() <= DETECT_RANGE:
		walk(to_player.normalized(), delta)
	else:
		_wander(delta)
	_clamp_inside_garden()


func _start_combat(player: Node) -> void:
	_engaged = true
	stop_walking()
	# Remember where the player stood so the garden restores them after the fight.
	GameState.set_spawn(player.global_position)
	get_tree().change_scene_to_file.call_deferred(COMBAT_SCENE)


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
	_pause_timer = randf_range(0.3, 1.2)
	_seconds_on_target = 0.0


func _clamp_inside_garden() -> void:
	global_position.x = clampf(global_position.x, ROAM_MIN.x, ROAM_MAX.x)
	global_position.y = clampf(global_position.y, ROAM_MIN.y, ROAM_MAX.y)
