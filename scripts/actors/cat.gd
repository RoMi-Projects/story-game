extends InteractiveCharacter
## Baby, the garden cat. She wanders the garden like the other creatures and stops
## to eye the player when they come near. Interact with her normally and she just
## meows, crossly. Interact while you're carrying the trash bag and she turns the
## encounter into a fight (see `cat_combat.gd`). Movement, wandering, interaction
## registration and dialogue all come from `InteractiveCharacter`.

const COMBAT_SCENE := "res://scenes/combat/cat_combat.tscn"
const ANGRY := preload("res://assets/cat_angry.png")
const SPEAKER := "Baby"

var _engaged := false


func _ready() -> void:
	super()
	_pick_new_target()


func _physics_process(delta: float) -> void:
	if _engaged or player_in_range():
		stop_walking()
		return
	wander(delta)


func on_primary() -> void:
	if QuestManager.is_carrying():
		_start_combat()
	else:
		_say(ANGRY, "Meow.")


func _start_combat() -> void:
	_engaged = true
	stop_walking()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		# Remember where the player stood so the garden restores them afterwards.
		GameState.set_spawn(player.global_position)
	get_tree().change_scene_to_file.call_deferred(COMBAT_SCENE)


func _speaker() -> String:
	return SPEAKER
