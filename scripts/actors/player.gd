extends Character
## The player character.
##
## Movement and the walk animation come from `Character`; this script only adds
## what is player-specific: reading input, placing itself at the spawn point
## after a door transition, and swapping to the carry spritesheet while holding
## the trash bag.

const DEFAULT_SHEET := preload("res://assets/player_spritesheet.png")
const CARRY_SHEET := preload("res://assets/player_carry_spritesheet.png")


func _ready() -> void:
	add_to_group("player")
	_apply_spawn()
	QuestManager.changed.connect(_update_spritesheet)
	_update_spritesheet()


func _physics_process(delta: float) -> void:
	walk(Input.get_vector("move_left", "move_right", "move_up", "move_down"), delta)


func _apply_spawn() -> void:
	if GameState.has_spawn():
		global_position = GameState.take_spawn()


func _update_spritesheet() -> void:
	_sprite.texture = CARRY_SHEET if QuestManager.is_carrying() else DEFAULT_SHEET
